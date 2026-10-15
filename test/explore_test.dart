import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeongsan_trip/models/place.dart';
import 'package:gyeongsan_trip/models/course_basket.dart';
import 'package:gyeongsan_trip/models/place_quality.dart';
import 'package:gyeongsan_trip/screens/explore_screen.dart';
import 'package:gyeongsan_trip/services/tour_api_service.dart';

class FakeTourApiService extends TourApiService {
  FakeTourApiService({this.failFirst = false});

  bool failFirst;
  int calls = 0;

  @override
  Future<PlacePage> getPlaces({int page = 1}) async {
    calls++;
    if (failFirst) {
      failFirst = false;
      throw const TourApiException('테스트 통신 실패');
    }
    return const PlacePage(
      items: [
        Place(
          id: '123',
          title: '테스트 장소',
          category: '관광지',
          address: '경상북도 경산시 테스트로',
        ),
      ],
      totalCount: 1,
    );
  }

  @override
  Future<PlaceDetail> getPlace(String id) async => const PlaceDetail(
    id: '123',
    title: '테스트 장소',
    category: '관광지',
    address: '경상북도 경산시 테스트로',
    source: '한국관광공사 TourAPI 국문 관광정보 서비스',
    sourceUrl: 'https://www.data.go.kr/data/15101578/openapi.do',
  );
}

class PagedTourApiService extends TourApiService {
  final List<int> pagesRequested = [];

  @override
  Future<PlacePage> getPlaces({int page = 1}) async {
    pagesRequested.add(page);
    return PlacePage(
      items: page == 1
          ? const [Place(id: '1', title: '산책 장소', category: '관광지')]
          : const [Place(id: '2', title: '식당 장소', category: '음식점')],
      totalCount: 2,
    );
  }
}

void main() {
  testWidgets('browse list opens details and marks missing fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: ExploreScreen(service: FakeTourApiService())),
    );
    await tester.pumpAndSettle();
    expect(find.text('테스트 장소'), findsOneWidget);
    await tester.tap(find.text('테스트 장소'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('데이터 출처: 한국관광공사 TourAPI 국문 관광정보 서비스'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('데이터 출처: 한국관광공사 TourAPI 국문 관광정보 서비스'), findsOneWidget);
    expect(find.text('정보 없음'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('communication failure offers retry', (tester) async {
    final service = FakeTourApiService(failFirst: true);
    await tester.pumpWidget(MaterialApp(home: ExploreScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('테스트 통신 실패'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('테스트 장소'), findsOneWidget);
    expect(service.calls, 2);
  });

  testWidgets(
    'loads every page, filters observed categories, and removes a saved place',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = PagedTourApiService();
      final basket = CourseBasket();
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(service: service, basket: basket),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.pagesRequested, [1, 2]);
      expect(find.text('음식점 1'), findsOneWidget);
      expect(find.textContaining('카페'), findsNothing);
      await tester.ensureVisible(find.text('음식점 1'));
      await tester.tap(find.text('음식점 1'));
      await tester.pumpAndSettle();
      expect(find.text('식당 장소'), findsOneWidget);
      expect(find.text('산책 장소'), findsNothing);
      await tester.ensureVisible(find.text('코스에 담기'));
      await tester.tap(find.text('코스에 담기'));
      await tester.pumpAndSettle();
      expect(basket.places.length, 1);
      expect(basket.add(basket.places.single), isFalse);
      await tester.tap(find.text('내 코스'));
      await tester.pumpAndSettle();
      expect(find.text('식당 장소'), findsOneWidget);
      await tester.tap(find.byTooltip('식당 장소 삭제'));
      await tester.pumpAndSettle();
      expect(basket.places, isEmpty);
      expect(find.text('담은 장소가 없어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('flags distant coordinates without removing the place', () {
    final result = flagLocationOutliers(const [
      Place(
        id: '1',
        title: '가',
        category: '관광지',
        latitude: 35.82,
        longitude: 128.77,
      ),
      Place(
        id: '2',
        title: '나',
        category: '관광지',
        latitude: 35.83,
        longitude: 128.78,
      ),
      Place(
        id: '3',
        title: '다',
        category: '관광지',
        latitude: 37.56,
        longitude: 126.98,
      ),
    ]);
    expect(result.length, 3);
    expect(result.last.qualityFlags, contains('좌표 위치 확인 필요'));
  });
}
