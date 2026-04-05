local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ProductService = Knit.CreateService({
	Name = "ProductService",
	Client = {},
})

function ProductService:KnitInit() end

function ProductService:KnitStart()
	self:_GetServices()

	self.DevFunctions = {
		[3539517021] = function(receiptInfo, player)
			self.DataManager.AddSeals(player, 10)
			return true
		end,
		[3539517026] = function(receiptInfo, player)
			self.DataManager.AddSeals(player, 100)
			return true
		end,
		[3539517022] = function(receiptInfo, player)
			self.DataManager.AddSeals(player, 1000)
			return true
		end,
	}
	local Compute = require(game:WaitForChild("Compute"))
	Compute.ProcessReceipt = function(receiptInfo)
		return self:_ProcessReceipt(receiptInfo)
	end
end

function ProductService:_GetServices()
	self.MarketplaceService = game:GetService("MarketplaceService")
	self.DataManager = require(ServerScriptService:WaitForChild("Data"):WaitForChild("DataManager"))
end

function ProductService:_GetProductIds()
	local ids = {}
	for id, _ in pairs(self.DevFunctions) do
		table.insert(ids, tostring(id))
	end
	return ids
end

function ProductService:_ProcessReceipt(receiptInfo)
	if not receiptInfo then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local purchaseId = receiptInfo.PurchaseId

	if not userId or not productId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = self:_GetReceiptHandler(productId)
	if not handler then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success, result = pcall(handler, receiptInfo, player)

	if success then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function ProductService:_GetReceiptHandler(productId)
	return self.DevFunctions[productId]
end

return ProductService
