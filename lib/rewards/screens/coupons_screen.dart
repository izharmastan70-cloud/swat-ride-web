import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/coupon_model.dart';
import '../models/global_promo_code_model.dart';
import '../models/reward_point_model.dart';
import '../services/coupon_service.dart';
import '../../help/widgets/contextual_video_guide_button.dart';
import '../services/reward_service.dart';

/// User coupon browser. This screen only shows/selects a coupon; it never
/// applies a discount or finalizes a payment without user confirmation.
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({
    super.key,
    required this.userId,
    this.loyaltyLevelId = '',
    this.module,
    this.isFirstBooking = false,
    this.couponService,
    this.rewardService,
    this.onCouponSelected,
  });

  final String userId;
  final String loyaltyLevelId;
  final RewardModule? module;
  final bool isFirstBooking;
  final CouponService? couponService;
  final RewardService? rewardService;
  final ValueChanged<CouponModel>? onCouponSelected;

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  static const Color _navy = Color(0xFF09233F);
  static const Color _blue = Color(0xFF1264E5);
  static const Color _background = Color(0xFFF5F7FB);

  late final CouponService _couponService;
  late final RewardService _rewardService;
  final TextEditingController _searchController = TextEditingController();

  List<CouponModel> _allCoupons = [];
  List<CouponModel> _visibleCoupons = [];
  bool _isLoading = true;
  bool _featureEnabled = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _couponService = widget.couponService ?? CouponService();
    _rewardService = widget.rewardService ?? RewardService();
    _loadCoupons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RewardModule> get _requestedModules {
    if (widget.module != null) return [widget.module!];
    return RewardModule.values
        .where(
          (module) =>
              module != RewardModule.all && module != RewardModule.future,
        )
        .toList();
  }

  Future<void> _loadCoupons() async {
    if (widget.userId.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID is required to load coupons.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await _rewardService.getSettings();
      final enabledModules = _requestedModules
          .where(settings.isCouponEnabledForModule)
          .toList();

      if (enabledModules.isEmpty) {
        if (!mounted) return;
        setState(() {
          _featureEnabled = false;
          _allCoupons = [];
          _visibleCoupons = [];
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait(
        enabledModules.map((module) {
          return _couponService.getAvailableCoupons(
            userId: widget.userId,
            loyaltyLevelId: widget.loyaltyLevelId,
            module: module,
            isFirstBooking: widget.isFirstBooking,
          );
        }),
      );

      final byId = <String, CouponModel>{};
      for (final coupons in results) {
        for (final coupon in coupons) {
          byId[coupon.id] = coupon;
        }
      }

      final coupons = byId.values.toList()
        ..sort((a, b) {
          if (a.expiryDate == null && b.expiryDate == null) return 0;
          if (a.expiryDate == null) return 1;
          if (b.expiryDate == null) return -1;
          return a.expiryDate!.compareTo(b.expiryDate!);
        });

      if (!mounted) return;
      setState(() {
        _featureEnabled = true;
        _allCoupons = coupons;
        _isLoading = false;
      });
      _applySearch();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _applySearch([String? value]) {
    final search = (value ?? _searchController.text).trim().toLowerCase();
    setState(() {
      _visibleCoupons = search.isEmpty
          ? List<CouponModel>.from(_allCoupons)
          : _allCoupons.where((coupon) {
              return coupon.normalizedCode.toLowerCase().contains(search) ||
                  coupon.title.toLowerCase().contains(search) ||
                  coupon.description.toLowerCase().contains(search);
            }).toList();
    });
  }

  Future<void> _copyCode(CouponModel coupon) async {
    await Clipboard.setData(ClipboardData(text: coupon.normalizedCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${coupon.normalizedCode} copied')),
      );
  }

  void _selectCoupon(CouponModel coupon) {
    if (widget.onCouponSelected != null) {
      widget.onCouponSelected!(coupon);
      return;
    }
    _copyCode(coupon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Coupons',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadCoupons,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Coupons unavailable',
        message: _errorMessage!.isEmpty
            ? 'Coupons could not be loaded.'
            : _errorMessage!,
        onRetry: _loadCoupons,
      );
    }

    if (!_featureEnabled) {
      return const _StateMessage(
        icon: Icons.pause_circle_outline_rounded,
        title: 'Coupons are turned off',
        message: 'Coupons are currently disabled by Admin for this service.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCoupons,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          ContextualVideoGuideButton(
            module: 'rewards',
            feature: 'coupons',
            intents: const <String>[
              'available_coupons',
              'use_coupon',
              'coupon_eligibility',
              'coupon_expiry',
              'coupon_terms',
            ],
            label: 'Need Help? Watch Coupon Guide',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _applySearch,
            decoration: InputDecoration(
              hintText: 'Search by coupon code or name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _applySearch('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5EAF2)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${_visibleCoupons.length} available',
            style: const TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (_visibleCoupons.isEmpty)
            const _EmptyCoupons()
          else
            for (final coupon in _visibleCoupons) ...[
              _CouponCard(
                coupon: coupon,
                onCopy: () => _copyCode(coupon),
                onSelect: () => _selectCoupon(coupon),
                selectionMode: widget.onCouponSelected != null,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x291264E5),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Color(0x24FFFFFF),
            child: Icon(
              Icons.local_offer_rounded,
              color: Color(0xFFFFD166),
              size: 29,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save more with SWAT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose a coupon. It will apply only after your confirmation.',
                  style: TextStyle(color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.onCopy,
    required this.onSelect,
    required this.selectionMode,
  });

  final CouponModel coupon;
  final VoidCallback onCopy;
  final VoidCallback onSelect;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Center(
                    child: Text(
                      _discountLabel(coupon),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1264E5),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title.trim().isEmpty
                            ? 'Special coupon'
                            : coupon.title,
                        style: const TextStyle(
                          color: Color(0xFF09233F),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (coupon.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          coupon.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64728A),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (coupon.minimumAmount > 0)
                  _InfoPill(text: 'Min PKR ${_money(coupon.minimumAmount)}'),
                if (coupon.maximumDiscount != null)
                  _InfoPill(text: 'Max PKR ${_money(coupon.maximumDiscount!)}'),
                _InfoPill(text: _expiryText(coupon.expiryDate)),
                _InfoPill(text: _moduleText(coupon.supportedModules)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE9EDF4)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCE3ED)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              coupon.normalizedCode,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF09233F),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Icon(Icons.copy_rounded, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
                if (selectionMode) ...[
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: onSelect,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Select'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF5D6B82), fontSize: 11),
      ),
    );
  }
}

class _EmptyCoupons extends StatelessWidget {
  const _EmptyCoupons();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.local_offer_outlined, size: 65, color: Color(0xFF9AA5B5)),
          SizedBox(height: 15),
          Text(
            'No coupons available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 7),
          Text(
            'New eligible coupons will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6A7890)),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 62, color: const Color(0xFF9AA5B5)),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

String _discountLabel(CouponModel coupon) {
  switch (coupon.discountType) {
    case GlobalPromoDiscountType.percentage:
      return '${_compact(coupon.discountValue)}%\nOFF';
    case GlobalPromoDiscountType.fixedAmount:
      return 'PKR\n${_compact(coupon.discountValue)}';
    case GlobalPromoDiscountType.freeDelivery:
      return 'FREE\nDELIVERY';
  }
}

String _moduleText(List<RewardModule> modules) {
  if (modules.contains(RewardModule.all)) return 'All services';
  if (modules.isEmpty) return 'Selected services';
  if (modules.length == 1) return _label(modules.first.name);
  return '${modules.length} services';
}

String _expiryText(DateTime? expiry) {
  if (expiry == null) return 'No expiry';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return 'Until ${expiry.day} ${months[expiry.month - 1]} ${expiry.year}';
}

String _money(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _compact(double value) => _money(value);

String _label(String value) {
  final spaced = value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .replaceAll('_', ' ')
      .trim();
  if (spaced.isEmpty) return 'Other';
  return spaced
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}
