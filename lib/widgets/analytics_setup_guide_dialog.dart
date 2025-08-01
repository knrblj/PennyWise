import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsSetupGuideDialog extends StatelessWidget {
  const AnalyticsSetupGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Zoho Analytics Setup Guide',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSection('OAuth Credentials', [
                _buildStep(
                  '1',
                  'Go to Zoho API Console',
                  'https://api-console.zoho.com/',
                ),
                _buildStep('2', 'Create a new client application'),
                _buildStep('3', 'Copy the Client ID and Client Secret'),
                _buildStep('4', 'Generate a Refresh Token using OAuth flow'),
              ]),
              const SizedBox(height: 20),
              _buildSection('Workspace Information', [
                _buildStep(
                  '1',
                  'Log into Zoho Analytics',
                  'https://analytics.zoho.com/',
                ),
                _buildStep('2', 'Go to your workspace dashboard'),
                _buildStep('3', 'Find Organization ID in account settings'),
                _buildStep(
                  '4',
                  'Copy Workspace ID from URL or workspace settings',
                ),
                _buildStep('5', 'Create or locate your expense tracking table'),
                _buildStep('6', 'Copy the Table ID from table settings'),
              ]),
              const SizedBox(height: 20),
              _buildInfoBox(
                'Example Table Structure',
                'Your expense table should have columns like:\n'
                    '• Date (date field)\n'
                    '• Amount (number field)\n'
                    '• Category (text field)\n'
                    '• Description (text field)\n'
                    '• Type (Income/Expense)',
                Icons.table_chart,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildInfoBox(
                'Finding IDs',
                'Organization ID: Account Settings → Organization Details\n'
                    'Workspace ID: In the URL when viewing workspace\n'
                    'Table ID: Table Settings → Properties',
                Icons.search,
                Colors.orange,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Could open browser to Zoho Analytics
          },
          child: Text(
            'Open Zoho Analytics',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...steps,
      ],
    );
  }

  Widget _buildStep(String number, String text, [String? url]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: GoogleFonts.poppins(fontSize: 14)),
                if (url != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
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
