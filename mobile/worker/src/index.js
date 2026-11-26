// Relé de push gratuito para o Conviva (Cloudflare Workers, plano Free).
//
// Fluxo: o app envia a mensagem ao Firestore e chama POST /notify-message com
// o ID token do Firebase Auth. Este Worker:
//   1. valida o token (assinatura, emissor, audiência, validade);
//   2. confere no Firestore que o remetente participa do chat e que a
//      mensagem é dele e é recente (impede push forjado ou reenviado);
//   3. envia o push FCM aos aparelhos do(s) outro(s) participante(s).

const FCM_CHANNEL_ID = 'conviva_notifications';
const MAX_MESSAGE_AGE_MS = 2 * 60 * 1000;
const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const ID_PATTERN = /^[A-Za-z0-9_.-]{1,200}$/;

let cachedJwks = null; // { keys, expiresAt }
let cachedAccessToken = null; // { value, expiresAt }

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method !== 'POST' || url.pathname !== '/notify-message') {
      return json({ error: 'not_found' }, 404);
    }

    try {
      const idToken = (request.headers.get('Authorization') ?? '')
        .replace(/^Bearer\s+/i, '')
        .trim();
      if (!idToken) return json({ error: 'unauthenticated' }, 401);

      const uid = await verifyIdToken(idToken, env.PROJECT_ID);
      if (!uid) return json({ error: 'unauthenticated' }, 401);

      const body = await request.json().catch(() => null);
      const chatId = body?.chatId;
      const messageId = body?.messageId;
      if (!ID_PATTERN.test(chatId ?? '') || !ID_PATTERN.test(messageId ?? '')) {
        return json({ error: 'bad_request' }, 400);
      }

      const result = await notifyMessage({ uid, chatId, messageId, env });
      return json(result.body, result.status);
    } catch (error) {
      console.error('notify-message failed', error);
      return json({ error: 'internal' }, 500);
    }
  },
};

// ---------------------------------------------------------------------------
// Regra de negócio
// ---------------------------------------------------------------------------

async function notifyMessage({ uid, chatId, messageId, env }) {
  const accessToken = await getAccessToken(env);
  const project = env.PROJECT_ID;

  const chat = await firestoreGet(
    project,
    accessToken,
    `chats/${enc(chatId)}`,
  );
  const participants = chat?.data.participants;
  if (!Array.isArray(participants) || !participants.includes(uid)) {
    return { status: 403, body: { error: 'forbidden' } };
  }

  const message = await firestoreGet(
    project,
    accessToken,
    `chats/${enc(chatId)}/messages/${enc(messageId)}`,
  );
  if (!message || message.data.senderId !== uid) {
    return { status: 403, body: { error: 'forbidden' } };
  }
  // createTime é do servidor: o cliente não consegue falsificar.
  if (Date.now() - Date.parse(message.createTime) > MAX_MESSAGE_AGE_MS) {
    return { status: 409, body: { error: 'message_too_old' } };
  }

  const senderName = String(chat.data.participantsData?.[uid]?.name ?? '').trim();
  const title = (senderName || 'Nova mensagem').slice(0, 120);
  const bodyText = previewFor(message.data);
  const notificationId = `message_${chatId}_${messageId}`;

  let sent = 0;
  for (const recipientId of participants.filter((id) => id !== uid)) {
    const prefs = await firestoreGet(
      project,
      accessToken,
      `users/${enc(recipientId)}/preferences/appSettings`,
    );
    if (prefs?.data.messageNotifications === false) continue;

    const devices = await firestoreList(
      project,
      accessToken,
      `users/${enc(recipientId)}/devices`,
    );
    for (const device of devices) {
      const token = device.data.token;
      if (typeof token !== 'string' || !token) continue;

      const outcome = await sendFcm(project, accessToken, {
        token,
        notification: { title, body: bodyText },
        data: { type: 'message', chatId, notificationId },
        android: {
          priority: 'HIGH',
          notification: { channel_id: FCM_CHANNEL_ID },
        },
      });

      if (outcome === 'ok') sent += 1;
      if (outcome === 'invalid_token') {
        // Aparelho que desinstalou o app: limpa o token morto.
        await firestoreDelete(project, accessToken, device.path);
      }
    }
  }

  return { status: 200, body: { sent } };
}

function previewFor(data) {
  if (data.type === 'image') return 'Você recebeu uma imagem.';
  if (data.type === 'audio') return 'Você recebeu uma mensagem de voz.';
  const text = String(data.text ?? '').trim();
  if (!text) return 'Nova mensagem.';
  return text.length > 120 ? `${text.slice(0, 117)}...` : text;
}

