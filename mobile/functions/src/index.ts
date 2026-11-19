import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {
  FieldValue,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {createHash, randomBytes} from "node:crypto";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const taskTimeZone = "America/Sao_Paulo";
const notificationChannelId = "conviva_notifications";

type NotificationKind = "message" | "task" | "password_reset";
type NotificationContent = {
  type: NotificationKind;
  title: string;
  body: string;
  chatId?: string;
  elderId?: string;
  elderName?: string;
  requestId?: string;
};

type DeviceDocument = {
  token?: string;
};

type UserDocument = {
  institutionId?: string;
  status?: string;
  type?: string;
  name?: string;
};

export const notifyNewChatMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const chatId = event.params.chatId;
    const chatSnapshot = await db.collection("chats").doc(chatId).get();
    const chat = chatSnapshot.data();
    if (!chatSnapshot.exists || !chat) return;

    const senderId = message.senderId?.toString();
    const participants = Array.isArray(chat.participants)
      ? chat.participants.map((participant: unknown) => String(participant))
      : [];
    if (!senderId || !participants.includes(senderId)) return;

    const participantsData = chat.participantsData ?? {};
    const senderName =
      participantsData[senderId]?.name?.toString().trim() ||
      "Nova mensagem";
    const body = messagePreview(message);
    const recipients = participants.filter((participant) => participant !== senderId);

    await Promise.all(
      recipients.map(async (recipientId) => {
        const [userSnapshot, preferencesSnapshot] = await Promise.all([
          db.collection("users").doc(recipientId).get(),
          db.collection("users").doc(recipientId)
            .collection("preferences").doc("appSettings").get(),
        ]);
        const user = userSnapshot.data() as UserDocument | undefined;
        if (
          !userSnapshot.exists ||
          user?.status !== "active" ||
          preferencesSnapshot.data()?.messageNotifications === false
        ) {
          return;
        }

        await storeAndSendNotification(
          recipientId,
          `message_${chatId}_${event.params.messageId}`,
          {
            type: "message",
            title: senderName,
            body,
            chatId,
          },
        );
      }),
    );
  },
);

export const notifyDueRoutineTasks = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: taskTimeZone,
    memory: "256MiB",
  },
  async () => {
    const now = new Date();
    const recentOneOffTasks = await db.collectionGroup("tasks")
      .where("repeatWeekly", "==", false)
      .where(
        "startAt",
        ">",
        Timestamp.fromDate(new Date(now.getTime() - 3 * 60_000)),
      )
      .where("startAt", "<=", Timestamp.fromDate(now))
      .get();
    const repeatingTasks = await db.collectionGroup("tasks")
      .where("repeatWeekly", "==", true)
      .get();

    for (const taskDocument of [
      ...recentOneOffTasks.docs,
      ...repeatingTasks.docs,
    ]) {
      const task = taskDocument.data();
      const elderId = taskDocument.ref.parent.parent?.id;
      const startAt = task.startAt;
      if (
        !elderId ||
        !(startAt instanceof Timestamp) ||
        !isTaskDue(task, startAt.toDate(), now)
      ) {
        continue;
      }

      const occurrenceDate = getOccurrenceDate(task, startAt.toDate(), now);
      if (!occurrenceDate) continue;

      const recurring = task.repeatWeekly === true;
      const completionId = recurring
        ? `${task.taskId}_${occurrenceDate}`
        : String(task.taskId ?? taskDocument.id);
      const completion = await db.collection("routines").doc(elderId)
        .collection("completions").doc(completionId).get();
      if (completion.exists) continue;

      const elderSnapshot = await db.collection("users").doc(elderId).get();
      const elder = elderSnapshot.data() as UserDocument | undefined;
      if (
        !elderSnapshot.exists ||
        elder?.status !== "active" ||
        !elder.institutionId
      ) {
        continue;
      }

      const recipientIds = await getTaskRecipientIds(elderId, elder.institutionId);
      const taskId = String(task.taskId ?? taskDocument.id);
      const notificationId = `task_${taskId}_${occurrenceDate}`;
      const title = "Hora da tarefa";
      const body = `Está na hora de ${String(task.title ?? "uma tarefa")}.`;

      await Promise.all(
        recipientIds.map(async (recipientId) => {
          const [userSnapshot, preferencesSnapshot] = await Promise.all([
            db.collection("users").doc(recipientId).get(),
            db.collection("users").doc(recipientId)
              .collection("preferences").doc("appSettings").get(),
          ]);
          const user = userSnapshot.data() as UserDocument | undefined;
          if (
            !userSnapshot.exists ||
            user?.status !== "active" ||
            preferencesSnapshot.data()?.reminderNotifications === false
          ) {
            return;
          }

          await storeAndSendNotification(recipientId, notificationId, {
            type: "task",
            title,
            body,
            elderId,
          });
        }),
      );
    }
  },
);

