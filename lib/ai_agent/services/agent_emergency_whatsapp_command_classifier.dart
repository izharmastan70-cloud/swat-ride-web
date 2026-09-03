import '../models/agent_emergency_whatsapp_foundation.dart';

class AgentEmergencyWhatsAppCommandClassification {
  const AgentEmergencyWhatsAppCommandClassification({
    required this.commandClass,
    required this.reasonCode,
    required this.requiresClarification,
  });

  final AgentEmergencyWhatsAppCommandClass commandClass;
  final String reasonCode;
  final bool requiresClarification;

  bool get mayGrantAuthority => false;
  bool get mayReadSafetyBackend => false;
  bool get mayCreateApproval => false;
  bool get mayConsumeApproval => false;
  bool get mayCreateSafetyIncident => false;
  bool get mayMutateSafetyIncident => false;
  bool get maySendWhatsApp => false;
  bool get maySendSms => false;
  bool get mayPlaceEmergencyCall => false;
  bool get mayCallProvider => false;
  bool get mayHandleWebhook => false;
  bool get mayDeploy => false;
}

class AgentEmergencyWhatsAppCommandClassifier {
  const AgentEmergencyWhatsAppCommandClassifier();

  AgentEmergencyWhatsAppCommandClassification classify(String message) {
    final String normalized = _normalize(message);

    if (normalized.isEmpty) {
      return const AgentEmergencyWhatsAppCommandClassification(
        commandClass: AgentEmergencyWhatsAppCommandClass.forbidden,
        reasonCode: 'EMPTY_OR_UNUSABLE_INPUT',
        requiresClarification: true,
      );
    }

    if (_containsCredentialRequest(normalized)) {
      return const AgentEmergencyWhatsAppCommandClassification(
        commandClass: AgentEmergencyWhatsAppCommandClass.forbidden,
        reasonCode: 'CREDENTIAL_OR_SECRET_REQUEST_FORBIDDEN',
        requiresClarification: false,
      );
    }

    // Explicit danger/help phrases have highest emergency intent priority.
    if (_containsStrongEmergencyEscalationIntent(normalized)) {
      return const AgentEmergencyWhatsAppCommandClassification(
        commandClass:
            AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
        reasonCode: 'EXPLICIT_EMERGENCY_HELP_REQUEST',
        requiresClarification: false,
      );
    }

    // Exact GPS/contact/medical requests remain sensitive/default-deny.
    if (_containsSensitiveSafetyDataRequest(normalized)) {
      return const AgentEmergencyWhatsAppCommandClassification(
        commandClass: AgentEmergencyWhatsAppCommandClass.sensitiveSafetyData,
        reasonCode: 'SENSITIVE_SAFETY_DATA_REQUEST',
        requiresClarification: false,
      );
    }

    // Status/read intent MUST be checked before standalone SOS fallback.
    if (_containsVerifiedSafetyStatusIntent(normalized)) {
      return const AgentEmergencyWhatsAppCommandClassification(
        commandClass:
            AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus,
        reasonCode: 'VERIFIED_SAFETY_STATUS_REQUEST',
        requiresClarification: false,
      );
    }

    // Short standalone SOS signals are explicit escalation intent, but they
    // are deliberately checked only after status/read phrases.
    if (_isStandaloneSosSignal(normalized)) {
      return const AgentEmergencyWhatsAppCommandClassification(
        commandClass:
            AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
        reasonCode: 'EXPLICIT_STANDALONE_SOS_SIGNAL',
        requiresClarification: false,
      );
    }

    return const AgentEmergencyWhatsAppCommandClassification(
      commandClass: AgentEmergencyWhatsAppCommandClass.forbidden,
      reasonCode: 'UNKNOWN_OR_AMBIGUOUS_EMERGENCY_COMMAND',
      requiresClarification: true,
    );
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s@._+-]', unicode: true), ' ');
  }

  bool _containsCredentialRequest(String text) {
    const List<String> blocked = <String>[
      'otp',
      'password',
      'passcode',
      'pin code',
      'cvv',
      'cvc',
      'card number',
      'access token',
      'refresh token',
      'api key',
      'private key',
      'secret key',
      'authorization token',
      'cookie',
      'login code',
    ];

    return blocked.any(text.contains);
  }

  bool _containsStrongEmergencyEscalationIntent(String text) {
    const List<String> phrases = <String>[
      'send help',
      'help me now',
      'emergency help',
      'need help now',
      'need emergency help',
      'call police',
      'call ambulance',
      'call emergency',
      'send police',
      'send ambulance',
      'i am in danger',
      'im in danger',
      'danger now',
      'mujhe madad chahiye',
      'mujhe help chahiye',
      'madad bhejo',
      'help bhejo',
      'police bulao',
      'ambulance bulao',
      'emergency hai',
      'jaan ko khatra',
      'jan ko khatra',
    ];

    return phrases.any(text.contains);
  }

  bool _containsSensitiveSafetyDataRequest(String text) {
    const List<String> phrases = <String>[
      'exact location',
      'exact gps',
      'gps coordinates',
      'latitude',
      'longitude',
      'live location',
      'trusted contact phone',
      'trusted contact number',
      'emergency contact number',
      'medical profile',
      'medical condition',
      'blood group',
      'allergy',
      'allergies',
      'medicine',
      'medicines',
      'meri exact location',
      'mera exact location',
      'contact ka number',
      'medical data',
    ];

    return phrases.any(text.contains);
  }

  bool _containsVerifiedSafetyStatusIntent(String text) {
    const List<String> phrases = <String>[
      'safety status',
      'sos status',
      'emergency status',
      'incident status',
      'is my sos active',
      'is sos active',
      'is there an active incident',
      'has admin acknowledged',
      'trusted contacts alerted',
      'emergency service called',
      'am i marked safe',
      'status batao',
      'sos ka status',
      'emergency ka status',
      'incident ka status',
      'mera sos active hai',
      'admin ne acknowledge kiya',
      'contacts alert hue',
    ];

    return phrases.any(text.contains);
  }

  bool _isStandaloneSosSignal(String text) {
    return text == 'sos' ||
        text == 'sos help' ||
        text == 'sos now' ||
        text == 'sos emergency';
  }
}
