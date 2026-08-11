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
    final seen = <String>{};
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (seen.contains(word)) {
        throw ArgumentError.value(
          word,
          'words',
          'Duplicate word at index $i in ${language.fileName}',
        );
      }
      seen.add(word);
    }
    return Bip39Wordlist._(
      language: language,
      words: List.unmodifiable(words),
    );
  }

  Bip39Wordlist._({
    required this.language,
    required this.words,
  });

  /// Standard BIP39 word count per list.
  static const int wordCount = 2048;

  /// Bits per word in the mnemonic encoding.
  static const int bitsPerWord = 11;

  final Bip39Language language;

  /// Ordered list of [wordCount] mnemonic words (index 0 … 2047).
  final List<String> words;

  Map<String, int>? _index;

  Map<String, int> get _wordIndex {
    final cached = _index;
    if (cached != null) {
      return cached;
    }
    final built = <String, int>{};
    for (var i = 0; i < words.length; i++) {
      built[words[i]] = i;
    }
    _index = built;
    return built;
  }

  /// O(1) lookup of a word's index, or `null` if absent.
  int? lookupIndex(String word) => _wordIndex[word];

  /// Word at [index] (0 … 2047).
  String wordAt(int index) {
    RangeError.checkValidIndex(index, words, 'index');
    return words[index];
  }

  /// Whether [word] appears in this list.
  bool containsWord(String word) => _wordIndex.containsKey(word);
}
