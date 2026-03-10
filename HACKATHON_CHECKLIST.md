# 🏆 Hackathon Day Checklist

## 📅 TONIGHT (Before Hackathon)

### Setup & Configuration (2 hours)
- [ ] **Install all dependencies**
  ```bash
  cd safeguard_app
  flutter pub get
  flutter doctor
  ```

- [ ] **Get Google Maps API Key** (15 min)
  - Go to console.cloud.google.com
  - Create project "SafeGuard-Hackathon"
  - Enable: Maps SDK, Directions API, Places API
  - Create API key
  - Add to `lib/config/api_keys.dart`
  - Add to `android/app/src/main/AndroidManifest.xml`

- [ ] **Get Google Custom Search** (10 min)
  - Go to programmablesearchengine.google.com
  - Create search engine
  - Get Engine ID
  - Add to `lib/config/api_keys.dart`

- [ ] **Test on Real Device** (30 min)
  - Connect phone via USB
  - Enable Developer Mode
  - Run: `flutter run`
  - Test all 4 features work
  - Grant all permissions

- [ ] **Prepare Demo Data** (15 min)
  - Add 2-3 emergency contacts
  - Test voice detection with "help me"
  - Test location sharing
  - Test privacy scanner

- [ ] **Read Documentation**
  - [ ] README.md
  - [ ] API_SETUP_GUIDE.md
  - [ ] This checklist

### Optional (If Time Permits)
- [ ] Set up Firebase (30 min)
- [ ] Customize app colors/theme
- [ ] Add app icon
- [ ] Test on both Android and iOS

---

## 🚀 HACKATHON DAY

### Hour 0-1: Problem Understanding & Planning
- [ ] Read problem statement 3 times
- [ ] Identify which features to prioritize
- [ ] Sketch UI flow on paper
- [ ] Plan demo script

### Hour 1-3: Feature 1 - Safe Routes
- [ ] Implement Google Maps integration
- [ ] Add route fetching from Directions API
- [ ] Integrate UK Police crime data
- [ ] Calculate safety scores
- [ ] Display routes with scores
- [ ] Add crime heatmap overlay
- [ ] **TEST THOROUGHLY**

### Hour 3-5: Feature 2 - Emergency SOS
- [ ] Implement panic button animation
- [ ] Add voice detection service
- [ ] Integrate emergency contacts
- [ ] Add SMS sending functionality
- [ ] Implement audio recording
- [ ] Add shake detection
- [ ] **TEST THOROUGHLY**

### Hour 5-7: Feature 3 - Location Sharing
- [ ] Implement real-time location tracking
- [ ] Add Firebase Realtime Database
- [ ] Create shareable links
- [ ] Add duration selector
- [ ] Implement auto-expiry
- [ ] **TEST THOROUGHLY**

### Hour 7-8: Feature 4 - Privacy Scanner
- [ ] Integrate Have I Been Pwned API
- [ ] Add Google Custom Search
- [ ] Calculate privacy score
- [ ] Display breach results
- [ ] Add removal instructions
- [ ] **TEST THOROUGHLY**

### Hour 8-9: Polish & Bug Fixes
- [ ] Fix any crashes
- [ ] Improve UI animations
- [ ] Add loading states
- [ ] Add error handling
- [ ] Test complete user flow 5 times
- [ ] Fix critical bugs only

### Hour 9-10: Demo Preparation
- [ ] Practice demo script 3 times
- [ ] Prepare backup APK
- [ ] Take screenshots
- [ ] Write 1-page description
- [ ] Charge phone to 100%
- [ ] Test in airplane mode (offline features)

---

## 🎯 Demo Script (3 Minutes)

### Opening (30 seconds)
"Hi, I'm [Name]. Every day, millions of people feel unsafe walking alone. Current solutions are fragmented - one app for navigation, another for emergencies, nothing for digital privacy. We need an all-in-one guardian."

### Problem (30 seconds)
"Meet Sarah. She's walking home at 10 PM. She doesn't know which route is safest. If something happens, she needs to manually call for help. And her personal data might already be leaked online."

### Solution (30 seconds)
"This is SafeGuard - Sarah's AI-powered safety companion. Let me show you how it works."

### Feature Demo (90 seconds)

**1. Safe Routes (30s)**
- Open app → Navigate to Routes tab
- Enter destination: "Home"
- Show 3 routes with safety scores
- "See? Route 1 is 85% safe with good lighting and low crime. Route 2 is only 60% safe."
- Tap on route to see crime heatmap
- "Real-time crime data from police APIs"

**2. Emergency SOS (25s)**
- Navigate to SOS tab
- "If Sarah feels threatened, she can say 'help me'"
- Say "help me" → Voice detection triggers
- Show 5-second countdown
- "Instantly sends SMS with location to emergency contacts"
- Show emergency contacts list
- "Also starts recording audio as evidence"

