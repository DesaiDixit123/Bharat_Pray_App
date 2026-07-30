import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class YatraStopProgressScreen extends StatefulWidget {
  final String journeyId;
  final VoidCallback? onContinue;

  const YatraStopProgressScreen({
    super.key,
    required this.journeyId,
    this.onContinue,
  });

  @override
  State<YatraStopProgressScreen> createState() => _YatraStopProgressScreenState();
}

class _YatraStopProgressScreenState extends State<YatraStopProgressScreen> {
  bool _isLoading = true;
  double _progress = 0.75;
  String _distanceCovered = '337.5 km';
  String _distanceRemaining = '112.5 km';
  String _stepsToday = '12,457';
  String _totalSteps = '1,08,000';
  String _yatraTitle = 'Yatra to Chidambaram';

  static const Color _bg = Color(0xFFFFE8D6);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF2E2A36);
  static const Color _textMuted = Color(0xFF8A7769);
  static const Color _accent = Color(0xFFFF7A00);
  static const Color _green = Color(0xFF2E8A3A);
  static const Color _red = Color(0xFFD12B2B);
  static const Color _ringTrack = Color(0xFFE8DCCF);

  static const String _backArrowSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''';

  @override
  void initState() {
    super.initState();
    _fetchProgressData();
  }

  Future<void> _fetchProgressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final progressData = await ApiService.getJourneyProgress(token, widget.journeyId);
      final distanceData = await ApiService.getJourneyDistanceRemaining(token, widget.journeyId);

      if (progressData.isNotEmpty || distanceData.isNotEmpty) {
        setState(() {
          _progress = (progressData['progress'] ?? 75) / 100.0;
          _distanceCovered = '${progressData['distanceCovered'] ?? 337.5} km';
          _stepsToday = '${progressData['stepsToday'] ?? '12,457'}';
          _totalSteps = '${progressData['totalSteps'] ?? '1,08,000'}';
          _yatraTitle = progressData['yatraTitle'] ?? 'Yatra to Chidambaram';
          
          _distanceRemaining = '${distanceData['distanceRemaining'] ?? 112.5} km';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.onContinue ?? () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC8A882), width: 1),
                  ),
                  child: Center(
                    child: SvgPicture.string(_backArrowSvg, width: 15, height: 15),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(300, 300),
                        painter: _ProgressRingPainter(
                          progress: _progress,
                          progressColor: _accent,
                          trackColor: _ringTrack,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: GoogleFonts.outfit(
                              color: _textPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Completion',
                            style: GoogleFonts.outfit(
                              color: _textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _yatraTitle,
                  style: GoogleFonts.outfit(
                    color: _textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  'Day 4 of 5 • Sacred Path',
                  style: GoogleFonts.outfit(
                    color: _textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEFE6DB), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distance Covered',
                            style: GoogleFonts.outfit(
                              color: _textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _distanceCovered,
                            style: GoogleFonts.outfit(
                              color: _green,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remaining Distance',
                            style: GoogleFonts.outfit(
                              color: _textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _distanceRemaining,
                            style: GoogleFonts.outfit(
                              color: _red,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoMiniCard(
                      icon: Icons.directions_walk_rounded,
                      title: 'Steps Today',
                      value: _stepsToday,
                      subtitle: 'Goal: 15,000',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoMiniCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Total Steps',
                      value: _totalSteps,
                      subtitle: 'Steps',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _InfoMiniCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFE6DB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFC8A882)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2E2A36),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E2A36),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              color: const Color(0xFF8A7769),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;

  _ProgressRingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}