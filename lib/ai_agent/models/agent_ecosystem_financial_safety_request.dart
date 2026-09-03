import '../constants/agent_ecosystem_financial_safety_constants.dart';

class AgentEcosystemFinancialSafetyRequest {
  AgentEcosystemFinancialSafetyRequest({
    required this.actionType,
    required this.idempotencyKey,
    required this.operationFingerprintSha256,
    required this.trustedSubjectReferenceSha256,
    required this.amountMinor,
    required this.currency,
    required this.trustedIdentityVerified,
    required this.permissionAllowed,
    required this.approvalRequired,
    required this.approvalPresent,
    required this.approvalFresh,
    required this.approvalBindingMatch,
    required this.runtimeGateAllowed,
    required this.emergencyStopActive,
    required this.moduleEnabled,
    required this.reservationAcquired,
    required this.reservationBindingMatch,
    required this.operationAmountCurrencyBindingMatch,
    required this.priorCompletionDetected,
    required this.priorCompletionBindingMatch,
    required this.providerCallbackReplayDetected,
    required this.auditReady,
  }) {
    validate();
  }

  final String actionType;
  final String idempotencyKey;

  /// Safe fingerprints only; no raw customer/payment credential is stored.
  final String operationFingerprintSha256;
  final String trustedSubjectReferenceSha256;

  final int amountMinor;
  final String currency;

  final bool trustedIdentityVerified;
  final bool permissionAllowed;

  final bool approvalRequired;
  final bool approvalPresent;
  final bool approvalFresh;
  final bool approvalBindingMatch;

  final bool runtimeGateAllowed;

  final bool emergencyStopActive;
  final bool moduleEnabled;

  final bool reservationAcquired;
  final bool reservationBindingMatch;
  final bool operationAmountCurrencyBindingMatch;

  final bool priorCompletionDetected;
  final bool priorCompletionBindingMatch;
  final bool providerCallbackReplayDetected;

  final bool auditReady;

  bool get idempotencyIsAuthorization => false;
  bool get financialMetadataOnly => true;
  bool get rawPaymentCredentialStored => false;
  bool get rawCustomerIdentifierStored => false;

  void validate() {
    final sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');
    final currencyPattern = RegExp(r'^[A-Z]{3}$');

    if (!AgentEcosystemFinancialActionType.values.contains(actionType) ||
        idempotencyKey.trim().isEmpty ||
        idempotencyKey.length >
            AgentEcosystemFinancialLimits.idempotencyKeyMaxLength ||
        !sha256.hasMatch(operationFingerprintSha256) ||
        !sha256.hasMatch(trustedSubjectReferenceSha256) ||
        amountMinor <= 0 ||
        !currencyPattern.hasMatch(currency)) {
      throw const FormatException(
        'Invalid ecosystem financial safety request.',
      );
    }
  }
}
