local ServerScriptService = game:GetService("ServerScriptService")
local GamepassManager = {}
local MarketplaceService = game:GetService("MarketplaceService")
local DataManager = require(ServerScriptService.Data.DataManager)
local GamepassList = require(ServerScriptService.Data.GamepassList)
function GamepassManager:PromptPurchase(player: Player, name: string)
	local profile = DataManager.GetProfile(player)
	if not profile then
		return
	end
	local passID = GamepassList.GetGamepassIDByName(name)
	if not passID then
		return
	end
	-- Check if player owns the gamepass
	local hasPass = profile.Data.Gamepasses[passID].owned
	print(player.Name .. "requests gamepass" .. name, "| Owned:", hasPass)

	if hasPass == false then
		local success, err = pcall(function()
			hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, tonumber(passID))
		end)
		if not success then
			warn("Error checking gamepass ownership:", err)
			return
		end

		if hasPass == false then
			-- Prompt purchase
			MarketplaceService:PromptGamePassPurchase(player, tonumber(passID))
		elseif hasPass == true then
			-- Update profile to reflect ownership
			self:UpdateOwnershipData(player)
		end
	end
end

--Award owned gamepasses
function GamepassManager:OnPromptPurchaseFinished(player: Player, passID: number, wasPurchased: boolean)
	if wasPurchased == false then
		return
	end
	local gamepassID = tostring(passID)

	local profile = DataManager.GetProfile(player)
	if not profile then
		return
	end

	profile.Data.Gamepasses[gamepassID].owned = true

	local awardFunction = GamepassList.Functions[gamepassID]
	if awardFunction then
		awardFunction(player)
		profile.Data.Gamepasses[gamepassID].awarded = true
	else
		warn("No award function found for gamepass ID:", gamepassID)
	end
end

function GamepassManager:UpdateOwnershipData(player: Player)
	local profile = DataManager.GetProfile(player)
	if not profile then
		return
	end

	for passID: string, awardFunction in GamepassList.Functions do
		local hasPass = profile.Data.Gamepasses[passID].owned
		if hasPass == false then
			local bool = nil
			local success, err = pcall(function()
				bool = MarketplaceService:UserOwnsGamePassAsync(player.UserId, tonumber(passID))
			end)
			if not success then
				warn("Error checking gamepass ownership:", err)
				continue
			end

			if bool == true then
				profile.Data.Gamepasses[passID].owned = true
				awardFunction(player)
				profile.Data.Gamepasses[passID].awarded = true
			end
		end
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(...)
	GamepassManager:OnPromptPurchaseFinished(...)
end)
return GamepassManager
