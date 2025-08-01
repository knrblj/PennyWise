import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'credentials_service.dart';
import '../utils/logger.dart';

class AnalyticsTokenService {
  static const String _tokenKey = 'analytics_access_token';
  static const String _tokenExpiryKey = 'analytics_token_expiry';
  static const String _tokenScopeKey = 'analytics_token_scope';
  static const String _apiDomainKey = 'analytics_api_domain';

  // Token endpoint
  static const String _tokenEndpoint =
      'https://accounts.zoho.com/oauth/v2/token';

  /// Generate access token using refresh token
  static Future<Map<String, dynamic>?> generateAccessToken() async {
    try {
      Logger.processStart(
        'Generating new access token',
        tag: 'Analytics.Token',
      );

      // Get stored credentials
      final credentials = await CredentialsService.getCredentials();
      final clientId = credentials['clientId'];
      final clientSecret = credentials['clientSecret'];
      final refreshToken = credentials['refreshToken'];

      if (clientId == null || clientSecret == null || refreshToken == null) {
        Logger.error('Analytics credentials not found', tag: 'Analytics.Token');
        return null;
      }

      // Prepare form data
      final formData = {
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      };

      Logger.apiRequest('POST', _tokenEndpoint, tag: 'Analytics.Token');

      // Make HTTP request
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        body: formData,
      );

      Logger.apiResponse(
        response.statusCode,
        tag: 'Analytics.Token',
        body: response.body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract token data
        final accessToken = responseData['access_token'];
        final scope = responseData['scope'];
        final apiDomain = responseData['api_domain'];
        final expiresIn = responseData['expires_in'] ?? 3600;

        if (accessToken != null) {
          // Calculate expiry time (subtract 5 minutes for safety)
          final expiryTime = DateTime.now().add(
            Duration(seconds: expiresIn - 300),
          );

          // Store token data
          await _storeTokenData(
            accessToken: accessToken,
            expiryTime: expiryTime,
            scope: scope,
            apiDomain: apiDomain,
          );

          print('✅ Access token generated successfully');
          print('🔑 Token expires at: ${expiryTime.toIso8601String()}');
          print('🌐 API Domain: $apiDomain');
          print('🔐 Scope: $scope');

          return {
            'access_token': accessToken,
            'scope': scope,
            'api_domain': apiDomain,
            'expires_in': expiresIn,
            'expires_at': expiryTime.toIso8601String(),
          };
        }
      }

      print('❌ Failed to generate access token: ${response.statusCode}');
      print('❌ Response: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error generating access token: $e');
      return null;
    }
  }

  /// Get valid access token (cached or generate new)
  static Future<String?> getValidAccessToken() async {
    try {
      // Check if we have a cached token
      final cachedToken = await _getCachedToken();
      final isExpired = await _isTokenExpired();

      if (cachedToken != null && !isExpired) {
        print('✅ Using cached access token');
        return cachedToken;
      }

      print('🔄 Cached token expired or not found, generating new token...');

      // Generate new token
      final tokenData = await generateAccessToken();
      return tokenData?['access_token'];
    } catch (e) {
      print('❌ Error getting valid access token: $e');
      return null;
    }
  }

  /// Get API domain for analytics requests
  static Future<String?> getApiDomain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_apiDomainKey);
    } catch (e) {
      print('❌ Error getting API domain: $e');
      return null;
    }
  }

  /// Check if analytics token is available and valid
  static Future<bool> isTokenValid() async {
    try {
      final token = await _getCachedToken();
      final isExpired = await _isTokenExpired();
      return token != null && !isExpired;
    } catch (e) {
      print('❌ Error checking token validity: $e');
      return false;
    }
  }

  /// Clear stored token data
  static Future<void> clearTokenData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_tokenExpiryKey),
        prefs.remove(_tokenScopeKey),
        prefs.remove(_apiDomainKey),
      ]);
      print('✅ Analytics token data cleared');
    } catch (e) {
      print('❌ Error clearing token data: $e');
    }
  }

  /// Test token generation with current credentials
  static Future<bool> testTokenGeneration() async {
    try {
      print('🧪 Testing analytics token generation...');

      final tokenData = await generateAccessToken();
      if (tokenData != null && tokenData['access_token'] != null) {
        print('✅ Token generation test successful');
        return true;
      } else {
        print('❌ Token generation test failed');
        return false;
      }
    } catch (e) {
      print('❌ Token generation test error: $e');
      return false;
    }
  }

  // Private helper methods

  static Future<void> _storeTokenData({
    required String accessToken,
    required DateTime expiryTime,
    String? scope,
    String? apiDomain,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_tokenKey, accessToken),
        prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String()),
        if (scope != null) prefs.setString(_tokenScopeKey, scope),
        if (apiDomain != null) prefs.setString(_apiDomainKey, apiDomain),
      ]);
    } catch (e) {
      print('❌ Error storing token data: $e');
    }
  }

  static Future<String?> _getCachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('❌ Error getting cached token: $e');
      return null;
    }
  }

  static Future<bool> _isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_tokenExpiryKey);
      if (expiryString == null) return true;

      final expiryTime = DateTime.parse(expiryString);
      final isExpired = DateTime.now().isAfter(expiryTime);

      if (isExpired) {
        print('⏰ Token expired at: ${expiryTime.toIso8601String()}');
      }

      return isExpired;
    } catch (e) {
      print('❌ Error checking token expiry: $e');
      return true;
    }
  }

  /// Get token info for debugging
  static Future<Map<String, dynamic>> getTokenInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final expiryString = prefs.getString(_tokenExpiryKey);
      final scope = prefs.getString(_tokenScopeKey);
      final apiDomain = prefs.getString(_apiDomainKey);

      DateTime? expiryTime;
      if (expiryString != null) {
        expiryTime = DateTime.parse(expiryString);
      }

      return {
        'has_token': token != null,
        'token_preview': token != null ? '${token.substring(0, 20)}...' : null,
        'expires_at': expiryTime?.toIso8601String(),
        'is_expired': expiryTime != null
            ? DateTime.now().isAfter(expiryTime)
            : true,
        'scope': scope,
        'api_domain': apiDomain,
        'time_until_expiry': expiryTime != null
            ? expiryTime.difference(DateTime.now()).inMinutes
            : null,
      };
    } catch (e) {
      print('❌ Error getting token info: $e');
      return {'error': e.toString()};
    }
  }
}
