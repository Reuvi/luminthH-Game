local RS = game:GetService("ReplicatedStorage")
local GD = require(RS.GameData)
local Logger = require(RS.Logger)
local Utility = RS.Utility
local Promise = require(Utility.Promise)
local Component = require(Utility.Component)
local Remotes = RS.Remotes
local PlaceCard = Remotes.PlaceCard
local UpdateState = Remotes.UpdateState
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local Extensions = RS.Extensions
local JanitorCreator = require(Extensions.JanitorCreator)
local Bindables = RS.Bindables
local PlaceCardClient = Bindables.ClientPlaceCard
local UpdatePosition = Remotes.UpdatePosition
local UpdatePositionClient = Bindables.UpdatePosition
local UpdateHealthServer = Remotes.UpdateHealth
local UpdateHealth = Bindables.UpdateHealth
local Heart2 = workspace.MAP.Hearts.heart1.Icosphere:WaitForChild("SurfaceGui").Frame.TextLabel
local Heart1 = workspace.MAP.Hearts.heart2.Icosphere:WaitForChild("SurfaceGui").Frame.TextLabel
local Hut1 =  workspace.MAP.HUTS.hut
local Hut2 = workspace.MAP.HUTS.hut2
local PathfindingService = game:GetService("PathfindingService")

local CardNPC = Component.new({
		Tag = "spawned",
		Extensions = {JanitorCreator},
	})


function CardNPC:Construct()
	
	--Set General Card Data
	self.Id = self.Instance:GetAttribute("id")
	GD["Cards"][self.Id]["dataRef"] = self 
	self.Team = GD["Cards"][self.Id].Team
	self.Lane = GD["Cards"][self.Id].Lane
	self.Rarity = self.Instance:GetAttribute("Rarity")
	
	--Set Cards Stats
	self.Name = self.Instance.Name 
	self.Health = tonumber(self.Instance:GetAttribute("Health"))
	self.Defense = self.Instance:GetAttribute("Defense") 
	self.Cooldown = self.Instance:GetAttribute("Cooldown")
	self.Speed = tonumber(self.Instance:GetAttribute("Speed"))
	self.Attack = tonumber(self.Instance:GetAttribute("Attack"))
	self.Fly = self.Instance:GetAttribute("Flyer") or false
	self._Vision = 20
	self.Range =  tonumber(self.Instance:GetAttribute("Range"))
	self.Reach = false
	self.AttackType = "Melee"
	
	--Anim Stuff could be changed
	self.AttackAnim = self.Instance:WaitForChild("Attack")
	self.AnimationController = self.Instance:WaitForChild("AnimationController")
	self.AnimTrack = self.AnimationController:LoadAnimation(self.AttackAnim)
	self.Length = self.AnimTrack.Length * .9
	
	
	--Set Card State Data 
	--States are, Moving, Attacking, AttackCooldown, Died, Idle
	self.State = "Walk"
	
	--Card World Data
	self.Pos = Vector3.new(
		GD.Lanes[self.Team][self.Lane].X, 
		GD.Lanes[self.Team][self.Lane].Y, 
		GD.Lanes[self.Team][self.Lane].Z + math.random(-6, 6)
	)
	
	if self.Fly then
		self.Pos += Vector3.new(0, 6, 0)
	end
	
	if self.Team == "Team1" then
		self.Ori = CFrame.Angles(0, math.rad(180), 0)
		self.enemyHeartText = Heart1
		self.enemyHut = Hut1
	
	elseif self.Team == "Team2" then
		self.Ori = CFrame.Angles(0, math.rad(0), 0)
		self.enemyHeartText = Heart2
		self.enemyHut = Hut2
	end
	
	self.enemyHeartTextModel = self.enemyHeartText.Parent.Parent.Parent
	
	self.targetPos = nil
	self.targetCF = nil
	self.initialCf = Instance.new("CFrameValue")
	self.tween = nil
	self.target = nil
	
	--Response Count
	self.ResponseCount = 0
	self.Open = true
	
	self._janitor:LinkToInstances(self.Instance, self)
	
	--Debug/FlyAnimMovement
	self.Bob = -0.5
	
	--Holding on anims
	self.locked = true
	

	
end

