// lib/screens/details/animated_journey/temple_entry_screen.dart
//
// Full-screen temple entry animation screen.
// Triggered when user taps "Enter Temple" on TempleProximityOverlay.
//
// Animation sequence:
//   1. Fade in from road → temple interior background
//   2. Character walks toward camera (scale up)
//   3. Character shrinks into temple door (scale down + translate)
//   4. Temple door opening animation (2 overlapping images)
//   5. Bell ring sound + visual bell swing animation
//   6. Fade to prayer/darshan content
//   7. Character praying animation
//   8. "Continue Journey" button appears with fade-in
//
// On "Continue Journey":
//   - Marks TempleStop as completed
//   - Calls ApiService.updateJourneyLocation (temple milestone sync)
//   - Pops back to AnimatedJourneyScreen with result
//
// Filled in Step 12.
