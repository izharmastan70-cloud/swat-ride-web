import 'package:flutter/material.dart';

import '../models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import '../services/agent_security_incident_fresh_owner_claim_verification_service.dart';

class AgentSecurityIncidentFreshOwnerClaimVerificationScreen
    extends StatefulWidget {
  const AgentSecurityIncidentFreshOwnerClaimVerificationScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<AgentSecurityIncidentFreshOwnerClaimVerificationScreen> createState() =>
      _AgentSecurityIncidentFreshOwnerClaimVerificationScreenState();
}

class _AgentSecurityIncidentFreshOwnerClaimVerificationScreenState
    extends State<AgentSecurityIncidentFreshOwnerClaimVerificationScreen> {
  final AgentSecurityIncidentFreshOwnerClaimVerificationService _service =
      AgentSecurityIncidentFreshOwnerClaimVerificationService();

  AgentSecurityIncidentFreshOwnerClaimVerificationResult? _result;
  bool _working = false;

  Future<void> _verify() async {
    if (_working) return;

    setState(() {
      _working = true;
      _result = null;
    });

    final AgentSecurityIncidentFreshOwnerClaimVerificationResult result =
        await _service.verify(currentAdminId: widget.currentAdminId);

    if (!mounted) return;

    setState(() {
      _working = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AgentSecurityIncidentFreshOwnerClaimVerificationResult? result =
        _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Fresh Owner Claim Check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Read-only production identity verification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Checks the current authenticated session for the '
                    'Firebase super_admin custom claim and fresh-login '
                    'requirement. No raw identity value or private claim '
                    'is shown or stored.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Passing this check does NOT attach or arm the Security '
                    'Incident repository and does NOT authorize any rollout '
                    'advance.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _working ? null : _verify,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('VERIFY FRESH OWNER CLAIM'),
          ),
          if (_working) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      result.verified ? 'VERIFIED' : 'BLOCKED',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      'Firebase Super Admin access',
                      _yesNo(result.superAdminAccessVerified),
                    ),
                    _row(
                      'role=super_admin custom claim',
                      _yesNo(result.roleClaimVerified),
                    ),
                    _row(
                      'Current Admin binding',
                      _yesNo(result.uidBindingVerified),
                    ),
                    _row(
                      'Custom-claim authority source',
                      _yesNo(result.customClaimSourceVerified),
                    ),
                    _row('Fresh login', _yesNo(result.freshLoginVerified)),
                    _row('Auth age', _authAgeLabel(result)),
                    _row('Decision', result.reasonCode),
                    const SizedBox(height: 12),
                    Text(
                      result.verified
                          ? 'Fresh Firebase super_admin identity is verified. '
                                'Runtime activation remains separately blocked '
                                'until a later explicit Owner authorization.'
                          : _blockedGuidance(result),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }

  String _yesNo(bool value) => value ? 'YES' : 'NO';

  String _authAgeLabel(
    AgentSecurityIncidentFreshOwnerClaimVerificationResult result,
  ) {
    if (result.authAgeBucket ==
        AgentSecurityIncidentFreshOwnerAuthAgeBucket.fresh) {
      final int seconds = result.boundedAuthAgeSeconds ?? 0;
      return 'FRESH (${seconds}s, max 300s)';
    }

    if (result.authAgeBucket ==
        AgentSecurityIncidentFreshOwnerAuthAgeBucket.stale) {
      return 'STALE (>300s)';
    }

    if (result.authAgeBucket ==
        AgentSecurityIncidentFreshOwnerAuthAgeBucket.futureSkew) {
      return 'INVALID FUTURE SKEW';
    }

    return 'UNAVAILABLE';
  }

  String _blockedGuidance(
    AgentSecurityIncidentFreshOwnerClaimVerificationResult result,
  ) {
    if (result.reasonCode ==
        'fresh_login_required_sign_out_and_sign_in_again_with_normal_otp') {
      return 'Fresh login is required. Sign out and sign in again using the '
          'normal OTP flow, then retry this read-only check.';
    }

    return 'Identity verification is not sufficient. Runtime activation '
        'remains blocked.';
  }
}
