import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFE6DB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFFF7700), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Your privacy is sacred to us. Learn how Bharat Pray protects your personal information and spiritual data.',
                      style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildTile(
              icon: Icons.person_pin_circle_rounded,
              title: 'Information We Collect',
              content: 'We collect profile details (Name, Mobile Number, Email), device contacts (only when synced for Group Yatra invites), and location coordinates during active Yatra tracking.',
            ),
            _buildTile(
              icon: Icons.phonelink_setup_rounded,
              title: 'How We Use Your Information',
              content: 'Your data is used to provide seamless Darshan notifications, calculate pilgrimage walking routes, maintain Jap counters, and connect you with fellow Yatra group members.',
            ),
            _buildTile(
              icon: Icons.lock_outline_rounded,
              title: 'Data Security & Storage',
              content: 'We employ industry-standard SSL encryption and secure cloud servers. Personal information is never sold or rented to third-party advertising companies.',
            ),
            _buildTile(
              icon: Icons.location_on_outlined,
              title: 'Location & Background Permissions',
              content: 'Background location permission is used strictly to record distance walked and steps completed during active Yatra journeys.',
            ),
            _buildTile(
              icon: Icons.delete_outline_rounded,
              title: 'Your Data Rights & Deletion',
              content: 'You retain full control over your profile. You may request account deletion or data erasure at any time via support@bharatpray.com.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF7700), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36).withValues(alpha: 0.7), height: 1.4),
          ),
        ],
      ),
    );
  }
}
