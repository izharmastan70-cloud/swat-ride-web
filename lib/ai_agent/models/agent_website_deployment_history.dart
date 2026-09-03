import 'package:cloud_firestore/cloud_firestore.dart';

import 'agent_website_deployment_plan.dart';

/// Immutable record of one controlled website deployment lifecycle.
///
/// Phase 34 Step 3D.
///
/// This model records state only.
/// It does not deploy, rollback, access secrets, or mutate DNS.
class AgentWebsiteDeploymentHistory {
  final String deploymentId;
  final String changeId;
  final String approvalId;

  final String target;
  final String decision;

  final List<String> approvedFilePaths;

  final String? backupId;

  final bool deploymentAttempted;
  final bool deploymentSucceeded;

  final bool ownerKeepConfirmed;
  final bool rollbackRequested;
  final bool rollbackCompleted;

  final DateTime createdAt;
  final DateTime? deployedAt;
  final DateTime? decidedAt;

  const AgentWebsiteDeploymentHistory({
    required this.deploymentId,
    required this.changeId,
    required this.approvalId,
    required this.target,
    required this.decision,
    required this.approvedFilePaths,
    required this.backupId,
    required this.deploymentAttempted,
    required this.deploymentSucceeded,
    required this.ownerKeepConfirmed,
    required this.rollbackRequested,
    required this.rollbackCompleted,
    required this.createdAt,
    required this.deployedAt,
    required this.decidedAt,
  });

  bool get isProduction =>
      target == AgentWebsiteDeploymentTarget.production;

  bool get isKept =>
      decision == AgentWebsiteDeploymentDecision.kept &&
      ownerKeepConfirmed;

  bool get needsRollback =>
      decision == AgentWebsiteDeploymentDecision.rollbackRequested &&
      rollbackRequested &&
      !rollbackCompleted;

  bool get isRolledBack =>
      decision == AgentWebsiteDeploymentDecision.rolledBack &&
      rollbackRequested &&
      rollbackCompleted;

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'deploymentId': deploymentId,
      'changeId': changeId,
      'approvalId': approvalId,
      'target': target,
      'decision': decision,
      'approvedFilePaths': List<String>.from(approvedFilePaths),
      'backupId': backupId,
      'deploymentAttempted': deploymentAttempted,
      'deploymentSucceeded': deploymentSucceeded,
      'ownerKeepConfirmed': ownerKeepConfirmed,
      'rollbackRequested': rollbackRequested,
      'rollbackCompleted': rollbackCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'deployedAt':
          deployedAt == null ? null : Timestamp.fromDate(deployedAt!),
      'decidedAt':
          decidedAt == null ? null : Timestamp.fromDate(decidedAt!),
    };
  }

  factory AgentWebsiteDeploymentHistory.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final String storedDeploymentId =
        (map['deploymentId'] ?? '').toString().trim();

    final String resolvedDeploymentId =
        storedDeploymentId.isNotEmpty
            ? storedDeploymentId
            : (documentId ?? '').trim();

    final AgentWebsiteDeploymentHistory history =
        AgentWebsiteDeploymentHistory(
      deploymentId: resolvedDeploymentId,
      changeId: (map['changeId'] ?? '').toString().trim(),
      approvalId: (map['approvalId'] ?? '').toString().trim(),
      target: (map['target'] ?? '').toString().trim(),
      decision: (map['decision'] ?? '').toString().trim(),
      approvedFilePaths: _stringList(map['approvedFilePaths']),
      backupId: _nullableString(map['backupId']),
      deploymentAttempted: _bool(map['deploymentAttempted']),
      deploymentSucceeded: _bool(map['deploymentSucceeded']),
      ownerKeepConfirmed: _bool(map['ownerKeepConfirmed']),
      rollbackRequested: _bool(map['rollbackRequested']),
      rollbackCompleted: _bool(map['rollbackCompleted']),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      deployedAt: _date(map['deployedAt']),
      decidedAt: _date(map['decidedAt']),
    );

    history.validate();
    return history;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable<dynamic>) {
      return const <String>[];
    }

    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String normalized =
        value.toString().trim();

    return normalized.isEmpty ? null : normalized;
  }

  static bool _bool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
  void validate() {
    if (deploymentId.trim().isEmpty ||
        changeId.trim().isEmpty ||
        approvalId.trim().isEmpty) {
      throw const AgentWebsiteDeploymentHistoryException(
        'Deployment history identity fields cannot be empty.',
      );
    }

    if (!AgentWebsiteDeploymentTarget.values.contains(target)) {
      throw AgentWebsiteDeploymentHistoryException(
        'Invalid deployment history target: $target',
      );
    }

    if (!AgentWebsiteDeploymentDecision.values.contains(decision)) {
      throw AgentWebsiteDeploymentHistoryException(
        'Invalid deployment history decision: $decision',
      );
    }

    final normalized = approvedFilePaths
        .map((path) => path.trim().replaceAll(r'\', '/'))
        .toList(growable: false);

    if (normalized.isEmpty ||
        normalized.any((path) => path.isEmpty) ||
        normalized.toSet().length != normalized.length) {
      throw const AgentWebsiteDeploymentHistoryException(
        'Deployment history requires a non-empty unique approved file scope.',
      );
    }

    if (deploymentSucceeded && !deploymentAttempted) {
      throw const AgentWebsiteDeploymentHistoryException(
        'Deployment cannot succeed when it was never attempted.',
      );
    }

    if (deploymentSucceeded && deployedAt == null) {
      throw const AgentWebsiteDeploymentHistoryException(
        'Successful deployment requires deployedAt.',
      );
    }

    if (ownerKeepConfirmed &&
        decision != AgentWebsiteDeploymentDecision.kept) {
      throw const AgentWebsiteDeploymentHistoryException(
        'Owner KEEP confirmation requires KEPT decision.',
      );
    }

    if (decision == AgentWebsiteDeploymentDecision.kept &&
        !ownerKeepConfirmed) {
      throw const AgentWebsiteDeploymentHistoryException(
        'KEPT decision requires explicit Owner KEEP confirmation.',
      );
    }

    if (rollbackCompleted && !rollbackRequested) {
      throw const AgentWebsiteDeploymentHistoryException(
        'Completed rollback requires a prior rollback request.',
      );
    }

    if (decision == AgentWebsiteDeploymentDecision.rollbackRequested &&
        !rollbackRequested) {
      throw const AgentWebsiteDeploymentHistoryException(
        'ROLLBACK_REQUESTED decision requires rollbackRequested=true.',
      );
    }

    if (decision == AgentWebsiteDeploymentDecision.rolledBack &&
        (!rollbackRequested || !rollbackCompleted)) {
      throw const AgentWebsiteDeploymentHistoryException(
        'ROLLED_BACK requires requested and completed rollback state.',
      );
    }
  }
}

class AgentWebsiteDeploymentHistoryException implements Exception {
  final String message;

  const AgentWebsiteDeploymentHistoryException(this.message);

  @override
  String toString() =>
      'AgentWebsiteDeploymentHistoryException: $message';
}