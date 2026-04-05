-- LocalScript as Knit Controller
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Controller
local UnboxingController = Knit.CreateController({
	Name = "UnboxingController",
})

function UnboxingController:KnitInit()
	-- Initialization code
end

-- Knit Controller methods
function UnboxingController:KnitStart()
	self:GetServices()
	self:GetAssets()
	self:setupCrateShop()
	self:setupButtons()

	-- Connect to service events
	self.UnboxingService.CrateOpened:Connect(function(crateName, itemChosen, unboxTime)
		self:handleCrateOpening(crateName, itemChosen, unboxTime)
	end)
end

-- Variables

function UnboxingController:GetAssets()
	self.SkinSystem = ReplicatedStorage:WaitForChild("SkinSystem")
	self.RarityProperties = self.SkinSystem:WaitForChild("RarityProperties")
	self.Items = self.SkinSystem:WaitForChild("Skins")
	self.Crates = self.SkinSystem:WaitForChild("Crates")
	self.rnd = Random.new()
	self.Player = game.Players.LocalPlayer
	self.PlayerGui = self.Player:WaitForChild("PlayerGui")
	self.CrateShopGui = self.PlayerGui:WaitForChild("Left")
	self.shopFrame = self.CrateShopGui:WaitForChild("CrateShopFrame")
	self.shopFrame.Visible = false
	self.closeShopBtn = self.shopFrame:WaitForChild("CloseButton")
	self.cratesList = self.shopFrame:WaitForChild("CratesList")

	self.selectedCrate = self.shopFrame:WaitForChild("SelectedCrate")
	self.selectedCrate.Visible = false

	self.openedGui = self.PlayerGui:WaitForChild("OpenedCrateGui")
	self.openedGui.Enabled = false

	self.openedFrame = self.openedGui:WaitForChild("CrateFrame")
	self.openedFrame.Visible = false

	self.closeOpenedBtn = self.openedFrame:WaitForChild("ContinueButton")
	self.openedItemsFrame = self.openedFrame:WaitForChild("ItemsFrame")

	self.Assets = ReplicatedStorage:WaitForChild("Assets")
	self.UiFolder = self.Assets:WaitForChild("Ui")
	self.crateButtonTemplate = self.UiFolder:WaitForChild("CrateShopButton"):Clone()
	self.selectedCrateItemTemplate = self.UiFolder:WaitForChild("SelectedCrateItemFrame"):Clone()
	self.openingCrateItemTemplate = self.UiFolder:WaitForChild("OpeningCrateItemFrame"):Clone()

	self.TickSound = self.Assets:WaitForChild("Sounds"):WaitForChild("TickSound"):Clone()
	self.TickSound.Parent = self.PlayerGui
	self.OpenButton = self.CrateShopGui:WaitForChild("Frame"):WaitForChild("Shop")

	self.PlusButton = self.shopFrame:WaitForChild("PlusButton")
end

function UnboxingController:GetServices()
	self.UnboxingService = Knit.GetService("UnboxingService")
	self.TweenService = game:GetService("TweenService")
	self.MarketplaceService = game:GetService("MarketplaceService")
end

-- Helper functions
function UnboxingController:lerp(a, b, t)
	return a + (b - a) * t
end

function UnboxingController:tweenGraph(x, pow)
	x = math.clamp(x, 0, 1)
	return 1 - (1 - x) ^ pow
end

