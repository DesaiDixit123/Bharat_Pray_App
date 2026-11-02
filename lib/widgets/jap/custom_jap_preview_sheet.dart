import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cinematic_jap/progressive_ram_reveal_painter.dart';
import '../cinematic_jap/ram_path_calculator.dart';
import '../dhup_jap/dhup_burner_widget.dart';
import '../dhup_jap/dhup_incense_reveal_painter.dart';

/// The Jap experiences a devotee can choose when creating a custom Jap.
class CustomJapEffect {
  final String value;
  final String label;
  final String description;

  const CustomJapEffect({
    required this.value,
    required this.label,
    required this.description,
  });

  static const List<CustomJapEffect> all = [
    CustomJapEffect(
      value: 'ram',
      label: 'Divine Name Reveal',
      description:
          'With every chant, the sacred name flies up and reveals a part of the deity.',
    ),
    CustomJapEffect(
      value: 'dhup',
      label: 'Dhoop Smoke Reveal',
      description:
          'With every chant, incense smoke rises from the dhoop and unveils the deity.',
    ),
  ];
}

/// Plays a short looping demo of a Jap effect, using the chosen god image if any.
class CustomJapPreviewSheet extends StatefulWidget {
  final CustomJapEffect effect;
  final String? imagePath;

  const CustomJapPreviewSheet({
    super.key,
    required this.effect,
    this.imagePath,
  });

  static Future<void> show(
    BuildContext context, {
    required CustomJapEffect effect,
    String? imagePath,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomJapPreviewSheet(effect: effect, imagePath: imagePath),
    );
  }

  @override
  State<CustomJapPreviewSheet> createState() => _CustomJapPreviewSheetState();
}

class _CustomJapPreviewSheetState extends State<CustomJapPreviewSheet>
    with SingleTickerProviderStateMixin {
  static const int _previewChants = 27;
  static const String _sampleImage = 'assets/images/lord_shri_ram_darshan.png';

  late final AnimationController _controller;

  bool get _isDhup => widget.effect.value == 'dhup';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildReveal(List<RevealNode> nodes, int count, bool isCompleted) {
    final image = widget.imagePath ?? _sampleImage;
    final progress = count / _previewChants;
    if (_isDhup) {
      return DhupIncenseRevealWidget(
        revealedNodes: nodes,
        shimmerProgress: 1.0,
        isCompleted: isCompleted,
        completionGlowProgress: isCompleted ? 1.0 : 0.0,
        imageAsset: image,
        revealProgress: progress,
      );
    }
    return ProgressiveRamRevealWidget(
      revealedNodes: nodes,
      shimmerProgress: 1.0,
      isCompleted: isCompleted,
      completionGlowProgress: isCompleted ? 1.0 : 0.0,
      imageAsset: image,
      revealProgress: progress,
    );
  }

  Widget _buildPreviewStage() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Chant through 85% of the loop, then hold on the completed darshan.
        final exact = math.min(1.0, _controller.value / 0.85) * _previewChants;
        final count = exact.floor().clamp(0, _previewChants);
        final isCompleted = count >= _previewChants;
        final nodes = RamPathCalculator.getRevealedNodesForCount(
          count,
          target: _previewChants,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final dstRect = RamPathCalculator.computeDstRect(size);
            final node = RamPathCalculator.getNodeForStep(
              math.min(count, _previewChants - 1),
              target: _previewChants,
            );
            final flight = Curves.easeOut.transform(exact - exact.floorToDouble());
            final start = Offset(size.width / 2, size.height * 0.84);
            final end = Offset(
              dstRect.left + node.u * dstRect.width,
              dstRect.top + node.v * dstRect.height,
            );
            final position = Offset.lerp(start, end, flight)!;

            return Stack(
              fit: StackFit.expand,
              children: [
                _buildReveal(nodes, count, isCompleted),
                if (_isDhup)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: DhupBurnerWidget(emberGlow: _controller.value),
                  ),
                if (!isCompleted)
                  Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: Opacity(
                        opacity: (1.0 - flight * 0.35).clamp(0.0, 1.0),
                        child: Text(
                          'राम',
                          style: GoogleFonts.notoSerifDevanagari(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD54F),
                            shadows: const [
                              Shadow(color: Color(0xFFFF7700), blurRadius: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count / $_previewChants',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0E6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.effect.label,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF8C7355)),
                ),
              ],
            ),
            Text(
              widget.effect.description,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildPreviewStage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
