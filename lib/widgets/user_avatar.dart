import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class UserAvatar extends StatelessWidget {
  final String profilePic;
  final String userName;
  final double size;
  final double fontSize;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;

  const UserAvatar({
    super.key,
    required this.profilePic,
    required this.userName,
    this.size = 48,
    this.fontSize = 18,
    this.borderColor = const Color(0xFFFF7700),
    this.borderWidth = 1.5,
    this.backgroundColor = const Color(0xFFFFE6D5),
  });

  @override
  Widget build(BuildContext context) {
    final clean = profilePic.trim();
    final initial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'U';

    Widget fallbackWidget = Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFF7700),
        ),
      ),
    );

    Widget imageContent;

    if (clean.isEmpty) {
      imageContent = fallbackWidget;
    } else if (clean.startsWith('/') || clean.startsWith('file://')) {
      final localPath = clean.replaceFirst('file://', '');
      final file = File(localPath);
      if (file.existsSync()) {
        imageContent = Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackWidget,
        );
      } else {
        imageContent = fallbackWidget;
      }
    } else {
      final fullUrl = ApiService.resolveImageUrl(clean);
      if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
        imageContent = Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackWidget,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF7700),
                  strokeWidth: 2,
                ),
              ),
            );
          },
        );
      } else {
        imageContent = fallbackWidget;
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: ClipOval(child: imageContent),
    );
  }
}
