-- Hebt interaktive Objekte (Ressourcen, NPCs, Portale) hervor, wenn man nah dran ist.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

local RADIUS = 14
local active: { [Model]: Highlight } = {}

local function makeHighlight(model: Model): Highlight
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 226, 140)
	hl.FillTransparency = 0.72
	hl.OutlineColor = Color3.fromRGB(255, 240, 180)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = model
	hl.Parent = model
	return hl
end

local function getRoot(): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- true, wenn das Objekt aktuell NICHT interaktiv ist (z. B. abgebaute Ressource)
local function isDisabled(model: Model): boolean
	local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
	return prompt ~= nil and prompt.Enabled == false
end

while true do
	local root = getRoot()
	if root then
		local origin = root.Position
		local inRange: { [Model]: boolean } = {}
		for _, model in ipairs(CollectionService:GetTagged("Interactable")) do
			if model:IsA("Model") and model.Parent then
				local ok, pivot = pcall(function() return model:GetPivot().Position end)
				if ok and (pivot - origin).Magnitude <= RADIUS and not isDisabled(model) then
					inRange[model] = true
					if not active[model] then active[model] = makeHighlight(model) end
				end
			end
		end
		for model, hl in pairs(active) do
			if not inRange[model] or not model.Parent then
				hl:Destroy()
				active[model] = nil
			end
		end
	end
	task.wait(0.15)
end
