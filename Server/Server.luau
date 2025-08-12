local PlayerService = game:GetService("Players")
local SS = game:GetService("ServerScriptService")
local Utility = game:GetService("ReplicatedStorage"):WaitForChild("Utility")
local Promise = require(Utility.Promise)
local Components = SS:WaitForChild("Components")
local Services = SS:WaitForChild("Services")

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
		print("Server component: \"" .. comp.Name .. "\" loaded!")
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