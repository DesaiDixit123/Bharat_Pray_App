import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/yatra_model.dart';
import '../../models/yatra_group_models.dart';
import '../../services/api_service.dart';
import '../details/start_yatra_overview_screen.dart';
import 'contact_sync_screen.dart';

class CreateYatraGroupScreen extends StatefulWidget {
  const CreateYatraGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateYatraGroupScreen> createState() => _CreateYatraGroupScreenState();
}

class _CreateYatraGroupScreenState extends State<CreateYatraGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _templeSearchController = TextEditingController();
  final TextEditingController _adminYatraSearchController = TextEditingController();

  String _yatraType = 'admin'; // 'admin' or 'custom'
  String _visibility = 'public';

  // Admin Yatra selection
  List<YatraModel> _adminYatraList = [];
  YatraModel? _selectedAdminYatra;
  bool _loadingAdminYatras = false;

  // Custom Yatra selection
  YatraTemple? _startTemple;
  YatraTemple? _selectedTemple;
  List<YatraTemple> _templeList = [];
  bool _loadingTemples = false;
  bool _calculatingDistance = false;
  bool _submitting = false;

  double _totalDistanceKm = 0.0;
  int _estimatedSteps = 0;
  int _estimatedDays = 0;
  String? _coverImagePath;

  List<ContactUserModel> _selectedMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminYatras();
    _fetchTemples();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _fetchAdminYatras({String search = ''}) async {
    setState(() => _loadingAdminYatras = true);
    try {
      final token = await _getToken();
      final res = await ApiService.getPopularYatra(token: token, search: search, limit: 20);
      setState(() {
        _adminYatraList = res.data ?? [];
      });
    } catch (e) {
      print('Failed to load admin yatras: $e');
    } finally {
      setState(() => _loadingAdminYatras = false);
    }
  }

  Future<void> _fetchTemples({String search = ''}) async {
    setState(() => _loadingTemples = true);
    try {
      final token = await _getToken();
      final res = await ApiService.getTemplesForGroup(token, search: search);
      final docs = res['docs'] as List<dynamic>? ?? [];
      setState(() {
        _templeList = docs.map((d) => YatraTemple.fromJson(d)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load temples: $e')),
      );
    } finally {
      setState(() => _loadingTemples = false);
    }
  }

  Future<void> _calculateDistance() async {
    final targetTemple = _selectedTemple ?? _startTemple;
    if (targetTemple == null) return;

    setState(() {
      _calculatingDistance = true;
    });

    try {
      final token = await _getToken();
      final res = await ApiService.calculateTempleDistance(
        token,
        templeId: _selectedTemple?.id ?? _startTemple?.id ?? '',
        startTempleId: _startTemple?.id,
        startLat: _startTemple?.latitude,
        startLng: _startTemple?.longitude,
      );

      setState(() {
        _totalDistanceKm = (res['totalDistanceKm'] ?? res['totalDistance'] ?? res['distance'] ?? 0.0).toDouble();

        final rawSteps = res['estimatedSteps'];
        if (rawSteps is int) {
          _estimatedSteps = rawSteps;
        } else if (rawSteps != null) {
          _estimatedSteps = int.tryParse(rawSteps.toString().replaceAll(RegExp(r'\D'), '')) ?? (_totalDistanceKm * 1400).round();
        } else {
          _estimatedSteps = (_totalDistanceKm * 1400).round();
        }

        final rawDays = res['estimatedDays'] ?? res['duration'];
        if (rawDays is int) {
          _estimatedDays = rawDays;
        } else if (rawDays != null) {
          _estimatedDays = int.tryParse(rawDays.toString().replaceAll(RegExp(r'\D'), '')) ?? (_totalDistanceKm / 30.0).ceil();
        } else {
          _estimatedDays = (_totalDistanceKm / 30.0).ceil();
        }
      });
    } catch (e) {
      print('Distance calculation fallback error: $e');
    } finally {
      setState(() => _calculatingDistance = false);
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _coverImagePath = picked.path);
    }
  }

  Future<void> _openAddMembers() async {
    final result = await Navigator.push<List<ContactUserModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => ContactSyncScreen(selectedMembers: _selectedMembers),
      ),
    );

    if (result != null) {
      setState(() => _selectedMembers = result);
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_yatraType == 'admin' && _selectedAdminYatra == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Admin Yatra from the list.')),
      );
      return;
    }

    if (_yatraType == 'custom' && _selectedTemple == null && _startTemple == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Start Location or Destination Temple.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = await _getToken();

      String coverBase64 = '';
      if (_coverImagePath != null) {
        final bytes = await File(_coverImagePath!).readAsBytes();
        coverBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final payload = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'yatraType': _yatraType,
        'yatraId': _yatraType == 'admin' ? _selectedAdminYatra?.id : null,
        'startTempleId': _yatraType == 'custom' ? _startTemple?.id : null,
        'endTempleId': _yatraType == 'custom' ? _selectedTemple?.id : null,
        'templeId': _yatraType == 'admin'
            ? (_selectedAdminYatra?.templeId ?? _selectedAdminYatra?.id)
            : (_selectedTemple?.id ?? _startTemple?.id),
        'visibility': _visibility,
        'totalDistance': _totalDistanceKm,
        'estimatedSteps': _estimatedSteps,
        'estimatedDays': _estimatedDays,
        'coverImage': coverBase64,
        'inviteeIds': _selectedMembers.map((m) => m.id).toList(),
      };

      final res = await ApiService.createYatraGroup(token, payload);
      if (res['_id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yatra Group created successfully!')),
        );
        final String selectedRouteName = _yatraType == 'admin' && _selectedAdminYatra != null
            ? _selectedAdminYatra!.title
            : (_selectedTemple != null
                ? '${_startTemple != null ? _startTemple!.name : "Start"} to ${_selectedTemple!.name}'
                : _nameController.text.trim());

        final String displayTitle = _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : (selectedRouteName.isNotEmpty ? selectedRouteName : 'Yatra Group');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StartYatraOverviewScreen(
              id: res['_id']?.toString() ?? _selectedAdminYatra?.id ?? _selectedTemple?.id ?? '',
              title: displayTitle,
              routeName: selectedRouteName,
              distance: '${_totalDistanceKm > 0 ? _totalDistanceKm.toStringAsFixed(1) : "450"} KM',
              steps: _estimatedSteps > 0 ? '$_estimatedSteps' : '108k',
              duration: '${_estimatedDays > 0 ? _estimatedDays : 5} Days',
              sangha: '${_selectedMembers.length + 1}',
              imageAsset: (_coverImagePath != null && _coverImagePath!.isNotEmpty)
                  ? _coverImagePath!
                  : (_yatraType == 'admin' && _selectedAdminYatra != null && _selectedAdminYatra!.image.isNotEmpty
                      ? _selectedAdminYatra!.image
                      : (_selectedTemple != null && _selectedTemple!.image.isNotEmpty)
                          ? _selectedTemple!.image
                          : 'assets/images/somnath_temple_new.png'),
              isFromCreateGroup: true,
            ),
          ),
        );
      } else {
        throw Exception(res['message'] ?? 'Failed to create group');
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group creation failed: $cleanMsg')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text('Create Yatra Group', style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Selector Card
              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  height: 145,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF7700), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: (_coverImagePath != null && _coverImagePath!.isNotEmpty)
                        ? DecorationImage(image: FileImage(File(_coverImagePath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (_coverImagePath == null || _coverImagePath!.isEmpty)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, color: Color(0xFFFF7700), size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'Upload Group Cover Image (Optional)',
                              style: GoogleFonts.outfit(color: const Color(0xFFFF7700), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Group Name Field
              Text('Group Name *', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. Kedarnath Yatra Pilgrims',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.4), fontSize: 13),
                  prefixIcon: const Icon(Icons.group_outlined, color: Color(0xFFFF7700), size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Group Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Yatra Type Segment Selector
              Text('Select Yatra Type *', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEFE6DB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _yatraType = 'admin';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _yatraType == 'admin' ? const Color(0xFFFF7700) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stars_rounded, size: 18, color: _yatraType == 'admin' ? Colors.white : const Color(0xFF2E2A36)),
                              const SizedBox(width: 6),
                              Text(
                                'Admin Yatra',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _yatraType == 'admin' ? Colors.white : const Color(0xFF2E2A36),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _yatraType = 'custom';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _yatraType == 'custom' ? const Color(0xFFFF7700) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_location_alt_rounded, size: 18, color: _yatraType == 'custom' ? Colors.white : const Color(0xFF2E2A36)),
                              const SizedBox(width: 6),
                              Text(
                                'Custom Yatra',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _yatraType == 'custom' ? Colors.white : const Color(0xFF2E2A36),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Body Based on Yatra Type Selection
              if (_yatraType == 'admin') ...[
                // Admin Yatra Picker
                Text('Select Admin Yatra *', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showAdminYatraPickerDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEFE6DB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF7700), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedAdminYatra != null ? _selectedAdminYatra!.title : 'Tap to select predefined Admin Yatra',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: _selectedAdminYatra != null ? FontWeight.bold : FontWeight.w500,
                              color: _selectedAdminYatra != null ? const Color(0xFF2E2A36) : const Color(0xFF2E2A36).withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF7700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Display Selected Admin Yatra Summary Card
                if (_selectedAdminYatra != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _selectedAdminYatra!.image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.temple_hindu_rounded, size: 36, color: Color(0xFFFF7700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedAdminYatra!.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF2E2A36))),
                                  const SizedBox(height: 2),
                                  Text('Admin Predefined Yatra', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFFF7700), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFEFE6DB))),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCalcStat('Distance', _selectedAdminYatra!.distance, Icons.straighten_rounded),
                            _buildCalcStat('Est. Steps', _selectedAdminYatra!.steps, Icons.directions_walk_rounded),
                            _buildCalcStat('Est. Days', _selectedAdminYatra!.duration, Icons.calendar_today_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                // Custom Yatra Pickers (Start Temple & End Temple)
                Text('Start Location / Starting Temple *', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showTemplePickerDialog(context, isStart: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEFE6DB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: Color(0xFFFF7700), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _startTemple != null ? '${_startTemple!.name} (${_startTemple!.city})' : 'Tap to search & select Start Location',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: _startTemple != null ? FontWeight.bold : FontWeight.w500,
                              color: _startTemple != null ? const Color(0xFF2E2A36) : const Color(0xFF2E2A36).withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF7700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Select Temple / Yatra Destination *', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showTemplePickerDialog(context, isStart: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEFE6DB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.temple_hindu_rounded, color: Color(0xFFFF7700), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedTemple != null ? '${_selectedTemple!.name} (${_selectedTemple!.city})' : 'Tap to search & select Destination Temple',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: _selectedTemple != null ? FontWeight.bold : FontWeight.w500,
                              color: _selectedTemple != null ? const Color(0xFF2E2A36) : const Color(0xFF2E2A36).withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF7700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Auto Distance & Calculations Display for Custom Yatra
                if (_calculatingDistance)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Color(0xFFFF7700))))
                else if (_selectedTemple != null || _startTemple != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCalcStat('Distance', '${_totalDistanceKm.toStringAsFixed(1)} KM', Icons.straighten_rounded),
                        _buildCalcStat('Est. Steps', '$_estimatedSteps', Icons.directions_walk_rounded),
                        _buildCalcStat('Est. Days', '$_estimatedDays Days', Icons.calendar_today_rounded),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 20),

              // Add Members Header + Sync Contacts Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Members (${_selectedMembers.length})', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
                  TextButton.icon(
                    onPressed: _openAddMembers,
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFFF7700), size: 18),
                    label: Text('Sync Contacts', style: GoogleFonts.outfit(color: const Color(0xFFFF7700), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              if (_selectedMembers.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMembers.map((m) {
                    return Chip(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFEFE6DB)),
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFFFF7700),
                        child: Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : '?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      label: Text(m.name, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36), fontWeight: FontWeight.w600)),
                      onDeleted: () {
                        setState(() => _selectedMembers.remove(m));
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Description
              Text('Description (Optional)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36), fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Add yatra rules, spiritual quotes, or guidance...',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.4), fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7700),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Create Yatra Group', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF7700), size: 22),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36))),
        Text(title, style: GoogleFonts.outfit(color: const Color(0xFF2E2A36).withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }

  void _showAdminYatraPickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFE8D6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Admin Predefined Yatra',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _adminYatraSearchController,
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
                    decoration: InputDecoration(
                      hintText: 'Search by Yatra title...',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFFF7700)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
                    ),
                    onChanged: (val) {
                      _fetchAdminYatras(search: val).then((_) => setModalState(() {}));
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _loadingAdminYatras
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
                        : ListView.separated(
                            itemCount: _adminYatraList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final yatra = _adminYatraList[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEFE6DB)),
                                ),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      yatra.image,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.temple_hindu_rounded, size: 28, color: Color(0xFFFF7700)),
                                    ),
                                  ),
                                  title: Text(yatra.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36), fontSize: 15)),
                                  subtitle: Text('${yatra.distance} • ${yatra.duration}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _selectedAdminYatra = yatra;
                                      final rawDist = double.tryParse(yatra.distance.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
                                      _totalDistanceKm = rawDist;

                                      final rawSteps = yatra.estimatedStepsNum > 0
                                          ? yatra.estimatedStepsNum
                                          : int.tryParse(yatra.steps.replaceAll(RegExp(r'\D'), '')) ?? (_totalDistanceKm * 1400).round();
                                      _estimatedSteps = rawSteps;

                                      final rawDays = yatra.estimatedDaysNum > 0
                                          ? yatra.estimatedDaysNum
                                          : int.tryParse(yatra.duration.replaceAll(RegExp(r'\D'), '')) ?? (_totalDistanceKm / 30.0).ceil();
                                      _estimatedDays = rawDays;
                                    });
                                  },
                                ),
                              );
                            },
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

  void _showTemplePickerDialog(BuildContext context, {required bool isStart}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFE8D6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isStart ? 'Select Start Location / Temple' : 'Select Destination Temple',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _templeSearchController,
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
                    decoration: InputDecoration(
                      hintText: 'Search by Temple name, city, state...',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFFF7700)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEFE6DB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF7700))),
                    ),
                    onChanged: (val) {
                      _fetchTemples(search: val).then((_) => setModalState(() {}));
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _loadingTemples
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
                        : ListView.separated(
                            itemCount: _templeList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final temple = _templeList[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEFE6DB)),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(isStart ? Icons.my_location_rounded : Icons.temple_hindu_rounded, color: const Color(0xFFFF7700), size: 22),
                                  ),
                                  title: Text(temple.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36), fontSize: 15)),
                                  subtitle: Text('${temple.city}, ${temple.state}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      if (isStart) {
                                        _startTemple = temple;
                                      } else {
                                        _selectedTemple = temple;
                                      }
                                    });
                                    _calculateDistance();
                                  },
                                ),
                              );
                            },
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
