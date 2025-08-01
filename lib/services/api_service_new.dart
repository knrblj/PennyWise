import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../constants/app_constants.dart';
import 'credentials_service.dart';
import 'analytics_api_service.dart';

class ApiService {
  static String get _baseUrl => ApiConstants.baseUrl;
  static String get _transactionsEndpoint =>
      '$_baseUrl${ApiConstants.transactionsEndpoint}';

  static Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConstants.defaultHeaders);

    if (ApiConstants.apiKey != null) {
      headers['X-API-Key'] = ApiConstants.apiKey!;
    }

    if (ApiConstants.authToken != null) {
      headers['Authorization'] = 'Bearer ${ApiConstants.authToken!}';
    }

    return headers;
  }

  static Future<bool> pushTransaction(TransactionModel transaction) async {
    try {
      // Check if analytics is configured
      final isConfigured = await CredentialsService.isAnalyticsConfigured();
      if (!isConfigured) {
        print('📊 Analytics not configured, skipping backend push');
        return false; // Not an error, just not configured
      }

      // Use the new analytics API service instead of the old generic endpoint
      print('📤 Pushing transaction to Zoho Analytics...');
      final success = await AnalyticsApiService.pushTransaction(transaction);

      if (success) {
        print('✅ Transaction pushed to analytics successfully');
        return true;
      } else {
        print('❌ Failed to push transaction to analytics');
        return false;
      }
    } catch (e) {
      print('❌ Error pushing transaction to backend: $e');
      return false;
    }
  }

  static Future<List<TransactionModel>> fetchTransactions() async {
    try {
      final response = await http
          .get(Uri.parse(_transactionsEndpoint), headers: _headers)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        print('❌ Failed to fetch transactions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      return [];
    }
  }
}
