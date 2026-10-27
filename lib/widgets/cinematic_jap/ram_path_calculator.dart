import 'package:flutter/material.dart';

/// Represents a feathered radial reveal node on the divine portrait.
class RevealNode {
  final int step; // 0..107
  final double u; // Normalized X (0.0 = left, 1.0 = right relative to portrait dstRect)
  final double v; // Normalized Y (0.0 = top, 1.0 = bottom relative to portrait dstRect)
  final double radiusNorm; // Normalized radius (e.g. 0.18)
  final String label;

  const RevealNode({
    required this.step,
    required this.u,
    required this.v,
    this.radiusNorm = 0.18,
    required this.label,
  });

  /// Calculates the screen offset mapped to the aspect-ratio fitted portrait rect.
  Offset toScreenOffset(Size screenSize) {
    final dstRect = RamPathCalculator.computeDstRect(screenSize);
    return Offset(
      dstRect.left + (u * dstRect.width),
      dstRect.top + (v * dstRect.height),
    );
  }

  /// Calculates the screen radius mapped to the aspect-ratio fitted portrait rect.
  /// Normalized strictly against width so radius is tightly bounded on all mobile devices.
  double toScreenRadius(Size screenSize) {
    final dstRect = RamPathCalculator.computeDstRect(screenSize);
    return radiusNorm * dstRect.width;
  }
}

/// Precomputed 108-step deterministic reveal plan with strict face-last protection
/// and smooth curved trajectory calculation from the circular mala.
class RamPathCalculator {
  static const int targetJapCount = 108;

  /// Face protection box: Lord Ram's divine face region.
  /// Strictly bounds forehead, tilak, eyes, nose, cheeks, lips, and chin.
  /// NO reveal node touches this region until Jap 103 (index 102)!
  static const Rect faceBox = Rect.fromLTRB(0.35, 0.23, 0.65, 0.40);

  /// Computes the aspect-ratio fitted destination rect for the portrait (BoxFit.cover).
  static Rect computeDstRect(Size size, {double imageAspect = 682.0 / 1024.0}) {
    if (size.width <= 0 || size.height <= 0) return Rect.zero;
    final double screenRatio = size.width / size.height;
    double dstW, dstH, dstX, dstY;
    if (screenRatio > imageAspect) {
      dstW = size.width;
      dstH = size.width / imageAspect;
      dstX = 0.0;
      dstY = (size.height - dstH) / 2.0;
    } else {
      dstH = size.height;
      dstW = size.height * imageAspect;
      dstY = 0.0;
      dstX = (size.width - dstW) / 2.0;
    }
    return Rect.fromLTWH(dstX, dstY, dstW, dstH);
  }

  /// Precomputed 108 reveal nodes with multi-region dispersion:
  /// Every chant reveals a DIFFERENT area around the deity (cycling through Top Halo,
  /// Bottom Pitambar, Right Bow, Left Quiver, Crown, Chest, Ears), preventing clustering in any single area.
  /// Face region is strictly locked in pure darkness until the grand finale (Japs 103..108).
  static final List<RevealNode> revealNodes = _build108RevealNodes();

