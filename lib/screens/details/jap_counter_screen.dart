import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'upload_god_photo_screen.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

// ─────────────────────────────────────────────
// Data model for a single Jap entry
// ─────────────────────────────────────────────
class JapEntry {
  final String id;
  final String name;
  final String mantra;
  final String imagePath;
  final String? detailImagePath;
  final String? audioUrl;
  final int target;
  int progress; // how many japs done so far
  final String? particleShape;
  final String? blessingTitle;
  final String? blessingSubtitle;

  JapEntry({
    required this.id,
    required this.name,
    required this.mantra,
    required this.imagePath,
    this.detailImagePath,
    this.audioUrl,
    this.target = 108,
    this.progress = 0,
    this.particleShape,
    this.blessingTitle,
    this.blessingSubtitle,
  });

  static String _sanitizeUrl(String? url) {
    return ApiService.resolveImageUrl(url);
  }

  factory JapEntry.fromJson(Map<String, dynamic> json) {
    final rawThumb = json['thumbnail'] ?? '';
    final rawDarshan = json['darshanImage'] ?? rawThumb;
    final rawAudio = json['shlokAudio'] ?? '';

    return JapEntry(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      mantra: json['shlokText'] ?? '',
      imagePath: _sanitizeUrl(rawThumb),
      detailImagePath: _sanitizeUrl(rawDarshan),
      audioUrl: _sanitizeUrl(rawAudio),
      target: json['targetCount'] ?? 108,
      progress: json['progress'] ?? 0,
      particleShape: json['particleShape'],
      blessingTitle: json['blessingTitle'],
      blessingSubtitle: json['blessingSubtitle'],
    );
  }
}

// ─────────────────────────────────────────────
// Main List Screen
// ─────────────────────────────────────────────
class JapCounterScreen extends StatefulWidget {
  final bool isTab;
  const JapCounterScreen({super.key, this.isTab = false});

  @override
  State<JapCounterScreen> createState() => _JapCounterScreenState();
}

