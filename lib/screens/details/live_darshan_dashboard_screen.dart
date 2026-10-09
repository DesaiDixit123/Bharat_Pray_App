import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/utsav_service.dart';
import 'live_darshan_screen.dart';

class LiveDarshanDashboardScreen extends StatefulWidget {
  const LiveDarshanDashboardScreen({super.key});

  @override
  State<LiveDarshanDashboardScreen> createState() => _LiveDarshanDashboardScreenState();
}

class _LiveDarshanDashboardScreenState extends State<LiveDarshanDashboardScreen> {
  int _activeSegment = 0; // 0 = Watch Live, 1 = Go Live
  List<dynamic> _apiDarshans = [];
  bool _isLoading = false;
  bool _isMandalLeader = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final reg = await UtsavService.getMyMandalRegistration();
    final isRegActive = await UtsavService.isRegistrationActive(reg);
    final isApproved = reg != null &&
        (reg['status']?.toString().toLowerCase() == 'approved') &&
        isRegActive;
    if (mounted) {
      setState(() {
        _isMandalLeader = isApproved;
        if (!_isMandalLeader) {
          _activeSegment = 0;
        }
      });
    }
    _fetchLiveStreams();
  }

  Future<void> _fetchLiveStreams() async {
    setState(() => _isLoading = true);
    try {
      final list = await UtsavService.getLiveMandals();
      if (mounted) {
        setState(() {
          _apiDarshans = list;
        });
      }
    } catch (e) {
      debugPrint("Error fetching mandal live streams: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show Go Live tab ONLY if mandal profile is approved
        if (_isMandalLeader)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  _buildSegmentTab("Live Darshans", 0),
                  _buildSegmentTab("Go Live", 1),
                ],
              ),
            ),
          ),

        // 2. Tab Contents
        Expanded(
          child: (_isMandalLeader && _activeSegment == 1)
              ? _buildGoLiveSetup()
              : _buildWatchLiveList(),
        ),
      ],
    );
  }

  Widget _buildSegmentTab(String label, int stateVal) {
    final active = _activeSegment == stateVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeSegment = stateVal),
        child: Container(
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF7700) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF7700).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: active ? Colors.white : const Color(0xFF8E5A2A),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Watch Live Stream List View ───────────────────────────────────────────

  Widget _buildWatchLiveList() {
    final bottomInset = 90.0 + MediaQuery.of(context).padding.bottom;

    if (_isLoading && _apiDarshans.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7700)),
        ),
      );
    }

    if (_apiDarshans.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset, left: 28.0, right: 28.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEAD8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.25), width: 2),
                        ),
                        child: const Icon(
                          Icons.sensors_off_rounded,
                          color: Color(0xFFFF7700),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No Mandal Live Right Now",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Live darshan streams will be available when an active festival begins (Maha Navratri starts on 11 Oct 2026). Registered mandals can broadcast live darshans.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                          height: 1.45,
                        ),
                      ),
                      if (_isMandalLeader) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7700),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.videocam_rounded),
                            label: Text(
                              "Go Live Now",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              setState(() => _activeSegment = 1);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    final list = _apiDarshans;

    return RefreshIndicator(
      onRefresh: _fetchLiveStreams,
      color: const Color(0xFFFF7700),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final stream = list[index];
          final String mandal = stream['mandalName'] ?? stream['name'] ?? 'Mandal Darshan';
          final String title = stream['name'] ?? 'Live Aarti & Darshan';
          final String location = stream['location'] ?? 'Gujarat, India';
          final String image = stream['imageUrl'] ?? 'assets/images/somnath_temple.png';
          final String viewers = (stream['viewersCount'] ?? stream['viewers'] ?? '1').toString();
          final String id = stream['_id']?.toString() ?? '';

          return GestureDetector(
            onTap: () async {
              if (id.isNotEmpty) {
                await UtsavService.joinLiveStream(id);
              }
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveDarshanScreen(
                    darshanId: id,
                    templeName: mandal,
                    imageUrl: image,
                  ),
                ),
              );
              if (id.isNotEmpty) {
                await UtsavService.leaveLiveStream(id);
              }
              if (mounted) {
                _fetchLiveStreams();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3E4D6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail Stack
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.asset(
                          image,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                           errorBuilder: (_, _, _) => Container(
                            height: 160,
                            color: const Color(0xFFFFF1E5),
                            child: const Icon(Icons.image_rounded, color: Color(0xFFB56E28), size: 40),
                          ),
                        ),
                      ),

                      // Flashing LIVE Badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.white, size: 8),
                              const SizedBox(width: 4),
                              Text(
                                "LIVE",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Viewer Count Badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                viewers,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Info details
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mandal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E2A36),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "$title • $location",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFFC8A882),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoLiveSetup() {
    if (!_isMandalLeader) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sensors_rounded, color: Color(0xFFFF7700), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Broadcast live virtual darshans directly from your temple or mandal to all devotees.",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stream Title input
          Text(
            "Live Stream Title",
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
            decoration: InputDecoration(
              hintText: "e.g., Evening Aarti live stream",
              hintStyle: GoogleFonts.outfit(color: const Color(0xFFC8A882).withValues(alpha: 0.6)),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC8A882), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category/Temple Location input
          Text(
            "Temple / Mandal Location Name",
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categoryController,
            style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
            decoration: InputDecoration(
              hintText: "e.g., Navdurga Garba Mandal, Vadodara",
              hintStyle: GoogleFonts.outfit(color: const Color(0xFFC8A882).withValues(alpha: 0.6)),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC8A882), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Go Live Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final title = _titleController.text.trim();
                final location = _categoryController.text.trim();
                if (title.isEmpty || location.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Please fill out both title and location to go live!",
                        style: GoogleFonts.outfit(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF2E2A36),
                    ),
                  );
                  return;
                }

                // Register and start mandal live broadcast
                await UtsavService.goLiveMandal(
                  mandalName: location,
                  streamTitle: title,
                  location: location,
                );

                if (mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MockCameraStreamingScreen(
                        streamTitle: title,
                        location: location,
                      ),
                    ),
                  );
                  _fetchLiveStreams();
                }
              },
              child: Text(
                'Start Live Darshan',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mock Camera Live Streaming Broadcast Screen ────────────────────────────

class MockCameraStreamingScreen extends StatefulWidget {
  final String streamTitle;
  final String location;

  const MockCameraStreamingScreen({
    super.key,
    required this.streamTitle,
    required this.location,
  });

  @override
  State<MockCameraStreamingScreen> createState() => _MockCameraStreamingScreenState();
}

class _MockCameraStreamingScreenState extends State<MockCameraStreamingScreen> {
  int _viewers = 1;
  int _likes = 0;
  final List<String> _comments = ["Har Har Mahadev! 🙏", "Jai Mata Di! ✨", "Shubh Navratri! 🪔"];
  final List<String> _userNames = ["Rajesh Kumar", "Priya Sharma", "Aarav Gupta"];
  
  Timer? _statsTimer;
  Timer? _commentsTimer;

  final List<Map<String, String>> _liveComments = [];

  @override
  void initState() {
    super.initState();
    // Simulate active live broadcast stats growth
    _statsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _viewers += (1 + (timer.tick % 2).toInt());
          _likes += (1 + (timer.tick % 3).toInt());
        });
      }
    });

    // Simulate incoming chat messages
    _commentsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          final nextComment = _comments[timer.tick % _comments.length];
          final nextUser = _userNames[timer.tick % _userNames.length];
          _liveComments.insert(0, {"user": nextUser, "msg": nextComment});
          if (_liveComments.length > 20) {
            _liveComments.removeLast();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _commentsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Feed Background
          Image.asset(
            'assets/images/new_year_card.png',
            fit: BoxFit.cover,
          ),
          
          // Camera grid lines overlay
          Container(
            color: Colors.black.withValues(alpha: 0.15),
            child: CustomPaint(
              painter: CameraGridPainter(),
            ),
          ),

          // 2. Top Banner Overlay (Flashing LIVE, title, viewers count)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Red LIVE indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        "LIVE",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Viewers
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "$_viewers",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Close Broadcast Button
                GestureDetector(
                  onTap: () => _endBroadcastDialog(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Title & Location
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.streamTitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 4)
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.location,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                    shadows: [
                      const Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 4)
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Comments overlay & end stream buttons
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scrollable Live Comments Box
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _liveComments.length,
                    itemBuilder: (context, index) {
                      final item = _liveComments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${item['user']}: ",
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF7700),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item['msg'] ?? '',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Interaction Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Likes indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "$_likes Likes",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // End Stream
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => _endBroadcastDialog(context),
                      child: Text(
                        "End Broadcast",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
    );
  }

  void _endBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "End Live Darshan?",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          content: Text(
            "Are you sure you want to stop this live virtual darshans broadcast?",
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.outfit(color: const Color(0xFFC8A882), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Exit dialog, then exit broadcast
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Live stream broadcasted successfully! Total Likes: $_likes",
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF2E2A36),
                  ),
                );
              },
              child: Text(
                "End Stream",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Camera Grid Painter (Faux grid lines for camera preview feel) ───────────

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw thirds grid lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
