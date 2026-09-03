import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_versioning_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_version_record.dart';
import 'package:swat_ride/ai_agent/services/agent_version_change_classification_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_version_contract_service.dart';

void main() {
  const AgentVersionChangeClassificationPolicy classificationPolicy =
      AgentVersionChangeClassificationPolicy();

  const AgentVersionContractService contractService =
      AgentVersionContractService();

  const String sha256 =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  AgentVersionRecord proposed({
    String versionId = 'ride_agent:v1.1.0',
    String agentId = 'ride_agent',
    String semanticVersion = '1.1.0',
    String? previousVersionId = 'ride_agent:v1.0.0',
    String changeType = AgentVersionChangeType.behaviorPrompt,
    String changeCode = 'improve_booking_clarification',
  }) {
    return contractService.createProposedVersion(
      versionId: versionId,
      agentId: agentId,
      semanticVersion: semanticVersion,
      previousVersionId: previousVersionId,
      changeType: changeType,
      changeCode: changeCode,
      artifactFingerprintSha256: sha256,
      proposedAtUtc: DateTime.utc(2026, 8, 24),
    );
  }

  group('Phase 62 Step 1B change classification', () {
    test('prompt model strategy changes are high-risk', () {
      for (final String type in <String>[
        AgentVersionChangeType.behaviorPrompt,
        AgentVersionChangeType.modelOrProvider,
        AgentVersionChangeType.orchestrationStrategy,
      ]) {
        final result = classificationPolicy.classify(type);

        expect(result.risk, AgentVersionChangeRisk.high);
        expect(result.versionable, true);
        expect(result.offlineEvaluationRequired, true);
        expect(result.humanApprovalRequired, true);
        expect(result.securityReviewRequired, true);
        expect(result.mayDirectlyDeploy, false);
      }
    });

    test('tool and knowledge changes remain evaluation-gated', () {
      final tool = classificationPolicy.classify(
        AgentVersionChangeType.toolSelectionPolicy,
      );
      final knowledge = classificationPolicy.classify(
        AgentVersionChangeType.knowledgeReference,
      );

      expect(tool.risk, AgentVersionChangeRisk.medium);
      expect(tool.securityReviewRequired, true);
      expect(knowledge.risk, AgentVersionChangeRisk.medium);
      expect(tool.offlineEvaluationRequired, true);
      expect(knowledge.offlineEvaluationRequired, true);
    });

    test('format-only change is low-risk but still evaluated', () {
      final result = classificationPolicy.classify(
        AgentVersionChangeType.outputFormatting,
      );

      expect(result.risk, AgentVersionChangeRisk.low);
      expect(result.versionable, true);
      expect(result.offlineEvaluationRequired, true);
      expect(result.mayActivateProduction, false);
    });

    test('protected authority families fail closed', () {
      for (final String type
          in AgentVersionChangeType.protectedAuthorityValues) {
        final result = classificationPolicy.classify(type);

        expect(result.risk, AgentVersionChangeRisk.blockedProtectedAuthority);
        expect(result.versionable, false);
        expect(result.blockedProtectedAuthority, true);
        expect(result.mayGrantPermission, false);
        expect(result.mayConsumeApproval, false);
        expect(result.mayChangeProviderPolicy, false);
        expect(result.mayChangeCostLimits, false);
        expect(result.mayChangeProductionAuthority, false);
      }
    });
  });

  group('Phase 62 Step 1B immutable version identity', () {
    test('valid proposed version is metadata-only and rollback-linked', () {
      final record = proposed();

      expect(record.contractVersion, AgentVersionContract.contractVersion);
      expect(record.status, AgentVersionLifecycleStatus.proposed);
      expect(record.changeRisk, AgentVersionChangeRisk.high);
      expect(record.immutableIdentity, true);
      expect(record.metadataOnly, true);
      expect(record.rollbackLinkAvailable, true);
      expect(record.productionActive, false);
      expect(record.deploymentPerformed, false);
      expect(record.rollbackPerformed, false);
    });

    test('version record exposes no raw/private/secret/token payload', () {
      final record = proposed();

      expect(record.rawPromptStored, false);
      expect(record.rawModelPayloadStored, false);
      expect(record.privateConversationStored, false);
      expect(record.secretsStored, false);
      expect(record.authTokenStored, false);
      expect(record.approvalTokenStored, false);
      expect(record.permissionTokenStored, false);
    });

    test('invalid semantic version fails closed', () {
      expect(() => proposed(semanticVersion: 'v1.1'), throwsFormatException);
    });

    test('unsafe email-like version id fails closed', () {
      expect(
        () => proposed(versionId: 'owner@example.com'),
        throwsFormatException,
      );
    });

    test('version cannot point to itself as previous version', () {
      expect(
        () => proposed(
          versionId: 'ride_agent:v1.1.0',
          previousVersionId: 'ride_agent:v1.1.0',
        ),
        throwsFormatException,
      );
    });

    test('protected Permission change cannot become proposed version', () {
      expect(
        () => proposed(changeType: AgentVersionChangeType.protectedPermissions),
        throwsStateError,
      );
    });
  });

  group('Phase 62 Step 1B authority boundary', () {
    test('contract service grants no runtime or deployment authority', () {
      expect(contractService.reusesPhase42EvaluationEvidence, true);
      expect(contractService.immutableVersionIdentityRequired, true);
      expect(
        contractService.previousVersionRollbackLinkRequiredForUpgrade,
        true,
      );

      expect(contractService.persistsVersion, false);
      expect(contractService.callsProvider, false);
      expect(contractService.trainsModel, false);
      expect(contractService.mutatesPrompt, false);
      expect(contractService.deploysVersion, false);
      expect(contractService.activatesProduction, false);
      expect(contractService.performsRollback, false);
      expect(contractService.grantsPermission, false);
      expect(contractService.consumesApproval, false);
      expect(contractService.assignsRole, false);
      expect(contractService.mutatesProviderPolicy, false);
      expect(contractService.mutatesCostLimit, false);
      expect(contractService.mutatesSecurity, false);
      expect(contractService.writesBusinessData, false);
    });

    test('classification policy itself has no authority', () {
      expect(classificationPolicy.grantsPermission, false);
      expect(classificationPolicy.consumesApproval, false);
      expect(classificationPolicy.trainsModel, false);
      expect(classificationPolicy.mutatesPrompt, false);
      expect(classificationPolicy.changesProviderPolicy, false);
      expect(classificationPolicy.changesCostLimits, false);
      expect(classificationPolicy.activatesProduction, false);
      expect(classificationPolicy.deploysVersion, false);
    });
  });
}
