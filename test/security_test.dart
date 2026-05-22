import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:test/test.dart';

void main() {
  group('zeroizeBytes', () {
    test('clears all bytes', () {
      final buf = Uint8List.fromList([1, 2, 3, 255]);
      zeroizeBytes(buf);
      expect(buf, everyElement(0));
    });

    test('handles null and empty', () {
      zeroizeBytes(null);
      zeroizeBytes(Uint8List(0));
    });
  });

  group('SensitiveBytes', () {
    test('zeroize prevents further reads', () {
      final s = SensitiveBytes(Uint8List.fromList([42]));
      s.zeroize();
      expect(() => s.bytes, throwsA(isA<StateError>()));
    });
  });

  group('mnemonicToSeed buffer hygiene', () {
    test('mnemonicToSeedSensitive matches mnemonicToSeed', () {
      const mnemonic =
          'legal winner thank year wave sausage worth useful legal winner thank yellow';
      final raw = Bip39.mnemonicToSeed(mnemonic);
      final sensitive = Bip39.mnemonicToSeedSensitive(mnemonic);
      addTearDown(sensitive.zeroize);
      expect(sensitive.bytes, raw);
      zeroizeBytes(raw);
    });
  });

  group('NFKD word normalization', () {
    test('validates Japanese vector NFC mnemonic', () {
      final body =
          File('test/japanese_vectors.json').readAsStringSync(encoding: utf8);
      final first =
          (json.decode(body) as List<dynamic>).first as Map<String, dynamic>;
      final mnemonic = first['mnemonic'] as String;
      expect(
        Bip39.validateMnemonic(
          mnemonic,
          options: const Bip39ValidateOptions(language: Bip39Language.japanese),
        ),
        isTrue,
      );
    });
  });
}
