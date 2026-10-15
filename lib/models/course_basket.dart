import 'package:flutter/foundation.dart';

import 'place.dart';

class CourseBasket extends ChangeNotifier {
  CourseBasket();

  static final CourseBasket instance = CourseBasket();
  final Map<String, Place> _places = {};

  List<Place> get places => List.unmodifiable(_places.values);
  bool contains(String id) => _places.containsKey(id);

  bool add(Place place) {
    if (_places.containsKey(place.id)) return false;
    _places[place.id] = place;
    notifyListeners();
    return true;
  }

  void remove(String id) {
    if (_places.remove(id) != null) notifyListeners();
  }
}
