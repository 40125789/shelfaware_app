import 'package:shelfaware_app/models/mark_food.dart';
import 'package:shelfaware_app/repositories/mark_food_respository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MarkFoodService {
  final MarkFoodRepository _repository = MarkFoodRepository();

  Future<MarkFood?> getFoodItem(String documentId) async {
    return await _repository.fetchFoodItem(documentId);
  }

  Future<void> markAsConsumed(MarkFood foodItem, int quantity) async {
    int remainingQuantity = foodItem.quantity - quantity;

    await _repository.addHistory({
      ...foodItem.toMap(),
      'status': 'consumed',
      'consumedQuantity': quantity,
      'updatedOn': Timestamp.now(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });

    if (remainingQuantity == 0) {
      await _repository.deleteFoodItem(foodItem.id);
    } else {
      await _repository.updateFoodItem(foodItem.copyWith(quantity: remainingQuantity));
    }
  }

  Future<void> markAsDiscarded(MarkFood foodItem, String reason, int quantity) async {
    int remainingQuantity = foodItem.quantity - quantity;

    await _repository.addHistory({
      ...foodItem.toMap(),
      'reason': reason,
      'status': 'discarded',
      'discardedQuantity': quantity,
      'updatedOn': Timestamp.now(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });

    if (remainingQuantity == 0) {
      await _repository.deleteFoodItem(foodItem.id);
    } else {
      await _repository.updateFoodItem(foodItem.copyWith(quantity: remainingQuantity));
    }
  }
}