function CardNPC:FindTarget()
	
	local min = self._Vision
	local target = nil
	for id, card in next, GD["Cards"] do
		--or GD["Cards"][id]["Team"] == self.Team
		if id == self.Id or GD["Cards"][id] == nil or GD["Cards"][id]["Team"] == self.Team or  self.Pos == nil or card["dataRef"] == nil then
			continue
		end
		
		if ((self.Pos - card["dataRef"].Pos) * Vector3.new(1, 0, 1)).Magnitude <= min then
			if card["dataRef"].Fly and not self.Reach and not self.Fly then
				continue
			end
			min =  ((self.Pos - card["dataRef"].Pos) * Vector3.new(1, 0, 1)).Magnitude
			target = id
		end

	end 
	
	
	return target
end

function CardNPC:Release()

	self.locked = false

end

function CardNPC:AccumulateResponses(_id, _responseCount, func, event)
	if self.Id == _id then
		self.ResponseCount += 1
		if self.ResponseCount == _responseCount then
			self.ResponseCount = 0
			--print(self.Open)
			--if self.Open then
				self.Open = false
				Promise.new(function(resolve, reject)
					func()
					resolve()
				end)
				:andThen(function()
					event:Disconnect()
					--warn("Signal Disconnected")
				--	self.Open = true
				end)
				:catch(function(error)
						warn("Signal Error occurred: " .. tostring(error))
				end)
			--end
		end
	end
end


function CardNPC:AttackNPC()
	
	if GD["Cards"][self.target] == nil then
		self.target = nil
		self:CardManager()
		return
	end

	self.Ori = (CFrame.lookAt(self.Pos, GD["Cards"][self.target]["dataRef"].Pos) * CFrame.Angles(0, math.rad(-90), 0)).Rotation
	self.Instance:PivotTo(CFrame.new(self.Pos) * self.Ori)
	self.State = "Attack"
	GD["Cards"][self.target]["dataRef"].Health -= self.Attack
	--DMG Enemy
	
	--UpdateHealth + ANim
	UpdateState:FireAllClients(self.State, self.Id, self.AttackType, self.target, GD["Cards"][self.target]["dataRef"].Health)
	
	--When the hit opponets healthj updates we continue. We should make it wait till that happens.
	
	self.DeathSignal = UpdateHealth.Event:Connect(function(id)
		self:AccumulateResponses(id, 2, 
			function()
				self:Release()
			end, 
			self.DeathSignal)
	end)
	
	while self.locked do
		
		task.wait()
	end
	
	self.locked = true
	--Temp Addition
	--print(self.Length)
	--UpdateHealthServer:FireAllClients(self.target, GD["Cards"][self.target]["dataRef"].Health, self.Length)
	
	--If Enemy Died 
	if GD["Cards"][self.target] then
		if GD["Cards"][self.target]["dataRef"].Health <= 0 then
			GD["Cards"][self.target] = nil
			self.target = nil
			self.State = "Walk"
			UpdateState:FireAllClients(self.State, self.Id)
		end
	else
		self.target = nil
		self.State = "Walk"
		UpdateState:FireAllClients(self.State, self.Id)
	end
	self:CardManager()
end

function CardNPC:Death()
	--Finds new target after original target Dead or kills itself Attack Logic
	self.Instance:Destroy()

end

function CardNPC:AttackHut()
	if self.State == "Dead" then
		print(self.Instance.Name, ' Shouldnt be here')
		return
	end
	self.Ori = (CFrame.lookAt(self.Pos, self.enemyHeartTextModel.CFrame.Position) * CFrame.Angles(0, math.rad(-90), 0)).Rotation
	self.Instance:PivotTo(CFrame.new(self.Pos) * self.Ori)
	self.State = "Attack"

	--UpdateHealth + ANim
	UpdateState:FireAllClients(self.State, self.Id)
	
	local num = tonumber(self.enemyHeartText.Text)
	self.enemyHeartText.Text = num - self.Attack
	
	self:CardManager()
	
end

function CardNPC:CardManager()
	if self.Health <= 0  or self.State == "Dead" then
		print("Stopped Loop")
		self:Death()
		return
	end

	if self.target then
		if GD["Cards"][self.target] == nil then
			self.target = nil
			self:CardManager()
			return
		end

		if ((self.Pos - GD["Cards"][self.target]["dataRef"].Pos) * Vector3.new(1, 0, 1)).Magnitude <= self.Range then
			task.wait(self.Cooldown)
			self:AttackNPC()
			return
		end
