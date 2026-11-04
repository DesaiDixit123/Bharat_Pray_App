import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/bhajan_track_item.dart';
import '../../services/api_service.dart';
import '../../services/bhajan_audio_service.dart';
import '../../widgets/bhajan/bhajan_mini_player_widget.dart';
import '../../core/localization/localization_constants.dart';
import 'bhajan_now_playing_screen.dart';

class BhajanDownloadsScreen extends StatefulWidget {
  const BhajanDownloadsScreen({super.key});

  @override
  State<BhajanDownloadsScreen> createState() => _BhajanDownloadsScreenState();
}

class _BhajanDownloadsScreenState extends State<BhajanDownloadsScreen> {
  String _token = '';
  bool _isLoading = true;
  String _error = '';
  List<BhajanTrackItem> _tracks = [];
  final Set<String> _likedTrackIds = {};

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

    try {
      List<dynamic> rawList = [];
      if (_token.isNotEmpty) {
        rawList = await ApiService.getDownloadedBhajans(_token);
      }

      final List<BhajanTrackItem> parsed = [];
      for (final item in rawList) {
        final track = _toTrack(item);
        if (track != null) {
          parsed.add(track);
          if (track.isLiked) {
            _likedTrackIds.add(track.id);
          }
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
        _error = 'Unable to load downloaded bhajans.';
      });
    }
  }

  BhajanTrackItem? _toTrack(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return BhajanTrackItem.fromJson(raw);
  }

  void _playTrack(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    BhajanAudioService.instance.playTrack(track, queue: queue, token: _token);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BhajanNowPlayingScreen(
          currentTrack: track,
          queue: queue,
        ),
      ),
    );
  }

  void _playAll() {
    if (_tracks.isNotEmpty) {
      _playTrack(_tracks.first, _tracks);
    }
  }

  Future<void> _toggleLike(BhajanTrackItem track) async {
    final isCurrentlyLiked = _likedTrackIds.contains(track.id);
    setState(() {
      if (isCurrentlyLiked) {
        _likedTrackIds.remove(track.id);
      } else {
        _likedTrackIds.add(track.id);
      }
    });

    if (_token.isNotEmpty) {
      try {
        if (isCurrentlyLiked) {
          await ApiService.unlikeBhajan(_token, track.id);
        } else {
          await ApiService.likeBhajan(_token, track.id);
        }
      } catch (_) {}
    }
  }

  void _onMenuAction(String action, BhajanTrackItem track) async {
    switch (action) {
      case 'play':
        _playTrack(track, _tracks);
        break;
      case 'share':
        final shareText = '🙏 Listen to divine bhajan "${track.title}" by ${track.singer} on Bharat Pray app!\nhttps://bharatpray.com/bhajan/${track.id}';
        await Share.share(shareText, subject: track.title);
        break;
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
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  children: [
                    _buildBackButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            SpiritualTerms.get('downloads'),
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          Text(
                            '${_tracks.length} ${_tracks.length == 1 ? 'Track' : 'Tracks'} • Offline Playback',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF8C7B6E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_tracks.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _playAll,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                        label: Text(
                          SpiritualTerms.get('play_all'),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7700),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                  ],
                ),
              ),

              // Content List
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFFF7700),
                  backgroundColor: Colors.white,
                  onRefresh: _loadDownloads,
                  child: _buildContent(),
                ),
              ),

              // Mini Player
              const BhajanMiniPlayerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
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
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7700)),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFFF7700), size: 48),
              const SizedBox(height: 12),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDownloads,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700)),
                child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.download_for_offline_rounded, size: 44, color: Color(0xFFFF7700)),
              ),
              const SizedBox(height: 18),
              Text(
                SpiritualTerms.get('no_downloads_yet'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Download your favorite divine bhajans from the Bhajan Dashboard to listen offline anytime without internet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF8C7B6E),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        final isLiked = _likedTrackIds.contains(track.id);

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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onTap: () => _playTrack(track, _tracks),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildNetworkOrFallbackImage(track.imagePath, width: 52, height: 52),
            ),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E2A36),
              ),
            ),
            subtitle: Row(
              children: [
                const Icon(Icons.offline_pin_rounded, size: 14, color: Color(0xFF4CAF50)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${track.singer}${track.duration != null ? " • ${track.duration}" : ""}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isLiked ? const Color(0xFFE53935) : const Color(0xFF8C7B6E),
                    size: 22,
                  ),
                  onPressed: () => _toggleLike(track),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4A3A2C), size: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  onSelected: (action) => _onMenuAction(action, track),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'play',
                      child: Row(
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 20, color: Color(0xFFFF7700)),
                          const SizedBox(width: 10),
                          Text('Play Now', style: GoogleFonts.outfit(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          const Icon(Icons.share_rounded, size: 20, color: Color(0xFFFF7700)),
                          const SizedBox(width: 10),
                          Text('Share', style: GoogleFonts.outfit(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNetworkOrFallbackImage(String path, {required double width, required double height}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(width, height),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(width, height),
      );
    }
    return _fallbackImage(width, height);
  }

  Widget _fallbackImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF6E8DC),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 24),
      ),
    );
  }
}
