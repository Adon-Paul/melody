import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../transitions/page_transitions.dart';
import '../../ui/full_music_player_page.dart';
import 'music_service.dart';

/// Utility class for handling music player navigation
class MusicPlayerNavigation {
  /// Navigates to the full music player screen
  /// 
  /// This should be called whenever a new song starts playing
  /// to provide an immersive full-screen experience
  static void navigateToFullPlayer(BuildContext context) {
    // Check if we're already on the full music player page
    if (_isOnFullMusicPlayer(context)) {
      // Already on full player, don't navigate
      return;
    }

    // Navigate to full music player with smooth transition
    Navigator.push(
      context,
      PageTransitions.circleMorph(const FullMusicPlayerPage()),
    );
  }

  /// Shows the full music player when a song starts playing
  /// 
  /// This is the main function to call when implementing auto-navigation
  /// to full screen on song play - but only for user-initiated plays
  static void showFullPlayerOnPlay(BuildContext context) {
    // Check if this was a user-initiated play
    final musicService = Provider.of<MusicService>(context, listen: false);
    if (!musicService.isUserInitiatedPlay) {
      // Not user-initiated (e.g., next/previous navigation), don't auto-open
      return;
    }

    // Add a small delay to ensure the song has started playing
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        navigateToFullPlayer(context);
      }
    });
  }

  /// Checks if the current screen is the full music player
  static bool _isOnFullMusicPlayer(BuildContext context) {
    // Check if we can find a FullMusicPlayerPage in the widget tree
    return context.findAncestorWidgetOfExactType<FullMusicPlayerPage>() != null;
  }

  /// Shows full player only for new song playback (not for next/previous navigation)
  /// 
  /// This can be used to differentiate between new song selection and 
  /// playlist navigation
  static void showFullPlayerOnNewSong(BuildContext context) {
    if (!_isOnFullMusicPlayer(context)) {
      showFullPlayerOnPlay(context);
    }
  }

  /// Force show full player regardless of user initiation (for manual calls)
  static void showFullPlayerAlways(BuildContext context) {
    // Add a small delay to ensure the song has started playing
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        navigateToFullPlayer(context);
      }
    });
  }
}
