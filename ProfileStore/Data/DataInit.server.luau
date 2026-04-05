-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- ProfileStore
local ProfileStore = require(ServerScriptService.ServerPackages.Profilestore)

local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

-- Template
local Template = require(ServerScriptService.Data.DataTemplate)

-- DataManager
local DataManager = require(ServerScriptService.Data.DataManager)

-- Access ProfileStore
local PlayerStore = ProfileStore.New(GetStoreName(), Template.Default)

-- GamepassManager
local GamepassManager = require(ServerScriptService.Data.GamepassManager)

-- Add leaderstats and synchronize player data
local function Initialize(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
	-- 1. Create a folder to hold non-sensitive, frequently accessed data for easy client access
	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "PlayerData"
	dataFolder.Parent = player

	local InventoryFolder = Instance.new("Folder")
	InventoryFolder.Name = "Inventory"
	InventoryFolder.Parent = dataFolder
	local EquippedSkin = Instance.new("StringValue")
	EquippedSkin.Name = "EquippedSkin"
	EquippedSkin.Value = profile.Data.Inventory.EquippedSkin
	EquippedSkin.Parent = InventoryFolder

	-- 2. Create leaderstats for public display (visible to all players)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local Wins = Instance.new("IntValue")
	Wins.Name = "Wins"
	Wins.Value = profile.Data.Stats.Wins
	Wins.Parent = leaderstats

	local Seals = Instance.new("IntValue")
	Seals.Name = "Seals"
	Seals.Value = profile.Data.Currency.Seals
	Seals.Parent = leaderstats

	local settingsFolder = Instance.new("Folder")
	settingsFolder.Name = "Settings"
	settingsFolder.Parent = dataFolder

	local MasterVolume = Instance.new("IntValue")
	MasterVolume.Name = "MasterVolume"
	MasterVolume.Value = profile.Data.Settings.MasterVolume
	MasterVolume.Parent = settingsFolder

	local BlindfoldType = Instance.new("StringValue")
	BlindfoldType.Name = "BlindfoldType"
	BlindfoldType.Value = profile.Data.Settings.BlindfoldType
	BlindfoldType.Parent = settingsFolder

	local FillSensitivity = Instance.new("IntValue")
	FillSensitivity.Name = "FillSensitivity"
	FillSensitivity.Value = profile.Data.Settings.FillSensitivity
	FillSensitivity.Parent = settingsFolder

	-- 6. Print loaded data for debugging
	print(profile.Data)

	GamepassManager:UpdateOwnershipData(player)
end

local function PlayerAdded(player: Player)
	-- Start a new profile session
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Sanity check to ensure profile exists
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing data variables from Template

		-- Handles session-locking
		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player] = nil
			player:Kick("Data error occurred. Please rejoin.")
		end)

		if player.Parent == Players then
			DataManager.Profiles[player] = profile
			Initialize(player, profile)
			--print(profile.Data)
		else
			profile:EndSession()
		end
	else
		-- Server shuts down while player is joining
		player:Kick("Data error occurred. Please rejoin.")
	end
end

-- Early Joiners
for i, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end
	profile:EndSession()
	DataManager.Profiles[player] = nil
end)
