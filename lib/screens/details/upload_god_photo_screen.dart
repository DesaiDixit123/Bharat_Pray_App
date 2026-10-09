import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../../services/api_service.dart';
import '../../services/yatra_personal_chat_service.dart';
import 'notification_screen.dart';
import 'messages_screen.dart';

// Top-level constant — avoids static-inside-State issues
const _audioPickerChannel = MethodChannel('com.bharatpray/audio_picker');

class UploadGodPhotoScreen extends StatefulWidget {
  const UploadGodPhotoScreen({super.key});

  @override
  State<UploadGodPhotoScreen> createState() => _UploadGodPhotoScreenState();
}

class _UploadGodPhotoScreenState extends State<UploadGodPhotoScreen> {
  // Images
  File? _coverImage;
  File? _godImage;

  // Text controllers
  final _nameController = TextEditingController();
  final _chantCountController = TextEditingController(text: '108');

  // Audio file
  String? _audioFileName;
  String? _audioFilePath;

  // Dropdowns
  String? _selectedCategory;
  String? _selectedParticleEffect;

  final ImagePicker _picker = ImagePicker();

  // Guard flag — prevents setState after widget is disposed
  bool _isActive = true;

  // God categories (loaded dynamically from backend API)
  List<Map<String, String>> _categories = [];

  // 10 Chant effect options matching reference styles
  final List<Map<String, String>> _particleEffects = [
    {'value': 'auto',       'label': '✨ Auto (Deity Default)'},
    {'value': 'ram',        'label': '🏹 1. Shri Ram - Golden Ram Burst'},
    {'value': 'om',         'label': '🌿 2. Om - Green Leaf Effect'},
    {'value': 'radhe',      'label': '🦚 3. Radhe Krishna - Blue Glow Effect'},
    {'value': 'hanuman',    'label': '🚩 4. Hanuman - Red Flame Effect'},
    {'value': 'shiva',      'label': '🔱 5. Shiva - Purple Cosmic Effect'},
    {'value': 'durga',      'label': '🌺 6. Maa Durga - Flower Petals Effect'},
    {'value': 'sai',        'label': '🕊️ 7. Sai Baba - White Light Effect'},
    {'value': 'gayatri',    'label': '📜 8. Gayatri Mantra - Sanskrit Text Effect'},
    {'value': 'navkar',     'label': '🪷 9. Navkar Mantra - Golden Particles Effect'},
    {'value': 'meditation', 'label': '🧘 10. Meditation - Calm Wave Effect'},
  ];

  @override
  void initState() {
    super.initState();
    _messageCount = YatraPersonalChatService().unreadMessageCount.value;
    YatraPersonalChatService().unreadMessageCount.addListener(_onUnreadMessagesChanged);
    YatraPersonalChatService().refreshUnreadCount();
    _retrieveLostData();
    _fetchGodCategories();
  }

  void _onUnreadMessagesChanged() {
    if (mounted) {
      setState(() {
        _messageCount = YatraPersonalChatService().unreadMessageCount.value;
      });
    }
  }

  Future<void> _fetchGodCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

      List<dynamic> rawList = [];
      try {
        rawList = await ApiService.getBhajanGodCategories(token);
      } catch (e) {
        debugPrint('[UploadGodPhoto] getBhajanGodCategories error: $e');
      }

      if (rawList.isEmpty) {
        try {
          rawList = await ApiService.getGodCategories(token);
        } catch (e) {
          debugPrint('[UploadGodPhoto] getGodCategories error: $e');
        }
      }

