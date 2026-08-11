import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('strength helpers', () {
    test('wordCountForStrength matches BIP39 word counts', () {
      expect(wordCountForStrength(128), 12);
      expect(wordCountForStrength(160), 15);
      expect(wordCountForStrength(192), 18);
      expect(wordCountForStrength(224), 21);
      expect(wordCountForStrength(256), 24);
    });

    test('strengthForWordCount inverts wordCountForStrength', () {
      for (final strength in allowedMnemonicStrengths) {
        expect(strengthForWordCount(wordCountForStrength(strength)), strength);
      }
    });
  });

  group('canonicalizeMnemonic', () {
    test('trims and rejoins with ASCII spaces', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      expect(
        canonicalizeMnemonic('  $mnemonic  ', normalizeInput: true),
        mnemonic,
      );
    });
  });

  group('Bip39MnemonicOptions.copyWith', () {
    test('can clear randomBytes with explicit null', () {
      Uint8List callback(int size) => Uint8List(size);
      final withCallback = Bip39MnemonicOptions(randomBytes: callback);
      expect(withCallback.copyWith(randomBytes: null).randomBytes, isNull);
      expect(
        withCallback.copyWith(strength: 256).randomBytes,
        same(callback),
      );
    });
  });

  group('MnemonicValidationResult', () {
    test('invalid requires a reason', () {
      expect(
        () => MnemonicValidationResult.invalid(
          Bip39FailureReason.unknownWord,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Bip39Wordlist.wordAt', () {
    test('rejects index 2048', () {
      expect(
        () => Bip39Wordlists.english.wordAt(2048),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('Bip39SeedOptions.derivedSeedLength', () {
    test('pbkdf2 is always 64 bytes', () {
      expect(const Bip39SeedOptions().derivedSeedLength, 64);
    });

    test('argon2 follows desiredKeyLength', () {
      expect(
        const Bip39SeedOptions(
          kdf: Bip39Kdf.argon2id,
          argon2Params: Bip39Argon2Params(desiredKeyLength: 32),
        ).derivedSeedLength,
        32,
      );
    });
  });

  group('Bip39CodecOptions', () {
    test('codec methods do not take language', () {
      const entropy = '00000000000000000000000000000000';
      final codec = MnemonicCodec.forLanguage(Bip39Language.french);
      expect(codec.entropyToMnemonic(entropy), isNotEmpty);
    });
  });
}
