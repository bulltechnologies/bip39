import 'dart:typed_data';

import 'package:pointycastle/key_derivators/api.dart' show Argon2Parameters;
import 'package:pointycastle/key_derivators/argon2.dart';

import '../bip39_kdf.dart';

/// Argon2id seed derivation (64-byte output by default).
class Argon2 {
  Argon2({Argon2BytesGenerator? generator})
      : _generator = generator ?? Argon2BytesGenerator();

  final Argon2BytesGenerator _generator;

  static final Argon2 instance = Argon2();

  Uint8List processBytes(
    Uint8List password,
    Uint8List salt, {
    Bip39Argon2Params params = Bip39Argon2Params.defaults,
  }) {
    final argon2Params = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: params.desiredKeyLength,
      iterations: params.iterations,
      memory: params.memoryKiB,
      lanes: params.parallelism,
      version: params.version,
    );
    _generator.init(argon2Params);
    return _generator.process(password);
  }
}
