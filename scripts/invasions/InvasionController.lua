--[[
  InvasionController
  ------------------
  Drives the lifecycle of each active invasion once a faction has decided to
  attack.

  Originally started 8/2/2020 by D. G. Andrews as pseudocode; rewritten as a
  working state machine.

  Invasion states:
    "gathering" - announced; the army is massing. The player has time to prepare.
    "active"    - invaders have spawned at the colony and must be defeated.
    (removed)   - once "ended" (defeated) or "penalty" (ignored), the invasion is
                  cleared from the list.

  Persisted invasion shape (state.invasions[factionId]):
    { factionId, name, state, elapsed, killCount, killGoal }

  The `ctx` table wires the controller to the running world:
    ctx.announce(text)   - show the player a message
    ctx.getOrigin()      - world position to spawn invaders at (colony/player)
    ctx.live             - script-local, non-persisted live spawn tracking
    ctx.spawns           - the InvasionSpawns module
]]

local InvasionController = {}

function InvasionController.load(state)
  state.invasions = state.invasions or {}
  return state.invasions
end

function InvasionController.hasInvasion(state, factionId)
  return state.invasions ~= nil and state.invasions[factionId] ~= nil
end

-- Announce a new invasion and place the faction into the "gathering" state.
function InvasionController.start(state, faction, ctx)
  if InvasionController.hasInvasion(state, faction.id) then
    return false
  end

  state.invasions[faction.id] = {
    factionId = faction.id,
    name = faction.name or faction.id,
    state = "gathering",
    elapsed = 0.0,
    killCount = 0,
    killGoal = 0
  }

  ctx.announce(string.format("The %s are gathering to raid your colony! Prepare your defenses.", faction.name or faction.id))
  return true
end

-- Move an invasion into the "active" state by spawning its army.
local function beginAssault(invasion, faction, config, ctx)
  local origin = ctx.getOrigin()
  if not origin then
    -- No valid place to spawn yet (e.g. player is between worlds); wait.
    return
  end

  local live = ctx.spawns.spawnWave(faction, config, origin)
  ctx.live[invasion.factionId] = live
  invasion.state = "active"
  -- Restart the clock so nonResponseDuration measures the active assault only,
  -- independent of how long the gathering phase lasted.
  invasion.elapsed = 0.0
  invasion.killCount = 0
  invasion.killGoal = live.goal

  if live.goal > 0 then
    ctx.announce(string.format("The %s have arrived! Defeat all %d raiders!", invasion.name, live.goal))
  else
    -- Nothing could be spawned; treat the raid as fizzled rather than soft-lock.
    invasion.state = "ended"
  end
end

-- Progress every ongoing invasion. Returns nothing; mutates state/ctx.live.
function InvasionController.update(state, config, dt, ctx)
  local finished = {}

  for factionId, invasion in pairs(state.invasions) do
    invasion.elapsed = (invasion.elapsed or 0.0) + dt
    local faction = ctx.factionConfig(factionId)

    if not faction then
      -- Faction no longer configured; drop the invasion.
      table.insert(finished, factionId)

    elseif invasion.state == "gathering" then
      if invasion.elapsed >= (config.gatheringDuration or 60.0) then
        beginAssault(invasion, faction, config, ctx)
      end

    elseif invasion.state == "active" then
      -- Re-spawn the wave if live tracking was lost (e.g. after a world change).
      if not ctx.live[factionId] then
        beginAssault(invasion, faction, config, ctx)
      end

      local live = ctx.live[factionId]
      if live then
        invasion.killCount = invasion.killCount + ctx.spawns.pollDefeated(live)

        if ctx.spawns.allDefeated(live) then
          invasion.state = "ended"
          ctx.announce(string.format("The %s invasion has been defeated! Your colony is safe.", invasion.name))
        elseif invasion.elapsed >= (config.nonResponseDuration or 600.0) then
          invasion.state = "penalty"
          ctx.announce(string.format("You failed to repel the %s. Your colony has been overrun!", invasion.name))
        end
      end
    end

    if invasion.state == "ended" or invasion.state == "penalty" then
      table.insert(finished, factionId)
    end
  end

  -- Clean up resolved invasions and their live tracking.
  for _, factionId in ipairs(finished) do
    state.invasions[factionId] = nil
    ctx.live[factionId] = nil
  end
end

return InvasionController
