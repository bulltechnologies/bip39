import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_crypto/native_crypto.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SHA-256 checksum (native provider)', () {
    final sha256 = Sha256();

    test('matches NIST empty-string vector', () {
      expect(
        HEX.encode(sha256.hash(Uint8List(0))),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('mnemonic checksum matches known entropy', () {
      const entropyHex = '00000000000000000000000000000000';
      const expectedMnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      expect(entropyToMnemonic(entropyHex), expectedMnemonic);
    });
  });

  group('injected deterministic RNG', () {
    test('generateMnemonic uses custom randomBytes callback', () {
      final mnemonic = generateMnemonic(
        strength: 128,
        randomBytes: (int size) => Uint8List.fromList(
          List<int>.generate(size, (index) => index & 0xff),
        ),
      );
      expect(mnemonicToEntropy(mnemonic), '000102030405060708090a0b0c0d0e0f');
    });
  });
}
