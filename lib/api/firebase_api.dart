import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  //create instance of firebase messaging
  final _firebaseMessging = FirebaseMessaging.instance;


  // function to initialise notifications
  Future<void> initNotifications() async {
    //request permission
    NotificationSettings settings = await _firebaseMessging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    //request permission
    await _firebaseMessging.requestPermission();


    print('User granted permission: ${settings.authorizationStatus}');

    //fetch FCM token for this device
    final fCMToken = await _firebaseMessging.getToken();

    //print the token
    print('FirebaseMessaging token: $fCMToken');
  }


  //function to handle received messges

  // function to initialise foreground and background settings


}