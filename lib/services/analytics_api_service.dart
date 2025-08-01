import 'dart:convert';
import 'package:http/http.dart' as http;
import 'analytics_token_service.dart';
import 'credentials_service.dart';
import '../models/transaction_model.dart';
import '../utils/logger.dart';

class AnalyticsApiService {
  static const String _baseUrl = 'https://analytics.zoho.com/restapi/v2';

  /// Get table details including column structure
  static Future<Map<String, dynamic>?> getTableDetails() async {
    try {
      Logger.processStart('Fetching table details', tag: 'Analytics');

      // Get credentials and token
      final credentials = await CredentialsService.getCredentials();
      final orgId = credentials['orgId'];
      final tableId = credentials['tableId'];
      final accessToken = await AnalyticsTokenService.getValidAccessToken();

      if (orgId == null || tableId == null || accessToken == null) {
        Logger.error(
          'Missing credentials or token for table details',
          tag: 'Analytics',
        );
        return null;
      }

      // Prepare request
      final url = Uri.parse(
        '$_baseUrl/views/$tableId?CONFIG=%7B%22withInvolvedMetaInfo%22%3A%22true%22%7D',
      );
      final headers = {
        'ZANALYTICS-ORGID': orgId,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      Logger.apiRequest('GET', url.toString(), tag: 'Analytics');
      Logger.data('Headers: ${headers.keys.join(', ')}', tag: 'Analytics');

      // Make HTTP request
      final response = await http.get(url, headers: headers);

      Logger.apiResponse(response.statusCode, tag: 'Analytics');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Logger.processComplete('Table details fetch', tag: 'Analytics');
        return responseData;
      } else {
        Logger.error(
          'Failed to fetch table details: ${response.statusCode}',
          tag: 'Analytics',
        );
        Logger.error('Response: ${response.body}', tag: 'Analytics');
        return null;
      }
    } catch (e) {
      Logger.error('Error fetching table details', tag: 'Analytics', error: e);
      return null;
    }
  }

  /// Validate transaction model against table schema
  static Future<ValidationResult> validateTransactionSchema() async {
    try {
      Logger.processStart(
        'Validating transaction schema',
        tag: 'Analytics.Validation',
      );

      final tableDetails = await getTableDetails();
      if (tableDetails == null) {
        return ValidationResult(
          isValid: false,
          error: 'Could not fetch table details',
        );
      }

      final columns = tableDetails['data']?['views']?['columns'] as List?;
      if (columns == null) {
        return ValidationResult(
          isValid: false,
          error: 'No columns found in table response',
        );
      }

      // Map column names to their details
      final columnMap = <String, Map<String, dynamic>>{};
      for (final column in columns) {
        final columnName = column['columnName'] as String?;
        if (columnName != null) {
          columnMap[columnName.toLowerCase()] = column;
        }
      }

      Logger.data(
        'Found columns: ${columnMap.keys.join(', ')}',
        tag: 'Analytics.Validation',
      );

      // Check required fields for our TransactionModel
      final requiredFields = {
        'id': 'POSITIVE_NUMBER',
        'type': 'PLAIN',
        'category': 'PLAIN',
        'amount': 'CURRENCY',
        'note': 'PLAIN',
        'date': 'DATE_AS_DATE',
      };

      final missingFields = <String>[];
      final incompatibleFields = <String, String>{};

      for (final entry in requiredFields.entries) {
        final fieldName = entry.key;
        final expectedType = entry.value;

        if (!columnMap.containsKey(fieldName)) {
          missingFields.add(fieldName);
        } else {
          final column = columnMap[fieldName]!;
          final actualType = column['dataType'] as String?;

          if (actualType != expectedType) {
            incompatibleFields[fieldName] =
                '$actualType (expected: $expectedType)';
          }
        }
      }

      if (missingFields.isNotEmpty || incompatibleFields.isNotEmpty) {
        String error = '';
        if (missingFields.isNotEmpty) {
          error += 'Missing fields: ${missingFields.join(', ')}. ';
        }
        if (incompatibleFields.isNotEmpty) {
          error +=
              'Incompatible fields: ${incompatibleFields.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
        }

        Logger.validation(false, error.trim(), tag: 'Analytics.Validation');
        return ValidationResult(
          isValid: false,
          error: error.trim(),
          tableDetails: tableDetails,
          availableColumns: columnMap.keys.toList(),
        );
      }

      Logger.validation(
        true,
        'Transaction schema validation successful',
        tag: 'Analytics.Validation',
      );
      return ValidationResult(
        isValid: true,
        tableDetails: tableDetails,
        availableColumns: columnMap.keys.toList(),
      );
    } catch (e) {
      Logger.error(
        'Error validating transaction schema',
        tag: 'Analytics.Validation',
        error: e,
      );
      return ValidationResult(isValid: false, error: 'Validation error: $e');
    }
  }

