import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CredentialsService {
  // Keys for storage
  static const String _clientIdKey = 'enc_analytics_client_id';
  static const String _clientSecretKey = 'enc_analytics_client_secret';
  static const String _refreshTokenKey = 'enc_analytics_refresh_token';
  static const String _configuredKey = 'analytics_configured';

  // Simple encoding for basic obfuscation (not cryptographically secure)
  static String _encodeData(String data) {
    final bytes = utf8.encode(data);
    return base64.encode(bytes);
  }

  static String _decodeData(String encoded) {
    try {
      final bytes = base64.decode(encoded);
      return utf8.decode(bytes);
    } catch (e) {
      return '';
    }
  }

  // Check if analytics is configured
  static Future<bool> isAnalyticsConfigured() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_configuredKey) ?? false;
    } catch (e) {
      print('❌ Error checking analytics configuration: $e');
      return false;
    }
  }

  // Save analytics credentials
  static Future<bool> saveCredentials({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
  }) async {
    try {
      // Validate inputs
      if (clientId.trim().isEmpty ||
          clientSecret.trim().isEmpty ||
          refreshToken.trim().isEmpty) {
        throw Exception('All credentials are required');
      }

      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_clientIdKey, _encodeData(clientId.trim())),
        prefs.setString(_clientSecretKey, _encodeData(clientSecret.trim())),
        prefs.setString(_refreshTokenKey, _encodeData(refreshToken.trim())),
        prefs.setBool(_configuredKey, true),
      ]);

      print('✅ Analytics credentials saved securely');
      return true;
    } catch (e) {
      print('❌ Error saving credentials: $e');
      return false;
    }
  }

  // Get analytics credentials
  static Future<Map<String, String?>> getCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientId = prefs.getString(_clientIdKey);
      final clientSecret = prefs.getString(_clientSecretKey);
      final refreshToken = prefs.getString(_refreshTokenKey);

      return {
        'clientId': clientId != null ? _decodeData(clientId) : null,
        'clientSecret': clientSecret != null ? _decodeData(clientSecret) : null,
        'refreshToken': refreshToken != null ? _decodeData(refreshToken) : null,
      };
    } catch (e) {
      print('❌ Error reading credentials: $e');
      return {'clientId': null, 'clientSecret': null, 'refreshToken': null};
    }
  }

  // Get masked credentials for display (security)
  static Future<Map<String, String>> getMaskedCredentials() async {
    try {
      final credentials = await getCredentials();

      return {
        'clientId': _maskCredential(credentials['clientId']),
        'clientSecret': _maskCredential(credentials['clientSecret']),
        'refreshToken': _maskCredential(credentials['refreshToken']),
      };
    } catch (e) {
      print('❌ Error getting masked credentials: $e');
      return {
        'clientId': 'Error loading',
        'clientSecret': 'Error loading',
        'refreshToken': 'Error loading',
      };
    }
  }

  // Mask credential for display (show first 4 and last 4 characters)
  static String _maskCredential(String? credential) {
    if (credential == null || credential.isEmpty) {
      return 'Not configured';
    }

    if (credential.length <= 8) {
      return '●' * credential.length;
    }

    final start = credential.substring(0, 4);
    final end = credential.substring(credential.length - 4);
    final middle = '●' * (credential.length - 8);

    return '$start$middle$end';
  }

  // Clear all credentials
  static Future<bool> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_clientIdKey),
        prefs.remove(_clientSecretKey),
        prefs.remove(_refreshTokenKey),
        prefs.remove(_configuredKey),
      ]);

      print('✅ Analytics credentials cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing credentials: $e');
      return false;
    }
  }

  // Validate credentials format
  static bool validateCredentials({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
  }) {
    // Basic validation
    if (clientId.trim().length < 10 ||
        clientSecret.trim().length < 10 ||
        refreshToken.trim().length < 10) {
      return false;
    }

    // Check for valid patterns (adjust based on your analytics provider)
    final clientIdPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
    final secretPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
    final tokenPattern = RegExp(r'^[a-zA-Z0-9._-]+$');

    return clientIdPattern.hasMatch(clientId.trim()) &&
        secretPattern.hasMatch(clientSecret.trim()) &&
        tokenPattern.hasMatch(refreshToken.trim());
  }

  // Test credentials connectivity (placeholder)
  static Future<bool> testCredentials({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
  }) async {
    try {
      // TODO: Implement actual API test call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // For now, just validate format
      return validateCredentials(
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
      );
    } catch (e) {
      print('❌ Error testing credentials: $e');
      return false;
    }
  }
}
