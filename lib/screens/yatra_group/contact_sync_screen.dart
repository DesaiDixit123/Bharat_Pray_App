import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/yatra_model.dart';
import '../../models/yatra_group_models.dart';
import '../../services/api_service.dart';

class ContactSyncScreen extends StatefulWidget {
  final List<ContactUserModel> selectedMembers;
  final String? groupId;

  const ContactSyncScreen({
    Key? key,
    required this.selectedMembers,
    this.groupId,
  }) : super(key: key);

  @override
  State<ContactSyncScreen> createState() => _ContactSyncScreenState();
}

class _ContactSyncScreenState extends State<ContactSyncScreen> {
  bool _loading = false;
  String _searchQuery = '';
  List<ContactUserModel> _registeredUsers = [];
  List<ContactUserModel> _nonRegisteredUsers = [];
  List<ContactUserModel> _selected = [];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedMembers);
    _performContactSync();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _performContactSync() async {
    setState(() => _loading = true);

    try {
      List<Map<String, String>> phoneContacts = [];

      try {
        if (await FlutterContacts.requestPermission(readonly: true)) {
          final deviceContacts = await FlutterContacts.getContacts(
            withProperties: true,
            withPhoto: false,
          );

          for (final c in deviceContacts) {
            final name = c.displayName.isNotEmpty
                ? c.displayName
                : '${c.name.first} ${c.name.last}'.trim();
            for (final p in c.phones) {
              if (p.number.trim().isNotEmpty) {
                phoneContacts.add({
                  'name': name.isNotEmpty ? name : 'Contact',
                  'phone': p.number.trim(),
                });
              }
            }
          }
        }
      } catch (e) {
        print('Error reading device contacts: $e');
      }

      if (phoneContacts.isEmpty) {
        phoneContacts = [
          {'name': 'Ramesh Kumar', 'phone': '+919876543210'},
          {'name': 'Suresh Sharma', 'phone': '9876543211'},
          {'name': 'Anita Verma', 'phone': '+919876543212'},
          {'name': 'Pooja Patel', 'phone': '9876543213'},
          {'name': 'Vikram Singh', 'phone': '+919876543214'},
        ];
      }

      final token = await _getToken();
      final res = await ApiService.syncContacts(
        token,
        contacts: phoneContacts,
        groupId: widget.groupId,
      );

      final regList = res['registeredUsers'] as List<dynamic>? ?? [];
      final nonRegList = res['nonRegisteredUsers'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _registeredUsers = regList.map((r) => ContactUserModel.fromJson(r, registered: true)).toList();
          _nonRegisteredUsers = nonRegList.map((nr) => ContactUserModel.fromJson(nr, registered: false)).toList();
        });
      }
    } catch (e) {
      print('Error during contact sync: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleMember(ContactUserModel user) {
    setState(() {
      final idx = _selected.indexWhere((m) => m.id == user.id);
      if (idx != -1) {
        _selected.removeAt(idx);
      } else {
        _selected.add(user);
      }
    });
  }

  void _shareInvite(ContactUserModel user) {
    final shareMsg = 'Join me on BharatPray for sacred Pilgrimage Yatras! Download BharatPray app now: https://bharatpray.com/invite';
    Share.share(shareMsg, subject: 'Join BharatPray Yatra');
  }

  @override
  Widget build(BuildContext context) {
    final filteredReg = _registeredUsers.where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()) || u.mobile.contains(_searchQuery)).toList();
    final filteredNonReg = _nonRegisteredUsers.where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()) || u.mobile.contains(_searchQuery)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text('Select Members (${_selected.length})', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selected);
            },
            child: const Text('Done', style: TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts by name or phone...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: const Color(0xFFFF7A00),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFFFF7A00),
                          tabs: [
                            Tab(text: 'Registered Users (${filteredReg.length})'),
                            Tab(text: 'Invite Contacts (${filteredNonReg.length})'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Registered Users Tab
                              ListView.builder(
                                itemCount: filteredReg.length,
                                itemBuilder: (context, index) {
                                  final user = filteredReg[index];
                                  final isSelected = _selected.any((m) => m.id == user.id);

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.orange.shade100,
                                      backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                                      child: user.profilePic.isEmpty ? Text(user.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold)) : null,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (user.isMutualFollower)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                            child: const Text('Mutual', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(user.mobile),
                                    trailing: user.isAlreadyMember
                                        ? const Text('In Group', style: TextStyle(color: Colors.grey, fontSize: 12))
                                        : ElevatedButton(
                                            onPressed: () => _toggleMember(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isSelected ? Colors.grey.shade400 : const Color(0xFFFF7A00),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text(isSelected ? 'Remove' : 'Add', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                  );
                                },
                              ),

                              // Non-Registered Users Tab
                              ListView.builder(
                                itemCount: filteredNonReg.length,
                                itemBuilder: (context, index) {
                                  final user = filteredNonReg[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey.shade200,
                                      child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(user.mobile),
                                    trailing: OutlinedButton.icon(
                                      onPressed: () => _shareInvite(user),
                                      icon: const Icon(Icons.share, size: 14, color: Color(0xFFFF7A00)),
                                      label: const Text('Invite', style: TextStyle(color: Color(0xFFFF7A00), fontSize: 12)),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFF7A00))),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
