class AgentEmailEphemeralAuthToken {
  const AgentEmailEphemeralAuthToken({
    required this.firebaseIdToken,
    required this.issuedForUserId,
  });

  final String firebaseIdToken;
  final String issuedForUserId;

  bool get hasToken => firebaseIdToken.trim().isNotEmpty;

  bool get mayPersist => false;
  bool get mayLogValue => false;
  bool get mayExposeInSafeMap => false;

  void validate() {
    if (firebaseIdToken.trim().isEmpty) {
      throw const AgentEmailEphemeralAuthTokenException(
        'Firebase ID token cannot be empty.',
      );
    }

    if (issuedForUserId.trim().isEmpty) {
      throw const AgentEmailEphemeralAuthTokenException(
        'issuedForUserId cannot be empty.',
      );
    }
  }

  Map<String, dynamic> toSafeMetadata() {
    return <String, dynamic>{
      'issuedForUserId': issuedForUserId.trim(),
      'firebaseIdTokenPresent': hasToken,
      'firebaseIdTokenValueIncluded': false,
    };
  }

  @override
  String toString() =>
      'AgentEmailEphemeralAuthToken(firebaseIdToken: [REDACTED], '
      'issuedForUserId: ${issuedForUserId.trim()})';
}

class AgentEmailEphemeralAuthTokenException implements Exception {
  const AgentEmailEphemeralAuthTokenException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailEphemeralAuthTokenException: $message';
}
