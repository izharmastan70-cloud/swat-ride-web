import 'package:flutter/material.dart';

import '../models/loyalty_level_model.dart';
import '../models/reward_point_model.dart';
import '../services/loyalty_service.dart';

class RewardLevelsScreen extends StatefulWidget {
  const RewardLevelsScreen({
    super.key,
    required this.userId,
    this.module,
    this.loyaltyService,
  });

  final String userId;
  final RewardModule? module;
  final LoyaltyService? loyaltyService;

  @override
  State<RewardLevelsScreen> createState() => _RewardLevelsScreenState();
}

class _RewardLevelsScreenState extends State<RewardLevelsScreen> {
  static const Color _navy = Color(0xFF09233F);
  static const Color _background = Color(0xFFF5F7FB);

  late final LoyaltyService _service;
  List<LoyaltyLevelModel> _levels = [];
  LoyaltyLevelProgress? _progress;
  bool _isLoading = true;
  bool _featureEnabled = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.loyaltyService ?? LoyaltyService();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.userId.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID is required to load reward levels.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final enabled = await _service.isLoyaltyEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() {
          _featureEnabled = false;
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait<dynamic>([
        _service.getActiveLevels(module: widget.module),
        _service.getLevelProgress(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _featureEnabled = true;
        _levels = results[0] as List<LoyaltyLevelModel>;
        _progress = results[1] as LoyaltyLevelProgress;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text('Reward Levels',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Levels unavailable',
        message: _errorMessage!.isEmpty
            ? 'Reward levels could not be loaded.'
            : _errorMessage!,
        onRetry: _loadData,
      );
    }
    if (!_featureEnabled) {
      return const _StateMessage(
        icon: Icons.pause_circle_outline_rounded,
        title: 'Loyalty levels are turned off',
        message: 'The loyalty program is currently disabled by Admin.',
      );
    }

    final progress = _progress;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (progress != null) _ProgressCard(progress: progress),
          const SizedBox(height: 24),
          const Text('Membership journey',
              style: TextStyle(color: _navy, fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text(
            'Level requirements and benefits are controlled by Admin.',
            style: TextStyle(color: Color(0xFF6A7890)),
          ),
          const SizedBox(height: 14),
          if (_levels.isEmpty)
            const _EmptyLevels()
          else
            for (var index = 0; index < _levels.length; index++)
              _LevelTimelineItem(
                level: _levels[index],
                currentLevelId: progress?.currentLevel?.id,
                passed: progress?.currentLevel != null &&
                    _levels[index].displayOrder <= progress!.currentLevel!.displayOrder,
                isLast: index == _levels.length - 1,
              ),
          const SizedBox(height: 16),
          const _InfoNote(),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});
  final LoyaltyLevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final current = progress.currentLevel;
    final next = progress.nextLevel;
    final currentColor = _hexColor(current?.colorHex, const Color(0xFFCD7F32));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09233F), Color(0xFF1264E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x291264E5), blurRadius: 22, offset: Offset(0, 11)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 31),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENT MEMBERSHIP',
                        style: TextStyle(color: Colors.white60, fontSize: 11,
                            fontWeight: FontWeight.w800, letterSpacing: 1)),
                    Text(current?.name ?? 'Getting started',
                        style: const TextStyle(color: Colors.white, fontSize: 23,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('${progress.progressPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(
                progress.highestLevelReached
                    ? 'Highest level reached'
                    : 'Next: ${next?.name ?? 'Level'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (progress.progressPercentage / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD166)),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _ProgressDetail(
                  icon: Icons.stars_rounded,
                  value: _number(progress.lifetimePoints),
                  label: progress.highestLevelReached
                      ? 'Lifetime points'
                      : '${_number(progress.pointsNeeded)} more points',
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _ProgressDetail(
                  icon: Icons.receipt_long_rounded,
                  value: _number(progress.completedBookings),
                  label: progress.highestLevelReached
                      ? 'Bookings completed'
                      : '${_number(progress.bookingsNeeded)} more bookings',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressDetail extends StatelessWidget {
  const _ProgressDetail({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          )),
        ]),
      );
}

class _LevelTimelineItem extends StatelessWidget {
  const _LevelTimelineItem({
    required this.level,
    required this.currentLevelId,
    required this.passed,
    required this.isLast,
  });
  final LoyaltyLevelModel level;
  final String? currentLevelId;
  final bool passed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(level.colorHex, const Color(0xFF1264E5));
    final current = level.id == currentLevelId;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: passed ? color : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: current ? 3 : 2),
                  ),
                  child: Icon(
                    passed ? Icons.check_rounded : Icons.workspace_premium_outlined,
                    color: passed ? Colors.white : color,
                    size: 21,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: passed ? color : const Color(0xFFDDE3ED))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: current ? color : const Color(0xFFE5EAF2),
                    width: current ? 2 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(level.name,
                        style: const TextStyle(color: Color(0xFF09233F), fontSize: 18,
                            fontWeight: FontWeight.w900))),
                    if (current) _Badge(text: 'CURRENT', color: color),
                    if (level.isDefaultLevel && !current)
                      const _Badge(text: 'START', color: Color(0xFF6A7890)),
                  ]),
                  if (level.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(level.description,
                        style: const TextStyle(color: Color(0xFF6A7890), height: 1.3)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(spacing: 7, runSpacing: 7, children: [
                    _InfoPill(text: '${_number(level.minimumLifetimePoints)} points'),
                    _InfoPill(text: '${_number(level.minimumCompletedBookings)} bookings'),
                    if (level.pointsEarningMultiplier > 1)
                      _InfoPill(text: '${_decimal(level.pointsEarningMultiplier)}x points'),
                    if (level.cashbackBonusPercentage > 0)
                      _InfoPill(text: '+${_decimal(level.cashbackBonusPercentage)}% cashback'),
                    if (level.levelDiscountPercentage > 0)
                      _InfoPill(text: '${_decimal(level.levelDiscountPercentage)}% discount'),
                  ]),
                  if (_benefits(level).isNotEmpty) ...[
                    const SizedBox(height: 11),
                    for (final benefit in _benefits(level))
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(children: [
                          Icon(Icons.check_circle_rounded, color: color, size: 17),
                          const SizedBox(width: 7),
                          Expanded(child: Text(benefit,
                              style: const TextStyle(color: Color(0xFF536178), fontSize: 12))),
                        ]),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
      );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF4F7FB), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Color(0xFF5D6B82), fontSize: 11)),
      );
}

