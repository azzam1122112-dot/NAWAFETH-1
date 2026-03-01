library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Optimizes media before multipart upload.
///
/// - Images: compressed and resized when helpful.
/// - Non-image files: returned as-is.
class UploadOptimizer {
  static const int _minCompressibleBytes = 250 * 1024; // 250 KB
  static const int _targetImageBytes = 900 * 1024; // ~900 KB
  static const int _initialQuality = 82;
  static const int _minQuality = 58;
  static const int _maxAttempts = 3;
  static const int _maxWidth = 1920;
  static const int _maxHeight = 1920;

  static final Random _rng = Random();

  static const Set<String> _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
  };

  static bool isImagePath(String path) {
    final ext = _extension(path);
    return _imageExtensions.contains(ext);
  }

  static Future<File> optimizeForUpload(
    File source, {
    String? declaredType,
  }) async {
    final type = (declaredType ?? '').trim().toLowerCase();
    final mustTreatAsImage = type == 'image';
    if (!mustTreatAsImage && !isImagePath(source.path)) {
      return source;
    }
    return optimizeImage(source);
  }

  static Future<File> optimizeImage(File source) async {
    int originalBytes;
    try {
      originalBytes = await source.length();
    } catch (_) {
      return source;
    }

    if (originalBytes <= _minCompressibleBytes) {
      return source;
    }

    final ext = _extension(source.path);
    final format = _formatForExt(ext);
    final targetExt = _targetExtForFormat(format);

    File? bestCandidate;
    var bestBytes = originalBytes;
    var quality = _initialQuality;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final candidate = await _compressOnce(
        source: source,
        quality: quality,
        format: format,
        extension: targetExt,
      );
      if (candidate == null) break;

      int candidateBytes;
      try {
        candidateBytes = await candidate.length();
      } catch (_) {
        continue;
      }

      if (candidateBytes < bestBytes) {
        bestBytes = candidateBytes;
        bestCandidate = candidate;
      }

      if (candidateBytes <= _targetImageBytes) {
        break;
      }

      quality = max(_minQuality, quality - 12);
      if (quality <= _minQuality) {
        break;
      }
    }

    return bestCandidate ?? source;
  }

  static Future<File?> _compressOnce({
    required File source,
    required int quality,
    required CompressFormat format,
    required String extension,
  }) async {
    try {
      final targetPath = _newTempPath(extension);
      final result = await FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        quality: quality,
        minWidth: _maxWidth,
        minHeight: _maxHeight,
        format: format,
        keepExif: true,
      );
      if (result == null) return null;
      return File(result.path);
    } catch (_) {
      return null;
    }
  }

  static String _newTempPath(String extension) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final salt = _rng.nextInt(1 << 20);
    return '${Directory.systemTemp.path}${Platform.pathSeparator}nawafeth_upload_${stamp}_$salt$extension';
  }

  static String _extension(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    final slash = normalized.lastIndexOf('/');
    final dot = normalized.lastIndexOf('.');
    if (dot == -1 || dot < slash) return '';
    return normalized.substring(dot);
  }

  static CompressFormat _formatForExt(String ext) {
    switch (ext) {
      case '.png':
        return CompressFormat.png;
      case '.webp':
        return CompressFormat.webp;
      default:
        return CompressFormat.jpeg;
    }
  }

  static String _targetExtForFormat(CompressFormat format) {
    switch (format) {
      case CompressFormat.png:
        return '.png';
      case CompressFormat.webp:
        return '.webp';
      default:
        return '.jpg';
    }
  }
}