  /// Convert TransactionModel to Zoho Analytics format
  static Map<String, dynamic> transactionToZohoFormat(
    TransactionModel transaction,
  ) {
    return {
      'id': transaction.id,
      'type': transaction.type, // 'income' or 'expense'
      'category': transaction.category,
      'amount': transaction.amount,
      'note': transaction.note,
      'date': transaction.date.toIso8601String(),
    };
  }

  /// Push transaction data to Zoho Analytics table
  static Future<bool> pushTransaction(TransactionModel transaction) async {
    try {
      Logger.processStart(
        'Pushing transaction to Zoho Analytics',
        tag: 'Analytics.Push',
      );

      // First validate schema
      final validation = await validateTransactionSchema();
      if (!validation.isValid) {
        Logger.error(
          'Schema validation failed: ${validation.error}',
          tag: 'Analytics.Push',
        );
        return false;
      }

      // Get credentials and token
      final credentials = await CredentialsService.getCredentials();
      final orgId = credentials['orgId'];
      final workspaceId = credentials['workspaceId'];
      final tableId = credentials['tableId'];
      final accessToken = await AnalyticsTokenService.getValidAccessToken();

      if (orgId == null ||
          workspaceId == null ||
          tableId == null ||
          accessToken == null) {
        Logger.error(
          'Missing credentials or token for data push',
          tag: 'Analytics.Push',
        );
        return false;
      }

      // Convert transaction to Zoho format for single row add
      final zohoData = {
        'id': transaction.id,
        'type': transaction.type,
        'category': transaction.category,
        'amount': transaction.amount.toString(),
        'note': transaction.note,
        'date': transaction.date.toIso8601String().split(
          'T',
        )[0], // Format as YYYY-MM-DD
      };

      // Prepare request using the exact format from your curl command
      final url = Uri.parse(
        '$_baseUrl/workspaces/$workspaceId/views/$tableId/rows',
      );
      final headers = {
        'ZANALYTICS-ORGID': orgId,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      // Create CONFIG parameter with columns as specified in your curl command
      final config = {'columns': zohoData};

      final body = 'CONFIG=${Uri.encodeComponent(json.encode(config))}';

      Logger.apiRequest('POST', url.toString(), tag: 'Analytics.Push');
      Logger.data('Config: ${json.encode(config)}', tag: 'Analytics.Push');

      // Make HTTP request
      final response = await http.post(url, headers: headers, body: body);

      Logger.apiResponse(response.statusCode, tag: 'Analytics.Push');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        Logger.processComplete('Transaction row added', tag: 'Analytics.Push');
        Logger.data('Response: $responseData', tag: 'Analytics.Push');
        return true;
      } else {
        Logger.error(
          'Failed to add transaction row: ${response.statusCode}',
          tag: 'Analytics.Push',
        );
        Logger.error('Response: ${response.body}', tag: 'Analytics.Push');
        return false;
      }
    } catch (e) {
      Logger.error(
        'Error adding transaction row',
        tag: 'Analytics.Push',
        error: e,
      );
      return false;
    }
  }