**3. Location Sharing (20s)**
- Navigate to Track tab
- "Sarah can share her live location"
- Click "Start Sharing" → Select 60 minutes
- Show shareable link
- "Her friends see her location in real-time. Auto-expires for privacy."

**4. Privacy Scanner (15s)**
- Navigate to Privacy tab
- Enter name and email
- Click "Start Scan"
- Show scanning animation
- "Checks if her data was leaked in breaches"
- Show results with privacy score
- "Provides removal instructions"

### Impact (30 seconds)
"SafeGuard combines physical and digital safety in one app. It uses AI for voice detection, real crime data for route optimization, and privacy scanning to protect your identity. This isn't just an app - it's peace of mind for students, travelers, and anyone who deserves to feel safe."

### Closing (10 seconds)
"Thank you! Questions?"

---

## ✅ Pre-Demo Checklist (10 minutes before)

- [ ] Phone charged to 100%
- [ ] All permissions granted
- [ ] Test internet connection
- [ ] Close all other apps
- [ ] Set phone to Do Not Disturb
- [ ] Increase screen brightness
- [ ] Test complete flow once more
- [ ] Have backup APK ready
- [ ] Prepare for questions

---

## 🎤 Common Judge Questions & Answers

**Q: How accurate is the safety scoring?**
A: We use real crime data from police APIs, street lighting density from Google Places, time of day, and user reports. The algorithm weighs these factors to calculate a 0-100 safety score.

**Q: Does voice detection work in noisy environments?**
A: We use the device's native speech-to-text API which has noise cancellation. We also require keyword confirmation within 5 seconds to reduce false positives.

**Q: What about privacy concerns with location tracking?**
A: Location sharing is opt-in, has auto-expiry, and only people with the unique link can see your location. We don't store location history.

**Q: How do you handle false alarms?**
A: Every emergency trigger has a 5-second countdown that can be cancelled. This prevents accidental activations.

**Q: What's your business model?**
A: Freemium - basic features free, premium features like extended location sharing, priority emergency response, and advanced privacy monitoring for $4.99/month.

**Q: How is this different from existing apps?**
A: We're the only app that combines physical safety (routes, SOS) with digital safety (privacy scanning) in one platform. Plus, we use AI for voice detection.

**Q: What about battery drain?**
A: Voice detection only runs when "Walking Mode" is enabled. Location updates every 10 seconds. We estimate 5-10% battery per hour of active use.

**Q: Can this scale globally?**
A: Yes! We use UK Police API (free, global), Crimeometer for USA, and can integrate any country's crime data API. The architecture is designed for multi-region support.

---

## 🚨 Emergency Troubleshooting

### App Won't Build
```bash
flutter clean
flutter pub get
flutter run
```

### Google Maps Not Showing
1. Check API key in api_keys.dart
2. Check API key in AndroidManifest.xml
3. Wait 5 minutes for API activation
4. Enable Maps SDK in Google Cloud Console

### Voice Detection Not Working
1. Grant microphone permission
2. Test on real device (not emulator)
3. Speak clearly: "help me"
4. Check VoiceDetectionService is initialized

### Location Not Working
1. Grant location permission
2. Enable location services on device
3. Test outdoors (GPS works better)

### Firebase Errors
1. Check google-services.json location
2. Run `flutter clean`
3. Rebuild app

---

## 📊 Judging Criteria Alignment

| Criteria | How We Excel | Score Target |
|----------|--------------|--------------|
| Innovation | AI voice detection + multi-factor safety | 9/10 |
| Technical | Multiple APIs, real-time data, ML | 9/10 |
| Design | Beautiful UI, smooth animations | 8/10 |
| Impact | Solves real problem, social good | 10/10 |
| Completeness | 4 working features, polished | 9/10 |

**Target Total: 45/50 (90%)**

---

## 🎁 Bonus Features (If Extra Time)

- [ ] Add app icon and splash screen
- [ ] Implement dark/light theme toggle
- [ ] Add onboarding tutorial
- [ ] Implement user authentication
- [ ] Add community safety reports
- [ ] Create promotional video
- [ ] Design pitch deck

---

## 💪 Motivation

Remember:
- You have AI tools (me!) - use them aggressively
- Don't perfectionism - working > beautiful
- Test frequently on real device
- Take 5-min breaks every 90 minutes
- Stay hydrated and eat well
- You've got this! 🚀

---

## 📞 Quick Commands Reference

```bash
# Run app
flutter run

# Hot reload (while running)
Press 'r' in terminal

# Hot restart
Press 'R' in terminal

# Build APK
flutter build apk --release

# Check for errors
flutter analyze

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Check device connection
flutter devices
```

---

**YOU'RE READY TO WIN! GO CRUSH IT! 🏆**
