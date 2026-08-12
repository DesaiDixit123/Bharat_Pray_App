import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/bhajan_track_item.dart';
import '../../services/api_service.dart';

class BhajanNowPlayingScreen extends StatefulWidget {
  const BhajanNowPlayingScreen({
    super.key,
    required this.currentTrack,
    required this.queue,
  });

  final BhajanTrackItem currentTrack;
  final List<BhajanTrackItem> queue;

  @override
  State<BhajanNowPlayingScreen> createState() => _BhajanNowPlayingScreenState();
}

class _BhajanNowPlayingScreenState extends State<BhajanNowPlayingScreen> with SingleTickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final AnimationController _rotationController;

  PlayerState _playerState = PlayerState.stopped;
  bool _autoplay = true;
  bool _isLiked = false;
  bool _isDownloaded = false;
  bool _isFavourite = false;
  String _token = '';
  String _lyricsFromDetails = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  _NowPlayingView _activeView = _NowPlayingView.player;
  bool _showUpNext = false;

  Duration? _parseDuration(String? value) {
    if (value == null || !value.contains(':')) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) {
      return null;
    }

    return Duration(minutes: minutes, seconds: seconds);
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get _currentTrackIndex {
    return widget.queue.indexWhere(
      (track) => track.title.toLowerCase() == widget.currentTrack.title.toLowerCase(),
    );
  }

  BhajanTrackItem? get _previousTrack {
    final index = _currentTrackIndex;
    if (index <= 0 || index >= widget.queue.length) {
      return null;
    }
    return widget.queue[index - 1];
  }

  BhajanTrackItem? get _nextTrack {
    final index = _currentTrackIndex;
    if (index < 0 || index >= widget.queue.length - 1) {
      return null;
    }
    return widget.queue[index + 1];
  }

  void _openTrack(BhajanTrackItem track) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BhajanNowPlayingScreen(currentTrack: track, queue: widget.queue),
      ),
    );
  }

  List<BhajanTrackItem> get _upNext {
    return widget.queue
        .where((track) => track.title.toLowerCase() != widget.currentTrack.title.toLowerCase())
        .take(4)
        .toList();
  }

  String get _lyricsText {
    final detailsLyrics = _lyricsFromDetails.trim();
    if (detailsLyrics.isNotEmpty) {
      return detailsLyrics;
    }

    final apiLyrics = widget.currentTrack.lyrics?.trim();
    if (apiLyrics != null && apiLyrics.isNotEmpty) {
      return apiLyrics;
    }

    final prayerLyrics = widget.currentTrack.linkedPrayer?.lyrics.trim();
    if (prayerLyrics != null && prayerLyrics.isNotEmpty) {
      return prayerLyrics;
    }

    return 'Lyrics are not available for this bhajan yet.';
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.currentTrack.isLiked;
    _isDownloaded = widget.currentTrack.isDownloaded;
    _isFavourite = widget.currentTrack.isFavourite;

    _audioPlayer = AudioPlayer();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
      if (state == PlayerState.playing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_autoplay && _nextTrack != null) {
        _openTrack(_nextTrack!);
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _initAudio();
    _loadTokenAndSaveHistory();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    if (_token.isEmpty || widget.currentTrack.id.isEmpty) return;
    try {
      final streamUrl = await ApiService.fetchBhajanStreamUrl(_token, widget.currentTrack.id);

      if (streamUrl.startsWith('blob:')) {
        throw Exception('Invalid stream URL format received from server (blob). This is a backend configuration issue.');
      }

      await _audioPlayer.setSource(UrlSource(streamUrl));
      if (_autoplay) await _audioPlayer.resume();
    } catch (e) {
      _showMessage('Failed to load audio. ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _loadTokenAndSaveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';

    if (_token.isNotEmpty && widget.currentTrack.id.isNotEmpty) {
      _loadBhajanDetails();
    }

    if (_token.isNotEmpty && widget.currentTrack.id.isNotEmpty) {
      try {
        await ApiService.saveBhajanHistory(_token, widget.currentTrack.id, _position.inSeconds);
      } catch (_) {
        // Keep silent on passive history sync failures.
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        await _audioPlayer.seek(Duration.zero);
      } 
      // The source is set in _initAudio. If it's null, _initAudio failed and showed a message.
      // We just need to resume. If resume fails, it's an unrecoverable player state issue.
      if (_audioPlayer.source != null) {
        await _audioPlayer.resume();
      } else {
        // If source is null, it means _initAudio failed. Let's try again.
        await _initAudio();
      }
    }
  }

  Future<void> _loadBhajanDetails() async {
    try {
      final details = await ApiService.getBhajanDetails(_token, widget.currentTrack.id);
      final raw = details['bhajan'];
        final map = raw is Map<String, dynamic> ? raw : details;
      final lyrics = (map['lyrics'] ?? '').toString().trim();
      if (!mounted || lyrics.isEmpty) return;
      setState(() {
        _lyricsFromDetails = lyrics;
      });
    } catch (_) {
      // Keep silent on passive details fetch failures.
    }
  }

  Future<void> _toggleLike() async {
    if (_token.isEmpty || widget.currentTrack.id.isEmpty) return;
    try {
      if (_isLiked) {
        await ApiService.unlikeBhajan(_token, widget.currentTrack.id);
      } else {
        await ApiService.likeBhajan(_token, widget.currentTrack.id);
      }
      if (!mounted) return;
      setState(() => _isLiked = !_isLiked);
    } catch (e) {
      _showMessage('Unable to update like.');
    }
  }

  Future<void> _toggleFavourite() async {
    if (_token.isEmpty || widget.currentTrack.id.isEmpty) return;
    try {
      if (_isFavourite) {
        await ApiService.removeFavouriteBhajan(_token, widget.currentTrack.id);
      } else {
        await ApiService.addFavouriteBhajan(_token, widget.currentTrack.id);
      }
      if (!mounted) return;
      setState(() => _isFavourite = !_isFavourite);
    } catch (e) {
      _showMessage('Unable to update favourite.');
    }
  }

  Future<void> _downloadTrack() async {
    if (_token.isEmpty || widget.currentTrack.id.isEmpty) return;
    try {
      await ApiService.downloadBhajan(_token, widget.currentTrack.id);
      if (!mounted) return;
      setState(() => _isDownloaded = true);
      _showMessage('Added to downloads.');
    } catch (e) {
      _showMessage('Unable to download now.');
    }
  }

  Future<void> _shareTrack() async {
    if (widget.currentTrack.id.isEmpty) {
      _showMessage('Cannot share this track.');
      return;
    }

    // The API call can happen in the background without blocking the UI.
    if (_token.isNotEmpty) {
      ApiService.shareBhajan(_token, widget.currentTrack.id).catchError((_) {
        // Silently fail if the backend share recording fails.
        // The user's primary action is sharing, which should not be blocked.
      });
    }

    final box = context.findRenderObject() as RenderBox?;
    final subject = 'Listen to this beautiful bhajan: ${widget.currentTrack.title}';
    final text =
        'I am listening to "${widget.currentTrack.title}" by ${widget.currentTrack.singer} on BharatPray. '
        'Join me in this divine experience!\n\n'
        'Download the app: https://bharatpray.com/download'; // Example URL

    try {
      await Share.share(text, subject: subject, sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size);
    } catch (e) {
      _showMessage('Could not open share sheet.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFFFF7A00),
      ),
    );
  }

  double get _progress {
    return (_duration.inSeconds > 0) ? (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _buildHeader(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: _buildViewToggle(),
            ),
            Expanded(
              child: _activeView == _NowPlayingView.player ? _buildPlayerView() : _buildLyricsView(),
            ),
            if (_activeView == _NowPlayingView.lyrics) _buildLyricsMiniPlayer(),
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
            'Now Playing',
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

  Widget _buildViewToggle() {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAD8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D9C1)),
      ),
      child: Row(
        children: [
          _buildToggleButton(label: 'Player', view: _NowPlayingView.player),
          _buildToggleButton(label: 'Lyrics', view: _NowPlayingView.lyrics),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required _NowPlayingView view,
  }) {
    final isSelected = _activeView == view;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _activeView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF7B0F) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF8E5A2A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final coverSize = (width * 0.76).clamp(250.0, 360.0);
        final horizontalPadding = width < 360 ? 16.0 : 24.0;
        final bottomSafePadding = MediaQuery.of(context).padding.bottom;

        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            if (!_showUpNext && notification.metrics.pixels > 90) {
              setState(() {
                _showUpNext = true;
              });
            }
            return false;
          },
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 30 + bottomSafePadding),
            children: [
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: RotationTransition(
              turns: _rotationController,
              child: Container(
                width: coverSize,
                height: coverSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7700).withValues(alpha: 0.09),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildTrackImage(
                    widget.currentTrack.imagePath,
                    fallbackIconSize: 56,
                    fallbackColor: const Color(0xFFE2BC8B),
                  ),
                ),
              ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.currentTrack.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.currentTrack.singer,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.58),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionItem(
                  _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  _isLiked ? 'Liked' : 'Like',
                  onTap: _toggleLike,
                ),
                _actionItem(
                  _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                  _isDownloaded ? 'Downloaded' : 'Download',
                  onTap: _downloadTrack,
                ),
                _actionItem(
                  _isFavourite ? Icons.playlist_add_check_rounded : Icons.playlist_add_rounded,
                  _isFavourite ? 'Favourited' : 'Favourite',
                  onTap: _toggleFavourite,
                ),
                _actionItem(Icons.share_rounded, 'Share', onTap: _shareTrack),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFF7B0F),
                inactiveTrackColor: const Color(0xFFE6D4C1),
                thumbColor: const Color(0xFFFF7B0F),
                trackHeight: 3.2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _progress,
                min: 0,
                max: 1,
                onChanged: (value) async {
                  final newPosition = Duration(seconds: (value * _duration.inSeconds).round());
                  await _audioPlayer.seek(newPosition);
                  setState(() => _position = newPosition);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(_position),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.62),
                    ),
                  ),
                  Text(
                    _formatTime(_duration),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Icon(Icons.shuffle_rounded, size: 30, color: Color(0xFF2E2A36)),
                IconButton(
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    size: 42,
                    color: _previousTrack == null
                        ? const Color(0xFF2E2A36).withValues(alpha: 0.28)
                        : const Color(0xFF2E2A36),
                  ),
                  onPressed: _previousTrack == null ? null : () => _openTrack(_previousTrack!),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(44),
                  onTap: _togglePlayback,
                  child: Container(
                    height: 84,
                    width: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF7B0F),
                    ),
                    child: Icon(
                      _playerState == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next_rounded,
                    size: 42,
                    color: _nextTrack == null
                        ? const Color(0xFF2E2A36).withValues(alpha: 0.28)
                        : const Color(0xFF2E2A36),
                  ),
                  onPressed: _nextTrack == null ? null : () => _openTrack(_nextTrack!),
                ),
                const Icon(Icons.repeat_rounded, size: 30, color: Color(0xFF2E2A36)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Autoplay',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                  ),
                ),
                Switch(
                  value: _autoplay,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFFFF7B0F),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFD8C4AF),
                  onChanged: (value) => setState(() => _autoplay = value),
                ),
              ],
            ),
              if (_showUpNext) ...[
                const SizedBox(height: 38),
                Row(
                  children: [
                    Text(
                      'Up Next',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Swipe up to view',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._upNext.map(_buildUpNextItem),
                if (_upNext.isEmpty)
                  Text(
                    'No upcoming tracks.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                    ),
                  ),
              ] else ...[
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'Scroll to show Up Next',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.42),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLyricsView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      children: [
        const SizedBox(height: 8),
        Text(
          'Govind Bolo Hari Gopal Bolo' == widget.currentTrack.title
              ? '༄༅།།'
              : 'ॐ',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            color: const Color(0xFFD8B892),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.currentTrack.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.currentTrack.singer,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFDDC9B3), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'ॐ',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: const Color(0xFFB48B61),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFDDC9B3), thickness: 1)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          _lyricsText,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 15,
            height: 1.8,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2A36),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFF6EE).withValues(alpha: 0),
                const Color(0xFFF4DDBF).withValues(alpha: 0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          alignment: Alignment.bottomCenter,
          child: Icon(
            Icons.temple_hindu_rounded,
            color: const Color(0xFFD4B28C).withValues(alpha: 0.6),
            size: 48,
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsMiniPlayer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3E4D6)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 46,
              height: 46,
              child: _buildTrackImage(widget.currentTrack.imagePath),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentTrack.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                Text(
                  widget.currentTrack.singer,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _togglePlayback,
            child: Container(
              height: 34,
              width: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7B0F),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playerState == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.playlist_add_rounded, color: Color(0xFFBD8A57), size: 22),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          children: [
            Icon(icon, size: 23, color: const Color(0xFF8E7963)),
            const SizedBox(height: 4),
            SizedBox(
              width: 74,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8E7963),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpNextItem(BhajanTrackItem track) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3E4D6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 46,
            height: 46,
            child: _buildTrackImage(track.imagePath),
          ),
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
            color: const Color(0xFF2E2A36).withValues(alpha: 0.56),
          ),
        ),
        trailing: const Icon(Icons.queue_music_rounded, color: Color(0xFFAF957C)),
        onTap: () => _openTrack(track),
      ),
    );
  }

  Widget _buildTrackImage(
    String imagePath, {
    double fallbackIconSize = 24,
    Color fallbackColor = const Color(0xFFFFF1E5),
  }) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => _fallbackTrackImage(fallbackIconSize, fallbackColor),
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => _fallbackTrackImage(fallbackIconSize, fallbackColor),
      );
    }

    return _fallbackTrackImage(fallbackIconSize, fallbackColor);
  }

  Widget _fallbackTrackImage(double iconSize, Color bgColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note_rounded,
        color: const Color(0xFFB56E28),
        size: iconSize,
      ),
    );
  }

}

enum _NowPlayingView {
  player,
  lyrics,
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
