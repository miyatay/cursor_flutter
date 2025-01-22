import 'package:go_router/go_router.dart';
import 'package:example/screen/chat_screen.dart';
import 'package:example/screen/debug_screen.dart';

final router = GoRouter(
  initialLocation: '/debug',
  routes: [
    GoRoute(
      path: '/debug',
      name: 'debug',
      builder: (context, state) => const DebugScreen(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return ChatScreen(
          nickname: extra?['nickname'] ?? '',
          record: extra?['record'] ?? '',
        );
      },
    ),
  ],
); 