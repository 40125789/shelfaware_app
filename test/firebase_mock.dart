import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_test/flutter_test.dart';


class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  test('Mock FirebaseAuth behavior for login', () async {
    final mockFirebaseAuth = MockFirebaseAuth();
    final mockUser = MockUser();
    final mockUserCredential = MockUserCredential();

    // Mock FirebaseAuth's signInWithEmailAndPassword method using any matcher for both email and password
    when(mockFirebaseAuth.signInWithEmailAndPassword(email: anyNamed('email') ?? 'test@example.com', password: anyNamed('password') ?? 'password123'))
        .thenAnswer((_) async => mockUserCredential);

    // Mock currentUser to return a mocked user
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

    // Simulate calling the sign-in method
    final result = await mockFirebaseAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password123');

    // Verify that Firebase Auth sign-in method was called
    verify(mockFirebaseAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password123')).called(1);

    // Assert the result
    expect(result, mockUserCredential);
  });
}
