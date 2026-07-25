import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'deity_temples_screen.dart';
import 'live_darshan_screen.dart';

class DarshanTabContent extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;
  const DarshanTabContent({super.key, this.onTabChanged});

  @override
  State<DarshanTabContent> createState() => _DarshanTabContentState();
}

class _DarshanTabContentState extends State<DarshanTabContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _token = '';
  String _selectedCategoryId = "All";
  List<dynamic> _categories = [];
  List<String> _recentSearches = [];
  List<dynamic> _deities = [];

  bool _isLoading = false;
  bool _isError = false;
  int _currentPage = 1;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasNextPage) {
        _fetchDeities(page: _currentPage + 1);
      }
    }
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    if (_token.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _isError = false;
      });
      try {
        await Future.wait([
          _fetchCategories(),
          _fetchRecentSearches(),
          _fetchDeities(page: 1, isRefresh: true),
        ]);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isError = true;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await ApiService.getGodCategories(_token);
      if (mounted) {
        setState(() {
          _categories = [
            {"_id": "All", "name": "All"},
            ...data
          ];
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _fetchRecentSearches() async {
    try {
      final data = await ApiService.getRecentSearches(_token);
      if (mounted) {
        setState(() {
          _recentSearches = List<String>.from(data.map((item) => item['query'].toString()));
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent searches: $e');
    }
  }

  Future<void> _fetchDeities({required int page, bool isRefresh = false}) async {
    if (_token.isEmpty) return;

    if (isRefresh) {
      _currentPage = 1;
      _hasNextPage = false;
    }

    try {
      final data = await ApiService.getDarshansList(
        token: _token,
        search: _searchController.text,
        categoryId: _selectedCategoryId,
        page: page,
      );

      if (mounted) {
        setState(() {
          final docs = data['docs'] ?? [];
          if (isRefresh) {
            _deities = docs;
          } else {
            _deities.addAll(docs);
          }
          _currentPage = data['page'] ?? page;
          _hasNextPage = data['hasNextPage'] ?? false;
          _isError = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching deities list: $e');
      if (mounted && isRefresh) {
        setState(() {
          _isError = true;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchDeities(page: 1, isRefresh: true);
      if (query.trim().isNotEmpty) {
        _saveSearchQuery(query.trim());
      }
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    try {
      await ApiService.saveSearchQuery(_token, query);
      _fetchRecentSearches();
    } catch (e) {
      debugPrint('Error saving search query: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      await ApiService.clearRecentSearches(_token);
      if (mounted) {
        setState(() {
          _recentSearches.clear();
        });
      }
    } catch (e) {
      debugPrint('Error clearing searches: $e');
    }
  }

  Widget _buildPlaceholderImage(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF7A00).withOpacity(0.05),
            const Color(0xFFFF7A00).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.temple_hindu_outlined,
                color: Color(0xFFFF7A00),
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFFFF7A00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveImageUrl(String? url) {
    return ApiService.resolveImageUrl(url);
  }

  Widget _buildRecentSearchChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _fetchDeities(page: 1, isRefresh: true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFE6DB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded, size: 12, color: const Color(0xFF2E2A36).withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF2E2A36),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridDeityCard(BuildContext context, dynamic deity) {
    final String imagePath = _resolveImageUrl(deity['image']);
    final String deityName = deity['name'] ?? 'Deity';
    final String templeName = (deity['temple'] != null) ? (deity['temple']['name'] ?? '') : '';

    return GestureDetector(
      onTap: () async {
        final tabIndex = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeityTemplesScreen(
              deityName: deityName,
              imageUrl: imagePath,
            ),
          ),
        );
        if (tabIndex is int && widget.onTabChanged != null) {
          widget.onTabChanged!(tabIndex);
        }
      },
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: imagePath.isNotEmpty
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _buildPlaceholderImage(deityName),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: const Color(0xFFFF7A00),
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : _buildPlaceholderImage(deityName),
                ),
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      templeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF2E2A36).withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Start Darshan button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF7A00), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveDarshanScreen(
                                darshanId: deity['_id']?.toString() ?? '',
                                templeName: templeName.isNotEmpty ? templeName : deityName,
                                imageUrl: imagePath,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Start Darshan',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF7A00),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth - 40 - 12) / 2;
    final double childAspectRatio = cardWidth / 233;

    return RefreshIndicator(
      color: const Color(0xFFFF7A00),
      backgroundColor: Colors.white,
      onRefresh: () => _fetchDeities(page: 1, isRefresh: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFEFE6DB),
                        width: 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(color: const Color(0xFF2E2A36)),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search gods, temples...',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFF2E2A36).withOpacity(0.4),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF2E2A36).withOpacity(0.4),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchDeities(page: 1, isRefresh: true);
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Orange filter button
                Container(
                  height: 48,
                  width: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7700),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // 2. Recent Searches Row
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT SEARCHES',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36).withOpacity(0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearRecentSearches,
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF7A00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 3. Recent search chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.take(4).map((query) => _buildRecentSearchChip(query)).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Horizontal Categories row
          if (_categories.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final catId = cat['_id'].toString();
                  final catName = cat['name'].toString();
                  final isActive = _selectedCategoryId == catId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = catId;
                        });
                        _fetchDeities(page: 1, isRefresh: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFFF7A00) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? Colors.transparent : const Color(0xFFEFE6DB),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          catName,
                          style: GoogleFonts.outfit(
                            color: isActive ? Colors.white : const Color(0xFF2E2A36),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // 5. Grid of Deities (2 Columns)
          Expanded(
            child: _isError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load Darshan slots.',
                          style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF2E2A36)),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _initData,
                          child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                        )
                      ],
                    ),
                  )
                : _isLoading && _deities.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
                      )
                    : _deities.isEmpty
                        ? Center(
                            child: Text(
                              'No live Darshans found.',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: const Color(0xFF2E2A36).withOpacity(0.5),
                              ),
                            ),
                          )
                        : GridView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 140 + MediaQuery.of(context).padding.bottom),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemCount: _deities.length,
                            itemBuilder: (context, index) {
                              final deity = _deities[index];
                              return _buildGridDeityCard(context, deity);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
