# Roblox Grab & Throw System

A physics-based object interaction system for Roblox Studio. Players can grab, carry, rotate, drop, and throw models located inside `Workspace.HoldableItems`.

## Features

* Folder-based object detection
* Model and `MeshPart` support
* Server-side request validation
* Smooth object movement and rotation
* Adjustable hold distance
* Charge-based throwing
* Object highlighting
* Custom first-person camera
* Multiplayer ownership checks
* Rate limiting and security validation

## How It Works

A raycast is fired from the center of the crosshair. If the hit part belongs to a model inside `Workspace.HoldableItems`, the model becomes available for interaction.

When the player presses the left mouse button, the client sends the selected model to the server through `GrabRequest`.

The server validates:

* Distance between the player and the item
* Line of sight
* Player state
* Whether another player is already holding the item
* Whether the item belongs to `HoldableItems`

The system searches for a direct child named `Root`. If no `Root` exists, the first direct child `MeshPart` is used as the physics root. `PrimaryPart` is not required.

## Physics System

`AlignPosition` moves the held item toward the target position in front of the player.

`AlignOrientation` rotates the item based on right mouse movement.

The target position is updated every physics frame:

```text
Player Position + Camera Direction × Hold Distance
```

The mouse wheel changes the hold distance between `3` and `8` studs. Distance changes are smoothed instead of being applied instantly.

`NoCollisionConstraint` prevents the held item from colliding with the player carrying it. The item can still collide with the world and other players.

## Throw System

Holding `R` starts charging the throw. When released, the client displays immediate feedback while the server calculates and validates the real charge duration.

```text
Minimum Speed + Charge Ratio × Speed Range
```

The throw charge UI uses a value between `0` and `1` and displays a visual multiplier between `x0.50` and `x2.00`.

The orange → yellow → green color transition is visual only. The actual throw speed is controlled by `minSpeed` and `maxSpeed` inside `ThrowConfig`.

## Camera System

The custom first-person camera uses a Scriptable camera and includes:

* Mouse smoothing
* Walking sway
* Breathing movement
* Directional tilt
* Jump reaction
* Landing reaction

Character parts are hidden only on the local player's screen.

## Controls

| Input       | Action               |
| ----------- | -------------------- |
| Left Mouse  | Grab or drop item    |
| Right Mouse | Rotate held item     |
| Mouse Wheel | Change hold distance |
| R           | Charge and throw     |

## Project Structure

```text
Workspace
└── HoldableItems (Folder)
    ├── Crystal_L.001_Node (Model)
    │   └── Crystal_L.001 (MeshPart)
    ├── Crystal_L.002_Node (Model)
    │   └── Crystal_L.002 (MeshPart)
    └── OtherItems (Model)
        ├── MainMesh (MeshPart)
        ├── AdditionalParts (BasePart)
        └── WeldConstraints

ReplicatedStorage
└── HoldThrowSystem (Folder)
    ├── Remotes (Folder)
    │   ├── GrabRequest (RemoteEvent)
    │   ├── HoldUpdate (RemoteEvent)
    │   ├── ReleaseRequest (RemoteEvent)
    │   ├── ChargeRequest (RemoteEvent)
    │   ├── ThrowRequest (RemoteEvent)
    │   └── StateChanged (RemoteEvent)
    │
    └── Shared (Folder)
        ├── Config (Folder)
        │   ├── InputConfig (ModuleScript)
        │   ├── InteractionConfig (ModuleScript)
        │   ├── PhysicsConfig (ModuleScript)
        │   └── ThrowConfig (ModuleScript)
        ├── ItemResolver (ModuleScript)
        └── Types (ModuleScript)

ServerScriptService
└── HoldThrowServer (Folder)
    ├── ServerBootstrap (Script)
    │
    ├── Services (Folder)
    │   ├── PlayerStateService (ModuleScript)
    │   ├── CollisionService (ModuleScript)
    │   ├── GrabService (ModuleScript)
    │   ├── HoldService (ModuleScript)
    │   ├── RotationService (ModuleScript)
    │   └── ThrowService (ModuleScript)
    │
    └── Security (Folder)
        ├── RequestValidator (ModuleScript)
        └── RateLimiter (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    ├── HoldThrowClient (Folder)
    │   ├── ClientBootstrap (LocalScript)
    │   │
    │   ├── Controllers (Folder)
    │   │   ├── InputController (ModuleScript)
    │   │   ├── TargetingController (ModuleScript)
    │   │   ├── HoldController (ModuleScript)
    │   │   ├── RotationController (ModuleScript)
    │   │   ├── ThrowController (ModuleScript)
    │   │   ├── HighlightController (ModuleScript)
    │   │   └── UIController (ModuleScript)
    │   │
    │   └── Utilities (Folder)
    │       ├── RaycastUtility (ModuleScript)
    │       └── ConnectionManager (ModuleScript)
    │
    └── FirstPersonCamera (Folder)
        ├── CameraBootstrap (LocalScript)
        ├── CameraController (ModuleScript)
        ├── CameraMotion (ModuleScript)
        └── CameraConfig (ModuleScript)

StarterGui
└── HoldThrowUI (ScreenGui)
    ├── Crosshair (Frame)
    │
    └── ThrowCharge (Frame)
        └── Fill (Frame)
```

## Folder Overview

* `HoldableItems` contains every model players are allowed to interact with.
* `HoldThrowSystem` contains shared configuration modules, types, and RemoteEvents.
* `HoldThrowServer` handles server-side physics, player states, validation, and security.
* `HoldThrowClient` handles input, targeting, highlighting, rotation, throwing, and UI updates.
* `FirstPersonCamera` contains the custom first-person camera system.
* `HoldThrowUI` contains the crosshair and throw charge interface.

## Holdable Item Requirements

Each holdable model must contain either:

* A direct child named `Root`
* At least one direct child `MeshPart`

If no `Root` is found, the first direct child `MeshPart` is automatically used as the physics root.

All additional parts should be connected to the physics root using `WeldConstraint`.

## Network Ownership

While an item is held, its network ownership is assigned to the player for lower latency and smoother movement.

The server continues validating distance, player state, ownership, and requests.

Client-owned physics cannot be completely exploit-proof. This is the trade-off for responsive physics interaction.
