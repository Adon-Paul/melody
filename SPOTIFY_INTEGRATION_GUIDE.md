# 🎵 Spotify API Integration Guide for Melody App

## 🔑 **Redirect URIs for Spotify App Registration**

Based on your app package name `com.example.melody`, here are the redirect URIs you should add to your Spotify App Dashboard:

### **Android**
```
com.example.melody://spotify-auth
```

### **iOS** 
```
com.example.melody://spotify-auth
```

### **Web/Desktop** (for testing)
```
http://localhost:8080/callback
```

### **Custom Deep Link** (recommended)
```
melody://auth/spotify/callback
```

## 📱 **Spotify Developer Dashboard Setup**

1. **Go to**: [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. **Create App** or edit existing app
3. **Add Redirect URIs**:
   - `com.example.melody://spotify-auth`
   - `melody://auth/spotify/callback`
   - `http://localhost:8080/callback` (for testing)

4. **App Settings**:
   - **App Name**: `Melody Music Player`
   - **App Description**: `Flutter music player with Spotify integration`
   - **Website**: Your app website (optional)

## 🛠️ **Required Dependencies**

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Spotify API
  spotify: ^0.13.0
  # OR use the official SDK
  spotify_sdk: ^3.0.0
  
  # OAuth/Authentication
  url_launcher: ^6.1.14
  uni_links: ^0.5.1
  
  # HTTP requests
  http: ^1.1.0
  
  # Secure storage for tokens
  flutter_secure_storage: ^9.0.0
```

## 📂 **File Structure for Spotify Integration**

```
lib/
├── core/
│   └── services/
│       ├── spotify_service.dart      # Main Spotify API service
│       ├── spotify_auth_service.dart # Authentication handling
│       └── spotify_player_service.dart # Playback control
├── models/
│   ├── spotify_track.dart           # Spotify track model
│   ├── spotify_playlist.dart        # Spotify playlist model
│   └── spotify_user.dart            # Spotify user model
└── ui/
    ├── spotify_login_page.dart      # Login interface
    ├── spotify_playlists_page.dart  # User playlists
    └── spotify_search_page.dart     # Search Spotify tracks
```

## 🔧 **Android Configuration**

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Add inside <activity> tag for MainActivity -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.example.melody" />
</intent-filter>

<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="melody" />
</intent-filter>
```

## 🍎 **iOS Configuration**

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>Spotify Auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.example.melody</string>
            <string>melody</string>
        </array>
    </dict>
</array>
```

## 💾 **Environment Configuration**

Create `lib/config/spotify_config.dart`:

```dart
class SpotifyConfig {
  static const String clientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const String clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
  
  // Redirect URIs
  static const String redirectUri = 'com.example.melody://spotify-auth';
  static const String customRedirectUri = 'melody://auth/spotify/callback';
  
  // Scopes needed for your app
  static const List<String> scopes = [
    'user-read-private',
    'user-read-email',
    'user-library-read',
    'user-library-modify',
    'playlist-read-private',
    'playlist-read-collaborative',
    'playlist-modify-public',
    'playlist-modify-private',
    'user-read-playback-state',
    'user-modify-playback-state',
    'user-read-currently-playing',
    'streaming',
  ];
}
```

## 🔐 **Authentication Flow**

```dart
// Basic Spotify authentication service
class SpotifyAuthService {
  static const String _authUrl = 'https://accounts.spotify.com/authorize';
  
  Future<String?> authenticate() async {
    final Uri authUri = Uri.parse('$_authUrl').replace(queryParameters: {
      'client_id': SpotifyConfig.clientId,
      'response_type': 'code',
      'redirect_uri': SpotifyConfig.redirectUri,
      'scope': SpotifyConfig.scopes.join(' '),
      'show_dialog': 'true',
    });
    
    if (await canLaunchUrl(authUri)) {
      await launchUrl(authUri, mode: LaunchMode.externalApplication);
      // Handle the callback with uni_links
      return await _handleAuthCallback();
    }
    return null;
  }
  
  Future<String?> _handleAuthCallback() async {
    // Implementation for handling the auth callback
    // Return the authorization code
  }
}
```

## 🎶 **Integration with Your Music Service**

You can extend your existing `MusicService` to include Spotify:

```dart
// Add to your existing MusicService
class MusicService extends ChangeNotifier {
  // ... existing code ...
  
  late SpotifyService _spotifyService;
  bool _isSpotifyConnected = false;
  
  Future<void> connectSpotify() async {
    try {
      await _spotifyService.authenticate();
      _isSpotifyConnected = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to connect to Spotify: $e');
    }
  }
  
  Future<List<Song>> searchSpotifyTracks(String query) async {
    if (!_isSpotifyConnected) return [];
    
    try {
      final tracks = await _spotifyService.searchTracks(query);
      return tracks.map((track) => Song.fromSpotifyTrack(track)).toList();
    } catch (e) {
      _setError('Spotify search failed: $e');
      return [];
    }
  }
}
```

## 🎯 **Next Steps**

1. **Register your app** on Spotify Developer Dashboard
2. **Get your Client ID and Client Secret**
3. **Add the redirect URIs** as specified above
4. **Install the dependencies** in pubspec.yaml
5. **Configure platform-specific settings** (Android/iOS)
6. **Implement the authentication flow**
7. **Test the integration** with the provided URIs

## 🔒 **Security Best Practices**

- **Never expose Client Secret** in client-side code
- **Use PKCE flow** for mobile apps (more secure)
- **Store tokens securely** using flutter_secure_storage
- **Implement token refresh** logic
- **Handle authentication errors** gracefully

## 📋 **Required Spotify App Permissions**

When registering your app, request these scopes:
- `user-read-private` - Read user profile
- `user-library-read` - Read user's saved tracks
- `playlist-read-private` - Read private playlists
- `streaming` - Play music through Spotify (Premium required)
- `user-read-currently-playing` - See what's currently playing

**Use the redirect URI: `com.example.melody://spotify-auth` as your primary redirect URI in the Spotify Dashboard.**
