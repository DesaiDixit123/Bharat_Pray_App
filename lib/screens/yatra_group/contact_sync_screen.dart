import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          'Select Members (${_selected.length})',
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context, _selected),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: Text(
              'Done',
              style: GoogleFonts.outfit(color: const Color(0xFFFF7700), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search contacts by name or phone...',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.4), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF7700)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: const Color(0xFFFF7700),
                          unselectedLabelColor: const Color(0xFF7A757F),
                          indicatorColor: const Color(0xFFFF7700),
                          indicatorWeight: 3,
                          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                          tabs: [
                            Tab(text: 'Registered Users (${filteredReg.length})'),
                            Tab(text: 'Invite Contacts (${filteredNonReg.length})'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Registered Users Tab
                              filteredReg.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No registered users found',
                                        style: GoogleFonts.outfit(color: const Color(0xFF7A757F), fontSize: 14),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      itemCount: filteredReg.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredReg[index];
                                        final isSelected = _selected.any((m) => m.id == user.id);

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                            leading: CircleAvatar(
                                              backgroundColor: const Color(0xFFFFE8D6),
                                              backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                                              child: user.profilePic.isEmpty
                                                  ? Text(
                                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                                      style: GoogleFonts.outfit(color: const Color(0xFFFF7700), fontWeight: FontWeight.bold, fontSize: 16),
                                                    )
                                                  : null,
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user.name,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: const Color(0xFF2E2A36),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (user.isMutualFollower)
                                                  Container(
                                                    margin: const EdgeInsets.only(left: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFE8D6),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Mutual',
                                                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFFF7700), fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            subtitle: Text(
                                              user.mobile,
                                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF7A757F), fontWeight: FontWeight.w500),
                                            ),
                                            trailing: user.isAlreadyMember
                                                ? Text(
                                                    'In Group',
                                                    style: GoogleFonts.outfit(color: const Color(0xFF7A757F), fontSize: 12, fontWeight: FontWeight.w600),
                                                  )
                                                : ElevatedButton(
                                                    onPressed: () => _toggleMember(user),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: isSelected ? const Color(0xFFEFE6DB) : const Color(0xFFFF7700),
                                                      elevation: 0,
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                    child: Text(
                                                      isSelected ? 'Remove' : 'Add',
                                                      style: GoogleFonts.outfit(
                                                        color: isSelected ? const Color(0xFF2E2A36) : Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        );
                                      },
                                    ),

                              // Non-Registered Users Tab
                              filteredNonReg.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No non-registered contacts found',
                                        style: GoogleFonts.outfit(color: const Color(0xFF7A757F), fontSize: 14),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      itemCount: filteredNonReg.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredNonReg[index];
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                            leading: CircleAvatar(
                                              backgroundColor: const Color(0xFFEFE6DB),
                                              child: Text(
                                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                                                style: GoogleFonts.outfit(color: const Color(0xFF7A757F), fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            title: Text(
                                              user.name,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: const Color(0xFF2E2A36),
                                              ),
                                            ),
                                            subtitle: Text(
                                              user.mobile,
                                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF7A757F), fontWeight: FontWeight.w500),
                                            ),
                                            trailing: OutlinedButton.icon(
                                              onPressed: () => _shareInvite(user),
                                              icon: const Icon(Icons.share, size: 14, color: Color(0xFFFF7700)),
                                              label: Text('Invite', style: GoogleFonts.outfit(color: const Color(0xFFFF7700), fontSize: 12, fontWeight: FontWeight.bold)),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Color(0xFFFF7700)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
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

