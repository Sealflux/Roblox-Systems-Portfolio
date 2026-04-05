local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local BadgeService = game:GetService("BadgeService")
local AwardService = Knit.CreateService({
	Name = "AwardService",
	Client = {
		AwardBadgeSignal = Knit.CreateSignal(),
	},
})

function AwardService:KnitInit()
	-- Initialize any necessary data structures here
end

function AwardService:KnitStart()
	self.WelcomeBadgeID = 255768825521057
	self.SealObbyistID = 3008557179067842
end

function AwardService:AwardWelcomeBadge(player)
	self:AwardBadge(player, self.WelcomeBadgeID)
end

function AwardService:AwardSealObbyistBadge(player)
	self:AwardBadge(player, self.SealObbyistID)
end

function AwardService:AwardBadge(player, badgeId)
	local hasBadge = BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	if not hasBadge then
		local success, err = pcall(function()
			BadgeService:AwardBadge(player.UserId, badgeId)
		end)
		if success then
			print("Awarded badge " .. badgeId .. " to " .. player.Name)
		else
			warn("Failed to award badge " .. badgeId .. " to " .. player.Name .. ": " .. tostring(err))
		end
	else
		print(player.Name .. " already has badge " .. badgeId)
	end
end

game.Players.PlayerAdded:Connect(function(player)
	task.wait(5)
	AwardService:AwardWelcomeBadge(player)
end)

return AwardService
