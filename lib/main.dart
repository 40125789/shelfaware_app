import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/auth_page.dart';
import 'package:provider/provider.dart';
import 'controllers/bottom_nav_controller.dart';
import 'controllers/auth_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: 'assets/.env');
    print("Environment variables loaded successfully");
    // Only access the variables here to avoid using them before initialization
    print("EDAMAM_APP_ID: ${dotenv.env['EDAMAM_APP_ID']}");
    print("GOOGLE_MAPS_API_KEY: ${dotenv.env['GOOGLE_MAPS_API_KEY']}");
  } catch (e) {
    // Handle the error gracefully
    print("Error loading .env file: $e");
    // Optionally, you can return here to prevent further execution
    return;
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => BottomNavController()),
      ],
      child: const MyApp(),
    ),
  );
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
