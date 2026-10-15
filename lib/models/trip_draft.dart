import 'package:flutter/material.dart';

class TripDraft extends ChangeNotifier {
  String departure = '';
  DateTime date = DateUtils.dateOnly(DateTime.now());
  TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
  final Set<String> preferences = <String>{};

  bool get hasValidTime =>
      endTime.hour * 60 + endTime.minute >
      startTime.hour * 60 + startTime.minute;

  void setDeparture(String value) {
    departure = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    date = DateUtils.dateOnly(value);
    notifyListeners();
  }

  void setStartTime(TimeOfDay value) {
    startTime = value;
    notifyListeners();
  }

  void setEndTime(TimeOfDay value) {
    endTime = value;
    notifyListeners();
  }

  void togglePreference(String value) {
    if (!preferences.add(value)) preferences.remove(value);
    notifyListeners();
  }
}
