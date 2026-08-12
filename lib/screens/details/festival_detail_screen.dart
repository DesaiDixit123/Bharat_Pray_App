import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'mandal_registration_screen.dart';

class FestivalDetailScreen extends StatefulWidget {
  final String festivalName;
  final String imageUrl;
  final bool isMandal;

  const FestivalDetailScreen({
    super.key,
    required this.festivalName,
    required this.imageUrl,
    this.isMandal = false,
  });

  @override
  State<FestivalDetailScreen> createState() => _FestivalDetailScreenState();
}

class _FestivalDetailScreenState extends State<FestivalDetailScreen> {
  // Checklist states (original view)
  final Map<String, bool> _checklist = {
    "Clay Diyas (मिट्टी के दीये)": false,
    "Marigold Flowers (गेंदे के फूल)": false,
    "Gangajal & Ghee (गंगाजल और घी)": false,
    "Sweet Offerings (नैवेद्य/मिठाई)": false,
    "Incense & Camphor (धूप और कपूर)": false,
  };

  bool _isDiyaLit = false;

  final List<String> _vidhiSteps = [
    "Step 1: Clean the prayer altar and place a red cloth on it.",
    "Step 2: Install the idols/photos of Lord Ganesha and Goddess Lakshmi.",
    "Step 3: Light the central Ghee Diya and apply vermilion tilak to the deities.",
    "Step 4: Offer fresh marigold flowers, sweets (laddoos), and fruits.",
    "Step 5: Perform the Aarti together with your family and distribute prasad.",
  ];

  Map<String, String> _getMandalDates() {
    if (widget.festivalName.contains('Ganesh') || widget.festivalName.toLowerCase().contains('celebrate')) {
      return {
        'Registration Start': '01 Aug 2026',
        'Registration End': '10 Sep 2026',
        'Posting Start': '11 Sep 2026',
        'Posting End': '24 Sep 2026',
        'Winners Announcement': '27 Sep 2026',
      };
    } else {
      return {
        'Registration Start': '15 Aug 2026',
        'Registration End': '25 Sep 2026',
        'Posting Start': '26 Sep 2026',
        'Posting End': '11 Oct 2026',
        'Winners Announcement': '14 Oct 2026',
      };
    }
  }

  String _getMandalDatesText() {
    if (widget.festivalName.contains('Ganesh') || widget.festivalName.toLowerCase().contains('celebrate')) {
      return '15 Sep 2026 - 25 Sep 2026';
    } else {
      return '03 Oct 2026 - 12 Oct 2026';
    }
  }

  String _getMandalDesc() {
    if (widget.festivalName.contains('Ganesh') || widget.festivalName.toLowerCase().contains('celebrate')) {
      return "Let's celebrate the arrival of Bappa together.";
    } else {
      return "Nine nights of devotion to Maa Durga.";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMandal) {
      return _buildMandalLayout(context);
    }
    return _buildOriginalLayout(context);
  }

  // ── Mandal Registration Layout ─────────────────────────────────────────────

  Widget _buildMandalLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: _FestivalBackButton(
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Festival Details',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // 1. Cover Card
                      _buildMandalCoverCard(),
                      const SizedBox(height: 20),

                      // 2. Dates Subtitle
                      Text(
                        _getMandalDatesText(),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3. Status Badge
                      _buildMandalBadge(),
                      const SizedBox(height: 12),

                      // 4. Description
                      Text(
                        _getMandalDesc(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 5. Divider
                      Container(
                        height: 1,
                        color: const Color(0xFFEFE6DB),
                      ),
                      const SizedBox(height: 25),

                      // 6. Important Dates
                      _buildImportantDatesSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // 7. Register Mandal Button (Bottom Sticky Layout)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildRegisterButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMandalCoverCard() {
    final displayName = widget.festivalName.toLowerCase().contains('celebrate')
        ? 'Ganesh Chaturthi 2026'
        : widget.festivalName;
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(widget.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Text(
                displayName.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMandalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Registrations Open',
        style: GoogleFonts.outfit(
          color: const Color(0xFF27AE60),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildImportantDatesSection() {
    final dates = _getMandalDates();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Important Dates',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 16),
        ...dates.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    e.value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF2E2A36),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRegisterButton() {
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
              builder: (context) => MandalRegistrationScreen(
                initialFestival: widget.festivalName,
              ),
            ),
          );
        },
        child: Text(
          'Register Mandal',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── Original Puja Prep/Lit Diya Layout ──────────────────────────────────────

  Widget _buildOriginalLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image header banner
              Stack(
                children: [
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: Image.asset(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            const Color(0xFFFFE8D6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 16,
                    child: _FestivalBackButton(
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Text(
                      widget.festivalName,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 1. Virtual Diya widget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFEFE6DB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Lit Virtual Diya (दीप प्रज्वलन)",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDiyaLit = !_isDiyaLit;
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/diya.png',
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                            if (_isDiyaLit)
                              Positioned(
                                top: 18,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.2),
                                  duration: const Duration(seconds: 1),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    height: 35,
                                    width: 35,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [Colors.white, Colors.yellow, Colors.orangeAccent, Colors.transparent],
                                        stops: [0.1, 0.4, 0.8, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withValues(alpha: 0.8),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isDiyaLit ? "May the light of wisdom guide you! 🌟" : "Click to Light Diya",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isDiyaLit ? const Color(0xFFFF7700) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 2. Puja Preparation Checklist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Puja Preparation Checklist (सामग्री)",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFEFE6DB)),
                      ),
                      child: Column(
                        children: _checklist.keys.map((item) {
                          return CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              item,
                              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
                            ),
                            value: _checklist[item],
                            activeColor: const Color(0xFFFF7700),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _checklist[item] = val;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 3. Step-by-Step Puja Vidhi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Puja Vidhi Steps (पूजा विधि)",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._vidhiSteps.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEFE6DB)),
                            ),
                            child: Text(
                              step,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Back Button ─────────────────────────────────────────────────────────────

class _FestivalBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FestivalBackButton({required this.onTap});

  static const String _backArrowSvg =
      '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
        ),
        child: Center(
          child: SvgPicture.string(
            _backArrowSvg,
            width: 15,
            height: 15,
          ),
        ),
      ),
    );
  }
}
