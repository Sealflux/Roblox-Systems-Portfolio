local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local MatchService = Knit.CreateService({
	Name = "MatchService",
	Client = {
		MatchCancelled = Knit.CreateSignal(),
		MatchEnded = Knit.CreateSignal(),
		TurnStarted = Knit.CreateSignal(),
		TurnEnded = Knit.CreateSignal(),
		ShowResults = Knit.CreateSignal(),
		CountdownUpdate = Knit.CreateSignal(),
	},
})

function MatchService:KnitInit()
	self._activeMatches = {}
	self._playerMatchBindings = {}
end

function MatchService:KnitStart()
	self:_GetServices()

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		self:_HandlePlayerLeave(player)
	end)
end

function MatchService:_GetServices()
	self.StationService = Knit.GetService("StationService")
	self.UiService = Knit.GetService("UiService")
	self.PlayerService = Knit.GetService("PlayerService")
	self.FillService = Knit.GetService("FillService")
	self.DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
	self.VFXService = Knit.GetService("VFXService")
end

function MatchService:_AnchorPlayer(player, stationID)
	local station = self.StationService:GetStationByID(stationID)
	if not station then
		return
	end

	for chairKey, occupant in pairs(station.Occupants) do
		if occupant.player == player and occupant.character then
			local character = occupant.character
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				humanoidRootPart.Anchored = true
			end
			break
		end
	end
end

function MatchService:_UnanchorPlayer(player)
	if not player or not player.Parent then
		return
	end

	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.Anchored = false
		end
	end
end

function MatchService:_UnanchorMatchPlayers(match)
	if match.player1 and self:_IsPlayerValid(match.player1) then
		self:_UnanchorPlayer(match.player1)
	end
	if match.player2 and self:_IsPlayerValid(match.player2) then
		self:_UnanchorPlayer(match.player2)
	end
end

function MatchService:StartMatch(stationID)
	if not stationID then
		return
	end

	local station = self.StationService:GetStationByID(stationID)
	if not station then
		return
	end

	if not station.IsMatchActive then
		return
	end

	if self._activeMatches[stationID] then
		return
	end

	local player1 = station.PlayersUsing[1]
	local player2 = station.PlayersUsing[2]

	if not player1 or not player2 then
		self.StationService:_EndStationMatch(stationID)
		return
	end

	local stationModel = station.Model
	local container = stationModel:FindFirstChild("Container")

	if not container then
		self:CancelMatch(stationID, "Missing container")
		return
	end

	self.FillService:RegisterStationContainer(stationID, container)
	self.FillService:ResetContainer(stationID)

	self._activeMatches[stationID] = {
		stationID = stationID,
		player1 = player1,
		player2 = player2,
		container = container,
		currentTurn = nil,
		turnNumber = 0,
		waterLevel = 0,
		overflowHappened = false,
		player1Result = nil,
		player2Result = nil,
	}

	self._playerMatchBindings[player1] = stationID
	self._playerMatchBindings[player2] = stationID

	self:_RunCountdown(stationID, player1, player2)
end

function MatchService:_RunCountdown(stationID, player1, player2)
	local station = self.StationService:GetStationByID(stationID)
	if not station then
		self:CancelMatch(stationID, "Station missing during countdown")
		return
	end

	local stationModel = station.Model
	local stationIndicator = stationModel:FindFirstChild("StationIndicator")
	local textLabel = stationIndicator and stationIndicator:FindFirstChild("TextLabel")

	for i = 3, 1, -1 do
		if not self._activeMatches[stationID] then
			return
		end

		if not self:_IsPlayerValid(player1) or not self:_IsPlayerValid(player2) then
			self:CancelMatch(stationID, "Player left during countdown")
			return
		end

		if textLabel then
			textLabel.Text = "Starting in " .. i .. "..."
			textLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
		end

		self.Client.CountdownUpdate:FireAll({
			stationID = stationID,
			secondsLeft = i,
		})

		task.wait(1)
		if i == 1 then
			self:_AnchorPlayer(player1, stationID)
			self:_AnchorPlayer(player2, stationID)
		end
	end

	if not self._activeMatches[stationID] then
		return
	end

	if not self:_IsPlayerValid(player1) or not self:_IsPlayerValid(player2) then
		self:CancelMatch(stationID, "Player left during countdown")
		return
	end

	if textLabel then
		textLabel.Text = "IN GAME"
		textLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	end

	local firstPlayer = math.random(1, 2) == 1 and player1 or player2
	self:_RunTurn(stationID, firstPlayer)
end

function MatchService:_RunTurn(stationID, player)
	local match = self._activeMatches[stationID]
	if not match then
		return
	end

	if match.overflowHappened then
		return
	end

	local isPlayer1 = (player == match.player1)
	local turnOrder = isPlayer1 and 1 or 2

	match.currentTurn = turnOrder
	match.turnNumber = match.turnNumber + 1

	self.Client.TurnStarted:Fire(player, {
		turnNumber = match.turnNumber,
		currentWaterLevel = match.waterLevel,
	})

	local success = self.FillService:StartPlayerTurn(player, stationID)

	if not success then
		self:CancelMatch(stationID, "Failed to start turn for " .. player.Name)
		return
	end

	local result = self:_WaitForPlayerResult(player, stationID)

	if not self._activeMatches[stationID] then
		return
	end

	if not result then
		self:CancelMatch(stationID, player.Name .. " left during their turn")
		return
	end

	if isPlayer1 then
		match.player1Result = result
	else
		match.player2Result = result
	end

	match.waterLevel = result.fillPercent

	if result.overflow then
		match.overflowHappened = true

		local winner = (player == match.player1) and match.player2 or match.player1
		self:_EndMatch(stationID, winner, player, result.fillPercent)
		return
	end

	self.Client.TurnEnded:Fire(player, {
		waterLevel = match.waterLevel,
		fillPercent = result.fillPercent,
	})

	local nextPlayer = (player == match.player1) and match.player2 or match.player1

	task.wait(1.5)
	self:_RunTurn(stationID, nextPlayer)
