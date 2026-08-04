import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Empty State view when no Yatras exist
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    this.title = 'No Yatras Available',
    this.message = 'There are no yatras to display right now.',
    this.icon = Icons.explore_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1332).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 44,
            color: const Color(0xFFFF7700).withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
