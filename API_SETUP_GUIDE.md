# 🔑 Complete API Setup Guide for SafeGuard App

This guide will help you set up all required APIs before the hackathon. Follow these steps carefully.

## ⏱️ Time Required: ~30 minutes

---

## 1. Google Maps Platform (REQUIRED) ⭐

### Step 1: Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click "Select a project" → "New Project"
3. Name: "SafeGuard-Hackathon"
4. Click "Create"

### Step 2: Enable Required APIs
1. In the left menu, go to "APIs & Services" → "Library"
2. Search and enable these APIs (click each, then "Enable"):
   - ✅ Maps SDK for Android
   - ✅ Maps SDK for iOS
   - ✅ Directions API
   - ✅ Places API
   - ✅ Geocoding API
   - ✅ Custom Search API (for privacy scanner)

### Step 3: Create API Key
1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "API Key"
3. Copy the API key immediately
4. (Optional) Click "Restrict Key":
   - Application restrictions: None (for hackathon)
   - API restrictions: Select the APIs you enabled
5. Click "Save"

### Step 4: Add to Your App
Open `lib/config/api_keys.dart` and paste:
```dart
static const String googleMapsApiKey = 'AIzaSy...YOUR_KEY_HERE';
```

### Step 5: Configure Android
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <!-- Add this inside <application> tag -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

### Step 6: Configure iOS
Edit `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 2. Google Custom Search (For Privacy Scanner) ⭐

### Step 1: Create Search Engine
1. Go to [Programmable Search Engine](https://programmablesearchengine.google.com/)
2. Click "Add" or "Get Started"
3. Sites to search: "Search the entire web"
4. Name: "SafeGuard Privacy Scanner"
5. Click "Create"
6. Copy the "Search engine ID" (looks like: `a1b2c3d4e5f6g7h8i`)

### Step 2: Get API Key
1. Already created in Google Cloud Console (Step 1)
2. Make sure "Custom Search API" is enabled

### Step 3: Add to Your App
```dart
static const String googleCustomSearchApiKey = 'AIzaSy...YOUR_KEY_HERE';
static const String googleCustomSearchEngineId = 'a1b2c3d4e5f6g7h8i';
```

---

## 3. UK Police Crime Data (NO KEY NEEDED!) ✅

This API is completely free and requires no registration!

### Test It Now
```bash
curl "https://data.police.uk/api/crimes-street/all-crime?lat=52.629729&lng=-1.131592&date=2024-01"
```

### Already Configured
The app is already set up to use this API. No action needed!

---

## 4. Crimeometer (USA Crime Data - Optional)

### Step 1: Sign Up
1. Go to [Crimeometer](https://www.crimeometer.com/crime-data-api)
2. Click "Get API Key"
3. Sign up for free tier (1000 requests/month)
4. Verify email

### Step 2: Get API Key
1. Login to dashboard
2. Copy your API key

### Step 3: Add to Your App
```dart
static const String crimeometerApiKey = 'YOUR_CRIMEOMETER_KEY';
```

**Note:** If you skip this, the app will use UK Police API instead.

---

## 5. Have I Been Pwned (Optional)

### Free Tier (Recommended for Hackathon)
No API key needed for basic breach checks!

### Premium Tier (Optional)
1. Go to [HIBP API Key](https://haveibeenpwned.com/API/Key)
2. Purchase API key ($3.50/month)
3. Add to app:
```dart
static const String haveibeenpwnedApiKey = 'YOUR_HIBP_KEY';
```

**Note:** Free tier works fine for hackathon demo.

---

## 6. Firebase (Optional but Recommended) 🔥

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Name: "SafeGuard-App"
4. Disable Google Analytics (optional)
5. Click "Create project"

### Step 2: Add Android App
1. Click Android icon
2. Package name: `com.safeguard.safeguard_app`
3. Download `google-services.json`
4. Place in: `android/app/google-services.json`

### Step 3: Add iOS App
1. Click iOS icon
2. Bundle ID: `com.safeguard.safeguardApp`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`

### Step 4: Enable Services
1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Start in test mode
4. Choose location closest to you
5. Click "Enable"

### Step 5: Enable Storage (for recordings)
1. Go to "Storage"
2. Click "Get started"
3. Start in test mode
4. Click "Done"

### Step 6: Configure Flutter
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

---

## 🧪 Testing Your Setup

### Test 1: Google Maps
```dart
// Run this in your app
final service = MapsService();
final routes = await service.getRoutesWithSafety(
  origin: LatLng(37.7749, -122.4194),
  destination: LatLng(37.7849, -122.4094),
);
print('Routes found: ${routes.length}');
```

### Test 2: Crime Data
```dart
final crimes = await CrimeDataService().fetchUKPoliceCrimes(
  location: LatLng(51.5074, -0.1278), // London
);
print('Crimes found: ${crimes.length}');
```

### Test 3: Privacy Scanner
```dart
final breaches = await PrivacyScannerService().checkDataBreaches(
  'test@example.com',
);
print('Breaches found: ${breaches.length}');
```

---

## 📋 Quick Checklist

Before the hackathon, make sure:

- [ ] Google Maps API key added to `api_keys.dart`
- [ ] Google Maps API key added to `AndroidManifest.xml`
- [ ] Google Maps API key added to iOS `AppDelegate.swift`
- [ ] Custom Search API key and Engine ID added
- [ ] Tested on real device (not just emulator)
- [ ] All permissions added to AndroidManifest.xml
- [ ] All permissions added to Info.plist
- [ ] Firebase configured (optional)
- [ ] `flutter pub get` completed successfully
- [ ] App builds without errors

---

## 🚨 Common Issues & Solutions

### Issue: "API key not found"
**Solution:** Make sure you replaced `YOUR_KEY_HERE` with actual key

### Issue: "Google Maps not showing"
**Solution:** 
1. Check API key is correct
2. Enable "Maps SDK for Android/iOS" in Google Cloud
3. Wait 5 minutes for API to activate

### Issue: "Permission denied"
**Solution:** 
1. Check AndroidManifest.xml has all permissions
2. Check Info.plist has usage descriptions
3. Manually grant permissions in device settings

### Issue: "Firebase not working"
**Solution:**
1. Check google-services.json is in correct location
2. Run `flutter clean` and rebuild
3. Make sure package name matches Firebase config

---

## 💰 Cost Breakdown (All Free for Hackathon!)

| Service | Free Tier | Cost |
|---------|-----------|------|
| Google Maps | $200 credit/month | FREE |
| Custom Search | 100 queries/day | FREE |
| UK Police API | Unlimited | FREE |
| Crimeometer | 1000 requests/month | FREE |
| HIBP | Basic checks | FREE |
| Firebase | Generous free tier | FREE |

**Total Cost: $0** 🎉

---

## 🎯 Minimum Required for Demo

If you're short on time, you only need:

1. ✅ Google Maps API Key (15 minutes)
2. ✅ UK Police API (already configured)
3. ✅ Test on device

Everything else is optional!

---

## 📞 Need Help?

### Google Cloud Support
- [Documentation](https://cloud.google.com/docs)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/google-maps)

### Firebase Support
- [Documentation](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev/)

---

## ⚡ Quick Start Commands

```bash
# 1. Get dependencies
flutter pub get

# 2. Clean build
flutter clean

# 3. Run on device
flutter run

# 4. Build APK (for demo)
flutter build apk --release

# 5. Build iOS (Mac only)
flutter build ios --release
```

---

**You're all set! Good luck at the hackathon! 🚀**
