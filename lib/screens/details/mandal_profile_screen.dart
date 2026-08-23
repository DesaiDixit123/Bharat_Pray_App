import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'create_mandal_post_screen.dart';
import 'create_mandal_reel_screen.dart';
import 'go_live_studio_screen.dart';

enum MandalStatus { approved, pending, notRegistered }

Widget buildSmartImage(String? path, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
  if (path == null || path.isEmpty) {
    return Container(
      color: const Color(0xFFFAF6F0),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.grey, size: 40),
      ),
    );
  }
  if (path.startsWith('assets/')) {
    return Image.asset(path, fit: fit, width: width, height: height);
  } else {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: fit, width: width, height: height);
    }
    return Image.asset('assets/images/ram_bhajan.png', fit: fit, width: width, height: height);
  }
}

class PostItem {
  final String id;
  final String imageUrl;
  final String caption;
  final String festivalName;
  final String location;
  final String timeAgo;
  int likes;
  bool isLiked;
  bool isSaved;

  PostItem({
    required this.id,
    required this.imageUrl,
    required this.caption,
    this.festivalName = "Somnath Maha Shivratri Mahotsav",
    this.location = "Ahmedabad, Gujarat",
    required this.timeAgo,
    required this.likes,
    this.isLiked = false,
    this.isSaved = false,
  });
}

class ReelItem {
  final String id;
  final String thumbnailUrl;
  final String title;
  final String audioTrack;
  final String festivalName;
  final String views;
  int likes;
  bool isLiked;
  bool isSaved;

  ReelItem({
    required this.id,
    required this.thumbnailUrl,
    required this.title,
    required this.audioTrack,
    this.festivalName = "Somnath Maha Shivratri Mahotsav",
    required this.views,
    required this.likes,
    this.isLiked = false,
    this.isSaved = false,
  });
}

class LiveEventItem {
  final String id;
  final String title;
  final String status; // "Upcoming" or "Recorded"
  final String dateOrTime;
  final String viewers;
  final String thumbnailUrl;

  LiveEventItem({
    required this.id,
    required this.title,
    required this.status,
    required this.dateOrTime,
    required this.viewers,
    required this.thumbnailUrl,
  });
}

class MandalProfileScreen extends StatefulWidget {
  final String? mandalName;
  final String? location;
  final String? avatarUrl;
  final String? coverUrl;
  final bool isOwnProfile;

  const MandalProfileScreen({
    super.key,
    this.mandalName,
    this.location,
    this.avatarUrl,
    this.coverUrl,
    this.isOwnProfile = false,
  });

  @override
  State<MandalProfileScreen> createState() => _MandalProfileScreenState();
}

