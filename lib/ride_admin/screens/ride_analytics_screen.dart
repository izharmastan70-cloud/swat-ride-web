import 'package:flutter/material.dart';

import '../models/ride_analytics_summary.dart';
import '../services/ride_analytics_service.dart';

class RideAnalyticsScreen extends StatefulWidget {
  const RideAnalyticsScreen({super.key});

  @override
  State<RideAnalyticsScreen> createState() => _RideAnalyticsScreenState();
}

class _RideAnalyticsScreenState extends State<RideAnalyticsScreen> {
  static const Color _background = Color(0xFF090909);
  static const Color _card = Color(0xFF191919);
  static const Color _yellow = Color(0xFFFFD400);

  final RideAnalyticsService _service = RideAnalyticsService();

  RideAnalyticsPreset _preset = RideAnalyticsPreset.today;

  DateTime? _customStart;
  DateTime? _customEnd;

  RideAnalyticsSummary? _summary;

  bool _loading = true;

  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final RideAnalyticsSummary result;

      switch (_preset) {
        case RideAnalyticsPreset.today:
          result = await _service.getToday();

        case RideAnalyticsPreset.last7Days:
          result = await _service.getLast7Days();

        case RideAnalyticsPreset.last30Days:
          result = await _service.getLast30Days();

        case RideAnalyticsPreset.custom:
          final DateTime? start = _customStart;
          final DateTime? end = _customEnd;

          if (start == null || end == null) {
            throw StateError('Please select both start and end dates.');
          }

          result = await _service.getSummary(
            range: RideAnalyticsDateRange.custom(
              start: start,
              endInclusive: end,
            ),
          );
      }

      if (!mounted) return;

