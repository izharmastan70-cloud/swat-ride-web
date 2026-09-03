import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_role.dart';

// =========================================================
// AGENT ROLE SERVICE
// =========================================================
//
// Firestore collection: agent_roles only.
// Phase 1 client-side validation is NOT a substitute for Firestore
// Security Rules / trusted backend enforcement.

class AgentRoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'agent_roles';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  AgentRole _readSafely(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final AgentRole raw = AgentRole.fromSnapshot(snapshot);
    return raw.isValid ? raw : raw.failClosed();
  }

  void _ensureOrdinaryWriteAllowed(AgentRole role) {
    if (role.isFailClosed) {
      throw const AgentRoleValidationException(
        'Corrupted agent role is locked. Repair the stored role before '
        'changing it.',
      );
    }
    role.validate();
  }

  Future<AgentRole?> getRole(String roleId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection.doc(roleId).get();

    if (!snapshot.exists) return null;
    return _readSafely(snapshot);
  }

  Future<List<AgentRole>> getAllRoles() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection.get();

    final List<AgentRole> roles = snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              _readSafely(doc),
        )
        .toList(growable: false);

    return roles;
  }

  Stream<List<AgentRole>> watchAllRoles() {
    return _collection.orderBy('roleId').snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<AgentRole> roles = snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  _readSafely(doc),
            )
            .toList(growable: false);
        return roles;
      },
    );
  }

  Stream<AgentRole?> watchRole(String roleId) {
    return _collection.doc(roleId).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (!snapshot.exists) return null;
        return _readSafely(snapshot);
      },
    );
  }

  Future<void> createRole(AgentRole role) async {
    _ensureOrdinaryWriteAllowed(role);
    await _collection.doc(role.roleId).set(role.toMap());
  }

  Future<void> createRoleIfNotExists(AgentRole role) async {
    _ensureOrdinaryWriteAllowed(role);

    final DocumentSnapshot<Map<String, dynamic>> existing =
        await _collection.doc(role.roleId).get();

    if (existing.exists) return;
    await _collection.doc(role.roleId).set(role.toMap());
  }

  Future<void> updateRole(AgentRole role) async {
    _ensureOrdinaryWriteAllowed(role);

    final AgentRole updated = role.copyWith(updatedAt: DateTime.now());
    _ensureOrdinaryWriteAllowed(updated);

    await _collection.doc(updated.roleId).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> updateMode({
    required String roleId,
    required String mode,
  }) async {
    final AgentRole? existing = await getRole(roleId);
    if (existing == null) {
      throw Exception('Agent role "$roleId" not found.');
    }

    _ensureOrdinaryWriteAllowed(existing);

    final AgentRole updated = existing.copyWith(mode: mode);
    _ensureOrdinaryWriteAllowed(updated);

    await _collection.doc(roleId).update(<String, dynamic>{
      'mode': mode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setEnabled({
    required String roleId,
    required bool enabled,
  }) async {
    final AgentRole? existing = await getRole(roleId);
    if (existing == null) {
      throw Exception('Agent role "$roleId" not found.');
    }

    _ensureOrdinaryWriteAllowed(existing);

    final AgentRole updated = existing.copyWith(enabled: enabled);
    _ensureOrdinaryWriteAllowed(updated);

    await _collection.doc(roleId).update(<String, dynamic>{
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isRoleAiClassValid(String roleId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection.doc(roleId).get();

    if (!snapshot.exists) return false;
    return AgentRole.fromSnapshot(snapshot).isValid;
  }
}
