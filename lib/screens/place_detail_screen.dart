import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/tour_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/place_photo.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({
    super.key,
    required this.place,
    required this.service,
  });

  final Place place;
  final TourApiService service;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late Future<PlaceDetail> _detail = widget.service.getPlace(widget.place.id);

  void _retry() {
    setState(() => _detail = widget.service.getPlace(widget.place.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('장소 정보')),
      body: SafeArea(
        child: FutureBuilder<PlaceDetail>(
          future: _detail,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_outlined,
                        color: AppTheme.accent,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error is TourApiException
                            ? error.message
                            : '상세정보를 불러오지 못했어요.',
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: _retry,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final place = snapshot.requireData;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: PlacePhoto(imageUrl: place.imageUrl, height: 220),
                ),
                const SizedBox(height: 22),
                Text(
                  place.category,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  place.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 22),
                _InfoRow(label: '주소', value: place.address),
                _InfoRow(label: '운영시간', value: place.openingHours),
                _InfoRow(label: '휴무일', value: place.closedDays),
                _InfoRow(label: '요금', value: place.fee),
                _InfoRow(label: '문의', value: place.phone),
                if (place.qualityFlags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    place.qualityFlags.join(' · '),
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ],
                const SizedBox(height: 20),
                Text('소개', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  place.overview ?? '정보 없음',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                const Divider(color: AppTheme.line),
                const SizedBox(height: 8),
                Text(
                  '데이터 출처: ${place.source}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  place.sourceUrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value ?? '정보 없음',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
