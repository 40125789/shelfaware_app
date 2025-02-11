import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/api/firebase_api.dart';
import 'package:shelfaware_app/controllers/expiring_items_controller.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/settings_page.dart';
import 'package:shelfaware_app/providers/settings_provider.dart'; // Ensure this import is correct
import 'package:shelfaware_app/services/notification_handler.dart';
import 'package:wiredash/wiredash.dart';
import 'firebase_options.dart';
import 'pages/auth_page.dart';
import 'package:provider/provider.dart';
import 'controllers/bottom_nav_controller.dart';
import 'controllers/auth_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  FirebaseAppCheck.instance.getToken(true).then((token) {
    print("App Check Debug Token: $token");
  }).catchError((e) {
    print("Error fetching App Check token: $e");
  });

  // Initialize Firebase Messaging
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize Firebase Auth
  FirebaseAuth auth = FirebaseAuth.instance;

  // Initialize notifications
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

  // Get FCM token
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
  const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Run the app wrapped with ProviderScope
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> storeFCMToken(String userId, String token) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await userRef.update({
      'fcm_token': token,
    }).catchError((e) {
      print("Error storing FCM token: $e");
    });
  } catch (e) {
    print("Error updating Firestore: $e");
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider); // Watch for changes in settingsProvider
    final isDarkMode = settingsState.isDarkMode;


    return Wiredash(
      projectId: 'shelfaware-vzxz2vt',
      secret: '-y_wurv7O5isCUa4qVVG_5CGaiiJsatH',
      feedbackOptions: WiredashFeedbackOptions(
        labels: [
          Label(id: 'label-rp8uxxf8zg', title: 'Feature Request'),
          Label(id: 'label-v4cxn1elkc', title: 'User Interface'),
          Label(id: 'label-s8wq58dcmb', title: 'Bug'),
        ],
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ShelfAware',
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // Dynamically set themeMode
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            backgroundColor: isDarkMode ? Colors.black87 : Colors.green,
            iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
            elevation: 0,
          ),
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: isDarkMode ? Colors.black87 : Colors.white,
          primaryColor: isDarkMode ? Colors.black : Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
            hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            errorStyle: TextStyle(color: Colors.redAccent),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: isDarkMode ? Colors.grey : Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: isDarkMode ? Colors.green : Colors.blue),
            ),
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
        ),
        darkTheme: ThemeData.dark(),
        home: AuthPage(),
        routes: {
          '/chat': (context) => ChatPage(
            receiverEmail: 'example@example.com',
            receiverId: 'receiverId',
            donationId: 'donationId',
            userId: 'userId',
            donationName: 'donationName',
            donorName: 'donorName', chatId: '',
            
          ),
          '/settings': (context) => SettingsPage(),
        },
      ),
    );
  }
}
