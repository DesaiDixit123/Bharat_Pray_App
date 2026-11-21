import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/localization/localized_api_helper.dart';
import '../../services/utsav_service.dart';
import 'mandal_profile_screen.dart';

class CreateMandalReelScreen extends StatefulWidget {
  final String mandalName;
  final String? festivalName;
  const CreateMandalReelScreen({
    super.key,
    this.mandalName = "Shree Ram Yuvak Mandal",
    this.festivalName,
  });

  @override
  State<CreateMandalReelScreen> createState() => _CreateMandalReelScreenState();
}

class _CreateMandalReelScreenState extends State<CreateMandalReelScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _audioController = TextEditingController(text: "Mandal Bhajan & Aarti Track");
  final ImagePicker _picker = ImagePicker();

  String _festivalName = "Pre Navratri";
  String? _selectedVideoPath;
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;

  @override
  void initState() {
    super.initState();
    if (widget.festivalName != null && widget.festivalName!.isNotEmpty) {
      _festivalName = widget.festivalName!;
    }
    _loadMandalRegistration();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  Future<void> _initVideoController(String path) async {
    try {
      await _videoController?.dispose();
      _videoController = null;
      setState(() {
        _selectedVideoPath = path;
        _isVideoInitializing = true;
      });

      final isAsset = path.startsWith('assets/');
      final controller = isAsset
          ? VideoPlayerController.asset(path)
          : VideoPlayerController.file(File(path));

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1.0);
      await controller.play();

      if (mounted) {
        setState(() {
          _videoController = controller;
          _isVideoInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoInitializing = false;
        });
      }
    }
  }

  Future<void> _loadMandalRegistration() async {
    try {
      final reg = await UtsavService.getMyMandalRegistration();
      if (reg != null && mounted) {
        setState(() {
          if ((widget.festivalName == null || widget.festivalName!.isEmpty) &&
              reg['festival'] != null && reg['festival'].toString().trim().isNotEmpty) {
            _festivalName = reg['festival'].toString().trim();
          }
        });
      }
    } catch (_) {}
  }

  void _showMediaSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Video Source",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
              ),
              const SizedBox(height: 6),
              Text(
                "Choose how you want to add your Reel video:",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // OPTION 1: CAMERA (ORANGE)
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? picked = await _picker.pickVideo(source: ImageSource.camera);
                    if (picked != null) {
                      await _initVideoController(picked.path);
                    }
                  } catch (e) {}
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7700).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF7700).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFFFF7700), shape: BoxShape.circle),
                        child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Take from Camera", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
                            Text("Capture a new video using camera", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF7700), size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // OPTION 2: GALLERY (ORANGE)
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
                    if (picked != null) {
                      await _initVideoController(picked.path);
                    }
                  } catch (e) {}
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7700).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF7700).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFFFF7700), shape: BoxShape.circle),
                        child: const Icon(Icons.video_library_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Browse from Gallery", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
                            Text("Select video from device gallery", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF7700), size: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          LocalizedApiHelper.parse("Create Mandal Reel 🎬"),
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocalizedApiHelper.parse("Upload Reel Video:"),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: _showMediaSourceDialog,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedVideoPath == null ? const Color(0xFFFF7700).withOpacity(0.5) : const Color(0xFFFF7700),
                    width: 2,
                  ),
                ),
                child: _selectedVideoPath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7700),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LocalizedApiHelper.parse("Tap to Select Reel Video"),
                            style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LocalizedApiHelper.parse("Record Camera Video or Browse Gallery"),
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _isVideoInitializing
                            ? Container(
                                color: const Color(0xFF2E2A36),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(color: Color(0xFFFF7700)),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Loading Video Preview...",
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                            : (_videoController != null && _videoController!.value.isInitialized)
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.cover,
                                        clipBehavior: Clip.hardEdge,
                                        child: SizedBox(
                                          width: _videoController!.value.size.width,
                                          height: _videoController!.value.size.height,
                                          child: VideoPlayer(_videoController!),
                                        ),
                                      ),
                                      Container(color: Colors.black26),
                                      Center(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (_videoController!.value.isPlaying) {
                                                _videoController!.pause();
                                              } else {
                                                _videoController!.play();
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: const BoxDecoration(
                                              color: Colors.black45,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _videoController!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 38,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: InkWell(
                                          onTap: _showMediaSourceDialog,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF7700),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Change",
                                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Container(color: const Color(0xFF2E2A36)),
                                      const Center(
                                        child: Icon(Icons.videocam_rounded, color: Color(0xFFFF7700), size: 48),
                                      ),
                                    ],
                                  ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              LocalizedApiHelper.parse("Reel Title & Description:"),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
              decoration: InputDecoration(
                hintText: LocalizedApiHelper.parse("Reel Title (e.g. Somnath Damru Aarti Clips)"),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              LocalizedApiHelper.parse("Audio / Dhun Track Name:"),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _audioController,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 22),
                hintText: LocalizedApiHelper.parse("Add Audio Soundtrack"),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 18),

            // AUTO-LINKED FESTIVAL BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF7700).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7700).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.festival_rounded, color: Color(0xFFFF7700), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizedApiHelper.parse("Registered Festival"),
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          LocalizedApiHelper.parse(_festivalName),
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      LocalizedApiHelper.parse("Auto-Linked"),
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                icon: const Icon(Icons.video_library_rounded, size: 22),
                label: Text(
                  LocalizedApiHelper.parse("Publish Reel to Mandal Profile"),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final check = await UtsavService.checkFestivalStartedForMandal(
                    festivalName: _festivalName,
                    mandalName: widget.mandalName,
                  );
                  if (check['isStarted'] != true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("તહેવાર શરૂ થયા પછી જ Reel પબ્લિશ કરી શકાશે (${check['formattedDate']})."),
                        backgroundColor: const Color(0xFFD32F2F),
                      ),
                    );
                    return;
                  }
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a reel title")),
                    );
                    return;
                  }
                  final newReel = ReelItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    thumbnailUrl: "assets/images/devotional/navratri_garba_festival.jpg",
                    videoUrl: _selectedVideoPath,
                    title: _titleController.text.trim(),
                    audioTrack: _audioController.text.trim(),
                    festivalName: _festivalName,
                    views: "0",
                    likes: 0,
                    isLiked: false,
                  );
                  await UtsavService.saveMandalReel(widget.mandalName.isNotEmpty ? widget.mandalName : _festivalName, newReel.toJson());
                  if (mounted) {
                    Navigator.pop(context, newReel);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
