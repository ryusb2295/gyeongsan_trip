import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/trip_draft.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const GyeongsanTripApp());

class GyeongsanTripApp extends StatefulWidget {
  const GyeongsanTripApp({super.key});

  @override
  State<GyeongsanTripApp> createState() => _GyeongsanTripAppState();
}

class _GyeongsanTripAppState extends State<GyeongsanTripApp> {
  final TripDraft draft = TripDraft();

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '경산 여행',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeScreen(draft: draft),
    );
  }
}
