import 'package:flutter/material.dart';

/// Pure Black Devotional Sanctum Background for Pushp Varsha.
/// Provides a pristine, high-contrast black canvas so that falling flower petals,
/// golden impact sparks, and the progressive emergence of Lord Shri Ram stand out
/// with extraordinary brilliance and devotional focus.
class PushpTempleBackground extends StatelessWidget {
  final double ambientTime;
  final double sunbeamIntensity;

  const PushpTempleBackground({
    super.key,
    this.ambientTime = 0.0,
    this.sunbeamIntensity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
    );
  }
}
