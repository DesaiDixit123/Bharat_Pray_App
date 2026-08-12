import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'live_darshan_screen.dart';

class LiveDarshanDashboardScreen extends StatefulWidget {
  const LiveDarshanDashboardScreen({super.key});

  @override
  State<LiveDarshanDashboardScreen> createState() => _LiveDarshanDashboardScreenState();
}

class _LiveDarshanDashboardScreenState extends State<LiveDarshanDashboardScreen> {
  int _activeSegment = 0; // 0 = Watch Live, 1 = Go Live
  String _token = '';
  List<dynamic> _apiDarshans = [];
  bool _isLoading = false;
  bool _isMandalLeader = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Premium fallback mock streams
  final List<Map<String, dynamic>> _mockStreams = [
    {
      '_id': 'mock_1',
      'name': 'Shree Somnath Mahadev Live Aarti',
      'temple': {'name': 'Somnath Temple, Gujarat'},
      'imageUrl': 'assets/images/somnath_temple.png',
      'viewers': '12.4K',
      'category': 'Shiva',
    },
    {
      '_id': 'mock_2',
      'name': 'Siddhivinayak Ganpati Evening Darshan',
      'temple': {'name': 'Siddhivinayak Temple, Mumbai'},
      'imageUrl': 'assets/images/utsav_card.png',
      'viewers': '8.2K',
      'category': 'Ganesha',
    },
    {
      '_id': 'mock_3',
      'name': 'Kashi Vishwanath Mangala Aarti',
      'temple': {'name': 'Kashi Vishwanath, Varanasi'},
      'imageUrl': 'assets/images/somnath_hero.png',
      'viewers': '5.9K',
      'category': 'Shiva',
    },
    {
      '_id': 'mock_4',
      'name': 'Dwarkadhish Temple Shringar Darshan',
      'temple': {'name': 'Dwarkadhish Temple, Gujarat'},
      'imageUrl': 'assets/images/new_year_card.png',
      'viewers': '15.1K',
      'category': 'Krishna',
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    if (mounted) {
      setState(() {
        _isMandalLeader = prefs.getBool('is_mandal_leader') ?? false;
      });
    }
    _fetchLiveStreams();
  }

  Future<void> _fetchLiveStreams() async {
    if (_token.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getDarshansList(token: _token, limit: 20);
      final docs = res['docs'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _apiDarshans = docs;
        });
      }
    } catch (e) {
      debugPrint("Error fetching API live streams: $e");
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
        // 1. Existing segment style tab selection at the top (with spacing removed)
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
          child: _activeSegment == 0
              ? _buildWatchLiveList()
              : _buildGoLiveSetup(),
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
    if (_isLoading && _apiDarshans.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7700)),
      );
    }
    final list = _apiDarshans.isNotEmpty ? _apiDarshans : _mockStreams;

    return RefreshIndicator(
      onRefresh: _fetchLiveStreams,
      color: const Color(0xFFFF7700),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final stream = list[index];
          final String name = stream['name'] ?? 'Live Darshan';
          final String temple = stream['temple']?['name'] ?? stream['temple_details']?['name'] ?? 'Temple';
          final String image = stream['imageUrl'] ?? 'assets/images/somnath_temple.png';
          final String viewers = stream['viewers']?.toString() ?? '2.1K';
          final String id = stream['_id']?.toString() ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveDarshanScreen(
                    darshanId: id,
                    templeName: temple,
                    imageUrl: image,
                  ),
                ),
              );
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
                                name,
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
                                temple,
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

  // ─── Go Live Stream Creation View ──────────────────────────────────────────

  Widget _buildGoLiveSetup() {
    if (!_isMandalLeader) {
      return _buildRestrictedGoLive();
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
              hintText: "e.g., Shree Ganesh Yuva Mandal, Ahmedabad",
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
              onPressed: () {
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

                // Push camera streaming view
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MockCameraStreamingScreen(
                      streamTitle: title,
                      location: location,
                    ),
                  ),
                );
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

  Widget _buildRestrictedGoLive() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Lock Icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEAD8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              color: Color(0xFFFF7700),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            "Mandal Leader Access Only",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            "Starting a live broadcast is restricted to authorized Mandal Leaders. Please register your mandal or contact the admin team for leader access.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),

          // Simulate leader role switch for easy local testing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Simulate Mandal Leader Role",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8E5A2A),
                  ),
                ),
                Switch(
                  value: _isMandalLeader,
                  activeThumbColor: const Color(0xFFFF7700),
                  onChanged: (val) {
                    setState(() {
                      _isMandalLeader = val;
                    });
                  },
                ),
              ],
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
  int _viewers = 12;
  int _likes = 4;
  final List<String> _comments = ["Har Har Mahadev! 🙏", "Jai Shree Ganesh", "Jai Mata Di! ✨"];
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
          _viewers += (3 + timer.tick % 5);
          _likes += (2 + timer.tick % 4);
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
          // 1. Mock Camera Feed Background (Representing camera recording Ganesha)
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
