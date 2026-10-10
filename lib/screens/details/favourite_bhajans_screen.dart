import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/bhajan_track_item.dart';
import '../../services/api_service.dart';
import 'bhajan_now_playing_screen.dart';

class FavouriteBhajansScreen extends StatefulWidget {
  const FavouriteBhajansScreen({super.key});

  @override
  State<FavouriteBhajansScreen> createState() => _FavouriteBhajansScreenState();
}

class _FavouriteBhajansScreenState extends State<FavouriteBhajansScreen> {
  String _token = '';
  bool _isLoading = true;
  String? _errorMessage;
  List<BhajanTrackItem> _tracks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

    if (_token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to view your favourite bhajans.';
      });
      return;
    }

    try {
      final rawList = await ApiService.getFavouriteBhajans(_token);
      final List<BhajanTrackItem> parsed = [];

      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final bhajanMap = (item['bhajanId'] is Map<String, dynamic>)
              ? (item['bhajanId'] as Map<String, dynamic>)
              : item;

          final id = (bhajanMap['_id'] ?? item['_id'] ?? '').toString();
          if (id.isEmpty) continue;

          final title = (bhajanMap['title'] ?? bhajanMap['name'] ?? 'Untitled Bhajan').toString();
          final singer = (bhajanMap['artist'] ?? bhajanMap['singer'] ?? 'Traditional').toString();
          final rawImg = (bhajanMap['coverImage'] ?? bhajanMap['image'] ?? '').toString();
          final imagePath = ApiService.resolveImageUrl(rawImg);

          final durationRaw = bhajanMap['duration'];
          String? formattedDuration;
          if (durationRaw != null) {
            if (durationRaw is String && durationRaw.contains(':')) {
              formattedDuration = durationRaw;
            } else {
              final sec = durationRaw is int ? durationRaw : int.tryParse(durationRaw.toString()) ?? 0;
              if (sec > 0) {
                formattedDuration = '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
              }
            }
          }

          parsed.add(BhajanTrackItem(
            id: id,
            title: title,
            singer: singer,
            imagePath: imagePath,
            audioUrl: null,
            duration: formattedDuration,
            lyrics: (bhajanMap['lyrics'] ?? '').toString(),
            categoryId: (bhajanMap['categoryId'] is Map ? bhajanMap['categoryId']['_id'] : bhajanMap['categoryId'])?.toString() ?? '',
            isLiked: true,
            isDownloaded: false,
            isFavourite: true,
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _tracks = parsed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load favourite bhajans.';
      });
    }
  }

  Future<void> _removeFavourite(BhajanTrackItem track) async {
    try {
      await ApiService.removeFavouriteBhajan(_token, track.id);
      if (!mounted) return;
      setState(() {
        _tracks.removeWhere((t) => t.id == track.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${track.title}" from favourites', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFFFF7A00),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favourite', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFFFF7A00),
        ),
      );
    }
  }

  void _openPlayer(BhajanTrackItem track) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BhajanNowPlayingScreen(
          currentTrack: track,
          queue: _tracks,
        ),
      ),
    ).then((_) => _loadData());
  }

  Widget _buildTrackImage(String image) {
    if (image.startsWith('data:image')) {
      try {
        final commaIdx = image.indexOf(',');
        final base64Str = commaIdx != -1 ? image.substring(commaIdx + 1) : image;
        return Image.memory(
          base64Decode(base64Str),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(),
        );
      } catch (_) {
        return _fallbackImage();
      }
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    }
    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      width: 50,
      height: 50,
      color: const Color(0xFFFFF0E0),
      child: const Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 24),
    );
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
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF0DEC9)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF2E2A36)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favourite Bhajans',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          if (_tracks.isNotEmpty)
                            Text(
                              '${_tracks.length} ${_tracks.length == 1 ? "track" : "tracks"} saved',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF2E2A36)),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF7A00),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    onPressed: _loadData,
                                    child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _tracks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFF1D9C1)),
                                      ),
                                      child: const Icon(Icons.favorite_border_rounded, size: 36, color: Color(0xFFFF7700)),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No favourite bhajans yet',
                                      style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2E2A36),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tap the favourite button while playing a bhajan\nto save it to this list.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                color: const Color(0xFFFF7A00),
                                onRefresh: _loadData,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                  itemCount: _tracks.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final track = _tracks[index];
                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFF1D9C1)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: _buildTrackImage(track.imagePath),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  track.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF2E2A36),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  track.singer,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                                                  ),
                                                ),
                                                if (track.duration != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    track.duration!,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: const Color(0xFFFF7A00),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.favorite_rounded, color: Color(0xFFFF3B30), size: 22),
                                            onPressed: () => _removeFavourite(track),
                                            tooltip: 'Remove from favourites',
                                          ),
                                          InkWell(
                                            onTap: () => _openPlayer(track),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              height: 36,
                                              width: 36,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF7700),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
