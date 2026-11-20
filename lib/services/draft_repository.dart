import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraftRepository {
  static const String draftKey = 'course_device_draft_v1';
  static const int maxPhotoBytes = 5 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png'};

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<Map<String, dynamic>?> load() async {
    final json = await _preferences.getString(draftKey);
    if (json == null) return null;

    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Format draft perangkat tidak valid.');
    }
    return decoded;
  }

  Future<void> save(Map<String, dynamic> draft) {
    return _preferences.setString(draftKey, jsonEncode(draft));
  }

  Future<String> savePermanentPhoto(XFile selected) async {
    final extension = _extensionOf(selected.name);
    if (!_allowedExtensions.contains(extension)) {
      throw const FormatException('Foto harus berformat JPG, JPEG, atau PNG.');
    }

    final size = await selected.length();
    if (size > maxPhotoBytes) {
      throw const FormatException('Ukuran foto maksimal 5 MB.');
    }
    if (size == 0) {
      throw const FormatException('File foto kosong atau tidak dapat dibaca.');
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final photoDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}course_photos',
    );
    await photoDirectory.create(recursive: true);

    final fileName =
        'photo_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final destination = File(
      '${photoDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await File(selected.path).copy(destination.path);
    return destination.path;
  }

  String _extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }
}
