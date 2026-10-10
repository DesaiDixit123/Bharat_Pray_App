import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/yatra_model.dart';
import '../../models/yatra_group_models.dart';
import '../../services/api_service.dart';
import '../../services/yatra_group_socket_service.dart';
import 'group_invitation_dialog.dart';
import 'group_dashboard_screen.dart';

/// Displays the user's active yatra groups and pending invitations.
/// Listens to real-time socket events for new invitations and member joins.
class MyYatraGroupsScreen extends StatefulWidget {
  const MyYatraGroupsScreen({Key? key}) : super(key: key);

  @override
  State<MyYatraGroupsScreen> createState() => _MyYatraGroupsScreenState();
}

class _MyYatraGroupsScreenState extends State<MyYatraGroupsScreen> {
  final _socketService = YatraGroupSocketService();
  final List<StreamSubscription> _subs = [];

  List<YatraGroupModel> _myGroups = [];
  List<GroupInvitationModel> _pendingInvitations = [];
  bool _loadingGroups = true;
  bool _loadingInvitations = true;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _loadData();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _initSocket() async {
    final token = await _getToken();
    if (!_socketService.isConnected) {
      _socketService.init(token);
    }

    // Listen for new invitations in real-time
    final invSub = _socketService.onInvitationReceived.listen((data) {
      if (!mounted) return;
      final invitation = GroupInvitationModel.fromJson(data);
      _showInvitationDialog(invitation);
      _loadPendingInvitations(); // Refresh count badge
    });

    // Listen for member join events
    final memSub = _socketService.onMemberJoined.listen((data) {
      if (!mounted) return;
      _loadMyGroups(); // Refresh group list to update member count
    });

    _subs.addAll([invSub, memSub]);
  }

  Future<void> _loadData() async {
    await Future.wait([_loadMyGroups(), _loadPendingInvitations()]);
  }

