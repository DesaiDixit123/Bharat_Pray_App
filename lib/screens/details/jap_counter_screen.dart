import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'upload_god_photo_screen.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

// ─────────────────────────────────────────────
// Data model for a single Jap entry
// ─────────────────────────────────────────────
class JapEntry {
  final String name;
  final String mantra;
  final String imagePath;
  final String? detailImagePath;
  final String? audioUrl;
  final int target;
  int progress; // how many japs done so far

  JapEntry({
    required this.name,
    required this.mantra,
    required this.imagePath,
    this.detailImagePath,
    this.audioUrl,
    this.target = 108,
    this.progress = 0,
  });
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

  final List<JapEntry> _allJaps = [
    JapEntry(
      name: "Shivji's Jap",
      mantra: 'ॐ नमः शिवाय',
      imagePath: 'assets/images/image_4.png',
      detailImagePath: 'assets/images/download_1.png',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      target: 108,
      progress: 0,
    ),
    JapEntry(
      name: "Kali Mataji's Jap",
      mantra: 'ॐ क्रीं कालिकायै नमः',
      imagePath: 'assets/images/image_4_1.png',
      detailImagePath: 'assets/images/image_4_1.png',
      target: 108,
      progress: 54,
    ),
    JapEntry(
      name: "Shivji's Jap",
      mantra: 'ॐ नमः शिवाय',
      imagePath: 'assets/images/image_4.png',
      detailImagePath: 'assets/images/download_1.png',
      target: 108,
      progress: 108,
    ),
    JapEntry(
      name: "Shivji's Jap",
      mantra: 'ॐ नमः शिवाय',
      imagePath: 'assets/images/image_4.png',
      detailImagePath: 'assets/images/download_1.png',
      target: 108,
      progress: 80,
    ),
  ];

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
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No results found',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFF2E2A36)
                                  .withValues(alpha: 0.4),
                              fontSize: 15)),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
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
              entry.imagePath.startsWith('assets/')
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

  static const int _totalTiles = 108;
  static const int _cols = 6;

  late List<int> _shuffledIndices;   // random reveal order (seeded per entry)
  late List<Offset> _jitteredPoints; // organic points corresponding to grid cells

  late final AudioPlayer _audioPlayer;

  // Single controller drives the "currently revealing" tile expansion
  late final AnimationController _revealController;
  int? _revealingTile;               // tile index being animated right now

  bool _canTap = true;
  double _buttonScale = 1.0;

  ImageProvider? _imageProvider;

  // Ambient loop controller and particles
  late final AnimationController _ambientController;
  final List<EmberParticle> _embers = [];
  final List<SmokeParticle> _smokeParticles = [];
  final List<GlowRing> _glowRings = [];
  final List<PetalParticle> _petals = [];

  Offset? _lastRevealPoint;
  double _smokeEmitTimer = 0.0;

  // ── Helpers ────────────────────────────────
  int get _totalProgress => (_completedMalas * _target) + _count;

  // Build a fresh shuffled order seeded by entry name + mala number
  List<int> _buildShuffled(int malaSeed) {
    final rng = math.Random(widget.entry.name.hashCode ^ malaSeed);
    return List.generate(_totalTiles, (i) => i)..shuffle(rng);
  }

  // Generate 108 jittered points so they cover the 336x630 area evenly but randomly
  List<Offset> _generateJitteredPoints(int malaSeed) {
    final rng = math.Random(widget.entry.name.hashCode ^ (malaSeed + 123));
    List<Offset> points = [];
    for (int i = 0; i < _totalTiles; i++) {
      final col = i % _cols;
      final row = i ~/ _cols;
      
      final cellCenterX = col * 56.0 + 28.0;
      final cellCenterY = row * 35.0 + 17.5;
      
      // Jitter offsets (bounded to keep point within cell but random)
      final dx = (rng.nextDouble() * 26.0) - 13.0; // [-13, 13]
      final dy = (rng.nextDouble() * 16.0) - 8.0;  // [-8, 8]
      
      points.add(Offset(cellCenterX + dx, cellCenterY + dy));
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
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _canTap = true);
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

    // Restore last reveal point if we are continuing a partially completed mala
    if (_count > 0 && _count < _target) {
      final lastRevealPos = (_count - 1) % _totalTiles;
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

  void _initPetals() {
    final rng = math.Random();
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
        color: rng.nextBool()
            ? (rng.nextBool() ? const Color(0xFFE22D5A) : const Color(0xFFC2185B)) // Rose petals
            : (rng.nextBool() ? const Color(0xFFFFB300) : const Color(0xFFFF8F00)), // Marigold petals
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

    // Emit & update rising incense smoke (inside card space)
    if (_lastRevealPoint != null && !isCompleted) {
      _smokeEmitTimer += 0.016;
      if (_smokeEmitTimer >= 0.14) { // emit smoke particle approx every 140ms
        _smokeEmitTimer = 0.0;
        final rng = math.Random();
        _smokeParticles.add(SmokeParticle(
          x: _lastRevealPoint!.dx,
          y: _lastRevealPoint!.dy,
          vx: (rng.nextDouble() * 0.4) - 0.2,
          vy: rng.nextDouble() * 0.7 + 0.6, // rise velocity
          size: rng.nextDouble() * 5.0 + 8.0,
          alpha: rng.nextDouble() * 0.25 + 0.25,
          maxLife: rng.nextDouble() * 1.4 + 1.2, // seconds
          growthRate: rng.nextDouble() * 0.35 + 0.25,
        ));
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
      if (path.startsWith('assets/')) {
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
    _ambientController.dispose();
    super.dispose();
  }

  // ── Tap handler ────────────────────────────
  void _increment() async {
    if (_completedMalas > 0 || _count >= _target) {
      _startNextMala();
      return;
    }
    if (!_canTap) return;

    HapticFeedback.lightImpact();

    // Pick the next point in the shuffled order
    final revealPos = _count % _totalTiles;
    final tileIdx = _shuffledIndices[revealPos];
    final revealPt = _jitteredPoints[tileIdx];

    setState(() {
      _canTap = false;
      _buttonScale = 0.92;
      _revealingTile = tileIdx;
      _lastRevealPoint = revealPt;
      _count++;
      
      // Emit a simple expanding golden aura ring
      _glowRings.add(GlowRing(
        position: revealPt,
        maxRadius: 55.0,
        maxLife: 0.5,
        color: const Color(0xFFFFB300),
      ));
    });

    // Scale button back
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _buttonScale = 1.0);
    });

    // Run the mask erase circle expansion
    _revealController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _revealingTile = null;
      });
    });

    // Mala complete?
    if (_count >= _target) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      HapticFeedback.heavyImpact();
    }

    // Cooldown: wait for audio to finish, or 500ms if no audio
    if (widget.entry.audioUrl != null && widget.entry.audioUrl!.isNotEmpty) {
      try {
        await _audioPlayer.play(UrlSource(widget.entry.audioUrl!));
      } catch (e) {
        debugPrint("Error playing audio: $e");
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _canTap = true);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _canTap = true);
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
      _revealingTile = null;
      _petals.clear();
      _glowRings.clear();
      _smokeParticles.clear();
      _lastRevealPoint = null;
      _smokeEmitTimer = 0.0;
      _canTap = true;
    });
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
    final int revealedCount = isCompleted ? _totalTiles : _count;
    final int revealPct = (revealedCount / _totalTiles * 100).toInt();

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

            // ── Absolute Positioned Scrollable Content ────
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: 393,
                      height: 1010,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ── Top Bar ──────────────────────────
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
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // ── Deity Picture + Shutter Grid ──────
                          Positioned(
                            top: 85,
                            left: 29,
                            width: 336,
                            height: 630,
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
                                          child: widget.entry.detailImagePath != null
                                              ? Image.asset(
                                                  widget.entry.detailImagePath!,
                                                  fit: BoxFit.cover,
                                                  gaplessPlayback: true,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return _buildFallbackImage();
                                                  },
                                                )
                                              : widget.entry.imagePath.startsWith('assets/')
                                                  ? Image.asset(
                                                      widget.entry.imagePath,
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return _buildFallbackImage();
                                                      },
                                                    )
                                                  : Image.file(
                                                      File(widget.entry.imagePath),
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return _buildFallbackImage();
                                                      },
                                                    ),
                                        ),
                                      ),
                                    ),

                                    // Particle Canvas & Organic Erase Mask Layer (DivineCardPainter)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: Listenable.merge([_ambientController, _revealController]),
                                        builder: (context, _) {
                                          return CustomPaint(
                                            painter: DivineCardPainter(
                                              jitteredPoints: _jitteredPoints,
                                              shuffledIndices: _shuffledIndices,
                                              count: _count,
                                              target: _target,
                                              revealingTileIndex: _revealingTile,
                                              currentRevealProgress: _revealController.value,
                                              smokeParticles: _smokeParticles,
                                              glowRings: _glowRings,
                                              timeSeconds: _ambientController.value * 10.0,
                                              isCompleted: isCompleted,
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

                                    // Glassmorphic Blessing Overlay Card
                                    Positioned(
                                      bottom: 20,
                                      left: 20,
                                      right: 20,
                                      child: AnimatedOpacity(
                                        opacity: isCompleted ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 1000),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF8F00).withValues(alpha: 0.2),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD700), size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Divine Blessing',
                                                    style: GoogleFonts.outfit(
                                                      color: const Color(0xFFFFD700),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD700), size: 16),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'May peace, prosperity, strength and happiness bless your life.',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white.withValues(alpha: 0.95),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.35,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
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
                                // Next Jap Button (when completed)
                                ? GestureDetector(
                                    onTap: _startNextMala,
                                    child: Container(
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                // Standard Note Container (when in progress)
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F2EC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE5DCD3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          color: Color(0xFFFF7700),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Complete 108 Darshan to unlock Full Darshan & Blessing',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF2E2A36),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                            top: 868,
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
                            top: 821,
                            left: 147,
                            width: 100,
                            height: 100,
                            child: GestureDetector(
                              onTap: _increment,
                              child: Transform.scale(
                                scale: _buttonScale,
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
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

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

  DivineBackgroundPainter({
    required this.timeSeconds,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isCompleted) return;

    final center = Offset(197.0, 400.0); // Center of card body

    // 1. Soft glowing aura backing
    final double pulse = 0.22 + (math.sin(timeSeconds * 2.5) * 0.05);
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9900).withValues(alpha: pulse),
          const Color(0xFFFF5500).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 350));
    canvas.drawCircle(center, 350, auraPaint);

    // 2. Swirling golden/orange energy particles orbiting around the card
    final double baseAngle = timeSeconds * 0.45;
    final orbitPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    
    for (int i = 0; i < 20; i++) {
      final double angle = baseAngle + (i * 2 * math.pi / 20);
      
      // Elliptical coordinates that wrap exactly outside the 336x630 card
      final double x = center.dx + math.cos(angle) * 195.0;
      final double y = center.dy + math.sin(angle) * 345.0;
      
      final double opacity = 0.5 + 0.3 * math.sin(timeSeconds * 3.0 + i);
      orbitPaint.color = (i % 2 == 0 ? const Color(0xFFFFD700) : const Color(0xFFFF5500))
          .withValues(alpha: opacity);
      
      final double sizeVal = 3.5 + 2.0 * math.sin(timeSeconds * 4.0 + i);
      canvas.drawCircle(Offset(x, y), sizeVal, orbitPaint);
    }

    // 3. Concentric rotating rings peeking out from behind
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final sweepShader = SweepGradient(
      colors: [
        const Color(0xFFFFD700).withValues(alpha: 0.7),
        const Color(0xFFFFD700).withValues(alpha: 0.05),
        const Color(0xFFFF8800).withValues(alpha: 0.7),
        const Color(0xFFFFD700).withValues(alpha: 0.05),
        const Color(0xFFFFD700).withValues(alpha: 0.7),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 250));

    ringPaint.shader = sweepShader;

    // Draw 3 concentric rings with alternating rotations
    void drawRing(double radius, double strokeWidth, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      ringPaint.strokeWidth = strokeWidth;
      
      // Draw an ellipse ring matching the card proportion
      final rect = Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 3.2);
      canvas.drawOval(rect, ringPaint);
      canvas.restore();
    }

    drawRing(130.0, 2.5, timeSeconds * 0.3);
    drawRing(180.0, 1.8, -timeSeconds * 0.2);
    drawRing(230.0, 1.2, timeSeconds * 0.12);
  }

  @override
  bool shouldRepaint(covariant DivineBackgroundPainter oldDelegate) =>
      oldDelegate.timeSeconds != timeSeconds || oldDelegate.isCompleted != isCompleted;
}

