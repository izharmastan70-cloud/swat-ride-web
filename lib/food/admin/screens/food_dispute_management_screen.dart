// lib/food/admin/screens/food_dispute_management_screen.dart

import 'package:flutter/material.dart';

import '../../models/food_order_dispute_model.dart';
import '../../services/food_order_dispute_service.dart';

class FoodDisputeManagementScreen extends StatefulWidget {
  const FoodDisputeManagementScreen({super.key, this.adminId = 'food_admin'});

  final String adminId;

  @override
  State<FoodDisputeManagementScreen> createState() =>
      _FoodDisputeManagementScreenState();
}

class _FoodDisputeManagementScreenState
    extends State<FoodDisputeManagementScreen> {
  final FoodOrderDisputeService _service = FoodOrderDisputeService();

  FoodOrderDisputeStatus? _selectedStatus;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Disputes')),
      body: StreamBuilder<List<FoodOrderDisputeModel>>(
        stream: _service.watchAllDisputes(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<FoodOrderDisputeModel>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load food disputes.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final List<FoodOrderDisputeModel> all =
                  snapshot.data ?? <FoodOrderDisputeModel>[];

              final List<FoodOrderDisputeModel> filtered =
                  _selectedStatus == null
                  ? all
                  : all
                        .where(
                          (FoodOrderDisputeModel dispute) =>
                              dispute.status == _selectedStatus,
                        )
                        .toList();

              return Column(
                children: <Widget>[
                  _buildSummary(all),
                  _buildFilters(),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No food disputes found.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(height: 12),
                            itemBuilder: (BuildContext context, int index) {
                              return _buildDisputeCard(filtered[index]);
                            },
                          ),
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _buildSummary(List<FoodOrderDisputeModel> disputes) {
    final int openCount = disputes
        .where((FoodOrderDisputeModel item) => !item.status.isClosed)
        .length;

    final int resolvedCount = disputes
        .where(
          (FoodOrderDisputeModel item) =>
              item.status == FoodOrderDisputeStatus.resolved,
        )
        .length;

    final int refundPendingCount = disputes
        .where(
          (FoodOrderDisputeModel item) =>
              item.status == FoodOrderDisputeStatus.resolved &&
              item.refundApproved &&
              item.approvedRefundAmount > 0,
        )
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _summaryCard(
              title: 'Open',
              value: '$openCount',
              icon: Icons.report_problem_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryCard(
              title: 'Resolved',
              value: '$resolvedCount',
              icon: Icons.task_alt_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryCard(
              title: 'Refunds',
              value: '$refundPendingCount',
              icon: Icons.currency_exchange_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: <Widget>[
            Icon(icon),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedStatus == null,
            onSelected: (_) {
              setState(() {
                _selectedStatus = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ...FoodOrderDisputeStatus.values.map((FoodOrderDisputeStatus status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(status.label),
                selected: _selectedStatus == status,
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(FoodOrderDisputeModel dispute) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Order ${dispute.orderId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _statusBadge(dispute.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              dispute.reason.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(dispute.description),
            const SizedBox(height: 12),
            _infoRow('Raised by', dispute.raisedBy.label),
            _infoRow(
              'Customer',
              dispute.customerId.isEmpty ? '-' : dispute.customerId,
            ),
            _infoRow(
              'Restaurant',
              dispute.restaurantId.isEmpty ? '-' : dispute.restaurantId,
            ),
            if (dispute.riderId.isNotEmpty) _infoRow('Rider', dispute.riderId),
            if (dispute.refundRequested)
              _infoRow(
                'Refund requested',
                'Rs ${dispute.requestedRefundAmount.toStringAsFixed(2)}',
              ),
            if (dispute.refundApproved)
              _infoRow(
                'Refund approved',
                'Rs ${dispute.approvedRefundAmount.toStringAsFixed(2)}',
              ),
            if (dispute.resolutionNote.isNotEmpty)
              _infoRow('Resolution', dispute.resolutionNote),
            const SizedBox(height: 14),
            _buildActions(dispute),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(FoodOrderDisputeModel dispute) {
    if (dispute.status.isClosed) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _runAction(
                  () => _service.markUnderReview(
                    disputeId: dispute.disputeId,
                    adminId: widget.adminId,
                  ),
                  'Dispute marked under review.',
                ),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Under Review'),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _showResponseMenu(dispute),
          icon: const Icon(Icons.question_answer_outlined),
          label: const Text('Request Response'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : () => _showResolveDialog(dispute),
          icon: const Icon(Icons.task_alt_outlined),
          label: const Text('Resolve'),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _showRejectDialog(dispute),
          icon: const Icon(Icons.block_outlined),
          label: const Text('Reject'),
        ),
      ],
    );
  }

  Future<void> _showResponseMenu(FoodOrderDisputeModel dispute) async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Request Customer Response'),
                onTap: () {
                  Navigator.pop(context, 'customer');
                },
              ),
              ListTile(
                leading: const Icon(Icons.store_outlined),
                title: const Text('Request Restaurant Response'),
                onTap: () {
                  Navigator.pop(context, 'restaurant');
                },
              ),
              if (dispute.riderId.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delivery_dining_outlined),
                  title: const Text('Request Rider Response'),
                  onTap: () {
                    Navigator.pop(context, 'rider');
                  },
                ),
            ],
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    if (result == 'customer') {
      await _runAction(
        () => _service.requestCustomerResponse(
          disputeId: dispute.disputeId,
          adminId: widget.adminId,
        ),
        'Customer response requested.',
      );
      return;
    }

    if (result == 'restaurant') {
      await _runAction(
        () => _service.requestRestaurantResponse(
          disputeId: dispute.disputeId,
          adminId: widget.adminId,
        ),
        'Restaurant response requested.',
      );
      return;
    }

    if (result == 'rider') {
      await _runAction(
        () => _service.requestRiderResponse(
          disputeId: dispute.disputeId,
          adminId: widget.adminId,
        ),
        'Rider response requested.',
      );
    }
  }

  Future<void> _showResolveDialog(FoodOrderDisputeModel dispute) async {
    final TextEditingController noteController = TextEditingController();

    final TextEditingController refundController = TextEditingController(
      text: dispute.refundRequested && dispute.requestedRefundAmount > 0
          ? dispute.requestedRefundAmount.toStringAsFixed(2)
          : '',
    );

    bool approveRefund = false;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setDialogState,
              ) {
                return AlertDialog(
                  title: const Text('Resolve Food Dispute'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Resolution note',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Approve refund'),
                          subtitle: const Text(
                            'Records approval only. Payment gateway refund is not executed here.',
                          ),
                          value: approveRefund,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              approveRefund = value ?? false;
                            });
                          },
                        ),
                        if (approveRefund)
                          TextField(
                            controller: refundController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Approved refund amount',
                              prefixText: 'Rs ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, false);
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                      },
                      child: const Text('Resolve'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (confirmed != true) {
      noteController.dispose();
      refundController.dispose();
      return;
    }

    final String note = noteController.text.trim();

    final double refundAmount =
        double.tryParse(refundController.text.trim()) ?? 0;

    noteController.dispose();
    refundController.dispose();

    if (note.isEmpty) {
      _showMessage('Resolution note is required.');
      return;
    }

    await _runAction(
      () => _service.resolveDispute(
        disputeId: dispute.disputeId,
        adminId: widget.adminId,
        resolutionNote: note,
        approveRefund: approveRefund,
        approvedRefundAmount: approveRefund ? refundAmount : 0,
      ),
      'Food dispute resolved.',
    );
  }

  Future<void> _showRejectDialog(FoodOrderDisputeModel dispute) async {
    final TextEditingController controller = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reject Food Dispute'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Rejection reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    final String reason = controller.text.trim();

    controller.dispose();

    if (reason.isEmpty) {
      _showMessage('Rejection reason is required.');
      return;
    }

    await _runAction(
      () => _service.rejectDispute(
        disputeId: dispute.disputeId,
        adminId: widget.adminId,
        resolutionNote: reason,
      ),
      'Food dispute rejected.',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      _showMessage(successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _statusBadge(FoodOrderDisputeStatus status) {
    return Chip(label: Text(status.label));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
