import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelfaware_app/repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepository;

  UserService(this._userRepository);

  Future<Map<String, dynamic>> getUserData(String userId) async {
    return await _userRepository.getUserData(userId);
  }

  Future<double?> fetchDonorRating(String donorId) async {
    return await _userRepository.fetchDonorRating(donorId);
  }

  Future<String?> fetchProfileImageUrl(String userId) async {
    return await _userRepository.fetchProfileImageUrl(userId);
  }

  Future<String> fetchDonorProfileImageUrl(String userId) async {
    return await _userRepository.fetchDonorProfileImageUrl(userId);
  }

  Future<void> updateUserBio(String userId, String newBio) async {
    try {
      await _userRepository.updateUserBio(userId, newBio);
    } catch (e) {
      print('Error updating user bio: $e');
      throw e;
    }
  }
}
