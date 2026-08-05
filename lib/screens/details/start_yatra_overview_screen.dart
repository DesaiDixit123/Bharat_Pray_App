import 'dart:convert';
import 'dart:io';
import 'package:bharat_pray/screens/details/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'add_temple_on_route_screen.dart';
import 'yatra_live_sangha_screen.dart';
import 'yatra_completed_screen.dart';

class StartYatraOverviewScreen extends StatefulWidget {
  static const Color accentOrange = Color(0xFFFF7A00);
  static const Color mutedBrown = Color(0xFFC8A882);
  static const Color statValueColor = Color(0xFF2E2A36);
  static const Color lightBackground = Color(0xFFFFE8D6);

  final String id;
  final String title;
  final String routeName;
  final String distance;
  final String steps;
  final String duration;
  final String sangha;
  final String imageAsset;
  final bool isFromCreateGroup;
  final List<dynamic>? routeTemples;

  const StartYatraOverviewScreen({
    super.key,
    this.id = '',
    required this.title,
    this.routeName = '',
    required this.distance,
    required this.steps,
    required this.duration,
    required this.sangha,
    required this.imageAsset,
    this.isFromCreateGroup = false,
    this.routeTemples,
  });

  @override
  State<StartYatraOverviewScreen> createState() => _StartYatraOverviewScreenState();
}

class _StartYatraOverviewScreenState extends State<StartYatraOverviewScreen> {
  bool _isLoading = false;
  List<TempleRouteItem> _addedRouteTemples = [];

