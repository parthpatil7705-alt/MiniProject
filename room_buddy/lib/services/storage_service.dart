import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  FirebaseStorage? get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  Future<String> uploadImage(String path, File file) async {
    final storage = _storage;
    if (storage == null) {
      throw StateError(
          'Firebase Storage is not initialized; image was not uploaded.');
    }
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = storage.ref().child(path).child(fileName);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteImage(String url) async {
    try {
      await _storage?.refFromURL(url).delete();
    } catch (e) {
      // Ignore if not found or invalid URL
    }
  }

  Future<List<String>> uploadMultipleImages(
      String basePath, List<File> files) async {
    List<String> urls = [];
    for (var file in files) {
      String url = await uploadImage(basePath, file);
      urls.add(url);
    }
    return urls;
  }
}
