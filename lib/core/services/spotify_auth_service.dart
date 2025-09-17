import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../config/spotify_config.dart';

class SpotifyAuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _isAuthenticated = false;
  StreamSubscription<Uri>? _linkStreamSubscription;
  final AppLinks _appLinks = AppLinks();
  
  String? _lastError;
  
  // Getters
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _isAuthenticated && _isTokenValid();
  String? get lastError => _lastError;
  
  // Get auth URL for manual copy
  String getAuthUrl() {
    final state = SpotifyConfig.generateState();
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    
    // Store for later use
    _storage.write(key: 'spotify_code_verifier', value: codeVerifier);
    _storage.write(key: 'spotify_state', value: state);
    
    final authUri = Uri.parse(SpotifyConfig.authUrl).replace(
      queryParameters: {
        'client_id': SpotifyConfig.clientId,
        'response_type': 'code',
        'redirect_uri': SpotifyConfig.redirectUri,
        'scope': SpotifyConfig.scopeString,
        'state': state,
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
        'show_dialog': 'true',
      },
    );
    
    return authUri.toString();
  }
  
  // Initialize the service
  Future<void> initialize() async {
    debugPrint('🎵 Initializing SpotifyAuthService...');
    await _loadStoredTokens();
    _listenForAuthCallback();
    debugPrint('🎧 Deep link listener started');
    
    // Check for initial link (app opened by deep link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 Found initial deep link: ${initialLink.toString()}');
        await _handleAuthCallback(initialLink.toString());
      } else {
        debugPrint('🔗 No initial deep link found');
      }
    } catch (e) {
      debugPrint('❌ Error checking initial link: $e');
    }
    
    // Check if we have valid tokens
    if (_isTokenValid()) {
      _isAuthenticated = true;
      debugPrint('✅ Found valid stored tokens');
      notifyListeners();
    } else if (_refreshToken != null) {
      debugPrint('🔄 Attempting to refresh stored tokens');
      await _refreshAccessToken();
    }
    
    debugPrint('🎵 SpotifyAuthService initialization complete');
  }
  
  // Start Spotify authentication flow
  Future<bool> authenticate() async {
    try {
      _lastError = null;
      debugPrint('🎵 Starting Spotify authentication...');
      
      final state = SpotifyConfig.generateState();
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      
      debugPrint('🔑 Generated PKCE challenge');
      
      // Store code verifier for later use
      await _storage.write(key: 'spotify_code_verifier', value: codeVerifier);
      await _storage.write(key: 'spotify_state', value: state);
      
      final authUri = Uri.parse(SpotifyConfig.authUrl).replace(
        queryParameters: {
          'client_id': SpotifyConfig.clientId,
          'response_type': 'code',
          'redirect_uri': SpotifyConfig.redirectUri,
          'scope': SpotifyConfig.scopeString,
          'state': state,
          'code_challenge_method': 'S256',
          'code_challenge': codeChallenge,
          'show_dialog': 'true',
        },
      );
      
      debugPrint('🌐 Auth URL: ${authUri.toString()}');
      
      // Try multiple launch methods with fallbacks
      bool launched = await _tryLaunchUrl(authUri);
      
      if (launched) {
        debugPrint('🚀 Successfully launched Spotify auth URL');
        return true;
      } else {
        _lastError = 'Could not launch Spotify authorization URL. Please manually open the URL in your browser.';
        debugPrint('❌ All launch methods failed. URL: ${authUri.toString()}');
        throw Exception(_lastError);
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Spotify authentication error: $e');
      return false;
    }
  }

  // Try multiple methods to launch the URL
  Future<bool> _tryLaunchUrl(Uri uri) async {
    debugPrint('🔄 Trying to launch URL: ${uri.toString()}');
    
    // Method 1: Try with external application mode
    try {
      debugPrint('🌐 Method 1: External application mode...');
      if (await canLaunchUrl(uri)) {
        bool result = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (result) {
          debugPrint('✅ Method 1 successful');
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ Method 1 failed: $e');
    }
    
    // Method 2: Try with platform default mode
    try {
      debugPrint('🌐 Method 2: Platform default mode...');
      bool result = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (result) {
        debugPrint('✅ Method 2 successful');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Method 2 failed: $e');
    }
    
    // Method 3: Try with in-app web view
    try {
      debugPrint('🌐 Method 3: In-app web view mode...');
      bool result = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      if (result) {
        debugPrint('✅ Method 3 successful');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Method 3 failed: $e');
    }
    
    // Method 4: Try without specifying mode
    try {
      debugPrint('🌐 Method 4: Default launch...');
      bool result = await launchUrl(uri);
      if (result) {
        debugPrint('✅ Method 4 successful');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Method 4 failed: $e');
    }
    
    debugPrint('❌ All launch methods failed');
    return false;
  }
  
  // Listen for authentication callback
  void _listenForAuthCallback() {
    debugPrint('🔗 Setting up deep link listener...');
    _linkStreamSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 Deep link received: ${uri.toString()}');
        _handleAuthCallback(uri.toString());
      },
      onError: (err) {
        debugPrint('❌ Deep link error: $err');
        _lastError = 'Deep link error: $err';
        notifyListeners();
      },
    );
    debugPrint('✅ Deep link listener active');
  }
  
  // Test method to check if a deep link works
  Future<void> testDeepLink(String testUrl) async {
    debugPrint('🧪 Testing deep link: $testUrl');
    try {
      await _handleAuthCallback(testUrl);
    } catch (e) {
      debugPrint('❌ Deep link test failed: $e');
    }
  }
  
  // Handle the authentication callback
  Future<void> _handleAuthCallback(String link) async {
    try {
      debugPrint('🔗 Received auth callback: $link');
      final uri = Uri.parse(link);
      
      // Handle both redirect URI schemes
      bool isValidCallback = false;
      if ((uri.scheme == 'com.example.melody' && uri.host == 'spotify-auth') ||
          (uri.scheme == 'melody' && uri.host == 'auth')) {
        isValidCallback = true;
      }
      
      if (isValidCallback) {
        final code = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];
        final error = uri.queryParameters['error'];
        
        debugPrint('📋 Callback params - code: ${code != null ? 'present' : 'missing'}, state: ${state != null ? 'present' : 'missing'}, error: $error');
        
        if (error != null) {
          _lastError = 'Spotify authorization error: $error';
          if (error == 'access_denied') {
            _lastError = 'Access denied. Please accept the Spotify permissions to continue.';
          }
          debugPrint('❌ Spotify auth error: $_lastError');
          notifyListeners();
          throw Exception(_lastError);
        }
        
        if (code != null && state != null) {
          final storedState = await _storage.read(key: 'spotify_state');
          debugPrint('🔐 State validation - received: $state, stored: $storedState');
          
          if (state != storedState) {
            _lastError = 'Security error: Invalid state parameter. Please try again.';
            debugPrint('❌ State validation failed: $_lastError');
            notifyListeners();
            throw Exception(_lastError);
          }
          
          await _exchangeCodeForTokens(code);
        } else {
          _lastError = 'Missing authorization code or state parameter.';
          debugPrint('❌ Missing required parameters: $_lastError');
          notifyListeners();
        }
      } else {
        debugPrint('🚫 Callback URL scheme not recognized: ${uri.scheme}://${uri.host}');
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Auth callback error: $e');
      notifyListeners();
    }
  }
  
  // Exchange authorization code for access tokens
  Future<void> _exchangeCodeForTokens(String code) async {
    try {
      debugPrint('🔄 Exchanging authorization code for tokens...');
      
      final codeVerifier = await _storage.read(key: 'spotify_code_verifier');
      if (codeVerifier == null) {
        _lastError = 'Code verifier not found. Please try authenticating again.';
        throw Exception(_lastError);
      }
      
      debugPrint('📤 Making token exchange request...');
      
      final response = await http.post(
        Uri.parse(SpotifyConfig.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': SpotifyConfig.redirectUri,
          'client_id': SpotifyConfig.clientId,
          'code_verifier': codeVerifier,
        },
      );
      
      debugPrint('📥 Token exchange response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storeTokens(data);
        
        _isAuthenticated = true;
        _lastError = null;
        debugPrint('✅ Spotify authentication successful!');
        notifyListeners();
        
        // Clean up stored verification data
        await _storage.delete(key: 'spotify_code_verifier');
        await _storage.delete(key: 'spotify_state');
      } else {
        final errorData = json.decode(response.body);
        _lastError = 'Token exchange failed: ${errorData['error_description'] ?? 'Unknown error'}';
        debugPrint('❌ Token exchange failed: ${response.statusCode} - ${response.body}');
        throw Exception(_lastError);
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Token exchange error: $e');
      rethrow;
    }
  }
  
  // Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse(SpotifyConfig.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': SpotifyConfig.clientId,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storeTokens(data);
        
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        await logout(); // Clear invalid tokens
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await logout();
      return false;
    }
  }
  
  // Store tokens securely
  Future<void> _storeTokens(Map<String, dynamic> tokenData) async {
    _accessToken = tokenData['access_token'];
    _refreshToken = tokenData['refresh_token'] ?? _refreshToken;
    
    final expiresIn = tokenData['expires_in'] as int;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    
    // Store in secure storage
    await _storage.write(key: 'spotify_access_token', value: _accessToken);
    if (_refreshToken != null) {
      await _storage.write(key: 'spotify_refresh_token', value: _refreshToken);
    }
    await _storage.write(key: 'spotify_token_expiry', value: _tokenExpiry!.toIso8601String());
  }
  
  // Load stored tokens
  Future<void> _loadStoredTokens() async {
    try {
      _accessToken = await _storage.read(key: 'spotify_access_token');
      _refreshToken = await _storage.read(key: 'spotify_refresh_token');
      
      final expiryString = await _storage.read(key: 'spotify_token_expiry');
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }
    } catch (e) {
      debugPrint('Error loading stored tokens: $e');
    }
  }
  
  // Check if current token is valid
  bool _isTokenValid() {
    if (_accessToken == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)));
  }
  
  // Get valid access token (refresh if needed)
  Future<String?> getValidAccessToken() async {
    if (_isTokenValid()) {
      return _accessToken;
    } else if (_refreshToken != null) {
      final refreshed = await _refreshAccessToken();
      return refreshed ? _accessToken : null;
    }
    return null;
  }
  
  // Logout and clear all tokens
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _isAuthenticated = false;
    
    // Clear stored tokens
    await _storage.delete(key: 'spotify_access_token');
    await _storage.delete(key: 'spotify_refresh_token');
    await _storage.delete(key: 'spotify_token_expiry');
    
    notifyListeners();
  }
  
  // Generate code verifier for PKCE
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (i) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Generate code challenge for PKCE
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
  
  @override
  void dispose() {
    _linkStreamSubscription?.cancel();
    super.dispose();
  }
}
