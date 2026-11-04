import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/localized_api_helper.dart';
import '../../models/bhajan_track_item.dart';
import '../../services/bhajan_audio_service.dart';
import '../../services/bhajan_library_service.dart';
import '../../widgets/bhajan/bhajan_mini_player_widget.dart';
import 'bhajan_now_playing_screen.dart';

class BhajanLibraryHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const BhajanLibraryHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<BhajanLibraryHubScreen> createState() => _BhajanLibraryHubScreenState();
}

class _BhajanLibraryHubScreenState extends State<BhajanLibraryHubScreen> {
  late int _selectedTab;
  String _token = '';
  String? _expandedPlaylistId;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFE8D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _initHub();
  }

  Future<void> _initHub() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    await BhajanLibraryService.instance.init(token: _token);
    if (mounted && BhajanLibraryService.instance.playlists.isNotEmpty) {
      setState(() {
        _expandedPlaylistId = BhajanLibraryService.instance.playlists.first.id;
      });
    }
  }

  void _playTrack(BhajanTrackItem track, List<BhajanTrackItem> queue) {
    BhajanLibraryService.instance.recordRecentPlay(track);
    BhajanAudioService.instance.playTrack(track, queue: queue, token: _token);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BhajanNowPlayingScreen(
          currentTrack: track,
          queue: queue,
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8F2),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFFFD8B3), width: 1.5),
          ),
          title: Text(
            LocalizedApiHelper.parse('Create New Playlist'),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.outfit(color: const Color(0xFF2E2A36)),
            decoration: InputDecoration(
              hintText: LocalizedApiHelper.parse('Enter playlist name...'),
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF8C7B6E), fontSize: 13.5),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEFE6DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFF7700)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                LocalizedApiHelper.parse('Cancel'),
                style: GoogleFonts.outfit(color: const Color(0xFF8C7B6E), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                final pl = await BhajanLibraryService.instance.createPlaylist(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  setState(() {
                    _selectedTab = 1;
                    _expandedPlaylistId = pl.id;
                  });
                  BhajanLibraryService.showLightSnackBar(
                    this.context,
                    '${LocalizedApiHelper.parse("Created playlist")} "${pl.name}"',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                LocalizedApiHelper.parse('Create'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFE8D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        body: SafeArea(
          top: true,
          child: AnimatedBuilder(
            animation: BhajanLibraryService.instance,
            builder: (context, _) {
              final lib = BhajanLibraryService.instance;

              return Column(
                children: [
                  // Top Bar (Matches BhajanDashboardScreen theme 100%)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: _buildHeader(),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Theme-Based Header Card & 4-Circle Stats Row
                          _buildProfileStyleStatsCard(lib),
                          const SizedBox(height: 22),

                          // 2. Active Section Content
                          if (_selectedTab == 0) _buildLikedSection(lib.likedTracks),
                          if (_selectedTab == 1) _buildPlaylistsSection(lib.playlists),
                          if (_selectedTab == 2) _buildDownloadsSection(lib.downloadedTracks),
                          if (_selectedTab == 3) _buildRecentSection(lib.recentTracks),
                        ],
                      ),
                    ),
                  ),
                  const BhajanMiniPlayerWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
            ),
            child: const Center(
              child: Icon(Icons.arrow_back_rounded, color: Color(0xFFC8A882), size: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizedApiHelper.parse('My Bhajan Library'),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              Text(
                LocalizedApiHelper.parse('Liked bhajans, playlists & saved audio'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF8C7B6E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStyleStatsCard(BhajanLibraryService lib) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0DFCE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                ),
                child: const Center(
                  child: Icon(Icons.library_music_rounded, color: Color(0xFFFF7700), size: 23),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizedApiHelper.parse('Devotional Collection'),
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocalizedApiHelper.parse('Liked bhajans, playlists & saved audio'),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF8C7B6E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3E4D6), height: 1),
          const SizedBox(height: 16),

          // Theme-Based 4 Circular Stats Row (Clean vector icons instead of system emojis)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCircleItem(
                index: 0,
                count: '${lib.likedTracks.length}',
                label: LocalizedApiHelper.parse('Liked'),
                icon: Icons.favorite_rounded,
              ),
              _buildStatCircleItem(
                index: 1,
                count: '${lib.playlists.length}',
                label: LocalizedApiHelper.parse('Playlists'),
                icon: Icons.queue_music_rounded,
              ),
              _buildStatCircleItem(
                index: 2,
                count: '${lib.downloadedTracks.length}',
                label: LocalizedApiHelper.parse('Downloads'),
                icon: Icons.download_rounded,
              ),
              _buildStatCircleItem(
                index: 3,
                count: '${lib.recentTracks.length}',
                label: LocalizedApiHelper.parse('Recent'),
                icon: Icons.history_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCircleItem({
    required int index,
    required String count,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF7700) : const Color(0xFFFFF8F2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFFF7700) : const Color(0xFFC8A882),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : const Color(0xFFC8A882),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFFFF7700) : const Color(0xFF2E2A36),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFFFF7700) : const Color(0xFF8C7B6E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitleRow({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF8C7B6E),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildPlayAllButton(List<BhajanTrackItem> tracks) {
    if (tracks.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _playTrack(tracks.first, tracks),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7700),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7700).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              LocalizedApiHelper.parse('Play All'),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedSection(List<BhajanTrackItem> liked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleRow(
          title: LocalizedApiHelper.parse('Favourite Bhajans'),
          subtitle: '${liked.length} ${LocalizedApiHelper.parse("Bhajans")}',
          trailing: _buildPlayAllButton(liked),
        ),
        const SizedBox(height: 14),
        if (liked.isEmpty)
          _buildEmptyCard(
            icon: Icons.favorite_border_rounded,
            title: LocalizedApiHelper.parse('No liked bhajans yet'),
            subtitle: LocalizedApiHelper.parse('Tap the heart icon on any bhajan to save it here'),
          )
        else
          ...liked.map((track) => _buildTrackTile(track, liked)),
      ],
    );
  }

  Widget _buildPlaylistsSection(List<BhajanPlaylistModel> playlists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleRow(
          title: LocalizedApiHelper.parse('My Playlists'),
          subtitle: '${playlists.length} ${LocalizedApiHelper.parse("Playlists")}',
          trailing: GestureDetector(
            onTap: _showCreatePlaylistDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF7700)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Color(0xFFFF7700), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    LocalizedApiHelper.parse('New Playlist'),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF7700),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...playlists.map((pl) {
          final isExpanded = _expandedPlaylistId == pl.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpanded ? const Color(0xFFFF7700).withValues(alpha: 0.5) : const Color(0xFFEFE6DB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  onTap: () {
                    setState(() {
                      _expandedPlaylistId = isExpanded ? null : pl.id;
                    });
                  },
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5EB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                    ),
                    child: Center(
                      child: Icon(
                        pl.id == 'default_listen_later'
                            ? Icons.watch_later_outlined
                            : Icons.queue_music_rounded,
                        color: const Color(0xFFFF7700),
                        size: 22,
                      ),
                    ),
                  ),
                  title: Text(
                    LocalizedApiHelper.parse(pl.name),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                  ),
                  subtitle: Text(
                    '${pl.tracks.length} ${LocalizedApiHelper.parse("Bhajans")}',
                    style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF8C7B6E)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pl.tracks.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF7700), size: 32),
                          onPressed: () => _playTrack(pl.tracks.first, pl.tracks),
                        ),
                      if (!pl.isDefault)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF8C7B6E), size: 20),
                          onPressed: () {
                            BhajanLibraryService.instance.deletePlaylist(pl.id);
                          },
                        ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF8C7B6E),
                      ),
                    ],
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(color: Color(0xFFF3E4D6), height: 1),
                  if (pl.tracks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        LocalizedApiHelper.parse('No bhajans in this playlist yet. Use "Add to Playlist" on any bhajan!'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF8C7B6E)),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        children: pl.tracks.map((track) {
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            onTap: () => _playTrack(track, pl.tracks),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildArtwork(track.imagePath, 42, 42),
                            ),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            subtitle: Text(
                              track.singer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF8C7B6E)),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE53935), size: 20),
                              onPressed: () {
                                BhajanLibraryService.instance.toggleTrackInPlaylist(pl.id, track);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDownloadsSection(List<BhajanTrackItem> downloads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleRow(
          title: LocalizedApiHelper.parse('Offline Downloads'),
          subtitle: '${downloads.length} ${LocalizedApiHelper.parse("Bhajans")}',
          trailing: _buildPlayAllButton(downloads),
        ),
        const SizedBox(height: 14),
        if (downloads.isEmpty)
          _buildEmptyCard(
            icon: Icons.download_for_offline_outlined,
            title: LocalizedApiHelper.parse('No downloads yet'),
            subtitle: LocalizedApiHelper.parse('Download bhajans from the 3-dots menu to listen offline'),
          )
        else
          ...downloads.map((track) => _buildTrackTile(track, downloads, isDownloadTab: true)),
      ],
    );
  }

  Widget _buildRecentSection(List<BhajanTrackItem> recents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleRow(
          title: LocalizedApiHelper.parse('Recently Played'),
          subtitle: '${recents.length} ${LocalizedApiHelper.parse("Bhajans")}',
          trailing: _buildPlayAllButton(recents),
        ),
        const SizedBox(height: 14),
        if (recents.isEmpty)
          _buildEmptyCard(
            icon: Icons.history_rounded,
            title: LocalizedApiHelper.parse('No recent bhajans'),
            subtitle: LocalizedApiHelper.parse('Bhajans you listen to will appear here automatically'),
          )
        else
          ...recents.map((track) => _buildTrackTile(track, recents)),
      ],
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7700).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF7700), size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFF8C7B6E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(
    BhajanTrackItem track,
    List<BhajanTrackItem> queue, {
    bool isDownloadTab = false,
  }) {
    final lib = BhajanLibraryService.instance;
    final isLiked = lib.isLiked(track.id);
    final isDownloaded = lib.isDownloaded(track.id);
    final isDownloading = lib.isDownloading(track.id);
    final downloadPct = lib.getDownloadPercentage(track.id);
    final localCover = lib.getLocalImagePath(track.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () => _playTrack(track, queue),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildArtwork(localCover ?? track.imagePath, 50, 50),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E2A36),
          ),
        ),
        subtitle: Row(
          children: [
            if (isDownloading) ...[
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    value: (downloadPct / 100.0).clamp(0.02, 1.0),
                    strokeWidth: 1.8,
                    backgroundColor: const Color(0xFFEBD7C2),
                    color: const Color(0xFFFF7700),
                  ),
                ),
              ),
              Text(
                '$downloadPct% ',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF7700),
                ),
              ),
            ] else if (isDownloadTab || isDownloaded) ...[
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.download_done_rounded,
                  size: 14,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
            Expanded(
              child: Text(
                '${track.singer}${track.duration != null ? " • ${track.duration}" : ""}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF8C7B6E),
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? const Color(0xFFE53935) : const Color(0xFF8C7B6E),
                size: 21,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                BhajanLibraryService.instance.toggleLike(track, token: _token);
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF4A3A2C), size: 21),
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFF0DFCE)),
              ),
              elevation: 6,
              onSelected: (action) async {
                if (action == 'playlist') {
                  BhajanLibraryService.showAddToPlaylistSheet(context, track);
                } else if (action == 'share') {
                  final shareText = '🙏 Listen to divine bhajan "${track.title}" by ${track.singer} on Bharat Pray app!';
                  await Share.share(shareText, subject: track.title);
                } else if (action == 'remove_download') {
                  await BhajanLibraryService.instance.removeDownload(track.id);
                  if (mounted) {
                    BhajanLibraryService.showLightSnackBar(
                      context,
                      '${LocalizedApiHelper.parse("Removed from Downloads")}: "${track.title}"',
                      icon: Icons.delete_outline_rounded,
                    );
                  }
                } else if (action == 'download') {
                  if (lib.isDownloaded(track.id) || lib.isDownloading(track.id)) return;
                  final completed = await BhajanLibraryService.instance.downloadTrack(track, token: _token);
                  if (completed && mounted) {
                    BhajanLibraryService.showLightSnackBar(
                      context,
                      '${LocalizedApiHelper.parse("Saved to Offline Downloads")}: ${track.title}',
                      icon: Icons.download_done_rounded,
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'playlist',
                  child: Row(
                    children: [
                      const Icon(Icons.playlist_add_rounded, size: 20, color: Color(0xFFFF7700)),
                      const SizedBox(width: 10),
                      Text(
                        LocalizedApiHelper.parse('Add to Playlist'),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDownloadTab)
                  PopupMenuItem(
                    value: 'remove_download',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFE53935)),
                        const SizedBox(width: 10),
                        Text(
                          LocalizedApiHelper.parse('Remove from Downloads'),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  PopupMenuItem(
                    value: 'download',
                    enabled: !isDownloaded && !isDownloading,
                    child: Row(
                      children: [
                        Icon(
                          isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                          size: 20,
                          color: isDownloaded ? const Color(0xFF4CAF50) : const Color(0xFFFF7700),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isDownloading
                              ? 'Downloading $downloadPct%...'
                              : (isDownloaded
                                  ? LocalizedApiHelper.parse('Downloaded')
                                  : LocalizedApiHelper.parse('Download')),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDownloaded
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2E2A36),
                          ),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded, size: 20, color: Color(0xFFFF7700)),
                      const SizedBox(width: 10),
                      Text(
                        LocalizedApiHelper.parse('Share'),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(String path, double width, double height) {
    if (path.isNotEmpty && !path.startsWith('http') && !path.startsWith('assets/')) {
      final f = File(path);
      if (f.existsSync()) {
        return Image.file(
          f,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackArt(width, height),
        );
      }
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArt(width, height),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackArt(width, height),
      );
    }
    return _fallbackArt(width, height);
  }

  Widget _fallbackArt(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF6E8DC),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 22),
      ),
    );
  }
}
