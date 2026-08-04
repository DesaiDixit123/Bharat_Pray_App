import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/yatra_model.dart';
import '../../services/api_service.dart';

class GroupInvitationDialog extends StatefulWidget {
  final GroupInvitationModel invitation;
  final VoidCallback? onResponded;

  const GroupInvitationDialog({
    Key? key,
    required this.invitation,
    this.onResponded,
  }) : super(key: key);

  @override
  State<GroupInvitationDialog> createState() => _GroupInvitationDialogState();
}

class _GroupInvitationDialogState extends State<GroupInvitationDialog> {
  bool _loading = false;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _respond(bool accept) async {
    setState(() => _loading = true);

    try {
      final token = await _getToken();
      if (accept) {
        await ApiService.acceptGroupInvitation(token, groupId: widget.invitation.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined "${widget.invitation.groupName}" successfully!')),
        );
      } else {
        await ApiService.rejectGroupInvitation(token, groupId: widget.invitation.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined.')),
        );
      }
      widget.onResponded?.call();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Response failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.group_add, color: Color(0xFFFF7A00), size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Yatra Group Invitation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '${inv.senderName} invited you to join sacred Yatra group "${inv.groupName}"!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Details card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildRow('Temple:', inv.templeName),
                  const Divider(height: 12),
                  _buildRow('Distance:', '${inv.distance.toStringAsFixed(1)} KM'),
                  const Divider(height: 12),
                  _buildRow('Steps:', inv.steps.toString()),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_loading)
              const CircularProgressIndicator(color: Color(0xFFFF7A00))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respond(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reject', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respond(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
