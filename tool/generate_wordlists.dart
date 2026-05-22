// ignore_for_file: avoid_print
import 'dart:io';

/// Generates lib/src/wordlists/generated/*.dart from tool/wordlist_src/*.txt
void main() {
  final srcDir = Directory('tool/wordlist_src');
  final outDir = Directory('lib/src/wordlists/generated');
  outDir.createSync(recursive: true);

  final files = srcDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.txt'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.txt', '');
    final words = file
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (words.length != 2048) {
      stderr.writeln('${file.path}: expected 2048 words, got ${words.length}');
      exit(1);
    }
    final constName = '${_toLowerCamelCase(name)}Words';
    final escaped = words.map(_escapeDartString).join(',\n  ');
    final content = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: bip-0039/$name.txt (bitcoin/bips)
// Regenerate: dart run tool/generate_wordlists.dart

const List<String> $constName = [
  $escaped,
];
''';
    final outFile = File('${outDir.path}/$name.dart');
    outFile.writeAsStringSync(content);
    print('Wrote ${outFile.path}');
  }

  final registry = StringBuffer('''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Regenerate: dart run tool/generate_wordlists.dart

''');
  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.txt', '');
    registry.writeln("import '$name.dart';");
  }
  registry.writeln();
  registry.writeln('/// Raw word arrays keyed by language file name.');
  registry.writeln('const Map<String, List<String>> generatedWordArrays = {');
  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.txt', '');
    final constName = '${_toLowerCamelCase(name)}Words';
    registry.writeln("  '$name': $constName,");
  }
  registry.writeln('};');

  File('${outDir.path}/generated_registry.dart')
      .writeAsStringSync(registry.toString());
  print('Wrote ${outDir.path}/generated_registry.dart');
}

String _toLowerCamelCase(String snake) {
  final pascal = snake.split('_').map((part) {
    if (part.isEmpty) return part;
    return part[0].toUpperCase() + part.substring(1);
  }).join();
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}

String _escapeDartString(String word) {
  final buffer = StringBuffer("'");
  for (final codeUnit in word.codeUnits) {
    switch (codeUnit) {
      case 0x27:
        buffer.write(r"\'");
      case 0x5c:
        buffer.write(r'\\');
      case 0x24:
        buffer.write(r'\$');
      default:
        if (codeUnit < 0x20 || codeUnit == 0x7f) {
          buffer.write('\\u${codeUnit.toRadixString(16).padLeft(4, '0')}');
        } else {
          buffer.write(String.fromCharCode(codeUnit));
        }
    }
  }
  buffer.write("'");
  return buffer.toString();
}
