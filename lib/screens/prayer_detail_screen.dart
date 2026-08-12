import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/prayer.dart';

class PrayerDetailScreen extends StatefulWidget {
  final Prayer prayer;

  const PrayerDetailScreen({super.key, required this.prayer});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final AnimationController _rotationController;

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _showTranslation = false;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Animation controller for the rotating disc
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    // Set up listeners for the player
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.playing) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Auto-load audio source
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSource(UrlSource(widget.prayer.audioUrl));
    } catch (e) {
      debugPrint("Error initializing audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _togglePlayback() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.prayer.audioUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2E2A36);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFEAD2), // Warm soft orange cream
              Color(0xFFFFE8D6), // Light cream background matched to mockup
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      widget.prayer.category,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF7700),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                    // Font Size Controller
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF2E2A36)),
                          onPressed: () {
                            setState(() {
                              if (_fontSize > 14) _fontSize -= 2;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2E2A36)),
                          onPressed: () {
                            setState(() {
                              if (_fontSize < 30) _fontSize += 2;
                            });
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 15),
                        // Spinning Prayer Disc
                        Center(
                          child: RotationTransition(
                            turns: _rotationController,
                            child: Container(
                              height: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF7700).withValues(alpha: 0.3),
                                  width: 3.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF7700).withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  widget.prayer.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) { // Corrected from withValues to withOpacity
                            return Container(
                              color: Colors.orange.withValues(alpha: 0.2),
                                      child: const Center(
                                        child: Text(
                                          '🕉️',
                                          style: TextStyle(fontSize: 80),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Title
                        Text(
                          widget.prayer.title,
                          style: GoogleFonts.outfit(
                            fontSize: 26, 
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Meditative Devotional Audio', style: GoogleFonts.outfit(
                            fontSize: 14, // Corrected from withValues to withOpacity
                            color: themeColor.withValues(alpha: 0.5),
                          ),
                        ),

                        // Music Visualizer
                        const SizedBox(height: 15),
                        _buildVisualizer(),

                        const SizedBox(height: 15),

                        // Slider & Times
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFFF7700),
                            inactiveTrackColor: const Color(0xFFEFE6DB),
                            thumbColor: const Color(0xFFFF7700),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds > 0
                                ? _duration.inSeconds.toDouble()
                                : 100.0,
                            onChanged: (value) async {
                              final position = Duration(seconds: value.toInt());
                              await _audioPlayer.seek(position);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position),
                                style: GoogleFonts.outfit(
                                    color: themeColor.withValues(alpha: 0.6), fontSize: 12)),
                              Text(_formatDuration(_duration),
                                style: GoogleFonts.outfit(
                                    color: themeColor.withValues(alpha: 0.6), fontSize: 12)),
                            ],
                          ),
                        ),

                        // Audio Controls
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.replay_10_rounded, color: Color(0xFF2E2A36)),
                              onPressed: () async {
                                final newPos = _position - const Duration(seconds: 10);
                                await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                              },
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: _togglePlayback,
                              child: Container(
                                height: 75,
                                width: 75,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF9933),
                                      Color(0xFFFF5500),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  _playerState == PlayerState.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.forward_10_rounded, color: Color(0xFF2E2A36)),
                              onPressed: () async {
                                final newPos = _position + const Duration(seconds: 10);
                                await _audioPlayer.seek(newPos > _duration ? _duration : newPos);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Toggle Buttons (Lyrics vs Translation)
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showTranslation = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: !_showTranslation
                                            ? const Color(0xFFFF7700)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Prayer Text (मंत्र)',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: !_showTranslation ? themeColor : themeColor.withValues(alpha: 0.4),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showTranslation = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _showTranslation
                                            ? const Color(0xFFFF7700)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Meaning (अर्थ)',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: _showTranslation ? themeColor : themeColor.withValues(alpha: 0.4),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Text Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFEFE6DB),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AnimatedCrossFade(
                            firstChild: SelectableText(
                              widget.prayer.lyrics,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.yatraOne(
                                fontSize: _fontSize,
                                color: themeColor,
                                height: 1.8,
                              ),
                            ),
                            secondChild: SelectableText(
                              widget.prayer.translation,
                              textAlign: TextAlign.left,
                              style: GoogleFonts.outfit(
                                fontSize: _fontSize - 2,
                                height: 1.6,
                                color: themeColor.withValues(alpha: 0.8),
                              ),
                            ),
                            crossFadeState: _showTranslation
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizer() {
    final isPlaying = _playerState == PlayerState.playing;
    return SizedBox(
      height: 35,
      width: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(15, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: isPlaying ? 300 + (index * 50) % 300 : 800),
            width: 4,
            height: isPlaying ? (10 + (index * 7) % 25).toDouble() : 4.0,
            decoration: BoxDecoration( 
              color: const Color(0xFFFF7700).withValues(alpha: isPlaying ? 0.8 : 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
