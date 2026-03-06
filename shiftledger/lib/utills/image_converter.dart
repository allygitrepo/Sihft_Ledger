import 'dart:convert';
import 'dart:typed_data';

class ImageConverter {
  /// Converts [Uint8List] bytes to a Base64 data URL string.
  /// [extension] should be the file extension (e.g., 'png', 'jpg', 'jpeg').
  static String toBase64(Uint8List bytes, String extension) {
    final mimeType = _getMimeType(extension);
    final base64String = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64String';
  }

  /// Decodes a Base64 data URL string back to [Uint8List] bytes.
  static Uint8List? fromBase64(String? base64String) {
    if (base64String == null || !base64String.contains(',')) return null;
    try {
      final base64Data = base64String.split(',').last;
      return base64Decode(base64Data);
    } catch (e) {
      return null;
    }
  }

  /// Helper to get the MIME type from a file extension.
  static String _getMimeType(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext == 'jpg' || ext == 'jpeg') {
      return 'image/jpeg';
    } else if (ext == 'webp') {
      return 'image/webp';
    } else {
      return 'image/png';
    }
  }
}
