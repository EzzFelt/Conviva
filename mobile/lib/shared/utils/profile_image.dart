import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Converte o valor salvo em `photoUrl` em um [ImageProvider].
///
/// Aceita:
/// - data URI (`data:image/jpeg;base64,...`), usado nas fotos de perfil
///   guardadas direto no Firestore;
/// - URL http(s) normal.
///
/// Retorna `null` quando não há foto ou o valor é inválido.
ImageProvider? profileImageProvider(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;

  if (normalized.startsWith('data:')) {
    final bytes = _decodeDataUri(normalized);
    return bytes == null ? null : MemoryImage(bytes);
  }

  return NetworkImage(normalized);
}

/// Monta o data URI que é salvo em `photoUrl`.
String buildProfileDataUri(Uint8List bytes, {String mimeType = 'image/jpeg'}) {
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

// Evita decodificar o mesmo base64 a cada rebuild.
final Map<String, Uint8List> _decodedCache = <String, Uint8List>{};

Uint8List? _decodeDataUri(String dataUri) {
  final cached = _decodedCache[dataUri];
  if (cached != null) return cached;

  final commaIndex = dataUri.indexOf(',');
  if (commaIndex == -1) return null;

  try {
    final bytes = base64Decode(dataUri.substring(commaIndex + 1));
    if (_decodedCache.length >= 30) {
      _decodedCache.remove(_decodedCache.keys.first);
    }
    _decodedCache[dataUri] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}
