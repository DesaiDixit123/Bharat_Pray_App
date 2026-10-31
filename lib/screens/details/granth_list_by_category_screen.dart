import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/saved_items_service.dart';
import '../../widgets/top_toast_notification.dart';
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
  final Set<String> _savedGranthIds = <String>{};

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
      final savedList = await SavedItemsService.getSavedGranths();
      final savedIds = savedList.map((g) => (g['_id'] ?? g['id'] ?? '').toString()).toSet();

      final categoryId = (widget.category['_id'] ?? widget.category['id'] ?? '').toString();
      final data = await ApiService.getGranthsByCategory(categoryId, limit: 50);
      final List<dynamic> list = data['docs'] ?? [];

      if (!mounted) return;
      setState(() {
        _savedGranthIds.clear();
        _savedGranthIds.addAll(savedIds);
        _granths = list;
        _isLoading = false;
        _error = '';
      });

      // Fetch / verify exact chapter counts from backend in background
      _refreshChapterCountsInBackground(list);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _granths = [];
        _isLoading = false;
        _error = 'Unable to load granths. Please try again.';
      });
    }
  }

  Future<void> _refreshChapterCountsInBackground(List<dynamic> granths) async {
    try {
      final updatedList = List<dynamic>.from(granths);
      bool hasChanges = false;

      for (int i = 0; i < updatedList.length; i++) {
        final g = Map<String, dynamic>.from(updatedList[i] as Map);
        final gId = (g['_id'] ?? g['id'] ?? '').toString();
        if (gId.isEmpty) continue;

        try {
          final chapters = await ApiService.getChaptersByGranth(gId);
          final realCount = chapters.length;
          if (g['totalChapters'] != realCount) {
            g['totalChapters'] = realCount;
            g['chaptersCount'] = realCount;
            g['chapterCount'] = realCount;
            updatedList[i] = g;
            hasChanges = true;
          }
        } catch (_) {}
      }

      if (hasChanges && mounted) {
        setState(() {
          _granths = updatedList;
        });
      }
    } catch (_) {}
  }

  int _resolveChapterCount(Map<String, dynamic> granth) {
    // 1. Check if backend provided a valid chapter count
    final dynamic totalChapters = granth['totalChapters'] ?? granth['chaptersCount'] ?? granth['chapterCount'];
    if (totalChapters != null) {
      final parsed = int.tryParse(totalChapters.toString());
      if (parsed != null && parsed >= 0) return parsed;
    }

    // 2. Check if embedded chapters list exists
    if (granth['chapters'] is List && (granth['chapters'] as List).isNotEmpty) {
      return (granth['chapters'] as List).length;
    }

    return 0;
  }

  Future<void> _toggleGranthSave(Map<String, dynamic> granth) async {
    final isNowSaved = await SavedItemsService.toggleSaveGranth(granth);
    final granthId = (granth['_id'] ?? granth['id'] ?? '').toString();
    final name = (granth['name'] ?? granth['title'] ?? 'Granth').toString();

    setState(() {
      if (isNowSaved) {
        _savedGranthIds.add(granthId);
      } else {
        _savedGranthIds.remove(granthId);
      }
    });

    if (mounted) {
      TopToastNotification.showSavedNotification(
        context: context,
        title: name,
        isSaved: isNowSaved,
        savedTabIndex: 0,
      );
    }
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
            (widget.category['title'] ?? widget.category['name'] ?? 'Granth').toString(),
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
              onPressed: _isLoading ? null : _loadGranths,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700)),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
            )
          ],
        ),
      );
    }

    if (_granths.isEmpty) {
      return Center(
        child: Text(
          'No granths available in this category.',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        // ── Royal Saffron Category Hero Banner ──────────────────────────
        Container(
          constraints: const BoxConstraints(minHeight: 145),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF6F00),
                Color(0xFFFF9E3D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7700).withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 96,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: _buildHeaderImage(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            'SACRED COLLECTION',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      (widget.category['name'] ?? widget.category['title'] ?? 'Granth Category').toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (widget.category['description'] ?? 'Explore sacred scriptures and timeless teachings.').toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.94),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Section Title & Count ───────────────────────────────────────
        Row(
          children: [
            Text(
              'Available Scriptures',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_granths.length} ${_granths.length == 1 ? 'Granth' : 'Granths'}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD35400),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Granth List ────────────────────────────────────────────────
        ..._granths.map((granth) => _buildGranthCard(granth as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildHeaderImage() {
    final rawImg = (widget.category['image'] ?? widget.category['coverImage'] ?? '').toString();
    final resolvedUrl = ApiService.resolveImageUrl(rawImg);

    if (resolvedUrl.startsWith('http')) {
      return Image.network(
        resolvedUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _placeholderImage(),
      );
    } else if (rawImg.startsWith('assets/')) {
      return Image.asset(
        rawImg,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _placeholderImage(),
      );
    }
    return Image.asset(
      'assets/images/image_2.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: Colors.white.withValues(alpha: 0.15),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: 38,
      ),
    );
  }

  Widget _buildGranthImage(Map<String, dynamic> granth) {
    final rawImg = (granth['coverImage'] ?? granth['image'] ?? '').toString();

    final resolved = ApiService.resolveImageUrl(rawImg);
    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _granthImageFallback(),
      );
    }
    if (rawImg.startsWith('assets/')) {
      return Image.asset(
        rawImg,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _granthImageFallback(),
      );
    }
    return _granthImageFallback();
  }

  Widget _granthImageFallback() {
    return Container(
      color: const Color(0xFF8F4D18),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildGranthCard(Map<String, dynamic> granth) {
    final granthId = (granth['_id'] ?? granth['id'] ?? '').toString();
    final isSaved = _savedGranthIds.contains(granthId);
    final int chapterCount = _resolveChapterCount(granth);
    final String chapterText = chapterCount == 1 ? '1 Chapter' : '$chapterCount Chapters';
    final author = (granth['author'] ?? '').toString();
    final language = (granth['language'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E4D6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Book cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 76,
                  height: 96,
                  color: const Color(0xFFF7ECE1),
                  child: _buildGranthImage(granth),
                ),
              ),
              const SizedBox(width: 14),
              // Granth information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (granth['name'] ?? granth['title'] ?? 'Sacred Granth').toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (author.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        author,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2E6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFD4AE), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_stories_rounded, size: 12, color: Color(0xFFFF7700)),
                              const SizedBox(width: 4),
                              Text(
                                chapterText,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD35400),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (language.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EFEA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              language,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5A524A),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action buttons: Bookmark and Arrow
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _toggleGranthSave(granth),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSaved ? const Color(0xFFFFF1E5) : const Color(0xFFF7F3EF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: isSaved ? const Color(0xFFFF7700) : const Color(0xFFA28D7B),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFF7700),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