  /// Push transaction data to Zoho Analytics table (legacy batch method)
  static Future<bool> pushTransactionLegacy(
    TransactionModel transaction,
  ) async {
    try {
      Logger.processStart(
        'Pushing transaction to Zoho Analytics (legacy)',
        tag: 'Analytics.Legacy',
      );

      // First validate schema
      final validation = await validateTransactionSchema();
      if (!validation.isValid) {
        Logger.error(
          'Schema validation failed: ${validation.error}',
          tag: 'Analytics.Legacy',
        );
        return false;
      }

      // Get credentials and token
      final credentials = await CredentialsService.getCredentials();
      final orgId = credentials['orgId'];
      final tableId = credentials['tableId'];
      final accessToken = await AnalyticsTokenService.getValidAccessToken();

      if (orgId == null || tableId == null || accessToken == null) {
        Logger.error(
          'Missing credentials or token for data push',
          tag: 'Analytics.Legacy',
        );
        return false;
      }

      // Convert transaction to Zoho format
      final zohoData = transactionToZohoFormat(transaction);

      // Prepare request
      final url = Uri.parse('$_baseUrl/views/$tableId/rows');
      final headers = {
        'ZANALYTICS-ORGID': orgId,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      final body = json.encode({
        'rows': [zohoData],
      });

      Logger.apiRequest('POST', url.toString(), tag: 'Analytics.Legacy');
      Logger.data('Data: $zohoData', tag: 'Analytics.Legacy');

      // Make HTTP request
      final response = await http.post(url, headers: headers, body: body);

      Logger.apiResponse(response.statusCode, tag: 'Analytics.Legacy');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        Logger.processComplete(
          'Transaction pushed (legacy)',
          tag: 'Analytics.Legacy',
        );
        Logger.data('Response: $responseData', tag: 'Analytics.Legacy');
        return true;
      } else {
        Logger.error(
          'Failed to push transaction (legacy): ${response.statusCode}',
          tag: 'Analytics.Legacy',
        );
        Logger.error('Response: ${response.body}', tag: 'Analytics.Legacy');
        return false;
      }
    } catch (e) {
      Logger.error(
        'Error pushing transaction (legacy)',
        tag: 'Analytics.Legacy',
        error: e,
      );
      return false;
    }
  }

  /// Push multiple transactions in batch
  static Future<BatchResult> pushTransactionsBatch(
    List<TransactionModel> transactions,
  ) async {
    try {
      Logger.processStart(
        'Pushing ${transactions.length} transactions in batch',
        tag: 'Analytics.Batch',
      );

      // First validate schema
      final validation = await validateTransactionSchema();
      if (!validation.isValid) {
        Logger.error(
          'Schema validation failed: ${validation.error}',
          tag: 'Analytics.Batch',
        );
        return BatchResult(
          success: false,
          error: 'Schema validation failed: ${validation.error}',
          processedCount: 0,
          totalCount: transactions.length,
        );
      }

      // Get credentials and token
      final credentials = await CredentialsService.getCredentials();
      final orgId = credentials['orgId'];
      final tableId = credentials['tableId'];
      final accessToken = await AnalyticsTokenService.getValidAccessToken();

      if (orgId == null || tableId == null || accessToken == null) {
        Logger.error('Missing credentials or token', tag: 'Analytics.Batch');
        return BatchResult(
          success: false,
          error: 'Missing credentials or token',
          processedCount: 0,
          totalCount: transactions.length,
        );
      }

      // Convert transactions to Zoho format
      final zohoRows = transactions.map(transactionToZohoFormat).toList();

      // Prepare request
      final url = Uri.parse('$_baseUrl/views/$tableId/rows');
      final headers = {
        'ZANALYTICS-ORGID': orgId,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      final body = json.encode({'rows': zohoRows});

      Logger.apiRequest('POST', url.toString(), tag: 'Analytics.Batch');
      Logger.data('Pushing ${zohoRows.length} rows', tag: 'Analytics.Batch');

      // Make HTTP request
      final response = await http.post(url, headers: headers, body: body);

      Logger.apiResponse(response.statusCode, tag: 'Analytics.Batch');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        Logger.processComplete('Batch push', tag: 'Analytics.Batch');
        Logger.data('Response: $responseData', tag: 'Analytics.Batch');

        return BatchResult(
          success: true,
          processedCount: transactions.length,
          totalCount: transactions.length,
          response: responseData,
        );
      } else {
        Logger.error(
          'Failed to push batch: ${response.statusCode}',
          tag: 'Analytics.Batch',
        );
        Logger.error('Response: ${response.body}', tag: 'Analytics.Batch');

        return BatchResult(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
          processedCount: 0,
          totalCount: transactions.length,
        );
      }
    } catch (e) {
      Logger.error('Error pushing batch', tag: 'Analytics.Batch', error: e);
      return BatchResult(
        success: false,
        error: 'Exception: $e',
        processedCount: 0,
        totalCount: transactions.length,
      );
    }
  }

