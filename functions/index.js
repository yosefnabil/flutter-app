const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const stringSimilarity = require("string-similarity");

initializeApp();
const db = getFirestore();

// إرسال الإشعارات بلغتين مع دعم click_action
async function sendNotification(uid, titleAr, titleEn, bodyAr, bodyEn, clickAction = null) {
  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.data();
  const token = userData?.fcmToken;
  const lang = userData?.language || "ar";

  if (!token) return;

  const title = lang === "en" ? titleEn : titleAr;
  const body = lang === "en" ? bodyEn : bodyAr;

  const message = {
    notification: { title, body },
    token,
  };

  if (clickAction) {
    message.webpush = {
      notification: {
        click_action: clickAction,
      },
    };
  }

  await getMessaging().send(message);

  await db.collection("users").doc(uid).collection("notifications").add({
    title,
    body,
    timestamp: FieldValue.serverTimestamp(),
    isRead: false,
  });
}

// 📩 إشعار عند إنشاء بلاغ جديد
exports.onNewReport = onDocumentCreated("reports/{reportId}", async (event) => {
  const data = event.data.data();

  if (data.type === "missing") {
    await sendNotification(
      data.userId,
      "📝 تم تسجيل بلاغ الفقد الخاص بك",
      "📝 Your Missing Report is Registered",
      `تم تسجيل بلاغ الفقد "${data.title}". سنقوم بالبحث ومتابعة حالته.`,
      `Your missing report "${data.title}" has been registered. We will keep you updated.`
    );
  } else if (data.type === "found") {
    await sendNotification(
      data.userId,
      "🛡️ تم تسجيل بلاغ العثور الخاص بك",
      "🛡️ Your Found Report is Registered",
      `تم تسجيل بلاغ العثور "${data.title}". سنعمل على مطابقته مع البلاغات المفقودة.`,
      `Your found report "${data.title}" has been registered. We will attempt to match it with missing reports.`
    );

    await sendNotification(
      data.userId,
      "📍 توجيه لتسليم الغرض",
      "📍 Proceed to Deliver the Item",
      "يرجى التوجه إلى مكتب المفقودات لتسليم الغرض الذي وجدته. يمكنك استخدام الخريطة للوصول إلينا بسهولة. نشكرك على أمانتك! 🤍",
      "Please proceed to the Lost and Found office to hand over the item you found. You can use the map to reach us easily. Thank you for your honesty! 🤍",
      "/map"
    );
  }
});

// 📩 إشعار عند تحديث حالة البلاغ
exports.onReportStatusUpdate = onDocumentUpdated("reports/{reportId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status !== after.status) {
    const statusMessages = {
      delivered_to_client: {
        ar: {
          title: "🎉 تم تسليم الغرض",
          body: "تم تسليم الغرض المفقود الخاص بك بنجاح. نرجو لك يومًا سعيدًا! 🤍",
        },
        en: {
          title: "🎉 Item Delivered",
          body: "Your lost item has been successfully delivered. Have a great day! 🤍",
        },
      },
      received: {
        ar: {
          title: "📥 تم استلام الغرض",
          body: "تم استلام الغرض منك بنجاح. نشكرك على أمانتك وتعاونك! 🌟",
        },
        en: {
          title: "📥 Item Received",
          body: "The item has been successfully received from you. Thank you for your honesty and cooperation! 🌟",
        },
      },
      matched: {
        ar: {
          title: "🎯 تأكيد التطابق",
          body: "تم تأكيد تطابق الغرض الذي فقدته! يرجى التوجه إلى مكتب المفقودات لاستلامه. 📍",
        },
        en: {
          title: "🎯 Match Confirmed",
          body: "The item matching your lost report has been confirmed! Please head to the Lost and Found office to collect it. 📍",
        },
      },
    };

    if (statusMessages[after.status]) {
      const msg = statusMessages[after.status];
      await sendNotification(
        after.userId,
        msg.ar.title,
        msg.en.title,
        msg.ar.body,
        msg.en.body,
        after.status === "matched" ? "/map" : null
      );
    } else {
      // الحالات الأخرى العامة
      const generalStatusMap = {
        processing: { ar: "قيد المعالجة", en: "Processing" },
        closed: { ar: "مغلق", en: "Closed" },
        rejected: { ar: "مرفوض", en: "Rejected" },
        delivered: { ar: "تم التسليم", en: "Delivered" },
      };

      await sendNotification(
        after.userId,
        "🔄 تحديث حالة البلاغ",
        "🔄 Report Status Updated",
        `تم تحديث حالة بلاغ "${after.title}" إلى ${generalStatusMap[after.status]?.ar || after.status}`,
        `Your report "${after.title}" status updated to ${generalStatusMap[after.status]?.en || after.status}`
      );
    }
  }
});

