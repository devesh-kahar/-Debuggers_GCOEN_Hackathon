# 🛡️ SafeGuard - AI-Powered Personal Safety App

An intelligent safety companion that protects you both physically and digitally. Built with Flutter for the hackathon.

## 🌟 Features

### 1. 🗺️ Smart Safe Route Navigator
- Real-time crime data integration (UK Police API / Crimeometer)
- Safety scoring algorithm (0-100) based on:
  - Crime incidents along route
  - Street lighting density
  - Time of day
  - User reports
- Multiple route comparison
- Interactive crime heatmap
- Google Maps integration

### 2. 🚨 Voice-Activated Emergency SOS
- Background voice detection for keywords: "help", "emergency", "stop"
- Multiple trigger methods:
  - Voice activation
  - Panic button (hold to activate)
  - Shake phone 3 times
- Emergency response:
  - SMS to emergency contacts with location
  - Audio/video recording
  - Location sharing
  - Direct call to emergency services
- 5-second countdown to cancel false alarms

### 3. 📍 Live Location Sharing & Tracking
- Real-time GPS tracking
- Shareable location links
- Auto-expiry (30, 60, 120, 240 minutes)
- Firebase Realtime Database integration
- ETA calculation
- Check-in alerts

### 4. 🔒 Digital Privacy Scanner
- Email breach detection (Have I Been Pwned API)
- Google Custom Search for personal info
- Privacy score calculation
- Data breach alerts
- Removal request generator
- Privacy tips and recommendations

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.10.1 or higher)
- Android Studio / Xcode
- Google Cloud Platform account
- Firebase account

### Installation

1. **Clone the repository**
```bash
cd safeguard_app
flutter pub get
```

2. **Configure API Keys**

Edit `lib/config/api_keys.dart` and add your API keys:

```dart
class ApiKeys {
  static const String googleMapsApiKey = 'YOUR_KEY_HERE';
  static const String googleCustomSearchApiKey = 'YOUR_KEY_HERE';
  static const String googleCustomSearchEngineId = 'YOUR_ENGINE_ID';
  // Optional
  static const String crimeometerApiKey = 'YOUR_KEY_HERE';
  static const String haveibeenpwnedApiKey = 'YOUR_KEY_HERE';
}
```

3. **Set up Firebase** (Optional but recommended)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init
```

Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase Console and place them in:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

4. **Configure Permissions**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.VIBRATE"/>

<!-- Add Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to suggest safe routes</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to track you during emergencies</string>
<key>NSMicrophoneUsageDescription</key>
<string>We listen for emergency keywords to keep you safe</string>
<key>NSCameraUsageDescription</key>
<string>Record evidence during emergencies</string>
<key>NSContactsUsageDescription</key>
<string>Access contacts for emergency alerts</string>
```

5. **Run the app**
```bash
flutter run
```

## 🔑 API Keys Setup Guide

### 1. Google Maps Platform
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Directions API
   - Places API
   - Geocoding API
4. Create credentials → API Key
5. (Optional) Restrict the API key

