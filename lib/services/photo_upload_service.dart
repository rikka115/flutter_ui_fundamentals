import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoUploadResult {
  const PhotoUploadResult({required this.storagePath, required this.publicUrl});

  final String storagePath;
  final String publicUrl;
}

class PhotoUploadService {
  static const int maxPhotoBytes = 5 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png'};

  final SupabaseClient _client = Supabase.instance.client;

  Future<PhotoUploadResult> upload(File photo) async {
    final extension = _extensionOf(photo.path);
    if (!_allowedExtensions.contains(extension)) {
      throw const FormatException('Foto harus berformat JPG, JPEG, atau PNG.');
    }

    final size = await photo.length();
    if (size > maxPhotoBytes) {
      throw const FormatException('Ukuran foto maksimal 5 MB.');
    }
    if (size == 0) {
      throw const FormatException('File foto kosong atau tidak dapat dibaca.');
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Login diperlukan untuk mengunggah foto.');
    }

    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final storagePath = '$userId/$timestamp.$extension';
    final contentType = switch (extension) {
      'png' => 'image/png',
      _ => 'image/jpeg',
    };

    await _client.storage
        .from('course-photos')
        .upload(
          storagePath,
          photo,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return PhotoUploadResult(
      storagePath: storagePath,
      publicUrl: _client.storage
          .from('course-photos')
          .getPublicUrl(storagePath),
    );
  }

  String _extensionOf(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }
}