      setState(() {
        _summary = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text(
          'Ride Analytics & Reports',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _filters(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      color: const Color(0xFF121212),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _presetChip(RideAnalyticsPreset.today, 'Today'),
                const SizedBox(width: 8),
                _presetChip(RideAnalyticsPreset.last7Days, '7 Days'),
                const SizedBox(width: 8),
                _presetChip(RideAnalyticsPreset.last30Days, '30 Days'),
                const SizedBox(width: 8),
                _presetChip(RideAnalyticsPreset.custom, 'Custom'),
              ],
            ),
          ),
          if (_preset == RideAnalyticsPreset.custom) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _dateButton(
                    label: 'Start',
                    value: _customStart,
                    onPressed: () => _selectCustomDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateButton(
                    label: 'End',
                    value: _customEnd,
                    onPressed: () => _selectCustomDate(isStart: false),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (_customStart == null || _customEnd == null) {
                            _showMessage(
                              'Select start and end dates.',
                              isError: true,
                            );
                            return;
                          }

                          _load();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'APPLY',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _presetChip(RideAnalyticsPreset preset, String label) {
    final bool selected = _preset == preset;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: _yellow,
      backgroundColor: _card,
      side: BorderSide(color: selected ? _yellow : Colors.white12),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.w800,
      ),
      onSelected: (_) async {
        if (_preset == preset) {
          return;
        }

        setState(() {
          _preset = preset;
        });

        if (preset != RideAnalyticsPreset.custom) {
          await _load();
        }
      },
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? value,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month_outlined, size: 18),
      label: Text(value == null ? label : _formatDate(value)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _errorState();
    }

    final RideAnalyticsSummary? summary = _summary;

    if (summary == null) {
      return const Center(
        child: Text(
          'No analytics available.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 30),
        children: <Widget>[
          _rangeHeader(summary),
          const SizedBox(height: 14),
          _rideStats(summary),
          const SizedBox(height: 14),
          _moneyStats(summary),
          const SizedBox(height: 14),
          _rateStats(summary),
          const SizedBox(height: 14),
          _bucketSection(
            title: 'Payment Methods',
            icon: Icons.payments_outlined,
            data: summary.paymentMethodBreakdown,
          ),
          const SizedBox(height: 14),
          _bucketSection(
            title: 'Vehicle Categories',
            icon: Icons.directions_car_outlined,
            data: summary.vehicleCategoryBreakdown,
          ),
          const SizedBox(height: 14),
          _countSection(
            title: 'Cancellation Statistics',
            icon: Icons.cancel_outlined,
            data: summary.cancellationBreakdown,
            emptyText: 'No cancellations in this period.',
          ),
          const SizedBox(height: 14),
          _driverActivity(summary),
          const SizedBox(height: 14),
          _exportReady(summary),
        ],
      ),
    );
  }

  Widget _rangeHeader(RideAnalyticsSummary summary) {
    final DateTime inclusiveEnd = summary.endDate.subtract(
      const Duration(days: 1),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.analytics_outlined, color: _yellow),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Analytics Period',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(summary.startDate)} → ${_formatDate(inclusiveEnd)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideStats(RideAnalyticsSummary summary) {
    return _section(
      title: 'Ride Activity',
      icon: Icons.local_taxi_outlined,
      children: <Widget>[
        _metricGrid(<_MetricData>[
          _MetricData('Total', '${summary.totalRides}', Icons.list_alt_rounded),
          _MetricData(
            'Completed',
            '${summary.completedRides}',
            Icons.check_circle_outline,
          ),
          _MetricData(
            'Cancelled',
            '${summary.cancelledRides}',
            Icons.cancel_outlined,
          ),
          _MetricData('Active', '${summary.activeRides}', Icons.route_outlined),
          _MetricData(
            'Searching',
            '${summary.searchingRides}',
            Icons.search_rounded,
          ),
          _MetricData(
            'Active Drivers',
            '${summary.uniqueActiveDrivers}',
            Icons.person_pin_circle_outlined,
          ),
        ]),
      ],
    );
  }

  Widget _moneyStats(RideAnalyticsSummary summary) {
    return _section(
      title: 'Financial Summary',
      icon: Icons.account_balance_wallet_outlined,
      children: <Widget>[
        _moneyRow('Gross booking value', summary.grossBookingValue),
        _moneyRow('Platform commission', summary.platformCommission),
        _moneyRow('Driver earnings', summary.driverEarnings),
        _moneyRow('Average completed fare', summary.averageCompletedFare),
      ],
    );
  }

  Widget _rateStats(RideAnalyticsSummary summary) {
    return _section(
      title: 'Performance',
      icon: Icons.speed_outlined,
      children: <Widget>[
        _progressRow('Completion rate', summary.completionRate),
        const SizedBox(height: 12),
        _progressRow('Cancellation rate', summary.cancellationRate),
      ],
    );
  }

  Widget _bucketSection({
    required String title,
    required IconData icon,
    required Map<String, RideAnalyticsBucket> data,
  }) {
    final List<MapEntry<String, RideAnalyticsBucket>> entries =
        data.entries.toList()..sort(
          (
            MapEntry<String, RideAnalyticsBucket> a,
            MapEntry<String, RideAnalyticsBucket> b,
          ) => b.value.count.compareTo(a.value.count),
        );

    return _section(
      title: title,
      icon: icon,
      children: entries.isEmpty
          ? const <Widget>[
              Text(
                'No completed ride data for this period.',
                style: TextStyle(color: Colors.white54),
              ),
            ]
          : entries
                .map(
                  (MapEntry<String, RideAnalyticsBucket> entry) =>
                      _breakdownRow(
                        label: _title(entry.key),
                        count: entry.value.count,
                        amount: entry.value.amount,
                      ),
                )
                .toList(),
    );
  }

  Widget _countSection({
    required String title,
    required IconData icon,
    required Map<String, int> data,
    required String emptyText,
  }) {
    final List<MapEntry<String, int>> entries = data.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );

    return _section(
      title: title,
      icon: icon,
      children: entries.isEmpty
          ? <Widget>[
              Text(emptyText, style: const TextStyle(color: Colors.white54)),
            ]
          : entries
                .map(
                  (MapEntry<String, int> entry) =>
                      _simpleCountRow(_title(entry.key), entry.value),
                )
                .toList(),
    );
  }

  Widget _driverActivity(RideAnalyticsSummary summary) {
    final List<MapEntry<String, int>> entries =
        summary.driverRideBreakdown.entries.toList()..sort(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              b.value.compareTo(a.value),
        );

    final List<MapEntry<String, int>> top = entries.take(10).toList();

    return _section(
      title: 'Driver Activity',
      icon: Icons.badge_outlined,
      children: top.isEmpty
          ? const <Widget>[
              Text(
                'No completed Driver activity for this period.',
                style: TextStyle(color: Colors.white54),
              ),
            ]
          : top
                .map(
                  (MapEntry<String, int> entry) => _simpleCountRow(
                    _shortId(entry.key),
                    entry.value,
                    suffix: 'completed rides',
                  ),
                )
                .toList(),
    );
  }

  Widget _exportReady(RideAnalyticsSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.file_download_outlined,
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Export / AI reporting ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Structured report contains ${summary.totalRides} rides and can be exported later through CSV/PDF or passed to the future AI reporting layer.',
                  style: const TextStyle(color: Colors.white60, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: _yellow, size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _metricGrid(List<_MetricData> items) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 650 ? 3 : 2;

        final double width =
            (constraints.maxWidth - ((columns - 1) * 10)) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (_MetricData item) =>
                    SizedBox(width: width, child: _metricCard(item)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _metricCard(_MetricData item) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(item.icon, color: Colors.white54, size: 20),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white60)),
          ),
          Text(
            'Rs ${value.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressRow(String label, double value) {
    final double normalized = value.clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white60)),
            ),
            Text(
              '${(normalized * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: normalized,
          minHeight: 7,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }

  Widget _breakdownRow({
    required String label,
    required int count,
    required double amount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text('$count rides', style: const TextStyle(color: Colors.white54)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              'Rs ${amount.toStringAsFixed(0)}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleCountRow(String label, int count, {String suffix = 'rides'}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            '$count $suffix',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load Ride analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomDate({required bool isStart}) async {
    final DateTime now = DateTime.now();

    final DateTime initial = isStart ? _customStart ?? now : _customEnd ?? now;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        _customStart = selected;

        if (_customEnd != null && _customEnd!.isBefore(selected)) {
          _customEnd = selected;
        }
      } else {
        _customEnd = selected;

        if (_customStart != null && selected.isBefore(_customStart!)) {
          _customStart = selected;
        }
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');

    final String month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  String _title(String value) {
    if (value.trim().isEmpty) {
      return 'Unknown';
    }

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _shortId(String value) {
    if (value.length <= 14) {
      return value;
    }

    return '${value.substring(0, 7)}…${value.substring(value.length - 5)}';
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
