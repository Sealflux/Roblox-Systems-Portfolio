local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local CodesController = Knit.CreateController({
	Name = "CodesController",
})

function CodesController:KnitInit() end

function CodesController:KnitStart()
	self:_GetServices()
	self:_GetAssets()
	self:_SetupConnections()
end

function CodesController:_GetServices()
	self.TweenService = game:GetService("TweenService")
	self.CodesService = Knit.GetService("CodesService")
	self.GroupController = Knit.GetController("GroupController")
end

function CodesController:_GetAssets()
	self.Player = game:GetService("Players").LocalPlayer
	self.PlayerGui = self.Player:WaitForChild("PlayerGui")
	self.CodesGui = self.PlayerGui:WaitForChild("Left")
	-- Buttons
	self.OpenButton = self.CodesGui:WaitForChild("Frame"):WaitForChild("Codes")
	self.CodesFrame = self.CodesGui:WaitForChild("CodesFrame")
	self.EnterTextBoxFrame = self.CodesFrame:WaitForChild("EnterTextBoxFrame")
	self.EnterCodeTextBox = self.EnterTextBoxFrame:WaitForChild("EnterCodeTextBox")
	self.RedeemButton = self.CodesFrame:WaitForChild("RedeemButton")
	self.ResultText = self.CodesFrame:WaitForChild("ResultText")
end

function CodesController:_SetupConnections()
	-- In your UI Controller:
	self.RedeemButton.Activated:Connect(function()
		local player = game.Players.LocalPlayer
		self.CodesService
			:CheckIfInGroup(34304222)
			:andThen(function(isInGroup)
				if not isInGroup then
					self.GroupController:PromptJoinGroup(player, 34304222)
					self.ResultText.Text = "You must be in the Sealflux group to redeem this code."
					return
				else
					self.ResultText.Text = "You are in the Sealflux group. You can redeem the code."
					task.wait(0.1)
					self.ResultText.Text = "."
					task.wait(0.1)
					self.ResultText.Text = ".."
					task.wait(0.1)
					self.ResultText.Text = "..."
					task.wait(0.1)
					self.ResultText.Text = "...."
					task.wait(0.1)
					self.ResultText.Text = "....."
					task.wait(0.1)
					local code = self.EnterCodeTextBox.Text
					if code == "" then
						self.ResultText.Text = "Please enter a code."
						return
					end
					self.CodesService
						:RedeemCode(code)
						:andThen(function(result)
							self.ResultText.Text = result
						end)
						:catch(function(errorMessage)
							self.ResultText.Text = "Error redeeming code: " .. errorMessage
							print("Error redeeming code: " .. errorMessage)
							return
						end)
				end
			end)
			:catch(function(errorMessage)
				print("Error checking group membership: " .. errorMessage)
			end)
	end)
end

return CodesController
