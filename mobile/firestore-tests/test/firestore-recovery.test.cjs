const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {
  after,
  before,
  beforeEach,
  test,
} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  Timestamp,
  collection,
  deleteField,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} = require('firebase/firestore');

const projectId = 'demo-conviva-rules';
const requestCollection = 'passwordRecoveryRequests';
const deliveryCollection = 'passwordRecoveryDeliveries';
let environment;

const timestamp = (offsetMs = 0) =>
  Timestamp.fromDate(new Date(Date.now() + offsetMs));

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await environment.cleanup();
});

beforeEach(async () => {
  await environment.clearFirestore();
  await seedBase();
});

function dbFor(uid, extraClaims = {}) {
  return environment.authenticatedContext(uid, extraClaims).firestore();
}

function anonymousDb(uid) {
  return dbFor(uid, {
    firebase: { sign_in_provider: 'anonymous' },
  });
}

async function seedBase() {
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const documents = [
      ['users/elder-1', {
        type: 'idoso',
        status: 'active',
        institutionId: 'institution-1',
        recoveryFamilyUid: 'family-1',
        recoveryCaregiverUid: 'caregiver-1',
      }],
      ['users/family-1', {
        type: 'family',
        status: 'active',
        institutionId: 'institution-1',
      }],
      ['users/family-2', {
        type: 'family',
        status: 'active',
        institutionId: 'institution-1',
      }],
      ['users/caregiver-1', {
        type: 'caregiver',
        status: 'active',
        institutionId: 'institution-1',
      }],
      ['users/caregiver-2', {
        type: 'caregiver',
        status: 'active',
        institutionId: 'institution-1',
      }],
      ['users/support-1', {
        type: 'support',
        status: 'active',
        institutionId: 'institution-1',
        name: 'Support',
      }],
      ['users/support-inactive', {
        type: 'support',
        status: 'inactive',
      }],
      ['familyLinks/elder-1_family-1', {
        elderId: 'elder-1',
        familiarId: 'family-1',
        institutionId: 'institution-1',
        status: 'active',
      }],
    ];
    for (const [documentPath, data] of documents) {
      await setDoc(doc(db, documentPath), data);
    }
  });
}

async function seedRequest(id, options = {}) {
  const {
    status = 'pending',
    familyDecision = 'pending',
    caregiverDecision = 'pending',
    approvedByUid,
    linkDeliveredToApprover = false,
    deliveryForwardedToElder = false,
    resetEmailRequested = false,
    resetEmailRequestedAt,
    resetEmailRequestedBy,
    resetEmailAttemptAt,
    resetEmailAttemptBy,
    createdAt = timestamp(-60_000),
    elderUid = 'elder-1',
    familyUid = 'family-1',
    caregiverUid = 'caregiver-1',
    requesterUid = 'anonymous-1',
  } = options;
  await environment.withSecurityRulesDisabled(async (context) => {
    const data = {
      requestId: id,
      lookupHash: 'a'.repeat(64),
      requesterUid,
      elderUid,
      institutionId: 'institution-1',
      familyUid,
      caregiverUid,
      status,
      familyDecision,
      caregiverDecision,
      linkDeliveredToApprover,
      deliveryForwardedToElder,
      resetEmailRequested,
      createdAt,
      ...(approvedByUid ? {
        approvedByUid,
        approvedByType: approvedByUid.startsWith('family')
          ? 'family'
          : 'caregiver',
      } : {}),
      ...(resetEmailRequestedAt ? { resetEmailRequestedAt } : {}),
      ...(resetEmailRequestedBy ? { resetEmailRequestedBy } : {}),
      ...(resetEmailAttemptAt ? { resetEmailAttemptAt } : {}),
      ...(resetEmailAttemptBy ? { resetEmailAttemptBy } : {}),
    };
    await setDoc(
      doc(context.firestore(), requestCollection, id),
      data,
    );
  });
}

