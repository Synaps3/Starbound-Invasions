--https://starbounder.org/Modding:Basics#Reference_Pages
--https://starbounder.org/Spawn_NPC_Command
--https://github.com/ThreeTen22/NpcSpawner/blob/master/objects/NpcSpawner/NpcPanel.lua
--world.debugText("Insert text here or a calculation here",{mcontroller.position()[1]-1,mcontroller.position()[2]-3.5}, "green")

invasionKillGoal = 1

function startSpawning(faction,player,planet)
    pos = "unused, tbd"
    for enemy in numberNPCsToKill
        spawnAfighter(pos)
    --TBD note the number of killed npcSpecies
end

function spawnAfighter(pos)
    local speciesList = root.assetJson("/interface/windowconfig/charcreation.config:speciesOrdering")
    local baseConfig = root.assetJson("/interface/scripted/NpcMenu/modConfig.config:init")
    local npcTypeList = shallowCopy(baseConfig.npcTypeList)
    speciesList = npcUtil.mergeUnique(speciesList, baseConfig.additionalSpecies)
    pos = tech.aimPosition() --we're going to spawn the npc at the cursor position
    local npcId = world.spawnNpc(pos, storage.npcSpecies,storage.npcType, storage.npcLevel, storage.npcSeed, storage.npcParam)

function randomizeNPCValues(speciesList,typeList,override)
---Function taken from  ThreeTen22 / NpcSpawner on github
  if (not storage.npcLevel) or override then storage.npcLevel = math.random(1, 10) end
  if (not storage.npcSpecies) or override then
    storage.npcSpecies = util.randomFromList(speciesList or {"penguin"})
  end
  if (not storage.npcType) or override then
    storage.npcType = util.randomFromList(typeList or {"nakedvillager"})
  end
  if (not storage.npcSeed) or override then
    storage.npcSeed = math.random(1, 20000)
  end
end

function endInvasion(player, planet)
    sendInvasionMesage("The penguin invasion has been defeated!")
    --TBD player.invasionActiveList remove the invasion on planet
end

function sendInvasionMesage(textMessage)
    --TBD, duplicate of function in InvasionController. ALl the references there should be changed to use this one
    world.sendEntityMessage(playerId, textMessage)
end

function nonResponsePenalty(player, planet)
    sendInvasionMesage("You failed to save the planet from the Penguin invasion!")
end

function updateInvasions()
    for invasion in player.storage.invasionActiveList
        if player.storage.invasionKillCount >= invasionKillGoal
            endInvasion(invasion[3][1])
        end
    end
end

function update(dt)
    updateInvasions()


  if not storage.uniqueId then
    storage.uniqueId = sb.makeUuid()
    world.setUniqueId(entity.id(), storage.uniqueId)
  end



  --if we do not have a living NPC spawned, spawn a new one
  if storage.spawned == false then
    if self.spawnTimer < 0 then

      --randomItUp(self.randomize))
      local pos = entity.position()

      if string.find(object.name(), "floor",-6,true) then
        pos[2] = pos[2] + 8
      end
      local npcId = world.spawnNpc(pos, storage.npcSpecies,storage.npcType, storage.npcLevel, storage.npcSeed, storage.npcParam)

      world.callScriptedEntity(npcId, "status.addEphemeralEffect","beamin")
      --assign our new NPC a special unique id
      storage.spawnedID = sb.makeUuid()
      world.setUniqueId(npcId, storage.spawnedID)
      storage.spawned = true
      self.spawnTimer = math.floor(self.maxRespawnTime)
      --logVariant()
    else
      self.spawnTimer = self.spawnTimer - dt
    end
  else
    --if our spawned NPC has died or disappeared since last tick, set spawned to false.
    if storage.spawnedID and world.loadUniqueEntity(storage.spawnedID) == 0 then
      storage.spawned = false
      self.spawnTimer = self.maxRespawnTime
    end
  end

end

function killNpc()
  self.spawnTimer = self.maxRespawnTime
  if (not storage.spawnedID) then storage.spawned = false; return end
  local loadedEnitity = world.loadUniqueEntity(storage.spawnedID)
  if loadedEnitity ~= 0 then
    world.callScriptedEntity(loadedEnitity, "npc.setDropPools",{})
    world.callScriptedEntity(loadedEnitity, "npc.setPersistent",false)
    world.sendEntityMessage(loadedEnitity,  "recruit.beamOut")
  end
  storage.spawned = false
end
