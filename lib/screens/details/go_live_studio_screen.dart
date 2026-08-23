import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class GoLiveStudioScreen extends StatefulWidget {
  const GoLiveStudioScreen({super.key});

  @override
  State<GoLiveStudioScreen> createState() => _GoLiveStudioScreenState();
}

class _GoLiveStudioScreenState extends State<GoLiveStudioScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;

  bool _isLiveActive = false;
  int _viewerCount = 1855;
  int _liveLikes = 468;
  Timer? _viewerTimer;
  final TextEditingController _liveTitleController = TextEditingController(text: "Evening Sandhya Aarti & Bhajan 🙏");
  final List<String> _liveComments = [
    "Jai Shree Ram! 🙏🚩",
    "Har Har Mahadev! 🌸",
    "Radhe Radhe! ✨",
    "Greetings from Surat Mandal!",
    "Jai Jinendra 🙏",
    "Jay Somnath Mahadev ⛰️",
    "Beautiful Aarti Darshan ✨",
  ];

  @override
  void initState() {
    super.initState();
    _initRealCamera();
  }

  Future<void> _initRealCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _onNewCameraSelected(_cameras![_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription description) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    final CameraController cameraController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
    );
    _cameraController = cameraController;

    try {
      await cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing camera controller: $e");
    }
  }

  void _switchCamera() {
    if (_cameras != null && _cameras!.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      _onNewCameraSelected(_cameras![_selectedCameraIndex]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No additional camera found"), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  void dispose() {
    _viewerTimer?.cancel();
    _cameraController?.dispose();
    _liveTitleController.dispose();
    super.dispose();
  }

  void _startLiveStream() {
    setState(() => _isLiveActive = true);
    _viewerTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _viewerCount += (1 + (DateTime.now().second % 5));
          _liveLikes += (2 + (DateTime.now().second % 3));
        });
      }
    });
  }

  void _endLiveStream() {
    _viewerTimer?.cancel();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🔴 Live Stream Ended. Broadcast saved to Mandal Live History!"),
        backgroundColor: Color(0xFFD32F2F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // REAL DEVICE LIVE CAMERA PREVIEW FEED
          _isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : Container(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset("assets/images/somnath_hero.png", fit: BoxFit.cover),
                      Container(color: Colors.black45),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFFFF7700)),
                            const SizedBox(height: 14),
                            Text(
                              "Initializing Live Camera...",
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

          // OVERLAY GRADIENT TO KEEP BUTTONS & TEXT LEGIBLE
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // TOP BAR: LIVE BADGE, VIEWER COUNT, CAMERA TOGGLE, CLOSE
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                if (_isLiveActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text("LIVE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("LIVE CAMERA STUDIO", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),

                const SizedBox(width: 10),

                if (_isLiveActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text("$_viewerCount Viewers", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),

                const Spacer(),

                // FLIP CAMERA BUTTON (FRONT / BACK)
                IconButton(
                  icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 28),
                  onPressed: _switchCamera,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // PRE-START SETUP VIEW
          if (!_isLiveActive)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  TextField(
                    controller: _liveTitleController,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Add Live Stream Title...",
                      hintStyle: GoogleFonts.outfit(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.sensors_rounded, size: 26),
                      label: Text(
                        "START LIVE BROADCAST",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      onPressed: _startLiveStream,
                    ),
                  ),
                ],
              ),
            ),

          // LIVE ACTIVE OVERLAY
          if (_isLiveActive) ...[
            // FLOATING COMMENTS STREAM
            Positioned(
              bottom: 110,
              left: 16,
              right: 90,
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  reverse: true,
                  itemCount: _liveComments.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _liveComments[index],
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // RIGHT ACTION BUTTONS (LIKE & SHARE NATIVE)
            Positioned(
              right: 16,
              bottom: 120,
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 36),
                    onPressed: () {
                      setState(() => _liveLikes++);
                    },
                  ),
                  Text(
                    "$_liveLikes",
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 32),
                    onPressed: () {
                      Share.share(
                        "🔴 Join Shree Ram Yuvak Mandal LIVE Stream Broadcast on Bharat Pray!\n\n${_liveTitleController.text.trim()}\n\nWatch Live: https://bharatpray.app/live/stream_123",
                        subject: "Bharat Pray Live Broadcast",
                      );
                    },
                  ),
                  Text(
                    "Share",
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),

            // END LIVE BROADCAST BUTTON AT BOTTOM
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: _endLiveStream,
                  child: Text(
                    "END LIVE BROADCAST",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
