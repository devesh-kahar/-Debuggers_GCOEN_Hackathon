import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/panic_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _walkingModeEnabled = false;
  bool _voiceDetectionEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('SafeGuard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Stay Safe',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI-powered safety companion',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Panic Button
            Center(
              child: PanicButton(
                onPressed: () {
                  _showEmergencyDialog();
                },
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Walking Mode Toggle
            _buildFeatureCard(
              icon: Icons.directions_walk_rounded,
              title: 'Walking Mode',
              subtitle: 'Enable voice detection & tracking',
              isActive: _walkingModeEnabled,
              onToggle: (value) {
                setState(() {
                  _walkingModeEnabled = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Voice Detection Toggle
            _buildFeatureCard(
              icon: Icons.mic_rounded,
              title: 'Voice Detection',
              subtitle: 'Listen for emergency keywords',
              isActive: _voiceDetectionEnabled,
              onToggle: (value) {
                setState(() {
                  _voiceDetectionEnabled = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Feature Cards
            Text(
              'Features',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.map_rounded,
                    title: 'Safe Routes',
                    color: AppColors.safe,
                    onTap: () {
                      // Navigate to map screen
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.location_on_rounded,
                    title: 'Share Location',
                    color: AppColors.info,
                    onTap: () {
                      // Navigate to tracking screen
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.shield_rounded,
                    title: 'Privacy Scan',
                    color: AppColors.primary,
                    onTap: () {
                      // Navigate to privacy screen
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.contacts_rounded,
                    title: 'Contacts',
                    color: AppColors.accent,
                    onTap: () {
                      // Navigate to contacts screen
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Safety Tips
            _buildSafetyTip(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required Function(bool) onToggle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.2) : AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: isActive,
              onChanged: onToggle,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.accent.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Tip',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Always share your location when walking alone at night',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text('Are you in an emergency situation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger emergency
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 Emergency alert sent!'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Yes, Send Alert'),
          ),
        ],
      ),
    );
  }
}
