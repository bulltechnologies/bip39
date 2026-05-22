import 'package:bip39/bip39.dart';
import 'package:test/test.dart';

void main() {
  group('Argon2id seed derivation', () {
    const mnemonic =
        'legal winner thank year wave sausage worth useful legal winner thank yellow';

    test('defaults to BIP39 PBKDF2 on Bip39SeedOptions', () {
      expect(Bip39SeedOptions.defaults.kdf, Bip39Kdf.pbkdf2);
      expect(Bip39SeedOptions.bip39Standard, Bip39SeedOptions.defaults);
    });

    test('Bip39SeedOptions.argon2 differs from PBKDF2 defaults', () {
      const passphrase = 'TREZOR';
      final pbkdf2 = Bip39.mnemonicToSeedHex(
        mnemonic,
        options: const Bip39SeedOptions(passphrase: passphrase),
      );
      final argon2 = Bip39.mnemonicToSeedHex(
        mnemonic,
        options: const Bip39SeedOptions(
          passphrase: passphrase,
          kdf: Bip39Kdf.argon2id,
        ),
      );
      expect(argon2, isNot(pbkdf2));
      expect(
        pbkdf2,
        '2e8905819b8723fe2c1d161860e5ee1830318dbf49a83bd451cfb8440c28bd6fa457fe1296106559a3c80937a1c1069be3a3a5bd381ee6260e8d9739fce1f607',
      );
    });

    test('deterministic with Bip39Argon2Params.test', () {
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
  });
}
