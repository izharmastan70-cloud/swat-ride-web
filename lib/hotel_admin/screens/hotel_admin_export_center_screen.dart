import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HotelAdminExportCenterScreen extends StatefulWidget {
  const HotelAdminExportCenterScreen({
    super.key,
    required this.hotelId,
    this.hotelName = 'Hotel',
  });

  final String hotelId;
  final String hotelName;

  @override
  State<HotelAdminExportCenterScreen> createState() =>
      _HotelAdminExportCenterScreenState();
}

class _HotelAdminExportCenterScreenState
    extends State<HotelAdminExportCenterScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedReport = 'bookings';
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isWorking = false;

  final List<String> _reportTypes = const <String>[
    'bookings',
    'revenue',
    'occupancy',
    'invoices',
    'refunds',
    'staff',
    'housekeeping',
    'maintenance',
  ];

  final List<String> _statuses = const <String>[
    'all',
    'pending',
    'confirmed',
    'checked_in',
    'checked_out',
    'completed',
    'cancelled',
    'paid',
    'refunded',
    'open',
    'in_progress',
    'awaiting_inspection',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Export Center',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _headerCard(),
              const SizedBox(height: 18),
              _reportTypeSection(),
              const SizedBox(height: 18),
              _filterSection(),
              const SizedBox(height: 18),
              _exportButtons(),
              const SizedBox(height: 18),
              _noticeCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: yellow.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.file_download_outlined,
              color: yellow,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local Report Export',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.hotelName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hotel ID: ${widget.hotelId}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportTypeSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: _reportTypes.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (
            context,
            index,
          ) {
            final String report =
                _reportTypes[index];

            final bool selected =
                _selectedReport == report;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedReport = report;
                  _selectedStatus = 'all';
                });
              },
              borderRadius:
                  BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: selected
                      ? yellow.withValues(
                          alpha: 0.13,
                        )
                      : darkCard,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? yellow
                        : Colors.white
                            .withValues(
                            alpha: 0.05,
                          ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _reportIcon(report),
                      color: selected
                          ? yellow
                          : Colors.grey,
                      size: 27,
                    ),
                    const Spacer(),
                    Text(
                      _reportLabel(report),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.grey,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _filterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 13),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue:
                _selectedStatus,
            dropdownColor: darkCard,
            decoration:
                const InputDecoration(
              labelText: 'Status Filter',
            ),
            items: _statuses
                .map(
                  (String status) =>
                      DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      _statusLabel(status),
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment:
                Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _selectedStatus = 'all';
                });
              },
              icon: const Icon(
                Icons.refresh,
                color: yellow,
              ),
              label: const Text(
                'Reset Filters',
                style: TextStyle(
                  color: yellow,
                ),
              ),
            ),
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
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: darkBackground,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: yellow,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date == null
                        ? 'All dates'
                        : _formatDate(date),
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Format',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _exportButton(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF Preview / Print',
            subtitle:
                'Generate a printable PDF report',
            onPressed: _exportPdf,
          ),
          const SizedBox(height: 10),
          _exportButton(
            icon: Icons.table_chart_outlined,
            title: 'CSV Export',
            subtitle:
                'Generate comma-separated report data',
            onPressed: _exportCsv,
          ),
          const SizedBox(height: 10),
          _exportButton(
            icon: Icons.grid_on_outlined,
            title: 'Excel-ready Export',
            subtitle:
                'Generate UTF-8 CSV that opens in Excel',
            onPressed: _exportExcelReadyCsv,
          ),
        ],
      ),
    );
  }

  Widget _exportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed:
          _isWorking ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: yellow,
        side: const BorderSide(
          color: yellow,
        ),
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: yellow,
            size: 27,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (_isWorking)
            const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: yellow,
              ),
            )
          else
            const Icon(
              Icons.arrow_forward_ios,
              color: yellow,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _noticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Reports are generated locally from Firestore records. Firebase Storage is not required. The Excel-ready option creates a UTF-8 CSV file that Microsoft Excel can open directly.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    await _runExport(
      action: () async {
        final _ExportTable table =
            await _loadSelectedReport();

        final Uint8List pdf =
            await _buildPdf(table);

        await Printing.layoutPdf(
          onLayout:
              (PdfPageFormat format) async =>
                  pdf,
          name:
              '${_selectedReport}_${widget.hotelId}.pdf',
        );

        await _saveAudit(
          format: 'pdf',
          rowCount: table.rows.length,
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    await _runExport(
      action: () async {
        final _ExportTable table =
            await _loadSelectedReport();

        final String csv =
            _buildCsv(table);

        await Printing.sharePdf(
          bytes:
              Uint8List.fromList(
            utf8.encode(csv),
          ),
          filename:
              '${_selectedReport}_${widget.hotelId}.csv',
        );

        await _saveAudit(
          format: 'csv',
          rowCount: table.rows.length,
        );
      },
    );
  }

  Future<void> _exportExcelReadyCsv() async {
    await _runExport(
      action: () async {
        final _ExportTable table =
            await _loadSelectedReport();

        final String csv =
            '\uFEFF${_buildCsv(table)}';

        await Printing.sharePdf(
          bytes:
              Uint8List.fromList(
            utf8.encode(csv),
          ),
          filename:
              '${_selectedReport}_${widget.hotelId}_excel.csv',
        );

        await _saveAudit(
          format: 'excel_ready_csv',
          rowCount: table.rows.length,
        );
      },
    );
  }

  Future<void> _runExport({
    required Future<void> Function() action,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await action();

      _showMessage(
        'Report generated successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to generate report: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<_ExportTable>
      _loadSelectedReport() async {
    switch (_selectedReport) {
      case 'bookings':
        return _loadBookingsReport();
      case 'revenue':
        return _loadRevenueReport();
      case 'occupancy':
        return _loadOccupancyReport();
      case 'invoices':
        return _loadInvoicesReport();
      case 'refunds':
        return _loadRefundsReport();
      case 'staff':
        return _loadStaffReport();
      case 'housekeeping':
        return _loadHousekeepingReport();
      case 'maintenance':
        return _loadMaintenanceReport();
      default:
        throw Exception(
          'Unsupported report type.',
        );
    }
  }

  Future<_ExportTable>
      _loadBookingsReport() async {
    final documents =
        await _loadCollection(
      collection: 'hotel_bookings',
      dateField: 'createdAt',
      statusField: 'bookingStatus',
    );

    return _ExportTable(
      title: 'Hotel Booking Report',
      headers: const <String>[
        'Booking ID',
        'Guest',
        'Phone',
        'Room',
        'Check-in',
        'Check-out',
        'Nights',
        'Status',
        'Payment',
        'Total',
      ],
      rows: documents.map(
        (Map<String, dynamic> data) {
          return <String>[
            data['bookingId']?.toString() ??
                data['id']?.toString() ??
                '',
            data['guestName']?.toString() ??
                '',
            data['guestPhone']?.toString() ??
                '',
            data['roomName']?.toString() ??
                '',
            _formatDynamicDate(
              data['checkIn'],
            ),
            _formatDynamicDate(
              data['checkOut'],
            ),
            data['nights']?.toString() ??
                '',
            data['bookingStatus']
                    ?.toString() ??
                '',
            data['paymentStatus']
                    ?.toString() ??
                '',
            _money(
              _readDouble(
                data['totalAmount'],
              ),
            ),
          ];
        },
      ).toList(),
    );
  }

  Future<_ExportTable>
      _loadRevenueReport() async {
    final documents =
        await _loadCollection(
      collection: 'hotel_bookings',
      dateField: 'createdAt',
      statusField: 'bookingStatus',
    );

    return _ExportTable(
      title: 'Hotel Revenue Report',
      headers: const <String>[
        'Booking ID',
        'Guest',
        'Date',
        'Gross Amount',
        'Paid',
        'Remaining',
        'Refund',
        'Payment Method',
        'Payment Status',
      ],
      rows: documents.map(
        (Map<String, dynamic> data) {
          final double total =
              _readDouble(
            data['totalAmount'],
          );

          final double paid =
              _readDouble(
            data['paidAmount'],
          );

          final double remaining =
              _readDouble(
            data['remainingAmount'],
            fallback:
                total - paid > 0
                    ? total - paid
                    : 0,
          );

          return <String>[
            data['bookingId']?.toString() ??
                data['id']?.toString() ??
                '',
            data['guestName']?.toString() ??
                '',
            _formatDynamicDate(
              data['createdAt'],
            ),
            _money(total),
            _money(paid),
            _money(remaining),
            _money(
              _readDouble(
                data['refundAmount'],
              ),
            ),
            data['paymentMethod']
                    ?.toString() ??
                '',
            data['paymentStatus']
                    ?.toString() ??
                '',
          ];
        },
      ).toList(),
    );
  }

  Future<_ExportTable>
      _loadOccupancyReport() async {
    final documents =
        await _loadCollection(
      collection: 'hotel_rooms',
      dateField: 'updatedAt',
      statusField: 'manualStatus',
    );

    return _ExportTable(
      title: 'Hotel Occupancy Report',
      headers: const <String>[
        'Room ID',
        'Room Number',
        'Room Name',
        'Manual Status',
        'Housekeeping',
        'Quantity',
        'Available Quantity',
        'Updated',
      ],
      rows: documents.map(
        (Map<String, dynamic> data) {
          return <String>[
            data['roomId']?.toString() ??
                data['id']?.toString() ??
                '',
            data['roomNumber']
                    ?.toString() ??
                '',
            data['roomName']?.toString() ??
                data['name']?.toString() ??
                '',
            data['manualStatus']
                    ?.toString() ??
                data['status']?.toString() ??
                '',
            data['housekeepingStatus']
                    ?.toString() ??
                '',
            data['quantity']?.toString() ??
                '',
            data['availableQuantity']
                    ?.toString() ??
                '',
            _formatDynamicDate(
              data['updatedAt'],
            ),
          ];
        },
      ).toList(),
    );
  }

  Future<_ExportTable>
      _loadInvoicesReport() async {
    final documents =
        await _loadCollection(
      collection: 'hotel_bookings',
      dateField: 'createdAt',
      statusField: 'invoiceStatus',
    );

    return _ExportTable(
      title: 'Hotel Invoice Report',
      headers: const <String>[
        'Invoice Number',
        'Booking ID',
        'Guest',
        'Invoice Status',
        'Payment Status',
        'Total',
        'Paid',
        'Remaining',
        'Refund',
      ],
      rows: documents.map(
        (Map<String, dynamic> data) {
          final double total =
              _readDouble(
            data['totalAmount'],
          );

          final double paid =
              _readDouble(
            data['paidAmount'],
          );

          return <String>[
            data['invoiceNumber']
                    ?.toString() ??
                '',
            data['bookingId']?.toString() ??
                data['id']?.toString() ??
                '',
            data['guestName']?.toString() ??
                '',
            data['invoiceStatus']
                    ?.toString() ??
                '',
            data['paymentStatus']
                    ?.toString() ??
                '',
            _money(total),
            _money(paid),
            _money(
              _readDouble(
                data['remainingAmount'],
                fallback:
                    total - paid > 0
                        ? total - paid
                        : 0,
              ),
            ),
            _money(
              _readDouble(
                data['refundAmount'],
              ),
            ),
          ];
        },
      ).toList(),
    );
  }

  Future<_ExportTable>
      _loadRefundsReport() async {
    final documents =
        await _loadCollection(
      collection: 'hotel_bookings',
      dateField: 'refundedAt',
      statusField: 'paymentStatus',
    );

    final refunds = documents.where(
      (Map<String, dynamic> data) =>
          _readDouble(
            data['refundAmount'],
          ) >
          0,
    );

    return _ExportTable(
      title: 'Hotel Refund Report',
      headers: const <String>[
        'Booking ID',
        'Invoice Number',
        'Guest',
        'Refund Amount',
        'Refund Reason',
        'Refund Date',
        'Payment Method',
      ],
      rows: refunds.map(
        (Map<String, dynamic> data) {
          return <String>[
            data['bookingId']?.toString() ??
                data['id']?.toString() ??
                '',
            data['invoiceNumber']
                    ?.toString() ??
                '',
            data['guestName']?.toString() ??
                '',
            _money(
              _readDouble(
                data['refundAmount'],
              ),
            ),
            data['refundReason']
                    ?.toString() ??
                '',
            _formatDynamicDate(
              data['refundedAt'],
            ),
            data['paymentMethod']
                    ?.toString() ??
                '',
          ];
        },
      ).toList(),
    );
  }

  Future<_ExportTable>
      _loadStaffReport() async {
    final documents =
        await _loadCollection(
      collection: 'hotel_staff',
      dateField: 'updatedAt',
      statusField: 'status',
    );

    return _ExportTable(
      title: 'Hotel Staff Report',
      headers: const <String>[
        'Staff ID',
        'Name',
        'Role',
        'Phone',
        'Email',
        'Status',
        'Permissions',
      ],
      rows: documents.map(
        (Map<String, dynamic> data) {
          return <String>[
            data['staffId']?.toString() ??
                data['id']?.toString() ??
                '',
            data['name']?.toString() ??
                data['staffName']
                    ?.toString() ??
                '',
            data['role']?.toString() ??
                '',
            data['phone']?.toString() ??
                '',
            data['email']?.toString() ??
                '',
            data['status']?.toString() ??
                '',
            _readStringList(
              data['permissions'],
            ).join(' | '),
          ];
        },
      ).toList(),
    );
  }

  Future<_ExportTable>
      _loadHousekeepingReport() async {
    final documents =
        await _loadCollection(
      collection:
          'hotel_housekeeping_inspections',
      dateField: 'createdAt',
      statusField: 'reviewStatus',
    );

    return _ExportTable(
      title: 'Hotel Housekeeping Report',
      headers: const <String>[
        'Inspection ID',
        'Room',
        'Guest Items Found',
        'Hotel Items Missing',
        'Damage Found',
        'Mini-bar Used',
        'Review Status',
        'Date',
      ],
      rows: documents.map(
        (Map<String, dynamic> data) {
          return <String>[
            data['inspectionId']
                    ?.toString() ??
                data['id']?.toString() ??
                '',
            data['roomNumber']
                    ?.toString() ??
                '',
            _yesNo(
              data['guestItemsFound'] ==
                  true,
            ),
            _yesNo(
              data['hotelItemsMissing'] ==
                  true,
            ),
            _yesNo(
              data['damageFound'] == true,
            ),
            _yesNo(
              data['minibarUsed'] == true,
            ),
            data['reviewStatus']
                    ?.toString() ??
                '',
            _formatDynamicDate(
              data['createdAt'],
            ),
          ];
        },
      ).toList(),
    );
  }

  Future<_ExportTable>
      _loadMaintenanceReport() async {
    final documents =
        await _loadCollection(
      collection:
          'hotel_maintenance_tasks',
      dateField: 'createdAt',
      statusField: 'status',
    );

    return _ExportTable(
      title: 'Hotel Maintenance Report',
      headers: const <String>[
        'Task ID',
        'Room',
        'Title',
        'Category',
        'Priority',
        'Status',
        'Technician',
        'Estimated Cost',
        'Final Cost',
        'Due Date',
      ],
      rows: documents.map(
        (Map<String, dynamic> data) {
          return <String>[
            data['taskId']?.toString() ??
                data['id']?.toString() ??
                '',
            data['roomNumber']
                    ?.toString() ??
                '',
            data['title']?.toString() ??
                '',
            data['category']?.toString() ??
                '',
            data['priority']?.toString() ??
                '',
            data['status']?.toString() ??
                '',
            data['assignedTechnicianName']
                    ?.toString() ??
                '',
            _money(
              _readDouble(
                data['estimatedCost'],
              ),
            ),
            _money(
              _readDouble(
                data['finalCost'],
              ),
            ),
            _formatDynamicDate(
              data['dueDate'],
            ),
          ];
        },
      ).toList(),
    );
  }

  Future<List<Map<String, dynamic>>>
      _loadCollection({
    required String collection,
    required String dateField,
    required String statusField,
  }) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(collection)
            .where(
              'hotelId',
              isEqualTo: widget.hotelId,
            )
            .get();

    return snapshot.docs
        .map(
          (
            QueryDocumentSnapshot<
                    Map<String, dynamic>>
                document,
          ) =>
              <String, dynamic>{
            ...document.data(),
            'id': document.id,
          },
        )
        .where(
          (Map<String, dynamic> data) {
            final DateTime date =
                _readDateTime(
              data[dateField],
            );

            if (_startDate != null &&
                date.millisecondsSinceEpoch !=
                    0 &&
                date.isBefore(
                  DateTime(
                    _startDate!.year,
                    _startDate!.month,
                    _startDate!.day,
                  ),
                )) {
              return false;
            }

            if (_endDate != null &&
                date.millisecondsSinceEpoch !=
                    0 &&
                !date.isBefore(
                  DateTime(
                    _endDate!.year,
                    _endDate!.month,
                    _endDate!.day,
                  ).add(
                    const Duration(
                      days: 1,
                    ),
                  ),
                )) {
              return false;
            }

            if (_selectedStatus !=
                'all') {
              final String status =
                  data[statusField]
                          ?.toString() ??
                      '';

              if (status !=
                  _selectedStatus) {
                return false;
              }
            }

            return true;
          },
        )
        .toList();
  }

  Future<Uint8List> _buildPdf(
    _ExportTable table,
  ) async {
    final pw.Document document =
        pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat:
            PdfPageFormat.a4.landscape,
        margin:
            const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'SWAT RIDE',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              widget.hotelName,
              style: const pw.TextStyle(
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              table.title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Generated: ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'Rows: ${table.rows.length}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 14),
            if (table.rows.isEmpty)
              pw.Text(
                'No records matched the selected filters.',
              )
            else
              pw.TableHelper.fromTextArray(
                headers: table.headers,
                data: table.rows,
                headerStyle: pw.TextStyle(
                  fontWeight:
                      pw.FontWeight.bold,
                  fontSize: 7,
                ),
                cellStyle:
                    const pw.TextStyle(
                  fontSize: 6.5,
                ),
                headerDecoration:
                    const pw.BoxDecoration(
                  color:
                      PdfColors.grey300,
                ),
                cellAlignment:
                    pw.Alignment.centerLeft,
              ),
          ];
        },
      ),
    );

    return document.save();
  }

  String _buildCsv(
    _ExportTable table,
  ) {
    final StringBuffer buffer =
        StringBuffer();

    buffer.writeln(
      table.headers
          .map(_escapeCsv)
          .join(','),
    );

    for (final List<String> row
        in table.rows) {
      buffer.writeln(
        row.map(_escapeCsv).join(','),
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(
    String value,
  ) {
    final String escaped =
        value.replaceAll(
      '"',
      '""',
    );

    if (escaped.contains(',') ||
        escaped.contains('\n') ||
        escaped.contains('"')) {
      return '"$escaped"';
    }

    return escaped;
  }

  Future<void> _saveAudit({
    required String format,
    required int rowCount,
  }) async {
    await _firestore
        .collection(
          'hotel_export_audit_logs',
        )
        .add(
      <String, dynamic>{
        'hotelId': widget.hotelId,
        'reportType': _selectedReport,
        'format': format,
        'statusFilter':
            _selectedStatus,
        'startDate': _startDate == null
            ? null
            : Timestamp.fromDate(
                _startDate!,
              ),
        'endDate': _endDate == null
            ? null
            : Timestamp.fromDate(
                _endDate!,
              ),
        'rowCount': rowCount,
        'generatedByRole':
            'hotel_admin',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime now =
        DateTime.now();

    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate:
          _startDate ??
              now.subtract(
                const Duration(days: 30),
              ),
      firstDate: DateTime(
        now.year - 10,
      ),
      lastDate: now.add(
        const Duration(days: 730),
      ),
    );

    if (selected == null ||
        !mounted) {
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
    final DateTime now =
        DateTime.now();

    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate:
          _endDate ?? now,
      firstDate:
          _startDate ??
              DateTime(
                now.year - 10,
              ),
      lastDate: now.add(
        const Duration(days: 730),
      ),
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  IconData _reportIcon(
    String report,
  ) {
    switch (report) {
      case 'bookings':
        return Icons.book_online_outlined;
      case 'revenue':
        return Icons.payments_outlined;
      case 'occupancy':
        return Icons.hotel_outlined;
      case 'invoices':
        return Icons.receipt_long_outlined;
      case 'refunds':
        return Icons.currency_exchange_outlined;
      case 'staff':
        return Icons.groups_outlined;
      case 'housekeeping':
        return Icons.cleaning_services_outlined;
      case 'maintenance':
        return Icons.build_circle_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  String _reportLabel(
    String report,
  ) {
    switch (report) {
      case 'bookings':
        return 'Bookings';
      case 'revenue':
        return 'Revenue';
      case 'occupancy':
        return 'Occupancy';
      case 'invoices':
        return 'Invoices';
      case 'refunds':
        return 'Refunds';
      case 'staff':
        return 'Staff';
      case 'housekeeping':
        return 'Housekeeping';
      case 'maintenance':
        return 'Maintenance';
      default:
        return report;
    }
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'all':
        return 'All';
      case 'checked_in':
        return 'Checked In';
      case 'checked_out':
        return 'Checked Out';
      case 'in_progress':
        return 'In Progress';
      case 'awaiting_inspection':
        return 'Awaiting Inspection';
      default:
        return _capitalize(status);
    }
  }

  List<String> _readStringList(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (dynamic item) =>
                item.toString(),
          )
          .toList();
    }

    return const <String>[];
  }

  DateTime _readDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  double _readDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  String _formatDynamicDate(
    dynamic value,
  ) {
    return _formatDate(
      _readDateTime(value),
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }

    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

    final String month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(
    DateTime date,
  ) {
    final String hour =
        date.hour
            .toString()
            .padLeft(2, '0');

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    return '${_formatDate(date)} $hour:$minute';
  }

  String _money(
    num amount,
  ) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (Match match) => ',',
        );
  }

  String _yesNo(
    bool value,
  ) {
    return value ? 'Yes' : 'No';
  }

  static String _capitalize(
    String value,
  ) {
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
              isError
                  ? Colors.red
                  : darkCard,
        ),
      );
  }
}

class _ExportTable {
  const _ExportTable({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}
