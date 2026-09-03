import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_customer_whatsapp_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_control_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/services/agent_customer_whatsapp_control_policy.dart';

void main() {
  const AgentCustomerWhatsAppControlPolicy policy =
      AgentCustomerWhatsAppControlPolicy();

  test('Customer WhatsApp Agent master switch defaults OFF', () {
    final AgentMasterSettings settings = AgentMasterSettings.safeDefaults();

    expect(settings.customerWhatsAppAgentEnabled, isFalse);

    expect(settings.toMap()['customerWhatsAppAgentEnabled'], isFalse);
  });

  test('Admin and Super Admin may control Customer WhatsApp Agent', () {
    expect(
      policy
          .authorizeMasterToggle(
            actorRole: AgentCustomerWhatsAppActorRole.admin,
          )
          .allowed,
      isTrue,
    );

    expect(
      policy
          .authorizeMasterToggle(
            actorRole: AgentCustomerWhatsAppActorRole.superAdmin,
          )
          .allowed,
      isTrue,
    );
  });

  test('customer WhatsApp message cannot grant control-plane authority', () {
    expect(
      policy.authorizeMasterToggle(actorRole: 'customer').allowed,
      isFalse,
    );

    expect(
      AgentCustomerWhatsAppControlPolicy.whatsappMessageIsAuthority,
      isFalse,
    );
  });

  test(
    'agent OFF never disables Admin/Super Admin control plane or core app',
    () {
      const AgentCustomerWhatsAppControlSettings settings =
          AgentCustomerWhatsAppControlSettings(enabled: false);

      expect(settings.adminControlPlaneRemainsAvailable, isTrue);

      expect(settings.coreSwatRideServicesRemainAvailable, isTrue);

      expect(settings.providerTransportEnabled, isFalse);

      expect(settings.outboundMessageExecutionEnabled, isFalse);
    },
  );

  test('service-wise controls require both master and service switch', () {
    const AgentCustomerWhatsAppControlSettings off =
        AgentCustomerWhatsAppControlSettings(enabled: false, rideEnabled: true);

    expect(off.isServiceEnabled(AgentCustomerWhatsAppService.ride), isFalse);

    const AgentCustomerWhatsAppControlSettings on =
        AgentCustomerWhatsAppControlSettings(
          enabled: true,
          rideEnabled: true,
          foodEnabled: false,
        );

    expect(on.isServiceEnabled(AgentCustomerWhatsAppService.ride), isTrue);

    expect(on.isServiceEnabled(AgentCustomerWhatsAppService.food), isFalse);
  });

  test(
    'fare driver payment booking status and availability cannot be guessed',
    () {
      expect(AgentCustomerWhatsAppControlPolicy.mayGuessFare, isFalse);
      expect(AgentCustomerWhatsAppControlPolicy.mayGuessDriver, isFalse);
      expect(AgentCustomerWhatsAppControlPolicy.mayGuessPayment, isFalse);
      expect(AgentCustomerWhatsAppControlPolicy.mayGuessBookingStatus, isFalse);
      expect(AgentCustomerWhatsAppControlPolicy.mayGuessAvailability, isFalse);

      expect(policy.canUseBackendFact(backendVerified: false), isFalse);

      expect(policy.canUseBackendFact(backendVerified: true), isTrue);
    },
  );

  test('sensitive information requires customer verification', () {
    expect(
      policy.requiresCustomerVerification(
        sensitiveAccountDataRequested: true,
        sensitiveBookingDataRequested: false,
        paymentInformationRequested: false,
      ),
      isTrue,
    );

    expect(
      policy.requiresCustomerVerification(
        sensitiveAccountDataRequested: false,
        sensitiveBookingDataRequested: false,
        paymentInformationRequested: false,
      ),
      isFalse,
    );
  });

  test(
    'business action requires Permission Engine and Runtime Gate and approval when required',
    () {
      expect(
        policy.mayExecuteBusinessAction(
          permissionPassed: false,
          approvalRequired: false,
          approvalPassed: false,
          runtimeGatePassed: true,
        ),
        isFalse,
      );

      expect(
        policy.mayExecuteBusinessAction(
          permissionPassed: true,
          approvalRequired: true,
          approvalPassed: false,
          runtimeGatePassed: true,
        ),
        isFalse,
      );

      expect(
        policy.mayExecuteBusinessAction(
          permissionPassed: true,
          approvalRequired: true,
          approvalPassed: true,
          runtimeGatePassed: true,
        ),
        isTrue,
      );
    },
  );

  test(
    'low-cost provider priority remains structured backend then Free then Local then Paid',
    () {
      expect(AgentCustomerWhatsAppControlPolicy.providerPriority, <String>[
        AgentCustomerWhatsAppProviderPolicy.structuredBackend,
        AgentCustomerWhatsAppProviderPolicy.freeOnlineAi,
        AgentCustomerWhatsAppProviderPolicy.localAi,
        AgentCustomerWhatsAppProviderPolicy.paidAi,
      ]);

      expect(
        AgentCustomerWhatsAppControlPolicy.paidCodeAiAllowedForNormalReplies,
        isFalse,
      );
    },
  );

  test(
    'Phase 45 stays separate from Call one-SMS, Owner WhatsApp and Emergency WhatsApp',
    () {
      expect(
        AgentCustomerWhatsAppControlPolicy.callAgentOneSmsRuleChanged,
        isFalse,
      );

      expect(
        AgentCustomerWhatsAppControlPolicy.phase46OwnerAuthorityIncluded,
        isFalse,
      );

      expect(
        AgentCustomerWhatsAppControlPolicy.phase47EmergencyAuthorityIncluded,
        isFalse,
      );
    },
  );

  test(
    'Urdu Pashto and English are explicit supported conversation language contracts',
    () {
      expect(
        AgentCustomerWhatsAppLanguage.values,
        containsAll(<String>[
          AgentCustomerWhatsAppLanguage.urdu,
          AgentCustomerWhatsAppLanguage.pashto,
          AgentCustomerWhatsAppLanguage.english,
        ]),
      );
    },
  );

  test('credentials spam phishing and social engineering remain blocked', () {
    expect(AgentCustomerWhatsAppControlPolicy.mayCollectOtp, isFalse);
    expect(AgentCustomerWhatsAppControlPolicy.mayCollectPassword, isFalse);
    expect(AgentCustomerWhatsAppControlPolicy.mayCollectApiKey, isFalse);
    expect(
      AgentCustomerWhatsAppControlPolicy.mayCollectPaymentCredential,
      isFalse,
    );
    expect(AgentCustomerWhatsAppControlPolicy.bulkSpamAllowed, isFalse);
    expect(AgentCustomerWhatsAppControlPolicy.phishingAllowed, isFalse);
    expect(
      AgentCustomerWhatsAppControlPolicy.socialEngineeringAllowed,
      isFalse,
    );
  });
}
