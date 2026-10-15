import 'dart:math' as math;

import 'place.dart';

/// Flags coordinate outliers for review; this is not an administrative boundary.
List<Place> flagLocationOutliers(List<Place> places) {
  final geocoded = places
      .where((place) => place.latitude != null && place.longitude != null)
      .toList();
  if (geocoded.length < 3) return places;
  final latitudes = geocoded.map((place) => place.latitude!).toList()..sort();
  final longitudes = geocoded.map((place) => place.longitude!).toList()..sort();
  final centerLat = _median(latitudes);
  final centerLon = _median(longitudes);
  return places.map((place) {
    if (place.latitude == null || place.longitude == null) return place;
    final distance = _distanceKm(
      centerLat,
      centerLon,
      place.latitude!,
      place.longitude!,
    );
    return distance > 30 ? place.withFlag('좌표 위치 확인 필요') : place;
  }).toList();
}

double _median(List<double> sorted) {
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const radians = math.pi / 180;
  final latitudeDelta = (lat2 - lat1) * radians;
  final longitudeDelta = (lon2 - lon1) * radians;
  final a =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(lat1 * radians) *
          math.cos(lat2 * radians) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  return 6371 * 2 * math.asin(math.sqrt(a));
}
