// API Configuration Constants
class ApiConstants {
  // TODO: Replace with your actual API endpoint
  static const String baseUrl = 'https://your-analytics-api.com/api';
  static const String transactionsEndpoint = '/transactions';

  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // TODO: Add your API key or authentication token here
  static const String? apiKey = null; // Replace with your API key
  static const String? authToken = null; // Replace with your auth token
}

// App Constants
class AppConstants {
  static const String appName = 'KB Expense Tracker';
  static const String appVersion = '1.0.0';

  // Categories
  static const List<String> transactionCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Rent',
    'Salary',
    'Investment',
    'Health',
    'Education',
    'Other',
  ];

  // Transaction types
  static const String creditType = 'credit';
  static const String debitType = 'debit';

  // UI Constants
  static const double defaultBorderRadius = 16.0;
  static const double glassBlurStrength = 10.0;
}
