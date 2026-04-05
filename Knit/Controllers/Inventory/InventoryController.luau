local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local InventoryController = Knit.CreateController({
	Name = "InventoryController",
})

function InventoryController:KnitInit() end

function InventoryController:KnitStart()
	self:_GetServices()
	self:_GetAssets()
	self.OpenButton.MouseButton1Click:Connect(function()
		if
			self.PlayerGui:WaitForChild("Left"):WaitForChild("CrateShopFrame").Visible == false
			and self.PlayerGui:WaitForChild("OpenedCrateGui"):WaitForChild("CrateFrame").Visible == false
			and self.PlayerGui:WaitForChild("Left"):WaitForChild("CodesFrame").Visible == false
		then
			self.InventoryService.OpenInventory:Fire(self.Player)
		end
	end)

	self.CloseButton.MouseButton1Click:Connect(function()
		self.InventoryFrame.Visible = false
	end)
	self.InventoryService.EquipSkin:Connect(function(skinName)
		self.Inventory:WaitForChild("EquippedSkin").Value = skinName
		self.EquippedSkin = skinName
	end)
	self.InventoryService.OpenInventory:Connect(function(skins)
		self:_SetupSkins(skins)
	end)
end

function InventoryController:_GetServices()
	self.ReplicatedStorage = game:GetService("ReplicatedStorage")
	self.InventoryService = Knit.GetService("InventoryService")
	self.TweenService = game:GetService("TweenService")
end

function InventoryController:_GetAssets()
	self.Player = game:GetService("Players").LocalPlayer
	self.PlayerData = self.Player:WaitForChild("PlayerData")
	self.PlayerGui = self.Player:WaitForChild("PlayerGui")
	self.Inventory = self.PlayerData:WaitForChild("Inventory")
	self.InventoryGui = self.PlayerGui:WaitForChild("Left")
	self.InventoryFrame = self.InventoryGui:WaitForChild("InventoryFrame")
	self.CloseButton = self.InventoryFrame:WaitForChild("CloseButton")
	self.SelectedSkin = self.InventoryFrame:WaitForChild("SelectedSkin")
	self.SkinList = self.InventoryFrame:WaitForChild("SkinList")
	self.SelectedSkin.Visible = false
	self.Assets = self.ReplicatedStorage:WaitForChild("Assets")
	self.UiFolder = self.Assets:WaitForChild("Ui")
	self.SkinTemplate = self.UiFolder:WaitForChild("SkinButton"):Clone()
	self.UiGridLayout = self.UiFolder:WaitForChild("UIGridLayout"):Clone()
	self.Skins = self.Assets:WaitForChild("Skins")
	self.SkinSystem = self.ReplicatedStorage:WaitForChild("SkinSystem")
	self.RarityProperties = self.SkinSystem:WaitForChild("RarityProperties")
	self.EquippedSkin = self.Inventory:WaitForChild("EquippedSkin").Value or "Default"

	-- Buttons
	self.OpenButton = self.InventoryGui:WaitForChild("Frame"):WaitForChild("Inventory")
end

function InventoryController:_SetupSkins(skins)
	self.PlayerSkins = skins
	self.EquipButton = self.SelectedSkin:WaitForChild("EquipButton")
	self.EquipButton.MouseButton1Click:Connect(function()
		local selectedSkinName = self.SelectedSkin.SkinName.Text
		self.InventoryService.EquipSkin:Fire(selectedSkinName)
		self.EquipButton.Visible = false
	end)
	self.SkinList:ClearAllChildren()
	local gridlayout = self.UiGridLayout:Clone()
	gridlayout.Parent = self.SkinList
	for _, Skin: string in pairs(self.PlayerSkins) do
		local SkinFrame = self.SkinTemplate:Clone()
		local SkinName = SkinFrame:FindFirstChild("SkinName")
		local SkinImage = SkinFrame:FindFirstChild("SkinImage")
		SkinName.Text = Skin
		local itemModel = Instance.new("Model")
		local AllRarities = self.SkinSystem.Skins:GetChildren()
		local SkinRarity = nil
		for _, rarityFolder in pairs(AllRarities) do
			if rarityFolder:FindFirstChild(Skin) then
				SkinRarity = rarityFolder.Name
				break
			end
		end
		for _, child in pairs(self.Skins:FindFirstChild(Skin, true):GetChildren()) do
			if
				not (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("Sound"))
			then
				child:Clone().Parent = itemModel
			end
		end

		itemModel:PivotTo(CFrame.new() * CFrame.Angles(math.rad(0), 0, 0))
		itemModel.Parent = SkinImage

		local currentCamera = Instance.new("Camera")
		currentCamera.CFrame = CFrame.new(
			Vector3.new(-itemModel:GetExtentsSize().Y * 0.7, 0, 0),
			itemModel:GetPivot().Position + Vector3.new(0, -0.1, 0)
		)
		currentCamera.Parent = SkinImage
		SkinImage.CurrentCamera = currentCamera

		SkinFrame.Parent = self.SkinList
		SkinFrame.MouseButton1Click:Connect(function()
			self.SelectedSkin.SkinImage:ClearAllChildren()
			self.SelectedSkin.Visible = true
			self.SelectedSkin.SkinName.Text = Skin
			self.SelectedSkin.Rarity.Text = "Rarity: " .. (SkinRarity or "Common")
			local selectedItemModel = Instance.new("Model")
			if Skin == self.EquippedSkin then
				self.EquipButton.Visible = false
			else
				self.EquipButton.Visible = true
			end
			for _, child in pairs(self.Skins:FindFirstChild(Skin, true):GetChildren()) do
				if
					not (
						child:IsA("Script")
						or child:IsA("LocalScript")
						or child:IsA("ModuleScript")
						or child:IsA("Sound")
					)
				then
					child:Clone().Parent = selectedItemModel
				end
			end

			selectedItemModel:PivotTo(CFrame.new() * CFrame.Angles(math.rad(0), 0, 0))
			selectedItemModel.Parent = self.SelectedSkin.SkinImage

			local selectedCamera = Instance.new("Camera")
			selectedCamera.CFrame = CFrame.new(
				Vector3.new(-selectedItemModel:GetExtentsSize().Y * 0.7, 0, 0),
				selectedItemModel:GetPivot().Position + Vector3.new(0, -0.1, 0)
			)
			selectedCamera.Parent = self.SelectedSkin.SkinImage
			self.SelectedSkin.SkinImage.CurrentCamera = selectedCamera
		end)
	end
end

return InventoryController
