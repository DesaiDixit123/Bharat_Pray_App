class TtsVoice {
  final String id;
  final String name;
  final String gender;
  final String locale;
  final String tier;
  final List<String> languages;
  final String title;
  final String description;
  final String previewUrl;
  final double defaultRate;
  final bool isDefault;
  final String languageCategory;
  final bool isCustom;
  final double pitch;
  final String? baseVoiceId;
  final String? localAudioSample;

  const TtsVoice({
    required this.id,
    required this.name,
    required this.gender,
    required this.locale,
    required this.tier,
    required this.languages,
    required this.title,
    required this.description,
    required this.previewUrl,
    required this.defaultRate,
    required this.isDefault,
    required this.languageCategory,
    this.isCustom = false,
    this.pitch = 0.0,
    this.baseVoiceId,
    this.localAudioSample,
  });

  factory TtsVoice.fromJson(Map<String, dynamic> json) {
    return TtsVoice(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      gender: (json['gender'] ?? 'Male').toString(),
      locale: (json['locale'] ?? 'hi-IN').toString(),
      tier: (json['tier'] ?? 'Standard').toString(),
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Hindi'],
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      previewUrl: (json['previewUrl'] ?? '').toString(),
      defaultRate: (json['defaultRate'] is num)
          ? (json['defaultRate'] as num).toDouble()
          : 0.90,
      isDefault: json['isDefault'] == true,
      languageCategory: (json['languageCategory'] ?? 'Hindi').toString(),
      isCustom: json['isCustom'] == true,
      pitch: (json['pitch'] is num) ? (json['pitch'] as num).toDouble() : 0.0,
      baseVoiceId: json['baseVoiceId']?.toString(),
      localAudioSample: json['localAudioSample']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'locale': locale,
      'tier': tier,
      'languages': languages,
      'title': title,
      'description': description,
      'previewUrl': previewUrl,
      'defaultRate': defaultRate,
      'isDefault': isDefault,
      'languageCategory': languageCategory,
      'isCustom': isCustom,
      'pitch': pitch,
      'baseVoiceId': baseVoiceId,
      'localAudioSample': localAudioSample,
    };
  }
}

class TtsPreferences {
  String gujaratiVoiceId;
  String hindiVoiceId;
  String sanskritVoiceId;
  String englishVoiceId;
  double speakingRate;
  double pitch;

  TtsPreferences({
    this.gujaratiVoiceId = 'gu-IN-Chirp3-HD-Kore',
    this.hindiVoiceId = 'hi-IN-Chirp3-HD-Kore',
    this.sanskritVoiceId = 'hi-IN-Chirp3-HD-Charon',
    this.englishVoiceId = 'en-IN-Neural2-D',
    this.speakingRate = 0.92,
    this.pitch = 0.0,
  });

  factory TtsPreferences.fromJson(Map<String, dynamic> json) {
    return TtsPreferences(
      gujaratiVoiceId: (json['gujaratiVoiceId'] ?? 'gu-IN-Chirp3-HD-Kore').toString(),
      hindiVoiceId: (json['hindiVoiceId'] ?? 'hi-IN-Chirp3-HD-Kore').toString(),
      sanskritVoiceId: (json['sanskritVoiceId'] ?? 'hi-IN-Chirp3-HD-Charon').toString(),
      englishVoiceId: (json['englishVoiceId'] ?? 'en-IN-Neural2-D').toString(),
      speakingRate: (json['speakingRate'] is num)
          ? (json['speakingRate'] as num).toDouble()
          : 0.92,
      pitch: (json['pitch'] is num) ? (json['pitch'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gujaratiVoiceId': gujaratiVoiceId,
      'hindiVoiceId': hindiVoiceId,
      'sanskritVoiceId': sanskritVoiceId,
      'englishVoiceId': englishVoiceId,
      'speakingRate': speakingRate,
      'pitch': pitch,
    };
  }

  TtsPreferences copyWith({
    String? gujaratiVoiceId,
    String? hindiVoiceId,
    String? sanskritVoiceId,
    String? englishVoiceId,
    double? speakingRate,
    double? pitch,
  }) {
    return TtsPreferences(
      gujaratiVoiceId: gujaratiVoiceId ?? this.gujaratiVoiceId,
      hindiVoiceId: hindiVoiceId ?? this.hindiVoiceId,
      sanskritVoiceId: sanskritVoiceId ?? this.sanskritVoiceId,
      englishVoiceId: englishVoiceId ?? this.englishVoiceId,
      speakingRate: speakingRate ?? this.speakingRate,
      pitch: pitch ?? this.pitch,
    );
  }
}
