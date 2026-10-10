import 'package:flutter/material.dart';
import 'jap_animation_type.dart';
import 'effects/radha_name_painter.dart';
import 'effects/ram_spread_painter.dart';
import 'effects/incense_smoke_painter.dart';
import 'effects/mantra_light_painter.dart';
import 'effects/divine_energy_painter.dart';
import 'effects/sacred_mandala_painter.dart';

/// Renders the active premium devotional animation overlay over the deity portrait.
class PremiumJapAnimator extends StatelessWidget {
  final JapAnimationType animationType;
  final double progress; // 0.0 to 1.0
  final bool isPlaying;
  final String deityName;
  final String currentMantra;
  final Offset revealPoint;
  final double seed;

  const PremiumJapAnimator({
    super.key,
    required this.animationType,
    required this.progress,
    required this.isPlaying,
    required this.deityName,
    required this.currentMantra,
    required this.revealPoint,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPlaying) {
      return const SizedBox.shrink();
    }

    CustomPainter painter;

    switch (animationType) {
      case JapAnimationType.radhaName:
        painter = RadhaNamePainter(
          progress: progress,
          revealPoint: revealPoint,
          seed: seed,
        );
        break;

      case JapAnimationType.ramSpread:
        painter = RamSpreadPainter(
          progress: progress,
          revealPoint: revealPoint,
          seed: seed,
        );
        break;

      case JapAnimationType.incenseSmoke:
        painter = IncenseSmokePainter(
          progress: progress,
          revealPoint: revealPoint,
          seed: seed,
        );
        break;

      case JapAnimationType.mantraLight:
        painter = MantraLightPainter(
          progress: progress,
          mantra: currentMantra,
          revealPoint: revealPoint,
          seed: seed,
        );
        break;

      case JapAnimationType.divineEnergy:
        painter = DivineEnergyPainter(
          progress: progress,
          revealPoint: revealPoint,
          seed: seed,
        );
        break;

      case JapAnimationType.sacredMandala:
        painter = SacredMandalaPainter(
          progress: progress,
          revealPoint: revealPoint,
          seed: seed,
        );
        break;

      default:
        return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: painter,
        size: Size.infinite,
      ),
    );
  }
}
