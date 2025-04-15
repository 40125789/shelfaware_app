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

  test('getDonationRequests returns correct data', () async {
    final donationId = 'testDonationId';
    final requestData = {'donationId': donationId, 'status': 'pending'};
    await fakeFirestore.collection('donationRequests').add(requestData);

    final stream = repository.getDonationRequests(donationId);
    final requests = await stream.first;

    expect(requests, isNotEmpty);
    expect(requests.first['donationId'], donationId);
    expect(requests.first['status'], 'pending');
  });

  test('getAssigneeProfileImage returns null if no assigned user', () async {
    final donationId = 'testDonationId';
    await fakeFirestore.collection('donations').doc(donationId).set({});

    final result = await repository.getAssigneeProfileImage(donationId);
    expect(result, isNull);
  });

  test('acceptDonationRequest updates donation and request status correctly', () async {
    final donationId = 'testDonationId';
    final requestId = 'testRequestId';
    final requesterId = 'testUserId';
    final requesterName = 'John';

    await fakeFirestore.collection('users').doc(requesterId).set({'firstName': requesterName});
    await fakeFirestore.collection('donations').doc(donationId).set({'status': 'available'});
    await fakeFirestore.collection('donationRequests').doc(requestId).set({'donationId': donationId, 'status': 'pending'});

    await repository.acceptDonationRequest(donationId, requestId, requesterId);

    final updatedDonation = await fakeFirestore.collection('donations').doc(donationId).get();
    final updatedRequest = await fakeFirestore.collection('donationRequests').doc(requestId).get();

    expect(updatedDonation['status'], 'Reserved');
    expect(updatedDonation['assignedTo'], requesterId);
    expect(updatedDonation['assignedToName'], requesterName);

    expect(updatedRequest['status'], 'Accepted');
    expect(updatedRequest['assignedTo'], requesterId);
    expect(updatedRequest['assignedToName'], requesterName);
  });

  test('declineDonationRequest updates request status correctly', () async {
    final requestId = 'testRequestId';
    await fakeFirestore.collection('donationRequests').doc(requestId).set({'status': 'pending'});

    await repository.declineDonationRequest(requestId);

    final updatedRequest = await fakeFirestore.collection('donationRequests').doc(requestId).get();
    expect(updatedRequest['status'], 'Declined');
  });

  test('addDonation adds a new donation', () async {
    final user = MockUser(uid: 'testUserId');
    mockAuth = MockFirebaseAuth(mockUser: user);
    await mockAuth.signInWithCustomToken('testToken');
    await mockAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password');
    repository = DonationRepository(firestore: fakeFirestore, auth: mockAuth); // Reinitialize repository with authenticated user
    final donationData = {'donationId': 'testDonationId', 'title': 'Food Donation'};
    await fakeFirestore.collection('donations').doc(donationData['donationId']).set(donationData);

    final addedDonation = await fakeFirestore.collection('donations').doc(donationData['donationId']).get();
    expect(addedDonation.exists, isTrue);
    expect(addedDonation['title'], 'Food Donation');
  });

  test('removeFoodItem deletes the food item', () async {
    final foodItemId = 'testFoodItemId';
    await fakeFirestore.collection('foodItems').doc(foodItemId).set({'name': 'Apple'});

    await repository.removeFoodItem(foodItemId);

    final deletedFoodItem = await fakeFirestore.collection('foodItems').doc(foodItemId).get();
    expect(deletedFoodItem.exists, isFalse);
  });

  test('hasUserAlreadyReviewed returns true if user has reviewed', () async {
    final donationId = 'testDonationId';
    final userId = 'testUserId';
    await fakeFirestore.collection('reviews').add({'donationId': donationId, 'reviewerId': userId});

    final result = await repository.hasUserAlreadyReviewed(donationId, userId);
    expect(result, isTrue);
  });

  test('hasUserAlreadyReviewed returns false if user has not reviewed', () async {
    final result = await repository.hasUserAlreadyReviewed('testDonationId', 'testUserId');
    expect(result, isFalse);
  });

  test('getAllDonations returns all donations', () async {
    final donationData1 = {'donationId': 'donation1', 'title': 'Food Donation 1'};
    final donationData2 = {'donationId': 'donation2', 'title': 'Food Donation 2'};
    await fakeFirestore.collection('donations').add(donationData1);
    await fakeFirestore.collection('donations').add(donationData2);

    final stream = repository.getAllDonations();
    final donations = await stream.first;

    expect(donations, hasLength(2));
    expect(donations[0]['title'], 'Food Donation 1');
    expect(donations[1]['title'], 'Food Donation 2');
  });
}
