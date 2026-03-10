import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/privacy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // TODO: Initialize Firebase
  // await Firebase.initializeApp();
  
  runApp(const SafeGuardApp());
}

class SafeGuardApp extends StatelessWidget {
  const SafeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add your providers here
        // ChangeNotifierProvider(create: (_) => SafetyProvider()),
      ],
      child: MaterialApp(
        title: 'SafeGuard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigator(),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const EmergencyScreen(),
    const TrackingScreen(),
    const PrivacyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Routes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_rounded),
              label: 'SOS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_rounded),
              label: 'Privacy',
            ),
          ],
        ),
      ),
    );
  }
}
