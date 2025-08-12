local player = game:GetService("Players").LocalPlayer
local winGui = player.PlayerGui:WaitForChild("Win").Frame.TextLabel
local guiEvent = game:GetService("ReplicatedStorage").Remotes.EndGame


local EndGameGui = {}

function EndGameGui:End(Winner)
	
	-- Loop through all GUI elements and disable them
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, guiElement in pairs(playerGui:GetChildren()) do
		if guiElement:IsA("GuiObject") then
			guiElement.Enabled = false
		end
	end

	script.Parent.Start.gameMusic:Stop()
	
	task.wait(1)
	
	script.Winner:Play()
	
	winGui.Text = "Congratulations " .. Winner .. " has won, please leave the game!"
	winGui.Parent.Parent.Enabled = true

end

function EndGameGui:run()
	guiEvent.OnClientEvent:Connect(function(...)
		local _Player = ...
		self:End(_Player)
	end)
end

return EndGameGui
