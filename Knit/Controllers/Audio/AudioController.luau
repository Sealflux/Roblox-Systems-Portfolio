local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AudioController = Knit.CreateController({ Name = "AudioController" })

function AudioController:KnitInit()
	self._sounds = {}
	self._isPouring = false
	self._currentLevel = 1
	self._currentFillPercent = 0
	self._activeTweens = {}
	self._isOverflow = false
	self._hasPlayedOverflow = false
	self._isLockedIn = false
end

function AudioController:KnitStart()
	self:_LoadSounds()

	self.MatchService = Knit.GetService("MatchService")
	if self.MatchService then
		self.MatchService.MatchEnded:Connect(function(player, results)
			if player == game.Players.LocalPlayer then
				self:OnMatchEnded(results)
			end
		end)
	end
end

function AudioController:_LoadSounds()
	local AssetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if not AssetsFolder then
		return
	end

	local SoundsFolder = AssetsFolder:FindFirstChild("Sounds")
	if not SoundsFolder then
		return
	end

	local gameplayFolder = SoundsFolder:FindFirstChild("Gameplay")
	if not gameplayFolder then
		return
	end

	self._sounds = {
		pourStart = gameplayFolder:FindFirstChild("PourStart"),
		pourFinish = gameplayFolder:FindFirstChild("PourFinish"),
		level1 = gameplayFolder:FindFirstChild("PourLevel1"),
		level2 = gameplayFolder:FindFirstChild("PourLevel2"),
		level3 = gameplayFolder:FindFirstChild("PourLevel3"),
		overflowSound = gameplayFolder:FindFirstChild("OverflowSound"),
		successSound = gameplayFolder:FindFirstChild("SuccessSound"),
		lockSound = gameplayFolder:FindFirstChild("LockSound"),
	}

	for name, sound in pairs(self._sounds) do
		if sound then
			local clone = sound:Clone()
			clone.Name = name
			clone.Parent = SoundService
			self._sounds[name] = clone

			if name:find("level") then
				clone.Looped = true
				clone.Volume = 0
				clone.PlaybackSpeed = 1.0
			end
		end
	end
end

function AudioController:StartPouring()
	if self._isPouring then
		return
	end

	if self._isLockedIn then
		self._isLockedIn = false
	end

	self._isPouring = true
	self._isOverflow = false
	self._hasPlayedOverflow = false
	self._currentFillPercent = 0

	if self._sounds.pourStart then
		self._sounds.pourStart:Play()
	end

	for i = 1, 3 do
		local sound = self._sounds["level" .. i]
		if sound and not sound.IsPlaying then
			sound:Play()
		end
	end

	self:_SetLevel(1)
end

function AudioController:StopPouring()
	if not self._isPouring then
		return
	end

	self._isPouring = false

	for i = 1, 3 do
		local sound = self._sounds["level" .. i]
		if sound then
			self:_FadeSound(sound, 0, 0.2)
		end
	end

	self._currentLevel = 1
end

function AudioController:UpdateWaterLevel(fillPercent)
	if self._isLockedIn then
		return
	end

	if not self._isPouring then
		return
	end

	if not fillPercent then
		return
	end

	self._currentFillPercent = fillPercent

	if fillPercent >= 1.0 and not self._hasPlayedOverflow then
		self._hasPlayedOverflow = true
		self._isOverflow = true
		self._isPouring = false
		self:PlayOverflowSound()
		return
	end

	if self._isOverflow then
		return
	end

	local targetLevel = self:_GetLevelFromWaterHeight(fillPercent)

	if targetLevel ~= self._currentLevel then
		self:_SetLevel(targetLevel)
		self._currentLevel = targetLevel
	end

	self:_AdjustVolumeBasedOnWaterHeight()
end

function AudioController:_GetLevelFromWaterHeight(fillPercent)
	if fillPercent <= 0.33 then
		return 1
	elseif fillPercent <= 0.66 then
		return 2
	else
		return 3
	end
end

