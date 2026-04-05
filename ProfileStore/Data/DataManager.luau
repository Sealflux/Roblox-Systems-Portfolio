local DataManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Store profiles from ProfileStore
DataManager.Profiles = {}

DataManager.GetProfile = function(player)
	return DataManager.Profiles[player]
end
DataManager.SetProfile = function(player, profile)
	DataManager.Profiles[player] = profile
end
DataManager.RemoveProfile = function(player)
	DataManager.Profiles[player] = nil
end
DataManager.GetTimestamp = function()
	return os.time()
end
DataManager.GetJoinDate = function(player)
	local profile = DataManager.GetProfile(player)
	if profile then
		return profile.Data.JoinTime
	end
	return nil
end

DataManager.AddWins = function(player: Player, amount: number)
	local profile = DataManager.GetProfile(player)
	if profile then
		profile.Data.Stats.Wins = (profile.Data.Stats.Wins or 0) + amount
		local leaderstats = player:WaitForChild("leaderstats")
		local Wins = leaderstats:WaitForChild("Wins")
		Wins.Value = Wins.Value + amount
	end
end

DataManager.AddSeals = function(player: Player, amount: number)
	local profile = DataManager.GetProfile(player)
	if profile then
		profile.Data.Currency.Seals = (profile.Data.Currency.Seals or 0) + amount
		local leaderstats = player:WaitForChild("leaderstats")
		local Seals = leaderstats:WaitForChild("Seals")
		Seals.Value = Seals.Value + amount
	end
end

DataManager.GetWins = function(player: Player)
	local profile = DataManager.GetProfile(player)
	if profile then
		return profile.Data.Stats.Wins
	end
	return 0
end

DataManager.GetSeals = function(player: Player)
	local profile = DataManager.GetProfile(player)
	if profile then
		return profile.Data.Currency.Seals
	end
	return 0
end

DataManager.RemoveSeals = function(player: Player, amount: number)
	local profile = DataManager.GetProfile(player)
	if profile then
		profile.Data.Currency.Seals = math.max(0, profile.Data.Currency.Seals - amount)
		local leaderstats = player:WaitForChild("leaderstats")
		local Seals = leaderstats:WaitForChild("Seals")
		Seals.Value = math.max(0, Seals.Value - amount)
	end
end

DataManager.GetMasterVolume = function(player: Player)
	local profile = DataManager.GetProfile(player)
	if profile then
		return profile.Data.Settings.MasterVolume
	end
	return 50 -- Default volume
end

DataManager.SetMasterVolume = function(player: Player, volume: number)
	local profile = DataManager.GetProfile(player)
	if profile then
		profile.Data.Settings.MasterVolume = volume
		local PlayerData = player:WaitForChild("PlayerData")
		local Settings = PlayerData:WaitForChild("Settings")
		local MasterVolume = Settings:WaitForChild("MasterVolume")
		MasterVolume.Value = volume
	end
end

DataManager.GetBlindfoldType = function(player: Player)
	local profile = DataManager.GetProfile(player)
	if profile then
		return profile.Data.Settings.BlindfoldType
	end
	return "Black" -- Default blindfold
end

DataManager.SetBlindfoldType = function(player: Player, blindfoldType: string)
	local profile = DataManager.GetProfile(player)
	if profile then
		profile.Data.Settings.BlindfoldType = blindfoldType
		local PlayerData = player:WaitForChild("PlayerData")
		local Settings = PlayerData:WaitForChild("Settings")
		local BlindfoldType = Settings:WaitForChild("BlindfoldType")
		BlindfoldType.Value = blindfoldType
	end
end

DataManager.GetFillSensitivity = function(player: Player)
	local profile = DataManager.GetProfile(player)
	if profile then
		return profile.Data.Settings.FillSensitivity
	end
	return 1.0 -- Default sensitivity
end

DataManager.SetFillSensitivity = function(player: Player, sensitivity: number)
	local profile = DataManager.GetProfile(player)
	if profile then
		profile.Data.Settings.FillSensitivity = sensitivity
		local PlayerData = player:WaitForChild("PlayerData")
		local Settings = PlayerData:WaitForChild("Settings")
		local FillSensitivity = Settings:WaitForChild("FillSensitivity")
		FillSensitivity.Value = sensitivity
	end
end

DataManager.AddSkin = function(player: Player, skinName: string)
	local profile = DataManager.GetProfile(player)
	if profile then
		for _, ownedSkin in ipairs(profile.Data.Inventory.PurchasedSkins) do
			if ownedSkin == skinName then
				return false
			end
		end
		table.insert(profile.Data.Inventory.PurchasedSkins, skinName)
		ReplicatedStorage.Events.UpdatePurchasedSkins:FireClient(player, profile.Data.Inventory.PurchasedSkins)
		return true
	else
		return false
	end
end

DataManager.HasSkin = function(player: Player, skinName: string)
	local profile = DataManager.GetProfile(player)
	if profile then
		for _, ownedSkin in ipairs(profile.Data.Inventory.PurchasedSkins) do
			if ownedSkin == skinName then
				return true
			end
		end
	end
	return false
end

DataManager.EquipSkin = function(player: Player, skinName: string)
	local profile = DataManager.GetProfile(player)
	if profile then
		if DataManager.HasSkin(player, skinName) then
			profile.Data.Inventory.EquippedSkin = skinName
			ReplicatedStorage.Events.UpdateEquippedSkin:FireClient(player, profile.Data.Inventory.EquippedSkin)
			return true
		end
	end
	return false
end

DataManager.GetEquippedSkin = function(player: Player)
	local profile = DataManager.GetProfile(player)
	if profile then
		return profile.Data.Inventory.EquippedSkin
	end
	return "Default"
end

DataManager.GetSkins = function(player: Player)
	local profile = DataManager.GetProfile(player)
	if profile then
		return profile.Data.Inventory.PurchasedSkins
	end
	return {}
end

DataManager.CanRedeemCode = function(player: Player, codeName: string)
	local profile = DataManager.GetProfile(player)
	if profile then
		codeName = string.upper(codeName)
		for _, redeemedCode in ipairs(profile.Data.Codes.RedeemedCodes) do
			if redeemedCode == codeName then
				return false
			end
		end
		return true
	else
		return false
	end
end

DataManager.MarkCodeAsRedeemed = function(player: Player, codeName: string)
	local profile = DataManager.GetProfile(player)
	if profile then
		codeName = string.upper(codeName)
		table.insert(profile.Data.Codes.RedeemedCodes, codeName)
		return true
	else
		return false
	end
end

return DataManager
