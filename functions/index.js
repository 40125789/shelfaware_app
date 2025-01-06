const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();


// For expiry notifications
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
  
        // Send the push notification
        const notificationPayload = {
          notification: {
            title: "Food Expiry Reminder",
            body: `Your ${productName} is expiring soon!`,
          },
          data: {
            foodItemId: doc.id,
            expiryDate: expiryDate.toDate().toString(),
          },
          token: fcmToken,
        };
  
        await admin.messaging().send(notificationPayload);
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
    if (!receiverId || !message || !donationId || !donorName || !productName) return null;

    try {
      // Fetch the receiver's FCM token
      const receiverDoc = await db.collection("users").doc(receiverId).get();
      if (!receiverDoc.exists) return null;

      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcm_token;
      if (!fcmToken) return null;

      // Save message notification to Firestore, including the chatId and other data
      const notificationDoc = {
        userId: receiverId,
        type: 'message', // Type of notification
        title: "New Message",
        body: `${senderEmail}: ${message}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        chatId: context.params.chatId, // Store chatId from context
        donationId: donationId, // Store donationId from messageData
        donorName: donorName, // Store donorName from messageData
        productName: productName, // Store productName from messageData
      };
      await db.collection("notifications").add(notificationDoc);

      // Create notification payload for FCM
      const notificationPayload = {
        notification: {
          title: "New Message",
          body: `${senderEmail}: ${message}`,
        },
        data: {
          chatId: context.params.chatId, // Include chatId from context
          messageId: context.params.messageId, // Include messageId from context
          donationId: donationId, // Pass donationId
          donorName: donorName, // Pass donorName
          productName: productName, // Pass productName
        },
        token: fcmToken,
      };

      // Send the push notification
      await admin.messaging().send(notificationPayload);
    } catch (error) {
      console.error("Error sending message notification:", error);
    }

    return null;
  });

