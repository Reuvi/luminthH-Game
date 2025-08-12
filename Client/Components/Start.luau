--Local Vars
local RP = game:GetService("ReplicatedStorage")
local GD = require(RP.GameData)
local Remotes = RP.Remotes
local Start = Remotes.StartGame
local Logger = require(RP.Logger)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local updateCards = RP.Bindables.updateCards
local CollectionService = game:GetService("CollectionService")
local gui = player.PlayerGui:WaitForChild("Deck"):WaitForChild("Canvas")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PlayerScripts = player:WaitForChild("PlayerScripts")
local ControlModule = require(PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

local player = Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

local freeCamEnabled = false
local flySpeed = 100 -- Adjust the speed as needed


local StartGame = {}

StartGame.ActiveDeck = {}
StartGame.IdleDeck = {}

-- Function to toggle free camera mode
local function toggleFreeCam()
	freeCamEnabled = not freeCamEnabled
	if freeCamEnabled then
		ControlModule:Disable()
		camera.CameraType = Enum.CameraType.Scriptable
		-- Start the camera high in the air
		camera.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position + Vector3.new(0, 100, 0)) * CFrame.Angles(0, math.rad(90), 0)
	else
		ControlModule:Enable()
		camera.CameraType = Enum.CameraType.Custom
		if player.Character then
			camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
		end
	end
end

-- Fly Camera Movement
local function flyCamera(deltaTime)
	local moveVector = Vector3.new()
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveVector = moveVector + Vector3.new(1, 0, 0) -- Forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveVector = moveVector + Vector3.new(-1, 0, 0) -- Backward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveVector = moveVector + Vector3.new(0, 0, 1) -- Left
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveVector = moveVector + Vector3.new(0, 0, -1) -- Right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
		moveVector = moveVector + Vector3.new(0, -1, 0) -- Down
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.E) then
		moveVector = moveVector + Vector3.new(0, 1, 0) -- Up
	end

	camera.CFrame = camera.CFrame + (moveVector * flySpeed * deltaTime)
end


function StartGame:UpdateXP(add)
	if GD["XP"] < 10 and add then
		GD["XP"] += 1
	end
	playerGui:WaitForChild("XP"):WaitForChild("Back"):WaitForChild("label").Text = GD["XP"]
	--Do Some XP Progress Bar Shit
	local xpBar	= playerGui:WaitForChild("XP"):WaitForChild("Back"):WaitForChild("XPBar")

	-- Calculate the target size for xpBar
	local targetSize = UDim2.new(((GD["XP"] / 10)), 0, 1, 0)

	-- Tween information
	local tweenInfo = TweenInfo.new(
		0.5, -- Duration (in seconds)
		Enum.EasingStyle.Quad, -- Easing style
		Enum.EasingDirection.Out, -- Easing direction
		0, -- Number of times to repeat (-1 for infinite)
		false, -- Should the tween reverse?
		0 -- Delay before tween starts
	)

	-- Create the tween
	local tween = game:GetService("TweenService"):Create(xpBar, tweenInfo, {Size = targetSize})

	-- Play the tween
	tween:Play()
end


local function swapValues(table1, table2, value)
	-- Find and remove the first occurrence of "value" in table1
	local firstValue
	for i, v in ipairs(table1) do
		if v == value then
			firstValue = v
			table.remove(table1, i)
			break
		end
	end

	-- If "value" not found in table1, return an error
	if not firstValue then
		error("Value not found in table1")
	end

	-- Randomly select and remove a value from table2
	if #table2 == 0 then
		error("Table2 is empty")
	end
	
	local randomIndex = math.random(#table2)
	local secondValue = table2[randomIndex]
	table.remove(table2, randomIndex)

	-- Append the first value to table2
	table.insert(table2, firstValue)

	-- Append the second value to table1
	table.insert(table1, secondValue)
	return secondValue
end

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function StartGame:switchCards(state, cardData, optionalButton)
	if state == "setUp" then
		shuffle(cardData)
		
		for i = 1, 4 do
			table.insert(StartGame.ActiveDeck, cardData[i])
		end
		
		for i = 5, #cardData do
			table.insert(StartGame.IdleDeck, cardData[i])
		end
		
		local idx = 1
		for _, button in next, gui:GetChildren() do
			if button:IsA("ImageButton") then
				button:SetAttribute("Name", StartGame.ActiveDeck[idx])
				button:SetAttribute("Xp", GD["CardXP"][StartGame.ActiveDeck[idx]])
				button.Image = GD["CardImgs"][StartGame.ActiveDeck[idx]]
				idx += 1
			end
		end
		
		return	
	end
	
	GD["XP"] -= optionalButton:GetAttribute("Xp")
	StartGame:UpdateXP(false)
	local value = swapValues(StartGame.ActiveDeck, StartGame.IdleDeck, cardData)
	optionalButton:SetAttribute("Name", value)
	optionalButton:SetAttribute("Xp", GD["CardXP"][value])
	optionalButton.Image = GD["CardImgs"][value]
	
end


function StartGame:Begin(decks, teamMap)
	
	GD.TeamMappings = teamMap
	
	print(GD.TeamMappings)
	
	local playerCards = decks[player.Name]
	Logger.Log("Player Card Data", playerCards)
	
	updateCards:Fire("setUp", playerCards)
	
	local Countdown = playerGui.Seperator:WaitForChild("CountDown").TextLabel
	Countdown.Text = "3"
	Countdown.Parent.Enabled = true
	Countdown.Alert_Sound_Efffect:Play()
	task.wait(1)
	Countdown.Text = "2"
	Countdown.Alert_Sound_Efffect:Play()
	task.wait(1)
	Countdown.Text = "1"
	Countdown.Alert_Sound_Efffect:Play()
	task.wait(1)
	Countdown.Text = "Begin!"
	Countdown["Alert Buzzer"]:Play()
	task.wait(1)
	Countdown.Parent.Enabled = false
	playerGui:WaitForChild("XP"):WaitForChild("Back"):WaitForChild("label").Text = "Mana: " .. tostring(GD["XP"])
	
	for _, guiObj in pairs(playerGui:GetChildren()) do
		if guiObj:IsA("ScreenGui") and guiObj.Name ~= "Win" then
			guiObj.Enabled = true
		end
	end
	--script.gameMusic.Looped = true
	--script.gameMusic:Play()
	
	while true do
		StartGame:UpdateXP(true)
		wait(2)  -- Wait for 0.1 seconds
	end
	
end



function StartGame:run()
	Start.OnClientEvent:Connect(function(...)
		self:Begin(...)
	end)
	
	updateCards.Event:Connect(function(...)
		self:switchCards(...)
	end)
	
	
	-- Connect toggle function to a key (F for example)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.F and not gameProcessed then
			toggleFreeCam()
		end
	end)

	-- Update the camera position each frame
	RunService.RenderStepped:Connect(function(deltaTime)
		if freeCamEnabled then
			-- Lock camera orientation to look 90 degrees to the right and downwards
			local position = camera.CFrame.Position
			camera.CFrame = CFrame.new(position, position + Vector3.new(0, -1, 0)) * CFrame.Angles(0, math.rad(45), math.rad(90))
			flyCamera(deltaTime)
		end
	end)
	
end


return StartGame