async function seedDelivery(id, options = {}) {
  const {
    expiresAt = timestamp(60 * 60 * 1000),
    forwardedToElder = false,
    requesterUid = 'anonymous-1',
    recipientUid = 'family-1',
    elderUid = 'elder-1',
  } = options;
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), deliveryCollection, id), {
      requestId: id,
      recipientUid,
      requesterUid,
      elderUid,
      resetLink:
        'https://conviva-63d6a.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=opaque',
      forwardedToElder,
      createdAt: timestamp(-1_000),
      deliveryExpiresAt: expiresAt,
      forwardedAt: forwardedToElder ? timestamp(-500) : null,
    });
  });
}

function requestRef(db, id) {
  return doc(db, requestCollection, id);
}

function deliveryRef(db, id) {
  return doc(db, deliveryCollection, id);
}

test('elder can replace the selected caregiver using getAfter in the same batch', async () => {
  const elderDb = dbFor('elder-1');
  const batch = writeBatch(elderDb);
  batch.update(doc(elderDb, 'users', 'elder-1'), {
    recoveryCaregiverUid: 'caregiver-2',
  });
  batch.set(doc(elderDb, 'elderRecoveryLookups', 'b'.repeat(64)), {
    elderUid: 'elder-1',
    institutionId: 'institution-1',
    familyUid: 'family-1',
    caregiverUid: 'caregiver-2',
  });
  await assertSucceeds(batch.commit());
});

test('family approval wins while caregiver is pending', async () => {
  await seedRequest('family-approval');
  const familyDb = dbFor('family-1');
  await assertSucceeds(updateDoc(requestRef(familyDb, 'family-approval'), {
    status: 'approved',
    familyDecision: 'approved',
    familyRespondedAt: serverTimestamp(),
    approvedByUid: 'family-1',
    approvedByType: 'family',
  }));
  await assertFails(updateDoc(requestRef(familyDb, 'family-approval'), {
    status: 'rejected',
    familyDecision: 'rejected',
    familyRespondedAt: serverTimestamp(),
  }));
});

