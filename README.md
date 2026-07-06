# Starbound Invasions

A Starbound mod that adds invading armies (such as the **Penguin Pirates**) which
gather their forces over time and then raid your colonies. Defend your
settlements before the raiders overrun them!

## How it works

The mod attaches a single script context to the player (via `player.config`) that
runs while you play. Each invading faction slowly builds **aggression** while you
have a colony worth raiding. Once a faction's aggression passes its threshold, an
invasion begins and moves through a simple lifecycle:

1. **Gathering** – The raid is announced. You get time to prepare your defenses.
2. **Active** – A wave of hostile invaders spawns at your colony. Defeat them all.
3. **Resolved** – The invasion ends when every raider is defeated. If you ignore
   the raid for too long, the colony is overrun (you lose the invasion).

Everything is data-driven through [`invasions/invasions.config`](invasions/invasions.config):
factions, aggression rates, gathering/timeout durations, wave size, spawn radius,
and colony scan settings.

## Project layout

| Path | Purpose |
| --- | --- |
| `_metadata` | Starbound mod metadata. |
| `player.config.patch` | Hooks the mod's player script into the game (with a fallback so it works whether or not `genericScriptContexts` already exists). |
| `invasions/invasions.config` | Tuning values and faction definitions. |
| `scripts/invasions/invasions_player.lua` | Player-context entry point; owns state and the update loop. |
| `scripts/invasions/FactionController.lua` | Builds faction aggression and decides when a faction attacks. |
| `scripts/invasions/InvasionController.lua` | Runs the invasion lifecycle (gathering -> active -> resolved). |
| `scripts/invasions/InvasionSpawns.lua` | Spawns the invaders and tracks how many have been defeated. |

## Installing

Copy this folder into your Starbound `mods/` directory (or pack it with
`asset_packer` into a `.pak`), then launch Starbound. State is stored on your
player, so it persists across sessions.

## Debugging hooks

Two entity messages are available for testing (send them to the player entity):

- `starboundInvasions.status` – returns current faction aggression and active
  invasions.
- `starboundInvasions.forceInvasion` – immediately launches an invasion
  (optionally pass a faction id).

## Status / history

The original 2020 upload was pseudocode that did not run. This version is a
complete, runnable rewrite against the real Starbound Lua API.
