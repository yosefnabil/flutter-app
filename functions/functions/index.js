const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// إرسال إشعار للمستخدم
async function sendNotification(uid, title, body) {
  const userDoc = await admin.firestore().collection("users").doc(uid).get();
  const token = userDoc.data().fcmToken;
  if (!token) return;

  const message = {
    notification: { title, body },
    token,
  };

  await admin.messaging().send(message);

  // حفظ في مجموعة notifications
  await admin.firestore().collection("users").doc(uid).collection("notifications").add({
    title,
    body,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// عند إضافة بلاغ جديد
exports.onNewReport = functions.firestore
  .document("reports/{reportId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = "تم استلام بلاغك";
    const body = `تم استلام بلاغ ${data.title} وجاري معالجته.`;
    await sendNotification(data.userId, title, body);
  });

// عند تحديث حالة البلاغ
exports.onReportStatusUpdate = functions.firestore
  .document("reports/{reportId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== after.status) {
      const statusMap = {
        processing: "قيد المعالجة",
        matched: "تم العثور على تطابق",
        delivered: "تم التسليم",
        closed: "مغلق",
        rejected: "مرفوض",
      };

      const statusText = statusMap[after.status] || after.status;
      const title = "تحديث حالة البلاغ";
      const body = `تم تحديث حالة بلاغ ${after.title} إلى ${statusText}`;
      await sendNotification(after.userId, title, body);
    }
  });

// إشعار عند وجود تطابق
exports.onMatchDetected = functions.firestore
  .document("matches/{matchId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = "🔔 تم العثور على تطابق!";
    const body = `تم العثور على غرض مشابه لبلاغك: ${data.title}`;
    await sendNotification(data.userId, title, body);
  });

// إشعار عند تأكيد التسليم
exports.onDeliveryConfirmed = functions.firestore
  .document("reports/{reportId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "delivered" && after.status === "delivered") {
      const title = "✅ تم تسليم الغرض";
      const body = `تم تأكيد استلامك للغرض ${after.title}.`;
      await sendNotification(after.userId, title, body);
    }
  });
