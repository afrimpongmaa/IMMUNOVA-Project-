import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String bucket = 'user-profiles';

  final SupabaseClient _client;
  StorageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Uploads a file to Supabase Storage under user folder and returns the public URL.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    final ext = p.extension(originalFileName).toLowerCase();
    final filename = 'avatar$ext';
    final path = '$userId/$filename';
    final contentType =
        lookupMimeType(originalFileName, headerBytes: bytes) ??
        'application/octet-stream';

    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: contentType,
          ),
        );

    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }
}