  void _startLiveYatra() async {
    setState(() { _isLoading = true; });
    String journeyId = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty) {
        final result = await ApiService.startYatra(token, widget.id);
        journeyId = result['_id'] ?? '';
      }
    } catch (e) {
      debugPrint('Error starting yatra: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => YatraLiveSanghaScreen(
              journeyId: journeyId,
              title: widget.title,
              distance: widget.distance,
              steps: widget.steps,
              duration: widget.duration,
              sangha: widget.sangha,
              imageAsset: widget.imageAsset,
              isFromCreateGroup: widget.isFromCreateGroup,
              selectedTemples: _addedRouteTemples,
              routeTemples: widget.routeTemples,
              completedScreen: YatraCompletedScreen(
                journeyId: journeyId,
                title: widget.title,
                distance: widget.distance,
                steps: widget.steps,
                duration: widget.duration,
                imageAsset: widget.imageAsset,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddTemples() async {
    final result = await Navigator.of(context).push<List<TempleRouteItem>>(
      MaterialPageRoute(
        builder: (context) => AddTempleOnRouteScreen(
          title: widget.title,
          distance: widget.distance,
          steps: widget.steps,
          duration: widget.duration,
          sangha: widget.sangha,
          imageAsset: widget.imageAsset,
          initialSelectedTemples: _addedRouteTemples,
          routeTemplesData: widget.routeTemples,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _addedRouteTemples = result;
      });
    }
  }

  String _getDestinationName() {
    String startName = '';
    if (widget.routeName.contains(' to ')) {
      startName = widget.routeName.split(' to ').first.trim();
    } else if (widget.title.isNotEmpty) {
      startName = widget.title.trim();
    }
    startName = startName.replaceAll(RegExp(r'\s*yatra', caseSensitive: false), '').trim();
    return startName.isNotEmpty ? ' to $startName' : '';
  }

  Widget _buildHeaderImage(String asset) {
    if (asset.isEmpty) {
      return Image.asset('assets/images/somnath_temple_new.png', fit: BoxFit.cover);
    }
    if (asset.startsWith('/') || asset.contains('/')) {
      try {
        final file = File(asset);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      } catch (_) {}
    }
    if (asset.startsWith('data:image') || (asset.length > 100 && !asset.startsWith('http') && !asset.startsWith('assets/'))) {
      try {
        final bytes = base64Decode(asset.contains(',') ? asset.split(',').last : asset);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    if (asset.startsWith('http')) {
      return Image.network(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/somnath_temple_new.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/somnath_temple_new.png',
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StartYatraOverviewScreen.lightBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: StartYatraOverviewScreen.lightBackground,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OutlineActionButton(
                label: 'Add a Temple on the Route',
                onTap: _navigateToAddTemples,
              ),
              const SizedBox(height: 12),
              _PrimaryActionButton(
                label: 'Confirm Your Distance',
                isLoading: _isLoading,
                onTap: _startLiveYatra,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildHeaderImage(widget.imageAsset),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.35),
                                    Colors.black.withOpacity(0.15),
                                    Colors.black.withOpacity(0.75),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: _BackButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title.isNotEmpty ? widget.title : (widget.routeName.isNotEmpty ? widget.routeName : 'Yatra Overview'),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(offset: Offset(0, 2), blurRadius: 6, color: Colors.black54),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.routeName.isNotEmpty && widget.routeName != widget.title) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Color(0xFFFF7700), size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.routeName,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _StatsGrid(
                  distance: widget.distance,
                  steps: widget.steps.replaceAll(RegExp(r'\s*steps', caseSensitive: false), '').trim(),
                  duration: widget.duration,
                  sangha: widget.sangha,
                  mutedBrown: StartYatraOverviewScreen.mutedBrown,
                  valueColor: StartYatraOverviewScreen.statValueColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sacred Overview',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E2A36),
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The ${widget.routeName.isNotEmpty ? widget.routeName : (widget.title.isNotEmpty ? widget.title : "Yatra")} is more than a physical journey; it is a pilgrimage to sacred divine shrines. '
                      'Traversing through holy paths, devotees walk in the footsteps of ancient sages, '
                      'seeking eternal blessings. Experience the transformative power of spiritual devotion '
                      'as chants echo along your path.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C7660),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add a Temple on the Route${_getDestinationName()}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF6B3A0A),
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildExactRouteTimeline(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExactRouteTimeline() {
    if (_addedRouteTemples.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFE6DB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.place_outlined, color: Color(0xFFFF7700), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No route temple stops added yet. Tap "Add a Temple on the Route" below to add stops.',
                style: GoogleFonts.outfit(color: const Color(0xFF8C7660), fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _addedRouteTemples.length; i++)
          _buildExactTimelineNode(
            temple: _addedRouteTemples[i],
            index: i,
            isLast: i == _addedRouteTemples.length - 1,
          ),
      ],
    );
  }

  Widget _buildExactTimelineNode({
    required TempleRouteItem temple,
    required int index,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 3),
                isLast
                    ? Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7700),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7700),
                          shape: BoxShape.circle,
                        ),
                      ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFFF7700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          temple.name,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF7700),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          temple.schedule.isNotEmpty ? temple.schedule : '${temple.distance} • Stop ${index + 1}',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFC8A882),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFFF7700), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _addedRouteTemples.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  static const String _backArrowSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#FFFFFF"/>
</svg>''';

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.0),
        ),
        child: Center(
          child: SvgPicture.string(
            _backArrowSvg,
            width: 15,
            height: 15,
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final String distance;
  final String steps;
  final String duration;
  final String sangha;
  final Color mutedBrown;
  final Color valueColor;

  const _StatsGrid({
    required this.distance,
    required this.steps,
    required this.duration,
    required this.sangha,
    required this.mutedBrown,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Distance',
                value: distance,
                iconAsset: AppIcons.distance,
                mutedBrown: mutedBrown,
                valueColor: valueColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Steps',
                value: steps,
                iconAsset: AppIcons.steps,
                mutedBrown: mutedBrown,
                valueColor: valueColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Duration',
                value: duration,
                iconAsset: AppIcons.duration,
                mutedBrown: mutedBrown,
                valueColor: valueColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Sangha',
                value: sangha,
                iconAsset: AppIcons.sangha,
                mutedBrown: mutedBrown,
                valueColor: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final String? iconAsset;
  final Color mutedBrown;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    this.icon,
    this.iconAsset,
    required this.mutedBrown,
    required this.valueColor,
  }) : assert(icon != null || iconAsset != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7B28C), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF7EFE4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: iconAsset != null
                  ? SvgPicture.asset(
                      iconAsset!,
                      width: 22,
                      height: 22,
                    )
                  : Icon(
                      icon,
                      color: mutedBrown,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: mutedBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: StartYatraOverviewScreen.accentOrange, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          foregroundColor: const Color(0xFF2E2A36),
        ),
        onPressed: onTap,
        icon: const Icon(
          Icons.add_circle_outline_rounded,
          color: StartYatraOverviewScreen.accentOrange,
        ),
        label: Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: StartYatraOverviewScreen.accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}