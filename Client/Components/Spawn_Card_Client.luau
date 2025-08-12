local moveCard = {}

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local CollectionService = game:GetService("CollectionService")
local Camera = game.Workspace.CurrentCamera
local ServerSpawn = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SpawnCard")
local updateCard = game:GetService("ReplicatedStorage").Bindables.updateCards
local TweenService = game:GetService("TweenService")
local GD = require(game:GetService("ReplicatedStorage").GameData)
local bgui = player.PlayerGui.Deck:WaitForChild("Canvas"):GetChildren()

local UserInputService = game:GetService("UserInputService")



local keyCodes = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four
}


moveCard.selected = nil
moveCard.state = false
moveCard.lane = nil
moveCard.PrevPos = nil

function moveCard:UpdateSelected(button)
	if moveCard.selected then
		moveCard.selected.Position = moveCard.PrevPos
	end

	if moveCard.selected == button then
		moveCard.selected = nil
		moveCard.PrevPos = nil
		moveCard.state = false
		return
	end

	moveCard.state = true
	moveCard.selected = button
	moveCard.PrevPos = button.Position

	--Add Tween
	button.Position = UDim2.new(
		button.Position.X.Scale, button.Position.X.Offset,
		button.Position.Y.Scale, button.Position.Y.Offset - 30
	)

end


function moveCard:Setup()
	for _, gui in next, CollectionService:GetTagged("lane") do
		
		gui.TextButton.Active = true
		
		--Setup GUI Connections to mouse entering
		gui.MouseEnter:Connect(function(x, y)
			if moveCard.state then
				moveCard.lane = gui.Parent.Parent
				moveCard.lane.Parent:WaitForChild("bridge"):WaitForChild("Highlight").Enabled = true
			end	
		end)
		
		gui.MouseLeave:Connect(function(x, y)
			if moveCard.state then
				if moveCard.lane then
					moveCard.lane.Parent:WaitForChild("bridge"):WaitForChild("Highlight").Enabled = false
					moveCard.lane = nil
				end
			end	
		end)
		
		gui.TextButton.MouseButton1Click:Connect(function()
			if moveCard.state then
				if moveCard.lane then
					moveCard.lane.Parent:WaitForChild("bridge"):WaitForChild("Highlight").Enabled = false
					if moveCard.lane and GD["XP"] >= moveCard.selected:GetAttribute("Xp") then
						updateCard:Fire("ingame", moveCard.selected:GetAttribute("Name"), moveCard.selected)
						ServerSpawn:FireServer(moveCard.lane.Name, moveCard.selected:GetAttribute("Name"))
						
						local button = moveCard.selected
						moveCard:UpdateSelected(moveCard.selected)

						-- Define the tween information
						local tweenInfo = TweenInfo.new(
							1, -- Time (in seconds) for the tween to complete
							Enum.EasingStyle.Quad, -- Easing style
							Enum.EasingDirection.Out, -- Easing direction
							0, -- Number of times to repeat the tween
							false, -- Should the tween reverse once completed
							0 -- Delay time before the tween starts
						)

						-- Create the tween
						local tween = TweenService:Create(button, tweenInfo, {Position = OriginalPosition})

						tween:Play()

						moveCard.lane = nil

						--Prevent super fast clicks
						task.wait(0.5)
					else
						print("Not Enough XP")
					end	
				end	
			end
		end)
	end
end

function moveCard:run()
	
	moveCard:Setup()
	
	--[[
	coroutine.wrap(function()
		mouse.Move:Connect(function()
			position = Vector2.new(mouse.X, mouse.Y)
		end)
	end)()
	]]--
	
	moveCard:Setup()


	for _, button in pairs(bgui) do
		if button:IsA("GuiButton") then  -- GuiButton covers both ImageButton and TextButton
			button.Active = true

			print("Found a button with DeckCard tag")

			button.MouseButton1Click:Connect(function()
				print("Button clicked")
				moveCard:UpdateSelected(button)
			end)
		
			local keyCode = keyCodes[tonumber(button:GetAttribute("x"))]
			if keyCode then
				UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if not gameProcessed and input.KeyCode == keyCode then
						print("Key pressed: " .. tostring(keyCode))
						moveCard:UpdateSelected(button)
					end
				end)
			else
				warn("No key code assigned for button index: ")-- .. tonumber(button:GetAttribute("Name")) - 1 )
			end
		else
			warn("Tagged object is not a GuiButton: " .. button:GetFullName())
		end
	end

--[[
				if not using then
					using = true
					moveCard.state = true
					moveCard.selected = button:GetAttribute("Name")

					local signal = button.MouseButton1Up:Connect(function() 
						
						if moveCard.lane then
							moveCard.lane.Parent:WaitForChild("bridge"):WaitForChild("Highlight").Enabled = false
							if moveCard.lane and GD["XP"] >= button:GetAttribute("Xp") then
								updateCard:Fire("ingame", moveCard.selected, button)
								ServerSpawn:FireServer(moveCard.lane.Name, moveCard.selected)
								spawned = true
							elseif moveCard.lane then
								print("Not Enough XP")
							end
						end
						
						moveCard.state = false
						
					end)

					while moveCard.state do
						task.wait()
						button.Position = UDim2.new(0, position.X, 0, position.Y)


					end

					signal:Disconnect()
					moveCard.selected = nil
					
					if moveCard.lane and spawned then
						button.Position = incomingPos
						
						-- Define the tween information
						local tweenInfo = TweenInfo.new(
							1, -- Time (in seconds) for the tween to complete
							Enum.EasingStyle.Quad, -- Easing style
							Enum.EasingDirection.Out, -- Easing direction
							0, -- Number of times to repeat the tween
							false, -- Should the tween reverse once completed
							0 -- Delay time before the tween starts
						)

						-- Create the tween
						local tween = TweenService:Create(button, tweenInfo, {Position = OriginalPosition})

						tween:Play()
						spawned = false
					else
						button.Position = OriginalPosition
					end
					
					moveCard.lane = nil
					
					--Prevent super fast clicks
					task.wait(0.5)
					using = false
				end
			end)

		else
			print("Error")
		end
	end ]]--
end
return moveCard
