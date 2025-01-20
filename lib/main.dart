import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // APIを呼び出してAIの応答を取得するストリーム
  Stream<String> _getAIResponse(String userMessage) {
    final controller = StreamController<String>.broadcast();
    String buffer = '';

    Future(() async {
      try {
        final request = http.Request('POST', Uri.parse('[URL]'));
        request.headers.addAll({
          'Authorization': 'Bearer [API_KEY]',
          'Content-Type': 'application/json',
        });
        request.body = jsonEncode({
          'inputs': {},
          'query': userMessage,
          'response_mode': 'streaming',
          'conversation_id': '',
          'user': 'abc-123'
        });

        final response = await http.Client().send(request);
        if (response.statusCode == 200) {
          await for (var chunk in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
            if (chunk.startsWith('data: ')) {
              final jsonStr = chunk.substring(6);
              try {
                final jsonData = jsonDecode(jsonStr);
                if (jsonData['event'] == 'message') {
                  final answer = jsonData['answer'] as String;
                  buffer += answer;
                  // 遅延を入れて段階的に表示
                  await Future.delayed(const Duration(milliseconds: 10));
                  controller.add(buffer);
                } else if (jsonData['event'] == 'message_end') {
                  break;
                }
              } catch (e) {
                print('JSONパースエラー: $e');
              }
            }
          }
        } else {
          controller.add('エラーが発生しました: ${response.statusCode}');
        }
      } catch (e) {
        controller.add('通信エラーが発生しました: $e');
      }

      await controller.close();
    });

    return controller.stream;
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.insert(
          0,
          ChatMessage(
            text: text,
            isUser: true,
          ));
      _messages.insert(
          0,
          StreamingChatMessage(
            stream: _getAIResponse(text), // シミュレーション関数の代わりにAPI呼び出しを使用
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
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
  @override
  Widget build(BuildContext context) {
    print('### build');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  print(
                      '### StreamBuilder: ${snapshot.connectionState} ${snapshot.data}');
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
