import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/course_basket.dart';
import '../models/place_quality.dart';
import '../services/tour_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/place_photo.dart';
import '../widgets/trip_bottom_navigation.dart';
import 'place_detail_screen.dart';
import 'selected_places_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.service, this.basket});

  final TourApiService? service;
  final CourseBasket? basket;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TourApiService _service = widget.service ?? TourApiService();
  late final CourseBasket _basket = widget.basket ?? CourseBasket.instance;
  List<Place> _places = [];
  String? _selectedCategory;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final first = await _service.getPlaces();
      final places = [...first.items];
      var page = 1;
      while (places.length < first.totalCount) {
        final next = await _service.getPlaces(page: ++page);
        if (next.items.isEmpty) break;
        places.addAll(next.items);
      }
      if (!mounted) return;
      setState(() {
        _places = flagLocationOutliers(places);
        if (!_places.any((place) => place.category == _selectedCategory)) {
          _selectedCategory = null;
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error is TourApiException
          ? error.message
          : '관광정보를 표시하지 못했어요.';
      setState(() {
        _loading = false;
        _error = message;
      });
    }
  }

  void _openSelected() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SelectedPlacesScreen(basket: _basket, returnToExplore: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = _StatusView(
        icon: Icons.wifi_off_outlined,
        title: '장소를 불러오지 못했어요',
        message: _error!,
        onRetry: _load,
      );
    } else if (_places.isEmpty) {
      content = _StatusView(
        icon: Icons.search_off_outlined,
        title: '표시할 장소가 없어요',
        message: '현재 TourAPI에서 제공하는 경산시 장소가 없습니다.',
        onRetry: _load,
      );
    } else {
      final counts = <String, int>{};
      for (final place in _places) {
        counts.update(place.category, (value) => value + 1, ifAbsent: () => 1);
      }
      final filtered = _selectedCategory == null
          ? _places
          : _places
                .where((place) => place.category == _selectedCategory)
                .toList();
      content = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: filtered.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '경산 둘러보기',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '한국관광공사 TourAPI가 제공하는 장소예요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('전체', _places.length, null),
                        for (final entry in counts.entries) ...[
                          const SizedBox(width: 8),
                          _filterChip(entry.key, entry.value, entry.key),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }
            final place = filtered[index - 1];
            return _PlaceTile(
              place: place,
              basket: _basket,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PlaceDetailScreen(place: place, service: _service),
                ),
              ),
            );
          },
        ),
      );
    }
    return Scaffold(
      body: SafeArea(child: content),
      bottomNavigationBar: TripBottomNavigation(
        selectedIndex: 1,
        onHome: () => Navigator.of(context).pop(),
        onExplore: () {},
        onCourses: _openSelected,
      ),
    );
  }

  Widget _filterChip(String label, int count, String? category) {
    return ChoiceChip(
      label: Text('$label $count'),
      selected: _selectedCategory == category,
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.basket,
    required this.onTap,
  });

  final Place place;
  final CourseBasket basket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 108,
              child: PlacePhoto(imageUrl: place.imageUrl, height: 112),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.category,
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address ?? '주소 정보 없음',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (place.qualityFlags.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        place.qualityFlags.join(' · '),
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: basket,
                      builder: (context, _) {
                        final selected = basket.contains(place.id);
                        return OutlinedButton.icon(
                          onPressed: selected ? null : () => basket.add(place),
                          icon: Icon(
                            selected ? Icons.check : Icons.add,
                            size: 16,
                          ),
                          label: Text(selected ? '담았어요' : '코스에 담기'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.accent, size: 44),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
