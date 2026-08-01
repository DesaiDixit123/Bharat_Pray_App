// lib/screens/details/animated_journey/widgets/character_widget.dart
//
// State-driven pilgrim character widget.
// Reads CharacterState and drives:
//   - Walking: bobbing Y animation, normal speed
//   - Slow Walking: reduced bobbing, slower speed
//   - Near Temple: slow + slight turn
//   - Turning Left/Right: horizontal offset + rotation
//   - Entering Temple: scale-down + fade
//   - Celebrating: jump + glow effect
//
// Phase 1: Uses assets/images/pilgrim_character.png with AnimationController.
// Phase 2: Swap for RiveAnimation with state machine inputs.
//
// Filled in Step 7.
