import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/src/utils/pbkdf2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_crypto/native_crypto.dart';

Uint8List _bytes(String ascii) => Uint8List.fromList(utf8.encode(ascii));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PBKDF2-HMAC-SHA512 known-answer vectors (native provider)', () {
    test('RFC-style vector (c=4096, dkLen=64)', () {
      final out = Pbkdf2().deriveKey(
        prf: Pbkdf2Prf.hmacSha512,
        password: _bytes('password'),
        salt: _bytes('salt'),
        iterations: 4096,
        derivedKeyLength: 64,
      );
      expect(
        HEX.encode(out),
        'd197b1b33db0143e018b12f3d1d1479e6cdebdcc97c5c0f87f6902e072f457b'
        '5143f30602641b3d55cd335988cb36b84376060ecd532e039b742a239434af2d5',
      );
    });

    test('BIP39 wrapper uses 2048 iterations and 64-byte output', () {
      const mnemonic =
          'legal winner thank year wave sausage worth useful legal winner thank yellow';
      final password = Uint8List.fromList(mnemonic.codeUnits);
      final salt = _bytes('mnemonicTREZOR');

      final out = PBKDF2.instance.processBytes(password, salt);

      expect(
        HEX.encode(out),
        '2e8905819b8723fe2c1d161860e5ee1830318dbf49a83bd451cfb8440c28bd6fa'
        '457fe1296106559a3c80937a1c1069be3a3a5bd381ee6260e8d9739fce1f607',
      );
    });
  });
}
