import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeityDetailScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String description;

  const DeityDetailScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.description,
  });

  @override
  State<DeityDetailScreen> createState() => _DeityDetailScreenState();
}

class _DeityDetailScreenState extends State<DeityDetailScreen> with SingleTickerProviderStateMixin {
  bool _isAartiTab = false;
  bool _diyaLit = false;
  bool _flowersOffered = false;
  double _bellScale = 1.0;

  final List<String> _rituals = [
    "Morning Mangala Aarti — 06:00 AM",
    "Bhog Naivedya Ritual — 12:00 PM",
    "Evening Sandhya Aarti — 07:00 PM",
    "Sayana Aarti Closing — 09:30 PM",
  ];

  final String _aartiText = '''जय गणेश, जय गणेश, जय गणेश देवा।
माता जाकी पारवती, पिता महादेवा॥
एकदंत, दयावन्त, चार भुजाधारी।
माथे पर तिलक सोहे, मूसे की सवारी॥

पान चढे, फूल चढे और चढे मेवा।
लड्डुअन का भोग लगे, सन्त करें सेवा॥
जय गणेश, जय गणेश, जय गणेश देवा।
माता जाकी पारवती, पिता महादेवा॥''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immersive Image Header Banner with Back arrow
              Stack(
                children: [
                  SizedBox(
                    height: 320,
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFFF7700), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Virtual Darshan Portal",
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
  
              // Virtual Offerings Widget Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEFE6DB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Perform Virtual Pooja (पूजा सेवा)",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Ring Bell
                          _buildPoojaItem(
                            label: "Ring Bell",
                            iconEmoji: "🔔",
                            isActive: false,
                            onTap: () {
                              setState(() {
                                _bellScale = 1.3;
                              });
                              Future.delayed(const Duration(milliseconds: 150), () {
                                if (mounted) setState(() => _bellScale = 1.0);
                              });
                            },
                          ),
                          // Lit Diya
                          _buildPoojaItem(
                            label: _diyaLit ? "Diya Lit" : "Lit Diya",
                            iconEmoji: _diyaLit ? "🔥" : "🪔",
                            isActive: _diyaLit,
                            onTap: () => setState(() => _diyaLit = !_diyaLit),
                          ),
                          // Offer Flowers
                          _buildPoojaItem(
                            label: _flowersOffered ? "Offered" : "Offer Flower",
                            iconEmoji: "🌸",
                            isActive: _flowersOffered,
                            onTap: () => setState(() => _flowersOffered = !_flowersOffered),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
  
              const SizedBox(height: 25),
  
              // Tab Buttons: Overview vs Aarti Texts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    _buildTabButton("Overview (विवरण)", !_isAartiTab),
                    const SizedBox(width: 16),
                    _buildTabButton("Aarti & Verses (आरती)", _isAartiTab),
                  ],
                ),
              ),
  
              const SizedBox(height: 16),
  
              // Tab Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _isAartiTab ? _buildAartiText() : _buildOverview(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        Text(
          "Daily Rituals Schedule (दैनिक सेवा)",
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: _rituals.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                const Icon(Icons.brightness_5_rounded, color: Color(0xFFFF7700), size: 14),
                const SizedBox(width: 10),
                Text(
                  r,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAartiText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: SelectableText(
        _aartiText,
        style: GoogleFonts.yatraOne(
          fontSize: 16,
          height: 1.8,
          color: const Color(0xFF2E2A36),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTabButton(String text, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAartiTab = (text.contains("Aarti"));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF7700) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.transparent : const Color(0xFFEFE6DB)),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: active ? Colors.white : const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPoojaItem({
    required String label,
    required String iconEmoji,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedScale(
            scale: label.contains("Bell") ? _bellScale : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFF7700).withValues(alpha: 0.15) : const Color(0xFFFFE8D6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? const Color(0xFFFF7700) : const Color(0xFFEFE6DB),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  iconEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E2A36),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
