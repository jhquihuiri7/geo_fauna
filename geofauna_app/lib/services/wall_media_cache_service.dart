import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class WallMediaCacheService {
  WallMediaCacheService._()
    : _manager = CacheManager(
        Config(
          'wall_media_cache_v1',
          stalePeriod: const Duration(days: 21),
          maxNrOfCacheObjects: 160,
        ),
      );

  static final instance = WallMediaCacheService._();

  final CacheManager _manager;
  final Set<String> _warming = <String>{};
  final Set<String> _warmed = <String>{};

  Future<File> getFile(String url) {
    return _manager.getSingleFile(url);
  }

  Stream<FileResponse> fileStream(String url) {
    return _manager.getFileStream(url, withProgress: true);
  }

  void warm(Iterable<String?> urls) {
    for (final url in urls) {
      final cleanUrl = url?.trim();
      if (cleanUrl == null || cleanUrl.isEmpty) continue;
      if (_warmed.contains(cleanUrl) || _warming.contains(cleanUrl)) continue;

      _warming.add(cleanUrl);
      unawaited(_warmOne(cleanUrl));
    }
  }

  Future<void> _warmOne(String url) async {
    try {
      await _manager.downloadFile(url);
      _warmed.add(url);
    } catch (_) {
      // Cache warmup is best-effort; the visible widget can still retry later.
    } finally {
      _warming.remove(url);
    }
  }
}
