import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/utsav_service.dart';
import 'mandal_profile_screen.dart';

class CreateMandalPostScreen extends StatefulWidget {
  final String mandalName;
  final String? festivalName;
  final String? location;
  const CreateMandalPostScreen({
    super.key,
    this.mandalName = "Shree Ram Yuvak Mandal",
    this.festivalName,
    this.location,
  });

  @override
  State<CreateMandalPostScreen> createState() => _CreateMandalPostScreenState();
}

class _CreateMandalPostScreenState extends State<CreateMandalPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _festivalName = "Pre Navratri";
  String _mandalLocation = "Gujarat, India";
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.festivalName != null && widget.festivalName!.isNotEmpty) {
      _festivalName = widget.festivalName!;
    }
    if (widget.location != null && widget.location!.isNotEmpty) {
      _mandalLocation = widget.location!;
    }
    _loadMandalRegistration();
    _checkLostData();
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
          if ((widget.location == null || widget.location!.isEmpty) &&
              reg['address'] != null && reg['address'].toString().trim().isNotEmpty) {
            _mandalLocation = reg['address'].toString().trim();
          }
        });
      }
    } catch (_) {}
  }

  // RECOVER IMAGE IF ANDROID KILLS ACTIVITY ON CAMERA INTENT
  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        setState(() {
          _selectedImagePath = response.file!.path;
        });
      }
    } catch (e) {
      debugPrint("Lost data error: $e");
    }
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
                "Select Photo Source",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
              ),
              const SizedBox(height: 6),
              Text(
                "Choose how you want to add your Mandal post image:",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // OPTION 1: CAMERA (OPTIMIZED TO PREVENT MEMORY CRASH)
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? picked = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1800,
                      maxHeight: 1800,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      setState(() => _selectedImagePath = picked.path);
                    } else if (_selectedImagePath == null) {
                      setState(() => _selectedImagePath = "assets/images/ram_bhajan.png");
                    }
                  } catch (e) {
                    if (_selectedImagePath == null) {
                      setState(() => _selectedImagePath = "assets/images/ram_bhajan.png");
                    }
                  }
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
                        child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Take from Camera", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
                            Text("Take a new photo using camera", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
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
                    final XFile? picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1800,
                      maxHeight: 1800,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      setState(() => _selectedImagePath = picked.path);
                    } else if (_selectedImagePath == null) {
                      setState(() => _selectedImagePath = "assets/images/somnath_hero.png");
                    }
                  } catch (e) {
                    if (_selectedImagePath == null) {
                      setState(() => _selectedImagePath = "assets/images/somnath_hero.png");
                    }
                  }
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
                        child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Browse from Gallery", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36))),
                            Text("Choose photo from device gallery", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
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
          "Create Mandal Post",
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upload Post Photo:",
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
                    color: _selectedImagePath == null ? const Color(0xFFFF7700).withOpacity(0.5) : const Color(0xFFFF7700),
                    width: 2,
                  ),
                ),
                child: _selectedImagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7700),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tap to Select Photo",
                            style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Take from Camera or Browse Gallery",
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            buildSmartImage(_selectedImagePath, fit: BoxFit.cover),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Post Caption & Details:",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 4,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
              decoration: InputDecoration(
                hintText: "Write a detailed caption for your Mandal post...",
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 18),

            // AUTO-LINKED MANDAL INFO (Registered Festival & Location)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF7700).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
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
                              "Registered Festival",
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _festivalName,
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
                          "Auto-Linked",
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFF5EDE4), height: 1),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7700).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFFFF7700), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mandal Location",
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _mandalLocation,
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                icon: const Icon(Icons.send_rounded, size: 22),
                label: Text(
                  "Share Post to Mandal Feed",
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
                        content: Text("તહેવાર શરૂ થયા પછી જ Post કરી શકાશે (${check['formattedDate']})."),
                        backgroundColor: const Color(0xFFD32F2F),
                      ),
                    );
                    return;
                  }
                  if (_captionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a caption")),
                    );
                    return;
                  }
                  final newPost = PostItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    imageUrl: _selectedImagePath ?? "assets/images/ram_bhajan.png",
                    caption: _captionController.text.trim(),
                    festivalName: _festivalName,
                    location: _mandalLocation,
                    timeAgo: "Just now",
                    likes: 0,
                    isLiked: false,
                  );
                  await UtsavService.saveMandalPost(widget.mandalName.isNotEmpty ? widget.mandalName : _festivalName, newPost.toJson());
                  if (mounted) {
                    Navigator.pop(context, newPost);
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
