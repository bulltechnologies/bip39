import 'dart:typed_data';

/// Overwrites every byte in [bytes] with zero.
///
/// Use on [Uint8List] buffers that held entropy, seeds, PBKDF2 passwords, or
/// salts. Has no effect when [bytes] is `null` or empty.
///
/// **Limits (Dart VM):** This cannot erase [String] instances (mnemonics,
/// passphrases remain in the immutable string heap until GC). It does not
/// guarantee the allocator or VM copies will be cleared. Combine with process
/// isolation and minimal lifetime for secrets.
void zeroizeBytes(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) return;
  bytes.fillRange(0, bytes.length, 0);
}

/// Extension for clearing byte buffers in `finally` blocks.
extension Bip39ZeroizeBytes on Uint8List {
  /// See [zeroizeBytes].
  void zeroize() => zeroizeBytes(this);
}

/// Owns a byte buffer that should be cleared after use (e.g. BIP39 seed).
///
/// Prefer this over raw [Uint8List] when the caller can call [zeroize] as soon
/// as the seed is copied into a secure enclave or derived key material.
///
/// ```dart
/// final sensitive = Bip39.mnemonicToSeedSensitive(mnemonic, options: opts);
/// try {
///   final seed = sensitive.bytes;
///   // use seed…
/// } finally {
///   sensitive.zeroize();
/// }
/// ```
final class SensitiveBytes {
  /// Wraps [bytes] (copied if [copy] is true).
  factory SensitiveBytes(Uint8List bytes, {bool copy = true}) {
    final owned = copy ? Uint8List.fromList(bytes) : bytes;
    return SensitiveBytes._(owned);
  }

  SensitiveBytes._(this._bytes);

  final Uint8List _bytes;
  var _zeroed = false;

  /// The secret buffer. Do not retain longer than necessary.
  Uint8List get bytes {
    if (_zeroed) {
      throw StateError('SensitiveBytes was zeroized');
    }
    return _bytes;
  }

  /// Length in bytes.
  int get length => _zeroed ? 0 : _bytes.length;

  /// Irreversibly clears the buffer.
  void zeroize() {
    if (_zeroed) return;
    zeroizeBytes(_bytes);
    _zeroed = true;
  }
}
