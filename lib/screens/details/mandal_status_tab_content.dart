import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mandal_registration_screen.dart';
import 'mandal_profile_screen.dart';
import '../../services/utsav_service.dart';

class MandalStatusTabContent extends StatefulWidget {
  final bool isStandalone;
  const MandalStatusTabContent({super.key, this.isStandalone = false});

  @override
  State<MandalStatusTabContent> createState() => _MandalStatusTabContentState();
}

class _MandalStatusTabContentState extends State<MandalStatusTabContent> {
  Map<String, dynamic>? _registration;
  bool _isLoading = true;
  Timer? _statusPollTimer;
  bool _dialogShownForDeleted = false;

  @override
  void initState() {
    super.initState();
    _loadRegistration();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) return;
      final currentStatus = _registration?['status']?.toString().toLowerCase();
      if (_registration != null && currentStatus != 'approved') {
        final reg = await UtsavService.getMyMandalRegistration();
        if (mounted && reg != null) {
          final newStatus = reg['status']?.toString();
          if (newStatus != _registration?['status']) {
            setState(() {
              _registration = reg;
            });
            if (newStatus?.toLowerCase() == 'deleted' && !_dialogShownForDeleted) {
              _dialogShownForDeleted = true;
              _showAccountDeletedDialog(context, reg);
            }
          }
        }
      }
    });
  }

  Future<void> _loadRegistration() async {
    setState(() => _isLoading = true);
    final reg = await UtsavService.getMyMandalRegistration();
    if (mounted) {
      setState(() {
        _registration = reg;
        _isLoading = false;
      });
      if (reg != null && reg['status']?.toString().toLowerCase() == 'deleted' && !_dialogShownForDeleted) {
        _dialogShownForDeleted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showAccountDeletedDialog(context, reg);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7700)),
      );
    } else if (_registration == null) {
      content = _buildNoRegistrationState();
    } else {
      final status = (_registration!['status'] ?? 'Pending').toString();
      content = RefreshIndicator(
        onRefresh: _loadRegistration,
        color: const Color(0xFFFF7700),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Image Illustration
              _buildStatusIllustration(status),
              const SizedBox(height: 28),

              // 2. Status Title
              _buildStatusTitle(status),
              const SizedBox(height: 12),

              // 3. Status Description
              _buildStatusDescription(status),
              const SizedBox(height: 24),

              // 4. Status specific details
              if (status.toLowerCase() == 'rejected') ...[
                _buildRejectionReasonBox(),
                const SizedBox(height: 28),
                _buildResubmitButton(),
              ] else if (status.toLowerCase() == 'deleted') ...[
                _buildDeletedReasonBox(),
                const SizedBox(height: 28),
                _buildRegisterAgainButton(),
              ] else if (status.toLowerCase() == 'approved') ...[
                _buildApprovedDetailsBox(),
              ] else ...[
                _buildPendingDetailsBox(),
              ],
            ],
          ),
        ),
      );
    }

    if (widget.isStandalone) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFE8D6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          leading: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF8E5A2A)),
                ),
              ),
            ),
          ),
          title: Text(
            'Registration Status',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E2A36),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(child: content),
      );
    }

    return content;
  }

  // ── Empty State: Not Registered Yet ────────────────────────────────────────

  Widget _buildNoRegistrationState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28.0, 20.0, 28.0, 120.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAD8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF7700).withValues(alpha: 0.25), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7700).withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.temple_hindu_rounded,
                color: Color(0xFFFF7700),
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Mandal Registered Yet",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Register your mandal to participate in Utsav Mahotsav competitions, broadcast live darshans, post festive media, and compete on the leaderboard.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.app_registration_rounded),
                label: Text(
                  'Register Your Mandal',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final openFestival = await UtsavService.getUpcomingRegistrationFestivalName();
                  if (mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MandalRegistrationScreen(
                          initialFestival: openFestival,
                        ),
                      ),
                    );
                    _loadRegistration();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status Visuals ─────────────────────────────────────────────────────────

  Widget _buildStatusIllustration(String status) {
    final logo = _registration?['logo']?.toString();
    final bool hasLogo = logo != null && logo.isNotEmpty && File(logo).existsSync();

    final Color statusColor = status.toLowerCase() == 'approved'
        ? const Color(0xFF27AE60)
        : (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'deleted')
            ? const Color(0xFFD32F2F)
            : const Color(0xFFFF7700);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: hasLogo
                  ? Image.file(
                      File(logo),
                      fit: BoxFit.cover,
                      width: 140,
                      height: 140,
                    )
                  : Container(
                      color: const Color(0xFFFFF1E5),
                      child: Center(
                        child: Icon(
                          status.toLowerCase() == 'approved'
                              ? Icons.verified_rounded
                              : (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'deleted')
                                  ? Icons.cancel_rounded
                                  : Icons.hourglass_top_rounded,
                          size: 60,
                          color: statusColor,
                        ),
                      ),
                    ),
            ),
          ),
          if (hasLogo)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status.toLowerCase() == 'approved'
                      ? Icons.check_circle_rounded
                      : (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'deleted')
                          ? Icons.cancel_rounded
                          : Icons.pending_rounded,
                  color: statusColor,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTitle(String status) {
    String text;
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        text = "Registration Approved! 🎉";
        color = const Color(0xFF27AE60);
        break;
      case 'rejected':
        text = "Registration Rejected";
        color = Colors.red.shade700;
        break;
      case 'deleted':
        text = "Mandal Account Deleted ❌";
        color = Colors.red.shade700;
        break;
      case 'pending':
      default:
        text = "Registration Pending";
        color = const Color(0xFFE67E22);
        break;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildStatusDescription(String status) {
    String text;
    final mandalName = (_registration?['mandalName'] ?? 'Your mandal').toString();
    switch (status.toLowerCase()) {
      case 'approved':
        text = "Congratulations! Your registration for '$mandalName' has been approved. You can now Go Live, post darshans, and lead your mandal.";
        break;
      case 'rejected':
        text = "Your mandal registration for '$mandalName' could not be approved at this time. Please see the rejection reason below and resubmit.";
        break;
      case 'deleted':
        text = "Your Mandal account '$mandalName' has been deleted by Bharat Pray Admin. Please review the reason below and submit a fresh registration.";
        break;
      case 'pending':
      default:
        text = "Your mandal registration for '$mandalName' has been submitted successfully and is currently under review by the admin team.";
        break;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: const Color(0xFF2E2A36).withValues(alpha: 0.7),
        height: 1.45,
      ),
    );
  }

  Widget _buildPendingDetailsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6DB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Submitted Mandal Details",
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const Divider(color: Color(0xFFEFE6DB), height: 24),
          _buildInfoRow("Mandal Name", (_registration?['mandalName'] ?? '-').toString()),
          _buildInfoRow("Leader Name", (_registration?['leaderName'] ?? '-').toString()),
          _buildInfoRow("Festival", (_registration?['festival'] ?? '-').toString()),
          _buildInfoRow("Registration ID", (_registration?['registrationId'] ?? '-').toString()),
          _buildInfoRow("Current Status", "Under Review ⏳", valColor: const Color(0xFFE67E22)),
        ],
      ),
    );
  }

  Widget _buildApprovedDetailsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6DB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7700).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Registered Mandal Info",
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E2A36),
            ),
          ),
          const Divider(color: Color(0xFFEFE6DB), height: 24),
          _buildInfoRow("Mandal Name", (_registration?['mandalName'] ?? '-').toString()),
          _buildInfoRow("Leader Name", (_registration?['leaderName'] ?? '-').toString()),
          _buildInfoRow("Festival", (_registration?['festival'] ?? '-').toString()),
          _buildInfoRow("Status", "Live & Approved", valColor: const Color(0xFF27AE60)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7700),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: Text(
                "Go to Mandal Profile",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MandalProfileScreen(
                      mandalName: (_registration?['mandalName'] ?? 'Mandal').toString(),
                      isOwnProfile: true,
                      avatarUrl: (_registration?['logo'] ?? _registration?['logoUrl'])?.toString(),
                      coverUrl: (_registration?['cover'] ?? _registration?['coverUrl'])?.toString(),
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

  Widget _buildRejectionReasonBox() {
    final reason = (_registration?['rejectionReason'] ?? '').toString();
    final displayReason = reason.isNotEmpty
        ? reason
        : "Document verification could not be completed. Please re-upload clear photos and valid address details.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                "Reason for Rejection",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayReason,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7700),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          final targetFest = (_registration?['festival'] ?? _registration?['festivalName'])?.toString() ??
              await UtsavService.getUpcomingRegistrationFestivalName();
          // Clear previous rejected registration so user starts fresh with blank form
          await UtsavService.clearMyMandalRegistration();
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MandalRegistrationScreen(
                  initialFestival: targetFest,
                ),
              ),
            );
            _loadRegistration();
          }
        },
        child: Text(
          'Re-submit Registration',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedReasonBox() {
    final reason = (_registration?['deletionReason'] ?? _registration?['rejectionReason'] ?? '').toString();
    final displayReason = reason.isNotEmpty
        ? reason
        : "Your Mandal account has been removed by the Bharat Pray administrator.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                "Reason for Deletion",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayReason,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterAgainButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7700),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          final targetFest = (_registration?['festival'] ?? _registration?['festivalName'])?.toString() ??
              await UtsavService.getUpcomingRegistrationFestivalName();
          // Clear deleted registration so user can register directly fresh
          await UtsavService.clearMyMandalRegistration();
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MandalRegistrationScreen(
                  initialFestival: targetFest,
                ),
              ),
            );
            _loadRegistration();
          }
        },
        child: Text(
          'Register Again',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAccountDeletedDialog(BuildContext context, Map<String, dynamic> reg) {
    final mandalName = (reg['mandalName'] ?? 'Your Mandal').toString();
    final reason = (reg['deletionReason'] ?? reg['rejectionReason'] ?? 'Account deleted by Bharat Pray Admin').toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade600, size: 34),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Mandal Account Deleted ❌",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Your Mandal account '$mandalName' has been deleted by Bharat Pray Admin.",
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.red.shade800, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Reason for Deletion:",
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "You can now register your Mandal again.",
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await UtsavService.clearMyMandalRegistration();
                      _loadRegistration();
                    },
                    child: Text("Dismiss", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7700),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final targetFest = (_registration?['festival'] ?? _registration?['festivalName'])?.toString() ??
                          await UtsavService.getUpcomingRegistrationFestivalName();
                      await UtsavService.clearMyMandalRegistration();
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MandalRegistrationScreen(initialFestival: targetFest),
                          ),
                        ).then((_) => _loadRegistration());
                      }
                    },
                    child: Text("Register Again", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String val, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
            ),
          ),
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valColor ?? const Color(0xFF2E2A36),
            ),
          ),
        ],
      ),
    );
  }
}
