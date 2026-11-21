import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class GranthDashboardScreen extends StatefulWidget {
  const GranthDashboardScreen({super.key});

  @override
  State<GranthDashboardScreen> createState() => _GranthDashboardScreenState();
}

class _GranthDashboardScreenState extends State<GranthDashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _dailyGraph = [];
  List<Map<String, dynamic>> _dateRecords = [];

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
        throw Exception('Please login to view your Granth Dashboard.');
      }
      final data = await ApiService.getGranthDashboard(token);
      if (mounted) {
        setState(() {
          _summary = data['summary'] is Map ? Map<String, dynamic>.from(data['summary'] as Map) : {};
          _dailyGraph = (data['dailyGraph'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _dateRecords = (data['dateWiseRecords'] as List? ?? [])
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

  void _showDateSheet(Map<String, dynamic> rec) {
    final displayDate = rec['displayDate']?.toString() ?? rec['date']?.toString() ?? '';
    final granths = (rec['granths'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF6EF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFD9C9B8), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Text(displayDate, style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF2E2A36))),
            Text('${granths.length} ${granths.length == 1 ? 'Granth' : 'Granths'} Opened', style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF7B7066))),
            const SizedBox(height: 14),
            ...granths.map((g) {
              final title = g['title']?.toString() ?? 'Sacred Granth';
              final opens = (g['openCount'] as num?)?.toInt() ?? 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEFE6DB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Color(0xFFFF7700)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title, style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF2E2A36))),
                    ),
                    Text('$opens×', style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFFFF7700))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUnique = (_summary['totalUnique'] as num?)?.toInt() ?? 0;
    final todayOpened = (_summary['todayOpened'] as num?)?.toInt() ?? 0;
    final activeDays = (_summary['activeDays'] as num?)?.toInt() ?? 0;
    final totalOpens = (_summary['totalOpens'] as num?)?.toInt() ?? 0;

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
          'Granth Dashboard',
          style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: const Color(0xFF2E2A36)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7700)))
          : _error != null
              ? Center(
                  child: ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7700), foregroundColor: Colors.white),
                    child: const Text('Retry'),
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
                          _kpiCard('Unique Granths', '$totalUnique', Icons.menu_book_rounded, const Color(0xFFFF7700)),
                          _kpiCard('Today Opened', '$todayOpened', Icons.wb_sunny_rounded, const Color(0xFF2E7D32)),
                          _kpiCard('Active Days', '$activeDays', Icons.calendar_month_rounded, const Color(0xFF1565C0)),
                          _kpiCard('Total Opens', '$totalOpens', Icons.auto_stories_rounded, const Color(0xFF8E24AA)),
                        ],
                      ),
                      const SizedBox(height: 18),

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
                                Text('Daily Granth Graph (Last 7 Days)', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF2E2A36))),
                                const Icon(Icons.bar_chart_rounded, color: Color(0xFF8E24AA), size: 20),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildBarChart(_dailyGraph),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text('Date-wise Granth Records', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF2E2A36))),
                      const SizedBox(height: 4),
                      Text('Tap any date to see which Granths you opened', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8A7E72))),
                      const SizedBox(height: 12),

                      if (_dateRecords.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFEFE6DB)),
                          ),
                          child: Center(
                            child: Text(
                              'No Granths opened yet. Open any Sacred Granth to track your daily reading! 📖',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF7B7066)),
                            ),
                          ),
                        )
                      else
                        ..._dateRecords.map((rec) {
                          final displayDate = rec['displayDate']?.toString() ?? rec['date']?.toString() ?? '';
                          final cnt = (rec['count'] as num?)?.toInt() ?? 0;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showDateSheet(rec),
                            child: Container(
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
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.menu_book_rounded, color: Color(0xFF8E24AA)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(displayDate, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF2E2A36))),
                                        Text('Tap to view opened Granths', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8A7E72))),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8E24AA).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$cnt ${cnt == 1 ? 'Granth' : 'Granths'}', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF8E24AA))),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5A89B)),
                                ],
                              ),
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
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF2E2A36))),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF8A7E72))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return SizedBox(height: 110, child: Center(child: Text('No reading data yet', style: GoogleFonts.outfit(color: Colors.grey))));
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
                Text(cnt > 0 ? '$cnt' : '', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF8E24AA))),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 22,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: cnt > 0
                        ? const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF8E24AA), Color(0xFFBA68C8)])
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
