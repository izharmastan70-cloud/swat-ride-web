import '../constants/agent_email_constants.dart';

class AgentEmailAddress {
  const AgentEmailAddress({required this.address, this.displayName = ''});

  final String address;
  final String displayName;

  String get normalizedAddress => address.trim().toLowerCase();

  void validate() {
    final String value = normalizedAddress;

    if (value.isEmpty ||
        value.contains('\n') ||
        value.contains('\r') ||
        !_emailPattern.hasMatch(value)) {
      throw AgentEmailDraftException('Invalid email address "$address".');
    }

    if (displayName.contains('\n') || displayName.contains('\r')) {
      throw const AgentEmailDraftException(
        'Email display name cannot contain line breaks.',
      );
    }
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'address': address.trim(),
    'displayName': displayName.trim(),
  };

  factory AgentEmailAddress.fromMap(Map<String, dynamic> map) {
    final AgentEmailAddress value = AgentEmailAddress(
      address: (map['address'] ?? '').toString(),
      displayName: (map['displayName'] ?? '').toString(),
    );

    value.validate();
    return value;
  }

  static final RegExp _emailPattern = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );
}

class AgentEmailAttachmentRef {
  const AgentEmailAttachmentRef({
    required this.attachmentId,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
  });

  final String attachmentId;
  final String fileName;
  final String contentType;
  final int sizeBytes;

  void validate() {
    if (attachmentId.trim().isEmpty ||
        fileName.trim().isEmpty ||
        contentType.trim().isEmpty) {
      throw const AgentEmailDraftException(
        'Attachment metadata cannot be empty.',
      );
    }

    if (fileName.contains('\n') || fileName.contains('\r')) {
      throw const AgentEmailDraftException(
        'Attachment file name cannot contain line breaks.',
      );
    }

    if (sizeBytes < 0) {
      throw const AgentEmailDraftException(
        'Attachment size cannot be negative.',
      );
    }
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'attachmentId': attachmentId.trim(),
    'fileName': fileName.trim(),
    'contentType': contentType.trim(),
    'sizeBytes': sizeBytes,
  };

  factory AgentEmailAttachmentRef.fromMap(Map<String, dynamic> map) {
    final AgentEmailAttachmentRef value = AgentEmailAttachmentRef(
      attachmentId: (map['attachmentId'] ?? '').toString(),
      fileName: (map['fileName'] ?? '').toString(),
      contentType: (map['contentType'] ?? '').toString(),
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? -1,
    );

    value.validate();
    return value;
  }
}

/// Structured Phase 44 email draft.
///
/// This is intentionally a DRAFT-ONLY contract. It does not send email,
/// open SMTP/network connections, grant permission, consume approval,
/// execute runtime actions, mutate prompts/models, or deploy anything.
class AgentEmailDraft {
  AgentEmailDraft({
    required this.draftId,
    required this.purpose,
    required this.senderIdentityId,
    required List<AgentEmailAddress> to,
    List<AgentEmailAddress> cc = const <AgentEmailAddress>[],
    List<AgentEmailAddress> bcc = const <AgentEmailAddress>[],
    required this.subject,
    required this.bodyText,
    this.replyToMessageId = '',
    List<AgentEmailAttachmentRef> attachments =
        const <AgentEmailAttachmentRef>[],
    this.status = AgentEmailDraftStatus.draft,
    required this.createdAt,
  }) : to = List<AgentEmailAddress>.unmodifiable(to),
       cc = List<AgentEmailAddress>.unmodifiable(cc),
       bcc = List<AgentEmailAddress>.unmodifiable(bcc),
       attachments = List<AgentEmailAttachmentRef>.unmodifiable(attachments);

  final String draftId;
  final String purpose;

  /// Logical sender identity only. Phase 44-B1 does not resolve credentials.
  final String senderIdentityId;

  final List<AgentEmailAddress> to;
  final List<AgentEmailAddress> cc;
  final List<AgentEmailAddress> bcc;

  final String subject;
  final String bodyText;
  final String replyToMessageId;
  final List<AgentEmailAttachmentRef> attachments;
  final String status;
  final DateTime createdAt;

  bool get requiresApprovalToSend => true;
  bool get maySend => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayOpenNetworkConnection => false;
  bool get mayReadMailbox => false;
  bool get mayWriteMailbox => false;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  List<AgentEmailAddress> get allRecipients =>
      List<AgentEmailAddress>.unmodifiable(<AgentEmailAddress>[
        ...to,
        ...cc,
        ...bcc,
      ]);

