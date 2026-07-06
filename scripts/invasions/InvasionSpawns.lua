--[[
  InvasionSpawns
  --------------
  Spawns the invading army near a colony and tracks how many invaders have been
  defeated.

  Originally started 8/2/2020 by D. G. Andrews as pseudocode; rewritten to use
  the real Starbound world API (world.spawnNpc / world.entityExists).

  Live spawn data is intentionally kept in-memory only (script-local): entity
  ids are not valid after a world change, so they are never persisted.
]]

local InvasionSpawns = {}

-- Build the parameter table that makes a spawned NPC a hostile raider.
local function invaderParameters()
  return {
    damageTeam = { type = "enemy", team = 0 },
    persistent = true
  }
end

-- Spawn a single NPC, falling back to a guaranteed-spawnable species/type if the
-- configured faction species is unavailable in the current build. Returns the
-- entity id, or nil on failure.
local function spawnInvader(species, npcType, level, position)
  local seed = math.random(1, 2000000000)
  local ok, npcId = pcall(world.spawnNpc, position, species, npcType, level, seed, invaderParameters())
  if ok and npcId and npcId ~= 0 then
    return npcId
  end
  return nil
end

-- Spawn a full wave of invaders around `origin`. Returns a live-tracking table:
--   { ids = { <entityId>, ... }, goal = <number spawned> }
function InvasionSpawns.spawnWave(faction, config, origin)
  local live = { ids = {}, goal = 0 }
  local count = config.waveSize or 1
  local radius = config.spawnRadius or 10.0
  local fallback = config.invaderFallback or {}

  for _ = 1, count do
    local angle = math.random() * 2 * math.pi
    local dist = math.random() * radius
    local pos = {
      origin[1] + math.cos(angle) * dist,
      origin[2] + math.abs(math.sin(angle) * dist) + 2.0
    }

    local npcId = spawnInvader(faction.species, faction.npcType, faction.level or 1, pos)
    if not npcId then
      npcId = spawnInvader(fallback.species or "human", fallback.npcType or "bandit", fallback.level or faction.level or 1, pos)
    end

    if npcId then
      table.insert(live.ids, npcId)
    end
  end

  live.goal = #live.ids
  return live
end

-- Poll the live wave and remove any invaders that no longer exist (killed or
-- despawned). Returns the number of invaders newly resolved this poll.
function InvasionSpawns.pollDefeated(live)
  if not live or not live.ids then return 0 end

  local remaining = {}
  local defeated = 0
  for _, id in ipairs(live.ids) do
    if world.entityExists(id) then
      table.insert(remaining, id)
    else
      defeated = defeated + 1
    end
  end
  live.ids = remaining
  return defeated
end

-- Whether every spawned invader has been resolved.
function InvasionSpawns.allDefeated(live)
  return not live or not live.ids or #live.ids == 0
end

return InvasionSpawns
