import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  final List<Map<String, String>> _liveFeed = [];

  // Heart Animation State
  final List<HeartAnim> _hearts = [];
  int _heartIdCounter = 0;

  // Loading / Error UI State
  bool _isLoading = true;
  bool _isError = false;

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

      if (_darshanId.isEmpty) {
        // Find matching darshan by temple name from the list to resolve static banner navigations
        final listData = await ApiService.getDarshansList(token: _token, limit: 100);
        final docs = listData['docs'] as List<dynamic>? ?? [];
        final match = docs.firstWhere(
          (d) {
            final tName = (d['temple']?['name'] ?? d['temple_id']?['name'] ?? d['temple_details']?['name'] ?? '')?.toString() ?? '';
            final dName = d['name']?.toString() ?? '';
            final searchName = widget.templeName.toLowerCase();
            return tName.toLowerCase().contains(searchName) || 
                   dName.toLowerCase().contains(searchName);
          },
          orElse: () => null,
        );
        if (match != null) {
          _darshanId = match['_id'].toString();
        }
      }

      if (_darshanId.isEmpty) {
        // Fallback: use first active stream from list
        final listData = await ApiService.getDarshansList(token: _token, limit: 1);
        final docs = listData['docs'] as List<dynamic>? ?? [];
        if (docs.isNotEmpty) {
          _darshanId = docs.first['_id'].toString();
        }
      }

      if (_darshanId.isNotEmpty) {
        // 1. Fetch details and comments
        await _fetchDetailsAndComments();
        // 2. Setup socket connections
        _connectSocket();
        // 3. Setup heartbeat
        _startHeartbeatTimer();
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing Live Darshan Screen: $e');
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  Future<void> _fetchDetailsAndComments() async {
    try {
      // 1. Fetch live details (joins stream as well)
      final details = await ApiService.getLiveDarshanDetails(_token, _darshanId);
      
      // Update counts
      _viewerCount = details['current_viewers'] ?? 0;
      _likesCount = details['like_count'] ?? 0;
      _commentsCount = details['comments_count'] ?? 0;
      _shareCount = details['share_count'] ?? 0;
      _isFavourite = false; // default, fetch active status in next call

      // Extract Youtube Video ID
      if (details['youtube_darshan_details'] != null) {
        _youtubeVideoId = details['youtube_darshan_details']['youtubeVideoId'] ?? '';
      }

      // Initialize YouTube Player
      if (_youtubeVideoId.isNotEmpty) {
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: _youtubeVideoId,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showControls: false,
            showFullscreenButton: false,
            mute: true, // Auto-play compliant
          ),
        );
      }

      // 2. Fetch current status (likes, favourite)
      final status = await ApiService.getLiveDarshanStatus(_token, _darshanId);
      _isLiked = status['isLiked'] ?? false;
      _isFavourite = status['isFavourite'] ?? false;

      // 3. Fetch past comments
      final commentsRes = await ApiService.getLiveComments(_token, _darshanId, page: 1);
      final docs = commentsRes['docs'] as List<dynamic>? ?? [];
      
      _liveFeed.clear();
      // Reverse array to render oldest first at top of listView
      for (final doc in docs.reversed) {
        _liveFeed.add({
          'user': doc['user']?['name'] ?? 'User',
          'message': doc['comment'] ?? '',
          'avatar': doc['user']?['profile_pic'] ?? '',
        });
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
      if (mounted) {
        setState(() {
          _viewerCount = data['current_viewers'] ?? 0;
        });
      }
    });

    _socket!.on('likes_count_update', (data) {
      if (mounted) {
        setState(() {
          _likesCount = data['like_count'] ?? 0;
        });
      }
    });

    _socket!.on('comments_count_update', (data) {
      if (mounted) {
        setState(() {
          _commentsCount = data['comments_count'] ?? 0;
        });
      }
    });

    _socket!.on('new_comment', (data) {
      if (mounted) {
        setState(() {
          _liveFeed.add({
            'user': data['user']?['name'] ?? 'User',
            'message': data['comment'] ?? '',
            'avatar': data['user']?['profile_pic'] ?? '',
          });
          
          if (_liveFeed.length > 50) {
            _liveFeed.removeAt(0);
          }
        });
        _scrollToBottom();
      }
    });

    _socket!.on('like_status', (data) {
      if (mounted) {
        setState(() {
          _isLiked = data['isLiked'] ?? false;
        });
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

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty && _socket != null && _socket!.connected) {
      _socket!.emit('send_comment', {
        'darshan_id': _darshanId,
        'comment': text
      });
      _commentController.clear();
      _commentFocusNode.unfocus();
    }
  }

  void _toggleLike() {
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
          _shareCount = res['share_count'] ?? _shareCount + 1;
        });
      }
      
      // Copy sharing link or trigger sharing dialogue
      final String shareUrl = "https://bharatpray.com/live-darshan/$_darshanId";
      await Clipboard.setData(ClipboardData(text: shareUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Darshan sharing link copied to clipboard! 🙏'),
            backgroundColor: Color(0xFFFF7A00),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing stream: $e');
    }
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
    if (url.isEmpty) return '';
    final baseDomain = ApiService.baseUrl.replaceAll('/user', ''); // http://192.168.29.250:3020
    
    String resolved = url;
    if (resolved.contains('localhost:3020')) {
      resolved = resolved.replaceAll('http://localhost:3020', baseDomain);
    } else if (resolved.contains('api.bharatpray.com')) {
      resolved = resolved.replaceAll('https://api.bharatpray.com', baseDomain);
    } else if (!resolved.startsWith('http')) {
      final isUploads = resolved.contains('uploads/');
      resolved = '$baseDomain${isUploads ? "" : "/uploads"}/${resolved.startsWith("/") ? resolved.substring(1) : resolved}';
    }
    return resolved;
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
            : _isError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.white60, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Stream details failed to load.',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _loadProfileAndInit,
                          child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      // 1. Full-screen Video Player / Image Fallback
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          child: _youtubeController != null
                              ? SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: 16,
                                      height: 9,
                                      child: YoutubePlayer(
                                        controller: _youtubeController!,
                                      ),
                                    ),
                                  ),
                                )
                              : imageUrl.isNotEmpty
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
                                            chat['user']!,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFFF8A00),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            chat['message']!,
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

                      // 9. Right-Side Action Buttons (Sound, Like, Fav, Comment, Share)
                      // Sound Toggle Button: bottom: 388
                      Positioned(
                        right: 16,
                        bottom: 388,
                        width: 48,
                        height: 72,
                        child: _buildLiveActionButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          label: _isMuted ? "Unmute" : "Mute",
                          onTap: _toggleSound,
                        ),
                      ),
                      // Like button: bottom: 310
                      Positioned(
                        right: 16,
                        bottom: 310,
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
                      // Favourite button: bottom: 232
                      Positioned(
                        right: 16,
                        bottom: 232,
                        width: 48,
                        height: 72,
                        child: _buildLiveActionButton(
                          icon: Icon(
                            _isFavourite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: _isFavourite ? const Color(0xFFFFB300) : Colors.white,
                            size: 22,
                          ),
                          label: "Fav",
                          onTap: _toggleFavorite,
                        ),
                      ),
                      // Comment button: bottom: 154
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
                            _commentFocusNode.requestFocus();
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
