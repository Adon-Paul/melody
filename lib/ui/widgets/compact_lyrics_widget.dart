import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../core/services/advanced_lyrics_sync_service.dart';
import '../../core/services/music_service.dart';
import '../../core/services/beat_visualizer_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

/// Compact lyrics widget that displays up to 4 lines of current lyrics
class CompactLyricsWidget extends StatefulWidget {
  final double? height;
  final bool showTimestamps;
  
  const CompactLyricsWidget({
    super.key,
    this.height,
    this.showTimestamps = false,
  });

  @override
  State<CompactLyricsWidget> createState() => _CompactLyricsWidgetState();
}

class _CompactLyricsWidgetState extends State<CompactLyricsWidget> 
    with TickerProviderStateMixin {
  Timer? _updateTimer;
  String _currentLyrics = '';
  bool _hasLyrics = false;
  bool _isLoading = false;
  String? _lastRequestedSong; // Track which song we last requested lyrics for
  
  // Delay adjustment state
  late ValueNotifier<double> _delayNotifier;
  
  // Beat visualizer
  late BeatVisualizerService _beatVisualizer;
  
  // RGB Breathing animation for when beat effects are disabled
  late AnimationController _breathingController;
  late Animation<Color?> _rgbAnimation;

  @override
  void initState() {
    super.initState();
    _beatVisualizer = BeatVisualizerService();
    _initializeDelayNotifier();
    _initializeBreathingAnimation();
    _startLyricsMonitoring();
  }

  void _initializeBreathingAnimation() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _rgbAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.red, end: Colors.green),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.green, end: Colors.blue),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.blue, end: Colors.red),
        weight: 1.0,
      ),
    ]).animate(_breathingController);

    _breathingController.repeat();
  }  void _initializeDelayNotifier() async {
    final lyricsService = Provider.of<AdvancedLyricsSyncService>(context, listen: false);
    final currentDelay = lyricsService.getDelay();
    _delayNotifier = ValueNotifier<double>(currentDelay);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _beatVisualizer.stopVisualization();
    _delayNotifier.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _startLyricsMonitoring() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _updateLyricsDisplay();
    });
  }

  void _updateLyricsDisplay() {
    final lyricsService = Provider.of<AdvancedLyricsSyncService>(context, listen: false);
    final musicService = Provider.of<MusicService>(context, listen: false);
    
    // Create a song identifier
    final currentSong = musicService.currentSong;
    final currentSongId = currentSong != null ? '${currentSong.artist}-${currentSong.title}' : null;
    
    // Check if we need to start loading lyrics for a new song
    if (currentSongId != null && currentSongId != _lastRequestedSong) {
      setState(() {
        _isLoading = true;
        _hasLyrics = false;
        _currentLyrics = '';
        _lastRequestedSong = currentSongId;
      });
      
      // Start beat visualization with estimated BPM
      final estimatedBPM = _beatVisualizer.estimateBPMFromSong(
        title: currentSong!.title,
        artist: currentSong.artist,
        duration: currentSong.duration ?? const Duration(minutes: 3),
      );
      _beatVisualizer.startVisualization(bpm: estimatedBPM);
      
      lyricsService.loadLyrics(currentSong.artist, currentSong.title);
      return;
    }
    
    // No song playing
    if (currentSong == null) {
      _beatVisualizer.stopVisualization();
      setState(() {
        _isLoading = false;
        _hasLyrics = false;
        _currentLyrics = '';
        _lastRequestedSong = null;
      });
      return;
    }
    
    // Update beat visualization based on playback state
    if (musicService.isPlaying) {
      if (!_beatVisualizer.isEnabled) {
        final estimatedBPM = _beatVisualizer.estimateBPMFromSong(
          title: currentSong.title,
          artist: currentSong.artist,
          duration: currentSong.duration ?? const Duration(minutes: 3),
        );
        _beatVisualizer.startVisualization(bpm: estimatedBPM);
      }
    } else {
      _beatVisualizer.stopVisualization();
    }
    
    // Determine the actual state based on lyrics service
    bool newIsLoading = false;
    bool newHasLyrics = false;
    String newLyrics = '';
    
    if (lyricsService.allLines.isNotEmpty) {
      // We have lyrics loaded
      newHasLyrics = true;
      newIsLoading = false;
      
      // Check if we have a current line to display
      if (lyricsService.currentLineIndex >= 0 && 
          lyricsService.currentLineIndex < lyricsService.allLines.length) {
        newLyrics = lyricsService.allLines[lyricsService.currentLineIndex].lyrics;
      } else {
        // Lyrics are available but haven't started yet (instrumental intro)
        newLyrics = ''; // Keep empty but don't show "No lyrics available"
      }
    } else if (lyricsService.hasLyrics == false && currentSongId == _lastRequestedSong) {
      // No lyrics found for this song (loading completed with no results)
      newHasLyrics = false;
      newIsLoading = false;
      newLyrics = '';
    } else if (currentSongId == _lastRequestedSong) {
      // Still loading lyrics for this song
      newIsLoading = true;
      newHasLyrics = false;
      newLyrics = '';
    }
    
    // Update state if changed (with debouncing to prevent excessive updates)
    if (newLyrics != _currentLyrics || newHasLyrics != _hasLyrics || newIsLoading != _isLoading) {
      if (mounted) {
        // Add a small delay to debounce rapid updates
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _currentLyrics = newLyrics;
              _hasLyrics = newHasLyrics;
              _isLoading = newIsLoading;
            });
          }
        });
      }
    }
  }

  void _reloadLyrics() {
    final musicService = Provider.of<MusicService>(context, listen: false);
    final lyricsService = Provider.of<AdvancedLyricsSyncService>(context, listen: false);
    
    final currentSong = musicService.currentSong;
    if (currentSong != null) {
      setState(() {
        _isLoading = true;
        _hasLyrics = false;
        _currentLyrics = '';
        _lastRequestedSong = '${currentSong.artist}-${currentSong.title}';
      });
      lyricsService.loadLyrics(currentSong.artist, currentSong.title);
      
      // Reset delay when reloading
      lyricsService.resetDelay();
      _delayNotifier.value = lyricsService.getDelay();
    }
  }

  void _increaseDelay() {
    final lyricsService = Provider.of<AdvancedLyricsSyncService>(context, listen: false);
    lyricsService.adjustDelay(500.0);
    _delayNotifier.value = lyricsService.getDelay();
  }

  void _decreaseDelay() {
    final lyricsService = Provider.of<AdvancedLyricsSyncService>(context, listen: false);
    lyricsService.adjustDelay(-500.0);
    _delayNotifier.value = lyricsService.getDelay();
  }

  /// Get Google Font based on settings
  TextStyle _getLyricsFontStyle(String fontName, {
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required double letterSpacing,
  }) {
    switch (fontName) {
      case 'MedievalSharp':
        return GoogleFonts.medievalSharp(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
        );
      case 'Orbitron':
        return GoogleFonts.orbitron(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
        );
      case 'Dancing Script':
        return GoogleFonts.dancingScript(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
        );
      case 'Cinzel':
        return GoogleFonts.cinzel(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
        );
      case 'Merriweather':
        return GoogleFonts.merriweather(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
        );
      default:
        return GoogleFonts.medievalSharp(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          letterSpacing: letterSpacing,
        );
    }
  }

  /// Apply either beat glow or RGB breathing effect based on beat visualizer state and settings
  BoxDecoration _getGlowDecoration(BoxDecoration baseDecoration) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    if (_beatVisualizer.isEnabled) {
      // Use beat-synchronized glow
      return _beatVisualizer.applyBeatGlow(baseDecoration);
    } else if (settingsService.rgbEffectsEnabled) {
      // Use RGB breathing effect
      return baseDecoration.copyWith(
        boxShadow: [
          ...?baseDecoration.boxShadow,
          BoxShadow(
            color: _rgbAnimation.value?.withValues(alpha: 0.8) ?? Colors.cyan.withValues(alpha: 0.5),
            blurRadius: 20.0,
            spreadRadius: 5.0,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: _rgbAnimation.value?.withValues(alpha: 0.5) ?? Colors.cyan.withValues(alpha: 0.3),
            blurRadius: 35.0,
            spreadRadius: 8.0,
            offset: Offset.zero,
          ),
        ],
      );
    } else {
      // No effects
      return baseDecoration;
    }
  }

  /// Apply either beat effects or RGB breathing text effects based on beat visualizer state and settings
  TextStyle _getTextEffects(TextStyle baseStyle) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    if (_beatVisualizer.isEnabled) {
      // Use beat-synchronized effects
      return _beatVisualizer.applyBeatEffects(baseStyle);
    } else if (settingsService.rgbEffectsEnabled) {
      // Use RGB breathing effect
      return baseStyle.copyWith(
        shadows: [
          Shadow(
            color: _rgbAnimation.value?.withValues(alpha: 1.0) ?? Colors.cyan.withValues(alpha: 0.7),
            blurRadius: 12.0,
            offset: Offset.zero,
          ),
          Shadow(
            color: _rgbAnimation.value?.withValues(alpha: 0.6) ?? Colors.cyan.withValues(alpha: 0.4),
            blurRadius: 20.0,
            offset: Offset.zero,
          ),
        ],
      );
    } else {
      // No effects
      return baseStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        // Return empty container if lyrics are disabled
        if (!settingsService.lyricsEnabled) {
          return const SizedBox.shrink();
        }
        
        return RepaintBoundary( // Isolate repaints to this widget only
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400, // Increased from 320 to 400
          minHeight: 90, // Increased from 80 to 90
          maxHeight: 180, // Increased from 140 to 180 for more length
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with BETA tag, delay controls, and reload button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'LYRICS • BETA',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                // Options button with dropdown menu
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      size: 16,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  color: AppTheme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppTheme.accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  offset: const Offset(0, 40),
                  itemBuilder: (context) => [
                    // Delay controls section
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sync Delay',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: _decreaseDelay,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 14,
                                      color: AppTheme.accentColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ValueListenableBuilder<double>(
                                  valueListenable: _delayNotifier,
                                  builder: (context, delay, child) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${delay.toInt()}ms',
                                        style: TextStyle(
                                          color: AppTheme.accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: _increaseDelay,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.accentColor.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: AppTheme.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    // Beat visualizer toggle
                    PopupMenuItem<String>(
                      value: 'beat_toggle',
                      child: AnimatedBuilder(
                        animation: _beatVisualizer,
                        builder: (context, child) {
                          return Row(
                            children: [
                              Icon(
                                _beatVisualizer.isEnabled ? Icons.graphic_eq : Icons.graphic_eq_outlined,
                                size: 18,
                                color: _beatVisualizer.isEnabled 
                                  ? AppTheme.accentColor
                                  : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _beatVisualizer.isEnabled ? 'Disable Beat Effects' : 'Enable Beat Effects',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // RGB effects toggle
                    PopupMenuItem<String>(
                      value: 'rgb_toggle',
                      child: Consumer<SettingsService>(
                        builder: (context, settingsService, child) {
                          return Row(
                            children: [
                              Icon(
                                settingsService.rgbEffectsEnabled ? Icons.color_lens : Icons.color_lens_outlined,
                                size: 18,
                                color: settingsService.rgbEffectsEnabled 
                                  ? AppTheme.accentColor
                                  : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                settingsService.rgbEffectsEnabled ? 'Disable RGB Effects' : 'Enable RGB Effects',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Reload lyrics
                    PopupMenuItem<String>(
                      value: 'reload',
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Reload Lyrics',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    // Font selection
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Consumer<SettingsService>(
                        builder: (context, settingsService, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lyrics Font',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButton<String>(
                                value: settingsService.lyricsFont,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    settingsService.setLyricsFont(newValue);
                                  }
                                },
                                items: [
                                  'MedievalSharp',
                                  'Orbitron',
                                  'Dancing Script',
                                  'Cinzel',
                                  'Merriweather'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                dropdownColor: AppTheme.cardColor,
                                underline: Container(),
                                isDense: true,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Font Size: ${settingsService.lyricsFontSize.toInt()}px',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  activeTrackColor: AppTheme.accentColor,
                                  inactiveTrackColor: AppTheme.accentColor.withValues(alpha: 0.3),
                                  thumbColor: AppTheme.accentColor,
                                ),
                                child: Slider(
                                  value: settingsService.lyricsFontSize,
                                  min: 16.0,
                                  max: 32.0,
                                  divisions: 8,
                                  onChanged: (value) => settingsService.setLyricsFontSize(value),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const PopupMenuDivider(),
                    // Lyrics provider info
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lyrics Provider',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'LRCLIB.net - Community Lyrics Database',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Synchronized LRC format with word-perfect timing',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'beat_toggle':
                        _beatVisualizer.toggleVisualization();
                        break;
                      case 'rgb_toggle':
                        Provider.of<SettingsService>(context, listen: false)
                            .setRgbEffectsEnabled(!Provider.of<SettingsService>(context, listen: false).rgbEffectsEnabled);
                        break;
                      case 'reload':
                        _reloadLyrics();
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Lyrics content
            Expanded(
              child: _buildLyricsContent(),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildLyricsContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading lyrics...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Show different messages based on the state
    if (!_hasLyrics) {
      // Truly no lyrics available for this song
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              color: Colors.white38,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              'No lyrics available',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (_currentLyrics.isEmpty) {
      // Lyrics are available but haven't started yet (instrumental intro)
      return AnimatedBuilder(
        animation: Listenable.merge([_beatVisualizer, _breathingController]),
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: _getGlowDecoration(
                    BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Lottie.asset(
                      'assets/animations/music_play.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
                // Animated music symbol for instrumentals (using splash screen animation)
              ],
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_beatVisualizer, _breathingController]),
      builder: (context, child) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360), // Increased from 280 to 360
            child: Consumer<SettingsService>(
              builder: (context, settingsService, child) {
                return Text(
                  _currentLyrics,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: _getTextEffects(
                    _getLyricsFontStyle(
                      settingsService.lyricsFont,
                      color: AppTheme.primaryColor,
                      fontSize: settingsService.lyricsFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
