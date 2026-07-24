import 'dart:convert';

import 'package:flutter/services.dart';

const _assetPrefix = 'packages/bip39/test';

/// Loads [vectors.json] from the bip39 package asset bundle.
Future<Map<String, dynamic>> loadEnglishVectors() async {
  final body = await rootBundle.loadString('$_assetPrefix/vectors.json');
  return json.decode(body) as Map<String, dynamic>;
}

/// Loads [japanese_vectors.json] from the bip39 package asset bundle.
Future<List<dynamic>> loadJapaneseVectors() async {
  final body = await rootBundle.loadString('$_assetPrefix/japanese_vectors.json');
  return json.decode(body) as List<dynamic>;
}
