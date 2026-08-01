// lib/screens/details/animated_journey/widgets/journey_road_scene.dart
//
// The multi-layer parallax road scene widget.
// Renders from back to front:
//   Layer 1: Sky gradient (static)
//   Layer 2: Mountains (slow scroll)
//   Layer 3: Background trees (medium scroll)
//   Layer 4: Foreground trees (fast scroll)
//   Layer 5: Road (fastest scroll)
//   Layer 6: Clouds (horizontal drift)
//   Layer 7: Dust/wind particles
//
// All layers driven by a single AnimationController from parent.
// Uses RepaintBoundary for 60 FPS isolation.
//
// Filled in Step 6.
