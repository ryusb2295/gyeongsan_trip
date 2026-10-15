import 'package:flutter/material.dart';

import '../models/course_basket.dart';
import '../theme/app_theme.dart';
import '../widgets/place_photo.dart';
import '../widgets/trip_bottom_navigation.dart';
import 'explore_screen.dart';

class SelectedPlacesScreen extends StatelessWidget {
  const SelectedPlacesScreen({
    super.key,
    required this.basket,
    this.returnToExplore = false,
  });

  final CourseBasket basket;
  final bool returnToExplore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('담은 장소')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: basket,
          builder: (context, _) {
            final places = basket.places;
            if (places.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.route_outlined,
                        size: 42,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '담은 장소가 없어요',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('둘러보기에서 장소를 코스에 담아보세요.'),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: places.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '${places.length}곳을 담았어요 · 자동 코스 구성은 준비 중이에요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                final place = places[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.line),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 76,
                          child: PlacePhoto(
                            imageUrl: place.imageUrl,
                            height: 80,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            place.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: '${place.title} 삭제',
                          onPressed: () => basket.remove(place.id),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: TripBottomNavigation(
        selectedIndex: 2,
        onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
        onExplore: () {
          if (returnToExplore) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ExploreScreen(basket: basket)),
            );
          }
        },
        onCourses: () {},
      ),
    );
  }
}
