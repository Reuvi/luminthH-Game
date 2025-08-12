local Team1 = workspace.MAP.Hearts.heart1:WaitForChild("Icosphere"):WaitForChild("SurfaceGui").Frame.TextLabel
local Team2 = workspace.MAP.Hearts.heart2:WaitForChild("Icosphere"):WaitForChild("SurfaceGui").Frame.TextLabel
local player = game:GetService("Players").LocalPlayer
local GD = require(game:GetService("ReplicatedStorage").GameData)
local hGui = player.PlayerGui:WaitForChild("Health").Canvas
local SelfHP = hGui:WaitForChild("Player").HealthAmount
local EnemyHP = hGui:WaitForChild("Enemy").HealthAmount

local ClientHeart = {}


function ClientHeart:updateHealth()
	
	
	local team = GD.TeamMappings[player.Name]
	
	if tostring(team) == "Team1" then
		SelfHP.Text = Team1.Text
		EnemyHP.Text = Team2.Text
	elseif tostring(team) == "Team2" then
		SelfHP.Text = Team2.Text
		EnemyHP.Text = Team1.Text
	end
end



function ClientHeart:run()
	
	Team1:GetPropertyChangedSignal("Text"):Connect(function()
		ClientHeart:updateHealth()
	end)

	Team2:GetPropertyChangedSignal("Text"):Connect(function()
		ClientHeart:updateHealth()
	end)
	
	
end

return ClientHeart
