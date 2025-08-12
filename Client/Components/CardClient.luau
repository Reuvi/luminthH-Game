local RS = game:GetService("ReplicatedStorage")
local GD = require(RS.GameData)
local Logger = require(RS.Logger)
local Utility = RS.Utility
local Promise = require(Utility.Promise)
local Component = require(Utility.Component)
local Remotes = RS.Remotes
local Bindables = RS.Bindables
local PlaceCard = Bindables.ClientPlaceCard
local PlaceCardServer = Remotes.PlaceCard
local warmup = Bindables.warmUp
local UpdateState = Bindables.UpdateState
local player = game:GetService("Players").LocalPlayer
local Extensions = RS.Extensions
local JanitorCreator = require(Extensions.JanitorCreator)
local TweenService = game:GetService("TweenService")
local tweenMoveInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local UpdatePositionClient = Bindables.UpdatePosition
local UpdatePositon = Remotes.UpdatePosition
local UpdateHealthClient = Bindables.UpdateHealth
local UpdateHealthServer = Remotes.UpdateHealth

local CardNPC = Component.new({
		Tag = "spawned",
		Extensions = {JanitorCreator},
	})

function CardNPC:UpdateHealth(spawnin)
	if self.State == "Dead" then
		return
	end 
	
	if self.HealthBar then
		
		if spawnin then
			self.particles:WaitForChild("BloodAndSpawn", 5).ShcokWave:Emit(1)
			self.particles.BloodAndSpawn.Impact:Emit(1)
			self.particles.BloodAndSpawn.ShcokWave2:Emit(1)
		else
			self.particles:WaitForChild("BloodAndSpawn", 5).Blood:Emit(25)
		end
		-- Calculate the target size for xpBar
		local targetSize = UDim2.new(((self.Health / self.Instance:GetAttribute("Health"))), 0, 1, 0)

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
		local tween = game:GetService("TweenService"):Create(self.HealthBar:WaitForChild("Frame"):WaitForChild("Back"):WaitForChild("HealthBar"), tweenInfo, {Size = targetSize})

		-- Play the tween
		tween:Play()
	end
end

function CardNPC:placeCard(Pos, Ori, Health, State, Team, Id)
	if Id == self.Instance:GetAttribute("id") then
		
		self.Id = Id
		self.Team = Team
		self.Pos = Pos
		self.Ori = Ori
		self.Health = Health
		self.State = State
		self.Name = self.Instance.Name
		self.HealthBar = RS:WaitForChild("HealthBar"):Clone()
		self.HealthBar:WaitForChild("Frame"):WaitForChild("NPCName").Text = self.Name
		if self.Team == "Team1" then
			self.HealthBar.Frame.NPCName.TextColor3 = Color3.new(0.666667, 0.333333, 1)
		elseif self.Team == "Team2" then
			self.HealthBar.Frame.NPCName.TextColor3 = Color3.new(0, 0.666667, 1)
		end
		self:UpdateHealth(true)
		self.HealthBar.Parent = self.Head
		
		Logger.Log("Card Spawned for ", player)
		PlaceCardServer:FireServer(self.Id)
	end
end

function CardNPC:Construct()
	
	self.State = ""
	self.Pos = ""
	self.Ori = ""
	self.Health = ""
	self.Head = self.Instance:WaitForChild("Cylinder", 5)
	self.Team = ""
	self.particles = self.Instance:WaitForChild("HumanoidRootPart", 5):WaitForChild("Particles", 5)
	self.particles:WaitForChild("WeldConstraint").Part1 = self.particles.Parent
	--AnimsSetup
	self.WalkAnim = self.Instance:WaitForChild("Walk")
	self.AttackAnim = self.Instance:WaitForChild("Attack")
	self.AnimationController = self.Instance:WaitForChild("AnimationController")
	self.AnimTrack = nil
	
	--Movement
	self.initialCf = Instance.new("CFrameValue")
	self.tween = nil
	
	--Signals
	self.Signal = PlaceCard.Event:Connect(function(...)
		self:placeCard(...)
		self.Signal:Disconnect()
		self.Signal = nil
	end)
	
	--Could be Changed
	self.MoveSignal = self.initialCf.Changed:Connect(function(val)
		self.Instance:PivotTo(CFrame.new(val.Position) * val.Rotation)
		self.Pos = val.Position
		self.Ori = val.Rotation
	end)
	--self._janitor:Add
	self._janitor:LinkToInstances(self.Instance, self)
	self._janitor:Add(self.MoveSignal)
