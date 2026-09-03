// SWAT RIDE - UNIVERSAL SAFETY & SOS SERVICE
//
// One central Firestore service for:
// - All customers
// - All normal drivers
// - Food customers and delivery riders
// - Restaurant owners/staff
// - Cargo and parcel customers/drivers
// - Parents, guardians, students and school staff
// - Hotel guests, owners and staff
// - Tour customers, guides and tourism drivers
// - Admins and safety agents
//
// Important:
// Every module will connect to this service one-by-one.
// Do not create separate SOS backend services for each module.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/safety_config.dart';
import '../models/safety_models.dart';

class UniversalSafetyService {
  UniversalSafetyService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // CENTRAL FIRESTORE COLLECTIONS
  // ---------------------------------------------------------------------------

  static const String incidentsCollection = 'safety_incidents';

  static const String incidentEventsCollection =
      'safety_incident_events';

  static const String configCollection = 'safety_config';

  static const String mainConfigDocument = 'universal';

  CollectionReference<Map<String, dynamic>>
      get _incidentsRef {
    return _firestore.collection(incidentsCollection);
  }

  CollectionReference<Map<String, dynamic>>
      get _eventsRef {
    return _firestore.collection(incidentEventsCollection);
  }

  DocumentReference<Map<String, dynamic>>
      get _configRef {
    return _firestore
        .collection(configCollection)
        .doc(mainConfigDocument);
  }

  // ---------------------------------------------------------------------------
  // CREATE INCIDENT
  // ---------------------------------------------------------------------------

