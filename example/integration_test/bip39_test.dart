import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:integration_test/integration_test.dart';

import 'fixtures.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final vectors = await loadEnglishVectors();

  var i = 0;
  for (final list in vectors['english'] as List<dynamic>) {
    testVector(list as List<dynamic>, i);
    i++;
  }

  group('Bip39 class API', () {
    test('mirrors top-level English vector', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      expect(
        Bip39.mnemonicToSeedHex(
          mnemonic,
          options: const Bip39SeedOptions(passphrase: 'TREZOR'),
        ),
        mnemonicToSeedHex(mnemonic, passphrase: 'TREZOR'),
      );
    });
  });

  group('invalid entropy', () {
    test('throws for empty entropy', () {
      expect(
        () => entropyToMnemonic(''),
        throwsA(isA<Bip39InvalidEntropyException>()),
      );
    });

    test('throws for entropy that is not a multiple of 4 bytes', () {
      expect(
        () => entropyToMnemonic('000000'),
        throwsA(isA<Bip39InvalidEntropyException>()),
      );
    });

    test('throws for entropy larger than 32 bytes', () {
      expect(
        () => entropyToMnemonic('00' * 66),
        throwsA(isA<Bip39InvalidEntropyException>()),
      );
    });

    test('throws for non-hex entropy', () {
      expect(
        () => entropyToMnemonic('gg'),
        throwsA(isA<Bip39InvalidEntropyException>()),
      );
    });

    test('throws for odd-length hex entropy', () {
      expect(
        () => entropyToMnemonic('0' * 31),
        throwsA(isA<Bip39InvalidEntropyException>()),
      );
    });
  });

  group('validateMnemonic', () {
    test('fails for a mnemonic that is too short', () {
      expect(validateMnemonic('sleep kitten'), isFalse);
    });

    test('fails for repeated short phrase', () {
      expect(
        validateMnemonic('sleep kitten sleep kitten sleep kitten'),
        isFalse,
      );
    });

    test('fails for a mnemonic that is too long', () {
      expect(validateMnemonic('abandon ' * 500 + 'about'), isFalse);
    });

    test('fails if mnemonic words are not in the word list', () {
      expect(
        validateMnemonic(
          'turtle front uncle idea crush write shrug there lottery flower risky shell',
        ),
        isFalse,
      );
    });

    test('fails for invalid checksum', () {
      expect(
        validateMnemonic(
          'sleep kitten sleep kitten sleep kitten sleep kitten sleep kitten sleep kitten',
        ),
        isFalse,
      );
    });
  });

  group('validateMnemonicDetailed', () {
    test('reports unknown word', () {
      final result = validateMnemonicDetailed(
        List.filled(12, 'notaword').join(' '),
      );
      expect(result.isValid, isFalse);
      expect(result.reason, Bip39FailureReason.unknownWord);
      expect(result.unknownWord, 'notaword');
    });

    test('reports invalid checksum', () {
      final result = validateMnemonicDetailed(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon',
      );
      expect(result.isValid, isFalse);
      expect(result.reason, Bip39FailureReason.invalidChecksum);
    });

    test('reports invalid word count before checksum work', () {
      final result = validateMnemonicDetailed(
        List.filled(9, 'abandon').join(' '),
      );
      expect(result.isValid, isFalse);
      expect(result.reason, Bip39FailureReason.invalidWordCount);
    });
  });

  group('generateMnemonic', () {
    test('can vary entropy length', () {
      final words = generateMnemonic(strength: 160).split(' ');
      expect(words.length, 15);
    });

    test('requests the exact amount of data from an RNG', () {
      generateMnemonic(
        strength: 160,
        randomBytes: (int size) {
          expect(size, 20);
          return Uint8List(size);
        },
      );
    });

    test('throws for invalid strength', () {
      expect(
        () => generateMnemonic(strength: 136),
        throwsA(isA<Bip39InvalidStrengthException>()),
      );
    });

    test('throws when randomBytes returns wrong length', () {
      expect(
        () => generateMnemonic(
          strength: 256,
          randomBytes: (int size) => Uint8List(16),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('RandomBytes may use byte value 255 in entropy', () {
      final mnemonic = generateMnemonic(
        strength: 128,
        randomBytes: (int size) => Uint8List(size)..[0] = 255,
      );
      expect(mnemonicToEntropy(mnemonic).startsWith('ff'), isTrue);
    });
  });

  group('normalizeInput', () {
    test('accepts extra whitespace when enabled', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      expect(validateMnemonic(mnemonic, normalizeInput: true), isTrue);
      expect(validateMnemonic('  $mnemonic  ', normalizeInput: true), isTrue);
      expect(validateMnemonic('  $mnemonic  ', normalizeInput: false), isFalse);
    });
  });

  group('seed encoding', () {
    test('matches Trezor vectors with default BIP39 options', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      expect(
        mnemonicToSeedHex(mnemonic, passphrase: 'TREZOR'),
        'c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04',
      );
    });

    test('ASCII mnemonic and passphrase match across encodings', () {
      const mnemonic =
          'legal winner thank year wave sausage worth useful legal winner thank yellow';
      expect(
        mnemonicToSeedHex(mnemonic, passphrase: 'TREZOR'),
        mnemonicToSeedHex(
          mnemonic,
          passphrase: 'TREZOR',
          seedEncoding: Bip39SeedEncoding.bip39Compliant,
        ),
      );
    });

    test('Unicode passphrase differs between legacy and BIP39 encoding', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final legacy = mnemonicToSeedHex(
        mnemonic,
        passphrase: 'café',
        seedEncoding: Bip39SeedEncoding.legacy,
      );
      final compliant = mnemonicToSeedHex(
        mnemonic,
        passphrase: 'café',
        seedEncoding: Bip39SeedEncoding.bip39Compliant,
      );
      expect(legacy, isNot(compliant));
    });
  });

  group('entropyToMnemonicFromBytes', () {
    test('matches hex path', () {
      const hex = '00000000000000000000000000000000';
      expect(
        entropyToMnemonicFromBytes(Uint8List.fromList(HEX.decode(hex))),
        entropyToMnemonic(hex),
      );
    });
  });

  group('MnemonicCodec language inference', () {
    test('codec-bound methods infer wordlist language from defaults', () {
      const entropy = '00000000000000000000000000000000';
      final codec = MnemonicCodec.forLanguage(Bip39Language.italian);
      final mnemonic = codec.entropyToMnemonic(entropy);
      expect(codec.validateMnemonic(mnemonic), isTrue);
      expect(codec.mnemonicToEntropy(mnemonic), entropy);
    });

    test('tryDecodeMnemonic returns bytes without hex conversion', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final result = MnemonicCodec.english.tryDecodeMnemonic(mnemonic);
      expect(result, isA<MnemonicDecodeSuccess>());
      final success = result as MnemonicDecodeSuccess;
      try {
        expect(success.entropyBytes.length, 16);
      } finally {
        success.entropyBytes.zeroize();
      }
    });
  });

  group('strength helpers', () {
    test('wordCountForStrength and strengthForWordCount round-trip', () {
      for (final strength in allowedMnemonicStrengths) {
        final words = wordCountForStrength(strength);
        expect(strengthForWordCount(words), strength);
      }
    });
  });

  group('canonicalizeMnemonic', () {
    test('normalizes whitespace without changing seed input semantics', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final canonical = canonicalizeMnemonic(
        '  $mnemonic  ',
        normalizeInput: true,
      );
      expect(canonical, mnemonic);
      expect(
        mnemonicToSeedHex(canonical, passphrase: 'TREZOR'),
        mnemonicToSeedHex(mnemonic, passphrase: 'TREZOR'),
      );
    });
  });

  group('exception compatibility', () {
    test('invalid mnemonic is ArgumentError', () {
      expect(
        () => mnemonicToEntropy(List.filled(12, 'notaword').join(' ')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('invalid checksum is StateError', () {
      expect(
        () => mnemonicToEntropy(
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

void testVector(List<dynamic> v, int i) {
  final ventropy = v[0] as String;
  final vmnemonic = v[1] as String;
  final vseedHex = v[2] as String;
  group('for English($i), $ventropy', () {
    test('mnemonic to entropy', () {
      expect(mnemonicToEntropy(vmnemonic), ventropy);
    });

    test('mnemonic to seed hex', () {
      expect(
        mnemonicToSeedHex(vmnemonic, passphrase: 'TREZOR'),
        vseedHex,
      );
    });

    test('entropy to mnemonic', () {
      expect(entropyToMnemonic(ventropy), vmnemonic);
    });

    test('generate mnemonic with injected entropy', () {
      final entropyBytes = Uint8List.fromList(HEX.decode(ventropy));
      final code = generateMnemonic(
        strength: entropyBytes.length * 8,
        randomBytes: (int size) => Uint8List.sublistView(entropyBytes, 0, size),
      );
      expect(code, vmnemonic);
    });

    test('validate mnemonic', () {
      expect(validateMnemonic(vmnemonic), isTrue);
    });
  });
}
