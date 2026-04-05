# Roblox Systems Portfolio

I'm an experienced Knit scripter seeking long-term work. This repository contains production code from my projects.

## What's here

| System | Type | Description |
|--------|------|-------------|
| AudioController | Knit Controller | Dynamic audio for pouring minigame |
| UiController | Knit Controller | Blindfold UI, input (mouse/touch/gamepad), water filling |
| InventoryController | Knit Controller | Skin inventory display, equipping, 3D model preview |
| UnboxingController | Knit Controller | Crate shop UI, unboxing animation, item reveal |
| FillService | Knit Service | Active turns, water updates, VFX, sync |
| MatchService | Knit Service | Match flow: countdown, turns, results, rewards |
| StationService | Knit Service | Station setup, chair occupancy, match lifecycle |
| ProductService | Knit Service | Developer product handling (seals purchases) |
| TeleportService | Knit Service | Player teleportation utilities |
| UnboxingService | Knit Service | Crate unboxing, rarities, duplicates, refunds |
| VFXService | Knit Service | Fill particles, confetti effects |

There is some other code but you can probably easily read and tell what they do. 

## What I know

- **Knit** (Services/Controllers, cross-boundary signals)
- **ProfileStore** (elementary — sessions, autosave)
- **Cross-platform input** (PC mouse/keyboard, mobile touch, gamepad)

## What I'm learning

- BridgeNet2 (networking optimization)

## How to review

Each `.luau` file is standalone code you can read. The systems demonstrate:
- Clean service/controller separation
- Signal-based communication
- Proper cleanup and memory management
- Anti-exploit checks (timeouts, validation)

## Contact

Discord: thuanson
