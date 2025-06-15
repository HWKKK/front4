import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'dart:async';
import 'package:nompangs/screens/auth/intro_screen.dart';
import 'package:nompangs/screens/auth/login_screen.dart';
import 'package:nompangs/screens/main/home_screen.dart';
import 'package:nompangs/screens/auth/register_screen.dart';
import 'package:nompangs/screens/main/qr_scanner_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_intro_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_input_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_purpose_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_photo_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_generation_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_personality_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_completion_screen.dart';
import 'package:nompangs/theme/app_theme.dart';
import 'package:nompangs/services/firebase_manager.dart';
import 'package:nompangs/helpers/deeplink_helper.dart';
import 'package:nompangs/screens/chat/chat_history_screen.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';
import 'package:nompangs/screens/main/new_home_screen.dart';
import 'package:nompangs/screens/main/flutter_mobile_clone.dart';
import 'package:nompangs/models/personality_profile.dart';

String? pendingRoomId;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env 파일 로드 성공!");
  } catch (e) {
    print("🚨 .env 파일 로드 실패: $e");
  }

  await Firebase.initializeApp();
  await FirebaseManager.initialize();

  runApp(NompangsApp());
}

// 간단한 테스트 화면
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('테스트 화면')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChangeNotifierProvider(
                          create:
                              (_) => ChatProvider(
                                characterName: '정적 테스트 봇',
                                characterHandle: '@static_bot',
                                personalityTags: ['테스트', '안정적'],
                                greeting: '정적 캐릭터 테스트를 시작합니다. 무엇이 궁금하신가요?',
                              ),
                          child: const ChatTextScreen(),
                        ),
                  ),
                );
              },
              child: const Text('정적 캐릭터로 채팅 테스트'),
            ),
            Text(
              '테스트 화면',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Flutter iOS가 작동합니다!',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/onboarding/intro');
              },
              child: Text('온보딩 시작'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              child: Text('홈으로 이동'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chat-history');
              },
              child: Text('채팅 히스토리'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/new-home');
              },
              child: Text('뉴홈 화면 UI'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/flutter-mobile-clone');
              },
              child: Text('Flutter 모바일 클론'),
            ),
          ],
        ),
      ),
    );
  }
}

class NompangsApp extends StatefulWidget {
  const NompangsApp({super.key});

  @override
  State<NompangsApp> createState() => _NompangsAppState();
}

class _NompangsAppState extends State<NompangsApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('App Link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) async {
    final roomId = uri.queryParameters['roomId'];
    final uuid = uri.queryParameters['id'];
    print('📦 딥링크 수신됨! URI: $uri, roomId: $roomId, uuid: $uuid');

    if (uuid != null) {
      final chatData = await DeepLinkHelper.processCharacterData(uuid);

      if (chatData != null) {
        _navigatorKey.currentState?.pushNamed(
          '/chat/$uuid',
          arguments: chatData,
        );
      } else {
        DeepLinkHelper.showError(
          _navigatorKey.currentContext!,
          '캐릭터 정보를 불러올 수 없습니다.',
        );
      }
    } else if (roomId != null) {
      DeepLinkHelper.showError(
        _navigatorKey.currentContext!,
        '캐릭터 정보가 없는 QR 코드입니다.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => OnboardingProvider())],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Nompangs',
        theme: AppTheme.lightTheme,
        initialRoute: '/test',
        routes: {
          '/': (context) => IntroScreen(),
          '/test': (context) => TestScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/register': (context) => RegisterScreen(),
          '/qr-scanner': (context) => const QRScannerScreen(),
          '/chat-history': (context) => const ChatHistoryScreen(),
          '/onboarding/intro': (context) => const OnboardingIntroScreen(),
          '/onboarding/input': (context) => const OnboardingInputScreen(),
          '/onboarding/purpose': (context) => const OnboardingPurposeScreen(),
          '/onboarding/photo': (context) => const OnboardingPhotoScreen(),
          '/onboarding/generation':
              (context) => const OnboardingGenerationScreen(),
          '/onboarding/personality':
              (context) => const OnboardingPersonalityScreen(),
          '/onboarding/completion':
              (context) => const OnboardingCompletionScreen(),
          '/new-home': (context) => const NewHomeScreen(),
          '/flutter-mobile-clone': (context) => MainScreen(),
        },
        onGenerateRoute: (settings) {
          final Uri uri = Uri.parse(settings.name ?? '');

          if (uri.pathSegments.length == 2 &&
              uri.pathSegments.first == 'chat') {
            final characterId = uri.pathSegments.last;
            final args = settings.arguments as Map<String, dynamic>?;

            final profile = args?['profile'] as PersonalityProfile?;

            if (profile == null) {
              return MaterialPageRoute(
                builder:
                    (_) => Scaffold(body: Center(child: Text('캐릭터 정보를 전달받지 못했습니다.'))),
              );
            }
            return MaterialPageRoute(
              builder: (context) {
                return ChatScreen(profile: profile);
              },
            );
          }
          return null;
        },
      ),
    );
  }
}
