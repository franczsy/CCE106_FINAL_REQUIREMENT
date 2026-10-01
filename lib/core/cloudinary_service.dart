import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'cloudinary_config.dart';

class CloudinaryService {
  static Future<String?> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String? folder,
  }) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/auto/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..fields['folder'] = folder ?? cloudinaryFolder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.isNotEmpty ? fileName : 'upload.jpg',
        ),
      );

    try {
      final response = await request.send().timeout(const Duration(seconds: 30));
      final body = await response.stream.bytesToString();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return (decoded['secure_url'] ?? decoded['url']) as String?;
    } catch (_) {
      return null;
    }
  }
}
