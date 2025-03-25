const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { Storage } = require('@google-cloud/storage');
const vision = require('@google-cloud/vision');
const storage = new Storage();
const { ImageAnnotatorClient } = require('@google-cloud/vision');
const client = new ImageAnnotatorClient();
const fs = require('fs');
const os = require('os');
const path = require('path');
const sharp = require('sharp');



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

exports.sendExpiredItemNotifications = functions.pubsub.schedule("every 24 hours").onRun(async () => {
  const db = admin.firestore();

  // Get the current date and calculate yesterday's date at midnight
  const currentDate = new Date();
  currentDate.setHours(0, 0, 0, 0); // Set time to midnight (00:00:00)
  const yesterday = new Date(currentDate);
  yesterday.setDate(currentDate.getDate() - 1); // Get yesterday's date

  // Convert yesterday's date to Firestore Timestamp
  const yesterdayTimestamp = admin.firestore.Timestamp.fromDate(yesterday);

  try {
    // Query items where expiry date is before yesterday's date (fully passed)
    const expiredItemsSnapshot = await db.collection("foodItems")
      .where("expiryDate", "<", yesterdayTimestamp) // Only items where expiry date has fully passed
      .get();

    if (expiredItemsSnapshot.empty) return null;

    const messaging = admin.messaging();

    expiredItemsSnapshot.forEach(async (doc) => {
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
        title: "Expired Food Alert",
        body: `Your ${productName} has expired! Consider discarding it safely.`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      };
      await db.collection("notifications").add(notificationDoc);

      // Send the push notification
      const message = {
        token: fcmToken,
        notification: {
          title: "Expired Food Alert",
          body: `Your ${productName} has expired! Consider discarding it safely.`,
        },
        data: {
          foodItemId: doc.id,
          expiryDate: expiryDate.toDate().toISOString(),
        },
      };

      await messaging.send(message);
    });
  } catch (error) {
    console.error("Error sending expired item notifications:", error);
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
    // Fetch the receiver's FCM token and notification preferences
    const receiverDoc = await db.collection("users").doc(receiverId).get();
    if (!receiverDoc.exists) return null;

    const receiverData = receiverDoc.data();
    const fcmToken = receiverData.fcm_token;
    const notificationPreferences = receiverData.notificationPreferences;

    // Check if message notifications are enabled
    if (!fcmToken || !notificationPreferences || !notificationPreferences.messages) {
      return null; // Don't send notification if it's not enabled in preferences
    }

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

 

  exports.sendDonationRequestNotification = functions.firestore
  .document('donationRequests/{requestId}')
  .onCreate(async (snapshot, context) => {
      const requestData = snapshot.data();

      if (!requestData || !requestData.donatorId || !requestData.requesterId || !requestData.productName) {
          console.log("Missing necessary data.");
          return null;
      }

      try {
          // Extract necessary fields from the donation request
          const { 
              donatorId, 
              productName, 
              donorImageUrl, 
              requesterId, 
              requesterProfileImageUrl, 
              imageUrl,
              message 
          } = requestData;

          // Fetch donor's document from Firestore
          const donorDoc = await admin.firestore()
              .collection('users')
              .doc(donatorId)
              .get();

          if (!donorDoc.exists || !donorDoc.data().fcm_token) {
              console.log("FCM token not found for donor.");
              return null;
          }

          // Fetch the donor's notification preferences
          const donatorPreferences = donorDoc.data().notificationPreferences || {};

          // Check if the donor has enabled request notifications
          if (donatorPreferences.requests === false) {
              console.log("Donor has disabled request notifications.");
              return null;
          }

          const fcmToken = donorDoc.data().fcm_token;

          // Fetch the requester's document from Firestore to get their first name
          const requesterDoc = await admin.firestore()
              .collection('users')
              .doc(requesterId)
              .get();

          if (!requesterDoc.exists) {
              console.log("Requester document not found.");
              return null;
          }

          const requesterFirstName = requesterDoc.data().firstName;

          // Notification message
          const notificationMessage = {
              notification: {
                  title: `New Request for ${productName} from ${requesterFirstName}`,
                  body: `Message: ${message}`,
                  image: imageUrl
              },
              token: fcmToken,
              data: {
                  requestId: context.params.requestId,
                  requesterId: requesterId,
                  requesterFirstName: requesterFirstName, 
                  requesterProfileImageUrl: requesterProfileImageUrl,
                  donorImageUrl: donorImageUrl,
                  productName: productName,
                  message: message,
                  imageUrl: imageUrl || "",
                  pickupDateTime: requestData.pickupDateTime.toDate().toISOString()
              }
          };

          // Send the notification if the user has the correct preference
          await admin.messaging().send(notificationMessage);
          console.log(`Notification sent successfully to donor: ${donatorId}`);

          // Add a document to the notifications collection with type "request"
          const notificationDoc = {
              type: "request",
              donatorId: donatorId,
              requesterId: requesterId,
              productName: productName,
              message: message,
              title: `New Request for ${productName} from ${requesterFirstName}`,
              body: `Message: ${message}`,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              read: false,
              pickupDateTime: requestData.pickupDateTime.toDate().toISOString(),
              donorImageUrl: donorImageUrl,
              requesterProfileImageUrl: requesterProfileImageUrl,
              userId: donatorId,
          };

          await admin.firestore().collection('notifications').add(notificationDoc);
          console.log("Notification document added to the 'notifications' collection.");

      } catch (error) {
          console.error("Error sending notification:", error);
      }

      return null;
  });


    exports.updateDonorAverageRating = functions.firestore
  .document("reviews/{reviewId}")
  .onWrite(async (change, context) => {
    const newValue = change.after.exists ? change.after.data() : null;
    const donorId = newValue ? newValue.donorId : null;

    if (!donorId) return null;

    try {
      const reviewsSnapshot = await admin.firestore()
        .collection("reviews")
        .where("donorId", "==", donorId)
        .get();

      let totalCommunicationRating = 0;
      let totalFoodItemRating = 0;
      let totalDonationProcessRating = 0;
      let reviewCount = 0;

      reviewsSnapshot.forEach(doc => {
        const communicationRating = doc.data().communicationRating;
        const foodItemRating = doc.data().foodItemRating;
        const donationProcessRating = doc.data().donationProcessRating;

        // Skip reviews with invalid ratings
        if (
          communicationRating !== null && communicationRating !== undefined &&
          foodItemRating !== null && foodItemRating !== undefined &&
          donationProcessRating !== null && donationProcessRating !== undefined
        ) {
          totalCommunicationRating += communicationRating;
          totalFoodItemRating += foodItemRating;
          totalDonationProcessRating += donationProcessRating;
          reviewCount++;
        }
      });

      // Ensure there's at least one valid review to calculate the average
      const avgCommunicationRating = reviewCount > 0 ? totalCommunicationRating / reviewCount : 0;
      const avgFoodItemRating = reviewCount > 0 ? totalFoodItemRating / reviewCount : 0;
      const avgDonationProcessRating = reviewCount > 0 ? totalDonationProcessRating / reviewCount : 0;

      // Calculate the overall average rating
      const overallAverageRating = (avgCommunicationRating + avgFoodItemRating + avgDonationProcessRating) / 3;

      // Round the overall average rating to 1 decimal place
      const roundedAverageRating = Math.round(overallAverageRating * 10) / 10;

      await admin.firestore().collection("users").doc(donorId).set({
        averageRating: roundedAverageRating,
        reviewCount: reviewCount
      }, { merge: true });

    } catch (error) {
      console.error("Error updating donor rating:", error);
    }

    return null;
  });

  // Trigger when the donation request status changes to "Denied"
exports.sendRequestDeniedNotification = functions.firestore
.document('donationRequests/{requestId}')
.onUpdate(async (change, context) => {
    // Get the new and old values of the donation request document
    const newValue = change.after.data();
    const oldValue = change.before.data();

    // Check if the status has changed to "Denied"
    if (newValue.status === 'Declined' && oldValue.status !== 'Declined') {
        const requesterId = newValue.requesterId;
        const productName = newValue.productName;

        try {
            // Retrieve the requester data from the 'users' collection
            const userRef = admin.firestore().collection('users').doc(requesterId);
            const userSnapshot = await userRef.get();
            
            if (!userSnapshot.exists) {
                console.log('User not found');
                return null;
            }

            const user = userSnapshot.data();
            const requesterToken = user.fcm_token;  // Assuming the user document has an FCM token field
            const requesterFirstName = user.firstName; // Assuming the user's first name is stored in Firestore

            if (!requesterToken) {
                console.log('No FCM token found for the user');
                return null;
            }

            // Check the user's notification preferences
            const notificationPreferences = user.notificationPreferences || {};
            if (notificationPreferences.requests === false) {
                console.log('User has disabled request notifications');
                return null;  // If the user has disabled requests notifications, don't send a message
            }

            // Create the message body
            const messageBody = `${requesterFirstName}, unfortunately, your request for ${productName} has been declined\nPlease check out other donations available'`;

            // Send a notification to the requester
            const message = {
                notification: {
                    title: 'Donation Request Declined',
                    body: messageBody,
                },
                token: requesterToken,
            };

            // Send the notification using Firebase Cloud Messaging (FCM)
            await admin.messaging().send(message);
            console.log('Denial notification sent successfully.');

            // Add a document to the notifications collection with type "request_denied"
            const notificationDoc = {
                type: "request",
                userId: requesterId,
                requesterId: requesterId,
                productName: productName,
                title: 'Donation Request Denied',
                body: messageBody,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                read: false,  // Track the notification status
            };

            await admin.firestore().collection('notifications').add(notificationDoc);
            console.log("Denial notification document added to the 'notifications' collection.");

        } catch (error) {
            console.error('Error sending denial notification: ', error);
        }

        return null;
    }

    return null;  // If the status hasn't changed to "Denied", do nothing
});


// Trigger when the donation request status changes to "Accepted"
exports.sendRequestAcceptedNotification = functions.firestore
    .document('donationRequests/{requestId}')
    .onUpdate(async (change, context) => {
        // Get the new and old values of the donation request document
        const newValue = change.after.data();
        const oldValue = change.before.data();

        // Check if the status has changed to "Accepted"
        if (newValue.status === 'Accepted' && oldValue.status !== 'Accepted') {
            const requesterId = newValue.requesterId;
            const assignedToName = newValue.assignedToName;
            const productName = newValue.productName;
            const pickupDateTime = newValue.pickupDateTime.toDate(); // Format the date without UTC
            
            try {
                // Retrieve the requester data from the 'users' collection
                const userRef = admin.firestore().collection('users').doc(requesterId);
                const userSnapshot = await userRef.get();
                
                if (!userSnapshot.exists) {
                    console.log('User not found');
                    return null;
                }

                const user = userSnapshot.data();
                const requesterToken = user.fcm_token;  // Assuming the user document has an FCM token field

                if (!requesterToken) {
                    console.log('No FCM token found for the user');
                    return null;
                }

                // Check the user's notification preferences
                const notificationPreferences = user.notificationPreferences || {};
                if (notificationPreferences.requests === false) {
                    console.log('User has disabled request notifications');
                    return null;  // If the user has disabled requests notifications, don't send a message
                }

                // Create the message body with the necessary details
                const messageBody = `${assignedToName}, your request for ${productName} has been accepted!\nYour pickup time is: ${pickupDateTime} as selected`;

                // Send a notification to the requester
                const message = {
                    notification: {
                        title: 'Donation Request Accepted',
                        body: messageBody,
                    },
                    token: requesterToken,
                };

                // Send the notification using Firebase Cloud Messaging (FCM)
                await admin.messaging().send(message);
                console.log('Notification sent successfully.');

                // Add a document to the notifications collection with type "request_accepted"
                const notificationDoc = {
                    type: "request",
                    userId: requesterId,
                    requesterId: requesterId,
                    assignedToName: assignedToName,
                    productName: productName,
                    title: 'Donation Request Accepted',  // Add the title here
                    body: messageBody,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    read: false,  // You can track the notification status
                    pickupDateTime: pickupDateTime.toISOString(),
                };

                await admin.firestore().collection('notifications').add(notificationDoc);
                console.log("Notification document added to the 'notifications' collection.");

            } catch (error) {
                console.error('Error sending notification: ', error);
            }

            return null;
        }

        return null;
        
       
    });

 

exports.moderateImages = functions.storage.object().onFinalize(async (object) => {
    const filePath = object.name; // Path of uploaded image
    const contentType = object.contentType;
    const bucketName = object.bucket;

    // Only process images in specific folders
    if (!filePath.startsWith("donation_images/") && !filePath.startsWith("user_profile_images/")) {
        console.log("File is not in a monitored folder, ignoring.");
        return null;
    }

    if (!contentType || !contentType.startsWith("image/")) {
        console.log("Not an image, skipping moderation.");
        return null;
    }

    console.log(`Analyzing ${filePath} for inappropriate content...`);

    const bucket = storage.bucket(bucketName);
    const file = bucket.file(filePath);
    const [result] = await client.safeSearchDetection(`gs://${bucketName}/${filePath}`);
    const detections = result.safeSearchAnnotation;

    console.log("Detected labels:", detections);

    // Check if image contains inappropriate content
    const isInappropriate = (
        detections.adult === "LIKELY" || detections.adult === "VERY_LIKELY" ||
        detections.violence === "LIKELY" || detections.violence === "VERY_LIKELY" ||
        detections.racy === "LIKELY" || detections.racy === "VERY_LIKELY"
    );

    if (isInappropriate) {
        console.log(`Inappropriate content found in ${filePath}`);

        // OPTION 1: BLUR IMAGE
        const tempFilePath = path.join(os.tmpdir(), path.basename(filePath));
        await file.download({ destination: tempFilePath });

        await sharp(tempFilePath)
            .blur(10) // Adjust blur level if needed
            .toFile(tempFilePath + "_blurred");

        await bucket.upload(tempFilePath + "_blurred", {
            destination: filePath, // Overwrite original
            metadata: { contentType: contentType },
        });

        fs.unlinkSync(tempFilePath);
        fs.unlinkSync(tempFilePath + "_blurred");

        console.log(`Blurred and replaced ${filePath}`);

        // OPTION 2: DELETE IMAGE (Uncomment if you want deletion instead)
        // await file.delete();
        // console.log(`Deleted ${filePath} due to inappropriate content.`);
    } else {
        console.log(`No inappropriate content found in ${filePath}.`);
    }

    return null;
});

