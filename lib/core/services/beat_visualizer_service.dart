import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Service that provides bass-synchronized visual effects for lyrics
class BeatVisualizerService extends ChangeNotifier {
  static final BeatVisualizerService _instance = BeatVisualizerService._internal();
  factory BeatVisualizerService() => _instance;
  BeatVisualizerService._internal();

  // Animation controllers and values
  double _flickerIntensity = 0.0;
  Color _glowColor = Colors.cyan;
  bool _isEnabled = true;
  
  // Bass detection parameters
  double _estimatedBassBPM = 80.0; // Focus on bass frequencies (typically slower)
  Duration _bassInterval = const Duration(milliseconds: 750); // Slower for bass detection
  Timer? _bassTimer;
  
  // Bass-specific flicker patterns
  int _currentPattern = 0;
  final List<List<double>> _bassFlickerPatterns = [
    [1.0, 0.3, 1.0], // Deep bass thump
    [1.0, 0.2, 0.8, 1.0], // Double bass hit
    [1.0, 0.1, 0.5, 0.2, 1.0], // Bass drop effect
    [1.0, 0.4, 1.0, 0.3, 1.0], // Rhythmic bass
  ];
  
  // Animation timers
  Timer? _flickerTimer;
  
  // Color patterns for different genres/moods
  final List<Color> _glowColors = [
    Colors.cyan,
    Colors.purple,
    Colors.pink,
    Colors.amber,
    Colors.green,
    Colors.red,
    Colors.blue,
  ];
  
  // Getters
  double get flickerIntensity => _flickerIntensity;
  Color get glowColor => _glowColor;
  bool get isEnabled => _isEnabled;
  double get estimatedBPM => _estimatedBassBPM;
  
  /// Start bass visualization with estimated BPM
  void startVisualization({double? bpm}) {
    if (!_isEnabled) return;
    
    _estimatedBassBPM = bpm ?? _estimatedBassBPM;
    _updateBassInterval();
    _startBassTimer();
    _randomizeColorPattern();
  }
  
  /// Stop bass visualization
  void stopVisualization() {
    _bassTimer?.cancel();
    _flickerTimer?.cancel();
    _resetEffects();
  }
  
  /// Update bass BPM dynamically
  void updateBPM(double bpm) {
    _estimatedBassBPM = bpm.clamp(60.0, 200.0);
    _updateBassInterval();
    
    if (_bassTimer?.isActive == true) {
      _bassTimer?.cancel();
      _startBassTimer();
    }
  }
  
  /// Toggle visualization on/off
  void toggleVisualization() {
    _isEnabled = !_isEnabled;
    if (!_isEnabled) {
      stopVisualization();
    }
    notifyListeners();
  }
  
  /// Set bass flicker pattern (0-3)
  void setFlickerPattern(int pattern) {
    _currentPattern = pattern.clamp(0, _bassFlickerPatterns.length - 1);
  }
  
  /// Estimate bass BPM from song duration and typical patterns
  double estimateBPMFromSong({
    required String title,
    required String artist,
    required Duration duration,
  }) {
    // Bass-focused genre BPM estimation (typically slower than main beat)
    final titleLower = title.toLowerCase();
    final artistLower = artist.toLowerCase();
    
    // Electronic/Dance music - focus on bass drops
    if (titleLower.contains(RegExp(r'(dance|electronic|techno|house|edm|beat|drop|bass)')) ||
        artistLower.contains(RegExp(r'(calvin harris|david guetta|skrillex|deadmau5|tiesto)'))) {
      return 60.0 + Random().nextDouble() * 15; // 60-75 BPM (bass emphasis)
    }
    
    // Hip-hop/Rap - strong bass presence
    if (titleLower.contains(RegExp(r'(rap|hip.?hop|trap|drill)')) ||
        artistLower.contains(RegExp(r'(eminem|drake|kanye|kendrick|travis scott)'))) {
      return 50.0 + Random().nextDouble() * 20; // 50-70 BPM (bass-heavy)
    }
    
    // Rock/Metal - bass guitar focus
    if (titleLower.contains(RegExp(r'(rock|metal|punk|hard|heavy)')) ||
        artistLower.contains(RegExp(r'(metallica|iron maiden|foo fighters|green day)'))) {
      return 65.0 + Random().nextDouble() * 20; // 65-85 BPM (bass guitar)
    }
    
    // Pop music - bass line focus
    if (titleLower.contains(RegExp(r'(pop|love|heart|feel|dream)'))) {
      return 55.0 + Random().nextDouble() * 15; // 55-70 BPM (bass line)
    }
    
    // Ballad/Slow songs - minimal bass
    if (titleLower.contains(RegExp(r'(slow|ballad|sad|tears|alone|miss)'))) {
      return 40.0 + Random().nextDouble() * 15; // 40-55 BPM (minimal bass)
    }
    
    // Default based on duration (bass frequencies)
    if (duration.inMinutes < 2) {
      return 70.0 + Random().nextDouble() * 15; // Short songs, moderate bass
    } else if (duration.inMinutes > 5) {
      return 45.0 + Random().nextDouble() * 15; // Long songs, slower bass
    }
    
    // Default bass BPM
    return 55.0 + Random().nextDouble() * 20; // 55-75 BPM (bass focus)
  }
  
