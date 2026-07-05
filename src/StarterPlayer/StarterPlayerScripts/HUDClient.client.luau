-- HUD: Inventar, Gold-Anzeige und Pop-up-Meldungen (Toasts).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RPG = ReplicatedStorage:WaitForChild("RPG")
local Config = RPG:WaitForChild("Config")
local Remotes = RPG:WaitForChild("Remotes")
local Items = require(Config:WaitForChild("Items"))

local ProfileUpdated = Remotes:WaitForChild("ProfileUpdated")
local Notify = Remotes:WaitForChild("Notify")

local INV_COLS = 5
local SLOT = 62
local PAD = 8

local currentProfile = nil

-- ---------- Helfer ----------
local function corner(inst, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = inst; return c
end
local function stroke(inst, color, th, tr)
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = th or 1.5
	s.Transparency = tr or 0; s.Parent = inst; return s
end
local function rarityColor(r)
	local c = Items.RarityColor[r] or {180,180,180}
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- ---------- ScreenGui ----------
local gui = Instance.new("ScreenGui")
gui.Name = "RPG_HUD"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- ---------- Gold-Anzeige (unten links) ----------
local goldFrame = Instance.new("Frame")
goldFrame.Size = UDim2.fromOffset(150, 40)
goldFrame.Position = UDim2.new(0, 16, 1, -56)
goldFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
goldFrame.BackgroundTransparency = 0.15
goldFrame.Parent = gui
corner(goldFrame, 10); stroke(goldFrame, Color3.fromRGB(220, 190, 90), 1.5, 0.2)
local coin = Instance.new("Frame")
coin.Size = UDim2.fromOffset(20,20); coin.Position = UDim2.new(0,12,0.5,-10)
coin.BackgroundColor3 = Color3.fromRGB(230, 195, 80); coin.Parent = goldFrame; corner(coin, 10)
local goldLabel = Instance.new("TextLabel")
goldLabel.BackgroundTransparency = 1; goldLabel.Size = UDim2.new(1, -40, 1, 0); goldLabel.Position = UDim2.fromOffset(40, 0)
goldLabel.Font = Enum.Font.GothamBold; goldLabel.TextSize = 18; goldLabel.TextXAlignment = Enum.TextXAlignment.Left
goldLabel.TextColor3 = Color3.fromRGB(245, 225, 150); goldLabel.Text = "0"; goldLabel.Parent = goldFrame

-- ---------- Inventar-Button (unten rechts) ----------
local invButton = Instance.new("TextButton")
invButton.Size = UDim2.fromOffset(52, 52); invButton.Position = UDim2.new(1, -68, 1, -68)
invButton.BackgroundColor3 = Color3.fromRGB(40, 40, 48); invButton.Text = "🎒"; invButton.TextSize = 26
invButton.Font = Enum.Font.GothamBold; invButton.TextColor3 = Color3.fromRGB(255,255,255); invButton.Parent = gui
corner(invButton, 12); stroke(invButton, Color3.fromRGB(90,90,110), 1.5)

-- ---------- Inventar-Panel ----------
local panelW = INV_COLS * SLOT + (INV_COLS + 1) * PAD
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(panelW, 400)
panel.Position = UDim2.new(0.5, -panelW/2, 0.5, -200)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 30); panel.Visible = false; panel.Parent = gui
corner(panel, 14); stroke(panel, Color3.fromRGB(80, 80, 100), 2, 0.1)

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1; header.Size = UDim2.new(1, -20, 0, 44); header.Position = UDim2.fromOffset(16, 6)
header.Font = Enum.Font.GothamBold; header.TextSize = 22; header.TextXAlignment = Enum.TextXAlignment.Left
header.TextColor3 = Color3.fromRGB(240,240,245); header.Text = "Inventar"; header.Parent = panel

local slotsLabel = Instance.new("TextLabel")
slotsLabel.BackgroundTransparency = 1; slotsLabel.Size = UDim2.new(1, -20, 0, 44); slotsLabel.Position = UDim2.fromOffset(-16, 6)
slotsLabel.Font = Enum.Font.Gotham; slotsLabel.TextSize = 14; slotsLabel.TextXAlignment = Enum.TextXAlignment.Right
slotsLabel.TextColor3 = Color3.fromRGB(160,160,175); slotsLabel.Text = "0/0"; slotsLabel.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30,30); closeBtn.Position = UDim2.new(1, -38, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,50,60); closeBtn.Text = "✕"; closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextColor3 = Color3.fromRGB(230,230,235); closeBtn.Parent = panel
corner(closeBtn, 8)

local grid = Instance.new("Frame")
grid.BackgroundTransparency = 1; grid.Position = UDim2.fromOffset(PAD, 56)
grid.Size = UDim2.new(1, -PAD*2, 1, -66); grid.Parent = panel
local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(SLOT, SLOT); layout.CellPadding = UDim2.fromOffset(PAD, PAD)
layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = grid

