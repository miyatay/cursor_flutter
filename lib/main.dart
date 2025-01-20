import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Widget> _messages = [];
  final TextEditingController _textController = TextEditingController();
  int _conversationCount = 0;

  // AIの応答をシミュレートするストリーム
  Stream<String> _simulateAIResponse() {
    _conversationCount++;
    final controller = StreamController<String>.broadcast();
    final response = '$_conversationCount: こんにちは！お手伝いできることはありますか？';
    
    Future(() async {
      for (var i = 0; i < response.length; i++) {
        try {
          await Future.delayed(const Duration(milliseconds: 50));
          if (!controller.isClosed) {  // コントローラーが閉じられていないことを確認
            print('### add: ${response.length} $i');
            controller.add(response.substring(0, i + 1));
          }
        } catch (e) {
          print('### error: $e');
          // エラーが発生した場合は処理を中断
          break;
        }
        }
      await controller.close();
    });

    return controller.stream;
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(
        text: text,
        isUser: true,
      ));
      _messages.insert(0, StreamingChatMessage(
        stream: _simulateAIResponse(),
        isUser: false,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: 'メッセージを入力してください',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.smart_toy),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(text),
            ),
          ),
          if (isUser) const SizedBox(width: 8.0),
        ],
      ),
    );
  }
}

// ストリーミング表示用のチャットメッセージウィジェット
class StreamingChatMessage extends StatefulWidget {
  const StreamingChatMessage({
    super.key,
    required this.stream,
    required this.isUser,
  });

  final bool isUser;
  final Stream<String> stream;

  @override
  State<StreamingChatMessage> createState() => _StreamingChatMessageState();
}

class _StreamingChatMessageState extends State<StreamingChatMessage> {
  String _lastValue = '';  // 最後の値を保持する変数を追加

  @override
  void initState() {
    super.initState();
    widget.stream.listen(
      (data) {
        _lastValue = data;  // データを保持
        print('### $data');
      },
      onDone: () {
        print('### done ');
        if (!mounted) return;
        
        final parentState = context.findAncestorStateOfType<_ChatScreenState>();
        if (parentState != null) {
          final index = parentState._messages.indexOf(widget);
          print('### index: $index');
          if (index != -1) {
            parentState.setState(() {
              parentState._messages[index] = ChatMessage(
                text: _lastValue,  // 保持した値を使用
                isUser: widget.isUser,
              );
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.smart_toy),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: widget.isUser ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: StreamBuilder<String>(
                stream: widget.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return Text(snapshot.data ?? '');
                },
              ),
            ),
          ),
          if (widget.isUser) const SizedBox(width: 8.0),
        ],
      ),
    );
  }
}
