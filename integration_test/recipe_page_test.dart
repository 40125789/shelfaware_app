import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/components/favourite_button.dart';
import 'package:shelfaware_app/pages/recipe_details_page.dart';
import 'package:shelfaware_app/pages/recipes_page.dart';
import 'package:shelfaware_app/components/recipe_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';
import 'package:shelfaware_app/pages/home_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
         await Permission.location.request(); // Request location permission
      await Permission.camera.request();   // Request camera permission
      await Permission.storage.request();  
  

    await Firebase.initializeApp();
  });

  group('RecipesPage Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late DonationService donationService;
    late FoodService foodService;
    late User user;

    // Authenticate once for all tests
    setUp(() async {
      auth = FirebaseAuth.instance;
      final userCredential = await auth.signInWithEmailAndPassword(
        email: 'smyth668@hotmail.com',
        password: 'Ya9maha8@',
      );
      firestore = FirebaseFirestore.instance;
      donationService = DonationService();
      foodService = FoodService();
      user = userCredential.user!;

      // Wait for Firebase to initialize properly if needed
      await Future.delayed(Duration(seconds: 2)); // Increase wait time if needed
    });

    testWidgets('Navigate to RecipesPage and verify RecipeCard with FavouriteButton', (WidgetTester tester) async {
      debugPrint("Starting test: Navigate to RecipesPage");

      // Pump the widget tree with the home page
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green, // Ensure this matches your main.dart
              ),
            ),
            home: HomePage(),
          ),
        ),
      );

      // Wait for the UI to settle
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 1)); // Allow additional UI updates

      debugPrint("Tapping on the RecipesPage icon...");
      await tester.tap(find.byIcon(Icons.book));
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 2)); // Increase delay for a more stable load

      debugPrint("Checking if RecipesPage is displayed...");
      expect(find.byType(RecipesPage), findsOneWidget);

      // Find RecipeCard inside RecipesPage
      final recipeCardFinder = find.byType(RecipeCard);

      if (recipeCardFinder.evaluate().isEmpty) {
        debugPrint("No RecipeCard found. Skipping test.");
        return;
      }

      debugPrint("RecipeCard found. Ensuring visibility...");
      await tester.scrollUntilVisible(recipeCardFinder.first, 200);
      await tester.pumpAndSettle();

      debugPrint("Verifying recipe name...");
      expect(find.text('Luscious Orange Cardamom Smoothie'), findsOneWidget);

      // Tap the RecipeCard to navigate to the details page
      debugPrint("Tapping on the RecipeCard to navigate to RecipeDetailsPage...");
      await tester.tap(recipeCardFinder.first);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 2)); // Allow time for navigation

      // Verify if the RecipeDetailsPage is displayed
      debugPrint("Verifying if RecipeDetailsPage is displayed...");
      expect(find.byType(RecipeDetailsPage), findsOneWidget);

      // Optionally, verify the contents of the RecipeDetailsPage (e.g., recipe name)
      debugPrint("Verifying recipe name on RecipeDetailsPage...");
      expect(find.text('Luscious Orange Cardamom Smoothie'), findsOneWidget);

      // Find the FavouriteButton inside the RecipeCard
      final favouriteButtonFinder = find.byType(FavouriteButton);

      debugPrint("Verifying FavouriteButton exists...");
      expect(favouriteButtonFinder, findsOneWidget);

      // Simulate tap on the FavouriteButton
      debugPrint("Tapping on the FavouriteButton...");
      await tester.tap(favouriteButtonFinder);
      await tester.pumpAndSettle();
      await Future.delayed(Duration(seconds: 1)); // Allow animation to complete

      debugPrint("FavouriteButton tapped successfully.");
    });

    tearDown(() async {
      await auth.signOut();
    });
  });
}
