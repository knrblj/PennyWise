import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/credentials_service.dart';
import '../services/analytics_token_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/analytics_setup_guide_dialog.dart';

class AnalyticsConfigScreen extends StatefulWidget {
  final bool isReconfiguring;

  const AnalyticsConfigScreen({super.key, this.isReconfiguring = false});

  @override
  State<AnalyticsConfigScreen> createState() => _AnalyticsConfigScreenState();
}

class _AnalyticsConfigScreenState extends State<AnalyticsConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _refreshTokenController = TextEditingController();
  final _orgIdController = TextEditingController();
  final _workspaceIdController = TextEditingController();
  final _tableIdController = TextEditingController();

  bool _isLoading = false;
  bool _showPasswords = false;
  bool _isTestingConnection = false;
  Map<String, String> _maskedCredentials = {};

  @override
  void initState() {
    super.initState();
    if (widget.isReconfiguring) {
      _loadMaskedCredentials();
    }
  }

  Future<void> _loadMaskedCredentials() async {
    final masked = await CredentialsService.getMaskedCredentials();
    setState(() {
      _maskedCredentials = masked;
    });
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _refreshTokenController.dispose();
    _orgIdController.dispose();
    _workspaceIdController.dispose();
    _tableIdController.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await CredentialsService.saveCredentials(
        clientId: _clientIdController.text,
        clientSecret: _clientSecretController.text,
        refreshToken: _refreshTokenController.text,
        orgId: _orgIdController.text,
        workspaceId: _workspaceIdController.text,
        tableId: _tableIdController.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
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
          Navigator.of(context).pop(true); // Return success
        } else {
          _showErrorSnackBar('Failed to save credentials. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTestingConnection = true);

    try {
      // First save the credentials temporarily to test them
      final success = await CredentialsService.saveCredentials(
        clientId: _clientIdController.text,
        clientSecret: _clientSecretController.text,
        refreshToken: _refreshTokenController.text,
        orgId: _orgIdController.text,
        workspaceId: _workspaceIdController.text,
        tableId: _tableIdController.text,
      );

      if (!success) {
        throw Exception('Failed to save credentials for testing');
      }

      // Test actual token generation
      print('🧪 Testing analytics token generation...');
      final tokenData = await AnalyticsTokenService.generateAccessToken();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  tokenData != null ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tokenData != null
                            ? 'Analytics connection successful!'
                            : 'Analytics connection failed. Check credentials.',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      if (tokenData != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Token expires in: ${tokenData['expires_in']} seconds\nAPI Domain: ${tokenData['api_domain']}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: tokenData != null ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Analytics test failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  Future<void> _clearCredentials() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Analytics Configuration',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will remove all saved analytics credentials. You will need to reconfigure to sync data.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final success = await CredentialsService.clearCredentials();

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Analytics configuration cleared',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(false); // Return cleared
        } else {
          _showErrorSnackBar('Failed to clear configuration');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isReconfiguring ? 'Reconfigure Analytics' : 'Setup Analytics',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AnalyticsSetupGuideDialog(),
              );
            },
            tooltip: 'Setup Help',
          ),
          if (widget.isReconfiguring)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _clearCredentials,
              tooltip: 'Clear Configuration',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                _buildHeaderInfo(),
                const SizedBox(height: 24),

                // Current Configuration (if reconfiguring)
                if (widget.isReconfiguring) ...[
                  _buildCurrentConfig(),
                  const SizedBox(height: 24),
                ],

                // Credentials Form
                _buildCredentialsForm(),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(),
                const SizedBox(height: 16),

                // Security Note
                _buildSecurityNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      color: Colors.blue.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Text(
                'Analytics Integration',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.isReconfiguring
                ? 'Update your analytics credentials to continue syncing transaction data.'
                : 'Configure your analytics credentials to automatically sync transaction data to your analytics dashboard.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConfig() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Configuration',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildCredentialRow(
            'Client ID',
            _maskedCredentials['clientId'] ?? '',
          ),
          _buildCredentialRow(
            'Client Secret',
            _maskedCredentials['clientSecret'] ?? '',
          ),
          _buildCredentialRow(
            'Refresh Token',
            _maskedCredentials['refreshToken'] ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsForm() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics Credentials',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showPasswords ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() => _showPasswords = !_showPasswords);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Client ID
          TextFormField(
            controller: _clientIdController,
            decoration: InputDecoration(
              labelText: 'Client ID',
              hintText: 'Enter your analytics client ID',
              prefixIcon: const Icon(Icons.account_circle),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Client ID is required';
              }
              if (value.trim().length < 10) {
                return 'Client ID must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Client Secret
          TextFormField(
            controller: _clientSecretController,
            obscureText: !_showPasswords,
            decoration: InputDecoration(
              labelText: 'Client Secret',
              hintText: 'Enter your analytics client secret',
              prefixIcon: const Icon(Icons.key),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Client Secret is required';
              }
              if (value.trim().length < 10) {
                return 'Client Secret must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Refresh Token
          TextFormField(
            controller: _refreshTokenController,
            obscureText: !_showPasswords,
            decoration: InputDecoration(
              labelText: 'Refresh Token',
              hintText: 'Enter your analytics refresh token',
              prefixIcon: const Icon(Icons.token),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Refresh Token is required';
              }
              if (value.trim().length < 10) {
                return 'Refresh Token must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Workspace Information Section
          Text(
            'Workspace Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Specify the Zoho Analytics organization, workspace, and table for data synchronization.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Organization ID
          TextFormField(
            controller: _orgIdController,
            decoration: InputDecoration(
              labelText: 'Organization ID',
              hintText: 'Enter your Zoho Analytics organization ID',
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Organization ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Workspace ID
          TextFormField(
            controller: _workspaceIdController,
            decoration: InputDecoration(
              labelText: 'Workspace ID',
              hintText: 'Enter your Zoho Analytics workspace ID',
              prefixIcon: const Icon(Icons.workspaces),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Workspace ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Table ID
          TextFormField(
            controller: _tableIdController,
            decoration: InputDecoration(
              labelText: 'Table ID',
              hintText: 'Enter your expense table ID',
              prefixIcon: const Icon(Icons.table_chart),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Table ID is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Test Connection Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading || _isTestingConnection
                ? null
                : _testCredentials,
            icon: _isTestingConnection
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_protected_setup),
            label: Text(
              _isTestingConnection ? 'Testing...' : 'Test Connection',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Save Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading || _isTestingConnection
                ? null
                : _saveCredentials,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isLoading ? 'Saving...' : 'Save Configuration',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: Colors.green.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Storage',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your credentials are encrypted and stored securely on your device. Only this app can access them.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
