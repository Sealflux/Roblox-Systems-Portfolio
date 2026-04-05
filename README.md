# Roblox Systems Portfolio

I'm an experienced Knit scripter seeking long-term work. This repository contains production code from my projects.

## What's here

| System | Type | Description |
|--------|------|-------------|
| AudioController | Knit Controller | Dynamic audio system for pouring minigame with volume based on fill level |
| UiController | Knit Controller | Handles blindfold UI, input (mouse/touch/gamepad), water filling logic |
| FillService | Knit Service | Manages active turns, water level updates, VFX, server-client sync |
| MatchService | Knit Service | Full match flow: countdown, turn management, results, rewards |
| StationService | Knit Service | Station setup, chair occupancy tracking, match lifecycle |
| ProductService | Knit Service | Developer product handling (seals purchases) |
| TeleportService | Knit Service | Player teleportation utilities |
| UnboxingService | Knit Service | Crate unboxing with rarity chances, duplicate detection, refunds |
| VFXService | Knit Service | Visual effects management (fill particles, confetti) |

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

Discord: thuanson# Roblox-Systems-Portfolio
