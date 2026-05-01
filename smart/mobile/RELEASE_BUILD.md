# Production Release Build Guide

This guide provides step-by-step instructions for building and deploying the Smart City mobile app to production (Google Play Store and Apple App Store).

## Prerequisites

- Flutter SDK installed and configured
- Android SDK with Build Tools
- Xcode (for iOS builds, macOS only)
- Valid Google Play Developer account (for Android)
- Valid Apple Developer account (for iOS)

---

## 🤖 Android Release Build

### Step 1: Generate Release Keystore

If you haven't created a keystore yet, generate one:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important:** Store your keystore file and passwords securely. You'll need them for all future app updates.

### Step 2: Configure Signing

1. Copy the example configuration:
   ```bash
   cd android
   cp key.properties.example key.properties
   ```

2. Edit `android/key.properties` with your keystore details:
   ```properties
   storePassword=YOUR_ACTUAL_PASSWORD
   keyPassword=YOUR_ACTUAL_PASSWORD
   keyAlias=upload
   storeFile=C:/Users/YourName/upload-keystore.jks
   ```

### Step 3: Update Version Numbers

Edit `pubspec.yaml` to increment version:
```yaml
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
```

### Step 4: Build Android Release APK

```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

### Step 5: Build Android App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

The AAB will be located at: `build/app/outputs/bundle/release/app-release.aab`

### Step 6: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app or create a new one
3. Navigate to **Production** → **Create new release**
4. Upload the `.aab` file from Step 5
5. Fill in release notes and submit for review

---

## 🍎 iOS Release Build

### Step 1: Configure Xcode Project

1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode, select **Runner** → **Signing & Capabilities**:
   - Select your Team
   - Ensure "Automatically manage signing" is checked
   - Verify Bundle Identifier matches your App ID

### Step 2: Update Version Numbers

In Xcode or edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Same as Android version
```

### Step 3: Build iOS Release

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols
```

The IPA will be located at: `build/ios/ipa/mobile.ipa`

### Step 4: Upload to App Store Connect

Option A - Using Xcode:
1. Open Xcode → **Window** → **Organizer**
2. Select the archive and click **Distribute App**
3. Choose **App Store Connect** → **Upload**
4. Follow the wizard to complete upload

Option B - Using Application Loader or Transporter:
1. Download [Transporter](https://apps.apple.com/app/transporter/id1450874784)
2. Open the `.ipa` file
3. Click **Deliver** to upload to App Store Connect

### Step 5: Submit for Review

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app → **App Store** tab
3. Create a new version
4. Fill in app information, screenshots, and metadata
5. Submit for review

---

## 🔧 Build Optimization Flags

### Recommended Release Flags

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --target-platform android-arm,android-arm64,android-x64
```

**Flags explained:**
- `--release`: Builds in release mode (optimized, no debugging)
- `--obfuscate`: Obfuscates Dart code to protect intellectual property
- `--split-debug-info`: Extracts debug symbols (required for obfuscation)
- `--target-platform`: Specifies CPU architectures (smaller APK per arch)

### Split APKs by Architecture (Advanced)

```bash
flutter build apk --split-per-abi --release --obfuscate --split-debug-info=build/symbols
```

This creates separate APKs for each architecture, reducing download size for users.

---

## 🧪 Pre-Release Testing Checklist

Before uploading to stores, verify:

- [ ] App runs smoothly in release mode: `flutter run --release`
- [ ] No debug banners or indicators visible
- [ ] All API endpoints point to production server
- [ ] App permissions are correctly configured
- [ ] App icons and splash screens are production-ready
- [ ] Version numbers match in `pubspec.yaml` and platform configs
- [ ] Test on real devices (Android and iOS)
- [ ] Verify login, registration, and all major features
- [ ] Check network error handling
- [ ] Test location services and image uploads
- [ ] Verify push notifications (if implemented)

---

## 🌐 Environment Configuration

### Production API URL

The app uses compile-time environment variables. Build with production API:

```bash
flutter build apk --release --dart-define=API_URL=https://your-production-api.com/api
```

Or update `lib/main.dart` to change the default URL:
```dart
final api = ApiService(baseUrl: const String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://your-production-api.com/api', // Change this
));
```

---

## 🔐 Security Best Practices

1. **Never commit sensitive files:**
   - `android/key.properties` (already in .gitignore)
   - `*.keystore` or `*.jks` files
   - Any files containing API keys or secrets

2. **Store keystore securely:**
   - Keep multiple backups in secure locations
   - Use a password manager for credentials
   - Document recovery procedures

3. **API Security:**
   - Use HTTPS for all API calls
   - Implement certificate pinning for production
   - Store sensitive tokens securely using flutter_secure_storage

---

## 📊 Monitoring & Analytics

### Crash Reporting

Consider integrating crash reporting:
- Firebase Crashlytics
- Sentry
- Bugsnag

### Analytics

Track user behavior with:
- Firebase Analytics
- Google Analytics for Firebase
- Mixpanel

---

## 🚀 CI/CD Automation (Optional)

### GitHub Actions Example

Create `.github/workflows/release.yml`:
```yaml
name: Release Build
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.18.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📝 Release Checklist

### Before Building:
- [ ] Update version number in `pubspec.yaml`
- [ ] Update CHANGELOG.md with release notes
- [ ] Test all features thoroughly
- [ ] Verify API endpoints point to production
- [ ] Update app store descriptions and screenshots

### After Building:
- [ ] Test the release APK/IPA on real devices
- [ ] Verify app permissions work correctly
- [ ] Check app size is acceptable
- [ ] Ensure obfuscation doesn't break functionality
- [ ] Upload symbols to crash reporting service

### After Submission:
- [ ] Monitor store review status
- [ ] Prepare rollback plan if issues arise
- [ ] Plan staged rollout (start with small percentage)
- [ ] Monitor crash reports and user feedback
- [ ] Prepare hotfix process if critical bugs found

---

## 🆘 Troubleshooting

### Common Issues

**"Keystore not found" error:**
- Verify `storeFile` path in `key.properties`
- Ensure file uses forward slashes or double backslashes on Windows

**"Flutter SDK not found" in CI:**
- Add Flutter to PATH or use flutter-action in CI

**iOS code signing errors:**
- Verify Team selection in Xcode
- Check provisioning profiles in Apple Developer portal
- Ensure Bundle ID matches registered App ID

**APK too large:**
- Use `--split-per-abi` to create architecture-specific builds
- Remove unused dependencies
- Optimize images and assets

---

## 📫 Support

For questions or issues:
- Check [Flutter documentation](https://docs.flutter.dev/deployment)
- Review [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- Visit [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)

---

**Last Updated:** $(date + "%Y-%m-%d")
**Flutter Version:** 3.18.0+
**Minimum Android SDK:** 21 (Android 5.0)
**Minimum iOS Version:** 11.0
