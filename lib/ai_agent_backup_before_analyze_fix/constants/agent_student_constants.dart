// =========================================================
// AI AGENT — STUDENT RIDE CONSTANTS
// =========================================================

class AgentStudentRideStatus {
  AgentStudentRideStatus._();

  static const String scheduled = 'SCHEDULED';
  static const String pickupPending = 'PICKUP_PENDING';
  static const String pickedUp = 'PICKED_UP';
  static const String atSchool = 'AT_SCHOOL';
  static const String returnPending = 'RETURN_PENDING';
  static const String returning = 'RETURNING';
  static const String handedOver = 'HANDED_OVER';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
  static const String unknown = 'UNKNOWN';
}

class AgentStudentIntent {
  AgentStudentIntent._();

  static const String scheduleHelp = 'SCHEDULE_HELP';
  static const String statusCheck = 'STATUS_CHECK';
  static const String attendanceCheck = 'ATTENDANCE_CHECK';
  static const String handoverQuestion = 'HANDOVER_QUESTION';
  static const String guardianQuestion = 'GUARDIAN_QUESTION';
  static const String safetyConcern = 'SAFETY_CONCERN';
  static const String emergency = 'EMERGENCY';
  static const String unknown = 'UNKNOWN';
}

class AgentStudentRisk {
  AgentStudentRisk._();

  static const String normal = 'NORMAL';
  static const String sensitive = 'SENSITIVE';
  static const String safetyCritical = 'SAFETY_CRITICAL';
}
