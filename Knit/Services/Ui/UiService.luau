local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local UiService = Knit.CreateService({ Name = "UiService", Client = {} })

function UiService:KnitInit() end

function UiService:KnitStart() end

function UiService:CreatePrompt(object)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Interact"
	prompt.ObjectText = "Station"
	prompt.HoldDuration = 0.2
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = object
	return prompt
end

function UiService:UpdateText(TextLabel, newText)
	TextLabel.Text = newText
end

return UiService
