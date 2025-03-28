import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/components/food_category_tile.dart';
import 'package:shelfaware_app/components/food_card.dart';
import 'package:shelfaware_app/utils/food_utils.dart';

class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late List<QueryDocumentSnapshot> mockItems;
  late Function(BuildContext, String) mockOnItemTap;
  late Function(String) mockOnItemEdit;
  late Function(String) mockOnItemDelete;
  late Function(String) mockOnItemDonate;
  late Function(String) mockOnItemAddToShoppingList;
  
  setUp(() {
    mockItems = [
      MockQueryDocumentSnapshot(),
      MockQueryDocumentSnapshot(),
    ];
    
    mockOnItemTap = (_, __) {};
    mockOnItemEdit = (_) {};
    mockOnItemDelete = (_) {};
    mockOnItemDonate = (_) {};
    mockOnItemAddToShoppingList = (_) {};
  });
  
  testWidgets('FoodCategoryTile displays correct category name and item count', (WidgetTester tester) async {
    // Arrange
    const String testCategory = 'Fruits';
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodCategoryTile(
            category: testCategory,
            items: mockItems,
            onItemTap: mockOnItemTap,
            onItemEdit: mockOnItemEdit,
            onItemDelete: mockOnItemDelete,
            onItemDonate: mockOnItemDonate,
            onItemAddToShoppingList: mockOnItemAddToShoppingList,
          ),
        ),
      ),
    );
    
    // Assert
    expect(find.text(testCategory), findsOneWidget);
    expect(find.text('(${mockItems.length} items)'), findsOneWidget);
  });
  

  
  testWidgets('FoodCategoryTile has correct color from FoodUtils', (WidgetTester tester) async {
    // Arrange
    const String testCategory = 'Dairy';
    final expectedColor = FoodUtils.getCategoryColor(testCategory);
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodCategoryTile(
            category: testCategory,
            items: mockItems,
            onItemTap: mockOnItemTap,
            onItemEdit: mockOnItemEdit,
            onItemDelete: mockOnItemDelete,
            onItemDonate: mockOnItemDonate,
            onItemAddToShoppingList: mockOnItemAddToShoppingList,
          ),
        ),
      ),
    );
    
    // Assert
    final containerFinder = find.descendant(
      of: find.byType(ExpansionTile),
      matching: find.byType(Container),
    ).first;
    
    final Container container = tester.widget<Container>(containerFinder);
    final BoxDecoration decoration = container.decoration as BoxDecoration;
    
    expect(decoration.color, equals(expectedColor));
  });
}