import 'package:flutter/material.dart';

/// Represents a feathered radial reveal node on the divine portrait.
class RevealNode {
  final int step; // 0..107
  final double u; // Normalized X (0.0 = left, 1.0 = right relative to portrait dstRect)
  final double v; // Normalized Y (0.0 = top, 1.0 = bottom relative to portrait dstRect)
  final double radiusNorm; // Normalized radius (e.g. 0.058)
  final String label;

  const RevealNode({
    required this.step,
    required this.u,
    required this.v,
    this.radiusNorm = 0.058,
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
  double toScreenRadius(Size screenSize) {
    final dstRect = RamPathCalculator.computeDstRect(screenSize);
    return radiusNorm * dstRect.width;
  }
}

/// Precomputed 108-step deterministic reveal plan with widely dispersed points
/// covering the entire portrait (including harmonious face reveal) with ZERO black holes.
class RamPathCalculator {
  static const int targetJapCount = 108;

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

  /// 108 uniquely distributed reveal nodes ensuring every single tap lands on a
  /// different area across the divine portrait (jumping across screen quadrants)
  /// and revealing ~50% at halfway (Jap 54..56) and 100% at Jap 108.
  static final List<RevealNode> revealNodes = const [
      RevealNode(step: 0, u: 0.500, v: 0.040, radiusNorm: 0.058, label: "Golden Solar Halo Peak"),
      RevealNode(step: 1, u: 0.500, v: 0.870, radiusNorm: 0.058, label: "Sacred Lotus Central Petal"),
      RevealNode(step: 2, u: 0.880, v: 0.220, radiusNorm: 0.058, label: "Kodanda Bow Upper Horn"),
      RevealNode(step: 3, u: 0.120, v: 0.220, radiusNorm: 0.058, label: "Quiver Upper Finial"),
      RevealNode(step: 4, u: 0.500, v: 0.140, radiusNorm: 0.058, label: "Royal Mukut Finial"),
      RevealNode(step: 5, u: 0.220, v: 0.720, radiusNorm: 0.058, label: "Yellow Pitambar Pleats Left"),
      RevealNode(step: 6, u: 0.550, v: 0.720, radiusNorm: 0.058, label: "Yellow Pitambar Pleats Right"),
      RevealNode(step: 7, u: 0.500, v: 0.410, radiusNorm: 0.058, label: "Neck Tri-Rekha"),
      RevealNode(step: 8, u: 0.500, v: 0.255, radiusNorm: 0.058, label: "Sacred Chandan Tilak"),
      RevealNode(step: 9, u: 0.240, v: 0.520, radiusNorm: 0.058, label: "Left Arm Golden Vanki"),
      RevealNode(step: 10, u: 0.820, v: 0.500, radiusNorm: 0.058, label: "Kodanda Bow Mid Grip"),
      RevealNode(step: 11, u: 0.500, v: 0.520, radiusNorm: 0.058, label: "Sacred Janeu & Ruby Strand"),
      RevealNode(step: 12, u: 0.350, v: 0.060, radiusNorm: 0.058, label: "Aura Rays Upper Left"),
      RevealNode(step: 13, u: 0.380, v: 0.890, radiusNorm: 0.058, label: "Pink Lotus Petals Left"),
      RevealNode(step: 14, u: 0.760, v: 0.240, radiusNorm: 0.058, label: "Silken Curls Right"),
      RevealNode(step: 15, u: 0.240, v: 0.240, radiusNorm: 0.058, label: "Silken Curls Left"),
      RevealNode(step: 16, u: 0.420, v: 0.160, radiusNorm: 0.058, label: "Crown Arch Left"),
      RevealNode(step: 17, u: 0.350, v: 0.720, radiusNorm: 0.058, label: "Golden Zari Border Left"),
      RevealNode(step: 18, u: 0.680, v: 0.720, radiusNorm: 0.058, label: "Golden Zari Border Right"),
      RevealNode(step: 19, u: 0.420, v: 0.430, radiusNorm: 0.058, label: "Pearl Choker Left"),
      RevealNode(step: 20, u: 0.440, v: 0.280, radiusNorm: 0.058, label: "Left Lotus Brow & Eye"),
      RevealNode(step: 21, u: 0.340, v: 0.530, radiusNorm: 0.058, label: "Rose Garland Left Upper"),
      RevealNode(step: 22, u: 0.740, v: 0.530, radiusNorm: 0.058, label: "Right Forearm Bracelets"),
      RevealNode(step: 23, u: 0.450, v: 0.550, radiusNorm: 0.058, label: "Parijat Garland Center Left"),
      RevealNode(step: 24, u: 0.650, v: 0.060, radiusNorm: 0.058, label: "Aura Rays Upper Right"),
      RevealNode(step: 25, u: 0.620, v: 0.890, radiusNorm: 0.058, label: "Pink Lotus Petals Right"),
      RevealNode(step: 26, u: 0.820, v: 0.300, radiusNorm: 0.058, label: "Golden Bow String Upper"),
      RevealNode(step: 27, u: 0.180, v: 0.300, radiusNorm: 0.058, label: "Golden Arrow Shafts Left"),
      RevealNode(step: 28, u: 0.580, v: 0.160, radiusNorm: 0.058, label: "Crown Arch Right"),
      RevealNode(step: 29, u: 0.450, v: 0.720, radiusNorm: 0.058, label: "Pitambar Drape Center Left"),
      RevealNode(step: 30, u: 0.800, v: 0.720, radiusNorm: 0.058, label: "Kodanda Bow Lower Shaft"),
      RevealNode(step: 31, u: 0.580, v: 0.430, radiusNorm: 0.058, label: "Pearl Choker Right"),
      RevealNode(step: 32, u: 0.560, v: 0.280, radiusNorm: 0.058, label: "Right Lotus Brow & Eye"),
      RevealNode(step: 33, u: 0.180, v: 0.580, radiusNorm: 0.058, label: "Abhaya Mudra Palm"),
      RevealNode(step: 34, u: 0.880, v: 0.560, radiusNorm: 0.058, label: "Bowstring Tension Mid"),
      RevealNode(step: 35, u: 0.550, v: 0.550, radiusNorm: 0.058, label: "Parijat Garland Center Right"),
      RevealNode(step: 36, u: 0.220, v: 0.090, radiusNorm: 0.058, label: "Dawn Sunlight Left"),
      RevealNode(step: 37, u: 0.250, v: 0.910, radiusNorm: 0.058, label: "Lotus Bloom Outer Left"),
      RevealNode(step: 38, u: 0.720, v: 0.300, radiusNorm: 0.058, label: "Ear Kundal Gems Right"),
      RevealNode(step: 39, u: 0.280, v: 0.300, radiusNorm: 0.058, label: "Ear Kundal Gems Left"),
      RevealNode(step: 40, u: 0.500, v: 0.180, radiusNorm: 0.058, label: "Mukut Emerald Crest"),
      RevealNode(step: 41, u: 0.180, v: 0.780, radiusNorm: 0.058, label: "Silken Robes Flare Left"),
      RevealNode(step: 42, u: 0.580, v: 0.790, radiusNorm: 0.058, label: "Pitambar Drape Center Right"),
      RevealNode(step: 43, u: 0.500, v: 0.450, radiusNorm: 0.058, label: "Gem Pectoral Center"),
      RevealNode(step: 44, u: 0.400, v: 0.315, radiusNorm: 0.058, label: "Left Compassionate Cheek"),
      RevealNode(step: 45, u: 0.270, v: 0.590, radiusNorm: 0.058, label: "Blessing Fingers Radiant"),
      RevealNode(step: 46, u: 0.780, v: 0.600, radiusNorm: 0.058, label: "Kodanda Golden Carvings"),
      RevealNode(step: 47, u: 0.500, v: 0.580, radiusNorm: 0.058, label: "Maharani Garland Pendant"),
      RevealNode(step: 48, u: 0.780, v: 0.090, radiusNorm: 0.058, label: "Dawn Sunlight Right"),
      RevealNode(step: 49, u: 0.750, v: 0.910, radiusNorm: 0.058, label: "Lotus Bloom Outer Right"),
      RevealNode(step: 50, u: 0.860, v: 0.380, radiusNorm: 0.058, label: "Kodanda Bow Shaft Upper"),
      RevealNode(step: 51, u: 0.140, v: 0.380, radiusNorm: 0.058, label: "Quiver Leather & Jewels"),
      RevealNode(step: 52, u: 0.350, v: 0.190, radiusNorm: 0.058, label: "Crown Gems Left"),
      RevealNode(step: 53, u: 0.300, v: 0.790, radiusNorm: 0.058, label: "Gold Brocade Sash Left"),
      RevealNode(step: 54, u: 0.700, v: 0.790, radiusNorm: 0.058, label: "Gold Brocade Sash Right"),
      RevealNode(step: 55, u: 0.360, v: 0.460, radiusNorm: 0.058, label: "Left Golden Epaulet"),
      RevealNode(step: 56, u: 0.500, v: 0.315, radiusNorm: 0.058, label: "Divine Nose Bridge"),
      RevealNode(step: 57, u: 0.350, v: 0.600, radiusNorm: 0.058, label: "Rose Garland Swag Left"),
      RevealNode(step: 58, u: 0.850, v: 0.640, radiusNorm: 0.058, label: "Golden Bow Silken Tassel"),
      RevealNode(step: 59, u: 0.440, v: 0.620, radiusNorm: 0.058, label: "Floral Swag Lower Left"),
      RevealNode(step: 60, u: 0.500, v: 0.090, radiusNorm: 0.058, label: "Spire Aura Core"),
      RevealNode(step: 61, u: 0.500, v: 0.920, radiusNorm: 0.058, label: "Divine Pedestal Base Mid"),
      RevealNode(step: 62, u: 0.740, v: 0.380, radiusNorm: 0.058, label: "Silken Hair Tresses Right"),
      RevealNode(step: 63, u: 0.260, v: 0.380, radiusNorm: 0.058, label: "Silken Hair Tresses Left"),
      RevealNode(step: 64, u: 0.650, v: 0.190, radiusNorm: 0.058, label: "Crown Gems Right"),
      RevealNode(step: 65, u: 0.420, v: 0.790, radiusNorm: 0.058, label: "Silken Folds Mid Left"),
      RevealNode(step: 66, u: 0.820, v: 0.790, radiusNorm: 0.058, label: "Bow String Anchor Right"),
      RevealNode(step: 67, u: 0.640, v: 0.460, radiusNorm: 0.058, label: "Right Golden Epaulet"),
      RevealNode(step: 68, u: 0.600, v: 0.315, radiusNorm: 0.058, label: "Right Compassionate Cheek"),
      RevealNode(step: 69, u: 0.200, v: 0.650, radiusNorm: 0.058, label: "Abhaya Wrist Bangles"),
      RevealNode(step: 70, u: 0.720, v: 0.660, radiusNorm: 0.058, label: "Right Brocade Robes Flank"),
      RevealNode(step: 71, u: 0.560, v: 0.620, radiusNorm: 0.058, label: "Floral Swag Lower Right"),
      RevealNode(step: 72, u: 0.380, v: 0.110, radiusNorm: 0.058, label: "Upper Nimbus Left"),
      RevealNode(step: 73, u: 0.360, v: 0.940, radiusNorm: 0.058, label: "Golden Pedestal Base Left"),
      RevealNode(step: 74, u: 0.780, v: 0.440, radiusNorm: 0.058, label: "Right Shoulder Brocade"),
      RevealNode(step: 75, u: 0.220, v: 0.440, radiusNorm: 0.058, label: "Left Shoulder Brocade"),
      RevealNode(step: 76, u: 0.440, v: 0.210, radiusNorm: 0.058, label: "Mukut Filigree Left"),
      RevealNode(step: 77, u: 0.250, v: 0.840, radiusNorm: 0.058, label: "Pitambar Hem Left"),
      RevealNode(step: 78, u: 0.620, v: 0.840, radiusNorm: 0.058, label: "Pitambar Hem Right"),
      RevealNode(step: 79, u: 0.500, v: 0.480, radiusNorm: 0.058, label: "Kaustubha Gem Medallion"),
      RevealNode(step: 80, u: 0.460, v: 0.345, radiusNorm: 0.058, label: "Gentle Smiling Lips Left"),
      RevealNode(step: 81, u: 0.300, v: 0.660, radiusNorm: 0.058, label: "Silken Sash Knot Left"),
      RevealNode(step: 82, u: 0.800, v: 0.680, radiusNorm: 0.058, label: "Kodanda Bow Lower Brace"),
      RevealNode(step: 83, u: 0.500, v: 0.650, radiusNorm: 0.058, label: "Golden Navel Brocade"),
      RevealNode(step: 84, u: 0.620, v: 0.110, radiusNorm: 0.058, label: "Upper Nimbus Right"),
      RevealNode(step: 85, u: 0.640, v: 0.940, radiusNorm: 0.058, label: "Golden Pedestal Base Right"),
      RevealNode(step: 86, u: 0.900, v: 0.180, radiusNorm: 0.058, label: "Golden Bow Crest Right"),
      RevealNode(step: 87, u: 0.100, v: 0.180, radiusNorm: 0.058, label: "Quiver Crest Left"),
      RevealNode(step: 88, u: 0.560, v: 0.210, radiusNorm: 0.058, label: "Mukut Filigree Right"),
      RevealNode(step: 89, u: 0.380, v: 0.840, radiusNorm: 0.058, label: "Golden Tassel Fringe Left"),
      RevealNode(step: 90, u: 0.750, v: 0.840, radiusNorm: 0.058, label: "Golden Tassel Fringe Right"),
      RevealNode(step: 91, u: 0.430, v: 0.490, radiusNorm: 0.058, label: "Pearl Strand Left"),
      RevealNode(step: 92, u: 0.540, v: 0.345, radiusNorm: 0.058, label: "Gentle Smiling Lips Right"),
      RevealNode(step: 93, u: 0.380, v: 0.670, radiusNorm: 0.058, label: "Jasmine Garland Left"),
      RevealNode(step: 94, u: 0.150, v: 0.120, radiusNorm: 0.058, label: "Solar Flare Outer Left"),
      RevealNode(step: 95, u: 0.200, v: 0.950, radiusNorm: 0.058, label: "Lotus Baseline Edge Left"),
      RevealNode(step: 96, u: 0.500, v: 0.230, radiusNorm: 0.058, label: "Diadem Band Jewels"),
      RevealNode(step: 97, u: 0.140, v: 0.840, radiusNorm: 0.058, label: "Left Robe Aura Edge"),
      RevealNode(step: 98, u: 0.860, v: 0.840, radiusNorm: 0.058, label: "Right Robe Aura Edge"),
      RevealNode(step: 99, u: 0.570, v: 0.490, radiusNorm: 0.058, label: "Pearl Strand Right"),
      RevealNode(step: 100, u: 0.500, v: 0.360, radiusNorm: 0.058, label: "Sacred Amrit Lips Center"),
      RevealNode(step: 101, u: 0.850, v: 0.120, radiusNorm: 0.058, label: "Solar Flare Outer Right"),
      RevealNode(step: 102, u: 0.800, v: 0.950, radiusNorm: 0.058, label: "Lotus Baseline Edge Right"),
      RevealNode(step: 103, u: 0.280, v: 0.160, radiusNorm: 0.058, label: "Mukut Aura Border Left"),
      RevealNode(step: 104, u: 0.500, v: 0.380, radiusNorm: 0.058, label: "Compassionate Lotus Chin"),
      RevealNode(step: 105, u: 0.500, v: 0.960, radiusNorm: 0.058, label: "Sacred Paduka Platform"),
      RevealNode(step: 106, u: 0.720, v: 0.160, radiusNorm: 0.058, label: "Mukut Aura Border Right"),
      RevealNode(step: 107, u: 0.500, v: 0.020, radiusNorm: 0.058, label: "Divine Apex Pinnacle"),
  ];

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
    path.moveTo(malaCenter.dx, malaCenter.dy);

    final cp1 = Offset(
      malaCenter.dx + (targetPoint.dx - malaCenter.dx) * 0.15,
      malaCenter.dy - ((malaCenter.dy - targetPoint.dy) * 0.55),
    );

    final cp2 = Offset(
      targetPoint.dx + (malaCenter.dx < targetPoint.dx ? 16.0 : -16.0),
      targetPoint.dy + ((malaCenter.dy - targetPoint.dy) * 0.12),
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, targetPoint.dx, targetPoint.dy);
    return path;
  }
}
