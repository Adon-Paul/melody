# 🔨 MELODY Build Instructions

## 📋 Overview

This document provides comprehensive instructions for building and deploying MELODY v2.1.0 across all supported platforms.

---

## 🛠️ Prerequisites

### **Development Environment**
- **Flutter SDK**: 3.19.0 or higher
- **Dart SDK**: 3.x or higher
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA
- **Git**: For version control

### **Platform-Specific Requirements**

#### **Android**
- **Android SDK**: API level 21+ (Android 5.0)
- **Target SDK**: API level 34 (Android 14)
- **NDK**: Latest version recommended
- **Build Tools**: Latest version

#### **iOS** 
- **Xcode**: 14.0 or higher
- **iOS Deployment Target**: 12.0+
- **CocoaPods**: Latest version
- **macOS**: Required for iOS builds

#### **Windows Desktop**
- **Visual Studio 2022**: With C++ development tools
- **Windows 10 SDK**: Latest version
- **CMake**: 3.15 or higher

#### **Web**
- **Modern Browser**: Chrome, Firefox, Safari, Edge
- **Web Server**: For deployment (nginx, Apache, etc.)

---

## 🚀 Quick Start

### **1. Clone Repository**
```bash
git clone https://github.com/Adon-Paul/melody.git
cd melody
```

### **2. Install Dependencies**
```bash
flutter pub get
```

### **3. Run Development Build**
```bash
# Android/iOS
flutter run

# Web
flutter run -d web

# Windows Desktop
flutter run -d windows
```

---

## 🔧 Environment Setup

### **Firebase Configuration**

#### **Android Setup**
1. **Download Configuration**:
   - Get `google-services.json` from Firebase Console
   - Place in: `android/app/google-services.json`

2. **Verify Placement**:
   ```
   android/
   └── app/
       ├── build.gradle.kts
       └── google-services.json  ← Here
   ```

#### **iOS Setup**
1. **Download Configuration**:
   - Get `GoogleService-Info.plist` from Firebase Console
   - Add to Xcode project via Xcode IDE

2. **Xcode Configuration**:
   - Open `ios/Runner.xcworkspace`
   - Drag `GoogleService-Info.plist` into Runner target
   - Ensure it's added to target membership

#### **Web Setup**
1. **Firebase Config**:
   - Configure in `lib/firebase_options.dart`
   - Update web configuration object

### **Development Environment Variables**
Create `.env` file in project root:
```env
# Development settings
FLUTTER_ENV=development
DEBUG_MODE=true

# Firebase (optional - uses firebase_options.dart)
FIREBASE_PROJECT_ID=your-project-id
```

---

## 📦 Building for Production

### **Android APK**
```bash
# Debug APK
flutter build apk --debug

# Release APK  
flutter build apk --release

# Split APKs by ABI
flutter build apk --split-per-abi --release
```

### **Android App Bundle (Recommended)**
```bash
# Release AAB for Google Play Store
flutter build appbundle --release
```

### **iOS IPA**
```bash
# Release build for App Store
flutter build ios --release

# Archive in Xcode
# 1. Open ios/Runner.xcworkspace
# 2. Product > Archive
# 3. Distribute to App Store Connect
```

### **Windows Executable**
```bash
# Release build for Windows
flutter build windows --release

# Output location: build/windows/x64/runner/Release/
```

### **Web Build**
```bash
# Release build for web deployment
flutter build web --release

# Output location: build/web/
```

---

## 🔍 Build Optimization

### **Performance Optimization**
```bash
# Enable code obfuscation (recommended for release)
flutter build apk --release --obfuscate --split-debug-info=debug-info/

# Tree-shake icons (reduces app size)
flutter build apk --release --tree-shake-icons
```

### **Size Optimization**
```bash
# Analyze bundle size
flutter build apk --analyze-size

# Remove debug symbols
flutter build apk --release --split-debug-info=symbols/
```

---

## 🧪 Testing Builds

### **Unit Tests**
```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Coverage report
flutter test --coverage
```

### **Integration Tests**
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart
```

### **Device Testing**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Install APK for testing
flutter install --debug
```

---

## 📱 Platform-Specific Builds

### **Android Signing Configuration**

#### **Debug Signing** (Automatic)
- Uses debug keystore automatically
- No configuration required

#### **Release Signing** (Required for Store)
1. **Generate Keystore**:
   ```bash
   keytool -genkey -v -keystore melody-release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias melody
   ```

