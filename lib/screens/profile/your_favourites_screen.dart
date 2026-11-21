import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/saved_items_service.dart';
import '../details/granth_screen.dart';
import '../details/live_darshan_screen.dart';
import '../details/jap_counter_screen.dart';

class YourFavouritesScreen extends StatefulWidget {
  const YourFavouritesScreen({super.key});

  @override
  State<YourFavouritesScreen> createState() => _YourFavouritesScreenState();
}

class _YourFavouritesScreenState extends State<YourFavouritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  Map<String, List<Map<String, dynamic>>> _favs = {
    'granth': [],
    'darshan': [],
    'bhajan': [],
    'jap': [],
    'utsav': [],
  };

  final List<Map<String, dynamic>> _tabs = const [
    {'key': 'granth', 'label': 'Granth', 'icon': Icons.menu_book_rounded},
    {'key': 'darshan', 'label': 'Darshan', 'icon': Icons.temple_hindu_rounded},
    {'key': 'bhajan', 'label': 'Bhajan', 'icon': Icons.music_note_rounded},
    {'key': 'jap', 'label': 'Jap', 'icon': Icons.self_improvement_rounded},
    {'key': 'utsav', 'label': 'Utsav', 'icon': Icons.celebration_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAllFavourites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFavourites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

      Map<String, List<Map<String, dynamic>>> serverData = {
        'granth': [],
        'darshan': [],
        'bhajan': [],
        'jap': [],
        'utsav': [],
      };

      if (token.isNotEmpty) {
        serverData = await ApiService.getAllUserFavourites(token);
      }

      // Merge local saved Granths / Chapters from SavedItemsService so offline bookmarks show up too
      try {
        final localGranths = await SavedItemsService.getSavedGranths();
        final existingIds = serverData['granth']!.map((e) => e['id'].toString()).toSet();
        for (final g in localGranths) {
          final gid = g['id']?.toString() ?? g['_id']?.toString() ?? '';
          if (gid.isNotEmpty && !existingIds.contains(gid)) {
            serverData['granth']!.add({
              'id': gid,
              'title': g['title']?.toString() ?? g['name']?.toString() ?? 'Sacred Granth',
              'subtitle': g['subtitle']?.toString() ?? g['author']?.toString() ?? 'Saved Granth',
              'image': g['coverImage']?.toString() ?? g['image']?.toString() ?? '',
              'category': 'granth',
            });
          }
        }
      } catch (_) {}

      // Show ONLY explicitly hearted/favourited Japs from SavedItemsService
      try {
        final localFavJaps = await SavedItemsService.getFavouriteJaps();
        serverData['jap'] = localFavJaps
            .map((j) => {
                  'id': j['id']?.toString() ?? '',
                  'title': j['title']?.toString() ?? 'Sacred Jap',
                  'subtitle': j['subtitle']?.toString() ?? 'Favourite Jap',
                  'image': j['image']?.toString() ?? '',
                  'category': 'jap',
                })
            .where((j) => (j['id'] as String).isNotEmpty)
            .toList();
      } catch (_) {
        serverData['jap'] = [];
      }

      if (mounted) {
        setState(() {
          _favs = serverData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openItem(String key, Map<String, dynamic> item) {
    if (key == 'granth') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GranthScreen()));
    } else if (key == 'darshan') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveDarshanScreen(
            darshanId: item['id']?.toString() ?? '',
            templeName: item['title']?.toString() ?? 'Live Darshan',
            imageUrl: item['image']?.toString() ?? '',
          ),
        ),
      );
    } else if (key == 'jap') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const JapCounterScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['title'] ?? 'Item'} opened'),
          backgroundColor: const Color(0xFFFF7700),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Favourites',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEFE6DB)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFFFF7700),
                borderRadius: BorderRadius.circular(11),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B625B),
              labelStyle: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600),
              tabs: _tabs.map((t) {
                final key = t['key'] as String;
                final count = _favs[key]?.length ?? 0;
                return Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t['icon'] as IconData, size: 15),
                        const SizedBox(width: 5),
                        Text('${t['label']} ($count)'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7700)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 42, color: Color(0xFFFF7700)),
                      const SizedBox(height: 10),
                      Text(
                        'Unable to load favourites',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadAllFavourites,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7700),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((t) {
                    final key = t['key'] as String;
                    final items = _favs[key] ?? [];
                    final iconData = t['icon'] as IconData;
                    final label = t['label'] as String;

                    if (items.isEmpty) {
                      return RefreshIndicator(
                        color: const Color(0xFFFF7700),
                        onRefresh: _loadAllFavourites,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 110),
                            Icon(iconData, size: 48, color: const Color(0xFFD6C7B8)),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No favourite $label yet',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B625B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                'Items you like or save in $label will appear here.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  color: const Color(0xFF9E8A78),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: const Color(0xFFFF7700),
                      onRefresh: _loadAllFavourites,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          final title = item['title']?.toString() ?? label;
                          final subtitle = item['subtitle']?.toString() ?? '';
                          final image = item['image']?.toString() ?? '';

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openItem(key, item),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFEFE6DB)),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      color: const Color(0xFFFFF4E6),
                                      child: image.startsWith('http')
                                          ? Image.network(
                                              image,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                iconData,
                                                color: const Color(0xFFFF7700),
                                              ),
                                            )
                                          : (image.startsWith('assets/')
                                              ? Image.asset(
                                                  image,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Icon(
                                                    iconData,
                                                    color: const Color(0xFFFF7700),
                                                  ),
                                                )
                                              : Icon(iconData, color: const Color(0xFFFF7700))),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF2E2A36),
                                          ),
                                        ),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: const Color(0xFF7B7066),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: key == 'jap'
                                        ? () async {
                                            await SavedItemsService.toggleFavouriteJap(item);
                                            _loadAllFavourites();
                                          }
                                        : null,
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.favorite_rounded,
                                        color: Color(0xFFE53935),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFFB5A89B),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
