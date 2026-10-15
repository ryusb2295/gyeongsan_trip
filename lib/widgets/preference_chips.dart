import 'package:flutter/material.dart';

import '../models/trip_draft.dart';
import '../theme/app_theme.dart';

class PreferenceChips extends StatelessWidget {
  const PreferenceChips({super.key, required this.draft});

  final TripDraft draft;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: draft,
      builder: (context, _) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: ['자연', '문화', '카페', '맛집'].map((label) {
          final selected = draft.preferences.contains(label);
          return FilterChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => draft.togglePreference(label),
            selectedColor: AppTheme.softGreen,
            backgroundColor: Colors.white,
            side: BorderSide(color: selected ? AppTheme.accent : AppTheme.line),
            labelStyle: TextStyle(
              color: selected ? AppTheme.accent : AppTheme.ink,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }).toList(),
      ),
    );
  }
}
