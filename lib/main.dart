import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path_provider/path_provider.dart';
import 'package:shelfaware_app/screens/chat_page.dart';
import 'package:shelfaware_app/screens/my_donations_page.dart';
import 'package:shelfaware_app/screens/settings_page.dart';
import 'package:shelfaware_app/providers/settings_provider.dart'; // Ensure this import is correct
import 'package:wiredash/wiredash.dart';
import 'firebase_options.dart';
import 'screens/auth_page.dart';
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

  // Initialize Firebase Auth
  FirebaseAuth auth = FirebaseAuth.instance;

  // Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    print("Environment variables loaded successfully");
  } catch (e) {
    print("Error loading .env file: $e");
    return;
  }

  // Listen for authentication state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      print("User logged in: ${user.uid}");

      String? token = await messaging.getToken();
      if (token != null) {
        print("Retrieved FCM Token: $token");
        await storeFCMToken(user.uid, token);
      }
    } else {
      print("User is not logged in.");
    }
  });

  // Handle token refresh
  messaging.onTokenRefresh.listen((newToken) async {
    print("FCM Token refreshed: $newToken");

    User? user = FirebaseAuth.instance.currentUser;
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

    await userRef.set({'fcm_token': token}, SetOptions(merge: true));

    print("FCM token stored successfully for user: $userId");
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
          '/login': (context) => AuthPage(),
          '/myDonations': (context) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return MyDonationsPage(userId: user.uid);
            } else {
              return AuthPage();
            }
          },

        },
      ),
    );
  }
}
