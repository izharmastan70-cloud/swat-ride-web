// =========================================================
// AI AGENT — STUDENT RIDE SNAPSHOT
// =========================================================
//
// Privacy-minimized view intended for a future trusted connector.
// No child phone number, medical profile, PIN/QR secret or exact live
// coordinates belong in this AI snapshot.

class AgentStudentRideSnapshot {
  final String rideId;
  final String studentAlias;
  final String schoolAlias;
  final String status;
  final bool attendanceMarked;
  final bool authorizedGuardianReady;
  final bool handoverCompleted;
  final DateTime? scheduledAt;

  const AgentStudentRideSnapshot({
    required this.rideId,
    required this.studentAlias,
    required this.schoolAlias,
    required this.status,
    required this.attendanceMarked,
    required this.authorizedGuardianReady,
    required this.handoverCompleted,
    required this.scheduledAt,
  });
}
