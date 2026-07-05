--!strict
-- Teleportiert Spieler zwischen Zonen. Portale sind Parts mit dem Tag "Portal"
-- und einem Vector3-Attribut "TeleportTo".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local PortalSystem = {}

local COOLDOWN = 2
local lastUse: { [Player]: number } = {}

local function onTouched(portal: BasePart, hit: BasePart)
	local char = hit.Parent
	if not char then return end
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end

	local now = os.clock()
	if lastUse[player] and now - lastUse[player] < COOLDOWN then return end
	lastUse[player] = now

	local target = portal:GetAttribute("TeleportTo")
	if typeof(target) ~= "Vector3" then return end
	root.CFrame = CFrame.new(target)
end

local function hookPortal(portal: Instance)
	if portal:IsA("BasePart") then
		portal.Touched:Connect(function(hit)
			onTouched(portal, hit)
		end)
	end
end

function PortalSystem.init()
	for _, p in ipairs(CollectionService:GetTagged("Portal")) do
		hookPortal(p)
	end
	CollectionService:GetInstanceAddedSignal("Portal"):Connect(hookPortal)
	Players.PlayerRemoving:Connect(function(pl) lastUse[pl] = nil end)
	print("[PortalSystem] initialisiert (" .. #CollectionService:GetTagged("Portal") .. " Portale).")
end

return PortalSystem
