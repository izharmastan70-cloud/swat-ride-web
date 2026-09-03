// =========================================================
// AI AGENT — MODULE CONNECTOR CONSTANTS
// =========================================================

class AgentModuleConnectorStatus {
  AgentModuleConnectorStatus._();

  static const String notConnected = 'NOT_CONNECTED';
  static const String monitorReady = 'MONITOR_READY';
  static const String readOnlyReady = 'READ_ONLY_READY';
  static const String writeReady = 'WRITE_READY';
  static const String disabled = 'DISABLED';
  static const String error = 'ERROR';

  static const Set<String> values = <String>{
    notConnected,
    monitorReady,
    readOnlyReady,
    writeReady,
    disabled,
    error,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentModuleId {
  AgentModuleId._();

  static const String ride = 'ride';
  static const String driver = 'driver';
  static const String food = 'food';
  static const String restaurant = 'restaurant';
  static const String hotel = 'hotel';
  static const String tour = 'tour';
  static const String rewards = 'rewards';
  static const String safety = 'safety';
  static const String cargo = 'cargo';
  static const String student = 'student';
  static const String finance = 'finance';

  static const Set<String> values = <String>{
    ride,
    driver,
    food,
    restaurant,
    hotel,
    tour,
    rewards,
    safety,
    cargo,
    student,
    finance,
  };

  static bool isValid(String value) => values.contains(value);
}
