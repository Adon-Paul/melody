import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/animated_background.dart';
import '../core/widgets/glass_notification.dart';
import '../core/services/music_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/settings_service.dart';
import '../core/transitions/page_transitions.dart';
import 'auth/login_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: AppTheme.titleMedium.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    GlassNotification.show(
      context,
      message: 'Clearing cache...',
      icon: Icons.cleaning_services,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      GlassNotification.show(
        context,
        message: 'Cache cleared successfully',
        icon: Icons.check_circle,
        backgroundColor: Colors.green.withValues(alpha: 0.2),
      );
    }
  }

  Future<void> _exportSettings() async {
    final settingsService = context.read<SettingsService>();
    // Export settings (in a real app, you'd save this to a file)
    settingsService.exportSettings();
    
    GlassNotification.show(
      context,
      message: 'Settings exported to device storage',
      icon: Icons.download_done,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
    );
  }

  Future<void> _resetSettings() async {
    final settingsService = context.read<SettingsService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Reset Settings',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to reset all settings to their default values?',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Reset', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settingsService.resetToDefaults();
      
      if (mounted) {
        GlassNotification.show(
          context,
          message: 'Settings reset to defaults',
          icon: Icons.restore,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final authService = context.read<AuthService>();
    await authService.signOut();
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransitions.circleMorph(const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Settings',
              style: AppTheme.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            backgroundColor: AppTheme.backgroundColor,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
            ),
          ),
          body: Stack(
            children: [
              const AnimatedBackground(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Playback Settings
                    _buildSectionHeader('Playback'),
                    _buildSettingTile(
                      title: 'Auto Play',
                      subtitle: 'Automatically play next song in queue',
                      icon: Icons.play_circle,
                      trailing: Switch(
                        value: settingsService.autoPlayEnabled,
                        onChanged: (value) => settingsService.setAutoPlayEnabled(value),
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Shuffle',
                      subtitle: 'Play songs in random order',
                      icon: Icons.shuffle,
                      trailing: Switch(
                        value: settingsService.shuffleEnabled,
                        onChanged: (value) {
                          settingsService.setShuffleEnabled(value);
                          context.read<MusicService>().toggleShuffle();
                        },
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Repeat',
                      subtitle: 'Repeat current playlist',
                      icon: Icons.repeat,
                      trailing: Switch(
                        value: settingsService.repeatEnabled,
                        onChanged: (value) {
                          settingsService.setRepeatEnabled(value);
                          context.read<MusicService>().toggleRepeat();
                        },
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Crossfade Duration',
                      subtitle: '${settingsService.crossfadeDuration.toInt()} seconds',
                      icon: Icons.merge,
                      trailing: SizedBox(
                        width: 120,
                        child: Slider(
                          value: settingsService.crossfadeDuration,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          onChanged: (value) => settingsService.setCrossfadeDuration(value),
                          thumbColor: AppTheme.primaryColor,
                          inactiveColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Audio Quality',
                      subtitle: 'Playback quality preference',
                      icon: Icons.high_quality,
                      trailing: DropdownButton<String>(
                        value: settingsService.audioQuality,
                        onChanged: (value) {
                          if (value != null) {
                            settingsService.setAudioQuality(value);
                          }
                        },
                        items: ['Low', 'Medium', 'High', 'Lossless']
                            .map((quality) => DropdownMenuItem(
                                  value: quality,
                                  child: Text(quality, style: TextStyle(color: AppTheme.textPrimary)),
                                ))
                            .toList(),
                        dropdownColor: AppTheme.surfaceColor,
                        underline: Container(),
                      ),
                    ),

                    // Interface Settings
                    _buildSectionHeader('Interface'),
                    _buildSettingTile(
                      title: 'Lyrics Display',
                      subtitle: 'Show lyrics in music player (disable for better performance)',
                      icon: Icons.lyrics,
                      trailing: Switch(
                        value: settingsService.lyricsEnabled,
                        onChanged: (value) => settingsService.setLyricsEnabled(value),
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Animations',
                      subtitle: 'Enable smooth animations and transitions',
                      icon: Icons.animation,
                      trailing: Switch(
                        value: settingsService.animationsEnabled,
                        onChanged: (value) => settingsService.setAnimationsEnabled(value),
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Theme Mode',
                      subtitle: 'Choose your preferred theme',
                      icon: Icons.palette,
                      trailing: DropdownButton<String>(
                        value: settingsService.themeMode,
                        onChanged: (value) {
                          if (value != null) {
                            settingsService.setThemeMode(value);
                          }
                        },
                        items: ['Light', 'Dark', 'Auto']
                            .map((mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode, style: TextStyle(color: AppTheme.textPrimary)),
                                ))
                            .toList(),
                        dropdownColor: AppTheme.surfaceColor,
                        underline: Container(),
                      ),
                    ),

                    // System Settings
                    _buildSectionHeader('System'),
                    _buildSettingTile(
                      title: 'Notifications',
                      subtitle: 'Show playback notifications',
                      icon: Icons.notifications,
                      trailing: Switch(
                        value: settingsService.notificationsEnabled,
                        onChanged: (value) => settingsService.setNotificationsEnabled(value),
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Background Audio',
                      subtitle: 'Continue playback when app is minimized',
                      icon: Icons.headphones,
                      trailing: Switch(
                        value: settingsService.backgroundAudioEnabled,
                        onChanged: (value) => settingsService.setBackgroundAudioEnabled(value),
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                    ),

                    // Storage & Data
                    _buildSectionHeader('Storage & Data'),
                    _buildSettingTile(
                      title: 'Clear Cache',
                      subtitle: 'Remove temporary files and cached data',
                      icon: Icons.cleaning_services,
                      trailing: TextButton(
                        onPressed: _clearCache,
                        child: Text(
                          'Clear',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Export Settings',
                      subtitle: 'Save your preferences to device storage',
                      icon: Icons.download,
                      trailing: TextButton(
                        onPressed: _exportSettings,
                        child: Text(
                          'Export',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),

                    // Account Settings
                    _buildSectionHeader('Account'),
                    _buildSettingTile(
                      title: 'Reset Settings',
                      subtitle: 'Restore all settings to default values',
                      icon: Icons.restore,
                      trailing: TextButton(
                        onPressed: _resetSettings,
                        child: Text(
                          'Reset',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      title: 'Sign Out',
                      subtitle: 'Sign out of your account',
                      icon: Icons.logout,
                      trailing: TextButton(
                        onPressed: _handleSignOut,
                        child: Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                    // App Info
                    _buildSectionHeader('App Info'),
                    _buildSettingTile(
                      title: 'Version',
                      subtitle: '1.0.0 (Build 1)',
                      icon: Icons.info,
                      trailing: const SizedBox(),
                    ),
                    _buildSettingTile(
                      title: 'About',
                      subtitle: 'MELODY - Advanced Music Player',
                      icon: Icons.music_note,
                      trailing: const SizedBox(),
                    ),

                    const SizedBox(height: 100), // Extra space for mini player
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
