import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Preserve the complete signed URL, including the original encoded query.
String? validAnimalImageUrl(
  String? value, {
  bool allowInsecureHttp = kDebugMode,
}) {
  if (value == null || value.trim().isEmpty || RegExp(r'\s').hasMatch(value)) {
    return null;
  }
  final uri = Uri.tryParse(value);
  return uri != null &&
          (uri.scheme == 'https' ||
              (kDebugMode && allowInsecureHttp && uri.scheme == 'http')) &&
          uri.host.isNotEmpty
      ? value
      : null;
}

/// Re-signing the same object does not invalidate its already downloaded bytes.
/// Keep non-signature parameters, since they can identify a different image.
String animalImageCacheKey(
  String url, {
  required String animalId,
  required String ownerId,
}) {
  final uri = Uri.parse(url);
  final parameters = Map<String, List<String>>.from(uri.queryParametersAll)
    ..removeWhere((key, _) {
      final lower = key.toLowerCase();
      return lower.startsWith('x-amz-') ||
          lower.startsWith('x-goog-') ||
          const {
            'awsaccesskeyid',
            'signature',
            'expires',
            'googleaccessid',
            'key-pair-id',
            'policy',
          }.contains(lower);
    });
  final keys = parameters.keys.toList()..sort();
  final resource = uri
      .replace(
        queryParameters: {for (final key in keys) key: parameters[key]!},
        fragment: '',
      )
      .toString();
  return sha256
      .convert(utf8.encode(jsonEncode([ownerId, animalId, resource])))
      .toString();
}
