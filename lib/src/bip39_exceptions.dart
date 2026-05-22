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
    super.message, {
    this.reason = Bip39FailureReason.invalidMnemonic,
    this.unknownWord,
  });

  @override
  final Bip39FailureReason reason;

  /// Set when [reason] is [Bip39FailureReason.unknownWord].
  final String? unknownWord;

  @override
  String get bip39Message => message as String;
}

/// Thrown when entropy hex or decoded bytes are out of spec.
class Bip39InvalidEntropyException extends ArgumentError implements Bip39Exception {
  Bip39InvalidEntropyException(super.message)
      : reason = Bip39FailureReason.invalidEntropy;

  @override
  final Bip39FailureReason reason;

  @override
  String get bip39Message => message as String;
}

/// Thrown when the mnemonic checksum does not match entropy.
class Bip39InvalidChecksumException extends StateError implements Bip39Exception {
  Bip39InvalidChecksumException(super.message)
      : reason = Bip39FailureReason.invalidChecksum;

  @override
  final Bip39FailureReason reason;

  @override
  String get bip39Message => message;
}

/// Thrown when [generateMnemonic] `strength` is not a supported BIP39 size.
class Bip39InvalidStrengthException extends ArgumentError implements Bip39Exception {
  Bip39InvalidStrengthException(super.message, this.strength)
      : reason = Bip39FailureReason.invalidStrength;

  @override
  final Bip39FailureReason reason;

  final int strength;

  @override
  String get bip39Message => message as String;
}

/// Outcome of [validateMnemonicDetailed].
class MnemonicValidationResult {
  const MnemonicValidationResult.valid()
      : isValid = true,
        reason = null,
        unknownWord = null;

  const MnemonicValidationResult.invalid(
    this.reason, {
    this.unknownWord,
  }) : isValid = false;

  final bool isValid;
  final Bip39FailureReason? reason;
  final String? unknownWord;
}
