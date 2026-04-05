local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkinSystem = ReplicatedStorage:WaitForChild("SkinSystem")
local items = SkinSystem:WaitForChild("Skins")
local crates = SkinSystem:WaitForChild("Crates")

local rnd = Random.new()
local playersUnboxing = {}

local UnboxingService = Knit.CreateService({
	Name = "UnboxingService",
	Client = {
		CrateOpened = Knit.CreateSignal(),
		BuyCrate = Knit.CreateSignal(),
	},
})

function UnboxingService:KnitInit()
	self.Client.BuyCrate:Connect(function(player, crateName)
		local success, result = self:BuyCrate(player, crateName)
		return success, result
	end)
end

function UnboxingService:KnitStart() end

function UnboxingService:BuyCrate(player, crateName)
	if playersUnboxing[player] then
		return false, "Already unboxing"
	end

	local crate = crates:FindFirstChild(crateName)
	if not crate then
		return false, "Crate not found"
	end

	local crateProperties = require(crate)
	local price = crateProperties["Price"] or 0

	local currentSeals = DataManager.GetSeals(player)
	if currentSeals < price then
		return false, "Not enough seals"
	end

	DataManager.RemoveSeals(player, price)

	local chances = crateProperties["Chances"] or {}
	local roll = rnd:NextNumber() * 100

	local total = 0
	local chosenRarity = nil

	for rarity, chance in pairs(chances) do
		total += chance
		if roll <= total then
			chosenRarity = rarity
			break
		end
	end

	if not chosenRarity then
		return false, "No rarity selected"
	end

	local availableItems = crateProperties["Items"] or {}

	for i = #availableItems, 2, -1 do
		local j = rnd:NextInteger(1, i)
		availableItems[i], availableItems[j] = availableItems[j], availableItems[i]
	end

	local chosenItem = nil
	for _, itemName in pairs(availableItems) do
		local item = items:FindFirstChild(itemName, true)
		if item and item.Parent.Name == chosenRarity then
			chosenItem = item
			break
		end
	end

	if not chosenItem then
		return false, "No item found"
	end

	playersUnboxing[player] = chosenItem.Name

	local unboxTime = rnd:NextNumber(3, 7)
	self.Client.CrateOpened:Fire(player, crateName, chosenItem, unboxTime)

	local startTime = tick()
	while tick() - startTime < unboxTime do
		if not player.Character then
			break
		end
		game:GetService("RunService").Heartbeat:Wait()
	end

	local isDuplicate = self:CheckDuplicateSkin(player, chosenItem.Name)
	if isDuplicate then
		local refundAmount = math.floor(price / 2)
		DataManager.AddSeals(player, refundAmount)
		playersUnboxing[player] = nil
		return false, "Duplicate skin. Refunded " .. refundAmount .. " seals."
	else
		DataManager.AddSkin(player, chosenItem.Name)
		DataManager.EquipSkin(player, chosenItem.Name)
		playersUnboxing[player] = nil
		return true, chosenItem.Name
	end
end

function UnboxingService:CheckDuplicateSkin(player, skinName)
	local hasSkin = DataManager.HasSkin(player, skinName)
	return hasSkin
end

return UnboxingService
