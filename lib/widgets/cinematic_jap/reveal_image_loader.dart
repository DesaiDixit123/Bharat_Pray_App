import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Loads a reveal portrait from a bundled asset, a server URL, or a device file.
Future<Uint8List> loadRevealImageBytes(String source) async {
  if (source.startsWith('http://') || source.startsWith('https://')) {
    final response = await http.get(Uri.parse(source));
    if (response.statusCode != 200) {
      throw Exception('Image request failed with status ${response.statusCode}');
    }
    return response.bodyBytes;
  }
  if (source.startsWith('assets/')) {
    final data = await rootBundle.load(source);
    return data.buffer.asUint8List();
  }
  return File(source).readAsBytes();
}