// ---------------------------------------------------------------------------
// Validação do ID token do Firebase Auth (sem chave de API)
// ---------------------------------------------------------------------------

async function verifyIdToken(idToken, projectId) {
  const parts = idToken.split('.');
  if (parts.length !== 3) return null;

  let header;
  let payload;
  try {
    header = JSON.parse(decodeText(parts[0]));
    payload = JSON.parse(decodeText(parts[1]));
  } catch {
    return null;
  }
  if (header.alg !== 'RS256' || !header.kid) return null;

  const now = Math.floor(Date.now() / 1000);
  if (
    payload.aud !== projectId ||
    payload.iss !== `https://securetoken.google.com/${projectId}` ||
    typeof payload.sub !== 'string' ||
    !payload.sub ||
    payload.exp <= now ||
    payload.iat > now + 300
  ) {
    return null;
  }

  const jwk = (await getJwks()).find((key) => key.kid === header.kid);
  if (!jwk) return null;

  const key = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    decodeBytes(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  return valid ? payload.sub : null;
}

async function getJwks() {
  if (cachedJwks && cachedJwks.expiresAt > Date.now()) return cachedJwks.keys;
  const response = await fetch(JWKS_URL);
  if (!response.ok) throw new Error(`jwks ${response.status}`);
  const { keys } = await response.json();
  cachedJwks = { keys, expiresAt: Date.now() + 60 * 60 * 1000 };
  return keys;
}

// ---------------------------------------------------------------------------
// Conta de serviço -> access token do Google
// ---------------------------------------------------------------------------

async function getAccessToken(env) {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) {
    return cachedAccessToken.value;
  }

  const account = JSON.parse(env.SERVICE_ACCOUNT_JSON);
  const now = Math.floor(Date.now() / 1000);
  const header = encodeText(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = encodeText(
    JSON.stringify({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/cloud-platform',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsigned = `${header}.${claims}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBytes(account.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${encodeBytes(new Uint8Array(signature))}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) throw new Error(`oauth ${response.status}`);

  const token = await response.json();
  cachedAccessToken = {
    value: token.access_token,
    expiresAt: Date.now() + token.expires_in * 1000,
  };
  return cachedAccessToken.value;
}

// ---------------------------------------------------------------------------
// Firestore (REST) e FCM v1
// ---------------------------------------------------------------------------

function documentsUrl(project) {
  return `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
}

async function firestoreGet(project, accessToken, path) {
  const response = await fetch(`${documentsUrl(project)}/${path}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`firestore get ${response.status}`);
  const document = await response.json();
  return {
    data: decodeFields(document.fields ?? {}),
    createTime: document.createTime,
  };
}

async function firestoreList(project, accessToken, path) {
  const response = await fetch(`${documentsUrl(project)}/${path}?pageSize=20`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (response.status === 404) return [];
  if (!response.ok) throw new Error(`firestore list ${response.status}`);
  const { documents = [] } = await response.json();
  return documents.map((document) => ({
    // "projects/x/databases/(default)/documents/<path>"
    path: document.name.split('/documents/')[1],
    data: decodeFields(document.fields ?? {}),
  }));
}

async function firestoreDelete(project, accessToken, path) {
  await fetch(`${documentsUrl(project)}/${path}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${accessToken}` },
  });
}

async function sendFcm(project, accessToken, message) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${project}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message }),
    },
  );
  if (response.ok) return 'ok';

  const text = await response.text();
  if (response.status === 404 || text.includes('UNREGISTERED')) {
    return 'invalid_token';
  }
  console.error('fcm send failed', response.status, text);
  return 'error';
}

function decodeValue(value) {
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  if ('arrayValue' in value) {
    return (value.arrayValue.values ?? []).map(decodeValue);
  }
  if ('mapValue' in value) return decodeFields(value.mapValue.fields ?? {});
  return undefined;
}

function decodeFields(fields) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, decodeValue(value)]),
  );
}

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

const enc = encodeURIComponent;

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function encodeBytes(bytes) {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function encodeText(text) {
  return encodeBytes(new TextEncoder().encode(text));
}

function decodeBytes(base64url) {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

function decodeText(base64url) {
  return new TextDecoder().decode(decodeBytes(base64url));
}

function pemToBytes(pem) {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  return Uint8Array.from(atob(body), (char) => char.charCodeAt(0));
}
