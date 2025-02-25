import 'package:equatable/equatable.dart';

class NotificationState extends Equatable {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    required this.notifications,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<Map<String, dynamic>>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [notifications, isLoading, error];
}