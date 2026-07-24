/// Argon2 version integers for [Bip39Argon2Params.version].
///
/// Matches the wire values used by Argon2 reference implementations (0x10, 0x13).
abstract final class Bip39Argon2Version {
  static const int v10 = 0x10;
  static const int v13 = 0x13;
}

/// Key derivation function for [Bip39.mnemonicToSeed].
enum Bip39Kdf {
  /// BIP39-standard PBKDF2-HMAC-SHA512, 2048 iterations, 64-byte output (default).
  pbkdf2,

  /// Optional Argon2id (memory-hard; not BIP39-standard).
  argon2id,
}

/// Argon2id parameters for [Bip39Kdf.argon2id] seed derivation.
final class Bip39Argon2Params {
  const Bip39Argon2Params({
    this.iterations = 4,
    this.memoryKiB = 65536,
    this.parallelism = 4,
    this.desiredKeyLength = 64,
    this.version = Bip39Argon2Version.v13,
  });

  /// Production-oriented defaults (~64 MiB, 4 lanes, 4 passes).
  static const Bip39Argon2Params defaults = Bip39Argon2Params();

  /// Low cost for unit tests (do not use in production).
  static const Bip39Argon2Params test = Bip39Argon2Params(
    iterations: 2,
    memoryKiB: 1024,
    parallelism: 1,
  );

  /// Time cost (passes).
  final int iterations;

  /// Memory in 1 KiB blocks (65536 = 64 MiB).
  final int memoryKiB;

  /// Parallel lanes.
  final int parallelism;

  /// Derived seed length in bytes.
  final int desiredKeyLength;

  /// Argon2 version constant ([Bip39Argon2Version.v13] = 0x13).
  final int version;

  Bip39Argon2Params copyWith({
    int? iterations,
    int? memoryKiB,
    int? parallelism,
    int? desiredKeyLength,
    int? version,
  }) =>
      Bip39Argon2Params(
        iterations: iterations ?? this.iterations,
        memoryKiB: memoryKiB ?? this.memoryKiB,
        parallelism: parallelism ?? this.parallelism,
        desiredKeyLength: desiredKeyLength ?? this.desiredKeyLength,
        version: version ?? this.version,
      );
}
