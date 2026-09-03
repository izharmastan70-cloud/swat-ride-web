import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/screens/agent_production_rollout_audit_signal_drilldown_screen.dart';

void main() {
  test('audit drilldown widget exposes admin identity only', () {
    const widget = AgentProductionRolloutAuditSignalDrilldownScreen(
      currentAdminId: 'admin',
    );

    expect(widget.currentAdminId, 'admin');
  });
}
