import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'granth_list_by_category_screen.dart';

class GranthScreen extends StatelessWidget {
  const GranthScreen({super.key});

  static const List<Map<String, dynamic>> _granthCategories = [
    {
      'title': 'Veda',
      'count': 4,
      'image': 'assets/images/bhagavad_gita.png',
      'description': 'The Vedas are the oldest sacred texts of Sanatan Dharma.',
    },
    {
      'title': 'Puran',
      'count': 18,
      'image': 'assets/images/granth_card.png',
      'description': 'Sacred stories, legends, and timeless divine teachings.',
    },
    {
      'title': 'Itihas',
      'count': 6,
      'image': 'assets/images/image_2.png',
      'description': 'Epic narratives that shape dharma, duty, and devotion.',
    },
    {
      'title': 'Darshan',
      'count': 8,
      'image': 'assets/images/image_3.png',
      'description': 'Philosophical schools exploring truth, self, and reality.',
    },
    {
      'title': 'Stotra',
      'count': 12,
      'image': 'assets/images/image_4.png',
      'description': 'Devotional hymns for prayer, praise, and reflection.',
    },
    {
      'title': 'Aarti',
      'count': 8,
      'image': 'assets/images/image_4_1.png',
      'description': 'Ceremonial songs offered in reverence with light and bhakti.',
    },
    {
      'title': 'Mantra',
      'count': 15,
      'image': 'assets/images/krishna.png',
      'description': 'Sacred chants for focus, healing, strength, and devotion.',
    },
    {
      'title': 'Other Granths',
      'count': 10,
      'image': 'assets/images/download_1.png',
      'description': 'Additional spiritual texts and treasured compilations.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2E2A36),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Granth',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Select Granth Category',
              style: GoogleFonts.outfit(
                    fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a category to explore sacred texts',
              style: GoogleFonts.outfit(
                    fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2E2A36).withOpacity(0.58),
              ),
            ),
            const SizedBox(height: 20),
            ..._granthCategories.map((category) {
              return _CategoryCard(
                category: category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GranthListByCategoryScreen(category: category),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  final Map<String, dynamic> category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow( // Corrected from withValues to withOpacity
            color: const Color(0xFFFF7700).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 78,
                  width: 102,
                  child: Image.asset(
                    category['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF8F4D18),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category['title'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category['count']} Granths',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E2A36).withOpacity(0.42),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                width: 36,
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFFF7700),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
