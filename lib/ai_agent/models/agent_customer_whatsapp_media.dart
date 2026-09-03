class AgentCustomerWhatsAppMediaKind {
  AgentCustomerWhatsAppMediaKind._();

  static const String image = 'IMAGE';
  static const String document = 'DOCUMENT';
  static const String location = 'LOCATION';

  static const Set<String> values = <String>{image, document, location};
}

class AgentCustomerWhatsAppMediaDecision {
  const AgentCustomerWhatsAppMediaDecision({
    required this.allowed,
    required this.code,
    required this.requiresHumanReview,
  });

  final bool allowed;
  final String code;
  final bool requiresHumanReview;
}

/// Metadata-only attachment contract.
///
/// Raw attachment bytes, raw coordinates, executable content, OTPs, passwords,
/// and provider credentials do not belong in this AI-facing object.
class AgentCustomerWhatsAppMediaDescriptor {
  const AgentCustomerWhatsAppMediaDescriptor({
    required this.attachmentId,
    required this.kind,
    required this.workflowPurpose,
    required this.userConsented,
    this.mimeType = '',
    this.sizeBytes = 0,
    this.securityScanPassed = false,
    this.locationReferenceId = '',
  });

  final String attachmentId;
  final String kind;
  final String workflowPurpose;
  final bool userConsented;

  /// Image/document metadata only.
  final String mimeType;
  final int sizeBytes;
  final bool securityScanPassed;

  /// For location, use an opaque secure backend reference.
  /// Exact latitude/longitude is intentionally not stored here.
  final String locationReferenceId;

  bool get containsRawBytes => false;
  bool get containsRawCoordinates => false;
  bool get containsAuthority => false;
}

class AgentCustomerWhatsAppMediaPolicy {
  const AgentCustomerWhatsAppMediaPolicy();

  /// SWAT RIDE internal safety cap, independent from any future provider limit.
  /// Owner/config may lower it later; provider limits must never silently
  /// increase this security cap.
  static const int maxImageBytes = 8 * 1024 * 1024;
  static const int maxDocumentBytes = 8 * 1024 * 1024;

  static const Set<String> allowedImageMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static const Set<String> allowedDocumentMimeTypes = <String>{
    'application/pdf',
    'text/plain',
    'image/jpeg',
    'image/png',
  };

  static const Set<String> blockedMimeFragments = <String>{
    'application/x-msdownload',
    'application/x-executable',
    'application/x-sh',
    'application/x-bat',
    'application/zip',
    'application/x-rar',
    'application/x-7z',
  };

  AgentCustomerWhatsAppMediaDecision evaluate(
    AgentCustomerWhatsAppMediaDescriptor media,
  ) {
    if (!AgentCustomerWhatsAppMediaKind.values.contains(media.kind)) {
      return const AgentCustomerWhatsAppMediaDecision(
        allowed: false,
        code: 'UNSUPPORTED_MEDIA_KIND',
        requiresHumanReview: true,
      );
    }

    if (media.attachmentId.trim().isEmpty ||
        media.workflowPurpose.trim().isEmpty) {
      return const AgentCustomerWhatsAppMediaDecision(
        allowed: false,
        code: 'EXPLICIT_WORKFLOW_REQUIRED',
        requiresHumanReview: true,
      );
    }

    if (!media.userConsented) {
      return const AgentCustomerWhatsAppMediaDecision(
        allowed: false,
        code: 'CUSTOMER_CONSENT_REQUIRED',
        requiresHumanReview: false,
      );
    }

    if (media.kind == AgentCustomerWhatsAppMediaKind.location) {
      if (media.locationReferenceId.trim().isEmpty) {
        return const AgentCustomerWhatsAppMediaDecision(
          allowed: false,
          code: 'SECURE_LOCATION_REFERENCE_REQUIRED',
          requiresHumanReview: true,
        );
      }

      return const AgentCustomerWhatsAppMediaDecision(
        allowed: true,
        code: 'SECURE_LOCATION_REFERENCE_ALLOWED',
        requiresHumanReview: false,
      );
    }

    final String mime = media.mimeType.trim().toLowerCase();

    if (blockedMimeFragments.any(mime.contains)) {
      return const AgentCustomerWhatsAppMediaDecision(
        allowed: false,
        code: 'EXECUTABLE_OR_ARCHIVE_BLOCKED',
        requiresHumanReview: true,
      );
    }

    if (media.sizeBytes <= 0) {
      return const AgentCustomerWhatsAppMediaDecision(
        allowed: false,
        code: 'INVALID_MEDIA_SIZE',
        requiresHumanReview: true,
      );
    }

    if (!media.securityScanPassed) {
      return const AgentCustomerWhatsAppMediaDecision(
        allowed: false,
        code: 'SECURITY_SCAN_REQUIRED',
        requiresHumanReview: true,
      );
    }

    if (media.kind == AgentCustomerWhatsAppMediaKind.image) {
      if (!allowedImageMimeTypes.contains(mime) ||
          media.sizeBytes > maxImageBytes) {
        return const AgentCustomerWhatsAppMediaDecision(
          allowed: false,
          code: 'IMAGE_TYPE_OR_SIZE_BLOCKED',
          requiresHumanReview: true,
        );
      }
    }

    if (media.kind == AgentCustomerWhatsAppMediaKind.document) {
      if (!allowedDocumentMimeTypes.contains(mime) ||
          media.sizeBytes > maxDocumentBytes) {
        return const AgentCustomerWhatsAppMediaDecision(
          allowed: false,
          code: 'DOCUMENT_TYPE_OR_SIZE_BLOCKED',
          requiresHumanReview: true,
        );
      }
    }

    return const AgentCustomerWhatsAppMediaDecision(
      allowed: true,
      code: 'MEDIA_ALLOWED_FOR_EXPLICIT_WORKFLOW',
      requiresHumanReview: false,
    );
  }
}
