local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local VFXService = Knit.CreateService({
	Name = "VFXService",
	Client = {},
})

function VFXService:KnitInit()
	self._activeEffects = {}
	self._activeConfetti = {}
end

function VFXService:KnitStart()
	self:_GetServices()
	self:_GetVFX()
end

function VFXService:_GetServices()
	self.StationService = Knit.GetService("StationService")
end

function VFXService:_GetVFX()
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	if not assets then
		return
	end

	local vfxFolder = assets:FindFirstChild("VFX")
	if not vfxFolder then
		return
	end

	self.VFXFolder = vfxFolder
	self.FillEffect = vfxFolder:FindFirstChild("FillEffect")
	self.ConfettiEffect = vfxFolder:FindFirstChild("ConfettiEffect")
end

function VFXService:PlayFillEffect(stationID)
	local station = self.StationService:GetStationByID(stationID)
	if not station then
		return nil
	end

	if not self.FillEffect then
		return nil
	end

	local stationModel = station.Model
	local sprinkler = stationModel:FindFirstChild("Sprinkler")

	if not sprinkler then
		return nil
	end

	if self._activeEffects[stationID] then
		return nil
	end

	local fillEffectClone = self.FillEffect:Clone()
	fillEffectClone.Parent = workspace

	local sprinklerCFrame = sprinkler:GetPivot()

	fillEffectClone:PivotTo(sprinklerCFrame)

	for _, part in ipairs(fillEffectClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
			part.CanCollide = false
		end
	end

	self._activeEffects[stationID] = fillEffectClone

	task.delay(1, function()
		self:StopFillEffect(stationID)
	end)

	return fillEffectClone
end

function VFXService:PlayConfettiEffect(player)
	if not player or not player.Character then
		return
	end

	local head = player.Character:FindFirstChild("Head")
	if not head then
		return
	end

	if self._activeConfetti[player] then
		return
	end

	if not self.ConfettiEffect then
		return
	end

	local confetti = self.ConfettiEffect:Clone()
	confetti.Parent = head

	confetti:PivotTo(head.CFrame * CFrame.new(0, 1, 0))

	for _, part in ipairs(confetti:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
			part.CanCollide = false
		elseif part:IsA("ParticleEmitter") then
			part.Enabled = true
		end
	end

	task.delay(1, function()
		confetti:Destroy()
		if self._activeConfetti[player] then
			self._activeConfetti[player] = nil
		end
	end)

	self._activeConfetti[player] = confetti
end

function VFXService:StopFillEffect(stationID)
	local effect = self._activeEffects[stationID]
	if effect then
		effect:Destroy()
		self._activeEffects[stationID] = nil
	end
end

function VFXService:StopAllEffects()
	for stationID, effect in pairs(self._activeEffects) do
		if effect then
			effect:Destroy()
		end
	end
	self._activeEffects = {}
end

function VFXService:StopAllConfetti()
	for player, effect in pairs(self._activeConfetti) do
		if effect then
			effect:Destroy()
		end
	end
	self._activeConfetti = {}
end

function VFXService.Client:PlayConfettiEffect(player: Player)
	if not player then
		return
	end
	self.Server:PlayConfettiEffect(player)
end

return VFXService
