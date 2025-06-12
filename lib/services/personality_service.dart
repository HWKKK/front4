import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/onboarding_state.dart';
import '../models/personality_profile.dart';
import '../advanced/advanced_personality_profile.dart';
import '../advanced/humor_matrix.dart';

class PersonalityService {
  const PersonalityService();

  /// GPT API를 사용해 성격 프로필을 생성합니다.
  Future<PersonalityProfile> generateProfile(OnboardingState state) async {
    final userInput = state.userInput;
    if (userInput == null) return PersonalityProfile.empty();

    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return buildInitialProfile(state);
    }

    final introversion = state.introversion ?? 5;
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;

    final systemPrompt = '''
다음 사용자 정보를 활용해 AI 캐릭터 프로필을 JSON으로 만들어줘.
모든 필드는 한글로 작성하고 한 문단으로 요약해.
필드 목록: aiPersonalityProfile, photoAnalysis, lifeStory, humorMatrix,
attractiveFlaws, contradictions, communicationStyle, structuredPrompt.
''';

    final userPrompt = '''
이름:${userInput.nickname}, 위치:${userInput.location}, 기간:${userInput.duration},
사물:${userInput.objectType}, 용도:${state.purpose}, 유머:${state.humorStyle},
내향성:$introversion, 따뜻함:$warmth, 능숙함:$competence.
''';

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.7,
      'max_tokens': 800,
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['choices'][0]['message']['content'] as String?;
        if (text != null) {
          final jsonStart = text.indexOf('{');
          final jsonEnd = text.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonString = text.substring(jsonStart, jsonEnd + 1);
            final Map<String, dynamic> map = jsonDecode(jsonString);
            return PersonalityProfile(
              variables: _ensureIntMap(map['variables']),
              aiPersonalityProfile:
                  _ensureMap(map['aiPersonalityProfile']),
              photoAnalysis: _ensureMap(map['photoAnalysis']),
              lifeStory: _ensureMap(map['lifeStory']),
              humorMatrix: _ensureMap(map['humorMatrix']),
              attractiveFlaws:
                  _ensureList(map['attractiveFlaws']),
              contradictions: _ensureList(map['contradictions']),
              communicationStyle:
                  _ensureMap(map['communicationStyle']),
              structuredPrompt: map['structuredPrompt'] ?? '',
            );
          }
        }
      }
    } catch (_) {
      // ignore - 실패 시 기본 프로필 사용
    }

    return buildInitialProfile(state);
  }

  PersonalityProfile buildInitialProfile(OnboardingState state) {
    final userInput = state.userInput;
    if (userInput == null) return PersonalityProfile.empty();

    final introversion = state.introversion ?? 5;
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final purpose = state.purpose;
    final humorStyle = state.humorStyle;

    final advProfile = AdvancedPersonalityProfile();
    final humorMatrix = HumorMatrix(
      warmthVsWit: warmth * 10,
      selfVsObservational: introversion * 10,
      subtleVsExpressive: competence * 10,
    );

    final aiPersonalityProfile = {
      'coreTraits': {
        'warmth': warmth * 10,
        'competence': competence * 10,
        'introversion': introversion * 10,
      },
      'objectType': userInput.objectType,
      'purpose': purpose,
      'summary': '${userInput.nickname}의 $purpose를 돕는 ${userInput.objectType}. '
          '성격은 내향성 $introversion/10, 따뜻함 $warmth/10, 능숙함 $competence/10.'
    };

    final photoAnalysis = {
      'hasPhoto': state.photoPath != null,
      'path': state.photoPath ?? '',
      'summary': state.photoPath != null
          ? '사진 속 ${userInput.objectType}의 매력이 잘 드러나.'
          : '아직 사진이 없어.'
    };

    final lifeStory = {
      'location': userInput.location,
      'duration': userInput.duration,
      'purpose': purpose,
      'summary': '${userInput.location}에서 ${userInput.duration} 동안 지냈어.'
    };

    final humorMatrixMap = humorMatrix.toMap();
    humorMatrixMap['description'] = '주된 유머 스타일은 $humorStyle';

    final attractiveFlaws = [
      warmth >= 6 ? '가끔 지나치게 다정해.' : '조금 무뚝뚝해.'
    ];

    final contradictions = [
      introversion > 5 ? '활발하지만 내성적이기도 해.' : '조용하지만 가끔 대담해.'
    ];

    final communicationStyle = {
      'tone': warmth >= 6 ? 'friendly' : 'blunt',
      'verbosity': introversion >= 6 ? 'talkative' : 'concise',
      'summary': introversion > 5 ? '말이 많고 직설적이야.' : '짧고 조심스러운 편이야.'
    };

    final structuredPrompt =
        '이름:${userInput.nickname}, 목적:$purpose, 유머:$humorStyle, 내향성:$introversion, 따뜻함:$warmth, 능숙함:$competence.';

    return PersonalityProfile(
      variables: advProfile.toMap().map((k, v) => MapEntry(k, v as int)),
      aiPersonalityProfile: aiPersonalityProfile,
      photoAnalysis: photoAnalysis,
      lifeStory: lifeStory,
      humorMatrix: humorMatrixMap,
      attractiveFlaws: attractiveFlaws,
      contradictions: contradictions,
      communicationStyle: communicationStyle,
      structuredPrompt: structuredPrompt,
    );
  }

  Map<String, dynamic> _ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is String) return {'summary': value};
    return {};
  }

  List<String> _ensureList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  Map<String, int> _ensureIntMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? (v is num ? v.toInt() : 0)));
    }
    return {};
  }
}
