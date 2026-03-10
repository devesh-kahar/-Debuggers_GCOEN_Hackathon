import 'package:flutter/material.dart';
import '../config/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _destinationController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Routes'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Enter destination',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location_rounded),
                      onPressed: () {
                        // Get current location
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _findSafeRoutes,
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('Find Safe Routes'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),

          // Map Placeholder
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 80,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter a destination to see safe routes',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Google Maps integration coming soon',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Route Options (when available)
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _findSafeRoutes() {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement route finding
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }
}
