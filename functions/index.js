const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendExpiryNotifications = functions.pubsub.schedule("every 24 hours").onRun(async () => {
  const db = admin.firestore();
  const currentDate = admin.firestore.Timestamp.now();
  const oneDayAhead = admin.firestore.Timestamp.fromMillis(currentDate.toMillis() + 24 * 60 * 60 * 1000);

  try {
    const foodItemsSnapshot = await db.collection("foodItems")
      .where("expiryDate", "<=", oneDayAhead)
      .where("expiryDate", ">=", currentDate)
      .get();

    if (foodItemsSnapshot.empty) return null;

    const messaging = admin.messaging();

    foodItemsSnapshot.forEach(async (doc) => {
      const foodItem = doc.data();
      const { userId, productName, expiryDate } = foodItem;

      if (!userId || !productName || !expiryDate) return;

      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const fcmToken = userData.fcm_token;
      if (!fcmToken) return;

      // Save notification to Firestore
      const notificationDoc = {
        userId,
        type: 'expiry', // Type of notification
        title: "Food Expiry Reminder",
        body: `Your ${productName} is expiring soon!`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      };
      await db.collection("notifications").add(notificationDoc);

      // Send the push notification using v1 payload
      const message = {
        token: fcmToken,
        notification: {
          title: "Food Expiry Reminder",
          body: `Your ${productName} is expiring soon!`,
        },
        data: {
          foodItemId: doc.id,
          expiryDate: expiryDate.toDate().toISOString(),
        },
      };

      await messaging.send(message);
    });
  } catch (error) {
    console.error("Error sending expiry notifications:", error);
  }
});

  
  exports.sendMessageNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const db = admin.firestore();
    const messageData = snapshot.data();

    if (!messageData) return null;

    const { receiverId, senderEmail, message, donationId, donorName, productName } = messageData;

    try {
      // Fetch the receiver's FCM token
      const receiverDoc = await db.collection("users").doc(receiverId).get();
      if (!receiverDoc.exists) return null;

      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcm_token;
      if (!fcmToken) return null;

      // Save message notification to Firestore
      const notificationDoc = {
        userId: receiverId,
        type: 'message', // Type of notification
        title: "New Message",
        body: `${senderEmail}: ${message}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        chatId: context.params.chatId,
      };
      await db.collection("notifications").add(notificationDoc);

      // Create v1 notification payload
      const messagePayload = {
        token: fcmToken,
        notification: {
          title: "New Message",
          body: `${senderEmail}: ${message}`,
        },
        data: {
          chatId: context.params.chatId,
          messageId: context.params.messageId,
          donationId: donationId || "",
          donorName: donorName || "",
          productName: productName || "",
        },
      };

      const messaging = admin.messaging();
      const response = await messaging.send(messagePayload);
      console.log("Successfully sent message:", response);
      return null;
    } catch (error) {
      console.error("Error processing message notification:", error);
      return null;
    }
  });
