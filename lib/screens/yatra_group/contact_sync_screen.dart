import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/yatra_group_models.dart';
import '../../services/api_service.dart';
import '../details/yatra_chat_screen.dart';

class ContactSyncScreen extends StatefulWidget {
  final List<ContactUserModel> selectedMembers;
  final String? groupId;
  final bool isGroupCreation;

  const ContactSyncScreen({
    Key? key,
    required this.selectedMembers,
    this.groupId,
    this.isGroupCreation = false,
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
  late bool _inGroupCreation;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedMembers);
    _inGroupCreation = widget.isGroupCreation;
    _performContactSync();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<List<Map<String, String>>> _loadCustomContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('local_custom_contacts');
    if (str != null && str.isNotEmpty) {
      try {
        final list = jsonDecode(str) as List<dynamic>;
        return list.map((c) => Map<String, String>.from(c as Map)).toList();
      } catch (e) {
        debugPrint("Error loading custom contacts: $e");
      }
    }
    return [];
  }

  Future<void> _saveCustomContact(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('local_custom_contacts');
    List<dynamic> list = [];
    if (str != null && str.isNotEmpty) {
      try {
        list = jsonDecode(str) as List<dynamic>;
      } catch (_) {}
    }
    list.add({'name': name, 'phone': phone});
    await prefs.setString('local_custom_contacts', jsonEncode(list));
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
        debugPrint('Error reading device contacts: $e');
      }

      // Merge locally saved custom contacts
      final customContacts = await _loadCustomContacts();
      phoneContacts.addAll(customContacts);

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
      debugPrint('Error during contact sync: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleMember(ContactUserModel user) {
    setState(() {
      final idx = _selected.indexWhere((m) => m.id == user.id || (m.mobile == user.mobile && user.mobile.isNotEmpty));
      if (idx != -1) {
        _selected.removeAt(idx);
      } else {
        _selected.add(user);
      }
    });
    _saveSelectedMembersLocally();
  }

