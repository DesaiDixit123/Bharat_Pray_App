import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/yatra_game.dart';
import 'game/player_component.dart';
// Ensure this model exists

class AnimatedJourneyScreen extends StatefulWidget {
  final dynamic yatra; // We pass the Yatra model here

  const AnimatedJourneyScreen({super.key, required this.yatra});

  @override
  State<AnimatedJourneyScreen> createState() => _AnimatedJourneyScreenState();
}

class _AnimatedJourneyScreenState extends State<AnimatedJourneyScreen> {
  late YatraGame game;

  @override
  void initState() {
    super.initState();
    // Initialize the Flame game with yatra data
    game = YatraGame(yatraData: widget.yatra is Map ? widget.yatra : {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. The Game Layer
          GameWidget(game: game),

          // 2. The UI Layer Overlay
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top HUD
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black45,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.yatra is Map ? widget.yatra['title'] ?? 'Yatra Journey' : 'Yatra Journey',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom HUD / Progress Info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black45,
                  child: Column(
                    children: [
                      const Text(
                        'Distance to next temple: 2.5 km',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(value: 0.3),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              game.player.state = PlayerState.walking;
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              game.player.state = PlayerState.idle;
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