  /// Update bass interval based on BPM
  void _updateBassInterval() {
    final millisecondsPerBeat = (60000 / _estimatedBassBPM).round();
    _bassInterval = Duration(milliseconds: millisecondsPerBeat);
  }
  
  /// Start the main bass timer
  void _startBassTimer() {
    _bassTimer = Timer.periodic(_bassInterval, (timer) {
      _triggerBassEffect();
    });
  }
  
  /// Trigger visual effects on each bass hit
  void _triggerBassEffect() {
    if (!_isEnabled) return;
    
    _triggerBassFlickerEffect();
    
    // Change color less frequently for bass (every 12 bass hits)
    if (Random().nextInt(12) == 0) {
      _randomizeColorPattern();
    }
  }
  
  /// Create bass flicker effect
  void _triggerBassFlickerEffect() {
    _flickerTimer?.cancel();
    
    final pattern = _bassFlickerPatterns[_currentPattern];
    int stepIndex = 0;
    
    void animateStep() {
      if (stepIndex >= pattern.length) {
        _flickerIntensity = 1.0;
        notifyListeners();
        return;
      }
      
      _flickerIntensity = pattern[stepIndex];
      notifyListeners();
      
      stepIndex++;
      // Slower bass flicker animation (bass is typically slower than treble)
      _flickerTimer = Timer(Duration(milliseconds: (_bassInterval.inMilliseconds / (pattern.length * 1.2)).round()), animateStep);
    }
    
    animateStep();
  }
  
  /// Randomize glow color
  void _randomizeColorPattern() {
    _glowColor = _glowColors[Random().nextInt(_glowColors.length)];
    notifyListeners();
  }
  
  /// Reset all effects to default
  void _resetEffects() {
    _flickerIntensity = 1.0;
    notifyListeners();
  }
  
  /// Create a text style with beat effects applied
  TextStyle applyBeatEffects(TextStyle baseStyle) {
    if (!_isEnabled) return baseStyle;
    
    return baseStyle.copyWith(
      color: baseStyle.color?.withValues(alpha: _flickerIntensity),
      shadows: [
        // Inner glow
        Shadow(
          color: _glowColor.withValues(alpha: _flickerIntensity * 0.9),
          blurRadius: 4.0 * _flickerIntensity,
          offset: Offset.zero,
        ),
        // Medium glow
        Shadow(
          color: _glowColor.withValues(alpha: _flickerIntensity * 0.7),
          blurRadius: 12.0 * _flickerIntensity,
          offset: Offset.zero,
        ),
        // Outer glow
        Shadow(
          color: _glowColor.withValues(alpha: _flickerIntensity * 0.5),
          blurRadius: 24.0 * _flickerIntensity,
          offset: Offset.zero,
        ),
        // Extra wide glow for dramatic effect
        Shadow(
          color: _glowColor.withValues(alpha: _flickerIntensity * 0.3),
          blurRadius: 40.0 * _flickerIntensity,
          offset: Offset.zero,
        ),
      ],
    );
  }
  
  /// Create a container decoration with beat effects
  BoxDecoration applyBeatGlow(BoxDecoration baseDecoration) {
    if (!_isEnabled) return baseDecoration;
    
    return baseDecoration.copyWith(
      boxShadow: [
        ...baseDecoration.boxShadow ?? [],
        // Inner glow - subtle but visible
        BoxShadow(
          color: _glowColor.withValues(alpha: _flickerIntensity * 0.4),
          blurRadius: 12.0 * _flickerIntensity,
          spreadRadius: 2.0 * _flickerIntensity,
          offset: Offset.zero,
        ),
        // Outer glow - gentle enhancement
        BoxShadow(
          color: _glowColor.withValues(alpha: _flickerIntensity * 0.25),
          blurRadius: 25.0 * _flickerIntensity,
          spreadRadius: 4.0 * _flickerIntensity,
          offset: Offset.zero,
        ),
      ],
    );
  }
}
