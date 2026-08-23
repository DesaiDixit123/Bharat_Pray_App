import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'mandal_profile_screen.dart';

class CreateMandalReelScreen extends StatefulWidget {
  final String mandalName;
  const CreateMandalReelScreen({super.key, this.mandalName = "Shree Ram Yuvak Mandal"});

  @override
  State<CreateMandalReelScreen> createState() => _CreateMandalReelScreenState();
}

class _CreateMandalReelScreenState extends State<CreateMandalReelScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _audioController = TextEditingController(text: "Ram Siya Ram • Mandal Dhun");
  final ImagePicker _picker = ImagePicker();

  String _selectedFestival = "🛕 Somnath Maha Shivratri Mahotsav";
  String? _selectedVideoPath;

  final List<String> _festivalList = [
    "🛕 Somnath Maha Shivratri Mahotsav",
    "🚩 Shree Ram Navami Mahotsav",
    "✨ Shri Krishna Janmashtami Utsav",
    "🪔 Diwali Deepotsav Mahotsav",
    "💃 Navratri Garba Mahotsav",
    "🌸 Hanuman Jayanti Utsav",
  ];

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
                      setState(() => _selectedVideoPath = picked.path);
                    } else {
                      setState(() => _selectedVideoPath = "assets/images/ram_bhajan.png");
                    }
                  } catch (e) {
                    setState(() => _selectedVideoPath = "assets/images/ram_bhajan.png");
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
                      setState(() => _selectedVideoPath = picked.path);
                    } else {
                      setState(() => _selectedVideoPath = "assets/images/krishna.png");
                    }
                  } catch (e) {
                    setState(() => _selectedVideoPath = "assets/images/krishna.png");
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
          "Create Mandal Reel 🎬",
          style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upload Reel Video:",
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
                            "Tap to Select Reel Video",
                            style: GoogleFonts.outfit(color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Record Camera Video or Browse Gallery",
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            buildSmartImage(_selectedVideoPath, fit: BoxFit.cover),
                            Container(color: Colors.black38),
                            const Center(
                              child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Reel Title & Description:",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
              decoration: InputDecoration(
                hintText: "Reel Title (e.g. Somnath Damru Aarti Clips)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Audio / Dhun Track Name:",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _audioController,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.music_note_rounded, color: Color(0xFFFF7700), size: 22),
                hintText: "Add Audio Soundtrack",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Festival Name:",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2E2A36)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFestival,
              dropdownColor: Colors.white,
              iconEnabledColor: const Color(0xFFFF7700),
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: _festivalList.map((fest) {
                return DropdownMenuItem(
                  value: fest,
                  child: Text(
                    fest,
                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF2E2A36), fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFestival = val);
              },
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
                  "Publish Reel to Mandal Profile",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a reel title")),
                    );
                    return;
                  }
                  final newReel = ReelItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    thumbnailUrl: _selectedVideoPath ?? "assets/images/ram_bhajan.png",
                    title: _titleController.text.trim(),
                    audioTrack: _audioController.text.trim(),
                    festivalName: _selectedFestival,
                    views: "1.0k",
                    likes: 1,
                    isLiked: true,
                  );
                  Navigator.pop(context, newReel);
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
