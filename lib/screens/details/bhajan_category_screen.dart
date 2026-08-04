import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'bhajan_list_by_category_screen.dart';

class BhajanScreen extends StatefulWidget {
  const BhajanScreen({super.key});

  @override
  State<BhajanScreen> createState() => _BhajanScreenState();
}

class _BhajanScreenState extends State<BhajanScreen> {
  bool _isLoading = true;
  String _error = '';
  List<_BhajanCategoryItem> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final categoryData = await ApiService.getBhajanGodCategories(token);
      final categories = categoryData
          .map((e) => _BhajanCategoryItem.fromJson(e))
          .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      if (token.isNotEmpty) {
        await ApiService.getBhajanHome(token);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load bhajan categories.';
      });
    }
  }

  void _openCategory(_BhajanCategoryItem category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BhajanListByCategoryScreen(
          categoryId: category.id,
          categoryTitle: category.title,
          categoryImagePath: category.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      body: SafeArea(
        top: true,
        child: RefreshIndicator(
          onRefresh: _loadCategories,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildHeaderCard(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFF7700))),
                )
              else if (_error.isNotEmpty)
                _buildErrorCard()
              else if (_categories.isEmpty)
                _buildEmptyCard()
              else
                ..._categories.map(_buildCategoryCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: _BhajanBackButton(onTap: () => Navigator.pop(context)),
          ),
          Text(
            'Bhajan',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      height: 184,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/bhajan_card.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xB30E0A08), Color(0x6B5C290B)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bhajan Categories',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore divine bhajans by categories',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            _error,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF2E2A36).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700)),
            child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Text(
          'No bhajan categories found.',
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: const Color(0xFF2E2A36).withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(_BhajanCategoryItem category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openCategory(category),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCategoryImage(category.imageUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.countLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E2A36).withOpacity(0.58),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF2E2A36),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String imageUrl) {
    final resolvedUrl = ApiService.resolveImageUrl(imageUrl);
    if (resolvedUrl.isNotEmpty && resolvedUrl.startsWith('http')) {
      return Image.network(
        resolvedUrl,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => _categoryImageFallback(),
      );
    }
    return _categoryImageFallback();
  }

  Widget _categoryImageFallback() {
    return Container(
      width: 58,
      height: 58,
      color: const Color(0xFFFFF1E5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.music_note_rounded,
        color: Color(0xFFB56E28),
        size: 24,
      ),
    );
  }
}

class _BhajanCategoryItem {
  const _BhajanCategoryItem({
    required this.id,
    required this.title,
    required this.count,
    required this.imageUrl,
  });

  factory _BhajanCategoryItem.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    return _BhajanCategoryItem(
      id: (map['_id'] ?? map['id'] ?? '').toString(),
      title: (map['name'] ?? map['title'] ?? map['categoryName'] ?? '').toString(),
      count: _readCount(map),
      imageUrl: (map['image'] ?? map['imageUrl'] ?? map['icon'] ?? map['coverImage'] ?? '').toString(),
    );
  }

  static int _readCount(Map<String, dynamic> map) {
    final value = map['bhajanCount'] ?? map['totalBhajans'] ?? map['count'] ?? 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  final String id;
  final String title;
  final int count;
  final String imageUrl;

  String get countLabel => '$count Bhajans';
}

class _BhajanBackButton extends StatelessWidget {
  final VoidCallback onTap;

  static const String _backArrowSvg = '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>'
      '</svg>';

  const _BhajanBackButton({
    required this.onTap,
  });

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