### 2. Google Custom Search
1. Go to [Google Custom Search](https://programmablesearchengine.google.com/)
2. Create a new search engine
3. Get your Search Engine ID
4. Go to [Google Cloud Console](https://console.cloud.google.com)
5. Enable Custom Search API
6. Create API key

### 3. UK Police API (No Key Needed!)
- Free, no registration required
- Excellent crime data for UK
- API: `https://data.police.uk/api`

### 4. Crimeometer (USA - Optional)
1. Go to [Crimeometer](https://www.crimeometer.com/crime-data-api)
2. Sign up for free tier (1000 requests/month)
3. Get API key

### 5. Have I Been Pwned (Optional)
1. Go to [HIBP API](https://haveibeenpwned.com/API/Key)
2. Free for non-commercial use
3. No key needed for basic breach check

## 📱 App Structure

```
lib/
├── config/
│   ├── api_keys.dart          # API configuration
│   └── theme.dart             # App theme & colors
├── models/
│   ├── crime_incident.dart    # Crime data model
│   ├── route_safety.dart      # Route & safety score
│   ├── emergency_contact.dart # Emergency contacts
│   ├── location_share.dart    # Location sharing
│   └── privacy_breach.dart    # Privacy scan results
├── services/
│   ├── crime_data_service.dart      # Crime API integration
│   ├── maps_service.dart            # Google Maps & routing
│   ├── emergency_service.dart       # SOS functionality
│   ├── voice_detection_service.dart # Speech recognition
│   └── location_service.dart        # GPS tracking
├── screens/
│   ├── home_screen.dart       # Dashboard
│   ├── map_screen.dart        # Safe routes
│   ├── emergency_screen.dart  # SOS controls
│   ├── tracking_screen.dart   # Location sharing
│   └── privacy_screen.dart    # Privacy scanner
└── widgets/
    └── panic_button.dart      # Animated SOS button
```

## 🎨 Design System

### Colors
- Primary: `#6C63FF` (Purple)
- Danger: `#EF5350` (Red)
- Safe: `#4CAF50` (Green)
- Warning: `#FFA726` (Orange)
- Background: `#0F0F1E` (Dark)

### Typography
- Font: Inter (Google Fonts)
- Heading: 32px, Bold
- Body: 16px, Regular
- Caption: 12px, Regular

## 🔧 Development Tips

### Testing Voice Detection
```dart
// Test keywords: "help", "help me", "emergency", "stop"
VoiceDetectionService().onEmergencyDetected = (text) {
  print('Emergency detected: $text');
};
```

### Testing Crime Data
```dart
// UK Police API (no key needed)
final crimes = await CrimeDataService().fetchUKPoliceCrimes(
  location: LatLng(51.5074, -0.1278), // London
);
```

### Mock Data for Demo
If APIs are not set up, the app will work with placeholder data for demo purposes.

## 🚨 Important Notes

### For Hackathon Demo
1. **Test on real device** - Voice detection works better on physical devices
2. **Pre-load API keys** - Don't waste time during hackathon
3. **Prepare mock data** - Have backup if APIs fail
4. **Test all features** - Run through complete user flow
5. **Practice pitch** - 3-minute demo script

### Privacy & Security
- Never commit API keys to Git
- Use environment variables in production
- Implement proper authentication
- Encrypt sensitive data
- Follow GDPR/privacy regulations

## 📊 Safety Score Algorithm

```dart
Overall Score = (
  Crime Score × 0.35 +
  Lighting Score × 0.25 +
  Time Score × 0.25 +
  User Reports × 0.15
)

Crime Score = 100 - (crime_count × 10)
Lighting Score = (lights_per_km × 10)
Time Score = night ? 60 : 100
User Report Score = 100 - (negative_reports × 5)
```

## 🎯 Hackathon Winning Strategy

### What Judges Look For
1. ✅ **Solves real problem** - Personal safety is universal
2. ✅ **Technical complexity** - Multiple APIs, real-time data
3. ✅ **Beautiful UI** - Professional design
4. ✅ **Working demo** - No crashes, smooth flow
5. ✅ **Innovation** - AI voice detection, multi-factor safety

### Demo Script (3 minutes)
1. **Problem** (30s): "Every day, people feel unsafe walking alone"
2. **Solution** (30s): "SafeGuard is your AI safety companion"
3. **Feature 1** (45s): Show safe route comparison
4. **Feature 2** (30s): Trigger voice detection
5. **Feature 3** (30s): Share location
6. **Feature 4** (15s): Privacy scan
7. **Impact** (30s): "Making the world safer, one route at a time"

## 🐛 Troubleshooting

### Google Maps not showing
- Check API key is correct
- Enable Maps SDK in Google Cloud Console
- Add API key to AndroidManifest.xml / Info.plist

### Voice detection not working
- Grant microphone permission
- Test on physical device (emulator may not work)
- Check speech_to_text package is initialized

### Firebase errors
- Ensure google-services.json is in correct location
- Run `flutter clean` and rebuild
- Check Firebase project configuration

## 📝 TODO for Production

- [ ] Implement Firebase authentication
- [ ] Add user profiles
- [ ] Community safety reports
- [ ] Offline mode with cached routes
- [ ] Push notifications
- [ ] Apple Watch integration
- [ ] Background location tracking
- [ ] ML model for scream detection
- [ ] Integration with local police APIs
- [ ] Multi-language support

## 📄 License

MIT License - Built for Hackathon

## 🤝 Contributing

This is a hackathon project. Feel free to fork and improve!

## 📞 Support

For hackathon questions, contact the team.

---

**Built with ❤️ using Flutter**

Good luck at the hackathon! 🚀
