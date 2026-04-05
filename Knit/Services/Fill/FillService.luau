local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local FillService = Knit.CreateService({
	Name = "FillService",
	Client = {
		StartTurnSignal = Knit.CreateSignal(),
		EndTurnSignal = Knit.CreateSignal(),
		UpdateWaterLevelSignal = Knit.CreateSignal(),
		LockInSignal = Knit.CreateSignal(),
		CancelTurnSignal = Knit.CreateSignal(),
	},
})

function FillService:KnitInit()
	self._activeTurns = {}
	self._playerContainers = {}
	self._finalResults = {}
	self._stationContainers = {}
	self.StationService = nil
end

function FillService:KnitStart()
	self:_GetServices()
end

function FillService:RegisterStationContainer(stationID, container)
	self._stationContainers[stationID] = container
end

function FillService:StartPlayerTurn(player, stationID)
	if not player or not player.Parent then
		return false
	end

	local container = self._stationContainers[stationID]
	if not container then
		return false
	end

	self:CancelPlayerTurn(player)

	self._playerContainers[player] = container

	local waterLine = container:FindFirstChild("WaterLine")
	local currentHeight = 0.1
	if waterLine then
		currentHeight = waterLine.Size.Y
		waterLine.Transparency = 0
	end

	self._activeTurns[player] = {
		isActive = true,
		isLockedIn = false,
		currentHeight = currentHeight,
		container = container,
		stationID = stationID,
		startTime = os.clock(),
	}

	self.Client.StartTurnSignal:Fire(player, container, currentHeight)

	return true
end

function FillService.Client:UpdateWaterLevel(player, newHeight)
	local service = self.Server
	local turnData = service._activeTurns[player]

	if not turnData then
		return
	end

	if not turnData.isActive then
		return
	end

	if turnData.isLockedIn then
		return
	end

	if os.clock() - turnData.startTime > 30 then
		service:ForceEndTurn(player)
		return
	end

	local container = turnData.container
	local CONTAINER_HEIGHT = container.YHolder.Size.Y
	local oldHeight = turnData.currentHeight
	newHeight = math.max(0.1, math.min(newHeight, CONTAINER_HEIGHT))
	turnData.currentHeight = newHeight
	local fillPercent = newHeight / CONTAINER_HEIGHT

	local waterLine = container:FindFirstChild("WaterLine")
	if waterLine then
		waterLine.Size = Vector3.new(waterLine.Size.X, newHeight, waterLine.Size.Z)
		waterLine.Position = container.PrimaryPart.Position
			- Vector3.new(
				0,
				CONTAINER_HEIGHT / 2 - newHeight / 2 - (CONTAINER_HEIGHT - container.PrimaryPart.Size.Y) / 2,
				0
			)
	end

	if service.VFXService and fillPercent > 0.01 and fillPercent < 0.99 then
		if not service._effectPlaying or not service._effectPlaying[turnData.stationID] then
			if not service._effectPlaying then
				service._effectPlaying = {}
			end

			service._effectPlaying[turnData.stationID] = true

			service.VFXService:PlayFillEffect(turnData.stationID)

			task.delay(0.3, function()
				if service._effectPlaying then
					service._effectPlaying[turnData.stationID] = nil
				end
			end)
		end
	end

	local station = service.StationService and service.StationService:GetStationByID(turnData.stationID)
	if station then
		local players = {}
		for _, occupant in pairs(station.Occupants) do
			if occupant.player then
				table.insert(players, occupant.player)
			end
		end

		for _, targetPlayer in ipairs(players) do
			service.Client.UpdateWaterLevelSignal:Fire(targetPlayer, {
				fillPercent = fillPercent,
				waterHeight = newHeight,
			})
		end
	end
end

function FillService.Client:LockIn(player)
	local service = self.Server
	local turnData = service._activeTurns[player]

	if not turnData then
		return
	end

	if turnData.isLockedIn then
		return
	end

	turnData.isLockedIn = true
	turnData.isActive = false

	local container = turnData.container
	local CONTAINER_HEIGHT = container.YHolder.Size.Y
	local fillPercent = turnData.currentHeight / CONTAINER_HEIGHT
	local overflow = fillPercent >= 0.99

	service._finalResults[player] = {
		fillPercent = fillPercent,
		overflow = overflow,
		fillHeight = turnData.currentHeight,
		stationID = turnData.stationID,
		timestamp = os.time(),
	}

	service.Client.EndTurnSignal:Fire(player, {
		fillPercent = fillPercent,
		overflow = overflow,
	})

	if service.VFXService then
		service.VFXService:StopFillEffect(turnData.stationID)
	end

	service._activeTurns[player] = nil
	service._playerContainers[player] = nil
end

function FillService:CancelPlayerTurn(player)
	local turnData = self._activeTurns[player]

	if turnData then
		self.Client.CancelTurnSignal:Fire(player)
	end

	self._activeTurns[player] = nil
	self._playerContainers[player] = nil
	self._finalResults[player] = nil
end

function FillService:ForceEndTurn(player)
	local turnData = self._activeTurns[player]
	if not turnData then
		return
	end

	self.Client.LockIn:Fire(player)
end

function FillService:ResetContainer(stationID)
	local container = self._stationContainers[stationID]
	if not container then
		return
	end

	if self.VFXService then
		self.VFXService:StopFillEffect(stationID)
	end

	local waterLine = container:FindFirstChild("WaterLine")
	if waterLine then
		local CONTAINER_HEIGHT = container.YHolder.Size.Y
		waterLine.Size = Vector3.new(waterLine.Size.X, 0.1, waterLine.Size.Z)
		waterLine.Position = container.PrimaryPart.Position
			- Vector3.new(0, CONTAINER_HEIGHT / 2 - 0.1 / 2 - (CONTAINER_HEIGHT - container.PrimaryPart.Size.Y) / 2, 0)
		waterLine.BrickColor = BrickColor.new("Bright blue")
		waterLine.Transparency = 1
	end
end

function FillService:GetPlayerResult(player)
	local result = self._finalResults[player]
	return result
end

function FillService:IsPlayerTurnActive(player)
	local turnData = self._activeTurns[player]
	local isActive = turnData and turnData.isActive
	return isActive
end

function FillService:_GetServices()
	local success, service = pcall(function()
		return Knit.GetService("StationService")
	end)
	if success then
		self.StationService = service
	end

	self.PlayerService = Knit.GetService("PlayerService")
	self.VFXService = Knit.GetService("VFXService")
end

return FillService