  static List<RevealNode> _build108RevealNodes() {
    final list = <RevealNode>[];

    // ── Distributed Non-Face Reveal (Japs 1..102) ──────────────────────────
    // Each chant lands on a DIFFERENT, dispersed region across the deity:
    // cycling through Halo, Pitambar, Right Bow, Left Quiver, Crown, Chest, Ears.
    // Face region is strictly preserved in pure darkness until Jap 103!

    list.add(const RevealNode(
      step: 0,
      u: 0.14,
      v: 0.03,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 1,
      u: 0.14,
      v: 0.8,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 2,
      u: 0.84,
      v: 0.24,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 3,
      u: 0.08,
      v: 0.24,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 4,
      u: 0.33,
      v: 0.12,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 5,
      u: 0.3,
      v: 0.52,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 6,
      u: 0.22,
      v: 0.33,
      radiusNorm: 0.065,
      label: 'Ear Kundals, Hair Curls & Crown Base',
    ));
    list.add(const RevealNode(
      step: 7,
      u: 0.764,
      v: 0.05,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 8,
      u: 0.691,
      v: 0.881,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 9,
      u: 0.873,
      v: 0.621,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 10,
      u: 0.113,
      v: 0.621,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 11,
      u: 0.625,
      v: 0.142,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 12,
      u: 0.7,
      v: 0.52,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 13,
      u: 0.56,
      v: 0.42,
      radiusNorm: 0.065,
      label: 'Ear Kundals, Hair Curls & Crown Base',
    ));
    list.add(const RevealNode(
      step: 14,
      u: 0.38,
      v: 0.073,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 15,
      u: 0.352,
      v: 0.896,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 16,
      u: 0.909,
      v: 0.387,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 17,
      u: 0.149,
      v: 0.387,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 18,
      u: 0.443,
      v: 0.168,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 19,
      u: 0.454,
      v: 0.614,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 20,
      u: 0.22,
      v: 0.37,
      radiusNorm: 0.065,
      label: 'Ear Kundals, Hair Curls & Crown Base',
    ));
    list.add(const RevealNode(
      step: 21,
      u: 0.62,
      v: 0.073,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 22,
      u: 0.564,
      v: 0.915,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 23,
      u: 0.909,
      v: 0.533,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 24,
      u: 0.149,
      v: 0.533,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 25,
      u: 0.557,
      v: 0.168,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 26,
      u: 0.608,
      v: 0.586,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 27,
      u: 0.44,
      v: 0.42,
      radiusNorm: 0.065,
      label: 'Ear Kundals, Hair Curls & Crown Base',
    ));
    list.add(const RevealNode(
      step: 28,
      u: 0.236,
      v: 0.05,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 29,
      u: 0.225,
      v: 0.843,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 30,
      u: 0.873,
      v: 0.299,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 31,
      u: 0.113,
      v: 0.299,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 32,
      u: 0.375,
      v: 0.142,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 33,
      u: 0.362,
      v: 0.566,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 34,
      u: 0.66,
      v: 0.33,
      radiusNorm: 0.065,
      label: 'Ear Kundals, Hair Curls & Crown Base',
    ));
    list.add(const RevealNode(
      step: 35,
      u: 0.86,
      v: 0.03,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 36,
      u: 0.775,
      v: 0.843,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 37,
      u: 0.84,
      v: 0.68,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 38,
      u: 0.08,
      v: 0.68,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 39,
      u: 0.67,
      v: 0.12,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 40,
      u: 0.515,
      v: 0.619,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 41,
      u: 0.66,
      v: 0.37,
      radiusNorm: 0.065,
      label: 'Ear Kundals, Hair Curls & Crown Base',
    ));
    list.add(const RevealNode(
      step: 42,
      u: 0.476,
      v: 0.08,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 43,
      u: 0.436,
      v: 0.915,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 44,
      u: 0.92,
      v: 0.445,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 45,
      u: 0.16,
      v: 0.445,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 46,
      u: 0.489,
      v: 0.175,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 47,
      u: 0.669,
      v: 0.544,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 48,
      u: 0.716,
      v: 0.059,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 49,
      u: 0.648,
      v: 0.896,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 50,
      u: 0.887,
      v: 0.592,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 51,
      u: 0.127,
      v: 0.592,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 52,
      u: 0.602,
      v: 0.152,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 53,
      u: 0.423,
      v: 0.602,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 54,
      u: 0.332,
      v: 0.067,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 55,
      u: 0.309,
      v: 0.881,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 56,
      u: 0.899,
      v: 0.357,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 57,
      u: 0.139,
      v: 0.357,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 58,
      u: 0.421,
      v: 0.161,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 59,
      u: 0.577,
      v: 0.602,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 60,
      u: 0.572,
      v: 0.078,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 61,
      u: 0.86,
      v: 0.8,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 62,
      u: 0.916,
      v: 0.504,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 63,
      u: 0.156,
      v: 0.504,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 64,
      u: 0.534,
      v: 0.172,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 65,
      u: 0.331,
      v: 0.544,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 66,
      u: 0.188,
      v: 0.04,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 67,
      u: 0.521,
      v: 0.919,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 68,
      u: 0.857,
      v: 0.269,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 69,
      u: 0.097,
      v: 0.269,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 70,
      u: 0.353,
      v: 0.131,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 71,
      u: 0.485,
      v: 0.619,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 72,
      u: 0.812,
      v: 0.04,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 73,
      u: 0.182,
      v: 0.822,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 74,
      u: 0.857,
      v: 0.651,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 75,
      u: 0.097,
      v: 0.651,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 76,
      u: 0.647,
      v: 0.131,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 77,
      u: 0.638,
      v: 0.566,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 78,
      u: 0.428,
      v: 0.078,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 79,
      u: 0.733,
      v: 0.863,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 80,
      u: 0.916,
      v: 0.416,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 81,
      u: 0.156,
      v: 0.416,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 82,
      u: 0.466,
      v: 0.172,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 83,
      u: 0.392,
      v: 0.586,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 84,
      u: 0.668,
      v: 0.067,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 85,
      u: 0.394,
      v: 0.907,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 86,
      u: 0.899,
      v: 0.563,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 87,
      u: 0.139,
      v: 0.563,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 88,
      u: 0.579,
      v: 0.161,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 89,
      u: 0.546,
      v: 0.614,
      radiusNorm: 0.08,
      label: 'Shoulders, Arms & Sacred Necklaces',
    ));
    list.add(const RevealNode(
      step: 90,
      u: 0.284,
      v: 0.059,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 91,
      u: 0.606,
      v: 0.907,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 92,
      u: 0.887,
      v: 0.328,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 93,
      u: 0.127,
      v: 0.328,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 94,
      u: 0.398,
      v: 0.152,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 95,
      u: 0.524,
      v: 0.08,
      radiusNorm: 0.08,
      label: 'Peacock Feather & Upper Temple Halo',
    ));
    list.add(const RevealNode(
      step: 96,
      u: 0.267,
      v: 0.863,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 97,
      u: 0.92,
      v: 0.475,
      radiusNorm: 0.08,
      label: 'Golden Kodanda Bow Right',
    ));
    list.add(const RevealNode(
      step: 98,
      u: 0.16,
      v: 0.475,
      radiusNorm: 0.08,
      label: 'Quiver & Arrows Left',
    ));
    list.add(const RevealNode(
      step: 99,
      u: 0.511,
      v: 0.175,
      radiusNorm: 0.075,
      label: 'Royal Mukut Crown & Gems',
    ));
    list.add(const RevealNode(
      step: 100,
      u: 0.818,
      v: 0.822,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));
    list.add(const RevealNode(
      step: 101,
      u: 0.479,
      v: 0.919,
      radiusNorm: 0.085,
      label: 'Yellow Pitambar Silks & Garland Base',
    ));

    // ── GRAND CLIMAX: Sacred Face of Lord Shri Ram (Japs 103..108) ────────
    // Jap 103: Sacred Chandan & Kumkum Tilak on Forehead
    list.add(const RevealNode(
      step: 102,
      u: 0.501,
      v: 0.256,
      radiusNorm: 0.075,
      label: 'Sacred Tilak & Forehead',
    ));

    // Jap 104: Left Divine Eye & Gentle Lotus Brow
    list.add(const RevealNode(
      step: 103,
      u: 0.441,
      v: 0.282,
      radiusNorm: 0.075,
      label: 'Left Divine Eye',
    ));

    // Jap 105: Right Divine Eye & Gentle Lotus Brow
    list.add(const RevealNode(
      step: 104,
      u: 0.548,
      v: 0.287,
      radiusNorm: 0.075,
      label: 'Right Divine Eye',
    ));

    // Jap 106: Lotus Nose & Compassionate Cheeks
    list.add(const RevealNode(
      step: 105,
      u: 0.500,
      v: 0.320,
      radiusNorm: 0.080,
      label: 'Divine Nose & Cheeks',
    ));

    // Jap 107: Sacred Smiling Lips & Compassionate Chin
    list.add(const RevealNode(
      step: 106,
      u: 0.500,
      v: 0.360,
      radiusNorm: 0.080,
      label: 'Sacred Smiling Lips',
    ));

    // Jap 108: Full Divine Face & Complete Full-Screen Darshan
    list.add(const RevealNode(
      step: 107,
      u: 0.500,
      v: 0.300,
      radiusNorm: 0.250,
      label: 'Full Divine Darshan Climax',
    ));

    assert(list.length == 108, 'Total reveal nodes must be exactly 108');
    return list;
  }

