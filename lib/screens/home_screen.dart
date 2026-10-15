import 'package:flutter/material.dart';

import '../models/trip_draft.dart';
import '../models/course_basket.dart';
import '../theme/app_theme.dart';
import '../widgets/preference_chips.dart';
import '../widgets/sample_course_card.dart';
import '../widgets/trip_controls.dart';
import '../widgets/trip_bottom_navigation.dart';
import 'explore_screen.dart';
import 'selected_places_screen.dart';
import 'trip_conditions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.draft});

  final TripDraft draft;

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature 기능은 준비 중이에요.')));
  }

  Future<void> _openConditions(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TripConditionsScreen(draft: draft)),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조건을 저장했어요. 코스 추천은 준비 중이에요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '경산 여행',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '남는 시간,\n경산 한 바퀴',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '출발지와 시간을 알려주면 여행 코스를 만들어드려요.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: double.infinity,
                        height: 160,
                        child: Image.asset(
                          'assets/images/lake_walk.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: AppTheme.softGreen,
                            child: Center(
                              child: Icon(
                                Icons.landscape_outlined,
                                color: AppTheme.accent,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '여행 만들기',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TripControls(draft: draft),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _openConditions(context),
                              child: const Text('내 코스 만들기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      '어떤 여행을 좋아하세요?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '끌리는 취향을 골라주세요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    PreferenceChips(draft: draft),
                    const SizedBox(height: 30),
                    Text(
                      '이런 하루는 어때요?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '아래 코스는 화면 예시를 위한 샘플이에요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    SampleCourseCard(
                      imagePath: 'assets/images/lake_walk.png',
                      title: '호수 산책과 느긋한 카페',
                      subtitle: '자연 · 카페  /  반나절 샘플',
                      onTap: () => _showComingSoon(context, '샘플 코스 상세'),
                    ),
                    const SizedBox(height: 14),
                    SampleCourseCard(
                      imagePath: 'assets/images/culture_walk.png',
                      title: '문화 산책과 맛있는 한 끼',
                      subtitle: '문화 · 맛집  /  반나절 샘플',
                      onTap: () => _showComingSoon(context, '샘플 코스 상세'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: TripBottomNavigation(
        selectedIndex: 0,
        onHome: () {},
        onExplore: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ExploreScreen())),
        onCourses: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SelectedPlacesScreen(basket: CourseBasket.instance),
          ),
        ),
      ),
    );
  }
}
