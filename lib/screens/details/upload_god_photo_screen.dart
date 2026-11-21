import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../../services/api_service.dart';
import '../../services/jap_voice_service.dart';
import '../../services/yatra_personal_chat_service.dart';
import '../../widgets/jap/custom_jap_preview_sheet.dart';
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
  final _displayNameController = TextEditingController();
  final _mantraController = TextEditingController();
  final _chantCountController = TextEditingController(text: '108');

  // Audio toggles & Background Dhun selection
  bool _voiceEnabled = true;
  bool _musicEnabled = true;
  String _selectedBackgroundDhun = 'audio/temple_peaceful_dhun.wav';
  final AudioPlayer _dhunPreviewPlayer = AudioPlayer();

  static const List<Map<String, String>> _templeDhunOptions = [
    {
      'path': 'audio/temple_peaceful_dhun.wav',
      'label': 'Sacred Temple Bells',
      'description': 'Resonant temple bells & calm sacred ambience',
    },
    {
      'path': 'audio/ram_mandir_dhun.wav',
      'label': 'Singing Bowl Serenity',
      'description': 'Warm 432 Hz brass singing bowl resonance',
    },
    {
      'path': 'audio/krishna_flute_dhun.wav',
      'label': 'Vedic Tanpura Drone',
      'description': 'Traditional meditative Tanpura harmonic cycle',
    },
    {
      'path': 'audio/shiva_meditative_dhun.wav',
      'label': 'Deep Om Resonance',
      'description': 'Deep 136.1 Hz grounding Om meditation hum',
    },
  ];

  String get _selectedDhunLabel {
    final match = _templeDhunOptions.where((d) => d['path'] == _selectedBackgroundDhun);
    return match.isNotEmpty ? match.first['label']! : 'Sacred Temple Bells';
  }

  // Audio file & Auto-Generate Voice
  String? _audioFileName;
  String? _audioFilePath;
  bool _isGeneratingAudio = false;
  bool _isPlayingAudioPreview = false;
  final AudioPlayer _chantPreviewPlayer = AudioPlayer();

  // Dropdowns
  String? _selectedCategory;
  String? _selectedParticleEffect;

  final ImagePicker _picker = ImagePicker();

  // Guard flags — prevents setState after dispose & concurrent image picker calls
  bool _isActive = true;
  bool _isPickingImage = false;

  static const String _prefDraftCover = 'draft_custom_jap_cover_path';
  static const String _prefDraftGod = 'draft_custom_jap_god_path';
  static const String _prefPendingIsCover = 'draft_custom_jap_pending_is_cover';

  // God categories (loaded dynamically from backend API)
  List<Map<String, String>> _categories = [];

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

  Future<File> _persistPickedImage(String sourcePath, {required bool isCover}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final draftDir = Directory('${dir.path}/custom_jap_drafts');
      if (!await draftDir.exists()) {
        await draftDir.create(recursive: true);
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${draftDir.path}/${isCover ? "cover" : "god"}_$ts.jpg';
      final copied = await File(sourcePath).copy(destPath);
      return copied;
    } catch (_) {
      return File(sourcePath);
    }
  }

  Future<void> _saveDraftPaths({bool? pendingIsCover}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_coverImage != null) {
        await prefs.setString(_prefDraftCover, _coverImage!.path);
      } else {
        await prefs.remove(_prefDraftCover);
      }
      if (_godImage != null) {
        await prefs.setString(_prefDraftGod, _godImage!.path);
      } else {
        await prefs.remove(_prefDraftGod);
      }
      if (pendingIsCover != null) {
        await prefs.setBool(_prefPendingIsCover, pendingIsCover);
      }
    } catch (_) {}
  }

  Future<void> _clearDraftPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefDraftCover);
      await prefs.remove(_prefDraftGod);
      await prefs.remove(_prefPendingIsCover);
    } catch (_) {}
  }

  Future<void> _retrieveLostData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCover = prefs.getString(_prefDraftCover);
      final savedGod = prefs.getString(_prefDraftGod);
      final pendingIsCover = prefs.getBool(_prefPendingIsCover);

      final LostDataResponse response = await _picker.retrieveLostData();
      if (!mounted || !_isActive) return;

      // Only restore draft images if the OS actually recreated the Activity during a pick
      if (!response.isEmpty && response.file != null) {
        final bool targetIsCover = pendingIsCover ?? (savedCover == null);
        final persisted = await _persistPickedImage(
          response.file!.path,
          isCover: targetIsCover,
        );
        if (!mounted || !_isActive) return;
        setState(() {
          if (savedCover != null && File(savedCover).existsSync()) {
            _coverImage = File(savedCover);
          }
          if (savedGod != null && File(savedGod).existsSync()) {
            _godImage = File(savedGod);
          }
          if (targetIsCover) {
            _coverImage = persisted;
          } else {
            _godImage = persisted;
          }
        });
        await _saveDraftPaths();
      } else {
        // Fresh screen open — clear any stale draft paths
        await _clearDraftPaths();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    YatraPersonalChatService().unreadMessageCount.removeListener(_onUnreadMessagesChanged);
    _isActive = false;
    _nameController.dispose();
    _displayNameController.dispose();
    _mantraController.dispose();
    _chantCountController.dispose();
    _dhunPreviewPlayer.stop();
    _dhunPreviewPlayer.dispose();
    _chantPreviewPlayer.stop();
    _chantPreviewPlayer.dispose();
    super.dispose();
  }

  // ─── Pick image with source choice popup ─────────────────────────────────
  Future<void> _showImagePickerPopup({required bool isCover}) async {
    if (_isPickingImage || !_isActive || !mounted) return;
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
    if (!_isActive || !mounted || _isPickingImage) return;
    _isPickingImage = true;

    try {
      // Save current draft & free decoded image cache RAM before launching heavy native Camera/Gallery
      await _saveDraftPaths(pendingIsCover: isCover);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Brief delay to allow modal bottom sheet dismissal to finish cleanly on Android
      await Future.delayed(const Duration(milliseconds: 120));
      if (!_isActive || !mounted) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
        requestFullMetadata: false,
      );
      // User pressed back without picking — silently return
      if (!_isActive || !mounted || image == null) return;

      final persistedFile = await _persistPickedImage(image.path, isCover: isCover);
      if (!_isActive || !mounted) return;

      setState(() {
        if (isCover) {
          _coverImage = persistedFile;
        } else {
          _godImage = persistedFile;
        }
      });
      await _saveDraftPaths();
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
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _generateAutoAudio() async {
    final text = _mantraController.text.trim().isNotEmpty
        ? _mantraController.text.trim()
        : _nameController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter Mantra / Chant Text first');
      return;
    }
    if (_isGeneratingAudio) return;

    setState(() => _isGeneratingAudio = true);
    try {
      final voiceService = JapVoiceService();
      final voiceId = await voiceService.loadSelectedVoiceId();
      final clipPath = await voiceService.prepareChantClip(text, voiceId);
      if (!mounted || !_isActive) return;

      if (clipPath != null && File(clipPath).existsSync()) {
        await _chantPreviewPlayer.stop();
        setState(() {
          _audioFilePath = clipPath;
          _audioFileName = 'Auto Audio • $text.mp3';
          _isPlayingAudioPreview = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Auto Audio ready for "$text"',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      } else {
        _showError('Could not generate audio. Check internet connection.');
      }
    } catch (e) {
      if (mounted && _isActive) {
        _showError('Audio generation failed. Please try again.');
      }
    } finally {
      if (mounted && _isActive) {
        setState(() => _isGeneratingAudio = false);
      }
    }
  }

  Future<void> _toggleChantAudioPreview() async {
    final path = _audioFilePath;
    if (path == null || path.isEmpty) return;
    try {
      if (_isPlayingAudioPreview) {
        await _chantPreviewPlayer.stop();
        if (mounted) setState(() => _isPlayingAudioPreview = false);
      } else {
        await _dhunPreviewPlayer.stop();
        await _chantPreviewPlayer.stop();
        _chantPreviewPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlayingAudioPreview = false);
        });
        if (path.startsWith('http')) {
          await _chantPreviewPlayer.play(UrlSource(path));
        } else {
          await _chantPreviewPlayer.play(DeviceFileSource(path));
        }
        if (mounted) setState(() => _isPlayingAudioPreview = true);
      }
    } catch (e) {
      debugPrint('[UploadGodPhoto] Chant audio preview error: $e');
      if (mounted) setState(() => _isPlayingAudioPreview = false);
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

  // ─── Background Temple Dhun sheet with live audio preview ────────────────
  Future<void> _showDhunPickerSheet() async {
    String? playingPath;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> togglePreview(String path) async {
              try {
                if (playingPath == path) {
                  await _dhunPreviewPlayer.stop();
                  setSheetState(() => playingPath = null);
                } else {
                  await _dhunPreviewPlayer.stop();
                  await _dhunPreviewPlayer.setVolume(0.75);
                  await _dhunPreviewPlayer.play(AssetSource(path));
                  setSheetState(() => playingPath = path);
                }
              } catch (e) {
                debugPrint('[UploadGodPhoto] Dhun preview error: $e');
              }
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEFE6DB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8A882).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select Background Dhun',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF2E2A36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final dhun in _templeDhunOptions)
                    InkWell(
                      onTap: () {
                        _dhunPreviewPlayer.stop();
                        Navigator.pop(sheetContext);
                        setState(() => _selectedBackgroundDhun = dhun['path']!);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dhun['label']!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedBackgroundDhun == dhun['path']
                                          ? const Color(0xFFFF7700)
                                          : const Color(0xFF2E2A36),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dhun['description']!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => togglePreview(dhun['path']!),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: playingPath == dhun['path']
                                    ? Colors.white
                                    : const Color(0xFFFF7700),
                                backgroundColor: playingPath == dhun['path']
                                    ? const Color(0xFFFF7700)
                                    : Colors.transparent,
                                side: const BorderSide(color: Color(0xFFFF9933)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: Icon(
                                playingPath == dhun['path']
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: Text(
                                playingPath == dhun['path'] ? 'Stop' : 'Preview',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );

    // Always stop preview audio when bottom sheet closes
    await _dhunPreviewPlayer.stop();
  }

  // ─── Jap effect sheet with previews ───────────────────────────────────────
  String? get _selectedJapEffectLabel {
    final match = CustomJapEffect.all.where((e) => e.value == _selectedParticleEffect);
    return match.isNotEmpty ? match.first.label : null;
  }

  void _showJapEffectSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEFE6DB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Select Jap',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF2E2A36),
                ),
              ),
              const SizedBox(height: 8),
              for (final effect in CustomJapEffect.all)
                InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _selectedParticleEffect = effect.value);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                effect.label,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedParticleEffect == effect.value
                                      ? const Color(0xFFFF7700)
                                      : const Color(0xFF2E2A36),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                effect.description,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => CustomJapPreviewSheet.show(
                            context,
                            effect: effect,
                            imagePath: _godImage?.path,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF7700),
                            side: const BorderSide(color: Color(0xFFFF9933)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text(
                            'Preview',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
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
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      _showError('Please enter Display Name');
      return;
    }
    final mantraText = _mantraController.text.trim();
    if (mantraText.isEmpty) {
      _showError('Please enter Mantra / Chant Text');
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
    if (_selectedParticleEffect == null || _selectedParticleEffect!.isEmpty) {
      _showError('Please select Jap');
      return;
    }
    final chantCount = int.tryParse(_chantCountController.text.trim());
    if (chantCount == null || chantCount < 1) {
      _showError('Please enter a valid Chant Count');
      return;
    }

    _clearDraftPaths();

    Navigator.pop(
      context,
      CustomJapDetails(
        coverImagePath: _coverImage!.path,
        godImagePath: _godImage!.path,
        name: name,
        displayName: displayName,
        mantraText: mantraText,
        voiceText: mantraText,
        backgroundMusic: _musicEnabled ? _selectedBackgroundDhun : '',
        voiceEnabled: _voiceEnabled,
        musicEnabled: _musicEnabled,
        audioFileName: _audioFileName ?? '',
        audioFilePath: _audioFilePath ?? '',
        chantCount: chantCount,
        category: _selectedCategory!,
        particleEffect: _selectedParticleEffect!,
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
                      _sectionLabel('Jap Name', isRequired: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'e.g. Shri Ram / Om Namah Shivaya',
                        icon: Icons.auto_awesome_outlined,
                      ),
                      const SizedBox(height: 16),

                      // 3a. Display Name (shown during chanting top bar)
                      _sectionLabel('Display Name', isRequired: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _displayNameController,
                        hint: 'e.g. RAM / SHIVA / RADHA',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),

                      // 3b. Mantra / Chanting Text + Auto Audio Generator Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionLabel('Mantra / Chant Text', isRequired: true),
                          GestureDetector(
                            onTap: _isGeneratingAudio ? null : _generateAutoAudio,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFF9900)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isGeneratingAudio)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFF7700),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 13,
                                      color: Color(0xFFFF7700),
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isGeneratingAudio ? 'Generating...' : 'Auto Audio 🎙️',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF7700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _mantraController,
                        hint: 'e.g. રામ / ॐ नमः शिवाय',
                        icon: Icons.record_voice_over_outlined,
                      ),
                      const SizedBox(height: 16),

                      // 3c. Chant Audio Box (Auto-Generated or Custom MP3/WAV)
                      _sectionLabel('Chant Audio (Auto or Upload)'),
                      const SizedBox(height: 8),
                      _buildAudioBox(),
                      const SizedBox(height: 16),

                      // 3c. Voice & Background Dhun Toggles
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEFE6DB)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.volume_up_rounded, color: Color(0xFFFF7700), size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Voice Chant',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2E2A36),
                                      ),
                                    ),
                                  ],
                                ),
                                Switch.adaptive(
                                  value: _voiceEnabled,
                                  activeThumbColor: const Color(0xFFFF7700),
                                  activeTrackColor: const Color(0xFFFF9933).withValues(alpha: 0.35),
                                  onChanged: (v) => setState(() => _voiceEnabled = v),
                                ),
                              ],
                            ),
                            const Divider(height: 1, color: Color(0xFFEFE6DB)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Background Temple Dhun',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2E2A36),
                                      ),
                                    ),
                                  ],
                                ),
                                Switch.adaptive(
                                  value: _musicEnabled,
                                  activeThumbColor: const Color(0xFFFF7700),
                                  activeTrackColor: const Color(0xFFFF9933).withValues(alpha: 0.35),
                                  onChanged: (v) => setState(() => _musicEnabled = v),
                                ),
                              ],
                            ),
                            if (_musicEnabled) ...[
                              const Divider(height: 1, color: Color(0xFFEFE6DB)),
                              InkWell(
                                onTap: _showDhunPickerSheet,
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.library_music_outlined, color: Color(0xFFFF7700), size: 17),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _selectedDhunLabel,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFE65100),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'Change / Preview',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF8C6239),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFC8A882), size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Audio File — full width box
                      // _sectionLabel('Audio File (Optional)'),
                      // const SizedBox(height: 8),
                      // _buildAudioBox(),
                      // const SizedBox(height: 16),

                      // 4. Chant Count
                      _sectionLabel('Chant Count', isRequired: true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _chantCountController,
                        hint: '108',
                        icon: Icons.repeat_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // 5. God Category dropdown
                      _sectionLabel('God Category', isRequired: true),
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

                      // 6. Jap effect dropdown
                      _sectionLabel('Select Jap', isRequired: true),
                      const SizedBox(height: 8),
                      _buildDropdownTile(
                        hint: 'Select Jap',
                        value: _selectedJapEffectLabel,
                        icon: Icons.movie_filter_rounded,
                        onTap: _showJapEffectSheet,
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
              'Create Custom Jap',
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
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label, isRequired: isRequired),
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
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                          cacheWidth: 600,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Color(0xFFFF7700),
                              size: 36,
                            ),
                          ),
                        ),
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
  Widget _sectionLabel(String text, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2E2A36).withValues(alpha: 0.55),
          letterSpacing: 0.4,
        ),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE53935),
                  ),
                ),
              ]
            : null,
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
  // ignore: unused_element
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
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _toggleChantAudioPreview,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isPlayingAudioPreview
                                      ? const Color(0xFFFF7700)
                                      : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFF9900)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isPlayingAudioPreview
                                          ? Icons.stop_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 15,
                                      color: _isPlayingAudioPreview
                                          ? Colors.white
                                          : const Color(0xFFFF7700),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _isPlayingAudioPreview ? 'Stop' : 'Preview',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: _isPlayingAudioPreview
                                            ? Colors.white
                                            : const Color(0xFFFF7700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tap card to upload',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF8C6239),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Clear button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        _chantPreviewPlayer.stop();
                        setState(() {
                          _audioFileName = null;
                          _audioFilePath = null;
                          _isPlayingAudioPreview = false;
                        });
                      },
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
  final String displayName;
  final String mantraText;
  final String voiceText;
  final String backgroundMusic;
  final bool voiceEnabled;
  final bool musicEnabled;
  final String audioFileName;
  final String audioFilePath;
  final int chantCount;
  final String category;
  final String particleEffect;

  CustomJapDetails({
    required this.coverImagePath,
    required this.godImagePath,
    required this.name,
    this.displayName = '',
    this.mantraText = '',
    this.voiceText = '',
    this.backgroundMusic = '',
    this.voiceEnabled = true,
    this.musicEnabled = true,
    required this.audioFileName,
    required this.audioFilePath,
    required this.chantCount,
    required this.category,
    required this.particleEffect,
  });
}
