import 'package:flutter/foundation.dart';

class ScanCounter extends ChangeNotifier {
  int _counter = 0;

  int get counter => _counter;

  void setCounter(int newValue) {
    _counter = newValue;
    notifyListeners();
  }
}
