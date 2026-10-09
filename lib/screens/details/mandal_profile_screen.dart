import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../services/api_service.dart';
import '../../services/saved_items_service.dart';
import '../../services/utsav_service.dart';

import 'create_mandal_post_screen.dart';
import 'create_mandal_reel_screen.dart';
import 'go_live_studio_screen.dart';
import 'mandal_registration_screen.dart';

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
  final clean = path.trim();
  if (clean.startsWith('data:image')) {
    try {
      final commaIdx = clean.indexOf(',');
      if (commaIdx != -1) {
        final bytes = base64Decode(clean.substring(commaIdx + 1));
        return Image.memory(bytes, fit: fit, width: width, height: height);
      }
    } catch (_) {}
  }
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return Image.network(
      clean,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Image.asset('assets/images/ram_bhajan.png', fit: fit, width: width, height: height),
    );
  }
  if (clean.startsWith('/uploads/') || clean.startsWith('uploads/')) {
    return Image.network(
      UtsavService.resolveImageUrl(clean),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Image.asset('assets/images/ram_bhajan.png', fit: fit, width: width, height: height),
    );
  }
  if (clean.startsWith('assets/')) {
    return Image.asset(clean, fit: fit, width: width, height: height);
  }
  try {
    final file = File(clean);
    if (file.existsSync()) {
      return Image.file(file, fit: fit, width: width, height: height);
    }
  } catch (_) {}
  return Image.asset('assets/images/ram_bhajan.png', fit: fit, width: width, height: height);
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'caption': caption,
    'festivalName': festivalName,
    'location': location,
    'timeAgo': timeAgo,
    'likes': likes,
    'isLiked': isLiked,
    'isSaved': isSaved,
  };

  factory PostItem.fromJson(Map<String, dynamic> json) => PostItem(
    id: json['id']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString() ?? 'assets/images/ram_bhajan.png',
    caption: json['caption']?.toString() ?? '',
    festivalName: json['festivalName']?.toString() ?? 'Somnath Maha Shivratri Mahotsav',
    location: json['location']?.toString() ?? 'Ahmedabad, Gujarat',
    timeAgo: json['timeAgo']?.toString() ?? 'Just now',
    likes: (json['likes'] is num) ? (json['likes'] as num).toInt() : int.tryParse(json['likes']?.toString() ?? '0') ?? 0,
    isLiked: json['isLiked'] == true,
    isSaved: json['isSaved'] == true,
  );
}

