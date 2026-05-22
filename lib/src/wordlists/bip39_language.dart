/// BIP39 mnemonic languages defined in [the spec wordlists](https://github.com/bitcoin/bips/blob/master/bip-0039/bip-0039-wordlists.md).
enum Bip39Language {
  english('english', 'English'),
  japanese('japanese', 'Japanese'),
  korean('korean', 'Korean'),
  spanish('spanish', 'Spanish'),
  chineseSimplified('chinese_simplified', 'Chinese (Simplified)'),
  chineseTraditional('chinese_traditional', 'Chinese (Traditional)'),
  french('french', 'French'),
  italian('italian', 'Italian'),
  czech('czech', 'Czech'),
  portuguese('portuguese', 'Portuguese');

  const Bip39Language(this.fileName, this.displayName);

  /// File stem in the bitcoin/bips `bip-0039` wordlist set.
  final String fileName;

  /// Human-readable label.
  final String displayName;

  /// Whether user input may use the ideographic space (U+3000) between words.
  ///
  /// BIP39 normalizes these to ASCII spaces before seed derivation; parsers
  /// should accept them when [Bip39MnemonicOptions.normalizeInput] is true.
  bool get supportsIdeographicSpace => this == Bip39Language.japanese;
}
