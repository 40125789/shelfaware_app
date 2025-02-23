import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shelfaware_app/models/mark_food.dart';
import 'package:shelfaware_app/repositories/mark_food_respository.dart';
import 'package:shelfaware_app/services/mark_food_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelfaware_app/firebase_options.dart';

// Mock classes
class MockMarkFoodRepository extends Mock implements MarkFoodRepository {}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  group('MarkFoodService', () {
    late MockMarkFoodRepository mockRepository;
    mockRepository = MockMarkFoodRepository();
    late MarkFoodService markFoodService;
    setUp(() {
      mockRepository = MockMarkFoodRepository();
      markFoodService = MarkFoodService();
    });

    test('getFoodItem returns a food item for a valid documentId', () async {
      final documentId = 'testDocumentId';
      final mockFoodItem =
          MarkFood(id: documentId, productName: 'Apple', quantity: 10);

      when(mockRepository.fetchFoodItem(documentId))
          .thenAnswer((_) async => mockFoodItem);

      final result = await markFoodService.getFoodItem(documentId);

      expect(result, isNotNull);
      expect(result?.id, documentId);
      expect(result?.productName, 'Apple');
      expect(result?.quantity, 10);
    });

    test('getFoodItem returns null for an invalid documentId', () async {
      final documentId = 'invalidDocumentId';

      when(mockRepository.fetchFoodItem(documentId))
          .thenAnswer((_) async => null);

      final result = await markFoodService.getFoodItem(documentId);

      expect(result, isNull);
    });
  });
}
