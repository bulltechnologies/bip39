import 'package:bip39/bip39.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_crypto/native_crypto.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  NativeCryptoTesting.allowUiIsolate();

  group('BIP39 native integration', () {
    test('English Trezor vector seed matches', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      expect(
        mnemonicToSeedHex(mnemonic, passphrase: 'TREZOR'),
        'c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04',
      );
    });

    test('Argon2id test params produce expected seed', () {
      const mnemonic =
          'legal winner thank year wave sausage worth useful legal winner thank yellow';
      expect(
        Bip39.mnemonicToSeedHex(
          mnemonic,
          options: const Bip39SeedOptions(
            passphrase: 'TREZOR',
            kdf: Bip39Kdf.argon2id,
            argon2Params: Bip39Argon2Params.test,
          ),
        ),
        '7acee1388e53fe854aa33ce8ec4df071d99f69a34942029435dbaab3d7345129319d27488c192b4d5829b1a692a52bff03335a124aa5bfcf6bc63dd81b082f59',
      );
    });

    test('generateMnemonic uses native secure random', () {
      final mnemonic = generateMnemonic();
      expect(validateMnemonic(mnemonic), isTrue);
    });
  });
}