      if (rawList.isNotEmpty) {
        final List<Map<String, String>> parsed = [];
        for (final item in rawList) {
          if (item is Map) {
            final id = (item['_id'] ?? item['id'] ?? '').toString();
            final name = (item['name'] ?? item['title'] ?? item['categoryName'] ?? '').toString().trim();
            if (id.isNotEmpty && name.isNotEmpty) {
              parsed.add({
                'id': id,
                'name': name,
              });
            }
          }
        }

        if (mounted && _isActive) {
          setState(() {
            _categories = parsed;
          });
        }
      }
    } catch (e) {
      debugPrint('[UploadGodPhoto] Error fetching god categories: $e');
    }
  }

  Future<void> _retrieveLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null || !mounted || !_isActive) {
        return;
      }
      setState(() {
        if (_coverImage == null) {
          _coverImage = File(response.file!.path);
        } else if (_godImage == null) {
          _godImage = File(response.file!.path);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    YatraPersonalChatService().unreadMessageCount.removeListener(_onUnreadMessagesChanged);
    _isActive = false;
    _nameController.dispose();
    _chantCountController.dispose();
    super.dispose();
  }

  // ─── Pick image with source choice popup ─────────────────────────────────
  Future<void> _showImagePickerPopup({required bool isCover}) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,   // swipe down → only sheet closes, not screen
      enableDrag: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFE6DB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC8A882).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isCover ? 'Upload Cover Image' : 'Upload God Image',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'JPG, PNG — Max 10MB',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 20),
            // Camera button
            _popupOptionTile(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo with Camera',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Color(0xFFEFE6DB), height: 1),
            ),
            // Gallery button
            _popupOptionTile(
              icon: Icons.image_outlined,
              label: 'Choose from Gallery',
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null && mounted && _isActive) {
      await _pickImage(source, isCover: isCover);
    }
  }

  Widget _popupOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9933).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF7700), size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E2A36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, {required bool isCover}) async {
    if (!_isActive || !mounted) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      // User pressed back without picking — silently return
      if (!_isActive || !mounted || image == null) return;
      setState(() {
        if (isCover) {
          _coverImage = File(image.path);
        } else {
          _godImage = File(image.path);
        }
      });
    } on PlatformException catch (e) {
      if (!_isActive || !mounted) return;
      // Ignore permission/cancel codes silently
      if (e.code != 'camera_access_denied' &&
          e.code != 'photo_access_denied' &&
          e.code != 'already_active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF5500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Could not open camera. Please try gallery.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        );
      }
    } catch (_) {
      // Back gesture / any other cancel — silently ignore, no crash
    }
  }

  // ─── Audio file picker — opens Android native document picker ─────────────
  Future<void> _pickAudioFile() async {
    if (!_isActive || !mounted) return;
    try {
      final result =
          await _audioPickerChannel.invokeMethod<Map>('pickAudioFile');
      // User pressed back — result is null, do nothing
      if (!_isActive || !mounted || result == null) return;
      setState(() {
        _audioFileName = result['name'] as String? ?? 'audio_file';
        _audioFilePath = result['path'] as String? ?? '';
      });
    } on PlatformException catch (e) {
      if (!_isActive || !mounted) return;
      if (e.code != 'CANCELLED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF5500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Could not open file picker.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        );
      }
    } catch (_) {
      // Cancelled or back gesture — silently ignore
    }
  }

  // ─── Dropdown sheet ───────────────────────────────────────────────────────
  void _showDropdown({
    required String title,
    required List<Map<String, String>> options,
    required String? selectedValue,
    required void Function(String value, String label) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEFE6DB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8A882).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Color(0xFFEFE6DB), height: 1),
              ),
              Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: Color(0xFFEFE6DB), height: 1),
                    ),
                    itemBuilder: (context, i) {
                      final opt = options[i];
                      final isSelected = selectedValue == opt['value'];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onSelected(opt['value']!, opt['label'] ?? opt['name'] ?? '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opt['label'] ?? opt['name'] ?? '',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFFFF7700)
                                        : const Color(0xFF2E2A36),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFFFF7700), size: 20),
                            ],
                          ),
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
  }

  // ─── Save / Submit ────────────────────────────────────────────────────────
  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter Jap name');
      return;
    }
    if (_coverImage == null) {
      _showError('Please upload Cover Image');
      return;
    }
    if (_godImage == null) {
      _showError('Please upload God Image');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please select God Category');
      return;
    }

    Navigator.pop(
      context,
      CustomJapDetails(
        coverImagePath: _coverImage!.path,
        godImagePath: _godImage!.path,
        name: name,
        audioFileName: _audioFileName ?? '',
        audioFilePath: _audioFilePath ?? '',
        chantCount: int.tryParse(_chantCountController.text.trim()) ?? 108,
        category: _selectedCategory!,
        particleEffect: _selectedParticleEffect ?? 'auto',
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFFF5500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF0E6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0E6),
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(),

              // ── Scrollable Form Body ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Cover Image — full width
                      _buildImageCard(
                        label: 'Cover Image',
                        image: _coverImage,
                        onTap: () => _showImagePickerPopup(isCover: true),
                        onClear: () => setState(() => _coverImage = null),
                      ),
                      const SizedBox(height: 16),

                      // 2. God Image — full width
                      _buildImageCard(
                        label: 'God Image',
                        image: _godImage,
                        onTap: () => _showImagePickerPopup(isCover: false),
                        onClear: () => setState(() => _godImage = null),
                      ),
                      const SizedBox(height: 16),

                      // 3. Jap Name
                      _sectionLabel('Jap Name'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'e.g. Om Namah Shivaya',
                        icon: Icons.auto_awesome_outlined,
                      ),
                      const SizedBox(height: 16),

                      // 4. Audio File — full width box
                      _sectionLabel('Audio File (Optional)'),
                      const SizedBox(height: 8),
                      _buildAudioBox(),
                      const SizedBox(height: 16),

                      // 4. Chant Count
                      _sectionLabel('Chant Count'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _chantCountController,
                        hint: '108',
                        icon: Icons.repeat_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // 5. God Category dropdown
                      _sectionLabel('God Category'),
                      const SizedBox(height: 8),
                      _buildDropdownTile(
                        hint: 'Select God Category',
                        value: () {
                          if (_selectedCategory == null) return null;
                          final match = _categories.where((c) => c['id'] == _selectedCategory);
                          return match.isNotEmpty ? match.first['name'] : null;
                        }(),
                        icon: Icons.account_balance_outlined,
                        onTap: () => _showDropdown(
                          title: 'Select God Category',
                          options: _categories
                              .map((c) => {
                                    'value': c['id'] ?? '',
                                    'label': c['name'] ?? '',
                                  })
                              .toList(),
                          selectedValue: _selectedCategory,
                          onSelected: (val, _) =>
                              setState(() => _selectedCategory = val),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 6. Particle Effect Style dropdown
                      _sectionLabel('Particle Effect Style'),
                      const SizedBox(height: 8),
                      _buildDropdownTile(
                        hint: '✨ Auto (Deity Default)',
                        value: _selectedParticleEffect != null
                            ? _particleEffects.firstWhere(
                                (e) => e['value'] == _selectedParticleEffect,
                                orElse: () => {'label': ''},
                              )['label']
                            : null,
                        icon: Icons.auto_fix_high_rounded,
                        onTap: () => _showDropdown(
                          title: 'Particle Effect Style',
                          options: _particleEffects,
                          selectedValue: _selectedParticleEffect,
                          onSelected: (val, _) =>
                              setState(() => _selectedParticleEffect = val),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 7. Save button
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _messageCount = 0;
  int _notificationCount = 0;

  String _getMailSvg(int count) {
    final fill = count > 0 ? '#FF0000' : 'none';
    return '''<svg width="26" height="24" viewBox="0 0 26 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6.01417 3.9978C3.80516 3.9978 2.01416 5.7888 2.01416 7.9978V15.9978C2.01416 18.2068 3.80516 19.9978 6.01417 19.9978H18.0142C20.2232 19.9978 22.0142 18.2068 22.0142 15.9978V7.9978C22.0142 5.7888 20.2232 3.9978 18.0142 3.9978H6.01417ZM6.01417 5.9978H18.0142C19.0222 5.9978 19.8552 6.73781 19.9932 7.70781C19.0352 8.60081 17.6112 9.6968 16.6702 10.3728C14.5052 11.9278 12.6002 12.9978 12.0142 12.9978C11.4282 12.9978 9.52317 11.9288 7.35816 10.3728C6.41716 9.6968 5.49217 8.9658 4.79517 8.3728C4.49817 8.1198 4.27816 7.9158 4.10816 7.7478C4.24616 6.7778 5.00616 5.9978 6.01417 5.9978ZM4.02417 10.3518C6.56218 12.4048 10.2812 14.9858 12.0142 14.9978C13.1432 15.0058 15.0742 13.9278 17.0442 12.5668C18.0632 11.8618 19.1972 11.0248 20.0152 10.3378L20.0142 15.9978C20.0142 17.1028 19.1192 17.9978 18.0142 17.9978H6.01417C4.90916 17.9978 4.01416 17.1028 4.01416 15.9978L4.02417 10.3518Z" fill="#6B4226"/>
<circle cx="22" cy="4.5" r="4" fill="$fill"/>
</svg>''';
  }

  String _getBellSvg(int count) {
    final fill = count > 0 ? '#FF0000' : 'none';
    return '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 6.43994V9.76994" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round"/>
<path d="M12.02 2C8.34002 2 5.36002 4.98 5.36002 8.66V10.76C5.36002 11.44 5.08002 12.46 4.73002 13.04L3.46002 15.16C2.68002 16.47 3.22002 17.93 4.66002 18.41C9.44002 20 14.61 20 19.39 18.41C20.74 17.96 21.32 16.38 20.59 15.16L19.32 13.04C18.97 12.46 18.69 11.43 18.69 10.76V8.66C18.68 5 15.68 2 12.02 2Z" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round"/>
<path d="M15.33 18.8199C15.33 20.6499 13.83 22.1499 12 22.1499C11.09 22.1499 10.25 21.7699 9.65004 21.1699C9.05004 20.5699 8.67004 19.7299 8.67004 18.8199" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10"/>
<circle cx="18" cy="4.5" r="4" fill="$fill"/>
</svg>''';
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC8A882),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: SvgPicture.string(
                  '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''',
                  width: 15,
                  height: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Expanded(
            child: Text(
              'Create Jap',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
          ),
          // Mail icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              ).then((_) {
                YatraPersonalChatService().refreshUnreadCount();
              });
            },
            child: SvgPicture.string(
              _getMailSvg(_messageCount),
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Notification icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            child: SvgPicture.string(
              _getBellSvg(_notificationCount),
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image upload card ────────────────────────────────────────────────────
  Widget _buildImageCard({
    required String label,
    required File? image,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: image != null
                    ? const Color(0xFFFF9933).withValues(alpha: 0.5)
                    : const Color(0xFFEFE6DB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: image != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(image, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onClear,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                      // Edit overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(18)),
                          ),
                          child: Center(
                            child: Text(
                              'Change',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9933).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_rounded,
                          color: Color(0xFFFF9933),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Image',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to choose',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
        letterSpacing: 0.4,
      ),
    );
  }

  // ─── Text field ───────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFE6DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(icon, size: 18, color: const Color(0xFFC8A882)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF2E2A36),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF2E2A36).withValues(alpha: 0.35),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ─── Audio box (full width, like image card) ───────────────────────────
  Widget _buildAudioBox() {
    return GestureDetector(
      onTap: _pickAudioFile,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _audioFileName != null
                ? const Color(0xFFFF9933).withValues(alpha: 0.5)
                : const Color(0xFFEFE6DB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _audioFileName != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Filled state
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9933).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.audio_file_rounded,
                            color: Color(0xFFFF7700),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _audioFileName!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to change',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFFFF7700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Clear button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() { _audioFileName = null; _audioFilePath = null; }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFF2E2A36), size: 14),
                      ),
                    ),
                  ),
                ],
              )
            // Empty state
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9933).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Color(0xFFFF9933),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload Audio File (Optional)',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Optional • MP3, M4A — Max 10MB',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Dropdown tile ────────────────────────────────────────────────────────
  Widget _buildDropdownTile({
    required String hint,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value != null
                ? const Color(0xFFFF9933).withValues(alpha: 0.5)
                : const Color(0xFFEFE6DB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value != null
                  ? const Color(0xFFFF7700)
                  : const Color(0xFFC8A882),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? hint,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight:
                      value != null ? FontWeight.w600 : FontWeight.normal,
                  color: value != null
                      ? const Color(0xFF2E2A36)
                      : const Color(0xFF2E2A36).withValues(alpha: 0.35),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFFC8A882),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Save button ──────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _onSave,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6600).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Add to My Japs',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data model returned to caller ───────────────────────────────────────────
class CustomJapDetails {
  final String coverImagePath;
  final String godImagePath;
  final String name;
  final String audioFileName;
  final String audioFilePath;
  final int chantCount;
  final String category;
  final String particleEffect;

  CustomJapDetails({
    required this.coverImagePath,
    required this.godImagePath,
    required this.name,
    required this.audioFileName,
    required this.audioFilePath,
    required this.chantCount,
    required this.category,
    required this.particleEffect,
  });
}
