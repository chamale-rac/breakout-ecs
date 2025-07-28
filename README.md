# Breakout Game with ECS Architecture

A Breakout game implementation using Zig and Raylib with Entity-Component-System (ECS) architecture.

## Requirements Accomplished

- [x] El jugador debe de manejar un "paddle" que se puede mover solo de izquierda a derecha en la pantalla.
- [x] Se debe controlar con el teclado.
- [x] Utilicen movimiento time-based (delta time).
- [x] Debe haber un rectángulo "pelota" que continuamente esté moviéndose en la pantalla.
- [x] Cuando la pelota toque la "paddle" debe invertir su movimiento en Y y ajustar su velocidad en X según el punto de contacto.
- [x] Cuando la pelota toque la pared de arriba o de los lados debe invertir su movimiento.
- [x] Si toca la pared de abajo, el juego muestra un mensaje en la terminal que dice "Game Over" y permite reiniciar con ESC.
- [x] En la pantalla, hay algunos rectángulos para representar los "bloques". Si la pelota toca un bloque, el bloque se elimina.
- [x] Si se eliminan todos los bloques, se muestra un mensaje que dice "You Win!" (en consola) y permite reiniciar con ESC.

## Project Structure

```
breakout-entt/
  build.zig
  build.zig.zon
  README.md
  src/
    ECS/
      components/
        component.zig      # Base component definitions
      ecs.zig              # ECS core system
      entity/
        entity.zig         # Entity management
      system/
        system.zig         # Base system definitions
        world.zig          # World/registry management
    GAME/
      game/
        game.zig           # Main game loop and window management
    main.zig               # Entry point
    PONG/
      components/
        components.zig     # Game-specific components (Ball, Paddle, Block, etc.)
      pong/
        pong.zig           # Main game logic and entity creation
      systems/
        collision_system.zig    # Collision detection and response
        input_system.zig        # Keyboard input handling
        movement_system.zig     # Physics and movement updates
        render_system.zig       # Rendering logic
        systems.zig             # System module exports
    SCENE/
      scene/
        scene.zig          # Scene management (future use)
  zig-out/
```

## Architecture

This project uses an Entity-Component-System (ECS) architecture:

- **Entities**: Game objects (paddle, ball, blocks)
- **Components**: Data containers (Position, Velocity, Size, Color, etc.)
- **Systems**: Logic processors (Input, Movement, Collision, Render)

## How to Build

1. Ensure you have Zig installed on your system
2. Run `zig build` in the project root (remember `zig fetch`)
3. The compiled executable will be found in the `zig-out` folder

## Controls

- **Left Arrow / Right Arrow:** Move the paddle left/right
- **Escape:** Quit the game (works during gameplay and after Game Over)

## Demo

[https://vimeo.com/1104996071](https://vimeo.com/1104996071)

<img width="798" height="622" alt="image" src="https://github.com/user-attachments/assets/83b66804-80a2-4ffc-92c2-09085cd34d01" />

