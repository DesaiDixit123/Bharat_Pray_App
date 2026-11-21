import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class YatraDashboardScreen extends StatefulWidget {
  const YatraDashboardScreen({super.key});

  @override
  State<YatraDashboardScreen> createState() => _YatraDashboardScreenState();
}

class _YatraDashboardScreenState extends State<YatraDashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _dailyGraph = [];
  List<Map<String, dynamic>> _yatras = [];

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
        throw Exception('Please login to view your Yatra Dashboard.');
      }
      final data = await ApiService.getYatraDashboard(token);
      if (mounted) {
        setState(() {
          _summary = data['summary'] is Map
              ? Map<String, dynamic>.from(data['summary'] as Map)
              : {};
          _dailyGraph = (data['dailyGraph'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _yatras = (data['yatras'] as List? ?? [])
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
    final totalYatras = (_summary['totalYatras'] as num?)?.toInt() ?? 0;
    final completedYatras = (_summary['completedYatras'] as num?)?.toInt() ?? 0;
    final activeYatras = (_summary['activeYatras'] as num?)?.toInt() ?? 0;
    final templesVisited = (_summary['templesVisited'] as num?)?.toInt() ?? 0;

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
          'Yatra Dashboard',
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
                      Text('Unable to load Yatra Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.85,
                        children: [
                          _kpiCard('Total Yatras', '$totalYatras', Icons.explore_rounded, const Color(0xFFFF7700)),
                          _kpiCard('Completed', '$completedYatras', Icons.verified_rounded, const Color(0xFF2E7D32)),
                          _kpiCard('In Progress', '$activeYatras', Icons.directions_walk_rounded, const Color(0xFF1565C0)),
                          _kpiCard('Temples', '$templesVisited', Icons.temple_hindu_rounded, const Color(0xFF8E24AA)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Yatra Activity Graph
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
                                  'Yatra Activity (Last 7 Days)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2E2A36),
                                  ),
                                ),
                                const Icon(Icons.bar_chart_rounded, color: Color(0xFF2E7D32), size: 20),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildBarChart(_dailyGraph),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Your Yatra Records',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_yatras.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFEFE6DB)),
                          ),
                          child: Center(
                            child: Text(
                              'No Yatras recorded yet. Start a sacred Yatra or join a Sangha group! 🚩',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF7B7066)),
                            ),
                          ),
                        )
                      else
                        ..._yatras.map((y) {
                          final title = y['title']?.toString() ?? 'Sacred Yatra';
                          final type = y['type']?.toString() ?? 'Yatra';
                          final status = y['status']?.toString() ?? 'Active';
                          final displayDate = y['displayDate']?.toString() ?? '';
                          final temples = (y['templesVisited'] as num?)?.toInt() ?? 0;
                          final isDone = status.toLowerCase() == 'completed';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEFE6DB)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: (isDone ? const Color(0xFF2E7D32) : const Color(0xFFFF7700))
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isDone ? Icons.verified_rounded : Icons.explore_rounded,
                                    color: isDone ? const Color(0xFF2E7D32) : const Color(0xFFFF7700),
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
                                        style: GoogleFonts.outfit(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2E2A36),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$type • $displayDate${temples > 0 ? ' • $temples Temples' : ''}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          color: const Color(0xFF8A7E72),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isDone ? const Color(0xFF2E7D32) : const Color(0xFFFF7700))
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDone ? const Color(0xFF2E7D32) : const Color(0xFFFF7700),
                                    ),
                                  ),
                                ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE6DB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: const Color(0xFF8A7E72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text('No activity yet', style: GoogleFonts.outfit(color: Colors.grey)),
        ),
      );
    }

    final maxVal = math.max(
      1,
      data.map((e) => (e['count'] as num?)?.toInt() ?? 0).fold<int>(0, math.max),
    );

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
                Text(
                  cnt > 0 ? '$cnt' : '',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 22,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: cnt > 0
                        ? const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                          )
                        : null,
                    color: cnt > 0 ? null : const Color(0xFFF1E8DF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B7066),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
