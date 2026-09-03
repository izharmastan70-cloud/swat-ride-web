// lib/food/rider/screens/food_delivery_support_screen.dart
// SOS is intentionally excluded. It will be handled separately for all app modules.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/food_delivery_rider_model.dart';

class FoodDeliverySupportScreen extends StatefulWidget {
  const FoodDeliverySupportScreen({
    required this.rider,
    super.key,
  });

  final FoodDeliveryRiderModel rider;

  @override
  State<FoodDeliverySupportScreen> createState() =>
      _FoodDeliverySupportScreenState();
}

class _FoodDeliverySupportScreenState
    extends State<FoodDeliverySupportScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isSubmitting = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchTickets() {
    return _firestore
        .collection('food_support_tickets')
        .where('riderId', isEqualTo: widget.rider.riderId)
        .snapshots();
  }

  Future<void> _openTicketDialog(String category) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController subjectController =
        TextEditingController();
    final TextEditingController messageController =
        TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(category),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please enter a subject'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: messageController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Describe the issue',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please describe the issue'
                            : null,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _submitTicket(
        category: category,
        subject: subjectController.text.trim(),
        message: messageController.text.trim(),
      );
    }

    subjectController.dispose();
    messageController.dispose();
  }

  Future<void> _submitTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final DocumentReference<Map<String, dynamic>> doc =
          _firestore.collection('food_support_tickets').doc();

      await doc.set(<String, dynamic>{
        'ticketId': doc.id,
        'module': 'food',
        'userRole': 'food_rider',
        'userId': widget.rider.userId,
        'riderId': widget.rider.riderId,
        'name': widget.rider.fullName,
        'phoneNumber': widget.rider.phoneNumber,
        'category': category,
        'subject': subject,
        'message': message,
        'status': 'open',
        'priority': 'normal',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'resolvedBy': '',
        'resolutionNote': '',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Support ticket submitted successfully.'),
          ),
        );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ?? 'Unable to submit support ticket.',
      );
    } catch (error) {
      _showMessage('Unable to submit support ticket: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final List<_SupportOption> options = <_SupportOption>[
      const _SupportOption(
        'Order or Delivery Issue',
        'Pickup, restaurant delay, customer or delivery problem',
        Icons.delivery_dining,
      ),
      const _SupportOption(
        'Earnings or Wallet',
        'Delivery earnings, wallet balance or commission issue',
        Icons.account_balance_wallet_outlined,
      ),
      const _SupportOption(
        'Account or Documents',
        'Profile, approval, CNIC, license or vehicle documents',
        Icons.badge_outlined,
      ),
      const _SupportOption(
        'App Technical Issue',
        'Food Rider screen, notification or application error',
        Icons.bug_report_outlined,
      ),
      const _SupportOption(
        'Other Food Rider Issue',
        'Any non-emergency Food Rider support request',
        Icons.help_outline,
      ),
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Rider Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: yellow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.black,
                  child: Icon(
                    Icons.support_agent,
                    color: yellow,
                    size: 33,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'How can we help?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Choose a Food Rider support category and submit your issue.',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: options.map((_SupportOption option) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF252525),
                    child: Icon(option.icon, color: yellow),
                  ),
                  title: Text(
                    option.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    option.subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isSubmitting
                      ? null
                      : () => _openTicketDialog(option.title),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'My Support Tickets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _watchTickets(),
            builder: (
              BuildContext context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: yellow),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _messageCard('Unable to load support tickets.');
              }

              final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                  snapshot.data?.docs.toList() ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              docs.sort(
                (
                  QueryDocumentSnapshot<Map<String, dynamic>> first,
                  QueryDocumentSnapshot<Map<String, dynamic>> second,
                ) =>
                    _dateValue(second.data()['createdAt']).compareTo(
                  _dateValue(first.data()['createdAt']),
                ),
              );

              if (docs.isEmpty) {
                return _messageCard(
                  'No Food Rider support tickets yet.',
                );
              }

              return Column(
                children: docs.map(
                  (
                    QueryDocumentSnapshot<Map<String, dynamic>> document,
                  ) {
                    final Map<String, dynamic> data = document.data();
                    final String status =
                        data['status']?.toString().trim() ?? 'open';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            status == 'resolved'
                                ? Icons.check_circle
                                : Icons.support_agent_outlined,
                            color: status == 'resolved'
                                ? Colors.greenAccent
                                : yellow,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  data['subject']?.toString() ??
                                      'Food Support Ticket',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['category']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: status == 'resolved'
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _messageCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  static DateTime _dateValue(dynamic value) {
    if (value is DateTime) return value;

    try {
      final dynamic converted = value.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {}

    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _SupportOption {
  const _SupportOption(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
