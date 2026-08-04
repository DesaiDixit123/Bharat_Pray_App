import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/yatra_model.dart';
import '../../services/api_service.dart';
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

  String _visibility = 'public';
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
    _fetchTemples();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
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

  Future<void> _calculateDistance(YatraTemple temple) async {
    setState(() {
      _selectedTemple = temple;
      _calculatingDistance = true;
    });

    try {
      final token = await _getToken();
      final res = await ApiService.calculateTempleDistance(
        token,
        templeId: temple.id,
      );

      setState(() {
        _totalDistanceKm = (res['totalDistanceKm'] ?? 0.0).toDouble();
        _estimatedSteps = res['estimatedSteps'] ?? 0;
        _estimatedDays = res['estimatedDays'] ?? 0;
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
    if (_selectedTemple == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Temple for your Yatra.')),
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
        'templeId': _selectedTemple!.id,
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
        Navigator.pop(context, true);
      } else {
        throw Exception(res['message'] ?? 'Failed to create group');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group creation failed: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Create Yatra Group', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Selector
              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                    image: _coverImagePath != null
                        ? DecorationImage(image: FileImage(File(_coverImagePath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _coverImagePath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, color: Color(0xFFFF7A00), size: 32),
                            SizedBox(height: 8),
                            Text('Upload Group Cover Image (Optional)',
                                style: TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Group Name Field
              const Text('Group Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Kedarnath Yatra Pilgrims',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Group Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Temple Dropdown Selection
              const Text('Select Temple / Yatra Destination *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showTemplePickerDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.temple_hindu, color: Color(0xFFFF7A00)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTemple != null ? '${_selectedTemple!.name} (${_selectedTemple!.city})' : 'Tap to search & select Temple',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedTemple != null ? FontWeight.bold : FontWeight.normal,
                            color: _selectedTemple != null ? Colors.black87 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Auto Distance & Calculations Display
              if (_calculatingDistance)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else if (_selectedTemple != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCalcStat('Distance', '${_totalDistanceKm.toStringAsFixed(1)} KM', Icons.straighten),
                      _buildCalcStat('Est. Steps', '$_estimatedSteps', Icons.directions_walk),
                      _buildCalcStat('Est. Days', '$_estimatedDays Days', Icons.calendar_today),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Group Visibility
              const Text('Group Visibility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Public', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: 'public',
                      groupValue: _visibility,
                      activeColor: const Color(0xFFFF7A00),
                      onChanged: (val) => setState(() => _visibility = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Private', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: 'private',
                      groupValue: _visibility,
                      activeColor: const Color(0xFFFF7A00),
                      onChanged: (val) => setState(() => _visibility = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Members Section
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Text('Add Members (${_selectedMembers.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  TextButton.icon(
                    onPressed: _openAddMembers,
                    icon: const Icon(Icons.person_add, color: Color(0xFFFF7A00), size: 18),
                    label: const Text('Sync Contacts', style: TextStyle(color: Color(0xFFFF7A00), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (_selectedMembers.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _selectedMembers.map((member) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(member.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 12)),
                      ),
                      label: Text(member.name, style: const TextStyle(fontSize: 12)),
                      onDeleted: () {
                        setState(() => _selectedMembers.remove(member));
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Description
              const Text('Description (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Add yatra rules, spiritual quotes, or guidance...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Yatra Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF7A00), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }

  void _showTemplePickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Select Temple', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _templeSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Temple name, city, state...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      _fetchTemples(search: val).then((_) => setModalState(() {}));
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _loadingTemples
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: _templeList.length,
                            itemBuilder: (context, index) {
                              final temple = _templeList[index];
                              return ListTile(
                                leading: const Icon(Icons.temple_hindu, color: Color(0xFFFF7A00)),
                                title: Text(temple.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${temple.city}, ${temple.state}'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _calculateDistance(temple);
                                },
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
