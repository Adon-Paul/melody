# 🎵 MELODY - Music App with Advanced Transitions

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Ready-orange.svg)](https://firebase.google.com/)
 Phase 2: Core Features ✅
- [x] Complete music player UI with full-screen experience
- [x] Advanced playlist management with auto-progression
- [x] Background audio playbook with notification controls
- [x] Favorites system with persistent storage
- [x] Enhanced mini player with previous/next controls
- [x] Shuffle and repeat modes with visual feedback
- [x] Android native notification integration
- [x] Glass morphism UI components
- [x] Advanced transition system enhancements

### Phase 2.1: Advanced Features ✅ (v2.1.0)
- [x] Professional lyrics system with RGB effects control
- [x] Interactive queue management with drag-and-drop reordering
- [x] Smart shuffle mode with predetermined order display
- [x] Performance optimization with intelligent caching system
- [x] Enhanced user experience with improved spacing and layout
- [x] Real-time progress indicators and cache status display
- [x] Settings service for granular feature control

### Phase 3: Advanced Features 📋
- [ ] Search and filtering system
- [x] Settings and preferences management (partially complete)
- [ ] Offline mode support
- [ ] Social features and sharing
- [ ] Cloud music sync
- [ ] Equalizer and audio effects
- [x] Lyrics integration (complete)
- [ ] Recommendation engine20Web%20%7C%20Desktop-lightgrey.svg)](https://flutter.dev/multi-platform)

**MELODY** is a modern music streaming app built with Flutter, featuring stunning advanced transitions, ultra-dark UI design, and comprehensive music management capabilities.

## 🌟 Key Features

### 🎬 **Advanced 3D Transitions**
- **3D Flip Transitions**: Realistic card-flip effects with perspective
- **Morph Animations**: Smooth morphing from mini player to full screen
- **Liquid Morphing**: Organic liquid-like page transitions
- **Cube Rotations**: 3D cube transitions between sections
- **Fold Transitions**: Paper-folding effects
- **Scale Rotate**: Combined scaling and rotation with elastic easing
- **Hardware Accelerated**: 60fps performance with GPU optimization

### 🎨 **Modern UI/UX**
- **Ultra-Dark Theme**: Pure black background with emerald green accents
- **Glass Morphism**: Frosted glass effects and modern transparency
- **Animated Backgrounds**: Floating particles and dynamic gradients  
- **Material 3 Design**: Latest Flutter design system implementation
- **Custom Animations**: Smooth micro-interactions throughout the app

### 🔐 **Authentication System**
- **Firebase Integration**: Secure user authentication
- **Multiple Sign-in Options**: Email/password and Google OAuth
- **Password Recovery**: Built-in forgot password functionality
- **Guest Mode**: Continue without account creation
- **Auto-login**: Persistent sessions with secure storage

### 🎵 **Advanced Music Features**
- **Intelligent Playlist Management**: Auto-progression with shuffle and repeat modes
- **Background Audio Playback**: Seamless music continuation with proper audio session handling
- **Android Notification Controls**: Native play/pause/next/previous buttons in notification bar
- **Enhanced Mini Player**: Previous/next controls with long-press settings panel
- **Comprehensive Favorites System**: Heart songs with persistent local storage
- **Full-Screen Music Player**: Professional-grade controls with advanced UI
- **Local Music Scanning**: Automatic detection of device music files
- **Multiple Format Support**: MP3, WAV, M4A, AAC, FLAC, OGG
- **Smart Permissions**: Adaptive storage access for different Android versions
- **Queue Management**: Dynamic playlist creation and management
- **Glass Morphism UI**: Modern blur effects and smooth transitions

## 🆕 Latest Features (v2.2.0)

### 🎵 **Enhanced Lyrics System with Bass-Synchronized Beat Visualization**
Our newest update revolutionizes the music experience with advanced audio-visual integration:

**🎛️ Bass-Synchronized Beat Visualization**
- Revolutionary bass-only beat detection with 4 specialized flicker patterns
- Multi-layer glow effects for cover art and instrumentals (triple-layer system)
- Genre-specific BPM estimation (40-85 BPM) with 750ms precision timing
- Dynamic color rotation every 12 bass hits for continuous visual variety
- Performance-optimized 60fps animations with RepaintBoundary optimization

**🎨 Professional Lyrics Customization**
- 4 Premium Google Fonts: MedievalSharp, Orbitron, Dancing Script, Cinzel
- Interactive font size adjustment (16-32px) with real-time preview
- Performance toggle to completely disable lyrics for maximum efficiency
- Comprehensive options menu combining all lyrics controls
- LRCLIB.net integration with proper provider attribution

**🎪 Enhanced User Interface**
- Compact player layout with optimized spacing throughout
- Extended lyrics box height (140px → 180px) for better readability
- Minimalist instrumentals display with music symbol only
- Consolidated controls with unified options button
- Real-time settings updates with Consumer pattern implementation

### 🎵 **Advanced Music Management & Performance (v2.1.0)**
Previous major update brought professional-grade music functionality:

**🎛️ Lyrics System with RGB Effects Control**
- Professional lyrics display with synchronized highlighting
- Customizable RGB breathing effects (Beat sync, RGB effects, or minimal display)
- Granular control over visual effects through settings
- Smooth transitions between lyrics modes

**🎪 Advanced Queue Management**
- Interactive queue modal with upcoming songs preview
- Drag-and-drop reordering for complete playlist control
- Smart shuffle mode with predetermined order display
- Visual indicators for current and upcoming tracks
- Tap-to-play functionality for instant song switching

**⚡ Performance Optimizations**
- Intelligent device music caching system (24-hour validity)
- Batch processing for large music libraries
- Real-time progress indicators during music scanning
- Memory optimization for smooth scrolling
- Instant cache loading with refresh functionality

**🎨 Enhanced User Experience**
- Improved spacing and layout optimization
- Cache status indicators for transparency
- Progress tracking during operations
- Responsive UI across all screen sizes
- Glass morphism effects throughout the interface

### 🎵 **Complete Music Playback System (v2.0)**
Our previous major update brought professional-grade music functionality:

**Automatic Playlist Management**: Songs automatically progress to the next track when finished, creating a seamless listening experience with intelligent queue management.

**Background Audio Support**: Continue enjoying your music when the app is minimized or when your screen is off, with proper audio session handling for uninterrupted playback.

**Native Android Notifications**: Full media controls directly in your notification bar - play, pause, skip to next/previous track without opening the app.

**Enhanced Mini Player**: New previous/next track buttons and a long-press settings panel for quick access to shuffle and repeat modes.

**Comprehensive Favorites**: Heart your favorite songs with persistent local storage, creating your personal collection that survives app restarts.

**Professional Full-Screen Player**: Immersive music experience with advanced controls, album artwork, and smooth animations.

**Glass Morphism UI**: Modern blur effects and translucent elements throughout the interface for a premium visual experience.

## 📱 Screenshots

| Splash Screen | Login Screen | Transition Demo |
|---------------|--------------|-----------------|
| ![Splash](docs/splash.png) | ![Login](docs/login.png) | ![Demo](docs/demo.png) |

*Note: Screenshots coming soon - app is currently in development*

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x or higher
- Dart 3.x or higher
- Android Studio / VS Code
- Firebase project (for authentication)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/nobodyuwouldknow/melody.git
   cd melody
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** (Optional - for authentication)
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication in Firebase Console

4. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Storage permissions configured for music access

#### iOS
- Minimum iOS: 12.0
- Camera and microphone permissions for media access
- Background audio capabilities

#### Desktop (Windows/macOS/Linux)
- Music directory scanning
- Native file system access
- High-DPI display support

## 🎬 Transition System

### Available Transitions

```dart
// Enhanced slide transitions
PageTransitions.slideRight(page)    // Morphing slide with parallax
PageTransitions.slideLeft(page)     // Slide with rotation effect
PageTransitions.slideUp(page)       // Elastic bounce slide

// Creative 3D effects  
PageTransitions.flip(page)          // 3D flip transition
PageTransitions.circleMorph(page)   // Expanding circle reveal
PageTransitions.liquidMorph(page)   // Flowing wave effect
PageTransitions.particleDissolve(page) // Particle animation
PageTransitions.glitch(page)        // Digital glitch effect
```

### Usage Examples

```dart
// Navigate with creative transitions
Navigator.push(
  context,
  PageTransitions.circleMorph(const HomePage()),
);

// Context-aware transitions
Navigator.push(
  context,
  PageTransitions.liquidMorph(const PlayerScreen()),
);
```

## 🏗️ Architecture

### Project Structure
```
lib/
├── core/                    # Core functionality
│   ├── services/           # Business logic services
│   │   ├── auth_service.dart
│   │   ├── music_service.dart      # Enhanced with queue management & shuffle
│   │   ├── notification_service.dart # Android notification controls
│   │   ├── favorites_service.dart   # Favorites management
│   │   ├── settings_service.dart    # App settings & RGB effects control
│   │   └── google_sign_in_service.dart
│   ├── theme/              # UI theme and styling
│   │   └── app_theme.dart
│   ├── widgets/            # Reusable UI components
│   │   ├── modern_button.dart
│   │   ├── modern_text_field.dart
│   │   ├── modern_toast.dart
│   │   ├── mini_player.dart         # Enhanced mini player with queue
│   │   ├── glass_notification.dart  # Glass morphism notifications
│   │   └── animated_background.dart
│   └── transitions/        # Page transition system
│       ├── page_transitions.dart
│       └── advanced_transitions.dart # Enhanced 3D transitions
├── ui/                     # Screen implementations
│   ├── auth/              # Authentication screens
│   ├── home/              # Home screen
│   ├── favorites_page.dart # Comprehensive favorites management
│   ├── full_music_player_page.dart # Full-screen music player
│   └── splash/            # Splash screen
└── main.dart              # App entry point
```

### Key Technologies
- **Flutter 3.x**: Cross-platform framework
- **Provider**: State management
- **Firebase**: Authentication and backend
- **just_audio**: Advanced audio playback with background support
- **flutter_animate**: Advanced animations
- **shared_preferences**: Local data persistence
- **permission_handler**: Smart Android permissions
- **google_fonts**: Typography system
- **AndroidX Media**: Native notification controls

## 🎨 Design System

### Color Palette
- **Primary**: Emerald Green (`#00C896`)
- **Accent**: Purple (`#6C63FF`)
- **Background**: Pure Black (`#000000`)
- **Surface**: Dark Gray (`#0F0F0F`)
- **Glass**: Semi-transparent overlays

### Typography
- **Font Family**: Inter (Google Fonts)
- **Weights**: 300-800 for hierarchical text
- **Responsive**: Scales across device sizes

### Animations
- **Duration**: 200ms (fast), 400ms (medium), 600ms (slow)
- **Curves**: easeInOutCubic, elasticOut, easeOutBack
- **Performance**: 60fps target with GPU acceleration

## 🔧 Configuration

### Theme Customization
```dart
// Modify app_theme.dart
static const Color primaryColor = Color(0xFF00C896);
static const Color backgroundColor = Color(0xFF000000);
```

### Transition Customization
```dart
// Add custom transitions in page_transitions.dart
class CustomRoute extends PageRouteBuilder {
  // Your custom transition implementation
}
```

## 📦 Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter: ^3.19.0
  provider: ^6.1.1
  firebase_auth: ^4.17.4
  google_sign_in: ^6.2.0
  just_audio: ^0.9.36
  flutter_animate: ^4.5.0
  google_fonts: ^6.1.0
  shared_preferences: ^2.2.2
  permission_handler: ^11.2.0
```

### Development Dependencies
```yaml
dev_dependencies:
  flutter_test: ^3.19.0
  flutter_lints: ^3.0.1
```

## 🚧 Roadmap

### Phase 1: Foundation ✅
- [x] Project setup and architecture
- [x] Creative transition system (8 effects)
- [x] Ultra-dark theme implementation
- [x] Authentication system
- [x] Basic music service

### Phase 2: Core Features ✅
- [x] Complete music player UI with full-screen experience
- [x] Advanced playlist management with auto-progression
- [x] Background audio playback with notification controls
- [x] Favorites system with persistent storage
- [x] Enhanced mini player with previous/next controls
- [x] Shuffle and repeat modes with visual feedback
- [x] Android native notification integration
- [x] Glass morphism UI components
- [x] Advanced transition system enhancements

### Phase 3: Advanced Features 📋
- [ ] Search and filtering system
- [ ] Settings and preferences management
- [ ] Offline mode support
- [ ] Social features and sharing
- [ ] Cloud music sync
- [ ] Equalizer and audio effects
- [ ] Lyrics integration
- [ ] Recommendation engine

### Phase 4: Platform Expansion 📋
- [ ] Apple Music integration
- [ ] Spotify API integration
- [ ] Web app optimization
- [ ] Desktop app enhancements

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow Flutter/Dart style guidelines
- Add tests for new features
- Update documentation as needed
- Ensure 60fps performance for animations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **Material Design**: For design system inspiration
- **Open Source Community**: For incredible packages and tools
- **Music Artists**: For inspiring this creative project

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/nobodyuwouldknow/melody/issues)
- **Discussions**: [GitHub Discussions](https://github.com/nobodyuwouldknow/melody/discussions)
- **Email**: melody.app.support@gmail.com

---

**Made with ❤️ and 🎵 by the MELODY team**

*Transform your music experience with smooth transitions and modern design*
