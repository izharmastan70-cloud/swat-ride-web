import 'package:flutter/material.dart';

import '../../models/cargo_off_platform_report_model.dart';
import '../../services/cargo_off_platform_report_service.dart';

class CargoAdminOffPlatformReportsScreen extends StatelessWidget {
  const CargoAdminOffPlatformReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CargoOffPlatformReportService service =
        CargoOffPlatformReportService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Off-platform Reports'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<CargoOffPlatformReportModel>>(
        stream: service.watchAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load Cargo reports: '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<CargoOffPlatformReportModel> reports =
              snapshot.data ?? <CargoOffPlatformReportModel>[];

          if (reports.isEmpty) {
            return const Center(child: Text('No Cargo off-platform reports.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _reportCard(context, service, reports[index]);
            },
          );
        },
      ),
    );
  }

  Widget _reportCard(
    BuildContext context,
    CargoOffPlatformReportService service,
    CargoOffPlatformReportModel report,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        leading: Icon(_statusIcon(report.status)),
        title: Text(
          'Booking ${report.cargoBookingId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${report.status} • Driver ${report.driverId}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _infoRow('Report ID', report.reportId),
          _infoRow('Customer ID', report.customerId),
          _infoRow('Driver ID', report.driverId),
          _infoRow('Booking Type', report.bookingType ?? '-'),
          _infoRow('Reason', report.reason),
          _infoRow('Customer Note', report.customerNote ?? '-'),
          _infoRow(
            'Cancellation Fee',
            report.cancellationFeeWaived ? 'Waived' : 'Not waived',
          ),
          _infoRow(
            'Admin Action',
            report.adminAction ?? CargoOffPlatformReportModel.noAction,
          ),
          if (report.adminNote != null)
            _infoRow('Admin Note', report.adminNote!),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (report.status == CargoOffPlatformReportModel.pending)
                ElevatedButton(
                  onPressed: () async {
                    await _runAction(
                      context,
                      () => service.markUnderReview(reportId: report.reportId),
                      'Report marked under review.',
                    );
                  },
                  child: const Text('Under Review'),
                ),

              if (report.status != CargoOffPlatformReportModel.verified &&
                  report.status != CargoOffPlatformReportModel.rejected)
                ElevatedButton.icon(
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Verify'),
                  onPressed: () {
                    _verifyReport(context, service, report);
                  },
                ),

              if (report.status != CargoOffPlatformReportModel.verified &&
                  report.status != CargoOffPlatformReportModel.rejected)
                OutlinedButton(
                  onPressed: () {
                    _rejectReport(context, service, report);
                  },
                  child: const Text('Reject'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _verifyReport(
    BuildContext context,
    CargoOffPlatformReportService service,
    CargoOffPlatformReportModel report,
  ) async {
    String action = CargoOffPlatformReportModel.warning;

    final TextEditingController noteController = TextEditingController();

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Verify Report'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: action,
                    decoration: const InputDecoration(
                      labelText: 'Admin Action',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: CargoOffPlatformReportModel.noAction,
                        child: Text('No Action'),
                      ),
                      DropdownMenuItem(
                        value: CargoOffPlatformReportModel.warning,
                        child: Text('Warning'),
                      ),
                      DropdownMenuItem(
                        value: CargoOffPlatformReportModel.temporaryRestriction,
                        child: Text('Temporary Restriction'),
                      ),
                      DropdownMenuItem(
                        value: CargoOffPlatformReportModel.suspension,
                        child: Text('Suspension'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        action = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Admin Note'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, <String, dynamic>{
                      'action': action,
                      'note': noteController.text.trim(),
                    });
                  },
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();

    if (result == null || !context.mounted) {
      return;
    }

    await _runAction(
      context,
      () => service.verifyReport(
        reportId: report.reportId,
        adminAction: result['action'] as String,
        adminNote: (result['note'] as String).isEmpty
            ? null
            : result['note'] as String,
      ),
      'Cargo off-platform report verified.',
    );
  }

  Future<void> _rejectReport(
    BuildContext context,
    CargoOffPlatformReportService service,
    CargoOffPlatformReportModel report,
  ) async {
    final TextEditingController controller = TextEditingController();

    final String? note = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Report'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Admin Note'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (note == null || !context.mounted) {
      return;
    }

    await _runAction(
      context,
      () => service.rejectReport(
        reportId: report.reportId,
        adminNote: note.isEmpty ? null : note,
      ),
      'Cargo off-platform report rejected.',
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cargo report action failed: $error')),
      );
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case CargoOffPlatformReportModel.verified:
        return Icons.verified_outlined;

      case CargoOffPlatformReportModel.rejected:
        return Icons.cancel_outlined;

      case CargoOffPlatformReportModel.underReview:
        return Icons.manage_search_outlined;

      default:
        return Icons.report_outlined;
    }
  }
}
