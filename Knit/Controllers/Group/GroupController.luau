local Knit = require(game:getService("ReplicatedStorage").Packages.Knit)

local GroupController = Knit.CreateController({
	Name = "GroupController",
})

function GroupController:KnitInit() end

function GroupController:KnitStart()
	self:_GetServices()
	task.delay(2, function()
		if not self:CheckIfInGroup(game.Players.LocalPlayer, 34304222) then
			print("Player is not in the group. Prompting to join...")
			self:PromptJoinGroup(game.Players.LocalPlayer, 34304222)
		end
	end)
end

function GroupController:_GetServices()
	self.GroupService = game:GetService("GroupService")
end

function GroupController:PromptJoinGroup(player: Player, groupId: number)
	local success, result = pcall(function()
		return self.GroupService:PromptJoinAsync(groupId)
	end)
	if not success then
		warn("Failed to prompt player " .. player.Name .. " to join group: " .. tostring(result))
		return false
	end
	return result
end

function GroupController:CheckIfInGroup(player: Player, groupId: number)
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

return GroupController
