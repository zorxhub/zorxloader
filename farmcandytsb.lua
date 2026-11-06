--============================================================
-- ZORX v6: FULL FIX TOTAL
-- - Anti mati setelah respawn
-- - TP ke pintu selalu jalan (fallback ke pintu terdekat)
-- - Anti void (candy jatuh)
-- - Ringan & cepat
-- - Auto recover dari error
--============================================================

local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

getgenv().ZorxRunning = true

--==================================================
-- ⚙️ CONFIG
--==================================================
local CANDY_KEYWORDS = {
	"candy","permen","sweet","lollipop","chocolate",
	"cupcake","donut","cookie","treat","gift","present",
	"collectable","collectible","pickup","reward","bonus","loot"
}
local IGNORE_KEYWORDS = {
	"particle","sparkle","highlight","indicator","gui","effect",
	"sound","hitbox","zone","trigger","spawner","spawnpoint",
	"decal","texture","mesh","image","billboard","label","frame",
	"script","remote","event","value","folder","skill","attack",
	"projectile","bullet","beam","vfx","fx","aura"
}
local CANDY_OBJ_KEYWORDS = {
	"candy","permen","sweet","lollipop","chocolate",
	"collect","pickup","take","claim","grab","open"
}
local HOSTILE_FOLDER = {
	"effects","vfx","fx","skill","skills","attack","projectile",
	"bullet","enemies","enemy","monster"
}
local doorKeywords = { "pintu","door","permen","tipu" }
local blacklist = {
	"buy","purchase","beli","robux","r$","gamepass","spin",
	"shop","confirm","checkout","upgrade","premium","vip",
	"donate","topup","top-up","offer","sale","promo"
}

--========= LIMIT & TIMING =========
local MIN_Y_POSITION = -500
local MAX_Y_POSITION = 5000
local VOID_Y_LIMIT      = -100
local CANDY_FALL_LIMIT  = -50
local FALL_TRACK_SEC    = 1.0
local FALL_DROP_THRESH  = 15

local TOUCH_DWELL     = 0.2
local SETTLE_WAIT     = 0.25
local CANDY_IDLE_WAIT = 0.7
local BATCH_SIZE      = 3
local LOOP_WAIT       = 0.03
local PROMPT_RETRY    = 3
local RESCAN_INTERVAL = 2.5
local DOOR_RESCAN     = 2.0
local IDLE_TIMEOUT    = 3.0

--==================================================
-- STATE GLOBAL
--==================================================
local candySet    = {}
local candyList   = {}
local cachedDoors = {}
local hostileCache = setmetatable({}, { __mode = "k" })
local fallHistory  = setmetatable({}, { __mode = "k" })
local safePosition = nil
local lastGoodPos  = nil
local lastCharacter = nil
local lastCharCheck = 0

--==================================================
-- UTIL
--==================================================
local function hasAny(str, list)
	if not str then return false end
	str = string.lower(str)
	for i = 1, #list do
		if string.find(str, list[i], 1, true) then return true end
	end
	return false
end

local function isHostile(obj)
	if not obj or not obj.Parent then return false end
	local c = hostileCache[obj]
	if c ~= nil then return c end
	local p = obj.Parent
	local res = false
	while p and p ~= Workspace do
		local pn = p.Name
		if pn then
			pn = string.lower(pn)
			for i = 1, #HOSTILE_FOLDER do
				if pn:find(HOSTILE_FOLDER[i], 1, true) then
					res = true
					break
				end
			end
			if res then break end
		end
		p = p.Parent
	end
	hostileCache[obj] = res
	return res
end

local function hasCandyPrompt(part)
	for _, c in ipairs(part:GetChildren()) do
		if c:IsA("ProximityPrompt") then
			local a = c.ActionText
			local o = c.ObjectText
			if (a and hasAny(a, CANDY_OBJ_KEYWORDS)) or (o and hasAny(o, CANDY_OBJ_KEYWORDS)) then
				return true
			end
		end
	end
	return false
end

