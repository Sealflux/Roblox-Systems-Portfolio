local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local StationService = Knit.CreateService({
	Name = "StationService",
	Client = {
		StationUpdate = Knit.CreateSignal(),
	},
})

function StationService:KnitInit() end

function StationService:KnitStart()
	self:_GetServices()
	self:_SetupStations()
	self:_SetupPlayerCleanup()
	self:_SetupMatchCancellationHandling()
end

function StationService:_SetupMatchCancellationHandling()
	if not self.MatchService then
		return
	end

	self.MatchService.Client.MatchCancelled:Connect(function(player, reason)
		local stationID = self:_GetPlayerStationID(player)
		if stationID then
			self:_ForceEndStationMatch(stationID, reason)
		end
	end)

	self.MatchService.Client.MatchEnded:Connect(function(player, results)
		local stationID = self:_GetPlayerStationID(player)
		if stationID then
			task.delay(2, function()
				self:_CleanStationAfterMatch(stationID)
			end)
		end
	end)
end

function StationService:_GetPlayerStationID(player)
	for stationID, station in pairs(self.Stations) do
		for _, p in ipairs(station.PlayersUsing) do
			if p == player then
				return stationID
			end
		end
	end
	return nil
end

function StationService:_ForceEndStationMatch(stationID, reason)
	local station = self:GetStationByID(stationID)
	if not station then
		return
	end

	if station.Seat1 and station.Seat1.Occupant then
		local humanoid = station.Seat1.Occupant
		humanoid.Sit = false
	end

	if station.Seat2 and station.Seat2.Occupant then
		local humanoid = station.Seat2.Occupant
		humanoid.Sit = false
	end

	station.IsMatchActive = false

	station.PlayersUsing = {}
	station.Occupants = {
		Chair1 = { character = nil, player = nil },
		Chair2 = { character = nil, player = nil },
	}

	self:_UpdateChairVisual(stationID, 1, false)
	self:_UpdateChairVisual(stationID, 2, false)

	local container = station.Model:FindFirstChild("Container")
	if container then
		local waterLine = container:FindFirstChild("WaterLine")
		if waterLine then
			waterLine.Transparency = 1
		end
	end

	self:UpdateStationIndicator(stationID)

	self.Client.StationUpdate:FireAll(stationID, {
		playerCount = 0,
		playerNames = {},
		canJoin = true,
		matchActive = false,
		message = "Match cancelled: " .. reason,
		reset = true,
	})
end

function StationService:_EndStationMatch(stationID)
	local station = self.Stations[stationID]
	if not station then
		return
	end

	if not station.IsMatchActive then
		return
	end

	station.IsMatchActive = false

	self:UpdateStationIndicator(stationID)

	self.Client.StationUpdate:FireAll(stationID, {
		playerCount = #station.PlayersUsing,
		playerNames = self:_GetPlayerNames(station.PlayersUsing),
		canJoin = false,
		matchActive = false,
		message = "Match complete!",
		showResults = true,
	})
end

function StationService:_CleanStationAfterMatch(stationID)
	local station = self.Stations[stationID]
	if not station then
		return
	end

	if station.Seat1 and station.Seat1.Occupant then
		local humanoid = station.Seat1.Occupant
		humanoid.Sit = false
	end

	if station.Seat2 and station.Seat2.Occupant then
		local humanoid = station.Seat2.Occupant
		humanoid.Sit = false
	end

	station.PlayersUsing = {}
	station.Occupants = {
		Chair1 = { character = nil, player = nil },
		Chair2 = { character = nil, player = nil },
	}

	self:_UpdateChairVisual(stationID, 1, false)
	self:_UpdateChairVisual(stationID, 2, false)

	local container = station.Model:FindFirstChild("Container")
	if container then
		local waterLine = container:FindFirstChild("WaterLine")
		if waterLine then
			waterLine.Transparency = 1
		end
	end

	self:UpdateStationIndicator(stationID)

	self.Client.StationUpdate:FireAll(stationID, {
		playerCount = 0,
		playerNames = {},
		canJoin = true,
		matchActive = false,
		message = "Ready for new players",
		reset = true,
	})
end

