import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SportHubLogoMark extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? border;

  const SportHubLogoMark({
    super.key,
    required this.size,
    this.backgroundColor = Colors.white,
    this.foregroundColor = AppColors.primaryDarkGreen,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'UNESA SportHub logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size * 0.35),
          border: border,
          boxShadow: boxShadow,
        ),
        child: Icon(
          Icons.sports_soccer,
          color: foregroundColor,
          size: size * 0.57,
        ),
      ),
    );
  }
}