// 📩 إشعار المطابقة لصاحب بلاغ الفقد والعثور
exports.onMatchDetected = onDocumentCreated("matches/{matchId}", async (event) => {
  const data = event.data.data();
  const originalId = data.originalReportId;
  if (!originalId) return;

  const originalSnap = await db.collection("reports").doc(originalId).get();
  const originalData = originalSnap.data();

  if (originalData?.type === "missing") {
    await sendNotification(
      data.userId,
      "🎯 تم العثور على تطابق!",
      "🎯 Match Found!",
      `تم العثور على غرض مشابه لبلاغك "${data.title}".`,
      `A matching item has been found for your report "${data.title}".`
    );
  }

  const matchedSnap = await db.collection("reports").doc(data.matchedWith).get();
  const matchedData = matchedSnap.data();

  if (matchedData?.userId) {
    await sendNotification(
      matchedData.userId,
      "🎯 تطابق مع غرض مفقود!",
      "🎯 Matched with Missing Item!",
      "تم ربط الغرض الذي وجدته مع مالكه بنجاح! نشكرك على أمانتك 🤍",
      "The item you found has been successfully matched with its owner! Thank you for your honesty 🤍"
    );
  }
});

// 💬 باقي كود المطابقة كما هو... (matchReports و matchFromFoundReport)

// منطق المطابقة عند رفع بلاغ فقدان
exports.matchReports = onDocumentCreated("reports/{reportId}", async (event) => {
  const newReport = event.data.data();
  const reportId = event.params.reportId;
  if (newReport.type !== "missing") return;

  const snapshot = await db.collection("reports")
    .where("type", "==", "found")
    .where("status", "==", "processing")
    .where("category", "==", newReport.category)
    .where("color", "==", newReport.color)
    .where("location", "==", newReport.location)
    .get();

  if (!snapshot.empty) {
    snapshot.forEach(async (doc) => {
      const foundReport = doc.data();

      const score = stringSimilarity.compareTwoStrings(
        `${newReport.title?.toLowerCase()} ${newReport.description?.toLowerCase()}`,
        `${foundReport.title?.toLowerCase()} ${foundReport.description?.toLowerCase()}`
      );

      if (newReport.userId !== foundReport.userId && score > 0.4) {
        const exists = await db.collection("matches")
          .where("originalReportId", "==", reportId)
          .where("matchedWith", "==", doc.id)
          .get();

        if (exists.empty) {
          await db.collection("matches").add({
            title: newReport.title,
            userId: newReport.userId,
            matchedWith: doc.id,
            originalReportId: reportId,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }
});

// ✅ منطق المطابقة عند رفع بلاغ العثور (للسيناريو العكسي)
exports.matchFromFoundReport = onDocumentCreated("reports/{reportId}", async (event) => {
  const newReport = event.data.data();
  const reportId = event.params.reportId;
  if (newReport.type !== "found") return;

  const snapshot = await db.collection("reports")
    .where("type", "==", "missing")
    .where("status", "==", "processing")
    .where("category", "==", newReport.category)
    .where("color", "==", newReport.color)
    .where("location", "==", newReport.location)
    .get();

  if (!snapshot.empty) {
    snapshot.forEach(async (doc) => {
      const missingReport = doc.data();

      const score = stringSimilarity.compareTwoStrings(
        `${newReport.title?.toLowerCase()} ${newReport.description?.toLowerCase()}`,
        `${missingReport.title?.toLowerCase()} ${missingReport.description?.toLowerCase()}`
      );

      if (newReport.userId !== missingReport.userId && score > 0.4) {
        const exists = await db.collection("matches")
          .where("originalReportId", "==", doc.id)
          .where("matchedWith", "==", reportId)
          .get();

        if (exists.empty) {
          await db.collection("matches").add({
            title: missingReport.title,
            userId: missingReport.userId,
            matchedWith: reportId,
            originalReportId: doc.id,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }
});