--[[
		local path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = false,
			AgentMaxSlope = 45
		})
		path:ComputeAsync(self.Pos, GD["Cards"][self.target]["dataRef"].Pos)

		if path.Status == Enum.PathStatus.Success then
			local waypoints = path:GetWaypoints()
			if #waypoints > 1 then
				local nextWaypoint = waypoints[2].Position
				local distanceToNextWaypoint = (nextWaypoint - self.Pos).Magnitude
				if self.Speed > distanceToNextWaypoint then
					self.targetPos = nextWaypoint
					print(self.targetPos)
				else
					local unitVector = (nextWaypoint - self.Pos).Unit
					self.targetPos = (self.Pos + unitVector * self.Speed)
					print(self.targetPos)
				end
				self:Activate()
				return
			end
		end
		]]--
		-- Fallback to direct movement if pathfinding fails
		local unitVector = (GD["Cards"][self.target]["dataRef"].Pos - self.Pos).Unit
		if self.Speed > (GD["Cards"][self.target]["dataRef"].Pos - self.Pos).Magnitude then
			self.targetPos = self.Pos + unitVector * ((GD["Cards"][self.target]["dataRef"].Pos - self.Pos).Magnitude - self.Range)
		else
			self.targetPos = self.Pos + unitVector * self.Speed
		end
		self:Activate()
	else
		self.target = self:FindTarget()
		--ReplaceAbleCode Below
		if self.Team == "Team1" then
			self.targetPos = self.Pos + Vector3.new(self.Speed, 0, 0)
			if self.targetPos.X >= 162 then
				task.wait(self.Cooldown)
				self:AttackHut()
				return
			end 
		elseif self.Team == "Team2" then
			self.targetPos = self.Pos - Vector3.new(self.Speed, 0, 0)
			if self.targetPos.X <= -8 then
				task.wait(self.Cooldown)
				self:AttackHut()
				return
			end
		end
		self:Activate()
	end
end


function CardNPC:GenerateMovement()
	self.Bob *= -1
	self.initialCf.Value = CFrame.new(self.Pos) * self.Ori
	
	self.targetPos = Vector3.new(self.targetPos.X, self.Pos.Y, self.targetPos.Z)
	self.Ori = (CFrame.lookAt(self.Pos, self.targetPos) * CFrame.Angles(0, math.rad(-90), 0)).Rotation
	self.Pos = self.targetPos
	if self.Fly then
		self.Pos += Vector3.new(0, self.Bob, 0)
	end
	self.targetCF = CFrame.new(self.Pos) * self.Ori
	--This will send a Response from Both Clients when first Client Finishes it Will Run Attack Mode Other
	UpdatePosition:FireAllClients(self.Id, self.initialCf.Value, self.targetCF, self.Pos, self.Ori)
end

function CardNPC:Activate()
	
	self.MoveSignal = UpdatePositionClient.Event:Connect(function(id)
		self:AccumulateResponses(id, 2, 
			function()
				self.Instance:PivotTo(CFrame.new(self.Pos) * self.Ori)
				self:CardManager()
			end, 
			self.MoveSignal)
	end)
	
	self:GenerateMovement()
	
	return

end

function CardNPC:SpawnAllClients()
	
	--Put Card in Position on the Client's Screen
	if not self.Fly then
		self.Pos += Vector3.new(0, 2, 0)
		self.Instance:PivotTo(CFrame.new(self.Pos) * self.Ori)
	else
		self.Instance:PivotTo(CFrame.new(self.Pos) * self.Ori)
	end
	--Initialize Values with the Card
	PlaceCard:FireAllClients(self.Pos, self.Ori, self.Health, self.State, self.Team, self.Id)
	
	self.ClientSignal = PlaceCardClient.Event:Connect(function(plr, id)
		self:AccumulateResponses(id, 2, 
			function()
				UpdateState:FireAllClients(self.State, self.Id)
				self:CardManager()
			end, 
			self.ClientSignal)
	end)
	
	
end

function CardNPC:Start()
	
	
	self:SpawnAllClients()	
	--Start Commanding it to do an action pased on state

end

function CardNPC:Stop()
	--print("Killed ", self.Name)
	self._janitor:Cleanup()
	self.State = "Dead"
	UpdateState:FireAllClients(self.State, self.Id)
	print("Dead")
	
end

return CardNPC
