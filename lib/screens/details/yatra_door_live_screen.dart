import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'yatra_certificate_screen.dart';

class YatraDoorLiveScreen extends StatefulWidget {
  const YatraDoorLiveScreen({super.key});

  @override
  State<YatraDoorLiveScreen> createState() => _YatraDoorLiveScreenState();
}

class _YatraDoorLiveScreenState extends State<YatraDoorLiveScreen>
    with SingleTickerProviderStateMixin {
  static const String _doorClosedAsset = 'assets/images/mandir_door_closed.jpg';
  static const String _doorOpenAsset = 'assets/images/mandir_door_open.jpg';

  static const String _backArrowSvg = '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#FFFFFF"/>
</svg>''';

  late final AnimationController _controller;
  late final Animation<double> _doorOpenProgress;
  bool _certificateOpened = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _doorOpenProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCertificateScreen() {
    if (_certificateOpened || _doorOpenProgress.value <= 0.96) return;
    _certificateOpened = true;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const YatraCertificateScreen(),
      ),
    ).then((_) {
      _certificateOpened = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final panelWidth = width / 2;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta! < -10) {
                      _openCertificateScreen();
                    }
                  },
                ),
              ),
              Positioned.fill(
                child: Image.asset(
                  _doorOpenAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: Colors.black),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.0, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _doorOpenProgress,
                builder: (context, child) {
                  final progress = _doorOpenProgress.value;
                  final leftShift = -panelWidth * progress;
                  final rightShift = panelWidth * progress;
                  final leftAngle = -0.08 * progress;
                  final rightAngle = 0.08 * progress;

                  return Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: panelWidth,
                        child: Transform(
                          alignment: Alignment.centerRight,
                          transform: Matrix4.identity()
                            ..translateByDouble(leftShift, 0, 0, 1)
                            ..rotateZ(leftAngle),
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.5,
                              child: SizedBox(
                                width: width,
                                height: double.infinity,
                                child: Image.asset(
                                  _doorClosedAsset,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const ColoredBox(color: Color(0xFF3B2516)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: panelWidth,
                        child: Transform(
                          alignment: Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..translateByDouble(rightShift, 0, 0, 1)
                            ..rotateZ(rightAngle),
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.centerRight,
                              widthFactor: 0.5,
                              child: SizedBox(
                                width: width,
                                height: double.infinity,
                                child: Image.asset(
                                  _doorClosedAsset,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const ColoredBox(color: Color(0xFF3B2516)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.string(
                        _backArrowSvg,
                        width: 15,
                        height: 15,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _doorOpenProgress,
                builder: (context, child) {
                  final showLiveUi = _doorOpenProgress.value > 0.96;
                  return IgnorePointer(
                    ignoring: !showLiveUi,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      opacity: showLiveUi ? 1 : 0,
                      child: Stack(
                        children: [
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 12,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF2D3A),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.sensors,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Live',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: MediaQuery.of(context).padding.bottom + 26,
                            child: GestureDetector(
                              onTap: _openCertificateScreen,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Scroll Down',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    'See Yours Certificate.',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.70),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Icon(
                                    Icons.keyboard_double_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
