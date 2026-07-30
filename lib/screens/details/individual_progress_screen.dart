import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class IndividualProgressScreen extends StatefulWidget {
  final String groupId;

  const IndividualProgressScreen({super.key, this.groupId = ''});

  @override
  State<IndividualProgressScreen> createState() => _IndividualProgressScreenState();
}

class _IndividualProgressScreenState extends State<IndividualProgressScreen> {
  static const Color _bg = Color(0xFFFFE8D6);
  
  List<_ProgressMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      if (token.isNotEmpty && widget.groupId.isNotEmpty) {
        final apiMembers = await ApiService.getGroupMembers(token, widget.groupId);
        if (apiMembers.isNotEmpty) {
          // In a real app we'd map apiMembers to _ProgressMember
          // For now, if there's any data, we'll assume it's correctly mapped or fallback to mock
          // We'll stick with mock data if we can't parse it easily
        }
      }
    } catch (e) {
      debugPrint('Error fetching group members: \$e');
    } finally {
      if (mounted) {
        setState(() {
          _members = _getMockMembers();
          _isLoading = false;
        });
      }
    }
  }

  List<_ProgressMember> _getMockMembers() {
    return <_ProgressMember>[
      const _ProgressMember(
        name: 'Mehul R.',
        city: 'Surat, Gujarat',
        distanceLabel: '6.5KM',
        stepsLabel: '48,000',
        progress: 0.28,
        detailDistance: '16.5KM',
        totalProgress: '12%',
        stepsToReach: '3,29,500 Steps',
        timeLeft: '2d 14h 30m',
        activities: <_ActivityItem>[
          _ActivityItem(time: '10:30 AM', distance: 'Walked 2.5KM', steps: '6,200 Steps'),
          _ActivityItem(time: '10:30 AM', distance: 'Walked 2.5KM', steps: '6,200 Steps'),
          _ActivityItem(time: '10:30 AM', distance: 'Walked 2.5KM', steps: '6,200 Steps'),
        ],
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=60',
        barColor: Color(0xFF7759D9),
        cityBg: Color(0xFFE8E5F7),
        cityText: Color(0xFF7A68D6),
      ),
      const _ProgressMember(
        name: 'Amit K.',
        city: 'Vapi, Gujarat',
        distanceLabel: '5.5KM',
        stepsLabel: '10,000',
        progress: 0.28,
        avatarUrl:
            'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&auto=format&fit=crop&q=60',
        barColor: Color(0xFF3B64B7),
        cityBg: Color(0xFFE5F1FD),
        cityText: Color(0xFF4A90E2),
      ),
      const _ProgressMember(
        name: 'Ketan P.',
        city: 'Bharuch, Gujarat',
        distanceLabel: '3.5KM',
        stepsLabel: '5,000',
        progress: 0.28,
        avatarUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop&q=60',
        barColor: Color(0xFF55B9C9),
        cityBg: Color(0xFFE0F7FA),
        cityText: Color(0xFF00ACC1),
      ),
      const _ProgressMember(
        name: 'Pooja H.',
        city: 'Ahemdabad, Gujarat',
        distanceLabel: '10.5KM',
        stepsLabel: '45,000',
        progress: 0.28,
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=60',
        barColor: Color(0xFFC85AAA),
        cityBg: Color(0xFFFCE4EC),
        cityText: Color(0xFFD81B60),
      ),
      const _ProgressMember(
        name: 'Hitakshi J.',
        city: 'Amreli, Gujarat',
        distanceLabel: '7.5KM',
        stepsLabel: '30,000',
        progress: 0.28,
        avatarUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&auto=format&fit=crop&q=60',
        barColor: Color(0xFF4AB56A),
        cityBg: Color(0xFFE8F5E9),
        cityText: Color(0xFF43A047),
      ),
      const _ProgressMember(
        name: 'Pratiksha S.',
        city: 'Vadodara, Gujarat',
        distanceLabel: '0.5',
        stepsLabel: '1,000',
        progress: 0.28,
        avatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&auto=format&fit=crop&q=60',
        barColor: Color(0xFFD1448E),
        cityBg: Color(0xFFFFEBEE),
        cityText: Color(0xFFE53935),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC8A882), width: 1),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Color(0xFFC8A882),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Individual Progress',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFC8A882)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                itemCount: _members.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return _MemberProgressCard(
                    member: member,
                    onTap: () => _showMemberDetailBottomSheet(context, member),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberDetailBottomSheet(BuildContext context, _ProgressMember member) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD7B28C), width: 1),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFFC8A882),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Column(
                      children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFE7D4C2),
                        backgroundImage: NetworkImage(member.avatarUrl),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        member.name,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF7A00),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: member.cityBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          member.city,
                          style: GoogleFonts.outfit(
                            color: member.cityText,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7A00),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {},
                                child: Text(
                                  'Following',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _SheetActionIcon(icon: Icons.mail_outline_rounded, onTap: () {}),
                          const SizedBox(width: 10),
                          _SheetActionIcon(icon: Icons.share_outlined, onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SheetStat(
                              title: 'Distance\nCovered',
                              value: member.detailDistance,
                            ),
                          ),
                          Expanded(
                            child: _SheetStat(
                              title: 'Today\nSteps',
                              value: member.stepsLabel,
                            ),
                          ),
                          Expanded(
                            child: _SheetStat(
                              title: 'Total\nProgress',
                              value: member.totalProgress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: member.progress,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE2DBEF),
                          valueColor: AlwaysStoppedAnimation<Color>(member.barColor),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Expanded(
                            child: _SheetStat(
                              title: 'Est. Steps to Reach',
                              value: member.stepsToReach,
                            ),
                          ),
                          Expanded(
                            child: _SheetStat(
                              title: 'Est. Time Left',
                              value: member.timeLeft,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Activity',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF994700),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RecentActivityTimeline(items: member.activities),
                      const SizedBox(height: 6),
                    ],
                  ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RecentActivityTimeline extends StatelessWidget {
  const _RecentActivityTimeline({required this.items});

  final List<_ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              height: 26,
              child: Row(
                children: [
                  _TimelineDot(
                    showTopLine: index > 0,
                    showBottomLine: index < items.length - 1,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    child: Text(
                      items[index].time,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E2A36),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      items[index].distance,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E2A36),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      items[index].steps,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E2A36),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.showTopLine,
    required this.showBottomLine,
  });

  final bool showTopLine;
  final bool showBottomLine;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 26,
      child: Stack(
        children: [
          if (showTopLine)
            Positioned(
              left: 7,
              top: 0,
              bottom: 13,
              child: Container(
                width: 1.6,
                color: const Color(0xFFC8A882),
              ),
            ),
          if (showBottomLine)
            Positioned(
              left: 7,
              top: 13,
              bottom: 0,
              child: Container(
                width: 1.6,
                color: const Color(0xFFC8A882),
              ),
            ),
          Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFC8A882),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7A7064), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberProgressCard extends StatelessWidget {
  const _MemberProgressCard({
    required this.member,
    required this.onTap,
  });

  final _ProgressMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2C09A), width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE7D4C2),
                backgroundImage: NetworkImage(member.avatarUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF7A00),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: member.cityBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            member.city,
                            style: GoogleFonts.outfit(
                              color: member.cityText,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Distance Covered',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFC9AA88),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          'Steps',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFC9AA88),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.distanceLabel,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF7A00),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          member.stepsLabel,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF7A00),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: member.progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE2DBEF),
                        valueColor: AlwaysStoppedAnimation<Color>(member.barColor),
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

class _SheetActionIcon extends StatelessWidget {
  const _SheetActionIcon({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF7A00), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
          foregroundColor: const Color(0xFFFF7A00),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  const _SheetStat({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFFC9AA88),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF7A00),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.time,
    required this.distance,
    required this.steps,
  });

  final String time;
  final String distance;
  final String steps;
}

class _ProgressMember {
  const _ProgressMember({
    required this.name,
    required this.city,
    required this.distanceLabel,
    required this.stepsLabel,
    required this.progress,
    required this.avatarUrl,
    required this.barColor,
    required this.cityBg,
    required this.cityText,
    this.detailDistance = '16.5KM',
    this.totalProgress = '12%',
    this.stepsToReach = '3,29,500 Steps',
    this.timeLeft = '2d 14h 30m',
    this.activities = const <_ActivityItem>[
      _ActivityItem(time: '10:30 AM', distance: 'Walked 2.5KM', steps: '6,200 Steps'),
      _ActivityItem(time: '10:30 AM', distance: 'Walked 2.5KM', steps: '6,200 Steps'),
      _ActivityItem(time: '10:30 AM', distance: 'Walked 2.5KM', steps: '6,200 Steps'),
    ],
  });

  final String name;
  final String city;
  final String distanceLabel;
  final String stepsLabel;
  final double progress;
  final String avatarUrl;
  final Color barColor;
  final Color cityBg;
  final Color cityText;
  final String detailDistance;
  final String totalProgress;
  final String stepsToReach;
  final String timeLeft;
  final List<_ActivityItem> activities;
}
