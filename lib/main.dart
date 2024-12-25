import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(GameWidget(game: Game()));
}

class Player extends SpriteAnimationComponent with HasGameReference<Game> {
  Player();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await game.loadSpriteAnimation(
      'player1.png',
      SpriteAnimationData.sequenced(
        amount: 5,
        stepTime: 0.1,
        textureSize: Vector2(128, 128),
      ),
    );
  }

  void goRight(double distance) {
    position.add(Vector2(distance, 0));
  }

  void goLeft(double distance) {
    position.add(Vector2(-distance, 0));
  }

// Other methods omitted
}

class Game extends FlameGame with KeyboardEvents {
  late Player player;
  late SpriteAnimationTicker a;
  double sizeMultiplier = 1.5;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    player = Player()
      ..x = size.x / 2
      ..y = size.y / 2
      ..width = 128 * sizeMultiplier
      ..height = 128 * sizeMultiplier
      ..anchor = Anchor.center;

    add(player);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isKeyDown = event is KeyDownEvent;
    final isD = keysPressed.contains(const LogicalKeyboardKey(0x00000064));
    final isA = keysPressed.contains(const LogicalKeyboardKey(0x00000061));

    if (isD && isKeyDown) {
      player.goRight(10);
      return KeyEventResult.handled;
    }
    if (isA && isKeyDown) {
      player.goLeft(10);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}