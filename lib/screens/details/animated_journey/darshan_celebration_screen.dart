// lib/screens/details/animated_journey/darshan_celebration_screen.dart
//
// Handles two scenarios:
//
// Scenario A — Temple Darshan (after entering a mid-journey temple):
//   - Temple image with golden glow frame
//   - Mantra text (scrolling Sanskrit)
//   - Aarti bell animation
//   - "Take Prasad & Continue" button
//   - Returns to AnimatedJourneyScreen
//
// Scenario B — Journey Completion Celebration (final destination):
//   - Full-screen confetti particle burst
//   - Fireworks-style color explosions
//   - "Yatra Completed!" title
//   - Stats summary (distance, steps, temples visited, time)
//   - "View Certificate" button → YatraCertificateScreen
//   - "Return Home" button → pops to root
//
// Mode toggled by `isFinalDestination` constructor parameter.
//
// Filled in Step 13.
