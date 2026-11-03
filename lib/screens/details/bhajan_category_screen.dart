import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../widgets/bhajan/bhajan_mini_player_widget.dart';
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
          return cat.title.toLowerCase().contains(query);
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
          child: Column(
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: _buildHeader(),
              ),

              // Categories List
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFFF7700),
                  backgroundColor: Colors.white,
                  onRefresh: _loadCategories,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    children: [
                      // Clean Search Bar
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
                      else
                        ..._filteredCategories.map(_buildCategoryCard),
                    ],
                  ),
                ),
              ),

              // Spotify-style Persistent Mini Player
              const BhajanMiniPlayerWidget(),
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

  /// Clean, subtle search bar matching the app's clean UI
  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DFCE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(
          fontSize: 14.5,
          color: const Color(0xFF2E2A36),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search by deity...',
          hintStyle: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFB56E28),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  child: const Icon(Icons.close_rounded, color: Color(0xFF999999), size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              fontSize: 14,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            const Icon(Icons.search_off_rounded, color: Color(0xFFC4A88F), size: 36),
            const SizedBox(height: 10),
            Text(
              'No categories found',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E2A36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean, calm, elegant card displaying ONLY real admin data (name and real count)
  Widget _buildCategoryCard(_BhajanCategoryItem category) {
    final imageAsset = _resolveDeityAsset(category.title, category.imageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DFCE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openCategory(category),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Real Deity Avatar
                _buildDeityAvatar(category.title, imageAsset),

                const SizedBox(width: 14),

                // Real Admin Deity Name & Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category.countLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.52),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle, gentle right chevron
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFC4A88F),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Clean, authentic deity circular portrait
  Widget _buildDeityAvatar(String title, String imagePath) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF9F2),
        border: Border.all(color: const Color(0xFFE8D4C1), width: 1.0),
      ),
      child: ClipOval(
        child: _renderDeityImage(title, imagePath),
      ),
    );
  }

  Widget _renderDeityImage(String title, String imagePath) {
    final fallbackAsset = _resolveFallbackDeityAsset(title);

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Image.asset(
          fallbackAsset,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      imagePath,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        fallbackAsset,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFFFF1E5),
          child: const Icon(Icons.temple_hindu_rounded, color: Color(0xFFB56E28), size: 24),
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
