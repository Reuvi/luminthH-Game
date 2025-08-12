---Services
local Players = game:GetService("Players")
local SG = game:GetService("StarterGui")
local Utility = game:GetService("ReplicatedStorage"):WaitForChild("Utility")
local Promise = require(Utility.Promise)

---Player Variables
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local PS = player.PlayerScripts
local Components = PS:WaitForChild("Components")
local Services = PS:WaitForChild("Services")

---Waiting For Gui To Load
for _, guiObj in next, SG:GetDescendants() do
	while not playerGui:FindFirstChild(guiObj.Name, true) do
		task.wait()
	end
end

--Running all Components
local function runComp(comp)
	local module = require(comp)
	local containsRun = (type(module) == "table") and (type(module["run"]) == "function")
	if containsRun then
		module:run()
	end	
end

local Runner = Promise.promisify(runComp)

for _, comp in next, Components:GetChildren() do
	Runner(comp):andThen(function()
		print("Client component: \"" .. comp.Name .. "\" loaded!")
	end):catch(warn)
end

--Running all Services
local function runServ(serv)
	local module = require(serv)
	local containsRun = (type(module) == "table") and (type(module["run"]) == "function")
	if containsRun then
		module:run()
	end	
end

local Runner = Promise.promisify(runServ)

for _, serv in next, Services:GetChildren() do
	Runner(serv):andThen(function()
		print("Server service: \"" .. serv.Name .. "\" loaded!")
	end):catch(warn)
end

