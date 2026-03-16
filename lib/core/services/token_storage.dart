import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  static const String _appleFirstNameKey = 'apple_first_name';
  static const String _appleLastNameKey = 'apple_last_name';

  TokenStorage(this._secureStorage);

  Future<void> saveAppleNames(String firstName, String lastName) async {
    await Future.wait([
      _secureStorage.write(key: _appleFirstNameKey, value: firstName),
      _secureStorage.write(key: _appleLastNameKey, value: lastName),
    ]);
  }

  Future<String?> getAppleFirstName() async => await _secureStorage.read(key: _appleFirstNameKey);
  Future<String?> getAppleLastName() async => await _secureStorage.read(key: _appleLastNameKey);

  Future<void> clearAppleNames() async {
    await Future.wait([
      _secureStorage.delete(key: _appleFirstNameKey),
      _secureStorage.delete(key: _appleLastNameKey),
    ]);
  }

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _userDataKey),
    ]);
  }

  Future<void> saveUserData(String userDataJson) async {
    await _secureStorage.write(key: _userDataKey, value: userDataJson);
  }

  Future<String?> getUserData() async {
    return await _secureStorage.read(key: _userDataKey);
  }

  Future<void> saveUserId(String id) async {
    await _secureStorage.write(key: _userIdKey, value: id);
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  static const String _biometricPendingKey = 'biometric_pending';

  Future<void> saveBiometricsEnabledForUser(String userId, bool enabled) async {
    await _secureStorage.write(
      key: '${_biometricsEnabledKey}_$userId',
      value: enabled.toString(),
    );
  }

  Future<bool> getBiometricsEnabledForUser(String userId) async {
    final value = await _secureStorage.read(
      key: '${_biometricsEnabledKey}_$userId',
    );
    return value == 'true';
  }

  Future<void> setBiometricActivationPending(bool pending) async {
    await _secureStorage.write(
      key: _biometricPendingKey,
      value: pending.toString(),
    );
  }

  Future<bool> isBiometricActivationPending() async {
    final value = await _secureStorage.read(key: _biometricPendingKey);
    return value == 'true';
  }

  static const String _userPinKey = 'user_pin';

  Future<void> saveUserPin(String userId, String pin) async {
    await _secureStorage.write(key: '${_userPinKey}_$userId', value: pin);
  }

  Future<String?> getUserPin(String userId) async {
    return await _secureStorage.read(key: '${_userPinKey}_$userId');
  }

  Future<bool> validateUserPin(String userId, String inputPin) async {
    final storedPin = await getUserPin(userId);
    return storedPin == inputPin;
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
