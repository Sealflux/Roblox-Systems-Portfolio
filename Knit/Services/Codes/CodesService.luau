local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local CodesService = Knit.CreateService({
	Name = "CodesService",
	Client = {},
})

function CodesService:KnitInit() end

function CodesService:KnitStart()
	-- Start code
	self:_GetServices()
end

function CodesService:_GetServices()
	self.Codes = require(game:GetService("ReplicatedStorage").Rojo.Codes)
	self.DataManager = require(ServerScriptService:WaitForChild("Data"):WaitForChild("DataManager"))
end

function CodesService:RedeemCode(player: Player, code: string)
	local Code = string.upper(code)
	local codeData = self.Codes[Code]
	local CanRedeem = self.DataManager.CanRedeemCode(player, Code)
	local isInGroup = self:CheckIfInGroup(player, 34304222)
	if not codeData then
		return ("Invalid code: " .. Code)
	end
	if not CanRedeem then
		return "You have already redeemed this code: " .. Code
	end
	if not isInGroup then
		return "You must be in the Sealflux group to redeem this code."
	end
	if codeData.Type == "Seals" then
		self.DataManager.AddSeals(player, codeData.Value)
		self.DataManager.MarkCodeAsRedeemed(player, Code)
		return ("Successfully redeemed code: " .. Code .. ". You have received " .. codeData.Value .. " seals!")
	elseif codeData.Type == "Wins" then
		self.DataManager.AddWins(player, codeData.Value)
		self.DataManager.MarkCodeAsRedeemed(player, Code)
		return ("Successfully redeemed code: " .. Code .. ". You have received " .. codeData.Value .. " wins!")
	else
		return ("Unknown reward type for code: " .. Code)
	end
end

function CodesService.Client:RedeemCode(player: Player, code: string)
	-- Validate player and codes
	if not player or not code then
		return
	end
	code = tostring(code)
	return self.Server:RedeemCode(player, code)
end

function CodesService:CheckIfInGroup(player: Player, groupId: number)
	local success, isInGroup = pcall(function()
		return player:IsInGroupAsync(groupId)
	end)
	if success then
		return isInGroup
	else
		warn("Failed to check group membership for player " .. player.Name .. ": " .. tostring(isInGroup))
		return false
	end
end

function CodesService.Client:CheckIfInGroup(player: Player, groupId: number)
	if not player or not groupId then
		return false
	end

	return self.Server:CheckIfInGroup(player, groupId)
end

return CodesService
