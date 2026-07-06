--[[
  invasions_player.lua
  --------------------
  Entry point for the Starbound Invasions mod. Attached to the player via a
  `genericScriptContexts` entry in player.config (see player.config.patch), so it
  runs continuously while the player is in the world.

  It owns the persisted mod state and each tick it:
    1. Periodically scans for a colony near the player (something to raid).
    2. Lets each faction build aggression (FactionController).
    3. Launches invasions when a faction is ready (InvasionController).
    4. Progresses ongoing invasions: spawning, kill tracking, win/lose.

  Persisted state lives on the player property "starboundInvasions" and only
  contains serialisable data (faction aggression + invasion metadata). Live
  entity ids and timers are kept in script-local variables and are deliberately
  not persisted, since entity ids are not valid across world changes.
]]

local FactionController = require "/scripts/invasions/FactionController.lua"
local InvasionController = require "/scripts/invasions/InvasionController.lua"
local InvasionSpawns = require "/scripts/invasions/InvasionSpawns.lua"

local DEFAULT_CONFIG = {
  factions = {
    {
      id = "penguinPirates", name = "Penguin Pirates", species = "penguin", npcType = "penguin", level = 6, aggressionThreshold = 100.0,
      enemies = {
        { role = "raider", species = "penguin", npcType = "penguin", level = 6, weight = 5 },
        { role = "brute", species = "penguin", npcType = "penguinbrute", level = 7, weight = 2 },
        { role = "gunner", species = "penguin", npcType = "penguingunner", level = 7, weight = 2 },
        { role = "captain", species = "penguin", npcType = "penguincaptain", level = 8, weight = 1 }
      }
    },
    {
      id = "floranHunters", name = "Floran Hunters", species = "floran", npcType = "floran", level = 7, aggressionThreshold = 130.0,
      enemies = {
        { role = "hunter", species = "floran", npcType = "floranhunter", level = 7, weight = 4 },
        { role = "guard", species = "floran", npcType = "floranguard", level = 8, weight = 2 },
        { role = "soldier", species = "floran", npcType = "floransoldier", level = 8, weight = 2 }
      }
    },
    {
      id = "humanBandits", name = "Human Bandits", species = "human", npcType = "bandit", level = 5, aggressionThreshold = 90.0,
      enemies = {
        { role = "bandit", species = "human", npcType = "bandit", level = 5, weight = 5 },
        { role = "gunner", species = "human", npcType = "banditgunman", level = 6, weight = 3 },
        { role = "boss", species = "human", npcType = "banditboss", level = 8, weight = 1 }
      }
    }
  },
  aggressionPerSecond = 2.0,
  aggressionDecayPerSecond = 0.5,
  gatheringDuration = 45.0,
  nonResponseDuration = 600.0,
  waveSize = 5,
  spawnRadius = 12.0,
  colonyScanRadius = 60.0,
  colonyScanInterval = 5.0,
  invaderFallback = { species = "human", npcType = "bandit", level = 6 }
}

local PROPERTY_NAME = "starboundInvasions"
local SAVE_INTERVAL = 10.0

local config
local state
local ctx
local live
local scanTimer
local saveTimer
local colonyPos
local hasColony

-- The current player position, or nil if it cannot be determined.
local function playerPosition()
  local pid = player.id()
  if not pid then return nil end
  local ok, pos = pcall(world.entityPosition, pid)
  if ok and pos then return pos end
  return nil
end

-- Show the player a message about the invasion. Guarded so a missing/renamed
-- radio message API never breaks the update loop.
local function announce(text)
  sb.logInfo("[StarboundInvasions] %s", text)
  pcall(player.radioMessage, {
    messageId = "starboundInvasions",
    unique = false,
    text = text
  })
end

-- Refresh whether the player currently has a colony to defend, and where it is.
local function rescanColony()
  colonyPos = nil
  hasColony = false

  local pos = playerPosition()
  if not pos then return end

  local ok, ids = pcall(world.objectQuery, pos, config.colonyScanRadius, { name = "colonydeed" })
  if ok and ids and #ids > 0 then
    hasColony = true
    local cok, cpos = pcall(world.entityPosition, ids[1])
    if cok and cpos then
      colonyPos = cpos
    end
  end
end

local function save()
  player.setProperty(PROPERTY_NAME, state)
end

function init()
  local ok, loaded = pcall(root.assetJson, "/invasions/invasions.config")
  config = (ok and type(loaded) == "table") and loaded or DEFAULT_CONFIG

  state = player.getProperty(PROPERTY_NAME) or {}
  FactionController.load(state, config)
  InvasionController.load(state)

  live = {}
  scanTimer = 0.0
  saveTimer = SAVE_INTERVAL
  colonyPos = nil
  hasColony = false

  ctx = {
    announce = announce,
    getOrigin = function() return colonyPos or playerPosition() end,
    factionConfig = function(factionId) return FactionController.factionConfig(config, factionId) end,
    live = live,
    spawns = InvasionSpawns
  }

  -- Debugging / integration hooks.
  message.setHandler("starboundInvasions.status", function()
    return { factions = state.factions, invasions = state.invasions, hasColony = hasColony }
  end)

  message.setHandler("starboundInvasions.forceInvasion", function(_, _, factionId)
    local faction = FactionController.factionConfig(config, factionId or (config.factions[1] and config.factions[1].id))
    if faction and InvasionController.start(state, faction, ctx) then
      FactionController.reset(state, faction.id)
      save()
      return true
    end
    return false
  end)
end

function update(dt)
  scanTimer = scanTimer - dt
  if scanTimer <= 0 then
    scanTimer = config.colonyScanInterval or 5.0
    rescanColony()
  end

  local ready = FactionController.update(state, config, dt, hasColony)
  for _, faction in ipairs(ready) do
    if not InvasionController.hasInvasion(state, faction.id) then
      if InvasionController.start(state, faction, ctx) then
        FactionController.reset(state, faction.id)
      end
    end
  end

  InvasionController.update(state, config, dt, ctx)

  saveTimer = saveTimer - dt
  if saveTimer <= 0 then
    saveTimer = SAVE_INTERVAL
    save()
  end
end

function uninit()
  if state then
    save()
  end
end