  Future<void> _saveSelectedMembersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _selected.map((m) => m.toJson()).toList();
      await prefs.setString('latest_yatra_members', jsonEncode(list));
    } catch (_) {}
  }

  void _openChatWithUser(ContactUserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YatraChatScreen(
          chatType: YatraChatType.single,
          title: user.name,
          subtitle: user.isRegistered ? "Devotee on BharatPray" : "Yatri",
          targetUserId: user.id,
          phoneNumber: user.mobile,
          messages: const [],
        ),
      ),
    );
  }

  void _shareInvite(ContactUserModel user) {
    final shareMsg = 'Jai Shree Ram! 🙏 Join me on BharatPray for sacred Pilgrimage Yatras, Temple Darshans & Sangha Groups. Download BharatPray now: https://bharatpray.com/invite';
    Share.share(shareMsg, subject: 'Join BharatPray Yatra');
  }

  void _showNewContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFE8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7700).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_rounded, color: Color(0xFFFF7700), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "New Contact",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF2E2A36)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36)),
              decoration: InputDecoration(
                labelText: "Full Name",
                hintText: "e.g. Ramesh Kumar",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFFF7700), size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36)),
              decoration: InputDecoration(
                labelText: "Phone / Mobile",
                hintText: "e.g. +91 98765 43210",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFFFF7700), size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: const Color(0xFF7A757F), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter both Name and Phone number")),
                );
                return;
              }
              Navigator.pop(ctx);
              await _saveCustomContact(name, phone);
              _performContactSync();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Added $name to Yatri Contacts!")),
                );
              }
            },
            child: Text("Save Contact", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupModal() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final List<ContactUserModel> groupSelected = [];
    String innerSearch = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final allContacts = [..._registeredUsers, ..._nonRegisteredUsers];
          final filtered = allContacts.where((u) {
            final q = innerSearch.toLowerCase();
            return u.name.toLowerCase().contains(q) || u.mobile.contains(q);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8D6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Top drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2A36).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.group_add_rounded, color: Color(0xFFFF7700), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create Group",
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                            ),
                            Text(
                              "${groupSelected.length} yatris selected",
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A757F)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF2E2A36)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE8D2B8)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    children: [
                      // Group Name Input
                      TextField(
                        controller: nameCtrl,
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2E2A36)),
                        decoration: InputDecoration(
                          labelText: "Group Name",
                          hintText: "e.g. Somnath Darshan Sangha",
                          prefixIcon: const Icon(Icons.groups_rounded, color: Color(0xFFFF7700), size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Destination / Description Input
                      TextField(
                        controller: descCtrl,
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
                        decoration: InputDecoration(
                          labelText: "Destination / Yatra (Optional)",
                          hintText: "e.g. Somnath Temple, Kedarnath",
                          prefixIcon: const Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF7700), size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Select Yatris (${groupSelected.length} added)",
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36).withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 8),

                      // Search Yatris Input
                      TextField(
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Search yatris by name or phone...",
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFFFF7700)),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                        ),
                        onChanged: (val) => setSheetState(() => innerSearch = val.trim()),
                      ),
                      const SizedBox(height: 10),

                      ...filtered.map((u) {
                        final isSel = groupSelected.any((s) => s.id == u.id || (s.mobile == u.mobile && u.mobile.isNotEmpty));
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? const Color(0xFFFF7700) : const Color(0xFFE8D2B8),
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSel,
                            activeColor: const Color(0xFFFF7700),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            secondary: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFFFE8D6),
                              backgroundImage: u.profilePic.isNotEmpty ? NetworkImage(ApiService.resolveImageUrl(u.profilePic)) : null,
                              child: u.profilePic.isEmpty
                                  ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : 'P',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFFF7700), fontSize: 13))
                                  : null,
                            ),
                            title: Text(u.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.5, color: const Color(0xFF2E2A36))),
                            subtitle: Text(u.mobile, style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF7A757F))),
                            onChanged: (_) {
                              setSheetState(() {
                                if (isSel) {
                                  groupSelected.removeWhere((s) => s.id == u.id || (s.mobile == u.mobile && u.mobile.isNotEmpty));
                                } else {
                                  groupSelected.add(u);
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Bottom Create Group Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: Text("Create Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () => _finalizeGroupCreation(ctx, nameCtrl.text.trim(), descCtrl.text.trim(), groupSelected),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _finalizeGroupCreation(
    BuildContext sheetContext,
    String groupName,
    String destination,
    List<ContactUserModel> members,
  ) async {
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name")),
      );
      return;
    }

    Navigator.pop(sheetContext);

    final newGroupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final List<Map<String, dynamic>> memberMaps = members.map((m) => <String, dynamic>{
      'id': m.id,
      'name': m.name,
      'mobile': m.mobile,
      'profilePic': m.profilePic,
      'city': m.city,
      'address': m.address,
      'role': 'member',
      'isAdmin': false,
    }).toList();

    // Add current user as leader
    final prefs = await SharedPreferences.getInstance();
    final myName = prefs.getString('name') ?? prefs.getString('fullName') ?? 'You';
    final myPic = prefs.getString('profile_pic') ?? '';
    final myCity = prefs.getString('city') ?? '';
    final myAddress = prefs.getString('address') ?? '';
    memberMaps.insert(0, <String, dynamic>{
      'name': '$myName (Leader)',
      'mobile': 'Leader',
      'profilePic': myPic,
      'city': myCity,
      'address': myAddress,
      'role': 'leader',
      'isAdmin': true,
    });

    final newGroupMap = {
      '_id': newGroupId,
      'name': groupName,
      'destination': destination.isNotEmpty ? destination : 'Pilgrimage Yatra',
      'memberCount': memberMaps.length,
      'lastMessage': 'Yatra group created. Har Har Mahadev! 🚩',
      'time': 'Just now',
      'unread': 0,
      'avatar': 'assets/images/somnath.png',
      'members': memberMaps,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    // Save locally to active groups
    final existingJson = prefs.getString('active_yatra_groups');
    List<dynamic> list = existingJson != null ? jsonDecode(existingJson) : [];
    list.insert(0, newGroupMap);
    await prefs.setString('active_yatra_groups', jsonEncode(list));

    // Try backend API in background
    final token = await _getToken();
    if (token.isNotEmpty) {
      ApiService.createYatraGroup(token, {
        'name': groupName,
        'description': destination,
        'inviteeIds': members.map((m) => m.id).where((id) => id.isNotEmpty).toList(),
      }).catchError((e) {
        debugPrint("Background group creation error: $e");
        return <String, dynamic>{};
      });
    }

    if (!mounted) return;

    // Navigate to the newly created group chat
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => YatraChatScreen(
          chatType: YatraChatType.group,
          title: groupName,
          subtitle: "${memberMaps.length} Yatris active",
          headerAvatarAsset: 'assets/images/somnath.png',
          yatraId: newGroupId,
          members: memberMaps,
          groupMembersText: "${memberMaps.length} Yatris in this Yatra Sangha",
          about: "Official Yatra Sangha group for ${destination.isNotEmpty ? destination : groupName}.",
          location: destination,
          messages: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Merge registered and non-registered contacts into a single continuous list
    final allContacts = [
      ..._registeredUsers,
      ..._nonRegisteredUsers,
    ];

    final filteredContacts = allContacts.where((u) {
      final q = _searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) || u.mobile.contains(q);
    }).toList();

    return PopScope(
      canPop: !_inGroupCreation,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _selected);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          _inGroupCreation ? 'Select Members (${_selected.length})' : 'Select Contact',
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () async {
            await _saveSelectedMembersLocally();
            if (context.mounted) Navigator.pop(context, _selected);
          },
        ),
        actions: [
          if (_inGroupCreation)
            TextButton(
              onPressed: () async {
                await _saveSelectedMembersLocally();
                if (context.mounted) Navigator.pop(context, _selected);
              },
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // If not in group creation selection mode, include 2 header items: New Contact and Create Group
                    itemCount: (!_inGroupCreation ? 2 : 0) + filteredContacts.length,
                    itemBuilder: (context, index) {
                      // Top Action 1: New Contact
                      if (!_inGroupCreation && index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8D2B8)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: _showNewContactDialog,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_add_rounded, color: Color(0xFFFF7700), size: 22),
                            ),
                            title: Text(
                              "New Contact",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            subtitle: Text(
                              "Add a yatri's phone number",
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A757F)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFFF7700)),
                          ),
                        );
                      }

                      // Top Action 2: Create Group
                      if (!_inGroupCreation && index == 1) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8D2B8)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: _showCreateGroupModal,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF7700),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                            ),
                            title: Text(
                              "Create Group",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            subtitle: Text(
                              "Group chat with multiple yatris",
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A757F)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFFF7700)),
                          ),
                        );
                      }

                      final actualIndex = !_inGroupCreation ? index - 2 : index;
                      final user = filteredContacts[actualIndex];
                      final isSelected = _selected.any((m) => m.id == user.id || (m.mobile == user.mobile && user.mobile.isNotEmpty));
                      final isRegistered = user.isRegistered;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8D2B8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            if (_inGroupCreation) {
                              if (isRegistered) {
                                _toggleMember(user);
                              } else {
                                _shareInvite(user);
                              }
                            } else if (isRegistered) {
                              _openChatWithUser(user);
                            } else {
                              _shareInvite(user);
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            radius: 21,
                            backgroundColor: isRegistered ? const Color(0xFFFFE8D6) : const Color(0xFFEFE6DB),
                            backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(ApiService.resolveImageUrl(user.profilePic)) : null,
                            child: user.profilePic.isEmpty
                                ? Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                                    style: GoogleFonts.outfit(
                                      color: isRegistered ? const Color(0xFFFF7700) : const Color(0xFF7A757F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
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
                                    fontSize: 14.5,
                                    color: const Color(0xFF2E2A36),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.isMutualFollower)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE8D6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Mutual',
                                    style: GoogleFonts.outfit(fontSize: 10.5, color: const Color(0xFFFF7700), fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            user.mobile,
                            style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF7A757F), fontWeight: FontWeight.w500),
                          ),
                          trailing: _inGroupCreation
                              ? (user.isAlreadyMember
                                  ? Text(
                                      'In Group',
                                      style: GoogleFonts.outfit(color: const Color(0xFF7A757F), fontSize: 12, fontWeight: FontWeight.w600),
                                    )
                                  : (isRegistered
                                      ? ElevatedButton(
                                          onPressed: () => _toggleMember(user),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSelected ? const Color(0xFFE8D2B8) : const Color(0xFFFF7700),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: Text(
                                            isSelected ? 'Remove' : 'Add',
                                            style: GoogleFonts.outfit(
                                              color: isSelected ? const Color(0xFF2E2A36) : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        )
                                      : OutlinedButton.icon(
                                          onPressed: () => _shareInvite(user),
                                          icon: const Icon(Icons.share_rounded, size: 13, color: Color(0xFFFF7700)),
                                          label: Text(
                                            'Invite',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFFF7700),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFFFF7700)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        )))
                              : (isRegistered
                                  // Registered user: Message button
                                  ? ElevatedButton.icon(
                                      onPressed: () => _openChatWithUser(user),
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.white),
                                      label: Text(
                                        'Message',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF7700),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    )
                                  // Unregistered user: Invite button
                                  : OutlinedButton.icon(
                                      onPressed: () => _shareInvite(user),
                                      icon: const Icon(Icons.share_rounded, size: 13, color: Color(0xFFFF7700)),
                                      label: Text(
                                        'Invite',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFF7700),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFFFF7700)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    )),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
}