test('a caregiver rejection does not prevent family approval', async () => {
  await seedRequest('or-approval');
  const caregiverDb = dbFor('caregiver-1');
  const familyDb = dbFor('family-1');
  await assertSucceeds(updateDoc(requestRef(caregiverDb, 'or-approval'), {
    status: 'pending',
    caregiverDecision: 'rejected',
    caregiverRespondedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(requestRef(familyDb, 'or-approval'), {
    status: 'approved',
    familyDecision: 'approved',
    familyRespondedAt: serverTimestamp(),
    approvedByUid: 'family-1',
    approvedByType: 'family',
  }));
});

test('family rejection does not prevent caregiver approval', async () => {
  await seedRequest('family-rejects');
  const familyDb = dbFor('family-1');
  const caregiverDb = dbFor('caregiver-1');
  await assertSucceeds(updateDoc(requestRef(familyDb, 'family-rejects'), {
    status: 'pending',
    familyDecision: 'rejected',
    familyRespondedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(requestRef(caregiverDb, 'family-rejects'), {
    status: 'approved',
    caregiverDecision: 'approved',
    caregiverRespondedAt: serverTimestamp(),
    approvedByUid: 'caregiver-1',
    approvedByType: 'caregiver',
  }));
});

test('both responsible parties can reject, but one rejection remains pending', async () => {
  await seedRequest('joint-rejection');
  const familyDb = dbFor('family-1');
  const caregiverDb = dbFor('caregiver-1');
  await assertSucceeds(updateDoc(requestRef(familyDb, 'joint-rejection'), {
    status: 'pending',
    familyDecision: 'rejected',
    familyRespondedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(requestRef(caregiverDb, 'joint-rejection'), {
    status: 'rejected',
    caregiverDecision: 'rejected',
    caregiverRespondedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(requestRef(familyDb, 'joint-rejection'), {
    status: 'approved',
    familyDecision: 'approved',
    familyRespondedAt: serverTimestamp(),
    approvedByUid: 'family-1',
    approvedByType: 'family',
  }));
});

test('related users can list pending, approved-by-self, and jointly rejected requests', async () => {
  await seedRequest('pending-list');
  await seedRequest('approved-list', {
    status: 'approved',
    familyDecision: 'approved',
    approvedByUid: 'family-1',
  });
  await seedRequest('rejected-list', {
    status: 'rejected',
    familyDecision: 'rejected',
    caregiverDecision: 'rejected',
  });
  const familyDb = dbFor('family-1');
  await assertSucceeds(getDocs(query(
    collection(familyDb, requestCollection),
    where('familyUid', '==', 'family-1'),
    where('status', '==', 'pending'),
  )));
  await assertSucceeds(getDocs(query(
    collection(familyDb, requestCollection),
    where('approvedByUid', '==', 'family-1'),
    where('status', '==', 'approved'),
  )));
  await assertSucceeds(getDocs(query(
    collection(familyDb, requestCollection),
    where('familyUid', '==', 'family-1'),
    where('status', '==', 'rejected'),
  )));
  await assertSucceeds(getDocs(query(
    collection(dbFor('caregiver-1'), requestCollection),
    where('caregiverUid', '==', 'caregiver-1'),
    where('status', '==', 'rejected'),
  )));
  await assertFails(getDocs(query(
    collection(dbFor('family-2'), requestCollection),
    where('status', '==', 'rejected'),
  )));
});

test('changing selected contacts does not invalidate an existing request', async () => {
  await seedRequest('contact-change-family');
  await seedRequest('contact-change-caregiver');
  const elderDb = dbFor('elder-1');
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'familyLinks', 'elder-1_family-2'),
      {
        elderId: 'elder-1',
        familiarId: 'family-2',
        institutionId: 'institution-1',
        status: 'active',
      },
    );
  });
  const batch = writeBatch(elderDb);
  batch.update(doc(elderDb, 'users', 'elder-1'), {
    recoveryFamilyUid: 'family-2',
    recoveryCaregiverUid: 'caregiver-2',
  });
  batch.set(doc(elderDb, 'elderRecoveryLookups', 'b'.repeat(64)), {
    elderUid: 'elder-1',
    institutionId: 'institution-1',
    familyUid: 'family-2',
    caregiverUid: 'caregiver-2',
  });
  await assertSucceeds(batch.commit());

  await assertSucceeds(updateDoc(
    requestRef(dbFor('family-1'), 'contact-change-family'),
    {
      status: 'approved',
      familyDecision: 'approved',
      familyRespondedAt: serverTimestamp(),
      approvedByUid: 'family-1',
      approvedByType: 'family',
    },
  ));
  await assertSucceeds(updateDoc(
    requestRef(dbFor('caregiver-1'), 'contact-change-caregiver'),
    {
      status: 'approved',
      caregiverDecision: 'approved',
      caregiverRespondedAt: serverTimestamp(),
      approvedByUid: 'caregiver-1',
      approvedByType: 'caregiver',
    },
  ));
  await assertFails(updateDoc(
    requestRef(dbFor('family-2'), 'contact-change-caregiver'),
    {
      status: 'approved',
      familyDecision: 'approved',
      familyRespondedAt: serverTimestamp(),
      approvedByUid: 'family-2',
      approvedByType: 'family',
    },
  ));
  await assertFails(updateDoc(
    requestRef(dbFor('caregiver-2'), 'contact-change-caregiver'),
    {
      status: 'approved',
      caregiverDecision: 'approved',
      caregiverRespondedAt: serverTimestamp(),
      approvedByUid: 'caregiver-2',
      approvedByType: 'caregiver',
    },
  ));
});

test('revoked family links and inactive caregiver accounts cannot review requests', async () => {
  await seedRequest('revoked-family-link');
  await seedRequest('inactive-caregiver');
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await updateDoc(doc(db, 'familyLinks', 'elder-1_family-1'), {
      status: 'revoked',
    });
    await updateDoc(doc(db, 'users', 'caregiver-1'), {
      status: 'inactive',
    });
  });

  await assertFails(updateDoc(
    requestRef(dbFor('family-1'), 'revoked-family-link'),
    {
      status: 'approved',
      familyDecision: 'approved',
      familyRespondedAt: serverTimestamp(),
      approvedByUid: 'family-1',
      approvedByType: 'family',
    },
  ));
  await assertFails(updateDoc(
    requestRef(dbFor('caregiver-1'), 'inactive-caregiver'),
    {
      status: 'approved',
      caregiverDecision: 'approved',
      caregiverRespondedAt: serverTimestamp(),
      approvedByUid: 'caregiver-1',
      approvedByType: 'caregiver',
    },
  ));
});

test('lookup without both contacts cannot create a recovery request', async () => {
  const lookupHash = 'c'.repeat(64);
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'elderRecoveryLookups', lookupHash), {
      elderUid: 'elder-1',
      institutionId: 'institution-1',
      familyUid: null,
      caregiverUid: null,
    });
  });
  const requesterUid = 'anonymous-1';
  const anonymous = anonymousDb(requesterUid);
  const lookup = await getDoc(doc(anonymous, 'elderRecoveryLookups', lookupHash));
  assert.equal(lookup.data().familyUid, null);
  assert.equal(lookup.data().caregiverUid, null);

  const requestReference = doc(collection(anonymous, requestCollection));
  const proofReference = doc(
    anonymous,
    'passwordRecoveryProofs',
    requestReference.id,
  );
  const rateLimitReference = doc(
    anonymous,
    'passwordRecoveryRateLimits',
    lookupHash,
  );
  const batch = writeBatch(anonymous);
  batch.set(proofReference, {
    requestId: requestReference.id,
    lookupHash,
    requesterUid,
    elderUid: 'elder-1',
    institutionId: 'institution-1',
    familyUid: null,
    caregiverUid: null,
    createdAt: serverTimestamp(),
  });
  batch.set(requestReference, {
    requestId: requestReference.id,
    lookupHash,
    requesterUid,
    elderUid: 'elder-1',
    institutionId: 'institution-1',
    familyUid: null,
    caregiverUid: null,
    status: 'pending',
    familyDecision: 'pending',
    caregiverDecision: 'pending',
    linkDeliveredToApprover: false,
    deliveryForwardedToElder: false,
    resetEmailRequested: false,
    createdAt: serverTimestamp(),
  });
  batch.set(rateLimitReference, {
    elderUid: 'elder-1',
    requestId: requestReference.id,
    lastRequestedAt: serverTimestamp(),
  });
  await assertFails(batch.commit());
});

