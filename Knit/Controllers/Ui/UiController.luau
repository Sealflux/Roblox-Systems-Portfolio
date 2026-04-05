local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local UiController = Knit.CreateController({ Name = "UiController" })

function UiController:KnitInit()
	self._currentTurn = nil
	self._isAddingWater = false
	self._fillConnection = nil
	self._container = nil
	self._currentHeight = 0.1
	self._lastUpdateTime = 0
	self._UPDATE_INTERVAL = 0.1
	self._isCancelled = false
	self._disabledUI = {}
	self.Player = Players.LocalPlayer
end

function UiController:KnitStart()
	self:_GetServices()

	self.FillService.StartTurnSignal:Connect(function(container, currentHeight)
		self:StartTurn(container, currentHeight)
		self:DisableAllUI()
	end)

	self.FillService.EndTurnSignal:Connect(function()
		self:EndTurn()
		self:DisableAllUI()
	end)

	self.FillService.CancelTurnSignal:Connect(function()
		self:CancelTurn()
	end)

	self.FillService.LockInSignal:Connect(function(finalHeight)
		self:ForceLockIn(finalHeight)
	end)

	self.FillService.UpdateWaterLevelSignal:Connect(function(data)
		if self.AudioController then
			self.AudioController:UpdateWaterLevel(data.fillPercent)
		end
	end)

	self.MatchService.ShowResults:Connect(function(resultsData)
		self:ShowResultsUi(resultsData)
		task.delay(5, function()
			self:CloseResultsUi()
		end)
	end)
end

function UiController:_GetServices()
	self.PlayerService = Knit.GetService("PlayerService")
	self.FillService = Knit.GetService("FillService")
	self.AudioController = Knit.GetController("AudioController")
	self.MatchService = Knit.GetService("MatchService")
	self.AnimationService = Knit.GetService("AnimationService")
end

function UiController:_ConnectButtons()
	if not self.BlindFoldGui or not self.BlindFoldGui.Parent then
		return
	end

	local frame = self.BlindFoldGui:FindFirstChild("Frame")
	if not frame then
		return
	end

	self.RopeButton = frame:WaitForChild("RopeButton")

	if self.RopeButtonConnection then
		self.RopeButtonConnection:Disconnect()
	end
	if self.RopeButtonReleaseConnection then
		self.RopeButtonReleaseConnection:Disconnect()
	end
	if self.RopeButtonTouchConnection then
		self.RopeButtonTouchConnection:Disconnect()
	end
	if self.GamepadConnection then
		self.GamepadConnection:Disconnect()
	end
	if self.GamepadReleaseConnection then
		self.GamepadReleaseConnection:Disconnect()
	end

	self.RopeButtonConnection = self.RopeButton.MouseButton1Down:Connect(function()
		if not self._currentTurn or self._currentTurn.isLockedIn or self._isCancelled then
			return
		end
		self:_StartFilling()
	end)

	self.RopeButtonReleaseConnection = self.RopeButton.MouseButton1Up:Connect(function()
		if not self._currentTurn or self._currentTurn.isLockedIn or self._isCancelled then
			return
		end
		self:_LockIn()
	end)

	self.RopeButtonTouchConnection = self.RopeButton.TouchLongPress:Connect(function(touch, pressTime)
		if touch == Enum.UserInputState.Begin then
			if not self._currentTurn or self._currentTurn.isLockedIn or self._isCancelled then
				return
			end
			self:_StartFilling()
		elseif touch == Enum.UserInputState.End then
			if not self._currentTurn or self._currentTurn.isLockedIn or self._isCancelled then
				return
			end
			self:_LockIn()
		end
	end)

	self.GamepadConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if not self._currentTurn or self._currentTurn.isLockedIn or self._isCancelled then
			return
		end

		if input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.E then
			self:_StartFilling()
		end
	end)

	self.GamepadReleaseConnection = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.E then
			if not self._currentTurn or self._currentTurn.isLockedIn or self._isCancelled then
				return
			end
			self:_LockIn()
		end
	end)
end

function UiController:_SetupInput()
	if self._inputBegan then
		self._inputBegan:Disconnect()
	end
	if self._inputEnded then
		self._inputEnded:Disconnect()
	end

	self._inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not self._currentTurn or self._currentTurn.isLockedIn or self._isCancelled then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			self:_StartFilling()
		end
	end)

	self._inputEnded = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.E then
			self:_LockIn()
		end
	end)
end

