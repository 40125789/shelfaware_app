import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/repositories/user_repository.dart';


void main() {
  late UserRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    // Use FakeFirebaseFirestore instead of a Mockito mock
    fakeFirestore = FakeFirebaseFirestore();
    // Use mock FirebaseAuth for authentication-related operations
    mockAuth = MockFirebaseAuth();

    
    repository = UserRepository(firestore: fakeFirestore, auth: mockAuth);
  });


  test('getUserData returns user data from Firestore', () async {
    final userId = 'testUid';
    final userData = {
      'firstName': 'John',
      'lastName': 'Doe',
      'email': 'john.doe@example.com',
    };

    await fakeFirestore.collection('users').doc(userId).set(userData);

    final fetchedData = await repository.getUserData(userId);
    expect(fetchedData, userData);
  });

  test('fetchDonorRating returns donor rating from Firestore', () async {
    final donorId = 'testDonorId';
    final donorData = {'averageRating': 4.5};

    await fakeFirestore.collection('users').doc(donorId).set(donorData);

    final rating = await repository.fetchDonorRating(donorId);
    expect(rating, 4.5);
  });

  test('fetchProfileImageUrl returns profile image URL from Firestore', () async {
    final userId = 'testUserId';
    final profileData = {'profileImageUrl': 'http://example.com/image.jpg'};

    await fakeFirestore.collection('users').doc(userId).set(profileData);

    final imageUrl = await repository.fetchProfileImageUrl(userId);
    expect(imageUrl, 'http://example.com/image.jpg');
  });

  test('fetchDonorProfileImageUrl returns donor profile image URL from Firestore', () async {
    final donorId = 'testDonorId';
    final profileData = {'profileImageUrl': 'http://example.com/image.jpg'};

    await fakeFirestore.collection('users').doc(donorId).set(profileData);

    final imageUrl = await repository.fetchDonorProfileImageUrl(donorId);
    expect(imageUrl, 'http://example.com/image.jpg');
  });
}
