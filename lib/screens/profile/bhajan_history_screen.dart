import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class BhajanHistoryScreen extends StatefulWidget {
  const BhajanHistoryScreen({super.key});

  @override
  State<BhajanHistoryScreen> createState() => _BhajanHistoryScreenState();
}

class _BhajanHistoryScreenState extends State<BhajanHistoryScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _dailyGraph = [];
  List<Map<String, dynamic>> _bhajans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      if (token.isEmpty) {
        throw Exception('Please login to view your Bhajan Dashboard.');
      }
      final data = await ApiService.getUserBhajanListeningHistory(token);
      if (mounted) {
        setState(() {
          _summary = data['summary'] is Map
              ? Map<String, dynamic>.from(data['summary'] as Map)
              : {'totalUnique': (data['totalUnique'] as num?)?.toInt() ?? 0};
          _dailyGraph = (data['dailyGraph'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _bhajans = (data['bhajans'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUnique = (_summary['totalUnique'] as num?)?.toInt() ?? _bhajans.length;
    final todayListened = (_summary['todayListened'] as num?)?.toInt() ?? 0;
    final activeDays = (_summary['activeDays'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF2E2A36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bhajan Dashboard',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E2A36),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 42, color: Color(0xFFFF7700)),
                      const SizedBox(height: 8),
                      Text('Unable to load Bhajan Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700), foregroundColor: Colors.white),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF7700),
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      // 3 Summary KPI Cards
                      Row(
                        children: [
                          Expanded(child: _kpiCard('Unique Bhajans', '$totalUnique', Icons.music_note_rounded, const Color(0xFFFF7700))),
                          const SizedBox(width: 8),
                          Expanded(child: _kpiCard('Today', '$todayListened', Icons.headphones_rounded, const Color(0xFF2E7D32))),
                          const SizedBox(width: 8),
                          Expanded(child: _kpiCard('Active Days', '$activeDays', Icons.calendar_today_rounded, const Color(0xFF1565C0))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 7-Day Bhajan Listening Graph
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEFE6DB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Bhajan Graph (Last 7 Days)',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF2E2A36)),
                                ),
                                const Icon(Icons.bar_chart_rounded, color: Color(0xFFFF7700), size: 20),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildBarChart(_dailyGraph),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Unique Listened Bhajans ($totalUnique)',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF2E2A36)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Each Bhajan is counted once even if played multiple times',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8A7E72)),
                      ),
                      const SizedBox(height: 12),

                      if (_bhajans.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFEFE6DB)),
                          ),
                          child: Center(
                            child: Text(
                              'No Bhajans listened yet. Play a Bhajan to see your history here! 🎵',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF7B7066)),
                            ),
                          ),
                        )
                      else
                        ..._bhajans.map((b) {
                          final title = b['title']?.toString() ?? 'Devotional Bhajan';
                          final artist = b['artist']?.toString() ?? 'Bharat Pray';
                          final image = b['image']?.toString() ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEFE6DB)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    color: const Color(0xFFFFF4E6),
                                    child: image.startsWith('http')
                                        ? Image.network(image, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, color: Color(0xFFFF7700)))
                                        : const Icon(Icons.music_note_rounded, color: Color(0xFFFF7700)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF2E2A36)),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8A7E72)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.headphones_rounded, color: Color(0xFFFF7700), size: 20),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF2E2A36))),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF8A7E72))),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return SizedBox(height: 110, child: Center(child: Text('No listening data yet', style: GoogleFonts.outfit(color: Colors.grey))));
    }
    final maxVal = math.max(1, data.map((e) => (e['count'] as num?)?.toInt() ?? 0).fold<int>(0, math.max));

    return SizedBox(
      height: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final cnt = (d['count'] as num?)?.toInt() ?? 0;
          final label = d['label']?.toString() ?? '';
          final ratio = (cnt / maxVal).clamp(0.0, 1.0);
          final barHeight = cnt > 0 ? math.max(12.0, ratio * 88.0) : 6.0;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(cnt > 0 ? '$cnt' : '', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFFF7700))),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 22,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: cnt > 0
                        ? const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFF7700), Color(0xFFFFB74D)])
                        : null,
                    color: cnt > 0 ? null : const Color(0xFFF1E8DF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF7B7066))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
