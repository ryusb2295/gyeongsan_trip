import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeongsan_trip/main.dart';
import 'package:gyeongsan_trip/models/trip_draft.dart';
import 'package:gyeongsan_trip/screens/home_screen.dart';
import 'package:gyeongsan_trip/screens/trip_conditions_screen.dart';
import 'package:gyeongsan_trip/theme/app_theme.dart';

void main() {
  testWidgets('small screen scrolls to the conditions form without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GyeongsanTripApp());
    expect(find.text('남는 시간,\n경산 한 바퀴'), findsOneWidget);
    await tester.ensureVisible(find.text('내 코스 만들기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('내 코스 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('나에게 맞는 경산 여행'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('end time before start time shows an error and keeps the form', (
    tester,
  ) async {
    final draft = TripDraft()
      ..setDeparture('경산역')
      ..setStartTime(const TimeOfDay(hour: 18, minute: 0))
      ..setEndTime(const TimeOfDay(hour: 17, minute: 0));
    addTearDown(draft.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TripConditionsScreen(draft: draft),
      ),
    );
    expect(find.text('종료 시간은 시작 시간보다 늦어야 해요.'), findsOneWidget);
    await tester.ensureVisible(find.text('조건 저장'));
    await tester.tap(find.text('조건 저장'));
    await tester.pump();
    expect(find.byType(TripConditionsScreen), findsOneWidget);
    expect(draft.hasValidTime, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trip inputs and preferences survive screen navigation', (
    tester,
  ) async {
    final draft = TripDraft()..setDeparture('경산역');
    addTearDown(draft.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(draft: draft),
      ),
    );

    await tester.ensureVisible(find.text('자연'));
    await tester.tap(find.text('자연'));
    expect(draft.preferences, contains('자연'));

    await tester.ensureVisible(find.text('내 코스 만들기'));
    await tester.tap(find.text('내 코스 만들기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '경산역'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '자연'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(draft.departure, '경산역');
    expect(draft.preferences, contains('자연'));
    expect(tester.takeException(), isNull);
  });
}
