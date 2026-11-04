import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/bhajan_track_item.dart';
import '../../services/api_service.dart';
import '../../services/bhajan_audio_service.dart';
import '../../services/bhajan_library_service.dart';
import '../../core/localization/localized_api_helper.dart';
import '../../widgets/bhajan/bhajan_mini_player_widget.dart';
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
  String _token = '';
  bool _isLoading = true;
  String _error = '';
  List<BhajanTrackItem> _tracks = const [];
  final Set<String> _likedTrackIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    await BhajanLibraryService.instance.init(token: _token);
    await _loadTracks();
  }

  Future<void> _loadTracks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await ApiService.getBhajansByCategory(_token, widget.categoryId, limit: 100);
      final rawList = _extractList(data);

      final parsed = rawList
          .map((item) => _toTrack(item))
          .where((item) => item != null)
          .cast<BhajanTrackItem>()
          .toList();

      BhajanLibraryService.instance.syncLikedFromTracks(parsed);

      if (!mounted) return;
      setState(() {
        _tracks = parsed;
        for (final t in parsed) {
          if (t.isLiked || BhajanLibraryService.instance.isLiked(t.id)) {
            _likedTrackIds.add(t.id);
          }
        }
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

    final categoryValue = bhajanMap['godCategoryId'] ?? bhajanMap['categoryId'];
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
      title: LocalizedApiHelper.parse(bhajanMap['title'] ?? bhajanMap['name'], defaultValue: 'Untitled Bhajan'),
      singer: LocalizedApiHelper.parse(bhajanMap['artist'] ?? bhajanMap['singer'], defaultValue: 'Traditional'),
      imagePath: ApiService.resolveImageUrl(image), // This is the cover image
      audioUrl: null, // The actual stream URL will be fetched in BhajanNowPlayingScreen
      duration: duration,
      lyrics: LocalizedApiHelper.parse(bhajanMap['lyrics']),
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
    final filteredTracks = _searchQuery.isEmpty
        ? _tracks
        : _tracks.where((t) {
            return t.title.toLowerCase().contains(_searchQuery) ||
                t.singer.toLowerCase().contains(_searchQuery);
          }).toList();

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
        body: SafeArea(
          top: true,
          child: AnimatedBuilder(
            animation: BhajanLibraryService.instance,
            builder: (context, _) {
              return Column(
                children: [
                  // Clean Theme Header (No top banner image, no tabs)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: _buildHeader(),
                  ),

                  // Search Bar inside Category
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _buildSearchBar(),
                  ),

                  // Direct Bhajan List
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFFFF7700),
                      backgroundColor: Colors.white,
                      onRefresh: _loadTracks,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        children: [
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: Center(
                                child: CircularProgressIndicator(color: Color(0xFFFF7700)),
                              ),
                            )
                          else if (_error.isNotEmpty)
                            _buildError()
                          else if (filteredTracks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFC8A882)),
                                      ),
                                      child: const Icon(
                                        Icons.music_note_rounded,
                                        color: Color(0xFFC8A882),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      LocalizedApiHelper.parse('No bhajans available in this section.'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        color: const Color(0xFF8C7B6E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...filteredTracks.map((track) => _buildTrackCard(track, _tracks)),
                        ],
                      ),
                    ),
                  ),
                  const BhajanMiniPlayerWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
            ),
            child: const Center(
              child: Icon(Icons.arrow_back_rounded, color: Color(0xFFC8A882), size: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizedApiHelper.parse(widget.categoryTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              Text(
                '${_tracks.length} ${LocalizedApiHelper.parse("Bhajans")}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF8C7B6E),
                ),
              ),
            ],
          ),
        ),
        if (_tracks.isNotEmpty)
          GestureDetector(
            onTap: () => _openNowPlaying(_tracks.first, _tracks),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    LocalizedApiHelper.parse('Play All'),
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DFCE), width: 1.0),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(
          fontSize: 14.5,
          color: const Color(0xFF2E2A36),
        ),
        decoration: InputDecoration(
          hintText: LocalizedApiHelper.parse('Search bhajans, deities, singers...'),
          hintStyle: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFB56E28),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  child: const Icon(Icons.close_rounded, color: Color(0xFF999999), size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
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

  void _openNowPlaying(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    BhajanLibraryService.instance.recordRecentPlay(track);
    BhajanAudioService.instance.playTrack(track, queue: queue, token: _token);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BhajanNowPlayingScreen(currentTrack: track, queue: queue),
      ),
    );
  }

  Future<void> _toggleLike(BhajanTrackItem track) async {
    final nowLiked = await BhajanLibraryService.instance.toggleLike(track, token: _token);
    if (!mounted) return;
    setState(() {
      if (nowLiked) {
        _likedTrackIds.add(track.id);
      } else {
        _likedTrackIds.remove(track.id);
      }
    });
    BhajanLibraryService.showLightSnackBar(
      context,
      nowLiked ? 'Added to Liked Bhajans ❤️' : 'Removed from Liked Bhajans',
      icon: nowLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    );
  }

  void _onTrackMenuSelected(String action, BhajanTrackItem track) async {
    switch (action) {
      case 'download':
        final lib = BhajanLibraryService.instance;
        if (lib.isDownloaded(track.id) || lib.isDownloading(track.id)) return;
        final completed = await lib.downloadTrack(track, token: _token);
        if (!mounted) return;
        setState(() {});
        if (completed) {
          BhajanLibraryService.showLightSnackBar(
            context,
            '✅ "${track.title}" ${LocalizedApiHelper.parse("Saved to Offline Downloads")}',
            icon: Icons.download_done_rounded,
          );
        }
        break;
      case 'share':
        final shareText = '🙏 Listen to divine bhajan "${track.title}" by ${track.singer} on Bharat Pray app!\nhttps://bharatpray.com/bhajan/${track.id}';
        await Share.share(shareText, subject: track.title);
        break;
      case 'playlist':
        await BhajanLibraryService.showAddToPlaylistSheet(context, track);
        if (mounted) setState(() {});
        break;
    }
  }

  Widget _buildTrackCard(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    final isLiked = BhajanLibraryService.instance.isLiked(track.id) || _likedTrackIds.contains(track.id);

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
          subtitle: AnimatedBuilder(
            animation: BhajanLibraryService.instance,
            builder: (context, _) {
              final lib = BhajanLibraryService.instance;
              final isDownloading = lib.isDownloading(track.id);
              final pct = lib.getDownloadPercentage(track.id);
              return Row(
                children: [
                  if (isDownloading) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          value: (pct / 100.0).clamp(0.02, 1.0),
                          strokeWidth: 1.8,
                          backgroundColor: const Color(0xFFEBD7C2),
                          color: const Color(0xFFFF7700),
                        ),
                      ),
                    ),
                    Text(
                      '$pct% ',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF7700),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      '${track.singer}${track.duration != null ? " • ${track.duration}" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like (Heart) Button in place of play icon
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isLiked ? const Color(0xFFE53935) : const Color(0xFF8C7B6E),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Like Bhajan',
                onPressed: () => _toggleLike(track),
              ),
              const SizedBox(width: 2),
              // 3-dots popup menu (Download, Share, Add to Playlist)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4A3A2C), size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFF0DFCE)),
                ),
                elevation: 6,
                onSelected: (action) => _onTrackMenuSelected(action, track),
                itemBuilder: (context) {
                  final lib = BhajanLibraryService.instance;
                  final isDownloaded = lib.isDownloaded(track.id);
                  final isDownloading = lib.isDownloading(track.id);
                  final pct = lib.getDownloadPercentage(track.id);
                  return [
                    PopupMenuItem(
                      value: 'download',
                      enabled: !isDownloaded && !isDownloading,
                      child: Row(
                        children: [
                          Icon(
                            isDownloaded
                                ? Icons.download_done_rounded
                                : Icons.download_rounded,
                            size: 20,
                            color: isDownloaded
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF7700),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isDownloading
                                ? 'Downloading $pct%...'
                                : (isDownloaded
                                    ? LocalizedApiHelper.parse('Downloaded', context: context)
                                    : LocalizedApiHelper.parse('Download', context: context)),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDownloaded
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF2E2A36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          const Icon(Icons.share_rounded, size: 20, color: Color(0xFFFF7700)),
                          const SizedBox(width: 10),
                          Text(
                            LocalizedApiHelper.parse('Share', context: context),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'playlist',
                      child: Row(
                        children: [
                          const Icon(Icons.playlist_add_rounded, size: 20, color: Color(0xFFFF7700)),
                          const SizedBox(width: 10),
                        Text(
                          LocalizedApiHelper.parse('Add to Playlist', context: context),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              ),
            ],
          ),
          onTap: () => _openNowPlaying(track, queue),
        ),
      ),
    );
  }



  Widget _buildNetworkOrFallbackImage(String image, {double? width, double? height}) {
    if (image.startsWith('data:image')) {
      try {
        final commaIdx = image.indexOf(',');
        final base64Str = commaIdx != -1 ? image.substring(commaIdx + 1) : image;
        return Image.memory(
          base64Decode(base64Str),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(width: width, height: height),
        );
      } catch (_) {
        return _fallbackImage(width: width, height: height);
      }
    }
    if (image.isNotEmpty && !image.startsWith('http') && !image.startsWith('assets/') && !image.startsWith('data:image')) {
      try {
        final f = File(image);
        if (f.existsSync()) {
          return Image.file(
            f,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackImage(width: width, height: height),
          );
        }
      } catch (_) {}
    }
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
