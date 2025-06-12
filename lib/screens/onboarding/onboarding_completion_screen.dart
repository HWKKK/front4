import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/widgets/common/primary_button.dart';
import 'package:nompangs/theme/app_theme.dart';
import 'package:nompangs/widgets/personality_chart.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nompangs/services/character_manager.dart';

class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _bounceController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _bounceAnimation;
  final GlobalKey _qrKey = GlobalKey();
  String? _qrUuid;
  bool _creatingQr = false;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    // 축하 애니메이션 시작
    _celebrationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _bounceController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OnboardingProvider>();
      final character = provider.state.generatedCharacter;
      if (character != null) {
        _createQrProfile(character);
      }
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _createQrProfile(Character character) async {
    if (_creatingQr) return;
    setState(() {
      _creatingQr = true;
    });
    final providerState = context.read<OnboardingProvider>();
    final profile = providerState.personalityProfile;
    final userInput = providerState.state.userInput;
    final data = {
      'name': character.name,
      'tags': character.traits,
      'greeting': character.greeting,
      'objectType': character.objectType,
      'personality': {
        'warmth': character.personality.warmth,
        'competence': character.personality.competence,
        'extroversion': character.personality.extroversion,
      },
      'aiPersonalityProfile': profile.aiPersonalityProfile,
      'photoAnalysis': profile.photoAnalysis,
      'lifeStory': profile.lifeStory,
      'humorMatrix': profile.humorMatrix,
      'attractiveFlaws': profile.attractiveFlaws,
      'contradictions': profile.contradictions,
      'communicationStyle': profile.communicationStyle,
      'structuredPrompt': profile.structuredPrompt,
      'location': userInput?.location ?? '',
      'duration': userInput?.duration ?? '',
      'purpose': providerState.state.purpose,
      'humorStyle': providerState.state.humorStyle,
      'photoUrl': providerState.state.photoPath ?? '',
    };
    try {
      final uuid = await CharacterManager.instance.saveCharacterForQR(data);
      if (mounted) {
        setState(() {
          _qrUuid = uuid;
        });
      }
    } catch (e) {
      print('QR 생성 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _creatingQr = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따른 반응형 높이 계산
    final greenHeight = screenHeight * 0.25;
    final pinkHeight = screenHeight * 0.35;
    final blueHeight = screenHeight * 0.4;

    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final character = provider.state.generatedCharacter;

        if (character == null) {
          return const Scaffold(
            body: Center(child: Text('캐릭터 정보를 불러올 수 없습니다.')),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          // AppBar with rounded corners and notification emoji
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFC5FF35),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  left: BorderSide(color: Colors.black, width: 1),
                  right: BorderSide(color: Colors.black, width: 1),
                  bottom: BorderSide(color: Colors.black, width: 1),
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications,
                      size: 16,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${character.name.isNotEmpty ? character.name : '털찐말랑이'}이 깨어났어요!',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
              ),
            ),
          ),
          body: Stack(
            children: [
              // 전체 스크롤 가능한 컨테이너
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80), // 플로팅 버튼 공간
                child: Column(
                  children: [
                    // 분홍색 섹션 (QR 코드)
                    Container(
                      width: double.infinity,
                      height: 140, // 160에서 140으로 줄임 (20px 감소)
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD8F1),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: 15, // 20에서 15로 줄임 (5px 감소)
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 왼쪽: 텍스트와 버튼들
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 110, // 120에서 110으로 줄임 (QR과 맞춤)
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // QR 텍스트 (줄바꿈 추가)
                                    const Text(
                                      'QR을 붙이면\n언제 어디서든 대화할 수 있어요!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    // 저장하기, 공유하기 버튼 (색상 통일)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _saveQRCode(),
                                            icon: const Icon(
                                              Icons.download,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              '저장하기',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF6750A4, // 통일된 색상
                                              ),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              minimumSize: const Size(0, 36),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                () => _shareQRCode(character),
                                            icon: const Icon(
                                              Icons.share,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              '공유하기',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF6750A4, // 통일된 색상
                                              ),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              minimumSize: const Size(0, 36),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // 오른쪽: QR 코드 (연보라색 배경)
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xC8A6FF,
                                ).withOpacity(0.66), // 연보라색 66% 투명도
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: RepaintBoundary(
                                  key: _qrKey,
                                  child: Container(
                                    width: 108, // 110에서 108로 더 줄임
                                    height: 108, // 110에서 108로 더 줄임
                                    padding: const EdgeInsets.all(
                                      0.5,
                                    ), // 1에서 0.5로 더 줄임
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                    ),
                                    child: QrImageView(
                                      data: _generateQRData(character),
                                      version: QrVersions.auto,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 파란색 섹션 (캐릭터 정보) - 아래 라운딩 추가
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C7E8),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            // 캐릭터 이름과 나이
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '털찐말랑이',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '${DateTime.now().year}년 ${DateTime.now().month}월생',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          '멘탈지기',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          provider.state.userInput?.location ??
                                              '우리집 거실',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 촬영한 사진과 말풍선 겹치게 배치
                            SizedBox(
                              height: 420, // 전체 높이 증가하여 말풍선 잘림 방지
                              child: Stack(
                                children: [
                                  // 촬영한 사진 표시 (20px 더 증가)
                                  Container(
                                    width: double.infinity,
                                    height: 230, // 210px에서 230px로 20px 증가
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        provider.state.photoPath != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                File(provider.state.photoPath!),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 230, // 210에서 230으로 변경
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Icon(
                                                    Icons.access_time,
                                                    size: 60,
                                                    color: Colors.red,
                                                  );
                                                },
                                              ),
                                            )
                                            : const Icon(
                                              Icons.access_time,
                                              size: 60,
                                              color: Colors.red,
                                            ),
                                  ),

                                  // bubble@2x.png 이미지 (말풍선 상단 오른쪽에 위치) - 40px 위로
                                  Positioned(
                                    top: 50, // 90에서 50으로 40px 위로 이동
                                    right: 30,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            'assets/ui_assets/bubble@2x.png',
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 버블 배경 이미지 위에 태그와 텍스트 - 20px 위로
                                  Positioned(
                                    top: 90, // 110에서 90으로 20px 위로 이동
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      width: double.infinity,
                                      height: 280, // 높이 더 증가하여 잘림 방지
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            'assets/ui_assets/bubble_bg@2x.png',
                                          ),
                                          fit:
                                              BoxFit
                                                  .fitWidth, // 가로 넓이에 맞춰서 비율 유지
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 50,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // 성격 태그들 (성격 슬라이더 기반)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _buildPersonalityTag(
                                                  _getPersonalityTag1(
                                                    provider.state,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildPersonalityTag(
                                                  _getPersonalityTag2(
                                                    provider.state,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 24),

                                            // 말풍선 텍스트 (버블 배경 위에)
                                            const Column(
                                              children: [
                                                Text(
                                                  '가끔 털이 엉킬까봐 걱정돼 :(',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  '가끔 털이 엉킬까봐 걱정돼 :(',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 성격 차트 추가
                            Builder(
                              builder: (context) {
                                final personalityData =
                                    _generatePersonalityData(provider.state);
                                final traits =
                                    personalityData["성격특성"]
                                        as Map<String, dynamic>;

                                return PersonalityChart(
                                  warmth: (traits["온기"] as double),
                                  competence: (traits["능력"] as double),
                                  extroversion: (traits["외향성"] as double),
                                  creativity: (traits["창의성"] as double),
                                  humour: (traits["유머감각"] as double),
                                  reliability: (traits["신뢰성"] as double),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 플로팅 대화 시작 버튼 (배경없음)
              Positioned(
                left: screenWidth * 0.06,
                right: screenWidth * 0.06,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/chat/${character.id}',
                        arguments: character,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      '지금 바로 대화해요',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalityTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  String _generateQRData(Character character) {
    final data = {
      'characterId': character.id,
      'name': character.name,
      'objectType': character.objectType,
      'personality': {
        'warmth': character.personality.warmth,
        'competence': character.personality.competence,
        'extroversion': character.personality.extroversion,
      },
      'greeting': character.greeting,
      'traits': character.traits,
      'createdAt': character.createdAt?.toIso8601String(),
    };

    return 'nompangs://character?data=${base64Url.encode(utf8.encode(jsonEncode(data)))}';
  }

  Future<void> _saveQRCode() async {
    if (_qrUuid == null) return;
    try {
      // 권한 확인 및 요청
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장소 권한이 필요합니다.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photosAddOnly.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사진 접근 권한이 필요합니다.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // QR 코드 위젯을 이미지로 캡처
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일 생성
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'nompangs_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // 갤러리에 저장
      await Gal.putImage(file.path);

      // 임시 파일 삭제
      await file.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ QR 코드가 갤러리에 저장되었습니다!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('QR 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _shareQRCode(Character character) async {
    if (_qrUuid == null) return;
    try {
      // QR 코드 위젯을 이미지로 캡처
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일 생성
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'nompangs_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // 이미지와 함께 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${character.name}와 함께하세요! 놈팽쓰 QR 코드입니다 🎉\n\nQR을 스캔하면 ${character.name}과 대화할 수 있어요!',
        subject: '놈팽쓰 친구 공유 - ${character.name}',
      );

      // 잠시 후 임시 파일 삭제
      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) {
          file.delete();
        }
      });
    } catch (e) {
      print('QR 공유 오류: $e');
      // 실패 시 기본 텍스트 공유
      final qrData = _generateQRData(character);
      await Share.share(
        '${character.name}와 함께하세요! 놈팽쓰 QR: $qrData',
        subject: '놈팽쓰 친구 공유',
      );
    }
  }

  String _getPersonalityTag1(OnboardingState state) {
    // 첫 번째 태그: 내향성 기반 (수줍음 ↔ 활발함)
    final introversion = state.introversion ?? 5;
    if (introversion <= 3) {
      return '#수줍음';
    } else if (introversion >= 7) {
      return '#활발함';
    } else {
      return '#적당함';
    }
  }

  String _getPersonalityTag2(OnboardingState state) {
    // 두 번째 태그: 감정표현과 유능함 조합 기반
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;

    if (warmth >= 7 && competence >= 7) {
      return '#따뜻하고능숙';
    } else if (warmth >= 7) {
      return '#따뜻함';
    } else if (competence >= 7) {
      return '#능숙함';
    } else if (warmth <= 3 && competence <= 3) {
      return '#차갑고서툰';
    } else if (warmth <= 3) {
      return '#차가움';
    } else if (competence <= 3) {
      return '#서툰';
    } else {
      return '#균형잡힌';
    }
  }

  // 백엔드 스타일의 성격 데이터 생성 (실제로는 API에서 받아올 데이터)
  Map<String, dynamic> _generatePersonalityData(OnboardingState state) {
    // 사용자가 설정한 값을 기반으로 백엔드 스타일 성격특성 생성
    final warmth = (state.warmth ?? 5).toDouble();
    final competence = (state.competence ?? 5).toDouble();
    final introversion = (state.introversion ?? 5).toDouble();

    return {
      "성격특성": {
        "온기": warmth * 10, // 1-10을 10-100으로 변환
        "능력": competence * 10,
        "외향성": (11 - introversion) * 10, // introversion 역변환
        "유머감각": 75.0, // 백엔드에서는 기본적으로 높음
        "창의성": 60 + (warmth * 4), // warmth 기반
        "신뢰성": 50 + (competence * 5), // competence 기반
      },
      "유머스타일": state.humorStyle.isNotEmpty ? state.humorStyle : "따뜻한 유머러스",
      "매력적결함": ["가끔 털이 엉킬까봐 걱정돼 :(", "완벽하게 정리되지 않으면 불안해함", "친구들과 함께 있을 때 더 빛남"],
    };
  }
}
