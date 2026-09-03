import 'package:flutter/material.dart';

import '../services/ride_admin_service.dart';

class DriverApplicationManagementScreen extends StatefulWidget {
  const DriverApplicationManagementScreen({
    super.key,
    this.adminId = 'testing_admin',
    this.adminName = 'SWAT RIDE Admin',
  });

  final String adminId;
  final String adminName;

  @override
  State<DriverApplicationManagementScreen> createState() =>
      _DriverApplicationManagementScreenState();
}

class _DriverApplicationManagementScreenState
    extends State<DriverApplicationManagementScreen> {
  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _background = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF191919);

  final RideAdminService _service = RideAdminService();
  final TextEditingController _searchController = TextEditingController();

  String _filter = RideAdminStatus.pending;
  String _search = '';
  String? _busyApplicationId;

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
        backgroundColor: _background,
        surfaceTintColor: _background,
        title: const Text(
          'Driver Applications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _yellow.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  widget.adminName,
                  style: const TextStyle(
                    color: _yellow,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            _header(),
            _filters(),
            Expanded(child: _applicationList()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF30290B), Color(0xFF171717)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _yellow.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 23,
                  backgroundColor: _yellow,
                  child: Icon(Icons.badge_outlined, color: Colors.black),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Normal Ride Drivers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Review documents before approving an account.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (String value) {
              setState(() => _search = value.trim().toLowerCase());
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search name, phone, CNIC or vehicle...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: _yellow),
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

  Widget _filters() {
    const List<MapEntry<String, String>> filters =
        <MapEntry<String, String>>[
      MapEntry<String, String>(RideAdminStatus.pending, 'Pending'),
      MapEntry<String, String>('all', 'All'),
      MapEntry<String, String>(RideAdminStatus.approved, 'Approved'),
      MapEntry<String, String>(RideAdminStatus.rejected, 'Rejected'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final MapEntry<String, String> item = filters[index];
          final bool selected = _filter == item.key;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => setState(() => _filter = item.key),
            label: Text(item.value),
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: _yellow,
            backgroundColor: _card,
            side: BorderSide(
              color: selected ? _yellow : Colors.white12,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _applicationList() {
    return StreamBuilder<List<RideAdminRecord>>(
      stream: _service.watchDriverApplications(status: _filter),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<RideAdminRecord>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _yellow),
          );
        }
        if (snapshot.hasError) {
          return _message(
            Icons.cloud_off,
            'Applications could not be loaded',
            _cleanError(snapshot.error!),
          );
        }

        final List<RideAdminRecord> applications =
            (snapshot.data ?? const <RideAdminRecord>[])
                .where(_matchesSearch)
                .toList(growable: false);
        if (applications.isEmpty) {
          return _message(
            Icons.assignment_outlined,
            'No applications found',
            _search.isEmpty
                ? 'Applications matching this status will appear here.'
                : 'Try a different search term.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          itemCount: applications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 11),
          itemBuilder: (BuildContext context, int index) {
            return _applicationCard(applications[index]);
          },
        );
      },
    );
  }

  bool _matchesSearch(RideAdminRecord application) {
    if (_search.isEmpty) return true;
    final String searchable = <String>[
      application.id,
      _name(application),
      _phone(application),
      _cnic(application),
      application.text('vehicleType'),
      application.text('vehicleNumber'),
    ].join(' ').toLowerCase();
    return searchable.contains(_search);
  }

  Widget _applicationCard(RideAdminRecord application) {
    final String status = application.text(
      'status',
      fallback: RideAdminStatus.pending,
    );
    final Color statusColor = _statusColor(status);
    final bool busy = _busyApplicationId == application.id;

    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: busy ? null : () => _showDetails(application),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  _driverPhoto(application),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _name(application),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${application.text('vehicleType', fallback: 'Vehicle')} • ${application.text('vehicleNumber', fallback: 'No number')}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _smallInfo(Icons.phone_outlined, _phone(application)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _smallInfo(Icons.credit_card, _cnic(application)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Text(
                    _date(application.createdAt),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const Spacer(),
                  if (busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: _yellow,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Row(
                      children: <Widget>[
                        Text(
                          'Review',
                          style: TextStyle(
                            color: _yellow,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, color: _yellow, size: 13),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _driverPhoto(RideAdminRecord application) {
    final String url = _documentUrl(application, 'driverPhoto');
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 54,
        color: Colors.white10,
        child: url.isEmpty
            ? const Icon(Icons.person, color: Colors.white38, size: 31)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.person,
                  color: Colors.white38,
                  size: 31,
                ),
              ),
      ),
    );
  }

  Widget _smallInfo(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: _yellow, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not added' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(RideAdminRecord application) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (BuildContext context, ScrollController controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 45,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      _driverPhoto(application),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _name(application),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Application ID: ${application.id}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('Driver information'),
                  _detailRow('Phone', _phone(application)),
                  _detailRow('CNIC', _cnic(application)),
                  _detailRow('Address', application.text('address')),
                  _detailRow('Vehicle type', application.text('vehicleType')),
                  _detailRow(
                    'Vehicle number',
                    application.text('vehicleNumber'),
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('Documents'),
                  _documents(application),
                  const SizedBox(height: 18),
                  _sectionTitle('Admin decision'),
                  _actionButtons(sheetContext, application),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _documents(RideAdminRecord application) {
    const List<MapEntry<String, String>> documentTypes =
        <MapEntry<String, String>>[
      MapEntry<String, String>('cnicFront', 'CNIC Front'),
      MapEntry<String, String>('cnicBack', 'CNIC Back'),
      MapEntry<String, String>('drivingLicenseFront', 'License Front'),
      MapEntry<String, String>('drivingLicenseBack', 'License Back'),
      MapEntry<String, String>('vehicleRegistration', 'Registration'),
      MapEntry<String, String>('vehiclePhoto', 'Vehicle Photo'),
      MapEntry<String, String>('driverPhoto', 'Driver Photo'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documentTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, String> item = documentTypes[index];
        final String url = _documentUrl(application, item.key);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (url.isNotEmpty)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white24),
                  ),
                )
              else
                const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white24),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(7),
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Text(
                    item.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionButtons(
    BuildContext sheetContext,
    RideAdminRecord application,
  ) {
    final String status = application.text(
      'status',
      fallback: RideAdminStatus.pending,
    );
    if (status == RideAdminStatus.approved) {
      return _decisionNotice(
        Icons.verified,
        Colors.greenAccent,
        'Application approved and Driver account created.',
      );
    }
    if (status == RideAdminStatus.rejected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _decisionNotice(
            Icons.cancel_outlined,
            Colors.redAccent,
            _rejectionReason(application),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _reset(sheetContext, application),
            icon: const Icon(Icons.restart_alt),
            label: const Text('RESET TO PENDING'),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _reject(sheetContext, application),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.close),
            label: const Text('REJECT'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approve(sheetContext, application),
            style: ElevatedButton.styleFrom(
              backgroundColor: _yellow,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.check),
            label: const Text(
              'APPROVE',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approve(
    BuildContext sheetContext,
    RideAdminRecord application,
  ) async {
    final bool confirmed = await _confirm(
      sheetContext,
      title: 'Approve Driver?',
      message: 'This will create an approved Driver account for '
          '${_name(application)}.',
      confirmLabel: 'APPROVE',
    );
    if (!confirmed || !sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    await _runAction(
      application.id,
      () => _service.approveDriverApplication(
        applicationId: application.id,
        reviewedBy: widget.adminId,
        adminNote: 'Approved by ${widget.adminName}',
      ),
      'Driver application approved.',
    );
  }

  Future<void> _reject(
    BuildContext sheetContext,
    RideAdminRecord application,
  ) async {
    final TextEditingController reasonController = TextEditingController();
    final String? reason = await showDialog<String>(
      context: sheetContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Reject Driver Application'),
        content: TextField(
          controller: reasonController,
          minLines: 3,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            hintText: 'Explain what the Driver must correct...',
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
              final String value = reasonController.text.trim();
              if (value.length < 5) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    await _runAction(
      application.id,
      () => _service.rejectDriverApplication(
        applicationId: application.id,
        reviewedBy: widget.adminId,
        rejectionReason: reason,
      ),
      'Driver application rejected.',
    );
  }

  Future<void> _reset(
    BuildContext sheetContext,
    RideAdminRecord application,
  ) async {
    final bool confirmed = await _confirm(
      sheetContext,
      title: 'Reset Application?',
      message: 'This application will return to the Pending list.',
      confirmLabel: 'RESET',
    );
    if (!confirmed || !sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    await _runAction(
      application.id,
      () => _service.resetDriverApplication(
        applicationId: application.id,
        reviewedBy: widget.adminId,
      ),
      'Application returned to pending.',
    );
  }

  Future<void> _runAction(
    String applicationId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyApplicationId = applicationId);
    try {
      await action();
      if (!mounted) return;
      _snack(successMessage, Colors.green);
    } catch (error) {
      if (!mounted) return;
      _snack(_cleanError(error), Colors.red);
    } finally {
      if (mounted) setState(() => _busyApplicationId = null);
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('CANCEL'),
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

  Widget _decisionNotice(IconData icon, Color color, String message) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _yellow,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
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
            Icon(icon, color: _yellow, size: 48),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _name(RideAdminRecord item) => item.text(
        'fullName',
        fallback: item.text('name', fallback: 'Unnamed Driver'),
      );

  String _phone(RideAdminRecord item) => item.text(
        'phoneNumber',
        fallback: item.text('phone'),
      );

  String _cnic(RideAdminRecord item) => item.text(
        'cnicNumber',
        fallback: item.text('cnic'),
      );

  String _documentUrl(RideAdminRecord item, String key) {
    final dynamic value = item.map('documents')[key];
    if (value is String) return value.trim();
    if (value is Map) {
      return (value['downloadUrl'] ?? value['url'] ?? '').toString().trim();
    }
    return '';
  }

  String _rejectionReason(RideAdminRecord application) {
    final String direct = application.text('rejectionReason');
    if (direct.isNotEmpty) return direct;
    final String nested =
        application.map('adminReview')['rejectionReason']?.toString().trim() ??
            '';
    return nested.isEmpty ? 'Application rejected by Admin.' : nested;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case RideAdminStatus.approved:
        return Colors.greenAccent;
      case RideAdminStatus.rejected:
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  String _date(DateTime date) {
    if (date.year <= 2000) return 'Date pending';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '');
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(backgroundColor: color, content: Text(message)),
      );
  }
}