export const requestElderPasswordReset = onCall(async (request) => {
  const code = normalizeElderCode(request.data?.code);
  if (!/^ELD[A-Z0-9]{4,}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Informe um código ELD válido.");
  }

  const matches = await db.collection("users")
    .where("type", "==", "idoso")
    .where("elderLinkCode", "==", code)
    .limit(2)
    .get();
  if (matches.size !== 1) {
    throw new HttpsError(
      "not-found",
      "Não foi possível localizar uma conta com esse código.",
    );
  }

  const elderDocument = matches.docs[0];
  const elder = elderDocument.data() as UserDocument;
  if (elder.status !== "active" || !elder.institutionId) {
    throw new HttpsError(
      "failed-precondition",
      "A conta não está disponível para redefinição.",
    );
  }

  const recipientIds = await getPasswordResetRecipientIds(
    elderDocument.id,
    elder.institutionId,
  );
  if (recipientIds.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Não há familiar ou cuidador disponível para receber o pedido.",
    );
  }

  const requestId = db.collection("passwordResetRequests").doc().id;
  const requestReference = db.collection("passwordResetRequests").doc(requestId);
  const token = randomBytes(32).toString("hex");
  const now = Date.now();
  const throttleReference = db.collection("passwordResetRateLimits")
    .doc(sha256(code));

  await db.runTransaction(async (transaction) => {
    const throttleSnapshot = await transaction.get(throttleReference);
    const lastRequestedAt = throttleSnapshot.data()?.lastRequestedAt;
    if (
      lastRequestedAt instanceof Timestamp &&
      now - lastRequestedAt.toMillis() < 5 * 60_000
    ) {
      throw new HttpsError(
        "resource-exhausted",
        "Aguarde alguns minutos antes de enviar outro pedido.",
      );
    }

    transaction.create(requestReference, {
      elderId: elderDocument.id,
      elderName: elder.name?.trim() || "O idoso",
      institutionId: elder.institutionId,
      status: "pending",
      tokenHash: sha256(token),
      createdAt: Timestamp.fromMillis(now),
      expiresAt: Timestamp.fromMillis(now + 15 * 60_000),
    });
    transaction.set(throttleReference, {
      lastRequestedAt: Timestamp.fromMillis(now),
    });
  });

  const elderName = elder.name?.trim() || "O idoso";
  const notificationContent: NotificationContent = {
    type: "password_reset",
    title: "Pedido de troca de senha",
    body: `${elderName} pediu para redefinir a senha.`,
    elderId: elderDocument.id,
    elderName,
    requestId,
  };
  await Promise.all(
    recipientIds.map(async (recipientId) => {
      try {
        await storeAndSendNotification(
          recipientId,
          `password_reset_${requestId}`,
          notificationContent,
        );
      } catch (error) {
        console.error(
          `Falha ao notificar ${recipientId} sobre redefinição de senha:`,
          error,
        );
      }
    }),
  );

  return {requestId, token};
});

