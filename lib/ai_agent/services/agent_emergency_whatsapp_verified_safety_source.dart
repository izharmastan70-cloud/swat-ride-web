import '../../safety/models/safety_models.dart';
import '../../safety/services/trusted_contact_service.dart';
import '../../safety/services/universal_safety_service.dart';
import '../models/agent_emergency_whatsapp_verified_safety_snapshot.dart';

class AgentEmergencyWhatsAppVerifiedSafetySanitizer {
  const AgentEmergencyWhatsAppVerifiedSafetySanitizer();

  AgentEmergencyWhatsAppVerifiedSafetySnapshot sanitize({
    required SafetyIncidentModel? activeIncident,
    required bool eligibleSosContactCountVerified,
    required int? eligibleSosContactCount,
  }) {
    if (activeIncident == null) {
      return AgentEmergencyWhatsAppVerifiedSafetySnapshot(
        incidentSourceVerified: true,
        hasActiveIncident: false,
        eligibleSosContactCountVerified: eligibleSosContactCountVerified,
        eligibleSosContactCount: eligibleSosContactCountVerified
            ? eligibleSosContactCount
            : null,
      );
    }

    return AgentEmergencyWhatsAppVerifiedSafetySnapshot(
      incidentSourceVerified: true,
      hasActiveIncident: true,
      status: activeIncident.status.name,
      category: activeIncident.category.name,
      severity: activeIncident.severity.name,
      serviceType: activeIncident.context.serviceType.name,
      initiatedByRole: activeIncident.context.initiatedByRole.name,
      locationStatus: activeIncident.locationStatus.name,
      adminAcknowledged: activeIncident.adminAcknowledged,
      emergencyServiceCalled: activeIncident.emergencyServiceCalled,
      trustedContactsAlerted: activeIncident.trustedContactsAlerted,
      userMarkedSafe: activeIncident.userMarkedSafe,
      isTestIncident: activeIncident.isTestIncident,
      createdAt: activeIncident.createdAt,
      updatedAt: activeIncident.updatedAt,
      eligibleSosContactCountVerified: eligibleSosContactCountVerified,
      eligibleSosContactCount: eligibleSosContactCountVerified
          ? eligibleSosContactCount
          : null,
    );
  }
}

/// Read-only Phase 47 source adapter.
///
/// Important:
/// - reuses the existing UniversalSafetyService user-scoped read path;
/// - reuses TrustedContactService only to calculate an eligible SOS count;
/// - never exposes raw SafetyIncidentModel or TrustedContactModel upstream;
/// - never writes/acknowledges/assigns/resolves/marks-safe/updates location;
/// - never sends WhatsApp/SMS or places emergency calls.
class AgentEmergencyWhatsAppVerifiedSafetySource {
  AgentEmergencyWhatsAppVerifiedSafetySource({
    UniversalSafetyService? safetyService,
    TrustedContactService? trustedContactService,
  }) : _safetyService = safetyService ?? UniversalSafetyService(),
       _trustedContactService =
           trustedContactService ?? TrustedContactService();

  final UniversalSafetyService _safetyService;
  final TrustedContactService _trustedContactService;
  final AgentEmergencyWhatsAppVerifiedSafetySanitizer _sanitizer =
      const AgentEmergencyWhatsAppVerifiedSafetySanitizer();

  Future<AgentEmergencyWhatsAppVerifiedSafetySnapshot> loadForUser({
    required String userId,
  }) async {
    final String cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return const AgentEmergencyWhatsAppVerifiedSafetySnapshot.unavailable(
        reason: 'Verified safety source requires a non-empty user ID.',
      );
    }

    List<SafetyIncidentModel> incidents;

    try {
      incidents = await _safetyService
          .watchUserIncidents(userId: cleanUserId)
          .first;
    } catch (_) {
      return const AgentEmergencyWhatsAppVerifiedSafetySnapshot.unavailable(
        reason:
            'Verified user-scoped safety incident source is currently unavailable.',
      );
    }

    final List<SafetyIncidentModel> activeIncidents = incidents
        .where((SafetyIncidentModel incident) => incident.isActive)
        .toList(growable: false);

    SafetyIncidentModel? latestActiveIncident;

    if (activeIncidents.isNotEmpty) {
      final List<SafetyIncidentModel> sorted =
          List<SafetyIncidentModel>.from(activeIncidents)..sort(
            (SafetyIncidentModel a, SafetyIncidentModel b) =>
                b.createdAt.compareTo(a.createdAt),
          );

      latestActiveIncident = sorted.first;
    }

    bool countVerified = false;
    int? eligibleSosContactCount;

    try {
      final contacts = await _trustedContactService.getEligibleSosContacts(
        userId: cleanUserId,
      );
      eligibleSosContactCount = contacts.length;
      countVerified = true;
    } catch (_) {
      // Fail partially: incident facts may still be verified while the
      // contact count is explicitly unavailable.
      countVerified = false;
      eligibleSosContactCount = null;
    }

    return _sanitizer.sanitize(
      activeIncident: latestActiveIncident,
      eligibleSosContactCountVerified: countVerified,
      eligibleSosContactCount: eligibleSosContactCount,
    );
  }

  bool get mayWriteSafetyIncident => false;
  bool get mayAcknowledgeIncident => false;
  bool get mayAssignSafetyAgent => false;
  bool get mayResolveIncident => false;
  bool get mayMarkUserSafe => false;
  bool get mayUpdateEmergencyLocation => false;
  bool get mayModifyTrustedContacts => false;
  bool get maySendWhatsApp => false;
  bool get maySendSms => false;
  bool get mayPlaceEmergencyCall => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;
}
