local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local TeleportService = Knit.CreateService({ Name = "TeleportService", Client = {} })

function TeleportService:KnitInit() end

function TeleportService:KnitStart() end

function TeleportService:TeleportPlayerToPosition(player, position)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
	end
end

function TeleportService:TeleportPlayerToSpawn(player)
	local spawnLocation = CFrame.new(-70.25, 83.804, 40.75)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = spawnLocation + Vector3.new(0, 5, 0)
	end
end

return TeleportService
