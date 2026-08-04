import 'dart:async';
import 'package:flame/game.dart';

import 'player_component.dart';
import 'road_component.dart';
import 'temple_component.dart';

class YatraGame extends FlameGame {
  late PlayerComponent player;
  late RoadComponent road;
  
  // Game state variables
  double currentSpeed = 0.0;
  bool isPraying = false;
  final Map<dynamic, dynamic> yatraData;

  // We pass data to the game (e.g., total distance, upcoming temples)
  YatraGame({required this.yatraData});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Add the scrolling road (Background)
    road = RoadComponent();
    await add(road);

    // 2. Add the player character in the center/bottom
    player = PlayerComponent();
    player.position = Vector2(size.x / 2, size.y * 0.75);
    await add(player);

    // 3. Spawn temples dynamically from API route data
    final routeTemples = yatraData['routeTemples'];
    if (routeTemples != null && routeTemples is List) {
      double startY = -300.0;
      bool isRight = false;
      int seq = 1;
      for (var t in routeTemples) {
        String name = 'Temple $seq';
        if (t['distanceFromStart'] != null) {
          name += '\n(${t['distanceFromStart']} km)';
        }
        // For demonstration, space them out by 500 pixels
        spawnTemple(name, startY, isRight);
        startY -= 600.0;
        isRight = !isRight;
        seq++;
      }
    } else {
      // Fallback if no route temples available
      spawnTemple('Somnath', -300, false);
      spawnTemple('Dwarka', -800, true);
      spawnTemple('Kashi', -1400, false);
    }
  }

  void spawnTemple(String name, double initialY, bool isRight) {
    final temple = TempleComponent(templeName: name, isOnRightSide: isRight);
    // Position it off the road
    final roadWidth = size.x * 0.6;
    final xPos = isRight ? (size.x / 2 + roadWidth / 2 + 50) : (size.x / 2 - roadWidth / 2 - 50);
    temple.position = Vector2(xPos, initialY);
    add(temple);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (player.state == PlayerState.walking) {
      currentSpeed = 100.0;
    } else {
      currentSpeed = 0.0;
    }

    road.scroll(currentSpeed * dt);

    for (var child in children) {
      if (child is TempleComponent) {
        child.position.y += currentSpeed * dt;
        
        // Trigger interaction when temple reaches player's Y level
        if (!isPraying && child.position.y > player.position.y - 10 && child.position.y < player.position.y + 10) {
          _triggerTempleInteraction(child);
        }
      }
    }
  }

  void _triggerTempleInteraction(TempleComponent temple) async {
    isPraying = true;
    player.state = PlayerState.idle;
    
    // Simulate walking to the temple
    player.position.x = temple.position.x > player.position.x 
        ? player.position.x + 50 // move right
        : player.position.x - 50; // move left
        
    await Future.delayed(const Duration(seconds: 1));
    player.state = PlayerState.praying;
    
    // Pray for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    // Return to road
    player.position.x = size.x / 2;
    player.state = PlayerState.idle;
    await Future.delayed(const Duration(seconds: 1));
    
    player.state = PlayerState.walking;
    isPraying = false;
    
    // Push the temple down a bit so it doesn't re-trigger immediately
    temple.position.y += 50;
  }
}
