import 'package:flutter/material.dart';

import '../models/complaint_model.dart';
import '../models/feedback_model.dart';
import '../services/complaint_service.dart';
import '../services/feedback_admin_service.dart';
import '../services/feedback_service.dart';

class FeedbackAdminDashboardScreen extends StatefulWidget {
  final String adminId;
  final FeedbackAdminService? adminService;
  final FeedbackService? feedbackService;
  final ComplaintService? complaintService;
  final VoidCallback? onOpenReviewManagement;
  final VoidCallback? onOpenComplaintManagement;
  final VoidCallback? onOpenAnalytics;

  const FeedbackAdminDashboardScreen({
    super.key,
    required this.adminId,
    this.adminService,
    this.feedbackService,
    this.complaintService,
    this.onOpenReviewManagement,
    this.onOpenComplaintManagement,
    this.onOpenAnalytics,
  });

  @override
  State<FeedbackAdminDashboardScreen> createState() =>
      _FeedbackAdminDashboardScreenState();
}

class _FeedbackAdminDashboardScreenState
    extends State<FeedbackAdminDashboardScreen> {
  late final FeedbackAdminService _adminService;
  late final FeedbackService _feedbackService;
  late final ComplaintService _complaintService;

  FeedbackServiceType? _serviceType;
  FeedbackStatus? _status;
  int? _rating;

  @override
  void initState() {
    super.initState();
    _adminService = widget.adminService ?? FeedbackAdminService();
    _feedbackService = widget.feedbackService ?? FeedbackService();
    _complaintService = widget.complaintService ?? ComplaintService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback Center',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'All SWAT RIDE services',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Feedback settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: StreamBuilder<FeedbackRuntimeSettings>(
          stream: _feedbackService.watchSettings(),
          builder: (context, settingsSnapshot) {
            final settings =
                settingsSnapshot.data ?? const FeedbackRuntimeSettings();
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                _SystemBanner(settings: settings),
                const SizedBox(height: 16),
                _buildReviewOverview(settings),
                const SizedBox(height: 16),
                _buildActionGrid(),
                const SizedBox(height: 22),
                const _SectionTitle(
                  title: 'Review monitor',
                  subtitle: 'Live reviews across every enabled service',
                ),
                const SizedBox(height: 12),
                _buildFilters(),
                const SizedBox(height: 12),
                _buildRecentReviews(),
                const SizedBox(height: 22),
                const _SectionTitle(
                  title: 'Safety & moderation',
                  subtitle: 'Items requiring human admin attention',
                ),
                const SizedBox(height: 12),
                _buildAttentionPanel(settings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReviewOverview(FeedbackRuntimeSettings settings) {
    return StreamBuilder<List<FeedbackModel>>(
      stream: _adminService.watchReviews(limit: 100),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <FeedbackModel>[];
        final active = reviews.where((item) => !item.isDeleted).toList();
        final average = active.isEmpty
            ? 0.0
            : active.fold<int>(0, (sum, item) => sum + item.rating) /
                  active.length;
        final flagged = active.where((item) => item.isFlagged).length;
        final low = active
            .where((item) => item.rating <= settings.lowRatingThreshold)
            .length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 900 ? 4 : 2;
            final ratio = width >= 900 ? 1.8 : 1.35;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: ratio,
              children: [
                _MetricCard(
                  label: 'Average rating',
                  value: average.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: const Color(0xFFF59E0B),
                  suffix: '/ 5',
                ),
                _MetricCard(
                  label: 'Latest reviews',
                  value: active.length.toString(),
                  icon: Icons.rate_review_rounded,
                  color: const Color(0xFF2563EB),
                ),
                _MetricCard(
                  label: 'Low ratings',
                  value: low.toString(),
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFDC2626),
                ),
                _MetricCard(
                  label: 'Flagged',
                  value: flagged.toString(),
                  icon: Icons.flag_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return GridView.count(
          crossAxisCount: wide ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: wide ? 2.5 : 4.2,
          children: [
            _ActionCard(
              title: 'Manage reviews',
              subtitle: 'Moderate, hide and audit',
              icon: Icons.fact_check_rounded,
              onTap:
                  widget.onOpenReviewManagement ??
                  () => _notConnected('Review management'),
            ),
            _ActionCard(
              title: 'Complaints',
              subtitle: 'Tickets and safety escalation',
              icon: Icons.support_agent_rounded,
              onTap:
                  widget.onOpenComplaintManagement ??
                  () => _notConnected('Complaint management'),
            ),
            _ActionCard(
              title: 'Analytics',
              subtitle: 'Trends and service quality',
              icon: Icons.insights_rounded,
              onTap:
                  widget.onOpenAnalytics ??
                  () => _notConnected('Feedback analytics'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _FilterDropdown<FeedbackServiceType?>(
            value: _serviceType,
            hint: 'All services',
            items: [
              const DropdownMenuItem(value: null, child: Text('All services')),
              ...FeedbackServiceType.values.map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value.displayName),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _serviceType = value),
          ),
          _FilterDropdown<FeedbackStatus?>(
            value: _status,
            hint: 'All statuses',
            items: [
              const DropdownMenuItem(value: null, child: Text('All statuses')),
              ...FeedbackStatus.values.map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_statusLabel(value)),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
          _FilterDropdown<int?>(
            value: _rating,
            hint: 'All ratings',
            items: [
              const DropdownMenuItem(value: null, child: Text('All ratings')),
              ...List.generate(5, (index) => 5 - index).map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text('$value star')),
              ),
            ],
            onChanged: (value) => setState(() => _rating = value),
          ),
          TextButton.icon(
            onPressed: () => setState(() {
              _serviceType = null;
              _status = null;
              _rating = null;
            }),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviews() {
    return StreamBuilder<List<FeedbackModel>>(
      stream: _adminService.watchReviews(
        serviceType: _serviceType,
        status: _status,
        rating: _rating,
        limit: 20,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorCard(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const _LoadingCard();
        }
        final reviews = snapshot.data!;
        if (reviews.isEmpty) {
          return const _EmptyCard(
            icon: Icons.reviews_outlined,
            text: 'No reviews match these filters.',
          );
        }
        return Container(
          decoration: _cardDecoration(),
          child: Column(
            children: reviews.take(8).map((review) {
              return Column(
                children: [
                  _ReviewRow(review: review),
                  if (review != reviews.take(8).last)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAttentionPanel(FeedbackRuntimeSettings settings) {
    return Column(
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _adminService.watchOpenReports(limit: 100),
          builder: (context, snapshot) => _AttentionTile(
            title: 'Open review/reply reports',
            value: snapshot.hasData ? snapshot.data!.length.toString() : '—',
            icon: Icons.report_problem_rounded,
            color: const Color(0xFFEA580C),
            onTap:
                widget.onOpenReviewManagement ??
                () => _notConnected('Report management'),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<FeedbackModel>>(
          stream: _adminService.watchLowRatingReviews(
            maximumRating: settings.lowRatingThreshold,
            limit: 100,
          ),
          builder: (context, snapshot) => _AttentionTile(
            title: 'Low-rating alerts',
            value: snapshot.hasData ? snapshot.data!.length.toString() : '—',
            icon: Icons.notification_important_rounded,
            color: const Color(0xFFDC2626),
            onTap:
                widget.onOpenReviewManagement ??
                () => _notConnected('Low-rating management'),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<ComplaintModel>>(
          stream: _complaintService.watchPendingSafetyEscalations(limit: 100),
          builder: (context, snapshot) => _AttentionTile(
            title: 'Pending safety escalations',
            value: snapshot.hasData ? snapshot.data!.length.toString() : '—',
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFFB91C1C),
            onTap:
                widget.onOpenComplaintManagement ??
                () => _notConnected('Safety complaint management'),
          ),
        ),
      ],
    );
  }

  Future<void> _openSettings() async {
    FeedbackRuntimeSettings current;
    bool complaintsEnabled;
    try {
      current = await _feedbackService.getSettings();
      complaintsEnabled = await _complaintService.isComplaintModuleEnabled();
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _SettingsDialog(
        initial: current,
        complaintsEnabled: complaintsEnabled,
        onSave: (settings, complaintEnabled) async {
          await _adminService.updateGlobalSettings(
            settings: settings,
            adminId: widget.adminId,
            complaintModuleEnabled: complaintEnabled,
            reason: 'Updated from Feedback Admin Dashboard',
          );
        },
      ),
    );
  }

  void _notConnected(String name) {
    _showMessage('$name screen will be connected in the next roadmap step.');
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFB91C1C) : null,
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  final FeedbackRuntimeSettings initial;
  final bool complaintsEnabled;
  final Future<void> Function(FeedbackRuntimeSettings, bool) onSave;

  const _SettingsDialog({
    required this.initial,
    required this.complaintsEnabled,
    required this.onSave,
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late bool feedback;
  late bool publicReviews;
  late bool replies;
  late bool editing;
  late bool deletion;
  late bool anonymous;
  late bool moderation;
  late bool verifiedOnly;
  late bool complaints;
  late double threshold;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    feedback = value.feedbackEnabled;
    publicReviews = value.publicReviewsEnabled;
    replies = value.partnerRepliesEnabled;
    editing = value.reviewEditingEnabled;
    deletion = value.reviewDeletionEnabled;
    anonymous = value.anonymousReviewsEnabled;
    moderation = value.requireModeration;
    verifiedOnly = value.verifiedServicesOnly;
    complaints = widget.complaintsEnabled;
    threshold = value.lowRatingThreshold.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Feedback controls'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _toggle(
                'Feedback system',
                feedback,
                (value) => setState(() => feedback = value),
              ),
              _toggle(
                'Public reviews',
                publicReviews,
                (value) => setState(() => publicReviews = value),
              ),
              _toggle(
                'Partner replies',
                replies,
                (value) => setState(() => replies = value),
              ),
              _toggle(
                'Review editing',
                editing,
                (value) => setState(() => editing = value),
              ),
              _toggle(
                'Review deletion',
                deletion,
                (value) => setState(() => deletion = value),
              ),
              _toggle(
                'Anonymous reviews',
                anonymous,
                (value) => setState(() => anonymous = value),
              ),
              _toggle(
                'Require moderation',
                moderation,
                (value) => setState(() => moderation = value),
              ),
              _toggle(
                'Verified services only',
                verifiedOnly,
                (value) => setState(() => verifiedOnly = value),
              ),
              _toggle(
                'Complaint module',
                complaints,
                (value) => setState(() => complaints = value),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Low-rating alert threshold'),
                subtitle: Slider(
                  value: threshold,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${threshold.round()} star',
                  onChanged: (value) => setState(() => threshold = value),
                ),
                trailing: Text(
                  '${threshold.round()}★',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save controls'),
        ),
      ],
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.onSave(
        FeedbackRuntimeSettings(
          feedbackEnabled: feedback,
          publicReviewsEnabled: publicReviews,
          partnerRepliesEnabled: replies,
          reviewEditingEnabled: editing,
          reviewDeletionEnabled: deletion,
          anonymousReviewsEnabled: anonymous,
          requireModeration: moderation,
          verifiedServicesOnly: verifiedOnly,
          editWindowHours: widget.initial.editWindowHours,
          lowRatingThreshold: threshold.round(),
          serviceRatingsEnabled: widget.initial.serviceRatingsEnabled,
        ),
        complaints,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    }
  }
}

class _SystemBanner extends StatelessWidget {
  final FeedbackRuntimeSettings settings;
  const _SystemBanner({required this.settings});

  @override
  Widget build(BuildContext context) {
    final active = settings.feedbackEnabled;
    final color = active ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              active
                  ? 'Universal feedback system is active'
                  : 'Feedback submissions are disabled by admin',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'Alert ≤ ${settings.lowRatingThreshold}★',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const Spacer(),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: suffix,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  final FeedbackModel review;
  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: _ratingColor(review.rating).withValues(alpha: .12),
          child: Text(
            '${review.rating}★',
            style: TextStyle(
              color: _ratingColor(review.rating),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.targetName.trim().isEmpty
                          ? review.targetType.displayName
                          : review.targetName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _StatusChip(status: review.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${review.serviceType.displayName} • ${review.publicReviewerName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              if (review.comment.trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  review.comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (review.isFlagged) ...[
                const SizedBox(height: 7),
                Text(
                  'Flagged • ${review.reportCount} report(s)',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final FeedbackStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F1F3),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _statusLabel(status),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _AttentionTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AttentionTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .1),
        foregroundColor: color,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F6F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hint),
      items: items,
      onChanged: onChanged,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
    ],
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(
    height: 130,
    decoration: _cardDecoration(),
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Icon(icon, size: 38, color: const Color(0xFF9CA3AF)),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFF991B1B))),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0xFFE5E7EB)),
);

String _statusLabel(FeedbackStatus value) {
  switch (value) {
    case FeedbackStatus.published:
      return 'Published';
    case FeedbackStatus.pendingModeration:
      return 'Pending';
    case FeedbackStatus.hidden:
      return 'Hidden';
    case FeedbackStatus.removed:
      return 'Removed';
    case FeedbackStatus.flagged:
      return 'Flagged';
  }
}

Color _ratingColor(int rating) {
  if (rating <= 2) return const Color(0xFFDC2626);
  if (rating == 3) return const Color(0xFFEA580C);
  return const Color(0xFF15803D);
}
