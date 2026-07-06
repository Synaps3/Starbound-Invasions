--[[
  FactionController
  -----------------
  Tracks how close each invading faction is to launching an attack.

  Originally started 8/2/2020 by D. G. Andrews as pseudocode; rewritten as a
  working, config-driven Starbound module.

  Aggression builds up over time while the player has a colony to threaten, and
  slowly decays otherwise. When a faction's aggression crosses its configured
  threshold it becomes "ready" and the InvasionController launches an invasion.

  State shape (owned by the bootstrap, persisted via player properties):
    state.factions = { [factionId] = { aggression = <number> }, ... }
]]

local FactionController = {}

-- Ensure every configured faction has a runtime aggression entry.
function FactionController.load(state, config)
  state.factions = state.factions or {}
  for _, faction in ipairs(config.factions or {}) do
    if type(state.factions[faction.id]) ~= "table" then
      state.factions[faction.id] = { aggression = 0.0 }
    end
  end
  return state.factions
end

-- Look up the static config for a faction id.
function FactionController.factionConfig(config, factionId)
  for _, faction in ipairs(config.factions or {}) do
    if faction.id == factionId then
      return faction
    end
  end
  return nil
end

-- Advance aggression for every faction. `hasColony` indicates whether the
-- player currently has a settlement worth raiding. Returns the list of faction
-- config tables whose aggression has reached their threshold this tick.
function FactionController.update(state, config, dt, hasColony)
  local ready = {}
  local gain = config.aggressionPerSecond or 1.0
  local decay = config.aggressionDecayPerSecond or 0.0

  for _, faction in ipairs(config.factions or {}) do
    local entry = state.factions[faction.id] or { aggression = 0.0 }
    state.factions[faction.id] = entry

    if hasColony then
      entry.aggression = entry.aggression + (gain * dt)
    else
      entry.aggression = math.max(0.0, entry.aggression - (decay * dt))
    end

    local threshold = faction.aggressionThreshold or 100.0
    if entry.aggression >= threshold then
      table.insert(ready, faction)
    end
  end

  return ready
end

-- Reset a faction's aggression once its invasion has been launched.
function FactionController.reset(state, factionId)
  if state.factions[factionId] then
    state.factions[factionId].aggression = 0.0
  end
end

return FactionController
