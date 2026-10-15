import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PlacePhoto extends StatelessWidget {
  const PlacePhoto({super.key, required this.imageUrl, required this.height});

  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppTheme.softGreen,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          color: AppTheme.accent,
          size: height < 110 ? 28 : 44,
        ),
      ),
    );
    return SizedBox(
      width: double.infinity,
      height: height,
      child: imageUrl == null || imageUrl!.isEmpty
          ? placeholder
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );
  }
}
