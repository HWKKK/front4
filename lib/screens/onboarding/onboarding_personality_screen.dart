import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/services/personality_service.dart';

class OnboardingPersonalityScreen extends StatefulWidget {
  const OnboardingPersonalityScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingPersonalityScreen> createState() =>
      _OnboardingPersonalityScreenState();
}

class _OnboardingPersonalityScreenState
    extends State<OnboardingPersonalityScreen> {
  double introversionValue = 0.5;
  double emotionalValue = 0.7;
  double competenceValue = 0.3;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // 베이지 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5DC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.pushNamed(context, '/onboarding/completion'),
            child: const Text(
              '건너뛰기',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // 상단 베이지 섹션 (이미지만)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5DC),
                  padding: const EdgeInsets.only(top: 0, bottom: 10),
                  child: Column(
                    children: [
                      // 중앙 이미지만
                      Center(
                        child: Container(
                          width: screenWidth * 0.8,
                          height: screenWidth * 0.8,
                          child: Image.asset(
                            'assets/ui_assets/placeHolder_1@2x.png',
                            width: screenWidth * 0.8,
                            height: screenWidth * 0.8,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('=== 이미지 로딩 에러 ===');
                              print('Error: $error');
                              print('StackTrace: $stackTrace');
                              print('===================');
                              return Container(
                                width: screenWidth * 0.8,
                                height: screenWidth * 0.8,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      size: 40,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '이미지 로드 실패',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (wasSynchronouslyLoaded) {
                                print('=== 이미지 로딩 성공 (동기) ===');
                                return child;
                              }
                              if (frame == null) {
                                print('=== 이미지 로딩 중... ===');
                                return Container(
                                  width: screenWidth * 0.8,
                                  height: screenWidth * 0.8,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              print('=== 이미지 로딩 성공 (비동기) ===');
                              return child;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 성격 섹션들을 연속적으로 배치
                Column(
                  children: [
                    // 내향성 슬라이더 섹션 (노란색)
                    _buildPersonalitySection(
                      screenWidth: screenWidth,
                      color: const Color(0xFFFFD700),
                      title: '내향성',
                      value: introversionValue,
                      leftLabel: '수줍음',
                      rightLabel: '활발함',
                      onChanged: (value) {
                        setState(() => introversionValue = value);
                        provider.updatePersonalitySlider(
                          'introversion',
                          (value * 10).round(),
                        );
                      },
                    ),

                    // 감정표현 슬라이더 섹션 (주황색)
                    _buildPersonalitySection(
                      screenWidth: screenWidth,
                      color: const Color(0xFFFF8C42),
                      title: '감정표현',
                      value: emotionalValue,
                      leftLabel: '차가운',
                      rightLabel: '따뜻한',
                      onChanged: (value) {
                        setState(() => emotionalValue = value);
                        provider.updatePersonalitySlider(
                          'warmth',
                          (value * 10).round(),
                        );
                      },
                    ),

                    // 유능함 슬라이더 섹션 (초록색)
                    _buildPersonalitySection(
                      screenWidth: screenWidth,
                      color: const Color(0xFF90EE90),
                      title: '유능함',
                      value: competenceValue,
                      leftLabel: '서툰',
                      rightLabel: '능숙한',
                      onChanged: (value) {
                        setState(() => competenceValue = value);
                        provider.updatePersonalitySlider(
                          'competence',
                          (value * 10).round(),
                        );
                      },
                    ),
                  ],
                ),

                // 하단 흰색 섹션 (저장 버튼)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.06,
                    24,
                    screenWidth * 0.06,
                    48,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final provider = context.read<OnboardingProvider>();
                        final service = const PersonalityService();
                        final profile =
                            await service.generateProfile(provider.state);
                        provider.setPersonalityProfile(profile);
                        if (mounted) {
                          Navigator.pushNamed(context, '/onboarding/completion');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        '성격 저장하기',
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
      ),
    );
  }

  Widget _buildPersonalitySection({
    required double screenWidth,
    required Color color,
    required String title,
    required double value,
    required String leftLabel,
    required String rightLabel,
    required Function(double) onChanged,
  }) {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // 제목 (중앙)
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 슬라이더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.black,
                  inactiveTrackColor: Colors.white,
                  thumbColor: Colors.black,
                  thumbShape: RectangularSliderThumbShape(borderColor: color),
                  trackHeight: 8,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  min: 0.0,
                  max: 1.0,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // 라벨들 (슬라이더 아래 양 끝)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    leftLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w200,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    rightLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w200,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 커스텀 썸 모양 (얇은 둥근사각형)
class RectangularSliderThumbShape extends SliderComponentShape {
  const RectangularSliderThumbShape({this.borderColor});

  final Color? borderColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(6, 26); // 높이를 22에서 26으로 증가
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // 테두리 그리기
    if (borderColor != null) {
      final borderPaint =
          Paint()
            ..color = borderColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2; // 1px 테두리

      final borderRect = Rect.fromCenter(center: center, width: 6, height: 26);

      final borderRRect = RRect.fromRectAndRadius(
        borderRect,
        const Radius.circular(3),
      );

      canvas.drawRRect(borderRRect, borderPaint);
    }

    // 썸 본체 그리기
    final paint =
        Paint()
          ..color = sliderTheme.thumbColor ?? Colors.black
          ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(center: center, width: 4, height: 24);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));

    canvas.drawRRect(rrect, paint);
  }
}
