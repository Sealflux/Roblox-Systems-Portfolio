local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local AnimationService = Knit.CreateService({
	Name = "AnimationService",
	Client = {
		-- Define client signals here if needed
	},
})

function AnimationService:KnitInit()
	-- Initialization logic here
end

function AnimationService:KnitStart()
	-- Startup logic here
end

function AnimationService:AnimateNPC(NPC, animationID)
	local humanoid = NPC:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. tostring(animationID)
	local animationTrack = animator:LoadAnimation(animation)
	animationTrack.Looped = true
	animationTrack.Priority = Enum.AnimationPriority.Idle
	animationTrack:Play()
end

function AnimationService.Client:AnimateNPC(NPC, animationID)
	AnimationService:AnimateNPC(NPC, animationID)
end

return AnimationService
