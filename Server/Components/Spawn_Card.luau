local RS = game:GetService("ReplicatedStorage")
local Remotes = RS.Remotes
local SStore = game:GetService("ServerStorage")
local spawnEvent = Remotes.SpawnCard
local GD = require(RS.GameData)

local SpawnServer = {}

SpawnServer.SpawnID = 0

local function waitForDescendants(object)
	for _, descendant in ipairs(object:GetDescendants()) do
		if not descendant.Parent then
			repeat
				wait()
			until descendant.Parent
		end
	end
end

function SpawnServer:Spawn(player, lane, card)
	
	for _, descendant in ipairs(SStore:WaitForChild(card):GetDescendants()) do
		if not descendant.Parent then
			repeat
				task.wait()
			until descendant.Parent
		end
	end
	
	local spawnablecard = SStore:WaitForChild(card):Clone()
	
	for _, descendant in ipairs(spawnablecard:GetDescendants()) do
		if not descendant.Parent then
			repeat
				task.wait()
			until descendant.Parent
		end
	end

	local team = GD.TeamMappings[player.Name]
	GD["Cards"][SpawnServer.SpawnID] = 
	{
		["Lane"] = tonumber(lane),
		["Team"] = team
	}
	--spawnablecard.Name = SpawnServer.SpawnID
	spawnablecard:SetAttribute("id", SpawnServer.SpawnID)
	spawnablecard:AddTag("spawned")
	spawnablecard.Parent = workspace.Cards
	SpawnServer.SpawnID += 1
	
end

function SpawnServer:run()
	
	spawnEvent.OnServerEvent:Connect(function(...) 
		self:Spawn(...)
	end)
	
end


return SpawnServer
