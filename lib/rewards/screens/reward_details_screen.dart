import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reward_transaction_model.dart';

class RewardDetailsScreen extends StatelessWidget {
  const RewardDetailsScreen({
    super.key,
    required this.transaction,
  });

  final RewardTransactionModel transaction;

  static const Color _navy = Color(0xFF09233F);
  static const Color _background = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    final amountColor = credit ? const Color(0xFF159B6C) : const Color(0xFFD1495B);
    final statusColor = _statusColor(transaction.status);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text('Reward Details',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _HeaderCard(
              transaction: transaction,
              amountColor: amountColor,
              statusColor: statusColor,
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Transaction summary',
              children: [
                _DetailRow(
                  label: 'Transaction type',
                  value: _label(transaction.type.name),
                  icon: Icons.swap_vert_circle_outlined,
                ),
                _DetailRow(
                  label: 'Module',
                  value: _label(transaction.module.name),
                  icon: _moduleIcon(transaction.module.name),
                ),
                _DetailRow(
                  label: 'Status',
                  value: _label(transaction.status.name),
                  icon: Icons.verified_outlined,
                  valueColor: statusColor,
                ),
                _DetailRow(
                  label: 'Created',
                  value: _formatDateTime(transaction.createdAt),
                  icon: Icons.calendar_today_outlined,
                ),
                if (transaction.completedAt != null)
                  _DetailRow(
                    label: 'Completed',
                    value: _formatDateTime(transaction.completedAt!),
                    icon: Icons.task_alt_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Points balance',
              children: [
                _DetailRow(
                  label: 'Points change',
                  value:
                      '${credit ? '+' : ''}${_number(transaction.points)} points',
                  icon: credit
                      ? Icons.add_circle_outline_rounded
                      : Icons.remove_circle_outline_rounded,
                  valueColor: amountColor,
                ),
                _DetailRow(
                  label: 'Balance before',
                  value: '${_number(transaction.balanceBefore)} points',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _DetailRow(
                  label: 'Balance after',
                  value: '${_number(transaction.balanceAfter)} points',
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
            if (transaction.expiresAt != null) ...[
              const SizedBox(height: 12),
              _ExpiryCard(
                expiresAt: transaction.expiresAt!,
                expired: transaction.isExpired,
              ),
            ],
            if (_hasReferenceInformation(transaction)) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Reference information',
                children: [
                  _CopyDetailRow(
                    label: 'Transaction ID',
                    value: transaction.id,
                  ),
                  if (transaction.sourceId?.trim().isNotEmpty == true)
                    _CopyDetailRow(
                      label: 'Booking / source ID',
                      value: transaction.sourceId!,
                    ),
                  if (transaction.rewardRuleId?.trim().isNotEmpty == true)
                    _CopyDetailRow(
                      label: 'Reward rule ID',
                      value: transaction.rewardRuleId!,
                    ),
                  if (transaction.reversedTransactionId?.trim().isNotEmpty ==
                      true)
                    _CopyDetailRow(
                      label: 'Reversed transaction',
                      value: transaction.reversedTransactionId!,
                    ),
                ],
              ),
            ],
            if (transaction.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Description',
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      color: Color(0xFF536178),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            const _ReadOnlyNote(),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.transaction,
    required this.amountColor,
    required this.statusColor,
  });

  final RewardTransactionModel transaction;
  final Color amountColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09233F), Color(0xFF1264E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x291264E5),
            blurRadius: 22,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0x24FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _transactionIcon(transaction.type),
              color: const Color(0xFFFFD166),
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            transaction.title.trim().isEmpty
                ? _label(transaction.type.name)
                : transaction.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${credit ? '+' : ''}${_number(transaction.points)} points',
            style: TextStyle(
              color: credit ? const Color(0xFF75E0B6) : const Color(0xFFFF9DA8),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.65)),
            ),
            child: Text(
              _label(transaction.status.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF09233F),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(height: 20, color: Color(0xFFE9EDF4)),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF718096)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Color(0xFF718096))),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF09233F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CopyDetailRow extends StatelessWidget {
  const _CopyDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Color(0xFF718096), fontSize: 12)),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF09233F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy',
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy_rounded, size: 19),
        ),
      ],
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.expiresAt, required this.expired});
  final DateTime expiresAt;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final color = expired ? const Color(0xFFD1495B) : const Color(0xFFE07A24);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: expired ? const Color(0xFFFFEEF0) : const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(expired ? Icons.timer_off_outlined : Icons.schedule_rounded,
              color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expired ? 'Points expired' : 'Points expiry',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                Text(_formatDateTime(expiresAt),
                    style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF1264E5)),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'This is a read-only reward receipt. Admin-controlled changes are recorded as separate transactions.',
              style: TextStyle(color: Color(0xFF315D91), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

bool _hasReferenceInformation(RewardTransactionModel transaction) {
  return transaction.id.trim().isNotEmpty ||
      transaction.sourceId?.trim().isNotEmpty == true ||
      transaction.rewardRuleId?.trim().isNotEmpty == true ||
      transaction.reversedTransactionId?.trim().isNotEmpty == true;
}

Color _statusColor(RewardTransactionStatus status) {
  switch (status) {
    case RewardTransactionStatus.completed:
      return const Color(0xFF159B6C);
    case RewardTransactionStatus.pending:
      return const Color(0xFFE07A24);
    case RewardTransactionStatus.failed:
    case RewardTransactionStatus.cancelled:
      return const Color(0xFFD1495B);
    case RewardTransactionStatus.reversed:
      return const Color(0xFF7654C4);
    case RewardTransactionStatus.expired:
      return const Color(0xFF6A7890);
  }
}

IconData _transactionIcon(RewardTransactionType type) {
  switch (type) {
    case RewardTransactionType.earned:
      return Icons.stars_rounded;
    case RewardTransactionType.redeemed:
      return Icons.redeem_rounded;
    case RewardTransactionType.signupBonus:
    case RewardTransactionType.firstBookingBonus:
    case RewardTransactionType.referralBonus:
    case RewardTransactionType.campaignBonus:
      return Icons.card_giftcard_rounded;
    case RewardTransactionType.manualCredit:
      return Icons.add_circle_rounded;
    case RewardTransactionType.manualDebit:
      return Icons.remove_circle_rounded;
    case RewardTransactionType.expired:
      return Icons.schedule_rounded;
    case RewardTransactionType.reversed:
    case RewardTransactionType.refundAdjustment:
      return Icons.undo_rounded;
  }
}

IconData _moduleIcon(String module) {
  final value = module.toLowerCase();
  if (value.contains('food') || value.contains('restaurant')) {
    return Icons.restaurant_rounded;
  }
  if (value.contains('hotel')) return Icons.hotel_rounded;
  if (value.contains('tour') || value.contains('guide')) {
    return Icons.travel_explore_rounded;
  }
  if (value.contains('cargo')) return Icons.local_shipping_rounded;
  if (value.contains('parcel')) return Icons.inventory_2_rounded;
  if (value.contains('wallet')) return Icons.account_balance_wallet_rounded;
  if (value.contains('student')) return Icons.school_rounded;
  return Icons.directions_car_rounded;
}

String _formatDateTime(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $period';
}

String _number(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

String _label(String value) {
  final spaced = value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
      .replaceAll('_', ' ')
      .trim();
  if (spaced.isEmpty) return 'Other';
  return spaced.split(' ').map((word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}
