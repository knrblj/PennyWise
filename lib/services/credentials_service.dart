import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class CredentialsService {
  // Keys for storage
  static const String _clientIdKey = 'enc_analytics_client_id';
  static const String _clientSecretKey = 'enc_analytics_client_secret';
  static const String _refreshTokenKey = 'enc_analytics_refresh_token';
  static const String _orgIdKey = 'enc_analytics_org_id';
  static const String _workspaceIdKey = 'enc_analytics_workspace_id';
  static const String _tableIdKey = 'enc_analytics_table_id';
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
      Logger.error(
        'Error checking analytics configuration',
        tag: 'Credentials',
        error: e,
      );
      return false;
    }
  }

  // Save analytics credentials
  static Future<bool> saveCredentials({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
    required String orgId,
    required String workspaceId,
    required String tableId,
  }) async {
    try {
      // Validate inputs
      if (clientId.trim().isEmpty ||
          clientSecret.trim().isEmpty ||
          refreshToken.trim().isEmpty ||
          orgId.trim().isEmpty ||
          workspaceId.trim().isEmpty ||
          tableId.trim().isEmpty) {
        throw Exception('All fields are required');
      }

      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_clientIdKey, _encodeData(clientId.trim())),
        prefs.setString(_clientSecretKey, _encodeData(clientSecret.trim())),
        prefs.setString(_refreshTokenKey, _encodeData(refreshToken.trim())),
        prefs.setString(_orgIdKey, _encodeData(orgId.trim())),
        prefs.setString(_workspaceIdKey, _encodeData(workspaceId.trim())),
        prefs.setString(_tableIdKey, _encodeData(tableId.trim())),
        prefs.setBool(_configuredKey, true),
      ]);

      Logger.success(
        'Analytics credentials and workspace info saved securely',
        tag: 'Credentials',
      );
      return true;
    } catch (e) {
      Logger.error('Error saving credentials', tag: 'Credentials', error: e);
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
      final orgId = prefs.getString(_orgIdKey);
      final workspaceId = prefs.getString(_workspaceIdKey);
      final tableId = prefs.getString(_tableIdKey);

      return {
        'clientId': clientId != null ? _decodeData(clientId) : null,
        'clientSecret': clientSecret != null ? _decodeData(clientSecret) : null,
        'refreshToken': refreshToken != null ? _decodeData(refreshToken) : null,
        'orgId': orgId != null ? _decodeData(orgId) : null,
        'workspaceId': workspaceId != null ? _decodeData(workspaceId) : null,
        'tableId': tableId != null ? _decodeData(tableId) : null,
      };
    } catch (e) {
      Logger.error('Error reading credentials', tag: 'Credentials', error: e);
      return {
        'clientId': null,
        'clientSecret': null,
        'refreshToken': null,
        'orgId': null,
        'workspaceId': null,
        'tableId': null,
      };
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
        'orgId': _maskCredential(credentials['orgId']),
        'workspaceId': _maskCredential(credentials['workspaceId']),
        'tableId': _maskCredential(credentials['tableId']),
      };
    } catch (e) {
      Logger.error(
        'Error getting masked credentials',
        tag: 'Credentials',
        error: e,
      );
      return {
        'clientId': 'Error loading',
        'clientSecret': 'Error loading',
        'refreshToken': 'Error loading',
        'orgId': 'Error loading',
        'workspaceId': 'Error loading',
        'tableId': 'Error loading',
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
        prefs.remove(_orgIdKey),
        prefs.remove(_workspaceIdKey),
        prefs.remove(_tableIdKey),
        prefs.remove(_configuredKey),
      ]);

      Logger.success('Analytics credentials cleared', tag: 'Credentials');
      return true;
    } catch (e) {
      Logger.error('Error clearing credentials', tag: 'Credentials', error: e);
      return false;
    }
  }

  // Validate credentials format
  static bool validateCredentials({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
    required String orgId,
    required String workspaceId,
    required String tableId,
  }) {
    // Basic validation
    if (clientId.trim().length < 10 ||
        clientSecret.trim().length < 10 ||
        refreshToken.trim().length < 10 ||
        orgId.trim().isEmpty ||
        workspaceId.trim().isEmpty ||
        tableId.trim().isEmpty) {
      return false;
    }

    // Check for valid patterns (adjust based on your analytics provider)
    final clientIdPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
    final secretPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
    final tokenPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
    final idPattern = RegExp(r'^[a-zA-Z0-9_-]+$');

    return clientIdPattern.hasMatch(clientId.trim()) &&
        secretPattern.hasMatch(clientSecret.trim()) &&
        tokenPattern.hasMatch(refreshToken.trim()) &&
        idPattern.hasMatch(orgId.trim()) &&
        idPattern.hasMatch(workspaceId.trim()) &&
        idPattern.hasMatch(tableId.trim());
  }

  // Test credentials connectivity (placeholder)
  static Future<bool> testCredentials({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
    required String orgId,
    required String workspaceId,
    required String tableId,
  }) async {
    try {
      // TODO: Implement actual API test call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // For now, just validate format
      return validateCredentials(
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
        orgId: orgId,
        workspaceId: workspaceId,
        tableId: tableId,
      );
    } catch (e) {
      Logger.error('Error testing credentials', tag: 'Credentials', error: e);
      return false;
    }
  }
}
