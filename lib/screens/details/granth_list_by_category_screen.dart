import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

import 'granth_chapter_list_screen.dart';

class GranthListByCategoryScreen extends StatefulWidget {
  const GranthListByCategoryScreen({
    super.key,
    required this.category,
  });

  final Map<String, dynamic> category;

  @override
  State<GranthListByCategoryScreen> createState() => _GranthListByCategoryScreenState();
}

class _GranthListByCategoryScreenState extends State<GranthListByCategoryScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _granths = [];

  @override
  void initState() {
    super.initState();
    _loadGranths();
  }

  Future<void> _loadGranths() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final categoryId = widget.category['id']?.toString() ?? '';
      if (categoryId.isEmpty) {
        throw Exception('Category ID is missing.');
      }
      final data = await ApiService.getGranthsByCategory(categoryId, limit: 50);
      if (!mounted) return;
      setState(() {
        _granths = data['docs'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load granths for this category.';
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
          widget.category['title'] as String,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadGranths,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, style: GoogleFonts.outfit(color: Colors.red.shade700)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadGranths,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700)),
              child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
            )
          ],
        ),
      );
    }

    if (_granths.isEmpty) {
      return Center(
        child: Text(
          'No granths available in this category.', style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36).withOpacity(0.6))),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          height: 192,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF8A4A18), Color(0xFFD9892C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: -12,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ApiService.resolveImageUrl(widget.category['image'] as String? ?? '').startsWith('http')
                      ? Image.network(
                          ApiService.resolveImageUrl(widget.category['image'] as String? ?? ''),
                          width: 134,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholderImage(),
                        )
                      : Image.asset(
                          widget.category['image'] as String,
                          width: 134,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholderImage(),
                        ),
                ),
              ),
              Positioned(
                left: 126,
                right: 4,
                top: 12,
                bottom: 12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category['name'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.category['description'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500, // Corrected from withValues to withOpacity
                        height: 1.45,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ..._granths.map((granth) => _buildGranthCard(granth as Map<String, dynamic>)),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 134,
      height: 150, // Corrected from withValues to withOpacity
      alignment: Alignment.center,
      color: Colors.white.withOpacity(0.12),
      child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 40,
      ),
    );
  }

  Widget _buildGranthCard(Map<String, dynamic> granth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow( // Corrected from withValues to withOpacity
            color: const Color(0xFFFF7700).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GranthChapterListScreen(
                category: widget.category,
                granth: granth,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ApiService.resolveImageUrl(granth['coverImage'] as String? ?? '').startsWith('http')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ApiService.resolveImageUrl(granth['coverImage'] as String? ?? ''),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFB56E28),
                          size: 24,
                            ),
                          ),
                        )
                      : const Icon(Icons.menu_book_rounded, color: Color(0xFFB56E28), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        granth['title'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${granth['totalChapters'] ?? 0} Chapters',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E2A36).withOpacity(0.52),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const SizedBox(
                  height: 36,
                  width: 36,
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFFF9B38),
                      size: 18,
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
}
