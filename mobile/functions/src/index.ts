import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const taskTimeZone = "America/Sao_Paulo";
const notificationChannelId = "conviva_notifications";

type NotificationKind = "message" | "task";
type NotificationContent = {
  type: NotificationKind;
  title: string;
  body: string;
  chatId?: string;
  elderId?: string;
};

type DeviceDocument = {
  token?: string;
};

type UserDocument = {
  institutionId?: string;
  status?: string;
  type?: string;
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
