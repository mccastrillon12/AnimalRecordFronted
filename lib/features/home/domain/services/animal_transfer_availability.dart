/// Basic requests use the configured backend. Acceptance and history require
/// separate opt-ins on an integration build.
class AnimalTransferAvailability {
  static const bool integration = bool.fromEnvironment('TRANSFER_INTEGRATION');
  static const bool acceptance =
      integration && bool.fromEnvironment('TRANSFER_ACCEPTANCE');
  static const bool history =
      integration && bool.fromEnvironment('TRANSFER_HISTORY');
}