-- Setup crate shop
function UnboxingController:setupCrateShop()
	self.crateButtons = {}
	for _, crate in pairs(self.Crates:GetChildren()) do
		local crateProperties = require(crate)

		local newBtn = self.crateButtonTemplate:Clone()
		newBtn.Name = crate.Name
		newBtn.CrateName.Text = crate.Name
		newBtn.CrateImage.Image = crateProperties["Image"]

		newBtn.MouseButton1Click:Connect(function()
			self.shopFrame.PlusButton.Title.Text = "Seals: " .. self.Seals.Value
			if self.selectedCrate.CrateName.Text ~= crate.Name then
				self.selectedCrate.CrateName.Text = crate.Name
				self.selectedCrate.CrateImage.Image = crateProperties["Image"]
				self.selectedCrate.UnboxButton.Text = "$" .. crateProperties["Price"]

				local rarities = {}
				for rarityName, chance in pairs(crateProperties["Chances"]) do
					table.insert(rarities, { rarityName, chance })
				end

				table.sort(rarities, function(a, b)
					return self.RarityProperties[a[1]].Order.Value < self.RarityProperties[b[1]].Order.Value
				end)

				local raritiesText = ""
				for _, rarity in pairs(rarities) do
					local color = self.RarityProperties[rarity[1]].Color.Value
					color = {
						R = math.round(color.R * 255),
						G = math.round(color.G * 255),
						B = math.round(color.B * 255),
					}
					raritiesText = raritiesText
						.. '<font color="rgb('
						.. color.R
						.. ","
						.. color.G
						.. ","
						.. color.B
						.. ')">'
						.. rarity[1]
						.. ": <b>"
						.. rarity[2]
						.. "%</b></font><br />"
				end

				self.selectedCrate.RaritiesText.RichText = true
				self.selectedCrate.RaritiesText.Text = raritiesText

				for _, child in pairs(self.selectedCrate.ItemsList:GetChildren()) do
					if child:IsA("Frame") then
						child:Destroy()
					end
				end

				local unboxableItems = crateProperties["Items"]
				table.sort(unboxableItems, function(a, b)
					local aRarity = self.Items:FindFirstChild(a, true).Parent.Name
					local bRarity = self.Items:FindFirstChild(b, true).Parent.Name

					if self.RarityProperties[aRarity].Order.Value < self.RarityProperties[bRarity].Order.Value then
						return true
					elseif self.RarityProperties[aRarity].Order.Value == self.RarityProperties[bRarity].Order.Value then
						return a < b
					end
					return false
				end)

				for _, unboxableItemName in pairs(unboxableItems) do
					local newItemFrame = self.selectedCrateItemTemplate:Clone()
					newItemFrame.ItemName.Text = unboxableItemName
					newItemFrame.ItemName.TextColor3 = self.RarityProperties[self.Items:FindFirstChild(
						unboxableItemName,
						true
					).Parent.Name].Color.Value

					local itemModel = Instance.new("Model")

					for _, child in pairs(self.Items:FindFirstChild(unboxableItemName, true):GetChildren()) do
						if
							not (
								child:IsA("Script")
								or child:IsA("LocalScript")
								or child:IsA("ModuleScript")
								or child:IsA("Sound")
							)
						then
							child:Clone().Parent = itemModel
						end
					end

					itemModel:PivotTo(CFrame.new() * CFrame.Angles(math.rad(0), 0, 0))
					itemModel.Parent = newItemFrame.ItemImage

					local currentCamera = Instance.new("Camera")
					currentCamera.CFrame = CFrame.new(
						Vector3.new(-itemModel:GetExtentsSize().Y * 0.7, 0, 0),
						itemModel:GetPivot().Position + Vector3.new(0, -0.1, 0)
					)
					currentCamera.Parent = newItemFrame.ItemImage
					newItemFrame.ItemImage.CurrentCamera = currentCamera

					newItemFrame.Parent = self.selectedCrate.ItemsList
				end

				self.selectedCrate.Visible = true
			end
		end)

		table.insert(self.crateButtons, { newBtn, crateProperties["Price"] })
	end

	table.sort(self.crateButtons, function(a, b)
		return (a[2] < b[2]) or (a[2] == b[2] and a[1].Name < b[1].Name)
	end)

	for _, crateButton in pairs(self.crateButtons) do
		crateButton[1].Parent = self.cratesList
	end
end

