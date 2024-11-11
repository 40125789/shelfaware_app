import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelfaware_app/api/firebase_api.dart';
import 'package:shelfaware_app/controllers/expiring_items_controller.dart';
import 'firebase_options.dart';
import 'pages/auth_page.dart';
import 'package:provider/provider.dart';
import 'controllers/bottom_nav_controller.dart';
import 'controllers/auth_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseApi firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();

  // Load environment variables
  try {
    await dotenv.load(fileName: 'assets/.env');
    print("Environment variables loaded successfully");
  } catch (e) {
    print("Error loading .env file: $e");
    return;
  }

  // Initialize Firebase Messaging
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize Firebase Auth
  FirebaseAuth auth = FirebaseAuth.instance;

  // Get FCM token (this is what you send to your server to identify the device)
  _firebaseMessaging.getToken().then((token) async {
    print("FCM Token: $token");
    if (token != null) {
      User? user = auth.currentUser;
      if (user != null) {
        await storeFCMToken(user.uid, token);
      }
    }
  });

  // Handle token refresh
  _firebaseMessaging.onTokenRefresh.listen((newToken) async {
    User? user = auth.currentUser;
    if (user != null) {
      await storeFCMToken(user.uid, newToken);
    }
  });

  // Initialize Local Notifications
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const initializationSettingsAndroid =
      AndroidInitializationSettings('@android:drawable/ic_dialog_info');
  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => BottomNavController()),
        ChangeNotifierProvider(create: (context) => ExpiringItemsController()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> storeFCMToken(String userId, String token) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Use update() to only update the 'fcm_token' field and not overwrite other fields
    await userRef.update({
      'fcm_token': token, // Store the token under the 'fcm_token' field
    }).catchError((e) {
      print("Error storing FCM token: $e");
    });
  } catch (e) {
    print("Error updating Firestore: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShelfAware',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              Colors.greenAccent, // You can choose your primary color here
          primary: Colors.green,
          secondary: Colors.lightGreen,
          // Primary color for your app
        ),
      ),
      home: AuthPage(),
    );
  }
}
