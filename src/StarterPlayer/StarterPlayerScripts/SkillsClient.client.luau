-- Skill-Panel (alle 12 Skills mit Level + XP-Balken) + Level-Up-Effekt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RPG = ReplicatedStorage:WaitForChild("RPG")
local Config = RPG:WaitForChild("Config")
local Remotes = RPG:WaitForChild("Remotes")
local Skills = require(Config:WaitForChild("Skills"))
local XP = require(Config:WaitForChild("XP"))

local ProfileUpdated = Remotes:WaitForChild("ProfileUpdated")
local SkillXpGained = Remotes:WaitForChild("SkillXpGained")

-- ---------- Theme ----------
local C = {
	bg = Color3.fromRGB(24,24,30),
	surface = Color3.fromRGB(38,38,46),
	surfaceDim = Color3.fromRGB(30,30,36),
	stroke = Color3.fromRGB(80,80,100),
	text = Color3.fromRGB(238,238,244),
	textDim = Color3.fromRGB(140,140,155),
	barBg = Color3.fromRGB(52,52,62),
	accent = Color3.fromRGB(255,210,90),
}
local function skillColor(def) local c = def.color; return Color3.fromRGB(c[1],c[2],c[3]) end
local function corner(i,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=i; return c end
local function stroke(i,col,th,tr) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1.5; s.Transparency=tr or 0; s.Parent=i; return s end

local currentProfile = nil

-- ---------- ScreenGui ----------
local gui = Instance.new("ScreenGui")
gui.Name = "RPG_Skills"; gui.ResetOnSpawn = false; gui.DisplayOrder = 30
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = playerGui

-- ---------- Toggle-Button (unten rechts, ueber dem Beutel) ----------
local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(52,52); btn.Position = UDim2.new(1,-68,1,-130)
btn.BackgroundColor3 = Color3.fromRGB(40,40,48); btn.Text = "\u{2B50}"; btn.TextSize = 24
btn.Font = Enum.Font.GothamBold; btn.TextColor3 = C.text; btn.Parent = gui
corner(btn,12); stroke(btn, C.stroke, 1.5)

-- ---------- Panel ----------
local PW, PH = 470, 540
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(PW, PH); panel.Position = UDim2.new(0.5,0,0.5,0); panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.BackgroundColor3 = C.bg; panel.Visible = false; panel.Parent = gui
corner(panel,14); stroke(panel, C.stroke, 2, 0.1)
local sizeC = Instance.new("UISizeConstraint"); sizeC.MinSize = Vector2.new(360,400); sizeC.Parent = panel

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1; header.Position = UDim2.fromOffset(18,10); header.Size = UDim2.new(1,-36,0,34)
header.Font = Enum.Font.GothamBold; header.TextSize = 22; header.TextXAlignment = Enum.TextXAlignment.Left
header.TextColor3 = C.text; header.Text = "F\u{00E4}higkeiten"; header.Parent = panel

local totalLabel = Instance.new("TextLabel")
totalLabel.BackgroundTransparency = 1; totalLabel.Position = UDim2.fromOffset(-18,12); totalLabel.Size = UDim2.new(1,-36,0,30)
totalLabel.Font = Enum.Font.GothamBold; totalLabel.TextSize = 15; totalLabel.TextXAlignment = Enum.TextXAlignment.Right
totalLabel.TextColor3 = C.accent; totalLabel.Text = "Gesamtlevel 0"; totalLabel.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30,30); closeBtn.Position = UDim2.new(1,-40,0,12)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,50,60); closeBtn.Text = "\u{2715}"; closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextColor3 = C.text; closeBtn.Parent = panel
corner(closeBtn,8)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(12,52); scroll.Size = UDim2.new(1,-24,1,-64)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6; scroll.ScrollBarImageColor3 = C.stroke
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.Parent = panel
local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0,6); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll

-- ---------- Zeilen bauen ----------
local function buildCategoryHeader(name, order)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1; l.Size = UDim2.new(1,0,0,24); l.LayoutOrder = order
	l.Font = Enum.Font.GothamBold; l.TextSize = 14; l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = C.textDim; l.Text = string.upper(name); l.Parent = scroll
end

