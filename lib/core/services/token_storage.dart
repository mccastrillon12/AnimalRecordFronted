import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class TokenStorage {
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  TokenStorage(this._secureStorage);

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

  // ── PIN storage (hashed with SHA-256) ──────────────────────────────────

  static const String _userPinKey = 'user_pin';

  /// Hashes a plaintext PIN with SHA-256.
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Returns true if [value] looks like a SHA-256 hex digest (64 hex chars).
  bool _isHashed(String value) {
    return value.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(value);
  }

  /// Saves the PIN as a SHA-256 hash. The plaintext PIN is never stored.
  Future<void> saveUserPin(String userId, String pin) async {
    final hashed = _hashPin(pin);
    await _secureStorage.write(key: '${_userPinKey}_$userId', value: hashed);
  }

  /// Returns the stored hash (or null). Callers should NOT interpret this value.
  Future<String?> getUserPin(String userId) async {
    return await _secureStorage.read(key: '${_userPinKey}_$userId');
  }

  /// Validates [inputPin] against the stored hash.
  ///
  /// Includes automatic migration: if the stored value is a plaintext PIN
  /// (from before hashing was introduced), it re-hashes and saves it.
  Future<bool> validateUserPin(String userId, String inputPin) async {
    final stored = await getUserPin(userId);
    if (stored == null) return false;

    // Migration: if the stored PIN is plaintext (not a 64-char hex hash),
    // compare directly and then re-save as a hash for future validations.
    if (!_isHashed(stored)) {
      if (stored == inputPin) {
        await saveUserPin(userId, inputPin); // migrates to hash
        return true;
      }
      return false;
    }

    // Normal path: compare hashes
    return stored == _hashPin(inputPin);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
