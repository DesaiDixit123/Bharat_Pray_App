import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:io';

class UploadGodPhotoScreen extends StatefulWidget {
  const UploadGodPhotoScreen({super.key});

  @override
  State<UploadGodPhotoScreen> createState() => _UploadGodPhotoScreenState();
}

class _UploadGodPhotoScreenState extends State<UploadGodPhotoScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF5500),
          content: Text(
            'Error selecting image: $e',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _showDetailsDialog() {
    final nameController = TextEditingController();
    final mantraController = TextEditingController();
    final targetController = TextEditingController(text: '108');
    final mainContext = context;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF0E6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFC8A882), width: 1.5),
          ),
          title: Text(
            'Enter Jap Details',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E2A36),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.outfit(color: const Color(0xFF2E2A36)),
                  decoration: InputDecoration(
                    labelText: 'Deity Name',
                    labelStyle: GoogleFonts.outfit(color: const Color(0xFFC8A882)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: const Color(0xFFC8A882).withValues(alpha: 0.5)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF7700)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mantraController,
                  style: GoogleFonts.outfit(color: const Color(0xFF2E2A36)),
                  decoration: InputDecoration(
                    labelText: 'Mantra Text',
                    labelStyle: GoogleFonts.outfit(color: const Color(0xFFC8A882)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: const Color(0xFFC8A882).withValues(alpha: 0.5)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF7700)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(color: const Color(0xFF2E2A36)),
                  decoration: InputDecoration(
                    labelText: 'Target Count',
                    labelStyle: GoogleFonts.outfit(color: const Color(0xFFC8A882)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: const Color(0xFFC8A882).withValues(alpha: 0.5)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF7700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final name = nameController.text.trim();
                final mantra = mantraController.text.trim();
                final targetStr = targetController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter Deity Name')),
                  );
                  return;
                }
                if (mantra.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter Mantra Text')),
                  );
                  return;
                }

                final target = int.tryParse(targetStr) ?? 108;

                Navigator.pop(context);

                Navigator.pop(
                  mainContext,
                  CustomJapDetails(
                    imagePath: _selectedImage!.path,
                    name: name,
                    mantra: mantra,
                    target: target,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Add to Japs',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Custom SVGs from Figma specs
    const String backArrowSvg = '''
<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>
''';

    const String cameraBigSvg = '''
<svg width="40" height="36" viewBox="0 0 40 36" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M20 29C22.5 29 24.625 28.125 26.375 26.375C28.125 24.625 29 22.5 29 20C29 17.5 28.125 15.375 26.375 13.625C24.625 11.875 22.5 11 20 11C17.5 11 15.375 11.875 13.625 13.625C11.875 15.375 11 17.5 11 20C11 22.5 11.875 24.625 13.625 26.375C15.375 28.125 17.5 29 20 29ZM20 25C18.6 25 17.4167 24.5167 16.45 23.55C15.4833 22.5833 15 21.4 15 20C15 18.6 15.4833 17.4167 16.45 16.45C17.4167 15.4833 18.6 15 20 15C21.4 15 22.5833 15.4833 23.55 16.45C24.5167 17.4167 25 18.6 25 20C25 21.4 24.5167 22.5833 23.55 23.55C22.5833 24.5167 21.4 25 20 25ZM4 36C2.9 36 1.95833 35.6083 1.175 34.825C0.391667 34.0417 0 33.1 0 32V8C0 6.9 0.391667 5.95833 1.175 5.175C1.95833 4.39167 2.9 4 4 4H10.3L14 0H26L29.7 4H36C37.1 4 38.0417 4.39167 38.825 5.175C39.6083 5.95833 40 6.9 40 8V32C40 33.1 39.6083 34.0417 38.825 34.825C38.0417 35.6083 37.1 36 36 36H4Z" fill="#C8A882"/>
</svg>
''';

    const String cameraSmallSvg = '''
<svg width="20" height="18" viewBox="0 0 20 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M10 14.5C11.25 14.5 12.3125 14.0625 13.1875 13.1875C14.0625 12.3125 14.5 11.25 14.5 10C14.5 8.75 14.0625 7.6875 13.1875 6.8125C12.3125 5.9375 11.25 5.5 10 5.5C8.75 5.5 7.6875 5.9375 6.8125 6.8125C5.9375 7.6875 5.5 8.75 5.5 10C5.5 11.25 5.9375 12.3125 6.8125 13.1875C7.6875 14.0625 8.75 14.5 10 14.5ZM10 12.5C9.3 12.5 8.70833 12.2583 8.225 11.775C7.74167 11.2917 7.5 10.7 7.5 10C7.5 9.3 7.74167 8.70833 8.225 8.225C8.70833 7.74167 9.3 7.5 10 7.5C10.7 7.5 11.2917 7.74167 11.775 8.225C12.2583 8.70833 12.5 9.3 12.5 10C12.5 10.7 12.2583 11.2917 11.775 11.775C11.2917 12.2583 10.7 12.5 10 12.5ZM2 18C1.45 18 0.979167 17.8042 0.5875 17.4125C0.195833 17.0208 0 16.55 0 16V4C0 3.45 0.195833 2.97917 0.5875 2.5875C0.979167 2.19583 1.45 2 2 2H5.15L7 0H13L14.85 2H18C18.55 2 19.0208 2.19583 19.4125 2.5875C19.8042 2.97917 20 3.45 20 4V16C20 16.55 19.8042 17.0208 19.4125 17.4125C19.0208 17.8042 18.55 18 18 18H2Z" fill="#C8A882"/>
</svg>
''';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0E6),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Profile / Header section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundImage: AssetImage('assets/images/image_3.png'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jai Shree Ram 🙏',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF2E2A36),
                              ),
                            ),
                            Text(
                              'Good Morning, Shiv 🌟',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _iconHeaderBtn(Icons.mail_outline_rounded),
                      const SizedBox(width: 8),
                      _iconHeaderBtn(Icons.notifications_none_rounded, hasDot: true),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Action/Title Row: Go Back + Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                          ),
                          child: Center(
                            child: SvgPicture.string(
                              backArrowSvg,
                              width: 15,
                              height: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Upload God Image',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Upload photo white box
                // width: 353; height: 260; border-radius: 24px; padding: 16px;
                Center(
                  child: Container(
                    width: 353,
                    height: 260,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 321,
                      height: 228,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: CustomPaint(
                        painter: DashedBorderPainter(
                          color: const Color(0xFFC8A882).withValues(alpha: 0.6),
                          borderRadius: 24,
                          strokeWidth: 2.0,
                          dashWidth: 6.0,
                          dashGap: 4.0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _selectedImage != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                    // Remove/Change photo button overlay
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImage = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // SVG logo inside white box
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFF0E6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: SvgPicture.string(
                                            cameraBigSvg,
                                            width: 40,
                                            height: 36,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Upload God Photo',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2E2A36),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'JPG, PNG — Max 10MB',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Browse Gallery button
                                      GestureDetector(
                                        onTap: () => _pickImage(ImageSource.gallery),
                                        child: Container(
                                          width: 141,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
                                            ),
                                            borderRadius: BorderRadius.circular(9999),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF6600).withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                                              child: Text(
                                                'Browse Gallery',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. "OR" Divider section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.15),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.15),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Take Photo with Camera Button
                // width: 353; height: 54; border-radius: 12px; border-width: 1px;
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      width: 353,
                      height: 54,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEFE6DB), width: 1.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.string(
                            cameraSmallSvg,
                            width: 20,
                            height: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Take Photo with Camera',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 6. Choose from Gallery Button
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      width: 353,
                      height: 54,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEFE6DB), width: 1.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            color: Color(0xFFC8A882),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Choose from Gallery',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 7. Photo Guidelines Box
                // width: 350; height: 159; border-radius: 20px; gap: 12px; border-width: 1px; padding: 27, 20, 28, 20
                Center(
                  child: Container(
                    width: 350,
                    height: 159,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.fromLTRB(20, 27, 20, 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6EE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEFE6DB), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photo Guidelines',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E2A36),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _guidelineItem('Clear front-facing image'),
                              _guidelineItem('Good lighting'),
                              _guidelineItem('No offensive content'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 8. Continue Button (at the bottom)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      if (_selectedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFFF5500),
                            content: Text(
                              'Please select or take a photo first!',
                              style: GoogleFonts.outfit(color: Colors.white),
                            ),
                          ),
                        );
                        return;
                      }
                      _showDetailsDialog();
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9933), Color(0xFFFF6600)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6600).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _guidelineItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: Color(0xFFC8A882), size: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _iconHeaderBtn(IconData icon, {bool hasDot = false}) {
    return Stack(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEFE6DB)),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2E2A36)),
        ),
        if (hasDot)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B42),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// Dashed border custom painter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.borderRadius = 24.0,
    this.dashWidth = 6.0,
    this.dashGap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, (distance + dashWidth).clamp(0.0, metric.length)),
          Offset.zero,
        );
        distance += dashWidth + dashGap;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}

class CustomJapDetails {
  final String imagePath;
  final String name;
  final String mantra;
  final int target;

  CustomJapDetails({
    required this.imagePath,
    required this.name,
    required this.mantra,
    required this.target,
  });
}