test('support cannot read or list personal user documents', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users', 'elder-other'), {
      type: 'idoso',
      status: 'active',
      institutionId: 'another-institution',
      elderLinkCode: 'ELD123456',
    });
  });
  const supportDb = dbFor('support-1');
  await assertSucceeds(getDoc(doc(supportDb, 'users', 'support-1')));
  await assertFails(getDoc(doc(supportDb, 'users', 'elder-other')));
  await assertFails(getDoc(doc(supportDb, 'users', 'elder-1')));
  await assertFails(getDoc(doc(supportDb, 'users', 'family-1')));
  await assertFails(getDocs(collection(supportDb, 'users')));
  await seedRequest('support-approved', {
    status: 'approved',
    familyDecision: 'approved',
    approvedByUid: 'family-1',
    elderUid: 'elder-1',
  });
  await assertSucceeds(getDocs(query(
    collection(supportDb, requestCollection),
    where('status', '==', 'approved'),
  )));
  await assertFails(getDocs(query(
    collection(dbFor('support-inactive'), requestCollection),
    where('status', '==', 'approved'),
  )));
});

test('support can mark an email attempt only once per five-minute interval', async () => {
  await seedRequest('email-attempt', { status: 'approved' });
  const supportDb = dbFor('support-1');
  await assertSucceeds(updateDoc(requestRef(supportDb, 'email-attempt'), {
    resetEmailAttemptAt: serverTimestamp(),
    resetEmailAttemptBy: 'support-1',
  }));
  await assertFails(updateDoc(requestRef(supportDb, 'email-attempt'), {
    resetEmailAttemptAt: serverTimestamp(),
    resetEmailAttemptBy: 'support-1',
  }));
});

