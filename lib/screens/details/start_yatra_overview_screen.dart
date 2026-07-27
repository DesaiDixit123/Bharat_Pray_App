import 'package:bharat_pray/screens/details/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'add_temple_on_route_screen.dart';
import 'yatra_live_sangha_screen.dart';
import 'yatra_completed_screen.dart';

class StartYatraOverviewScreen extends StatelessWidget {
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
  final bool isFromCreateGroup;

  const StartYatraOverviewScreen({
    super.key,
    required this.title,
    required this.distance,
    required this.steps,
    required this.duration,
    required this.sangha,
    required this.imageAsset,
    this.isFromCreateGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: _lightBackground,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OutlineActionButton(
                label: 'Add a Temple on the Route',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddTempleOnRouteScreen(
                        title: title,
                        distance: distance,
                        steps: steps,
                        duration: duration,
                        sangha: sangha,
                        imageAsset: imageAsset,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PrimaryActionButton(
                label: 'Confirm Your Distance',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => YatraLiveSanghaScreen(
                        title: title,
                        distance: distance,
                        steps: steps,
                        duration: duration,
                        sangha: sangha,
                        imageAsset: imageAsset,
                        isFromCreateGroup: isFromCreateGroup,
                        selectedTemples: const <TempleRouteItem>[],
                        completedScreen: YatraCompletedScreen(
                          title: title,
                          distance: distance,
                          steps: steps,
                          duration: duration,
                          imageAsset: imageAsset,
                        ),
                      ),
                    ),
                  );
                },
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
                            Image.asset(
                              imageAsset,
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
                  distance: distance,
                  steps: steps,
                  duration: duration,
                  sangha: sangha,
                  mutedBrown: _mutedBrown,
                  valueColor: _statValueColor,
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
                      'The Somnath Yatra is more than a physical journey; it is a pilgrimage to the "First among Twelve Jyotirlingas." '
                      'Traversing through the rugged beauty of the Saurashtra coast, devotees walk in the footsteps of ancient sages, '
                      'seeking the eternal blessings of Lord Shiva. Experience the transformative power of the Pancha Mahabhuta '
                      'as the ocean winds carry the chants of Om Namah Shivaya.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C7660),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                      ),
                    ),
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
          side: const BorderSide(color: StartYatraOverviewScreen._accentOrange, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          foregroundColor: const Color(0xFF2E2A36),
        ),
        onPressed: onTap,
        icon: const Icon(
          Icons.add_circle_outline_rounded,
          color: StartYatraOverviewScreen._accentOrange,
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

  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: StartYatraOverviewScreen._accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onTap,
        child: Text(
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