export const getElderPasswordResetStatus = onCall(async (request) => {
  const {requestId, token} = readResetCredentials(request.data);
  const resetSnapshot = await db.collection("passwordResetRequests")
    .doc(requestId)
    .get();
  const reset = resetSnapshot.data();
  if (!resetSnapshot.exists || reset?.tokenHash !== sha256(token)) {
    throw new HttpsError("permission-denied", "A solicitação não é válida.");
  }

  const isExpired = !(reset.expiresAt instanceof Timestamp) ||
    reset.expiresAt.toMillis() <= Date.now();
  if (reset.status === "approved" && !isExpired) {
    return {status: "approved"};
  }
  if (reset.status === "pending" && !isExpired) {
    return {status: "pending"};
  }
  return {status: "closed"};
});

export const respondToElderPasswordReset = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "Entre na sua conta para continuar.");
  }

  const requestId = readString(request.data?.requestId, "Pedido");
  const approve = request.data?.approve;
  if (typeof approve !== "boolean") {
    throw new HttpsError("invalid-argument", "A resposta não é válida.");
  }

  const resetReference = db.collection("passwordResetRequests").doc(requestId);
  const userReference = db.collection("users").doc(userId);
  await db.runTransaction(async (transaction) => {
    const [resetSnapshot, userSnapshot] = await Promise.all([
      transaction.get(resetReference),
      transaction.get(userReference),
    ]);
    const reset = resetSnapshot.data();
    const user = userSnapshot.data() as UserDocument | undefined;
    if (
      !resetSnapshot.exists ||
      reset?.status !== "pending" ||
      !(reset.expiresAt instanceof Timestamp) ||
      reset.expiresAt.toMillis() <= Date.now()
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Este pedido já foi respondido ou expirou.",
      );
    }
    if (!userSnapshot.exists || user?.status !== "active") {
      throw new HttpsError("permission-denied", "Conta sem permissão.");
    }

    if (user.type === "caregiver") {
      if (user.institutionId !== reset.institutionId) {
        throw new HttpsError("permission-denied", "Conta sem permissão.");
      }
    } else if (user.type === "family") {
      const linkReference = db.collection("familyLinks")
        .doc(`${reset.elderId}_${userId}`);
      const linkSnapshot = await transaction.get(linkReference);
      const link = linkSnapshot.data();
      if (
        !linkSnapshot.exists ||
        link?.status !== "active" ||
        link?.elderId !== reset.elderId ||
        link?.familiarId !== userId ||
        link?.institutionId !== reset.institutionId
      ) {
        throw new HttpsError("permission-denied", "Conta sem permissão.");
      }
    } else {
      throw new HttpsError("permission-denied", "Conta sem permissão.");
    }

    transaction.update(resetReference, {
      status: approve ? "approved" : "rejected",
      respondedBy: userId,
      respondedAt: FieldValue.serverTimestamp(),
    });
  });

  return {success: true};
});

