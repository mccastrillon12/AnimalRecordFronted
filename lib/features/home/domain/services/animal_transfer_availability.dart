/// History remains an integration opt-in.
class AnimalTransferAvailability {
  static const bool integration = bool.fromEnvironment('TRANSFER_INTEGRATION');
  static const bool history =
      integration && bool.fromEnvironment('TRANSFER_HISTORY');
}
