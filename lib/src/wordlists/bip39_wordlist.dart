import 'bip39_language.dart';

/// Immutable BIP39 wordlist with O(1) word → index lookup.
///
/// Obtain instances via [Bip39Wordlists.forLanguage] or [Bip39Wordlists.of].
final class Bip39Wordlist {
  /// Builds a validated wordlist. Prefer the cached instances from [Bip39Wordlists].
  factory Bip39Wordlist({
    required Bip39Language language,
    required List<String> words,
  }) {
    if (words.length != wordCount) {
      throw ArgumentError.value(
        words.length,
        'words',
        'BIP39 wordlists must contain exactly $wordCount words',
      );
    }
    final index = <String, int>{};
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (index.containsKey(word)) {
        throw ArgumentError.value(
          word,
          'words',
          'Duplicate word at index $i in ${language.fileName}',
        );
      }
      index[word] = i;
    }
    return Bip39Wordlist._(
      language: language,
      words: List.unmodifiable(words),
      index: index,
    );
  }

  Bip39Wordlist._({
    required this.language,
    required this.words,
    required Map<String, int> index,
  }) : _index = index;

  /// Standard BIP39 word count per list.
  static const int wordCount = 2048;

  /// Bits per word in the mnemonic encoding.
  static const int bitsPerWord = 11;

  final Bip39Language language;

  /// Ordered list of [wordCount] mnemonic words (index 0 … 2047).
  final List<String> words;

  final Map<String, int> _index;

  /// O(1) lookup of a word's index, or `null` if absent.
  int? lookupIndex(String word) => _index[word];

  /// Word at [index] (0 … 2047).
  String wordAt(int index) {
    RangeError.checkValueInInterval(index, 0, words.length, 'index');
    return words[index];
  }

  /// Whether [word] appears in this list.
  bool containsWord(String word) => _index.containsKey(word);
}
