import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shelfaware_app/repositories/watched_donations_repository.dart';

void main() {
  late WatchedDonationsRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    // Use FakeFirebaseFirestore instead of a Mockito mock
    fakeFirestore = FakeFirebaseFirestore();
    // For FirebaseAuth, you can use a mock from firebase_auth_mocks
    mockAuth = MockFirebaseAuth();
    repository = WatchedDonationsRepository(
        firebaseFirestore: fakeFirestore, firebaseAuth: mockAuth);
  });

  test('getWatchedDonations should return watched donations for a user',
      () async {
    // Arrange
    final userId = 'user123';
    await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .add({'productName': 'Apples'});

    // Act
    final watchlistStream = repository.getWatchedDonations(userId);
    final watchlist = await watchlistStream.first;

    // Assert
    expect(watchlist.docs.length, 1);
    expect(watchlist.docs.first['productName'], 'Apples');
  });

  test('getDonorData should return correct donor details', () async {
    // Arrange
    final donorId = 'donor456';
    await fakeFirestore
        .collection('users')
        .doc(donorId)
        .set({'name': 'John Doe', 'location': 'Belfast'});

    // Act
    final donorData = await repository.getDonorData(donorId);

    // Assert
    expect(donorData.exists, true);
    expect(donorData['name'], 'John Doe');
    expect(donorData['location'], 'Belfast');
  });

  test(
      'isDonationInWatchlist should return true if donation exists in watchlist',
      () async {
    // Arrange
    final userId = 'user123';
    final donationId = 'donation789';
    await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .set({'productName': 'Milk'});

    // Act
    final exists = await repository.isDonationInWatchlist(userId, donationId);

    // Assert
    expect(exists, true);
  });

  test(
      'isDonationInWatchlist should return false if donation does not exist in watchlist',
      () async {
    // Arrange
    final userId = 'user123';
    final donationId = 'donation999'; // Not added to Firestore

    // Act
    final exists = await repository.isDonationInWatchlist(userId, donationId);

    // Assert
    expect(exists, false);
  });

  test('addToWatchlist should correctly add donation details', () async {
    // Arrange
    final userId = 'user123';
    final donationId = 'donation101';
    final donationData = {
      'productName': 'Bananas',
      'status': 'available',
      'expiryDate': '2025-01-01',
      'location': 'Dublin',
      'donorName': 'Alice',
      'imageUrl': 'image_url',
      'donorId': 'donor999',
    };

    // Act
    await repository.addToWatchlist(userId, donationId, donationData);
    final addedDonation = await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .get();

    // Assert
    expect(addedDonation.exists, true);
    expect(addedDonation['productName'], 'Bananas');
    expect(addedDonation['status'], 'available');
    expect(addedDonation['donorId'], 'donor999');
  });

  test('removeFromWatchlist should correctly remove a donation', () async {
    // Arrange
    final userId = 'user123';
    final donationId = 'donation303';
    await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .set({'productName': 'Oranges'});

    // Act
    await repository.removeFromWatchlist(userId, donationId);
    final removedDonation = await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .get();

    // Assert
    expect(removedDonation.exists, false);
  });

  test('toggleWatchlist should add donation if not already in watchlist',
      () async {
    // Arrange
    final userId = 'user123';
    final donationId = 'donation505';
    final donationData = {
      'productName': 'Tomatoes',
      'status': 'available',
      'expiryDate': '2025-02-15',
      'location': 'Cork',
      'donorName': 'Emma',
      'imageUrl': 'image_url',
      'donorId': 'donor111',
    };

    // Act
    await repository.toggleWatchlist(userId, donationId, donationData);
    final addedDonation = await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .get();

    // Assert
    expect(addedDonation.exists, true);
    expect(addedDonation['productName'], 'Tomatoes');
  });

  test('toggleWatchlist should remove donation if already in watchlist',
      () async {
    // Arrange
    final userId = 'user123';
    final donationId = 'donation707';
    await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .set({'productName': 'Carrots'});

    // Act
    await repository.toggleWatchlist(userId, donationId, {});
    final removedDonation = await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(donationId)
        .get();

    // Assert
    expect(removedDonation.exists, false);
  });
}
