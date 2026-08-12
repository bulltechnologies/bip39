import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_crypto/native_crypto.dart';

import 'fixtures.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  NativeCryptoTesting.allowUiIsolate();

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
    test('validates Japanese vector NFC mnemonic', () async {
      final vectors = await loadJapaneseVectors();
      final first = vectors.first as Map<String, dynamic>;
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
