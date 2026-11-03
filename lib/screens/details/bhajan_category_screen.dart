import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<_BhajanCategoryItem> _filteredCategories = const [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredCategories = _categories;
      });
    } else {
      setState(() {
        _filteredCategories = _categories.where((cat) {
          final titleMatch = cat.title.toLowerCase().contains(query);
          final mantraMatch = _getDeityMantra(cat.title).toLowerCase().contains(query);
          return titleMatch || mantraMatch;
        }).toList();
      });
    }
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

      // Sort categories so prominent deities appear first
      categories.sort((a, b) => _getSortPriority(a.title).compareTo(_getSortPriority(b.title)));

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _filteredCategories = _searchController.text.trim().isEmpty
            ? categories
            : categories.where((c) => c.title.toLowerCase().contains(_searchController.text.trim().toLowerCase())).toList();
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

  int _getSortPriority(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('krishna')) return 1;
    if (lower.contains('ram')) return 2;
    if (lower.contains('mahadev') || lower.contains('shiva')) return 3;
    if (lower.contains('hanuman')) return 4;
    if (lower.contains('ganesh')) return 5;
    if (lower.contains('durga') || lower.contains('amba')) return 6;
    if (lower.contains('khodiyar')) return 7;
    if (lower.contains('vishnu')) return 8;
    if (lower.contains('surya')) return 9;
    if (lower.contains('ayyappa')) return 10;
    if (lower.contains('brahma')) return 11;
    return 20;
  }

  void _openCategory(_BhajanCategoryItem category) {
    final resolvedImage = _resolveDeityAsset(category.title, category.imageUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BhajanListByCategoryScreen(
          categoryId: category.id,
          categoryTitle: category.title,
          categoryImagePath: resolvedImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFE8D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        body: SafeArea(
          top: true,
          child: RefreshIndicator(
            color: const Color(0xFFFF7700),
            backgroundColor: Colors.white,
            onRefresh: _loadCategories,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildHeroBanner(),
                const SizedBox(height: 14),
                _buildSearchBar(),
                const SizedBox(height: 14),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7700)),
                      ),
                    ),
                  )
                else if (_error.isNotEmpty)
                  _buildErrorCard()
                else if (_filteredCategories.isEmpty)
                  _buildEmptyCard()
                else ...[
                  _buildSectionHeader(),
                  const SizedBox(height: 10),
                  ..._filteredCategories.map(_buildCategoryCard),
                ],
              ],
            ),
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
            'Bhajan Categories',
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note_rounded, size: 14, color: Color(0xFFFF7700)),
                  const SizedBox(width: 4),
                  Text(
                    '${_categories.length} Gods',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A4B23),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern, premium Devotional Highlights Banner that replaces the old cardboard box
  Widget _buildHeroBanner() {
    return Container(
      height: 126,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF851B),
            Color(0xFFFF5E00),
            Color(0xFFDD3B00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Background subtle spiritual glow patterns
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Sacred Melodies & Stutis',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Devotional Bhajans',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Immerse in soul-stirring bhakti and kirtans',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side decorative spiritual diya/music badge
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.queue_music_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
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

  /// Modern search input for quick deity search
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E4D6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4527).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(
          fontSize: 15,
          color: const Color(0xFF2E2A36),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search by deity name (Krishna, Ram, Mahadev...)',
          hintStyle: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.42),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFFF7700),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  child: const Icon(Icons.close_rounded, color: Color(0xFF999999), size: 20),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Gods & Deities',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E2A36),
          ),
        ),
        Text(
          '${_filteredCategories.length} Categories',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF7A4B23).withValues(alpha: 0.8),
          ),
        ),
      ],
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
              color: const Color(0xFF2E2A36).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, color: Color(0xFFFF7700), size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'No deity categories found',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with a different deity name',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(_BhajanCategoryItem category) {
    final mantra = _getDeityMantra(category.title);
    final imageAsset = _resolveDeityAsset(category.title, category.imageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E4D6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4527).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCategory(category),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 1. Deity Avatar with Golden Ring
                _buildDeityAvatar(category.title, imageAsset),

                const SizedBox(width: 14),

                // 2. Deity Name, Mantra, and Bhajan Count Pill
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
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mantra,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCC5E00),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFFD5B3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.music_note_rounded,
                              size: 11,
                              color: Color(0xFFFF7700),
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              category.countLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8C522A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // 3. Circular Action Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF3E6),
                    border: Border.all(
                      color: const Color(0xFFFFCC99).withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFFF7700),
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a stunning circular deity avatar with a delicate golden saffron ring
  Widget _buildDeityAvatar(String title, String imagePath) {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9933), Color(0xFFFF5500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFFDF8),
        ),
        child: ClipOval(
          child: _renderDeityImage(title, imagePath),
        ),
      ),
    );
  }

  Widget _renderDeityImage(String title, String imagePath) {
    final fallbackAsset = _resolveFallbackDeityAsset(title);

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Image.asset(
          fallbackAsset,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      imagePath,
      width: 58,
      height: 58,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => Image.asset(
        fallbackAsset,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFFFF1E5),
          child: const Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF7700), size: 26),
        ),
      ),
    );
  }

  /// Maps every deity title to their authentic high-res portrait asset
  static String _resolveDeityAsset(String title, String? rawImg) {
    if (rawImg != null && rawImg.isNotEmpty) {
      final resolved = ApiService.resolveImageUrl(rawImg);
      if (resolved.startsWith('http') ||
          (resolved.startsWith('assets/') &&
              !resolved.contains('bhajan_card.png') &&
              !resolved.contains('bhagavad_gita.png'))) {
        return resolved;
      }
    }

    return _resolveFallbackDeityAsset(title);
  }

  static String _resolveFallbackDeityAsset(String title) {
    final lower = title.toLowerCase().trim();

    if (lower.contains('krishna') || lower.contains('radha') || lower.contains('kanha') || lower.contains('shyam')) {
      return 'assets/images/deity_krishna.png';
    }
    if (lower.contains('ram') || lower.contains('sita') || lower.contains('raghu') || lower.contains('ayodhya')) {
      return 'assets/images/deity_ram.png';
    }
    if (lower.contains('mahadev') || lower.contains('shiva') || lower.contains('bhole') || lower.contains('shankar')) {
      return 'assets/images/deity_shiva.png';
    }
    if (lower.contains('hanuman') || lower.contains('maruti') || lower.contains('bajrang') || lower.contains('anjaneya')) {
      return 'assets/images/deity_hanuman.png';
    }
    if (lower.contains('durga') || lower.contains('amba') || lower.contains('kali') || lower.contains('devi')) {
      return 'assets/images/deity_amba.png';
    }
    if (lower.contains('ganesh') || lower.contains('ganpati') || lower.contains('vinayak') || lower.contains('gajanand')) {
      return 'assets/images/deity_ganesha.png';
    }
    if (lower.contains('khodiyar') || lower.contains('khodal')) {
      return 'assets/images/deity_khodiyar.png';
    }
    if (lower.contains('vishnu') || lower.contains('narayan') || lower.contains('dwarka')) {
      return 'assets/images/deity_vishnu.png';
    }
    if (lower.contains('brahma')) {
      return 'assets/images/deity_brahma.png';
    }
    if (lower.contains('surya') || lower.contains('sun') || lower.contains('aditya') || lower.contains('bhaskar')) {
      return 'assets/images/deity_surya.png';
    }
    if (lower.contains('ayyappa') || lower.contains('swamy') || lower.contains('shabarimala') || lower.contains('manikandan')) {
      return 'assets/images/deity_ayyappa.png';
    }

    return 'assets/images/deity_shiva.png';
  }

  /// Sacred Sanskrit/Devotional tagline for each deity
  static String _getDeityMantra(String title) {
    final lower = title.toLowerCase().trim();
    if (lower.contains('krishna')) return 'हरे कृष्ण हरे रामा • ॐ नमो भगवते';
    if (lower.contains('ram')) return 'जय श्री राम • सियावर रामचंद्र';
    if (lower.contains('mahadev') || lower.contains('shiva')) return 'हर हर महादेव • ॐ नमः शिवाय';
    if (lower.contains('hanuman')) return 'जय बजरंगबली • संकटमोचन';
    if (lower.contains('durga') || lower.contains('amba')) return 'जय माता दी • ॐ ऐं ह्रीं क्लीं';
    if (lower.contains('ganesh')) return 'श्री गणेशाय नमः • मंगल मूर्ति';
    if (lower.contains('khodiyar')) return 'जय माँ ખોડિયાર • આઈ ખોડલ';
    if (lower.contains('vishnu')) return 'ॐ नमो नारायणाय • श्रीहरि';
    if (lower.contains('brahma')) return 'ॐ ब्रह्मणे नमः • सृष्टिकर्ता';
    if (lower.contains('surya')) return 'ॐ सूर्याय नमः • आदिदेव';
    if (lower.contains('ayyappa')) return 'स्वामीये शरणम अय्यप्पा • धर्मशास्ता';
    return 'ભક્તિ સંગીત અને આરતી';
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

  String get countLabel => count == 1 ? '1 Bhajan' : '$count Bhajans';
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
