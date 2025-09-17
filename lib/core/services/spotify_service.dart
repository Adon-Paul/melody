import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/spotify_config.dart';
import 'spotify_auth_service.dart';

class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String? albumArt;
  final int durationMs;
  final String? previewUrl;
  final bool isPlayable;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    this.albumArt,
    required this.durationMs,
    this.previewUrl,
    this.isPlayable = false,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final artists = (json['artists'] as List?)
        ?.map((a) => a['name'] as String)
        .join(', ') ?? 'Unknown Artist';
    
    final images = json['album']?['images'] as List?;
    String? albumArt;
    if (images != null && images.isNotEmpty) {
      albumArt = images.first['url'];
    }

    return SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Track',
      artist: artists,
      album: json['album']?['name'] ?? 'Unknown Album',
      albumArt: albumArt,
      durationMs: json['duration_ms'] ?? 0,
      previewUrl: json['preview_url'],
      isPlayable: json['is_playable'] ?? false,
    );
  }

  Duration get duration => Duration(milliseconds: durationMs);
}

class SpotifyPlaylist {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int trackCount;
  final bool isPublic;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.trackCount,
    this.isPublic = false,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      imageUrl = images.first['url'];
    }

    return SpotifyPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled Playlist',
      description: json['description'],
      imageUrl: imageUrl,
      trackCount: json['tracks']?['total'] ?? 0,
      isPublic: json['public'] ?? false,
    );
  }
}

class SpotifyService extends ChangeNotifier {
  final SpotifyAuthService _authService;
  
  SpotifyService(this._authService);

  // Get user's profile information
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Get user profile failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  // Search for tracks
  Future<List<SpotifyTrack>> searchTracks(String query, {int limit = 20}) async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return [];

      final encodedQuery = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/search?q=$encodedQuery&type=track&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['items'] as List;
        return tracks.map((track) => SpotifyTrack.fromJson(track)).toList();
      } else {
        debugPrint('Search tracks failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Search tracks error: $e');
      return [];
    }
  }

  // Get user's playlists
  Future<List<SpotifyPlaylist>> getUserPlaylists({int limit = 50}) async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/me/playlists?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlists = data['items'] as List;
        return playlists.map((playlist) => SpotifyPlaylist.fromJson(playlist)).toList();
      } else {
        debugPrint('Get user playlists failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Get user playlists error: $e');
      return [];
    }
  }

  // Get playlist tracks
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId, {int limit = 100}) async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/playlists/$playlistId/tracks?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        return items
            .where((item) => item['track'] != null)
            .map((item) => SpotifyTrack.fromJson(item['track']))
            .toList();
      } else {
        debugPrint('Get playlist tracks failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Get playlist tracks error: $e');
      return [];
    }
  }

  // Get user's saved tracks (liked songs)
  Future<List<SpotifyTrack>> getSavedTracks({int limit = 50}) async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/me/tracks?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        return items
            .where((item) => item['track'] != null)
            .map((item) => SpotifyTrack.fromJson(item['track']))
            .toList();
      } else {
        debugPrint('Get saved tracks failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Get saved tracks error: $e');
      return [];
    }
  }

  // Get currently playing track
  Future<SpotifyTrack?> getCurrentlyPlaying() async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/me/player/currently-playing'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['item'] != null) {
          return SpotifyTrack.fromJson(data['item']);
        }
      } else if (response.statusCode != 204) {
        debugPrint('Get currently playing failed: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('Get currently playing error: $e');
      return null;
    }
  }

  // Get top tracks
  Future<List<SpotifyTrack>> getTopTracks({int limit = 20, String timeRange = 'medium_term'}) async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/me/top/tracks?limit=$limit&time_range=$timeRange'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['items'] as List;
        return tracks.map((track) => SpotifyTrack.fromJson(track)).toList();
      } else {
        debugPrint('Get top tracks failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Get top tracks error: $e');
      return [];
    }
  }

  // Add track to saved tracks
  Future<bool> saveTrack(String trackId) async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/me/tracks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'ids': [trackId]}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Save track error: $e');
      return false;
    }
  }

  // Remove track from saved tracks
  Future<bool> unsaveTrack(String trackId) async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/me/tracks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'ids': [trackId]}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Unsave track error: $e');
      return false;
    }
  }

  // Check if tracks are saved
  Future<List<bool>> checkSavedTracks(List<String> trackIds) async {
    try {
      final token = await _authService.getValidAccessToken();
      if (token == null) return List.filled(trackIds.length, false);

      final idsParam = trackIds.join(',');
      final response = await http.get(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/me/tracks/contains?ids=$idsParam'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((saved) => saved as bool).toList();
      } else {
        debugPrint('Check saved tracks failed: ${response.statusCode}');
        return List.filled(trackIds.length, false);
      }
    } catch (e) {
      debugPrint('Check saved tracks error: $e');
      return List.filled(trackIds.length, false);
    }
  }
}
