import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelfaware_app/services/food_suggestions_service.dart';

// This function ensures Firebase is initialized for testing
Future<void> initializeFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  try {
    // Mock Firebase initialization for unit testing
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase already initialized');
  }
}

void main() {
  late FoodSuggestionsService foodSuggestionsService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUpAll(() async {
    await initializeFirebaseForTesting(); // Ensure Firebase is initialized
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    foodSuggestionsService = FoodSuggestionsService();
  });

  test('fetchFoodSuggestions returns an empty list for an empty query', () async {
    List<String> suggestions = await foodSuggestionsService.fetchFoodSuggestions('');
    expect(suggestions, isEmpty);
  });

  test('fetchFoodSuggestions returns food items from Firestore', () async {
    // Add mock data to Firestore (this will be used by FoodSuggestionsService)
    await fakeFirestore.collection('foodItems').add({'productName': 'Apple'});
    await fakeFirestore.collection('foodItems').add({'productName': 'Banana'});

    // Act: Call the fetchFoodSuggestions method
    List<String> suggestions = await foodSuggestionsService.fetchFoodSuggestions('App');

    // Assert: Check if 'Apple' is returned in the suggestions
    expect(suggestions, contains('Apple'));
  });

  test('fetchFoodSuggestions returns history items from Firestore', () async {
    await fakeFirestore.collection('history').add({'productName': 'Orange'});

    List<String> suggestions = await foodSuggestionsService.fetchFoodSuggestions('O');
    expect(suggestions, contains('Orange'));
  });
}
