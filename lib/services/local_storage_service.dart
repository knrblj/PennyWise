import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

class LocalStorageService {
  static const String _transactionsKey = 'transactions';
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save transactions to local storage
  static Future<bool> saveTransactions(
    List<TransactionModel> transactions,
  ) async {
    try {
      await init();
      final List<Map<String, dynamic>> jsonList = transactions
          .map((transaction) => transaction.toJson())
          .toList();
      final String jsonString = json.encode(jsonList);
      final bool result = await _prefs!.setString(_transactionsKey, jsonString);
      print(
        '✅ Transactions saved to local storage: ${transactions.length} items',
      );
      return result;
    } catch (e) {
      print('❌ Error saving transactions to local storage: $e');
      return false;
    }
  }

  // Load transactions from local storage
  static Future<List<TransactionModel>> loadTransactions() async {
    try {
      await init();
      final String? jsonString = _prefs!.getString(_transactionsKey);

      if (jsonString == null || jsonString.isEmpty) {
        print(
          '📱 No transactions found in local storage, returning empty list',
        );
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final List<TransactionModel> transactions = jsonList
          .map((json) => TransactionModel.fromJson(json))
          .toList();

      print('✅ Loaded ${transactions.length} transactions from local storage');
      return transactions;
    } catch (e) {
      print('❌ Error loading transactions from local storage: $e');
      print('📱 Returning empty transaction list');
      return [];
    }
  }

  // Add a single transaction
  static Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final List<TransactionModel> transactions = await loadTransactions();
      transactions.insert(0, transaction); // Add to beginning
      return await saveTransactions(transactions);
    } catch (e) {
      print('❌ Error adding transaction to local storage: $e');
      return false;
    }
  }

  // Delete a transaction by ID
  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      final List<TransactionModel> transactions = await loadTransactions();
      transactions.removeWhere((t) => t.id == transactionId);
      return await saveTransactions(transactions);
    } catch (e) {
      print('❌ Error deleting transaction from local storage: $e');
      return false;
    }
  }

  // Clear all transactions
  static Future<bool> clearAllTransactions() async {
    try {
      await init();
      final bool result = await _prefs!.remove(_transactionsKey);
      print('✅ All transactions cleared from local storage');
      return result;
    } catch (e) {
      print('❌ Error clearing transactions from local storage: $e');
      return false;
    }
  }

  // Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      await init();
      final String? jsonString = _prefs!.getString(_transactionsKey);
      final int sizeInBytes = jsonString?.length ?? 0;
      final List<TransactionModel> transactions = await loadTransactions();

      return {
        'transaction_count': transactions.length,
        'storage_size_bytes': sizeInBytes,
        'storage_size_kb': (sizeInBytes / 1024).toStringAsFixed(2),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'transaction_count': 0,
        'storage_size_bytes': 0,
      };
    }
  }
}
