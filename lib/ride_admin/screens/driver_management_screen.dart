import 'package:flutter/material.dart';

import '../services/ride_admin_service.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({
    super.key,
    this.adminId = 'testing_admin',
  });

  final String adminId;

  @override
  State<DriverManagementScreen> createState() =>
      _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0B0B0B);
  static const Color card = Color(0xFF191919);

  final RideAdminService _service = RideAdminService();
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';
  String _search = '';
  String? _busyDriverId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: background,
        title: const Text(
          'Driver Management',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            _topControls(),
            Expanded(child: _drivers()),
          ],
        ),
      ),
    );
  }

  Widget _topControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 5),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: (String value) {
              setState(() => _search = value.trim().toLowerCase());
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Driver, phone or vehicle...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: yellow),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
              filled: true,
              fillColor: card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _chip('all', 'All'),
                _chip(RideAdminStatus.approved, 'Approved'),
                _chip(RideAdminStatus.suspended, 'Suspended'),
                _chip('online', 'Online'),
                _chip('available', 'Available'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final bool selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: yellow,
        backgroundColor: card,
        side: BorderSide(color: selected ? yellow : Colors.white12),
        showCheckmark: false,
      ),
    );
  }

  Widget _drivers() {
    final String? firestoreStatus = <String>{
      RideAdminStatus.approved,
      RideAdminStatus.suspended,
    }.contains(_filter)
        ? _filter
        : null;
    return StreamBuilder<List<RideAdminRecord>>(
      stream: _service.watchDrivers(status: firestoreStatus),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<RideAdminRecord>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: yellow));
        }
        if (snapshot.hasError) {
          return _message(
            Icons.cloud_off,
            'Drivers could not be loaded',
            _cleanError(snapshot.error!),
          );
        }
        final List<RideAdminRecord> drivers =
            (snapshot.data ?? const <RideAdminRecord>[])
                .where(_matches)
                .toList(growable: false);
        if (drivers.isEmpty) {
          return _message(
            Icons.local_taxi_outlined,
            'No Drivers found',
            'Drivers matching this filter will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          itemCount: drivers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 11),
          itemBuilder: (BuildContext context, int index) =>
              _driverCard(drivers[index]),
        );
      },
    );
  }

  bool _matches(RideAdminRecord driver) {
    if (_filter == 'online' && !driver.boolean('isOnline')) return false;
    if (_filter == 'available' && !driver.boolean('isAvailable')) return false;
    if (_search.isEmpty) return true;
    final String values = <String>[
      driver.id,
      _name(driver),
      _phone(driver),
      driver.text('vehicleType'),
      driver.text('vehicleNumber'),
    ].join(' ').toLowerCase();
    return values.contains(_search);
  }

  Widget _driverCard(RideAdminRecord driver) {
    final bool suspended = _isSuspended(driver);
    final bool online = driver.boolean('isOnline');
    final bool available = driver.boolean('isAvailable');
    final bool busy = _busyDriverId == driver.id;
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: busy ? null : () => _showDriver(driver),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: suspended
                        ? Colors.red.withValues(alpha: 0.15)
                        : yellow.withValues(alpha: 0.16),
                    child: Icon(
                      suspended ? Icons.person_off : Icons.person,
                      color: suspended ? Colors.redAccent : yellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _name(driver),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${driver.text('vehicleType', fallback: 'Vehicle')} • '
                          '${driver.text('vehicleNumber', fallback: 'No number')}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (busy)
                    const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        color: yellow,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    _statusBadge(
                      suspended ? 'SUSPENDED' : 'APPROVED',
                      suspended ? Colors.redAccent : Colors.greenAccent,
                    ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _info(
                      'Connection',
                      online ? 'Online' : 'Offline',
                      online ? Colors.greenAccent : Colors.white54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _info(
                      'Ride status',
                      available ? 'Available' : 'Busy / Offline',
                      available ? Colors.lightBlueAccent : Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _info(
                      'Wallet',
                      'Rs ${_money(driver.number('walletBalance'))}',
                      Colors.lightBlueAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _info(
                      'Commission due',
                      'Rs ${_money(driver.number('outstandingCommission'))}',
                      driver.number('outstandingCommission') > 0
                          ? Colors.orangeAccent
                          : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        value,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900),
      ),
    );
  }

  Future<void> _showDriver(RideAdminRecord driver) async {
    final bool suspended = _isSuspended(driver);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
      ),
      builder: (BuildContext sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _name(driver),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text('Driver ID: ${driver.id}',
                  style: const TextStyle(color: Colors.white38)),
              const SizedBox(height: 18),
              _detail('Phone', _phone(driver)),
              _detail('CNIC', driver.text('cnicNumber')),
              _detail('Vehicle', driver.text('vehicleType')),
              _detail('Vehicle number', driver.text('vehicleNumber')),
              _detail('Address', driver.text('address')),
              _detail('Wallet', 'Rs ${_money(driver.number('walletBalance'))}'),
              _detail(
                'Outstanding commission',
                'Rs ${_money(driver.number('outstandingCommission'))}',
              ),
              if (suspended)
                _detail(
                  'Suspension reason',
                  driver.text('suspensionReason', fallback: 'Not provided'),
                ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => suspended
                    ? _reactivate(sheetContext, driver)
                    : _suspend(sheetContext, driver),
                style: ElevatedButton.styleFrom(
                  backgroundColor: suspended ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                icon: Icon(suspended ? Icons.person_add_alt : Icons.person_off),
                label: Text(
                  suspended ? 'REACTIVATE DRIVER' : 'SUSPEND DRIVER',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _suspend(
    BuildContext sheetContext,
    RideAdminRecord driver,
  ) async {
    final TextEditingController controller = TextEditingController();
    final String? reason = await showDialog<String>(
      context: sheetContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Suspend Driver'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Suspension reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final String value = controller.text.trim();
              if (value.length >= 5) Navigator.pop(dialogContext, value);
            },
            child: const Text('SUSPEND'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    await _changeStatus(driver.id, true, reason);
  }

  Future<void> _reactivate(
    BuildContext sheetContext,
    RideAdminRecord driver,
  ) async {
    Navigator.pop(sheetContext);
    await _changeStatus(driver.id, false, null);
  }

  Future<void> _changeStatus(
    String driverId,
    bool suspended,
    String? reason,
  ) async {
    setState(() => _busyDriverId = driverId);
    try {
      await _service.setDriverSuspended(
        driverId: driverId,
        isSuspended: suspended,
        updatedBy: widget.adminId,
        reason: reason,
      );
      if (!mounted) return;
      _snack(
        suspended ? 'Driver suspended.' : 'Driver reactivated.',
        Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      _snack(_cleanError(error), Colors.red);
    } finally {
      if (mounted) setState(() => _busyDriverId = null);
    }
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 135,
            child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not added' : value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: yellow, size: 48),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  bool _isSuspended(RideAdminRecord driver) =>
      driver.boolean('isSuspended') ||
      driver.text('status').toLowerCase() == RideAdminStatus.suspended;

  String _name(RideAdminRecord driver) => driver.text(
        'fullName',
        fallback: driver.text('name', fallback: 'SWAT RIDE Driver'),
      );

  String _phone(RideAdminRecord driver) => driver.text(
        'phoneNumber',
        fallback: driver.text('phone'),
      );

  String _money(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 2);

  String _cleanError(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('FirebaseException: ', '');

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(backgroundColor: color, content: Text(message)));
  }
}
