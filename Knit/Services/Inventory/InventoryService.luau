local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local InventoryService = Knit.CreateService({
	Name = "InventoryService",
	Client = {
		AddSkin = Knit.CreateSignal(),
		EquipSkin = Knit.CreateSignal(),
		OpenInventory = Knit.CreateSignal(),
	},
})

function InventoryService:KnitInit()
	self.Client.AddSkin:Connect(function(player, skinName)
		self.DataManager.AddSkin(player, skinName)
	end)
	self.Client.EquipSkin:Connect(function(player, skinName)
		self.DataManager.EquipSkin(player, skinName)
		self.Client.EquipSkin:Fire(player, skinName)
	end)
	self.Client.OpenInventory:Connect(function(player)
		local skins = self.DataManager.GetSkins(player)
		self.Client.OpenInventory:Fire(player, skins)
	end)
end

function InventoryService:KnitStart()
	self:_GetServices()
end

function InventoryService:_GetServices()
	self.DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
end

function InventoryService:GetSkins(player)
	return self.DataManager.GetSkins(player)
end

return InventoryService