-- Slots erzeugen
local slotFrames = {}
local function buildSlots(count)
	for _, f in ipairs(slotFrames) do f:Destroy() end
	slotFrames = {}
	for i = 1, count do
		local s = Instance.new("Frame")
		s.BackgroundColor3 = Color3.fromRGB(38, 38, 46); s.LayoutOrder = i; s.Parent = grid
		corner(s, 8); stroke(s, Color3.fromRGB(60,60,72), 1)
		local tile = Instance.new("Frame")
		tile.Name = "Tile"; tile.Size = UDim2.new(1, -8, 1, -8); tile.Position = UDim2.fromOffset(4,4)
		tile.BackgroundTransparency = 1; tile.Visible = false; tile.Parent = s
		corner(tile, 6)
		local nameL = Instance.new("TextLabel")
		nameL.Name = "ItemName"; nameL.BackgroundTransparency = 1; nameL.Size = UDim2.new(1,-4,1,-4); nameL.Position = UDim2.fromOffset(2,2)
		nameL.Font = Enum.Font.GothamMedium; nameL.TextSize = 11; nameL.TextWrapped = true
		nameL.TextColor3 = Color3.fromRGB(255,255,255); nameL.Text = ""; nameL.Parent = tile
		local countL = Instance.new("TextLabel")
		countL.Name = "Count"; countL.BackgroundTransparency = 1; countL.Size = UDim2.new(1,-4,0,16)
		countL.Position = UDim2.new(0,0,1,-16); countL.Font = Enum.Font.GothamBold; countL.TextSize = 13
		countL.TextXAlignment = Enum.TextXAlignment.Right; countL.TextColor3 = Color3.fromRGB(255,255,255)
		countL.Text = ""; countL.Parent = tile
		slotFrames[i] = s
	end
end

local function refresh()
	if not currentProfile then return end
	goldLabel.Text = tostring(currentProfile.gold or 0)
	local maxSlots = currentProfile.maxSlots or 20
	local inv = currentProfile.inventory or {}
	if #slotFrames ~= maxSlots then buildSlots(maxSlots) end
	slotsLabel.Text = string.format("%d/%d", #inv, maxSlots)
	for i = 1, maxSlots do
		local s = slotFrames[i]
		if not s then continue end
		local tile = s:FindFirstChild("Tile")
		local entry = inv[i]
		if entry then
			local def = Items.get(entry.id)
			local rc = rarityColor(def and def.rarity or "gewoehnlich")
			tile.Visible = true; tile.BackgroundTransparency = 0.15
			tile.BackgroundColor3 = rc
			tile.ItemName.Text = def and def.name or entry.id
			tile.Count.Text = (entry.count and entry.count > 1) and ("x"..entry.count) or ""
			local st = s:FindFirstChildOfClass("UIStroke"); if st then st.Color = rc; st.Thickness = 1.5 end
		else
			tile.Visible = false
			local st = s:FindFirstChildOfClass("UIStroke"); if st then st.Color = Color3.fromRGB(60,60,72); st.Thickness = 1 end
		end
	end
end

local function toggleInv()
	panel.Visible = not panel.Visible
	if panel.Visible then refresh() end
end
invButton.Activated:Connect(toggleInv)
closeBtn.Activated:Connect(function() panel.Visible = false end)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.Tab then
		toggleInv()
	end
end)

ProfileUpdated.OnClientEvent:Connect(function(profile)
	currentProfile = profile
	refresh()
end)

-- ---------- Toasts ----------
local toastHolder = Instance.new("Frame")
toastHolder.BackgroundTransparency = 1; toastHolder.Size = UDim2.fromOffset(340, 300)
toastHolder.Position = UDim2.new(0.5, -170, 0, 70); toastHolder.Parent = gui
local tl = Instance.new("UIListLayout")
tl.HorizontalAlignment = Enum.HorizontalAlignment.Center; tl.VerticalAlignment = Enum.VerticalAlignment.Top
tl.Padding = UDim.new(0, 6); tl.SortOrder = Enum.SortOrder.LayoutOrder; tl.Parent = toastHolder

local kindColor = {
	good = Color3.fromRGB(70, 175, 95),
	warn = Color3.fromRGB(210, 140, 50),
	info = Color3.fromRGB(70, 110, 180),
}
local toastCount = 0
local function showToast(text, kind)
	toastCount += 1
	local t = Instance.new("TextLabel")
	t.LayoutOrder = toastCount; t.Size = UDim2.fromOffset(0, 34); t.AutomaticSize = Enum.AutomaticSize.X
	t.BackgroundColor3 = Color3.fromRGB(28, 28, 34); t.BackgroundTransparency = 0.05
	t.Font = Enum.Font.GothamMedium; t.TextSize = 15; t.TextColor3 = Color3.fromRGB(240,240,245)
	t.Text = "  " .. text .. "  "; t.Parent = toastHolder
	corner(t, 8); stroke(t, kindColor[kind] or kindColor.info, 2)
	t.BackgroundTransparency = 1; t.TextTransparency = 1
	TweenService:Create(t, TweenInfo.new(0.2), {BackgroundTransparency = 0.05, TextTransparency = 0}):Play()
	task.delay(2.6, function()
		local out = TweenService:Create(t, TweenInfo.new(0.4), {BackgroundTransparency = 1, TextTransparency = 1})
		out:Play(); out.Completed:Wait(); t:Destroy()
	end)
end
Notify.OnClientEvent:Connect(function(data)
	showToast(data.text, data.kind)
end)

print("[HUD] bereit")
