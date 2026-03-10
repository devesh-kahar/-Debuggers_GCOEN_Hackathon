import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isSharing = false;
  int _selectedDuration = 60; // minutes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Sharing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 24),

            // Share Location Section
            if (!_isSharing) ...[
              Text(
                'Share Your Location',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Duration Selector
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                children: [
                  _buildDurationChip(30),
                  _buildDurationChip(60),
                  _buildDurationChip(120),
                  _buildDurationChip(240),
                ],
              ),
              const SizedBox(height: 24),

              // Start Sharing Button
              ElevatedButton.icon(
                onPressed: _startSharing,
                icon: const Icon(Icons.share_location_rounded),
                label: const Text('Start Sharing'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ] else ...[
              // Active Sharing Section
              Text(
                'Currently Sharing',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              _buildShareLinkCard(),
              const SizedBox(height: 24),

              // Stop Sharing Button
              ElevatedButton.icon(
                onPressed: _stopSharing,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop Sharing'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.danger,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Features
            Text(
              'Features',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              icon: Icons.timer_rounded,
              title: 'Auto-Expire',
              subtitle: 'Location sharing stops automatically',
            ),
            _buildFeatureItem(
              icon: Icons.lock_rounded,
              title: 'Privacy First',
              subtitle: 'Only people with link can see your location',
            ),
            _buildFeatureItem(
              icon: Icons.notifications_rounded,
              title: 'Check-In Alerts',
              subtitle: 'Get notified when you reach destination',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSharing
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.textTertiary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSharing ? Icons.location_on_rounded : Icons.location_off_rounded,
                color: _isSharing ? AppColors.success : AppColors.textTertiary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSharing ? 'Location Sharing Active' : 'Not Sharing',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isSharing
                        ? 'Expires in ${_selectedDuration} minutes'
                        : 'Start sharing to let others track you',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes) {
    final isSelected = _selectedDuration == minutes;
    return ChoiceChip(
      label: Text('${minutes} min'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDuration = minutes;
        });
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildShareLinkCard() {
    const shareLink = 'https://safeguard.app/track/abc123';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Link',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: shareLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Share link
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share Link'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
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

  void _startSharing() {
    setState(() {
      _isSharing = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Location sharing started'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _stopSharing() {
    setState(() {
      _isSharing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing stopped')),
    );
  }
}
