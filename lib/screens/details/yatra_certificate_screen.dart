import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class YatraCertificateScreen extends StatelessWidget {
  const YatraCertificateScreen({super.key});

  static const Color _bg = Color(0xFFFFE8D6);
  static const Color _accent = Color(0xFFFF7A00);
  static const Color _mutedBrown = Color(0xFFC8A882);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 400,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/mandir_door_open.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(color: Colors.black),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2D3A),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sensors, size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              'Live',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 130,
                height: 130,
                child: _TrophyAssetView(mutedBrown: _mutedBrown),
              ),
              const SizedBox(height: 10),
              Container(
                width: MediaQuery.of(context).size.width - 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2C6A1), width: 1),
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  children: [
                    Text(
                      'CERTIFICATE',
                      style: GoogleFonts.outfit(
                        color: _mutedBrown,
                        fontSize: 31,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'OF COMPLETION',
                      style: GoogleFonts.outfit(
                        color: _mutedBrown,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Proudly presented to',
                      style: GoogleFonts.outfit(
                        color: _mutedBrown,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Shiv Sharma',
                      style: GoogleFonts.outfit(
                        color: _accent,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 1, color: const Color(0xFFE8D7C2)),
                    const SizedBox(height: 8),
                    Text(
                      'SOMNATH YATRA',
                      style: GoogleFonts.outfit(
                        color: _mutedBrown,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your devotion, dedication and spiritual journey\nhave reached the divine abode of Lord Somnath.\nMay Lord Somnath bless you with peace, prosperity\nand happiness always.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: _mutedBrown,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: const Color(0xFFE8D7C2)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _CertificateStat(icon: Icons.location_on_rounded, label: 'Distance Covered'),
                        _CertificateStat(icon: Icons.directions_walk_rounded, label: 'Total Steps'),
                        _CertificateStat(icon: Icons.access_time_filled_rounded, label: 'Time Taken'),
                        _CertificateStat(icon: Icons.calendar_today_rounded, label: 'Completed On'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    Text(
                      'Congratulations on completing the Somnath Yatra!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: _mutedBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Khodiyar Dham is nearby.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: _mutedBrown,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Would you like to begin your next divine journey?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: _mutedBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
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
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          child: Text(
                            'Home',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
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
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Next Yatra',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrophyAssetView extends StatelessWidget {
  const _TrophyAssetView({required this.mutedBrown});

  final Color mutedBrown;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _extractEmbeddedPngBytes('assets/images/Tropgold_trophy.svg'),
      builder: (context, snapshot) {
        final pngBytes = snapshot.data;
        if (pngBytes != null && pngBytes.isNotEmpty) {
          return Image.memory(
            pngBytes,
            fit: BoxFit.contain,
          );
        }

        return SvgPicture.asset(
          'assets/images/Tropgold_trophy.svg',
          fit: BoxFit.contain,
          placeholderBuilder: (context) => Icon(
            Icons.military_tech_rounded,
            size: 96,
            color: mutedBrown,
          ),
        );
      },
    );
  }

  Future<Uint8List?> _extractEmbeddedPngBytes(String assetPath) async {
    try {
      final rawSvg = await rootBundle.loadString(assetPath);
      const marker = 'data:image/png;base64,';
      final start = rawSvg.indexOf(marker);
      if (start == -1) return null;

      final base64Start = start + marker.length;
      final quoteEnd = rawSvg.indexOf('"', base64Start);
      if (quoteEnd == -1) return null;

      final base64Payload = rawSvg.substring(base64Start, quoteEnd);
      return base64Decode(base64Payload);
    } catch (_) {
      return null;
    }
  }
}

class _CertificateStat extends StatelessWidget {
  const _CertificateStat({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFC8A882)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFC8A882),
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
