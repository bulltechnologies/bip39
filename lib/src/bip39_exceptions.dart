import 'dart:typed_data';

/// Reason codes for [Bip39Exception] and validation results.
enum Bip39FailureReason {
  invalidMnemonic,
  invalidEntropy,
  invalidChecksum,
  invalidStrength,
  unknownWord,
  invalidWordCount,
}

/// Base type for BIP39 failures. Thrown types extend [ArgumentError] or
/// [StateError] so existing `catch (ArgumentError)` / `catch (StateError)`
/// handlers keep working.
abstract interface class Bip39Exception implements Exception {
  Bip39FailureReason get reason;

  /// Human-readable error (same strings as pre-1.1.0 for compatibility).
  String get bip39Message;
}

/// Thrown when mnemonic structure or words are invalid.
class Bip39InvalidMnemonicException extends ArgumentError
    implements Bip39Exception {
  Bip39InvalidMnemonicException(
    String message, {
    this.reason = Bip39FailureReason.invalidMnemonic,
    this.unknownWord,
  })  : _message = message,
        super(message);

  final String _message;

  @override
  final Bip39FailureReason reason;

  /// Set when [reason] is [Bip39FailureReason.unknownWord].
  final String? unknownWord;

  @override
  String get bip39Message => _message;
}

/// Thrown when entropy hex or decoded bytes are out of spec.
class Bip39InvalidEntropyException extends ArgumentError implements Bip39Exception {
  Bip39InvalidEntropyException(String message)
      : _message = message,
        reason = Bip39FailureReason.invalidEntropy,
        super(message);

  final String _message;

  @override
  final Bip39FailureReason reason;

  @override
  String get bip39Message => _message;
}

/// Thrown when the mnemonic checksum does not match entropy.
class Bip39InvalidChecksumException extends StateError implements Bip39Exception {
  Bip39InvalidChecksumException(String message)
      : _message = message,
        reason = Bip39FailureReason.invalidChecksum,
        super(message);

  final String _message;

  @override
  final Bip39FailureReason reason;

  @override
  String get bip39Message => _message;
}

/// Thrown when [generateMnemonic] `strength` is not a supported BIP39 size.
class Bip39InvalidStrengthException extends ArgumentError implements Bip39Exception {
  Bip39InvalidStrengthException(String message, this.strength)
      : _message = message,
        reason = Bip39FailureReason.invalidStrength,
        super(message);

  final String _message;

  @override
  final Bip39FailureReason reason;

  final int strength;

  @override
  String get bip39Message => _message;
}

/// Outcome of [validateMnemonicDetailed].
final class MnemonicValidationResult {
  const MnemonicValidationResult._({
    required this.isValid,
    this.reason,
    this.unknownWord,
  })  : assert(isValid || reason != null),
        assert(
          isValid ||
              reason != Bip39FailureReason.unknownWord ||
              unknownWord != null,
        ),
        assert(
          isValid ||
              unknownWord == null ||
              reason == Bip39FailureReason.unknownWord,
        );

  const MnemonicValidationResult.valid() : this._(isValid: true);

  factory MnemonicValidationResult.invalid(
    Bip39FailureReason reason, {
    String? unknownWord,
  }) =>
      MnemonicValidationResult._(
        isValid: false,
        reason: reason,
        unknownWord: unknownWord,
      );

  final bool isValid;
  final Bip39FailureReason? reason;
  final String? unknownWord;
}

/// Outcome of [MnemonicCodec.tryDecodeMnemonic] and [Bip39.tryDecodeMnemonic].
sealed class MnemonicDecodeResult {
  const MnemonicDecodeResult();
}

/// Successful mnemonic decode with verified checksum.
final class MnemonicDecodeSuccess extends MnemonicDecodeResult {
  MnemonicDecodeSuccess(this.entropyBytes);

  /// Decoded entropy bytes. Call [zeroizeBytes] when finished.
  final Uint8List entropyBytes;
}

/// Failed mnemonic decode without throwing.
final class MnemonicDecodeFailure extends MnemonicDecodeResult {
  const MnemonicDecodeFailure(this.reason, {this.unknownWord})
      : assert(
          reason != Bip39FailureReason.unknownWord || unknownWord != null,
        ),
        assert(
          unknownWord == null || reason == Bip39FailureReason.unknownWord,
        );

  final Bip39FailureReason reason;
  final String? unknownWord;
}
