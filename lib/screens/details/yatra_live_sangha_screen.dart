import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' show asin, cos, sin, sqrt, pi;
import 'add_temple_on_route_screen.dart';
import 'individual_progress_screen.dart';
import 'yatra_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../controllers/live_yatra_controller.dart';
import '../../models/live_yatra_models.dart';
import 'package:bharat_pray/screens/details/app_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';

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
  final List<dynamic>? routeTemples;

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
    this.routeTemples,
  });

  @override
  State<YatraLiveSanghaScreen> createState() => _YatraLiveSanghaScreenState();
}

enum YatraVideoMode { walking, templeReaching, templeEntrance }

class _YatraLiveSanghaScreenState extends State<YatraLiveSanghaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _runController;
  bool _isRunning = false;
  bool _hasShownTempleAlertInRun = false;
  Timer? _liveWalkingTimer;
  Timer? _loopSeekTimer;

  // GPS proximity
  StreamSubscription<Position>? _locationSubscription;
  final Set<String> _templeAlertShownFor = {}; // track which temples already triggered

  // 3 video controllers
  VideoPlayerController? _walkingVideoControllerA;     // Continue_walking.mp4 (Ping-Pong A)
  VideoPlayerController? _walkingVideoControllerB;     // Continue_walking.mp4 (Ping-Pong B)
  bool _useWalkingA = true; // Tracks which walking controller is active

  VideoPlayerController? _templeReachingVideoController; // Temple_reaching.mp4
  VideoPlayerController? _templeEntranceVideoController; // Temple_entrarance.mp4

  YatraVideoMode _currentVideoMode = YatraVideoMode.walking;
  
  // Live stats tracking
  double _liveDistanceKm = 0.0;
  final int _onlineDevotees = 1;

  static const String _backArrowSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#FFFFFF"/>