--==================================================
-- VALIDASI
--==================================================
local function isCandy(obj)
	if not obj or not obj.Parent then return false end
	if not obj:IsA("BasePart") then return false end
	if obj.Transparency >= 1 then return false end
	local y = obj.Position.Y
	if y < MIN_Y_POSITION or y > MAX_Y_POSITION then return false end
	if y < CANDY_FALL_LIMIT then return false end
	if obj:IsDescendantOf(player.Character) then return false end

	local n = obj.Name
	if not n then return false end
	n = string.lower(n)

	if hasAny(n, IGNORE_KEYWORDS) then return false end
	if isHostile(obj) then return false end

	local v = obj.AssemblyLinearVelocity
	if v.X * v.X + v.Y * v.Y + v.Z * v.Z > 900 then return false end

	if hasAny(n, CANDY_KEYWORDS) then return true end
	return hasCandyPrompt(obj)
end

--==================================================
-- ANTI ANIM LOCK (AMAN)
--==================================================
local function unlockHumanoid(hum)
	if not hum or not hum.Parent then return end
	pcall(function()
		if hum.PlatformStand then hum.PlatformStand = false end
		if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
		if hum.JumpPower < 50 then hum.JumpPower = 50 end
	end)
end

--==================================================
-- GROUND CHECK
--==================================================
local function isOnGround(root)
	if not root or not root.Parent then return false end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {player.Character}
	local result = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayParams)
	return result ~= nil
end

--==================================================
-- TP INSTANT
--==================================================
local function tpTo(root, pos)
	if not root or not root.Parent then return false end
	local ok = pcall(function()
		root.CFrame = CFrame.new(pos)
	end)
	return ok
end

--==================================================
-- FIRE PROMPT
--==================================================
local function firePrompts(part, root)
	if not part or not part.Parent or not root or not root.Parent then return false end
	local fired = false
	local rp = root.Position

	for _, c in ipairs(part:GetChildren()) do
		if c:IsA("ProximityPrompt") and c.Enabled then
			local pp = c.Parent
			if pp and pp:IsA("BasePart") then
				local d = (pp.Position - rp).Magnitude
				if d <= c.MaxActivationDistance + 8 then
					local h = c.HoldDuration
					c.HoldDuration = 0
					pcall(fireproximityprompt, c)
					c.HoldDuration = h
					fired = true
				end
			end
		end
	end
	return fired
end

