import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:example/config/env.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.nickname,
    required this.record,
  });

  final String nickname;
  final String record;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Widget> _messages = [];
  final TextEditingController _textController = TextEditingController();
  String conversationId = '';
  int messageCount = 0;  // メッセージ送信回数を追加
  static const int maxMessages = 5;  // 最大メッセージ数を定数で定義

  @override
  void initState() {
    super.initState();
    if (widget.record.isNotEmpty) {
      messageCount++;  // 初期メッセージをカウント
      _messages.insert(
        0,
        StreamingChatMessage(
          stream: _getAIResponseFirst(widget.nickname, widget.record),
          isUser: false,
        ),
      );
    }
  }

  Stream<String> _getAIResponseFirst(String nickname, String record) {
    return _getAIResponse('開始', nickname, record);
  }
  Stream<String> _getAIResponseSecond(String userMessage) {
    return _getAIResponse(userMessage, '', '');
  }

  // APIを呼び出してAIの応答を取得するストリーム
  Stream<String> _getAIResponse(String userMessage, String nickname, String record) {
    final controller = StreamController<String>.broadcast();
    String buffer = '';

    Future(() async {
      try {
        final request = http.Request('POST', Uri.parse(apiUrl));
        request.headers.addAll({
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        });
        request.body = jsonEncode({
          'inputs': {
            'record_nutirition': widget.record,
            'isdebug': '0',
            'nickname': widget.nickname,
          },
          'query': userMessage,
          'response_mode': 'streaming',
          'conversation_id': conversationId,
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
                  controller.add('$messageCount: $buffer'); // TODO デバッグ用に会話数を表示
                } else if (jsonData['event'] == 'message_end') {
                  conversationId = jsonData['conversation_id'];
                  break;
                }
              } catch (e) {
                print('JSONパースエラー: $e');
              }
            }
          }
        } else {
          controller.add('ERROR: エラーが発生しました: ${response.statusCode}');
        }
      } catch (e) {
        controller.add('ERROR: 通信エラーが発生しました: $e');
      }

      await controller.close();
    });

    return controller.stream;
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    if (messageCount >= maxMessages) return;  // 制限に達した場合は送信しない

    _textController.clear();
    setState(() {
      messageCount++;  // メッセージをカウント
      _messages.insert(
          0,
          ChatMessage(
            text: text,
            isUser: true,
          ));
      _messages.insert(
          0,
          StreamingChatMessage(
            stream: _getAIResponseSecond(text),
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
    final bool isEnabled = messageCount < maxMessages;  // 送信可能かどうかを判定

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: isEnabled ? Row(  // isEnabledがfalseの場合は何も表示しない
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration(
                hintText: 'メッセージを入力してください',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ) : const SizedBox.shrink(),  // 非表示にする
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.isError = false,  // エラー状態を追加
  });

  final String text;
  final bool isUser;
  final bool isError;  // エラー状態

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
                color: isError ? Colors.red[50] : (isUser ? Colors.blue[100] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isError ? Colors.red : null,
                ),
              ),
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
  String _lastValue = '';
  bool _isError = false;  // エラー状態を追加

  @override
  void initState() {
    super.initState();
    widget.stream.listen(
      (data) {
        setState(() {
          _lastValue = data;
        });
      },
      onDone: () {
        if (!mounted) return;
        final parentState = context.findAncestorStateOfType<_ChatScreenState>();
        if (parentState != null) {
          final index = parentState._messages.indexOf(widget);
          if (index != -1) {
            parentState.setState(() {
              parentState._messages[index] = ChatMessage(
                text: _lastValue,
                isUser: widget.isUser,
                isError: _lastValue.startsWith('ERROR:'),  // エラー状態を渡す
              );
            });
          }
        }
      },
      onError: (error) {
        if (!mounted) return;
        final parentState = context.findAncestorStateOfType<_ChatScreenState>();
        if (parentState != null) {
          final index = parentState._messages.indexOf(widget);
          if (index != -1) {
            parentState.setState(() {
              parentState._messages[index] = ChatMessage(
                text: 'エラーが発生しました: $error',
                isUser: widget.isUser,
                isError: true,
              );
            });
          }
        }
        // setState(() {
        //   _lastValue = 'エラーが発生しました: $error';
        //   _isError = true;
        // });
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
                color: _isError ? Colors.red[50] : (widget.isUser ? Colors.blue[100] : Colors.grey[200]),
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
                  return Text(
                    snapshot.data ?? '',
                    style: TextStyle(
                      color: _isError ? Colors.red : null,
                    ),
                  );
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
