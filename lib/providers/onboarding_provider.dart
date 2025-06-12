import 'package:flutter/foundation.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'dart:math';
import 'dart:convert';

class OnboardingProvider extends ChangeNotifier {
  OnboardingState _state = const OnboardingState();
  PersonalityProfile _profile = PersonalityProfile.empty();

  PersonalityProfile get personalityProfile => _profile;
  
  OnboardingState get state => _state;
  
  void nextStep() {
    _state = _state.copyWith(currentStep: _state.currentStep + 1);
    notifyListeners();
    debugPrint('=== Onboarding Status [nextStep] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  void setUserInput(UserInput input) {
    _state = _state.copyWith(userInput: input);
    notifyListeners();
    debugPrint('=== Onboarding Status [setUserInput] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  /// 용도 업데이트 (Step 3)
  void updatePurpose(String purpose) {
    _state = _state.copyWith(purpose: purpose);
    notifyListeners();
    debugPrint('=== Onboarding Status [updatePurpose] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  /// 유머스타일 업데이트 (Step 3)
  void updateHumorStyle(String style) {
    _state = _state.copyWith(humorStyle: style);
    notifyListeners();
    debugPrint('=== Onboarding Status [updateHumorStyle] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  /// 사진 경로 업데이트 (Step 4)
  void updatePhotoPath(String? path) {
    _state = _state.copyWith(photoPath: path);
    notifyListeners();
    debugPrint('=== Onboarding Status [updatePhotoPath] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  /// 성격 슬라이더 업데이트 (Step 6)
  void updatePersonalitySlider(String type, int value) {
    switch (type) {
      case 'introversion':
        _state = _state.copyWith(introversion: value);
        break;
      case 'warmth':
        _state = _state.copyWith(warmth: value);
        break;
      case 'competence':
        _state = _state.copyWith(competence: value);
        break;
    }
    notifyListeners();
    debugPrint('=== Onboarding Status [updatePersonalitySlider] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  /// QR 코드 URL 업데이트 (완료 단계)
  void updateQRCodeUrl(String url) {
    _state = _state.copyWith(qrCodeUrl: url);
    notifyListeners();
    debugPrint('=== Onboarding Status [updateQRCodeUrl] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  void setPhotoPath(String path) {
    _state = _state.copyWith(photoPath: path);
    notifyListeners();
    debugPrint('=== Onboarding Status [setPhotoPath] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  void setGeneratedCharacter(Character character) {
    _state = _state.copyWith(generatedCharacter: character);
    notifyListeners();
    debugPrint('=== Onboarding Status [setGeneratedCharacter] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  void setError(String error) {
    _state = _state.copyWith(errorMessage: error, isLoading: false);
    notifyListeners();
    debugPrint('=== Onboarding Status [setError] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
    debugPrint('=== Onboarding Status [clearError] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
  
  Future<void> generateCharacter() async {
    if (_state.userInput == null) {
      setError('사용자 입력 정보가 없습니다.');
      return;
    }
    
    _state = _state.copyWith(
      isGenerating: true, 
      generationProgress: 0.0,
      generationMessage: "캐릭터 깨우는 중..."
    );
    notifyListeners();
    debugPrint("=== Onboarding Status [startGenerateCharacter] ===");
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint("===============================");
    
    try {
      // 3단계 시뮬레이션 (Figma 정확)
      await _simulateProgress(0.3, "캐릭터 깨우는 중...");
      await _simulateProgress(0.7, "개성을 찾고 있어요");
      await _simulateProgress(1.0, "마음을 열고 있어요");
      
      // 실제 AI 호출 (향후 구현)
      final character = await _generateMockCharacter();
      
      _state = _state.copyWith(
        generatedCharacter: character,
        isGenerating: false,
        generationProgress: 1.0,
      );
      notifyListeners();
    debugPrint("=== Onboarding Status [generateCharacterComplete] ===");
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint("===============================");
      
    } catch (e) {
      _state = _state.copyWith(
        isGenerating: false,
        errorMessage: '캐릭터 생성 중 오류가 발생했습니다: $e'
      );
      notifyListeners();
    debugPrint("=== Onboarding Status [generateCharacterError] ===");
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint("===============================");
    }
  }
  
  Future<void> _simulateProgress(double target, String message) async {
    while (_state.generationProgress < target) {
      await Future.delayed(const Duration(milliseconds: 200));
      _state = _state.copyWith(
        generationProgress: _state.generationProgress + 0.05,
        generationMessage: message,
      );
      notifyListeners();
      debugPrint("=== Onboarding Status [simulateProgress] ===");
      debugPrint(jsonEncode(_state.toJson()));
      debugPrint(jsonEncode(_profile.toMap()));
      debugPrint("===============================");
    }
  }
  
  Future<Character> _generateMockCharacter() async {
    final userInput = _state.userInput!;
    final random = Random();
    
    // 사용자가 입력한 용도와 유머스타일을 반영한 성격 생성
    final personality = Personality(
      warmth: _state.warmth ?? (50 + random.nextInt(40)),
      competence: _state.competence ?? (30 + random.nextInt(50)), 
      extroversion: _state.introversion ?? (40 + random.nextInt(40)),
    );
    
    final traits = _generateTraits(personality);
    final greeting = _generateGreeting(userInput.nickname, personality);
    
    return Character(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: userInput.nickname,
      objectType: userInput.objectType,
      personality: personality,
      greeting: greeting,
      traits: traits,
      createdAt: DateTime.now(),
    );
  }
  
  List<String> _generateTraits(Personality personality) {
    final traits = <String>[];
    
    if (personality.warmth > 70) {
      traits.add("따뜻한");
    } else if (personality.warmth < 30) {
      traits.add("차분한");
    }
    
    if (personality.competence > 70) {
      traits.add("유능한");
    } else if (personality.competence < 30) {
      traits.add("순수한");
    }
    
    if (personality.extroversion > 70) {
      traits.add("활발한");
    } else if (personality.extroversion < 30) {
      traits.add("내성적인");
    }
    
    return traits;
  }
  
  String _generateGreeting(String nickname, Personality personality) {
    // 유머스타일에 따른 인사말 생성
    final humorStyle = _state.humorStyle ?? '';
    
    if (humorStyle == '따뜻한') {
      return "$nickname아~ 안녕! 따뜻하게 함께하자 💕";
    } else if (humorStyle == '날카로운 관찰자적') {
      return "흠... $nickname. 너에 대해 관찰해보겠어. 흥미롭군.";
    } else if (humorStyle == '위트있는') {
      return "$nickname! 나와 함께라면 재미있을 거야. 위트 한 스푼 넣어서! 😂";
    } else if (humorStyle == '자기비하적') {
      return "어... $nickname? 나 같은 거랑 친해져도 괜찮을까? 😅";
    } else if (humorStyle == '장난꾸러기') {
      return "앗! $nickname 발견! 나랑 장난치자~ 헤헤 😝";
    } else {
      return "안녕 $nickname! 잘 부탁해 😊";
    }
  }
  
  void updatePersonality(PersonalityType type, double value) {
    final currentCharacter = _state.generatedCharacter;
    if (currentCharacter == null) return;
    
    final intValue = value.round();
    Personality updatedPersonality;
    
    switch (type) {
      case PersonalityType.warmth:
        updatedPersonality = currentCharacter.personality.copyWith(warmth: intValue);
        break;
      case PersonalityType.competence:
        updatedPersonality = currentCharacter.personality.copyWith(competence: intValue);
        break;
      case PersonalityType.extroversion:
        updatedPersonality = currentCharacter.personality.copyWith(extroversion: intValue);
        break;
    }
    
    final updatedGreeting = _generateGreeting(currentCharacter.name, updatedPersonality);
    final updatedTraits = _generateTraits(updatedPersonality);
    
    final updatedCharacter = currentCharacter.copyWith(
      personality: updatedPersonality,
      greeting: updatedGreeting,
      traits: updatedTraits,
    );
    
    _state = _state.copyWith(generatedCharacter: updatedCharacter);
    notifyListeners();
    debugPrint('=== Onboarding Status [updatePersonality] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }

  void setPersonalityProfile(PersonalityProfile profile) {
    _profile = profile;
    notifyListeners();
    debugPrint('=== Onboarding Status [setPersonalityProfile] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }

  void reset() {
    _state = const OnboardingState();
    _profile = PersonalityProfile.empty();
    notifyListeners();
    debugPrint('=== Onboarding Status [reset] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }
}
