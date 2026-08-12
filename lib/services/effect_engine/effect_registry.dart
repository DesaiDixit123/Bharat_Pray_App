import '../../models/jap_models.dart';

/// Central registry of available EffectPacks, decoupling deity visual resolution from core counting logic.
class EffectRegistry {
  static final EffectRegistry _instance = EffectRegistry._internal();
  factory EffectRegistry() => _instance;
  EffectRegistry._internal() {
    _registerBuiltInPresets();
  }

  final Map<String, EffectPack> _packsByCode = {};
  final Map<String, EffectPack> _packsById = {};

  void _registerBuiltInPresets() {
    final presets = [
      EffectPack.shivaPreset,
      EffectPack.krishnaPreset,
      EffectPack.ganeshaPreset,
      EffectPack.hanumanPreset,
      EffectPack.durgaPreset,
      EffectPack.lakshmiPreset,
      EffectPack.vishnuPreset,
      EffectPack.defaultGoldPreset,
    ];
    for (final pack in presets) {
      registerPack(pack);
    }
  }

  /// Registers or updates an EffectPack in the registry
  void registerPack(EffectPack pack) {
    if (pack.code.isNotEmpty) {
      _packsByCode[pack.code.toUpperCase()] = pack;
    }
    if (pack.id.isNotEmpty) {
      _packsById[pack.id] = pack;
    }
  }

  /// Registers multiple EffectPacks
  void registerPacks(List<EffectPack> packs) {
    for (final pack in packs) {
      registerPack(pack);
    }
  }

  /// Retrieves an EffectPack by unique code
  EffectPack? getPackByCode(String code) {
    return _packsByCode[code.toUpperCase()];
  }

  /// Retrieves an EffectPack by ID
  EffectPack? getPackById(String id) {
    return _packsById[id];
  }

  /// Resolves the best-matching EffectPack for a given deity name or particle shape
  EffectPack resolveForDeity({
    required String name,
    String? particleShape,
    String? customTitle,
    String? customSubtitle,
  }) {
    return EffectPack.resolve(
      name: name,
      particleShape: particleShape,
      customTitle: customTitle,
      customSubtitle: customSubtitle,
    );
  }

  /// Default fallback pack
  EffectPack get defaultPack => EffectPack.defaultGoldPreset;

  /// Returns all registered packs
  List<EffectPack> get allPacks => _packsByCode.values.toList();

  /// Clears registry (useful for testing)
  void reset() {
    _packsByCode.clear();
    _packsById.clear();
    _registerBuiltInPresets();
  }
}
