local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local NetService = Knit.CreateService({
	Name = "NetService",
	Client = {},
})
local CollectionService = game:GetService("CollectionService")
function NetService:_Construct()
	self.Nets = {}
	for i, Net in ipairs(CollectionService:GetTagged("Net")) do
		Net.Name = "Net" .. i
		table.insert(self.Nets, Net)
		Net.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = game:GetService("Players"):GetPlayerFromCharacter(character)
			if player then
				self:_OnPlayerTouchNet(player, Net)
			end
		end)
	end
end

function NetService:_GetServices()
	self.TeleportService = Knit.GetService("TeleportService")
end

function NetService:KnitInit() end

function NetService:KnitStart()
	self:_GetServices()
	self:_Construct()
end

function NetService:_OnPlayerTouchNet(player)
	local pos = Vector3.new(-70.586, 56.534, 134)
	self.TeleportService:TeleportPlayerToPosition(player, pos)
end

return NetService
