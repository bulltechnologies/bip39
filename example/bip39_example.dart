import 'package:bip39/bip39.dart';

void main() {
  // --- Top-level API (English default, BIP39-compliant seed encoding) ---
  final mnemonic = generateMnemonic();
  print('English mnemonic: $mnemonic');

  // --- BIP39 facade: compliant seed + explicit zeroization ---
  final sensitive = Bip39.mnemonicToSeedSensitive(
    mnemonic,
    options: const Bip39SeedOptions(passphrase: 'optional'),
  );
  try {
    print('seed length: ${sensitive.length} bytes');
  } finally {
    sensitive.zeroize();
  }

  // --- Wordlist access ---
  print('French word count: ${frenchWords.length}');
  print('First French word: ${Bip39Wordlists.french.words.first}');

  // --- Another language via options ---
  final spanish = Bip39.generateMnemonic(
    options: const Bip39MnemonicOptions(
      language: Bip39Language.spanish,
      strength: 128,
    ),
  );
  print('Spanish mnemonic: $spanish');

  // --- Japanese: U+3000 separators + NFKD word lookup ---
  final codec = MnemonicCodec.forLanguage(Bip39Language.japanese);
  const entropy = '00000000000000000000000000000000';
  final jp = codec.entropyToMnemonic(entropy);
  print('Japanese (zero entropy): $jp');

  final detail = validateMnemonicDetailed('basket actual');
  print('Invalid phrase reason: ${detail.reason}');
}
