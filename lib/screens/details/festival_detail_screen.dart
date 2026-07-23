import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FestivalDetailScreen extends StatefulWidget {
  final String festivalName;
  final String imageUrl;

  const FestivalDetailScreen({
    super.key,
    required this.festivalName,
    required this.imageUrl,
  });

  @override
  State<FestivalDetailScreen> createState() => _FestivalDetailScreenState();
}

class _FestivalDetailScreenState extends State<FestivalDetailScreen> {
  // Checklist states
  final Map<String, bool> _checklist = {
    "Clay Diyas (मिट्टी के दीये)": false,
    "Marigold Flowers (गेंदे के फूल)": false,
    "Gangajal & Ghee (गंगाजल और घी)": false,
    "Sweet Offerings (नैवेद्य/मिठाई)": false,
    "Incense & Camphor (धूप और कपूर)": false,
  };

  bool _isDiyaLit = false;
  double _diyaScale = 1.0;

  final List<String> _vidhiSteps = [
    "Step 1: Clean the prayer altar and place a red cloth on it.",
    "Step 2: Install the idols/photos of Lord Ganesha and Goddess Lakshmi.",
    "Step 3: Light the central Ghee Diya and apply vermilion tilak to the deities.",
    "Step 4: Offer fresh marigold flowers, sweets (laddoos), and fruits.",
    "Step 5: Perform the Aarti together with your family and distribute prasad.",
  ];

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
                            Colors.black.withOpacity(0.4),
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
                      decoration: const BoxDecoration(
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
                        color: Colors.black.withOpacity(0.02),
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
                                          color: Colors.orange.withOpacity(0.8),
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
                                color: const Color(0xFF2E2A36).withOpacity(0.8),
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
