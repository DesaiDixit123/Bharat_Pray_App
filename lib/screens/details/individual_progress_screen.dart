import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/yatra_group_models.dart';

class IndividualProgressScreen extends StatefulWidget {
  final String groupId;
  final double currentLeaderKm;
  final int currentLeaderSteps;
  final double currentLeaderProgress;
  final List<dynamic>? initialMembers;

  const IndividualProgressScreen({
    super.key,
    this.groupId = '',
    this.currentLeaderKm = 0.0,
    this.currentLeaderSteps = 0,
    this.currentLeaderProgress = 0.0,
    this.initialMembers,
  });

  @override
  State<IndividualProgressScreen> createState() => _IndividualProgressScreenState();
}

ImageProvider? _getAvatarProvider(String url) {
  final clean = url.trim();
  if (clean.isEmpty) return null;
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }
  if (clean.startsWith('assets/')) {
    return AssetImage(clean);
  }
  final baseDomain = ApiService.baseUrl.replaceAll('/user', '');
  return NetworkImage('$baseDomain/uploads/$clean');
}

class _IndividualProgressScreenState extends State<IndividualProgressScreen> {
  static const Color _bg = Color(0xFFFFE8D6);

  static const List<({Color bar, Color bg, Color text})> _palette = [
    (bar: Color(0xFF7759D9), bg: Color(0xFFE8E5F7), text: Color(0xFF7A68D6)),
    (bar: Color(0xFF3B64B7), bg: Color(0xFFE5F1FD), text: Color(0xFF4A90E2)),
    (bar: Color(0xFF55B9C9), bg: Color(0xFFE0F7FA), text: Color(0xFF00ACC1)),
    (bar: Color(0xFFC85AAA), bg: Color(0xFFFCE4EC), text: Color(0xFFD81B60)),
    (bar: Color(0xFF4AB56A), bg: Color(0xFFE8F5E9), text: Color(0xFF43A047)),
    (bar: Color(0xFFD1448E), bg: Color(0xFFFFEBEE), text: Color(0xFFE53935)),
  ];

