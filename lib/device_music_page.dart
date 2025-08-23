import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DeviceMusicPage extends StatefulWidget {
  const DeviceMusicPage({super.key});

  @override
  State<DeviceMusicPage> createState() => _DeviceMusicPageState();
}

class _DeviceMusicPageState extends State<DeviceMusicPage> {
  List<FileSystemEntity> _musicFiles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMusicFiles();
  }

  Future<void> _loadMusicFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (Platform.isAndroid) {
        bool permissionGranted = false;
        // Check Android version using device_info_plus
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        if (sdkInt >= 30) {
          // Android 11+ (API 30+): MANAGE_EXTERNAL_STORAGE
          final status = await Permission.manageExternalStorage.request();
          if (status.isGranted) {
            permissionGranted = true;
          } else if (status.isPermanentlyDenied) {
            setState(() {
              _error = 'Storage permission permanently denied. Please enable it in app settings.';
              _loading = false;
            });
            await openAppSettings();
            return;
          } else {
            setState(() {
              _error = 'Storage permission denied.';
              _loading = false;
            });
            return;
          }
        } else {
          // Android 10 and below: STORAGE
          final status = await Permission.storage.request();
          if (status.isGranted) {
            permissionGranted = true;
          } else if (status.isPermanentlyDenied) {
            setState(() {
              _error = 'Storage permission permanently denied. Please enable it in app settings.';
              _loading = false;
            });
            await openAppSettings();
            return;
          } else {
            setState(() {
              _error = 'Storage permission denied.';
              _loading = false;
            });
            return;
          }
        }
        if (!permissionGranted) return;
        // Scan all available external storage directories and the standard Music directory for music files
        List<FileSystemEntity> allMusicFiles = [];
        try {
          final dirs = await getExternalStorageDirectories();
          if (dirs != null && dirs.isNotEmpty) {
            for (final dir in dirs) {
              if (dir.existsSync()) {
                final files = dir
                    .listSync(recursive: true)
                    .where((f) => f is File && (f.path.endsWith('.mp3') || f.path.endsWith('.wav') || f.path.endsWith('.flac')))
                    .toList();
                allMusicFiles.addAll(files);
              }
            }
          }
          // Explicitly add the standard Music directory
          final musicDir = Directory('/storage/emulated/0/Music');
          if (musicDir.existsSync()) {
            final files = musicDir
                .listSync(recursive: true)
                .where((f) => f is File && (f.path.endsWith('.mp3') || f.path.endsWith('.wav') || f.path.endsWith('.flac')))
                .toList();
            allMusicFiles.addAll(files);
          }
        } catch (_) {}
        setState(() {
          _musicFiles = allMusicFiles;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Music scan only implemented for Android.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Music'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF181818),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _musicFiles.isEmpty
                  ? const Center(child: Text('No music files found.', style: TextStyle(color: Colors.white70)))
                  : ListView.separated(
                      itemCount: _musicFiles.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, i) {
                        final file = _musicFiles[i];
                        final name = file.path.split(Platform.pathSeparator).last;
                        return ListTile(
                          leading: const Icon(Icons.music_note, color: Colors.green),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(file.path, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          onTap: () {},
                        );
                      },
                    ),
    );
  }
}
