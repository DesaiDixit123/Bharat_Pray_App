import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class JapDashboardScreen extends StatefulWidget {
  const JapDashboardScreen({super.key});

  @override
  State<JapDashboardScreen> createState() => _JapDashboardScreenState();
}

class _JapDashboardScreenState extends State<JapDashboardScreen> {
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
        throw Exception('Please login to view your Jap Dashboard.');
      }
      final data = await ApiService.getJapDashboard(token);
      if (mounted) {
        setState(() {
          _summary = data['summary'] is Map
              ? Map<String, dynamic>.from(data['summary'] as Map)
              : {};
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

  void _showDateBreakdownSheet(Map<String, dynamic> record) {
    final displayDate = record['displayDate']?.toString() ?? record['date']?.toString() ?? '';
    final totalChants = (record['totalChants'] as num?)?.toInt() ?? 0;
    final japs = (record['japs'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.72,
        ),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFD9C9B8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayDate,
                      style: GoogleFonts.outfit(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2E2A36),
                      ),
                    ),
                    Text(
                      '${japs.length} ${japs.length == 1 ? 'Jap' : 'Japs'} Chanted',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: const Color(0xFF7B7066),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7700),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$totalChants Chants',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: japs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final j = japs[idx];
                  final name = j['name']?.toString() ?? 'Sacred Jap';
                  final image = j['image']?.toString() ?? '';
                  final count = (j['count'] as num?)?.toInt() ?? 0;
                  final malas = (j['malas'] as num?)?.toInt() ?? 0;
                  final target = (j['targetCount'] as num?)?.toInt() ?? 108;

                  return Container(
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
                            width: 48,
                            height: 48,
                            color: const Color(0xFFFFF4E6),
                            child: image.startsWith('http')
                                ? Image.network(image, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.self_improvement_rounded, color: Color(0xFFFF7700)))
                                : (image.startsWith('assets/')
                                    ? Image.asset(image, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.self_improvement_rounded, color: Color(0xFFFF7700)))
                                    : const Icon(Icons.self_improvement_rounded, color: Color(0xFFFF7700))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E2A36),
                                ),
                              ),
                              Text(
                                'Target: $target • $malas ${malas == 1 ? 'Mala' : 'Malas'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF8A7E72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count×',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF7700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalChants = (_summary['totalChants'] as num?)?.toInt() ?? 0;
    final totalMalas = (_summary['totalMalas'] as num?)?.toInt() ?? 0;
    final todayChants = (_summary['todayChants'] as num?)?.toInt() ?? 0;
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
          'Jap Dashboard',
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
                      Text('Unable to load Jap Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                      // 4 Summary KPI Cards
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.85,
                        children: [
                          _kpiCard('Total Chants', '$totalChants', Icons.self_improvement_rounded, const Color(0xFFFF7700)),
                          _kpiCard('Total Malas', '$totalMalas', Icons.auto_awesome_rounded, const Color(0xFF8E24AA)),
                          _kpiCard("Today's Jap", '$todayChants', Icons.wb_sunny_rounded, const Color(0xFF2E7D32)),
                          _kpiCard('Active Days', '$activeDays', Icons.calendar_month_rounded, const Color(0xFF1565C0)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Daily 7-Day Jap Bar Graph
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
                                  'Daily Jap Graph (Last 7 Days)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2E2A36),
                                  ),
                                ),
                                const Icon(Icons.bar_chart_rounded, color: Color(0xFFFF7700), size: 20),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDailyBarChart(_dailyGraph),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date-wise Record List
                      Text(
                        'Date-wise Jap Records',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E2A36),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any date to see which Japs you chanted & how many times',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8A7E72)),
                      ),
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
                              'No Jap records yet. Start chanting to build your daily history! 📿',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF7B7066)),
                            ),
                          ),
                        )
                      else
                        ..._dateRecords.map((rec) {
                          final displayDate = rec['displayDate']?.toString() ?? rec['date']?.toString() ?? '';
                          final total = (rec['totalChants'] as num?)?.toInt() ?? 0;
                          final japsCount = (rec['japsCount'] as num?)?.toInt() ?? 0;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showDateBreakdownSheet(rec),
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
                                      color: const Color(0xFFFFF4E6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.event_note_rounded, color: Color(0xFFFF7700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayDate,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF2E2A36),
                                          ),
                                        ),
                                        Text(
                                          '$japsCount ${japsCount == 1 ? 'Jap' : 'Japs'} • Tap to view details',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: const Color(0xFF8A7E72),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$total Chants',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFF7700),
                                      ),
                                    ),
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

  Widget _buildDailyBarChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('No daily data yet', style: GoogleFonts.outfit(color: Colors.grey)),
        ),
      );
    }

    final maxVal = math.max(
      1,
      data.map((e) => (e['totalChants'] as num?)?.toInt() ?? 0).fold<int>(0, math.max),
    );

    return SizedBox(
      height: 155,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final chants = (d['totalChants'] as num?)?.toInt() ?? 0;
          final label = d['label']?.toString() ?? '';
          final ratio = (chants / maxVal).clamp(0.0, 1.0);
          final barHeight = chants > 0 ? math.max(12.0, ratio * 98.0) : 6.0;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  chants > 0 ? '$chants' : '',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF7700),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 22,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: chants > 0
                        ? const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFFFF7700), Color(0xFFFFB74D)],
                          )
                        : null,
                    color: chants > 0 ? null : const Color(0xFFF1E8DF),
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
