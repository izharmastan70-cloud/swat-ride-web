import 'package:flutter/material.dart';

import '../services/ride_admin_service.dart';

class RidePricingManagementScreen extends StatefulWidget {
  const RidePricingManagementScreen({
    super.key,
    this.adminId = 'testing_admin',
  });

  final String adminId;

  @override
  State<RidePricingManagementScreen> createState() =>
      _RidePricingManagementScreenState();
}

class _RidePricingManagementScreenState
    extends State<RidePricingManagementScreen> {
  static const Color _yellow = Color(0xFFFFD400);
  static const Color _background = Color(0xFF090909);
  static const Color _card = Color(0xFF191919);

  final RideAdminService _service = RideAdminService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ride Pricing',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPricingEditor(),
        backgroundColor: _yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<RideAdminRecord>>(
                stream: _service.watchPricing(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Pricing could not be loaded',
                      message: _cleanError(snapshot.error),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _yellow),
                    );
                  }
                  final List<RideAdminRecord> records =
                      _filter(snapshot.data ?? <RideAdminRecord>[]);
                  if (records.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.price_change_outlined,
                      title: 'No vehicle pricing found',
                      message: 'Add the first vehicle pricing configuration.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildPricingCard(records[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _yellow.withValues(alpha: 0.1),
              border: Border.all(color: _yellow.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.admin_panel_settings_outlined, color: _yellow),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Changes are saved in Firestore and become available to the normal Ride module without an app update.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search vehicle name or ID',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search_rounded, color: _yellow),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<RideAdminRecord> _filter(List<RideAdminRecord> source) {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source.where((record) {
      return <String>[
        record.id,
        record.text('vehicleId'),
        record.text('vehicleName'),
        record.text('displayName'),
      ].join(' ').toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Widget _buildPricingCard(RideAdminRecord record) {
    final bool enabled = record.boolean('isEnabled', fallback: true);
    final String vehicleName = record.text(
      'vehicleName',
      fallback: record.text('displayName', fallback: _title(record.id)),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled ? Colors.white10 : Colors.redAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_vehicleIcon(record.id), color: _yellow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      vehicleName,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.text('vehicleId', fallback: record.id),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _EnabledBadge(enabled: enabled),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _priceTile('Base fare', record.number('baseFare'), 'Rs')),
              const SizedBox(width: 8),
              Expanded(child: _priceTile('Per km', record.number('perKilometerRate'), 'Rs')),
              const SizedBox(width: 8),
              Expanded(child: _priceTile('Per min', record.number('perMinuteRate'), 'Rs')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(child: _priceTile('Minimum', record.number('minimumFare'), 'Rs')),
              const SizedBox(width: 8),
              Expanded(child: _priceTile('Commission', record.number('adminCommissionPercentage'), '%')),
              const SizedBox(width: 8),
              Expanded(child: _priceTile('Surge', _surge(record), 'x')),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Updated ${_date(record.updatedAt)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openPricingEditor(record),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: _yellow),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceTile(String label, double value, String unit) {
    final String display = unit == 'x'
        ? '${value == 0 ? 1 : value.toStringAsFixed(2)}x'
        : unit == '%'
            ? '${value.toStringAsFixed(1)}%'
            : 'Rs ${value.toStringAsFixed(0)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(label, maxLines: 1, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(display, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _openPricingEditor([RideAdminRecord? record]) async {
    final _PricingDraft draft = _PricingDraft.fromRecord(record);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.65,
          maxChildSize: 0.97,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF151515),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Form(
              key: formKey,
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 30,
                ),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    record == null ? 'Add vehicle pricing' : 'Edit vehicle pricing',
                    style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'All amounts are in Pakistani Rupees.',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 20),
                  _field(draft.vehicleId, 'Vehicle ID', icon: Icons.key_rounded, enabled: record == null, requiredText: true),
                  _field(draft.vehicleName, 'Vehicle display name', icon: Icons.local_taxi_outlined, requiredText: true),
                  _field(draft.baseFare, 'Base fare', icon: Icons.payments_outlined, number: true),
                  _field(draft.perKilometer, 'Rate per kilometer', icon: Icons.route_outlined, number: true),
                  _field(draft.perMinute, 'Rate per minute', icon: Icons.timer_outlined, number: true),
                  _field(draft.minimumFare, 'Minimum fare', icon: Icons.price_check_outlined, number: true),
                  _field(draft.bookingFee, 'Booking fee', icon: Icons.receipt_long_outlined, number: true),
                  _field(draft.taxPercentage, 'Tax percentage', icon: Icons.percent_rounded, number: true, max: 100),
                  _field(draft.commission, 'Admin commission percentage', icon: Icons.account_balance_wallet_outlined, number: true, max: 100),
                  _field(draft.surge, 'Surge multiplier (minimum 1.0)', icon: Icons.trending_up_rounded, number: true, minimum: 1),
                  const SizedBox(height: 4),
                  _toggleTile(
                    title: 'Vehicle service enabled',
                    subtitle: 'OFF hides/disables this vehicle pricing option.',
                    value: draft.isEnabled,
                    onChanged: (value) => setSheetState(() => draft.isEnabled = value),
                  ),
                  _toggleTile(
                    title: 'Surge pricing enabled',
                    subtitle: 'Multiplier applies only when this is ON.',
                    value: draft.surgeEnabled,
                    onChanged: (value) => setSheetState(() => draft.surgeEnabled = value),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              if (formKey.currentState?.validate() != true) return;
                              setSheetState(() => saving = true);
                              try {
                                await _service.updateVehiclePricing(
                                  vehicleId: draft.vehicleId.text.trim(),
                                  pricing: draft.toMap(),
                                  updatedBy: widget.adminId,
                                );
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                if (!mounted) return;
                                _showMessage('Vehicle pricing saved successfully.', success: true);
                              } catch (error) {
                                if (!sheetContext.mounted) return;
                                setSheetState(() => saving = false);
                                if (!mounted) return;
                                _showMessage(_cleanError(error));
                              }
                            },
                      icon: saving
                          ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Saving...' : 'Save Pricing'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _yellow,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: _yellow.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    draft.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required IconData icon,
    bool number = false,
    bool enabled = true,
    bool requiredText = false,
    double minimum = 0,
    double? max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: _yellow),
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          errorMaxLines: 2,
        ),
        validator: (value) {
          final String text = value?.trim() ?? '';
          if (requiredText && text.isEmpty) return '$label is required.';
          if (!number) return null;
          final double? parsed = double.tryParse(text);
          if (parsed == null) return 'Enter a valid number.';
          if (parsed < minimum) return 'Value cannot be below $minimum.';
          if (max != null && parsed > max) return 'Value cannot exceed $max.';
          return null;
        },
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeTrackColor: _yellow, activeThumbColor: Colors.black),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: success ? Colors.green : Colors.redAccent, content: Text(message)),
    );
  }

  static double _surge(RideAdminRecord record) {
    final double value = record.number('surgeMultiplier');
    return value < 1 ? 1 : value;
  }

  static IconData _vehicleIcon(String id) {
    final String value = id.toLowerCase();
    if (value.contains('bike')) return Icons.two_wheeler_rounded;
    if (value.contains('rickshaw')) return Icons.electric_rickshaw_rounded;
    return Icons.local_taxi_rounded;
  }

  static String _title(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static String _date(DateTime value) {
    if (value.year <= 2000) return 'not available';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  static String _cleanError(Object? error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}

class _PricingDraft {
  _PricingDraft({
    required this.vehicleId,
    required this.vehicleName,
    required this.baseFare,
    required this.perKilometer,
    required this.perMinute,
    required this.minimumFare,
    required this.bookingFee,
    required this.taxPercentage,
    required this.commission,
    required this.surge,
    required this.isEnabled,
    required this.surgeEnabled,
  });

  final TextEditingController vehicleId;
  final TextEditingController vehicleName;
  final TextEditingController baseFare;
  final TextEditingController perKilometer;
  final TextEditingController perMinute;
  final TextEditingController minimumFare;
  final TextEditingController bookingFee;
  final TextEditingController taxPercentage;
  final TextEditingController commission;
  final TextEditingController surge;
  bool isEnabled;
  bool surgeEnabled;

  factory _PricingDraft.fromRecord(RideAdminRecord? record) {
    String number(String key, {double fallback = 0}) {
      final double value = record?.number(key) ?? fallback;
      return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
    }
    final String vehicleId = record == null
        ? ''
        : record.text('vehicleId', fallback: record.id);
    final String vehicleName = record == null
        ? ''
        : record.text(
            'vehicleName',
            fallback: record.text('displayName'),
          );
    return _PricingDraft(
      vehicleId: TextEditingController(text: vehicleId),
      vehicleName: TextEditingController(text: vehicleName),
      baseFare: TextEditingController(text: number('baseFare')),
      perKilometer: TextEditingController(text: number('perKilometerRate')),
      perMinute: TextEditingController(text: number('perMinuteRate')),
      minimumFare: TextEditingController(text: number('minimumFare')),
      bookingFee: TextEditingController(text: number('bookingFee')),
      taxPercentage: TextEditingController(text: number('taxPercentage')),
      commission: TextEditingController(text: number('adminCommissionPercentage')),
      surge: TextEditingController(text: number('surgeMultiplier', fallback: 1)),
      isEnabled: record?.boolean('isEnabled', fallback: true) ?? true,
      surgeEnabled: record?.boolean('surgeEnabled') ?? false,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'vehicleName': vehicleName.text.trim(),
        'baseFare': double.parse(baseFare.text.trim()),
        'perKilometerRate': double.parse(perKilometer.text.trim()),
        'perMinuteRate': double.parse(perMinute.text.trim()),
        'minimumFare': double.parse(minimumFare.text.trim()),
        'bookingFee': double.parse(bookingFee.text.trim()),
        'taxPercentage': double.parse(taxPercentage.text.trim()),
        'adminCommissionPercentage': double.parse(commission.text.trim()),
        'surgeMultiplier': double.parse(surge.text.trim()),
        'isEnabled': isEnabled,
        'surgeEnabled': surgeEnabled,
      };

  void dispose() {
    vehicleId.dispose();
    vehicleName.dispose();
    baseFare.dispose();
    perKilometer.dispose();
    perMinute.dispose();
    minimumFare.dispose();
    bookingFee.dispose();
    taxPercentage.dispose();
    commission.dispose();
    surge.dispose();
  }
}

class _EnabledBadge extends StatelessWidget {
  const _EnabledBadge({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color color = enabled ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        enabled ? 'ON' : 'OFF',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

