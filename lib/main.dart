import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelfaware_app/api/firebase_api.dart';
import 'package:shelfaware_app/controllers/expiring_items_controller.dart';
import 'package:shelfaware_app/pages/chat_page.dart';
import 'package:shelfaware_app/pages/settings_page.dart';
import 'package:shelfaware_app/providers/settings_provider.dart';
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

  // Initialize Firebase App Check with error handling

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
  // final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      AndroidInitializationSettings('@android:drawable/ic_dialog_info');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => BottomNavController()),
        ChangeNotifierProvider(create: (context) => ExpiringItemsController()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()), 
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notifications here
  print("Handling background message: ${message.messageId}");
  _handleNotification(message);
}

void _handleNotification(RemoteMessage message) {
  // Check if the message contains a chatId
  String? chatId = message.data['chatId'];

  if (chatId != null) {
    // Navigate to chat screen when a message notification is received
    // You can either use Navigator.pushNamed or another method to handle navigation
    navigatorKey.currentState?.pushNamed('/chat_page', arguments: chatId);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the notification handler
    final notificationHandler = NotificationHandler(context: context);

    notificationHandler.initialize();

    // Get the dark mode status
    bool isDarkMode = Provider.of<SettingsProvider>(context).isDarkMode;

 return Wiredash(
  projectId: 'shelfaware-vzxz2vt',
  secret: '-y_wurv7O5isCUa4qVVG_5CGaiiJsatH',

  feedbackOptions: WiredashFeedbackOptions(
  labels: [
      // Grab the label IDs from the Console
      // https://wiredash.com/console -> Settings -> Labels
      Label(
        id: 'label-rp8uxxf8zg',
        title: 'Feature Request',
      ),
      Label(
        id: 'label-v4cxn1elkc',
        title: 'User Interface',
      ),
      Label(
        id: 'label-s8wq58dcmb',
        title: 'Bug',
      ),
    ],
  
  ),
  child: MaterialApp(

  debugShowCheckedModeBanner: false,
  title: 'ShelfAware',
  theme: ThemeData(
    // Customize the AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: isDarkMode ? Colors.black : Colors.green, // Black in dark mode, green in light mode
      iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black), // Icon color in AppBar
      elevation: 0, // Optional: Remove shadow for flat look
    ),
    brightness: isDarkMode ? Brightness.dark : Brightness.light, // Set brightness
    scaffoldBackgroundColor: isDarkMode ? Colors.black : Colors.white, // Scaffold background color
    primaryColor: isDarkMode ? Colors.black : Colors.green, // Primary color
    visualDensity: VisualDensity.adaptivePlatformDensity,

    // Customize text field theme to fix purple text in dark mode
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[200], // Darker fill color in dark mode
      hintStyle: TextStyle(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600], // Hint text color
      ),
      labelStyle: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black, // Label text color
      ),
      errorStyle: TextStyle(
        color: Colors.redAccent, // Error text color
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey : Colors.black, // Border color when enabled
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isDarkMode ? Colors.green : Colors.blue, // Border color when focused
        ),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black, // Set text color based on theme
      ),
    ),
  ),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
  ),
  themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // Apply theme dynamically

      // Otherwise, use light theme
      home: AuthPage(),
      routes: {
        '/chat': (context) => ChatPage(
              receiverEmail: 'example@example.com',
              receiverId: 'receiverId',
              donationId: 'donationId',
              userId: 'userId',
              donationName: 'donationName',
              donorName: 'donorName',
              chatId: 'chatId',
            ), // Define route for the chat page
            
        '/settings': (context) => SettingsPage(), 
      },
    ),
  );
  }
}
