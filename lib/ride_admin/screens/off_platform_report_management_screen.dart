import 'package:flutter/material.dart';

import '../../models/off_platform_ride_report_model.dart';
import '../services/off_platform_report_admin_service.dart';

class OffPlatformReportManagementScreen extends StatefulWidget {
  const OffPlatformReportManagementScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<OffPlatformReportManagementScreen> createState() =>
      _OffPlatformReportManagementScreenState();
}

class _OffPlatformReportManagementScreenState
    extends State<OffPlatformReportManagementScreen> {
  static const Color _yellow = Color(0xFFFFD600);
  static const Color _background = Color(0xFF0C0C0C);
  static const Color _card = Color(0xFF1B1B1B);

  final OffPlatformReportAdminService _service =
      OffPlatformReportAdminService();

  String _status = OffPlatformRideReportModel.pending;
  String? _busyReportId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Off-Platform Reports'),
        backgroundColor: _background,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          _header(),
          Expanded(
            child: StreamBuilder<List<OffPlatformRideReportModel>>(
              stream: _service.watchReports(status: _status),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _emptyState(
                    Icons.cloud_off_rounded,
                    'Could not load reports',
                    _cleanError(snapshot.error!),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _yellow),
                  );
                }

                final reports = snapshot.data!;
                if (reports.isEmpty) {
                  return _emptyState(
                    Icons.verified_user_outlined,
                    'No ${_title(_status)} reports',
                    'Reports will appear here when Riders submit them.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _reportCard(reports[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    const statuses = <String>[
      'all',
      OffPlatformRideReportModel.pending,
      OffPlatformRideReportModel.underReview,
      OffPlatformRideReportModel.verified,
      OffPlatformRideReportModel.rejected,
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.shield_outlined, color: _yellow),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Review evidence before taking Driver action',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'A Rider report never suspends a Driver automatically.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _status,
            dropdownColor: _card,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Report status',
              labelStyle: TextStyle(color: Colors.white60),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _yellow),
              ),
            ),
            items: statuses
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(_title(status)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _reportCard(OffPlatformRideReportModel report) {
    final bool isBusy = _busyReportId == report.reportId;
    final bool canReview = report.status == OffPlatformRideReportModel.pending ||
        report.status == OffPlatformRideReportModel.underReview;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(report.status).withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Ride ${_shortId(report.rideId)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusBadge(report.status),
            ],
          ),
          const SizedBox(height: 14),
          _row('Rider ID', report.riderId),
          _row('Driver ID', report.driverId),
          _row('Reported', _dateTime(report.createdAt)),
          _row('Fee waived', report.cancellationFeeWaived ? 'Yes' : 'No'),
          if ((report.riderNote ?? '').isNotEmpty)
            _row('Rider note', report.riderNote!),
          if ((report.adminNote ?? '').isNotEmpty)
            _row('Admin note', report.adminNote!),
          if ((report.adminAction ?? '').isNotEmpty)
            _row('Action', _title(report.adminAction!)),
          if (canReview) ...<Widget>[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy ? null : () => _openReview(report),
                icon: isBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(isBusy ? 'Saving...' : 'Review Report'),
                style: FilledButton.styleFrom(
                  backgroundColor: _yellow,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReview(OffPlatformRideReportModel report) async {
    if (report.status == OffPlatformRideReportModel.pending) {
      try {
        await _service.markUnderReview(
          reportId: report.reportId,
          adminId: widget.adminId,
        );
      } catch (error) {
        if (mounted) _message(_cleanError(error));
        return;
      }
    }
    if (!mounted) return;

    final TextEditingController noteController = TextEditingController();
    String action = OffPlatformRideReportModel.warning;

    final String? decision = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: const Text('Admin Review', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Required review note',
                    labelStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: action,
                  dropdownColor: const Color(0xFF222222),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Action if verified',
                    labelStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: OffPlatformRideReportModel.warning,
                      child: Text('Warning'),
                    ),
                    DropdownMenuItem(
                      value: OffPlatformRideReportModel.temporaryRestriction,
                      child: Text('Restrict ride requests for 24 hours'),
                    ),
                    DropdownMenuItem(
                      value: OffPlatformRideReportModel.suspension,
                      child: Text('Suspend Driver'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => action = value);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'reject'),
              child: const Text('Reject Report'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'verify:$action'),
              child: const Text('Verify & Apply'),
            ),
          ],
        ),
      ),
    );

    final String note = noteController.text.trim();
    noteController.dispose();
    if (decision == null) return;

    setState(() => _busyReportId = report.reportId);
    try {
      if (decision == 'reject') {
        await _service.rejectReport(
          reportId: report.reportId,
          adminId: widget.adminId,
          adminNote: note,
        );
      } else {
        await _service.verifyReport(
          reportId: report.reportId,
          adminId: widget.adminId,
          adminNote: note,
          action: decision.substring('verify:'.length),
        );
      }
      if (mounted) _message('Admin review saved successfully.', success: true);
    } catch (error) {
      if (mounted) _message(_cleanError(error));
    } finally {
      if (mounted) setState(() => _busyReportId = null);
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? 'Not available' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final Color color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _title(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case OffPlatformRideReportModel.verified:
        return Colors.greenAccent;
      case OffPlatformRideReportModel.rejected:
        return Colors.redAccent;
      case OffPlatformRideReportModel.underReview:
        return Colors.lightBlueAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  Widget _emptyState(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: Colors.white38, size: 56),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  void _message(String text, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? Colors.green : Colors.redAccent,
        content: Text(text),
      ),
    );
  }

  String _shortId(String value) {
    return value.length <= 10 ? value : '${value.substring(0, 10)}...';
  }

  String _dateTime(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }

  String _title(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '');
  }
}
