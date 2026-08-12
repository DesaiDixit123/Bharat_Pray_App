import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class LiveDarshanScreen extends StatefulWidget {
  final String darshanId;
  final String templeName;
  final String imageUrl;

  const LiveDarshanScreen({
    super.key,
    this.darshanId = '',
    required this.templeName,
    required this.imageUrl,
  });

  @override
  State<LiveDarshanScreen> createState() => _LiveDarshanScreenState();
}

class HeartAnim {
  final int id;
  final double x;
  final double y;
  HeartAnim({required this.id, required this.x, required this.y});
}

class _LiveDarshanScreenState extends State<LiveDarshanScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();

  String _darshanId = '';
  String _token = '';
  String _userName = '';
  String _userAvatar = '';

  // Social Stats States
  int _viewerCount = 0;
  int _likesCount = 0;
  int _commentsCount = 0;
  int _shareCount = 0;
  bool _isLiked = false;
  bool _isFavourite = false;
  bool _isMuted = true;

  // Video Streaming State
  String _youtubeVideoId = '';
  YoutubePlayerController? _youtubeController;

  // Chat Feed State
  final List<Map<String, dynamic>> _liveFeed = [];

  // Heart Animation State
  final List<HeartAnim> _hearts = [];
  int _heartIdCounter = 0;

  // Loading / Error UI State
  bool _isLoading = true;
  bool _isError = false;
  bool _isOffline = false;

  // Sockets / Timers
  IO.Socket? _socket;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _darshanId = widget.darshanId;
    _loadProfileAndInit();
  }

  Future<void> _loadProfileAndInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token') ?? '';
      _userName = prefs.getString('user_name') ?? prefs.getString('name') ?? 'Devotee';
      _userAvatar = prefs.getString('user_avatar') ?? prefs.getString('profile_pic') ?? '';

      bool success = false;

      // 1. If a valid darshanId was passed from parent screen, fetch its details directly
      if (_darshanId.isNotEmpty) {
        try {
          await _fetchDetailsAndComments();
          success = true;
        } catch (e) {
          debugPrint('Passed darshanId $_darshanId invalid or not a stream: $e');
          _darshanId = ''; // reset so we can search by temple name
        }
      }

      // 2. If darshanId is empty or invalid, search live streams dynamically by temple name
      if (!success && widget.templeName.isNotEmpty) {
        try {
          final listData = await ApiService.getDarshansList(token: _token, search: widget.templeName, limit: 20);
          final docs = listData['docs'] as List<dynamic>? ?? [];
          if (docs.isNotEmpty) {
            _darshanId = docs.first['_id'].toString();
            await _fetchDetailsAndComments();
            success = true;
          }
        } catch (e) {
          debugPrint('Search by temple name failed: $e');
        }
      }

      // 3. Fallback search across all live darshan streams for temple match
      if (!success && widget.templeName.isNotEmpty) {
        try {
          final listData = await ApiService.getDarshansList(token: _token, limit: 100);
          final docs = listData['docs'] as List<dynamic>? ?? [];
          final searchName = widget.templeName.trim().toLowerCase();
          final match = docs.firstWhere(
            (d) {
              final tName = (d['temple']?['name'] ?? d['temple_id']?['name'] ?? d['temple_details']?['name'] ?? '')?.toString().toLowerCase() ?? '';
              final dName = (d['name'] ?? '')?.toString().toLowerCase() ?? '';
              return (tName.isNotEmpty && (tName.contains(searchName) || searchName.contains(tName))) || 
                     (dName.isNotEmpty && (dName.contains(searchName) || searchName.contains(dName)));
            },
            orElse: () => null,
          );
          if (match != null) {
            _darshanId = match['_id'].toString();
            await _fetchDetailsAndComments();
            success = true;
          }
        } catch (e) {
          debugPrint('Fuzzy match failed: $e');
        }
      }

      // NO STATIC FALLBACK!
      if (success && _darshanId.isNotEmpty && !_isOffline) {
        _connectSocket();
        _startHeartbeatTimer();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isOffline = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing Live Darshan Screen: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOffline = true;
        });
      }
    }
  }

  Future<void> _fetchDetailsAndComments() async {
    try {
      // 1. Fetch live details (joins stream as well)
      final details = await ApiService.getLiveDarshanDetails(_token, _darshanId);
      
      // Update counts
      _viewerCount = details['current_viewers'] ?? details['currentViewers'] ?? 0;
      _likesCount = details['like_count'] ?? details['likesCount'] ?? 0;
      _commentsCount = details['comments_count'] ?? details['commentsCount'] ?? 0;
      _shareCount = details['share_count'] ?? details['sharesCount'] ?? 0;
      _isFavourite = false; // default, fetch active status in next call

      // Extract Youtube Video ID
      if (details['youtube_darshan_details'] != null) {
        _youtubeVideoId = details['youtube_darshan_details']['youtubeVideoId'] ?? '';
      }

      // Check if admin has enabled live status AND configured youtube video ID
      final bool isLiveFlag = (details['is_live_status'] == true || 
                              details['liveStatus'] == 'live' || 
                              details['status'] == 'live') &&
                             _youtubeVideoId.trim().isNotEmpty;

      if (!isLiveFlag) {
        _isOffline = true;
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isOffline = true;
          });
        }
        return;
      }

      _isOffline = false;

      // Initialize YouTube Player
      if (_youtubeVideoId.isNotEmpty) {
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: _youtubeVideoId,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showControls: false,
            showFullscreenButton: false,
            mute: false,
          ),
        );
      }

      // 2. Fetch current status (likes, favourite)
      try {
        final status = await ApiService.getLiveDarshanStatus(_token, _darshanId);
        _isLiked = status['isLiked'] ?? false;
        _isFavourite = status['isFavourite'] ?? false;
      } catch (_) {}

      // 3. Fetch past comments
      try {
        final commentsRes = await ApiService.getLiveComments(_token, _darshanId, page: 1);
        final dynamic rawList = commentsRes is List
            ? commentsRes
            : (commentsRes['docs'] ?? commentsRes['comments'] ?? commentsRes['data'] ?? []);
        final docs = rawList is List ? rawList : [];

        _liveFeed.clear();
        for (final doc in docs.reversed) {
          if (doc is Map) {
            final uName = (doc['user'] is Map ? doc['user']['name'] : null) ?? doc['userName'] ?? doc['user_name'] ?? 'Devotee';
            final uMsg = doc['comment'] ?? doc['content'] ?? doc['message'] ?? '';
            final uAvatar = (doc['user'] is Map ? doc['user']['profile_pic'] : null) ?? doc['userAvatar'] ?? '';
            final uId = doc['_id']?.toString() ?? doc['id']?.toString();
            final isPinned = doc['isPinned'] == true;
            final likesCount = doc['likes_count'] ?? doc['likesCount'] ?? 0;
            if (uMsg.toString().isNotEmpty) {
              _liveFeed.add({
                'id': uId,
                'user': uName.toString(),
                'message': uMsg.toString(),
                'avatar': uAvatar.toString(),
                'isPinned': isPinned,
                'likesCount': likesCount,
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching comments: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error fetching details and comments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    }
  }

  void _connectSocket() {
    final baseSocketUrl = ApiService.baseUrl.replaceAll('/user', ''); // http://192.168.29.250:3020
    
    _socket = IO.io(baseSocketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setQuery({'token': _token})
      .build());

    _socket!.onConnect((_) {
      debugPrint('Socket connected successfully');
      _socket!.emit('join_stream', {'darshan_id': _darshanId});
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    // Handle updates
    _socket!.on('viewer_count_update', (data) {
      if (mounted && data is Map) {
        setState(() {
          _viewerCount = data['current_viewers'] ?? 0;
        });
      }
    });

    _socket!.on('likes_count_update', (data) {
      if (mounted && data is Map) {
        final String eventDarshanId = (data['darshan_id'] ?? data['darshanId'])?.toString() ?? '';
        if (eventDarshanId.isEmpty || eventDarshanId == _darshanId) {
          setState(() {
            _likesCount = data['like_count'] ?? 0;
          });
        }
      }
    });

    _socket!.on('comments_count_update', (data) {
      if (mounted && data is Map) {
        final String eventDarshanId = (data['darshan_id'] ?? data['darshanId'])?.toString() ?? '';
        if (eventDarshanId.isEmpty || eventDarshanId == _darshanId) {
          setState(() {
            _commentsCount = data['comments_count'] ?? 0;
          });
        }
      }
    });

    _socket!.on('new_comment', (data) {
      if (mounted && data is Map) {
        final String eventDarshanId = (data['darshan_id'] ?? data['darshanId'])?.toString() ?? '';
        if (eventDarshanId.isNotEmpty && eventDarshanId != _darshanId) return;

        final commentUser = (data['user'] is Map ? data['user']['name'] : null) ?? data['userName'] ?? data['user_name'] ?? 'Devotee';
        final commentText = data['comment'] ?? data['content'] ?? data['message'] ?? '';
        final commentAvatar = (data['user'] is Map ? data['user']['profile_pic'] : null) ?? data['userAvatar'] ?? '';

        // Prevent duplicate if this is the user's own comment echoed back
        final isOwnEcho = commentUser == _userName && _liveFeed.isNotEmpty && _liveFeed.last['message'] == commentText;
        if (!isOwnEcho && commentText.toString().isNotEmpty) {
          setState(() {
            _liveFeed.add({
              'id': data['_id']?.toString() ?? data['id']?.toString(),
              'user': commentUser.toString(),
              'message': commentText.toString(),
              'avatar': commentAvatar.toString(),
              'isPinned': data['isPinned'] == true,
              'likesCount': data['likes_count'] ?? 0,
            });
            
            if (_liveFeed.length > 100) {
              _liveFeed.removeAt(0);
            }
          });
          _scrollToBottom();
        }
      }
    });

    _socket!.on('like_status', (data) {
      if (mounted && data is Map) {
        final String eventDarshanId = (data['darshan_id'] ?? data['darshanId'])?.toString() ?? '';
        if (eventDarshanId.isEmpty || eventDarshanId == _darshanId) {
          setState(() {
            _isLiked = data['isLiked'] ?? false;
          });
        }
      }
    });
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('heartbeat', {'darshan_id': _darshanId});
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _socket?.emit('leave_stream');
    _socket?.disconnect();
    _socket?.dispose();
    _youtubeController?.close();
    _commentController.dispose();
    _chatScrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _toggleSound() {
    if (_youtubeController == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _youtubeController?.mute();
    } else {
      _youtubeController?.unMute();
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // 1. Instantly update UI locally (Optimistic update so chat ALWAYS shows user's comment)
    setState(() {
      _liveFeed.add({
        'id': null,
        'user': _userName.isNotEmpty ? _userName : 'Devotee',
        'message': text,
        'avatar': _userAvatar,
        'isPinned': false,
        'likesCount': 0,
      });
      _commentsCount += 1;
    });

    _commentController.clear();
    _commentFocusNode.unfocus();
    _scrollToBottom();

    // 2. Emit over socket if connected
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_comment', {
        'darshan_id': _darshanId,
        'comment': text,
        'content': text,
      });
    }

    // 3. Send over HTTP API as fallback / persistence
    try {
      await ApiService.sendLiveComment(_token, _darshanId, text);
    } catch (e) {
      debugPrint('Error sending comment via HTTP API: $e');
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likesCount++;
      } else {
        _likesCount = (_likesCount > 0) ? _likesCount - 1 : 0;
      }
    });

    if (_socket != null && _socket!.connected) {
      _socket!.emit('like_stream', {'darshan_id': _darshanId});
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final res = await ApiService.toggleFavorite(_token, _darshanId);
      if (mounted) {
        setState(() {
          _isFavourite = res['isFavourite'] ?? !_isFavourite;
        });
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> _shareStream() async {
    try {
      // Increment share counts on backend
      final res = await ApiService.incrementShareCount(_token, _darshanId);
      if (mounted) {
        setState(() {
          _shareCount = res['share_count'] ?? (_shareCount + 1);
        });
      }

      final String templeTitle = widget.templeName.isNotEmpty ? widget.templeName : 'Live Darshan';
      final String shareUrl = "https://bharatpray.com/live-darshan/$_darshanId";
      final String shareText = "🙏 Watch Live Darshan of $templeTitle on Bharat Pray app!\n\n$shareUrl";

      // Trigger system share sheet with fallback to options modal
      final result = await Share.share(shareText, subject: 'Live Darshan - $templeTitle');
      if (result.status == ShareResultStatus.dismissed && mounted) {
        _showShareOptionsBottomSheet(templeTitle, shareText, shareUrl);
      }
    } catch (e) {
      debugPrint('Error sharing stream: $e');
      final String templeTitle = widget.templeName.isNotEmpty ? widget.templeName : 'Live Darshan';
      final String shareUrl = "https://bharatpray.com/live-darshan/$_darshanId";
      final String shareText = "🙏 Watch Live Darshan of $templeTitle on Bharat Pray app!\n\n$shareUrl";
      if (mounted) {
        _showShareOptionsBottomSheet(templeTitle, shareText, shareUrl);
      }
    }
  }

  void _showShareOptionsBottomSheet(String templeTitle, String shareText, String shareUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share Live Darshan',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareAppTile(
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                    label: 'WhatsApp',
                    onTap: () async {
                      Navigator.pop(context);
                      final waUrl = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(shareText)}");
                      if (await canLaunchUrl(waUrl)) {
                        await launchUrl(waUrl);
                      } else {
                        Share.share(shareText, subject: 'Live Darshan - $templeTitle');
                      }
                    },
                  ),
                  _buildShareAppTile(
                    icon: Icons.send_rounded,
                    color: const Color(0xFF0088CC),
                    label: 'Telegram',
                    onTap: () async {
                      Navigator.pop(context);
                      final tgUrl = Uri.parse("https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent("🙏 Live Darshan of $templeTitle")}");
                      if (await canLaunchUrl(tgUrl)) {
                        await launchUrl(tgUrl, mode: LaunchMode.externalApplication);
                      } else {
                        Share.share(shareText, subject: 'Live Darshan - $templeTitle');
                      }
                    },
                  ),
                  _buildShareAppTile(
                    icon: Icons.link_rounded,
                    color: const Color(0xFFFF7A00),
                    label: 'Copy Link',
                    onTap: () async {
                      Navigator.pop(context);
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Darshan link copied to clipboard! 🙏'),
                            backgroundColor: Color(0xFFFF7A00),
                          ),
                        );
                      }
                    },
                  ),
                  _buildShareAppTile(
                    icon: Icons.grid_view_rounded,
                    color: Colors.white70,
                    label: 'More Apps',
                    onTap: () {
                      Navigator.pop(context);
                      Share.share(shareText, subject: 'Live Darshan - $templeTitle');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareAppTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _spawnHeart(double x, double y) {
    final id = _heartIdCounter++;
    setState(() {
      _hearts.add(HeartAnim(id: id, x: x, y: y));
    });
    
    // Toggle like via socket
    _toggleLike();

    // Auto remove heart widget when animation finishes
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _hearts.removeWhere((h) => h.id == id);
        });
      }
    });
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return "${(number / 1000000).toStringAsFixed(1)}M";
    }
    if (number >= 1000) {
      return "${(number / 1000).toStringAsFixed(1)}K";
    }
    return number.toString();
  }

  String _resolveImageUrl(String url) {
    return ApiService.resolveImageUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(widget.imageUrl);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF7A00),
                ),
              )
            : (_isOffline || _isError)
                ? _buildOfflineScreen(context)
                : Stack(
                    children: [
                      // 1. Full-screen Video Player / Image Fallback
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          child: _youtubeController != null
                              ? Center(
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: YoutubePlayer(
                                      controller: _youtubeController!,
                                    ),
                                  ),
                                )
                              : imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => Image.asset(
                                        'assets/images/image_2.png',
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/image_2.png',
                                      fit: BoxFit.contain,
                                    ),
                        ),
                      ),

                      // 1b. Touch interceptor overlay covering the player (captures double-taps for hearts, prevents webview taps)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTapDown: (details) {
                            _spawnHeart(details.globalPosition.dx, details.globalPosition.dy);
                          },
                          onTap: () {
                            // Suppress single taps so they never reach the webview
                          },
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.02),
                          ),
                        ),
                      ),

                      // 2. Floating Heart Animations Layer
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Stack(
                            children: _hearts.map((heart) {
                              return Positioned(
                                left: heart.x - 40,
                                top: heart.y - 40,
                                child: FloatingHeartWidget(key: ValueKey(heart.id)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // 3a. TOP gradient shadow (top ~35% of screen)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 280,
                        child: IgnorePointer(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF000000),
                                  Colors.transparent,
                                ],
                                stops: [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 3b. BOTTOM gradient shadow (bottom ~50% of screen)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 400,
                        child: IgnorePointer(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF000000),
                                ],
                                stops: [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 4. Top Row Header (Avatar & Title)
                      Positioned(
                        top: 55,
                        left: 20,
                        width: 250,
                        height: 60,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30, width: 1.0),
                              ),
                              child: ClipOval(
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Image.asset(
                                          'assets/images/image_3.png',
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/image_3.png',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.templeName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 5. Close Button
                      Positioned(
                        top: 55,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
                            ),
                            child: const Center(
                              child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),

                      // 6. LIVE Status Badge
                      Positioned(
                        top: 125,
                        left: 20,
                        width: 80,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B42),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sensors_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 7. Views Count Badge
                      Positioned(
                        top: 125,
                        left: 110,
                        width: 87,
                        height: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(47),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4.6, sigmaY: 4.6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(47),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 16),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatNumber(_viewerCount),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 8. Live Comments Feed Overlay
                      Positioned(
                        left: 20,
                        bottom: 75,
                        width: 250,
                        height: 237,
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black, Colors.black],
                              stops: [0.0, 0.15, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: ListView.builder(
                            controller: _chatScrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _liveFeed.length,
                            padding: const EdgeInsets.only(top: 10),
                            itemBuilder: (context, index) {
                              final chat = _liveFeed[index];
                              final avatarUrl = _resolveImageUrl(chat['avatar'] ?? '');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white30, width: 1.0),
                                      ),
                                      child: ClipOval(
                                        child: avatarUrl.isNotEmpty
                                            ? Image.network(
                                                avatarUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Image.asset(
                                                  'assets/images/image_3.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Image.asset(
                                                'assets/images/image_3.png',
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chat['user'] ?? 'Devotee',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFFF8A00),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            chat['message'] ?? '',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // 9. Right-Side Action Buttons (Like, Comment, Share)
                      // Like button: bottom: 232
                      Positioned(
                        right: 16,
                        bottom: 232,
                        width: 48,
                        height: 72,
                        child: _buildLiveActionButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isLiked ? const Color(0xFFFF2D55) : Colors.white,
                            size: 22,
                          ),
                          label: _formatNumber(_likesCount),
                          onTap: _toggleLike,
                        ),
                      ),
                      // Comment button: bottom: 154 (Opens Half-Screen Instagram-style Comments Sheet)
                      Positioned(
                        right: 16,
                        bottom: 154,
                        width: 48,
                        height: 72,
                        child: _buildLiveActionButton(
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: _formatNumber(_commentsCount),
                          onTap: () {
                            _showCommentsBottomSheet(context);
                          },
                        ),
                      ),
                      // Share button: bottom: 76
                      Positioned(
                        right: 16,
                        bottom: 76,
                        width: 48,
                        height: 72,
                        child: _buildLiveActionButton(
                          icon: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: _formatNumber(_shareCount),
                          onTap: _shareStream,
                        ),
                      ),

                      // 10. Bottom Comment Input Bar + Send Button
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(83),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
                                ),
                                child: TextField(
                                  controller: _commentController,
                                  focusNode: _commentFocusNode,
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                                  onSubmitted: (_) => _sendComment(),
                                  decoration: InputDecoration(
                                    hintText: "Say something nice.......",
                                    hintStyle: GoogleFonts.outfit(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _sendComment,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
                                ),
                                child: Center(
                                  child: SvgPicture.string(
                                    '''<svg width="17" height="17" viewBox="0 0 17 17" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M10.4489 17.0093C9.40754 17.0093 7.93375 16.2769 6.76884 12.7733L6.13343 10.8671L4.22721 10.2317C0.732482 9.06677 0 7.59299 0 6.55163C0 5.51909 0.732482 4.03648 4.22721 2.86274L11.7197 0.365244C13.5906 -0.261337 15.1527 -0.0760106 16.1146 0.877098C17.0765 1.83021 17.2619 3.40107 16.6353 5.27199L14.1378 12.7645C12.964 16.2769 11.4903 17.0093 10.4489 17.0093ZM4.64199 4.12473C2.18862 4.94546 1.31494 5.91622 1.31494 6.55163C1.31494 7.18703 2.18862 8.15779 4.64199 8.9697L6.86591 9.71101C7.06006 9.77278 7.21892 9.93163 7.28069 10.1258L8.022 12.3497C8.83391 14.8031 9.81349 15.6768 10.4489 15.6768C11.0843 15.6768 12.0551 14.8031 12.8758 12.3497L15.3733 4.85721C15.8234 3.49815 15.7439 2.38619 15.1703 1.81256C14.5967 1.23893 13.4847 1.16833 12.1345 1.61841L4.64199 4.12473Z" fill="white"/>
</svg>''',
                                    width: 17,
                                    height: 17,
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
    );
  }

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.60,
                decoration: const BoxDecoration(
                  color: Color(0xFF191722),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Header: Live Chat title + comments count + Close button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Text(
                            'Live Chat',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatNumber(_commentsCount),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF7A00),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),

                    // Live Comments List (Pinned comments sorted to top)
                    Expanded(
                      child: () {
                        final displayList = List<Map<String, dynamic>>.from(_liveFeed);
                        displayList.sort((a, b) {
                          final bool aPinned = a['isPinned'] == true;
                          final bool bPinned = b['isPinned'] == true;
                          if (aPinned && !bPinned) return -1;
                          if (!aPinned && bPinned) return 1;
                          return 0;
                        });

                        return displayList.isEmpty
                          ? Center(
                              child: Text(
                                'No comments yet. Say something nice!',
                                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              controller: _chatScrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                final chat = displayList[index];
                                final avatarUrl = _resolveImageUrl(chat['avatar'] ?? '');
                                final bool isPinned = chat['isPinned'] == true;
                                final int commentLikes = chat['likesCount'] is int
                                    ? chat['likesCount'] as int
                                    : int.tryParse(chat['likesCount']?.toString() ?? '0') ?? 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white24, width: 1.0),
                                        ),
                                        child: ClipOval(
                                          child: avatarUrl.isNotEmpty
                                              ? Image.network(
                                                  avatarUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Image.asset(
                                                    'assets/images/image_3.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Image.asset(
                                                  'assets/images/image_3.png',
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (isPinned)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 4.0),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFFF7A00)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Pinned by Admin',
                                                      style: GoogleFonts.outfit(
                                                        color: const Color(0xFFFF7A00),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            Text(
                                              chat['user'] ?? 'Devotee',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFFFF8A00),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              chat['message'] ?? '',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (chat['id'] != null && _socket != null && _socket!.connected) {
                                            _socket!.emit('like_comment', {
                                              'darshan_id': _darshanId,
                                              'comment_id': chat['id'],
                                            });
                                            setModalState(() {
                                              final currentLikes = chat['likesCount'] is int
                                                  ? chat['likesCount'] as int
                                                  : int.tryParse(chat['likesCount']?.toString() ?? '0') ?? 0;
                                              chat['likesCount'] = currentLikes + 1;
                                            });
                                            setState(() {});
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                (commentLikes > 0) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                color: (commentLikes > 0) ? const Color(0xFFFF2D55) : Colors.white38,
                                                size: 16,
                                              ),
                                              if (commentLikes > 0) ...[
                                                const SizedBox(width: 3),
                                                Text(
                                                  _formatNumber(commentLikes),
                                                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                      }(),
                    ),

                    // Input Field at Bottom of Sheet
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22202C),
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: TextField(
                                controller: _commentController,
                                focusNode: _commentFocusNode,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                                onSubmitted: (_) {
                                  _sendComment();
                                  setModalState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: "Say something nice.......",
                                  hintStyle: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              _sendComment();
                              setModalState(() {});
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF7A00),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildLiveActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: icon,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                color: Color(0x8C000000),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineScreen(BuildContext context) {
    final imageUrl = _resolveImageUrl(widget.imageUrl);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.templeName.isNotEmpty ? widget.templeName : 'Temple Darshan',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Live Stream Offline',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 12,
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

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // 2. Temple Banner Card
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Image.asset(
                                        'assets/images/image_2.png',
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/image_2.png',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 20,
                              right: 20,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.sensors_off_rounded,
                                          color: Colors.orangeAccent,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'STREAM OFFLINE',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 3. Informative Spiritual Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1924),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2C283B)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8A00), Color(0xFFFF4500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.videocam_off_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Live Darshan Currently Offline',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The admin is currently offline. Live Aarti and Darshan stream for ${widget.templeName.isNotEmpty ? widget.templeName : "this temple"} will resume during scheduled temple timings.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 16),

                          // Timings Info Grid
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFB300), size: 20),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Morning Aarti',
                                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '06:00 AM',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.nights_stay_rounded, color: Color(0xFF7C4DFF), size: 20),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Evening Aarti',
                                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '06:30 PM',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. Action Buttons
                    // Refresh Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _isOffline = false;
                            _isError = false;
                          });
                          _loadProfileAndInit();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Check Live Status Again',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Notify Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🙏 You will be notified when ${widget.templeName.isNotEmpty ? widget.templeName : "this temple"} goes live!'),
                              backgroundColor: const Color(0xFFFF7A00),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_active_outlined, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Notify Me When Live',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingHeartWidget extends StatefulWidget {
  const FloatingHeartWidget({super.key});

  @override
  State<FloatingHeartWidget> createState() => _FloatingHeartWidgetState();
}

class _FloatingHeartWidgetState extends State<FloatingHeartWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_controller);

    _slideAnimation = Tween<double>(begin: 0.0, end: -100.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFFF2D55),
                size: 80,
              ),
            ),
          ),
        );
      },
    );
  }
}
