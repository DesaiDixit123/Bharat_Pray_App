import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';

class AppShareService {
  AppShareService._();

  // Always use clean public domain for share links (never expose local dev IP in shared links)
  static const String _publicShareBaseUrl = 'https://api.bharatpray.com';

  /// Builds a clean, unified HTTPS share URL that opens the installed Bharat Pray app
  /// directly via Android App Links / Intent Filter / Smart Redirect.
  static String buildShareUrl({required String type, String id = ''}) {
    final cleanType = type.trim().toLowerCase();
    final cleanId = id.trim();
    if (cleanId.isNotEmpty) {
      return '$_publicShareBaseUrl/share/$cleanType/${Uri.encodeComponent(cleanId)}';
    }
    return '$_publicShareBaseUrl/share/$cleanType';
  }

  /// Generates a branded PNG banner image with:
  /// - Content banner/cover image (or devotional gradient fallback)
  /// - Top-left pill badge
  /// - Automatic Bharat Pray App Logo in the Top-Right corner
  /// - Bottom-left title (and optional subtitle)
  static Future<File?> createBrandedBannerFile({
    required String cacheKey,
    required String title,
    String subtitle = '',
    String badgeText = 'BHARAT PRAY',
    Color badgeColor = const Color(0xFFFF7A00),
    bool showLiveDot = false,
    List<String> imageUrls = const [],
    String? fallbackAsset,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final safeKey = cacheKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final cacheFile = File('${tempDir.path}/bp_share_v2_$safeKey.png');

      Uint8List? rawBytes;
      for (final rawUrl in imageUrls) {
        final trimmed = rawUrl.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('assets/')) {
          try {
            final bd = await rootBundle.load(trimmed);
            rawBytes = bd.buffer.asUint8List();
            break;
          } catch (_) {}
          continue;
        }
        try {
          final resolved = ApiService.resolveImageUrl(trimmed);
          final response = await http
              .get(Uri.parse(resolved))
              .timeout(const Duration(seconds: 4));
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            rawBytes = response.bodyBytes;
            break;
          }
        } catch (e) {
          debugPrint('[AppShareService] Image fetch failed ($trimmed): $e');
        }
      }

      if ((rawBytes == null || rawBytes.isEmpty) &&
          fallbackAsset != null &&
          fallbackAsset.isNotEmpty) {
        try {
          final bd = await rootBundle.load(fallbackAsset);
          rawBytes = bd.buffer.asUint8List();
        } catch (_) {}
      }

      final bytes = await _renderBrandedBannerBytes(
        rawBytes: rawBytes,
        title: title,
        subtitle: subtitle,
        badgeText: badgeText,
        badgeColor: badgeColor,
        showLiveDot: showLiveDot,
      );