test('successful email request can be recorded and old delivery removed', async () => {
  const lastSent = timestamp(-6 * 60 * 1000);
  await seedRequest('email-resend', {
    status: 'approved',
    approvedByUid: 'family-1',
    familyDecision: 'approved',
    linkDeliveredToApprover: true,
    resetEmailAttemptAt: lastSent,
    resetEmailAttemptBy: 'support-1',
    resetEmailRequestedAt: lastSent,
    resetEmailRequestedBy: 'support-1',
  });
  await seedDelivery('email-resend');
  const supportDb = dbFor('support-1');
  await assertSucceeds(updateDoc(requestRef(supportDb, 'email-resend'), {
    resetEmailAttemptAt: serverTimestamp(),
    resetEmailAttemptBy: 'support-1',
  }));

  const batch = writeBatch(supportDb);
  batch.update(requestRef(supportDb, 'email-resend'), {
    linkDeliveredToApprover: false,
    deliveryForwardedToElder: false,
    resetEmailRequested: true,
    resetEmailRequestedAt: serverTimestamp(),
    resetEmailRequestedBy: 'support-1',
    linkDeliveredAt: deleteField(),
  });
  batch.delete(deliveryRef(supportDb, 'email-resend'));
  await assertSucceeds(batch.commit());
  await environment.withSecurityRulesDisabled(async (context) => {
    const snapshot = await getDoc(
      deliveryRef(context.firestore(), 'email-resend'),
    );
    assert.equal(snapshot.exists(), false);
  });
});

test('support can deliver a valid link only after recording a successful email call', async () => {
  const requestedAt = timestamp(-30_000);
  await seedRequest('valid-delivery', {
    status: 'approved',
    familyDecision: 'approved',
    approvedByUid: 'family-1',
    resetEmailRequested: true,
    resetEmailRequestedAt: requestedAt,
    resetEmailRequestedBy: 'support-1',
  });
  const supportDb = dbFor('support-1');
  await assertFails(setDoc(deliveryRef(supportDb, 'valid-delivery'), {
    requestId: 'valid-delivery',
    recipientUid: 'family-1',
    requesterUid: 'anonymous-1',
    elderUid: 'elder-1',
    resetLink:
      'https://wrong-project.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=opaque',
    forwardedToElder: false,
    createdAt: serverTimestamp(),
    deliveryExpiresAt: timestamp(60 * 60 * 1000),
    forwardedAt: null,
  }));
  const batch = writeBatch(supportDb);
  batch.set(deliveryRef(supportDb, 'valid-delivery'), {
    requestId: 'valid-delivery',
    recipientUid: 'family-1',
    requesterUid: 'anonymous-1',
    elderUid: 'elder-1',
    resetLink:
      'https://conviva-63d6a.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=opaque',
    forwardedToElder: false,
    createdAt: serverTimestamp(),
    deliveryExpiresAt: timestamp(60 * 60 * 1000),
    forwardedAt: null,
  });
  batch.update(requestRef(supportDb, 'valid-delivery'), {
    linkDeliveredToApprover: true,
    linkDeliveredAt: serverTimestamp(),
    resetEmailRequested: false,
    resetEmailRequestedAt: deleteField(),
    resetEmailRequestedBy: deleteField(),
  });
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(deliveryRef(dbFor('family-1'), 'valid-delivery')));
  await assertFails(getDoc(deliveryRef(dbFor('family-2'), 'valid-delivery')));
  await assertFails(getDoc(deliveryRef(anonymousDb('anonymous-1'), 'valid-delivery')));
});

