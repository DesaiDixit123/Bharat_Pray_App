import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mandal_profile_screen.dart';

class MandalLeaderboardTabContent extends StatefulWidget {
  const MandalLeaderboardTabContent({super.key});

  @override
  State<MandalLeaderboardTabContent> createState() => _MandalLeaderboardTabContentState();
}

class _MandalLeaderboardTabContentState extends State<MandalLeaderboardTabContent> {
  // Demo State: 0 = Contest Ongoing (Screen 10), 1 = Contest Ended/Winners (Screen 11)
  int _contestState = 0;

  // Countdown timer values
  int _days = 5;
  int _hours = 12;
  int _minutes = 45;
  int _seconds = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            _seconds = 59;
            if (_minutes > 0) {
              _minutes--;
            } else {
              _minutes = 59;
              if (_hours > 0) {
                _hours--;
              } else {
                _hours = 23;
                if (_days > 0) {
                  _days--;
                } else {
                  // Timer expired, show winners
                  _contestState = 1;
                  _countdownTimer?.cancel();
                }
              }
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── State Selector (For Testing) ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                _buildToggleTab("Contest Active", 0),
                _buildToggleTab("Contest Ended", 1),
              ],
            ),
          ),
        ),

        // ── Main Body ────────────────────────────────────────────────────────
        Expanded(
          child: _contestState == 0 ? _buildLeaderboardView() : _buildWinnersView(),
        ),
      ],
    );
  }

  Widget _buildToggleTab(String label, int stateVal) {
    final active = _contestState == stateVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _contestState = stateVal),
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

  // ─── 1. Contest Active Leaderboard View (Screen 10) ────────────────────────

  Widget _buildLeaderboardView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contest Ends Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF7E6D7)),
            ),
            child: Column(
              children: [
                Text(
                  "Ganesh Chaturthi 2026",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Contest Ends in",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeBox(_days, "Days"),
                    _buildTimeDivider(),
                    _buildTimeBox(_hours, "Hours"),
                    _buildTimeDivider(),
                    _buildTimeBox(_minutes, "Mins"),
                    _buildTimeDivider(),
                    _buildTimeBox(_seconds, "Secs"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Leaderboard list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rankings",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              Text(
                "Score",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Rankings List
          _buildLeaderboardRow(1, "Shree Ganesh Yuva Mandal", "12.5K Likes • 3.2K Shares", "15.7K", isUserMandal: true),
          _buildLeaderboardRow(2, "Krishna Yuva Mandal", "9.8K Likes • 2.1K Shares", "11.9K"),
          _buildLeaderboardRow(3, "Jay Mataji Mandal", "6.4K Likes • 1.8K Shares", "8.2K"),
          _buildLeaderboardRow(4, "Shiv Shakti Mandal", "4.2K Likes • 1.2K Shares", "5.4K"),
          _buildLeaderboardRow(5, "Swaminarayan Mandal", "3.6K Likes • 950 Shares", "4.5K"),
        ],
      ),
    );
  }

  Widget _buildTimeBox(int val, String label) {
    final strVal = val.toString().padLeft(2, '0');
    return Column(
      children: [
        Container(
          width: 52,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEAD8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              strVal,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF7700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF8E5A2A)),
        ),
      ],
    );
  }

  Widget _buildTimeDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 12.0),
      child: Text(
        ":",
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFF7700),
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, String name, String subtitle, String score, {bool isUserMandal = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MandalProfileScreen(mandalName: name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMandal ? const Color(0xFFFFF7EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUserMandal ? const Color(0xFFFF7700).withValues(alpha: 0.3) : const Color(0xFFF3E4D6),
            width: isUserMandal ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Rank Number
            SizedBox(
              width: 24,
              child: Text(
                "$rank",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? const Color(0xFFFF7700) : const Color(0xFFB59E83),
                ),
              ),
            ),

            // Mandal Avatar
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF1E5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/new_year_card.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Score
            Text(
              score,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. Contest Ended Winners View (Screen 11) ─────────────────────────────

  Widget _buildWinnersView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Ganesh Chaturthi 2026 Winners",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const SizedBox(height: 36),

          // Podium Layout (Screen 11 style)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              _buildPodiumColumn(
                rank: 2,
                name: "Krishna Yuva\nMandal",
                height: 100,
                color: const Color(0xFFD5DADE),
              ),
              const SizedBox(width: 12),

              // 1st Place (Center / Taller)
              _buildPodiumColumn(
                rank: 1,
                name: "Shree Ganesh\nYuva Mandal",
                height: 140,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(width: 12),

              // 3rd Place
              _buildPodiumColumn(
                rank: 3,
                name: "Jay Mataji\nMandal",
                height: 80,
                color: const Color(0xFFE6C29E),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // User Mandal Winner Special Banner to Claim/View Certificate (Screen 12 navigation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFF7700), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Congratulations! Your mandal secured 1st Position.",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                          builder: (context) => const MandalCertificateScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "View Winner Certificate",
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required int rank,
    required String name,
    required double height,
    required Color color,
  }) {
    return Column(
      children: [
        // Avatar circle
        Container(
          width: rank == 1 ? 74 : 64,
          height: rank == 1 ? 74 : 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(
              'assets/images/new_year_card.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Rank Badge Ribbon
        Container(
          width: 44,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                "$rank",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Mandal Name
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
      ],
    );
  }
}

// ─── 3. Winner Certificate View Screen (Screen 12) ───────────────────────────

class MandalCertificateScreen extends StatelessWidget {
  const MandalCertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFC8A882), size: 16),
              ),
            ),
          ),
        ),
        title: Text(
          'Certificate',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  // 1. Outer Container (Double Gold Border gap simulation)
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    // 2. Inner Container
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Ornate corner flourishes (filter_vintage_outlined simulates original visual)
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Icon(Icons.filter_vintage_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.8), size: 16),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Transform.rotate(
                              angle: 1.57,
                              child: Icon(Icons.filter_vintage_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.8), size: 16),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            left: 2,
                            child: Transform.rotate(
                              angle: 4.71,
                              child: Icon(Icons.filter_vintage_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.8), size: 16),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Transform.rotate(
                              angle: 3.14,
                              child: Icon(Icons.filter_vintage_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.8), size: 16),
                            ),
                          ),

                          // Certificate Contents
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 12),
                              // Title (Serif style)
                              Text(
                                "WINNER CERTIFICATE",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF8E5A2A),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Ganesh Chaturthi 2026",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Presented to
                              Text(
                                "Presented to",
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Shree Ganesh Yuva Mandal",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // For Securing
                              Text(
                                "For Securing",
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "1st Position",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Appreciation Description
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "We appreciate your devotion, enthusiasm and participation.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF2E2A36).withValues(alpha: 0.85),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 38),

                              // Seal and Signatures row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left Signature (Cursive signature text overlay)
                                  Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Text(
                                            "Indrane",
                                            style: GoogleFonts.dancingScript(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -4,
                                            child: Container(width: 60, height: 1, color: const Color(0xFFC8A882)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Chairman",
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Center Gold Seal Medallion with Ribbons
                                  Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        bottom: -18,
                                        left: -4,
                                        child: Transform.rotate(
                                          angle: -0.25,
                                          child: CustomPaint(
                                            size: const Size(12, 28),
                                            painter: RibbonTailPainter(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -18,
                                        right: -4,
                                        child: Transform.rotate(
                                          angle: 0.25,
                                          child: CustomPaint(
                                            size: const Size(12, 28),
                                            painter: RibbonTailPainter(),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFF7C844), Color(0xFFD4AF37), Color(0xFFB38F1F)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          border: Border.all(color: const Color(0xFFA67C1E), width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFFA67C1E).withValues(alpha: 0.5), width: 1),
                                            ),
                                            child: const Icon(
                                              Icons.emoji_events_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Right Signature (Cursive signature text overlay)
                                  Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Text(
                                            "OohSheeren",
                                            style: GoogleFonts.dancingScript(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -4,
                                            child: Container(width: 60, height: 1, color: const Color(0xFFC8A882)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Trustee",
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Download and Share buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    // Download Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Certificate saved to Gallery!",
                                  style: GoogleFonts.outfit(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF2E2A36),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                            "Download",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Share Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Preparing certificate link to share...",
                                  style: GoogleFonts.outfit(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF2E2A36),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            "Share",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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

// ─── Ribbon Tail Painter (Draws the realistic gold ribbons under the seal) ─

class RibbonTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFA67C1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height - 6); // Notched end
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