function StationService:PlayerLeaveStation(player, stationID)
	local station = self:GetStationByID(stationID)
	if not station then
		return false
	end

	for i, p in ipairs(station.PlayersUsing) do
		if p == player then
			table.remove(station.PlayersUsing, i)

			for chairKey, occupant in pairs(station.Occupants) do
				if occupant.player == player then
					station.Occupants[chairKey] = { character = nil, player = nil }
					local chairNum = chairKey == "Chair1" and 1 or 2
					self:_UpdateChairVisual(stationID, chairNum, false)
				end
			end

			self:UpdateStationIndicator(stationID)

			if station.IsMatchActive and #station.PlayersUsing == 0 then
				self:_ForceEndStationMatch(stationID, "All players left")
				if self.MatchService then
					self.MatchService:CancelMatch(stationID, "All players left")
				end
			end

			self.Client.StationUpdate:FireAll(stationID, {
				playerCount = #station.PlayersUsing,
				playerNames = self:_GetPlayerNames(station.PlayersUsing),
				canJoin = (#station.PlayersUsing < 2),
			})

			return true
		end
	end

	return false
end

function StationService:ResetStation(stationID, reason)
	local station = self:GetStationByID(stationID)
	if not station then
		return false
	end

	if station.IsMatchActive and self.MatchService then
		self.MatchService:CancelMatch(stationID, "Manual reset: " .. (reason or ""))
	end

	station.IsMatchActive = false
	station.PlayersUsing = {}
	station.Occupants = {
		Chair1 = { character = nil, player = nil },
		Chair2 = { character = nil, player = nil },
	}

	self:_UpdateChairVisual(stationID, 1, false)
	self:_UpdateChairVisual(stationID, 2, false)

	self:UpdateStationIndicator(stationID)

	self.Client.StationUpdate:FireAll(stationID, {
		playerCount = 0,
		playerNames = {},
		canJoin = true,
		matchActive = false,
		message = "Station reset: " .. (reason or "Ready"),
		reset = true,
	})

	return true
end

function StationService:_GetServices()
	local success, service = pcall(function()
		return Knit.GetService("UiService")
	end)
	if success then
		self.UiService = service
	else
		self.UiService = nil
	end

	local success2, service2 = pcall(function()
		return Knit.GetService("PlayerService")
	end)
	if success2 then
		self.PlayerService = service2
	else
		self.PlayerService = nil
	end

	local success3, service3 = pcall(function()
		return Knit.GetService("MatchService")
	end)
	if success3 then
		self.MatchService = service3
	else
		self.MatchService = nil
	end

	local success4, service4 = pcall(function()
		return Knit.GetService("FillService")
	end)
	if success4 then
		self.FillService = service4
	else
		self.FillService = nil
	end
end

function StationService:_SetupStations()
	self.Stations = {}

	local stationsFolder = workspace:FindFirstChild("Stations")
	if not stationsFolder then
		return
	end

	for i, stationModel in ipairs(stationsFolder:GetChildren()) do
		self.Stations[i] = {
			Model = stationModel,
			ID = i,
			PlayersUsing = {},
			Occupants = {
				Chair1 = { character = nil, player = nil },
				Chair2 = { character = nil, player = nil },
			},
			IsMatchActive = false,
		}

		stationModel.Name = "Station_" .. tostring(i)
		stationModel:SetAttribute("StationID", i)

		self:_SetupStationChairs(i)
	end
end

function StationService:_SetupStationChairs(stationID)
	local station = self.Stations[stationID]
	if not station then
		return
	end

	local stationModel = station.Model

	local chair1 = stationModel:FindFirstChild("Chair1")
	local chair2 = stationModel:FindFirstChild("Chair2")

	if not chair1 or not chair2 then
		return
	end

	local seat1 = chair1:FindFirstChild("Seat")
	local seat2 = chair2:FindFirstChild("Seat")

	if not seat1 or not seat2 then
		return
	end

	station.Chair1 = chair1
	station.Chair2 = chair2
	station.Seat1 = seat1
	station.Seat2 = seat2

	local container = stationModel:FindFirstChild("Container")
	if container then
		if self.FillService then
			self.FillService:RegisterStationContainer(stationID, container)
		end
	end

	seat1:GetPropertyChangedSignal("Occupant"):Connect(function()
		self:_OnSeatOccupantChanged(stationID, 1, seat1)
	end)

	seat2:GetPropertyChangedSignal("Occupant"):Connect(function()
		self:_OnSeatOccupantChanged(stationID, 2, seat2)
	end)
end

function StationService:_OnSeatOccupantChanged(stationID, chairNum, seat)
	local station = self.Stations[stationID]
	if not station then
		return
	end

	local occupant = seat.Occupant
	local chairKey = chairNum == 1 and "Chair1" or "Chair2"

	if occupant then
		local character = occupant.Parent
		local player = game.Players:GetPlayerFromCharacter(character)

		if player then
			station.Occupants[chairKey].character = character
			station.Occupants[chairKey].player = player

			local alreadyInStation = false
			for _, p in ipairs(station.PlayersUsing) do
				if p == player then
					alreadyInStation = true
					break
				end
			end
			if not alreadyInStation then
				table.insert(station.PlayersUsing, player)
			end

			self:_UpdateChairVisual(stationID, chairNum, true)
			self:UpdateStationIndicator(stationID)

			if #station.PlayersUsing == 2 and not station.IsMatchActive then
				self:_StartStationMatch(stationID)
			end
		end
	else
		local player = station.Occupants[chairKey].player

		if player then
			station.Occupants[chairKey].character = nil
			station.Occupants[chairKey].player = nil

			for i, p in ipairs(station.PlayersUsing) do
				if p == player then
					table.remove(station.PlayersUsing, i)
					break
				end
			end

			self:_UpdateChairVisual(stationID, chairNum, false)
			self:UpdateStationIndicator(stationID)

			if station.IsMatchActive then
				if #station.PlayersUsing == 0 then
					self:_ForceEndStationMatch(stationID, "All players left")
				elseif self.MatchService then
					self.MatchService:CancelMatch(stationID, "Player left")
				end
			end
		end
	end
end

function StationService:_UpdateChairVisual(stationID, chairNum, occupied)
	local station = self.Stations[stationID]
	if not station then
		return
	end

	local chair = chairNum == 1 and station.Chair1 or station.Chair2
	if not chair then
		return
	end

	if occupied then
		for _, part in ipairs(chair:GetChildren()) do
			if part:IsA("BasePart") then
				part.Material = Enum.Material.Neon
				part.Color = Color3.fromRGB(255, 100, 100)
			end
		end
	else
		for _, part in ipairs(chair:GetChildren()) do
			if part:IsA("BasePart") then
				part.Material = Enum.Material.Plastic
				part.Color = Color3.fromRGB(108, 88, 75)
			end
		end
	end
end

function StationService:_StartStationMatch(stationID)
	local station = self.Stations[stationID]
	if not station or station.IsMatchActive then
		return
	end

	station.IsMatchActive = true

	local container = station.Model:FindFirstChild("Container")
	if container then
		local waterLine = container:FindFirstChild("WaterLine")
		if waterLine then
			waterLine.Transparency = 0
		end
	end

	if self.MatchService then
		self.MatchService:StartMatch(stationID)
	end
end

function StationService:UpdateStationIndicator(stationID)
	local station = self:GetStationByID(stationID)
	if not station then
		return
	end

	local stationModel = station.Model

	local stationIndicator = stationModel:FindFirstChild("StationIndicator")
	if not stationIndicator then
		stationIndicator = stationModel:FindFirstChildWhichIsA("BillboardGui")
	end

	if stationIndicator then
		local textLabel = stationIndicator:FindFirstChild("TextLabel")
		if textLabel then
			local playerCount = #station.PlayersUsing
			textLabel.Text = playerCount .. "/2"

			if playerCount == 0 then
				textLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			elseif playerCount == 1 then
				textLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
			else
				textLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			end
		end
	end

	if self.UiService and self.UiService.UpdateStationDisplay then
		self.UiService:UpdateStationDisplay(stationID, #station.PlayersUsing, station.IsMatchActive)
	end
end

function StationService:_GetPlayerNames(players)
	local names = {}
	for _, player in ipairs(players) do
		table.insert(names, player.Name)
	end
	return names
end

function StationService:GetStationByID(stationID)
	return self.Stations[stationID]
end

function StationService:GetStationStatus(stationID)
	local station = self:GetStationByID(stationID)
	if not station then
		return nil
	end

	return {
		stationID = stationID,
		playerCount = #station.PlayersUsing,
		playerNames = self:_GetPlayerNames(station.PlayersUsing),
		isMatchActive = station.IsMatchActive,
		canJoin = (#station.PlayersUsing < 2 and not station.IsMatchActive),
	}
end

function StationService:GetAllStationStatus()
	local statuses = {}
	for stationID, station in pairs(self.Stations) do
		statuses[stationID] = self:GetStationStatus(stationID)
	end
	return statuses
end

function StationService:_SetupPlayerCleanup()
	game.Players.PlayerRemoving:Connect(function(player)
		for stationID, station in pairs(self.Stations) do
			for chairKey, occupant in pairs(station.Occupants) do
				if occupant.player == player then
					self:PlayerLeaveStation(player, stationID)
					break
				end
			end
		end
	end)
end

return StationService
