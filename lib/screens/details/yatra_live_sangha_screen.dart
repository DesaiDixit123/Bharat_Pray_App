import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'add_temple_on_route_screen.dart';
import 'individual_progress_screen.dart';
import 'yatra_chat_screen.dart';
import 'yatra_stop_progress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:bharat_pray/screens/details/app_icons.dart';

class YatraLiveSanghaScreen extends StatefulWidget {
  final String journeyId;
  final String title;
  final String distance;
  final String steps;
  final String duration;
  final String sangha;
  final String imageAsset;
  final List<TempleRouteItem> selectedTemples;
  final Widget? completedScreen;
  final bool isFromCreateGroup;

  const YatraLiveSanghaScreen({
    super.key,
    this.journeyId = '',
    this.title = 'Somnath',
    this.distance = '450 km',
    this.steps = '108k',
    this.duration = '5 Days',
    this.sangha = '12.5k',
    this.imageAsset = 'assets/images/somnath_temple_new.png',
    this.selectedTemples = const <TempleRouteItem>[],
    this.completedScreen,
    this.isFromCreateGroup = false,
  });

  @override
  State<YatraLiveSanghaScreen> createState() => _YatraLiveSanghaScreenState();
}

class _YatraLiveSanghaScreenState extends State<YatraLiveSanghaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _runController;
  late final Future<Uint8List?> _backgroundBytesFuture;
  bool _isRunning = false;
  bool _hasShownTempleAlertInRun = false;
  Timer? _liveWalkingTimer;
  static const String _routeBackgroundSvg =
      'assets/images/ChatGPT Image May 30, 2026, 06_05_16 PM 1.svg';

  static const String _backArrowSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#FFFFFF"/>
