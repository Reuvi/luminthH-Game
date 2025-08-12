local RS = game:GetService("ReplicatedStorage")
local Bindables = RS.Bindables
local Remotes = RS.Remotes

--SetUpConnection
local PlaceCardClient = Remotes.PlaceCard
local PlaceCardServer = Bindables.ClientPlaceCard

local UpdatePositionClient = Remotes.UpdatePosition
local UpdatePositionServer = Bindables.UpdatePosition


local UpdateHealthClient = Remotes.UpdateHealth
local UpdateHealthServer = Bindables.UpdateHealth



local Listener = {}

function Listener:spawnCard()
	
	local _plr, _Id = nil
	
	PlaceCardClient.OnServerEvent:Connect(function(...)
		_plr, _Id = ...
		PlaceCardServer:Fire(_plr, _Id)
	end)
	
	
end

function Listener:updatePosition()

	local _plr, _Id = nil

	UpdatePositionClient.OnServerEvent:Connect(function(...)
		_plr, _Id = ...
		UpdatePositionServer:Fire(_Id)
	end)


end

function Listener:updateHealth()

	local _plr, _Id = nil
	

	UpdateHealthClient.OnServerEvent:Connect(function(...)
		_plr, _Id = ...
		UpdateHealthServer:Fire(_Id)
	end)


end


function Listener:run()
	
	self:spawnCard()
	
	self:updatePosition()
	
	self:updateHealth()
	
end


return Listener
