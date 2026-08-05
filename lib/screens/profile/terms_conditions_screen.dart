import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          'Terms & Conditions',
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
                  const Icon(Icons.gavel_rounded, color: Color(0xFFFF7700), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Welcome to Bharat Pray. By accessing our application, you agree to these spiritual & community terms.',
                      style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              num: '1',
              title: 'Acceptance of Terms',
              content: 'By downloading, installing, or using Bharat Pray, you agree to comply with and be bound by these Terms and Conditions. These terms apply to all visitors, registered devotees, and group yatra participants.',
            ),
            _buildSection(
              num: '2',
              title: 'Devotional Content & Respect',
              content: 'Bharat Pray is dedicated to sacred pilgrimages, daily Darshan, Jap counting, and spiritual Yatras. All user contributions, comments, and group interactions must maintain sanctity, respect, and peace.',
            ),
            _buildSection(
              num: '3',
              title: 'Group Yatras & Contact Syncing',
              content: 'Group Yatra features allow devotees to sync phone contacts to invite trusted friends & family. Contact data is processed solely to categorize registered devotees and non-registered contacts for invitation purposes.',
            ),
            _buildSection(
              num: '4',
              title: 'Location & Tracking Services',
              content: 'During active Yatra pilgrimages, location permissions enable route progress calculations, step estimates, and live member tracking. Location sharing is active only during an explicit Yatra session.',
            ),
            _buildSection(
              num: '5',
              title: 'Intellectual Property',
              content: 'All original Darshan media, Aarti streams, audio tracks, and Yatra routes are protected by copyright laws. Commercial reproduction without prior written consent is strictly prohibited.',
            ),
            _buildSection(
              num: '6',
              title: 'Contact Us',
              content: 'If you have questions regarding these terms, please contact our support team at support@bharatpray.com or call +91 80000 10808.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String num, required String title, required String content}) {
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
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7700),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(num, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
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
