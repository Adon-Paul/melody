import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/advanced_lyrics_sync_service.dart';
import '../../core/theme/app_theme.dart';

class LyricsSettingsDialog extends StatefulWidget {
  const LyricsSettingsDialog({super.key});

  @override
  State<LyricsSettingsDialog> createState() => _LyricsSettingsDialogState();
}

class _LyricsSettingsDialogState extends State<LyricsSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AdvancedLyricsSyncService>(
      builder: (context, lyricsService, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.95),
                  AppTheme.accentColor.withValues(alpha: 0.9),
                  AppTheme.primaryColor.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lyrics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Lyrics Sync Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auto-scroll setting
                        _buildSettingCard(
                          icon: Icons.auto_awesome_motion,
                          title: 'Auto-scroll',
                          subtitle: 'Automatically scroll to current line',
                          child: Switch(
                            value: lyricsService.autoScroll,
                            onChanged: (value) => lyricsService.setAutoScroll(value),
                            activeColor: AppTheme.accentColor,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Font size setting
                        _buildSettingCard(
                          icon: Icons.format_size,
                          title: 'Font Size',
                          subtitle: 'Adjust lyrics text size',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Size: \${lyricsService.fontSize.toInt()}px',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sample Text',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: lyricsService.fontSize,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: lyricsService.fontSize,
                                min: 12.0,
                                max: 24.0,
                                divisions: 12,
                                activeColor: AppTheme.accentColor,
                                inactiveColor: Colors.white.withValues(alpha: 0.3),
                                onChanged: (value) => lyricsService.setFontSize(value),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sync offset setting
                        _buildSettingCard(
                          icon: Icons.sync,
                          title: 'Sync Offset',
                          subtitle: 'Fine-tune lyrics timing (milliseconds)',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Offset: \${lyricsService.syncOffset.toInt()}ms',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => lyricsService.setSyncOffset(
                                      lyricsService.syncOffset - 500,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('-500ms'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => lyricsService.setSyncOffset(0),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentColor.withValues(alpha: 0.3),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Reset'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => lyricsService.setSyncOffset(
                                      lyricsService.syncOffset + 500,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('+500ms'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Status info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    lyricsService.hasLyrics ? Icons.check_circle : Icons.info,
                                    color: lyricsService.hasLyrics ? Colors.green : Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    lyricsService.hasLyrics ? 'Lyrics Loaded' : 'No Lyrics',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (lyricsService.hasLyrics) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Lines: \${lyricsService.allLines.length}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Source: LRCLIB (Word-perfect sync)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
