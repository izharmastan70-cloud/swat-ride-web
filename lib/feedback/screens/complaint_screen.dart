import 'package:flutter/material.dart';

import '../models/complaint_model.dart';
import '../models/feedback_model.dart';
import '../services/complaint_service.dart';
import '../services/feedback_service.dart';

class ComplaintScreen extends StatefulWidget {
  final FeedbackServiceType serviceType;
  final String sourceId;
  final String sourceReference;
  final String feedbackId;
  final String reporterId;
  final String reporterName;
  final String reporterPhone;
  final FeedbackTargetType targetType;
  final String targetId;
  final String targetName;
  final int? relatedRating;
  final ComplaintService? complaintService;

  const ComplaintScreen({
    super.key,
    required this.serviceType,
    required this.sourceId,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    this.sourceReference = '',
    this.feedbackId = '',
    this.reporterName = '',
    this.reporterPhone = '',
    this.targetName = '',
    this.relatedRating,
    this.complaintService,
  });

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  late final ComplaintService _service;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _evidenceController = TextEditingController();
  ComplaintCategory _category = ComplaintCategory.serviceQuality;
  bool _confirmed = false;
  bool _allowContact = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.complaintService ?? ComplaintService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.length < 20) {
      _message('Add a title and at least 20 characters of details.');
      return;
    }
    if (title.length > ComplaintModel.maximumTitleLength ||
        description.length > ComplaintModel.maximumDescriptionLength) {
      _message('Complaint text is longer than the allowed limit.');
      return;
    }
    if (!_confirmed) {
      _message('Please confirm that the information is accurate.');
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final complaint = ComplaintModel(
      id: '',
      ticketId: '',
      serviceType: widget.serviceType,
      sourceId: widget.sourceId.trim(),
      sourceReference: widget.sourceReference.trim(),
      feedbackId: widget.feedbackId.trim(),
      reporterId: widget.reporterId.trim(),
      reporterName: widget.reporterName.trim(),
      reporterPhone: widget.reporterPhone.trim(),
      targetType: widget.targetType,
      targetId: widget.targetId.trim(),
      targetName: widget.targetName.trim(),
      category: _category,
      priority: _category.recommendedPriority,
      title: title,
      description: description,
      safetyEscalationRequired: _category.requiresSafetyEscalation,
      createdAt: now,
      updatedAt: now,
      metadata: <String, dynamic>{
        'relatedRating': widget.relatedRating,
        'evidenceNotes': _evidenceController.text.trim(),
        'allowSupportContact': _allowContact,
        'storageEvidencePending': _evidenceController.text.trim().isNotEmpty,
      },
    );
    try {
      final id = await _service.createComplaint(complaint: complaint);
      if (mounted) Navigator.of(context).pop(id);
    } on FeedbackOperationException catch (error) {
      if (mounted) _message(error.message);
    } on FormatException catch (error) {
      if (mounted) _message(error.message);
    } on Object catch (error) {
      if (mounted) _message('Complaint could not be submitted.');
      debugPrint('Complaint submit error: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _service.watchComplaintModuleEnabled(),
      builder: (context, snapshot) {
        final waiting =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final enabled = snapshot.data ?? true;
        return Scaffold(
          backgroundColor: const Color(0xFFF4F5F6),
          appBar: AppBar(
            title: const Text(
              'Open a complaint',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF202124),
            surfaceTintColor: Colors.white,
          ),
          body: waiting
              ? const Center(child: CircularProgressIndicator())
              : enabled
              ? _form()
              : const _DisabledView(),
        );
      },
    );
  }

  Widget _form() {
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if ((widget.relatedRating ?? 5) <= 2)
                  const _Notice(
                    icon: Icons.support_agent_rounded,
                    text:
                        'A complaint creates a separate support ticket. '
                        'Your original review remains unchanged.',
                    color: Color(0xFFB06000),
                  ),
                if ((widget.relatedRating ?? 5) <= 2)
                  const SizedBox(height: 12),
                _Card(
                  title: 'Related service',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: <Widget>[
                      _Info('Service', widget.serviceType.displayName),
                      const SizedBox(height: 10),
                      _Info(
                        'Against',
                        widget.targetName.trim().isEmpty
                            ? widget.targetType.displayName
                            : widget.targetName.trim(),
                      ),
                      const SizedBox(height: 10),
                      _Info(
                        'Reference',
                        widget.sourceReference.trim().isEmpty
                            ? widget.sourceId
                            : widget.sourceReference,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: 'What happened?',
                  icon: Icons.category_outlined,
                  child: DropdownButtonFormField<ComplaintCategory>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: _input('Complaint category'),
                    items: ComplaintCategory.values
                        .map(
                          (item) => DropdownMenuItem<ComplaintCategory>(
                            value: item,
                            child: Text(item.displayName),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                ),
                if (_category.requiresSafetyEscalation) ...<Widget>[
                  const SizedBox(height: 12),
                  const _Notice(
                    icon: Icons.health_and_safety_outlined,
                    text:
                        'This complaint will automatically enter the admin '
                        'safety-review queue. Final action remains admin-controlled.',
                    color: Color(0xFFD93025),
                  ),
                ],
                const SizedBox(height: 12),
                _Card(
                  title: 'Complaint details',
                  icon: Icons.edit_note_rounded,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _titleController,
                        maxLength: ComplaintModel.maximumTitleLength,
                        decoration: _input('Short title'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descriptionController,
                        minLines: 6,
                        maxLines: 12,
                        maxLength: ComplaintModel.maximumDescriptionLength,
                        decoration: _input('Full details'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: 'Evidence details',
                  icon: Icons.attach_file_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Uploads will be enabled after Firebase Storage billing. '
                        'For now, describe your evidence.',
                        style: TextStyle(color: Color(0xFF777C85), height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _evidenceController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: _input('Evidence notes (optional)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: _decoration(),
                  child: Column(
                    children: <Widget>[
                      CheckboxListTile(
                        value: _confirmed,
                        activeColor: const Color(0xFF111315),
                        title: const Text(
                          'I confirm this information is accurate',
                        ),
                        onChanged: (value) =>
                            setState(() => _confirmed = value ?? false),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _allowContact,
                        activeTrackColor: const Color(0xFF111315),
                        title: const Text('Allow support to contact me'),
                        onChanged: (value) =>
                            setState(() => _allowContact = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Submitting...' : 'Submit complaint'),
                style: FilledButton.styleFrom(
                  backgroundColor: _category.requiresSafetyEscalation
                      ? const Color(0xFFD93025)
                      : const Color(0xFF111315),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF555960)),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 85,
        child: Text(label, style: const TextStyle(color: Color(0xFF8A8F98))),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Notice({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 11),
        Expanded(
          child: Text(text, style: TextStyle(color: color, height: 1.4)),
        ),
      ],
    ),
  );
}

class _DisabledView extends StatelessWidget {
  const _DisabledView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text(
        'Complaints are temporarily disabled by admin.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

InputDecoration _input(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: const Color(0xFFF5F6F7),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  ),
);

BoxDecoration _decoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: const Color(0xFFE7E9EC)),
);
