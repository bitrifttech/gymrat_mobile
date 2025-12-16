import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DayChangeNotifier extends ChangeNotifier with WidgetsBindingObserver {
  DayChangeNotifier() : _currentDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day) {
    _startTimer();
    WidgetsBinding.instance.addObserver(this);
  }

  DateTime _currentDate;
  Timer? _timer;

  DateTime get currentDate => _currentDate;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkDayChange();
    });
  }

  void _checkDayChange() {
    final now = _dateOnly(DateTime.now());
    if (now != _currentDate) {
      _currentDate = now;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDayChange();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final dayChangeNotifierProvider = ChangeNotifierProvider<DayChangeNotifier>((ref) {
  return DayChangeNotifier();
});

final currentDateProvider = Provider<DateTime>((ref) {
  final notifier = ref.watch(dayChangeNotifierProvider);
  return notifier.currentDate;
});
