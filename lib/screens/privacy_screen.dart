import 'package:flutter/material.dart';
import '../config/theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isScanning = false;
  bool _hasScanned = false;
  int _privacyScore = 0;
  List<Map<String, dynamic>> _breaches = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Score Card
            if (_hasScanned) _buildPrivacyScoreCard(),
            if (_hasScanned) const SizedBox(height: 24),

            // Scan Form
            if (!_hasScanned) ...[
              Text(
                'Scan Your Digital Footprint',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Check if your personal information has been leaked online',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(_isScanning ? 'Scanning...' : 'Start Scan'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ],

            // Results
            if (_hasScanned) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Found Issues',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  TextButton.icon(
                    onPressed: _resetScan,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('New Scan'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_breaches.isEmpty)
                _buildNoIssuesCard()
              else
                ..._breaches.map((breach) => _buildBreachCard(breach)),

              const SizedBox(height: 24),

              // Privacy Tips
              Text(
                'Privacy Tips',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              _buildPrivacyTip(
                icon: Icons.lock_rounded,
                title: 'Use Strong Passwords',
                subtitle: 'Use unique passwords for each account',
              ),
              _buildPrivacyTip(
                icon: Icons.security_rounded,
                title: 'Enable 2FA',
                subtitle: 'Add an extra layer of security',
              ),
              _buildPrivacyTip(
                icon: Icons.visibility_off_rounded,
                title: 'Limit Social Media',
                subtitle: 'Make your profiles private',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyScoreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Privacy Score',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _privacyScore / 100,
                    strokeWidth: 12,
                    backgroundColor: AppColors.cardLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(_privacyScore),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$_privacyScore',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getScoreLabel(_privacyScore),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _breaches.isEmpty
                  ? 'No breaches found!'
                  : '${_breaches.length} issues found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreachCard(Map<String, dynamic> breach) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(breach['severity']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: _getSeverityColor(breach['severity']),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        breach['title'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        breach['source'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              breach['description'],
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Request removal
              },
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('Request Removal'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoIssuesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              'All Clear!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No data breaches or leaks found',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTip({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startScan() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    // Simulate scanning
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isScanning = false;
      _hasScanned = true;
      _privacyScore = 75;
      _breaches = [
        {
          'title': 'Data Breach Found',
          'source': 'example.com',
          'description': 'Your email was found in a 2023 data breach',
          'severity': 'high',
        },
      ];
    });
  }

  void _resetScan() {
    setState(() {
      _hasScanned = false;
      _privacyScore = 0;
      _breaches = [];
      _nameController.clear();
      _emailController.clear();
    });
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.moderate;
    return AppColors.danger;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.moderate;
      default:
        return AppColors.success;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
