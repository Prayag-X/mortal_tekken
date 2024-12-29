import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
  ]);
  runApp(GameWidget(game: MortalTekken()));
}

class Player extends SpriteAnimationComponent
    with HasGameReference<MortalTekken>, CollisionCallbacks {
  final int number;
  final double playerSize;
  bool isGettingAttacked;

  Player({
    required this.number,
    required this.playerSize,
    this.isGettingAttacked = false,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    goIdle();
    height = playerSize;
    width = playerSize;
    add(
      RectangleHitbox.relative(
        Vector2(0.5, 1),
        parentSize: Vector2(
          playerSize,
          playerSize,
        ),
      ),
    );
  }

  void attack() async {
    animation = await game.loadSpriteAnimation(
      'player${number}_attack.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.1,
        textureSize: Vector2(128, 128),
      ),
    );
  }

  void goIdle() async {
    animation = await game.loadSpriteAnimation(
      'player${number}_idle.png',
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

  set setGettingAttacked(bool x) => isGettingAttacked = x;

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (isGettingAttacked) {
      print("$number");
    }
  }

  //
  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    print("hola END");
  }
}

class MortalTekken extends FlameGame
    with KeyboardEvents, HasCollisionDetection {
  late Player player1;
  late Player player2;
  late SpriteAnimationTicker a;
  double playerSize = 128;
  double sizeMultiplier = 1.5;
  double distance = 30;
  bool isAttacking1 = false;
  bool isAttacking2 = false;
  int playerHP1 = 10;
  int playerHP2 = 10;

  double get playerSizeMultiplied => playerSize * sizeMultiplier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    player1 = Player(
      number: 1,
      playerSize: playerSizeMultiplied,
    )
      ..x = size.x / 4
      ..y = size.y / 2
      ..scale = Vector2(1, 1)
      ..anchor = Anchor.center;

    player2 = Player(
      number: 2,
      playerSize: playerSizeMultiplied,
    )
      ..x = size.x / 4 * 3
      ..y = size.y / 2
      ..scale = Vector2(-1, 1)
      ..anchor = Anchor.center;

    add(player1);
    add(player2);
    camera.viewport.add(Hud(playerNumber: 1));
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isKeyDown = event is KeyDownEvent;
    final isD = keysPressed.contains(const LogicalKeyboardKey(0x00000064));
    final isA = keysPressed.contains(const LogicalKeyboardKey(0x00000061));
    final isE = keysPressed.contains(const LogicalKeyboardKey(0x00000065));
    final isR = keysPressed.contains(const LogicalKeyboardKey(0x00000072));
    final isLeftArrow =
        keysPressed.contains(const LogicalKeyboardKey(0x100000304));
    final isRightArrow =
        keysPressed.contains(const LogicalKeyboardKey(0x100000301));
    final isLeftBracket =
        keysPressed.contains(const LogicalKeyboardKey(0x0000002e));
    final isRightBracket =
        keysPressed.contains(const LogicalKeyboardKey(0x0000002C));

    if (isD && isKeyDown) {
      player1.goRight(distance);
      return KeyEventResult.handled;
    }
    if (isA && isKeyDown) {
      player1.goLeft(distance);
      return KeyEventResult.handled;
    }

    if (isRightArrow && isKeyDown) {
      player2.goRight(distance);
      return KeyEventResult.handled;
    }
    if (isLeftArrow && isKeyDown) {
      player2.goLeft(distance);
      return KeyEventResult.handled;
    }

    if (isE && !isAttacking1) {
      player1.attack();
      player2.isGettingAttacked = true;
      isAttacking1 = true;
      return KeyEventResult.handled;
    }

    if (isR && isAttacking1) {
      player1.goIdle();
      player2.isGettingAttacked = false;
      isAttacking1 = false;
      return KeyEventResult.handled;
    }

    if (isLeftBracket && !isAttacking2) {
      player2.attack();
      player1.isGettingAttacked = true;
      isAttacking2 = true;
      return KeyEventResult.handled;
    }

    if (isRightBracket && isAttacking2) {
      player2.goIdle();
      player1.isGettingAttacked = false;
      isAttacking2 = false;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

enum HeartState {
  available, // Current HP
  unavailable, // Lost Health
}

class HeartHealthComponent extends SpriteGroupComponent<HeartState>
    with HasGameReference<MortalTekken> {
  final int heartNumber;
  final int playerNumber;

  HeartHealthComponent({
    required this.heartNumber,
    required this.playerNumber,
    required super.position,
    required super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final availableSprite = await game.loadSprite(
      'health.png',
      srcSize: Vector2.all(32),
    );

    final unavailableSprite = await game.loadSprite(
      'health_no.png',
      srcSize: Vector2.all(32),
    );

    sprites = {
      HeartState.available: availableSprite,
      HeartState.unavailable: unavailableSprite,
    };

    current = HeartState.available;
  }

  @override
  void update(double dt) {
    if (playerNumber == 1) {
      if (game.playerHP1 < heartNumber) {
        current = HeartState.unavailable;
      } else {
        current = HeartState.available;
      }
    } else {
      if (game.playerHP2 < heartNumber) {
        current = HeartState.unavailable;
      } else {
        current = HeartState.available;
      }
    }

    super.update(dt);
  }
}

class Hud extends PositionComponent with HasGameReference<MortalTekken> {
  final int playerNumber;

  Hud({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority = 5,
    required this.playerNumber,
  });

  late TextComponent _scoreTextComponent;

  @override
  Future<void> onLoad() async {
    if (playerNumber == 1) {
      for (var i = 1; i <= game.playerHP1; i++) {
        final positionX = 40 * i;
        await add(
          HeartHealthComponent(
            heartNumber: i,
            position: Vector2(positionX.toDouble(), 20),
            playerNumber: playerNumber,
            size: Vector2.all(32),
          ),
        );
      }
    } else {
      for (var i = 1; i <= game.playerHP2; i++) {
        final positionX = 40 * i;
        await add(
          HeartHealthComponent(
            heartNumber: i,
            position: Vector2(positionX.toDouble(), 20),
            playerNumber: playerNumber,
            size: Vector2.all(32),
          ),
        );
      }
    }
  }
}