local function buildSkillRow(def, xpVal, order)
	local active = def.active
	local prog = XP.progress(xpVal)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1,0,0,52); row.LayoutOrder = order
	row.BackgroundColor3 = active and C.surface or C.surfaceDim; row.Parent = scroll
	corner(row,8); stroke(row, active and skillColor(def) or C.stroke, active and 1.5 or 1, active and 0.4 or 0.7)

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1; name.Position = UDim2.fromOffset(12,7); name.Size = UDim2.new(0.6,0,0,20)
	name.Font = Enum.Font.GothamBold; name.TextSize = 15; name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = active and C.text or C.textDim
	name.Text = def.name .. (active and "" or "   (bald)"); name.Parent = row

	local lvl = Instance.new("TextLabel")
	lvl.BackgroundTransparency = 1; lvl.Position = UDim2.new(1,-70,0,7); lvl.Size = UDim2.fromOffset(58,20)
	lvl.Font = Enum.Font.GothamBold; lvl.TextSize = 14; lvl.TextXAlignment = Enum.TextXAlignment.Right
	lvl.TextColor3 = active and C.accent or C.textDim
	lvl.Text = active and ("Lv " .. prog.level) or "Lv 1"; lvl.Parent = row

	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.fromOffset(12,32); barBg.Size = UDim2.new(1,-90,0,10)
	barBg.BackgroundColor3 = C.barBg; barBg.Parent = row; corner(barBg,5)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(active and prog.fraction or 0,0,1,0)
	fill.BackgroundColor3 = active and skillColor(def) or C.barBg; fill.Parent = barBg; corner(fill,5)

	local xpText = Instance.new("TextLabel")
	xpText.BackgroundTransparency = 1; xpText.Position = UDim2.new(1,-74,0,30); xpText.Size = UDim2.fromOffset(64,14)
	xpText.Font = Enum.Font.Gotham; xpText.TextSize = 11; xpText.TextXAlignment = Enum.TextXAlignment.Right
	xpText.TextColor3 = C.textDim
	xpText.Text = active and (prog.max and "MAX" or string.format("%d/%d", prog.into, prog.need)) or "gesperrt"
	xpText.Parent = row
end

local function refresh()
	if not currentProfile then return end
	for _, c in ipairs(scroll:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	local totalLevel = 0
	local order = 0
	for _, cat in ipairs(Skills.Categories) do
		order += 1; buildCategoryHeader(cat, order)
		for _, def in ipairs(Skills.List) do
			if def.category == cat then
				local xpVal = (currentProfile.skills and currentProfile.skills[def.key]) or 0
				totalLevel += XP.levelForXp(xpVal)
				order += 1; buildSkillRow(def, xpVal, order)
			end
		end
	end
	totalLabel.Text = "Gesamtlevel " .. totalLevel
end

local function toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refresh()
		panel.Size = UDim2.fromOffset(PW*0.85, PH*0.85)
		TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(PW,PH) }):Play()
	end
end
btn.Activated:Connect(toggle)
closeBtn.Activated:Connect(function() panel.Visible = false end)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.K then toggle() end
end)

ProfileUpdated.OnClientEvent:Connect(function(profile)
	currentProfile = profile
	if panel.Visible then refresh() end
end)

-- ================= LEVEL-UP-EFFEKT =================
local function playLevelUp(skillKey, newLevel)
	local def = Skills.ByKey[skillKey]
	local col = def and skillColor(def) or C.accent

	local pop = Instance.new("Frame")
	pop.AnchorPoint = Vector2.new(0.5,0.5); pop.Position = UDim2.new(0.5,0,0.36,0)
	pop.Size = UDim2.fromOffset(340,96); pop.BackgroundColor3 = C.bg; pop.BackgroundTransparency = 0.05
	pop.Parent = gui
	corner(pop,14); local st = stroke(pop, col, 3, 0)

	local glow = Instance.new("UIGradient")
	glow.Color = ColorSequence.new(col, Color3.fromRGB(255,255,255)); glow.Rotation = 90; glow.Parent = st

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1; title.Size = UDim2.new(1,0,0,40); title.Position = UDim2.fromOffset(0,12)
	title.Font = Enum.Font.GothamBlack; title.TextSize = 26; title.TextColor3 = C.accent
	title.Text = "\u{2B50}  LEVEL UP!  \u{2B50}"; title.Parent = pop

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1; sub.Size = UDim2.new(1,0,0,26); sub.Position = UDim2.fromOffset(0,52)
	sub.Font = Enum.Font.GothamBold; sub.TextSize = 18; sub.TextColor3 = col
	sub.Text = string.format("%s  \u{2192}  Level %d", def and def.name or skillKey, newLevel); sub.Parent = pop

	-- Auftauchen
	pop.Size = UDim2.fromOffset(0,0)
	TweenService:Create(pop, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(340,96) }):Play()
	-- Pulsierender Rahmen
	TweenService:Create(st, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), { Thickness = 6 }):Play()
	-- Ausblenden
	task.delay(1.9, function()
		local out = TweenService:Create(pop, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5,0,0.30,0), BackgroundTransparency = 1,
		})
		TweenService:Create(title, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(sub, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(st, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		out:Play(); out.Completed:Wait(); pop:Destroy()
	end)
end

SkillXpGained.OnClientEvent:Connect(function(data)
	if panel.Visible then refresh() end
	if data.leveledUp then
		playLevelUp(data.skill, data.level)
	end
end)

print("[SkillsClient] bereit")
