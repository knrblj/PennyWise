import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/credentials_service.dart';
import '../screens/analytics_config_screen.dart';
import '../screens/analytics_debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final loadedTransactions = await LocalStorageService.loadTransactions();
      if (mounted) {
        setState(() {
          transactions = loadedTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addTransaction(TransactionModel transaction) async {
    // Add to UI immediately for responsiveness
    setState(() {
      transactions.insert(0, transaction);
    });

    // Save to local storage
    final localSaved = await LocalStorageService.addTransaction(transaction);

    if (!localSaved) {
      // If local save failed, show warning but keep in UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Warning: Failed to save locally',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }

    // Push to analytics backend (non-blocking)
    ApiService.pushTransaction(transaction).then((success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  success ? 'Synced to analytics' : 'Saved locally only',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.blue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });
  }

  Future<void> _openAnalyticsConfig() async {
    final isConfigured = await CredentialsService.isAnalyticsConfigured();

    if (mounted) {
      final result = await Navigator.of(context).push<bool?>(
        MaterialPageRoute(
          builder: (context) =>
              AnalyticsConfigScreen(isReconfiguring: isConfigured),
        ),
      );

      if (result == true) {
        // Configuration was successful, show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.analytics, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Analytics configured successfully!',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openAnalyticsDebug() async {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AnalyticsDebugScreen()),
      );
    }
  }

  Future<void> _syncAllTransactions() async {
    // Check if analytics is configured
    final isConfigured = await CredentialsService.isAnalyticsConfigured();
    if (!isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Analytics not configured. Please configure analytics first.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (transactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ℹ️ No transactions to sync.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sync All Transactions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will replace ALL data in your analytics workspace with ${transactions.length} local transactions.\n\n'
          '⚠️ Warning: This will permanently delete all existing data in your analytics table and replace it with current local data.\n\n'
          'Are you sure you want to continue?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Sync & Replace',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Syncing ${transactions.length} transactions...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final success = await ApiService.syncAllTransactions(transactions);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Successfully synced ${transactions.length} transactions!'
                  : '❌ Failed to sync transactions. Check debug console for details.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('❌ Sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _deleteTransaction(String transactionId) {
    // Find the transaction to show details in confirmation
    final transaction = transactions.firstWhere((t) => t.id == transactionId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Transaction',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this transaction?\n\n'
          '${transaction.category}: ₹${NumberFormat('#,##,###').format(transaction.amount)}\n'
          '${transaction.note}',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Remove from UI immediately
              setState(() {
                transactions.removeWhere((t) => t.id == transactionId);
              });
              Navigator.of(context).pop();

              // Remove from local storage
              final localDeleted = await LocalStorageService.deleteTransaction(
                transactionId,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          localDeleted
                              ? 'Transaction deleted'
                              : 'Deleted from app (local save failed)',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                    backgroundColor: localDeleted ? Colors.red : Colors.orange,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTransactions() async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No transactions to export',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Convert transactions to JSON
      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'total_transactions': transactions.length,
        'summary': {
          'total_income': totalIncome,
          'total_expense': totalExpense,
          'balance': balance,
        },
        'transactions': transactions
            .map(
              (t) => {
                'id': t.id,
                'type': t.type,
                'category': t.category,
                'amount': t.amount,
                'note': t.note,
                'date': t.date.toIso8601String(),
              },
            )
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_done, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Transactions exported to clipboard as JSON',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Exported JSON',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    content: SingleChildScrollView(
                      child: SelectableText(
                        jsonString,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddTransactionModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AddTransactionModal(onTransactionAdded: _addTransaction),
    );
  }

  double get totalIncome {
    return transactions
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading screen while data is loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Sort transactions by date (newest first)
    final sortedTransactions = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // iOS-style Header
            _buildHeader(context),

            // Balance Cards
            _buildBalanceCards(context),

            // Transactions List
            Expanded(child: _buildTransactionsList(sortedTransactions)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PennyWise',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Smart spending, smarter insights',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // Analytics Config button with menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'config') {
                _openAnalyticsConfig();
              } else if (value == 'debug') {
                _openAnalyticsDebug();
              } else if (value == 'sync') {
                _syncAllTransactions();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'config',
                child: Row(
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 8),
                    Text('Analytics Config', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, size: 20),
                    const SizedBox(width: 8),
                    Text('Debug Console', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    const Icon(Icons.sync, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Sync All Data',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/icons/analytics_icon_24.png',
                width: 24,
                height: 24,
                color: Colors.purple,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to default icon if image fails to load
                  return const Icon(
                    Icons.analytics_outlined,
                    color: Colors.purple,
                    size: 24,
                  );
                },
              ),
            ),
          ),
          // Export button
          GestureDetector(
            onTap: _exportTransactions,
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Balance',
              balance,
              balance >= 0 ? Colors.blue : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Income', totalIncome, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Expense', totalExpense, Colors.red)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: color.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹${NumberFormat('#,##,###').format(amount.abs())}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> sortedTransactions) {
    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.displayMedium?.color,
                ),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: sortedTransactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sortedTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = sortedTransactions[index];
                    return TransactionTile(
                      key: ValueKey(transaction.id), // Prevent widget jumping
                      transaction: transaction,
                      onDelete: () => _deleteTransaction(transaction.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to get started',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddTransactionModal,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add Transaction',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }
}
