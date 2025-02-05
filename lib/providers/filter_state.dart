import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterStateNotifier extends StateNotifier<String> {
  FilterStateNotifier() : super('All'); // Default to 'All'

  void setFilter(String filter) {
    state = filter;
  }
}

final filterStateProvider = StateNotifierProvider<FilterStateNotifier, String>((ref) {
  return FilterStateNotifier();
});