export const completeElderPasswordReset = onCall(async (request) => {
  const {requestId, token} = readResetCredentials(request.data);
  const newPassword = request.data?.newPassword;
  if (
    typeof newPassword !== "string" ||
    newPassword.length < 6 ||
    newPassword.length > 4096
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A senha deve ter pelo menos 6 caracteres.",
    );
  }

  const resetReference = db.collection("passwordResetRequests").doc(requestId);
  const elderId = await db.runTransaction(async (transaction) => {
    const resetSnapshot = await transaction.get(resetReference);
    const reset = resetSnapshot.data();
    if (
      !resetSnapshot.exists ||
      reset?.tokenHash !== sha256(token) ||
      reset.status !== "approved" ||
      !(reset.expiresAt instanceof Timestamp) ||
      reset.expiresAt.toMillis() <= Date.now()
    ) {
      throw new HttpsError(
        "failed-precondition",
        "A aprovação expirou ou não está mais disponível.",
      );
    }

    transaction.update(resetReference, {status: "completing"});
    return readString(reset.elderId, "Idoso");
  });

  try {
    await getAuth().updateUser(elderId, {password: newPassword});
    await resetReference.update({
      status: "completed",
      tokenHash: FieldValue.delete(),
      completedAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    await resetReference.update({status: "approved"});
    console.error("Falha ao concluir redefinição de senha:", error);
    throw new HttpsError("internal", "Não foi possível trocar a senha.");
  }

  return {success: true};
});

function messagePreview(message: FirebaseFirestore.DocumentData): string {
  switch (message.type) {
  case "image":
    return "Você recebeu uma imagem.";
  case "audio":
    return "Você recebeu uma mensagem de voz.";
  default: {
    const text = String(message.text ?? "").trim();
    return text.length > 120 ? `${text.slice(0, 117)}...` : text || "Nova mensagem.";
  }
  }
}

function normalizeElderCode(value: unknown): string {
  return typeof value === "string"
    ? value.trim().toUpperCase().replace(/[^A-Z0-9]/g, "")
    : "";
}

function readString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${label} não foi informado.`);
  }
  return value.trim();
}

function readResetCredentials(value: unknown): {
  requestId: string;
  token: string;
} {
  if (typeof value !== "object" || value === null) {
    throw new HttpsError("invalid-argument", "A solicitação não é válida.");
  }
  const data = value as Record<string, unknown>;
  return {
    requestId: readString(data.requestId, "Pedido"),
    token: readString(data.token, "Token"),
  };
}

function sha256(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

async function getPasswordResetRecipientIds(
  elderId: string,
  institutionId: string,
): Promise<string[]> {
  const [caregivers, familyLinks] = await Promise.all([
    db.collection("users")
      .where("institutionId", "==", institutionId)
      .where("type", "==", "caregiver")
      .where("status", "==", "active")
      .get(),
    db.collection("familyLinks")
      .where("elderId", "==", elderId)
      .where("status", "==", "active")
      .get(),
  ]);
  const recipientIds = new Set(caregivers.docs.map((document) => document.id));
  const familyRecipientIds = await Promise.all(
    familyLinks.docs.map(async (link) => {
      const data = link.data();
      const familyId = data.familiarId;
      if (
        data.receiveNotifications === false ||
        typeof familyId !== "string"
      ) {
        return null;
      }

      const familySnapshot = await db.collection("users").doc(familyId).get();
      const family = familySnapshot.data() as UserDocument | undefined;
      return familySnapshot.exists &&
          family?.type === "family" &&
          family.status === "active" &&
          family.institutionId === institutionId
        ? familyId
        : null;
    }),
  );
  for (const familyId of familyRecipientIds) {
    if (familyId) recipientIds.add(familyId);
  }
  return [...recipientIds];
}

async function getTaskRecipientIds(
  elderId: string,
  institutionId: string,
): Promise<string[]> {
  const [caregivers, familyLinks] = await Promise.all([
    db.collection("users").where("institutionId", "==", institutionId).get(),
    db.collection("familyLinks").where("elderId", "==", elderId).get(),
  ]);
  const recipientIds = new Set<string>([elderId]);

  for (const caregiver of caregivers.docs) {
    const data = caregiver.data() as UserDocument;
    if (data.type === "caregiver" && data.status === "active") {
      recipientIds.add(caregiver.id);
    }
  }

  for (const link of familyLinks.docs) {
    const data = link.data();
    if (
      data.status === "active" &&
      data.receiveNotifications !== false &&
      typeof data.familiarId === "string"
    ) {
      recipientIds.add(data.familiarId);
    }
  }

  return [...recipientIds];
}

async function storeAndSendNotification(
  userId: string,
  notificationId: string,
  content: NotificationContent,
): Promise<void> {
  const reference = db.collection("users").doc(userId)
    .collection("notifications").doc(notificationId);

  const shouldSend = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(reference);
    if (existing.exists) {
      return existing.data()?.pushSent !== true;
    }

    transaction.create(reference, {
      ...content,
      read: false,
      pushSent: false,
      createdAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!shouldSend) return;

  try {
    await sendPush(userId, notificationId, content);
    await reference.update({pushSent: true});
  } catch (error) {
    await reference.update({pushSent: false});
    throw error;
  }
}

async function sendPush(
  userId: string,
  notificationId: string,
  content: NotificationContent,
): Promise<void> {
  const devices = await db.collection("users").doc(userId)
    .collection("devices").get();
  const tokens = devices.docs
    .flatMap((document) => {
      const token = (document.data() as DeviceDocument).token;
      return typeof token === "string" && token.length > 0
        ? [{document, token}]
        : [];
    });
  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens: tokens.map((device) => device.token),
    notification: {
      title: content.title,
      body: content.body,
    },
    data: {
      notificationId,
      type: content.type,
      ...(content.chatId ? {chatId: content.chatId} : {}),
      ...(content.elderId ? {elderId: content.elderId} : {}),
      ...(content.requestId ? {requestId: content.requestId} : {}),
      ...(content.elderName ? {elderName: content.elderName} : {}),
    },
    android: {
      priority: "high",
      notification: {channelId: notificationChannelId},
    },
  });

  const invalidTokens = response.responses.flatMap((result, index) => {
    const code = result.error?.code;
    return code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
      ? [tokens[index].document.ref]
      : [];
  });
  await Promise.all(invalidTokens.map((reference) => reference.delete()));
}

function isTaskDue(
  task: FirebaseFirestore.DocumentData,
  startAt: Date,
  now: Date,
): boolean {
  if (task.repeatWeekly !== true) {
    const minutesSinceStart = (now.getTime() - startAt.getTime()) / 60_000;
    return minutesSinceStart >= 0 && minutesSinceStart < 3;
  }

  const weekdays = Array.isArray(task.repeatWeekdays)
    ? task.repeatWeekdays.map(Number)
    : [];
  for (let elapsedMinute = 0; elapsedMinute < 3; elapsedMinute++) {
    const occurrence = new Date(now.getTime() - elapsedMinute * 60_000);
    const occurrenceParts = dateParts(occurrence);
    const startParts = dateParts(startAt);
    if (
      dateKey(occurrenceParts) >= dateKey(startParts) &&
      Number(occurrenceParts.hour) === Number(startParts.hour) &&
      Number(occurrenceParts.minute) === Number(startParts.minute) &&
      weekdays.includes(weekdayNumber(occurrenceParts.weekday))
    ) {
      return true;
    }
  }
  return false;
}

function getOccurrenceDate(
  task: FirebaseFirestore.DocumentData,
  startAt: Date,
  now: Date,
): string | null {
  if (task.repeatWeekly !== true) return dateKey(dateParts(startAt));

  const weekdays = Array.isArray(task.repeatWeekdays)
    ? task.repeatWeekdays.map(Number)
    : [];
  const startParts = dateParts(startAt);
  for (let elapsedMinute = 0; elapsedMinute < 3; elapsedMinute++) {
    const occurrenceParts = dateParts(
      new Date(now.getTime() - elapsedMinute * 60_000),
    );
    if (
      dateKey(occurrenceParts) >= dateKey(startParts) &&
      Number(occurrenceParts.hour) === Number(startParts.hour) &&
      Number(occurrenceParts.minute) === Number(startParts.minute) &&
      weekdays.includes(weekdayNumber(occurrenceParts.weekday))
    ) {
      return dateKey(occurrenceParts);
    }
  }
  return null;
}

function dateParts(date: Date): Record<string, string> {
  return Object.fromEntries(
    new Intl.DateTimeFormat("en-US", {
      timeZone: taskTimeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23",
    }).formatToParts(date)
      .filter((part) => part.type !== "literal")
      .map((part) => [part.type, part.value]),
  );
}

function weekdayNumber(weekday: string): number {
  return ({
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
    Sun: 7,
  } as Record<string, number>)[weekday] ?? 0;
}

function dateKey(parts: Record<string, string>): string {
  return `${parts.year}${parts.month}${parts.day}`;
}
