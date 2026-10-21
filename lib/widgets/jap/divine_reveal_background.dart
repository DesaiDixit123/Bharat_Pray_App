import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/jap_customization_models.dart';
import '../../models/jap_models.dart';
import 'live_darshan_view.dart';

/// Renders the immersive full-screen background with progressive divine image reveal,
/// dark devotional vignettes, and seamless transition into the AI-Powered/Living Darshan on 100% completion.
class DivineRevealBackground extends StatelessWidget {
  final ImageProvider? imageProvider;
  final String deityId;
  final String deityName;
  final int count;
  final int target;
  final JapStartingStyle startingStyle;
  final JapRevealStyle revealStyle;
  final EffectPack effectPack;
  final bool isCompleted;
  final Color? activeColor;
  final Color? glowColor;

  const DivineRevealBackground({
    super.key,
    required this.imageProvider,
    this.deityId = 'shri_radha',
    required this.deityName,
    required this.count,
    this.target = 108,
    required this.startingStyle,
    required this.revealStyle,
    required this.effectPack,
    required this.isCompleted,
    this.activeColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final double rawProgress = target > 0 ? (count / target).clamp(0.0, 1.0) : 0.0;
    final double progress = isCompleted ? 1.0 : rawProgress;

    // Calculate baseline visibility according to starting style
    double baseVisibility = 0.0;
    switch (startingStyle) {
      case JapStartingStyle.pureBlack:
      case JapStartingStyle.minimalCounter:
        baseVisibility = 0.0; // 100% pure black starting state
        break;
      case JapStartingStyle.blackWithParticles:
        baseVisibility = 0.02;
        break;
      case JapStartingStyle.gradualReveal:
        baseVisibility = 0.12; // Faint silhouette from start
        break;
      case JapStartingStyle.goldenTemple:
      case JapStartingStyle.cosmicGlow:
        baseVisibility = 0.06;
        break;
    }

    // Effective image visibility (from base to 1.0)
    final double effectiveProgress = (baseVisibility + (progress * (1.0 - baseVisibility))).clamp(0.0, 1.0);

    return Container(
      color: Colors.black, // Guaranteed deep black baseline
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Atmosphere base gradient (Temple, Cosmic, Midnight)
          _buildAtmosphereLayer(startingStyle),

          // 2. Deity Artwork with progressive reveal shader (transitions into LiveDarshanView on 100% complete)
          if (imageProvider != null && effectiveProgress > 0.001)
            _buildRevealedImage(context, effectiveProgress),

          // 3. Central & Edge Vignettes (Ensures circular mala & counter remain 100% readable)
          _buildDevotionalVignette(progress),
        ],
      ),
    );
  }

  Widget _buildAtmosphereLayer(JapStartingStyle style) {
    switch (style) {
      case JapStartingStyle.goldenTemple:
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.2),
              radius: 1.2,
              colors: [
                Color(0x33FFA000),
                Color(0x1A8D4004),
                Colors.black,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        );
      case JapStartingStyle.cosmicGlow:
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.1),
              radius: 1.3,
              colors: [
                Color(0x331A237E),
                Color(0x220D47A1),
                Colors.black,
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        );
      case JapStartingStyle.pureBlack:
      case JapStartingStyle.minimalCounter:
      case JapStartingStyle.blackWithParticles:
      case JapStartingStyle.gradualReveal:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRevealedImage(BuildContext context, double p) {
    if (isCompleted) {
      // 100% Reveal: Full-Screen Devotional Living Darshan (AI video / Local breathing & radiant engine)
      return LiveDarshanView(
        imageProvider: imageProvider!,
        deityId: deityId,
        deityName: deityName,
        activeColor: activeColor ?? effectPack.primaryColor,
        glowColor: glowColor ?? effectPack.haloGlowColor,
      );
    }

    final imageWidget = Image(
      image: imageProvider!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        JapConfig.defaultDeityImage(deityName),
        fit: BoxFit.cover,
      ),
    );

    switch (revealStyle) {
      case JapRevealStyle.radialCenter:
        // Radial mask expanding outward from deity's face (center 0.0, -0.15)
        final double innerRadius = math.max(0.05, p * 0.9);
        final double outerRadius = math.min(1.4, innerRadius + 0.35);
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            return RadialGradient(
              center: const Alignment(0.0, -0.12),
              radius: outerRadius,
              colors: [
                Colors.white.withValues(alpha: math.min(1.0, p * 1.4)),
                Colors.white.withValues(alpha: math.max(0.0, (p - 0.15) * 1.2)),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ).createShader(bounds);
          },
          child: imageWidget,
        );

      case JapRevealStyle.goldenCircleExpansion:
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            return RadialGradient(
              center: const Alignment(0.0, -0.1),
              radius: math.max(0.1, p * 1.3),
              colors: const [
                Colors.white,
                Colors.white70,
                Colors.transparent,
              ],
              stops: const [0.0, 0.85, 1.0],
            ).createShader(bounds);
          },
          child: imageWidget,
        );

      case JapRevealStyle.topBottomLightSweep:
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            final double sweepY = -1.0 + (p * 2.2);
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                0.0,
                (sweepY.clamp(-1.0, 1.0) + 1.0) / 2.0,
                math.min(1.0, ((sweepY + 0.4).clamp(-1.0, 1.0) + 1.0) / 2.0),
              ],
            ).createShader(bounds);
          },
          child: imageWidget,
        );

      case JapRevealStyle.clarityBrightness:
      case JapRevealStyle.silhouetteDissolve:
      case JapRevealStyle.particleReveal:
        // Smooth opacity & contrast transition
        final double opacity = (p * 1.05).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: imageWidget,
        );
    }
  }

  Widget _buildDevotionalVignette(double progress) {
    // Atmospheric dark vignette that keeps borders dark and center counter legible
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, 0.0),
            radius: 1.15,
            colors: [
              Colors.black.withValues(alpha: isCompleted ? 0.06 : 0.15),
              Colors.black.withValues(alpha: isCompleted ? 0.28 : 0.55),
              Colors.black.withValues(alpha: isCompleted ? 0.72 : 0.92),
            ],
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
      ),
    );
  }
}
