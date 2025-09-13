import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _autoPlayKey = 'auto_play_enabled';
  static const String _shuffleKey = 'shuffle_enabled';
  static const String _repeatKey = 'repeat_enabled';
  static const String _animationsKey = 'animations_enabled';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _backgroundAudioKey = 'background_audio_enabled';
  static const String _lyricsEnabledKey = 'lyrics_enabled';
  static const String _lyricsFontKey = 'lyrics_font';
  static const String _lyricsFontSizeKey = 'lyrics_font_size';
  static const String _crossfadeDurationKey = 'crossfade_duration';
  static const String _audioQualityKey = 'audio_quality';
  static const String _themeModeKey = 'theme_mode';

  // Settings properties
  bool _autoPlayEnabled = true;
  bool _shuffleEnabled = false;
  bool _repeatEnabled = false;
  bool _animationsEnabled = true;
  bool _notificationsEnabled = true;
  bool _backgroundAudioEnabled = true;
  bool _lyricsEnabled = true;
  String _lyricsFont = 'MedievalSharp';
  double _lyricsFontSize = 24.0;
  double _crossfadeDuration = 3.0;
  String _audioQuality = 'High';
  String _themeMode = 'Dark';

  // Getters
  bool get autoPlayEnabled => _autoPlayEnabled;
  bool get shuffleEnabled => _shuffleEnabled;
  bool get repeatEnabled => _repeatEnabled;
  bool get animationsEnabled => _animationsEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get backgroundAudioEnabled => _backgroundAudioEnabled;
  bool get lyricsEnabled => _lyricsEnabled;
  String get lyricsFont => _lyricsFont;
  double get lyricsFontSize => _lyricsFontSize;
  double get crossfadeDuration => _crossfadeDuration;
  String get audioQuality => _audioQuality;
  String get themeMode => _themeMode;

  SharedPreferences? _prefs;

  /// Initialize the settings service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Load all settings from shared preferences
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _autoPlayEnabled = _prefs!.getBool(_autoPlayKey) ?? true;
    _shuffleEnabled = _prefs!.getBool(_shuffleKey) ?? false;
    _repeatEnabled = _prefs!.getBool(_repeatKey) ?? false;
    _animationsEnabled = _prefs!.getBool(_animationsKey) ?? true;
    _notificationsEnabled = _prefs!.getBool(_notificationsKey) ?? true;
    _backgroundAudioEnabled = _prefs!.getBool(_backgroundAudioKey) ?? true;
    _lyricsEnabled = _prefs!.getBool(_lyricsEnabledKey) ?? true;
    _lyricsFont = _prefs!.getString(_lyricsFontKey) ?? 'MedievalSharp';
    _lyricsFontSize = _prefs!.getDouble(_lyricsFontSizeKey) ?? 24.0;
    _crossfadeDuration = _prefs!.getDouble(_crossfadeDurationKey) ?? 3.0;
    _audioQuality = _prefs!.getString(_audioQualityKey) ?? 'High';
    _themeMode = _prefs!.getString(_themeModeKey) ?? 'Dark';

    notifyListeners();
  }

  /// Set auto play setting
  Future<void> setAutoPlayEnabled(bool enabled) async {
    _autoPlayEnabled = enabled;
    await _prefs?.setBool(_autoPlayKey, enabled);
    notifyListeners();
  }

  /// Set shuffle setting
  Future<void> setShuffleEnabled(bool enabled) async {
    _shuffleEnabled = enabled;
    await _prefs?.setBool(_shuffleKey, enabled);
    notifyListeners();
  }

  /// Set repeat setting
  Future<void> setRepeatEnabled(bool enabled) async {
    _repeatEnabled = enabled;
    await _prefs?.setBool(_repeatKey, enabled);
    notifyListeners();
  }

  /// Set animations setting
  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    await _prefs?.setBool(_animationsKey, enabled);
    notifyListeners();
  }

  /// Set notifications setting
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs?.setBool(_notificationsKey, enabled);
    notifyListeners();
  }

  /// Set background audio setting
  Future<void> setBackgroundAudioEnabled(bool enabled) async {
    _backgroundAudioEnabled = enabled;
    await _prefs?.setBool(_backgroundAudioKey, enabled);
    notifyListeners();
  }

  /// Set lyrics enabled setting
  Future<void> setLyricsEnabled(bool enabled) async {
    _lyricsEnabled = enabled;
    await _prefs?.setBool(_lyricsEnabledKey, enabled);
    notifyListeners();
  }

  /// Set lyrics font setting
  Future<void> setLyricsFont(String font) async {
    _lyricsFont = font;
    await _prefs?.setString(_lyricsFontKey, font);
    notifyListeners();
  }

  /// Set lyrics font size setting
  Future<void> setLyricsFontSize(double size) async {
    _lyricsFontSize = size;
    await _prefs?.setDouble(_lyricsFontSizeKey, size);
    notifyListeners();
  }

  /// Set crossfade duration
  Future<void> setCrossfadeDuration(double duration) async {
    _crossfadeDuration = duration;
    await _prefs?.setDouble(_crossfadeDurationKey, duration);
    notifyListeners();
  }

  /// Set audio quality
  Future<void> setAudioQuality(String quality) async {
    _audioQuality = quality;
    await _prefs?.setString(_audioQualityKey, quality);
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _prefs?.setString(_themeModeKey, mode);
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    if (_prefs == null) return;

    await _prefs!.clear();
    
    _autoPlayEnabled = true;
    _shuffleEnabled = false;
    _repeatEnabled = false;
    _animationsEnabled = true;
    _notificationsEnabled = true;
    _backgroundAudioEnabled = true;
    _lyricsEnabled = true;
    _lyricsFont = 'MedievalSharp';
    _lyricsFontSize = 24.0;
    _crossfadeDuration = 3.0;
    _audioQuality = 'High';
    _themeMode = 'Dark';

    notifyListeners();
  }

  /// Export settings as a map for backup
  Map<String, dynamic> exportSettings() {
    return {
      _autoPlayKey: _autoPlayEnabled,
      _shuffleKey: _shuffleEnabled,
      _repeatKey: _repeatEnabled,
      _animationsKey: _animationsEnabled,
      _notificationsKey: _notificationsEnabled,
      _backgroundAudioKey: _backgroundAudioEnabled,
      _lyricsEnabledKey: _lyricsEnabled,
      _lyricsFontKey: _lyricsFont,
      _lyricsFontSizeKey: _lyricsFontSize,
      _crossfadeDurationKey: _crossfadeDuration,
      _audioQualityKey: _audioQuality,
      _themeModeKey: _themeMode,
    };
  }

  /// Import settings from a map (for restore)
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (_prefs == null) return;

    for (final entry in settings.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is bool) {
        await _prefs!.setBool(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is String) {
        await _prefs!.setString(key, value);
      }
    }

    await _loadSettings();
  }
}
