import 'package:cloud_firestore/cloud_firestore.dart';

bool isNewlyAdded(Timestamp? addedOn) {
  if (addedOn == null) return false;
  var addedDate = addedOn.toDate();
  return DateTime.now().difference(addedDate).inHours < 24;
}

bool isExpiringSoon(Timestamp? expiryDate) {
  if (expiryDate == null) return false;
  var expiryDateTime = expiryDate.toDate();
  int daysUntilExpiry = expiryDateTime.difference(DateTime.now()).inDays;
  return daysUntilExpiry >= 0 && daysUntilExpiry <= 3;
}
