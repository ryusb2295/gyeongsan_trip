import 'package:flutter/material.dart';

import '../models/trip_draft.dart';
import '../theme/app_theme.dart';
import '../widgets/preference_chips.dart';
import '../widgets/trip_controls.dart';

class TripConditionsScreen extends StatefulWidget {
  const TripConditionsScreen({super.key, required this.draft});

  final TripDraft draft;

  @override
  State<TripConditionsScreen> createState() => _TripConditionsScreenState();
}

class _TripConditionsScreenState extends State<TripConditionsScreen> {
  late final TextEditingController _departureController;

  @override
  void initState() {
    super.initState();
    _departureController = TextEditingController(text: widget.draft.departure);
  }

  @override
  void dispose() {
    _departureController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    widget.draft.setDeparture(_departureController.text.trim());
    if (widget.draft.departure.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('출발지를 입력해 주세요.')));
      return;
    }
    if (!widget.draft.hasValidTime) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 해요.')));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('여행 조건')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '나에게 맞는 경산 여행',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '출발지와 여행할 시간을 알려주세요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    Text('출발지', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _departureController,
                      textInputAction: TextInputAction.done,
                      onChanged: widget.draft.setDeparture,
                      decoration: InputDecoration(
                        hintText: '예: 경산역, 영남대역',
                        prefixIcon: const Icon(
                          Icons.place_outlined,
                          color: AppTheme.accent,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.line),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '날짜와 시간',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TripControls(
                        draft: widget.draft,
                        showDeparture: false,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '여행 취향',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    PreferenceChips(draft: widget.draft),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('조건 저장'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        '코스 추천 기능은 준비 중이에요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
