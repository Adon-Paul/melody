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

  @override
  void initState() {
    super.initState();
    _startLyricsMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startLyricsMonitoring() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _updateLyricsDisplay();
    });
  }

  void _updateLyricsDisplay() {
    final lyricsService = Provider.of<AdvancedLyricsSyncService>(context, listen: false);
    
    // Check if lyrics are loading
    final newIsLoading = lyricsService.allLines.isEmpty && !lyricsService.hasLyrics;
    
    // Get current lyrics line
    String newLyrics = '';
    bool newHasLyrics = false;
    
    if (lyricsService.allLines.isNotEmpty && lyricsService.currentLineIndex >= 0) {
      final currentIndex = lyricsService.currentLineIndex;
      if (currentIndex < lyricsService.allLines.length) {
        newLyrics = lyricsService.allLines[currentIndex].lyrics;
        newHasLyrics = true;
      }
    }
    
    // Update state if changed
    if (newLyrics != _currentLyrics || newHasLyrics != _hasLyrics || newIsLoading != _isLoading) {
      if (mounted) {
        setState(() {
          _currentLyrics = newLyrics;
          _hasLyrics = newHasLyrics;
          _isLoading = newIsLoading;
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
      });
      lyricsService.loadLyrics(currentSong.artist, currentSong.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Header with BETA tag and reload button
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
          const SizedBox(height: 12),
          // Lyrics content
          Expanded(
            child: _buildLyricsContent(),
          ),
        ],
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

    if (!_hasLyrics || _currentLyrics.isEmpty) {
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
