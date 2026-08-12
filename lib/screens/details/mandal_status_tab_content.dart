import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mandal_registration_screen.dart';
import 'mandal_profile_screen.dart';

class MandalStatusTabContent extends StatefulWidget {
  const MandalStatusTabContent({super.key});

  @override
  State<MandalStatusTabContent> createState() => _MandalStatusTabContentState();
}

class _MandalStatusTabContentState extends State<MandalStatusTabContent> {
  // Demo status state: 0 = Pending, 1 = Approved, 2 = Rejected
  // This lets the user toggle between states easily to test all views.
  int _statusState = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Demo State Switcher (for testing and review) ─────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                _buildDemoTab("Pending", 0),
                _buildDemoTab("Approved", 1),
                _buildDemoTab("Rejected", 2),
              ],
            ),
          ),
        ),

        // ── Main Status Layout ───────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                
                // 1. Image Illustration
                _buildStatusIllustration(),
                const SizedBox(height: 32),

                // 2. Status Title
                _buildStatusTitle(),
                const SizedBox(height: 16),

                // 3. Status Description
                _buildStatusDescription(),
                const SizedBox(height: 24),

                // 4. Rejection Reason Box (Only visible if status is Rejected)
                if (_statusState == 2) ...[
                  _buildRejectionReasonBox(),
                  const SizedBox(height: 32),
                  _buildResubmitButton(),
                ],

                // 5. Approved Details Box (Only visible if status is Approved)
                if (_statusState == 1) ...[
                  _buildApprovedDetailsBox(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Component Helpers ──────────────────────────────────────────────────────

  Widget _buildDemoTab(String label, int stateVal) {
    final active = _statusState == stateVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _statusState = stateVal),
        child: Container(
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF7700) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: active ? Colors.white : const Color(0xFF8E5A2A),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIllustration() {
    String imageAsset = 'assets/images/registration_success.jpg';
    
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStatusTitle() {
    String text;
    Color color;
    switch (_statusState) {
      case 1:
        text = "Registration Approved! 🎉";
        color = const Color(0xFF27AE60);
        break;
      case 2:
        text = "Registration Rejected";
        color = Colors.red;
        break;
      case 0:
      default:
        text = "Registration Pending";
        color = const Color(0xFF2E2A36);
        break;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildStatusDescription() {
    String text;
    switch (_statusState) {
      case 1:
        text = "Congratulations! Your request has been accepted. Your mandal is now live on the platform.";
        break;
      case 2:
        text = "Your mandal registration request could not be approved at this time. Please see the rejection reason below.";
        break;
      case 0:
      default:
        text = "Your mandal registration has been submitted successfully and is currently under review by the admin team.";
        break;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
        height: 1.45,
      ),
    );
  }

  Widget _buildRejectionReasonBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                "Reason for Rejection",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "The uploaded cover image is blurry and the address details do not match the location document. Please re-upload clear photos and valid address details.",
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedDetailsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Registered Mandal Info",
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const Divider(color: Color(0xFFEFE6DB), height: 24),
          _buildInfoRow("Mandal Name", "Shree Ganesh Yuva Mandal"),
          _buildInfoRow("Leader Name", "Rohit Sharma"),
          _buildInfoRow("Festival", "Ganesh Chaturthi 2026"),
          _buildInfoRow("Status", "Live", valColor: const Color(0xFF27AE60)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MandalProfileScreen(),
                  ),
                );
              },
              child: Text(
                "View Mandal Profile",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
            ),
          ),
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valColor ?? const Color(0xFF2E2A36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7700),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MandalRegistrationScreen(),
            ),
          );
        },
        child: Text(
          'Re-submit Registration',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
