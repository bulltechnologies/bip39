import 'dart:typed_data';

import 'package:native_crypto/native_crypto.dart' as native_crypto;

import '../bip39_kdf.dart';

native_crypto.Argon2Version _mapArgon2Version(int version) {
  switch (version) {
    case Bip39Argon2Version.v10:
      return native_crypto.Argon2Version.v10;
    case Bip39Argon2Version.v13:
      return native_crypto.Argon2Version.v13;
    default:
      throw ArgumentError.value(
        version,
        'version',
        'unsupported Argon2 version: expected 0x10 (v1.0) or 0x13 (v1.3)',
      );
  }
}

/// Argon2id seed derivation (64-byte output by default).
class Argon2 {
  Argon2({native_crypto.Argon2? generator})
      : _generator = generator ?? native_crypto.Argon2();

  final native_crypto.Argon2 _generator;

  static final Argon2 instance = Argon2();

  Uint8List processBytes(
    Uint8List password,
    Uint8List salt, {
    Bip39Argon2Params params = Bip39Argon2Params.defaults,
  }) {
    return _generator.deriveKey(
      password: password,
      salt: salt,
      type: native_crypto.Argon2Type.argon2id,
      version: _mapArgon2Version(params.version),
      memoryKiB: params.memoryKiB,
      iterations: params.iterations,
      parallelism: params.parallelism,
      hashLength: params.desiredKeyLength,
    );
  }
}
