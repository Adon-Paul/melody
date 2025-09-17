import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'music_service.dart';

class NotificationService {
  static const platform = MethodChannel('melody/notification');
  
  static Future<void> initialize() async {
    try {
      await platform.invokeMethod('initialize');
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize notification service: ${e.message}');
    }
  }

  static Future<void> showMusicNotification({
    required String title,
    required String artist,
    required bool isPlaying,
    String? albumArt,
  }) async {
    try {
      await platform.invokeMethod('showMusicNotification', {
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
        'albumArt': albumArt,
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to show music notification: ${e.message}');
    }
  }

  static Future<void> updateNotification({
    String? title,
    String? artist,
    bool? isPlaying,
    String? albumArt,
  }) async {
    try {
      final args = <String, dynamic>{};
      if (title != null) args['title'] = title;
      if (artist != null) args['artist'] = artist;
      if (isPlaying != null) args['isPlaying'] = isPlaying;
      if (albumArt != null) args['albumArt'] = albumArt;
      
      await platform.invokeMethod('updateNotification', args);
    } on PlatformException catch (e) {
      debugPrint('Failed to update music notification: ${e.message}');
    }
  }

  static Future<void> hideNotification() async {
    try {
      await platform.invokeMethod('hideNotification');
    } on PlatformException catch (e) {
      debugPrint('Failed to hide music notification: ${e.message}');
    }
  }

  static void setupNotificationHandlers(MusicService musicService) {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPlayPause':
          await musicService.togglePlayPause();
          break;
        case 'onNext':
          await musicService.playNext();
          break;
        case 'onPrevious':
          await musicService.playPrevious();
          break;
        case 'onStop':
          await musicService.stop();
          await hideNotification();
          break;
        default:
          throw PlatformException(
            code: 'UNKNOWN_METHOD',
            message: 'Unknown method: ${call.method}',
          );
      }
    });
  }
}
