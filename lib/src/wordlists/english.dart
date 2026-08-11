// English wordlist — backward-compatible export.
export 'generated/english.dart' show englishWords;

import 'generated/english.dart';

/// English BIP39 wordlist (2048 words).
///
/// Prefer [Bip39Wordlists.english.words] or [englishWords] for new code.
/// [WORDLIST] is a legacy alias for [englishWords].
const List<String> WORDLIST = englishWords;