class _EmptyLevels extends StatelessWidget {
  const _EmptyLevels();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Column(children: [
          Icon(Icons.workspace_premium_outlined, size: 58, color: Color(0xFF9AA5B5)),
          SizedBox(height: 12),
          Text('No levels available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Admin-configured loyalty levels will appear here.',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6A7890))),
        ]),
      );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: const Color(0xFFEAF3FF), borderRadius: BorderRadius.circular(14)),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF1264E5)),
          SizedBox(width: 9),
          Expanded(child: Text(
            'Levels are evaluated after completed eligible bookings. This screen never upgrades a level itself.',
            style: TextStyle(color: Color(0xFF315D91), fontSize: 12),
          )),
        ]),
      );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.title, required this.message, this.onRetry});
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            Icon(icon, size: 62, color: const Color(0xFF9AA5B5)),
            const SizedBox(height: 15),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ]),
        ),
      );
}

List<String> _benefits(LoyaltyLevelModel level) {
  final benefits = List<String>.from(level.benefits);
  if (level.prioritySupportEnabled && !benefits.contains('Priority support')) {
    benefits.add('Priority support');
  }
  if (level.freeDeliveryEnabled && !benefits.contains('Free delivery')) {
    benefits.add('Free delivery');
  }
  if (level.exclusiveOffersEnabled && !benefits.contains('Exclusive offers')) {
    benefits.add('Exclusive offers');
  }
  return benefits;
}

Color _hexColor(String? value, Color fallback) {
  if (value == null) return fallback;
  final cleaned = value.replaceAll('#', '').trim();
  if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(cleaned)) return fallback;
  return Color(int.parse('FF$cleaned', radix: 16));
}

String _decimal(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _number(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

