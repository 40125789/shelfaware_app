import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shelfaware_app/repositories/donation_repository.dart';


void main() {
late FakeFirebaseFirestore fakeFirestore;
late MockFirebaseAuth mockAuth;
late DonationRepository repository;

setUp(() {
  fakeFirestore = FakeFirebaseFirestore();
  mockAuth = MockFirebaseAuth();
  repository = DonationRepository(firestore: fakeFirestore, auth: mockAuth);
});


  test('getDonationDetails returns correct data when donation exists', () async {
    final donationId = 'testDonationId';
    final donationData = {'title': 'Food Donation', 'status': 'available'};
    await fakeFirestore.collection('donations').doc(donationId).set(donationData);

    final result = await repository.getDonationDetails(donationId);
    expect(result, isNotEmpty);
    expect(result['title'], 'Food Donation');
    expect(result['status'], 'available');
  });

  test('getDonationDetails returns empty map when donation does not exist', () async {
    final result = await repository.getDonationDetails('nonExistentId');
    expect(result, isEmpty);
  });

  test('updateDonationStatus updates the status correctly', () async {
    final donationId = 'testDonationId';
    await fakeFirestore.collection('donations').doc(donationId).set({'status': 'available'});

    await repository.updateDonationStatus(donationId, 'reserved');

    final updatedDoc = await fakeFirestore.collection('donations').doc(donationId).get();
    expect(updatedDoc['status'], 'reserved');
  });

  test('fetchUserById returns user data if user exists', () async {
    final userId = 'testUserId';
    final userData = {'firstName': 'John', 'lastName': 'Doe'};
    await fakeFirestore.collection('users').doc(userId).set(userData);

    final result = await repository.fetchUserById(userId);
    expect(result, isNotNull);
    expect(result?['firstName'], 'John');
    expect(result?['lastName'], 'Doe');
  });

  test('fetchUserById returns null if user does not exist', () async {
    final result = await repository.fetchUserById('unknownUserId');
    expect(result, isNull);
  });
}