</svg>''';

  @override
  void initState() {
    super.initState();
    _backgroundBytesFuture = _loadEmbeddedBackgroundBytes();
    _runController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  Future<Uint8List?> _loadEmbeddedBackgroundBytes() async {
    try {
      final svgText = await rootBundle.loadString(_routeBackgroundSvg);
      final match = RegExp(
        "data:image/[^;]+;base64,([^\"']+)",
        caseSensitive: false,
      ).firstMatch(svgText);
      if (match == null || match.groupCount < 1) return null;
      final base64Payload = match.group(1);
      if (base64Payload == null || base64Payload.isEmpty) return null;
      return base64Decode(base64Payload);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _liveWalkingTimer?.cancel();
    _runController.dispose();
    super.dispose();
  }

  void _startRun() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _runController.repeat();
    _scheduleTempleAlertPreview();

    // Start live pedometer simulation
    _liveWalkingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        if (token.isNotEmpty && widget.journeyId.isNotEmpty) {
          // Simulate 500 steps and 400 meters walked every 3 seconds
          await ApiService.updateJourneyLocation(token, widget.journeyId, 500, 400.0);
          
          final progressData = await ApiService.getJourneyProgress(token, widget.journeyId);
          if (progressData.isNotEmpty) {
            final progress = (progressData['progress'] ?? 0) / 100.0;
            if (progress >= 1.0) {
              _stopRun(isComplete: true);
            }
          }
        }
      } catch (e) {
        debugPrint('Error in live walking timer: $e');
      }
    });
  }

  void _stopRun({bool isComplete = false}) async {
    if (!_isRunning) return;

    _liveWalkingTimer?.cancel();
    
    if (_isRunning) {
      _runController.stop();
      _runController.reset();
      setState(() {
        _isRunning = false;
        _hasShownTempleAlertInRun = false;
      });
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        if (token.isNotEmpty && widget.journeyId.isNotEmpty) {
          await ApiService.stopJourney(token, widget.journeyId);
        }
      } catch (e) {
        debugPrint('Failed to stop journey in backend: $e');
      }
    }

    if (!mounted) return;
    
    if (isComplete && widget.completedScreen != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget.completedScreen!,
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => YatraStopProgressScreen(
            journeyId: widget.journeyId,
            onContinue: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    }
  }

  void _scheduleTempleAlertPreview() {
    if (_hasShownTempleAlertInRun) return;
    _hasShownTempleAlertInRun = true;

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || !_isRunning) return;
      _showTempleOnRoutePopup(
        const _TempleRouteAlert(
          templeName: 'Kashtabhanjan Hanuman Temple',
          locationName: 'Sarangpur',
          templeImage: 'assets/images/deity_hanuman.png',
          messageLine1: "You are passing by one of Gujarat's",
          messageLine2: 'most revered Hanuman temples.',
          messageLine3: 'Would you like to visit the Live Darshan before',
          messageLine4: 'continuing your Somnath Yatra?',
        ),
      );
    });
  }

  void _showTempleOnRoutePopup(_TempleRouteAlert alert) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAF8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8400).withValues(alpha: 0.45),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: const Color(0xFFC9A57A),
                      size: 22,
                    ),
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEAD7C4), width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      alert.templeImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: Color(0xFFE6D6C4)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  alert.templeName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF7A00),
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: const Color(0xFFC7A684),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.locationName,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFC7A684),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  alert.messageLine1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC1A17E),
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  alert.messageLine2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC1A17E),
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.messageLine3,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC1A17E),
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  alert.messageLine4,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC1A17E),
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'View Darshan',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Continue Yatra',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTravelerProfilePopup(_TravelerProfile traveler) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 34),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0CA9F), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A00).withValues(alpha: 0.28),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCFA87B), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      traveler.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: Color(0xFFE6D6C4)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  traveler.name,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF3B2A1B),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  traveler.distance,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF7A00),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7C9A4), width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TravelerStatItem(
                          icon: Icons.location_on_rounded,
                          primary: traveler.km,
                          secondary: 'KM',
                        ),
                      ),
                      Expanded(
                        child: _TravelerStatItem(
                          icon: Icons.directions_walk_rounded,
                          primary: traveler.steps,
                          secondary: 'Steps',
                        ),
                      ),
                      Expanded(
                        child: _TravelerStatItem(
                          icon: Icons.access_time_filled_rounded,
                          primary: traveler.days,
                          secondary: 'Days',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openSingleChat(traveler);
                    },
                    child: Text(
                      'Start a Chatting',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSingleChat(_TravelerProfile traveler) {
    final seedMessages = <YatraChatMessage>[
      YatraChatMessage(
        senderName: traveler.name,
        text: 'Har Har Mahadev.',
        time: '10:00 pm',
        isCurrentUser: false,
        avatarAsset: traveler.image,
      ),
      YatraChatMessage(
        senderName: 'You',
        text: 'Har Har Mahadev.',
        time: '10:00 pm',
        isCurrentUser: true,
        avatarAsset: traveler.image,
      ),
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => YatraChatScreen(
          chatType: YatraChatType.single,
          title: traveler.name,
          subtitle: 'Online',
          headerAvatarAsset: traveler.image,
          messages: seedMessages,
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(Widget child) {
    return AnimatedBuilder(
      animation: _runController,
      child: child,
      builder: (context, animatedChild) {
        if (!_isRunning) return animatedChild ?? const SizedBox.shrink();

        final phase = _runController.value;
        final scale = 1.03 + (0.02 * math.sin(phase * math.pi * 2));
        final dx = 4 * math.cos(phase * math.pi * 2);
        final dy = 8 * math.sin(phase * math.pi * 2);

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: animatedChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<Uint8List?>(
              future: _backgroundBytesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Container(color: const Color(0xFF1A1A1A));
                }

                final bytes = snapshot.data;
                if (bytes != null) {
                  return _buildAnimatedBackground(
                    Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  );
                }

                // Fallback to regular SVG rendering if no embedded image is found.
                return _buildAnimatedBackground(
                  SvgPicture.asset(
                    _routeBackgroundSvg,
                    fit: BoxFit.cover,
                    placeholderBuilder: (context) => Container(
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
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
                  ),
                  if (!widget.isFromCreateGroup) ...[
                    const SizedBox(height: 18),
                    _LiveSanghaCard(),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TRAVELERS ON YOUR ROUTE',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TravelerStrip(
                      onTravelerTap: _showTravelerProfilePopup,
                    ),
                  ] else ...[
                    const Spacer(),
                    _TotalGroupProgressCard(
                      progressText: '14%',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const IndividualProgressScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRunning
                                  ? const Color(0xFFD12B2B)
                                  : const Color(0xFFB8B8B8),
                              disabledBackgroundColor: const Color(0xFFB8B8B8),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isRunning ? _stopRun : null,
                            child: Text(
                              'Stop',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRunning
                                  ? const Color(0xFFB8B8B8)
                                  : const Color(0xFF2E8A3A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _startRun,
                            child: Text(
                              'Start',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalGroupProgressCard extends StatelessWidget {
  const _TotalGroupProgressCard({
    required this.progressText,
    required this.onTap,
  });

  final String progressText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0C5A3), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, color: Color(0xFFC8A882), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total Group Progress',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC8A882),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                progressText,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFC08E4C),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(AppIcons.steps, width: 18, height: 18, colorFilter: const ColorFilter.mode(Color(0xFFE3C7A4), BlendMode.srcIn)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveSanghaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADCCF), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3DDE1A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE SANGHA',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF7A00),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFD7B792)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '1,240',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF5F5F5F),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Devotees Online',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFC8A882),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '42',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF5F5F5F),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Nearby',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFC8A882),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TravelerStrip extends StatelessWidget {
  const _TravelerStrip({required this.onTravelerTap});

  final ValueChanged<_TravelerProfile> onTravelerTap;

  @override
  Widget build(BuildContext context) {
    final travelers = <_TravelerProfile>[
      const _TravelerProfile(
        name: 'Arjun S.',
        distance: '0.4 km away',
        image: 'assets/images/deity_shiva.png',
        km: '336',
        steps: '99,000',
        days: '4.5',
      ),
      const _TravelerProfile(
        name: 'Priya M.',
        distance: '1.2 km away',
        image: 'assets/images/deity_krishna.png',
        km: '290',
        steps: '81,400',
        days: '5.2',
      ),
      const _TravelerProfile(
        name: 'Ravi P.',
        distance: '2.4 km away',
        image: 'assets/images/deity_ram.png',
        km: '264',
        steps: '76,850',
        days: '6.0',
      ),
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: travelers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final traveler = travelers[index];
          return GestureDetector(
            onTap: () => onTravelerTap(traveler),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B).withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(29),
                border: Border.all(color: const Color(0xFFC8A882), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF7A00), width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        traveler.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(color: Color(0xFF2A2A2A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        traveler.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        traveler.distance,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF9B20),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TravelerProfile {
  const _TravelerProfile({
    required this.name,
    required this.distance,
    required this.image,
    required this.km,
    required this.steps,
    required this.days,
  });

  final String name;
  final String distance;
  final String image;
  final String km;
  final String steps;
  final String days;
}

class _TravelerStatItem extends StatelessWidget {
  const _TravelerStatItem({
    required this.icon,
    required this.primary,
    required this.secondary,
  });

  final IconData icon;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFC79A65), size: 22),
        const SizedBox(height: 6),
        Text(
          primary,
          style: GoogleFonts.outfit(
            color: const Color(0xFF5A5146),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          secondary,
          style: GoogleFonts.outfit(
            color: const Color(0xFF7A7064),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _TempleRouteAlert {
  const _TempleRouteAlert({
    required this.templeName,
    required this.locationName,
    required this.templeImage,
    required this.messageLine1,
    required this.messageLine2,
    required this.messageLine3,
    required this.messageLine4,
  });

  final String templeName;
  final String locationName;
  final String templeImage;
  final String messageLine1;
  final String messageLine2;
  final String messageLine3;
  final String messageLine4;
}