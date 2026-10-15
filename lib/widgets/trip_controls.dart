import 'package:flutter/material.dart';

import '../models/trip_draft.dart';
import '../theme/app_theme.dart';

String formatTripDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}. ${date.month}. ${date.day}. (${weekdays[date.weekday - 1]})';
}

String formatTripTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

class TripControls extends StatelessWidget {
  const TripControls({
    super.key,
    required this.draft,
    this.showDeparture = true,
  });

  final TripDraft draft;
  final bool showDeparture;

  Future<void> _pickDeparture(BuildContext context) async {
    final controller = TextEditingController(text: draft.departure);
    try {
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.background,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '어디에서 출발하나요?',
                    style: Theme.of(sheetContext).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: '예: 경산역, 영남대역',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) =>
                        Navigator.pop(sheetContext, value.trim()),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: ['경산역', '영남대역', '경산시청']
                        .map(
                          (place) => ActionChip(
                            label: Text(place),
                            onPressed: () => Navigator.pop(sheetContext, place),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, controller.text.trim()),
                      child: const Text('적용'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (selected != null) draft.setDeparture(selected);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: draft.date.isBefore(today) ? today : draft.date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (selected != null) draft.setDate(selected);
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? draft.startTime : draft.endTime,
    );
    if (selected == null) return;
    if (isStart) {
      draft.setStartTime(selected);
    } else {
      draft.setEndTime(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: draft,
      builder: (context, _) => Column(
        children: [
          if (showDeparture) ...[
            _InputTile(
              icon: Icons.place_outlined,
              label: '출발지',
              value: draft.departure.isEmpty ? '출발지를 선택해 주세요' : draft.departure,
              placeholder: draft.departure.isEmpty,
              onTap: () => _pickDeparture(context),
            ),
            const Divider(height: 1, color: AppTheme.line),
          ],
          _InputTile(
            icon: Icons.calendar_today_outlined,
            label: '여행 날짜',
            value: formatTripDate(draft.date),
            onTap: () => _pickDate(context),
          ),
          const Divider(height: 1, color: AppTheme.line),
          Row(
            children: [
              Expanded(
                child: _InputTile(
                  icon: Icons.schedule_outlined,
                  label: '시작',
                  value: formatTripTime(draft.startTime),
                  onTap: () => _pickTime(context, isStart: true),
                ),
              ),
              const SizedBox(height: 64, child: VerticalDivider(width: 1)),
              Expanded(
                child: _InputTile(
                  icon: Icons.schedule_outlined,
                  label: '종료',
                  value: formatTripTime(draft.endTime),
                  onTap: () => _pickTime(context, isStart: false),
                ),
              ),
            ],
          ),
          if (!draft.hasValidTime)
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '종료 시간은 시작 시간보다 늦어야 해요.',
                  style: TextStyle(color: Color(0xFFB3261E), fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: placeholder ? AppTheme.muted : AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
