class PersonalityProfile {
  final Map<String, int> variables;
  final Map<String, dynamic> aiPersonalityProfile;
  final Map<String, dynamic> photoAnalysis;
  final Map<String, dynamic> lifeStory;
  final Map<String, dynamic> humorMatrix;
  final List<String> attractiveFlaws;
  final List<String> contradictions;
  final Map<String, dynamic> communicationStyle;
  final String structuredPrompt;

  const PersonalityProfile({
    this.variables = const {},
    required this.aiPersonalityProfile,
    required this.photoAnalysis,
    required this.lifeStory,
    required this.humorMatrix,
    required this.attractiveFlaws,
    required this.contradictions,
    required this.communicationStyle,
    required this.structuredPrompt,
  });

  factory PersonalityProfile.empty() => const PersonalityProfile(
        variables: {},
        aiPersonalityProfile: {},
        photoAnalysis: {},
        lifeStory: {},
        humorMatrix: {},
        attractiveFlaws: [],
        contradictions: [],
        communicationStyle: {},
        structuredPrompt: '',
      );

  Map<String, dynamic> toMap() => {
        'variables': variables,
        'aiPersonalityProfile': aiPersonalityProfile,
        'photoAnalysis': photoAnalysis,
        'lifeStory': lifeStory,
        'humorMatrix': humorMatrix,
        'attractiveFlaws': attractiveFlaws,
        'contradictions': contradictions,
        'communicationStyle': communicationStyle,
        'structuredPrompt': structuredPrompt,
      };
}