function AudioController:_AdjustVolumeBasedOnWaterHeight()
	local currentSound = self._sounds["level" .. self._currentLevel]
	if not currentSound then
		return
	end

	local fillPercent = self._currentFillPercent
	local volume = 0.5

	if self._currentLevel == 1 then
		local progress = fillPercent / 0.33
		volume = 0.4 + (progress * 0.2)
	elseif self._currentLevel == 2 then
		local progress = (fillPercent - 0.33) / 0.33
		volume = 0.6 + (progress * 0.2)
	elseif self._currentLevel == 3 then
		local progress = (fillPercent - 0.66) / 0.34
		volume = 0.8 + (progress * 0.2)

		if fillPercent >= 0.95 then
			local overdrive = (fillPercent - 0.95) / 0.05
			volume = volume + (overdrive * 0.15)
		end
	end

	volume = math.min(volume, 1.0)

	if math.abs(currentSound.Volume - volume) > 0.02 then
		self:_FadeSound(currentSound, volume, 0.05)
	end
end

function AudioController:_SetLevel(level)
	local newSound = self._sounds["level" .. level]
	if newSound and not newSound.IsPlaying then
		newSound:Play()
	end

	self:_AdjustVolumeBasedOnWaterHeight()
end

function AudioController:OnLockIn()
	self._isLockedIn = true
	self:_StopAllPouringSounds()

	if self._sounds.lockSound then
		local clone = self._sounds.lockSound:Clone()
		clone.Parent = SoundService
		clone.Volume = 0.7
		clone:Play()
		clone.Ended:Connect(function()
			clone:Destroy()
		end)
	end

	if self._sounds.pourFinish then
		local clone = self._sounds.pourFinish:Clone()
		clone.Parent = SoundService
		clone.Volume = 0.5
		clone.PlaybackSpeed = 1.0
		clone:Play()
		clone.Ended:Connect(function()
			clone:Destroy()
		end)
	end
end

function AudioController:_StopAllPouringSounds()
	for i = 1, 3 do
		local sound = self._sounds["level" .. i]
		if sound then
			sound:Stop()
			sound.Volume = 0
		end
	end

	if self._sounds.pourStart then
		self._sounds.pourStart:Stop()
	end

	self._isPouring = false
end

function AudioController:PlayOverflowSound()
	self:_StopAllPouringSounds()
	self._isLockedIn = true

	if self._sounds.overflowSound then
		self._sounds.overflowSound:Play()
	else
		local fallback = self._sounds.pourFinish
		if fallback then
			local clone = fallback:Clone()
			clone.PlaybackSpeed = 0.5
			clone.Volume = 1.0
			clone.Parent = SoundService
			clone:Play()
			clone.Ended:Connect(function()
				clone:Destroy()
			end)
		end
	end
end

function AudioController:OnMatchEnded(results)
	self:_StopAllPouringSounds()

	self._isLockedIn = false
	self._isOverflow = false
	self._hasPlayedOverflow = false
	self._isPouring = false
	self._currentLevel = 1
	self._currentFillPercent = 0

	if results and results.winner then
		local isWinner = (results.winner == game.Players.LocalPlayer)

		if isWinner and self._sounds.successSound then
			self._sounds.successSound:Play()
		elseif not isWinner and self._sounds.pourFinish then
			local clone = self._sounds.pourFinish:Clone()
			clone.PlaybackSpeed = 0.8
			clone.Volume = 0.5
			clone.Parent = SoundService
			clone:Play()
			clone.Ended:Connect(function()
				clone:Destroy()
			end)
		end
	end
end

function AudioController:ResetAudio()
	self._isPouring = false
	self._isOverflow = false
	self._hasPlayedOverflow = false
	self._isLockedIn = false
	self._currentLevel = 1
	self._currentFillPercent = 0

	for i = 1, 3 do
		local sound = self._sounds["level" .. i]
		if sound then
			sound:Stop()
			sound.Volume = 0
			sound.PlaybackSpeed = 1.0
		end
	end
end

function AudioController:_FadeSound(sound, targetVolume, duration)
	if not sound then
		return
	end

	if self._activeTweens[sound] then
		self._activeTweens[sound]:Cancel()
	end

	local tween = TweenService:Create(
		sound,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = targetVolume }
	)

	self._activeTweens[sound] = tween

	tween.Completed:Connect(function()
		self._activeTweens[sound] = nil
	end)

	tween:Play()
end

function AudioController:KnitDestroy()
	for name, sound in pairs(self._sounds) do
		if sound then
			sound:Stop()
			sound:Destroy()
		end
	end
end

return AudioController
