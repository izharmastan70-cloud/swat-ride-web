import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TourismExportCenterScreen extends StatefulWidget {
  const TourismExportCenterScreen({
    super.key,
  });

  @override
  State<TourismExportCenterScreen> createState() =>
      _TourismExportCenterScreenState();
}

class _TourismExportCenterScreenState
    extends State<TourismExportCenterScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedReport = 'tour_bookings';
  String _selectedFormat = 'csv';
  String _selectedStatus = 'all';
  String _searchText = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includeHeaders = true;
  bool _includeInactive = false;
  bool _isGenerating = false;
  String _workingExportId = '';

  CollectionReference<Map<String, dynamic>> get _historyCollection =>
      _firestore.collection('tourism_export_history');

  CollectionReference<Map<String, dynamic>> get _auditCollection =>
      _firestore.collection('tourism_export_audit_logs');

  final List<_ExportReportOption> _reportOptions =
      const <_ExportReportOption>[
    _ExportReportOption(
      key: 'tour_bookings',
      label: 'Tour Bookings',
      collection: 'tour_bookings',
      icon: Icons.book_online_outlined,
    ),
    _ExportReportOption(
      key: 'revenue',
      label: 'Revenue Report',
      collection: 'tour_bookings',
      icon: Icons.payments_outlined,
    ),
    _ExportReportOption(
      key: 'cancellation_refund',
      label: 'Cancellation & Refund',
      collection: 'tour_bookings',
      icon: Icons.currency_exchange_outlined,
    ),
    _ExportReportOption(
      key: 'destination_performance',
      label: 'Destination Performance',
      collection: 'tour_destinations',
      icon: Icons.location_on_outlined,
    ),
    _ExportReportOption(
      key: 'package_performance',
      label: 'Package Performance',
      collection: 'tour_packages',
      icon: Icons.card_travel_outlined,
    ),
    _ExportReportOption(
      key: 'driver_performance',
      label: 'Driver Performance',
      collection: 'tourism_driver_applications',
      icon: Icons.airport_shuttle_outlined,
    ),
    _ExportReportOption(
      key: 'guide_performance',
      label: 'Guide Performance',
      collection: 'tour_guide_applications',
      icon: Icons.person_pin_circle_outlined,
    ),
    _ExportReportOption(
      key: 'vehicle_usage',
      label: 'Vehicle Usage',
      collection: 'tour_vehicles',
      icon: Icons.directions_car_outlined,
    ),
    _ExportReportOption(
      key: 'commission',
      label: 'Commission Report',
      collection: 'tourism_pricing_rules',
      icon: Icons.percent_outlined,
    ),
    _ExportReportOption(
      key: 'tour_hotel',
      label: 'Tour + Hotel Report',
      collection: 'tour_hotel_packages',
      icon: Icons.hotel_class_outlined,
    ),
  ];

  final List<String> _formats = const <String>[
    'csv',
    'excel_csv',
    'pdf_ready',
    'json',
  ];

  final List<String> _statuses = const <String>[
    'all',
    'pending',
    'confirmed',
    'assigned',
    'in_progress',
    'completed',
    'cancelled',
    'refunded',
    'active',
    'inactive',
    'draft',
    'sold_out',
    'approved',
    'rejected',
    'suspended',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tourism Export Center',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            _headerCard(),
            const SizedBox(height: 16),
            _reportSelector(),
            const SizedBox(height: 14),
            _filterSection(),
            const SizedBox(height: 14),
            _formatSection(),
            const SizedBox(height: 14),
            _generateButton(),
            const SizedBox(height: 18),
            _historySection(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: yellow.withValues(alpha: 0.22),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.file_download_outlined,
            color: yellow,
            size: 36,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tourism Reports Export',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Generate CSV, Excel-ready CSV, JSON or PDF-ready text without adding new export libraries.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportSelector() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reportOptions.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) {
              final option = _reportOptions[index];
              final selected = _selectedReport == option.key;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReport = option.key;
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? yellow.withValues(alpha: 0.13)
                        : darkBackground,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: selected
                          ? yellow
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.icon,
                        color: selected ? yellow : Colors.grey,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Text(
                'Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search inside report',
              prefixIcon: const Icon(
                Icons.search,
                color: yellow,
              ),
              suffixIcon: _searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            dropdownColor: darkCard,
            decoration: const InputDecoration(
              labelText: 'Status Filter',
            ),
            items: _statuses
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status == 'all'
                          ? 'All Status'
                          : status
                              .split('_')
                              .map(_capitalize)
                              .join(' '),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dateCard(
                  title: 'Start Date',
                  date: _startDate,
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateCard(
                  title: 'End Date',
                  date: _endDate,
                  onTap: _selectEndDate,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Include Inactive Records',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            subtitle: const Text(
              'Include disabled or archived data where available.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            value: _includeInactive,
            activeThumbColor: yellow,
            onChanged: (value) {
              setState(() {
                _includeInactive = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _dateCard({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: yellow,
              size: 17,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date == null ? 'Not set' : _formatDate(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Text(
                'Export Format',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formats.map((format) {
              final selected =
                  format == _selectedFormat;

              return ChoiceChip(
                selected: selected,
                label: Text(
                  _formatLabel(format),
                ),
                selectedColor:
                    yellow.withValues(alpha: 0.24),
                checkmarkColor: yellow,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedFormat = format;
                  });
                },
              );
            }).toList(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Include Column Headers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            value: _includeHeaders,
            activeThumbColor: yellow,
            onChanged: (value) {
              setState(() {
                _includeHeaders = value;
              });
            },
          ),
          const Text(
            'The generated content can be copied, reviewed and saved through a platform-specific file picker later without changing the report logic.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _generateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGenerating
            ? null
            : _generateExport,
        icon: _isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(
                Icons.file_download_outlined,
              ),
        label: Text(
          _isGenerating
              ? 'Generating Report...'
              : 'Generate Export',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _historySection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Text(
                'Export History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _historyCollection.snapshots(),
            builder: (
              context,
              snapshot,
            ) {
              final docs = snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              docs.sort(
                (a, b) => _readDateTime(
                  b.data()['createdAt'],
                ).compareTo(
                  _readDateTime(
                    a.data()['createdAt'],
                  ),
                ),
              );

              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: yellow,
                    ),
                  ),
                );
              }

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                  child: Center(
                    child: Text(
                      'No exports generated yet.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length > 20 ? 20 : docs.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  return _historyCard(docs[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _historyCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final reportType =
        data['reportType']?.toString() ?? 'tour_bookings';
    final format =
        data['format']?.toString() ?? 'csv';
    final recordCount =
        _readInt(data['recordCount']);
    final createdAt =
        _readDateTime(data['createdAt']);
    final working =
        _workingExportId == document.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: darkBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.description_outlined,
            color: yellow,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reportLabel(reportType),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatLabel(format)} • $recordCount records',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                if (createdAt.millisecondsSinceEpoch != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (working)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: yellow,
              ),
            )
          else
            PopupMenuButton<String>(
              color: darkCard,
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              onSelected: (action) {
                _handleHistoryAction(
                  action: action,
                  document: document,
                );
              },
              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: 'copy',
                  child: Text('Copy Export Content'),
                ),
                PopupMenuItem(
                  value: 'details',
                  child: Text('View Details'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Record'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _generateExport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final option = _reportOptions.firstWhere(
        (item) => item.key == _selectedReport,
      );

      final snapshot =
          await _firestore.collection(option.collection).get();

      final filteredRecords = snapshot.docs.where((document) {
        return _matchesFilters(document.data(), document.id);
      }).map((document) {
        return <String, dynamic>{
          'documentId': document.id,
          ...document.data(),
        };
      }).toList();

      final exportContent = _buildExportContent(
        reportType: _selectedReport,
        format: _selectedFormat,
        records: filteredRecords,
      );

      final exportReference = _historyCollection.doc();

      await exportReference.set(
        <String, dynamic>{
          'exportId': exportReference.id,
          'reportType': _selectedReport,
          'reportLabel': option.label,
          'sourceCollection': option.collection,
          'format': _selectedFormat,
          'statusFilter': _selectedStatus,
          'searchText': _searchText.trim(),
          'startDate': _startDate == null
              ? null
              : Timestamp.fromDate(_startDate!),
          'endDate': _endDate == null
              ? null
              : Timestamp.fromDate(_endDate!),
          'includeHeaders': _includeHeaders,
          'includeInactive': _includeInactive,
          'recordCount': filteredRecords.length,
          'content': exportContent,
          'generatedByRole': 'tourism_admin',
          'fileSavedLocally': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await _auditCollection.add(
        <String, dynamic>{
          'exportId': exportReference.id,
          'action': 'tourism_export_generated',
          'details':
              '${option.label} generated in ${_formatLabel(_selectedFormat)} format with ${filteredRecords.length} records.',
          'performedByRole': 'tourism_admin',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      if (!mounted) {
        return;
      }

      await _showExportPreview(
        title: option.label,
        content: exportContent,
        recordCount: filteredRecords.length,
      );
    } catch (error) {
      _showMessage(
        'Unable to generate export: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  bool _matchesFilters(
    Map<String, dynamic> data,
    String documentId,
  ) {
    if (!_includeInactive) {
      if (data['isActive'] == false ||
          data['isArchived'] == true ||
          data['status']?.toString() == 'inactive') {
        return false;
      }
    }

    if (_selectedStatus != 'all') {
      final normalizedStatus =
          _normalizedStatus(data);

      if (normalizedStatus != _selectedStatus) {
        return false;
      }
    }

    final date = _extractRecordDate(data);

    if (_startDate != null &&
        date.millisecondsSinceEpoch != 0) {
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );

      if (date.isBefore(start)) {
        return false;
      }
    }

    if (_endDate != null &&
        date.millisecondsSinceEpoch != 0) {
      final end = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
      ).add(const Duration(days: 1));

      if (!date.isBefore(end)) {
        return false;
      }
    }

    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    final searchableValues = <String>[
      documentId,
      ...data.values.expand<String>((value) {
        if (value is Iterable) {
          return value.map((item) => item.toString());
        }
        if (value is Map) {
          return value.values.map((item) => item.toString());
        }
        return <String>[value?.toString() ?? ''];
      }),
    ];

    return searchableValues.any(
      (value) => value.toLowerCase().contains(query),
    );
  }

  String _buildExportContent({
    required String reportType,
    required String format,
    required List<Map<String, dynamic>> records,
  }) {
    final processedRecords = records
        .map(
          (record) => _prepareRecordForReport(
            reportType,
            record,
          ),
        )
        .toList();

    switch (format) {
      case 'json':
        return const JsonEncoder.withIndent('  ')
            .convert(processedRecords);
      case 'pdf_ready':
        return _buildPdfReadyText(
          reportType,
          processedRecords,
        );
      case 'excel_csv':
      case 'csv':
      default:
        return _buildCsv(processedRecords);
    }
  }

  Map<String, dynamic> _prepareRecordForReport(
    String reportType,
    Map<String, dynamic> data,
  ) {
    switch (reportType) {
      case 'revenue':
        return <String, dynamic>{
          'bookingId': data['bookingId'] ?? data['documentId'],
          'customerName':
              data['customerName'] ?? data['userName'] ?? '',
          'packageName': data['packageName'] ?? '',
          'status': _normalizedStatus(data),
          'paymentStatus': data['paymentStatus'] ?? '',
          'totalAmount': _readDouble(
            data['totalAmount'] ??
                data['finalPrice'] ??
                data['estimatedPrice'],
          ),
          'paidAmount': _readDouble(data['paidAmount']),
          'remainingAmount': _readDouble(
            data['remainingAmount'],
          ),
          'refundAmount': _readDouble(
            data['refundAmount'],
          ),
          'createdAt': _formatDynamicDate(
            data['createdAt'],
          ),
        };
      case 'cancellation_refund':
        return <String, dynamic>{
          'bookingId': data['bookingId'] ?? data['documentId'],
          'customerName':
              data['customerName'] ?? data['userName'] ?? '',
          'packageName': data['packageName'] ?? '',
          'status': _normalizedStatus(data),
          'cancellationReason':
              data['cancellationReason'] ?? '',
          'refundReason': data['refundReason'] ?? '',
          'refundAmount': _readDouble(
            data['refundAmount'],
          ),
          'cancelledAt': _formatDynamicDate(
            data['cancelledAt'],
          ),
          'refundedAt': _formatDynamicDate(
            data['refundedAt'],
          ),
        };
      case 'destination_performance':
        return <String, dynamic>{
          'destinationId':
              data['destinationId'] ?? data['documentId'],
          'name': data['name'] ?? data['destinationName'] ?? '',
          'category': data['category'] ?? '',
          'isActive': data['isActive'] ?? true,
          'isFeatured': data['isFeatured'] ?? false,
          'popularityScore': data['popularityScore'] ?? 0,
          'aiRecommendationScore':
              data['aiRecommendationScore'] ?? 0,
          'bookingCount': data['bookingCount'] ?? 0,
          'rating': data['averageRating'] ?? 0,
        };
      case 'package_performance':
        return <String, dynamic>{
          'packageId': data['packageId'] ?? data['documentId'],
          'packageName': data['packageName'] ?? '',
          'packageCode': data['packageCode'] ?? '',
          'durationDays': data['durationDays'] ?? 0,
          'adultPrice': data['adultPrice'] ?? 0,
          'childPrice': data['childPrice'] ?? 0,
          'availableSeats': data['availableSeats'] ?? 0,
          'isFeatured': data['isFeatured'] ?? false,
          'isActive': data['isActive'] ?? true,
          'popularityScore': data['popularityScore'] ?? 0,
          'aiMatchScore': data['aiMatchScore'] ?? 0,
        };
      case 'driver_performance':
        return <String, dynamic>{
          'driverId': data['driverId'] ?? data['documentId'],
          'fullName': data['fullName'] ?? data['name'] ?? '',
          'phone': data['phone'] ?? '',
          'status':
              data['applicationStatus'] ?? data['status'] ?? '',
          'isAvailable': data['isAvailable'] ?? false,
          'vehicleType': data['vehicleType'] ?? '',
          'vehicleNumber': data['vehicleNumber'] ?? '',
          'dailyRate': data['dailyRate'] ?? 0,
          'averageRating': data['averageRating'] ?? 0,
          'reviewCount': data['reviewCount'] ?? 0,
          'completedTours': data['completedTours'] ?? 0,
        };
      case 'guide_performance':
        return <String, dynamic>{
          'guideId': data['guideId'] ?? data['documentId'],
          'fullName': data['fullName'] ?? data['name'] ?? '',
          'phone': data['phone'] ?? '',
          'status':
              data['applicationStatus'] ?? data['status'] ?? '',
          'isAvailable': data['isAvailable'] ?? false,
          'languages': _stringifyValue(data['languages']),
          'specializations':
              _stringifyValue(data['specializations']),
          'dailyPrice': data['dailyPrice'] ?? 0,
          'averageRating': data['averageRating'] ?? 0,
          'reviewCount': data['reviewCount'] ?? 0,
          'completedTours': data['completedTours'] ?? 0,
        };
      case 'vehicle_usage':
        return <String, dynamic>{
          'vehicleId': data['vehicleId'] ?? data['documentId'],
          'registrationNumber':
              data['registrationNumber'] ?? '',
          'vehicleType': data['vehicleType'] ?? '',
          'brand': data['brand'] ?? '',
          'model': data['model'] ?? '',
          'status': data['status'] ?? '',
          'isAvailable': data['isAvailable'] ?? false,
          'dailyRate': data['dailyRate'] ?? 0,
          'perKmRate': data['perKmRate'] ?? 0,
          'completedTours': data['completedTours'] ?? 0,
          'maintenanceStatus':
              data['maintenanceStatus'] ?? '',
        };
      case 'commission':
        return <String, dynamic>{
          'pricingRuleId':
              data['pricingRuleId'] ?? data['documentId'],
          'ruleName': data['ruleName'] ?? '',
          'ruleCode': data['ruleCode'] ?? '',
          'ruleType': data['ruleType'] ?? '',
          'targetName': data['targetName'] ?? '',
          'valueType': data['valueType'] ?? '',
          'amount': data['amount'] ?? 0,
          'percentage': data['percentage'] ?? 0,
          'isActive': data['isActive'] ?? true,
          'startDate': _formatDynamicDate(data['startDate']),
          'endDate': _formatDynamicDate(data['endDate']),
        };
      case 'tour_hotel':
        return <String, dynamic>{
          'combinedPackageId':
              data['combinedPackageId'] ?? data['documentId'],
          'packageName': data['packageName'] ?? '',
          'tourPackageName': data['tourPackageName'] ?? '',
          'hotelName': data['hotelName'] ?? '',
          'roomType': data['roomType'] ?? '',
          'nights': data['nights'] ?? 0,
          'rooms': data['rooms'] ?? 0,
          'availableRooms': data['availableRooms'] ?? 0,
          'hotelCost': data['hotelCost'] ?? 0,
          'combinedPrice': data['combinedPrice'] ?? 0,
          'hotelCommissionPercent':
              data['hotelCommissionPercent'] ?? 0,
          'tourismCommissionPercent':
              data['tourismCommissionPercent'] ?? 0,
          'status': data['status'] ?? '',
        };
      case 'tour_bookings':
      default:
        return <String, dynamic>{
          'bookingId': data['bookingId'] ?? data['documentId'],
          'customerName':
              data['customerName'] ?? data['userName'] ?? '',
          'customerPhone': data['customerPhone'] ?? '',
          'packageName': data['packageName'] ?? '',
          'destination':
              data['destinationName'] ?? data['destination'] ?? '',
          'status': _normalizedStatus(data),
          'travellers':
              data['travellers'] ?? data['totalPersons'] ?? 0,
          'driverName': data['driverName'] ?? '',
          'guideName': data['guideName'] ?? '',
          'vehicleName':
              data['vehicleName'] ?? data['vehicleType'] ?? '',
          'paymentStatus': data['paymentStatus'] ?? '',
          'totalAmount': _readDouble(
            data['totalAmount'] ??
                data['finalPrice'] ??
                data['estimatedPrice'],
          ),
          'createdAt': _formatDynamicDate(data['createdAt']),
          'startDate': _formatDynamicDate(
            data['startDate'] ?? data['tourDate'],
          ),
        };
    }
  }

  String _buildCsv(
    List<Map<String, dynamic>> records,
  ) {
    if (records.isEmpty) {
      return _includeHeaders
          ? 'No records found'
          : '';
    }

    final headers = <String>[];

    for (final record in records) {
      for (final key in record.keys) {
        if (!headers.contains(key)) {
          headers.add(key);
        }
      }
    }

    final rows = <String>[];

    if (_includeHeaders) {
      rows.add(
        headers.map(_escapeCsvValue).join(','),
      );
    }

    for (final record in records) {
      rows.add(
        headers
            .map(
              (header) => _escapeCsvValue(
                _stringifyValue(record[header]),
              ),
            )
            .join(','),
      );
    }

    return rows.join('\n');
  }

  String _buildPdfReadyText(
    String reportType,
    List<Map<String, dynamic>> records,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('SWAT RIDE TOURISM REPORT');
    buffer.writeln(_reportLabel(reportType).toUpperCase());
    buffer.writeln('Generated: ${_formatDateTime(DateTime.now())}');
    buffer.writeln('Total Records: ${records.length}');
    buffer.writeln('=' * 60);

    if (records.isEmpty) {
      buffer.writeln('No records found.');
      return buffer.toString();
    }

    for (int i = 0; i < records.length; i++) {
      buffer.writeln();
      buffer.writeln('Record ${i + 1}');
      buffer.writeln('-' * 60);

      for (final entry in records[i].entries) {
        buffer.writeln(
          '${_humanizeKey(entry.key)}: ${_stringifyValue(entry.value)}',
        );
      }
    }

    return buffer.toString();
  }

  Future<void> _showExportPreview({
    required String title,
    required String content,
    required int recordCount,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.preview_outlined,
                        color: yellow,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$recordCount records • ${_formatLabel(_selectedFormat)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      10,
                    ),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: SelectableText(
                          content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    18,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: content),
                        );

                        if (!sheetContext.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(sheetContext)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Export content copied.',
                              ),
                              backgroundColor: darkCard,
                            ),
                          );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text(
                        'Copy Export Content',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleHistoryAction({
    required String action,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) async {
    switch (action) {
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
            text: document.data()['content']?.toString() ?? '',
          ),
        );
        _showMessage('Export content copied.');
        break;
      case 'details':
        await _showHistoryDetails(document);
        break;
      case 'delete':
        await _deleteHistoryRecord(document);
        break;
    }
  }

  Future<void> _showHistoryDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Export Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogDetail(
                  'Report',
                  _reportLabel(
                    data['reportType']?.toString() ??
                        'tour_bookings',
                  ),
                ),
                _dialogDetail(
                  'Format',
                  _formatLabel(
                    data['format']?.toString() ?? 'csv',
                  ),
                ),
                _dialogDetail(
                  'Records',
                  '${_readInt(data['recordCount'])}',
                ),
                _dialogDetail(
                  'Status Filter',
                  data['statusFilter']?.toString() ?? 'all',
                ),
                _dialogDetail(
                  'Search',
                  data['searchText']?.toString() ?? '',
                ),
                _dialogDetail(
                  'Created',
                  _formatDateTime(
                    _readDateTime(data['createdAt']),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogDetail(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: yellow,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHistoryRecord(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: darkCard,
            title: const Text(
              'Delete Export Record',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Delete this export history record and its stored content?',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() {
      _workingExportId = document.id;
    });

    try {
      await document.reference.delete();

      await _auditCollection.add(
        <String, dynamic>{
          'exportId': document.id,
          'action': 'tourism_export_deleted',
          'details':
              'Tourism export history record deleted.',
          'performedByRole': 'tourism_admin',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      _showMessage('Export record deleted.');
    } catch (error) {
      _showMessage(
        'Unable to delete export: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingExportId = '';
        });
      }
    }
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(now.year - 10),
      lastDate: now.add(const Duration(days: 730)),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;

      if (_endDate != null &&
          _endDate!.isBefore(selected)) {
        _endDate = selected;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate:
          _startDate ?? DateTime(now.year - 10),
      lastDate: now.add(const Duration(days: 730)),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  String _normalizedStatus(
    Map<String, dynamic> data,
  ) {
    final raw = data['bookingStatus']?.toString() ??
        data['applicationStatus']?.toString() ??
        data['status']?.toString() ??
        (data['isActive'] == false ? 'inactive' : 'active');

    if (<String>{
      'pending_admin_review',
      'pending_confirmation',
    }.contains(raw)) {
      return 'pending';
    }

    if (<String>{
      'driver_assigned',
      'guide_assigned',
    }.contains(raw)) {
      return 'assigned';
    }

    if (<String>{
      'active',
      'started',
    }.contains(raw)) {
      return 'in_progress';
    }

    if (raw == 'finished') {
      return 'completed';
    }

    return raw;
  }

  DateTime _extractRecordDate(
    Map<String, dynamic> data,
  ) {
    return _readDateTime(
      data['createdAt'] ??
          data['updatedAt'] ??
          data['startDate'] ??
          data['tourDate'] ??
          data['approvedAt'],
    );
  }

  String _escapeCsvValue(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _stringifyValue(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is Timestamp) {
      return _formatDateTime(value.toDate());
    }

    if (value is DateTime) {
      return _formatDateTime(value);
    }

    if (value is Iterable) {
      return value.map(_stringifyValue).join(' | ');
    }

    if (value is Map) {
      return jsonEncode(value);
    }

    return value.toString();
  }

  String _formatDynamicDate(dynamic value) {
    final date = _readDateTime(value);

    if (date.millisecondsSinceEpoch == 0) {
      return '';
    }

    return _formatDateTime(date);
  }

  String _reportLabel(String key) {
    for (final option in _reportOptions) {
      if (option.key == key) {
        return option.label;
      }
    }

    return key
        .split('_')
        .map(_capitalize)
        .join(' ');
  }

  String _formatLabel(String format) {
    switch (format) {
      case 'excel_csv':
        return 'Excel-ready CSV';
      case 'pdf_ready':
        return 'PDF-ready Text';
      case 'json':
        return 'JSON';
      default:
        return 'CSV';
    }
  }

  String _humanizeKey(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split('_')
        .map(_capitalize)
        .join(' ');
  }

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return '';
    }

    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '${_formatDate(date)} $hour:$minute';
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : darkCard,
        ),
      );
  }
}

class _ExportReportOption {
  const _ExportReportOption({
    required this.key,
    required this.label,
    required this.collection,
    required this.icon,
  });

  final String key;
  final String label;
  final String collection;
  final IconData icon;
}
