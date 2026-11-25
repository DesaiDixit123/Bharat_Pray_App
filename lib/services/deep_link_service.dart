import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../screens/details/bhajan_dashboard_screen.dart';
import '../screens/details/live_darshan_screen.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const MethodChannel _channel = MethodChannel('com.bharatpray/deep_links');

  bool _initialized = false;
  bool _appReady = false;
  String? _pendingLink;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final String? link = call.arguments as String?;
        if (link != null && link.trim().isNotEmpty) {
          debugPrint('[DeepLink] Received warm link: $link');
          _handleOrQueue(link.trim());
        }
      }
    });

    try {
      final String? initialLink = await _channel.invokeMethod<String>('getInitialLink');
      if (initialLink != null && initialLink.trim().isNotEmpty) {
        debugPrint('[DeepLink] Received initial cold link: $initialLink');
        _handleOrQueue(initialLink.trim());
      }
    } catch (e) {
      debugPrint('[DeepLink] getInitialLink notice: $e');
    }
  }

  /// Called once SplashScreen finishes navigating to HomeScreen.
  void markAppReady() {
    _appReady = true;
    final pending = _pendingLink;
    if (pending != null) {
      _pendingLink = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateForLink(pending);
      });
    }
  }

  void _handleOrQueue(String rawLink) {
    if (!_appReady) {
      _pendingLink = rawLink;
      return;
    }
    _navigateForLink(rawLink);
  }

  void _navigateForLink(String rawLink) {
    final Uri? uri = Uri.tryParse(rawLink);
    if (uri == null) return;

    // Normalize segments across both custom scheme (bharatpray://live-darshan/<id>)
    // and https/http URLs (https://api.bharatpray.com/share/live-darshan/<id>)
    final List<String> segments = [];
    if (uri.scheme == 'bharatpray') {
      if (uri.host.isNotEmpty) segments.add(uri.host.toLowerCase());
      segments.addAll(uri.pathSegments.where((s) => s.isNotEmpty));
    } else {
      final rawSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (rawSegments.isNotEmpty && rawSegments.first.toLowerCase() == 'share') {
        segments.addAll(rawSegments.sublist(1));
      } else {
        segments.addAll(rawSegments);
      }
    }

    if (segments.isEmpty) return;

    final String type = segments[0].toLowerCase();
    final String id = segments.length > 1 ? segments[1] : '';

    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      _pendingLink = rawLink;
      return;
    }

    if ((type == 'live-darshan' || type == 'darshan') && id.isNotEmpty) {
      debugPrint('[DeepLink] Opening LiveDarshanScreen for darshanId=$id');
      nav.push(
        MaterialPageRoute(
          builder: (_) => LiveDarshanScreen(
            darshanId: id,
            templeName: '',
            imageUrl: '',
          ),
        ),
      );
    } else if (type == 'bhajan') {
      debugPrint('[DeepLink] Opening BhajanDashboardScreen for bhajanId=$id');
      nav.push(
        MaterialPageRoute(
          builder: (_) => const BhajanDashboardScreen(),
        ),
      );
    }
  }
}
