import 'bip39_language.dart';
import 'bip39_wordlist.dart';
import 'generated/generated_registry.dart';

/// Registry of all official BIP39 wordlists.
abstract final class Bip39Wordlists {
  /// English wordlist (default across the ecosystem).
  static final Bip39Wordlist english = _cached[Bip39Language.english]!;

  /// All languages in stable enum order.
  static final List<Bip39Language> languages = Bip39Language.values;

  /// Cached wordlist per [Bip39Language].
  static final Map<Bip39Language, Bip39Wordlist> _cached = {
    for (final language in Bip39Language.values)
      language: Bip39Wordlist(
        language: language,
        words: generatedWordArrays[language.fileName]!,
      ),
  };

  /// Returns the wordlist for [language].
  static Bip39Wordlist forLanguage(Bip39Language language) => _cached[language]!;

  /// Alias for [forLanguage].
  static Bip39Wordlist of(Bip39Language language) => forLanguage(language);

  /// Resolves [language] from a case-insensitive [fileName] (e.g. `english`,
  /// `chinese_simplified`). Throws [ArgumentError] if unknown.
  static Bip39Wordlist forFileName(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    for (final language in Bip39Language.values) {
      if (language.fileName == normalized) {
        return forLanguage(language);
      }
    }
    throw ArgumentError.value(fileName, 'fileName', 'Unknown BIP39 language');
  }
}
