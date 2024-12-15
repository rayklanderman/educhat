import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  factory FileService() {
    return _instance;
  }

  FileService._internal();

  Future<String?> uploadFile({
    required File file,
    required String chatId,
    required String senderId,
    String? customFileName,
  }) async {
    try {
      final fileExtension = path.extension(file.path);
      final fileName = customFileName ?? '${_uuid.v4()}$fileExtension';
      final filePath = 'chats/$chatId/$fileName';

      await _client.storage.from('chat-files').upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final fileUrl = _client.storage.from('chat-files').getPublicUrl(filePath);
      
      // Create file metadata record
      await _client.from('files').insert({
        'file_name': fileName,
        'file_path': filePath,
        'file_url': fileUrl,
        'file_type': fileExtension.replaceAll('.', ''),
        'size': await file.length(),
        'uploaded_by': senderId,
        'chat_id': chatId,
      });

      return fileUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<FilePickerResult?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      return await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      await _client.storage.from('chat-files').remove([filePath]);
      await _client.from('files').delete().eq('file_path', filePath);
    } catch (e) {
      rethrow;
    }
  }

  String getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return 'image';
      case '.pdf':
        return 'pdf';
      case '.doc':
      case '.docx':
        return 'document';
      case '.mp4':
      case '.mov':
      case '.avi':
        return 'video';
      case '.mp3':
      case '.wav':
        return 'audio';
      default:
        return 'other';
    }
  }
}
