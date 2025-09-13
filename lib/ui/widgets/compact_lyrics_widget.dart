import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/advanced_lyrics_sync_service.dart';
import '../../core/services/music_service.dart';
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

class _CompactLyricsWidgetState extends State<CompactLyricsWidget> {
  Timer? _updateTimer;
  String _currentLyrics = '';
  bool _hasLyrics = false;
  bool _isLoading = false;
  String? _lastRequestedSong; // Track which song we last requested lyrics for
  
  // Delay adjustment state
  late ValueNotifier<double> _delayNotifier;

  @override
  void initState() {
    super.initState();
    _initializeDelayNotifier();
    _startLyricsMonitoring();
  }

  void _initializeDelayNotifier() async {
    final lyricsService = Provider.of<AdvancedLyricsSyncService>(context, listen: false);
    final currentDelay = lyricsService.getDelay();
    _delayNotifier = ValueNotifier<double>(currentDelay);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _delayNotifier.dispose();
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
      return;
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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary( // Isolate repaints to this widget only
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 320,
          minHeight: 80,
          maxHeight: 120,
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
                // Delay adjustment controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delay display
                    ValueListenableBuilder<double>(
                      valueListenable: _delayNotifier,
                      builder: (context, delay, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${delay.toInt()}ms',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    // Decrease delay button
                    InkWell(
                      onTap: _decreaseDelay,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
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
                          size: 12,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Increase delay button
                    InkWell(
                      onTap: _increaseDelay,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
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
                          size: 12,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reload button
                    InkWell(
                      onTap: _reloadLyrics,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
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
                          Icons.refresh_rounded,
                          size: 16,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              color: Colors.white60,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              '[Instrumentals]',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Text(
          _currentLyrics,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
