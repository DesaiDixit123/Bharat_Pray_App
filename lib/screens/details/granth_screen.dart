import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'granth_list_by_category_screen.dart';

class GranthScreen extends StatefulWidget {
  const GranthScreen({super.key});

  @override
  State<GranthScreen> createState() => _GranthScreenState();
}

class _GranthScreenState extends State<GranthScreen> {
  List<Map<String, dynamic>> _granthCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGranthCategories();
  }

  Future<void> _fetchGranthCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token'); 

      final List<dynamic> fetchedCategories = await ApiService.getGranthCategories(token: token); 
      final categories = fetchedCategories.map((apiCategory) {
        return {
          'id': apiCategory['_id'] as String?, 
          'title': apiCategory['name'] as String? ?? 'Unknown Category', 
          'name': apiCategory['name'] as String? ?? 'Unknown Category', 
          'description': apiCategory['description'] as String? ?? '', 
          'count': 0, 
          'image': null, 
        };
      }).toList();
      setState(() {
        _granthCategories = List<Map<String, dynamic>>.from(categories);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load Granth categories: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2E2A36),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Granth',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false, // This is usually handled by Scaffold's body if it's a ListView
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchGranthCategories,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Text(
                        'Select Granth Category',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose a category to explore sacred texts',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.58),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._granthCategories.map((category) {
                        return _CategoryCard(category: category, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => GranthListByCategoryScreen(category: category)));
                        });
                      }),
                    ],
                  ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  final Map<String, dynamic> category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3E4D6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 78,
                  width: 102,
                  child: Image.network( // Changed to Image.network
                    ApiService.resolveImageUrl(category['image'] as String?), // Use ApiService.resolveImageUrl
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF8F4D18),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category['title'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category['count']} Granths',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 36,
                width: 36,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFFF7700),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