end

function MatchService:_WaitForPlayerResult(player, stationID)
	local startTime = os.time()
	local TIMEOUT = 45

	while os.time() - startTime < TIMEOUT do
		if not self:_IsPlayerValid(player) then
			return nil
		end

		if not self._activeMatches[stationID] then
			return nil
		end

		local result = self.FillService:GetPlayerResult(player)
		if result then
			return result
		end

		task.wait(0.1)
	end

	self.FillService:ForceEndTurn(player)

	task.wait(0.5)
	local result = self.FillService:GetPlayerResult(player)
	return result or { fillPercent = 0, overflow = true }
end

function MatchService:_EndMatch(stationID, winner, loser, finalFillPercent)
	local match = self._activeMatches[stationID]
	if not match then
		return
	end

	self.VFXService:PlayConfettiEffect(winner)

	local station = self.StationService:GetStationByID(stationID)
	if station then
		local seat1 = station.Seat1
		local seat2 = station.Seat2

		if seat1 and seat1.Occupant then
			local humanoid = seat1.Occupant
			humanoid.Sit = false
		end

		if seat2 and seat2.Occupant then
			local humanoid = seat2.Occupant
			humanoid.Sit = false
		end
	end

	self:_UnanchorMatchPlayers(match)

	self.DataManager.AddWins(winner, 1)
	self.DataManager.AddSeals(winner, 5)
	self.DataManager.AddSeals(loser, 2)

	local results = {
		winner = winner,
		loser = loser,
		finalFillPercent = finalFillPercent,
		turnsPlayed = match.turnNumber,
		player1FillPercent = match.player1Result and match.player1Result.fillPercent or 0,
		player2FillPercent = match.player2Result and match.player2Result.fillPercent or 0,
	}

	self.Client.ShowResults:Fire(winner, results)
	self.Client.ShowResults:Fire(loser, results)

	self.Client.MatchEnded:Fire(winner, results)
	self.Client.MatchEnded:Fire(loser, results)

	local stationModel = station and station.Model
	if stationModel then
		local stationIndicator = stationModel:FindFirstChild("StationIndicator")
		local textLabel = stationIndicator and stationIndicator:FindFirstChild("TextLabel")
		if textLabel then
			textLabel.Text = "0/2"
			textLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end

	task.wait(3)

	self.FillService:ResetContainer(stationID)
	self.StationService:_EndStationMatch(stationID)
	self:_CleanupMatch(stationID)
end

function MatchService:CancelMatch(stationID, reason)
	local match = self._activeMatches[stationID]
	if not match then
		return
	end

	local station = self.StationService:GetStationByID(stationID)
	if station then
		local seat1 = station.Seat1
		local seat2 = station.Seat2

		if seat1 and seat1.Occupant then
			local humanoid = seat1.Occupant
			humanoid.Sit = false
		end

		if seat2 and seat2.Occupant then
			local humanoid = seat2.Occupant
			humanoid.Sit = false
		end
	end

	self:_UnanchorMatchPlayers(match)

	if match.currentTurn == 1 and match.player1 then
		self.FillService:CancelPlayerTurn(match.player1)
	elseif match.currentTurn == 2 and match.player2 then
		self.FillService:CancelPlayerTurn(match.player2)
	end

	if match.player1 and self:_IsPlayerValid(match.player1) then
		self.Client.MatchCancelled:Fire(match.player1, reason)
	end
	if match.player2 and self:_IsPlayerValid(match.player2) then
		self.Client.MatchCancelled:Fire(match.player2, reason)
	end

	self.FillService:ResetContainer(stationID)

	self._playerMatchBindings[match.player1] = nil
	self._playerMatchBindings[match.player2] = nil

	self.StationService:_EndStationMatch(stationID)
	self:_CleanupMatch(stationID)
end

function MatchService:_HandlePlayerLeave(player)
	local stationID = self._playerMatchBindings[player]
	if stationID then
		self:CancelMatch(stationID, player.Name .. " disconnected")
	end
end

function MatchService:_CleanupMatch(stationID)
	self._activeMatches[stationID] = nil

	self._playerMatchBindings = {}
	for id, match in pairs(self._activeMatches) do
		if match.player1 then
			self._playerMatchBindings[match.player1] = id
		end
		if match.player2 then
			self._playerMatchBindings[match.player2] = id
		end
	end
end

function MatchService:_IsPlayerValid(player)
	local isValid = player and player.Parent ~= nil
	return isValid
end

function MatchService:GetActiveMatch(stationID)
	return self._activeMatches[stationID]
end

function MatchService:IsPlayerInMatch(player)
	return self._playerMatchBindings[player] ~= nil
end

function MatchService:GetCurrentWaterLevel(stationID)
	local match = self._activeMatches[stationID]
	return match and match.waterLevel or 0
end

return MatchService
