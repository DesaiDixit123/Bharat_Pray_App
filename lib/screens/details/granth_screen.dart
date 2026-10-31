import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<Map<String, dynamic>> _mapCategories(List<dynamic> rawList) {
    final List<Map<String, dynamic>> res = [];
    for (final cat in rawList) {
      final catMap = Map<String, dynamic>.from(cat as Map);
      final title = (catMap['name'] ?? catMap['title'] ?? 'Granth').toString();
      final catId = (catMap['_id'] ?? catMap['id'] ?? '').toString();
      final rawImg = (catMap['image'] ?? catMap['coverImage'] ?? '').toString();

      String resolvedImg = 'assets/images/bhagavad_gita.png';
      if (rawImg.isNotEmpty) {
        resolvedImg = ApiService.resolveImageUrl(rawImg);
      } else if (title.toLowerCase().contains('gita')) {
        resolvedImg = 'assets/images/bhagavad_gita.png';
      } else if (title.toLowerCase().contains('itihas') || title.toLowerCase().contains('epic')) {
        resolvedImg = 'assets/images/image_2.png';
      } else if (title.toLowerCase().contains('puran')) {
        resolvedImg = 'assets/images/deity_shiva.png';
      } else if (title.toLowerCase().contains('stotra') || title.toLowerCase().contains('chalisa')) {
        resolvedImg = 'assets/images/image_4.png';
      } else if (title.toLowerCase().contains('veda') || title.toLowerCase().contains('upanishad')) {
        resolvedImg = 'assets/images/image_4_1.png';
      } else if (title.toLowerCase().contains('aarti')) {
        resolvedImg = 'assets/images/image_4_1.png';
      }

      int? countVal;
      if (catMap['granthCount'] != null) {
        countVal = int.tryParse(catMap['granthCount'].toString());
      } else if (catMap['count'] != null) {
        countVal = int.tryParse(catMap['count'].toString());
      }

      res.add({
        '_id': catId,
        'title': title,
        'count': countVal ?? 0,
        'image': resolvedImg,
        'description': (catMap['description'] ?? '').toString().isNotEmpty
            ? catMap['description'].toString()
            : 'Explore sacred texts of $title',
      });
    }
    return res;
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    if (_categories.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final remoteCats = await ApiService.getGranthCategories();
      if (!mounted) return;

      final fetched = _mapCategories(remoteCats);

      setState(() {
        _categories = fetched;
        _isLoading = false;
        _error = _categories.isEmpty ? 'No granth categories found.' : '';
      });

      // Verify & refresh accurate counts in background for each category
      _refreshCountsInBackground(fetched);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _categories.isEmpty ? 'Unable to load granth categories. Please try again.' : '';
      });
    }
  }

  Future<void> _refreshCountsInBackground(List<Map<String, dynamic>> cats) async {
    try {
      final updatedList = List<Map<String, dynamic>>.from(cats);
      bool hasChanges = false;

      for (int i = 0; i < updatedList.length; i++) {
        final item = Map<String, dynamic>.from(updatedList[i]);
        final cId = item['_id']?.toString() ?? '';
        if (cId.isEmpty) continue;

        try {
          final data = await ApiService.getGranthsByCategory(cId, limit: 1);
          final dynamic totalDocs = data['totalDocs'];
          final dynamic docs = data['docs'];
          int? actualCount;
          if (totalDocs != null) {
            actualCount = int.tryParse(totalDocs.toString());
          } else if (docs is List) {
            actualCount = docs.length;
          }

          if (actualCount != null && actualCount != item['count']) {
            item['count'] = actualCount;
            updatedList[i] = item;
            hasChanges = true;
          }
        } catch (_) {}
      }

      if (hasChanges && mounted) {
        setState(() {
          _categories = updatedList;
        });
      }
    } catch (_) {}
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
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
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
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _fallbackImage(),
      );
    }
    return Image.asset(
      imgPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
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
    final int count = category['count'] is int
        ? category['count'] as int
        : (int.tryParse(category['count']?.toString() ?? '0') ?? 0);
    final String countText = count == 1 ? '1 Granth' : '$count Granths';
    final imgPath = (category['image'] ?? 'assets/images/bhagavad_gita.png').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 74,
                  width: 96,
                  color: const Color(0xFFF6ECE1),
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
                      countText,
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