class DivineCardPainter extends CustomPainter {
  final List<Offset> jitteredPoints;
  final List<int> shuffledIndices;
  final int count;
  final int target;
  final int? revealingTileIndex;
  final double currentRevealProgress;
  final List<SmokeParticle> smokeParticles;
  final List<GlowRing> glowRings;
  final double timeSeconds;
  final bool isCompleted;

  DivineCardPainter({
    required this.jitteredPoints,
    required this.shuffledIndices,
    required this.count,
    required this.target,
    required this.revealingTileIndex,
    required this.currentRevealProgress,
    required this.smokeParticles,
    required this.glowRings,
    required this.timeSeconds,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If completed, draw the premium inside-image Live Darshan animations
    if (isCompleted) {
      // 1. Divine Aura Halo & Sunbeams (Light Rays) radiating from upper center
      final center = Offset(size.width / 2, size.height * 0.35);

      // A. Draw concentric glowing aura behind/around the deity's face
      final double haloPulse = 0.2 + (math.sin(timeSeconds * 2.0) * 0.05);
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: haloPulse),
            const Color(0xFFFF8800).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 150));
      canvas.drawCircle(center, 150, haloPaint);

      // B. Draw rotating sunbeams (light rays)
      final rayPaint = Paint()..style = PaintingStyle.fill;
      final double rayAngleStep = 2 * math.pi / 12; // 12 rays
      final double rotationAngle = timeSeconds * 0.08; // slow elegant rotation

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
        final double rayOpacity = 0.05 + 0.03 * math.sin(timeSeconds * 1.5 + i);
        rayPaint.shader = RadialGradient(
          colors: [
            const Color(0xFFFFE066).withValues(alpha: rayOpacity),
            const Color(0xFFFF9900).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));

