import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:bip39/src/utils/argon2.dart' as bip39_argon2;
import 'package:bip39/src/utils/pbkdf2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_crypto/native_crypto.dart' as native_crypto;
import 'package:native_crypto/src/ffi/native_crypto_backend.dart';

class _FakeBackend implements NativeCryptoBackend {
  _FakeBackend();

  int pbkdf2Calls = 0;
  int? lastPbkdf2Prf;
  int? lastPbkdf2Iterations;
  int? lastPbkdf2DerivedKeyLength;

  int argon2Calls = 0;
  int? lastArgon2Type;
  int? lastArgon2Version;
  int? lastArgon2MemoryKiB;
  int? lastArgon2Iterations;
  int? lastArgon2Parallelism;
  int? lastArgon2HashLength;

  @override
  Uint8List pbkdf2({
    required int prf,
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int derivedKeyLength,
  }) {
    pbkdf2Calls++;
    lastPbkdf2Prf = prf;
    lastPbkdf2Iterations = iterations;
    lastPbkdf2DerivedKeyLength = derivedKeyLength;
    return Uint8List(derivedKeyLength);
  }

  @override
  Uint8List argon2({
    required int type,
    required int version,
    required int memoryKiB,
    required int iterations,
    required int parallelism,
    required Uint8List password,
    required Uint8List salt,
    required int hashLength,
  }) {
    argon2Calls++;
    lastArgon2Type = type;
    lastArgon2Version = version;
    lastArgon2MemoryKiB = memoryKiB;
    lastArgon2Iterations = iterations;
    lastArgon2Parallelism = parallelism;
    lastArgon2HashLength = hashLength;
    return Uint8List(hashLength);
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

void main() {
  group('PBKDF2 dispatch', () {
    test('uses HMAC-SHA512, 2048 iterations, and 64-byte output', () {
      final backend = _FakeBackend();
      final pbkdf2 = PBKDF2(pbkdf2: native_crypto.Pbkdf2(backend: backend));
      final password = Uint8List.fromList([1, 2, 3]);
      final salt = Uint8List.fromList([4, 5, 6]);

      pbkdf2.processBytes(password, salt);

      expect(backend.pbkdf2Calls, 1);
      expect(backend.lastPbkdf2Prf, 1);
      expect(backend.lastPbkdf2Iterations, 2048);
      expect(backend.lastPbkdf2DerivedKeyLength, 64);
    });
  });

  group('Argon2 dispatch', () {
    test('maps Bip39Argon2Params to native Argon2id v1.3', () {
      final backend = _FakeBackend();
      final argon2 = bip39_argon2.Argon2(
        generator: native_crypto.Argon2(backend: backend),
      );
      const params = Bip39Argon2Params(
        iterations: 2,
        memoryKiB: 1024,
        parallelism: 1,
        desiredKeyLength: 64,
        version: Bip39Argon2Version.v13,
      );

      argon2.processBytes(
        Uint8List.fromList([1]),
        Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        params: params,
      );

      expect(backend.argon2Calls, 1);
      expect(backend.lastArgon2Type, 2);
      expect(backend.lastArgon2Version, 1);
      expect(backend.lastArgon2MemoryKiB, 1024);
      expect(backend.lastArgon2Iterations, 2);
      expect(backend.lastArgon2Parallelism, 1);
      expect(backend.lastArgon2HashLength, 64);
    });

    test('maps Argon2 v1.0 version integer', () {
      final backend = _FakeBackend();
      final argon2 = bip39_argon2.Argon2(
        generator: native_crypto.Argon2(backend: backend),
      );

      argon2.processBytes(
        Uint8List.fromList([1]),
        Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        params: const Bip39Argon2Params(version: Bip39Argon2Version.v10),
      );

      expect(backend.lastArgon2Version, 0);
    });
  });
}
