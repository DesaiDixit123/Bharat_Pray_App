import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/utsav_service.dart';
import 'mandal_profile_screen.dart';

class MandalLeaderboardTabContent extends StatefulWidget {
  const MandalLeaderboardTabContent({super.key});

  @override
  State<MandalLeaderboardTabContent> createState() => _MandalLeaderboardTabContentState();
}

class _MandalLeaderboardTabContentState extends State<MandalLeaderboardTabContent> {
  // State: 0 = Contest Active, 1 = Contest Ended
  int _contestState = 0;

  // Countdown timer values
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  Timer? _countdownTimer;

  // Dynamic Data
  bool _isLoading = true;
  String _festivalName = "";
  List<Map<String, dynamic>> _rankings = [];
  List<Map<String, dynamic>> _topThree = [];
  String? _userMandalName;

  bool _hasEndedFestival = false;
  Map<String, dynamic>? _completedFestival;

  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    try {
      final myReg = await UtsavService.getMyMandalRegistration();
      final data = await UtsavService.getLeaderboard();
      final allFestivals = await UtsavService.getFestivals(status: 'ALL');
      final completedList = allFestivals
          .where((f) => (f['status'] ?? '').toString().toLowerCase() == 'completed')
          .toList();

      if (mounted) {
        setState(() {
          _userMandalName = myReg?['mandalName'];
          if (data['festival'] != null && data['festival']['name'] != null) {
            _festivalName = data['festival']['name'].toString();
          } else {
            _festivalName = "";
          }
          final list = (data['rankings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _rankings = list;
          final top = (data['topThree'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _topThree = top.isNotEmpty ? top : (_rankings.take(3).toList());

          _hasEndedFestival = completedList.isNotEmpty;
          _completedFestival = completedList.isNotEmpty ? completedList.first : null;
          if (!_hasEndedFestival) {
            _contestState = 0;
          }
          _isLoading = false;
        });
        _updateCountdown(data['festival'] as Map<String, dynamic>?);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateCountdown(Map<String, dynamic>? fest) {
    _countdownTimer?.cancel();
    if (fest == null) {
      if (mounted) {
        setState(() {
          _days = 0;
          _hours = 0;
          _minutes = 0;
          _seconds = 0;
        });
      }
      return;
    }

    final endStr = (fest['endDate'] ?? fest['date'])?.toString();
    DateTime? endDate;
    if (endStr != null && endStr.isNotEmpty) {
      endDate = DateTime.tryParse(endStr);
    }

    if (endDate == null) return;

    void tick() {
      final now = DateTime.now();
      final diff = endDate!.difference(now);
      if (diff.isNegative) {
        if (mounted) {
          setState(() {
            _days = 0;
            _hours = 0;
            _minutes = 0;
            _seconds = 0;
            _hasEndedFestival = true;
          });
        }
        _countdownTimer?.cancel();
      } else {
        if (mounted) {
          setState(() {
            _days = diff.inDays;
            _hours = diff.inHours % 24;
            _minutes = diff.inMinutes % 60;
            _seconds = diff.inSeconds % 60;
          });
        }
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = 90.0 + MediaQuery.of(context).padding.bottom;

    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7700)),
        ),
      );
    }

    return Column(
      children: [
        // ── State Selector (Contest Active / Contest Ended) ──────────────────
        // Only visible when a festival contest has actually ended!
        if (_hasEndedFestival)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  _buildToggleTab("Contest Active", 0),
                  _buildToggleTab("Contest Ended", 1),
                ],
              ),
            ),
          ),

        // ── Main Body ────────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF7700),
            onRefresh: _loadLeaderboardData,
            child: (_hasEndedFestival && _contestState == 1)
                ? _buildWinnersView()
                : _buildLeaderboardView(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTab(String label, int stateVal) {
    final active = _contestState == stateVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _contestState = stateVal),
        child: Container(
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF7700) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: active ? Colors.white : const Color(0xFF8E5A2A),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. Contest Active Leaderboard View ─────────────────────────────────────

  Widget _buildLeaderboardView() {
    final bottomInset = 90.0 + MediaQuery.of(context).padding.bottom;

    if (_rankings.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset, left: 28.0, right: 28.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEAD8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.25), width: 2),
                        ),
                        child: const Icon(
                          Icons.leaderboard_outlined,
                          color: Color(0xFFFF7700),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No Active Contest Right Now",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Leaderboard rankings will be live once an active festival begins (Maha Navratri starts on 11 Oct 2026).",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                          height: 1.45,
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contest Ends Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF7E6D7)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E5A2A).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _festivalName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Contest Ends in",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeBox(_days, "Days"),
                    _buildTimeDivider(),
                    _buildTimeBox(_hours, "Hours"),
                    _buildTimeDivider(),
                    _buildTimeBox(_minutes, "Mins"),
                    _buildTimeDivider(),
                    _buildTimeBox(_seconds, "Secs"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Leaderboard list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rankings (${_rankings.length})",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              Text(
                "Score / Votes",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dynamic Rankings List
          if (_rankings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  "No mandal rankings available yet.",
                  style: GoogleFonts.outfit(color: const Color(0xFF8E5A2A)),
                ),
              ),
            )
          else
            ...List.generate(_rankings.length, (index) {
              final item = _rankings[index];
              final rank = index + 1;
              final name = (item['name'] ?? 'Mandal').toString();
              final likes = item['likes'] ?? '${item['votes'] ?? 0}';
              final shares = item['shares'] ?? '1.2K';
              final subtitle = "$likes Likes • $shares Shares";
              final score = item['votes'] != null ? '${item['votes']}' : '0';
              final isUserMandal = _userMandalName != null &&
                  _userMandalName!.trim().toLowerCase() == name.trim().toLowerCase();

              return _buildLeaderboardRow(
                rank,
                name,
                subtitle,
                score,
                imageUrl: item['imageUrl']?.toString(),
                isUserMandal: isUserMandal,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTimeBox(int val, String label) {
    final strVal = val.toString().padLeft(2, '0');
    return Column(
      children: [
        Container(
          width: 52,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEAD8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              strVal,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF7700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF8E5A2A)),
        ),
      ],
    );
  }

  Widget _buildTimeDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 12.0),
      child: Text(
        ":",
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFF7700),
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(
    int rank,
    String name,
    String subtitle,
    String score, {
    String? imageUrl,
    bool isUserMandal = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MandalProfileScreen(mandalName: name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMandal ? const Color(0xFFFFF7EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUserMandal ? const Color(0xFFFF7700).withValues(alpha: 0.4) : const Color(0xFFF3E4D6),
            width: isUserMandal ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank Number
            SizedBox(
              width: 28,
              child: Text(
                "#$rank",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? const Color(0xFFFF7700) : const Color(0xFFB59E83),
                ),
              ),
            ),

            // Mandal Avatar
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF1E5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  imageUrl != null && imageUrl.isNotEmpty ? imageUrl : 'assets/images/new_year_card.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFFFF7700),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                      ),
                      if (isUserMandal) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7700),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "YOU",
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Score
            Text(
              score,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF7700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. Contest Ended Winners View (Redesigned 3D Podium) ──────────────────

  Widget _buildWinnersView() {
    final bottomInset = 90.0 + MediaQuery.of(context).padding.bottom;

    if (!_hasEndedFestival || _topThree.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset, left: 28.0, right: 28.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEAD8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.25), width: 2),
                        ),
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          color: Color(0xFFFF7700),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No Ended Contest Yet",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Winner certificates and champions will be announced once an active festival concludes.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                          height: 1.45,
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

    final endedFestName = (_completedFestival?['name'] ?? _festivalName).toString();
    final m1 = _topThree[0];
    final m2 = _topThree.length > 1 ? _topThree[1] : null;
    final m3 = _topThree.length > 2 ? _topThree[2] : null;

    final isUserWinner = _userMandalName != null &&
        _userMandalName!.trim().toLowerCase() == (m1['name'] ?? '').toString().trim().toLowerCase();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEAD8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC8A882).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFF7700), size: 18),
                const SizedBox(width: 6),
                Text(
                  "Official Grand Winners",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8E5A2A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Text(
            "$endedFestName\nChampions",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 24),

          // ── Grand 3D Winner Podium Section ──
          if (_topThree.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF0D6BE), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E5A2A).withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row of 3 Pedestals (Rank 2 - Left, Rank 1 - Center, Rank 3 - Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2nd Place (Silver)
                      Expanded(
                        child: _buildPodiumColumn(
                          rank: 2,
                          mandal: m2,
                          height: 128,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 1st Place (Gold Champion)
                      Expanded(
                        child: _buildPodiumColumn(
                          rank: 1,
                          mandal: m1,
                          height: 165,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3rd Place (Bronze)
                      Expanded(
                        child: _buildPodiumColumn(
                          rank: 3,
                          mandal: m3,
                          height: 108,
                        ),
                      ),
                    ],
                  ),

                  // Grand Podium Stage Base Platform
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE8D5C4),
                          Color(0xFFC8A882),
                          Color(0xFFB58E62),
                          Color(0xFFC8A882),
                          Color(0xFFE8D5C4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E5A2A).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // User Mandal Winner Certificate Banner (Screen 12 navigation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUserWinner
                    ? [const Color(0xFFFFF7EF), const Color(0xFFFFE8D6)]
                    : [Colors.white, const Color(0xFFFFF9F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isUserWinner ? const Color(0xFFFF7700) : const Color(0xFFE8D4C2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E5A2A).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                      ),
                      child: const Center(
                        child: Icon(Icons.workspace_premium_rounded, color: Color(0xFFFF7700), size: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUserWinner
                                ? "Congratulations! You Won 1st Prize!"
                                : "Official Winner Certificate",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Verified digital certificate of honor & devotion.",
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7700),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MandalCertificateScreen(
                            mandalName: (m1['name'] ?? 'Mandal').toString(),
                            festivalName: endedFestName.isNotEmpty ? endedFestName : 'Festival',
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "View Winner Certificate",
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Remaining Leaderboard List (Rank 4, 5, etc.)
          if (_rankings.length > 3) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Other Participants",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2A36),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_rankings.length - 3, (i) {
              final idx = i + 3;
              final item = _rankings[idx];
              final rank = idx + 1;
              final name = (item['name'] ?? 'Mandal').toString();
              final likes = item['likes'] ?? '${item['votes'] ?? 0}';
              final shares = item['shares'] ?? '1.2K';
              final subtitle = "$likes Likes • $shares Shares";
              final score = item['votes'] != null ? '${item['votes']}' : '0';
              final isUserMandal = _userMandalName != null &&
                  _userMandalName!.trim().toLowerCase() == name.trim().toLowerCase();

              return _buildLeaderboardRow(
                rank,
                name,
                subtitle,
                score,
                imageUrl: item['imageUrl']?.toString(),
                isUserMandal: isUserMandal,
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── 3D Podium Column Widget ───────────────────────────────────────────────

  Widget _buildPodiumColumn({
    required int rank,
    required Map<String, dynamic>? mandal,
    required double height,
  }) {
    final name = (mandal?['name'] ?? 'Mandal').toString();
    final votes = mandal?['votes'] != null ? '${mandal!['votes']}' : '0';
    final imageUrl = mandal?['imageUrl']?.toString();

    // Theme configurations according to rank
    late final List<Color> gradientColors;
    late final Color borderColor;
    late final Color shadowColor;
    late final String rankLabel;
    late final IconData crownIcon;
    late final double avatarSize;

    if (rank == 1) {
      // 1st Place - Champion Gold
      gradientColors = const [
        Color(0xFFFFE082),
        Color(0xFFFFCA28),
        Color(0xFFFFA000),
        Color(0xFFFF8F00),
      ];
      borderColor = const Color(0xFFFFB300);
      shadowColor = const Color(0xFFFF8F00).withValues(alpha: 0.4);
      rankLabel = "CHAMPION";
      crownIcon = Icons.emoji_events_rounded;
      avatarSize = 72;
    } else if (rank == 2) {
      // 2nd Place - Metallic Silver
      gradientColors = const [
        Color(0xFFECEFF1),
        Color(0xFFCFD8DC),
        Color(0xFFB0BEC5),
        Color(0xFF90A4AE),
      ];
      borderColor = const Color(0xFF90A4AE);
      shadowColor = const Color(0xFF78909C).withValues(alpha: 0.35);
      rankLabel = "RUNNER UP";
      crownIcon = Icons.workspace_premium_rounded;
      avatarSize = 60;
    } else {
      // 3rd Place - Warm Bronze / Copper (Matches warm peach theme)
      gradientColors = const [
        Color(0xFFEFEBE9),
        Color(0xFFD7CCC8),
        Color(0xFFBCAAA4),
        Color(0xFFA1887F),
      ];
      borderColor = const Color(0xFFA1887F);
      shadowColor = const Color(0xFF8D6E63).withValues(alpha: 0.35);
      rankLabel = "3RD PLACE";
      crownIcon = Icons.military_tech_rounded;
      avatarSize = 58;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Trophy / Crown Icon for Rank 1
        if (rank == 1)
          Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3D0), Color(0xFFFFD54F), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(crownIcon, color: const Color(0xFF4E2C00), size: 20),
          )
        else
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(bottom: 4),
            child: Icon(crownIcon, color: borderColor, size: 18),
          ),

        // Avatar circle with Glowing 3D Frame
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MandalProfileScreen(mandalName: name),
              ),
            );
          },
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: rank == 1 ? 3.5 : 2.5),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Image.asset(
                imageUrl != null && imageUrl.isNotEmpty ? imageUrl : 'assets/images/new_year_card.png',
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => Container(
                  color: const Color(0xFFFFF1E5),
                  child: Icon(Icons.groups_rounded, color: borderColor, size: 24),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Mandal Name (Fixed height so 1 or 2 lines never push podium unevenly)
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          alignment: Alignment.center,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: rank == 1 ? 12 : 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // 3D Pedestal Body
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(rank == 1 ? 16 : 12)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Medal Seal Badge with Rank Number
              Container(
                width: rank == 1 ? 38 : 32,
                height: rank == 1 ? 38 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "$rank",
                    style: GoogleFonts.outfit(
                      fontSize: rank == 1 ? 20 : 17,
                      fontWeight: FontWeight.w900,
                      color: rank == 1
                          ? const Color(0xFFFF8F00)
                          : (rank == 2 ? const Color(0xFF607D8B) : const Color(0xFF8D6E63)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Rank Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rankLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),

              // Votes counter at bottom of pedestal
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "$votes Votes",
                  style: GoogleFonts.outfit(
                    fontSize: rank == 1 ? 11 : 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        color: Colors.black38,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 3. Winner Certificate View Screen (Screen 12) ───────────────────────────

class MandalCertificateScreen extends StatelessWidget {
  final String mandalName;
  final String festivalName;
  const MandalCertificateScreen({
    super.key,
    this.mandalName = 'Mandal',
    this.festivalName = 'Utsav Mahotsav',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
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
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFC8A882), size: 16),
              ),
            ),
          ),
        ),
        title: Text(
          'Certificate',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  // 1. Outer Container (Double Gold Border gap simulation)
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    // 2. Inner Container
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Ornate corner flourishes (filter_vintage_outlined simulates original visual)
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Icon(Icons.filter_vintage_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.8), size: 16),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Transform.rotate(
                              angle: 1.57,
                              child: Icon(Icons.filter_vintage_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.8), size: 16),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            left: 2,
                            child: Transform.rotate(
                              angle: 4.71,
                              child: Icon(Icons.filter_vintage_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.8), size: 16),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Transform.rotate(
                              angle: 3.14,
                              child: Icon(Icons.filter_vintage_outlined, color: const Color(0xFFD4AF37).withValues(alpha: 0.8), size: 16),
                            ),
                          ),

                          // Certificate Contents
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 12),
                              // Title (Serif style)
                              Text(
                                "WINNER CERTIFICATE",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF8E5A2A),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                festivalName,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Presented to
                              Text(
                                "Presented to",
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                mandalName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // For Securing
                              Text(
                                "For Securing",
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "1st Position",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Appreciation Description
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  "We appreciate your devotion, enthusiasm and participation.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF2E2A36).withValues(alpha: 0.85),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 38),

                              // Seal and Signatures row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left Signature (Cursive signature text overlay)
                                  Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Text(
                                            "Indrane",
                                            style: GoogleFonts.dancingScript(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -4,
                                            child: Container(width: 60, height: 1, color: const Color(0xFFC8A882)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Chairman",
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Center Gold Seal Medallion with Ribbons
                                  Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        bottom: -18,
                                        left: -4,
                                        child: Transform.rotate(
                                          angle: -0.25,
                                          child: CustomPaint(
                                            size: const Size(12, 28),
                                            painter: RibbonTailPainter(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -18,
                                        right: -4,
                                        child: Transform.rotate(
                                          angle: 0.25,
                                          child: CustomPaint(
                                            size: const Size(12, 28),
                                            painter: RibbonTailPainter(),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFF7C844), Color(0xFFD4AF37), Color(0xFFB38F1F)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          border: Border.all(color: const Color(0xFFA67C1E), width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFFA67C1E).withValues(alpha: 0.5), width: 1),
                                            ),
                                            child: const Icon(
                                              Icons.emoji_events_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Right Signature (Cursive signature text overlay)
                                  Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Text(
                                            "OohSheeren",
                                            style: GoogleFonts.dancingScript(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -4,
                                            child: Container(width: 60, height: 1, color: const Color(0xFFC8A882)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Trustee",
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Download and Share buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    // Download Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Certificate saved to Gallery!",
                                  style: GoogleFonts.outfit(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF2E2A36),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                            "Download",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Share Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Preparing certificate link to share...",
                                  style: GoogleFonts.outfit(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF2E2A36),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            "Share",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
      ),
    );
  }
}

// ─── Ribbon Tail Painter (Draws the realistic gold ribbons under the seal) ─

class RibbonTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFA67C1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height - 6); // Notched end
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