-- Setup button events
function UnboxingController:setupButtons()
	self.closeOpenedBtn.MouseButton1Click:Connect(function()
		self.openedFrame.Visible = false
		self.openedGui.Enabled = false

		for _, child in pairs(self.openedItemsFrame.ItemsContainer:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end)

	self.selectedCrate.UnboxButton.MouseButton1Click:Connect(function()
		self.shopFrame.PlusButton.Title.Text = "Seals: " .. self.Seals.Value
		if self.selectedCrate.Visible == true then
			self.priceText = self.selectedCrate.UnboxButton.Text
			local price = tonumber(string.sub(self.priceText, 2, -1))
			local leaderstats = self.Player:FindFirstChild("leaderstats")
			if leaderstats then
				local seals = leaderstats:FindFirstChild("Seals")
				if seals and seals.Value >= price then
					self.UnboxingService.BuyCrate:Fire(self.selectedCrate.CrateName.Text)
				else
					warn("Not enough seals!")
				end
			end
		end
	end)
	self.Seals = self.Player.leaderstats:WaitForChild("Seals")
	self.Seals.Changed:Connect(function()
		self.shopFrame.PlusButton.Title.Text = "Seals: " .. self.Seals.Value
	end)

	-- Plus Button/Dev Product Shop
	self.PlusButtonShop = self.shopFrame:WaitForChild("RobuxShop")
	self.Seal1Button = self.PlusButtonShop:WaitForChild("Seal1")
	self.Seal2Button = self.PlusButtonShop:WaitForChild("Seal2")
	self.Seal3Button = self.PlusButtonShop:WaitForChild("Seal3")
	self.PlusButton.Activated:Connect(function()
		self.PlusButtonShop.Visible = not self.PlusButtonShop.Visible
	end)
	self.Seal1Button.Activated:Connect(function()
		self.MarketplaceService:PromptProductPurchase(self.Player, 3539517021)
	end)
	self.Seal2Button.Activated:Connect(function()
		self.MarketplaceService:PromptProductPurchase(self.Player, 3539517026)
	end)
	self.Seal3Button.Activated:Connect(function()
		self.MarketplaceService:PromptProductPurchase(self.Player, 3539517022)
	end)
end

-- Handle crate opening
function UnboxingController:handleCrateOpening(crateName, itemChosen, unboxTime)
	local crateProperties = require(self.Crates[crateName])

	local numItems = self.rnd:NextInteger(20, 100)
	local chosenPosition = self.rnd:NextInteger(15, numItems - 5)

	for i = 1, numItems do
		local rarityChosen = itemChosen.Parent.Name
		local randomItemChosen = itemChosen

		if i ~= chosenPosition then
			local rndChance = self.rnd:NextNumber() * 100
			local n = 0

			for rarity, chance in pairs(crateProperties["Chances"]) do
				n += chance
				if rndChance <= n then
					rarityChosen = rarity
					break
				end
			end

			local unboxableItems = crateProperties["Items"]
			for i = #unboxableItems, 2, -1 do
				local j = self.rnd:NextInteger(1, i)
				unboxableItems[i], unboxableItems[j] = unboxableItems[j], unboxableItems[i]
			end

			for _, itemName in pairs(unboxableItems) do
				if self.Items:FindFirstChild(itemName, true).Parent.Name == rarityChosen then
					randomItemChosen = self.Items:FindFirstChild(itemName, true)
					break
				end
			end
		end

		local newItemFrame = self.openingCrateItemTemplate:Clone()
		newItemFrame.ItemName.Text = randomItemChosen.Name
		newItemFrame.ItemName.TextColor3 = self.RarityProperties[rarityChosen].Color.Value

		local itemModel = Instance.new("Model")

		for _, child in pairs(randomItemChosen:GetChildren()) do
			if
				not (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("Sound"))
			then
				child:Clone().Parent = itemModel
			end
		end

		itemModel:PivotTo(CFrame.new() * CFrame.Angles(math.rad(0), 0, 0))
		itemModel.Parent = newItemFrame.ItemImage

		local currentCamera = Instance.new("Camera")
		currentCamera.CFrame = CFrame.new(
			Vector3.new(-itemModel:GetExtentsSize().Y * 0.7, 0, 0),
			itemModel:GetPivot().Position + Vector3.new(0, -0.1, 0)
		)
		currentCamera.Parent = newItemFrame.ItemImage
		newItemFrame.ItemImage.CurrentCamera = currentCamera

		newItemFrame.Parent = self.openedItemsFrame.ItemsContainer
	end

	self.openedItemsFrame.ItemsContainer.Position = UDim2.new(0, 0, 0.5, 0)

	local cellSize = self.openingCrateItemTemplate.Size.X.Scale
	local padding = self.openedItemsFrame.ItemsContainer.UIListLayout.Padding.Scale
	local pos1 = 0.5 - cellSize / 2
	local nextOffset = -cellSize - padding

	local posFinal = pos1 + (chosenPosition - 1) * nextOffset
	local rndOffset = self.rnd:NextNumber(-cellSize / 2, cellSize / 2)
	posFinal += rndOffset

	local timeOpened = tick()

	self.openedFrame.CrateName.Text = crateName
	self.shopFrame.Visible = false
	self.closeOpenedBtn.Visible = false
	self.openedFrame.Visible = true
	self.openedGui.Enabled = true

	local pow = self.rnd:NextNumber(2, 10)
	local lastSlot = 0

	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		local timeSinceOpened = tick() - timeOpened
		local x = timeSinceOpened / unboxTime

		if x >= 1 then
			connection:Disconnect()
			self.closeOpenedBtn.Visible = true
			return
		end

		local t = self:tweenGraph(x, pow)
		local newXPos = self:lerp(0, posFinal, t)

		local currentSlot = math.abs(math.floor((newXPos + rndOffset) / cellSize)) + 1
		if currentSlot ~= lastSlot then
			self.TickSound:Play()
			lastSlot = currentSlot
		end

		self.openedItemsFrame.ItemsContainer.Position = UDim2.new(newXPos, 0, 0.5, 0)
	end)
end

return UnboxingController
