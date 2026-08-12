import 'package:bip39/bip39.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_crypto/native_crypto.dart';

import 'fixtures.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  NativeCryptoTesting.allowUiIsolate();
  final vectors = await loadJapaneseVectors();

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

      test('entropy to mnemonic', () {
        expect(
          bip39Normalize(Bip39.entropyToMnemonic(entropy, options: entropyOpts)),
          bip39Normalize(mnemonic),
        );
      });

      test('validate mnemonic', () {
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
}
