import 'package:bip39/bip39.dart';
import 'package:flutter/material.dart';

void main() => runApp(const Bip39ExampleApp());

class Bip39ExampleApp extends StatelessWidget {
  const Bip39ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bip39 example',
      home: Scaffold(
        appBar: AppBar(title: const Text('bip39')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: _Bip39Demo(),
        ),
      ),
    );
  }
}

class _Bip39Demo extends StatefulWidget {
  const _Bip39Demo();

  @override
  State<_Bip39Demo> createState() => _Bip39DemoState();
}

class _Bip39DemoState extends State<_Bip39Demo> {
  late final String _mnemonic;
  late final String _seedPreview;

  @override
  void initState() {
    super.initState();
    _mnemonic = generateMnemonic();
    final seedHex = mnemonicToSeedHex(_mnemonic);
    _seedPreview = '${seedHex.substring(0, 16)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mnemonic: $_mnemonic'),
        const SizedBox(height: 8),
        Text('Seed (prefix): $_seedPreview'),
        const SizedBox(height: 8),
        Text('Valid: ${validateMnemonic(_mnemonic)}'),
      ],
    );
  }
}
