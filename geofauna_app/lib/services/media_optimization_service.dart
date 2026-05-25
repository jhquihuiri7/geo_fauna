import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

enum MediaUploadType { image, video }

class PreparedMediaUpload {
  const PreparedMediaUpload({
    required this.type,
    required this.primaryFile,
    required this.primaryFileName,
    required this.primaryContentType,
    required this.originalSizeBytes,
    required this.primarySizeBytes,
    required this.optimized,
    this.thumbnailFile,
    this.thumbnailFileName,
    this.thumbnailSizeBytes,
    this.width,
    this.height,
    this.durationMs,
  });

  final MediaUploadType type;
  final File primaryFile;
  final String primaryFileName;
  final String primaryContentType;
  final int originalSizeBytes;
  final int primarySizeBytes;
  final bool optimized;
  final File? thumbnailFile;
  final String? thumbnailFileName;
  final int? thumbnailSizeBytes;
  final int? width;
  final int? height;
  final double? durationMs;
}

class MediaOptimizationService {
  const MediaOptimizationService();

  static const int imageDisplayMaxSide = 1600;
  static const int imageDisplayQuality = 82;
  static const int imageThumbMaxSide = 480;
  static const int imageThumbQuality = 72;
  static const int videoFrameRate = 30;

  Future<PreparedMediaUpload> prepare({
    required XFile file,
    required MediaUploadType type,
    required int index,
  }) {
    return switch (type) {
      MediaUploadType.image => _prepareImage(file, index),
      MediaUploadType.video => _prepareVideo(file, index),
    };
  }

  Future<PreparedMediaUpload> _prepareImage(XFile source, int index) async {
    final original = File(source.path);
    final originalSize = await original.length();
    final baseName = _safeBaseName(source, index);
    final tempRoot = Directory.systemTemp.path;

    final displayPath =
        '$tempRoot${Platform.pathSeparator}${baseName}_display.jpg';
    final thumbPath = '$tempRoot${Platform.pathSeparator}${baseName}_thumb.jpg';

    XFile? display;
    XFile? thumb;
    try {
      display = await FlutterImageCompress.compressAndGetFile(
        source.path,
        displayPath,
        minWidth: imageDisplayMaxSide,
        minHeight: imageDisplayMaxSide,
        quality: imageDisplayQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
    } catch (_) {
      display = null;
    }
    try {
      thumb = await FlutterImageCompress.compressAndGetFile(
        source.path,
        thumbPath,
        minWidth: imageThumbMaxSide,
        minHeight: imageThumbMaxSide,
        quality: imageThumbQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
    } catch (_) {
      thumb = null;
    }

    var primary = original;
    var primaryContentType = _imageContentType(source.path);
    var primaryFileName =
        '$baseName${_uploadExtension(source.path, primaryContentType)}';
    var optimized = false;
    if (display != null) {
      final compressed = File(display.path);
      final compressedSize = await compressed.length();
      final shouldUseCompressed =
          compressedSize < originalSize || !_isWebFriendlyImage(source.path);
      if (shouldUseCompressed) {
        primary = compressed;
        primaryFileName = '${baseName}_display.jpg';
        primaryContentType = 'image/jpeg';
        optimized = true;
      }
    }
    final primarySize = await primary.length();
    final thumbnail = thumb == null ? null : File(thumb.path);
    final thumbnailSize = thumbnail == null ? null : await thumbnail.length();

    return PreparedMediaUpload(
      type: MediaUploadType.image,
      primaryFile: primary,
      primaryFileName: primaryFileName,
      primaryContentType: primaryContentType,
      originalSizeBytes: originalSize,
      primarySizeBytes: primarySize,
      optimized: optimized,
      thumbnailFile: thumbnail,
      thumbnailFileName: thumbnail == null ? null : '${baseName}_thumb.jpg',
      thumbnailSizeBytes: thumbnailSize,
    );
  }

  Future<PreparedMediaUpload> _prepareVideo(XFile source, int index) async {
    final original = File(source.path);
    final originalSize = await original.length();
    final baseName = _safeBaseName(source, index);

    File primary = original;
    var primaryContentType = _videoContentType(source.path);
    var optimized = false;
    int? width;
    int? height;
    double? durationMs;

    try {
      final mediaInfo = await VideoCompress.compressVideo(
        source.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: videoFrameRate,
      );
      final compressed = mediaInfo?.file;
      if (compressed != null && await compressed.exists()) {
        final compressedSize = await compressed.length();
        if (compressedSize < originalSize || !_isMp4Video(source.path)) {
          primary = compressed;
          primaryContentType = 'video/mp4';
          optimized = true;
          width = mediaInfo?.width;
          height = mediaInfo?.height;
          durationMs = mediaInfo?.duration;
        }
      }
    } catch (_) {
      try {
        VideoCompress.dispose();
      } catch (_) {}
      // Unsupported platform or codec: keep the original so the save continues.
    }

    try {
      final info = await VideoCompress.getMediaInfo(primary.path);
      width ??= info.width;
      height ??= info.height;
      durationMs ??= info.duration;
    } catch (_) {
      // Metadata is optional.
    }

    File? thumbnail;
    int? thumbnailSize;
    try {
      thumbnail = await VideoCompress.getFileThumbnail(
        primary.path,
        quality: 78,
        position: 1000,
      );
      if (!await thumbnail.exists()) thumbnail = null;
      thumbnailSize = thumbnail == null ? null : await thumbnail.length();
    } catch (_) {
      thumbnail = null;
    }

    final primarySize = await primary.length();
    final primaryFileName = optimized
        ? '${baseName}_video.mp4'
        : '$baseName${_uploadExtension(source.path, primaryContentType)}';
    return PreparedMediaUpload(
      type: MediaUploadType.video,
      primaryFile: primary,
      primaryFileName: primaryFileName,
      primaryContentType: primaryContentType,
      originalSizeBytes: originalSize,
      primarySizeBytes: primarySize,
      optimized: optimized,
      thumbnailFile: thumbnail,
      thumbnailFileName: thumbnail == null ? null : '${baseName}_poster.jpg',
      thumbnailSizeBytes: thumbnailSize,
      width: width,
      height: height,
      durationMs: durationMs,
    );
  }
}

bool _isWebFriendlyImage(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
}

bool _isMp4Video(String path) => path.toLowerCase().endsWith('.mp4');

String _sourceExtension(String path) {
  final fileName = path.split(Platform.pathSeparator).last;
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '.bin';
  return fileName.substring(dot).toLowerCase();
}

String _uploadExtension(String path, String contentType) {
  final sourceExtension = _sourceExtension(path);
  if (sourceExtension != '.bin') return sourceExtension;
  return switch (contentType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    'image/gif' => '.gif',
    'image/heic' => '.heic',
    'image/heif' => '.heif',
    'video/quicktime' => '.mov',
    'video/webm' => '.webm',
    'video/mp4' => '.mp4',
    _ => '.jpg',
  };
}

String _imageContentType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.heif')) return 'image/heif';
  return 'image/jpeg';
}

String _safeBaseName(XFile file, int index) {
  final rawName = file.name.trim().isNotEmpty
      ? file.name.trim()
      : file.path.split(Platform.pathSeparator).last;
  final withoutExtension = rawName.contains('.')
      ? rawName.substring(0, rawName.lastIndexOf('.'))
      : rawName;
  final cleaned = withoutExtension.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final prefix = DateTime.now().millisecondsSinceEpoch;
  return '${prefix}_${index}_${cleaned.isEmpty ? 'media' : cleaned}';
}

String _videoContentType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.webm')) return 'video/webm';
  return 'video/mp4';
}
