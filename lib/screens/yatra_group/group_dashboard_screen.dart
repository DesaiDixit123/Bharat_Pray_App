import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../models/yatra_model.dart';
import '../../models/yatra_group_models.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/yatra_group_socket_service.dart';
import 'contact_sync_screen.dart';
import 'edit_group_dialog.dart';

class GroupDashboardScreen extends StatefulWidget {
  final String groupId;

  const GroupDashboardScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupDashboardScreen> createState() => _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends State<GroupDashboardScreen> {
  final _socketService = YatraGroupSocketService();
  final List<StreamSubscription> _subscriptions = [];

  YatraGroupDashboardModel? _dashboard;
  bool _loading = true;
  bool _error = false;
  String _errorMessage = '';
  bool _togglingReady = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _initSocket();
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
    _socketService.joinGroup(widget.groupId);

    // Listen for realtime ready status changes
    final readySub = _socketService.onMemberReadyStatusChanged.listen((data) {
      if (data['groupId'] == widget.groupId && mounted) {
        _loadDashboard(showLoading: false);
      }
    });

    // Listen for group details updates or deletion
    final updateSub = _socketService.onGroupUpdated.listen((data) {
      if (data['groupId'] == widget.groupId && mounted) {
        if (data['action'] == 'deleted') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This group has been deleted by the owner.')),
          );
          Navigator.pop(context);
        } else {
          _loadDashboard(showLoading: false);
        }
      }
    });

    // Listen for invitation resend or cancel actions
    final invSub = _socketService.onInvitationAction.listen((data) {
      if (data['groupId'] == widget.groupId && mounted) {
        _loadDashboard(showLoading: false);
      }
    });

    _subscriptions.addAll([readySub, updateSub, invSub]);
  }

  Future<void> _loadDashboard({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    setState(() => _error = false);

    try {
      final token = await _getToken();
      final data = await ApiService.getGroupDashboard(token, widget.groupId);
      
      // Resolve current user ID from token/profile if possible
      try {
        final profile = await ApiService.getProfile(token);
        _currentUserId = profile.id;
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _dashboard = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleReadyStatus(String newStatus) async {
    if (_togglingReady) return;
    setState(() => _togglingReady = true);

    try {
      final token = await _getToken();
      await ApiService.toggleMemberReadyStatus(
        token,
        groupId: widget.groupId,
        readyStatus: newStatus,
      );
      await _loadDashboard(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ready status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingReady = false);
    }
  }

  Future<void> _openEditDialog() async {
    if (_dashboard == null) return;
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditGroupDialog(
        groupId: widget.groupId,
        currentName: _dashboard!.name,
        currentDescription: _dashboard!.description,
        currentCoverImage: _dashboard!.coverImage,
      ),
    );
    if (updated == true) {
      _loadDashboard();
    }
  }

  Future<void> _inviteMoreMembers() async {
    final result = await Navigator.push<List<ContactUserModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactSyncScreen(selectedMembers: []),
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final token = await _getToken();
        final inviteeIds = result.map((m) => m.id).toList();
        await ApiService.sendGroupInvitations(token, groupId: widget.groupId, inviteeIds: inviteeIds);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sent invitations to ${inviteeIds.length} contact(s)!')),
        );
        _loadDashboard(showLoading: false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invitations: $e')),
        );
      }
    }
  }

  Future<void> _resendInvite(String receiverId) async {
    try {
      final token = await _getToken();
      await ApiService.resendGroupInvitation(token, groupId: widget.groupId, receiverId: receiverId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation resent successfully!')),
      );
      _loadDashboard(showLoading: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend invitation: $e')),
      );
    }
  }

  Future<void> _cancelInvite(String receiverId) async {
    final confirm = await _showConfirmDialog(
      'Cancel Invitation',
      'Are you sure you want to cancel this invitation?',
    );
    if (!confirm) return;

    try {
      final token = await _getToken();
      await ApiService.cancelGroupInvitation(token, groupId: widget.groupId, receiverId: receiverId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation cancelled.')),
      );
      _loadDashboard(showLoading: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel invitation: $e')),
      );
    }
  }

  Future<void> _removeMember(String memberUserId, String memberName) async {
    final confirm = await _showConfirmDialog(
      'Remove Member',
      'Are you sure you want to remove $memberName from the group?',
    );
    if (!confirm) return;

    try {
      final token = await _getToken();
      await ApiService.removeGroupMember(token, widget.groupId, memberUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$memberName removed from group.')),
      );
      _loadDashboard(showLoading: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove member: $e')),
      );
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await _showConfirmDialog(
      'Delete Yatra Group',
      'This action is irreversible. All members will be removed and group data deleted. Continue?',
      confirmText: 'Delete Group',
      isDanger: true,
    );
    if (!confirm) return;

    try {
      final token = await _getToken();
      await ApiService.deleteYatraGroup(token, widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yatra group deleted.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete group: $e')),
        );
      }
    }
  }

  Future<void> _validateAndStartGroup() async {
    try {
      final token = await _getToken();
      final res = await ApiService.validateGroupStart(token, widget.groupId);
      final canStart = res['canStart'] == true;
      final errors = (res['errors'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                canStart ? Icons.check_circle : Icons.error_outline,
                color: canStart ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                canStart ? 'Group Ready!' : 'Validation Failed',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canStart
                    ? 'All pre-Yatra validation checks passed! All members are ready to begin.'
                    : 'Please resolve the following issues before starting:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (errors.isNotEmpty)
                ...errors.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(e, style: const TextStyle(fontSize: 12, color: Colors.red))),
                        ],
                      ),
                    )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validation check error: $e')),
      );
    }
  }

  Future<bool> _showConfirmDialog(String title, String content, {String confirmText = 'Confirm', bool isDanger = false}) async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDanger ? Colors.red : const Color(0xFFFF7A00),
                ),
                child: Text(confirmText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  void dispose() {
    _socketService.leaveGroup(widget.groupId);
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: Text(
          _dashboard?.name ?? 'Group Dashboard',
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF2E2A36)),
        actions: [
          if (_dashboard != null && _dashboard!.isOwner)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _openEditDialog();
                if (val == 'invite') _inviteMoreMembers();
                if (val == 'delete') _deleteGroup();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Details')])),
                PopupMenuItem(value: 'invite', child: Row(children: [Icon(Icons.person_add, size: 18), SizedBox(width: 8), Text('Invite Members')])),
                PopupMenuDivider(),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete Group', style: TextStyle(color: Colors.red))])),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF7A00),
        onRefresh: () => _loadDashboard(showLoading: false),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
            : _error
                ? _buildErrorState()
                : _dashboard == null
                    ? const Center(child: Text('Dashboard not available'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGroupHeaderCard(),
                            const SizedBox(height: 16),
                            _buildReadinessProgressBar(),
                            const SizedBox(height: 16),
                            _buildMetricsRow(),
                            const SizedBox(height: 16),
                            _buildStatsSummaryGrid(),
                            const SizedBox(height: 20),
                            _buildMyReadyToggleCard(),
                            const SizedBox(height: 20),
                            _buildMemberListHeader(),
                            const SizedBox(height: 10),
                            _buildMemberList(),
                            const SizedBox(height: 20),
                            if (_dashboard!.invitations.isNotEmpty) ...[
                              _buildInvitationsSection(),
                              const SizedBox(height: 20),
                            ],
                            _buildValidateStartBanner(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Failed to load Dashboard', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeaderCard() {
    final d = _dashboard!;
    final createdDateStr = d.createdDate != null ? DateFormat('dd MMM yyyy').format(d.createdDate!) : 'Recently';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.orange.shade50,
              child: d.coverImage.isNotEmpty
                  ? Image.network(
                      d.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.temple_hindu, color: Color(0xFFFF7A00), size: 54),
                    )
                  : const Center(child: Icon(Icons.temple_hindu, color: Color(0xFFFF7A00), size: 54)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          d.name,
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: d.canStart ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: d.canStart ? Colors.green.shade200 : Colors.orange.shade200),
                        ),
                        child: Text(
                          d.canStart ? 'READY TO START' : 'PREPARING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: d.canStart ? Colors.green.shade700 : const Color(0xFFFF7A00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (d.temple != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.temple_hindu, size: 16, color: Color(0xFFFF7A00)),
                        const SizedBox(width: 6),
                        Text(
                          '${d.temple!['name']} (${d.temple!['city'] ?? ""})',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  if (d.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(d.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.person, size: 14, color: Color(0xFFFF7A00)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Created by ${d.createdBy?['name'] ?? "Owner"} on $createdDateStr',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessProgressBar() {
    final d = _dashboard!;
    final readyPercent = d.acceptedMembers > 0 ? (d.readyCount / d.acceptedMembers) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Group Readiness', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${d.readyCount} / ${d.acceptedMembers} Members Ready', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF7A00), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: readyPercent,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFFFF7A00),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Minimum required ready members: ${d.minReadyRequired}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final d = _dashboard!;
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Distance', '${d.totalDistanceKm.toStringAsFixed(1)} KM', Icons.straighten)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricCard('Est. Steps', '${d.estimatedSteps}', Icons.directions_walk)),
        const SizedBox(width: 10),
        Expanded(child: _buildMetricCard('Est. Duration', '${d.estimatedDays} Days', Icons.calendar_today)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF7A00)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildStatsSummaryGrid() {
    final d = _dashboard!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatSummaryItem('Total', '${d.totalMembers}', Colors.black87),
          _buildStatSummaryItem('Accepted', '${d.acceptedMembers}', Colors.green),
          _buildStatSummaryItem('Pending', '${d.pendingInvitations}', Colors.orange),
          _buildStatSummaryItem('Rejected', '${d.rejectedInvitations}', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMyReadyToggleCard() {
    final me = _dashboard!.members.firstWhere(
      (m) => m.userId == _currentUserId || m.role == 'leader',
      orElse: () => _dashboard!.members.first,
    );
    final isReady = me.readyStatus == 'ready';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isReady ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Readiness Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                isReady ? 'You are marked READY for Yatra' : 'Mark yourself READY when prepared',
                style: TextStyle(fontSize: 12, color: isReady ? Colors.green.shade800 : Colors.grey.shade600),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _togglingReady ? null : () => _toggleReadyStatus(isReady ? 'not_ready' : 'ready'),
            icon: Icon(isReady ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.white, size: 18),
            label: Text(
              isReady ? 'READY' : 'MARK READY',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady ? Colors.green : const Color(0xFFFF7A00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Group Members (${_dashboard!.members.length})',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (_dashboard!.isOwner)
          TextButton.icon(
            onPressed: _inviteMoreMembers,
            icon: const Icon(Icons.person_add, size: 16, color: Color(0xFFFF7A00)),
            label: const Text('Invite More', style: TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildMemberList() {
    final members = _dashboard!.members;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isOwner = member.role == 'leader';
        final isReady = member.readyStatus == 'ready';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              backgroundImage: member.profilePic.isNotEmpty ? NetworkImage(member.profilePic) : null,
              child: member.profilePic.isEmpty ? Text(member.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold)) : null,
            ),
            title: Row(
              children: [
                Text(member.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 6),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Owner', style: TextStyle(fontSize: 10, color: Color(0xFFFF7A00), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text(
              '${member.mobile.isNotEmpty ? member.mobile : "No contact"}\nStatus: ${member.invitationStatus.toUpperCase()}',
              style: const TextStyle(fontSize: 11),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReady ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isReady ? Colors.green : Colors.grey.shade400),
                  ),
                  child: Text(
                    isReady ? '✓ READY' : 'NOT READY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isReady ? Colors.green : Colors.grey.shade600),
                  ),
                ),
                if (_dashboard!.isOwner && !isOwner)
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'remove') _removeMember(member.userId, member.name);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'remove', child: Text('Remove Member', style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitationsSection() {
    final invitations = _dashboard!.invitations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pending Invitations (${invitations.length})', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final inv = invitations[index];
            final receiverId = inv['receiverId']?.toString() ?? '';
            final receiverName = inv['receiverName']?.toString() ?? 'User';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.mail_outline, color: Colors.white, size: 18),
                ),
                title: Text(receiverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Status: ${inv['status']}', style: const TextStyle(fontSize: 11)),
                trailing: _dashboard!.isOwner
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.orange, size: 20),
                            onPressed: () => _resendInvite(receiverId),
                            tooltip: 'Resend Invitation',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () => _cancelInvite(receiverId),
                            tooltip: 'Cancel Invitation',
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildValidateStartBanner() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _validateAndStartGroup,
        icon: const Icon(Icons.play_circle_fill, color: Colors.white),
        label: const Text('Validate Pre-Yatra Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A00),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