      if (bytes == null || bytes.isEmpty) return null;
      await cacheFile.writeAsBytes(bytes, flush: true);
      return cacheFile;
    } catch (e) {
      debugPrint('[AppShareService] createBrandedBannerFile error: $e');
      return null;
    }
  }

  static Future<Uint8List?> _renderBrandedBannerBytes({
    Uint8List? rawBytes,
    required String title,
    String subtitle = '',
    required String badgeText,
    required Color badgeColor,
    required bool showLiveDot,
  }) async {
    try {
      ui.Image? bgImage;
      if (rawBytes != null && rawBytes.isNotEmpty) {
        try {
          final codec = await ui.instantiateImageCodec(rawBytes);
          final frame = await codec.getNextFrame();
          bgImage = frame.image;
        } catch (_) {}
      }

      final int outW = bgImage != null ? bgImage.width : 1080;
      final int outH = bgImage != null ? bgImage.height : 608;
      final double width = outW.toDouble();
      final double height = outH.toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 1. Background image or devotional plum-saffron gradient backdrop
      if (bgImage != null) {
        canvas.drawImage(bgImage, Offset.zero, Paint());
      } else {
        final bgGrad = Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(width, height),
            const [
              Color(0xFF1A0B2E),
              Color(0xFF3A1456),
              Color(0xFF6B2418),
            ],
            const [0.0, 0.55, 1.0],
          );
        canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgGrad);

        // Soft warm aura circle
        final auraPaint = Paint()
          ..shader = ui.Gradient.radial(
            Offset(width * 0.5, height * 0.45),
            width * 0.45,
            [
              const Color(0xFFFF9933).withValues(alpha: 0.28),
              Colors.transparent,
            ],
          );
        canvas.drawRect(Rect.fromLTWH(0, 0, width, height), auraPaint);
      }

      // 2. Top & Bottom legibility gradients
      final topGrad = Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, height * 0.30),
          [Colors.black.withValues(alpha: 0.65), Colors.transparent],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height * 0.30), topGrad);

      final bottomGrad = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, height * 0.48),
          Offset(0, height),
          [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.90),
          ],
          const [0.0, 0.55, 1.0],
        );
      canvas.drawRect(Rect.fromLTWH(0, height * 0.48, width, height * 0.52), bottomGrad);

      final scale = (width / 720.0).clamp(0.7, 2.5);
      final margin = 24.0 * scale;

      // 3. Top-Left Pill Badge
      final badgeTextPainter = TextPainter(
        text: TextSpan(
          text: badgeText.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.5 * scale,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double badgeHeight = 42.0 * scale;
      final double dotSpace = showLiveDot ? 22.0 * scale : 0.0;
      final double badgeWidth = badgeTextPainter.width + (32.0 * scale) + dotSpace;
      final RRect badgeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, margin, badgeWidth, badgeHeight),
        Radius.circular(21.0 * scale),
      );
      canvas.drawRRect(badgeRRect, Paint()..color = badgeColor);

      if (showLiveDot) {
        canvas.drawCircle(
          Offset(margin + 18.0 * scale, margin + badgeHeight / 2),
          5.2 * scale,
          Paint()..color = Colors.white,
        );
      }
      badgeTextPainter.paint(
        canvas,
        Offset(
          margin + (16.0 * scale) + dotSpace,
          margin + (badgeHeight - badgeTextPainter.height) / 2,
        ),
      );

      // 4. Top-Right Automatic Bharat Pray App Logo
      bool drewLogo = false;
      try {
        final logoData = await rootBundle.load('assets/images/app_logo.png');
        final logoCodec = await ui.instantiateImageCodec(logoData.buffer.asUint8List());
        final logoFrame = await logoCodec.getNextFrame();
        final logoImg = logoFrame.image;

        final double logoBoxSize = 76.0 * scale;
        final double logoLeft = width - logoBoxSize - margin;
        final double logoTop = margin;
        final RRect logoBgRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(logoLeft, logoTop, logoBoxSize, logoBoxSize),
          Radius.circular(18.0 * scale),
        );

        canvas.drawRRect(
          logoBgRRect.shift(Offset(0, 4.0 * scale)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * scale),
        );
        canvas.drawRRect(
          logoBgRRect,
          Paint()..color = const Color(0xFF1A0D2E).withValues(alpha: 0.88),
        );
        canvas.drawRRect(
          logoBgRRect,
          Paint()
            ..color = const Color(0xFFFF9933).withValues(alpha: 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 * scale,
        );

        final double pad = 8.0 * scale;
        final double innerSize = logoBoxSize - (pad * 2);
        final double srcW = logoImg.width.toDouble();
        final double srcH = logoImg.height.toDouble();
        final double fitScale = (innerSize / srcW) < (innerSize / srcH)
            ? (innerSize / srcW)
            : (innerSize / srcH);
        final double drawW = srcW * fitScale;
        final double drawH = srcH * fitScale;

        canvas.drawImageRect(
          logoImg,
          Rect.fromLTWH(0, 0, srcW, srcH),
          Rect.fromLTWH(
            logoLeft + (logoBoxSize - drawW) / 2,
            logoTop + (logoBoxSize - drawH) / 2,
            drawW,
            drawH,
          ),
          Paint()..filterQuality = FilterQuality.high,
        );
        drewLogo = true;
      } catch (e) {
        debugPrint('[AppShareService] Logo overlay fallback: $e');
      }

      if (!drewLogo) {
        final fallbackBrand = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Bharat',
                style: TextStyle(
                  color: const Color(0xFFFF9933),
                  fontSize: 17.0 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: 'Pray',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.0 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        fallbackBrand.paint(
          canvas,
          Offset(width - fallbackBrand.width - margin, margin + 10.0 * scale),
        );
      }

      // 5. Bottom-Left Title & Optional Subtitle
      double bottomCursor = height - (margin * 1.15);

      if (subtitle.trim().isNotEmpty) {
        final subPainter = TextPainter(
          text: TextSpan(
            text: subtitle.trim(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 16.0 * scale,
              fontWeight: FontWeight.w500,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        )..layout(maxWidth: width - (margin * 2));
        bottomCursor -= subPainter.height;
        subPainter.paint(canvas, Offset(margin, bottomCursor));
        bottomCursor -= 6.0 * scale;
      }

      final titlePainter = TextPainter(
        text: TextSpan(
          text: title.trim().isNotEmpty ? title.trim() : 'Bharat Pray',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25.0 * scale,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '...',
      )..layout(maxWidth: width - (margin * 2));

      bottomCursor -= titlePainter.height;
      titlePainter.paint(canvas, Offset(margin, bottomCursor));

      final picture = recorder.endRecording();
      final rendered = await picture.toImage(outW, outH);
      final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[AppShareService] _renderBrandedBannerBytes error: $e');
      return null;
    }
  }

  /// One-call unified share helper used across the entire app:
  /// Shares the branded banner image (with automatic top-right logo) + message + working deep link.
  static Future<ShareResult?> shareContent({
    required String type,
    String id = '',
    required String title,
    required String message,
    String subtitle = '',
    String badgeText = 'BHARAT PRAY',
    Color badgeColor = const Color(0xFFFF7A00),
    bool showLiveDot = false,
    List<String> imageUrls = const [],
    String? fallbackAsset,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    final String shareUrl = buildShareUrl(type: type, id: id);
    final String fullText = '$message\n\nTap to open in Bharat Pray:\n$shareUrl';
    final String effectiveSubject = subject ?? title;

    final bannerFile = await createBrandedBannerFile(
      cacheKey: '${type}_${id.isNotEmpty ? id : title.hashCode}',
      title: title,
      subtitle: subtitle,
      badgeText: badgeText,
      badgeColor: badgeColor,
      showLiveDot: showLiveDot,
      imageUrls: imageUrls,
      fallbackAsset: fallbackAsset,
    );

    if (bannerFile != null && await bannerFile.exists()) {
      // ignore: deprecated_member_use
      return await Share.shareXFiles(
        [XFile(bannerFile.path, mimeType: 'image/png', name: 'bharatpray_share.png')],
        text: fullText,
        subject: effectiveSubject,
        sharePositionOrigin: sharePositionOrigin,
      );
    }

    // ignore: deprecated_member_use
    return await Share.share(
      fullText,
      subject: effectiveSubject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
