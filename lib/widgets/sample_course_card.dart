import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SampleCourseCard extends StatelessWidget {
  const SampleCourseCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 155,
              width: double.infinity,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppTheme.softGreen,
                  child: Center(
                    child: Icon(
                      Icons.landscape_outlined,
                      color: AppTheme.accent,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '샘플 코스',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
