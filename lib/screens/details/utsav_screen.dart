import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'festival_detail_screen.dart';

class UtsavScreen extends StatelessWidget {
  const UtsavScreen({super.key});

  final List<Map<String, dynamic>> _upcomingFestivals = const [
    {
      'title': 'Dhanterash',
      'date': 'Nov 07, Saturday',
      'tithi': 'Kartik Krishna Trayodashi',
      'muhurat': '05:45 PM - 07:30 PM',
      'imageUrl': 'assets/images/dhanterash.png',
      'significance': 'Festival of wealth, worship of Lord Dhanvantari & Goddess Lakshmi.',
    },
    {
      'title': 'Diwali',
      'date': 'Nov 08, Sunday',
      'tithi': 'Kartik Amavasya',
      'muhurat': '06:12 PM - 08:05 PM',
      'imageUrl': 'assets/images/diwali.png',
      'significance': 'Festival of Lights, return of Lord Rama, worship of Goddess Lakshmi.',
    },
    {
      'title': 'Govardhan Puja',
      'date': 'Nov 09, Monday',
      'tithi': 'Kartik Shukla Pratipada',
      'muhurat': '06:32 AM - 08:47 AM',
      'imageUrl': 'assets/images/login_bg.png', // Fallback
      'significance': 'Worship of Lord Krishna lifting the Govardhan Hill.',
    },
  ];

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
          'Utsav Vibes',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panchang Timing Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEFE6DB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Panchang",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7700).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Tithi: Shukla Dwadashi",
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF7700),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFEFE6DB), height: 24),
                      
                      // Panchang Details grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPanchangItem("Sunrise", "05:42 AM", "🌅"),
                          _buildPanchangItem("Sunset", "07:11 PM", "🌇"),
                          _buildPanchangItem("Rahu Kaal", "07:30 - 09:00", "⚠️"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Upcoming Festivals header
                Text(
                  "Upcoming Festivals (त्यौहार)",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2A36),
                  ),
                ),

                const SizedBox(height: 12),

                // Festivals List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _upcomingFestivals.length,
                  itemBuilder: (context, index) {
                    final fest = _upcomingFestivals[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFEFE6DB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FestivalDetailScreen(
                                festivalName: fest['title'],
                                imageUrl: fest['imageUrl'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    fest['title'],
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E2A36),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7700),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      fest['date'],
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fest['tithi'],
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFFFF7700),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fest['significance'],
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFF2E2A36).withOpacity(0.7),
                                  height: 1.3,
                                ),
                              ),
                              const Divider(color: Color(0xFFEFE6DB), height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.timer_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Puja Muhurat: ",
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                                  ),
                                  Text(
                                    fest['muhurat'],
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF2E2A36).withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "Read Vidhi",
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF7700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF7700), size: 10),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanchangItem(String label, String time, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(
          time,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: const Color(0xFF2E2A36).withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
