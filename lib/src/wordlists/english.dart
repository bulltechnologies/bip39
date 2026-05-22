// English wordlist — backward-compatible export.
export 'generated/english.dart' show englishWords;

import 'generated/english.dart';

/// English BIP39 wordlist (2048 words).
///
/// Prefer [Bip39Wordlists.english] or [Bip39Language.english] for new code.
const List<String> WORDLIST = englishWords;
