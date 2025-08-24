import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lyrics_service.dart';

class LyricsDisplay extends StatefulWidget {
  final double currentTime;
  final bool isPlaying;
  final VoidCallback? onToggleLyrics;

  const LyricsDisplay({
    super.key,
    required this.currentTime,
    required this.isPlaying,
    this.onToggleLyrics,
  });

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _lastScrolledLineIndex = -1; // Track the last line we scrolled to
  double _lastScrollTime = -1; // Track when we last scrolled

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LyricsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update lyrics sync when time changes
    if (widget.currentTime != oldWidget.currentTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final lyricsService = context.read<LyricsService>();
        lyricsService.updateCurrentTime(widget.currentTime);
        
        // Timestamp-based scrolling: only scroll when we hit a new timestamp
        if (lyricsService.autoScroll && lyricsService.currentLineIndex >= 0) {
          _handleTimestampBasedScrolling(lyricsService);
        }
      });
    }
  }

  void _handleTimestampBasedScrolling(LyricsService lyricsService) {
    final currentLineIndex = lyricsService.currentLineIndex;
    final currentTime = widget.currentTime;
    
    // Only scroll if:
    // 1. We're on a new line that we haven't scrolled to yet
    // 2. Enough time has passed since the last scroll (prevent rapid scrolling)
    // 3. For synced lyrics, scroll exactly when timestamp is reached
    if (currentLineIndex != _lastScrolledLineIndex && 
        (currentTime - _lastScrollTime) > 0.5) { // Minimum 500ms between scrolls
      
      if (lyricsService.currentLyrics?.isTimeSynced == true) {
        // For synced lyrics, check if we're at the exact timestamp
        final currentLine = lyricsService.currentLyrics!.lines[currentLineIndex];
        final timeDiff = (currentTime - currentLine.timestamp).abs();
        
        // Only scroll if we're very close to the timestamp (within 200ms)
        if (timeDiff <= 0.2) {
          _scrollToCurrentLine(currentLineIndex);
          _lastScrolledLineIndex = currentLineIndex;
          _lastScrollTime = currentTime;
        }
      } else {
        // For estimated lyrics, use the regular auto-scroll behavior
        _scrollToCurrentLine(currentLineIndex);
        _lastScrolledLineIndex = currentLineIndex;
        _lastScrollTime = currentTime;
      }
    }
  }

  void _scrollToCurrentLine(int lineIndex) {
    if (_scrollController.hasClients) {
      const lineHeight = 60.0; // Approximate height per line
      final targetOffset = lineIndex * lineHeight - 
          (MediaQuery.of(context).size.height * 0.4); // Center on screen
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatTimestamp(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LyricsService>(
      builder: (context, lyricsService, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(lyricsService),
              Expanded(
                child: _buildLyricsContent(lyricsService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(LyricsService lyricsService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lyrics,
            color: const Color(0xFF00C896),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lyrics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (lyricsService.currentLyrics != null)
                  Text(
                    'Source: ${lyricsService.currentLyrics!.source}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          _buildSettingsButton(lyricsService),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(LyricsService lyricsService) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.white70,
      ),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) => _handleSettingsAction(value, lyricsService),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'font_size',
          child: Row(
            children: [
              Icon(Icons.text_fields, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Text(
                'Font Size',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'auto_scroll',
          child: Row(
            children: [
              Icon(
                lyricsService.autoScroll 
                    ? Icons.check_box 
                    : Icons.check_box_outline_blank,
                color: lyricsService.autoScroll 
                    ? const Color(0xFF00C896) 
                    : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Auto Scroll',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'timestamps',
          child: Row(
            children: [
              Icon(
                lyricsService.showTimestamps 
                    ? Icons.check_box 
                    : Icons.check_box_outline_blank,
                color: lyricsService.showTimestamps 
                    ? const Color(0xFF00C896) 
                    : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Show Timestamps',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'highlight_chorus',
          child: Row(
            children: [
              Icon(
                lyricsService.highlightChorus 
                    ? Icons.check_box 
                    : Icons.check_box_outline_blank,
                color: lyricsService.highlightChorus 
                    ? const Color(0xFF00C896) 
                    : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Highlight Chorus',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleSettingsAction(String action, LyricsService lyricsService) {
    switch (action) {
      case 'font_size':
        _showFontSizeDialog(lyricsService);
        break;
      case 'auto_scroll':
        lyricsService.setAutoScroll(!lyricsService.autoScroll);
        break;
      case 'timestamps':
        lyricsService.setShowTimestamps(!lyricsService.showTimestamps);
        break;
      case 'highlight_chorus':
        lyricsService.setHighlightChorus(!lyricsService.highlightChorus);
        break;
    }
  }

  void _showFontSizeDialog(LyricsService lyricsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Font Size',
          style: TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sample lyrics text',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: lyricsService.fontSize,
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: lyricsService.fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                activeColor: const Color(0xFF00C896),
                onChanged: (value) {
                  setState(() {});
                  lyricsService.setFontSize(value);
                },
              ),
              Text(
                '${lyricsService.fontSize.round()}pt',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: TextStyle(color: const Color(0xFF00C896)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(LyricsService lyricsService) {
    if (lyricsService.isLoading) {
      return _buildLoadingState();
    }

    if (lyricsService.error != null) {
      return _buildErrorState(lyricsService.error!);
    }

    if (lyricsService.currentLyrics == null) {
      return _buildEmptyState();
    }

    return _buildLyricsList(lyricsService);
  }

  Widget _buildLoadingState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF00C896),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fetching lyrics...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Lyrics not available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              color: Colors.white30,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No lyrics available',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy the music!',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsList(LyricsService lyricsService) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: lyricsService.currentLyrics!.lines.length,
          itemBuilder: (context, index) {
            final line = lyricsService.currentLyrics!.lines[index];
            final isCurrentLine = index == lyricsService.currentLineIndex;
            final isPastLine = index < lyricsService.currentLineIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentLine 
                    ? const Color(0xFF00C896).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isCurrentLine 
                    ? Border.all(
                        color: const Color(0xFF00C896).withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: _buildLyricsLine(line, isCurrentLine, isPastLine, lyricsService),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLyricsLine(
    LyricsLine line,
    bool isCurrentLine,
    bool isPastLine,
    LyricsService lyricsService,
  ) {
    Color textColor;
    if (isCurrentLine) {
      textColor = const Color(0xFF00C896);
    } else if (isPastLine) {
      textColor = Colors.white54;
    } else {
      textColor = Colors.white70;
    }

    // Special styling for chorus and verse
    if (lyricsService.highlightChorus && line.isChorus && !isCurrentLine) {
      textColor = const Color(0xFF00C896).withValues(alpha: 0.7);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lyricsService.showTimestamps) ...[
          SizedBox(
            width: 50,
            child: Text(
              _formatTimestamp(line.timestamp),
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: textColor,
              fontSize: lyricsService.fontSize,
              fontWeight: isCurrentLine ? FontWeight.w600 : FontWeight.normal,
              height: 1.4,
            ),
            child: Text(
              line.text,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (line.isChorus && lyricsService.highlightChorus)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Chorus',
              style: TextStyle(
                color: const Color(0xFF00C896),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
