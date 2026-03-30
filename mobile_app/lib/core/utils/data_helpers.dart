import 'package:flutter/material.dart';

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<dynamic> asList(Object? value) {
  return value is List ? value : const [];
}

String readString(dynamic source, String key) {
  return (asMap(source)[key] ?? '').toString();
}

int readInt(dynamic source, String key) {
  final value = asMap(source)[key];
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool readBool(dynamic source, String key) {
  final value = asMap(source)[key];
  if (value is bool) {
    return value;
  }
  return value?.toString().toLowerCase() == 'true';
}

String readPath(dynamic source, List<String> path) {
  dynamic current = source;
  for (final segment in path) {
    current = asMap(current)[segment];
  }
  return (current ?? '').toString();
}

IconData contentIcon(dynamic item) {
  final videoUrl = readString(item, 'video_url');
  final pdfUrl = readString(item, 'pdf_url');
  final materialUrl = readString(item, 'material_url');
  if (videoUrl.isNotEmpty) {
    return Icons.play_circle_outline_rounded;
  }
  if (pdfUrl.isNotEmpty) {
    return Icons.picture_as_pdf_outlined;
  }
  if (materialUrl.isNotEmpty) {
    return Icons.language_rounded;
  }
  return Icons.article_outlined;
}