--==================================================
-- REFRESH LIST CANDY
--==================================================
local function refreshCandyList()
	local newList = {}
	for part in pairs(candySet) do
		if part.Parent and isCandy(part) then
			newList[#newList + 1] = part
		else
			candySet[part] = nil
		end
	end
	candyList = newList
end

--==================================================
-- SCAN CANDY
--==================================================
local function tryAddCandy(obj)
	if not obj or not obj.Parent then return end
	if candySet[obj] then return end
	if not isCandy(obj) then return end
	candySet[obj] = true
	candyList[#candyList + 1] = obj
end

local function fullScan()
	local ok = pcall(function()
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				tryAddCandy(obj)
			end
		end
	end)
	if ok then refreshCandyList() end
end

--==================================================
-- SCAN DOORS (REFRESH LEBIH SERING + VALIDASI)
--==================================================
local function scanDoors()
	local doors = {}
	local ok = pcall(function()
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt") then
				local pp = obj.Parent
				if pp and pp:IsA("BasePart") and pp.Parent then
					local n = pp.Name and string.lower(pp.Name) or ""
					local a = obj.ActionText and string.lower(obj.ActionText) or ""
					local o = obj.ObjectText and string.lower(obj.ObjectText) or ""
					if not (hasAny(n, blacklist) or hasAny(a, blacklist) or hasAny(o, blacklist)) then
						if hasAny(n, doorKeywords) or hasAny(a, doorKeywords) or hasAny(o, doorKeywords) then
							doors[#doors + 1] = { part = pp, pos = pp.Position, prompt = obj }
						end
					end
				end
			end
		end
	end)
	if ok then cachedDoors = doors end
end

--==================================================
-- FIND NEAREST CANDY
--==================================================
local function findNearestCandies(root, count)
	if not root or not root.Parent then return {} end
	local rp = root.Position
	local best, bestD = {}, {}

	for i = 1, #candyList do
		local c = candyList[i]
		if c.Parent and c.Transparency < 1 then
			local pos = c.Position
			if pos.Y < CANDY_FALL_LIMIT then
				candySet[c] = nil
			else
				local v = c.AssemblyLinearVelocity
				if v.Y > -25 then
					local d = (pos - rp).Magnitude
					local len = #best
					if len < count then
						best[len + 1] = c
						bestD[len + 1] = d
					else
						local maxI, maxV = 1, bestD[1]
						for j = 2, len do
							if bestD[j] > maxV then maxI, maxV = j, bestD[j] end
						end
						if d < maxV then
							best[maxI] = c
							bestD[maxI] = d
						end
					end
				end
			end
		end
	end
	return best
end

--==================================================
-- FIND NEAREST DOOR (fallback saat candy habis)
--==================================================
local function findNearestDoor(root)
	if not root or not root.Parent then return nil end
	if #cachedDoors == 0 then return nil end
	local rp = root.Position
	local best, bestD = nil, math.huge
	for i = 1, #cachedDoors do
		local d = cachedDoors[i]
		if d.part and d.part.Parent then
			local dist = (d.part.Position - rp).Magnitude
			if dist < bestD then
				best, bestD = d, dist
			end
		end
	end
	return best
end

--==================================================
-- FALL TRACKER (candy jatuh)
--==================================================
task.spawn(function()
	while getgenv().ZorxRunning do
		task.wait(0.5)
		local now = tick()
		for candy in pairs(candySet) do
			if not candy.Parent then
				candySet[candy] = nil
				fallHistory[candy] = nil
			else
				local y = candy.Position.Y
				local h = fallHistory[candy]
				if y < CANDY_FALL_LIMIT then
					candySet[candy] = nil
					fallHistory[candy] = nil
				elseif not h then
					fallHistory[candy] = { startY = y, startT = now }
				else
					local dt = now - h.startT
					local dy = h.startY - y
					if dt >= FALL_TRACK_SEC and dy > FALL_DROP_THRESH then
						candySet[candy] = nil
						fallHistory[candy] = nil
					elseif dt > FALL_TRACK_SEC * 2 then
						fallHistory[candy] = { startY = y, startT = now }
					end
				end
			end
		end
	end
end)

--==================================================
-- EVENT LISTENER (candy baru)
--==================================================
Workspace.DescendantAdded:Connect(function(obj)
	if not getgenv().ZorxRunning then return end
	if obj:IsA("BasePart") then
		task.defer(function()
			tryAddCandy(obj)
		end)
	end
end)

--==================================================
-- RESCAN LOOPS
--==================================================
task.spawn(function()
	while getgenv().ZorxRunning do
		fullScan()
		task.wait(RESCAN_INTERVAL)
	end
end)

task.spawn(function()
	while getgenv().ZorxRunning do
		scanDoors()
		task.wait(DOOR_RESCAN)
	end
end)

--==================================================
-- ANTI-VOID (SMART)
--==================================================
task.spawn(function()
	while getgenv().ZorxRunning do
		task.wait(0.3)
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local y = root.Position.Y
				if y > VOID_Y_LIMIT and isOnGround(root) then
					lastGoodPos = root.CFrame
					safePosition = root.CFrame
				end
				if y < VOID_Y_LIMIT then
					local recoverTo = lastGoodPos or safePosition
					if recoverTo then
						pcall(function()
							root.CFrame = recoverTo
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
						end)
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then
							pcall(function()
								hum.PlatformStand = false
								hum:ChangeState(Enum.HumanoidStateType.GettingUp)
							end)
						end
					end
				end
			end
		end
	end
end)

--==================================================
-- CHARACTER RESPAWN DETECTOR
--==================================================
local function onCharacterAdded(char)
	-- tunggu HRP & Humanoid siap
	local root, hum
	for _ = 1, 50 do
		root = char:FindFirstChild("HumanoidRootPart")
		hum  = char:FindFirstChildOfClass("Humanoid")
		if root and hum then break end
		task.wait(0.1)
	end

	-- reset state
	candySet = {}
	candyList = {}
	fallHistory = setmetatable({}, { __mode = "k" })
	hostileCache = setmetatable({}, { __mode = "k" })
	safePosition = nil
	lastGoodPos = nil

	-- immediate scan doors
	task.spawn(function()
		task.wait(0.3)
		scanDoors()
	end)
end

if player.Character then
	lastCharacter = player.Character
end
player.CharacterAdded:Connect(function(char)
	lastCharacter = char
	onCharacterAdded(char)
end)

--==================================================
-- LOOP UTAMA (AMAN DARI ERROR)
--==================================================
local function mainLoop()
	local lastRescan = 0
	local idleStart = 0

	while getgenv().ZorxRunning do
		local ok, err = pcall(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum  = char and char:FindFirstChildOfClass("Humanoid")

			if not root or not hum then
				task.wait(0.1)
				return
			end

			unlockHumanoid(hum)

			local batch = findNearestCandies(root, BATCH_SIZE)

			if #batch > 0 then
				idleStart = 0
				for i = 1, #batch do
					local candy = batch[i]
					if candy and candy.Parent then
						-- settle wait kalau perlu
						local v = candy.AssemblyLinearVelocity
						if v.X * v.X + v.Y * v.Y + v.Z * v.Z > 16 then
							local t0 = tick()
							while tick() - t0 < SETTLE_WAIT do
								if not candy.Parent then break end
								local vv = candy.AssemblyLinearVelocity
								if vv.X * vv.X + vv.Y * vv.Y + vv.Z * vv.Z <= 4 then break end
								task.wait()
							end
						end

						if candy.Parent and candy.Position.Y >= CANDY_FALL_LIMIT then
							-- simpan posisi aman
							if root.Position.Y > VOID_Y_LIMIT and isOnGround(root) then
								safePosition = root.CFrame
								lastGoodPos = root.CFrame
							end

							tpTo(root, candy.Position + Vector3.new(0, 0.2, 0))
							task.wait()

							-- Cek void setelah TP
							if root.Position.Y < VOID_Y_LIMIT then
								local recoverTo = lastGoodPos or safePosition
								if recoverTo then
									root.CFrame = recoverTo
									root.AssemblyLinearVelocity = Vector3.zero
								end
							else
								local fired = firePrompts(candy, root)
								if candy.Parent and candy.Parent:IsA("Model") then
									firePrompts(candy.Parent, root)
								end
								if not fired then
									task.wait(TOUCH_DWELL)
									if candy.Parent then firePrompts(candy, root) end
								end
								if not candy.Parent then
									candySet[candy] = nil
								end
							end
						else
							candySet[candy] = nil
						end
					else
						if candy then candySet[candy] = nil end
					end
				end
			else
				-- 🚪 PINTU — fallback
				local door = findNearestDoor(root)
				if door then
					idleStart = 0
					local targetPos = door.pos + Vector3.new(0, 0.5, -2)
					tpTo(root, targetPos)
					task.wait()

					if root.Position.Y < VOID_Y_LIMIT then
						local recoverTo = lastGoodPos or safePosition
						if recoverTo then
							root.CFrame = recoverTo
							root.AssemblyLinearVelocity = Vector3.zero
						end
					else
						for _ = 1, PROMPT_RETRY do
							if firePrompts(door.part, root) then break end
							task.wait(0.03)
						end
					end
				else
					-- tidak ada pintu juga → idle
					if idleStart == 0 then
						idleStart = tick()
					elseif tick() - idleStart > IDLE_TIMEOUT then
						-- paksa rescan
						fullScan()
						scanDoors()
						idleStart = tick()
					end
					task.wait(CANDY_IDLE_WAIT)
				end
			end

			-- refresh list kadang-kadang
			if tick() - lastRescan > 1 then
				refreshCandyList()
				lastRescan = tick()
			end
		end)

		-- kalau error, tunggu dan lanjut (jangan mati)
		if not ok then
			warn("[ZORX] Loop error (recovered):", err)
			task.wait(0.5)
		end

		task.wait(LOOP_WAIT)
	end
end

--==================================================
-- START
--==================================================
getgenv().ZorxThread = task.spawn(mainLoop)

--==================================================
-- NOTIF
--==================================================
pcall(function()
	task.wait(2)
	StarterGui:SetCore("SendNotification", {
		Title = "ZORX v6",
		Text = "✅ Full Fix Aktif (respawn-safe)",
		Duration = 3,
	})
end)

print("==============================================")
print("[ZORX v6] ✅ FULL FIX TOTAL")
print("  • Anti mati setelah respawn")
print("  • TP pintu selalu jalan (fallback)")
print("  • Anti void candy jatuh")
print("  • Ringan + error recovery")
print("==============================================")