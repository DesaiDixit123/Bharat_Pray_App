import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/bhajan_track_item.dart';
import '../../services/api_service.dart';
import 'bhajan_now_playing_screen.dart';

class BhajanListByCategoryScreen extends StatefulWidget {
  const BhajanListByCategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    required this.categoryImagePath,
  });

  final String categoryId;
  final String categoryTitle;
  final String categoryImagePath;

  @override
  State<BhajanListByCategoryScreen> createState() => _BhajanListByCategoryScreenState();
}

class _BhajanListByCategoryScreenState extends State<BhajanListByCategoryScreen> {
  static const List<String> _tabs = ['All Bhajan', 'Recent', 'Liked', 'Downloaded'];

  String _selectedTab = _tabs.first;
  String _token = '';
  bool _isLoading = true;
  String _error = '';
  List<BhajanTrackItem> _tracks = const [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    await _loadTracks();
  }

  Future<void> _loadTracks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      List<dynamic> rawList;
      switch (_selectedTab) {
        case 'Recent':
          if (_token.isEmpty) {
            throw Exception('Please login to view recent tracks.');
          }
          rawList = await ApiService.getBhajanHistory(_token);
          break;
        case 'Liked':
          if (_token.isEmpty) {
            throw Exception('Please login to view liked tracks.');
          }
          rawList = await ApiService.getFavouriteBhajans(_token);
          break;
        case 'Downloaded':
          if (_token.isEmpty) {
            throw Exception('Please login to view downloads.');
          }
          rawList = await ApiService.getDownloadedBhajans(_token);
          break;
        case 'All Bhajan':
        default:
          final data = await ApiService.getBhajansByCategory(_token, widget.categoryId, limit: 100);
          rawList = _extractList(data);
          break;
      }

      final parsed = rawList
          .map((item) => _toTrack(item))
          .where((item) => item != null)
          .cast<BhajanTrackItem>()
          .toList();

      final visible = _selectedTab == 'All Bhajan'
          ? parsed
          : parsed.where((track) => _belongsToCategory(track, widget.categoryId)).toList();