end

--This is a Test Solution for Client side Tweening
function CardNPC:mover(initialCf, targetCf, pos, ori)
	self.Pos = pos
	self.Ori = ori
	self.initialCf.Value = initialCf
	self.tween = TweenService:Create(self.initialCf, tweenMoveInfo, {Value = targetCf})
	self.tween:Play()
	local ninetyPercentTime = 0.5 * 0.90
	-- Fire UpdatePositon at 90% completion
	task.delay(ninetyPercentTime, function()
		UpdatePositon:FireServer(self.Id)
	end)
	
	self.tween.Completed:Wait()
	self.tween:Destroy()
	--UpdatePositon:FireServer(self.Id)
end


function CardNPC:Animator(_TypeAttack, _TargId, _TargHealth)
	if self.AnimTrack then
		self.AnimTrack:Stop()
	end
	
	if self.State == "Walk" then
		local success, err = pcall(function()
			if self.WalkAnim then
				self.AnimTrack = self.AnimationController:LoadAnimation(self.WalkAnim)
				self.AnimTrack.Looped = true
				self.AnimTrack:Play()
			end
		end)
	elseif self.State == "Attack" then
		
		local success, err = pcall(function()
			if self.AttackAnim then
				self.AnimTrack = self.AnimationController:LoadAnimation(self.AttackAnim)
				self.AnimTrack.Looped = false
				self.AnimTrack:Play()
				task.wait(self.AnimTrack.Length * .9)
				
				--Run Attack Particles After Anim Plays
				if self.particles:WaitForChild("Attack", 1) then
					if self.particles.Attack:GetAttribute("EmitAmount") then
						print(self.particles.Attack:GetAttribute("EmitAmount"))
						for _, child in ipairs(self.particles.Attack:GetChildren()) do
							-- Check if the child is a ParticleEmitter
							if child:IsA("ParticleEmitter") then
								-- Emit particles
								child:Emit(self.particles.Attack:GetAttribute("EmitAmount"))
							end
						end
					else
						for _, child in ipairs(self.particles.Attack:GetChildren()) do
							-- Check if the child is a ParticleEmitter
							if child:IsA("ParticleEmitter") then
								-- Emit particles
								child:Emit(1)
							end
						end
					end
				end
				
				--Play Attack Sound for Impact/Release
				self.Instance.AttackSound:Play()
				
				--If Melee Update Health
				if _TypeAttack == "Melee" then
					UpdateHealthClient:Fire(_TargId, _TargHealth, self.Id)
				--If Projectile do Projectile then Update Health	
				elseif _TypeAttack == "Projectile" then	
					print("Do Proj Attack")
				end
			end
		end)
		
	elseif self.State == "Dead" then
		self.AnimTrack = nil
	end 
end

function CardNPC:Start()
	
	UpdateState.Event:Connect(function(_State, _Id, _TypeAttack, _TargId, _TargHealth)
		if _Id == self.Id then
			self.State = _State
			self:Animator(_TypeAttack, _TargId, _TargHealth)
		end
	end)
	
	UpdatePositionClient.Event:Connect(function(_Id, _initialCf, _targetCf, _pos, _ori)
		if _Id == self.Id then
			self:mover(_initialCf, _targetCf, _pos, _ori)
		end
	end)
	
	UpdateHealthClient.Event:Connect(function(_Id, _Health, Attackers_ID)
		if _Id == self.Id then
			self.Health = _Health
			self:UpdateHealth()
			UpdateHealthServer:FireServer(Attackers_ID)
		end
	end)
		
	warmup:Fire()
	
end

function CardNPC:Stop()
	self.State = "Dead"
	self.HealthBar:Destroy()
	self:Animator()
	self.MoveSignal:Disconnect()
end

return CardNPC