function UiController:StartTurn(container, currentHeight)
	self._isCancelled = false

	local startHeight = 0.1

	if currentHeight and currentHeight > 0 then
		startHeight = currentHeight
	end

	self._currentTurn = {
		container = container,
		isActive = true,
		isLockedIn = false,
	}

	self._container = container
	self._currentHeight = startHeight
	self._isAddingWater = false
	self._lastUpdateTime = 0

	self:PlaceBlindFold()
	self:_SetupInput()
end

function UiController:EndTurn()
	self:_CleanupTurn(false)
end

function UiController:CancelTurn()
	self:_CleanupTurn(true)
end

function UiController:ForceLockIn(finalHeight)
	if not self._currentTurn or self._currentTurn.isLockedIn then
		return
	end

	self._currentTurn.isLockedIn = true
	self._isAddingWater = false
	self._currentHeight = finalHeight

	if self._fillConnection then
		self._fillConnection:Disconnect()
		self._fillConnection = nil
	end

	task.delay(1.5, function()
		self:RemoveBlindFold()
	end)
end

function UiController:_CleanupTurn(wasCancelled)
	self._currentTurn = nil
	self._isAddingWater = false
	self._isCancelled = wasCancelled

	if self._fillConnection then
		self._fillConnection:Disconnect()
		self._fillConnection = nil
	end

	self:RemoveBlindFold()
end

function UiController:_StartFilling()
	if not self._currentTurn or not self._currentTurn.isActive or self._currentTurn.isLockedIn or self._isCancelled then
		return
	end

	self._isAddingWater = true

	if self._fillConnection then
		self._fillConnection:Disconnect()
	end

	local lastServerUpdate = tick()
	local hasWarnedHigh = false
	local hasWarnedCritical = false
	local startHeight = self._currentHeight

	self._fillConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not self._isAddingWater or not self._currentTurn or not self._currentTurn.isActive or self._isCancelled then
			if self._fillConnection then
				self._fillConnection:Disconnect()
				self._fillConnection = nil
			end
			return
		end

		local CONTAINER_HEIGHT = self._container.YHolder.Size.Y
		local FILL_RATE = (CONTAINER_HEIGHT / 6)
			* (self.Player.PlayerData.Settings:FindFirstChild("FillSensitivity").Value or 1.0)
		local randomizedFillRate = FILL_RATE * (0.9 + math.random() * 0.2)

		local newHeight = math.min(self._currentHeight + (randomizedFillRate * deltaTime), CONTAINER_HEIGHT * 1.05)

		if math.abs(newHeight - self._currentHeight) > 0.001 then
			self._currentHeight = newHeight

			local fillPercent = self._currentHeight / CONTAINER_HEIGHT

			if fillPercent >= 0.95 and not hasWarnedCritical then
				hasWarnedCritical = true
			elseif fillPercent >= 0.85 and not hasWarnedHigh then
				hasWarnedHigh = true
			end

			if self.AudioController then
				self.AudioController:StartPouring()
				self.AudioController:UpdateWaterLevel(fillPercent)
			end

			local now = tick()
			if now - lastServerUpdate >= self._UPDATE_INTERVAL then
				self.FillService:UpdateWaterLevel(self._currentHeight)
				lastServerUpdate = now
			end
		end
	end)
end

function UiController:_LockIn()
	if not self._currentTurn or self._currentTurn.isLockedIn or self._isCancelled then
		return
	end

	self._currentTurn.isLockedIn = true
	self._isAddingWater = false

	if self._fillConnection then
		self._fillConnection:Disconnect()
		self._fillConnection = nil
	end

	if self.AudioController then
		self.AudioController:OnLockIn()
	end

	self.FillService:LockIn(self._currentHeight)

	task.delay(1, function()
		self:RemoveBlindFold()
	end)
end

function UiController:DisableAllUI()
	local playerGui = self.Player:WaitForChild("PlayerGui")
	self._disabledUI = {}

	local keepVisibleList = { "BlackBlindfold", "ResultsGui" }

	for _, obj in ipairs(playerGui:GetChildren()) do
		local shouldKeep = false
		for _, keepName in ipairs(keepVisibleList) do
			if obj.Name == keepName then
				shouldKeep = true
				break
			end
		end

		if not shouldKeep then
			pcall(function()
				if obj.Enabled ~= nil then
					self._disabledUI[obj] = obj.Enabled
					obj.Enabled = false
				end
			end)
		end
	end
end

function UiController:RestoreAllUI()
	if not self._disabledUI then
		return
	end

	for obj, wasEnabled in pairs(self._disabledUI) do
		if obj and obj.Parent then
			pcall(function()
				obj.Enabled = wasEnabled
			end)
		end
	end

	self._disabledUI = {}