  Future<void> _loadMyGroups() async {
    setState(() => _loadingGroups = true);
    try {
      final token = await _getToken();
      final res = await ApiService.getMyYatraGroups(token);
      List<dynamic> docs = [];
      if (res is List) {
        docs = res;
      } else if (res is Map) {
        docs = (res['docs'] ?? res['groups'] ?? res['data'] ?? []) as List<dynamic>;
      }

      // If API returned empty, check local active_yatra_groups
      if (docs.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final localStr = prefs.getString('active_yatra_groups');
        if (localStr != null && localStr.isNotEmpty) {
          try {
            final localList = jsonDecode(localStr);
            if (localList is List) {
              docs = localList;
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _myGroups = docs.map((d) => YatraGroupModel.fromJson(d)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading my groups: $e');
    } finally {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  Future<void> _loadPendingInvitations() async {
    setState(() => _loadingInvitations = true);
    try {
      final token = await _getToken();
      final docs = await ApiService.getPendingInvitations(token);
      if (mounted) {
        setState(() {
          _pendingInvitations =
              docs.map((d) => GroupInvitationModel.fromJson(d)).toList();
        });
      }
    } catch (e) {
      print('Error loading invitations: $e');
    } finally {
      if (mounted) setState(() => _loadingInvitations = false);
    }
  }

  void _showInvitationDialog(GroupInvitationModel invitation) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GroupInvitationDialog(
        invitation: invitation,
        onResponded: _loadData,
      ),
    );
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        title: Text(
          'My Yatra Groups',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2E2A36)),
        actions: [
          if (_pendingInvitations.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined,
                      color: Color(0xFFFF7A00)),
                  onPressed: _showPendingInvitations,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '${_pendingInvitations.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF7A00),
        onRefresh: _loadData,
        child: _loadingGroups
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
            : _myGroups.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myGroups.length,
                    itemBuilder: (context, index) =>
                        _buildGroupCard(_myGroups[index]),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 72, color: Colors.orange.shade200),
          const SizedBox(height: 16),
          Text(
            'No Yatra Groups Yet',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or join a Yatra group to begin your\nsacred pilgrimage journey together.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          if (_pendingInvitations.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _showPendingInvitations,
              icon: const Icon(Icons.mail_outline, color: Colors.white),
              label: Text(
                'View ${_pendingInvitations.length} Pending Invitation(s)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildMemberAvatarsPreview(List<dynamic> members) {
    final previewList = members.take(4).toList();
    if (previewList.isEmpty) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFFFFE8D6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 14, color: Color(0xFFFF7A00)),
      );
    }
    return SizedBox(
      width: (previewList.length * 16.0) + 12,
      height: 26,
      child: Stack(
        children: [
          for (int i = 0; i < previewList.length; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: const Color(0xFFFFE8D6),
                ),
                child: Center(
                  child: Text(
                    _getMemberInitial(previewList[i]),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF7A00),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getMemberInitial(dynamic m) {
    if (m is Map) {
      final name = (m['name'] ?? m['userId']?['name'] ?? '').toString();
      if (name.isNotEmpty) return name[0].toUpperCase();
    }
    return 'Y';
  }

  String _getMemberNamesSummary(List<dynamic> members) {
    if (members.isEmpty) return 'Leader + Yatris';
    final names = <String>[];
    for (final m in members) {
      if (m is Map) {
        final name = (m['name'] ?? m['userId']?['name'] ?? '').toString();
        if (name.isNotEmpty) names.add(name);
      }
    }
    if (names.isEmpty) return 'Leader + Yatris';
    return names.join(', ');
  }

  Widget _buildGroupCard(YatraGroupModel group) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDashboardScreen(groupId: group.id),
          ),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8D2B8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Header with Badges
              Stack(
                children: [
                  Container(
                    height: 125,
                    width: double.infinity,
                    color: const Color(0xFFFFE8D6),
                    child: group.coverImage.isNotEmpty
                        ? (group.coverImage.startsWith('http')
                            ? Image.network(
                                group.coverImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF7A00), size: 48),
                                ),
                              )
                            : Image.asset(
                                group.coverImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF7A00), size: 48),
                                ),
                              ))
                        : const Center(
                            child: Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF7A00), size: 48),
                          ),
                  ),
                  // Created Date Badge (Top Left)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(group.createdAt),
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Visibility Badge (Top Right)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: group.visibility == 'public'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: group.visibility == 'public'
                              ? const Color(0xFF81C784)
                              : const Color(0xFFFFB74D),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        group.visibility == 'public' ? '🌐 Public' : '🔒 Private',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: group.visibility == 'public'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Name
                    Text(
                      group.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: const Color(0xFF2E2A36),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Destination / Yatra Name
                    Row(
                      children: [
                        const Icon(Icons.temple_hindu_rounded, size: 15, color: Color(0xFFFF7A00)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            group.templeName.isNotEmpty ? group.templeName : 'Sacred Pilgrimage Yatra',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF7A00),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Metrics Chips
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.straighten_rounded,
                          '${group.totalDistance.toStringAsFixed(1)} KM',
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          Icons.directions_walk_rounded,
                          '${group.estimatedSteps}',
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          Icons.group_rounded,
                          '${group.memberCount} Yatris',
                        ),
                      ],
                    ),

                    // Members Preview Container
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0DECB), width: 1),
                      ),
                      child: Row(
                        children: [
                          _buildMemberAvatarsPreview(group.members),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${group.memberCount} Group Members',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E2A36),
                                  ),
                                ),
                                Text(
                                  _getMemberNamesSummary(group.members),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF7A757F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFFF7A00)),
                        ],
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

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8D6).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFFF7A00)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: const Color(0xFF2E2A36),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPendingInvitations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.85,
        initialChildSize: 0.5,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pending Invitations',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _pendingInvitations.length,
                  itemBuilder: (context, index) {
                    final inv = _pendingInvitations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFF7A00),
                          child: Icon(Icons.group_add, color: Colors.white, size: 18),
                        ),
                        title: Text(inv.groupName,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'From: ${inv.senderName}\n${inv.templeName}',
                          style: GoogleFonts.outfit(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showInvitationDialog(inv);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('View',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
