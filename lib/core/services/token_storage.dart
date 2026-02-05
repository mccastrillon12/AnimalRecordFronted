import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing and retrieving authentication tokens
class TokenStorage {
  final FlutterSecureStorage _secureStorage;

  // Keys for secure storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  TokenStorage(this._secureStorage);

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  /// Save both tokens at once
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Check if user has valid tokens (basic check)
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Clear all tokens (for logout)
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _userDataKey),
    ]);
  }

  /// Save user data as JSON string
  Future<void> saveUserData(String userDataJson) async {
    await _secureStorage.write(key: _userDataKey, value: userDataJson);
  }

  /// Get user data JSON string
  Future<String?> getUserData() async {
    return await _secureStorage.read(key: _userDataKey);
  }

  /// Save user ID
  Future<void> saveUserId(String id) async {
    await _secureStorage.write(key: _userIdKey, value: id);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  static const String _biometricPendingKey = 'biometric_pending';

  /// Save biometric preference for specific user
  Future<void> saveBiometricsEnabledForUser(String userId, bool enabled) async {
    await _secureStorage.write(
      key: '${_biometricsEnabledKey}_$userId',
      value: enabled.toString(),
    );
  }

  /// Get biometric preference for specific user
  Future<bool> getBiometricsEnabledForUser(String userId) async {
    final value = await _secureStorage.read(
      key: '${_biometricsEnabledKey}_$userId',
    );
    return value == 'true';
  }

  /// Set pending biometric activation (used when activating before login)
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

  /// Clear all secure storage
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
