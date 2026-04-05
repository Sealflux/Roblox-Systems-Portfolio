local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PlayerService = Knit.CreateService({ Name = "PlayerService", Client = {} })

function PlayerService:KnitInit() end

function PlayerService:KnitStart()
	self.PlayerStates = {}
	self:_PlayerConnections()
end

----

function PlayerService:GetPlayerState(player)
	return self.PlayerStates[player.UserId]
end

function PlayerService:ChangePlayerState(player, key, value)
	local playerState = self:GetPlayerState(player)
	if playerState then
		playerState[key] = value
	else
		warn("Attempted to change state for a player without a valid state.")
	end
end

function PlayerService:AssignPlayerState(player)
	if not self.PlayerStates[player.UserId] then
		self.PlayerStates[player.UserId] = {
			Player = player,
			IsBlindfolded = false,
			isTurnActive = false,
			isLockedIn = false,
			isAddingWater = false,
			currentHeight = 0.1,
			fillConnection = nil,
			container = nil,
			waterLine = nil,
		}
	end
end

function PlayerService:GetPlayerFromUserId(userId)
	return self.PlayerStates[userId].Player
end

function PlayerService:GetAllPlayers()
	local players = {}
	for _, state in pairs(self.PlayerStates) do
		table.insert(players, state.Player)
	end
	return players
end

function PlayerService:GetPlayerByName(name)
	for _, state in pairs(self.PlayerStates) do
		if state.Player.Name == name then
			return state.Player
		end
	end
	return nil
end

function PlayerService:GetPlayerCount()
	return #self.PlayerStates
end

function PlayerService:_PlayerConnections()
	game.Players.PlayerAdded:Connect(function(player)
		PlayerService:AssignPlayerState(player)
	end)
	game.Players.PlayerRemoving:Connect(function(player)
		PlayerService.PlayerStates[player.UserId] = nil
	end)
end

return PlayerService
