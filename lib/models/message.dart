import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderEmail;

  final String message;
  final String senderId;
  final String receiverId;
  //final bool isRead;
  final Timestamp timestamp;

  Message({
    required this.senderEmail,
    required this.message,
    required this.senderId,
    required this.receiverId,
    //required this.isRead,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderEmail': senderEmail,
      'message': message,
      'senderId': senderId,
      'receiverId': receiverId,
      //'isRead': isRead,
      'timestamp': timestamp,
    };
  }
}
