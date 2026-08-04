import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Network Error view with Retry button
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetryWidget({
    super.key,
    this.message = 'Failed to load data. Please check your connection.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3A2450)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 40,
            color: Color(0xFFFF7700),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
            label: Text(
              'Retry',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
