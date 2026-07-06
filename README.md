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

## Factions and enemy types

Each faction fields a mixed army rather than a single enemy. A faction may define
an `enemies` roster; each invader in a wave is drawn at random from that roster,
weighted by each entry's `weight` (default `1`), so common troops appear more
often than rare ones. The faction's top-level `species`/`npcType`/`level` are
kept as a fallback for factions that don't define a roster, and
`invaderFallback` is a final safety net if a configured enemy can't be spawned in
the current build.

Shipped factions:

| Faction | Example enemy types |
| --- | --- |
| Penguin Pirates | raider, brute, gunner, captain |
| Floran Hunters | hunter, guard, soldier |
| Human Bandits | bandit, gunner, boss |

Add your own by appending a faction (with an `enemies` list) to
`invasions/invasions.config`.


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

## Continuous integration

A GitHub Actions workflow ([`.github/workflows/ci.yml`](.github/workflows/ci.yml))
runs on every push and pull request and validates syntax so a stray comma or
brace can't silently break the mod at load time:

- **Lua** – every `*.lua` file is checked with `luac -p` (parse only).
- **JSON** – every `.json`, `.config`, `.patch` and the `_metadata` manifest is
  parsed by [`.github/scripts/validate_json.py`](.github/scripts/validate_json.py).

## Design notes: should invasions grant reputation?

Short answer for now: **no reputation/reward system is included**, and that's a
deliberate choice rather than an oversight.

Repelling an invasion is currently its own reward — your colony survives, and any
loot the defeated NPCs drop is handled by Starbound's normal drop system. A few
things to weigh before adding a dedicated "rep" mechanic:

- **What would rep represent?** Options include standing with the *attacking*
  faction (does beating them make them respect or hate you more?) or standing
  with a *defending*/allied faction. The current mod has no allied faction to
  gain standing with, so a rep bar would need new content to be meaningful.
- **Avoid rewarding avoidance.** Aggression only builds while you own a colony,
  so paying out rep per repelled wave risks encouraging players to farm
  invasions. Any reward should scale with difficulty (wave size / enemy level)
  and be capped to prevent grinding.
- **Persistence already exists.** State is stored on the player property
  `starboundInvasions`, so a `reputation` field could be added there cheaply if
  we decide to pursue it.

Recommendation: keep the current "survival is the reward" loop for the first
release, and revisit a reputation/standing system once there is an allied or
rival faction for that reputation to matter to. If we do add it, drive it from
config (e.g. a `reputationPerWave` value scaled by enemy level) so it stays
data-driven like the rest of the mod.

## Status / history

The original 2020 upload was pseudocode that did not run. This version is a
complete, runnable rewrite against the real Starbound Lua API.
