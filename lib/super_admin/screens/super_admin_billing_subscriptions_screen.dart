import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuperAdminBillingSubscriptionsScreen extends StatelessWidget {
  const SuperAdminBillingSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Subscriptions')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('billing_subscriptions')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load subscriptions.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> items =
              snapshot.data!.docs;
          if (items.isEmpty) {
            return const Center(child: Text('No services discovered yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> item = items[index].data();
              final Object? amount = item['estimatedMonthlyCost'];
              final List<dynamic> variables =
                  item['detectedEnvironmentVariables'] as List<dynamic>? ??
                      <dynamic>[];
              return Card(
                child: ListTile(
                  title: Text(item['serviceName']?.toString() ?? 'Service'),
                  subtitle: Text(
                    'Status: ${item['status'] ?? 'pending_review'}\n'
                    'Monthly cost: ${amount == null ? 'Needs review' : 'Rs. $amount'}\n'
                    'Detected configuration: ${variables.join(', ')}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.receipt_long_outlined),
                ),
              );
            },
          );
        },
      ),
    );
  }
}