class _JapCounterScreenState extends State<JapCounterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  bool _isLoading = true;
  String _token = '';
  List<JapEntry> _allJaps = [];

  @override
  void initState() {
    super.initState();
    _fetchJaps();
  }

  Future<void> _fetchJaps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token') ?? '';
      
      if (_token.isNotEmpty) {
        final data = await ApiService.getJapList(_token);
        if (mounted) {
          setState(() {
            _allJaps = data.map((e) => JapEntry.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching japs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<JapEntry> get _filteredJaps {
    if (_searchQuery.isEmpty) return _allJaps;
    final q = _searchQuery.toLowerCase();
    return _allJaps
        .where((j) =>
            j.name.toLowerCase().contains(q) ||
            j.mantra.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openJapDetail(JapEntry entry) async {
    final updatedProgress = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => JapDetailScreen(entry: entry),
      ),
    );
    if (updatedProgress != null) {
      setState(() {
        entry.progress = updatedProgress;
      });
      
      // Sync to backend if it's a valid remote Jap (valid MongoDB ObjectId length)
      if (_token.isNotEmpty && entry.id.isNotEmpty && entry.id.length == 24) {
        try {
          await ApiService.syncJapProgress(_token, entry.id, updatedProgress);
        } catch (e) {
          debugPrint('Error syncing progress: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredJaps;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0E6),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage:
                        const AssetImage('assets/images/image_3.png'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jai Shree Ram 🙏',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF2E2A36))),
                        Text('Good Morning, Shiv 🌟',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF2E2A36)
                                    .withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  _iconBtn(Icons.mail_outline_rounded),
                  const SizedBox(width: 8),
                  _iconBtn(Icons.notifications_none_rounded, hasDot: true),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Search Bar & Go Back Row ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Go back button (width: 40, height: 40, border: 1px solid #C8A882, radius: 124)
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                      ),
                      child: Center(
                        child: SvgPicture.string(
                          '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''',
                          width: 15,
                          height: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Search bar (width: 297, height: 43, border: 1px solid #C8A882, radius: 89)
                  Expanded(
                    child: Container(
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(89),
                        border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFFC8A882),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search gods, temples, bhajans...',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFFC8A882).withValues(alpha: 0.6),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.string(
                              '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M11 19C15.4183 19 19 15.4183 19 11C19 6.58172 15.4183 3 11 3C6.58172 3 3 6.58172 3 11C3 15.4183 6.58172 19 11 19Z" stroke="#C8A882" stroke-width="1.33333"/>
<path d="M21 20.9999L16.65 16.6499" stroke="#C8A882" stroke-width="1.33333"/>
</svg>''',
                              width: 18,
                              height: 18,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      color: Color(0xFFC8A882), size: 18),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Add Photo Button ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadGodPhotoScreen(),
                    ),
                  );
                  if (result == null) return;
                  if (!context.mounted) return;
                  
                  if (result is CustomJapDetails) {
                    setState(() {
                      _allJaps.insert(
                        0,
                        JapEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: result.name,
                          mantra: result.mantra,
                          imagePath: result.imagePath,
                          target: result.target,
                          progress: 0,
                        ),
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFFF7700),
                        content: Text(
                          'Added "${result.name}" successfully!',
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
                    ),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      Text('Add Photo',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              height: 1.0)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Card List ────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF7700),
                onRefresh: _fetchJaps,
                child: _isLoading 
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF7700)),
                      )
                    : filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 300,
                            child: Center(
                              child: Text('No results found',
                                  style: GoogleFonts.outfit(
                                      color: const Color(0xFF2E2A36)
                                          .withValues(alpha: 0.4),
                                      fontSize: 15)),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            widget.isTab
                                ? 140 +
                                    MediaQuery.of(context).padding.bottom
                                : 20),
                        itemCount: filtered.length,
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final jap = filtered[index];
                          return _JapCard(
                            entry: jap,
                            onTap: () => _openJapDetail(jap),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {bool hasDot = false}) {
    return Stack(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEFE6DB)),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2E2A36)),
        ),
        if (hasDot)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B42),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Individual Jap Card  (width:353, height:200, radius:32)
// ─────────────────────────────────────────────
class _JapCard extends StatelessWidget {
  final JapEntry entry;
  final VoidCallback onTap;

  const _JapCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double fraction = entry.progress / entry.target;
    final bool inProgress = entry.progress > 0 && entry.progress < entry.target;
    final bool completed = entry.progress >= entry.target;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 353,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              entry.imagePath.startsWith('http')
                  ? Image.network(entry.imagePath, fit: BoxFit.cover)
                  : entry.imagePath.startsWith('assets/')
                      ? Image.asset(entry.imagePath, fit: BoxFit.cover)
                      : Image.file(File(entry.imagePath), fit: BoxFit.cover),

              // Gradient overlay (transparent top → black bottom)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),

                    // God name
                    Text(
                      entry.name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Mantra text
                    Text(
                      entry.mantra,
                      style: GoogleFonts.notoSans(
                        color: const Color(0xFFFF9933),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Progress bar row
                    Row(
                      children: [
                        // Progress bar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Count text
                              Text(
                                '${entry.progress.toString().padLeft(2, '0')}/${entry.target}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    // Background (white)
                                    Container(
                                      height: 6,
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                    // Foreground (orange fill)
                                    FractionallySizedBox(
                                      widthFactor: fraction.clamp(0.0, 1.0),
                                      child: Container(
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFFF9933),
                                              Color(0xFFFF6600),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Action Button
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              completed
                                  ? 'Completed'
                                  : inProgress
                                      ? 'Continue'
                                      : 'Start Jap',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail / Counting Screen – Image Reveal
// ─────────────────────────────────────────────
class JapDetailScreen extends StatefulWidget {
  final JapEntry entry;
  const JapDetailScreen({super.key, required this.entry});

  @override
  State<JapDetailScreen> createState() => _JapDetailScreenState();
}

class _JapDetailScreenState extends State<JapDetailScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────
  late int _count;   // japs done in current mala
  late int _target;
  int _completedMalas = 0;



  late List<int> _shuffledIndices;   // random reveal order (seeded per entry)
  late List<Offset> _jitteredPoints; // organic points corresponding to grid cells

  late final AudioPlayer _audioPlayer;

  // Single controller drives the "currently revealing" tile expansion
  late final AnimationController _revealController;
  late final AnimationController _completionController;
  int? _revealingTile;               // tile index being animated right now

  bool _canTap = true;
  bool _isAudioPlaying = false;
  bool _isRevealAnimating = false;

  void _tryUnlockTap() {
    if (!_isAudioPlaying && !_isRevealAnimating && _count < _target) {
      if (mounted) {
        setState(() {
          _canTap = true;
        });
      }
    }
  }

  bool _showContinueButton = false;
  double _audioProgress = 0.0;
  Duration _audioDuration = Duration.zero;
  double _buttonScale = 1.0;

  ImageProvider? _imageProvider;

  // Ambient loop controller and particles
  late final AnimationController _ambientController;
  final List<EmberParticle> _embers = [];
  final List<SmokeParticle> _smokeParticles = [];
  final List<GlowRing> _glowRings = [];
  final List<PetalParticle> _petals = [];
  final List<TapSparkParticle> _tapSparks = [];
  final List<SpiralSparkParticle> _spiralSparks = [];
  final List<FloatingOmText> _floatingOms = [];

  Offset? _lastRevealPoint;
  Offset? _currentAgarbattiPos;
  double _smokeEmitTimer = 0.0;

  // Predict the next reveal point based on the current count
  Offset? get _nextRevealPoint {
    if (_count >= _target) return null;
    final nextRevealPos = _count % _target;
    final tileIdx = _shuffledIndices[nextRevealPos];
    return _jitteredPoints[tileIdx];
  }

  // ── Helpers ────────────────────────────────
  int get _totalProgress => (_completedMalas * _target) + _count;

  // Build a fresh shuffled order seeded by entry name + mala number
  List<int> _buildShuffled(int malaSeed) {
    final rng = math.Random(widget.entry.name.hashCode ^ malaSeed);
    return List.generate(_target, (i) => i)..shuffle(rng);
  }

  // Generate N jittered points (N = _target) so they cover the 353x650 area evenly but randomly
  List<Offset> _generateJitteredPoints(int malaSeed) {
    final rng = math.Random(widget.entry.name.hashCode ^ (malaSeed + 123));
    List<Offset> points = [];

    final int cols = math.max(1, math.sqrt(_target / 1.875).round());
    final int rows = (_target / cols).ceil();

    final double cellWidth = 353.0 / cols;
    final double cellHeight = 650.0 / rows;

    for (int i = 0; i < _target; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final cellCenterX = col * cellWidth + (cellWidth / 2.0);
      final cellCenterY = row * cellHeight + (cellHeight / 2.0);

      final dx = (rng.nextDouble() * (cellWidth * 0.4)) - (cellWidth * 0.2);
      final dy = (rng.nextDouble() * (cellHeight * 0.4)) - (cellHeight * 0.2);

      points.add(Offset(
        (cellCenterX + dx).clamp(10.0, 343.0),
        (cellCenterY + dy).clamp(10.0, 640.0),
      ));
    }
    return points;
  }

  @override
  void initState() {
    super.initState();

    _target = widget.entry.target;
    final totalProgress = widget.entry.progress;
    _completedMalas = totalProgress ~/ _target;
    _count = totalProgress % _target;

    _shuffledIndices = _buildShuffled(_completedMalas);
    _jitteredPoints = _generateJitteredPoints(_completedMalas);

    _audioPlayer = AudioPlayer();
    
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          if (_audioDuration.inMilliseconds > 0) {
            _audioProgress = p.inMilliseconds / _audioDuration.inMilliseconds;
          }
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
          _audioProgress = 0.0;
        });
        _tryUnlockTap();
      }
    });

    // Continuous ambient loop for floating embers, halo rotation, flower petals
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        _updateParticlesNoSetState();
      });
    _ambientController.repeat();

    _initEmbers();

    // 500 ms controller to scale the mask erase radius on tap
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 1200 ms controller for smooth veil dissolve on completion
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (_completedMalas > 0) {
      _completionController.value = 1.0;
      _showContinueButton = true;
    }

    // Restore last reveal point if we are continuing a partially completed mala
    if (_count > 0 && _count < _target) {
      final lastRevealPos = (_count - 1) % _target;
      final tileIdx = _shuffledIndices[lastRevealPos];
      _lastRevealPoint = _jitteredPoints[tileIdx];
    }
  }

  void _initEmbers() {
    final rng = math.Random();
    _embers.clear();
    for (int i = 0; i < 25; i++) {
      _embers.add(EmberParticle(
        x: rng.nextDouble() * 393,
        y: rng.nextDouble() * 1010,
        vx: (rng.nextDouble() * 0.5) - 0.25,
        vy: rng.nextDouble() * 0.6 + 0.4,
        size: rng.nextDouble() * 2.8 + 1.2,
        alpha: rng.nextDouble() * 0.45 + 0.15,
        speedMultiplier: rng.nextDouble() * 0.5 + 0.8,
      ));
    }
  }

  Color _getDeityPetalColor(math.Random rng) {
    final nameLower = widget.entry.name.toLowerCase();
    if (nameLower.contains('shiva') || nameLower.contains('mahadev')) {
      return rng.nextBool()
          ? (rng.nextBool() ? const Color(0xFFE8F4FC) : const Color(0xFFC5D8E0))
          : const Color(0xFF81C784); // Ash silver & bilva leaf green
    } else if (nameLower.contains('krishna') || nameLower.contains('radha')) {
      return rng.nextBool()
          ? (rng.nextBool() ? const Color(0xFF0D4F8B) : const Color(0xFF50C878))
          : const Color(0xFFFF80AB); // Peacock blue & lotus pink
    } else if (nameLower.contains('ganesh') || nameLower.contains('ganpati')) {
      return rng.nextBool() ? const Color(0xFFFF6B35) : const Color(0xFFFFB300); // Marigold
    } else if (nameLower.contains('hanuman')) {
      return rng.nextBool() ? const Color(0xFFCC2200) : const Color(0xFFFF6600); // Sindoor & saffron
    } else if (nameLower.contains('durga') || nameLower.contains('kali')) {
      return rng.nextBool() ? const Color(0xFF990000) : const Color(0xFFFF1744); // Kumkum red
    } else if (nameLower.contains('lakshmi')) {
      return rng.nextBool() ? const Color(0xFFFF80AB) : const Color(0xFFFFE082); // Pink lotus & soft gold
    } else if (nameLower.contains('vishnu')) {
      return rng.nextBool() ? const Color(0xFF0277BD) : const Color(0xFFFFD700); // Ocean blue & gold
    }
    return rng.nextBool()
        ? (rng.nextBool() ? const Color(0xFFE22D5A) : const Color(0xFFC2185B))
        : (rng.nextBool() ? const Color(0xFFFFB300) : const Color(0xFFFF8F00));
  }

  void _initPetals() {
    final rng = math.Random();
    final theme = TempleThemeConfig.fromEntry(widget.entry);
    _petals.clear();
    for (int i = 0; i < 30; i++) {
      _petals.add(PetalParticle(
        x: rng.nextDouble() * 393,
        y: rng.nextDouble() * 1010 - 1010,
        vy: rng.nextDouble() * 1.2 + 0.9,
        angle: rng.nextDouble() * 2 * math.pi,
        rotationSpeed: (rng.nextDouble() * 0.035) - 0.0175,
        size: rng.nextDouble() * 8.0 + 8.0,
        windFreq: rng.nextDouble() * 1.3 + 0.7,
        windAmp: rng.nextDouble() * 1.2 + 0.6,
        color: _getDeityPetalColor(rng),
        shape: theme.particleShape,
      ));
    }
  }

  void _updateParticlesNoSetState() {
    final bool isCompleted = _completedMalas > 0 || _count >= _target;

    // Update floating embers (across 393 x 1010 screen space)
    for (final ember in _embers) {
      ember.update(393, 1010);
    }

    // Update glow rings (inside card space)
    _glowRings.removeWhere((ring) => !ring.update());
    _tapSparks.removeWhere((spark) => !spark.update());
    _spiralSparks.removeWhere((spark) => !spark.update());
    _floatingOms.removeWhere((om) => !om.update());

    // Smoothly hover Agarbatti to the NEXT reveal point to predict it
    final targetPos = _nextRevealPoint ?? _lastRevealPoint;
    if (targetPos != null) {
      if (_currentAgarbattiPos == null) {
        _currentAgarbattiPos = targetPos;
      } else {
        _currentAgarbattiPos = Offset.lerp(_currentAgarbattiPos, targetPos, 0.06); // medium floating speed
      }
    }

    // Emit & update rising incense smoke (inside card space)
    if (_currentAgarbattiPos != null && !isCompleted) {
      _smokeEmitTimer += 0.016;
      if (_smokeEmitTimer >= 0.25) { // emit very slowly (every 250ms) to minimize bubbles
        _smokeEmitTimer = 0.0;
        final rng = math.Random();
        _smokeParticles.add(SmokeParticle(
          x: _currentAgarbattiPos!.dx,
          y: _currentAgarbattiPos!.dy,
          vx: (rng.nextDouble() * 0.4) - 0.2, // tight sway
          vy: rng.nextDouble() * 0.6 + 0.6,
          size: rng.nextDouble() * 2.0 + 2.0, // tiny minimal bubbles
          alpha: rng.nextDouble() * 0.10 + 0.08, // barely visible smoke

          maxLife: rng.nextDouble() * 1.5 + 1.0, // dies faster
          growthRate: rng.nextDouble() * 0.4 + 0.2, // grows slower
        ));

        // Emit intense glowing crackle embers from the burning tip like a fountain!
        if (rng.nextDouble() > 0.15) { // 85% chance to emit an ember!
          for (int i = 0; i < (rng.nextBool() ? 2 : 1); i++) { // Sometimes emit 2!
            _tapSparks.add(TapSparkParticle(
              position: _currentAgarbattiPos!,
              vx: (rng.nextDouble() * 2.5) - 1.25, // scatter sideways violently
              vy: rng.nextDouble() * 3.5 + 1.5, // shoot upwards!
              size: rng.nextDouble() * 2.0 + 1.0,
              color: rng.nextBool() ? const Color(0xFFFF3300) : const Color(0xFFFFCC00),
              maxLife: rng.nextDouble() * 0.6 + 0.3,
            ));
          }
        }
      }
    }
    _smokeParticles.removeWhere((smoke) => !smoke.update());

    // Update falling flower petals when completed
    if (isCompleted) {
      if (_petals.isEmpty) {
        _initPetals();
      }
      for (final petal in _petals) {
        petal.update(393, 1010);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imageProvider == null) {
      final path = widget.entry.detailImagePath ?? widget.entry.imagePath;
      if (path.startsWith('http')) {
        _imageProvider = NetworkImage(path);
      } else if (path.startsWith('assets/')) {
        _imageProvider = AssetImage(path);
      } else {
        _imageProvider = FileImage(File(path));
      }
      precacheImage(_imageProvider!, context);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _revealController.dispose();
    _completionController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  // ── Tap handler ────────────────────────────
  void _increment() async {
    if (!_canTap) return; // Strict lock: disallow tap while audio or reveal animation is active
    if (_completedMalas > 0 || _count >= _target) {
      _startNextMala();
      return;
    }
    // Devotion Milestones (50% & 90%)
    final int halfTarget = _target ~/ 2;
    final int nearCompletion = (_target * 0.9).round();
    if ((_count + 1) == halfTarget) {
      HapticFeedback.mediumImpact();
    } else if ((_count + 1) == nearCompletion) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }

    // Pick the next point in the shuffled order
    final revealPos = _count % _target;
    final tileIdx = _shuffledIndices[revealPos];
    final revealPt = _jitteredPoints[tileIdx];

    setState(() {
      _canTap = false;
      _isRevealAnimating = true;
      _isAudioPlaying = true;
      _buttonScale = 0.82;
      _revealingTile = tileIdx;
      _lastRevealPoint = revealPt;
      _count++;
      
      // Only load celebratory animations once the full image gets revealed
      if (_count >= _target) {
        // 1. Radial Sparkle Explosion (12 divine gold/amber/white sparks)
        final rng = math.Random();
        for (int i = 0; i < 12; i++) {
          final angle = (i / 12.0) * 2 * math.pi + (rng.nextDouble() * 0.4 - 0.2);
          final speed = rng.nextDouble() * 5.0 + 3.5;
          final sparkColors = [
            const Color(0xFFFFD700), // Pure Gold
            const Color(0xFFFF9100), // Amber
            const Color(0xFFFFFFFF), // Divine White
            const Color(0xFFFF5500), // Saffron
          ];
          _tapSparks.add(TapSparkParticle(
            position: revealPt,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed,
            maxLife: rng.nextDouble() * 0.35 + 0.35,
            size: rng.nextDouble() * 4.0 + 3.0,
            color: sparkColors[i % sparkColors.length],
          ));
        }

        // 1b. Spiral Galaxy Swirl Sparks (8 double-helix spiral sparks)
        for (int i = 0; i < 8; i++) {
          final startAngle = (i / 8.0) * 2 * math.pi;
          _spiralSparks.add(SpiralSparkParticle(
            center: revealPt,
            angle: startAngle,
            speed: (i % 2 == 0 ? 1.0 : -1.0) * (rng.nextDouble() * 0.18 + 0.12),
            radialSpeed: rng.nextDouble() * 2.8 + 2.2,
            maxLife: rng.nextDouble() * 0.35 + 0.40,
            size: rng.nextDouble() * 3.5 + 2.5,
            color: i % 2 == 0 ? const Color(0xFFFFD700) : const Color(0xFFFF8A00),
          ));
        }

        // 1c. Instant Fragrant Incense Smoke Puff (4 expanding golden-pearl smoke clouds)
        for (int i = 0; i < 4; i++) {
          _smokeParticles.add(SmokeParticle(
            x: revealPt.dx,
            y: revealPt.dy,
            vx: (rng.nextDouble() * 0.8) - 0.4,
            vy: rng.nextDouble() * 0.9 + 0.8,
            size: rng.nextDouble() * 6.0 + 9.0,
            alpha: rng.nextDouble() * 0.35 + 0.30,
            maxLife: rng.nextDouble() * 1.2 + 1.0,
            growthRate: rng.nextDouble() * 0.4 + 0.3,
          ));
        }

        // 2. Floating Sacred Chant Symbol Text
        final omTexts = ['ॐ', 'राम', 'जय', 'ॐ', 'हरि', 'नमः'];
        _floatingOms.add(FloatingOmText(
          position: revealPt,
          maxLife: 0.65,
          text: omTexts[(_count - 1) % omTexts.length],
        ));

        // 3. Concentric Glow Rings (Inner Gold + Outer Saffron Shockwave)
        _glowRings.add(GlowRing(
          position: revealPt,
          maxRadius: 180.0,
          maxLife: 1.1,
          color: const Color(0xFFFFD700),
        ));
        _glowRings.add(GlowRing(
          position: revealPt,
          maxRadius: 220.0,
          maxLife: 1.3,
          color: const Color(0xFFFF6D00),
        ));
      }
    });

    // Button tactile spring rebound (0.82 -> 1.12 -> 1.0)
    Future.delayed(const Duration(milliseconds: 70), () {
      if (mounted) setState(() => _buttonScale = 1.12);
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _buttonScale = 1.0);
    });

    // Run the mask erase circle expansion
    _revealController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _revealingTile = null;
        _isRevealAnimating = false;
      });
      _tryUnlockTap();
    });

    // Audio Playback with Strict Lock until Completion + 5s Safety Fallback
    if (widget.entry.audioUrl != null && widget.entry.audioUrl!.isNotEmpty) {
      try {
        await _audioPlayer.stop(); // Stop before play to ensure it responds
        if (widget.entry.audioUrl!.startsWith('http')) {
          await _audioPlayer.play(UrlSource(widget.entry.audioUrl!));
        } else if (widget.entry.audioUrl!.startsWith('assets/')) {
          await _audioPlayer.play(AssetSource(widget.entry.audioUrl!.replaceFirst('assets/', '')));
        } else {
          await _audioPlayer.play(DeviceFileSource(widget.entry.audioUrl!));
        }

        // Safety Fallback: If audio stream takes > 5s or gets interrupted, auto-unlock button
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isAudioPlaying) {
            setState(() {
              _isAudioPlaying = false;
              _audioProgress = 0.0;
            });
            _tryUnlockTap();
          }
        });
      } catch (e) {
        debugPrint("Error playing audio: $e");
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() {
            _isAudioPlaying = false;
            _audioProgress = 0.0;
          });
          _tryUnlockTap();
        }
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
          _audioProgress = 0.0;
        });
        _tryUnlockTap();
      }
    }

    // Mala complete? Final Darshan Ceremony (700ms silence pause -> 1.2s smooth dissolve -> 6s absorption pause -> Continue button reveal)
    if (_count >= _target) {
      await Future.delayed(const Duration(milliseconds: 700));
      _completionController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 6000));
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _showContinueButton = true;
        });
      }
    }
  }

  void _startNextMala() {
    HapticFeedback.mediumImpact();
    // Return back to the list screen, passing the fully completed mala progress
    Navigator.pop(context, (_completedMalas + 1) * _target);
  }

  void _resetCurrentMala() {
    HapticFeedback.mediumImpact();
    setState(() {
      _count = 0;
      _completedMalas = 0;
      _shuffledIndices = _buildShuffled(0);
      _jitteredPoints = _generateJitteredPoints(0);
      _revealingTile = null;
      _petals.clear();
      _glowRings.clear();
      _smokeParticles.clear();
      _lastRevealPoint = null;
      _smokeEmitTimer = 0.0;
      _canTap = true;
      _showContinueButton = false;
    });
    _completionController.reset();
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E1705), Color(0xFF1E0E02)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported_outlined,
                color: Color(0xFFFF9933), size: 48),
            const SizedBox(height: 12),
            Text(
              'No Photo Available',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isCompleted = _completedMalas > 0 || _count >= _target;
    final int revealedCount = isCompleted ? _target : _count;
    final int revealPct = (_count / _target * 100).toInt();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _totalProgress);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Dark gradient bg ──────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D0600), Color(0xFF1A0A00)],
                  ),
                ),
              ),
            ),

            // ── Absolute Positioned Scaled Content ────
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 393,
                      height: 860,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ── Divine Background Painter (Rotating Halo behind Deity Card) ──
                          Positioned(
                            top: 0,
                            left: 0,
                            width: 393,
                            height: 1010,
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _ambientController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    painter: DivineBackgroundPainter(
                                      timeSeconds: _ambientController.value * 10.0,
                                      isCompleted: isCompleted,
                                      progressPct: (_count / _target).clamp(0.0, 1.0),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // ── Deity Picture + Shutter Grid ──────
                          Positioned(
                            top: 75,
                            left: 20,
                            width: 353,
                            height: 650,
                            child: AnimatedBuilder(
                              animation: _ambientController,
                              builder: (context, child) {
                                final double pulseValue = isCompleted
                                    ? (0.6 + 0.4 * math.sin(_ambientController.value * 2 * math.pi))
                                    : 1.0;
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: isCompleted
                                          ? const Color(0xFFFFD700).withValues(alpha: 0.5 + 0.3 * pulseValue)
                                          : const Color(0xFFFF9933).withValues(alpha: 0.3),
                                      width: isCompleted ? 2.0 : 1.0,
                                    ),
                                    boxShadow: isCompleted
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFF8F00).withValues(
                                                  alpha: 0.2 + 0.15 * pulseValue),
                                              blurRadius: 15 + 10 * pulseValue,
                                              spreadRadius: 1 + 2 * pulseValue,
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: child,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Stack(
                                  children: [
                                    // Fallback Background
                                    Positioned.fill(
                                      child: Container(
                                        color: const Color(0xFF1E1107),
                                      ),
                                    ),

                                    // Deity image (slow breathing zoom when completed)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _ambientController,
                                        builder: (context, child) {
                                          final double scale = isCompleted
                                              ? 1.0 + (math.sin(_ambientController.value * 2 * math.pi) * 0.015)
                                              : 1.0;
                                          return Transform.scale(
                                            scale: scale,
                                            child: child,
                                          );
                                        },
                                        child: RepaintBoundary(
                                          child: widget.entry.detailImagePath != null && widget.entry.detailImagePath!.isNotEmpty
                                              ? (widget.entry.detailImagePath!.startsWith('http')
                                                  ? Image.network(
                                                      widget.entry.detailImagePath!,
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true,
                                                      errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                                                    )
                                                  : widget.entry.detailImagePath!.startsWith('assets/')
                                                      ? Image.asset(
                                                          widget.entry.detailImagePath!,
                                                          fit: BoxFit.cover,
                                                          gaplessPlayback: true,
                                                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                                                        )
                                                      : Image.file(
                                                          File(widget.entry.detailImagePath!),
                                                          fit: BoxFit.cover,
                                                          gaplessPlayback: true,
                                                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                                                        ))
                                              : (widget.entry.imagePath.startsWith('http')
                                                  ? Image.network(
                                                      widget.entry.imagePath,
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true,
                                                      errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                                                    )
                                                  : widget.entry.imagePath.startsWith('assets/')
                                                      ? Image.asset(
                                                          widget.entry.imagePath,
                                                          fit: BoxFit.cover,
                                                          gaplessPlayback: true,
                                                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                                                        )
                                                      : Image.file(
                                                          File(widget.entry.imagePath),
                                                          fit: BoxFit.cover,
                                                          gaplessPlayback: true,
                                                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                                                        )),
                                        ),
                                      ),
                                    ),

                                    // Particle Canvas & Organic Erase Mask Layer (DivineCardPainter)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: Listenable.merge([_ambientController, _revealController, _completionController]),
                                        builder: (context, _) {
                                          return CustomPaint(
                                            painter: DivineCardPainter(
                                              jitteredPoints: _jitteredPoints,
                                              shuffledIndices: _shuffledIndices,
                                              count: _count,
                                              target: _target,
                                              revealingTileIndex: _revealingTile,
                                              currentRevealProgress: _revealController.value,
                                              completionFadeProgress: _completionController.value,
                                              smokeParticles: _smokeParticles,
                                              glowRings: _glowRings,
                                              timeSeconds: _ambientController.value * 10.0,
                                              isCompleted: isCompleted,
                                              lastRevealPoint: _currentAgarbattiPos ?? _lastRevealPoint,
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // Reveal percent badge
                                    if (!isCompleted)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.55),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFFFF9933).withValues(alpha: 0.6),
                                            ),
                                          ),
                                          child: Text(
                                            '$revealPct% revealed',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFFF9933),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                           // ── Glassmorphic Blessing Card removed per user request ──
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Note Container / Next Jap Button ───────────────────
                          Positioned(
                            top: 730,
                            left: 20,
                            width: 353,
                            height: 56,
                            child: isCompleted
                                ? AnimatedOpacity(
                                    opacity: _showContinueButton ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 800),
                                    child: IgnorePointer(
                                      ignoring: !_showContinueButton,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _resetCurrentMala,
                                              child: Container(
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF7F2EC),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: const Color(0xFFFF7700),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(
                                                        Icons.refresh_rounded,
                                                        color: Color(0xFFFF7700),
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Retry / Restart',
                                                        style: GoogleFonts.outfit(
                                                          color: const Color(0xFFFF7700),
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _startNextMala,
                                              child: Container(
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFFF9933), Color(0xFFFF5500)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFFF5500).withValues(alpha: 0.3),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Next Jap',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                // Standard Note Container (when in progress)
                                : const SizedBox.shrink(),
                          ),

                          // ── Progress Bar ─────────────────────
                          if (!isCompleted)
                            Positioned(
                              top: 802,
                              left: 20,
                              width: 353,
                              height: 6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Container(
                                  height: 6,
                                  color: const Color(0xFFE5DCD3),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (_count / _target).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFF9933),
                                            Color(0xFFFF5500),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // ── Bottom Reveal Panel ──────────────
                          Positioned(
                            top: 730,
                            left: 20,
                            width: 353,
                            height: 131,
                            child: GestureDetector(
                              onTap: _increment,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F2EC),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFE5DCD3),
                                    width: 1.0,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      bottom: 25,
                                      left: 0,
                                      right: 0,
                                      child: Text(
                                        isCompleted
                                            ? 'Mala Completed! You are blessed. 🙏'
                                            : 'Tap here and reveal a darshan.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFF7700),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Orange Circle TAP Button ─────────
                          Positioned(
                            top: 678, // Adjusted slightly for ring
                            left: 142, // Adjusted slightly for ring
                            width: 110,
                            height: 110,
                            child: GestureDetector(
                              onTap: _increment,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (!_canTap && _audioDuration.inMilliseconds > 0)
                                    SizedBox(
                                      width: 110,
                                      height: 110,
                                      child: CircularProgressIndicator(
                                        value: _audioProgress,
                                        color: const Color(0xFFFF9933),
                                        backgroundColor: Colors.grey.shade800,
                                        strokeWidth: 4,
                                      ),
                                    ),
                                  AnimatedScale(
                                    scale: _buttonScale,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeOutBack,
                                    child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isCompleted
                                          ? [
                                              const Color(0xFFFF9933),
                                              const Color(0xFFFF5500),
                                            ]
                                          : [
                                              _canTap
                                                  ? const Color(0xFFFF9933)
                                                  : Colors.grey.shade700,
                                              _canTap
                                                  ? const Color(0xFFFF5500)
                                                  : Colors.grey.shade800,
                                            ],
                                    ),
                                    boxShadow: _canTap
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFF7700).withValues(alpha: 0.4),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      revealedCount.toString().padLeft(3, '0'),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ), // closes TextStyle
                                    ), // closes Text
                                  ), // closes Center
                                ), // closes Container
                              ), // closes Transform.scale
                            ], // closes children
                          ), // closes Stack
                        ), // closes GestureDetector
                      ), // closes Positioned

                          // ── Divine Overlay Painter (Floating Embers & Petals over all UI elements) ──
                          Positioned(
                            top: 0,
                            left: 0,
                            width: 393,
                            height: 1010,
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _ambientController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    painter: DivineOverlayPainter(
                                      embers: _embers,
                                      petals: _petals,
                                      isCompleted: isCompleted,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // ── Top Bar (Moved to top of stack) ──────────────────────────
                          Positioned(
                            top: 25,
                            left: 20,
                            right: 20,
                            height: 48,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _circleBtn(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  onTap: () => Navigator.pop(context, _totalProgress),
                                ),
                                _circleBtn(
                                  icon: Icons.refresh_rounded,
                                  onTap: _resetCurrentMala,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Particle Systems & Divine Painters
// ─────────────────────────────────────────────

class EmberParticle {
  double x, y;
  double vx, vy;
  double size;
  double alpha;
  double speedMultiplier;
  
  EmberParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    this.speedMultiplier = 1.0,
  });
  
  void update(double width, double height) {
    y -= vy * speedMultiplier;
    x += vx;
    if (y < -20) {
      y = height + 20;
      x = math.Random().nextDouble() * width;
    }
    if (x < -20 || x > width + 20) {
      vx = -vx;
    }
  }
}

class GlowRing {
  final Offset position;
  final double maxRadius;
  final double maxLife;
  double life;
  final Color color;

  GlowRing({
    required this.position,
    this.maxRadius = 55.0,
    this.maxLife = 0.5,
    required this.color,
  }) : life = maxLife;

  bool update() {
    life -= 0.016;
    return life > 0;
  }
}

class SmokeParticle {
  double x, y;
  double vx, vy;
  double size;
  double alpha;
  double maxLife;
  double life;
  double growthRate;
  double waveFrequency;
  double waveAmplitude;
  double wavePhase;
  
  SmokeParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.maxLife,
    required this.growthRate,
    this.waveFrequency = 2.5,
    this.waveAmplitude = 0.6,
  }) : life = maxLife, wavePhase = math.Random().nextDouble() * 10.0;
  
  bool update() {
    life -= 0.016;
    size += growthRate;
    y -= vy;
    x += vx + math.sin(life * waveFrequency + wavePhase) * waveAmplitude;
    alpha = (life / maxLife).clamp(0.0, 1.0);
    return life > 0;
  }
}

class SpiralSparkParticle {
  Offset center;
  double angle;
  double radius;
  double speed;
  double radialSpeed;
  double life;
  final double maxLife;
  double size;
  Color color;

  SpiralSparkParticle({
    required this.center,
    required this.angle,
    required this.speed,
    required this.radialSpeed,
    required this.maxLife,
    required this.size,
    required this.color,
  })  : radius = 0.0,
        life = maxLife;

  bool update() {
    life -= 0.016;
    angle += speed;
    radius += radialSpeed;
    return life > 0;
  }

  Offset get currentPosition => Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
}

class TapSparkParticle {
  Offset position;
  double vx;
  double vy;
  double life;
  final double maxLife;
  double size;
  Color color;

  TapSparkParticle({
    required this.position,
    required this.vx,
    required this.vy,
    required this.maxLife,
    required this.size,
    required this.color,
  }) : life = maxLife;

  bool update() {
    life -= 0.016;
    position += Offset(vx, vy);
    vx *= 0.92;
    vy *= 0.92;
    vy -= 0.12;
    return life > 0;
  }
}

class FloatingOmText {
  Offset position;
  double life;
  final double maxLife;
  final String text;

  FloatingOmText({
    required this.position,
    required this.maxLife,
    required this.text,
  }) : life = maxLife;

  bool update() {
    life -= 0.016;
    position = position - const Offset(0, 0.85);
    return life > 0;
  }
}

enum ParticleShape { petal, leaf, ash, feather, spark }

class TempleThemeConfig {
  final String deityName;
  final ParticleShape particleShape;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String blessingTitle;
  final String blessingSubtitle;

  const TempleThemeConfig({
    required this.deityName,
    required this.particleShape,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.blessingTitle,
    required this.blessingSubtitle,
  });

  static TempleThemeConfig fromName(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('shiva') || nameLower.contains('mahadev')) {
      return const TempleThemeConfig(
        deityName: 'Lord Shiva',
        particleShape: ParticleShape.leaf,
        primaryColor: Color(0xFF81C784),
        secondaryColor: Color(0xFFE8F4FC),
        accentColor: Color(0xFFC5D8E0),
        blessingTitle: '🙏 Har Har Mahadev 🙏',
        blessingSubtitle: 'May Lord Shiva bless you with inner peace, courage, and divine liberation.',
      );
    } else if (nameLower.contains('krishna') || nameLower.contains('radha')) {
      return const TempleThemeConfig(
        deityName: 'Lord Krishna',
        particleShape: ParticleShape.feather,
        primaryColor: Color(0xFF0D4F8B),
        secondaryColor: Color(0xFF50C878),
        accentColor: Color(0xFFFF80AB),
        blessingTitle: '🙏 Jai Shree Krishna 🙏',
        blessingSubtitle: 'May Lord Krishna fill your life with eternal joy, love, and divine grace.',
      );
    } else if (nameLower.contains('ganesh') || nameLower.contains('ganpati')) {
      return const TempleThemeConfig(
        deityName: 'Lord Ganesha',
        particleShape: ParticleShape.petal,
        primaryColor: Color(0xFFFF6B35),
        secondaryColor: Color(0xFFFFB300),
        accentColor: Color(0xFFFFD700),
        blessingTitle: '🙏 Ganpati Bappa Morya 🙏',
        blessingSubtitle: 'May Lord Ganesha remove all obstacles and bestow wisdom upon your path.',
      );
    } else if (nameLower.contains('hanuman')) {
      return const TempleThemeConfig(
        deityName: 'Lord Hanuman',
        particleShape: ParticleShape.spark,
        primaryColor: Color(0xFFCC2200),
        secondaryColor: Color(0xFFFF6600),
        accentColor: Color(0xFFFFD700),
        blessingTitle: '🙏 Jai Bajrangbali 🙏',
        blessingSubtitle: 'May Lord Hanuman grant you immense strength, devotion, and divine protection.',
      );
    } else if (nameLower.contains('durga') || nameLower.contains('kali')) {
      return const TempleThemeConfig(
        deityName: 'Maa Durga',
        particleShape: ParticleShape.spark,
        primaryColor: Color(0xFF990000),
        secondaryColor: Color(0xFFFF1744),
        accentColor: Color(0xFFFFD700),
        blessingTitle: '🙏 Jai Mata Di 🙏',
        blessingSubtitle: 'May Maa Durga empower your spirit with fearless strength and victory.',
      );
    } else if (nameLower.contains('lakshmi')) {
      return const TempleThemeConfig(
        deityName: 'Maa Lakshmi',
        particleShape: ParticleShape.petal,
        primaryColor: Color(0xFFFF80AB),
        secondaryColor: Color(0xFFFFE082),
        accentColor: Color(0xFFFFD700),
        blessingTitle: '🙏 Shreem Mahalakshmiye Namah 🙏',
        blessingSubtitle: 'May Maa Lakshmi shower your home with eternal wealth, peace, and grace.',
      );
    } else if (nameLower.contains('vishnu')) {
      return const TempleThemeConfig(
        deityName: 'Lord Vishnu',
        particleShape: ParticleShape.spark,
        primaryColor: Color(0xFF0277BD),
        secondaryColor: Color(0xFFFFD700),
        accentColor: Color(0xFFFF8F00),
        blessingTitle: '🙏 Om Namo Narayanaya 🙏',
        blessingSubtitle: 'May Lord Vishnu preserve harmony, righteousness, and peace in your life.',
      );
    }
    return TempleThemeConfig(
      deityName: name,
      particleShape: ParticleShape.petal,
      primaryColor: const Color(0xFFFF9933),
      secondaryColor: const Color(0xFFFF5500),
      accentColor: const Color(0xFFFFD700),
      blessingTitle: '🙏 May $name Bless You 🙏',
      blessingSubtitle: 'May peace, strength, wisdom and divine grace always guide your sacred path.',
    );
  }

  static ParticleShape parseShape(String? shapeStr, ParticleShape defaultShape) {
    if (shapeStr == null || shapeStr.isEmpty || shapeStr == 'auto') return defaultShape;
    switch (shapeStr.toLowerCase()) {
      case 'leaf':
        return ParticleShape.leaf;
      case 'feather':
        return ParticleShape.feather;
      case 'spark':
        return ParticleShape.spark;
      case 'ash':
        return ParticleShape.ash;
      case 'petal':
        return ParticleShape.petal;
      default:
        return defaultShape;
    }
  }

  static TempleThemeConfig fromEntry(JapEntry entry) {
    final base = fromName(entry.name);
    return TempleThemeConfig(
      deityName: base.deityName,
      particleShape: parseShape(entry.particleShape, base.particleShape),
      primaryColor: base.primaryColor,
      secondaryColor: base.secondaryColor,
      accentColor: base.accentColor,
      blessingTitle: (entry.blessingTitle != null && entry.blessingTitle!.trim().isNotEmpty)
          ? entry.blessingTitle!
          : base.blessingTitle,
      blessingSubtitle: (entry.blessingSubtitle != null && entry.blessingSubtitle!.trim().isNotEmpty)
          ? entry.blessingSubtitle!
          : base.blessingSubtitle,
    );
  }
}

class PetalParticle {
  double x, y;
  double vy;
  double angle;
  double rotationSpeed;
  double size;
  double windFreq;
  double windAmp;
  double time;
  Color color;
  ParticleShape shape;
  
  PetalParticle({
    required this.x,
    required this.y,
    required this.vy,
    required this.angle,
    required this.rotationSpeed,
    required this.size,
    required this.windFreq,
    required this.windAmp,
    required this.color,
    this.shape = ParticleShape.petal,
  }) : time = math.Random().nextDouble() * 100;
  
  void update(double width, double height) {
    time += 0.016;
    y += vy;
    x += math.sin(time * windFreq) * windAmp;
    angle += rotationSpeed;
    
    if (y > height + 20) {
      y = -20;
      x = math.Random().nextDouble() * width;
    }
  }
}

class DivineBackgroundPainter extends CustomPainter {
  final double timeSeconds;
  final bool isCompleted;
  final double progressPct;

  DivineBackgroundPainter({
    required this.timeSeconds,
    required this.isCompleted,
    this.progressPct = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double effectiveProgress = isCompleted ? 1.0 : progressPct;
    if (effectiveProgress <= 0.02) return;

    final center = Offset(197.0, 400.0); // Center of card body

    // 1. Soft glowing aura backing (scales with progress)
    final double pulse = (0.08 + 0.14 * effectiveProgress) + (math.sin(timeSeconds * 2.5) * 0.04);
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9900).withValues(alpha: pulse.clamp(0.0, 0.35)),
          const Color(0xFFFF5500).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 350 * (0.6 + 0.4 * effectiveProgress)));
    canvas.drawCircle(center, 350 * (0.6 + 0.4 * effectiveProgress), auraPaint);

    // 2. Swirling golden/orange energy particles orbiting around the card (starts at 25% progress)
    if (effectiveProgress >= 0.25) {
      final double baseAngle = timeSeconds * (0.3 + 0.2 * effectiveProgress);
      final orbitPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      
      final int particleCount = (20 * effectiveProgress).round();
      for (int i = 0; i < particleCount; i++) {
        final double angle = baseAngle + (i * 2 * math.pi / math.max(1, particleCount));
        
        final double x = center.dx + math.cos(angle) * 195.0;
        final double y = center.dy + math.sin(angle) * 345.0;
        
        final double opacity = (0.3 + 0.3 * math.sin(timeSeconds * 3.0 + i)) * effectiveProgress;
        orbitPaint.color = (i % 2 == 0 ? const Color(0xFFFFD700) : const Color(0xFFFF5500))
            .withValues(alpha: opacity.clamp(0.0, 0.8));
        
        final double sizeVal = (2.5 + 1.5 * math.sin(timeSeconds * 4.0 + i)) * (0.7 + 0.3 * effectiveProgress);
        canvas.drawCircle(Offset(x, y), sizeVal, orbitPaint);
      }
    }

    // 3. Concentric rotating rings peeking out from behind (starts at 50% progress)
    if (effectiveProgress >= 0.50) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      final sweepShader = SweepGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.7 * effectiveProgress),
          const Color(0xFFFFD700).withValues(alpha: 0.05),
          const Color(0xFFFF8800).withValues(alpha: 0.7 * effectiveProgress),
          const Color(0xFFFFD700).withValues(alpha: 0.05),
          const Color(0xFFFFD700).withValues(alpha: 0.7 * effectiveProgress),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 250));

      ringPaint.shader = sweepShader;

      void drawRing(double radius, double strokeWidth, double angle) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        ringPaint.strokeWidth = strokeWidth;
        
        final rect = Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 3.2);
        canvas.drawOval(rect, ringPaint);
        canvas.restore();
      }

      drawRing(130.0, 2.5, timeSeconds * 0.3);
      if (effectiveProgress > 0.75) drawRing(180.0, 1.8, -timeSeconds * 0.2);
      if (effectiveProgress >= 0.90) drawRing(230.0, 1.2, timeSeconds * 0.12);
    }
  }

  @override
  bool shouldRepaint(covariant DivineBackgroundPainter oldDelegate) =>
      oldDelegate.timeSeconds != timeSeconds || oldDelegate.isCompleted != isCompleted || oldDelegate.progressPct != progressPct;
}

class DivineCardPainter extends CustomPainter {
  final List<Offset> jitteredPoints;
  final List<int> shuffledIndices;
  final int count;
  final int target;
  final int? revealingTileIndex;
  final double currentRevealProgress;
  final double completionFadeProgress;
  final List<SmokeParticle> smokeParticles;
  final List<GlowRing> glowRings;
  final List<TapSparkParticle> tapSparks;
  final List<SpiralSparkParticle> spiralSparks;
  final List<FloatingOmText> floatingOms;
  final double timeSeconds;
  final bool isCompleted;
  final Offset? lastRevealPoint;

  DivineCardPainter({
    required this.jitteredPoints,
    required this.shuffledIndices,
    required this.count,
    required this.target,
    required this.revealingTileIndex,
    required this.currentRevealProgress,
    this.completionFadeProgress = 0.0,
    required this.smokeParticles,
    required this.glowRings,
    this.tapSparks = const [],
    this.spiralSparks = const [],
    this.floatingOms = const [],
    required this.timeSeconds,
    required this.isCompleted,
    this.lastRevealPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double progressPct = isCompleted ? 1.0 : (count / math.max(1, target)).clamp(0.0, 1.0);

    // 0. Draw a subtle, pulsing Golden Divine Border around the whole card to make it look amazing from the start
    final borderPulse = 0.3 + (math.sin(timeSeconds * 1.5) * 0.15);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFD700).withValues(alpha: borderPulse),
          const Color(0xFFFF8800).withValues(alpha: borderPulse * 0.5),
          const Color(0xFFFFD700).withValues(alpha: borderPulse),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4.0);
    
    final borderRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height), 
      const Radius.circular(16)
    );
    canvas.drawRRect(borderRRect, borderPaint);

    // 1. Divine Aura Halo & Sunbeams (Light Rays) radiating from upper center
    // Starts subtly at 0% and becomes intensely bright as progress reaches 100%
    final double rayIntensity = 0.2 + (progressPct * 0.8);
    final center = Offset(size.width / 2, size.height * 0.35);

    // A. Draw concentric glowing aura behind/around the deity's face
    final double haloPulse = (0.2 + (math.sin(timeSeconds * 2.0) * 0.05)) * rayIntensity;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: haloPulse.clamp(0.0, 0.4)),
          const Color(0xFFFF8800).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 180));
    canvas.drawCircle(center, 180, haloPaint);

      // B. Draw rotating sunbeams (light rays)
      final rayPaint = Paint()..style = PaintingStyle.fill;
      final double rayAngleStep = 2 * math.pi / 12; // 12 rays
      final double rotationAngle = timeSeconds * (0.06 + 0.04 * rayIntensity); // speeds up with devotion

      for (int i = 0; i < 12; i++) {
        final double startAngle = i * rayAngleStep + rotationAngle;
        final double sweepAngle = rayAngleStep * 0.35; // width of rays

        final path = Path();
        path.moveTo(center.dx, center.dy);

        final double r = size.height; // radius to cover the entire card
        path.lineTo(
          center.dx + r * math.cos(startAngle),
          center.dy + r * math.sin(startAngle),
        );
        path.lineTo(
          center.dx + r * math.cos(startAngle + sweepAngle),
          center.dy + r * math.sin(startAngle + sweepAngle),
        );
        path.close();

        // Rays are semi-transparent and shimmer gently
        final double rayOpacity = (0.04 + 0.03 * math.sin(timeSeconds * 1.5 + i)) * rayIntensity;
        rayPaint.shader = RadialGradient(
          colors: [
            const Color(0xFFFFE066).withValues(alpha: rayOpacity.clamp(0.0, 0.12)),
            const Color(0xFFFF9900).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));

        canvas.drawPath(path, rayPaint);
      }

    // 2. Shimmering Gold Ambient Sparks (always visible, intensity scales)
    final double sparkMultiplier = 0.3 + (progressPct * 0.7);
      final sparkPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      final rng = math.Random(1088); // fixed seed for card particles
      for (int i = 0; i < 25; i++) {
        final double seedX = rng.nextDouble();
        final double seedY = rng.nextDouble();
        final double seedSpeed = rng.nextDouble() * 0.35 + 0.25;
        final double seedSize = rng.nextDouble() * 2.5 + 1.2;

        // vertical progress loop: goes bottom to top
        double y = (size.height + 40) - (((timeSeconds * 35 * seedSpeed) + seedY * size.height) % (size.height + 80));
        // horizontal sway
        double x = (seedX * size.width) + math.sin(timeSeconds * 1.2 + i) * 12.0;

        // Fade in from bottom, fade out at top
        double opacity = 0.4 * sparkMultiplier;
        if (y < 80) {
          opacity = ((y / 80) * 0.4 * sparkMultiplier).clamp(0.0, 0.4);
        } else if (y > size.height - 80) {
          opacity = (((size.height - y) / 80) * 0.4 * sparkMultiplier).clamp(0.0, 0.4);
        }

        final double currentSize = seedSize * (0.85 + 0.25 * math.sin(timeSeconds * 2.5 + i));
        sparkPaint.color = const Color(0xFFFFD700).withValues(
            alpha: (opacity * (0.6 + 0.4 * math.sin(timeSeconds * 1.8 + i))).clamp(0.0, 0.8));

        canvas.drawCircle(Offset(x, y), currentSize, sparkPaint);
      }

    // 3. Diagonal Golden Light Sweep / Shimmer overlay (starts at 50% progress)
    if (progressPct >= 0.50) {
      final double sweepProgress = (timeSeconds * 0.15) % 2.0;
      if (sweepProgress < 1.2) {
        final double sweepAlpha = (0.12 * progressPct).clamp(0.0, 0.15);
        final sweepPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.0),
              const Color(0xFFFFEFA0).withValues(alpha: sweepAlpha),
              const Color(0xFFFFD700).withValues(alpha: 0.0),
            ],
            stops: [
              (sweepProgress - 0.25).clamp(0.0, 1.0),
              sweepProgress.clamp(0.0, 1.0),
              (sweepProgress + 0.25).clamp(0.0, 1.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..blendMode = BlendMode.screen;

        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sweepPaint);
      }
    }

    final double mistOpacity = isCompleted
        ? (1.0 - completionFadeProgress).clamp(0.0, 1.0)
        : 1.0;

    // 1. Draw Mist Cover Layer & Organic Erase mask
    if (mistOpacity > 0.0) {
      canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: mistOpacity));

      // Warm cream mist canvas
      final paintMist = Paint()
        ..color = const Color(0xFFF7F2EC).withValues(alpha: mistOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, paintMist);

      // Cloudy mist background texture
      final paintMistTexture = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFEADBCE).withValues(alpha: 0.85 * mistOpacity),
            const Color(0xFFF7F2EC).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: 300));
      canvas.drawRect(Offset.zero & size, paintMistTexture);

      final paintErase = Paint()
        ..blendMode = BlendMode.dstOut
        ..style = PaintingStyle.fill;

      // Calculate dynamic reveal radius based on target count so N taps reveal the full image proportionally
      final double cardArea = size.width * size.height;
      final double areaPerPoint = cardArea / math.max(1, target);
      final double baseRevealRadius = math.max(28.0, math.sqrt(areaPerPoint / math.pi) * 1.35);

      // Draw all previously revealed organic cloud points
      final completedLimit = revealingTileIndex != null ? count - 1 : count;
      for (int i = 0; i < completedLimit; i++) {
        final idx = shuffledIndices[i];
        final pt = jitteredPoints[idx];

        final eraseShader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: 1.0),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: pt, radius: baseRevealRadius));

        paintErase.shader = eraseShader;
        canvas.drawCircle(pt, baseRevealRadius, paintErase);

        // Overlapping organic blobs for irregular edges (scaled down proportionally)
        final rng = math.Random(idx);
        for (int j = 0; j < 3; j++) {
          final angle = rng.nextDouble() * 2 * math.pi;
          final dist = rng.nextDouble() * 12.0 + 6.0;
          final r = rng.nextDouble() * 12.0 + 18.0;
          final offsetPt = pt + Offset(math.cos(angle) * dist, math.sin(angle) * dist);

          final subEraseShader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 1.0),
              Colors.black.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: offsetPt, radius: r));

          paintErase.shader = subEraseShader;
          canvas.drawCircle(offsetPt, r, paintErase);
        }
      }

      // Draw current tap reveal expanding mask (Sacred Lotus & Radiant Edge Flare)
      if (revealingTileIndex != null) {
        final pt = jitteredPoints[revealingTileIndex!];
        final currentRadius = baseRevealRadius * currentRevealProgress;

        if (currentRadius > 0) {
          // 1. Organic 8-Petal Lotus Blossom Geometry Erase Path
          final lotusPath = Path();
          const int numPetals = 8;
          for (int k = 0; k <= 360; k += 6) {
            final rad = k * math.pi / 180;
            final petalMod = 1.0 + 0.22 * math.sin(numPetals * rad);
            final r = currentRadius * petalMod;
            final x = pt.dx + r * math.cos(rad);
            final y = pt.dy + r * math.sin(rad);
            if (k == 0) {
              lotusPath.moveTo(x, y);
            } else {
              lotusPath.lineTo(x, y);
            }
          }
          lotusPath.close();

          final eraseShader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 1.0),
              Colors.black.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: pt, radius: currentRadius * 1.3));

          paintErase.shader = eraseShader;
          canvas.drawPath(lotusPath, paintErase);

          final rng = math.Random(revealingTileIndex!);
          for (int j = 0; j < 4; j++) {
            final angle = rng.nextDouble() * 2 * math.pi;
            final dist = (rng.nextDouble() * 14.0 + 6.0) * currentRevealProgress;
            final r = (rng.nextDouble() * 12.0 + 16.0) * currentRevealProgress;
            final offsetPt = pt + Offset(math.cos(angle) * dist, math.sin(angle) * dist);

            if (r > 0) {
              final subEraseShader = RadialGradient(
                colors: [
                  Colors.black.withValues(alpha: 1.0),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ).createShader(Rect.fromCircle(center: offsetPt, radius: r));

              paintErase.shader = subEraseShader;
              canvas.drawCircle(offsetPt, r, paintErase);
            }
          }
        }
      }

      canvas.restore();

      // 1b. Radiant Golden Edge Flare Halo around newly revealed deity tile
      if (revealingTileIndex != null) {
        final pt = jitteredPoints[revealingTileIndex!];
        final flareRadius = (baseRevealRadius * 1.35) * currentRevealProgress;
        final flareAlpha = (1.0 - currentRevealProgress).clamp(0.0, 1.0);

        final flarePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5 * (1.0 - currentRevealProgress)
          ..color = const Color(0xFFFFD700).withValues(alpha: flareAlpha * 0.95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(pt, flareRadius, flarePaint);

        final coreFlarePaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFFAEB).withValues(alpha: flareAlpha * 0.65),
              const Color(0xFFFF9900).withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: pt, radius: flareRadius * 1.25));
        canvas.drawCircle(pt, flareRadius * 1.25, coreFlarePaint);
      }
    }

    // 2. Draw Incense Smoke rising from the last reveal point
    // Draw an intense glowing Agarbatti ember tip and stick at lastRevealPoint
    if (lastRevealPoint != null && smokeParticles.isNotEmpty) {
      canvas.save();
      // Animate the stick swaying gently and floating elegantly (Medium Speed)
      final double swayAngle = math.sin(timeSeconds * 2.0) * 0.15; // medium sway
      final double bounceY = math.cos(timeSeconds * 4.5) * 1.0; // medium float
      canvas.translate(lastRevealPoint!.dx, lastRevealPoint!.dy + bounceY);
      canvas.rotate(swayAngle);

      // Calculate how much of the stick is left (1.0 = full, 0.0 = completely burned)
      final double stickRemaining = 1.0 - (count / math.max(1, target)).clamp(0.0, 1.0);
      final double pasteLength = 26.0 * stickRemaining;
      
      final double pasteStartY = 2.0;
      final double pasteEndY = pasteStartY + pasteLength;
      
      // Bamboo is attached to the bottom of the paste, overlapping by 2 units to prevent gaps.
      final double bambooStartY = math.max(pasteStartY, pasteEndY - 2.0);
      final double bambooEndY = bambooStartY + 15.0; // The bare bamboo tail is always 15 units long

      // X offsets to simulate the 0.088 slant angle (x=0 to x=4 over 45 units)
      final double pasteEndX = pasteEndY * 0.088;
      final double bambooStartX = bambooStartY * 0.088;
      final double bambooEndX = bambooEndY * 0.088;

      // Draw the bamboo base stick (extending downwards)
      final bambooPaint = Paint()
        ..color = const Color(0xFFC19A6B) // Light brown bamboo
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(bambooStartX, bambooStartY), Offset(bambooEndX, bambooEndY), bambooPaint);

      // Draw the incense paste body (dark grey/charcoal, thicker)
      if (pasteLength > 0.5) {
        final pastePaint = Paint()
          ..color = const Color(0xFF2A2A2A) // Dark charcoal paste
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.5);
        canvas.drawLine(const Offset(0, 2), Offset(pasteEndX, pasteEndY), pastePaint);
      }

      // Add a thin ash tip layer right below the ember
      final ashPaint = Paint()
        ..color = const Color(0xFF888888)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, 1), const Offset(0.5, 6), ashPaint);

      // Minimalist pulsing ember glow (gentle breathe instead of frantic crackle)
      final pulseRadius = 1.2 + math.sin(timeSeconds * 4.0) * 0.4; // tiny gentle pulse
      final glowEmberPaint = Paint()
        ..color = const Color(0xFFFF1100).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(Offset.zero, pulseRadius + 1.5, glowEmberPaint); // minimal outer glow
      
      // Core burning ember (tiny dot)
      final coreEmberPaint = Paint()
        ..color = const Color(0xFFFFaa00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0);
      canvas.drawCircle(Offset.zero, pulseRadius, coreEmberPaint);

      // White hot oxygenated center (tiny static dot)
      canvas.drawCircle(Offset.zero, 0.5, Paint()..color = Colors.white);
      
      // Removed the large blazing fire flame to make it look like a real agarbatti

      canvas.restore();

      // Draw highly realistic, wispy, swirling, overlapping smoke tendrils
      final int numTendrils = 2; // reduced from 4 for subtler smoke
      final int segments = 25; // reduced segments
      
      for (int tIdx = 0; tIdx < numTendrils; tIdx++) {
        final smokePath = Path();
        smokePath.moveTo(lastRevealPoint!.dx, lastRevealPoint!.dy);
        
        final double speedOffset = tIdx * 1.5;
        final double phaseOffset = tIdx * 2.14;
        final double spreadFactor = 1.0 + (tIdx * 0.4);
        
        for (int i = 1; i <= segments; i++) {
          final t = i / segments;
          final height = lastRevealPoint!.dy - t * 250.0; // shorter smoke column
          
          // Realistic laminar-to-turbulent transition
          final turbulence = (t < 0.1) ? (t * 5.0) : (t * t * 50.0 * spreadFactor); // reduced turbulence
          
          final phase1 = timeSeconds * (1.5 + speedOffset * 0.15) - t * 6.0 + phaseOffset; 
          final phase2 = timeSeconds * (1.2 + speedOffset * 0.25) + t * 10.0; 
          
          final waveX = lastRevealPoint!.dx + 
                        (math.sin(phase1) * turbulence) + 
                        (math.sin(phase2) * (turbulence * 0.35));
                        
          smokePath.lineTo(waveX, height);
        }
        
        final double strokeW = 1.5 + tIdx * 2.0;
        final double maxAlpha = 0.25 - (tIdx * 0.1); // significantly reduced alpha
        
        final tendrilPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: maxAlpha),
              const Color(0xFFE2E9F0).withValues(alpha: maxAlpha * 0.7),
              const Color(0xFFFFFFFF).withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(lastRevealPoint!.dx - 100, lastRevealPoint!.dy - 300, 200, 300));
          
        canvas.drawPath(smokePath, tendrilPaint);
      }
    }
    if (smokeParticles.isNotEmpty) {
      final blurPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0); // reduced from 6.0
        
      for (final smoke in smokeParticles) {
        final smokeShader = RadialGradient(
          colors: [
            const Color(0xFFFFFFFF).withValues(alpha: smoke.alpha * 0.5),
            const Color(0xFFFFE5B4).withValues(alpha: smoke.alpha * 0.2),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(smoke.x, smoke.y), radius: smoke.size * 0.8)); // reduced radius
        
        blurPaint.shader = smokeShader;
        canvas.drawCircle(Offset(smoke.x, smoke.y), smoke.size * 0.8, blurPaint);
      }
    }

    // 3. Draw Unique Blooming Lotus Mandala on Tap
    for (final ring in glowRings) {
      final progress = 1.0 - (ring.life / ring.maxLife);
      // Easing function for natural blooming scale
      final scale = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      
      final petalPaint = Paint()
        ..color = ring.color.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0);

      canvas.save();
      canvas.translate(ring.position.dx, ring.position.dy);
      // Base scale of lotus based on ring's maxRadius
      canvas.scale(scale * (ring.maxRadius / 60.0)); 
      
      // Draw 8 overlapping lotus petals
      for (int i = 0; i < 8; i++) {
        canvas.save();
        // Rotate petals and add a slight spin while blooming
        canvas.rotate(i * math.pi / 4.0 + (progress * math.pi / 12.0)); 
        
        // Exquisite petal curve
        final petalPath = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(20, -30, 0, -60)
          ..quadraticBezierTo(-20, -30, 0, 0)
          ..close();
          
        canvas.drawPath(petalPath, petalPaint);
        canvas.drawPath(petalPath, borderPaint);
        canvas.restore();
      }
      
      // Center glowing core of the lotus
      canvas.drawCircle(Offset.zero, 8.0, Paint()..color = Colors.white.withValues(alpha: opacity));
      canvas.restore();
    }

    // 3b. Draw Explosive Radial Tap Sparks (Comet Trails)
    for (final spark in tapSparks) {
      final progress = 1.0 - (spark.life / spark.maxLife);
      final alpha = (spark.life / spark.maxLife).clamp(0.0, 1.0);
      final currentSize = spark.size * (1.0 - progress * 0.4);

      final sparkPaint = Paint()
        ..color = spark.color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      final angle = math.atan2(spark.vy, spark.vx);
      final tailLength = currentSize * 5.0; // dynamic comet tail
      
      canvas.save();
      canvas.translate(spark.position.dx, spark.position.dy);
      canvas.rotate(angle);
      
      final sparkPath = Path()
        ..moveTo(currentSize, 0)
        ..quadraticBezierTo(0, currentSize * 0.8, -tailLength, 0)
        ..quadraticBezierTo(0, -currentSize * 0.8, currentSize, 0)
        ..close();
        
      canvas.drawPath(sparkPath, sparkPaint);
      
      final corePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(currentSize * 0.3, 0), currentSize * 0.4, corePaint);
      
      canvas.restore();
    }

    // 3bb. Draw Double-Helix Spiral Swirl Sparks
    for (final spark in spiralSparks) {
      final alpha = (spark.life / spark.maxLife).clamp(0.0, 1.0);
      final pos = spark.currentPosition;
      final spiralPaint = Paint()
        ..color = spark.color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(pos, spark.size, spiralPaint);
      final corePaint = Paint()..color = Colors.white.withValues(alpha: alpha * 0.8);
      canvas.drawCircle(pos, spark.size * 0.5, corePaint);
    }

    // 3c. Draw Floating Sacred Om & Chant Text ("ॐ", "राम", "जय")
    for (final om in floatingOms) {
      final progress = 1.0 - (om.life / om.maxLife);
      final alpha = (om.life / om.maxLife).clamp(0.0, 1.0);
      final scale = 1.0 + (progress * 0.5);

      final textSpan = TextSpan(
        text: om.text,
        style: GoogleFonts.outfit(
          fontSize: 16.0 * scale,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFD700).withValues(alpha: alpha),
          shadows: [
            Shadow(
              color: const Color(0xFFFF6D00).withValues(alpha: alpha * 0.8),
              blurRadius: 8,
            ),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        om.position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // 4. Removed the soft breathing target ring around nextPt

    // 5. Paint Inner Shadow/Glow (vignette) when completed inside the card
  }

  @override
  bool shouldRepaint(covariant DivineCardPainter oldDelegate) => true;
}

class DivineOverlayPainter extends CustomPainter {
  final List<EmberParticle> embers;
  final List<PetalParticle> petals;
  final bool isCompleted;

  DivineOverlayPainter({
    required this.embers,
    required this.petals,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Floating Embers (only when completed)
    if (isCompleted) {
      final emberPaint = Paint()..style = PaintingStyle.fill;
      for (final ember in embers) {
        emberPaint.color = const Color(0xFFFFB300).withValues(alpha: ember.alpha);
        canvas.drawCircle(Offset(ember.x, ember.y), ember.size, emberPaint);
      }
    }

    // 2. Draw Falling Petals / Leaves / Feathers / Sparks (only when completed)
    if (isCompleted && petals.isNotEmpty) {
      for (final particle in petals) {
        _drawParticle(canvas, Offset(particle.x, particle.y), particle.size, particle.angle, particle.color, particle.shape);
      }
    }
  }

  void _drawParticle(Canvas canvas, Offset center, double size, double angle, Color color, ParticleShape shape) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final path = Path();

    switch (shape) {
      case ParticleShape.leaf: // Bilva leaf shape for Shiva
        path.moveTo(0, -size);
        path.quadraticBezierTo(size * 0.6, -size * 0.3, 0, size * 0.5);
        path.quadraticBezierTo(-size * 0.6, -size * 0.3, 0, -size);
        path.moveTo(0, 0);
        path.lineTo(0, size * 0.8);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.2;
        canvas.drawPath(path, paint);
        paint.style = PaintingStyle.fill;
        break;

      case ParticleShape.feather: // Peacock feather shape for Krishna
        final rect = Rect.fromCenter(center: Offset.zero, width: size * 0.8, height: size * 1.5);
        canvas.drawOval(rect, paint);
        final innerPaint = Paint()..color = const Color(0xFFFFD700);
        canvas.drawCircle(Offset.zero, size * 0.25, innerPaint);
        break;

      case ParticleShape.spark: // Glowing embers / Sindoor for Hanuman/Durga
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(Offset.zero, size * 0.6, glowPaint);
        canvas.drawCircle(Offset.zero, size * 0.3, paint);
        break;

      case ParticleShape.petal:
      case ParticleShape.ash:
        path.moveTo(0, -size / 2);
        path.quadraticBezierTo(size / 2.5, -size / 4, 0, size / 2);
        path.quadraticBezierTo(-size / 2.5, -size / 4, 0, -size / 2);
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DivineOverlayPainter oldDelegate) => true;
}


