import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing and retrieving authentication tokens
class TokenStorage {
  final FlutterSecureStorage _secureStorage;

  // Keys for secure storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

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
    ]);
  }

  /// Clear all secure storage
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
