import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'granth_list_by_category_screen.dart';

import '../../services/api_service.dart';

class GranthScreen extends StatefulWidget {
  const GranthScreen({super.key});

  @override
  State<GranthScreen> createState() => _GranthScreenState();
}

class _GranthScreenState extends State<GranthScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final remoteCats = await ApiService.getGranthCategories();
      if (!mounted) return;
      
      final List<Map<String, dynamic>> fetched = [];
      for (final cat in remoteCats) {
        final catMap = Map<String, dynamic>.from(cat as Map);
        final title = (catMap['name'] ?? catMap['title'] ?? 'Granth').toString();
        final catId = (catMap['_id'] ?? catMap['id'] ?? '').toString();
        final rawImg = (catMap['image'] ?? catMap['coverImage'] ?? '').toString();

        String resolvedImg = 'assets/images/bhagavad_gita.png';
        if (rawImg.isNotEmpty) {
          resolvedImg = ApiService.resolveImageUrl(rawImg);
        } else if (title.toLowerCase().contains('veda') || title.toLowerCase().contains('puran')) {
          resolvedImg = 'assets/images/bhagavad_gita.png';
        } else if (title.toLowerCase().contains('itihas')) {
          resolvedImg = 'assets/images/image_2.png';
        } else if (title.toLowerCase().contains('darshan')) {
          resolvedImg = 'assets/images/image_3.png';
        } else if (title.toLowerCase().contains('stotra')) {
          resolvedImg = 'assets/images/image_4.png';
        } else if (title.toLowerCase().contains('aarti')) {
          resolvedImg = 'assets/images/image_4_1.png';
        }

        fetched.add({
          '_id': catId,
          'title': title,
          'count': catMap['granthCount'] ?? catMap['count'] ?? 1,
          'image': resolvedImg,
          'description': (catMap['description'] ?? '').toString().isNotEmpty
              ? catMap['description'].toString()
              : 'Explore sacred texts of $title',
        });
      }

      setState(() {
        _categories = fetched;
        _isLoading = false;
        _error = fetched.isEmpty ? 'No granth categories found.' : '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load granth categories.';
      });
    }
  }

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
        child: RefreshIndicator(
          onRefresh: _fetchCategories,
          color: const Color(0xFFFF7700),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
              : _error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error, style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF2E2A36))),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchCategories,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700)),
                            child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                            color: const Color(0xFF2E2A36).withValues(alpha: 0.58),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._categories.map((category) {
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

  Widget _buildImage(String imgPath) {
    if (imgPath.startsWith('http')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
    }
    return Image.asset(
      imgPath,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFF8F4D18),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (category['title'] ?? category['name'] ?? 'Granth').toString();
    final count = (category['count'] ?? 1).toString();
    final imgPath = (category['image'] ?? 'assets/images/bhagavad_gita.png').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.08),
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
                  child: _buildImage(imgPath),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count Granths',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.42),
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
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
