import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInService {
  // Use the traditional 6.x API configuration
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In...');
      
      // Check if we're on a supported platform
      if (kIsWeb) {
        debugPrint('Web platform - Google Sign-In implementation');
        return await _signInWithGoogleWeb();
      } else if (defaultTargetPlatform == TargetPlatform.android || 
                 defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('Mobile platform - Google Sign-In implementation');
        return await _signInWithGoogleMobile();
      } else {
        debugPrint('Desktop platform - Google Sign-In not directly supported');
        throw Exception('Google Sign-In is not available on this platform. Please use email/password authentication.');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }
  
  static Future<UserCredential?> _signInWithGoogleWeb() async {
    try {
      // Create a GoogleAuthProvider instance
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes if needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Trigger the authentication flow
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      
      debugPrint('Web Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Web Google Sign-In failed: $e');
      rethrow;
    }
  }
  
  static Future<UserCredential?> _signInWithGoogleMobile() async {
    try {
      debugPrint('Starting mobile Google Sign-In with traditional 6.x API...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If the user cancels the sign-in process
      if (googleUser == null) {
        debugPrint('Google Sign-In was cancelled by user');
        return null;
      }
      
      debugPrint('Google user obtained: ${googleUser.email}');
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      debugPrint('Google authentication obtained');
      debugPrint('Has access token: ${googleAuth.accessToken != null}');
      debugPrint('Has ID token: ${googleAuth.idToken != null}');
      
      // Validate that we have the required tokens
      if (googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google ID token. This usually indicates an OAuth configuration issue.');
      }
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken!,
      );
      
      debugPrint('Firebase credential created, signing in...');
      
      // Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      debugPrint('Mobile Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Mobile Google Sign-In failed: $e');
      
      // Handle specific error cases
      if (e.toString().contains('sign_in_canceled') || 
          e.toString().contains('cancelled') || 
          e.toString().contains('CANCELED')) {
        debugPrint('User cancelled Google Sign-In');
        return null;
      }
      
      if (e.toString().contains('network_error')) {
        throw Exception('Network error during Google Sign-In. Please check your internet connection and try again.');
      }
      
      if (e.toString().contains('sign_in_failed') || 
          e.toString().contains('CLIENT_ID') || 
          e.toString().contains('configuration')) {
        throw Exception('Google Sign-In configuration issue. The account selection worked, which means basic OAuth is set up, but token exchange failed. Please ensure:\n'
            '1. OAuth client ID is properly configured in Firebase Console\n'
            '2. SHA-1 fingerprint is added to Firebase project\n'
            '3. google-services.json contains the correct configuration');
      }
      
      // For any other error, provide a helpful message
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }
  
  /// Sign out from Google Sign-In
  static Future<void> signOut() async {
    try {
      if (kIsWeb) {
        // Web sign out is handled by Firebase Auth
        await FirebaseAuth.instance.signOut();
      } else if (defaultTargetPlatform == TargetPlatform.android || 
                 defaultTargetPlatform == TargetPlatform.iOS) {
        // Mobile platforms need to sign out from both Google and Firebase
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      }
      debugPrint('Google Sign-In sign out successful');
    } catch (e) {
      debugPrint('Google Sign-In sign out error: $e');
      rethrow;
    }
  }
}
