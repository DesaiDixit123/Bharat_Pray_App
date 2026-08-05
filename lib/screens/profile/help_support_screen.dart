import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          'Help & Support',
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
            // Contact Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7700), Color(0xFFFF9933)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7700).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help with Bharat Pray?',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Our dedicated support team is available 24/7 to assist with your spiritual app experience.',
                    style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Support Email: support@bharatpray.com', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF2E2A36),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF7700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: Text('Email Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Helpline: +91 80000 10808', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF2E2A36),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: Text('Helpline', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 12),

            _buildFaqItem(
              question: 'How do I track my Yatra steps and distance?',
              answer: 'Start a Yatra journey from the Yatra tab. Make sure Location permissions are enabled. The app automatically records your walking distance and step counts.',
            ),
            _buildFaqItem(
              question: 'How do Yatra Group invitations work?',
              answer: 'Go to Yatra Group > Sync Contacts. The app categorizes your phonebook contacts into registered devotees and invite contacts. Tap Invite to send group invites.',
            ),
            _buildFaqItem(
              question: 'Can I listen to Aartis and Bhajans offline?',
              answer: 'Yes! Saved Bhajans and Grantha chapters are cached for offline devotional listening.',
            ),
            _buildFaqItem(
              question: 'How do I change my Jap Mala bead sound?',
              answer: 'Open Profile > App Preferences > Beads Sound Effects. Enable or disable haptic audio feedback per count.',
            ),
            const SizedBox(height: 20),

            // App Version Footer
            Center(
              child: Column(
                children: [
                  Text('Bharat Pray App v2.4.0', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36).withValues(alpha: 0.6))),
                  Text('Made with ❤️ for Devotees Across India', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF2E2A36).withValues(alpha: 0.4))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: ExpansionTile(
        iconColor: const Color(0xFFFF7700),
        collapsedIconColor: const Color(0xFF2E2A36),
        title: Text(
          question,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36).withValues(alpha: 0.7), height: 1.4),
            ),
          )
        ],
      ),
    );
  }
}