  void validate() {
    if (draftId.trim().isEmpty) {
      throw const AgentEmailDraftException('Email draftId cannot be empty.');
    }

    if (!AgentEmailPurpose.values.contains(purpose)) {
      throw AgentEmailDraftException('Invalid email purpose "$purpose".');
    }

    if (senderIdentityId.trim().isEmpty) {
      throw const AgentEmailDraftException('Sender identity must be explicit.');
    }

    if (to.isEmpty) {
      throw const AgentEmailDraftException(
        'At least one explicit TO recipient is required.',
      );
    }

    for (final AgentEmailAddress recipient in allRecipients) {
      recipient.validate();
    }

    final Set<String> recipientSet = <String>{};

    for (final AgentEmailAddress recipient in allRecipients) {
      if (!recipientSet.add(recipient.normalizedAddress)) {
        throw AgentEmailDraftException(
          'Duplicate recipient "${recipient.normalizedAddress}" '
          'across TO/CC/BCC is not allowed.',
        );
      }
    }

    final String cleanSubject = subject.trim();

    if (cleanSubject.isEmpty ||
        subject.contains('\n') ||
        subject.contains('\r')) {
      throw const AgentEmailDraftException(
        'Email subject must be non-empty and single-line.',
      );
    }

    if (cleanSubject.length > 200) {
      throw const AgentEmailDraftException(
        'Email subject exceeds the Phase 44 safe limit.',
      );
    }

    if (bodyText.trim().isEmpty) {
      throw const AgentEmailDraftException('Email body cannot be empty.');
    }

    if (!AgentEmailDraftStatus.values.contains(status)) {
      throw AgentEmailDraftException('Invalid email draft status "$status".');
    }

    final Set<String> attachmentIds = <String>{};

    for (final AgentEmailAttachmentRef attachment in attachments) {
      attachment.validate();

      if (!attachmentIds.add(attachment.attachmentId.trim())) {
        throw AgentEmailDraftException(
          'Duplicate attachmentId "${attachment.attachmentId}".',
        );
      }
    }

    if (!requiresApprovalToSend || maySend) {
      throw const AgentEmailDraftException(
        'Phase 44-B1 email drafts must remain approval-required and unsendable.',
      );
    }
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'draftId': draftId.trim(),
    'purpose': purpose,
    'senderIdentityId': senderIdentityId.trim(),
    'to': to.map((AgentEmailAddress item) => item.toMap()).toList(),
    'cc': cc.map((AgentEmailAddress item) => item.toMap()).toList(),
    'bcc': bcc.map((AgentEmailAddress item) => item.toMap()).toList(),
    'subject': subject.trim(),
    'bodyText': bodyText,
    'replyToMessageId': replyToMessageId.trim(),
    'attachments': attachments
        .map((AgentEmailAttachmentRef item) => item.toMap())
        .toList(),
    'status': status,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'requiresApprovalToSend': true,
    'maySend': false,
  };

  factory AgentEmailDraft.fromMap(Map<String, dynamic> map) {
    List<AgentEmailAddress> addresses(String key) {
      final Object? raw = map[key];

      if (raw is! List) {
        return const <AgentEmailAddress>[];
      }

      return raw
          .whereType<Map>()
          .map(
            (Map value) =>
                AgentEmailAddress.fromMap(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    }

    final List<AgentEmailAttachmentRef> attachmentValues =
        (map['attachments'] is List)
        ? (map['attachments'] as List)
              .whereType<Map>()
              .map(
                (Map value) => AgentEmailAttachmentRef.fromMap(
                  Map<String, dynamic>.from(value),
                ),
              )
              .toList(growable: false)
        : const <AgentEmailAttachmentRef>[];

    final AgentEmailDraft value = AgentEmailDraft(
      draftId: (map['draftId'] ?? '').toString(),
      purpose: (map['purpose'] ?? '').toString(),
      senderIdentityId: (map['senderIdentityId'] ?? '').toString(),
      to: addresses('to'),
      cc: addresses('cc'),
      bcc: addresses('bcc'),
      subject: (map['subject'] ?? '').toString(),
      bodyText: (map['bodyText'] ?? '').toString(),
      replyToMessageId: (map['replyToMessageId'] ?? '').toString(),
      attachments: attachmentValues,
      status: (map['status'] ?? AgentEmailDraftStatus.draft).toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString())?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

    value.validate();
    return value;
  }
}

class AgentEmailDraftException implements Exception {
  const AgentEmailDraftException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailDraftException: $message';
}
