/// A preparation adapter for one registered AI action.
///
/// Authorization, risk, read/write classification, and approval policy remain
/// owned by [AgentActionRegistry] and the execution boundary. Implementations
/// must not perform provider calls, business-data writes, or financial actions.
abstract interface class CapabilityContract<T> {
  String get actionId;

  String get module;

  void validateInput(Map<String, dynamic> input);

  Future<T> prepare(Map<String, dynamic> input);
}