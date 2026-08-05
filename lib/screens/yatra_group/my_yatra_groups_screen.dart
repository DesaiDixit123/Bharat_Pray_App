import 'dart:async';
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
      final docs = (res['docs'] ?? res['groups'] ?? res) as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _myGroups = docs.map((d) => YatraGroupModel.fromJson(d)).toList();
        });
      }
    } catch (e) {
      print('Error loading my groups: $e');
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.orange.shade50,
              child: group.coverImage.isNotEmpty
                  ? Image.network(
                      group.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.temple_hindu, color: Color(0xFFFF7A00), size: 48),
                    )
                  : const Center(
                      child: Icon(Icons.temple_hindu, color: Color(0xFFFF7A00), size: 48)),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF2E2A36),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: group.visibility == 'public'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          group.visibility == 'public' ? '🌐 Public' : '🔒 Private',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: group.visibility == 'public' ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip(Icons.straighten_rounded,
                          '${group.totalDistance.toStringAsFixed(1)} KM'),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.directions_walk,
                          '${group.estimatedSteps} Steps'),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.group,
                          '${group.members.length}/${group.maxMembers}'),
                    ],
                  ),
                  if (group.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      group.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFF7A00)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
