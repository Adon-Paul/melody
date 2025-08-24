class SpotifyConfig {
  // Spotify App Credentials
  static const String clientId = 'a72c5609ff8549bbbec4325a2099e02f';
  
  // Note: Client Secret should be handled server-side for production apps
  // For development/testing purposes only - use PKCE flow in production
  static const String clientSecret = 'f12fac8a72294b6d835ff84a666ab03e';
  
  // Redirect URIs (must match Spotify Dashboard settings)
  static const String redirectUri = 'com.example.melody://spotify-auth';
  static const String customRedirectUri = 'melody://auth/spotify/callback';
  
  // Spotify API endpoints
  static const String authUrl = 'https://accounts.spotify.com/authorize';
  static const String tokenUrl = 'https://accounts.spotify.com/api/token';
  static const String apiBaseUrl = 'https://api.spotify.com/v1';
  
  // Required scopes for music player functionality
  static const List<String> scopes = [
    'user-read-private',           // Read user profile
    'user-read-email',             // Read user email
    'user-library-read',           // Read user's saved tracks
    'user-library-modify',         // Modify user's saved tracks
    'playlist-read-private',       // Read private playlists
    'playlist-read-collaborative', // Read collaborative playlists
    'playlist-modify-public',      // Modify public playlists
    'playlist-modify-private',     // Modify private playlists
    'user-read-playback-state',    // Read playback state
    'user-modify-playback-state',  // Control playback
    'user-read-currently-playing', // Read currently playing
    'streaming',                   // Play music (Premium required)
    'user-read-recently-played',   // Read listening history
    'user-top-read',              // Read top artists and tracks
  ];
  
  // Generate scope string for authorization
  static String get scopeString => scopes.join(' ');
  
  // Generate state parameter for security
  static String generateState() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
