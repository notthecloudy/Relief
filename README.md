# Relief Hub v2.0

A modular Roblox exploit script hub with Rayfield Gen2 UI, anti-detection features, and game-specific modules.

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/notthecloudy/Relief/main/Loader.lua"))()
```

## Features

- **Rayfield Gen2 UI** - Modern, clean interface
- **Modular Architecture** - Clean separation of concerns
- **Anti-Detection** - Metatable hooks blocking Kick, suspicious remotes
- **Universal Modules** - Movement, Combat, Render, Player, World, Utility
- **Game-Specific Scripts** - Auto-loaded based on PlaceId
- **Configurable** - All modules have settings (sliders, toggles, dropdowns)
- **Commands System** - Chat commands with prefix `;`

## Module Categories

### Movement
- Fly, Noclip, Speed, AntiWarp, NoPlayerCollision
- InfiniteJump, Bhop, Freecam, PlayerTransporter
- AntiVoid, Blink

### Combat
- Aimbot (FOV, Wall Check, Target Part)
- TriggerBot (KatanaCheck, Delay)
- ESP (Box ESP)
- LoopFling

### Render
- ESP (Box ESP)
- Zoom (Smooth, Amount)
- Theme (RGB, Rainbow)
- Crosshair, Fullbright, NoFog

### Player
- AntiAfk, AutoReset, AntiSit
- GodMode, InfiniteHealth
- WalkSpeed, JumpPower, HipHeight
- AutoGrabTools, NoClip, FriendLogs

### World
- AntiVoid, AntiBoundsKill
- VehicleSpam, PianoCrash
- ChatSpam, Advertise (with AutoServerHop)
- AutoGrabTools

### Utility
- ChatSpam, Advertise, AntiVoid
- Rejoin, ServerHop, AutoRejoin
- FpsCap, LagSwitch
- ChatLogs, JoinLogs, LeaveLogs

## Game Scripts Supported

- **The Chosen One** (PlaceId: 11137575513, 12943245078)
- **Rivals** (PlaceId: 17625359962, 117398147513099)
- **BlindShot** (PlaceId: 118614517739521)
- **Ban or Get Banned** (PlaceId: 96017656548489)
- **Developer Hub** (PlaceId: 9008985963)

## Commands

Prefix: `;`

| Command | Aliases | Description |
|---------|---------|-------------|
| `;whitelist` | `;wl` | Add player to whitelist |
| `;unwhitelist` | `;unwl` | Remove player from whitelist |
| `;fly` | - | Toggle fly |
| `;noclip` | - | Toggle noclip |
| `;speed` | - | Toggle speed |
| `;infjump` | `;infj` | Toggle infinite jump |
| `;bhop` | - | Toggle bhop |
| `;freecam` | `;fc` | Toggle freecam |
| `;tp` | `;teleport` | Teleport to player |
| `;bring` | - | Bring player to you |
| `;kill` | - | Kill player |
| `;loopfling` | `;lf` | Loop fling player(s) |
| `;unloopfling` | `;unlf` | Stop loop fling |
| `;fling` | - | Fling player(s) once |
| `;void` | - | Void player(s) |
| `;rejoin` | `;rj` | Rejoin current server |
| `;serverhop` | `;sh` | Hop to another server |
| `;cmds` | `;commands`, `;help` | List all commands |
| `;reset` | `;rs` | Reset character |
| `;chat` | `;say` | Send chat message |
| `;bypass` | `;by` | Send bypassed chat message |

## Structure

```
ReliefHub/
├── Loader.lua                 # Entry point
├── Core/                      # Core modules
│   ├── Init.lua
│   ├── Services.lua
│   ├── Thread.lua
│   ├── Utilities.lua
│   ├── Character.lua
│   └── Whitelist.lua
├── UI/
│   └── RayfieldWrapper.lua    # Rayfield Gen2 wrapper
├── Modules/
│   ├── Universal/             # Universal modules
│   │   ├── Movement.lua
│   │   ├── Combat.lua
│   │   ├── Render.lua
│   │   ├── Player.lua
│   │   ├── World.lua
│   │   ├── Utility.lua
│   │   └── Commands.lua
│   └── Bloxbiz/               # Bloxbiz modules
│       ├── Polymall.lua
│       └── BloxbizModules.lua
├── Games/
│   ├── GameRegistry.lua       # Dynamic game loading
│   ├── TheChosenOne.lua
│   ├── Rivals.lua
│   ├── BlindShot.lua
│   ├── BanOrBeBanned.lua
│   └── DeveloperHub.lua
└── Util/                      # Legacy utilities
```

## Discord

Join our community: [discord.gg/aZfFCkqYyA](https://discord.gg/aZfFCkqYyA)