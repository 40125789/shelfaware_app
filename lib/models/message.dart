import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderEmail;
  final String receiverEmail;
  final String message;
  final String senderId;
  final String receiverId;
  final bool isRead;
  final Timestamp timestamp;

  Message({
    required this.senderEmail,
    required this.receiverEmail,
    required this.message,
    required this.senderId,
    required this.receiverId,
    required this.isRead,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
      senderEmail: data['senderEmail'] ?? '',
      receiverEmail: data['receiverEmail'] ?? '',
      message: data['message'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      isRead: data['isRead'] ?? false,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
