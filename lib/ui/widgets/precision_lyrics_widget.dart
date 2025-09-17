import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lrc/lrc.dart';
import '../../core/services/advanced_lyrics_sync_service.dart';
import '../../core/theme/app_theme.dart';

/// Advanced lyrics widget with word-perfect synchronization
class PrecisionLyricsWidget extends StatefulWidget {
  final double? height;
  final bool showTimestamps;
  
  const PrecisionLyricsWidget({
    super.key,
    this.height,
    this.showTimestamps = false,
  });

  @override
  State<PrecisionLyricsWidget> createState() => _PrecisionLyricsWidgetState();
}

class _PrecisionLyricsWidgetState extends State<PrecisionLyricsWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late AnimationController _highlightController;
  late Animation<double> _fadeAnimation;
  
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _highlightController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _scrollToCurrentLine(int lineIndex) {
    if (!mounted || lineIndex < 0) return;
    
    final lyricsService = context.read<AdvancedLyricsSyncService>();
    if (!lyricsService.autoScroll) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      try {
        // Calculate the position to scroll to
        final itemHeight = 60.0; // Approximate height per line
        final containerHeight = widget.height ?? 300.0; // Default height if not specified
        final targetOffset = (lineIndex * itemHeight) - (containerHeight / 2);
        final maxOffset = _scrollController.position.maxScrollExtent;
        final clampedOffset = targetOffset.clamp(0.0, maxOffset);
        
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        debugPrint('Auto-scroll error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvancedLyricsSyncService>(
      builder: (context, lyricsService, child) {
        if (!lyricsService.isEnabled) {
          return _buildDisabledState();
        }

        if (!lyricsService.hasLyrics) {
          return _buildNoLyricsState();
        }

        // Auto-scroll to current line
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (lyricsService.currentLineIndex >= 0) {
            _scrollToCurrentLine(lyricsService.currentLineIndex);
            _highlightController.forward();
          }
        });

        return _buildLyricsView(lyricsService);
      },
    );
  }

  Widget _buildDisabledState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Lyrics Disabled',
              style: AppTheme.titleLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable lyrics in settings',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLyricsState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 48,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Lyrics Available',
                style: AppTheme.titleLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lyrics will appear here when available',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsView(AdvancedLyricsSyncService lyricsService) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header with sync status
            _buildHeader(lyricsService),
            
            // Lyrics content
            Expanded(
              child: _buildLyricsContent(lyricsService),
            ),
            
            // Controls
            _buildControls(lyricsService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AdvancedLyricsSyncService lyricsService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            lyricsService.isPlaying ? Icons.sync : Icons.pause_circle_outline,
            color: lyricsService.isPlaying ? AppTheme.accentColor : Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            lyricsService.isPlaying ? 'Syncing...' : 'Paused',
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (lyricsService.currentLineIndex >= 0)
            Text(
              '${lyricsService.currentLineIndex + 1} / ${lyricsService.allLines.length}',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(AdvancedLyricsSyncService lyricsService) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      itemCount: lyricsService.allLines.length,
      itemBuilder: (context, index) {
        final line = lyricsService.allLines[index];
        final isCurrent = index == lyricsService.currentLineIndex;
        final isPrevious = index < lyricsService.currentLineIndex;
        final isNext = index > lyricsService.currentLineIndex;
        
        return _buildLyricsLine(
          line,
          isCurrent: isCurrent,
          isPrevious: isPrevious,
          isNext: isNext,
          showTimestamp: widget.showTimestamps,
          fontSize: lyricsService.fontSize,
        );
      },
    );
  }

  Widget _buildLyricsLine(
    LrcLine line, {
    required bool isCurrent,
    required bool isPrevious,
    required bool isNext,
    required bool showTimestamp,
    required double fontSize,
  }) {
    Color textColor;
    FontWeight fontWeight;
    double opacity;
    
    if (isCurrent) {
      textColor = AppTheme.accentColor;
      fontWeight = FontWeight.bold;
      opacity = 1.0;
    } else if (isPrevious) {
      textColor = Colors.white;
      fontWeight = FontWeight.normal;
      opacity = 0.6;
    } else {
      textColor = Colors.white;
      fontWeight = FontWeight.normal;
      opacity = 0.4;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isCurrent 
            ? AppTheme.accentColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrent 
            ? Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTimestamp) ...[
            SizedBox(
              width: 60,
              child: Text(
                _formatTimestamp(line.timestamp),
                style: TextStyle(
                  color: textColor.withValues(alpha: opacity * 0.7),
                  fontSize: fontSize * 0.8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: textColor.withValues(alpha: opacity),
                fontSize: fontSize,
                fontWeight: fontWeight,
                height: 1.4,
              ),
              child: Text(
                line.lyrics.isEmpty ? '♪' : line.lyrics,
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AdvancedLyricsSyncService lyricsService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Sync offset control
          Flexible(
            child: Text(
              'Sync: ${lyricsService.syncOffset.round()}ms',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                lyricsService.setSyncOffset(lyricsService.syncOffset - 100);
              },
              icon: Icon(
                Icons.fast_rewind,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                lyricsService.setSyncOffset(lyricsService.syncOffset + 100);
              },
              icon: Icon(
                Icons.fast_forward,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ),
          ),
          const Spacer(),
          // Font size control
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                lyricsService.setFontSize(lyricsService.fontSize - 1);
              },
              icon: Icon(
                Icons.text_decrease,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                lyricsService.setFontSize(lyricsService.fontSize + 1);
              },
              icon: Icon(
                Icons.text_increase,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Duration timestamp) {
    final minutes = timestamp.inMinutes;
    final seconds = timestamp.inSeconds % 60;
    final milliseconds = (timestamp.inMilliseconds % 1000) ~/ 10;
    
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}.'
           '${milliseconds.toString().padLeft(2, '0')}';
  }
}
