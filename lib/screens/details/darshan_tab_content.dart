import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/localization/localized_api_helper.dart';
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
  String _selectedState = "All";
  String _selectedCity = "All";
  List<String> _availableStates = ['All'];
  Map<String, List<String>> _stateCitiesMap = {};
  List<dynamic> _categories = [];
  List<String> _recentSearches = [];
  List<dynamic> _deities = [];

  bool get _isFilterActive => _selectedState != 'All' || _selectedCity != 'All';

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
          _fetchLocations(),
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

  Future<void> _fetchLocations() async {
    try {
      final data = await ApiService.getDarshanLocations(_token);
      if (mounted) {
        final List<dynamic> rawStates = data['states'] ?? [];
        final Map<String, dynamic> rawMap = data['stateCitiesMap'] ?? {};

        final List<String> states = ['All', ...rawStates.map((e) => e.toString())];
        final Map<String, List<String>> stateCities = {};
        rawMap.forEach((key, value) {
          if (value is List) {
            stateCities[key] = value.map((e) => e.toString()).toList();
          }
        });

        setState(() {
          _availableStates = states;
          _stateCitiesMap = stateCities;
        });
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
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
        state: _selectedState != 'All' ? _selectedState : null,
        city: _selectedCity != 'All' ? _selectedCity : null,
        page: page,
        limit: 100,
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

  void _showLocationFilterModal() {
    String tempState = _selectedState;
    String tempCity = _selectedCity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableCities = tempState == 'All'
                ? <String>['All']
                : <String>['All', ...(_stateCitiesMap[tempState] ?? [])];

            if (!availableCities.contains(tempCity)) {
              tempCity = 'All';
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBF7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5DCD0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFFFF7700),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter by Location',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E2A36),
                                ),
                              ),
                              Text(
                                'Choose state and city to explore temples',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF2E2A36), size: 22),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0E8DC), height: 1),
                  const SizedBox(height: 16),

                  // State Label
                  Row(
                    children: [
                      const Icon(Icons.map_rounded, size: 16, color: Color(0xFFFF7700)),
                      const SizedBox(width: 6),
                      Text(
                        'SELECT STATE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // State Dropdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEFE6DB), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _availableStates.contains(tempState) ? tempState : 'All',
                        isExpanded: true,
                        menuMaxHeight: 320,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF7700)),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        items: _availableStates.map((st) {
                          final isAll = st == 'All';
                          return DropdownMenuItem<String>(
                            value: st,
                            child: Row(
                              children: [
                                Icon(
                                  isAll ? Icons.public_rounded : Icons.location_on_outlined,
                                  size: 16,
                                  color: isAll ? const Color(0xFFFF7700) : const Color(0xFF2E2A36).withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isAll ? 'All States (Entire India)' : st,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: st == tempState ? FontWeight.w600 : FontWeight.w400,
                                      color: st == tempState ? const Color(0xFFFF7700) : const Color(0xFF2E2A36),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            tempState = val ?? 'All';
                            tempCity = 'All';
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // City Label
                  Row(
                    children: [
                      const Icon(Icons.location_city_rounded, size: 16, color: Color(0xFFFF7700)),
                      const SizedBox(width: 6),
                      Text(
                        'SELECT CITY / AREA',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (tempState != 'All') ...[
                        const SizedBox(width: 6),
                        Text(
                          '($tempState)',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF7700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // City Dropdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: tempState == 'All' ? const Color(0xFFF7F4EF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tempState == 'All' ? const Color(0xFFE5DDD2) : const Color(0xFFEFE6DB),
                        width: 1.2,
                      ),
                      boxShadow: tempState == 'All'
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableCities.contains(tempCity) ? tempCity : 'All',
                        isExpanded: true,
                        menuMaxHeight: 320,
                        disabledHint: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'Select a state first to view cities',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: tempState == 'All' ? Colors.grey.shade400 : const Color(0xFFFF7700),
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        items: availableCities.map((ct) {
                          final isAll = ct == 'All';
                          return DropdownMenuItem<String>(
                            value: ct,
                            child: Row(
                              children: [
                                Icon(
                                  isAll ? Icons.apartment_rounded : Icons.place_outlined,
                                  size: 16,
                                  color: isAll ? const Color(0xFFFF7700) : const Color(0xFF2E2A36).withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isAll ? (tempState == 'All' ? 'All Cities' : 'All Cities in $tempState') : ct,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: ct == tempCity ? FontWeight.w600 : FontWeight.w400,
                                      color: ct == tempCity ? const Color(0xFFFF7700) : const Color(0xFF2E2A36),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: tempState == 'All'
                            ? null
                            : (val) {
                                setModalState(() {
                                  tempCity = val ?? 'All';
                                });
                              },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons (Reset & Apply)
                  Row(
                    children: [
                      // Reset Button
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE0D5C7), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setModalState(() {
                              tempState = 'All';
                              tempCity = 'All';
                            });
                          },
                          child: Text(
                            'Reset',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2A36).withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFFFF7700),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pop(modalContext);
                            setState(() {
                              _selectedState = tempState;
                              _selectedCity = tempCity;
                            });
                            _fetchDeities(page: 1, isRefresh: true);
                          },
                          child: Text(
                            'Apply Filter',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFF7F4EF),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: const Color(0xFF2E2A36).withValues(alpha: 0.18),
          size: 32,
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
            Icon(Icons.access_time_rounded, size: 12, color: const Color(0xFF2E2A36).withValues(alpha: 0.5)),
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
    final String rawImg = (deity['image'] ??
            deity['temple']?['thumbnailImage'] ??
            deity['temple']?['bannerImage'] ??
            deity['bannerImage'] ??
            '')
        .toString();
    final String imagePath = _resolveImageUrl(rawImg);
    final String deityName = LocalizedApiHelper.parse(deity['name'], defaultValue: 'Deity');
    final String templeName = (deity['temple'] != null) ? LocalizedApiHelper.parse(deity['temple']['name']) : '';
    final String city = (deity['temple']?['city'] ?? '').toString().trim();
    final String state = (deity['temple']?['state'] ?? '').toString().trim();
    final String locationText = [city, state].where((s) => s.isNotEmpty).join(', ');
    final String liveDarshanId = (deity['darshan_id'] ?? deity['_id'])?.toString() ?? '';

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
              color: Colors.black.withValues(alpha: 0.02),
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
                          errorBuilder: (c, e, s) => _buildPlaceholderImage(),
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
                      : _buildPlaceholderImage(),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.2,
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
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                      ),
                    ),
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: const Color(0xFFFF7700).withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              locationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                                darshanId: liveDarshanId,
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
    final double childAspectRatio = cardWidth / 262;

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
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
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
                // Orange filter button with active indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7700),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                        onPressed: _showLocationFilterModal,
                      ),
                    ),
                    if (_isFilterActive)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFF7700), width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Active Location Filter Banner Chip
          if (_isFilterActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF7700).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Color(0xFFFF7700),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _selectedCity != 'All'
                              ? '$_selectedCity, $_selectedState'
                              : _selectedState,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF7700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedState = 'All';
                              _selectedCity = 'All';
                            });
                            _fetchDeities(page: 1, isRefresh: true);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7700).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: Color(0xFFFF7700),
                            ),
                          ),
                        ),
                      ],
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
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
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
                  final catName = LocalizedApiHelper.parse(cat['name']);
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.temple_hindu_rounded,
                                      size: 32,
                                      color: Color(0xFFFF7700),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isFilterActive
                                        ? 'There is not any temple'
                                        : 'No Darshans found',
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E2A36),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isFilterActive
                                        ? 'No temples found matching your selected location.'
                                        : 'No temple darshans currently available.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  if (_isFilterActive) ...[
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        backgroundColor: const Color(0xFFFF7700).withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFFF7700)),
                                      label: Text(
                                        'Clear Filter',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFF7700),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedState = 'All';
                                          _selectedCity = 'All';
                                        });
                                        _fetchDeities(page: 1, isRefresh: true);
                                      },
                                    ),
                                  ],
                                ],
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
