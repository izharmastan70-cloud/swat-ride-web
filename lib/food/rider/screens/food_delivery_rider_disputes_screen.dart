// lib/food/rider/screens/food_delivery_rider_disputes_screen.dart

import 'package:flutter/material.dart';

import '../../models/food_order_dispute_model.dart';
import '../../services/food_order_dispute_service.dart';
import '../models/food_delivery_rider_model.dart';

class FoodDeliveryRiderDisputesScreen extends StatefulWidget {
  const FoodDeliveryRiderDisputesScreen({required this.rider, super.key});

  final FoodDeliveryRiderModel rider;

  @override
  State<FoodDeliveryRiderDisputesScreen> createState() =>
      _FoodDeliveryRiderDisputesScreenState();
}

class _FoodDeliveryRiderDisputesScreenState
    extends State<FoodDeliveryRiderDisputesScreen> {
  static const Color yellow = Color(0xFFFFD60A);

  static const Color background = Color(0xFF0D0D0D);

  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderDisputeService _service = FoodOrderDisputeService();

  bool _submitting = false;

  String get _riderId => widget.rider.riderId.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Delivery Disputes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _riderId.isEmpty
          ? _buildMessage(
              icon: Icons.delivery_dining_outlined,
              title: 'Rider account unavailable',
              message: 'Food Delivery Rider ID is not available.',
            )
          : StreamBuilder<List<FoodOrderDisputeModel>>(
              stream: _service.watchRiderDisputes(_riderId),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<FoodOrderDisputeModel>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: yellow),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildMessage(
                        icon: Icons.cloud_off_outlined,
                        title: 'Unable to load disputes',
                        message: snapshot.error.toString(),
                      );
                    }

                    final List<FoodOrderDisputeModel> disputes =
                        snapshot.data ?? const <FoodOrderDisputeModel>[];

                    if (disputes.isEmpty) {
                      return _buildMessage(
                        icon: Icons.verified_outlined,
                        title: 'No delivery disputes',
                        message:
                            'Disputes involving your Food deliveries will appear here.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                      itemCount: disputes.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        return _buildDisputeCard(disputes[index]);
                      },
                    );
                  },
            ),
    );
  }

  Widget _buildDisputeCard(FoodOrderDisputeModel dispute) {
    final bool responseRequested =
        dispute.status == FoodOrderDisputeStatus.awaitingRider;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: responseRequested
              ? yellow.withValues(alpha: 0.55)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Order ${dispute.orderId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(dispute.status),
            ],
          ),
          const SizedBox(height: 12),
          _info('Issue', dispute.reason.label),
          _info('Raised by', dispute.raisedBy.label),
          const SizedBox(height: 8),
          Text(
            dispute.description,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          if (dispute.refundRequested) ...<Widget>[
            const SizedBox(height: 10),
            _info(
              'Refund requested',
              'Rs ${dispute.requestedRefundAmount.toStringAsFixed(2)}',
            ),
          ],
          if (responseRequested) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: yellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Food Admin requested a response from you.',
                style: TextStyle(color: yellow, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () => _showResponseDialog(dispute),
                icon: const Icon(Icons.reply_outlined),
                label: const Text('Submit Response'),
              ),
            ),
          ],
          if (dispute.status == FoodOrderDisputeStatus.underReview) ...<Widget>[
            const SizedBox(height: 12),
            const Text(
              'Food Admin is reviewing this dispute.',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ],
          if (dispute.status.isClosed) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              dispute.resolutionNote.trim().isEmpty
                  ? 'This dispute is closed.'
                  : 'Resolution: ${dispute.resolutionNote}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showResponseDialog(FoodOrderDisputeModel dispute) async {
    final TextEditingController controller = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delivery Rider Response'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Response',
              hintText: 'Explain what happened during this delivery.',
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
                final String value = controller.text.trim();

                if (value.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter a response.')),
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    final String response = controller.text.trim();

    controller.dispose();

    if (confirmed != true || response.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _service.submitRiderResponse(
        disputeId: dispute.disputeId,
        riderId: _riderId,
        response: response,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Rider response submitted to Food Admin.');
    } on StateError catch (error) {
      if (mounted) {
        _showMessage(error.message.toString());
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to submit response: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _statusChip(FoodOrderDisputeStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white10,
      ),
      child: Text(
        status.label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 60, color: yellow),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