class _MandalProfileScreenState extends State<MandalProfileScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Posts, 1: Reels, 2: Live, 3: Info
  bool _isFollowing = false;

  // Sample Mandal Details
  String _mandalName = "Shree Ram Yuvak Mandal 🚩";
  String _mandalTag = "Official Spiritual Organisation • Ahmedabad";
  String _regNumber = "REG/2024/GJT/88492";
  String _bio = "🛕 Dedicated to Prabhu Shree Ram Bhakti & Seva. 🌸 Morning & Evening Live Aarti, Annakshetra, Yatra & Youth Satsang.";

  // Mock Posts Data
  final List<PostItem> _posts = [
    PostItem(
      id: "1",
      imageUrl: "assets/images/somnath_hero.png",
      caption: "🌸 Daily Morning Maha Aarti at Mandal Premises. Har Har Mahadev! 🙏✨",
      festivalName: "🛕 Somnath Maha Shivratri Mahotsav",
      location: "Somnath Temple, Gujarat",
      timeAgo: "2 hours ago",
      likes: 1240,
    ),
    PostItem(
      id: "2",
      imageUrl: "assets/images/dhanterash.png",
      caption: "🛕 Deepotsav & Grand Aarti Celebrations with all Mandal Devotees! 🪔",
      festivalName: "🪔 Diwali Deepotsav Mahotsav",
      location: "Ahmedabad, Gujarat",
      timeAgo: "1 day ago",
      likes: 2150,
    ),
    PostItem(
      id: "3",
      imageUrl: "assets/images/krishna.png",
      caption: "✨ Shri Krishna Janmashtami Mahotsav Bhajan Sandhya highlights. Jai Shri Krishna! 🚩",
      festivalName: "✨ Shri Krishna Janmashtami Utsav",
      location: "Dwarka, Gujarat",
      timeAgo: "3 days ago",
      likes: 3410,
    ),
    PostItem(
      id: "4",
      imageUrl: "assets/images/ram_bhajan.png",
      caption: "🎶 Grand Ram Dhun & Sunderkand Path organised by our Mandal Youth Team! 🙏",
      festivalName: "🚩 Shree Ram Navami Mahotsav",
      location: "Surat, Gujarat",
      timeAgo: "5 days ago",
      likes: 980,
    ),
    PostItem(
      id: "5",
      imageUrl: "assets/images/diwali.png",
      caption: "🪔 Mandal Annakshetra Seva - Distributing Prasadam to 1000+ devotees. 🌸",
      festivalName: "🪔 Diwali Deepotsav Mahotsav",
      location: "Rajkot, Gujarat",
      timeAgo: "1 week ago",
      likes: 1890,
    ),
  ];

  // Mock Reels Data
  final List<ReelItem> _reels = [
    ReelItem(
      id: "r1",
      thumbnailUrl: "assets/images/ram_bhajan.png",
      title: "🔥 Ram Siya Ram Divine Aarti Clips",
      audioTrack: "Ram Siya Ram • Original Mandal Audio",
      festivalName: "🚩 Shree Ram Navami Mahotsav",
      views: "45.2k",
      likes: 5820,
    ),
    ReelItem(
      id: "r2",
      thumbnailUrl: "assets/images/somnath_hero.png",
      title: "🛕 Somnath Live Darshan & Damru Dhun",
      audioTrack: "Shiv Tandav Stotram • Sacred Beats",
      festivalName: "🛕 Somnath Maha Shivratri Mahotsav",
      views: "89.1k",
      likes: 12400,
    ),
    ReelItem(
      id: "r3",
      thumbnailUrl: "assets/images/krishna.png",
      title: "🌸 Flute Meditation by Mandal Gurukul",
      audioTrack: "Krishna Bansuri Dhun • Mandal Studio",
      festivalName: "✨ Shri Krishna Janmashtami Utsav",
      views: "28.6k",
      likes: 3100,
    ),
    ReelItem(
      id: "r4",
      thumbnailUrl: "assets/images/dhanterash.png",
      title: "✨ 108 Diya Deepotsav Grand View",
      audioTrack: "Deepawali Sacred Chants",
      festivalName: "🪔 Diwali Deepotsav Mahotsav",
      views: "64.0k",
      likes: 7200,
    ),
  ];

  // Mock Live Events Data
  final List<LiveEventItem> _liveEvents = [
    LiveEventItem(
      id: "l1",
      title: "🔴 Morning Live Mangala Aarti",
      status: "Recorded",
      dateOrTime: "Today • 6:30 AM",
      viewers: "1,840 Viewers",
      thumbnailUrl: "assets/images/somnath_hero.png",
    ),
    LiveEventItem(
      id: "l2",
      title: "🔴 Sunderkand Live Path & Bhajan",
      status: "Upcoming",
      dateOrTime: "Today • 7:00 PM",
      viewers: "520 Devotees Waiting",
      thumbnailUrl: "assets/images/ram_bhajan.png",
    ),
    LiveEventItem(
      id: "l3",
      title: "🔴 Maha Shivratri Night Live Jagran",
      status: "Recorded",
      dateOrTime: "5 days ago",
      viewers: "8,920 Viewers",
      thumbnailUrl: "assets/images/somnath_temple.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.mandalName != null && widget.mandalName!.isNotEmpty) {
      _mandalName = widget.mandalName!;
    }
    if (widget.location != null && widget.location!.isNotEmpty) {
      _mandalTag = "Official Spiritual Organisation • ${widget.location!}";
    }
  }

  // --- SEPARATE FULL SCREEN NAVIGATION HANDLERS ---

  void _openCreatePostScreen() async {
    final result = await Navigator.push<PostItem>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMandalPostScreen(mandalName: _mandalName),
      ),
    );
    if (result != null) {
      setState(() {
        _posts.insert(0, result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 Post published to Mandal Profile!"),
          backgroundColor: Color(0xFFFF7700),
        ),
      );
    }
  }

  void _openCreateReelScreen() async {
    final result = await Navigator.push<ReelItem>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMandalReelScreen(mandalName: _mandalName),
      ),
    );
    if (result != null) {
      setState(() {
        _reels.insert(0, result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎬 Reel published successfully!"),
          backgroundColor: Color(0xFFFF7700),
        ),
      );
    }
  }

  void _openGoLiveStudioScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoLiveStudioScreen(),
      ),
    );
  }

  // POST DETAIL MODAL (FIXED OVERFLOW BUG & NATIVE SHARE)
  void _showPostDetailModal(PostItem post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: AssetImage(widget.avatarUrl ?? "assets/images/ram_bhajan.png"),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _mandalName,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 16),
                              ],
                            ),
                            Text(
                              post.timeAgo,
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (widget.isOwnProfile)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _posts.removeWhere((p) => p.id == post.id));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Post deleted")),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Image
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.black,
                      child: buildSmartImage(post.imageUrl, fit: BoxFit.contain),
                    ),
                  ),
                  // Action buttons (ONLY LIKE, SAVE, SHARE NATIVE)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: post.isLiked ? Colors.red : Colors.black87,
                            size: 26,
                          ),
                          onPressed: () {
                            setModalState(() {
                              post.isLiked = !post.isLiked;
                              post.likes += post.isLiked ? 1 : -1;
                            });
                            setState(() {});
                          },
                        ),
                        Text("${post.likes}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: post.isSaved ? const Color(0xFFFF7700) : Colors.black87,
                            size: 26,
                          ),
                          onPressed: () {
                            setModalState(() {
                              post.isSaved = !post.isSaved;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(post.isSaved ? "Saved to your Library! 🔖" : "Removed from Saved Items"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.black87, size: 24),
                          onPressed: () {
                            Share.share(
                              " Check out this post by ${_mandalName} on Bharat Pray!\n\n${post.caption}\n\nDownload App: https://bharatpray.app/post/${post.id}",
                              subject: "Bharat Pray Mandal Post",
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Caption & Festival Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7700).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                post.festivalName,
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFF7700)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                post.location,
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.caption,
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReelPlayerModal(ReelItem reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return _ReelPlayerFullscreen(reel: reel, mandalName: _mandalName, onLikedChanged: () => setState(() {}));
      },
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                _mandalName,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2E2A36),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 18),
          ],
        ),
        actions: const [],
      ),
      body: _buildApprovedInstagramProfileView(),
    );
  }

  // APPROVED INSTAGRAM STYLE PROFILE VIEW
  Widget _buildApprovedInstagramProfileView() {
    final coverImage = (widget.coverUrl != null && widget.coverUrl!.isNotEmpty)
        ? widget.coverUrl!
        : "assets/images/somnath_hero.png";
    final avatarImage = (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
        ? widget.avatarUrl!
        : "assets/images/ram_bhajan.png";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(coverImage),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Admin Approved",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: -40,
                left: 20,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7700).withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: AssetImage(avatarImage),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mandalName,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                        Text(
                          _mandalTag,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF2E2A36).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  _bio,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF2E2A36).withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.badge_rounded, size: 14, color: Color(0xFFFF7700)),
                    const SizedBox(width: 4),
                    Text(
                      "Govt Reg: $_regNumber",
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF7700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // STATS ROW (STRICTLY NO DEVOTEES)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEFE6DB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStatColumn("${_posts.length}", "Posts"),
                      Container(height: 24, width: 1, color: Colors.grey.shade300),
                      _buildProfileStatColumn("${_reels.length}", "Reels"),
                      Container(height: 24, width: 1, color: Colors.grey.shade300),
                      _buildProfileStatColumn("${_liveEvents.length}", "Lives"),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // DYNAMIC ACTION BUTTONS (OWNER VS PUBLIC VISITOR)
                if (widget.isOwnProfile)
                  // OWNER MANDAL VIEW: Add Post, Add Reel, Go Live
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                          label: Text(
                            "Add Post",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _openCreatePostScreen,
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2E2A36),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFFF7700), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.video_call_rounded, color: Color(0xFFFF7700), size: 20),
                          label: Text(
                            "Add Reel",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _openCreateReelScreen,
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.sensors_rounded, size: 18),
                          label: Text(
                            "Go Live",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _openGoLiveStudioScreen,
                        ),
                      ),
                    ],
                  )
                else
                  // PUBLIC VISITOR VIEW (From Utsav / Top Mandals): Follow Mandal & Share
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.grey.shade200 : const Color(0xFFFF7700),
                            foregroundColor: _isFollowing ? const Color(0xFF2E2A36) : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: _isFollowing ? 0 : 2,
                          ),
                          icon: Icon(
                            _isFollowing ? Icons.check_circle_rounded : Icons.favorite_rounded,
                            size: 18,
                            color: _isFollowing ? const Color(0xFF2E7D32) : Colors.white,
                          ),
                          label: Text(
                            _isFollowing ? "Following Mandal 🙏" : "Follow Mandal",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            setState(() {
                              _isFollowing = !_isFollowing;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isFollowing ? "You are now following ${_mandalName}! 🚩" : "Unfollowed Mandal"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2E2A36),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFFF7700), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.share_rounded, color: Color(0xFFFF7700), size: 18),
                          label: Text(
                            "Share",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            Share.share(
                              "🚩 Join ${_mandalName} on Bharat Pray App!\nWatch Live Aarti & Daily Darshan.\n\nExplore Mandal: https://bharatpray.app/mandal",
                              subject: "Share Mandal Profile",
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEFE6DB)),
                bottom: BorderSide(color: Color(0xFFEFE6DB)),
              ),
            ),
            child: Row(
              children: [
                _buildTabItem(0, Icons.grid_on_rounded, "Posts (${_posts.length})"),
                _buildTabItem(1, Icons.video_collection_rounded, "Reels (${_reels.length})"),
                _buildTabItem(2, Icons.live_tv_rounded, "Live"),
                _buildTabItem(3, Icons.info_outline_rounded, "Mandal Info"),
              ],
            ),
          ),

          IndexedStack(
            index: _selectedTab,
            children: [
              _buildPostsGridTab(),
              _buildReelsGridTab(),
              _buildLiveEventsTab(),
              _buildMandalInfoTab(),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // TAB 1: POSTS
  Widget _buildPostsGridTab() {
    if (_posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text("No Posts Yet", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                widget.isOwnProfile
                    ? "Tap 'Add Post' to share your first Mandal update!"
                    : "No posts shared by this Mandal yet.",
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () => _showPostDetailModal(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              buildSmartImage(post.imageUrl, fit: BoxFit.cover),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        "${post.likes}",
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 2: REELS
  Widget _buildReelsGridTab() {
    if (_reels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.video_library_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text("No Reels Yet", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                widget.isOwnProfile
                    ? "Tap 'Add Reel' to upload divine video clips!"
                    : "No reels uploaded by this Mandal yet.",
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return GestureDetector(
          onTap: () => _showReelPlayerModal(reel),
          child: Stack(
            fit: StackFit.expand,
            children: [
              buildSmartImage(reel.thumbnailUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 36),
              ),
              Positioned(
                bottom: 6,
                left: 6,
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      reel.views,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: LIVE EVENTS
  Widget _buildLiveEventsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isOwnProfile)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sensors_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Broadcast Live Stream Now",
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "Go Live for Aarti, Satsang & Special Events",
                          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openGoLiveStudioScreen,
                    child: Text("Go LIVE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          if (widget.isOwnProfile) const SizedBox(height: 20),

          Text(
            "Live Stream Broadcasts & History",
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _liveEvents.length,
            itemBuilder: (context, index) {
              final live = _liveEvents[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEFE6DB)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: buildSmartImage(live.thumbnailUrl, width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: live.status == "Upcoming" ? Colors.orange : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  live.status,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: live.status == "Upcoming" ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(live.dateOrTime, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            live.title,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                          ),
                          Text(
                            live.viewers,
                            style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFFF7700), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // TAB 4: MANDAL INFO
  Widget _buildMandalInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFE6DB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Official Registration Certificate",
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoRow("Registration Number:", _regNumber),
                _buildInfoRow("Status:", "Approved by Bharat Pray Admin ✅"),
                _buildInfoRow("Approved Date:", "12 January 2024"),
                _buildInfoRow("Mandal President:", "Ayush Kyada"),
                _buildInfoRow("Official Phone:", "+91 81287 53230"),
                _buildInfoRow("Location:", "Ahmedabad, Gujarat"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFFFF7700) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFFF7700) : Colors.grey,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFFFF7700) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(val, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
          ),
        ],
      ),
    );
  }
}

// FULLSCREEN REEL PLAYER (WITH NATIVE OS SHARE SHEET)
class _ReelPlayerFullscreen extends StatefulWidget {
  final ReelItem reel;
  final String mandalName;
  final VoidCallback onLikedChanged;

  const _ReelPlayerFullscreen({
    required this.reel,
    required this.mandalName,
    required this.onLikedChanged,
  });

  @override
  State<_ReelPlayerFullscreen> createState() => _ReelPlayerFullscreenState();
}

class _ReelPlayerFullscreenState extends State<_ReelPlayerFullscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          buildSmartImage(widget.reel.thumbnailUrl, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          const Center(
            child: Icon(Icons.play_circle_fill_rounded, color: Colors.white54, size: 72),
          ),

          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // RIGHT SIDE ACTIONS (LIKE, SAVE, SHARE NATIVE)
          Positioned(
            right: 16,
            bottom: 60,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    widget.reel.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: widget.reel.isLiked ? Colors.red : Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      widget.reel.isLiked = !widget.reel.isLiked;
                      widget.reel.likes += widget.reel.isLiked ? 1 : -1;
                    });
                    widget.onLikedChanged();
                  },
                ),
                Text(
                  "${widget.reel.likes}",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 16),
                IconButton(
                  icon: Icon(
                    widget.reel.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: widget.reel.isSaved ? const Color(0xFFFF7700) : Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      widget.reel.isSaved = !widget.reel.isSaved;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.reel.isSaved ? "Reel saved to Library! 🔖" : "Reel removed from Saved Items"),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                Text(
                  "Save",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 30),
                  onPressed: () {
                    Share.share(
                      " Check out this Divine Reel by ${widget.mandalName} on Bharat Pray!\n\n${widget.reel.title}\n\nDownload App: https://bharatpray.app/reel/${widget.reel.id}",
                      subject: "Bharat Pray Mandal Reel",
                    );
                  },
                ),
                Text(
                  "Share",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage("assets/images/ram_bhajan.png"),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.mandalName,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.reel.title,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.music_note_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.reel.audioTrack,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
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
}

// --- MANDAL POSTS FEED SCREEN ---
class MandalPostsFeedScreen extends StatefulWidget {
  final int startIndex;
  final String mandalName;
  final String avatarUrl;

  const MandalPostsFeedScreen({
    super.key,
    this.startIndex = 0,
    this.mandalName = "Shree Ram Yuvak Mandal",
    this.avatarUrl = "assets/images/ram_bhajan.png",
  });

  @override
  State<MandalPostsFeedScreen> createState() => _MandalPostsFeedScreenState();
}

class _MandalPostsFeedScreenState extends State<MandalPostsFeedScreen> {
  late List<PostItem> _feedPosts;

  @override
  void initState() {
    super.initState();
    _feedPosts = [
      PostItem(
        id: "1",
        imageUrl: "assets/images/somnath_hero.png",
        caption: "🌸 Daily Morning Maha Aarti at Mandal Premises. Har Har Mahadev! 🙏✨",
        timeAgo: "2 hours ago",
        likes: 1240,
      ),
      PostItem(
        id: "2",
        imageUrl: "assets/images/dhanterash.png",
        caption: "🛕 Deepotsav & Grand Aarti Celebrations with all Mandal Devotees! 🪔",
        timeAgo: "1 day ago",
        likes: 2150,
      ),
      PostItem(
        id: "3",
        imageUrl: "assets/images/krishna.png",
        caption: "✨ Shri Krishna Janmashtami Mahotsav Bhajan Sandhya highlights. Jai Shri Krishna! 🚩",
        timeAgo: "3 days ago",
        likes: 3410,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.mandalName,
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feedPosts.length,
        itemBuilder: (context, index) {
          final post = _feedPosts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFE6DB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(widget.avatarUrl),
                  ),
                  title: Row(
                    children: [
                      Text(widget.mandalName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 16),
                    ],
                  ),
                  subtitle: Text(post.timeAgo, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                ),
                ClipRRect(
                  child: buildSmartImage(post.imageUrl, width: double.infinity, height: 260, fit: BoxFit.cover),
                ),
                // NO COMMENTS - ONLY LIKE, SAVE, SHARE NATIVE
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: post.isLiked ? Colors.red : Colors.black87,
                        ),
                        onPressed: () {
                          setState(() {
                            post.isLiked = !post.isLiked;
                            post.likes += post.isLiked ? 1 : -1;
                          });
                        },
                      ),
                      Text("${post.likes}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: post.isSaved ? const Color(0xFFFF7700) : Colors.black87,
                        ),
                        onPressed: () {
                          setState(() => post.isSaved = !post.isSaved);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(post.isSaved ? "Saved to Library! 🔖" : "Removed from Saved Items"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.black87),
                        onPressed: () {
                          Share.share(
                            " Check out this post by ${widget.mandalName} on Bharat Pray!\n\n${post.caption}\n\nDownload App: https://bharatpray.app/post/${post.id}",
                            subject: "Bharat Pray Post",
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(post.caption, style: GoogleFonts.outfit(fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- FULLSCREEN REEL VIEWER (WITH NATIVE OS SHARE SHEET) ---
class FullscreenReelViewer extends StatefulWidget {
  final int startIndex;
  final String mandalName;
  final String avatarUrl;

  const FullscreenReelViewer({
    super.key,
    this.startIndex = 0,
    this.mandalName = "Shree Ram Yuvak Mandal",
    this.avatarUrl = "assets/images/ram_bhajan.png",
  });

  @override
  State<FullscreenReelViewer> createState() => _FullscreenReelViewerState();
}

class _FullscreenReelViewerState extends State<FullscreenReelViewer> {
  late PageController _pageController;

  final List<ReelItem> _allReels = [
    ReelItem(
      id: "r1",
      thumbnailUrl: "assets/images/ram_bhajan.png",
      title: "🔥 Ram Siya Ram Divine Aarti Clips",
      audioTrack: "Ram Siya Ram • Original Mandal Audio",
      views: "45.2k",
      likes: 5820,
    ),
    ReelItem(
      id: "r2",
      thumbnailUrl: "assets/images/somnath_hero.png",
      title: "🛕 Somnath Live Darshan & Damru Dhun",
      audioTrack: "Shiv Tandav Stotram • Sacred Beats",
      views: "89.1k",
      likes: 12400,
    ),
    ReelItem(
      id: "r3",
      thumbnailUrl: "assets/images/krishna.png",
      title: "🌸 Flute Meditation by Mandal Gurukul",
      audioTrack: "Krishna Bansuri Dhun • Mandal Studio",
      views: "28.6k",
      likes: 3100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    int initialPage = widget.startIndex;
    if (initialPage < 0 || initialPage >= _allReels.length) {
      initialPage = 0;
    }
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _allReels.length,
        itemBuilder: (context, index) {
          final reel = _allReels[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              buildSmartImage(reel.thumbnailUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white54, size: 72),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // NO COMMENTS - ONLY LIKE, SAVE, SHARE NATIVE
              Positioned(
                right: 16,
                bottom: 60,
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        reel.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: reel.isLiked ? Colors.red : Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          reel.isLiked = !reel.isLiked;
                          reel.likes += reel.isLiked ? 1 : -1;
                        });
                      },
                    ),
                    Text("${reel.likes}", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: Icon(
                        reel.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: reel.isSaved ? const Color(0xFFFF7700) : Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() => reel.isSaved = !reel.isSaved);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(reel.isSaved ? "Saved to Library! 🔖" : "Removed from Saved Items"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    Text("Save", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 30),
                      onPressed: () {
                        Share.share(
                          " Check out this Divine Reel by ${widget.mandalName} on Bharat Pray!\n\n${reel.title}\n\nDownload App: https://bharatpray.app/reel/${reel.id}",
                          subject: "Bharat Pray Reel",
                        );
                      },
                    ),
                    Text("Share", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: AssetImage(widget.avatarUrl),
                        ),
                        const SizedBox(width: 8),
                        Text(widget.mandalName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(reel.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.music_note_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(reel.audioTrack, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