test('forwarding is limited to the approved, non-expired delivery and requester session', async () => {
  await seedRequest('forwarded', {
    status: 'approved',
    familyDecision: 'approved',
    approvedByUid: 'family-1',
    linkDeliveredToApprover: true,
  });
  await seedDelivery('forwarded');
  const familyDb = dbFor('family-1');
  const batch = writeBatch(familyDb);
  batch.update(deliveryRef(familyDb, 'forwarded'), {
    forwardedToElder: true,
    forwardedAt: serverTimestamp(),
  });
  batch.update(requestRef(familyDb, 'forwarded'), {
    deliveryForwardedToElder: true,
    deliveryForwardedAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(deliveryRef(anonymousDb('anonymous-1'), 'forwarded')));
  await assertSucceeds(getDoc(requestRef(anonymousDb('anonymous-1'), 'forwarded')));
  await assertFails(getDoc(deliveryRef(anonymousDb('anonymous-other'), 'forwarded')));
  await assertFails(getDoc(requestRef(anonymousDb('anonymous-other'), 'forwarded')));
  await assertFails(getDoc(requestRef(dbFor('family-2'), 'forwarded')));
  await assertFails(getDoc(deliveryRef(dbFor('family-2'), 'forwarded')));
  await assertFails(updateDoc(requestRef(dbFor('family-2'), 'forwarded'), {
    status: 'approved',
    familyDecision: 'approved',
    familyRespondedAt: serverTimestamp(),
    approvedByUid: 'family-2',
    approvedByType: 'family',
  }));
  await assertFails(getDoc(doc(anonymousDb('anonymous-1'), 'users', 'elder-1')));
});

test('approved request older than 24 hours can still read a live delivery', async () => {
  await seedRequest('old-approved', {
    status: 'approved',
    familyDecision: 'approved',
    approvedByUid: 'family-1',
    linkDeliveredToApprover: true,
    createdAt: timestamp(-25 * 60 * 60 * 1000),
  });
  await seedDelivery('old-approved', {
    expiresAt: timestamp(50 * 60 * 1000),
  });
  await assertSucceeds(
    getDoc(deliveryRef(dbFor('family-1'), 'old-approved')),
  );
});

test('expired deliveries are unreadable and cannot be forwarded by the requester', async () => {
  await seedRequest('expired-delivery', {
    status: 'approved',
    familyDecision: 'approved',
    approvedByUid: 'family-1',
    linkDeliveredToApprover: true,
  });
  await seedDelivery('expired-delivery', {
    expiresAt: timestamp(-1_000),
  });
  await assertFails(
    getDoc(deliveryRef(dbFor('family-1'), 'expired-delivery')),
  );
  await assertFails(
    getDoc(deliveryRef(anonymousDb('anonymous-1'), 'expired-delivery')),
  );
  await assertFails(
    deleteDoc(deliveryRef(anonymousDb('anonymous-1'), 'expired-delivery')),
  );
  const familyDb = dbFor('family-1');
  const batch = writeBatch(familyDb);
  batch.update(deliveryRef(familyDb, 'expired-delivery'), {
    forwardedToElder: true,
    forwardedAt: serverTimestamp(),
  });
  batch.update(requestRef(familyDb, 'expired-delivery'), {
    deliveryForwardedToElder: true,
    deliveryForwardedAt: serverTimestamp(),
  });
  await assertFails(batch.commit());
});

test('elder can clean up an already-forwarded request after 24 hours', async () => {
  await seedRequest('completion', {
    status: 'approved',
    familyDecision: 'approved',
    approvedByUid: 'family-1',
    linkDeliveredToApprover: true,
    deliveryForwardedToElder: true,
    createdAt: timestamp(-25 * 60 * 60 * 1000),
  });
  await seedDelivery('completion', { forwardedToElder: true });
  const elderDb = dbFor('elder-1');
  const completion = {
    status: 'completed',
    completedBy: 'elder-1',
    completedAt: serverTimestamp(),
  };
  await assertFails(updateDoc(requestRef(elderDb, 'completion'), completion));

  const batch = writeBatch(elderDb);
  batch.update(requestRef(elderDb, 'completion'), completion);
  batch.delete(deliveryRef(elderDb, 'completion'));
  await assertSucceeds(batch.commit());

  await environment.withSecurityRulesDisabled(async (context) => {
    const snapshot = await getDoc(
      deliveryRef(context.firestore(), 'completion'),
    );
    assert.equal(snapshot.exists(), false);
  });
});
