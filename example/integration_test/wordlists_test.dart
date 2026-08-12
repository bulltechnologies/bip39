import 'package:bip39/bip39.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_crypto/native_crypto.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  NativeCryptoTesting.allowUiIsolate();

  group('Bip39Wordlists', () {
    test('every language has 2048 unique words', () {
      for (final language in Bip39Language.values) {
        final list = Bip39Wordlists.forLanguage(language);
        expect(list.words.length, Bip39Wordlist.wordCount,
            reason: language.fileName);
        expect(list.words.toSet().length, Bip39Wordlist.wordCount,
            reason: '${language.fileName} duplicates');
      }
    });

    test('forFileName resolves all languages', () {
      for (final language in Bip39Language.values) {
        expect(
          Bip39Wordlists.forFileName(language.fileName).language,
          language,
        );
      }
    });

    test('WORDLIST matches englishWords', () {
      expect(WORDLIST, englishWords);
      expect(WORDLIST.length, 2048);
    });
  });

  group('cross-language', () {
    test('English vector mnemonic fails validation in Spanish list', () {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      expect(
        Bip39.validateMnemonic(
          mnemonic,
          options: const Bip39ValidateOptions(language: Bip39Language.spanish),
        ),
        isFalse,
      );
    });

    test('zero entropy English mnemonic encodes per language', () {
      const entropy = '00000000000000000000000000000000';
      for (final language in Bip39Language.values) {
        final mnemonic = Bip39.entropyToMnemonic(
          entropy,
          options: Bip39EntropyOptions(language: language),
        );
        expect(
          Bip39.validateMnemonic(
            mnemonic,
            options: Bip39ValidateOptions(language: language),
          ),
          isTrue,
          reason: language.fileName,
        );
        expect(
          Bip39.mnemonicToEntropy(
            mnemonic,
            options: Bip39EntropyOptions(language: language),
          ),
          entropy,
          reason: language.fileName,
        );
      }
    });
  });

  group('Japanese separators', () {
    test('encodes with ideographic space and round-trips', () {
      const entropy = '00000000000000000000000000000000';
      final mnemonic = Bip39.entropyToMnemonic(
        entropy,
        options: const Bip39EntropyOptions(language: Bip39Language.japanese),
      );
      expect(mnemonic.contains('\u3000'), isTrue);
      expect(
        Bip39.mnemonicToEntropy(
          mnemonic,
          options: const Bip39EntropyOptions(language: Bip39Language.japanese),
        ),
        entropy,
      );
    });
  });
}
