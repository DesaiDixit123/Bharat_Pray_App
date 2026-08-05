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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final res = await ApiService.getTemplesForGroup(token, search: search);

      final List docs = (res['docs'] is List)
          ? res['docs']
          : (res is List ? res : []);

      final List<TempleRouteItem> fetched = [];
      for (int i = 0; i < docs.length; i++) {
        final item = docs[i];
        final name = item['name']?.toString() ?? 'Temple';
        final city = item['city']?.toString() ?? '';
        final state = item['state']?.toString() ?? '';
        final locationStr = [city, state].where((s) => s.isNotEmpty).join(', ');
        
        String img = item['thumbnailImage']?.toString() ?? item['bannerImage']?.toString() ?? '';
        if (img.isEmpty || (!img.startsWith('http') && !img.startsWith('assets/'))) {
          img = 'assets/images/somnath_temple_new.png';
        }

        final lat = double.tryParse(item['latitude']?.toString() ?? '');
        final lng = double.tryParse(item['longitude']?.toString() ?? '');

        fetched.add(
          TempleRouteItem(
            name: name,
            distance: locationStr.isNotEmpty ? locationStr : 'Shrimandir',
            imageAsset: img,
            phone: item['_id']?.toString() ?? '$i',
            schedule: 'Stop ${i + 1} • Available for Darshan',
            lat: lat,
            lng: lng,
          ),
        );
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
                            'No temples found.',
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              item.imageAsset,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  color: const Color(0xFFF3ECE4),
                  child: const Icon(Icons.image_not_supported_rounded, color: Color(0xFFC8A882)),
                );
              },
            ),
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