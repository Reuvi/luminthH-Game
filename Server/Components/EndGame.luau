local HutTeam2 = workspace.MAP.Hearts.heart1:WaitForChild("Icosphere"):WaitForChild("SurfaceGui").Frame.TextLabel
local HutTeam1 = workspace.MAP.Hearts.heart2:WaitForChild("Icosphere"):WaitForChild("SurfaceGui").Frame.TextLabel
local guiEvent = game:GetService("ReplicatedStorage").Remotes.EndGame
local GD = require(game:GetService("ReplicatedStorage"):WaitForChild("GameData"))

local EndGame = {}
local won = false
function EndGame:End(team)

	if (won) then
		return
	end

	won = true

	-- Loop through workspace.Card and destroy each
	local cardFolder = workspace:FindFirstChild("Cards")
	if cardFolder then
		for _, card in pairs(cardFolder:GetChildren()) do
			card:Destroy()
		end
	end
	
	for _Player, _Team in GD["TeamMappings"] do
		if _Team == team then
			guiEvent:FireAllClients(_Player)
			break
		end
	end

end

function EndGame:run()
	-- Function to check the text value and print "game over" if the number is <= 0
	local function checkGameOver(hutLabel, team)
		local num = tonumber(hutLabel.Text)
		if num and num <= 0 then
			EndGame:End(team)
			-- Call EndGame:End or any other end game logic here
		end
	end

	-- Connect the Changed event to the checkGameOver function for both hut labels
	HutTeam1:GetPropertyChangedSignal("Text"):Connect(function()
		checkGameOver(HutTeam1, "Team1")
	end)

	HutTeam2:GetPropertyChangedSignal("Text"):Connect(function()
		checkGameOver(HutTeam2, "Team2")
	end)

	-- Initial check in case the text is already <= 0 at the start
	checkGameOver(HutTeam1, "Team1")
	checkGameOver(HutTeam2, "Team2")
end

return EndGame
