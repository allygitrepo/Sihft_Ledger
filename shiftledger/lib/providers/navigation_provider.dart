import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);
  
  void setIndex(int index) {
    state = index;
  }
}

// Provider for navigation management
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});