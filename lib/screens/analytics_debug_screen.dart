import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/analytics_token_service.dart';
import '../services/credentials_service.dart';
import '../services/analytics_api_service.dart';

class AnalyticsDebugScreen extends StatefulWidget {
  const AnalyticsDebugScreen({super.key});

  @override
  State<AnalyticsDebugScreen> createState() => _AnalyticsDebugScreenState();
}

class _AnalyticsDebugScreenState extends State<AnalyticsDebugScreen> {
  Map<String, dynamic> _tokenInfo = {};
  bool _isLoading = false;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await AnalyticsTokenService.getTokenInfo();
      setState(() {
        _tokenInfo = info;
        _output = 'Token info loaded successfully';
      });
    } catch (e) {
      setState(() {
        _output = 'Error loading token info: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateToken() async {
    setState(() {
      _isLoading = true;
      _output = 'Generating new token...';
    });

    try {
      final tokenData = await AnalyticsTokenService.generateAccessToken();
      if (tokenData != null) {
        setState(() {
          _output =
              'Token generated successfully!\n\n' +
              'Access Token: ${tokenData['access_token']?.substring(0, 20)}...\n' +
              'Expires In: ${tokenData['expires_in']} seconds\n' +
              'API Domain: ${tokenData['api_domain']}\n' +
              'Scope: ${tokenData['scope']}\n' +
              'Expires At: ${tokenData['expires_at']}';
        });
        await _loadTokenInfo();
      } else {
        setState(() {
          _output =
              'Failed to generate token. Check credentials and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Error generating token: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getValidToken() async {
    setState(() {
      _isLoading = true;
      _output = 'Getting valid token...';
    });

    try {
      final token = await AnalyticsTokenService.getValidAccessToken();
      if (token != null) {
        setState(() {
          _output = 'Valid token retrieved:\n${token.substring(0, 50)}...';
        });
      } else {
        setState(() {
          _output = 'No valid token available. Generate a new one.';
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Error getting valid token: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearTokens() async {
    setState(() {
      _isLoading = true;
      _output = 'Clearing token data...';
    });

    try {
      await AnalyticsTokenService.clearTokenData();
      setState(() {
        _output = 'Token data cleared successfully';
      });
      await _loadTokenInfo();
    } catch (e) {
      setState(() {
        _output = 'Error clearing tokens: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkCredentials() async {
    setState(() {
      _isLoading = true;
      _output = 'Checking stored credentials...';
    });

    try {
      final isConfigured = await CredentialsService.isAnalyticsConfigured();
      final credentials = await CredentialsService.getMaskedCredentials();

      setState(() {
        _output =
            'Analytics configured: $isConfigured\n\n' +
            'OAuth Credentials:\n' +
            'Client ID: ${credentials['clientId']}\n' +
            'Client Secret: ${credentials['clientSecret']}\n' +
            'Refresh Token: ${credentials['refreshToken']}\n\n' +
            'Workspace Information:\n' +
            'Organization ID: ${credentials['orgId']}\n' +
            'Workspace ID: ${credentials['workspaceId']}\n' +
            'Table ID: ${credentials['tableId']}';
      });
    } catch (e) {
      setState(() {
        _output = 'Error checking credentials: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _validateTableSchema() async {
    setState(() {
      _isLoading = true;
      _output = 'Validating table schema...';
    });

    try {
      final validation = await AnalyticsApiService.validateTransactionSchema();

      if (validation.isValid) {
        setState(() {
          _output =
              '✅ Table schema validation successful!\n\n' +
              'Available columns: ${validation.availableColumns?.join(', ')}\n\n' +
              'All required fields are present and compatible:\n' +
              '• id (POSITIVE_NUMBER)\n' +
              '• type (PLAIN)\n' +
              '• category (PLAIN)\n' +
              '• amount (CURRENCY)\n' +
              '• note (PLAIN)\n' +
              '• date (DATE_AS_DATE)';
        });
      } else {
        setState(() {
          _output =
              '❌ Table schema validation failed!\n\n' +
              'Error: ${validation.error}\n\n' +
              'Available columns: ${validation.availableColumns?.join(', ') ?? 'Unable to fetch'}';
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Error validating table schema: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics Debug',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Token Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Token Status',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_tokenInfo.isNotEmpty) ...[
                      _buildInfoRow(
                        'Has Token',
                        _tokenInfo['has_token']?.toString() ?? 'false',
                      ),
                      if (_tokenInfo['token_preview'] != null)
                        _buildInfoRow(
                          'Token Preview',
                          _tokenInfo['token_preview'],
                        ),
                      if (_tokenInfo['expires_at'] != null)
                        _buildInfoRow('Expires At', _tokenInfo['expires_at']),
                      _buildInfoRow(
                        'Is Expired',
                        _tokenInfo['is_expired']?.toString() ?? 'true',
                      ),
                      if (_tokenInfo['time_until_expiry'] != null)
                        _buildInfoRow(
                          'Minutes Until Expiry',
                          _tokenInfo['time_until_expiry']?.toString() ?? 'N/A',
                        ),
                      if (_tokenInfo['scope'] != null)
                        _buildInfoRow('Scope', _tokenInfo['scope']),
                      if (_tokenInfo['api_domain'] != null)
                        _buildInfoRow('API Domain', _tokenInfo['api_domain']),
                    ] else
                      const Text('No token info available'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkCredentials,
                  child: const Text('Check Credentials'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _validateTableSchema,
                  child: const Text('Validate Table'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateToken,
                  child: const Text('Generate Token'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getValidToken,
                  child: const Text('Get Valid Token'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadTokenInfo,
                  child: const Text('Refresh Info'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearTokens,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Clear Tokens'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Output Console
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Console Output',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _output.isEmpty ? 'No output yet...' : _output,
                            style: GoogleFonts.jetBrainsMono(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
