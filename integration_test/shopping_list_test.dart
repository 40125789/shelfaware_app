import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shelfaware_app/pages/home_page.dart';
import 'package:shelfaware_app/services/donation_service.dart';
import 'package:shelfaware_app/services/food_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
  });

  group('HomePage Integration Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;
    late DonationService donationService;
    late FoodService foodService;
    late User user;

    setUp(() async {
      await Firebase.initializeApp();
      auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
          email: 'smyth668@hotmail.com', password: 'Ya9maha8@');
      firestore = FirebaseFirestore.instance;
      donationService = DonationService();
      foodService = FoodService();
      user = auth.currentUser!;
    });

    Future<void> navigateToShoppingList(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green,
              ),
            ),
            home: HomePage(),
          ),
        ),
      );
      final Finder menuButton = find.byTooltip('Open navigation menu');
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final Finder shoppingListNavItem = find.text('Shopping List');
      await tester.tap(shoppingListNavItem);
      await tester.pumpAndSettle();
    }

    testWidgets('Navigate to Shopping List Screen',
        (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      expect(find.text('Shopping List'), findsOneWidget);
    });

    testWidgets('Add a product to the Shopping List',
        (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      final Finder textField = find.byType(TextField);
      await tester.enterText(textField, 'egg');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final Finder addButton = find.byIcon(Icons.add);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('egg'), findsOneWidget);
    });

    testWidgets('Mark an item as purchased', (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      final Finder eggItem = find.ancestor(
        of: find.text('egg'),
        matching: find.byType(ListTile),
      );

      final Finder eggCheckBox = find.descendant(
        of: eggItem,
        matching: find.byIcon(Icons.check_box_outline_blank),
      );

      await tester.tap(eggCheckBox);
      await tester.pumpAndSettle();
      expect(find.text('Purchased'), findsOneWidget);
    });

    testWidgets('Toggle Hide Purchased Items', (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      final Finder toggleButton = find.byType(Switch);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.text('egg'), findsNothing);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.text('egg'), findsOneWidget);
    });

    testWidgets('Delete an item from the Shopping List',
        (WidgetTester tester) async {
      await navigateToShoppingList(tester);
      final Finder deleteButton = find.byIcon(Icons.delete);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      expect(find.text('egg'), findsNothing);
    });
  });
}
