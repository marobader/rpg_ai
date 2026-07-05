-- Quest-UI: NPC-Dialog + Quest-Tracker (oben links).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RPG = ReplicatedStorage:WaitForChild("RPG")
local Config = RPG:WaitForChild("Config")
local Remotes = RPG:WaitForChild("Remotes")
local Quests = require(Config:WaitForChild("Quests"))

local OpenDialogue = Remotes:WaitForChild("OpenDialogue")
local DialogueChoice = Remotes:WaitForChild("DialogueChoice")
local ProfileUpdated = Remotes:WaitForChild("ProfileUpdated")

local function corner(inst, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = inst; return c
end
local function stroke(inst, color, th, tr)
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = th or 1.5; s.Transparency = tr or 0; s.Parent = inst; return s
end

local gui = Instance.new("ScreenGui")
gui.Name = "RPG_Quest"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = playerGui

-- ========== Quest-Tracker (oben links) ==========
local tracker = Instance.new("Frame")
tracker.Size = UDim2.fromOffset(250, 10); tracker.AutomaticSize = Enum.AutomaticSize.Y
tracker.Position = UDim2.fromOffset(16, 90)
tracker.BackgroundColor3 = Color3.fromRGB(24,24,30); tracker.BackgroundTransparency = 0.15
tracker.Visible = false; tracker.Parent = gui
corner(tracker, 10); stroke(tracker, Color3.fromRGB(80,80,100), 1.5, 0.2)
local trackerPad = Instance.new("UIPadding")
trackerPad.PaddingTop = UDim.new(0,8); trackerPad.PaddingBottom = UDim.new(0,8)
trackerPad.PaddingLeft = UDim.new(0,12); trackerPad.PaddingRight = UDim.new(0,12); trackerPad.Parent = tracker
local trackerList = Instance.new("UIListLayout")
trackerList.Padding = UDim.new(0,4); trackerList.SortOrder = Enum.SortOrder.LayoutOrder; trackerList.Parent = tracker

local function addLine(text, color, order, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1; l.Size = UDim2.new(1,0,0,18); l.AutomaticSize = Enum.AutomaticSize.Y
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham; l.TextSize = bold and 15 or 13
	l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
	l.TextColor3 = color; l.Text = text; l.LayoutOrder = order; l.Parent = tracker
end

local function refreshTracker(profile)
	for _, c in ipairs(tracker:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	local any = false
	local order = 0
	for questId, e in pairs(profile.quests or {}) do
		local def = Quests.get(questId)
		if def and e.status == "active" then
			any = true
			order += 1; addLine("\u{1F4DC} " .. def.title, Color3.fromRGB(255,220,120), order, true)
			for _, obj in ipairs(def.objectives) do
				local cur = (e.progress and e.progress[obj.key]) or 0
				local done = cur >= obj.amount
				order += 1
				addLine(string.format("  %s %s  %d/%d", done and "\u{2714}" or "\u{2022}", obj.text, cur, obj.amount),
					done and Color3.fromRGB(110,210,130) or Color3.fromRGB(210,210,220), order, false)
			end
		end
	end
	tracker.Visible = any
end

ProfileUpdated.OnClientEvent:Connect(refreshTracker)

-- ========== Dialog-Fenster (unten mittig) ==========
local dlg = Instance.new("Frame")
dlg.Size = UDim2.fromOffset(620, 180); dlg.Position = UDim2.new(0.5, -310, 1, -230)
dlg.BackgroundColor3 = Color3.fromRGB(20,20,26); dlg.Visible = false; dlg.Parent = gui
corner(dlg, 14); stroke(dlg, Color3.fromRGB(120,110,180), 2, 0.05)

local nameTag = Instance.new("TextLabel")
nameTag.Size = UDim2.fromOffset(180, 32); nameTag.Position = UDim2.fromOffset(18, -16)
nameTag.BackgroundColor3 = Color3.fromRGB(120,100,180); nameTag.Font = Enum.Font.GothamBold
nameTag.TextSize = 17; nameTag.TextColor3 = Color3.fromRGB(255,255,255); nameTag.Text = "NPC"; nameTag.Parent = dlg
corner(nameTag, 8)

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1; body.Position = UDim2.fromOffset(22, 30); body.Size = UDim2.new(1,-44,0,86)
body.Font = Enum.Font.Gotham; body.TextSize = 16; body.TextColor3 = Color3.fromRGB(235,235,240)
body.TextXAlignment = Enum.TextXAlignment.Left; body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true; body.Text = ""; body.Parent = dlg

local optHolder = Instance.new("Frame")
optHolder.BackgroundTransparency = 1; optHolder.Position = UDim2.new(0,22,1,-52); optHolder.Size = UDim2.new(1,-44,0,40)
optHolder.Parent = dlg
local optLayout = Instance.new("UIListLayout")
optLayout.FillDirection = Enum.FillDirection.Horizontal; optLayout.Padding = UDim.new(0,10)
optLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; optLayout.VerticalAlignment = Enum.VerticalAlignment.Center
optLayout.SortOrder = Enum.SortOrder.LayoutOrder; optLayout.Parent = optHolder

local function clearOptions()
	for _, c in ipairs(optHolder:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
end

OpenDialogue.OnClientEvent:Connect(function(payload)
	nameTag.Text = payload.npcName or "NPC"
	body.Text = table.concat(payload.lines or {}, "\n")
	clearOptions()
	for i, opt in ipairs(payload.options or {}) do
		local b = Instance.new("TextButton")
		b.AutomaticSize = Enum.AutomaticSize.X; b.Size = UDim2.fromOffset(0, 36)
		b.BackgroundColor3 = Color3.fromRGB(70,60,120); b.Font = Enum.Font.GothamBold; b.TextSize = 15
		b.TextColor3 = Color3.fromRGB(255,255,255); b.Text = "  " .. opt.label .. "  "; b.LayoutOrder = i; b.Parent = optHolder
		corner(b, 8)
		b.Activated:Connect(function()
			DialogueChoice:FireServer({ questId = payload.questId, choice = opt.id })
			dlg.Visible = false
		end)
	end
	dlg.Visible = true
end)

print("[QuestClient] bereit")
