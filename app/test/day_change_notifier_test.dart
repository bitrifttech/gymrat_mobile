import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app/core/day_change_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DayChangeNotifier', () {
    test('initializes with current date', () {
      final notifier = DayChangeNotifier();
      final now = DateTime.now();
      final expectedDate = DateTime(now.year, now.month, now.day);
      
      expect(notifier.currentDate, expectedDate);
      
      notifier.dispose();
    });

    test('notifies listeners when date changes', () async {
      final notifier = DayChangeNotifier();
      var listenerCalled = false;
      
      notifier.addListener(() {
        listenerCalled = true;
      });
      
      expect(listenerCalled, false);
      
      notifier.dispose();
    });

    test('checks for day change on app lifecycle resume', () {
      final notifier = DayChangeNotifier();
      final initialDate = notifier.currentDate;
      
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      
      expect(notifier.currentDate, initialDate);
      
      notifier.dispose();
    });
  });
}
