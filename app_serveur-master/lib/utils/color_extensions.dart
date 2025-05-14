// lib/utils/color_extensions.dart
import 'package:flutter/material.dart';

extension ColorX on Color {
  Color withValues({double? red, double? green, double? blue, double? alpha}) {
    final redValue = (red != null) ? (red * 255).round() : this.red;
    final greenValue = (green != null) ? (green * 255).round() : this.green;
    final blueValue = (blue != null) ? (blue * 255).round() : this.blue;
    final alphaValue = (alpha != null) ? (alpha * 255).round() : this.alpha;
    
    return Color.fromARGB(
      alphaValue.clamp(0, 255),
      redValue.clamp(0, 255),
      greenValue.clamp(0, 255),
      blueValue.clamp(0, 255),
    );
  }
}