class ReelItem {
  final String id;
  final String thumbnailUrl;
  final String? videoUrl;
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
    this.videoUrl,
    required this.title,
    required this.audioTrack,
    this.festivalName = "Somnath Maha Shivratri Mahotsav",
    required this.views,
    required this.likes,
    this.isLiked = false,
    this.isSaved = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'thumbnailUrl': thumbnailUrl,
    'videoUrl': videoUrl,
    'title': title,
    'audioTrack': audioTrack,
    'festivalName': festivalName,
    'views': views,
    'likes': likes,
    'isLiked': isLiked,
    'isSaved': isSaved,
  };

  factory ReelItem.fromJson(Map<String, dynamic> json) => ReelItem(
    id: json['id']?.toString() ?? '',
    thumbnailUrl: json['thumbnailUrl']?.toString() ?? 'assets/images/ram_bhajan.png',
    videoUrl: json['videoUrl']?.toString(),
    title: json['title']?.toString() ?? '',
    audioTrack: json['audioTrack']?.toString() ?? '',
    festivalName: json['festivalName']?.toString() ?? 'Somnath Maha Shivratri Mahotsav',
    views: json['views']?.toString() ?? '0',
    likes: (json['likes'] is num) ? (json['likes'] as num).toInt() : int.tryParse(json['likes']?.toString() ?? '0') ?? 0,
    isLiked: json['isLiked'] == true,
    isSaved: json['isSaved'] == true,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'dateOrTime': dateOrTime,
    'viewers': viewers,
    'thumbnailUrl': thumbnailUrl,
  };

  factory LiveEventItem.fromJson(Map<String, dynamic> json) => LiveEventItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Recorded',
    dateOrTime: json['dateOrTime']?.toString() ?? 'Recently',
    viewers: json['viewers']?.toString() ?? '1 Viewer',
    thumbnailUrl: json['thumbnailUrl']?.toString() ?? 'assets/images/somnath_temple.png',
  );
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

  // Mandal Details
  String _mandalName = "Mandal";
  String _mandalTag = "Official Spiritual Organisation";
  String _regNumber = "-";
  String _presidentName = "-";
  String _officialPhone = "";
  String _location = "-";
  String _approvedDate = "-";
  String _statusText = "Approved by Bharat Pray Admin ✅";
  String _bio = "";
  String? _avatarUrl;
  String? _coverUrl;

  // Festival Active Status (Post, Reel & Live are locked until festival starts)
  bool _isFestivalStarted = false;
  String _associatedFestivalName = "Maha Navratri Garba Utsav 2026";
  String _festivalStartDateStr = "11 Oct 2026";

  // Real Posts, Reels and Live Events Data (Starts empty, 0 counts)
  final List<PostItem> _posts = [];
  final List<ReelItem> _reels = [];
  final List<LiveEventItem> _liveEvents = [];
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.mandalName != null && widget.mandalName!.isNotEmpty) {
      _mandalName = widget.mandalName!;
    }
    if (widget.location != null && widget.location!.isNotEmpty) {
      _location = widget.location!;
      _mandalTag = "Official Spiritual Organisation • ${widget.location!}";
    }
    _avatarUrl = widget.avatarUrl;
    _coverUrl = widget.coverUrl;
    _loadMandalData();
    _syncSavedStatus();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) return;
      final myReg = await UtsavService.getMyMandalRegistration();
      if (mounted && myReg != null) {
        if (myReg['status']?.toString().toLowerCase() == 'deleted') {
          _statusPollTimer?.cancel();
          _showMandalDeletedPopup(context, myReg);
        }
      }
    });
  }

  Future<void> _loadMandalData() async {
    final myReg = await UtsavService.getMyMandalRegistration();
    String name = widget.mandalName ?? _mandalName;
    if ((name.isEmpty || name == 'Mandal') && myReg != null && myReg['mandalName'] != null) {
      name = myReg['mandalName'].toString();
    }
    _mandalName = name;

    // Check if the festival associated with this mandal has started
    final festInfo = await UtsavService.checkFestivalStartedForMandal(mandalName: name);
    if (mounted) {
      setState(() {
        _isFestivalStarted = festInfo['isStarted'] == true;
        _associatedFestivalName = festInfo['festivalName']?.toString() ?? _associatedFestivalName;
        _festivalStartDateStr = (festInfo['formattedDate'] ?? festInfo['startDate'] ?? _festivalStartDateStr).toString();
      });
    }

    final isMyMandal = widget.isOwnProfile ||
        (myReg != null && (
          (name.isNotEmpty && myReg['mandalName']?.toString().toLowerCase().trim() == name.toLowerCase().trim()) ||
          (myReg['registrationId']?.toString() == name) ||
          (widget.mandalName == null || widget.mandalName!.isEmpty)
        ));

    if (isMyMandal && myReg != null && mounted) {
      final months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
      setState(() {
        final regLogo = (myReg['logo'] ?? myReg['avatar'] ?? myReg['logoUrl'])?.toString();
        if (regLogo != null && regLogo.isNotEmpty) {
          _avatarUrl = regLogo;
        }
        final regCover = (myReg['cover'] ?? myReg['coverUrl'] ?? myReg['imageUrl'])?.toString();
        if (regCover != null && regCover.isNotEmpty) {
          _coverUrl = regCover;
        }
        if (myReg['mandalName'] != null && myReg['mandalName'].toString().isNotEmpty) {
          _mandalName = myReg['mandalName'].toString();
        }
        if (myReg['address'] != null && myReg['address'].toString().isNotEmpty) {
          _location = myReg['address'].toString();
          _mandalTag = "Official Spiritual Organisation • $_location";
        }
        if (myReg['registrationId'] != null) {
          _regNumber = myReg['registrationId'].toString();
        }
        if (myReg['leaderName'] != null && myReg['leaderName'].toString().isNotEmpty) {
          _presidentName = myReg['leaderName'].toString();
        }
        if (myReg['mobile'] != null && myReg['mobile'].toString().isNotEmpty) {
          _officialPhone = myReg['mobile'].toString();
        }
        if (myReg['bio'] != null && myReg['bio'].toString().isNotEmpty) {
          _bio = myReg['bio'].toString();
        } else if (myReg['description'] != null && myReg['description'].toString().isNotEmpty) {
          _bio = myReg['description'].toString();
        }
        final regStatus = (myReg['status'] ?? 'Approved').toString();
        if (regStatus.toLowerCase() == 'pending') {
          _statusText = "Pending Verification ⏳";
        } else if (regStatus.toLowerCase() == 'rejected') {
          _statusText = "Rejected by Bharat Pray Admin ❌";
        } else if (regStatus.toLowerCase() == 'deleted') {
          _statusText = "Deleted by Bharat Pray Admin ❌";
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showMandalDeletedPopup(context, myReg);
          });
        } else {
          _statusText = "Approved by Bharat Pray Admin ✅";
        }
        if (myReg['createdAt'] != null || myReg['updatedAt'] != null) {
          final dtStr = (myReg['updatedAt'] ?? myReg['createdAt']).toString();
          final dt = DateTime.tryParse(dtStr);
          if (dt != null) {
            _approvedDate = "${dt.day} ${months[dt.month - 1]} ${dt.year}";
          }
        }
      });
    } else {
      final m = await UtsavService.getMandalByName(name);
      if (m != null && mounted) {
        final months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        setState(() {
          _mandalName = (m['name'] ?? _mandalName).toString();
          final city = (m['city'] ?? widget.location ?? _location).toString();
          _location = city;
          final est = m['establishedYear'] != null ? ' • Est. ${m['establishedYear']}' : '';
          _mandalTag = "Official Spiritual Organisation • $city$est";
          if (m['regNo'] != null) _regNumber = m['regNo'].toString();
          if (m['bio'] != null && m['bio'].toString().isNotEmpty) {
            _bio = m['bio'].toString();
          } else if (m['description'] != null && m['description'].toString().isNotEmpty) {
            _bio = m['description'].toString();
          }
          if (_avatarUrl == null || _avatarUrl!.isEmpty) {
            _avatarUrl = (m['logo'] ?? m['imageUrl'])?.toString();
          }
          if (_coverUrl == null || _coverUrl!.isEmpty) {
            _coverUrl = (m['imageUrl'] ?? m['cover'] ?? m['banner'])?.toString();
          }

          // Leader details from mandal object
          if (m['leader'] is Map) {
            final l = m['leader'] as Map;
            if (l['name'] != null && l['name'].toString().isNotEmpty) {
              _presidentName = l['name'].toString();
            }
            if (l['phone'] != null && l['phone'].toString().isNotEmpty) {
              _officialPhone = l['phone'].toString();
            }
          } else if (m['leaderName'] != null && m['leaderName'].toString().isNotEmpty) {
            _presidentName = m['leaderName'].toString();
          }

          if (m['phone'] != null && m['phone'].toString().isNotEmpty && _officialPhone.isEmpty) {
            _officialPhone = m['phone'].toString();
          }

          final status = (m['status'] ?? 'Approved').toString();
          if (status.toLowerCase() == 'pending') {
            _statusText = "Pending Verification ⏳";
          } else if (status.toLowerCase() == 'rejected') {
            _statusText = "Rejected by Bharat Pray Admin ❌";
          } else {
            _statusText = "Approved by Bharat Pray Admin ✅";
          }

          if (m['updatedAt'] != null || m['createdAt'] != null) {
            final dtStr = (m['updatedAt'] ?? m['createdAt']).toString();
            final dt = DateTime.tryParse(dtStr);
            if (dt != null) {
              _approvedDate = "${dt.day} ${months[dt.month - 1]} ${dt.year}";
            }
          } else if (m['requestDate'] != null) {
            _approvedDate = m['requestDate'].toString();
          } else if (m['establishedYear'] != null) {
            _approvedDate = "Est. ${m['establishedYear']}";
          }
        });
      }
    }

    // Load persisted posts, reels, and live events
    final savedPostsMaps = await UtsavService.getMandalPosts(_mandalName);
    final savedReelsMaps = await UtsavService.getMandalReels(_mandalName);
    final savedLivesMaps = await UtsavService.getMandalLiveEvents(_mandalName);
    if (mounted) {
      setState(() {
        _posts.clear();
        for (final pm in savedPostsMaps) {
          _posts.add(PostItem.fromJson(pm));
        }
        _reels.clear();
        for (final rm in savedReelsMaps) {
          _reels.add(ReelItem.fromJson(rm));
        }
        _liveEvents.clear();
        for (final lm in savedLivesMaps) {
          _liveEvents.add(LiveEventItem.fromJson(lm));
        }
      });
    }
  }

  void _syncSavedStatus() async {
    for (var r in _reels) {
      final saved = await SavedItemsService.isReelSaved(r.id);
      r.isSaved = saved;
    }
    for (var p in _posts) {
      final saved = await SavedItemsService.isPostSaved(p.id);
      p.isSaved = saved;
    }
    if (mounted) setState(() {});
  }

  // --- SEPARATE FULL SCREEN NAVIGATION HANDLERS ---

  void _showFestivalNotStartedSheet({required String action}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7700).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: Color(0xFFFF7700),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Festival Not Started Yet ⏳",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Text(
                  _associatedFestivalName,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Posts, Reels and Live streaming will unlock once $_associatedFestivalName begins on $_festivalStartDateStr.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7700),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Understood",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showMandalDeletedPopup(BuildContext context, Map<String, dynamic> reg) {
    final mandalName = (reg['mandalName'] ?? _mandalName).toString();
    final reason = (reg['deletionReason'] ?? reg['rejectionReason'] ?? 'Account deleted by Bharat Pray Admin').toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade600, size: 34),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Mandal Account Deleted ❌",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Your Mandal account '$mandalName' has been deleted by Bharat Pray Admin.",
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.red.shade800, size: 14),
                      const SizedBox(width: 4),
                      Text("Reason for Deletion:", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(reason, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.red.shade900)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "You can now submit a fresh registration directly.",
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await UtsavService.clearMyMandalRegistration();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text("Dismiss", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7700),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await UtsavService.clearMyMandalRegistration();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MandalRegistrationScreen(initialFestival: _associatedFestivalName),
                          ),
                        );
                      }
                    },
                    child: Text("Register Again", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCreatePostScreen() async {
    if (!_isFestivalStarted) {
      _showFestivalNotStartedSheet(action: "Post");
      return;
    }
    final result = await Navigator.push<PostItem>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMandalPostScreen(
          mandalName: _mandalName,
          festivalName: _associatedFestivalName,
          location: _location,
        ),
      ),
    );
    if (result != null) {
      await UtsavService.saveMandalPost(_mandalName, result.toJson());
      setState(() {
        _posts.removeWhere((p) => p.id == result.id);
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
    if (!_isFestivalStarted) {
      _showFestivalNotStartedSheet(action: "Reel");
      return;
    }
    final result = await Navigator.push<ReelItem>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMandalReelScreen(
          mandalName: _mandalName,
          festivalName: _associatedFestivalName,
        ),
      ),
    );
    if (result != null) {
      await UtsavService.saveMandalReel(_mandalName, result.toJson());
      setState(() {
        _reels.removeWhere((r) => r.id == result.id);
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
    if (!_isFestivalStarted) {
      _showFestivalNotStartedSheet(action: "Live Darshan");
      return;
    }
    _showLiveChoiceBottomSheet();
  }

  // FULLSCREEN POST VIEWER (INSTAGRAM-STYLE FEED)
  void _openPostViewer({int startIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MandalPostsFeedScreen(
          startIndex: startIndex,
          posts: _posts,
          mandalName: _mandalName,
          avatarUrl: widget.avatarUrl ?? "assets/images/ram_bhajan.png",
          isOwnProfile: widget.isOwnProfile,
          isFromProfile: true,
          onPostDeleted: (postId) async {
            await UtsavService.deleteMandalPost(_mandalName, postId);
            setState(() {
              _posts.removeWhere((p) => p.id == postId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Post deleted")),
            );
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showPostDetailModal(PostItem post) {
    final idx = _posts.indexOf(post);
    _openPostViewer(startIndex: idx >= 0 ? idx : 0);
  }

  void _openReelViewer({int startIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenReelViewer(
          startIndex: startIndex,
          reels: _reels,
          mandalName: _mandalName,
          avatarUrl: widget.avatarUrl ?? "assets/images/ram_bhajan.png",
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: const [],
        ),
        body: _buildApprovedInstagramProfileView(),
      ),
    );
  }

  ImageProvider _resolveImageProvider(String path, {required String fallback}) {
    if (path.isNotEmpty) {
      final clean = path.trim();
      if (clean.startsWith('data:image')) {
        try {
          final commaIdx = clean.indexOf(',');
          if (commaIdx != -1) {
            final bytes = base64Decode(clean.substring(commaIdx + 1));
            return MemoryImage(bytes);
          }
        } catch (_) {}
      }
      if (clean.startsWith('http://') || clean.startsWith('https://')) {
        return NetworkImage(clean);
      }
      if (clean.startsWith('/uploads/') || clean.startsWith('uploads/')) {
        return NetworkImage(UtsavService.resolveImageUrl(clean));
      }
      if (clean.startsWith('assets/')) {
        return AssetImage(clean);
      }
      try {
        final file = File(clean);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }
    return AssetImage(fallback);
  }

  // APPROVED INSTAGRAM STYLE PROFILE VIEW
  Widget _buildApprovedInstagramProfileView() {
    final coverImage = (_coverUrl != null && _coverUrl!.isNotEmpty)
        ? _coverUrl!
        : (widget.coverUrl != null && widget.coverUrl!.isNotEmpty)
            ? widget.coverUrl!
            : "assets/images/somnath_hero.png";
    final avatarImage = (_avatarUrl != null && _avatarUrl!.isNotEmpty)
        ? _avatarUrl!
        : (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
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
                    image: _resolveImageProvider(coverImage, fallback: "assets/images/somnath_hero.png"),
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
                        backgroundImage: _resolveImageProvider(avatarImage, fallback: "assets/images/ram_bhajan.png"),
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

                if (_bio.trim().isNotEmpty) ...[
                  Text(
                    _bio,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF2E2A36).withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                if (widget.isOwnProfile) ...[
                  Row(
                    children: [
                      // 1. Add Post
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openCreatePostScreen,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isFestivalStarted ? const Color(0xFFFF7700) : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isFestivalStarted
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF7700).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: _isFestivalStarted ? Colors.white : Colors.grey.shade600,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Add Post",
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _isFestivalStarted ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. Add Reel
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openCreateReelScreen,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isFestivalStarted ? Colors.white : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _isFestivalStarted ? const Color(0xFFFF7700) : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                boxShadow: _isFestivalStarted
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_call_rounded,
                                    color: _isFestivalStarted ? const Color(0xFFFF7700) : Colors.grey.shade600,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Add Reel",
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _isFestivalStarted ? const Color(0xFF2E2A36) : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Go Live
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openGoLiveStudioScreen,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isFestivalStarted ? const Color(0xFFD32F2F) : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isFestivalStarted
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFD32F2F).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sensors_rounded,
                                    color: _isFestivalStarted ? Colors.white : Colors.grey.shade600,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Go Live",
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _isFestivalStarted ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isFestivalStarted)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.grey.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Posts, Reels and Live will unlock once the festival starts ($_festivalStartDateStr).",
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ]
                else
                  // PUBLIC VISITOR VIEW: Share Mandal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7700),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      label: Text(
                        "Share Mandal",
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
          onTap: () => _openPostViewer(startIndex: index),
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
          onTap: () => _openReelViewer(startIndex: index),
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
                          _isFestivalStarted
                              ? "Go Live for Aarti, Satsang & Special Events"
                              : "Live Streaming unlocks on $_associatedFestivalName start ($_festivalStartDateStr)",
                          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFestivalStarted ? Colors.white : Colors.grey.shade300,
                      foregroundColor: _isFestivalStarted ? const Color(0xFFD32F2F) : Colors.grey.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
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
    final displayPhone = _officialPhone.isNotEmpty
        ? (_officialPhone.startsWith('+') ? _officialPhone : "+91 $_officialPhone")
        : "-";

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
                _buildInfoRow("Status:", _statusText),
                _buildInfoRow("Approved Date:", _approvedDate),
                _buildInfoRow("Mandal President:", _presidentName),
                _buildInfoRow("Official Phone:", displayPhone),
                _buildInfoRow("Location:", _location),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LIVE BROADCAST BOTTOM SHEETS (INSTANT VS SCHEDULE) ---

  String _formatDate(DateTime date) {
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  void _showLiveChoiceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 14, left: 20, right: 20, bottom: 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sensors_rounded, color: Color(0xFFD32F2F), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Live Broadcast Options",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                        Text(
                          "Broadcast live spiritual Darshan for $_mandalName",
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // OPTION 1: Instant Live
              _buildLiveOptionTile(
                icon: Icons.videocam_rounded,
                iconBg: const Color(0xFFD32F2F).withOpacity(0.12),
                iconColor: const Color(0xFFD32F2F),
                title: "Instant Live",
                subtitle: "Start live streaming immediately via device camera",
                badge: "GO LIVE NOW",
                badgeColor: const Color(0xFFD32F2F),
                onTap: () {
                  Navigator.pop(context);
                  _showInstantLiveDialog();
                },
              ),

              const SizedBox(height: 12),

              // OPTION 2: Schedule Live
              _buildLiveOptionTile(
                icon: Icons.calendar_today_rounded,
                iconBg: const Color(0xFFFF7700).withOpacity(0.12),
                iconColor: const Color(0xFFFF7700),
                title: "Schedule Live",
                subtitle: "Set date & time, devotees will be notified automatically",
                badge: "SET TIME & DATE",
                badgeColor: const Color(0xFFFF7700),
                onTap: () {
                  Navigator.pop(context);
                  _showScheduleLiveDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveOptionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFE6DB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  void _showInstantLiveDialog() {
    final titleController = TextEditingController(text: "$_mandalName Live Aarti & Darshan 🙏");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sensors_rounded, color: Color(0xFFD32F2F), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Instant Live Broadcast",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Live Stream / Aarti Name",
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: "Enter live stream name...",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 20),
                    label: Text(
                      "Start Live Camera Now",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () {
                      final title = titleController.text.trim().isNotEmpty
                          ? titleController.text.trim()
                          : "$_mandalName Live Aarti";
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoLiveStudioScreen(initialTitle: title),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScheduleLiveDialog() {
    final titleController = TextEditingController(text: "$_mandalName Special Live Mahotsav");
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final dateStr = _formatDate(selectedDate);
            final timeStr = _formatTime(selectedTime);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBF7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7700).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available_rounded, color: Color(0xFFFF7700), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Schedule Live Broadcast",
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name / Title Input
                    Text(
                      "Live Event / Puja Name",
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "e.g. Sunderkand Path, Sandhya Aarti...",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF7700), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date & Time Row
                    Row(
                      children: [
                        // DATE PICKER
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Event Date",
                                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36)),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFEFE6DB)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFFF7700)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dateStr,
                                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // TIME PICKER
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Event Time",
                                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36)),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedTime = picked;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFEFE6DB)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFFF7700)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          timeStr,
                                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Notification Info Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCC80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFFE65100)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "All Mandal devotees will be sent an automated notification alert at scheduled time.",
                              style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFFE65100), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Schedule Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7700),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.notifications_rounded, size: 20),
                        label: Text(
                          "Schedule & Notify Devotees",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim().isNotEmpty
                              ? titleController.text.trim()
                              : "$_mandalName Live Aarti";
                          Navigator.pop(ctx);

                          // Insert into _liveEvents and focus Live tab
                          setState(() {
                            _liveEvents.insert(
                              0,
                              LiveEventItem(
                                id: "sched_${DateTime.now().millisecondsSinceEpoch}",
                                title: "🔴 $title",
                                status: "Upcoming",
                                dateOrTime: "$dateStr • $timeStr",
                                viewers: "Notification Scheduled 🔔",
                                thumbnailUrl: "assets/images/somnath_hero.png",
                              ),
                            );
                            _selectedTab = 2; // Jump directly to Live Tab to see it!
                          });

                          // Show automated notification confirmation banner
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF2E2A36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              content: Row(
                                children: [
                                  const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF7700), size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Live Scheduled & Alert Set! 🔔",
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                                        ),
                                        Text(
                                          "Devotees will be notified for '$title' on $dateStr at $timeStr.",
                                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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



// --- MANDAL POSTS FEED SCREEN (FULL POST VIEWER) ---
class MandalPostsFeedScreen extends StatefulWidget {
  final int startIndex;
  final List<PostItem>? posts;
  final String mandalName;
  final String avatarUrl;
  final bool isOwnProfile;
  final bool isFromProfile;
  final Function(String postId)? onPostDeleted;

  const MandalPostsFeedScreen({
    super.key,
    this.startIndex = 0,
    this.posts,
    this.mandalName = "Mandal",
    this.avatarUrl = "assets/images/ram_bhajan.png",
    this.isOwnProfile = false,
    this.isFromProfile = false,
    this.onPostDeleted,
  });

  static final List<PostItem> defaultPosts = [];

  @override
  State<MandalPostsFeedScreen> createState() => _MandalPostsFeedScreenState();
}

class _MandalPostsFeedScreenState extends State<MandalPostsFeedScreen> {
  late ScrollController _scrollController;
  late List<PostItem> _feedPosts;
  String? _heartAnimatedPostId;

  @override
  void initState() {
    super.initState();
    _feedPosts = widget.posts != null ? List<PostItem>.from(widget.posts!) : <PostItem>[];
    _scrollController = ScrollController();
    if (widget.startIndex > 0 && widget.startIndex < _feedPosts.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final offset = widget.startIndex * 580.0;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openMandalProfile(BuildContext context, PostItem post) {
    if (widget.isFromProfile) {
      Navigator.pop(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MandalProfileScreen(
            mandalName: widget.mandalName,
            avatarUrl: widget.avatarUrl,
            location: post.location.isNotEmpty ? post.location : "Gujarat, India",
            isOwnProfile: widget.isOwnProfile,
          ),
        ),
      );
    }
  }

  void _triggerHeartAnimation(String postId, PostItem post) {
    setState(() {
      _heartAnimatedPostId = postId;
      if (!post.isLiked) {
        post.isLiked = true;
        post.likes += 1;
      }
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _heartAnimatedPostId = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFE8D6),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Posts",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
        ),
      body: _feedPosts.isEmpty
          ? Center(
              child: Text(
                "No posts available",
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _feedPosts.length,
              itemBuilder: (context, index) {
                final post = _feedPosts[index];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEFE6DB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Post Header - Click to Open Mandal Profile Directly
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _openMandalProfile(context, post),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFFF9500), Color(0xFFFF5500)],
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundImage: widget.avatarUrl.startsWith('http')
                                            ? NetworkImage(widget.avatarUrl) as ImageProvider
                                            : AssetImage(widget.avatarUrl),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  widget.mandalName,
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.5,
                                                    color: const Color(0xFF2E2A36), // High contrast readable dark text
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 15),
                                            ],
                                          ),
                                          const SizedBox(height: 1),
                                          Row(
                                            children: [
                                              if (post.location.isNotEmpty) ...[
                                                const Icon(Icons.location_on_rounded, size: 11, color: Color(0xFFFF7700)),
                                                const SizedBox(width: 2),
                                                Text(
                                                  "${post.location} • ",
                                                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF7A757F)),
                                                ),
                                              ],
                                              Text(
                                                post.timeAgo,
                                                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF7A757F)),
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
                            if (widget.isOwnProfile)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text("Delete Post?"),
                                      content: const Text("Are you sure you want to delete this sacred post?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            setState(() {
                                              _feedPosts.removeWhere((p) => p.id == post.id);
                                            });
                                            widget.onPostDeleted?.call(post.id);
                                          },
                                          child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      // 2. Post Image (Clean, Full-width, Double-tap to Like)
                      GestureDetector(
                        onDoubleTap: () => _triggerHeartAnimation(post.id, post),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 260, maxHeight: 440),
                              color: const Color(0xFFF7F2EB),
                              child: buildSmartImage(post.imageUrl, fit: BoxFit.cover),
                            ),
                            if (_heartAnimatedPostId == post.id)
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 400),
                                tween: Tween(begin: 0.4, end: 1.2),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.white,
                                      size: 90,
                                      shadows: [
                                        BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 14,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      // 3. Action Buttons Row (Like, Share, Save)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: post.isLiked ? Colors.redAccent : const Color(0xFF2E2A36),
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  post.isLiked = !post.isLiked;
                                  post.likes += post.isLiked ? 1 : -1;
                                });
                              },
                            ),
                            Text(
                              "${post.likes}",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: const Color(0xFF2E2A36)),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, color: Color(0xFF2E2A36), size: 22),
                              onPressed: () {
                                Share.share(
                                  "🚩 Check out this post by ${widget.mandalName} on Bharat Pray!\n\n${post.caption}\n\nDownload App: https://bharatpray.app/post/${post.id}",
                                  subject: "Bharat Pray Mandal Post",
                                );
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: post.isSaved ? const Color(0xFFFF7700) : const Color(0xFF2E2A36),
                                size: 24,
                              ),
                              onPressed: () async {
                                final isNowSaved = await SavedItemsService.toggleSavePost(
                                  {
                                    'id': post.id,
                                    'content': post.caption,
                                    'image': post.imageUrl,
                                    'likes': post.likes,
                                    'time': post.timeAgo,
                                  },
                                  widget.mandalName,
                                  widget.avatarUrl,
                                );
                                setState(() {
                                  post.isSaved = isNowSaved;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isNowSaved ? "Saved to Library! 🔖" : "Removed from Saved Items"),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // 4. Festival Tag Chip
                      if (post.festivalName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7700).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF7700).withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("🛕", style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 5),
                                Text(
                                  post.festivalName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF7700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 5. Post Caption (Clear, Dark Text, High Contrast)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              color: const Color(0xFF2E2A36), // High contrast readable
                              height: 1.35,
                            ),
                            children: [
                              TextSpan(
                                text: "${widget.mandalName} ",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: post.caption),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}

// --- FULLSCREEN REEL VIEWER (INSTAGRAM-STYLE REELS PLAYER) ---
class FullscreenReelViewer extends StatefulWidget {
  final int startIndex;
  final List<ReelItem>? reels;
  final String mandalName;
  final String avatarUrl;

  const FullscreenReelViewer({
    super.key,
    this.startIndex = 0,
    this.reels,
    this.mandalName = "Mandal",
    this.avatarUrl = "assets/images/ram_bhajan.png",
  });

  static final List<ReelItem> defaultReels = [];

  @override
  State<FullscreenReelViewer> createState() => _FullscreenReelViewerState();
}

class _FullscreenReelViewerState extends State<FullscreenReelViewer> {
  late PageController _pageController;
  late List<ReelItem> _reels;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _reels = widget.reels != null ? List<ReelItem>.from(widget.reels!) : <ReelItem>[];

    int initialPage = widget.startIndex;
    if (initialPage < 0 || initialPage >= _reels.length) {
      initialPage = 0;
    }
    _currentIndex = initialPage;
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
        physics: const BouncingScrollPhysics(),
        itemCount: _reels.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _SingleReelView(
            key: ValueKey(_reels[index].id),
            reel: _reels[index],
            isActive: index == _currentIndex,
            mandalName: widget.mandalName,
            avatarUrl: widget.avatarUrl,
          );
        },
      ),
    );
  }
}

