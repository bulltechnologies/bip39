import 'dart:convert';
import 'dart:io';

import 'package:bip39/bip39.dart';
import 'package:test/test.dart';

void main() {
  final vectors = json.decode(
    File('test/japanese_vectors.json').readAsStringSync(encoding: utf8),
  ) as List<dynamic>;

  const entropyOpts = Bip39EntropyOptions(language: Bip39Language.japanese);

  for (var i = 0; i < vectors.length; i++) {
    final v = vectors[i] as Map<String, dynamic>;
    final entropy = v['entropy'] as String;
    final mnemonic = v['mnemonic'] as String;
    final passphrase = v['passphrase'] as String;
    final seed = v['seed'] as String;

    group('Japanese vector $i', () {
      test('mnemonic to entropy (NFC input)', () {
        expect(
          Bip39.mnemonicToEntropy(mnemonic, options: entropyOpts),
          entropy,
        );
      });

      test('mnemonic to seed (BIP39 compliant)', () {
        expect(
          Bip39.mnemonicToSeedHex(
            mnemonic,
            options: Bip39SeedOptions(
              passphrase: passphrase,
              seedEncoding: Bip39SeedEncoding.bip39Compliant,
            ),
          ),
          seed,
        );
      });

      test('entropy to mnemonic uses ideographic space', () {
        final encoded = Bip39.entropyToMnemonic(entropy, options: entropyOpts);
        expect(encoded.contains('\u3000'), isTrue);
        expect(
          Bip39.validateMnemonic(encoded, options: const Bip39ValidateOptions(
            language: Bip39Language.japanese,
          )),
          isTrue,
        );
      });
    });
  }
}
