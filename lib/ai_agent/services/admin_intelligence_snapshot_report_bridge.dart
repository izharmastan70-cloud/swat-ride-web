import '../models/admin_intelligence_health_snapshot.dart';
import '../models/admin_intelligence_report.dart';
import 'admin_intelligence_health_signal_collector.dart';
import 'admin_intelligence_report_engine.dart';

class AdminIntelligenceSnapshotReportBridge {
  const AdminIntelligenceSnapshotReportBridge({
    this.collector = const AdminIntelligenceHealthSignalCollector(),
    this.reportEngine = const AdminIntelligenceReportEngine(),
  });

  final AdminIntelligenceHealthSignalCollector collector;
  final AdminIntelligenceReportEngine reportEngine;

  AdminIntelligenceReport buildReportFromSnapshot(
    AdminIntelligenceHealthSnapshot snapshot,
  ) {
    final signals = collector.collect(snapshot);

    return reportEngine.buildReport(
      reportId: 'admin_intelligence:${snapshot.snapshotId}',
      generatedAt: snapshot.generatedAt,
      windowStart: snapshot.windowStart,
      windowEnd: snapshot.windowEnd,
      signals: signals,
      adminAreasScanned: snapshot.adminAreasScanned,
      sourcesScanned: snapshot.sourcesScanned,
    );
  }
}