class _SingleReelView extends StatefulWidget {
  final ReelItem reel;
  final bool isActive;
  final String mandalName;
  final String avatarUrl;

  const _SingleReelView({
    super.key,
    required this.reel,
    required this.isActive,
    required this.mandalName,
    required this.avatarUrl,
  });

  @override
  State<_SingleReelView> createState() => _SingleReelViewState();
}

class _SingleReelViewState extends State<_SingleReelView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _showPlayPauseOverlay = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
    _setupVideo();
  }

  void _checkSavedStatus() async {
    final saved = await SavedItemsService.isReelSaved(widget.reel.id);
    if (mounted && saved != widget.reel.isSaved) {
      setState(() {
        widget.reel.isSaved = saved;
      });
    }
  }

  String _pickFallbackVideo(String id) {
    final hash = id.hashCode.abs() % 3;
    if (hash == 0) return 'assets/images/1st_Scene.mp4';
    if (hash == 1) return 'assets/images/2nd_Scene.mp4';
    return 'assets/images/3rd_Scene.mp4';
  }

  void _setupVideo() {
    final vUrl = widget.reel.videoUrl;
    if (vUrl != null && vUrl.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(vUrl));
    } else if (vUrl != null && (vUrl.startsWith('assets/') || vUrl.endsWith('.mp4'))) {
      if (vUrl.startsWith('assets/')) {
        _controller = VideoPlayerController.asset(vUrl);
      } else {
        final f = File(vUrl);
        if (f.existsSync()) {
          _controller = VideoPlayerController.file(f);
        } else {
          _controller = VideoPlayerController.asset(_pickFallbackVideo(widget.reel.id));
        }
      }
    } else {
      _controller = VideoPlayerController.asset(_pickFallbackVideo(widget.reel.id));
    }

    _controller!.initialize().then((_) {
      if (!mounted) return;
      _controller!.setLooping(true);
      setState(() {
        _isInitialized = true;
      });
      if (widget.isActive) {
        _controller!.seekTo(Duration.zero);
        _controller!.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }).catchError((err) {
      debugPrint("Reel video error: $err");
    });
  }

  @override
  void didUpdateWidget(covariant _SingleReelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        // Returned to this reel: seek to beginning and start playing automatically!
        _controller?.seekTo(Duration.zero);
        _controller?.play();
        setState(() {
          _isPlaying = true;
        });
      } else {
        // Navigated away from this reel: pause and reset to start!
        _controller?.pause();
        _controller?.seekTo(Duration.zero);
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          _controller!.play();
          _isPlaying = true;
        }
        _showPlayPauseOverlay = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _showPlayPauseOverlay = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Player or Thumbnail
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 1080,
                  height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 1920,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            buildSmartImage(widget.reel.thumbnailUrl, fit: BoxFit.cover),

          // 2. Subtle Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.0, 0.25, 0.65, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Play/Pause Overlay - only shows when tapped or paused, never statically blocks video
          if (_showPlayPauseOverlay || (!_isPlaying && _isInitialized))
            Center(
              child: AnimatedOpacity(
                opacity: _showPlayPauseOverlay || !_isPlaying ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 54,
                  ),
                ),
              ),
            ),

          // 4. Back Button at Top Left
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 5. Right Action Buttons (Like, Save, Share)
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
                  onPressed: () async {
                    final isNowSaved = await SavedItemsService.toggleSaveReel(
                      {
                        'id': widget.reel.id,
                        'title': widget.reel.title,
                        'likes': widget.reel.likes.toString(),
                        'thumbnailUrl': widget.reel.thumbnailUrl,
                        'videoUrl': widget.reel.videoUrl ?? '',
                        'audioTrack': widget.reel.audioTrack,
                      },
                      widget.mandalName,
                      widget.avatarUrl,
                    );
                    if (mounted) {
                      setState(() => widget.reel.isSaved = isNowSaved);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isNowSaved ? "Saved to Library! 🔖" : "Removed from Saved Items"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                Text("Save", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 30),
                  onPressed: () {
                    Share.share(
                      "🕉️ Check out this Divine Reel by ${widget.mandalName} on Bharat Pray!\n\n${widget.reel.title}\n\nDownload App: https://bharatpray.app/reel/${widget.reel.id}",
                      subject: "Bharat Pray Reel",
                    );
                  },
                ),
                Text("Share", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),

          // 6. Bottom Info (Avatar, Mandal Name, Title, Audio) - EXPANDED to prevent overflow!
          Positioned(
            bottom: 24,
            left: 16,
            right: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage(widget.avatarUrl),
                      onBackgroundImageError: (_, __) {},
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.mandalName,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: Color(0xFFFF7700), size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.reel.title,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 7. Bottom Video Progress Line (Instagram Style)
          if (_isInitialized && _controller != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFFF7700),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