end

function UiController:PlaceBlindFold()
	self:RemoveBlindFold()

	self:DisableAllUI()

	local playerGui = self.Player:WaitForChild("PlayerGui")
	local PlayerData = self.Player:WaitForChild("PlayerData")
	local Settings = PlayerData:WaitForChild("Settings")
	local BlindfoldType = Settings:FindFirstChild("BlindfoldType")
	self.BlindFoldColor = BlindfoldType.Value or "Black"

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return
	end

	local uiFolder = assets:FindFirstChild("Ui")
	if not uiFolder then
		return
	end

	local blindfoldGui = uiFolder:WaitForChild((self.BlindFoldColor .. "Blindfold"), 5)
	if not blindfoldGui then
		return
	end

	self.BlindFoldGui = blindfoldGui:Clone()
	self.BlindFoldGui.Parent = playerGui
	self.BlindFoldGui.Enabled = true

	self:_ConnectButtons()
end

function UiController:RemoveBlindFold()
	if self._inputBegan then
		self._inputBegan:Disconnect()
		self._inputBegan = nil
	end
	if self._inputEnded then
		self._inputEnded:Disconnect()
		self._inputEnded = nil
	end

	if self.RopeButtonConnection then
		self.RopeButtonConnection:Disconnect()
		self.RopeButtonConnection = nil
	end
	if self.RopeButtonReleaseConnection then
		self.RopeButtonReleaseConnection:Disconnect()
		self.RopeButtonReleaseConnection = nil
	end
	if self.RopeButtonTouchConnection then
		self.RopeButtonTouchConnection:Disconnect()
		self.RopeButtonTouchConnection = nil
	end
	if self.GamepadConnection then
		self.GamepadConnection:Disconnect()
		self.GamepadConnection = nil
	end
	if self.GamepadReleaseConnection then
		self.GamepadReleaseConnection:Disconnect()
		self.GamepadReleaseConnection = nil
	end

	if self._fillConnection then
		self._fillConnection:Disconnect()
		self._fillConnection = nil
	end

	if self.BlindFoldGui then
		pcall(function()
			self.BlindFoldGui:Destroy()
		end)
		self.BlindFoldGui = nil
	end

	self:RestoreAllUI()
end

function UiController:ShowResultsUi(resultsData)
	if not resultsData then
		return
	end

	local playerGui = self.Player:WaitForChild("PlayerGui")
	self.ResultsGui = playerGui:FindFirstChild("ResultsGui")

	if not self.ResultsGui then
		return
	end

	self.ResultsGui.Enabled = true

	local player1Percent = self.ResultsGui:FindFirstChild("Player1Percent")
	local player2Percent = self.ResultsGui:FindFirstChild("Player2Percent")
	local resultText = self.ResultsGui:FindFirstChild("ResultText")

	local player1Overflow = resultsData.Player1FillPercent and resultsData.Player1FillPercent >= 0.99
	local player2Overflow = resultsData.Player2FillPercent and resultsData.Player2FillPercent >= 0.99

	if player1Percent then
		if player1Overflow then
			player1Percent.Text = "Overflow!"
		else
			player1Percent.Text = math.floor((resultsData.Player1FillPercent or 0) * 100) .. "%"
		end
	end
	if player2Percent then
		if player2Overflow then
			player2Percent.Text = "Overflow!"
		else
			player2Percent.Text = math.floor((resultsData.Player2FillPercent or 0) * 100) .. "%"
		end
	end

	local isWinner = (resultsData.winner == self.Player)
	local isLoser = (resultsData.loser == self.Player)

	if isWinner then
		if resultText then
			resultText.Text = "You Win! 🏆"
		end
	elseif isLoser then
		if resultText then
			resultText.Text = "You Overflowed! 💥"
		end
	end

	task.delay(4, function()
		if self.ResultsGui and self.ResultsGui.Enabled then
			self.ResultsGui.Enabled = false
		end
	end)
	self:RestoreAllUI()
end

function UiController:CleanupResultsUi()
	if self.ResultsGui then
		self.ResultsGui.Enabled = false
		for _, child in ipairs(self.ResultsGui:GetDescendants()) do
			if child.Name == "Glow" then
				child:Destroy()
			end
		end
	end
end

function UiController:CloseResultsUi()
	if self.ResultsGui then
		self.ResultsGui.Enabled = false
	end
end

function UiController:Test()
	local testContainer = workspace:FindFirstChild("TestContainer")
	if testContainer then
		self:StartTurn(testContainer, 0.1)
	end
end

return UiController