  /// Returns the set of nodes revealed up to and including [japCount] (0..108).
  static List<RevealNode> getRevealedNodesForCount(int japCount) {
    if (japCount <= 0) return const [];
    if (japCount >= targetJapCount) return revealNodes;
    return revealNodes.sublist(0, japCount);
  }

  /// Returns the newly revealed node on [japStep] (0..107).
  static RevealNode getNodeForStep(int japStep) {
    final idx = japStep.clamp(0, targetJapCount - 1);
    return revealNodes[idx];
  }

  /// Returns the normalized target center coordinate (0.0..1.0, 0.0..1.0) for [japStep].
  static Offset getTargetNormalizedPoint(int japStep) {
    final node = getNodeForStep(japStep);
    return Offset(node.u, node.v);
  }

  /// Creates the slow, divine curved trajectory path emerging from the circular mala around the play button,
  /// traveling upwards towards the top, and smoothly bending towards the target stopping position.
  static Path computeTrajectoryPath({
    required Size screenSize,
    required Offset malaCenter,
    required Offset targetPoint,
  }) {
    final path = Path();
    // 1. Emerge directly from the circular mala encircling the play button
    path.moveTo(malaCenter.dx, malaCenter.dy);

    // 2. Slow upward movement towards the upper portion of the screen
    final cp1 = Offset(
      malaCenter.dx + (targetPoint.dx - malaCenter.dx) * 0.15,
      malaCenter.dy - ((malaCenter.dy - targetPoint.dy) * 0.55),
    );

    // 3. Smooth curved bend towards the right / target position
    final cp2 = Offset(
      targetPoint.dx + (malaCenter.dx < targetPoint.dx ? 16.0 : -16.0),
      targetPoint.dy + ((malaCenter.dy - targetPoint.dy) * 0.12),
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, targetPoint.dx, targetPoint.dy);
    return path;
  }
}
