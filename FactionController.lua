--Faction controller manages the state of factions in the mod
--Started 8/2/2020 D. G. Andrews
--require "/scripts/InvasionController.lua"
local InvasionController = require "/scripts/InvasionController"

function init()
    -- load factions in from config files
    factionsList = ["Penguin Pirates",]
    playerlist = ["Teca",]

function dt()
    for player in playerlist
        for faction in factionsList
            raiseFactionHappiness(1)
        end
    end
    for faction in factions
        if storage.faction.happiness >=1
            currentDateTime = os.time(os.date('!*t'))
            InvasionController.startInvasion(player, faction, currentDateTime)
end

function raiseFactionHappiness(intIncrease)
    storage.faction.happiness += 1
end