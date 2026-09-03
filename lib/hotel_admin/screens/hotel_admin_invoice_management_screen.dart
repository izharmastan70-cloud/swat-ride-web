import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../screens/hotel_invoice_screen.dart';

class HotelAdminInvoiceManagementScreen
    extends StatefulWidget {
  const HotelAdminInvoiceManagementScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAdminInvoiceManagementScreen>
      createState() =>
          _HotelAdminInvoiceManagementScreenState();
}

class _HotelAdminInvoiceManagementScreenState
    extends State<HotelAdminInvoiceManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'all';
  String _searchText = '';
  bool _showArchived = false;
  String _workingInvoiceId = '';

  CollectionReference<Map<String, dynamic>>
      get _bookingsCollection =>
          _firestore.collection(
            'hotel_bookings',
          );

  CollectionReference<Map<String, dynamic>>
      get _auditCollection =>
          _firestore.collection(
            'hotel_invoice_audit_logs',
          );

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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Invoice Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Invoice settings',
            onPressed: _openInvoiceSettings,
            icon: const Icon(
              Icons.settings_outlined,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _bookingsCollection
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<
                        Map<String, dynamic>>>
                snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title:
                    'Unable to Load Invoices',
                message:
                    snapshot.error.toString(),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                allDocuments =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                visibleDocuments =
                allDocuments.where(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    document,
              ) {
                final Map<String, dynamic>
                    data = document.data();

                final bool archived =
                    data['invoiceArchived'] ==
                        true;

                if (!_showArchived &&
                    archived) {
                  return false;
                }

                if (_showArchived &&
                    !archived) {
                  return false;
                }

                final String status =
                    _invoiceStatus(data);

                if (_selectedStatus !=
                        'all' &&
                    status !=
                        _selectedStatus) {
                  return false;
                }

                final String query =
                    _searchText
                        .trim()
                        .toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                final List<String> values =
                    <String>[
                  data['invoiceNumber']
                          ?.toString() ??
                      '',
                  data['bookingId']
                          ?.toString() ??
                      document.id,
                  data['guestName']
                          ?.toString() ??
                      '',
                  data['guestPhone']
                          ?.toString() ??
                      '',
                  data['roomName']
                          ?.toString() ??
                      '',
                  data['roomNumber']
                          ?.toString() ??
                      '',
                ];

                return values.any(
                  (String value) =>
                      value
                          .toLowerCase()
                          .contains(query),
                );
              },
            ).toList();

            visibleDocuments.sort(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    a,
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    b,
              ) =>
                  _readDateTime(
                    b.data()['updatedAt'] ??
                        b.data()['createdAt'],
                  ).compareTo(
                    _readDateTime(
                      a.data()['updatedAt'] ??
                          a.data()['createdAt'],
                    ),
                  ),
            );

            return Column(
              children: [
                _summaryHeader(
                  allDocuments,
                ),
                _searchBox(),
                _statusFilters(),
                _archiveSwitch(),
                Expanded(
                  child:
                      visibleDocuments.isEmpty
                          ? _messageState(
                              icon: _showArchived
                                  ? Icons
                                      .archive_outlined
                                  : Icons
                                      .receipt_long_outlined,
                              title:
                                  'No Invoices Found',
                              message:
                                  'No invoice matches the selected search and filter.',
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets
                                      .fromLTRB(
                                16,
                                8,
                                16,
                                24,
                              ),
                              itemCount:
                                  visibleDocuments
                                      .length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                return _invoiceCard(
                                  visibleDocuments[
                                      index],
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryHeader(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    int pending = 0;
    int paid = 0;
    int refunded = 0;
    int voided = 0;

    for (final document in documents) {
      final String status =
          _invoiceStatus(
        document.data(),
      );

      switch (status) {
        case 'paid':
          paid++;
          break;
        case 'refunded':
          refunded++;
          break;
        case 'voided':
          voided++;
          break;
        default:
          pending++;
      }
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        8,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          _summaryItem(
            'Pending',
            pending,
            Colors.orange,
          ),
          _summaryItem(
            'Paid',
            paid,
            Colors.green,
          ),
          _summaryItem(
            'Refunded',
            refunded,
            Colors.blue,
          ),
          _summaryItem(
            'Voided',
            voided,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      child: TextField(
        controller:
            _searchController,
        onChanged: (String value) {
          setState(() {
            _searchText = value;
          });
        },
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText:
              'Search invoice, booking, guest or room...',
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: yellow,
          ),
          suffixIcon:
              _searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                    ),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _statusFilters() {
    const List<String> statuses =
        <String>[
      'all',
      'draft',
      'pending',
      'paid',
      'refunded',
      'cancelled',
      'voided',
    ];

    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (
          context,
          index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          context,
          index,
        ) {
          final String status =
              statuses[index];

          final bool selected =
              _selectedStatus ==
                  status;

          return ChoiceChip(
            selected: selected,
            label: Text(
              _statusLabel(status),
            ),
            selectedColor:
                yellow.withValues(
              alpha: 0.24,
            ),
            checkmarkColor: yellow,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.grey,
              fontWeight:
                  FontWeight.bold,
            ),
            onSelected: (_) {
              setState(() {
                _selectedStatus =
                    status;
              });
            },
          );
        },
      ),
    );
  }

  Widget _archiveSwitch() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.archive_outlined,
            color: yellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Show archived invoices',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Switch(
            value: _showArchived,
            activeThumbColor: yellow,
            onChanged: (bool value) {
              setState(() {
                _showArchived = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _invoiceCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String bookingId =
        data['bookingId']?.toString() ??
            document.id;

    final String invoiceNumber =
        data['invoiceNumber']?.toString() ??
            _fallbackInvoiceNumber(
              bookingId,
            );

    final String guestName =
        data['guestName']?.toString() ??
            'Guest';

    final String roomName =
        data['roomName']?.toString() ??
            'Room';

    final String roomNumber =
        data['roomNumber']?.toString() ??
            '';

    final String status =
        _invoiceStatus(data);

    final double totalAmount =
        _readDouble(
      data['totalAmount'],
    );

    final double paidAmount =
        _readDouble(
      data['paidAmount'],
    );

    final double remainingAmount =
        _readDouble(
      data['remainingAmount'],
      fallback:
          totalAmount - paidAmount,
    );

    final bool archived =
        data['invoiceArchived'] ==
            true;

    final bool working =
        _workingInvoiceId ==
            document.id;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: _statusColor(
            status,
          ).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      yellow.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: yellow,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      invoiceNumber,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '$guestName â€¢ $roomName${roomNumber.isEmpty ? '' : ' - $roomNumber'}',
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          _detailLine(
            'Booking',
            bookingId,
          ),
          _detailLine(
            'Total',
            'PKR ${_money(totalAmount)}',
          ),
          if (paidAmount > 0)
            _detailLine(
              'Paid',
              'PKR ${_money(paidAmount)}',
            ),
          if (remainingAmount > 0)
            _detailLine(
              'Remaining',
              'PKR ${_money(remainingAmount)}',
            ),
          if (data['invoiceVersion'] !=
              null)
            _detailLine(
              'Version',
              'V${_readInt(data['invoiceVersion'], fallback: 1)}',
            ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () =>
                          _openInvoice(
                            document,
                          ),
                  icon: const Icon(
                    Icons.visibility_outlined,
                  ),
                  label: const Text(
                    'Preview',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor: yellow,
                    side: const BorderSide(
                      color: yellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (working)
                const SizedBox(
                  width: 42,
                  height: 42,
                  child:
                      CircularProgressIndicator(
                    color: yellow,
                    strokeWidth: 2,
                  ),
                )
              else
                PopupMenuButton<String>(
                  color: darkCard,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (
                    String action,
                  ) {
                    _handleAction(
                      action: action,
                      document: document,
                    );
                  },
                  itemBuilder: (
                    context,
                  ) =>
                      <PopupMenuEntry<
                          String>>[
                    if (status ==
                            'draft' ||
                        status ==
                            'pending')
                      const PopupMenuItem(
                        value:
                            'mark_paid',
                        child: Text(
                          'Mark paid',
                        ),
                      ),
                    if (status ==
                        'paid')
                      const PopupMenuItem(
                        value:
                            'mark_pending',
                        child: Text(
                          'Mark pending',
                        ),
                      ),
                    if (status !=
                            'refunded' &&
                        status !=
                            'voided')
                      const PopupMenuItem(
                        value: 'refund',
                        child: Text(
                          'Mark refunded',
                        ),
                      ),
                    if (status ==
                            'draft' ||
                        status ==
                            'pending')
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit invoice',
                        ),
                      ),
                    if (status ==
                        'paid')
                      const PopupMenuItem(
                        value: 'void',
                        child: Text(
                          'Void invoice',
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'version',
                      child: Text(
                        'Create corrected version',
                      ),
                    ),
                    PopupMenuItem(
                      value: archived
                          ? 'restore'
                          : 'archive',
                      child: Text(
                        archived
                            ? 'Restore'
                            : 'Archive',
                      ),
                    ),
                    if (status ==
                        'draft')
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete draft',
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'audit',
                      child: Text(
                        'View audit log',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction({
    required String action,
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  }) async {
    switch (action) {
      case 'mark_paid':
        await _markPaid(document);
        break;
      case 'mark_pending':
        await _markPending(document);
        break;
      case 'refund':
        await _markRefunded(document);
        break;
      case 'edit':
        await _editInvoice(document);
        break;
      case 'void':
        await _voidInvoice(document);
        break;
      case 'version':
        await _createCorrectedVersion(
          document,
        );
        break;
      case 'archive':
        await _setArchived(
          document,
          true,
        );
        break;
      case 'restore':
        await _setArchived(
          document,
          false,
        );
        break;
      case 'delete':
        await _deleteDraft(document);
        break;
      case 'audit':
        _showAuditLog(document);
        break;
    }
  }

  Future<void> _markPaid(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final Map<String, dynamic> data =
        document.data();

    final double total =
        _readDouble(
      data['totalAmount'],
    );

    final bool confirmed =
        await _confirmAction(
      title: 'Mark Invoice Paid',
      message:
          'Mark this invoice as fully paid?',
      confirmLabel: 'Mark Paid',
    );

    if (!confirmed) {
      return;
    }

    await _updateInvoice(
      document: document,
      action: 'invoice_marked_paid',
      details:
          'Invoice marked paid by admin.',
      update: <String, dynamic>{
        'invoiceStatus': 'paid',
        'paymentStatus': 'paid',
        'paidAmount': total,
        'remainingAmount': 0,
        'paidAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _markPending(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final bool confirmed =
        await _confirmAction(
      title: 'Mark Invoice Pending',
      message:
          'Move this paid invoice back to pending?',
      confirmLabel: 'Mark Pending',
    );

    if (!confirmed) {
      return;
    }

    await _updateInvoice(
      document: document,
      action:
          'invoice_marked_pending',
      details:
          'Invoice payment status moved to pending.',
      update: <String, dynamic>{
        'invoiceStatus': 'pending',
        'paymentStatus': 'pending',
      },
    );
  }

  Future<void> _markRefunded(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final Map<String, dynamic>? values =
        await _refundDialog(
      document.data(),
    );

    if (values == null) {
      return;
    }

    await _updateInvoice(
      document: document,
      action:
          'invoice_marked_refunded',
      details:
          'Refund recorded: PKR ${_money(values['refundAmount'])}.',
      update: <String, dynamic>{
        'invoiceStatus': 'refunded',
        'paymentStatus': 'refunded',
        ...values,
        'refundedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _editInvoice(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final Map<String, dynamic>? values =
        await _editInvoiceDialog(
      document.data(),
    );

    if (values == null) {
      return;
    }

    await _updateInvoice(
      document: document,
      action: 'invoice_edited',
      details:
          'Draft/pending invoice values edited.',
      update: values,
    );
  }

  Future<void> _voidInvoice(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final String? reason =
        await _reasonDialog(
      title: 'Void Paid Invoice',
      hint:
          'Enter the reason for voiding this invoice',
      confirmLabel: 'Void Invoice',
    );

    if (reason == null ||
        reason.trim().isEmpty) {
      return;
    }

    await _updateInvoice(
      document: document,
      action: 'invoice_voided',
      details:
          'Invoice voided. Reason: $reason',
      update: <String, dynamic>{
        'invoiceStatus': 'voided',
        'isVoided': true,
        'voidReason': reason.trim(),
        'voidedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _createCorrectedVersion(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final bool confirmed =
        await _confirmAction(
      title:
          'Create Corrected Version',
      message:
          'Create a new invoice version while preserving the current audit record?',
      confirmLabel:
          'Create Version',
    );

    if (!confirmed) {
      return;
    }

    final Map<String, dynamic> data =
        document.data();

    final int currentVersion =
        _readInt(
      data['invoiceVersion'],
      fallback: 1,
    );

    final String currentNumber =
        data['invoiceNumber']
                ?.toString() ??
            _fallbackInvoiceNumber(
              data['bookingId']
                      ?.toString() ??
                  document.id,
            );

    await _updateInvoice(
      document: document,
      action:
          'invoice_version_created',
      details:
          'Corrected invoice version V${currentVersion + 1} created.',
      update: <String, dynamic>{
        'invoiceVersion':
            currentVersion + 1,
        'previousInvoiceNumber':
            currentNumber,
        'invoiceNumber':
            '$currentNumber-V${currentVersion + 1}',
        'invoiceStatus': 'draft',
        'isVoided': false,
        'voidReason': '',
        'correctedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _setArchived(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    bool archived,
  ) async {
    await _updateInvoice(
      document: document,
      action: archived
          ? 'invoice_archived'
          : 'invoice_restored',
      details: archived
          ? 'Invoice archived.'
          : 'Invoice restored.',
      update: <String, dynamic>{
        'invoiceArchived': archived,
        if (archived)
          'invoiceArchivedAt':
              FieldValue
                  .serverTimestamp(),
        if (!archived)
          'invoiceRestoredAt':
              FieldValue
                  .serverTimestamp(),
      },
    );
  }

  Future<void> _deleteDraft(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final String status =
        _invoiceStatus(
      document.data(),
    );

    if (status != 'draft') {
      _showMessage(
        'Only draft invoices can be permanently deleted.',
        isError: true,
      );
      return;
    }

    final bool confirmed =
        await _confirmAction(
      title: 'Delete Draft Invoice',
      message:
          'This permanently removes the draft invoice fields from this booking. Continue?',
      confirmLabel: 'Delete Draft',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    await _setWorking(
      document.id,
      () async {
        await document.reference.set(
          <String, dynamic>{
            'invoiceStatus':
                FieldValue.delete(),
            'invoiceNumber':
                FieldValue.delete(),
            'invoiceVersion':
                FieldValue.delete(),
            'invoiceArchived':
                FieldValue.delete(),
            'invoiceDeletedAt':
                FieldValue
                    .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          bookingId:
              document.data()['bookingId']
                      ?.toString() ??
                  document.id,
          invoiceNumber:
              document.data()['invoiceNumber']
                      ?.toString() ??
                  '',
          action:
              'draft_invoice_deleted',
          details:
              'Draft invoice fields permanently deleted by admin.',
        );
      },
    );

    _showMessage(
      'Draft invoice deleted.',
    );
  }

  Future<void> _updateInvoice({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    required String action,
    required String details,
    required Map<String, dynamic>
        update,
  }) async {
    await _setWorking(
      document.id,
      () async {
        await document.reference.set(
          <String, dynamic>{
            ...update,
            'invoiceUpdatedAt':
                FieldValue
                    .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          bookingId:
              document.data()['bookingId']
                      ?.toString() ??
                  document.id,
          invoiceNumber:
              document.data()['invoiceNumber']
                      ?.toString() ??
                  _fallbackInvoiceNumber(
                    document.id,
                  ),
          action: action,
          details: details,
        );
      },
    );

    _showMessage(
      'Invoice updated successfully.',
    );
  }

  Future<void> _saveAudit({
    required String bookingId,
    required String invoiceNumber,
    required String action,
    required String details,
  }) async {
    await _auditCollection.add(
      <String, dynamic>{
        'hotelId': widget.hotelId,
        'bookingId': bookingId,
        'invoiceNumber':
            invoiceNumber,
        'action': action,
        'details': details,
        'performedByRole':
            'hotel_admin',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _setWorking(
    String documentId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingInvoiceId =
          documentId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update invoice: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingInvoiceId = '';
        });
      }
    }
  }

  void _openInvoice(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            HotelInvoiceScreen(
          booking:
              <String, dynamic>{
            ...document.data(),
            'id': document.id,
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?>
      _editInvoiceDialog(
    Map<String, dynamic> data,
  ) async {
    final TextEditingController
        taxController =
        TextEditingController(
      text: _readDouble(
        data['taxAmount'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        serviceController =
        TextEditingController(
      text: _readDouble(
        data['serviceCharges'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        discountController =
        TextEditingController(
      text: _readDouble(
        data['discountAmount'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        noteController =
        TextEditingController(
      text: data['invoiceNote']
              ?.toString() ??
          '',
    );

    final Map<String, dynamic>? result =
        await showDialog<
            Map<String, dynamic>>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) =>
          AlertDialog(
        backgroundColor: darkCard,
        title: const Text(
          'Edit Invoice',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              _dialogField(
                controller:
                    taxController,
                label: 'Tax Amount',
                keyboardType:
                    TextInputType.number,
              ),
              const SizedBox(height: 10),
              _dialogField(
                controller:
                    serviceController,
                label:
                    'Service Charges',
                keyboardType:
                    TextInputType.number,
              ),
              const SizedBox(height: 10),
              _dialogField(
                controller:
                    discountController,
                label:
                    'Discount Amount',
                keyboardType:
                    TextInputType.number,
              ),
              const SizedBox(height: 10),
              _dialogField(
                controller:
                    noteController,
                label: 'Invoice Note',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
              );
            },
            child:
                const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final double tax =
                  double.tryParse(
                        taxController.text
                            .trim(),
                      ) ??
                      0;

              final double service =
                  double.tryParse(
                        serviceController
                            .text
                            .trim(),
                      ) ??
                      0;

              final double discount =
                  double.tryParse(
                        discountController
                            .text
                            .trim(),
                      ) ??
                      0;

              Navigator.pop(
                dialogContext,
                <String, dynamic>{
                  'taxAmount': tax,
                  'serviceCharges':
                      service,
                  'discountAmount':
                      discount,
                  'invoiceNote':
                      noteController
                          .text
                          .trim(),
                },
              );
            },
            style:
                ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor:
                  Colors.black,
            ),
            child: const Text(
              'Save',
            ),
          ),
        ],
      ),
    );

    taxController.dispose();
    serviceController.dispose();
    discountController.dispose();
    noteController.dispose();

    return result;
  }

  Future<Map<String, dynamic>?>
      _refundDialog(
    Map<String, dynamic> data,
  ) async {
    final TextEditingController
        amountController =
        TextEditingController(
      text: _readDouble(
        data['paidAmount'] ??
            data['totalAmount'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        reasonController =
        TextEditingController();

    final Map<String, dynamic>? result =
        await showDialog<
            Map<String, dynamic>>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) =>
          AlertDialog(
        backgroundColor: darkCard,
        title: const Text(
          'Record Refund',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            _dialogField(
              controller:
                  amountController,
              label: 'Refund Amount',
              keyboardType:
                  TextInputType.number,
            ),
            const SizedBox(height: 10),
            _dialogField(
              controller:
                  reasonController,
              label: 'Refund Reason',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
              );
            },
            child:
                const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final double amount =
                  double.tryParse(
                        amountController
                            .text
                            .trim(),
                      ) ??
                      0;

              if (amount <= 0 ||
                  reasonController.text
                      .trim()
                      .isEmpty) {
                return;
              }

              Navigator.pop(
                dialogContext,
                <String, dynamic>{
                  'refundAmount':
                      amount,
                  'refundReason':
                      reasonController
                          .text
                          .trim(),
                  'remainingAmount':
                      0,
                },
              );
            },
            style:
                ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor:
                  Colors.black,
            ),
            child: const Text(
              'Save Refund',
            ),
          ),
        ],
      ),
    );

    amountController.dispose();
    reasonController.dispose();

    return result;
  }

  Future<String?> _reasonDialog({
    required String title,
    required String hint,
    required String confirmLabel,
  }) async {
    final TextEditingController
        controller =
        TextEditingController();

    final String? result =
        await showDialog<String>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) =>
          AlertDialog(
        backgroundColor: darkCard,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        content: _dialogField(
          controller: controller,
          label: hint,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
              );
            },
            child:
                const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text
                  .trim()
                  .isEmpty) {
                return;
              }

              Navigator.pop(
                dialogContext,
                controller.text.trim(),
              );
            },
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.red,
              foregroundColor:
                  Colors.white,
            ),
            child: Text(
              confirmLabel,
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    return result;
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (
            BuildContext dialogContext,
          ) =>
              AlertDialog(
            backgroundColor: darkCard,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child:
                    const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      destructive
                          ? Colors.red
                          : yellow,
                  foregroundColor:
                      destructive
                          ? Colors.white
                          : Colors.black,
                ),
                child: Text(
                  confirmLabel,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showAuditLog(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final String bookingId =
        document.data()['bookingId']
                ?.toString() ??
            document.id;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          darkBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.72,
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _auditCollection
                  .where(
                    'hotelId',
                    isEqualTo:
                        widget.hotelId,
                  )
                  .where(
                    'bookingId',
                    isEqualTo:
                        bookingId,
                  )
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                final List<
                        QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>
                    documents =
                    snapshot.data?.docs ??
                        <QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>[];

                documents.sort(
                  (a, b) =>
                      _readDateTime(
                        b.data()[
                            'createdAt'],
                      ).compareTo(
                        _readDateTime(
                          a.data()[
                              'createdAt'],
                        ),
                      ),
                );

                return Column(
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.all(
                        18,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: yellow,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Invoice Audit Log',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child:
                          documents.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No audit history yet.',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets
                                          .fromLTRB(
                                    16,
                                    0,
                                    16,
                                    20,
                                  ),
                                  itemCount:
                                      documents
                                          .length,
                                  itemBuilder: (
                                    context,
                                    index,
                                  ) {
                                    final data =
                                        documents[
                                                index]
                                            .data();

                                    return Container(
                                      margin:
                                          const EdgeInsets
                                              .only(
                                        bottom:
                                            9,
                                      ),
                                      padding:
                                          const EdgeInsets
                                              .all(
                                        13,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            darkCard,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            data['action']
                                                    ?.toString() ??
                                                'Action',
                                            style:
                                                const TextStyle(
                                              color:
                                                  yellow,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height:
                                                5,
                                          ),
                                          Text(
                                            data['details']
                                                    ?.toString() ??
                                                '',
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize:
                                                  11,
                                            ),
                                          ),
                                          const SizedBox(
                                            height:
                                                5,
                                          ),
                                          Text(
                                            _formatDateTime(
                                              _readDateTime(
                                                data[
                                                    'createdAt'],
                                              ),
                                            ),
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize:
                                                  9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openInvoiceSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          darkBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) =>
          _InvoiceSettingsSheet(
        firestore: _firestore,
        hotelId: widget.hotelId,
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController
        controller,
    required String label,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(
          color: Colors.grey,
        ),
        filled: true,
        fillColor: darkBackground,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }

  Widget _detailLine(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final Color color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.13,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              color: yellow,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _invoiceStatus(
    Map<String, dynamic> data,
  ) {
    final String saved =
        data['invoiceStatus']
                ?.toString() ??
            '';

    if (saved.isNotEmpty) {
      return saved;
    }

    if (data['isVoided'] == true) {
      return 'voided';
    }

    if (_readDouble(
          data['refundAmount'],
        ) >
        0) {
      return 'refunded';
    }

    final String bookingStatus =
        data['bookingStatus']
                ?.toString() ??
            '';

    if (bookingStatus ==
        'cancelled') {
      return 'cancelled';
    }

    final String paymentStatus =
        data['paymentStatus']
                ?.toString() ??
            '';

    if (paymentStatus == 'paid') {
      return 'paid';
    }

    if (bookingStatus ==
            'pending' ||
        bookingStatus ==
            'pending_hotel_confirmation') {
      return 'draft';
    }

    return 'pending';
  }

  String _fallbackInvoiceNumber(
    String bookingId,
  ) {
    final String clean =
        bookingId.replaceAll(
      RegExp(r'[^A-Za-z0-9]'),
      '',
    );

    final String suffix =
        clean.length <= 10
            ? clean.toUpperCase()
            : clean
                .substring(
                  clean.length - 10,
                )
                .toUpperCase();

    return 'SR-HOT-${DateTime.now().year}-$suffix';
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'refunded':
        return Colors.blue;
      case 'cancelled':
      case 'voided':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'all':
        return 'All';
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'refunded':
        return 'Refunded';
      case 'cancelled':
        return 'Cancelled';
      case 'voided':
        return 'Voided';
      default:
        return status;
    }
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
      return DateTime.tryParse(
            value,
          ) ??
          DateTime
              .fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatDateTime(
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

    final String hour =
        date.hour
            .toString()
            .padLeft(2, '0');

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  String _money(
    dynamic amount,
  ) {
    final double value =
        _readDouble(amount);

    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (Match match) => ',',
        );
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

class _InvoiceSettingsSheet
    extends StatefulWidget {
  const _InvoiceSettingsSheet({
    required this.firestore,
    required this.hotelId,
  });

  final FirebaseFirestore firestore;
  final String hotelId;

  @override
  State<_InvoiceSettingsSheet>
      createState() =>
          _InvoiceSettingsSheetState();
}

class _InvoiceSettingsSheetState
    extends State<_InvoiceSettingsSheet> {
  static const Color yellow =
      Color(0xFFFFD60A);
  static const Color darkCard =
      Color(0xFF1A1A1A);

  final TextEditingController
      _prefixController =
      TextEditingController(
    text: 'SR-HOT',
  );

  final TextEditingController
      _companyController =
      TextEditingController(
    text: 'SWAT RIDE',
  );

  final TextEditingController
      _ntnController =
      TextEditingController();

  final TextEditingController
      _strnController =
      TextEditingController();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _websiteController =
      TextEditingController();

  bool _qrEnabled = true;
  bool _showPromo = true;
  bool _showRewards = true;
  bool _showCashback = true;
  bool _adminStampEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _companyController.dispose();
    _ntnController.dispose();
    _strnController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final snapshot = await widget
          .firestore
          .collection(
            'hotel_invoice_settings',
          )
          .doc(widget.hotelId)
          .get();

      final data =
          snapshot.data() ??
              <String, dynamic>{};

      _prefixController.text =
          data['invoicePrefix']
                  ?.toString() ??
              'SR-HOT';

      _companyController.text =
          data['companyName']
                  ?.toString() ??
              'SWAT RIDE';

      _ntnController.text =
          data['ntn']?.toString() ??
              '';

      _strnController.text =
          data['strn']?.toString() ??
              '';

      _emailController.text =
          data['supportEmail']
                  ?.toString() ??
              '';

      _websiteController.text =
          data['website']
                  ?.toString() ??
              '';

      _qrEnabled =
          data['qrEnabled'] != false;

      _showPromo =
          data['showPromo'] != false;

      _showRewards =
          data['showRewards'] != false;

      _showCashback =
          data['showCashback'] != false;

      _adminStampEnabled =
          data['adminStampEnabled'] ==
              true;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await widget.firestore
          .collection(
            'hotel_invoice_settings',
          )
          .doc(widget.hotelId)
          .set(
        <String, dynamic>{
          'hotelId': widget.hotelId,
          'invoicePrefix':
              _prefixController.text
                  .trim(),
          'companyName':
              _companyController.text
                  .trim(),
          'ntn':
              _ntnController.text.trim(),
          'strn':
              _strnController.text
                  .trim(),
          'supportEmail':
              _emailController.text
                  .trim(),
          'website':
              _websiteController.text
                  .trim(),
          'qrEnabled': _qrEnabled,
          'showPromo': _showPromo,
          'showRewards':
              _showRewards,
          'showCashback':
              _showCashback,
          'adminStampEnabled':
              _adminStampEnabled,
          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const SizedBox(
              height: 300,
              child: Center(
                child:
                    CircularProgressIndicator(
                  color: yellow,
                ),
              ),
            )
          : SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(
                18,
                18,
                18,
                18 +
                    MediaQuery.of(context)
                        .viewInsets
                        .bottom,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Invoice Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  _field(
                    _prefixController,
                    'Invoice Prefix',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _field(
                    _companyController,
                    'Company Name',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _field(
                    _ntnController,
                    'NTN',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _field(
                    _strnController,
                    'STRN',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _field(
                    _emailController,
                    'Support Email',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _field(
                    _websiteController,
                    'Website',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _switch(
                    'QR Verification',
                    _qrEnabled,
                    (value) {
                      setState(() {
                        _qrEnabled =
                            value;
                      });
                    },
                  ),
                  _switch(
                    'Show Promo',
                    _showPromo,
                    (value) {
                      setState(() {
                        _showPromo =
                            value;
                      });
                    },
                  ),
                  _switch(
                    'Show Rewards',
                    _showRewards,
                    (value) {
                      setState(() {
                        _showRewards =
                            value;
                      });
                    },
                  ),
                  _switch(
                    'Show Cashback',
                    _showCashback,
                    (value) {
                      setState(() {
                        _showCashback =
                            value;
                      });
                    },
                  ),
                  _switch(
                    'Admin Verified Stamp',
                    _adminStampEnabled,
                    (value) {
                      setState(() {
                        _adminStampEnabled =
                            value;
                      });
                    },
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : _save,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            yellow,
                        foregroundColor:
                            Colors.black,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save Settings',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(
          color: Colors.grey,
        ),
        filled: true,
        fillColor: darkCard,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }

  Widget _switch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding:
          EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      value: value,
      activeThumbColor: yellow,
      onChanged: onChanged,
    );
  }
}
