import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/panic_button.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final List<Map<String, String>> _emergencyContacts = [
    {'name': 'Mom', 'phone': '+1234567890', 'relation': 'Mother'},
    {'name': 'Dad', 'phone': '+1234567891', 'relation': 'Father'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _addEmergencyContact,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Panic Button
            Center(
              child: PanicButton(
                size: 160,
                onPressed: _triggerEmergency,
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.phone_rounded,
                    label: 'Call 911',
                    color: AppColors.danger,
                    onTap: () {
                      // Call emergency services
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.location_on_rounded,
                    label: 'Share Location',
                    color: AppColors.info,
                    onTap: () {
                      // Share location
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.videocam_rounded,
                    label: 'Record',
                    color: AppColors.warning,
                    onTap: () {
                      // Start recording
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.call_rounded,
                    label: 'Fake Call',
                    color: AppColors.success,
                    onTap: () {
                      // Trigger fake call
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Emergency Contacts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                TextButton.icon(
                  onPressed: _addEmergencyContact,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ..._emergencyContacts.map((contact) => _buildContactCard(contact)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, String> contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(
            contact['name']![0],
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(contact['name']!),
        subtitle: Text('${contact['relation']} • ${contact['phone']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone_rounded),
              onPressed: () {
                // Call contact
              },
            ),
            IconButton(
              icon: const Icon(Icons.message_rounded),
              onPressed: () {
                // Message contact
              },
            ),
          ],
        ),
      ),
    );
  }

  void _triggerEmergency() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.danger,
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Emergency Alert', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Sending emergency alerts to your contacts...',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // Auto-close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Emergency alerts sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _addEmergencyContact() {
    // TODO: Implement add contact dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add contact feature coming soon')),
    );
  }
}
