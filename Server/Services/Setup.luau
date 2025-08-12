
local RP = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GD = require(RP.GameData)
local Logger = require(RP.Logger)
local StartGame = RP.Remotes.StartGame
local LoadedIn = RP.Remotes.LoadedIn
local Promise = require(RP.Utility.Promise)
local TeleportService = game:GetService("TeleportService")
local loadedCount = 0

function playerJoined(player)
	
	-- Get the teleport data for the player
	local teleportData = TeleportService:GetLocalPlayerTeleportData(player)
	
	--MakeTrueForTesting
	teleportData = true
	
	if teleportData then
		-- Extract the custom data
		local deckData --= teleportData.deckData
		
		--Make DeckData for Testing
		deckData = {
			"Air Spirit",
			"Water Spirit",
			"Earth Spirit",
			"Fire Spirit",
			"Skeleton",
			"Air Spirit",
			"Fire Spirit",
			"Imp",
			"Demon Hound",
		}
		
		GD.Decks[player.Name] = {}
		
		for _, card in next, deckData do
			
			table.insert(GD.Decks[player.Name], card)

		end
		
		Logger.Log(player.Name .. "Deck", GD.Decks[player.Name])
		
	else
		print("No teleport data found for player.")
	end
end


local GameSetup = {}



function GameSetup:MapPlayersToTeams()
	for i, player in Players:GetChildren() do
		GD.TeamMappings[player.Name] = "Team"..i
		player.RespawnLocation = game.Workspace.PlayerSpawns["Team"..i]
		player:LoadCharacter()
	end
	
	
end


function GameSetup:LoadedIn(player)
	loadedCount += 1
	if loadedCount >=2 then
		
		--Setup Teams
		Promise.try(function()
			GameSetup:MapPlayersToTeams()
		end)
		:andThen(function()
				StartGame:FireAllClients(GD.Decks, GD.TeamMappings)
		end)
		:catch(function()
			warn()
		end)

		Logger.Log("Team Mappings", GD.TeamMappings)
	end
end

function GameSetup:run()
	
	Players.PlayerAdded:Connect(playerJoined)
	
	LoadedIn.OnServerEvent:Connect(function(...)
		self:LoadedIn(...)
	end)
end


return GameSetup
