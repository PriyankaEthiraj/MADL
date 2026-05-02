# Production Configuration Checklist

This file tracks all production-ready configurations applied to the Smart City mobile app.

## ✅ Completed Configurations

### 1. Debug Mode Removal
- [x] **Debug banner disabled** in `lib/main.dart`
  - `debugShowCheckedModeBanner: false` in MaterialApp
  - Status bar configured for production (transparent, dark icons)

### 2. Android Release Configuration
- [x] **Release signing configured** in `android/app/build.gradle.kts`
  - Keystore properties loading from `key.properties` file
  - Separate `signingConfigs` for release builds
  - Falls back to debug signing if `key.properties` not found
  
- [x] **Code obfuscation enabled**
  - `isMinifyEnabled = true` in release buildType
  - `isShrinkResources = true` to remove unused resources
  - ProGuard rules applied from `proguard-rules.pro`
  
- [x] **ProGuard rules created** at `android/app/proguard-rules.pro`
  - Flutter framework preservation rules
  - Gson serialization support
  - HTTP/networking libraries (OkHttp, Okio)
  - Image picker and geolocator plugins
  - Provider state management
  
- [x] **Keystore template created** at `android/key.properties.example`
  - Contains example structure for signing configuration
  - Instructions for generating keystore
  - Security notes to prevent accidental commits

### 3. iOS Configuration
- [x] **Info.plist reviewed** for production settings
  - Bundle identifier: `com.example.mobile`
  - Display name: `Mobile`
  - Supported orientations configured
  - No debug-specific entries found

### 4. Security
- [x] **Sensitive files protected** via `.gitignore`
  - `key.properties` excluded (in `android/.gitignore`)
  - `*.keystore` and `*.jks` excluded
  - Ensures no accidental commit of signing credentials

### 5. Documentation
- [x] **Release build guide created** at `RELEASE_BUILD.md`
  - Android release build instructions (APK and AAB)
  - iOS release build instructions (IPA)
  - Keystore generation and configuration
  - App store submission procedures
  - Build optimization flags
  - Pre-release testing checklist
  - Environment configuration
  - Security best practices
  - Troubleshooting guide
  
- [x] **Production checklist created** (this file)
  - Tracks all production configurations
  - Provides quick reference for deployment readiness

---

## 🔄 Pending Actions

### Developer Actions Required

1. **Generate Release Keystore**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   - Store keystore file securely
   - Document passwords in secure location (password manager)

2. **Create `android/key.properties` file**
   - Copy from `android/key.properties.example`
   - Fill in actual keystore credentials
   - Verify file is not committed to version control

3. **Configure App Identifiers**
   - Update `applicationId` in `android/app/build.gradle.kts` (currently: `com.example.mobile`)
   - Update Bundle Identifier in Xcode (iOS)
   - Register identifiers in Google Play Console and App Store Connect

4. **Update Production API URL**
   - Set environment variable: `--dart-define=API_URL=https://your-production-api.com/api`
   - Or update default in `lib/main.dart` line 24-26

5. **Prepare App Store Assets**
   - App icon (1024x1024 for iOS, various sizes for Android)
   - Screenshots for all required device sizes
   - Feature graphic for Google Play
   - Privacy policy URL
   - App description and release notes

6. **Version Management**
   - Update version in `pubspec.yaml` before each release
   - Follow semantic versioning: `major.minor.patch+buildNumber`
   - Document changes in CHANGELOG.md

---

## 🎯 Build Commands

### Android Release Build

**App Bundle (Recommended for Play Store):**
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

**APK (For direct distribution):**
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

**With Production API:**
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define=API_URL=https://api.yourserver.com/api
```

### iOS Release Build

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols
```

---

## 🧪 Pre-Deployment Testing

Run these tests before each release:

```bash
# Run automated tests
flutter test

# Analyze code for issues
flutter analyze

# Check for outdated dependencies
flutter pub outdated

# Test release build on device
flutter run --release

# Build and inspect APK size
flutter build apk --release --analyze-size
```

---

## 📋 Store Submission Checklist

### Google Play Store
- [ ] App Bundle built and signed
- [ ] Version code incremented
- [ ] Release notes prepared (per language)
- [ ] Screenshots updated (if UI changed)
- [ ] Privacy policy link provided
- [ ] App permissions reviewed and justified
- [ ] Target API level meets Google Play requirements
- [ ] 64-bit support included

### Apple App Store
- [ ] IPA built and signed
- [ ] Build number incremented
- [ ] Release notes prepared
- [ ] Screenshots updated (all required sizes)
- [ ] Privacy policy link provided
- [ ] App permissions usage descriptions in Info.plist
- [ ] Minimum iOS version specified
- [ ] Testflight testing completed

---

## 🔐 Security Verification

- [x] Debug banner removed
- [x] Code obfuscation enabled
- [x] Keystore files excluded from version control
- [ ] HTTPS enforced for all API calls
- [ ] SSL certificate pinning implemented (recommended)
- [ ] Sensitive data stored securely (flutter_secure_storage)
- [ ] API keys not hardcoded in source
- [ ] Authentication tokens handled securely

---

## 📊 Production Monitoring (Recommended)

Consider implementing:

1. **Crash Reporting**
   - Firebase Crashlytics
   - Sentry
   - Symbolicate crashes using `--split-debug-info` symbols

2. **Analytics**
   - Firebase Analytics
   - Google Analytics
   - Track user flows and feature usage

3. **Performance Monitoring**
   - Firebase Performance Monitoring
   - Monitor app startup time
   - Track network request latency

4. **Remote Configuration**
   - Firebase Remote Config
   - Feature flags for gradual rollouts
   - A/B testing capabilities

---

## 📝 Notes

- **Material Design 3** theme is production-ready
- All deprecated APIs have been updated
- Package dependencies are locked and verified
- The app currently uses `http://localhost:4000/api` as default API - **must be changed for production**

---

## 🚀 Deployment Status

| Platform | Status | Last Build | Version |
|----------|--------|------------|---------|
| Android  | Ready for build | - | - |
| iOS      | Ready for build | - | - |

Update this table after each successful deployment.

---

**Configuration Date:** $(date +"%Y-%m-%d")
**Configured By:** GitHub Copilot AI Assistant
**Flutter Version:** 3.18.0+