  List<_ProgressMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  String _formatCity(String? rawCity, String? rawAddress) {
    final city = rawCity?.trim() ?? '';
    final address = rawAddress?.trim() ?? '';

    if (city.isNotEmpty && city.toLowerCase() != 'gujarat, india') {
      if (!city.toLowerCase().contains('gujarat') && !city.contains(',')) {
        return '$city, Gujarat';
      }
      return city;
    }

    if (address.isNotEmpty) {
      final parts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts[parts.length - 2]}, ${parts.last}';
      } else if (parts.isNotEmpty) {
        final p = parts.first;
        if (!p.toLowerCase().contains('gujarat')) {
          return '$p, Gujarat';
        }
        return p;
      }
    }

    return 'Surat, Gujarat';
  }

  Future<void> _fetchMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Leader info from SharedPreferences
      String leaderName = prefs.getString('user_name') ??
          prefs.getString('name') ??
          prefs.getString('fullName') ??
          'You';
      String leaderAvatar = prefs.getString('profile_pic') ?? '';
      String leaderCity = prefs.getString('city') ??
          prefs.getString('user_city') ??
          prefs.getString('address') ??
          prefs.getString('user_address') ??
          '';

      double leaderKm = widget.currentLeaderKm;
      int leaderSteps = widget.currentLeaderSteps;
      double leaderProg = widget.currentLeaderProgress.clamp(0.0, 1.0);

      final List<_ProgressMember> loadedMembers = [];

      // 1. Check widget.initialMembers if provided
      if (widget.initialMembers != null && widget.initialMembers!.isNotEmpty) {
        int colorIdx = 1;
        for (final m in widget.initialMembers!) {
          String mName = '';
          String mPic = '';
          String mCity = '';
          String mAddress = '';
          if (m is ContactUserModel) {
            mName = m.name;
            mPic = m.profilePic;
            mCity = m.city;
            mAddress = m.address;
          } else if (m is Map) {
            mName = m['name']?.toString() ?? 'Member';
            mPic = m['profilePic']?.toString() ?? m['avatar']?.toString() ?? m['profile_pic']?.toString() ?? '';
            mCity = m['city']?.toString() ?? '';
            mAddress = m['address']?.toString() ?? '';
          }
          if (mName.isNotEmpty &&
              !mName.toLowerCase().contains('(leader)') &&
              !mName.toLowerCase().contains('leader')) {
            final theme = _palette[colorIdx % _palette.length];
            colorIdx++;
            loadedMembers.add(_ProgressMember(
              name: mName,
              city: _formatCity(mCity, mAddress),
              distanceLabel: '0.0 KM',
              stepsLabel: '0',
              progress: 0.0,
              detailDistance: '0.0 KM',
              totalProgress: '0%',
              stepsToReach: '0 Steps',
              timeLeft: 'Active',
              activities: const [],
              avatarUrl: mPic,
              barColor: theme.bar,
              cityBg: theme.bg,
              cityText: theme.text,
            ));
          }
        }
      }

      // 2. Check local latest_yatra_members from SharedPreferences
      if (loadedMembers.isEmpty) {
        try {
          final savedMembersStr = prefs.getString('latest_yatra_members');
          if (savedMembersStr != null && savedMembersStr.isNotEmpty) {
            final List<dynamic> savedList = jsonDecode(savedMembersStr);
            int colorIdx = 1;
            for (final sm in savedList) {
              if (sm is Map) {
                final mName = sm['name']?.toString() ?? 'Member';
                if (mName.toLowerCase().contains('leader')) continue;
                final theme = _palette[colorIdx % _palette.length];
                colorIdx++;
                final mPic = sm['profilePic']?.toString() ?? sm['profile_pic']?.toString() ?? '';
                final mCity = sm['city']?.toString() ?? '';
                final mAddress = sm['address']?.toString() ?? '';
                loadedMembers.add(_ProgressMember(
                  name: mName,
                  city: _formatCity(mCity, mAddress),
                  distanceLabel: '0.0 KM',
                  stepsLabel: '0',
                  progress: 0.0,
                  detailDistance: '0.0 KM',
                  totalProgress: '0%',
                  stepsToReach: '0 Steps',
                  timeLeft: 'Active',
                  activities: const [],
                  avatarUrl: mPic,
                  barColor: theme.bar,
                  cityBg: theme.bg,
                  cityText: theme.text,
                ));
              }
            }
          }
        } catch (e) {
          debugPrint('Error reading latest_yatra_members: $e');
        }
      }

      // 3. Try fetching group dashboard from API if groupId is present
      if (token.isNotEmpty && widget.groupId.isNotEmpty) {
        try {
          final dashboard = await ApiService.getGroupDashboard(token, widget.groupId);
          if (dashboard.createdBy != null) {
            final creator = dashboard.createdBy!;
            final cName = creator['name']?.toString() ?? '';
            if (cName.isNotEmpty) {
              leaderName = cName;
            }
            final cPic = creator['profilePic']?.toString() ?? '';
            if (cPic.isNotEmpty) {
              leaderAvatar = cPic;
            }
            final cCity = creator['city']?.toString() ?? '';
            if (cCity.isNotEmpty) {
              leaderCity = cCity;
            }
          }

          if (dashboard.members.isNotEmpty) {
            final apiMemberList = <_ProgressMember>[];
            int colorIdx = 1;
            for (final m in dashboard.members) {
              if (m.role.toLowerCase() == 'leader' || m.name.toLowerCase().contains('(leader)')) {
                continue;
              }
              final theme = _palette[colorIdx % _palette.length];
              colorIdx++;
              apiMemberList.add(_ProgressMember(
                name: m.name,
                city: _formatCity(m.city, ''),
                distanceLabel: '${m.distanceCoveredKm.toStringAsFixed(1)} KM',
                stepsLabel: '${m.steps}',
                progress: (m.progressPercent / 100.0).clamp(0.0, 1.0),
                detailDistance: '${m.distanceCoveredKm.toStringAsFixed(1)} KM',
                totalProgress: '${(m.progressPercent).toStringAsFixed(0)}%',
                stepsToReach: '0 Steps',
                timeLeft: 'Active',
                activities: const [],
                avatarUrl: m.profilePic,
                barColor: theme.bar,
                cityBg: theme.bg,
                cityText: theme.text,
              ));
            }
            if (apiMemberList.isNotEmpty) {
              loadedMembers.clear();
              loadedMembers.addAll(apiMemberList);
            }
          }
        } catch (e) {
          debugPrint('Error fetching group dashboard: $e');
        }
      }

      // 4. Check active_yatra_groups if loadedMembers is still empty
      if (loadedMembers.isEmpty) {
        try {
          final localGroupsStr = prefs.getString('active_yatra_groups');
          if (localGroupsStr != null && localGroupsStr.isNotEmpty) {
            final List<dynamic> localGroups = jsonDecode(localGroupsStr);
            Map<String, dynamic>? targetGroup;
            if (widget.groupId.isNotEmpty) {
              targetGroup = localGroups.firstWhere(
                (g) => g['_id'] == widget.groupId || g['id'] == widget.groupId,
                orElse: () => null,
              );
            }
            targetGroup ??= localGroups.isNotEmpty ? localGroups.first as Map<String, dynamic> : null;

            if (targetGroup != null && targetGroup['members'] is List) {
              final rawMembers = targetGroup['members'] as List<dynamic>;
              int colorIdx = 1;
              for (final rm in rawMembers) {
                if (rm is Map) {
                  final mRole = rm['role']?.toString().toLowerCase() ?? '';
                  final mName = rm['name']?.toString() ?? 'Member';
                  if (mRole == 'leader' ||
                      mName.toLowerCase().contains('(leader)') ||
                      mName.toLowerCase().contains('(admin)')) {
                    final lCity = rm['city']?.toString() ?? rm['address']?.toString() ?? '';
                    if (lCity.isNotEmpty && leaderCity.isEmpty) {
                      leaderCity = lCity;
                    }
                    continue;
                  }
                  final theme = _palette[colorIdx % _palette.length];
                  colorIdx++;
                  final memberCity = rm['city']?.toString() ?? rm['address']?.toString() ?? '';
                  loadedMembers.add(_ProgressMember(
                    name: mName,
                    city: _formatCity(memberCity, rm['address']?.toString()),
                    distanceLabel: '0.0 KM',
                    stepsLabel: '0',
                    progress: 0.0,
                    detailDistance: '0.0 KM',
                    totalProgress: '0%',
                    stepsToReach: '0 Steps',
                    timeLeft: 'Active',
                    activities: const [],
                    avatarUrl: rm['profilePic']?.toString() ?? rm['avatar']?.toString() ?? '',
                    barColor: theme.bar,
                    cityBg: theme.bg,
                    cityText: theme.text,
                  ));
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error reading local active_yatra_groups: $e');
        }
      }

      // Format leader card as #1
      final leaderTheme = _palette[0];
      final displayName = leaderName.toLowerCase().contains('leader')
          ? leaderName
          : '$leaderName (Leader)';

      final leaderMember = _ProgressMember(
        name: displayName,
        city: _formatCity(leaderCity, ''),
        distanceLabel: '${leaderKm.toStringAsFixed(1)} KM',
        stepsLabel: '$leaderSteps',
        progress: leaderProg,
        detailDistance: '${leaderKm.toStringAsFixed(1)} KM',
        totalProgress: '${(leaderProg * 100).toInt()}%',
        stepsToReach: '0 Steps',
        timeLeft: 'Active',
        activities: const [],
        avatarUrl: leaderAvatar,
        barColor: leaderTheme.bar,
        cityBg: leaderTheme.bg,
        cityText: leaderTheme.text,
      );

      final fullList = <_ProgressMember>[leaderMember, ...loadedMembers];

      if (mounted) {
        setState(() {
          _members = fullList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _fetchMembers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                        backgroundImage: _getAvatarProvider(member.avatarUrl),
                        child: member.avatarUrl.trim().isEmpty
                            ? Text(
                                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF7A00),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
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
                backgroundImage: _getAvatarProvider(member.avatarUrl),
                child: member.avatarUrl.trim().isEmpty
                    ? Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF7A00),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
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