</svg>''';

  final LiveYatraController _liveController = LiveYatraController();

  @override
  void initState() {
    super.initState();
    _liveController.setInitialParams(
      journeyId: widget.journeyId,
      title: widget.title,
      totalDistanceStr: widget.distance,
    );
    _liveController.addListener(_onLiveControllerChanged);

    _runController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Video 1A & 1B: New_walking.mp4 — double buffered for 0-second seamless looping
    _walkingVideoControllerA = VideoPlayerController.asset(
      'assets/images/New_walking.mp4',
    )..initialize().then((_) {
        if (mounted) {
          _walkingVideoControllerA!.setLooping(false);
          _walkingVideoControllerA!.addListener(_onWalkingVideoPositionChanged);
          setState(() {});
        }
      });

    _walkingVideoControllerB = VideoPlayerController.asset(
      'assets/images/New_walking.mp4',
    )..initialize().then((_) {
        if (mounted) {
          _walkingVideoControllerB!.setLooping(false);
          _walkingVideoControllerB!.addListener(_onWalkingVideoPositionChanged);
          setState(() {});
        }
      });

    // Video 2: Temple_reaching.mp4 — plays once then shows popup
    _templeReachingVideoController = VideoPlayerController.asset(
      'assets/images/Temple_reaching.mp4',
    )..initialize().then((_) {
        if (mounted) {
          _templeReachingVideoController!.setLooping(false);
          _templeReachingVideoController!.addListener(_onTempleReachingStatusChanged);
          _templeReachingVideoController!.addListener(() {
            if (mounted) setState(() {});
          });
          setState(() {});
        }
      });

    // Video 3: Temple_entrarance.mp4 — plays when user taps View Darshan
    _templeEntranceVideoController = VideoPlayerController.asset(
      'assets/images/Temple_entrarance.mp4',
    )..initialize().then((_) {
        if (mounted) {
          _templeEntranceVideoController!.setLooping(false);
          _templeEntranceVideoController!.addListener(_onTempleEntranceStatusChanged);
          _templeEntranceVideoController!.addListener(() {
            if (mounted) setState(() {});
          });
          setState(() {});
        }
      });
  }

  // ─── Seamless loop: Ping-Pong technique for 0-second gap
  // When active controller hits the end, we instantly swap to the standby controller
  // which is already queued at 1s, creating a perfect seamless loop.
  void _onWalkingVideoPositionChanged() {
    if (_currentVideoMode != YatraVideoMode.walking) return;
    
    final activeCtrl = _useWalkingA ? _walkingVideoControllerA : _walkingVideoControllerB;
    final standbyCtrl = _useWalkingA ? _walkingVideoControllerB : _walkingVideoControllerA;
    
    if (activeCtrl == null || !activeCtrl.value.isInitialized) return;
    if (standbyCtrl == null || !standbyCtrl.value.isInitialized) return;
    
    final pos = activeCtrl.value.position;
    final loopEnd = activeCtrl.value.duration.inMilliseconds < 9000
        ? activeCtrl.value.duration.inMilliseconds
        : 9000;
        
    // Start the 2-second crossfade exactly 2000ms before the end
    if (pos.inMilliseconds >= loopEnd - 2000) {
      // 1. Play the standby video (already pre-buffered at 1s)
      standbyCtrl.play();
      
      // 2. Swap UI to trigger the 2-second AnimatedOpacity crossfade
      setState(() {
        _useWalkingA = !_useWalkingA;
      });
      
      // 3. Let the old video keep playing during the 2-second fade.
      // After it's completely hidden, pause and rewind it for the NEXT loop.
      Future.delayed(const Duration(milliseconds: 2050), () {
        if (mounted) {
          activeCtrl.pause();
          activeCtrl.seekTo(const Duration(seconds: 1));
        }
      });
    }
  }

  void _onTempleReachingStatusChanged() {
    if (_currentVideoMode != YatraVideoMode.templeReaching) return;
    final ctrl = _templeReachingVideoController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final value = ctrl.value;
    if (!value.isPlaying &&
        value.position.inMilliseconds >= value.duration.inMilliseconds - 200) {
      // Temple reaching video finished → show the choice popup
      _showTempleChoicePopup();
    }
  }

  void _onTempleEntranceStatusChanged() {
    if (_currentVideoMode != YatraVideoMode.templeEntrance) return;
    final ctrl = _templeEntranceVideoController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final value = ctrl.value;
    if (!value.isPlaying &&
        value.position.inMilliseconds >= value.duration.inMilliseconds - 200) {
      // Darshan video finished → loop back to walking
      _switchToWalkingVideo();
    }
  }

  /// Switch back to the seamless-looping walking video (1s–end window).
  void _switchToWalkingVideo() {
    _templeReachingVideoController?.pause();
    _templeEntranceVideoController?.pause();
    setState(() {
      _currentVideoMode = YatraVideoMode.walking;
    });
    
    final activeCtrl = _useWalkingA ? _walkingVideoControllerA : _walkingVideoControllerB;
    final standbyCtrl = _useWalkingA ? _walkingVideoControllerB : _walkingVideoControllerA;
    
    if (_isRunning) {
      standbyCtrl?.seekTo(const Duration(seconds: 1)).then((_) => standbyCtrl.pause());
      activeCtrl?.seekTo(const Duration(seconds: 1)).then((_) => activeCtrl.play());
    }
  }

  /// Play Temple_reaching.mp4 once, then show the choice popup.
  void _switchToTempleReachingVideo() {
    _walkingVideoControllerA?.pause();
    _walkingVideoControllerB?.pause();
    setState(() {
      _currentVideoMode = YatraVideoMode.templeReaching;
    });
    final ctrl = _templeReachingVideoController;
    if (ctrl != null && ctrl.value.isInitialized) {
      ctrl.seekTo(Duration.zero).then((_) => ctrl.play());
    }
  }

  /// Play Temple_entrarance.mp4 (View Darshan path).
  void _switchToTempleEntranceVideo() {
    _templeReachingVideoController?.pause();
    setState(() {
      _currentVideoMode = YatraVideoMode.templeEntrance;
    });
    final ctrl = _templeEntranceVideoController;
    if (ctrl != null && ctrl.value.isInitialized) {
      ctrl.seekTo(Duration.zero).then((_) => ctrl.play());
    }
  }

  /// The popup that appears when Temple_reaching.mp4 finishes.
  void _showTempleChoicePopup() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAF8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8400).withOpacity(0.45),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Temple Nearby!',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF7A00),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A temple is approaching on your left.\nWhat would you like to do?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC1A17E),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
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
                      Navigator.of(ctx).pop();
                      _switchToTempleEntranceVideo();
                    },
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
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A00),
                      side: const BorderSide(color: Color(0xFFFF8A00), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _switchToWalkingVideo();
                    },
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

  void _onLiveControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _liveController.removeListener(_onLiveControllerChanged);
    _liveController.dispose();
    _liveWalkingTimer?.cancel();
    _loopSeekTimer?.cancel();
    _locationSubscription?.cancel();
    _runController.dispose();
    _walkingVideoControllerA?.removeListener(_onWalkingVideoPositionChanged);
    _walkingVideoControllerB?.removeListener(_onWalkingVideoPositionChanged);
    _templeReachingVideoController?.removeListener(_onTempleReachingStatusChanged);
    _templeEntranceVideoController?.removeListener(_onTempleEntranceStatusChanged);
    _walkingVideoControllerA?.dispose();
    _walkingVideoControllerB?.dispose();
    _templeReachingVideoController?.dispose();
    _templeEntranceVideoController?.dispose();
    super.dispose();
  }

  void _startRun() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _currentVideoMode = YatraVideoMode.walking;
    });
    _runController.repeat();

    // Start live tracking via LiveYatraController
    _liveController.startTracking();

    // Queue standby controller at 1s, and play active controller at 1s
    final activeCtrl = _useWalkingA ? _walkingVideoControllerA : _walkingVideoControllerB;
    final standbyCtrl = _useWalkingA ? _walkingVideoControllerB : _walkingVideoControllerA;
    
    if (activeCtrl != null && activeCtrl.value.isInitialized &&
        standbyCtrl != null && standbyCtrl.value.isInitialized) {
      standbyCtrl.seekTo(const Duration(seconds: 1)).then((_) => standbyCtrl.pause());
      activeCtrl.seekTo(const Duration(seconds: 1)).then((_) => activeCtrl.play());
    } else {
      activeCtrl?.initialize().then((_) {
        if (mounted && _isRunning) {
          standbyCtrl?.seekTo(const Duration(seconds: 1)).then((_) => standbyCtrl.pause());
          activeCtrl.seekTo(const Duration(seconds: 1)).then((_) => activeCtrl.play());
          setState(() {});
        }
      });
    }

    _startLocationTracking();
    _resumeBackendJourney();
  }

  void _resumeBackendJourney() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty && widget.journeyId.isNotEmpty) {
        await ApiService.resumeJourney(token, widget.journeyId);
      }
    } catch (e) {
      debugPrint('Failed to resume journey on backend: $e');
    }
  }

  void _confirmAndStopRun() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5EC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Stop Live Tracking?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF3B2A1B)),
        ),
        content: Text(
          'Are you sure you want to stop live tracking for this Yatra?',
          style: GoogleFonts.outfit(color: const Color(0xFF5A5146)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFFC8A882))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD12B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _stopRun();
            },
            child: Text('Stop', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _stopRun({bool isComplete = false}) {
    if (!_isRunning) return;

    _liveController.stopTracking();
    _liveWalkingTimer?.cancel();
    _loopSeekTimer?.cancel();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _runController.stop();
    _runController.reset();

    _walkingVideoControllerA?.pause();
    _walkingVideoControllerB?.pause();
    _templeReachingVideoController?.pause();
    _templeEntranceVideoController?.pause();

    setState(() {
      _isRunning = false;
      _hasShownTempleAlertInRun = false;
    });

    _stopBackendJourney();

    if (isComplete && mounted && widget.completedScreen != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget.completedScreen!,
        ),
      );
    }
  }

  void _stopBackendJourney() async {
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

  void _scheduleTempleAlertPreview() {
    if (_hasShownTempleAlertInRun) return;
    _hasShownTempleAlertInRun = true;

    // After a short walking period, switch to Temple_reaching video.
    // When that video ends, _onTempleReachingStatusChanged fires the choice popup.
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (!mounted || !_isRunning) return;
      _switchToTempleReachingVideo();
    });
  }

  // ─── Real GPS Proximity Tracking ─────────────────────────────────────────
  // Requests location permission, then listens to device position updates.
  // When the user comes within 500 m of any selected temple that has lat/lng,
  // we switch to Temple_reaching.mp4 (only once per temple per run).
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled – skipping proximity tracking.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied.');
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // metres – receive update every 20 m movement
    );

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(_onLocationUpdate);
  }

  void _onLocationUpdate(Position position) {
    if (!_isRunning || _currentVideoMode != YatraVideoMode.walking) return;

    // Check every temple on the route that has GPS coordinates.
    for (final temple in widget.selectedTemples) {
      if (temple.lat == null || temple.lng == null) continue;

      final templeKey = '${temple.name}|${temple.lat}|${temple.lng}';
      if (_templeAlertShownFor.contains(templeKey)) continue; // already triggered

      final distanceMeters = _haversineDistanceMeters(
        position.latitude,
        position.longitude,
        temple.lat!,
        temple.lng!,
      );

      debugPrint('Distance to ${temple.name}: ${distanceMeters.toStringAsFixed(0)} m');

      if (distanceMeters <= 500) {
        // User is within 500 m – mark as shown and play the reaching video.
        _templeAlertShownFor.add(templeKey);
        _switchToTempleReachingVideo();
        break; // handle one temple at a time
      }
    }
  }

  /// Haversine formula – returns distance in metres between two lat/lng points.
  double _haversineDistanceMeters(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadiusMeters = 6371000;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * asin(sqrt(a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;



  void _showTravelerProfilePopup(_TravelerProfile traveler) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0CA9F), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A00).withOpacity(0.28),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCFA87B), width: 2),
                      ),
                      child: ClipOval(
                        child: traveler.image.startsWith('http')
                            ? Image.network(
                                traveler.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const ColoredBox(color: Color(0xFFE6D6C4)),
                              )
                            : Image.asset(
                                traveler.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const ColoredBox(color: Color(0xFFE6D6C4)),
                              ),
                      ),
                    ),
                    if (traveler.isOnline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8A3A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          'Online',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
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
                          secondary: 'KM Completed',
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
                if (traveler.kmRemaining.isNotEmpty && traveler.kmRemaining != '0' && traveler.kmRemaining != '0.0') ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag_rounded, color: Color(0xFFFF7A00), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${traveler.kmRemaining} KM Remaining to Destination',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF7A00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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


  Widget _buildVideoLayer(VideoPlayerController? ctrl, {required bool isVisible, bool alwaysOpaque = false}) {
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return AnimatedOpacity(
      opacity: alwaysOpaque ? 1.0 : (isVisible ? 1.0 : 0.0),
      duration: const Duration(seconds: 2), // 2-second smooth transition
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.size.width,
            height: ctrl.value.size.height,
            child: VideoPlayer(ctrl),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The FULL screen Photorealistic Video Layers with Crossfading!
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Render the loading indicator at the bottom if nothing is ready
                const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
                
                if (_currentVideoMode == YatraVideoMode.walking) ...[
                  // Bottom layer: Video B is ALWAYS opaque. This prevents any black background 
                  // from showing through during the crossfade.
                  _buildVideoLayer(_walkingVideoControllerB, isVisible: true, alwaysOpaque: true),
                  
                  // Top layer: Video A fades in and out over Video B.
                  // When A fades out (1 -> 0), B is revealed underneath flawlessly.
                  // When A fades in (0 -> 1), it covers B flawlessly.
                  _buildVideoLayer(_walkingVideoControllerA, isVisible: _useWalkingA, alwaysOpaque: false),
                ],
                
                if (_currentVideoMode == YatraVideoMode.templeReaching)
                  _buildVideoLayer(_templeReachingVideoController, isVisible: true, alwaysOpaque: true),
                  
                if (_currentVideoMode == YatraVideoMode.templeEntrance)
                  _buildVideoLayer(_templeEntranceVideoController, isVisible: true, alwaysOpaque: true),
              ],
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
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.45), width: 1),
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
                    _LiveSanghaCard(
                      onlineDevotees: _liveController.state.activeDevoteesCount,
                      kmCompleted: _liveController.state.kmCompleted > 0 ? _liveController.state.kmCompleted : _liveDistanceKm,
                      kmRemaining: _liveController.state.kmRemaining,
                      totalDistanceKm: _liveController.state.totalDistanceKm,
                      progressPercent: _liveController.state.progressPercent,
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TRAVELERS ON YOUR ROUTE',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TravelerStrip(
                      liveDevotees: _liveController.state.nearbyDevotees,
                      onTravelerTap: _showTravelerProfilePopup,
                    ),
                  ] else ...[
                    const Spacer(),
                    _TotalGroupProgressCard(
                      progressText: '${_liveController.state.progressPercent.toInt()}%',
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
                            onPressed: _isRunning ? _confirmAndStopRun : null,
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
            color: Colors.white.withOpacity(0.95),
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
  final int onlineDevotees;
  final double kmCompleted;
  final double kmRemaining;
  final double totalDistanceKm;
  final double progressPercent;

  const _LiveSanghaCard({
    required this.onlineDevotees,
    required this.kmCompleted,
    required this.kmRemaining,
    required this.totalDistanceKm,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADCCF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${progressPercent.toStringAsFixed(1)}% Completed',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF7A00),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progressPercent / 100.0).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFFFEAD5),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$onlineDevotees',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF3B2A1B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Devotees',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9E846B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE5D5C5)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${kmCompleted.toStringAsFixed(2)} KM',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E8A3A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Completed',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9E846B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE5D5C5)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${kmRemaining.toStringAsFixed(2)} KM',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFD12B2B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Remaining',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9E846B),
                        fontSize: 11,
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
  const _TravelerStrip({
    required this.onTravelerTap,
    this.liveDevotees = const [],
  });

  final ValueChanged<_TravelerProfile> onTravelerTap;
  final List<LiveDevoteeModel> liveDevotees;

  @override
  Widget build(BuildContext context) {
    if (liveDevotees.isEmpty) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B).withOpacity(0.65),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFC8A882).withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, color: Color(0xFFFF9B20), size: 18),
            const SizedBox(width: 8),
            Text(
              'No other pilgrims currently live on this route',
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final travelers = liveDevotees.map((d) {
      return _TravelerProfile(
        name: d.name,
        distance: d.distanceText,
        image: d.profilePic.isNotEmpty ? d.profilePic : 'assets/images/deity_shiva.png',
        km: d.kmCompleted.toStringAsFixed(1),
        steps: d.steps.toString(),
        days: d.days,
        kmRemaining: d.kmRemaining.toStringAsFixed(1),
        isOnline: d.isOnline,
      );
    }).toList();

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
                color: const Color(0xFF1B1B1B).withOpacity(0.78),
                borderRadius: BorderRadius.circular(29),
                border: Border.all(color: const Color(0xFFC8A882), width: 1),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF7A00), width: 1),
                        ),
                        child: ClipOval(
                          child: traveler.image.startsWith('http')
                              ? Image.network(
                                  traveler.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Color(0xFF2A2A2A)),
                                )
                              : Image.asset(
                                  traveler.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Color(0xFF2A2A2A)),
                                ),
                        ),
                      ),
                      if (traveler.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3DDE1A),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1B1B1B), width: 1.5),
                            ),
                          ),
                        ),
                    ],
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
    this.kmRemaining = '0',
    this.isOnline = true,
  });

  final String name;
  final String distance;
  final String image;
  final String km;
  final String steps;
  final String days;
  final String kmRemaining;
  final bool isOnline;
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