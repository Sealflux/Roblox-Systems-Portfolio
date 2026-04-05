-- This module defines the default structure for a player's saved data.
-- ProfileService will use this template to create new profiles and fill in missing values for old ones.

local DataTemplate = {}

-- The master template. This is what a brand new player's data looks like.
DataTemplate.Default = {
	-- 1. CORE PROGRESSION & STATS
	JoinTime = os.time(), -- Timestamp of when the player first joined
	Stats = {
		Wins = 0, -- Total number of wins
	},

	-- 3. ECONOMY & REWARDS
	Currency = {
		Seals = 0, -- In-game currency earned through gameplay
	},

	-- 4. COSMETICS & INVENTORY
	Inventory = {
		EquippedSkin = "Default", -- The currently equipped cosmetic
		PurchasedSkins = { "Default" }, -- A list of all owned cosmetics
		-- Could add: EquippedPet, EquippedBadge, etc.
	},

	Gamepasses = {
		["1688599023"] = { owned = false, awarded = false }, -- SealsX2
		["1688501120"] = { owned = false, awarded = false }, -- WinsX2
	},

	Codes = {
		RedeemedCodes = {}, -- List of redeemed code names
	},
	-- 5. ACHIEVEMENTS & MILESTONES
	--[[ Achievements = {
		FirstCorrectAnswer = false,
		Answered100Questions = false,
		MasteredASubject = false, -- Achieved 100% Mastery in any subject
		-- Add more achievement flags...
	}, ]]

	-- 6. SETTINGS & PREFERENCES
	Settings = {
		MasterVolume = 50, -- Default master volume level (0-100)
		BlindfoldType = "Black", -- Default blindfold cosmetic
		FillSensitivity = 1.0, -- Default fill sensitivity setting
	},
}

return DataTemplate
