import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {  final _nicknameController = TextEditingController();
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
        child: SingleChildScrollView(
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
      ),
    );
  }
}

const exampleRecord = '''
今日の記録

摂取カロリー目標：1605kcal
今日の摂取カロリー：1266kcal
差分：339kcal不足

目標たんぱく質摂取量：52.2～80.3ℊ
今日のたんぱく質摂取量：80.9ℊ
過剰

目標脂質摂取量：35.7～53.3ℊ
今日の脂質摂取量：58.3ℊ
過剰

目標炭水化物摂取量：200.6～260.8g
今日の炭水化物摂取量：109ℊ
不足

消費カロリー目標：334kcal
今日の消費カロリー：418kcal
差分：+84kcal

今日の体重：60.0kg
体脂肪率：28.5%
今日の歩数：7393歩

朝食の摂取カロリー：合計173kcal
朝食の目標摂取カロリー：482kcal
しゃけ (1個) (セブンイレブン)　1個　173kcal　たんぱく質4.7g　脂質1.6g　炭水化物35.8ℊ

昼食の摂取カロリー：合計637kcal
昼食の目標摂取カロリー：642kcal
チキンとナッツの11種野菜サ ラダランチ(1人前) (ココス)　1人前　637kcal　たんぱく質24g　脂質41.7g　炭水化物41.5ℊ

夕食の摂取カロリー：合計274kcal
夕食の目標摂取カロリー：482kcal
蒸し野菜(かぼちゃ、キャベツ、 ブロッコリー)　1人前　43kcal　たんぱく質2.4g　脂質0.3g　炭水化物10.5ℊ
味噌汁(わかめと豆腐)　1杯　44kcal　たんぱく質3.7g　脂質1.8g　炭水化物4.1ℊ
鶏むね肉チャーシュー(皮なし)　1人前　187kcal　たんぱく質31.1g　脂質2.5g　炭水化物8.7ℊ

間食の摂取カロリー：合計182kcal
間食の目標摂取カロリー：0〜200kcal
プロテインバー シリアルチョコ ビター(1本36g) (トップバリュ)　1本　182kcal　たんぱく質15g　脂質10.4g　炭水化物8.4ℊ

運動：合計418kcal
HIIT (きつい労力・インターバル)　20分　168kcal
歩行　7393歩　250kcal

エネルギー
過不足判定：不足
摂取量：1266kcal
摂取目標：1405~1805kcal

タンパク質
過不足判定：過剩
摂取量：80.9g
摂取目標：52.2~80.3g

脂質
過不足判定：過剩
摂取量：58.3g
摂取目標：35.7~53.5g

炭水化物
過不足判定：不足
摂取量：109g
摂取目標：200.6~260.8g

カルシウム
過不足判定：不足
摂取量：404mg
摂取目標：650~2500mg

鉄
過不足判定：不足
摂取量：7mg
摂取目標：10.5~40mg

ビタミンA
過不足判定：不足
摂取量：395μg
摂取目標：650~2700μg

ビタミンE
過不足判定：適切
摂取量：11mg
摂取目標：5~650mg

ビタミンB1
過不足判定：不足
摂取量：0.65mg
摂取目標：0.9mg以上

ビタミンB2
過不足判定：適切
摂取量：1.04mg
摂取目標：1mg以上

ビタミンC
過不足判定：適切
摂取量：110mg
摂取目標：100mg以上

食物繊維
過不足判定：不足
摂取量：15.5g
摂取目標：18g以上

飽和脂肪酸
過不足判定：過剩
摂取量：15.98g
摂取目標：12.48g未満

塩分
過不足判定：適切
摂取量：6.3g
摂取目標：6.5g未満

就寝時間：24:00
起床時間：6:30
睡眠時間：6時間30分

今日の調子：良い

お通じ：あり
''';
