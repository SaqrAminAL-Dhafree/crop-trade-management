
import 'package:flutter/material.dart';

class AppState {
  static ValueNotifier<int> refresh = ValueNotifier(0);

  static void notify() {
    refresh.value++;
  }
}

