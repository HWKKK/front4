// Simplified HumorMatrix based on the original python version
class HumorMatrix {
  Map<String, double> dimensions;
  Map<String, double> derivedAttributes;

  HumorMatrix({
    double warmthVsWit = 50,
    double selfVsObservational = 50,
    double subtleVsExpressive = 50,
  })  : dimensions = {
          'warmth_vs_wit': warmthVsWit,
          'self_vs_observational': selfVsObservational,
          'subtle_vs_expressive': subtleVsExpressive,
        },
        derivedAttributes = {
          'sarcasm_level': 0,
          'absurdity_level': 0,
          'wordplay_frequency': 0,
          'callback_tendency': 0,
          'humor_density': 0,
        } {
    _recalculate();
  }

  void _recalculate() {
    final warmth = dimensions['warmth_vs_wit'] ?? 50;
    final selfRef = dimensions['self_vs_observational'] ?? 50;
    final expressive = dimensions['subtle_vs_expressive'] ?? 50;

    derivedAttributes['sarcasm_level'] =
        ((100 - selfRef) * 0.7 + (100 - warmth) * 0.3).clamp(0, 100);
    derivedAttributes['absurdity_level'] = (expressive * 0.8).clamp(0, 100);
    derivedAttributes['wordplay_frequency'] =
        ((100 - warmth) * 0.6 + expressive * 0.2).clamp(0, 100);
    derivedAttributes['callback_tendency'] = (selfRef * 0.8).clamp(0, 100);
    derivedAttributes['humor_density'] =
        (expressive * 0.6 + (100 - warmth) * 0.2).clamp(0, 100);
  }

  Map<String, dynamic> toMap() => {
        ...dimensions,
        'derived_attributes': derivedAttributes,
      };
}

