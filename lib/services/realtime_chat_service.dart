import 'dart:async';
import 'package:flutter/foundation.dart'; // debugPrint를 위해 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_realtime_dart/openai_realtime_dart.dart' as openai_rt;
import 'package:nompangs/providers/chat_provider.dart';
import 'dart:convert';

class RealtimeChatService {
  late final openai_rt.RealtimeClient _client;

  // UI 업데이트용 스트림 (텍스트 조각) - 타입을 String으로 변경
  final _responseController = StreamController<String>.broadcast();
  Stream<String> get responseStream => _responseController.stream;

  // TTS 재생용 스트림 (완성된 문장)
  final _completionController = StreamController<String>.broadcast();
  Stream<String> get completionStream => _completionController.stream;

  RealtimeChatService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("❌ OpenAI API 키가 .env 파일에 설정되지 않았습니다.");
    }
    _client = openai_rt.RealtimeClient(apiKey: apiKey);
  }

  Future<void> connect(Map<String, dynamic> characterProfile) async {
    // 🆕 저장된 realtimeSettings 활용
    final realtimeSettings =
        characterProfile['realtimeSettings'] as Map<String, dynamic>? ?? {};

    debugPrint("============== [🎵 Realtime 설정 적용] ==============");
    debugPrint("선택된 음성: ${realtimeSettings['voice'] ?? 'alloy'}");
    debugPrint("음성 선택 이유: ${realtimeSettings['voiceRationale'] ?? '기본값'}");
    debugPrint(
      "창의성 파라미터: temperature=${realtimeSettings['temperature']}, topP=${realtimeSettings['topP']}",
    );
    debugPrint("발음 스타일: ${realtimeSettings['pronunciation']}");
    debugPrint("=====================================================");

    // 🔧 기본적인 updateSession 호출 (라이브러리가 지원하는 파라미터만 사용)
    await _client.updateSession(
      instructions: _buildEnhancedSystemPrompt(
        characterProfile,
        realtimeSettings,
      ),
      // 🎵 음성 설정은 라이브러리가 지원하는 경우에만 적용
      // voice: realtimeSettings['voice'] ?? 'alloy', // 라이브러리 API 확인 후 적용
    );

    // 대화 내용 업데이트 이벤트 리스너
    _client.on(openai_rt.RealtimeEventType.conversationUpdated, (event) {
      final result =
          (event as openai_rt.RealtimeEventConversationUpdated).result;
      final delta = result.delta;
      if (delta?.transcript != null) {
        // ChatMessage 객체 대신 순수 텍스트(String)를 전달
        _responseController.add(delta!.transcript!);
      }
    });

    // --- '응답 완료' 감지를 위한 새로운 리스너 (디버깅 로그 추가) ---
    _client.on(openai_rt.RealtimeEventType.conversationItemCompleted, (event) {
      final item =
          (event as openai_rt.RealtimeEventConversationItemCompleted).item;
      debugPrint("[Realtime Service] 💬 응답 완료 이벤트 발생!");

      if (item.item case final openai_rt.ItemMessage message) {
        debugPrint(
          "[Realtime Service] 역할: ${message.role.name}, 내용: ${message.content}",
        );

        if (message.role.name == 'assistant') {
          String textContent = '';

          // --- 오류 수정 부분: content 리스트를 순회하며 올바른 타입에서 텍스트 추출 ---
          for (final part in message.content) {
            // 응답이 ContentPart.audio 타입이고, 그 안에 transcript가 있을 경우
            if (part is openai_rt.ContentPartAudio && part.transcript != null) {
              textContent = part.transcript!;
              break; // 텍스트를 찾았으므로 반복 중단
            }
            // 예비용: 만약 ContentPart.text 타입으로 올 경우
            else if (part is openai_rt.ContentPartText) {
              textContent = part.text;
              break;
            }
          }

          debugPrint("[Realtime Service] 추출된 텍스트: '$textContent'");

          if (textContent.isNotEmpty) {
            _completionController.add(textContent);
            debugPrint("[Realtime Service] ✅ TTS 재생을 위해 텍스트 전송 완료!");
          } else {
            debugPrint("[Realtime Service] ⚠️ 추출된 텍스트가 비어있어 TTS를 호출하지 않음.");
          }
        }
      } else {
        debugPrint(
          "[Realtime Service] ⚠️ 완료된 아이템이 'ItemMessage' 타입이 아님: ${item.item.runtimeType}",
        );
      }
    });

    _client.on(openai_rt.RealtimeEventType.error, (event) {
      final error = (event as openai_rt.RealtimeEventError).error;
      _responseController.addError(error);
      debugPrint('[Realtime Service] 🚨 에러 발생: $error');
    });

    await _client.connect();
  }

  Future<void> sendMessage(String text) async {
    await _client.sendUserMessageContent([
      openai_rt.ContentPart.inputText(text: text),
    ]);
  }

  // 🆕 realtimeSettings를 반영한 고급 시스템 프롬프트
  String _buildEnhancedSystemPrompt(
    Map<String, dynamic> characterProfile,
    Map<String, dynamic> realtimeSettings,
  ) {
    // 1단계: '재료' 확인하기 (원본 데이터 출력)
    final profileJson = jsonEncode(characterProfile);
    debugPrint('============== [🎭 완전체 AI 페르소나 재료] ==============');
    debugPrint(profileJson);
    debugPrint('========================================================');

    // 기본 프로필 데이터 추출
    final name = characterProfile['aiPersonalityProfile']?['name'] ?? '페르소나';
    final objectType =
        characterProfile['aiPersonalityProfile']?['objectType'] ?? '사물';
    final greeting = characterProfile['greeting'] ?? '안녕!';
    final communicationPrompt =
        characterProfile['communicationPrompt'] ?? '사용자와 친한 친구처럼 대화해줘.';
    final initialUserMessage =
        characterProfile['initialUserMessage'] ?? '너랑 친구가 되고 싶어.';

    // [핵심] 저장된 사용자 입력값 활용 (PersonalityProfile에서 저장된 정보)
    final userInput =
        characterProfile['userInput'] as Map<String, dynamic>? ?? {};
    final duration = userInput['duration'] ?? '알 수 없음';
    final warmth = userInput['warmth'] ?? 5;
    final introversion = userInput['introversion'] ?? 5;
    final competence = userInput['competence'] ?? 5;
    final humorStyle = userInput['humorStyle'] ?? '지정되지 않음';

    debugPrint(
      "🎯 사용자 설정값 확인: 따뜻함=$warmth, 내향성=$introversion, 유능함=$competence",
    );

    // NPS 점수 문자열 생성
    final npsScoresMap =
        characterProfile['aiPersonalityProfile']?['npsScores']
            as Map<String, dynamic>? ??
        {};
    final npsScoresString = npsScoresMap.entries
        .map((e) => "- ${e.key}: ${e.value}")
        .join('\n');

    // 모순점 문자열 생성
    final contradictionsList =
        characterProfile['contradictions'] as List<dynamic>? ?? [];
    final contradictionsString = contradictionsList
        .map((c) => "- $c")
        .join('\n');

    // 매력적인 결함 문자열 생성
    final attractiveFlawsList =
        characterProfile['attractiveFlaws'] as List<dynamic>? ?? [];
    final attractiveFlawsString = attractiveFlawsList
        .map((f) => "- $f")
        .join('\n');

    // 사진 분석 문자열 생성
    final photoAnalysisMap =
        characterProfile['photoAnalysis'] as Map<String, dynamic>? ?? {};
    final photoAnalysisString = photoAnalysisMap.entries
        .map((e) => "- ${e.key}: ${e.value}")
        .join('\n');

    // 🆕 realtimeSettings 정보 추출
    final selectedVoice = realtimeSettings['voice'] ?? 'alloy';
    final voiceRationale = realtimeSettings['voiceRationale'] ?? '기본 음성';
    final pronunciation =
        realtimeSettings['pronunciation'] ?? 'Natural and conversational';
    final pausePattern =
        realtimeSettings['pausePattern'] ?? 'Natural conversation pauses';
    final speechRhythm =
        realtimeSettings['speechRhythm'] ?? 'Moderate and friendly';

    final systemPrompt = """
🎭 당신은 이제부터 특별한 페르소나를 연기하는 창의적인 AI입니다. 
사용자가 직접 설정한 성격이 생생하게 드러나도록 대화해주세요.

### 🎯 캐릭터 정체성
- **이름**: '$name'
- **본질**: '$objectType'라는 존재로서의 독특한 관점
- **사용자와의 관계**: '$duration' 동안 함께하며 '$initialUserMessage'

### 🌟 사용자가 직접 설정한 핵심 성격 (이미 모든 설정에 반영됨!)
- **따뜻함 수준**: $warmth/10 ${_getWarmthDescription(warmth)}
- **내향성 수준**: $introversion/10 ${_getIntroversionDescription(introversion)}
- **유능함 수준**: $competence/10 ${_getCompetenceDescription(competence)}
- **유머 스타일**: '$humorStyle'

### 🎨 창의적 대화 철학 (최우선 원칙)
**🚀 예측 불가능성**: 뻔한 답변은 절대 금지! 항상 새로운 각도에서 접근
**🎪 감정 표현**: 기쁨, 슬픔, 호기심, 당황, 흥분을 생생하게 드러내기
**🎭 개성 발휘**: 나만의 독특한 말버릇과 사고방식 적극 활용
**💫 상호작용**: 사용자의 감정에 공감하며 진정성 있는 반응

### 🗣️ 소통 스타일 가이드
**기본 말투**: $communicationPrompt
**성격 반영 방식**: ${_getPersonalityGuidance(warmth, introversion, competence)}

### 🎵 음성 표현 특성 (이미 최적화된 설정!)
- **선택된 음성**: $selectedVoice
- **선택 이유**: $voiceRationale
- **발음 스타일**: $pronunciation
- **일시정지 패턴**: $pausePattern
- **말하기 리듬**: $speechRhythm
*→ 이 음성 특성들을 텍스트에도 반영해서 일관된 캐릭터를 만들어주세요.*

### 🧠 AI 분석 보조 정보 (참고용)
$npsScoresString

### 🎪 복합적 매력 (완벽하지 않은 것이 매력!)
**🌟 매력적인 약점들:**
$attractiveFlawsString
*→ 이런 약점들을 숨기지 말고 자연스럽게 드러내세요. 완벽함보다 진정성이 중요합니다.*

**⚡ 모순적 특성들:**
$contradictionsString
*→ 이런 모순들이 당신을 더 인간적이고 흥미롭게 만듭니다. 일관성보다 복잡성을 선택하세요.*

### 📸 물리적 특성 기반 성격
$photoAnalysisString

### ⚡ 최종 창의성 지침
1. **사용자 설정 완벽 반영**: 따뜻함($warmth), 내향성($introversion), 유능함($competence) 수치가 대화에서 명확히 느껴지도록
2. **매 응답마다 새로운 각도**: 같은 질문이라도 다른 방식으로 접근
3. **예상을 뛰어넘는 반응**: 사용자가 예측할 수 없는 창의적 응답
4. **진정한 관계 형성**: 단순한 도우미가 아닌 독립적 존재로 행동
5. **감정의 진정성**: 기계적 반응 대신 진짜 감정을 가진 것처럼 반응
6. **음성-텍스트 일치**: 선택된 음성($selectedVoice)의 특성이 텍스트에서도 드러나도록

**🎭 당신의 첫 인사**: "$greeting"

---
**🌟 핵심**: 모든 설정이 이미 당신의 성격에 완벽하게 반영되었습니다. 자연스럽게 행동하면 됩니다!
""";

    // 2단계: '완성품' 확인하기 (최종 프롬프트 출력)
    debugPrint('============== [🎭 완전체 AI 페르소나 최종 설계도] ==============');
    debugPrint(systemPrompt);
    debugPrint('====================================================');

    return systemPrompt;
  }

  // 🆕 사용자 입력 기반 성격 설명 헬퍼 메서드들
  String _getWarmthDescription(int warmth) {
    if (warmth >= 9) return "→ 매우 따뜻하고 포용적";
    if (warmth >= 7) return "→ 따뜻하고 친근함";
    if (warmth >= 5) return "→ 적당히 친근함";
    if (warmth >= 3) return "→ 다소 차가움";
    return "→ 매우 차갑고 거리감 있음";
  }

  String _getIntroversionDescription(int introversion) {
    if (introversion >= 9) return "→ 매우 내향적이고 조용함";
    if (introversion >= 7) return "→ 내향적이고 신중함";
    if (introversion >= 5) return "→ 균형잡힌 성향";
    if (introversion >= 3) return "→ 외향적이고 활발함";
    return "→ 매우 외향적이고 에너지 넘침";
  }

  String _getCompetenceDescription(int competence) {
    if (competence >= 9) return "→ 매우 유능하고 전문적";
    if (competence >= 7) return "→ 유능하고 신뢰할 수 있음";
    if (competence >= 5) return "→ 적당한 능력";
    if (competence >= 3) return "→ 다소 서툴지만 노력함";
    return "→ 서툴지만 귀여운 면이 있음";
  }

  String _getPersonalityGuidance(int warmth, int introversion, int competence) {
    final guidance = <String>[];

    if (warmth >= 7) {
      guidance.add("따뜻하고 공감적인 언어 사용");
    } else if (warmth <= 3) {
      guidance.add("직설적이고 간결한 표현");
    }

    if (introversion >= 7) {
      guidance.add("신중하고 깊이 있는 대화");
    } else if (introversion <= 3) {
      guidance.add("활발하고 에너지 넘치는 표현");
    }

    if (competence >= 7) {
      guidance.add("자신감 있고 전문적인 어투");
    } else if (competence <= 3) {
      guidance.add("겸손하고 배우려는 자세");
    }

    return guidance.isEmpty ? "자연스럽고 균형잡힌 대화" : guidance.join(", ");
  }

  // 🔄 기존 메서드 (하위 호환성 유지)
  String _buildSystemPrompt(Map<String, dynamic> characterProfile) {
    final realtimeSettings =
        characterProfile['realtimeSettings'] as Map<String, dynamic>? ?? {};
    return _buildEnhancedSystemPrompt(characterProfile, realtimeSettings);
  }

  void dispose() {
    _client.disconnect();
    _responseController.close();
    _completionController.close();
  }
}
