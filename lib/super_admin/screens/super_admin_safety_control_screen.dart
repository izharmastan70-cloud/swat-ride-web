import 'package:flutter/material.dart';

import '../../safety/models/safety_models.dart';
import '../../safety/screens/active_emergency_screen.dart';
import '../../safety/services/universal_safety_service.dart';

// =========================================================
// SWAT RIDE — SUPER ADMIN SAFETY CONTROL
// =========================================================
//
// Global Super Admin oversight for existing Universal Safety/SOS.
//
// IMPORTANT:
// - Does NOT replace or modify existing SOS flows.
// - Reads active incidents through UniversalSafetyService.
// - Opening an incident reuses ActiveEmergencyScreen.
// - Super Admin identity is passed explicitly.
// - Existing Safety service remains the single source of truth.

class SuperAdminSafetyControlScreen extends StatefulWidget {
  const SuperAdminSafetyControlScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<SuperAdminSafetyControlScreen> createState() =>
      _SuperAdminSafetyControlScreenState();
}

class _SuperAdminSafetyControlScreenState
    extends State<SuperAdminSafetyControlScreen> {
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _yellow = Color(0xFFFFD60A);

  final UniversalSafetyService _safetyService =
      UniversalSafetyService();

  void _openIncident(SafetyIncidentModel incident) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveEmergencyScreen(
          incidentId: incident.incidentId,
          currentUserId: widget.currentAdminId,
          currentUserRole: SafetyUserRole.superAdmin,
          safetyService: _safetyService,
        ),
      ),
    );
  }

  String _labelFromEnumName(String value) {
    if (value.trim().isEmpty) {
      return 'Unknown';
    }

    final String text = value
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (Match match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .trim();

    if (text.isEmpty) {
      return 'Unknown';
    }

    return text
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) =>
              '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _dateText(DateTime value) {
    final DateTime local = value.toLocal();

    String two(int number) => number.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Widget _statusChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _severityColor(SafetyIncidentModel incident) {
    if (incident.isCritical) {
      return Colors.redAccent;
    }

    switch (incident.severity) {
      case SafetySeverity.high:
        return Colors.orangeAccent;
      case SafetySeverity.medium:
        return Colors.amberAccent;
      case SafetySeverity.low:
        return Colors.lightGreenAccent;
      case SafetySeverity.critical:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text(
          'Safety Control',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<List<SafetyIncidentModel>>(
        stream: _safetyService.watchActiveIncidents(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<SafetyIncidentModel>> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load active safety incidents.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: _yellow,
              ),
            );
          }

          final List<SafetyIncidentModel> incidents =
              List<SafetyIncidentModel>.from(
            snapshot.data!,
          )
                ..sort(
                  (
                    SafetyIncidentModel a,
                    SafetyIncidentModel b,
                  ) {
                    if (a.isCritical != b.isCritical) {
                      return a.isCritical ? -1 : 1;
                    }

                    return b.createdAt.compareTo(a.createdAt);
                  },
                );

          if (incidents.isEmpty) {
            return const _SafetyEmptyState();
          }

          final int criticalCount = incidents
              .where(
                (SafetyIncidentModel incident) =>
                    incident.isCritical,
              )
              .length;

          final int unacknowledgedCount = incidents
              .where(
                (SafetyIncidentModel incident) =>
                    !incident.adminAcknowledged,
              )
              .length;

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  8,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _SafetySummaryCard(
                        title: 'Active',
                        value: incidents.length.toString(),
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SafetySummaryCard(
                        title: 'Critical',
                        value: criticalCount.toString(),
                        icon: Icons.crisis_alert,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SafetySummaryCard(
                        title: 'Unacknowledged',
                        value: unacknowledgedCount.toString(),
                        icon: Icons.notification_important_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24,
                  ),
                  itemCount: incidents.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    final SafetyIncidentModel incident =
                        incidents[index];

                    final String service =
                        _labelFromEnumName(
                      incident.context.serviceType.name,
                    );

                    final String category =
                        _labelFromEnumName(
                      incident.category.name,
                    );

                    final String severity =
                        _labelFromEnumName(
                      incident.severity.name,
                    );

                    final String status =
                        _labelFromEnumName(
                      incident.status.name,
                    );

                    final Color severityColor =
                        _severityColor(incident);

                    return Material(
                      color: _card,
                      borderRadius:
                          BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(16),
                        onTap: () =>
                            _openIncident(incident),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration:
                                        BoxDecoration(
                                      color: severityColor
                                          .withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    child: Icon(
                                      incident.isCritical
                                          ? Icons
                                              .crisis_alert
                                          : Icons
                                              .health_and_safety_outlined,
                                      color:
                                          severityColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: <Widget>[
                                        Text(
                                          category,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.white,
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight
                                                    .w800,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 3,
                                        ),
                                        Text(
                                          service,
                                          style:
                                              const TextStyle(
                                            color: Colors
                                                .white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white38,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: <Widget>[
                                  _statusChip(
                                    text: severity,
                                    color:
                                        severityColor,
                                  ),
                                  _statusChip(
                                    text: status,
                                    color:
                                        Colors.lightBlueAccent,
                                  ),
                                  _statusChip(
                                    text: incident
                                            .adminAcknowledged
                                        ? 'Acknowledged'
                                        : 'Needs acknowledgement',
                                    color: incident
                                            .adminAcknowledged
                                        ? Colors
                                            .greenAccent
                                        : Colors
                                            .orangeAccent,
                                  ),
                                ],
                              ),
                              if (incident
                                  .description
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  incident.description
                                      .trim(),
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white70,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'Incident: '
                                      '${incident.incidentId}',
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _dateText(
                                      incident.createdAt,
                                    ),
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SafetySummaryCard extends StatelessWidget {
  const _SafetySummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: const Color(0xFFFFD60A),
            size: 21,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyEmptyState extends StatelessWidget {
  const _SafetyEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.verified_user_outlined,
              color: Colors.greenAccent,
              size: 54,
            ),
            SizedBox(height: 14),
            Text(
              'No active safety incidents',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Active SOS and safety incidents will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