      if (!mounted) return;
      setState(() {
        _tracks = visible;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _belongsToCategory(BhajanTrackItem track, String categoryId) {
    final lhs = (track.categoryId ?? '').trim();
    final rhs = categoryId.trim();
    if (lhs.isEmpty || rhs.isEmpty) {
      return true;
    }
    return lhs == rhs;
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is! Map<String, dynamic>) {
      return const [];
    }

    const keys = [
      'docs',
      'items',
      'data',
      'list',
      'results',
      'bhajans',
      'favourites',
      'downloads',
      'history',
    ];

    for (final key in keys) {
      final value = raw[key];
      if (value is List) {
        return value;
      }
    }

    for (final value in raw.values) {
      if (value is List) {
        return value;
      }
    }

    return const [];
  }

  BhajanTrackItem? _toTrack(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final nested = raw['bhajan'];
    final bhajanMap = nested is Map<String, dynamic> ? nested : raw;

    final id = (bhajanMap['_id'] ?? bhajanMap['id'] ?? '').toString();
    if (id.isEmpty) {
      return null;
    }

    final categoryValue = bhajanMap['categoryId'];
    String categoryId = '';
    if (categoryValue is Map<String, dynamic>) {
      categoryId = (categoryValue['_id'] ?? categoryValue['id'] ?? '').toString();
    } else {
      categoryId = categoryValue?.toString() ?? '';
    }

    final durationRaw = bhajanMap['duration'];
    final duration = _formatDuration(durationRaw);

    final image = (bhajanMap['coverImage'] ?? bhajanMap['image'] ?? '').toString();
    final isLiked = (raw['isLiked'] ?? raw['liked'] ?? bhajanMap['isLiked'] ?? false) == true;
    final isDownloaded =
        (raw['isDownloaded'] ?? raw['downloaded'] ?? bhajanMap['isDownloaded'] ?? false) == true;
    final isFavourite =
        (raw['isFavourite'] ?? raw['favourite'] ?? bhajanMap['isFavourite'] ?? false) == true;

    return BhajanTrackItem(
      id: id,
      title: (bhajanMap['title'] ?? bhajanMap['name'] ?? 'Untitled Bhajan').toString(),
      singer: (bhajanMap['artist'] ?? bhajanMap['singer'] ?? 'Traditional').toString(),
      imagePath: ApiService.resolveImageUrl(image), // This is the cover image
      audioUrl: null, // The actual stream URL will be fetched in BhajanNowPlayingScreen
      duration: duration,
      lyrics: (bhajanMap['lyrics'] ?? '').toString(),
      categoryId: categoryId,
      isLiked: isLiked,
      isDownloaded: isDownloaded,
      isFavourite: isFavourite,
    );
  }

  String? _formatDuration(dynamic durationRaw) {
    if (durationRaw == null) {
      return null;
    }

    if (durationRaw is String && durationRaw.contains(':')) {
      return durationRaw;
    }

    final seconds = durationRaw is int
        ? durationRaw
        : int.tryParse(durationRaw.toString()) ?? 0;
    if (seconds <= 0) {
      return null;
    }

    final minutesPart = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsPart = (seconds % 60).toString().padLeft(2, '0');
    return '$minutesPart:$secondsPart';
  }

  String get _bannerSubtitle {
    switch (widget.categoryTitle.toLowerCase()) {
      case 'krishna bhajans':
        return 'Immerse yourself in the love and leelas of Lord Krishna.';
      case 'shiv bhajans':
        return 'Feel the power and calm of Mahadev through sacred melodies.';
      case 'hanuman bhajans':
        return 'Listen to energetic chants filled with devotion and strength.';
      case 'rama bhajans':
        return 'Experience peace through the divine name of Shri Ram.';
      case 'devi bhajans':
        return 'Celebrate the grace of Maa through soulful bhajans.';
      default:
        return 'Explore divine bhajans by categories.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _buildHeader(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTracks,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  children: [
                    _buildBanner(),
                    const SizedBox(height: 14),
                    _buildFilterTabs(),
                    const SizedBox(height: 14),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF7700))),
                      )
                    else if (_error.isNotEmpty)
                      _buildError()
                    else if (_tracks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Center(
                          child: Text(
                            'No bhajans available in this section.',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                            color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._tracks.map((track) => _buildTrackCard(track, _tracks)),
                  ],
                ),
              ),
            ),
            if (_tracks.isNotEmpty) _buildMiniPlayer(_tracks.first, _tracks),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left back arrow button
          Positioned(
            left: 0,
            child: _BhajanBackButton(onTap: () => Navigator.pop(context)),
          ),
          // Screen Title
          Text(
            widget.categoryTitle,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            _error,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loadTracks,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700)),
            child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildNetworkOrFallbackImage(widget.categoryImagePath),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xC31A1209), Color(0x8A5B2F0A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 230,
                    child: Text(
                      widget.categoryTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 240,
                    child: Text(
                      _bannerSubtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final selected = tab == _selectedTab;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (_selectedTab == tab) {
                return;
              }
              setState(() => _selectedTab = tab);
              await _loadTracks();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF7700) : const Color(0xFFFFEAD8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  tab,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF8E5A2A),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openNowPlaying(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BhajanNowPlayingScreen(currentTrack: track, queue: queue),
      ),
    );
  }

  Widget _buildTrackCard(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, 
        borderRadius: BorderRadius.circular(16), 
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildNetworkOrFallbackImage(track.imagePath, width: 54, height: 54),
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E2A36),
            ),
          ),
          subtitle: Text(
            track.singer,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
            ),
          ),
          trailing: SizedBox(
            width: 64, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _openNowPlaying(track, queue),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFA144)),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: Color(0xFFFF8A1E),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox( 
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero, 
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF2E2A36)),
                    onPressed: () {},
                    iconSize: 24,
                  ),
                )
              ],
            ),
          ),
          onTap: () => _openNowPlaying(track, queue),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3E4D6)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildNetworkOrFallbackImage(track.imagePath, width: 42, height: 42),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                Text(
                  track.singer,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _openNowPlaying(track, queue),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7B0F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.playlist_add_check_rounded, color: Color(0xFFBD8A57), size: 21),
        ],
      ),
    );
  }

  Widget _buildNetworkOrFallbackImage(String image, {double? width, double? height}) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => _fallbackImage(width: width, height: height),
      );
    }
    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => _fallbackImage(width: width, height: height),
      );
    }
    return _fallbackImage(width: width, height: height);
  }

  Widget _fallbackImage({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFFFF1E5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.music_note_rounded,
        size: 20,
        color: Color(0xFFB56E28),
      ),
    );
  }
}

class _BhajanBackButton extends StatelessWidget {
  final VoidCallback onTap;

  static const String _backArrowSvg = '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>'
      '</svg>';

  const _BhajanBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
        ),
        child: Center(
          child: SvgPicture.string(
            _backArrowSvg,
            width: 15,
            height: 15,
          ),
        ),
      ),
    );
  }
}
