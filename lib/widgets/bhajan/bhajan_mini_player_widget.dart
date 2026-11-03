import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/bhajan_track_item.dart';
import '../../screens/details/bhajan_now_playing_screen.dart';
import '../../services/bhajan_audio_service.dart';

class BhajanMiniPlayerWidget extends StatelessWidget {
  final double bottomMargin;

  const BhajanMiniPlayerWidget({
    super.key,
    this.bottomMargin = 10,
  });

  @override
  Widget build(BuildContext context) {
    final audioService = BhajanAudioService.instance;

    return ValueListenableBuilder<BhajanTrackItem?>(
      valueListenable: audioService.currentTrackNotifier,
      builder: (context, track, child) {
        if (track == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.fromLTRB(14, 0, 14, bottomMargin),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0DFCE), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A2511).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BhajanNowPlayingScreen(
                        currentTrack: track,
                        queue: audioService.queue,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thin progress indicator bar on top edge
                    _buildProgressBar(audioService),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: Row(
                        children: [
                          // Track Artwork / Deity Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildArtwork(track.imagePath),
                          ),
                          const SizedBox(width: 10),

                          // Track Title & Artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2E2A36),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  track.singer.isNotEmpty ? track.singer : 'Devotional Melody',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF7A6858),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Playback Controls (Prev, Play/Pause, Next, Cancel)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Previous
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                color: const Color(0xFF7A6858),
                                iconSize: 22,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () => audioService.previous(),
                              ),

                              // Play / Pause Toggle
                              ValueListenableBuilder<PlayerState>(
                                valueListenable: audioService.playerStateNotifier,
                                builder: (context, state, _) {
                                  final isPlaying = state == PlayerState.playing;
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: audioService.isBufferingNotifier,
                                    builder: (context, isBuffering, _) {
                                      if (isBuffering) {
                                        return const SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: Padding(
                                            padding: EdgeInsets.all(6),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7700)),
                                            ),
                                          ),
                                        );
                                      }
                                      return Container(
                                        width: 34,
                                        height: 34,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFFF7700),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          ),
                                          color: Colors.white,
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          onPressed: () => audioService.togglePlayPause(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),

                              // Next
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                color: const Color(0xFF7A6858),
                                iconSize: 22,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () => audioService.next(),
                              ),

                              const SizedBox(width: 4),

                              // Clear Close / Cancel Button (X) to dismiss and stop
                              Tooltip(
                                message: 'Close Player',
                                child: InkWell(
                                  onTap: () => audioService.stop(),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3EAE0),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFDFCCBA), width: 0.9),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Color(0xFF6E5A4A),
                                    ),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BhajanAudioService audioService) {
    return ValueListenableBuilder<Duration>(
      valueListenable: audioService.positionNotifier,
      builder: (context, pos, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: audioService.durationNotifier,
          builder: (context, dur, _) {
            final progress = (dur.inSeconds > 0) ? (pos.inSeconds / dur.inSeconds).clamp(0.0, 1.0) : 0.0;
            return LinearProgressIndicator(
              value: progress,
              minHeight: 2.5,
              backgroundColor: const Color(0xFFF0DFCE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7700)),
            );
          },
        );
      },
    );
  }

  Widget _buildArtwork(String imagePath) {
    const double size = 44;

    if (imagePath.startsWith('data:image')) {
      try {
        final commaIdx = imagePath.indexOf(',');
        final base64Str = commaIdx != -1 ? imagePath.substring(commaIdx + 1) : imagePath;
        return Image.memory(
          base64Decode(base64Str),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackArtwork(size),
        );
      } catch (_) {
        return _fallbackArtwork(size);
      }
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArtwork(size),
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArtwork(size),
      );
    }

    return _fallbackArtwork(size);
  }

  Widget _fallbackArtwork(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFFFF0E0),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 22),
      ),
    );
  }
}
