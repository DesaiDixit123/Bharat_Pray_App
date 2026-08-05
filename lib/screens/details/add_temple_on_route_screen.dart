import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class TempleRouteItem {
  final String name;
  final String distance;
  final String imageAsset;
  final String phone;
  final String schedule;
  final double? lat;
  final double? lng;

  const TempleRouteItem({
    required this.name,
    required this.distance,
    required this.imageAsset,
    required this.phone,
    required this.schedule,
    this.lat,
    this.lng,
  });
}

class AddTempleOnRouteScreen extends StatefulWidget {
  final String title;
  final String distance;
  final String steps;
  final String duration;
  final String sangha;
  final String imageAsset;
  final List<TempleRouteItem>? initialSelectedTemples;
  final List<dynamic>? routeTemplesData;

  const AddTempleOnRouteScreen({
    super.key,
    required this.title,
    required this.distance,
    required this.steps,
    required this.duration,
    required this.sangha,
    required this.imageAsset,
    this.initialSelectedTemples,
    this.routeTemplesData,
  });

  @override
  State<AddTempleOnRouteScreen> createState() => _AddTempleOnRouteScreenState();
}

class _AddTempleOnRouteScreenState extends State<AddTempleOnRouteScreen> {
  static const Color _bg = Color(0xFFFFE8D6);
  static const Color _accent = Color(0xFFFF7A00);
  static const Color _mutedText = Color(0xFFC8A882);
  static const Color _titleText = Color(0xFF2E2A36);
  static const String _backArrowSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''';
  static const String _selectedTempleSvg = '''<svg width="30" height="30" viewBox="0 0 30 30" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="15" cy="15" r="14.5" stroke="#2E7D32"/>
<path d="M9.8 15.3L13.1 18.6L20.2 11.7" stroke="#2E7D32" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedTempleIds = <String>{};

