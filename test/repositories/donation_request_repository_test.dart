
  import 'package:flutter_test/flutter_test.dart';
    import 'package:cloud_firestore/cloud_firestore.dart';
    import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
    import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
    import 'package:shelfaware_app/models/donation_request.dart';
    import 'package:shelfaware_app/repositories/donation_request_repository.dart';

    void main() {
      group('DonationRequestRepository', () {
        late DonationRequestRepository repository;
        late FakeFirebaseFirestore fakeFirestore;
        late MockFirebaseAuth mockAuth;

        setUp(() {
          fakeFirestore = FakeFirebaseFirestore();
          mockAuth = MockFirebaseAuth();
          repository = DonationRequestRepository(firebaseFirestore: fakeFirestore, firebaseAuth: mockAuth);
        });

        test('addDonationRequest adds a donation request and updates requestId', () async {
          final donationRequest = DonationRequest(
            productName: 'Test Product',
            expiryDate: DateTime.now().toIso8601String(),
            status: 'Pending',
            donorName: 'Test Donor',
            donatorId: 'testDonatorId',
            donationId: 'testDonationId',
            imageUrl: 'testImageUrl',
            donorImageUrl: 'testDonorImageUrl',
            pickupDateTime: DateTime.now().add(Duration(days: 1)),
            message: 'Test Message',
            requesterId: 'testRequesterId',
            requestDate: Timestamp.fromDate(DateTime.now()),
            requesterProfileImageUrl: 'testRequesterProfileImageUrl',
          );
          final docRef = await fakeFirestore.collection('donationRequests').add(donationRequest.toMap());
          final requestId = docRef.id;

          await repository.addDonationRequest(donationRequest);

          final addedDoc = await docRef.get();
          expect(addedDoc['requestId'], equals(requestId));
        });

        test('getUserProfileImageUrl returns profile image URL if exists', () async {
          final userDoc = fakeFirestore.collection('users').doc('testUserId');
          await userDoc.set({'profileImageUrl': 'testUrl'});

          final result = await repository.getUserProfileImageUrl('testUserId');

          expect(result, 'testUrl');
        });

        test('getUserProfileImageUrl returns empty string if profile image URL does not exist', () async {
          final userDoc = fakeFirestore.collection('users').doc('testUserId');
          await userDoc.set({'profileImageUrl': null});

          final result = await repository.getUserProfileImageUrl('testUserId');

          expect(result, '');
        });

        test('addDonationRequest throws an exception if adding fails', () async {
          final donationRequest = DonationRequest(
            productName: 'Test Product',
            expiryDate: DateTime.now().toIso8601String(),
            status: 'Pending',
            donorName: 'Test Donor',
            donatorId: 'testDonatorId',
            donationId: 'testDonationId',
            imageUrl: 'testImageUrl',
            donorImageUrl: 'testDonorImageUrl',
            pickupDateTime: DateTime.now().add(Duration(days: 1)),
            message: 'Test Message',
            requesterId: 'testRequesterId',
            requestDate: Timestamp.fromDate(DateTime.now()),
            requesterProfileImageUrl: 'testRequesterProfileImageUrl',
          );

          fakeFirestore = FakeFirebaseFirestore();
          repository = DonationRequestRepository(firebaseFirestore: fakeFirestore, firebaseAuth: mockAuth);

          await fakeFirestore.collection('donationRequests').doc('testDoc').delete();

          expect(() async => await repository.addDonationRequest(donationRequest), throwsException);
        });

        test('getUserProfileImageUrl throws an exception if fetching fails', () async {
          fakeFirestore = FakeFirebaseFirestore();
          repository = DonationRequestRepository(firebaseFirestore: fakeFirestore, firebaseAuth: mockAuth);

          await fakeFirestore.collection('users').doc('testUserId').delete();

          expect(() async => await repository.getUserProfileImageUrl('testUserId'), throwsException);
        });
});
    }


