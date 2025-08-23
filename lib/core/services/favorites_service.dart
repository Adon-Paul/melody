import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'music_service.dart';

class FavoritesService extends ChangeNotifier {
  final List<Song> _favorites = [];
  SharedPreferences? _prefs;

  List<Song> get favorites => List.unmodifiable(_favorites);

  FavoritesService() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favoritesJson = _prefs?.getStringList('favorites') ?? [];
      _favorites.clear();
      
      for (final jsonString in favoritesJson) {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final song = Song(
          id: jsonMap['id'] as String,
          title: jsonMap['title'] as String,
          artist: jsonMap['artist'] as String,
          path: jsonMap['path'] as String,
          duration: jsonMap['duration'] != null 
              ? Duration(milliseconds: jsonMap['duration'] as int)
              : null,
          albumArt: jsonMap['albumArt'] != null 
              ? base64Decode(jsonMap['albumArt'] as String)
              : null,
        );
        _favorites.add(song);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final favoritesJson = _favorites.map((song) {
        return jsonEncode({
          'id': song.id,
          'title': song.title,
          'artist': song.artist,
          'path': song.path,
          'duration': song.duration?.inMilliseconds,
          'albumArt': song.albumArt != null ? base64Encode(song.albumArt!) : null,
        });
      }).toList();
      
      await _prefs?.setStringList('favorites', favoritesJson);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  bool isFavorite(String songId) {
    return _favorites.any((song) => song.id == songId);
  }

  Future<void> addFavorite(Song song) async {
    if (!isFavorite(song.id)) {
      _favorites.add(song);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String songId) async {
    _favorites.removeWhere((song) => song.id == songId);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(Song song) async {
    if (isFavorite(song.id)) {
      await removeFavorite(song.id);
    } else {
      await addFavorite(song);
    }
  }

  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveFavorites();
    notifyListeners();
  }
}