  bool _isLoading = false;
  List<TempleRouteItem> _apiTemples = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedTemples != null) {
      for (final item in widget.initialSelectedTemples!) {
        _selectedTempleIds.add(_templeId(item));
      }
    }
    _loadTemples();
  }

  Future<void> _loadTemples({String search = ''}) async {
    setState(() { _isLoading = true; });
    try {
      final List<TempleRouteItem> fetched = [];

      // Fetch DB temples lookup dictionary to resolve unpopulated templeId IDs!
      List allDbTemples = [];
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        final res = await ApiService.getTemplesForGroup(token, search: '');
        allDbTemples = (res['docs'] is List)
            ? res['docs']
            : (res is List ? res : []);
      } catch (err) {
        debugPrint('DB Temples lookup fetch error: $err');
      }

      if (widget.routeTemplesData != null && widget.routeTemplesData!.isNotEmpty) {
        final query = search.trim().toLowerCase();

        for (int i = 0; i < widget.routeTemplesData!.length; i++) {
          final item = widget.routeTemplesData![i];
          if (item == null) continue;

          // Extract templeId ID string
          String tIdStr = '';
          if (item is Map) {
            if (item['templeId'] is Map) {
              tIdStr = item['templeId']['_id']?.toString() ?? '';
            } else if (item['templeId'] != null) {
              tIdStr = item['templeId'].toString();
            }
            if (tIdStr.isEmpty) {
              tIdStr = item['_id']?.toString() ?? '';
            }
          }

          // Match with DB temples lookup if available
          Map? dbMatched;
          if (tIdStr.isNotEmpty && allDbTemples.isNotEmpty) {
            for (final dbT in allDbTemples) {
              if (dbT is Map && dbT['_id']?.toString() == tIdStr) {
                dbMatched = dbT;
                break;
              }
            }
          }

          // 1. Extract Name accurately
          String name = '';
          if (item is Map) {
            if (item['name'] != null && item['name'].toString().trim().isNotEmpty) {
              name = item['name'].toString().trim();
            }
            if (name.isEmpty && item['templeId'] is Map && item['templeId']['name'] != null) {
              name = item['templeId']['name'].toString().trim();
            }
            if (name.isEmpty && dbMatched != null && dbMatched['name'] != null) {
              name = dbMatched['name'].toString().trim();
            }
            if (name.isEmpty && item['templeName'] != null && item['templeName'].toString().trim().isNotEmpty) {
              name = item['templeName'].toString().trim();
            }
            if (name.isEmpty && item['title'] != null && item['title'].toString().trim().isNotEmpty) {
              name = item['title'].toString().trim();
            }
            if (name.isEmpty && item['address'] != null && item['address'].toString().trim().isNotEmpty) {
              name = item['address'].toString().trim();
            }
          }
          if (name.isEmpty) {
            if (i < allDbTemples.length && allDbTemples[i] is Map && allDbTemples[i]['name'] != null) {
              name = allDbTemples[i]['name'].toString().trim();
            } else {
              name = 'Temple Stop #${i + 1}';
            }
          }

          // 2. Extract Location (City, State, or Address)
          String locationStr = '';
          if (item is Map) {
            final Map? tObj = (item['templeId'] is Map) ? (item['templeId'] as Map) : (dbMatched ?? item);
            final city = (tObj?['city'] ?? item['city'])?.toString() ?? '';
            final state = (tObj?['state'] ?? item['state'])?.toString() ?? '';
            final address = (tObj?['address'] ?? item['address'])?.toString() ?? '';

            final loc = [city, state].where((s) => s.trim().isNotEmpty).join(', ');
            locationStr = loc.isNotEmpty ? loc : address;
          }
          if (locationStr.trim().isEmpty) {
            locationStr = 'Sacred Stop on Yatra Path';
          }

          // 3. Search Filter
          if (query.isNotEmpty) {
            final matches = name.toLowerCase().contains(query) ||
                            locationStr.toLowerCase().contains(query);
            if (!matches) continue;
          }

          // 4. Extract Image & resolve URL
          String img = '';
          if (item is Map) {
            final Map? tObj = (item['templeId'] is Map) ? (item['templeId'] as Map) : (dbMatched ?? item);
            img = (tObj?['thumbnailImage'] ?? tObj?['bannerImage'] ?? item['thumbnailImage'] ?? item['bannerImage'] ?? item['image'])?.toString() ?? '';
          }
          final resolvedImg = ApiService.resolveImageUrl(img);

          // 5. Extract Coordinates
          double? lat;
          double? lng;
          if (item is Map) {
            final Map? tObj = (item['templeId'] is Map) ? (item['templeId'] as Map) : (dbMatched ?? item);
            lat = double.tryParse((tObj?['latitude'] ?? item['latitude'] ?? '').toString());
            lng = double.tryParse((tObj?['longitude'] ?? item['longitude'] ?? '').toString());
          }

          // 6. Format Distance matching Admin Timeline
          dynamic distStartRaw = item is Map ? (item['distanceFromStart'] ?? item['distance']) : null;
          dynamic distPrevRaw = item is Map ? item['distanceFromPrevious'] : null;

          String distInfo = 'Stop #${i + 1}';
          if (distStartRaw != null && distStartRaw.toString().isNotEmpty) {
            final num distStart = num.tryParse(distStartRaw.toString()) ?? 0;
            distInfo += ' • ${distStart.toStringAsFixed(2)} KM from Start';
          }
          if (distPrevRaw != null && distPrevRaw.toString().isNotEmpty) {
            final num distPrev = num.tryParse(distPrevRaw.toString()) ?? 0;
            if (distPrev > 0) {
              distInfo += ' (+${distPrev.toStringAsFixed(2)} KM)';
            }
          }

          fetched.add(
            TempleRouteItem(
              name: name,
              distance: locationStr,
              imageAsset: resolvedImg,
              phone: tIdStr.isNotEmpty ? tIdStr : '$i',
              schedule: distInfo,
              lat: lat,
              lng: lng,
            ),
          );
        }
      } else {
        // Fallback: fetch general DB temples if no routeTemplesData was configured
        for (int i = 0; i < allDbTemples.length; i++) {
          final item = allDbTemples[i];
          final name = item['name']?.toString() ?? 'Temple';
          final city = item['city']?.toString() ?? '';
          final state = item['state']?.toString() ?? '';
          final locationStr = [city, state].where((s) => s.isNotEmpty).join(', ');

          String img = item['thumbnailImage']?.toString() ?? item['bannerImage']?.toString() ?? '';
          final resolvedImg = ApiService.resolveImageUrl(img);

          final lat = double.tryParse(item['latitude']?.toString() ?? '');
          final lng = double.tryParse(item['longitude']?.toString() ?? '');

          fetched.add(
            TempleRouteItem(
              name: name,
              distance: locationStr.isNotEmpty ? locationStr : 'Shrimandir',
              imageAsset: resolvedImg,
              phone: item['_id']?.toString() ?? '$i',
              schedule: 'Stop #${i + 1} • Available for Darshan',
              lat: lat,
              lng: lng,
            ),
          );
        }
      }

      setState(() {
        _apiTemples = fetched;
      });
    } catch (e) {
      debugPrint('Error loading temples: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  bool get _isAllSelected =>
      _apiTemples.isNotEmpty &&
      _apiTemples.every((item) => _selectedTempleIds.contains(_templeId(item)));

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedTempleIds.clear();
      } else {
        for (final item in _apiTemples) {
          _selectedTempleIds.add(_templeId(item));
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _templeId(TempleRouteItem item) => '${item.name}|${item.phone}';

  void _toggleTemple(TempleRouteItem item) {
    final id = _templeId(item);
    setState(() {
      if (_selectedTempleIds.contains(id)) {
        _selectedTempleIds.remove(id);
      } else {
        _selectedTempleIds.add(id);
      }
    });
  }

  void _openRouteSummary() {
    final selected = _apiTemples.where((item) {
      return _selectedTempleIds.contains(_templeId(item));
    }).toList();

    // Also include any initial selected temples if they were selected
    if (widget.initialSelectedTemples != null) {
      for (final item in widget.initialSelectedTemples!) {
        if (_selectedTempleIds.contains(_templeId(item)) && !selected.any((s) => _templeId(s) == _templeId(item))) {
          selected.add(item);
        }
      }
    }

    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _openRouteSummary,
              child: Text(
                'Add Temple on the Route',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFC8A882),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.string(
                          _backArrowSvg,
                          width: 15,
                          height: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Temple on Route',
                      style: GoogleFonts.outfit(
                        color: _titleText,
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC8A882), width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _loadTemples(search: val.trim()),
                  style: GoogleFonts.outfit(
                    color: _titleText,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, city or state',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFC8A882),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFC8A882),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : _apiTemples.isEmpty
                      ? Center(
                          child: Text(
                            'No temples found on this route.',
                            style: GoogleFonts.outfit(color: _mutedText, fontSize: 15),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _SectionTitle(text: 'Available Route Temples', color: _accent),
                                  InkWell(
                                    onTap: _toggleSelectAll,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _isAllSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                            size: 18,
                                            color: _accent,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isAllSelected ? 'Deselect All' : 'Select All',
                                            style: GoogleFonts.outfit(
                                              color: _accent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._apiTemples.map(
                                (item) => _TempleItemRow(
                                  item: item,
                                  accent: _accent,
                                  mutedText: _mutedText,
                                  isSelected: _selectedTempleIds.contains(_templeId(item)),
                                  selectedTempleSvg: _selectedTempleSvg,
                                  onToggle: () => _toggleTemple(item),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TempleItemRow extends StatelessWidget {
  final TempleRouteItem item;
  final Color accent;
  final Color mutedText;
  final bool isSelected;
  final String selectedTempleSvg;
  final VoidCallback onToggle;

  const _TempleItemRow({
    required this.item,
    required this.accent,
    required this.mutedText,
    required this.isSelected,
    required this.selectedTempleSvg,
    required this.onToggle,
  });

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/somnath_temple_new.png',
          width: 70,
          height: 70,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      path.isNotEmpty ? path : 'assets/images/somnath_temple_new.png',
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/somnath_temple_new.png',
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildImage(item.imageAsset),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.distance,
                  style: GoogleFonts.outfit(
                    color: mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.schedule.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.schedule,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B4226),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onToggle,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: isSelected
                    ? SvgPicture.string(
                        selectedTempleSvg,
                        width: 30,
                        height: 30,
                      )
                    : Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 1.5),
                        ),
                        child: Icon(
                          Icons.add,
                          color: accent,
                          size: 20,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}