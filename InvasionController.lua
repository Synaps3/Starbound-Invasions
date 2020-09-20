--Invasion controller manages the state of ongoing invasions once started in the mod
--Started 8/2/2020 D. G. Andrews
local InvasionSpawn = require "scripts/InvasionSpawns"

function init()
--init() - this function is called by game evey X millisec while you are placing this object
end

function main()
    --main() - this function is called by game evey X millisec after you've placed this object.

end

function startInvasion(player, faction, startedTime, state)
    --Invasions have a player who owns the settlement, a faction doing the invading (e.g. pirate penguins), a time it was announced, and a state. Valid states are "gathering", "scouting", "active", "ended"
    if faction not in player.storage.InvasionList
            locAndDifficulty = getColoniesOwnedBy(player)
            player.storage.InvasionGatheringList = table.insert(player.storage.InvasionList, faction, startedTime, locAndDifficulty)
            sendInvasionMesage("The penguins are coming for your settlement!")
    else
        world.debugText("Invasions Mod Error: Already an invasion going for player and faction id:", tech.aimPosition(), "green")
    end
end

function update(dt)
    updateInvasionsList()
end

function getColoniesOwnedBy(player)
    --TBD this function should pick one colony owned by a player at random and return its location and its difficulty level
       return [loc, difficulty]
end

function sendInvasionMesage(textMessage)
    --TBD
    world.sendEntityMessage(playerId, textMessage)
end

function getCurrentPlayerPlanet(player)
    --TBD: THis function returns the planet the player is on
    return planet
end

function updateInvasionsList():
    for player in playerList
        for factionInvasion in player.storage.InvasionGatheringList
            currentDateTime = os.time(os.date('!*t'))
            if (factionInvasion[2] + 5.0) > currentDateTime --5 minutes after invasion announced
                player.storage.InvasionScoutingList = table.insert(player.storage.InvasionScoutingList, factionInvasion)
                --TBD remove the invasioon from the gathering list
                sendInvasionMesage("The penguins have arrived!")
            end
        end
        for factionInvasion in player.storage.InvasionScoutingList
            if factionInvasion[2] % 1 = 0 --TBD only perform this check every minute
                if factionInvasion[4] == getCurrentPlayerPlanet()
                    player.storage.InvasionActiveList = table.insert(player.storage.InvasionActiveList, factionInvasion)
                    -- tbd remove the invasion from the scouting list
                    InvasionSpawns.startSpawning(faction,player,planet)
                end
            end
        end
        for factionInvasion in player.storage.InvasionScoutingList
            if (factionInvasion[2] + 20.0) > currentDateTime -- 20 minutes since invasion announced and no player response
                InvasionSpawns.nonResponsePenalty(planet)
                InvasionSpawns.endInvasion(player, planet)
    end
end