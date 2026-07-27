import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'yatra_route_summary_screen.dart';

class TempleRouteItem {
  final String name;
  final String distance;
  final String imageAsset;
  final String phone;
  final String schedule;

  const TempleRouteItem({
    required this.name,
    required this.distance,
    required this.imageAsset,
    required this.phone,
    required this.schedule,
  });
}

class AddTempleOnRouteScreen extends StatefulWidget {
  final String title;
  final String distance;
  final String steps;
  final String duration;
  final String sangha;
  final String imageAsset;

  const AddTempleOnRouteScreen({
    super.key,
    required this.title,
    required this.distance,
    required this.steps,
    required this.duration,
    required this.sangha,
    required this.imageAsset,
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

  final List<TempleRouteItem> _popularTemples = const [
    TempleRouteItem(
      name: 'Harshad Mata Temple',
      distance: '210KM',
      imageAsset: 'assets/images/somnath_temple.png',
      phone: '9876543210',
      schedule: 'Day 1 • 05:00 AM',
    ),
    TempleRouteItem(
      name: 'Nageshwar Jyotirlinga',
      distance: '210KM',
      imageAsset: 'assets/images/dwarka_temple.jpg',
      phone: '9988776655',
      schedule: 'Day 1 • 05:00 AM',
    ),
    TempleRouteItem(
      name: 'Madhavpur Krishna Temple',
      distance: '210KM',
      imageAsset: 'assets/images/image_2.png',
      phone: '9090909090',
      schedule: 'Day 2 • 09:30 AM',
    ),
    TempleRouteItem(
      name: 'Kirti Mandir Porbandar',
      distance: '210KM',
      imageAsset: 'assets/images/image_4.png',
      phone: '9123456780',
      schedule: 'Day 4 • 08:45 AM',
    ),
  ];

  final List<TempleRouteItem> _searchResultTemples = const [
    TempleRouteItem(
      name: 'Bhalka Tirth',
      distance: '210KM',
      imageAsset: 'assets/images/download_1.png',
      phone: '9871200000',
      schedule: 'Day 3 • 04:00 PM',
    ),
    TempleRouteItem(
      name: 'Dwarkadhish Temple',
      distance: '210KM',
      imageAsset: 'assets/images/somnath_temple_new.png',
      phone: '9900011122',
      schedule: 'Day 5 • Evening Aarti',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TempleRouteItem> _applyFilter(List<TempleRouteItem> items) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) {
      return item.name.toLowerCase().contains(query) || item.phone.contains(query);
    }).toList();
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
    final allTemples = <TempleRouteItem>[
      ..._popularTemples,
      ..._searchResultTemples,
    ];

    final selected = allTemples.where((item) {
      return _selectedTempleIds.contains(_templeId(item));
    }).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one temple.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => YatraRouteSummaryScreen(
          title: widget.title,
          distance: widget.distance,
          steps: widget.steps,
          duration: widget.duration,
          sangha: widget.sangha,
          imageAsset: widget.imageAsset,
          selectedTemples: selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final popular = _applyFilter(_popularTemples);
    final results = _applyFilter(_searchResultTemples);

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
                  Text(
                    'Add Temple on Route',
                    style: GoogleFonts.outfit(
                      color: _titleText,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC8A882), width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.outfit(
                    color: _titleText,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone number',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFC8A882),
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: const Color(0xFFC8A882),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(text: 'Popular Temples', color: _accent),
                    const SizedBox(height: 8),
                    ...popular.map(
                      (item) => _TempleItemRow(
                        item: item,
                        accent: _accent,
                        mutedText: _mutedText,
                        isSelected: _selectedTempleIds.contains(_templeId(item)),
                        selectedTempleSvg: _selectedTempleSvg,
                        onToggle: () => _toggleTemple(item),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SectionTitle(text: 'Search Results', color: _accent),
                    const SizedBox(height: 8),
                    ...results.map(
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