2. **Configure Gradle** (`android/app/build.gradle.kts`):
   ```kotlin
   android {
       signingConfigs {
           release {
               storeFile = file("../melody-release.keystore")
               storePassword = "your-store-password"
               keyAlias = "melody"
               keyPassword = "your-key-password"
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.release
           }
       }
   }
   ```

### **iOS Code Signing**
1. **Development**:
   - Automatic signing in Xcode
   - Development team selection required

2. **Distribution**:
   - App Store Connect configuration
   - Distribution certificate required
   - Provisioning profiles setup

---

## 🚀 Deployment

### **Google Play Store (Android)**
1. **Build AAB**:
   ```bash
   flutter build appbundle --release
   ```

2. **Upload to Play Console**:
   - Create app listing
   - Upload AAB file
   - Configure store listing
   - Submit for review

### **Apple App Store (iOS)**
1. **Archive in Xcode**:
   - Open `ios/Runner.xcworkspace`
   - Product > Archive
   - Validate and upload

2. **App Store Connect**:
   - Configure app metadata
   - Submit for review

### **Web Deployment**
1. **Build for Web**:
   ```bash
   flutter build web --release
   ```

2. **Deploy to Server**:
   ```bash
   # Example: Deploy to Firebase Hosting
   firebase deploy

   # Example: Deploy to GitHub Pages
   # Copy build/web/* to gh-pages branch
   ```

### **Windows Distribution**
1. **Package for Microsoft Store**:
   - Use MSIX packaging
   - Configure Package.appxmanifest

2. **Direct Distribution**:
   - Create installer with NSIS or similar
   - Include Visual C++ Redistributables

---

## ⚡ Performance Considerations

### **Build Performance**
- **Enable Multidex**: For Android apps with many dependencies
- **Use R8**: Enable code shrinking and obfuscation
- **Optimize Images**: Compress assets for smaller app size
- **Tree Shake**: Remove unused code and dependencies

### **Runtime Performance**
- **Profile Mode**: Test performance with `flutter run --profile`
- **Release Mode**: Always test final builds in release mode
- **Device Variety**: Test on different devices and screen sizes

---

## 🔍 Troubleshooting

### **Common Build Issues**

#### **Android**
```bash
# Clean build cache
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..

# Fix Gradle wrapper permissions (Linux/macOS)
chmod +x android/gradlew
```

#### **iOS**
```bash
# Clean iOS build
flutter clean
cd ios && rm -rf Pods && pod install && cd ..

# Reset iOS Simulator
xcrun simctl erase all
```

#### **General**
```bash
# Doctor check
flutter doctor -v

# Update Flutter
flutter upgrade

# Clear pub cache
flutter pub cache repair
```

### **Build Errors**

**Error**: `AAPT: error: resource android:attr/lStar not found`
**Solution**: Update to latest Android SDK and build tools

**Error**: iOS build fails with CocoaPods
**Solution**: 
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

**Error**: Web build fails
**Solution**: Check for web-incompatible packages

---

## 📊 Build Verification

### **Quality Checklist**
- [ ] All tests pass (`flutter test`)
- [ ] No analysis issues (`flutter analyze`)
- [ ] App starts successfully on target platforms
- [ ] Core functionality works (authentication, music playbook)
- [ ] Performance is acceptable (startup time < 3 seconds)
- [ ] No memory leaks in profile mode
- [ ] Build size is reasonable (< 50MB for Android)

### **Release Checklist**
- [ ] Version number updated in `pubspec.yaml`
- [ ] Changelog updated with new features
- [ ] Release notes prepared
- [ ] Screenshots updated if UI changed
- [ ] Store metadata prepared
- [ ] Signing certificates valid
- [ ] Privacy policy updated if needed
- [ ] Terms of service current

---

## 📞 Support

### **Build Issues**
- **GitHub Issues**: [Report build problems](https://github.com/Adon-Paul/melody/issues)
- **Flutter Community**: [Flutter Developer Discord](https://discord.gg/flutter)
- **Documentation**: [Flutter Build Documentation](https://flutter.dev/docs/deployment)

### **Development Questions**
- **GitHub Discussions**: [Development discussions](https://github.com/Adon-Paul/melody/discussions)
- **Stack Overflow**: Tag questions with `flutter` and `melody-app`

---

**🎵 Happy building with MELODY!**

*Made with ❤️ and 🎵 by the MELODY team*
