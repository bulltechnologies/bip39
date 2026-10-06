import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:native_crypto/native_crypto.dart';

void main() {
  NativeCryptoTesting.allowUiIsolate();

  test('custom RNG views remain caller-owned after generation', () {
    final backing = Uint8List.fromList(
      List<int>.generate(24, (index) => index),
    );
    final expected = Uint8List.fromList(backing);
    final view = Uint8List.sublistView(backing, 4, 20);
    final mnemonic = Bip39.generateMnemonic(
      options: Bip39MnemonicOptions(randomBytes: (_) => view),
    );
    expect(backing, expected);
    expect(Bip39.mnemonicToEntropyBytes(mnemonic), view);
    expect(generateMnemonic(randomBytes: (_) => view), mnemonic);
    expect(backing, expected);
  });

  test('wrong-length RNG buffers are neither modified nor accepted', () {
    final backing = Uint8List.fromList(List<int>.filled(17, 23));
    expect(
      () => generateMnemonic(randomBytes: (_) => backing),
      throwsArgumentError,
    );
    expect(backing, everyElement(23));
  });

  test('default RNG works through class and compatibility entry points', () {
    expect(validateMnemonic(Bip39.generateMnemonic()), isTrue);
    expect(validateMnemonic(generateMnemonic()), isTrue);
  });

  test(
    'failed decode retains failure reasons and later success owns entropy',
    () {
      const mnemonic =
          'legal winner thank year wave sausage worth useful legal winner thank yellow';
      final expected = Bip39.mnemonicToEntropyBytes(mnemonic);
      final unknown = mnemonic.replaceFirst('yellow', 'notaword');
      final invalidChecksum = mnemonic.replaceFirst('yellow', 'zoo');
      expect(
        Bip39.tryDecodeMnemonic(unknown),
        isA<MnemonicDecodeFailure>()
            .having(
              (result) => result.reason,
              'reason',
              Bip39FailureReason.unknownWord,
            )
            .having((result) => result.unknownWord, 'word', 'notaword'),
      );
      expect(
        Bip39.tryDecodeMnemonic(invalidChecksum),
        isA<MnemonicDecodeFailure>().having(
          (result) => result.reason,
          'reason',
          Bip39FailureReason.invalidChecksum,
        ),
      );
      final decoded =
          Bip39.tryDecodeMnemonic(mnemonic) as MnemonicDecodeSuccess;
      expect(decoded.entropyBytes, expected);
      expect(validateMnemonic(mnemonic), isTrue);
      expect(decoded.entropyBytes, expected);
      decoded.entropyBytes.fillRange(0, decoded.entropyBytes.length, 0);
      expect(Bip39.mnemonicToEntropyBytes(mnemonic), expected);
    },
  );

  test('official English seeds retain fresh caller-owned outputs', () {
    final vectors =
        jsonDecode(File('test/vectors.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final vector in vectors['english'] as List<dynamic>) {
      final values = vector as List<dynamic>;
      final mnemonic = values[1] as String;
      final expected = Uint8List.fromList(HEX.decode(values[2] as String));
      const options = Bip39SeedOptions(passphrase: 'TREZOR');
      final seed = Bip39.mnemonicToSeed(mnemonic, options: options);
      final sensitive = Bip39.mnemonicToSeedSensitive(
        mnemonic,
        options: options,
      );
      expect(seed, expected);
      expect(sensitive.bytes, expected);
      seed.fillRange(0, seed.length, 0);
      expect(sensitive.bytes, expected);
      sensitive.zeroize();
      expect(Bip39.mnemonicToSeed(mnemonic, options: options), expected);
    }
  });

  test('Japanese normalization and seed bytes remain unchanged', () {
    final vectors =
        jsonDecode(File('test/japanese_vectors.json').readAsStringSync())
            as List<dynamic>;
    for (final vector in vectors) {
      final values = vector as Map<String, dynamic>;
      final seed = Bip39.mnemonicToSeed(
        values['mnemonic'] as String,
        options: Bip39SeedOptions(passphrase: values['passphrase'] as String),
      );
      expect(HEX.encode(seed), values['seed']);
      zeroizeBytes(seed);
    }
  });

  test('optional Argon2 seed outputs remain independent and retain length', () {
    const mnemonic =
        'legal winner thank year wave sausage worth useful legal winner thank yellow';
    const options = Bip39SeedOptions(
      kdf: Bip39Kdf.argon2id,
      argon2Params: Bip39Argon2Params(
        iterations: 2,
        memoryKiB: 1024,
        parallelism: 1,
        desiredKeyLength: 32,
      ),
    );
    final seed = Bip39.mnemonicToSeed(mnemonic, options: options);
    final sensitive = Bip39.mnemonicToSeedSensitive(mnemonic, options: options);
    expect(seed.length, 32);
    expect(sensitive.bytes, seed);
    final expected = Uint8List.fromList(seed);
    zeroizeBytes(seed);
    expect(sensitive.bytes, expected);
    sensitive.zeroize();
    expect(Bip39.mnemonicToSeed(mnemonic, options: options), expected);
  });
}
