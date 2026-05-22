/// BIP39 mnemonic generation and seed derivation for deterministic wallets.
///
/// ### Quick start
/// ```dart
/// import 'package:bip39/bip39.dart';
///
/// final mnemonic = generateMnemonic();
/// final seed = mnemonicToSeed(mnemonic, passphrase: 'optional');
/// ```
///
/// ### Wordlists
/// All official languages are exposed via [Bip39Language], [Bip39Wordlist],
/// and [Bip39Wordlists]. Use [Bip39.wordlist] or [englishWords] directly.
///
/// ### Options & codecs
/// For full control, use [Bip39MnemonicOptions], [Bip39SeedOptions], and
/// [MnemonicCodec.forLanguage].
library;

export 'src/bip39.dart';
