import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/student_ride_driver_application_model.dart';
import '../../services/student_ride_driver_application_service.dart';

class StudentRideAdminDriverApplicationsScreen extends StatefulWidget {
  const StudentRideAdminDriverApplicationsScreen({super.key});

  @override
  State<StudentRideAdminDriverApplicationsScreen> createState() =>
      _StudentRideAdminDriverApplicationsScreenState();
}

class _StudentRideAdminDriverApplicationsScreenState
    extends State<StudentRideAdminDriverApplicationsScreen> {
  final StudentRideDriverApplicationService _service =
      StudentRideDriverApplicationService();
  StudentRideDriverApplicationStatus? _statusFilter;
  String? _busyApplicationId;

  String get _adminId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Admin is not logged in.');
    }
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Applications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<StudentRideDriverApplicationStatus?>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Application status',
                prefixIcon: Icon(Icons.filter_alt_rounded),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All applications'),
                ),
                ...StudentRideDriverApplicationStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _statusFilter = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<StudentRideDriverApplicationModel>>(
              stream: _service.watchAllApplications(status: _statusFilter),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageView(
                    icon: Icons.error_outline_rounded,
                    message: 'Applications could not be loaded.\n${snapshot.error}',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final applications = snapshot.data!;
                if (applications.isEmpty) {
                  return const _MessageView(
                    icon: Icons.inbox_outlined,
                    message: 'No driver applications found.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: applications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final application = applications[index];
                      return _ApplicationCard(
                        application: application,
                        isBusy: _busyApplicationId == application.id,
                        onTap: () => _showDetails(application),
                        onAction: (action) =>
                            _handleAction(application, action),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    StudentRideDriverApplicationModel application,
    _ApplicationAction action,
  ) async {
    if (_busyApplicationId != null) return;
    String reason = '';
    String notes = '';

    if (action == _ApplicationAction.approve) {
      final confirmed = await _confirm(
        title: 'Approve driver?',
        message:
            '${application.fullName} will be approved for Student Ride service.',
        confirmLabel: 'Approve',
      );
      if (!confirmed) return;
    } else if (action == _ApplicationAction.reject) {
      final result = await _reasonDialog(
        title: 'Reject application',
        reasonLabel: 'Rejection reason',
        includeNotes: true,
      );
      if (result == null) return;
      reason = result.reason;
      notes = result.notes;
    } else if (action == _ApplicationAction.suspend) {
      final result = await _reasonDialog(
        title: 'Suspend Student Ride driver',
        reasonLabel: 'Suspension reason',
      );
      if (result == null) return;
      reason = result.reason;
      final confirmed = await _confirm(
        title: 'Confirm suspension',
        message:
            '${application.fullName} will lose Student Ride approval until reviewed again.',
        confirmLabel: 'Suspend',
      );
      if (!confirmed) return;
    }

    setState(() => _busyApplicationId = application.id);
    try {
      switch (action) {
        case _ApplicationAction.review:
          await _service.markUnderReview(
            applicationId: application.id,
            adminId: _adminId,
          );
          break;
        case _ApplicationAction.approve:
          await _service.approveApplication(
            applicationId: application.id,
            adminId: _adminId,
            adminNotes: notes,
          );
          break;
        case _ApplicationAction.reject:
          await _service.rejectApplication(
            applicationId: application.id,
            adminId: _adminId,
            reason: reason,
            adminNotes: notes,
          );
          break;
        case _ApplicationAction.suspend:
          await _service.suspendStudentRideDriver(
            applicationId: application.id,
            adminId: _adminId,
            reason: reason,
          );
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_successMessage(action))),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyApplicationId = null);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<_ReasonResult?> _reasonDialog({
    required String title,
    required String reasonLabel,
    bool includeNotes = false,
  }) async {
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    String? validationError;
    final result = await showDialog<_ReasonResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: reasonLabel,
                    errorText: validationError,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (includeNotes) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Admin notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.length < 3) {
                  setDialogState(
                    () => validationError = 'Enter at least 3 characters.',
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _ReasonResult(reason, notesController.text.trim()),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
    notesController.dispose();
    return result;
  }

  void _showDetails(StudentRideDriverApplicationModel application) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .88,
        minChildSize: .5,
        maxChildSize: .95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              application.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            _StatusChip(status: application.status),
            _DetailsSection(
              title: 'Personal information',
              values: {
                'Phone': application.phoneNumber,
                'CNIC': application.cnicNumber,
                'Date of birth': application.dateOfBirth,
                'Address': application.address,
                'City': application.city,
                'Emergency contact':
                    '${application.emergencyContactName} Â· ${application.emergencyContactPhone}',
                'Normal driver ID': application.existingNormalDriverId,
              },
            ),
            _DetailsSection(
              title: 'Driver documents',
              values: {
                'Profile photo': application.profilePhotoUrl,
                'CNIC front': application.cnicFrontUrl,
                'CNIC back': application.cnicBackUrl,
                'License number': application.drivingLicenseNumber,
                'License front': application.drivingLicenseFrontUrl,
                'License back': application.drivingLicenseBackUrl,
                'Police verification': application.policeVerificationUrl,
              },
            ),
            _DetailsSection(
              title: 'Vehicle',
              values: {
                'Type': application.vehicleType,
                'Make / model':
                    '${application.vehicleMake} ${application.vehicleModel}',
                'Color': application.vehicleColor,
                'Registration': application.vehicleRegistrationNumber,
                'Model year': application.vehicleModelYear.toString(),
                'Seating capacity': application.seatingCapacity.toString(),
                'Front photo': application.vehicleFrontPhotoUrl,
                'Back photo': application.vehicleBackPhotoUrl,
                'Registration document':
                    application.vehicleRegistrationDocumentUrl,
                'Fitness certificate':
                    application.vehicleFitnessCertificateUrl,
                'Insurance': application.vehicleInsuranceDocumentUrl,
              },
            ),
            _DetailsSection(
              title: 'Student transport and availability',
              values: {
                'Experience':
                    '${application.schoolTransportExperienceYears} year(s)',
                'School transport experience':
                    _yesNo(application.hasSchoolTransportExperience),
                'First aid training': _yesNo(application.hasFirstAidTraining),
                'Child safety declaration':
                    _yesNo(application.childSafetyDeclarationAccepted),
                'Background check consent':
                    _yesNo(application.backgroundCheckConsentAccepted),
                'Morning available': _yesNo(application.morningAvailable),
                'Afternoon available': _yesNo(application.afternoonAvailable),
                'Preferred schools':
                    application.preferredSchoolIds.join(', '),
                'Preferred routes':
                    application.preferredRouteIds.join(', '),
                'Has attendant': _yesNo(application.hasAttendant),
                if (application.hasAttendant)
                  'Attendant':
                      '${application.attendantName} Â· ${application.attendantPhone} Â· ${application.attendantCnicNumber}',
              },
            ),
            _DetailsSection(
              title: 'Settlement and review',
              values: {
                'Settlement method': application.settlementMethod,
                'Account title': application.accountTitle,
                'Account number': application.accountNumber,
                'Bank': application.bankName,
                'Rejection reason': application.rejectionReason,
                'Admin notes': application.adminNotes,
                'Reviewed by': application.reviewedBy,
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _ApplicationAction { review, approve, reject, suspend }

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.isBusy,
    required this.onTap,
    required this.onAction,
  });

  final StudentRideDriverApplicationModel application;
  final bool isBusy;
  final VoidCallback onTap;
  final ValueChanged<_ApplicationAction> onAction;

  @override
  Widget build(BuildContext context) {
    final status = application.status;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      application.fullName.trim().isEmpty
                          ? '?'
                          : application.fullName.trim()[0].toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${application.phoneNumber} Â· ${application.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${application.vehicleType} Â· ${application.vehicleMake} '
                '${application.vehicleModel} Â· ${application.seatingCapacity} seats',
              ),
              const SizedBox(height: 5),
              Text(
                'Availability: '
                '${application.morningAvailable ? 'Morning' : ''}'
                '${application.morningAvailable && application.afternoonAvailable ? ' + ' : ''}'
                '${application.afternoonAvailable ? 'Afternoon' : ''}',
              ),
              const SizedBox(height: 12),
              if (isBusy)
                const LinearProgressIndicator()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (status ==
                        StudentRideDriverApplicationStatus.submitted)
                      OutlinedButton(
                        onPressed: () =>
                            onAction(_ApplicationAction.review),
                        child: const Text('Under Review'),
                      ),
                    if (status !=
                            StudentRideDriverApplicationStatus.approved &&
                        status !=
                            StudentRideDriverApplicationStatus.suspended &&
                        status != StudentRideDriverApplicationStatus.draft)
                      FilledButton(
                        onPressed: () =>
                            onAction(_ApplicationAction.approve),
                        child: const Text('Approve'),
                      ),
                    if (status ==
                            StudentRideDriverApplicationStatus.submitted ||
                        status ==
                            StudentRideDriverApplicationStatus.underReview)
                      TextButton(
                        onPressed: () =>
                            onAction(_ApplicationAction.reject),
                        child: const Text('Reject'),
                      ),
                    if (status ==
                        StudentRideDriverApplicationStatus.approved)
                      FilledButton.tonal(
                        onPressed: () =>
                            onAction(_ApplicationAction.suspend),
                        child: const Text('Suspend'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final StudentRideDriverApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StudentRideDriverApplicationStatus.approved => Colors.green,
      StudentRideDriverApplicationStatus.rejected => Colors.red,
      StudentRideDriverApplicationStatus.suspended => Colors.deepOrange,
      StudentRideDriverApplicationStatus.underReview => Colors.blue,
      StudentRideDriverApplicationStatus.submitted => Colors.amber.shade800,
      StudentRideDriverApplicationStatus.draft => Colors.grey,
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(_statusLabel(status)),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withValues(alpha: .08),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.values});

  final String title;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    final visible = values.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          ...visible.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(entry.value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReasonResult {
  const _ReasonResult(this.reason, this.notes);

  final String reason;
  final String notes;
}

String _statusLabel(StudentRideDriverApplicationStatus status) {
  return switch (status) {
    StudentRideDriverApplicationStatus.draft => 'Draft',
    StudentRideDriverApplicationStatus.submitted => 'Submitted',
    StudentRideDriverApplicationStatus.underReview => 'Under review',
    StudentRideDriverApplicationStatus.approved => 'Approved',
    StudentRideDriverApplicationStatus.rejected => 'Rejected',
    StudentRideDriverApplicationStatus.suspended => 'Suspended',
  };
}

String _successMessage(_ApplicationAction action) {
  return switch (action) {
    _ApplicationAction.review => 'Application marked under review.',
    _ApplicationAction.approve => 'Student Ride driver approved.',
    _ApplicationAction.reject => 'Application rejected.',
    _ApplicationAction.suspend => 'Student Ride driver suspended.',
  };
}

String _yesNo(bool value) => value ? 'Yes' : 'No';

