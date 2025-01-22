import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _nicknameController = TextEditingController();
  final _recordController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _recordController.text = exampleRecord;
    _recordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _recordController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _recordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('デバッグ画面'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                hintText: 'ニックネーム',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recordController,
              minLines: 3,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: '記録',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isButtonEnabled ? () {
                context.go('/chat', extra: {
                  'nickname': _nicknameController.text,
                  'record': _recordController.text,
                });
              } : null,
              child: const Text('開始'),
            ),
          ],
        ),
      ),
    );
  }
}

const exampleRecord = '''
こんにちは！
''';