        canvas.drawPath(path, rayPaint);
      }

      // 2. Shimmering Gold Sparks (deterministic particles floating upwards)
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
        double opacity = 0.4;
        if (y < 80) {
          opacity = (y / 80).clamp(0.0, 0.4);
        } else if (y > size.height - 80) {
          opacity = ((size.height - y) / 80).clamp(0.0, 0.4);
        }

        final double currentSize = seedSize * (0.85 + 0.25 * math.sin(timeSeconds * 2.5 + i));
        sparkPaint.color = const Color(0xFFFFD700).withValues(
            alpha: opacity * (0.6 + 0.4 * math.sin(timeSeconds * 1.8 + i)));

        canvas.drawCircle(Offset(x, y), currentSize, sparkPaint);
      }

      // 3. Diagonal Golden Light Sweep / Shimmer overlay
      final double sweepProgress = (timeSeconds * 0.15) % 2.0; // moves from -0.5 to 1.5
      if (sweepProgress < 1.2) {
        final sweepPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.0),
              const Color(0xFFFFEFA0).withValues(alpha: 0.12),
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

    // 1. Draw Mist Cover Layer & Organic Erase mask
    if (!isCompleted) {
      canvas.saveLayer(Offset.zero & size, Paint());

      // Warm cream mist canvas
      final paintMist = Paint()
        ..color = const Color(0xFFF7F2EC)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, paintMist);

      // Cloudy mist background texture
      final paintMistTexture = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFEADBCE).withValues(alpha: 0.85),
            const Color(0xFFF7F2EC).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: 300));
      canvas.drawRect(Offset.zero & size, paintMistTexture);

      final paintErase = Paint()
        ..blendMode = BlendMode.dstOut
        ..style = PaintingStyle.fill;

      // Reduced reveal radius to 45.0 for tighter, more detailed reveal
      const double baseRevealRadius = 45.0;

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

      // Draw current tap reveal expanding mask
      if (revealingTileIndex != null) {
        final pt = jitteredPoints[revealingTileIndex!];
        final currentRadius = baseRevealRadius * currentRevealProgress;

        if (currentRadius > 0) {
          final eraseShader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 1.0),
              Colors.black.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: pt, radius: currentRadius));

          paintErase.shader = eraseShader;
          canvas.drawCircle(pt, currentRadius, paintErase);

          final rng = math.Random(revealingTileIndex!);
          for (int j = 0; j < 3; j++) {
            final angle = rng.nextDouble() * 2 * math.pi;
            final dist = (rng.nextDouble() * 12.0 + 6.0) * currentRevealProgress;
            final r = (rng.nextDouble() * 12.0 + 18.0) * currentRevealProgress;
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
    }

    // 2. Draw Incense Smoke rising from the last reveal point
    final smokePaint = Paint()..style = PaintingStyle.fill;
    for (final smoke in smokeParticles) {
      final smokeShader = RadialGradient(
        colors: [
          const Color(0xFFF7F2EC).withValues(alpha: smoke.alpha * 0.45),
          const Color(0xFFFFEAD0).withValues(alpha: smoke.alpha * 0.22),
          const Color(0xFFF7F2EC).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(smoke.x, smoke.y), radius: smoke.size));
      smokePaint.shader = smokeShader;
      canvas.drawCircle(Offset(smoke.x, smoke.y), smoke.size, smokePaint);
    }

    // 3. Draw expanding Glow Rings (tap aura shockwaves)
    for (final ring in glowRings) {
      final progress = 1.0 - (ring.life / ring.maxLife);
      final radius = progress * ring.maxRadius;
      final opacity = (ring.life / ring.maxLife).clamp(0.0, 1.0);

      // Outer thin glowing ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - progress * 0.5)
        ..color = ring.color.withValues(alpha: opacity * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(ring.position, radius, ringPaint);

      // Soft filled aura inside
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = ring.color.withValues(alpha: opacity * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(ring.position, radius * 0.8, fillPaint);
    }

    // 4. Paint Next Target Incense Stick Indicator (slanted diagonally, pointing to nextPt)
    if (!isCompleted && revealingTileIndex == null && count < target) {
      final nextPt = jitteredPoints[shuffledIndices[count % target]];
      
      // Tip is at nextPt. Stick goes down-right.
      final tip = nextPt;
      final mid = nextPt + const Offset(8.0, 18.0);
      final base = nextPt + const Offset(14.0, 32.0);

      // A. Draw the thin bamboo stick base (brownish-tan)
      final bambooPaint = Paint()
        ..color = const Color(0xFFC6A07A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(base, mid, bambooPaint);

      // B. Draw the thicker incense coating (dark charcoal/brown)
      final pastePaint = Paint()
        ..color = const Color(0xFF4A3E3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(mid, tip, pastePaint);

      // C. Draw the burning glowing tip (ember)
      final pulse = 1.0 + (math.sin(timeSeconds * 8.0) * 0.15);
      final emberGlowPaint = Paint()
        ..color = const Color(0xFFFF4500).withValues(alpha: 0.8)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(tip, 3.5 * pulse, emberGlowPaint);

      final emberCorePaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tip, 1.5, emberCorePaint);
      
      // D. Draw a tiny soft breathing target ring around the tip to make it pop
      final ringPulse = 1.0 + (math.sin(timeSeconds * 4.0) * 0.1);
      final targetRingPaint = Paint()
        ..color = const Color(0xFFFF9900).withValues(alpha: 0.35 + (math.sin(timeSeconds * 4.0) * 0.15))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(tip, 12.0 * ringPulse, targetRingPaint);
    }

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
    // 1. Draw Floating Embers
    final emberPaint = Paint()..style = PaintingStyle.fill;
    for (final ember in embers) {
      emberPaint.color = const Color(0xFFFFB300).withValues(alpha: ember.alpha);
      canvas.drawCircle(Offset(ember.x, ember.y), ember.size, emberPaint);
    }

    // 2. Draw Falling Petals (only when completed)
    if (isCompleted && petals.isNotEmpty) {
      for (final petal in petals) {
        _drawPetal(canvas, Offset(petal.x, petal.y), petal.size, petal.angle, petal.color);
      }
    }
  }

  void _drawPetal(Canvas canvas, Offset center, double size, double angle, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final path = Path();
    path.moveTo(0, -size / 2);
    path.quadraticBezierTo(size / 2.5, -size / 4, 0, size / 2);
    path.quadraticBezierTo(-size / 2.5, -size / 4, 0, -size / 2);
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DivineOverlayPainter oldDelegate) => true;
}


