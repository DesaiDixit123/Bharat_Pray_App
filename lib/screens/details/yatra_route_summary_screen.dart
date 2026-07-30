import 'package:bharat_pray/screens/details/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_temple_on_route_screen.dart';
import 'yatra_completed_screen.dart';
import 'yatra_live_sangha_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class YatraRouteSummaryScreen extends StatefulWidget {
  static const Color _accentOrange = Color(0xFFFF7A00);
  static const Color _mutedBrown = Color(0xFFC8A882);
  static const Color _statValueColor = Color(0xFF2E2A36);
  static const Color _lightBackground = Color(0xFFFFE8D6);

  final String title;
  final String distance;
  final String steps;
  final String duration;
  final String sangha;
  final String imageAsset;
  final List<TempleRouteItem> selectedTemples;

  const YatraRouteSummaryScreen({
    super.key,
    required this.title,
    required this.distance,
    required this.steps,
    required this.duration,
    required this.sangha,
    required this.imageAsset,
    required this.selectedTemples,
  });

  @override
  State<YatraRouteSummaryScreen> createState() => _YatraRouteSummaryScreenState();
}

class _YatraRouteSummaryScreenState extends State<YatraRouteSummaryScreen> {
  bool _isLoading = true;
  late String _distance;
  late String _steps;
  late String _duration;
  late String _sangha;
  String _overview = 'The Somnath Yatra is more than a physical journey; it is a pilgrimage to the "First among Twelve Jyotirlingas." Traversing through the rugged beauty of the Saurashtra coast, devotees walk in the footsteps of ancient sages, seeking the eternal blessings of Lord Shiva. Experience the transformative power of the Pancha Mahabhuta as the ocean winds carry the chants of Om Namah Shivaya.';

  String get _shortTitle {
    if (widget.title.trim().isEmpty) return 'Yatra';
    return widget.title.split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _distance = widget.distance;
    _steps = widget.steps;
    _duration = widget.duration;
    _sangha = widget.sangha;
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final summary = await ApiService.getJourneySummary(token);
      if (summary.isNotEmpty && mounted) {
        setState(() {
          _distance = '${summary['totalDistance'] ?? _distance}';
          _steps = '${summary['totalSteps'] ?? _steps}';
          _duration = '${summary['duration'] ?? _duration}';
          _overview = summary['overview'] ?? _overview;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YatraRouteSummaryScreen._lightBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: YatraRouteSummaryScreen._lightBackground,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: YatraRouteSummaryScreen._accentOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => YatraLiveSanghaScreen(
                      title: widget.title,
                      distance: _distance,
                      steps: _steps,
                      duration: _duration,
                      sangha: _sangha,
                      imageAsset: widget.imageAsset,
                      selectedTemples: widget.selectedTemples,
                      completedScreen: YatraCompletedScreen(
                        title: widget.title,
                        distance: _distance,
                        steps: _steps,
                        duration: _duration,
                        imageAsset: widget.imageAsset,
                      ),
                    ),
                  ),
                );
              },
              child: Text(
                'Strat your Yatra',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
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
                height: 382,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            widget.imageAsset.startsWith('http')
                                ? Image.network(
                                    widget.imageAsset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const ColoredBox(color: Colors.black),
                                  )
                                : Image.asset(
                                    widget.imageAsset,
                                    fit: BoxFit.cover,
                                  ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.14),
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.black.withValues(alpha: 0.62),
                                  ],
                                  stops: const [0.0, 0.38, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 20,
                      child: _BackButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _StatsGrid(
                  distance: _distance,
                  steps: _steps,
                  duration: _duration,
                  sangha: _sangha,
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
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _overview,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C7660),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Add a Temple on the Route to $_shortTitle',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E2A36),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RouteTimeline(temples: widget.selectedTemples),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.0),
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

  const _StatsGrid({
    required this.distance,
    required this.steps,
    required this.duration,
    required this.sangha,
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Steps',
                value: steps,
                iconAsset: AppIcons.steps,
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Sangha',
                value: sangha,
                iconAsset: AppIcons.sangha,
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

  const _StatCard({
    required this.title,
    required this.value,
    this.icon,
    this.iconAsset,
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
                      color: YatraRouteSummaryScreen._mutedBrown,
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
                    color: YatraRouteSummaryScreen._mutedBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: YatraRouteSummaryScreen._statValueColor,
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

class _RouteTimeline extends StatelessWidget {
  final List<TempleRouteItem> temples;

  const _RouteTimeline({required this.temples});

  @override
  Widget build(BuildContext context) {
    if (temples.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(temples.length, (index) {
        final temple = temples[index];
        final isLast = index == temples.length - 1;

        return SizedBox(
          height: 84,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                child: Column(
                  children: [
                    if (isLast)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF141414), width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: YatraRouteSummaryScreen._accentOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: YatraRouteSummaryScreen._accentOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: YatraRouteSummaryScreen._accentOrange,
                          margin: const EdgeInsets.only(top: 2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temple.name,
                      style: GoogleFonts.outfit(
                        color: YatraRouteSummaryScreen._accentOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      temple.schedule,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8A7769),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}