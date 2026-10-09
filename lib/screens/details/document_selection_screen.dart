import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentSelectionScreen extends StatefulWidget {
  final Function(String docName, String? docPath, String docSize) onDocumentSelected;

  const DocumentSelectionScreen({
    super.key,
    required this.onDocumentSelected,
  });

  @override
  State<DocumentSelectionScreen> createState() => _DocumentSelectionScreenState();
}

class _DocumentSelectionScreenState extends State<DocumentSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Temple & Yatra Passes',
    'Sacred Scriptures',
    'Darshan Slips',
    'Device Storage',
  ];

  // Device files discovered
  final List<Map<String, dynamic>> _deviceFiles = [];
  bool _isScanningDevice = true;

  // Preset Authentic Devotional & Temple Documents
  final List<Map<String, dynamic>> _predefinedDocs = [
    {
      'name': 'Somnath_Jyotirlinga_VIP_Darshan_Pass_2026.pdf',
      'category': 'Temple & Yatra Passes',
      'size': '520 KB',
      'date': 'Today, 2:40 PM',
      'type': 'PDF',
      'isPass': true,
      'description': 'Official Somnath Trust Darshan pass barcode & timing slip.',
    },
    {
      'name': 'Kedarnath_Dham_Biometric_Yatra_Registration.pdf',
      'category': 'Temple & Yatra Passes',
      'size': '820 KB',
      'date': 'Yesterday',
      'type': 'PDF',
      'isPass': true,
      'description': 'Uttarakhand Char Dham biometric verification certificate.',
    },
    {
      'name': 'Shri_Ramcharitmanas_Sundarkand_Path.pdf',
      'category': 'Sacred Scriptures',
      'size': '3.4 MB',
      'date': '02 Oct 2026',
      'type': 'PDF',
      'isPass': false,
      'description': 'Complete Sundarkand Chaupai, Doha & Aarti with Gujarati/Hindi translation.',
    },
    {
      'name': 'Shri_Hanuman_Chalisa_With_Bhavarth.pdf',
      'category': 'Sacred Scriptures',
      'size': '1.2 MB',
      'date': '28 Sep 2026',
      'type': 'PDF',
      'isPass': false,
      'description': 'Sacred 40 verses of Goswami Tulsidas with devotional meaning.',
    },
    {
      'name': 'Kashi_Vishwanath_Sugam_Darshan_Receipt.pdf',
      'category': 'Darshan Slips',
      'size': '310 KB',
      'date': 'Today, 11:15 AM',
      'type': 'PDF',
      'isPass': true,
      'description': 'Kashi Vishwanath Corridor priority entry confirmation token.',
    },
    {
      'name': 'Shri_Bhagavad_Gita_All_18_Adhyay_Summary.pdf',
      'category': 'Sacred Scriptures',
      'size': '8.5 MB',
      'date': '24 Sep 2026',
      'type': 'PDF',
      'isPass': false,
      'description': 'Lord Krishna’s sacred dialogue on Dharma, Karma & Bhakti Yoga.',
    },
    {
      'name': 'Ayodhya_Ram_Mandir_Aarti_Darshan_Booking.pdf',
      'category': 'Darshan Slips',
      'size': '440 KB',
      'date': '20 Sep 2026',
      'type': 'PDF',
      'isPass': true,
      'description': 'Shri Ram Janmabhoomi Teerth Kshetra Aarti invitation slot.',
    },
    {
      'name': 'Mahamrityunjaya_Mantra_Vidhi_&_Path.pdf',
      'category': 'Sacred Scriptures',
      'size': '2.1 MB',
      'date': '18 Sep 2026',
      'type': 'PDF',
      'isPass': false,
      'description': 'Lord Shiva auspicious healing mantra chanting guide.',
    },
    {
      'name': 'Holy_Yatra_Sangha_Route_Guide_2026.pdf',
      'category': 'Temple & Yatra Passes',
      'size': '840 KB',
      'date': '15 Sep 2026',
      'type': 'PDF',
      'isPass': true,
      'description': 'Complete holy walking route, dharamsala stops & water stations.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scanDeviceForDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanDeviceForDocuments() async {
    try {
      final List<String> pathsToSearch = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
      ];

      for (final p in pathsToSearch) {
        final dir = Directory(p);
        if (dir.existsSync()) {
          final entities = dir.listSync(recursive: false);
          for (final entity in entities) {
            if (entity is File) {
              final lower = entity.path.toLowerCase();
              if (lower.endsWith('.pdf') || lower.endsWith('.doc') || lower.endsWith('.docx') || lower.endsWith('.txt')) {
                final fName = entity.path.split(Platform.pathSeparator).last;
                final stat = entity.statSync();
                final sizeKb = (stat.size / 1024).toStringAsFixed(0);
                final sizeStr = stat.size > (1024 * 1024)
                    ? '${(stat.size / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : '$sizeKb KB';

                _deviceFiles.add({
                  'name': fName,
                  'category': 'Device Storage',
                  'size': sizeStr,
                  'date': 'Device File',
                  'type': fName.split('.').last.toUpperCase(),
                  'path': entity.path,
                  'isPass': false,
                  'description': 'Stored in ${dir.path.split("/").last}',
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Device document scan exception: $e");
    } finally {
      if (mounted) {
        setState(() => _isScanningDevice = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDocs {
    List<Map<String, dynamic>> combined = [
      ..._deviceFiles,
      ..._predefinedDocs,
    ];

    if (_selectedCategory != 'All') {
      combined = combined.where((d) => d['category'] == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      combined = combined.where((d) {
        final name = (d['name'] ?? '').toString().toLowerCase();
        final desc = (d['description'] ?? '').toString().toLowerCase();
        final cat = (d['category'] ?? '').toString().toLowerCase();
        return name.contains(q) || desc.contains(q) || cat.contains(q);
      }).toList();
    }

    return combined;
  }

  void _selectDocument(Map<String, dynamic> doc) {
    final name = doc['name']?.toString() ?? 'Document.pdf';
    final path = doc['path']?.toString();
    final size = doc['size']?.toString() ?? 'Unknown';

    widget.onDocumentSelected(name, path, size);
    Navigator.pop(context);
  }

  void _showAddCustomDocDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFBF6EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.note_add_rounded, color: Color(0xFFFF7700)),
            const SizedBox(width: 8),
            Text(
              "Add Document",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter custom document or pass name:", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "e.g. Mahakal_Darshan_Pass.pdf",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8D2B8))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF7700), width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7700),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final n = nameController.text.trim();
              if (n.isNotEmpty) {
                final fullName = n.endsWith('.pdf') ? n : '$n.pdf';
                Navigator.pop(ctx);
                _selectDocument({
                  'name': fullName,
                  'size': '450 KB',
                });
              }
            },
            child: Text("Send Document", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filteredDocs;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFBF6EF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Document",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
            Text(
              "PDFs, Temple Passes & Sacred Texts",
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Add Custom Document",
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFFF7700), size: 24),
            onPressed: _showAddCustomDocDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8D2B8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search documents, passes or scriptures...",
                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF7700), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF7700),
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF2E2A36),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFFF7700) : const Color(0xFFE8D2B8),
                    ),
                  ),
                  onSelected: (val) {
                    setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Documents List
          Expanded(
            child: docs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE8D2B8)),
                          ),
                          child: const Icon(Icons.description_outlined, size: 38, color: Color(0xFFFF7700)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No documents found",
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Try searching another keyword or upload custom doc.",
                          style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddCustomDocDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("Add Custom File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final doc = docs[idx];
                      final name = doc['name']?.toString() ?? 'Document.pdf';
                      final size = doc['size']?.toString() ?? '500 KB';
                      final desc = doc['description']?.toString() ?? '';
                      final isPass = doc['isPass'] == true;
                      final isDevice = doc['category'] == 'Device Storage';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEFE6DB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _selectDocument(doc),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // File Badge Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isPass
                                        ? const Color(0xFF0D9488).withValues(alpha: 0.12)
                                        : (isDevice ? const Color(0xFF8B5CF6).withValues(alpha: 0.12) : const Color(0xFFE11D48).withValues(alpha: 0.12)),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isPass
                                        ? Icons.confirmation_number_rounded
                                        : (isDevice ? Icons.folder_open_rounded : Icons.picture_as_pdf_rounded),
                                    color: isPass
                                        ? const Color(0xFF0D9488)
                                        : (isDevice ? const Color(0xFF8B5CF6) : const Color(0xFFE11D48)),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title & Description
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2E2A36),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFBF6EF),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFE8D2B8), width: 0.8),
                                            ),
                                            child: Text(
                                              doc['type'] ?? 'PDF',
                                              style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFFF7700)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            size,
                                            style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF7A757F)),
                                          ),
                                          if (doc['date'] != null) ...[
                                            Text(
                                              " • ${doc['date']}",
                                              style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF7A757F)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (desc.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          desc,
                                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Send Action Button
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Color(0xFFFF7700),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
