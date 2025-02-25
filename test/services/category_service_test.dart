
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shelfaware_app/services/category_service.dart';

void main() {
  late CategoryService categoryService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    categoryService = CategoryService(firestore: fakeFirestore);
  });

  test('getFilterOptions returns a list of non-empty categories', () async {
    // Arrange
    await fakeFirestore.collection('categories').add({'Food Type': 'Fruits'});
    await fakeFirestore.collection('categories').add({'Food Type': 'Vegetables'});
    await fakeFirestore.collection('categories').add({'Food Type': ''}); // Should be filtered out
    await fakeFirestore.collection('categories').add({}); // Missing field, should be filtered out

    // Act
    List<String> categories = await categoryService.getFilterOptions();

    // Assert
    expect(categories.length, 2);
    expect(categories, containsAll(['Fruits', 'Vegetables']));
  });

  test('getFilterOptions returns an empty list when no valid categories are found', () async {
    // Arrange
    await fakeFirestore.collection('categories').add({'Food Type': ''});
    await fakeFirestore.collection('categories').add({});

    // Act
    List<String> categories = await categoryService.getFilterOptions();

    // Assert
    expect(categories, isEmpty);
  });
}


