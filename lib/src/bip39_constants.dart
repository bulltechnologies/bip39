/// Supported mnemonic strengths in bits (BIP39).
const List<int> allowedMnemonicStrengths = [128, 160, 192, 224, 256];

const String invalidMnemonicMessage = 'Invalid mnemonic';
const String invalidEntropyMessage = 'Invalid entropy';
const String invalidChecksumMessage = 'Invalid mnemonic checksum';

final RegExp entropyBitChunkPattern = RegExp(r'.{1,11}');
final RegExp entropyBytePattern = RegExp(r'.{1,8}');