  /// Creates a new universal SOS incident.
  ///
  /// The same method will be used by Ride, Food, Cargo, Student,
  /// Hotel, Tour and every user/provider/owner role.
  Future<String> createIncident({
    required SafetyContext context,
    required SafetyEmergencyCategory category,
    required SafetySeverity severity,
    String description = '',
    SafetyLocation? currentLocation,
    SafetyLocation? lastKnownLocation,
    SafetyNetworkStatus networkStatus =
        SafetyNetworkStatus.unknown,
    SafetyLocationStatus locationStatus =
        SafetyLocationStatus.unknown,
    bool isSilentSos = false,
    bool isTestIncident = true,
    Map<String, dynamic> metadata =
        const <String, dynamic>{},
  }) async {
    _validateContext(context);

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument = _incidentsRef.doc();

      final DateTime now = DateTime.now();

      final SafetyIncidentModel incident =
          SafetyIncidentModel(
        incidentId: incidentDocument.id,
        context: context,
        category: category,
        severity: severity,
        status: SafetyIncidentStatus.created,
        description: description.trim(),
        currentLocation: currentLocation,
        lastKnownLocation: lastKnownLocation,
        locationHistory: currentLocation == null
            ? const <SafetyLocation>[]
            : <SafetyLocation>[currentLocation],
        networkStatus: networkStatus,
        locationStatus: locationStatus,
        isSilentSos: isSilentSos,
        isTestIncident: isTestIncident,
        createdAt: now,
        updatedAt: now,
        metadata: metadata,
      );

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.set(
        incidentDocument,
        <String, dynamic>{
          ...incident.toMap(),

          // Firestore timestamps make admin sorting reliable.
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: incidentDocument.id,
          eventType: 'incidentCreated',
          status: SafetyIncidentStatus.created,
          performedByUserId: context.initiatedByUserId,
          performedByRole: context.initiatedByRole,
          message: 'Universal safety incident created.',
          metadata: <String, dynamic>{
            'serviceType': context.serviceType.name,
            'referenceId': context.referenceId,
            'category': category.name,
            'severity': severity.name,
            'isSilentSos': isSilentSos,
            'isTestIncident': isTestIncident,
          },
        ),
      );

      await batch.commit();

      return incidentDocument.id;
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to create safety incident: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to create safety incident: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // READ SINGLE INCIDENT
  // ---------------------------------------------------------------------------

  Future<SafetyIncidentModel?> getIncident(
    String incidentId,
  ) async {
    final String cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      throw const UniversalSafetyServiceException(
        message: 'Incident ID is required.',
        code: 'missing-incident-id',
      );
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await _incidentsRef.doc(cleanIncidentId).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return _incidentFromSnapshot(snapshot);
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to load safety incident: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to load safety incident: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // WATCH SINGLE INCIDENT
  // ---------------------------------------------------------------------------

  Stream<SafetyIncidentModel?> watchIncident(
    String incidentId,
  ) {
    final String cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      return Stream<SafetyIncidentModel?>.error(
        const UniversalSafetyServiceException(
          message: 'Incident ID is required.',
          code: 'missing-incident-id',
        ),
      );
    }

    return _incidentsRef
        .doc(cleanIncidentId)
        .snapshots()
        .map(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }

        return _incidentFromSnapshot(snapshot);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WATCH INCIDENTS CREATED BY A USER
  // ---------------------------------------------------------------------------

  Stream<List<SafetyIncidentModel>> watchUserIncidents({
    required String userId,
  }) {
    final String cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return Stream<List<SafetyIncidentModel>>.error(
        const UniversalSafetyServiceException(
          message: 'User ID is required.',
          code: 'missing-user-id',
        ),
      );
    }

    return _incidentsRef
        .where(
          'initiatedByUserId',
          isEqualTo: cleanUserId,
        )
        .snapshots()
        .map(_incidentListFromQuery);
  }

  // ---------------------------------------------------------------------------
  // WATCH INCIDENTS FOR A BOOKING / ORDER / RIDE
  // ---------------------------------------------------------------------------

  Stream<List<SafetyIncidentModel>>
      watchReferenceIncidents({
    required SafetyServiceType serviceType,
    required String referenceId,
  }) {
    final String cleanReferenceId = referenceId.trim();

    if (cleanReferenceId.isEmpty) {
      return Stream<List<SafetyIncidentModel>>.error(
        const UniversalSafetyServiceException(
          message:
              'Ride, order or booking reference ID is required.',
          code: 'missing-reference-id',
        ),
      );
    }

    return _incidentsRef
        .where(
          'referenceId',
          isEqualTo: cleanReferenceId,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<SafetyIncidentModel> incidents =
            _incidentListFromQuery(snapshot);

        return incidents
            .where(
              (SafetyIncidentModel incident) =>
                  incident.context.serviceType ==
                  serviceType,
            )
            .toList();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WATCH ALL ACTIVE INCIDENTS - ADMIN / SAFETY AGENT
  // ---------------------------------------------------------------------------

  Stream<List<SafetyIncidentModel>>
      watchActiveIncidents() {
    return _incidentsRef.snapshots().map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        return _incidentListFromQuery(snapshot)
            .where(
              (SafetyIncidentModel incident) =>
                  incident.isActive,
            )
            .toList();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WATCH INCIDENTS BY SERVICE
  // ---------------------------------------------------------------------------

  Stream<List<SafetyIncidentModel>>
      watchServiceIncidents({
    required SafetyServiceType serviceType,
    bool activeOnly = false,
  }) {
    return _incidentsRef
        .where(
          'serviceType',
          isEqualTo: serviceType.name,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<SafetyIncidentModel> incidents =
            _incidentListFromQuery(snapshot);

        if (!activeOnly) {
          return incidents;
        }

        return incidents
            .where(
              (SafetyIncidentModel incident) =>
                  incident.isActive,
            )
            .toList();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE INCIDENT STATUS
  // ---------------------------------------------------------------------------

  Future<void> updateIncidentStatus({
    required String incidentId,
    required SafetyIncidentStatus status,
    required String performedByUserId,
    required SafetyUserRole performedByRole,
    String message = '',
    Map<String, dynamic> metadata =
        const <String, dynamic>{},
  }) async {
    final String cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      throw const UniversalSafetyServiceException(
        message: 'Incident ID is required.',
        code: 'missing-incident-id',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'statusUpdated',
          status: status,
          performedByUserId: performedByUserId,
          performedByRole: performedByRole,
          message: message.trim().isEmpty
              ? 'Incident status updated to ${status.name}.'
              : message.trim(),
          metadata: metadata,
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to update incident status: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to update incident status: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ADMIN ACKNOWLEDGEMENT
  // ---------------------------------------------------------------------------

  Future<void> acknowledgeIncident({
    required String incidentId,
    required String adminUserId,
    SafetyUserRole adminRole =
        SafetyUserRole.safetyAgent,
  }) async {
    final String cleanIncidentId = incidentId.trim();
    final String cleanAdminUserId = adminUserId.trim();

    if (cleanIncidentId.isEmpty ||
        cleanAdminUserId.isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'Incident ID and admin user ID are required.',
        code: 'missing-acknowledgement-data',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'status':
              SafetyIncidentStatus.acknowledged.name,
          'adminAcknowledged': true,
          'adminAcknowledgedBy': cleanAdminUserId,
          'acknowledgedAt':
              FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'incidentAcknowledged',
          status: SafetyIncidentStatus.acknowledged,
          performedByUserId: cleanAdminUserId,
          performedByRole: adminRole,
          message:
              'Safety incident acknowledged by an authorized admin.',
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to acknowledge incident: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to acknowledge incident: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ASSIGN SAFETY AGENT
  // ---------------------------------------------------------------------------

  Future<void> assignSafetyAgent({
    required String incidentId,
    required String safetyAgentId,
    required String assignedByUserId,
    SafetyUserRole assignedByRole =
        SafetyUserRole.admin,
  }) async {
    final String cleanIncidentId = incidentId.trim();
    final String cleanAgentId = safetyAgentId.trim();
    final String cleanAssignedBy =
        assignedByUserId.trim();

    if (cleanIncidentId.isEmpty ||
        cleanAgentId.isEmpty ||
        cleanAssignedBy.isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'Incident, safety agent and assigning user IDs are required.',
        code: 'missing-agent-assignment-data',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'status':
              SafetyIncidentStatus.agentAssigned.name,
          'assignedSafetyAgentId': cleanAgentId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'safetyAgentAssigned',
          status: SafetyIncidentStatus.agentAssigned,
          performedByUserId: cleanAssignedBy,
          performedByRole: assignedByRole,
          message:
              'A safety agent was assigned to the incident.',
          metadata: <String, dynamic>{
            'assignedSafetyAgentId': cleanAgentId,
          },
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to assign safety agent: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to assign safety agent: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE EMERGENCY LOCATION
  // ---------------------------------------------------------------------------

  Future<void> updateIncidentLocation({
    required String incidentId,
    required SafetyLocation location,
    required String performedByUserId,
    required SafetyUserRole performedByRole,
    bool routeDeviationDetected = false,
  }) async {
    final String cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      throw const UniversalSafetyServiceException(
        message: 'Incident ID is required.',
        code: 'missing-incident-id',
      );
    }

    if (!location.isValid) {
      throw const UniversalSafetyServiceException(
        message: 'A valid emergency location is required.',
        code: 'invalid-location',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'currentLocation': location.toMap(),
          'locationHistory':
              FieldValue.arrayUnion(
            <Map<String, dynamic>>[
              location.toMap(),
            ],
          ),
          'routeDeviationDetected':
              routeDeviationDetected,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'locationUpdated',
          status: SafetyIncidentStatus.responding,
          performedByUserId: performedByUserId,
          performedByRole: performedByRole,
          message: 'Emergency location updated.',
          metadata: <String, dynamic>{
            'location': location.toMap(),
            'routeDeviationDetected':
                routeDeviationDetected,
          },
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to update emergency location: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to update emergency location: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK USER SAFE
  // ---------------------------------------------------------------------------

  Future<void> markUserSafe({
    required String incidentId,
    required String userId,
    required SafetyUserRole userRole,
    required String reason,
  }) async {
    final String cleanIncidentId = incidentId.trim();
    final String cleanUserId = userId.trim();
    final String cleanReason = reason.trim();

    if (cleanIncidentId.isEmpty ||
        cleanUserId.isEmpty ||
        cleanReason.isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'Incident ID, user ID and safety reason are required.',
        code: 'missing-safe-confirmation-data',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'status':
              SafetyIncidentStatus.userMarkedSafe.name,
          'userMarkedSafe': true,
          'resolutionReason': cleanReason,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'userMarkedSafe',
          status:
              SafetyIncidentStatus.userMarkedSafe,
          performedByUserId: cleanUserId,
          performedByRole: userRole,
          message: 'User marked themselves as safe.',
          metadata: <String, dynamic>{
            'reason': cleanReason,
          },
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to mark user safe: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to mark user safe: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // RECORD EMERGENCY SERVICE CALL
  // ---------------------------------------------------------------------------

  Future<void> markEmergencyServiceCalled({
    required String incidentId,
    required String performedByUserId,
    required SafetyUserRole performedByRole,
    String emergencyServiceType = '',
    String phoneNumber = '',
  }) async {
    final String cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      throw const UniversalSafetyServiceException(
        message: 'Incident ID is required.',
        code: 'missing-incident-id',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'status': SafetyIncidentStatus
              .emergencyServiceContacted.name,
          'emergencyServiceCalled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'emergencyServiceCalled',
          status: SafetyIncidentStatus
              .emergencyServiceContacted,
          performedByUserId: performedByUserId,
          performedByRole: performedByRole,
          message:
              'Emergency service contact was recorded.',
          metadata: <String, dynamic>{
            'emergencyServiceType':
                emergencyServiceType.trim(),
            'phoneNumber': phoneNumber.trim(),
          },
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to record emergency call: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to record emergency call: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK TRUSTED CONTACTS ALERTED
  // ---------------------------------------------------------------------------

  Future<void> markTrustedContactsAlerted({
    required String incidentId,
    required String performedByUserId,
    required SafetyUserRole performedByRole,
    int alertedContactCount = 0,
  }) async {
    final String cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      throw const UniversalSafetyServiceException(
        message: 'Incident ID is required.',
        code: 'missing-incident-id',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'trustedContactsAlerted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'trustedContactsAlerted',
          status: SafetyIncidentStatus.alertSent,
          performedByUserId: performedByUserId,
          performedByRole: performedByRole,
          message: 'Trusted contacts were alerted.',
          metadata: <String, dynamic>{
            'alertedContactCount':
                alertedContactCount,
          },
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to record trusted-contact alert: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to record trusted-contact alert: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ADD ADMIN NOTE
  // ---------------------------------------------------------------------------

  Future<void> addAdminNote({
    required String incidentId,
    required String adminUserId,
    required String note,
    SafetyUserRole adminRole =
        SafetyUserRole.safetyAgent,
  }) async {
    final String cleanIncidentId = incidentId.trim();
    final String cleanAdminUserId = adminUserId.trim();
    final String cleanNote = note.trim();

    if (cleanIncidentId.isEmpty ||
        cleanAdminUserId.isEmpty ||
        cleanNote.isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'Incident ID, admin ID and note are required.',
        code: 'missing-admin-note-data',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'adminNotes': FieldValue.arrayUnion(
            <String>[cleanNote],
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'adminNoteAdded',
          status:
              SafetyIncidentStatus.underInvestigation,
          performedByUserId: cleanAdminUserId,
          performedByRole: adminRole,
          message: cleanNote,
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to add admin note: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to add admin note: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // RESOLVE INCIDENT
  // ---------------------------------------------------------------------------

  Future<void> resolveIncident({
    required String incidentId,
    required String resolvedByUserId,
    required SafetyUserRole resolvedByRole,
    required String resolutionReason,
  }) async {
    final String cleanIncidentId = incidentId.trim();
    final String cleanResolvedBy =
        resolvedByUserId.trim();
    final String cleanReason = resolutionReason.trim();

    if (cleanIncidentId.isEmpty ||
        cleanResolvedBy.isEmpty ||
        cleanReason.isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'Incident ID, resolving user and resolution reason are required.',
        code: 'missing-resolution-data',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'status': SafetyIncidentStatus.resolved.name,
          'resolutionReason': cleanReason,
          'resolvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'incidentResolved',
          status: SafetyIncidentStatus.resolved,
          performedByUserId: cleanResolvedBy,
          performedByRole: resolvedByRole,
          message: cleanReason,
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to resolve incident: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to resolve incident: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK FALSE ALARM
  // ---------------------------------------------------------------------------

  Future<void> markFalseAlarm({
    required String incidentId,
    required String performedByUserId,
    required SafetyUserRole performedByRole,
    required String reason,
  }) async {
    final String cleanIncidentId = incidentId.trim();
    final String cleanUserId = performedByUserId.trim();
    final String cleanReason = reason.trim();

    if (cleanIncidentId.isEmpty ||
        cleanUserId.isEmpty ||
        cleanReason.isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'Incident ID, user ID and false-alarm reason are required.',
        code: 'missing-false-alarm-data',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          incidentDocument =
          _incidentsRef.doc(cleanIncidentId);

      final DocumentReference<Map<String, dynamic>>
          eventDocument = _eventsRef.doc();

      final WriteBatch batch = _firestore.batch();

      batch.update(
        incidentDocument,
        <String, dynamic>{
          'status':
              SafetyIncidentStatus.falseAlarm.name,
          'falseAlarm': true,
          'resolutionReason': cleanReason,
          'resolvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        eventDocument,
        _buildEventData(
          eventId: eventDocument.id,
          incidentId: cleanIncidentId,
          eventType: 'incidentMarkedFalseAlarm',
          status: SafetyIncidentStatus.falseAlarm,
          performedByUserId: cleanUserId,
          performedByRole: performedByRole,
          message: cleanReason,
        ),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to mark false alarm: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message: 'Unable to mark false alarm: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // INCIDENT EVENT TIMELINE
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>>
      watchIncidentEvents(
    String incidentId,
  ) {
    final String cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.error(
        const UniversalSafetyServiceException(
          message: 'Incident ID is required.',
          code: 'missing-incident-id',
        ),
      );
    }

    return _eventsRef
        .where(
          'incidentId',
          isEqualTo: cleanIncidentId,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<Map<String, dynamic>> events =
            snapshot.docs.map(
          (
            QueryDocumentSnapshot<Map<String, dynamic>>
                document,
          ) {
            return <String, dynamic>{
              ...document.data(),
              'eventId': document.id,
            };
          },
        ).toList();

        events.sort(
          (
            Map<String, dynamic> first,
            Map<String, dynamic> second,
          ) {
            final DateTime firstDate =
                _dateFromDynamic(first['createdAt']) ??
                    DateTime.fromMillisecondsSinceEpoch(0);

            final DateTime secondDate =
                _dateFromDynamic(second['createdAt']) ??
                    DateTime.fromMillisecondsSinceEpoch(0);

            return firstDate.compareTo(secondDate);
          },
        );

        return events;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SAFETY CONFIGURATION
  // ---------------------------------------------------------------------------

  Future<UniversalSafetyConfig>
      getSafetyConfig() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _configRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        return defaultUniversalSafetyConfig();
      }

      return UniversalSafetyConfig.fromMap(
        snapshot.data()!,
      );
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to load safety configuration: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to load safety configuration: $error',
      );
    }
  }

  Stream<UniversalSafetyConfig>
      watchSafetyConfig() {
    return _configRef.snapshots().map(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!snapshot.exists || snapshot.data() == null) {
          return defaultUniversalSafetyConfig();
        }

        return UniversalSafetyConfig.fromMap(
          snapshot.data()!,
        );
      },
    );
  }

  /// Only an authorized admin/super admin should call this method.
  ///
  /// Firestore security rules will later enforce that permission.
  Future<void> saveSafetyConfig({
    required UniversalSafetyConfig config,
    required String updatedByUserId,
  }) async {
    final String cleanUpdatedBy =
        updatedByUserId.trim();

    if (cleanUpdatedBy.isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'Admin user ID is required to update safety configuration.',
        code: 'missing-admin-id',
      );
    }

    try {
      await _configRef.set(
        <String, dynamic>{
          ...config.toMap(),
          'updatedBy': cleanUpdatedBy,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to save safety configuration: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw UniversalSafetyServiceException(
        message:
            'Unable to save safety configuration: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPERS
  // ---------------------------------------------------------------------------

  void _validateContext(SafetyContext context) {
    if (context.referenceId.trim().isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'Ride, order or booking reference ID is required.',
        code: 'missing-reference-id',
      );
    }

    if (context.initiatedByUserId.trim().isEmpty) {
      throw const UniversalSafetyServiceException(
        message:
            'The user creating the safety incident is required.',
        code: 'missing-user-id',
      );
    }
  }

  SafetyIncidentModel _incidentFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      snapshot.data() ?? <String, dynamic>{},
    );

    data['incidentId'] = snapshot.id;

    return SafetyIncidentModel.fromMap(data);
  }

  List<SafetyIncidentModel> _incidentListFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<SafetyIncidentModel> incidents =
        snapshot.docs
            .map(_incidentFromQueryDocument)
            .toList();

    incidents.sort(
      (
        SafetyIncidentModel first,
        SafetyIncidentModel second,
      ) {
        return second.createdAt.compareTo(first.createdAt);
      },
    );

    return incidents;
  }

  SafetyIncidentModel _incidentFromQueryDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(document.data());

    data['incidentId'] = document.id;

    return SafetyIncidentModel.fromMap(data);
  }

  Map<String, dynamic> _buildEventData({
    required String eventId,
    required String incidentId,
    required String eventType,
    required SafetyIncidentStatus status,
    required String performedByUserId,
    required SafetyUserRole performedByRole,
    required String message,
    Map<String, dynamic> metadata =
        const <String, dynamic>{},
  }) {
    return <String, dynamic>{
      'eventId': eventId,
      'incidentId': incidentId,
      'eventType': eventType,
      'status': status.name,
      'performedByUserId': performedByUserId.trim(),
      'performedByRole': performedByRole.name,
      'message': message.trim(),
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  DateTime? _dateFromDynamic(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

/// Safe exception returned by the universal safety service.
class UniversalSafetyServiceException implements Exception {
  const UniversalSafetyServiceException({
    required this.message,
    this.code = 'universal-safety-error',
  });

  final String message;
  final String code;

  @override
  String toString() {
    return 'UniversalSafetyServiceException'
        '(code: $code, message: $message)';
  }
}