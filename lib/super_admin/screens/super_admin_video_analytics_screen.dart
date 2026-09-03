import 'package:flutter/material.dart';

import '../services/super_admin_video_analytics_service.dart';

class SuperAdminVideoAnalyticsScreen extends StatelessWidget {
  SuperAdminVideoAnalyticsScreen({
    super.key,
    SuperAdminVideoAnalyticsService? service,
  }) : service = service ?? SuperAdminVideoAnalyticsService();

  final SuperAdminVideoAnalyticsService service;

  String _label(String value) {
    return value.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Guide Analytics')),
      body: StreamBuilder<SuperAdminVideoAnalyticsSummary>(
        stream: service.watchSummary(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load analytics: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = snapshot.data!;

          final reasons = summary.notHelpfulReasons.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const Text(
                'Privacy-safe content analytics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                'No user ID, phone, email, device ID, '
                'location, search query or free-text '
                'customer message is stored.',
              ),
              const SizedBox(height: 16),
              _MetricCard(
                label: 'Recent events',
                value: '${summary.totalEvents}',
              ),
              _MetricCard(
                label: 'Video opened',
                value: '${summary.videoOpened}',
              ),
              _MetricCard(label: 'Helpful', value: '${summary.helpful}'),
              _MetricCard(label: 'Not helpful', value: '${summary.notHelpful}'),
              _MetricCard(
                label: 'Helpful rate',
                value: '${(summary.helpfulRate * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 16),
              const Text(
                'Not-helpful reasons',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              if (reasons.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No not-helpful feedback yet.'),
                )
              else
                ...reasons.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_label(entry.key)),
                    trailing: Text('${entry.value}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