  /// Sync all transactions - truncate and replace all data in the table
  static Future<SyncResult> syncAllTransactions(
    List<TransactionModel> transactions,
  ) async {
    try {
      Logger.processStart(
        'Full sync - truncate and replace all data',
        tag: 'Analytics.Sync',
      );
      Logger.data(
        'Total transactions to sync: ${transactions.length}',
        tag: 'Analytics.Sync',
      );

      // Get credentials and token
      final credentials = await CredentialsService.getCredentials();
      final orgId = credentials['orgId'];
      final workspaceId = credentials['workspaceId'];
      final tableId = credentials['tableId'];
      final accessToken = await AnalyticsTokenService.getValidAccessToken();

      if (orgId == null ||
          workspaceId == null ||
          tableId == null ||
          accessToken == null) {
        Logger.error('Missing credentials or token', tag: 'Analytics.Sync');
        return SyncResult(
          success: false,
          error: 'Missing credentials or token',
          syncedCount: 0,
          totalCount: transactions.length,
        );
      }

      // Prepare data for bulk import
      final List<Map<String, dynamic>> jsonData = transactions.map((
        transaction,
      ) {
        return {
          'id': transaction.id,
          'type': transaction.type,
          'category': transaction.category,
          'amount': transaction.amount,
          'note': transaction.note,
          'date': transaction.date.toIso8601String().split(
            'T',
          )[0], // Format as YYYY-MM-DD
        };
      }).toList();

      final jsonString = json.encode(jsonData);
      Logger.data(
        'Prepared JSON data (${jsonString.length} characters)',
        tag: 'Analytics.Sync',
      );

      // Prepare request
      final url = Uri.parse(
        '$_baseUrl/workspaces/$workspaceId/views/$tableId/data',
      );

      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers.addAll({
        'ZANALYTICS-ORGID': orgId,
        'Authorization': 'Bearer $accessToken',
      });

      // Add CONFIG form field
      final config = {
        'importType': 'truncateadd',
        'fileType': 'json',
        'autoIdentify': 'true',
        'onError': 'setcolumnempty',
      };
      request.fields['CONFIG'] = json.encode(config);

      // Add FILE form field with JSON data
      request.files.add(
        http.MultipartFile.fromString(
          'FILE',
          jsonString,
          filename: 'transactions.json',
        ),
      );

      Logger.apiRequest('POST', url.toString(), tag: 'Analytics.Sync');
      Logger.data('Config: ${json.encode(config)}', tag: 'Analytics.Sync');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Logger.apiResponse(response.statusCode, tag: 'Analytics.Sync');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Logger.processComplete('Full sync', tag: 'Analytics.Sync');
        Logger.data(
          'Response: ${json.encode(responseData)}',
          tag: 'Analytics.Sync',
        );

        return SyncResult(
          success: true,
          syncedCount: transactions.length,
          totalCount: transactions.length,
          response: responseData,
        );
      } else {
        final errorMsg = 'Sync failed with status ${response.statusCode}';
        Logger.error(errorMsg, tag: 'Analytics.Sync');
        Logger.error('Response body: ${response.body}', tag: 'Analytics.Sync');

        return SyncResult(
          success: false,
          error: '$errorMsg: ${response.body}',
          syncedCount: 0,
          totalCount: transactions.length,
        );
      }
    } catch (e) {
      Logger.error('Error during full sync', tag: 'Analytics.Sync', error: e);
      return SyncResult(
        success: false,
        error: 'Exception: $e',
        syncedCount: 0,
        totalCount: transactions.length,
      );
    }
  }
}

/// Result of schema validation
class ValidationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? tableDetails;
  final List<String>? availableColumns;

  ValidationResult({
    required this.isValid,
    this.error,
    this.tableDetails,
    this.availableColumns,
  });
}

/// Result of batch operation
class BatchResult {
  final bool success;
  final String? error;
  final int processedCount;
  final int totalCount;
  final Map<String, dynamic>? response;

  BatchResult({
    required this.success,
    this.error,
    required this.processedCount,
    required this.totalCount,
    this.response,
  });

  double get successRate => totalCount > 0 ? processedCount / totalCount : 0.0;
}

/// Result of sync operation (truncate and replace)
class SyncResult {
  final bool success;
  final String? error;
  final int syncedCount;
  final int totalCount;
  final Map<String, dynamic>? response;

  SyncResult({
    required this.success,
    this.error,
    required this.syncedCount,
    required this.totalCount,
    this.response,
  });

  double get successRate => totalCount > 0 ? syncedCount / totalCount : 0.0;
}
