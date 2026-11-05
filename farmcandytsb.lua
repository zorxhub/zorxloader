-- ==================================================
-- ZORX - AUTO TP PINTU (STEALTH / NO SERVER LOG)
-- ==================================================

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ==================================================
-- KONFIGURASI
-- ==================================================
local doorKeywords = { "pintu", "door", "permen", "tipu" }
local blacklist    = {
    "buy","purchase","beli","robux","r$","gamepass","spin",
    "shop","confirm","checkout","upgrade","premium","vip",
    "donate","topup","top-up","offer","sale","promo"
}

-- Anti-log tuning
local TP_OFFSET       = Vector3.new(0, 0.5, -2)   -- jarak wajar dari pintu
local MOVE_DURATION   = 0.08                       -- durasi "glide" antar pintu (detik)
local PROMPT_WAIT     = 0.12                       -- jeda sebelum fire prompt
local LOOP_WAIT       = 0.25                       -- jeda antar siklus

-- Thread control
if getgenv().ZorxThread then
    task.cancel(getgenv().ZorxThread)
    getgenv().ZorxThread = nil
end
getgenv().ZorxRunning = true

-- ==================================================
-- HELPER
-- ==================================================
local function hasBlacklist(str)
    if not str then return false end
    str = string.lower(str)
    for _, bl in ipairs(blacklist) do
        if str:find(bl, 1, true) then return true end
    end
    return false
end

local function hasKeyword(str)
    if not str then return false end
    str = string.lower(str)
    for _, kw in ipairs(doorKeywords) do
        if str:find(kw, 1, true) then return true end
    end
    return false
end

local function collectAllDoors()
    local doors = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local n = string.lower(parent.Name or "")
                local a = string.lower(obj.ActionText or "")
                local o = string.lower(obj.ObjectText or "")

                if not (hasBlacklist(n) or hasBlacklist(a) or hasBlacklist(o)) then
                    if hasKeyword(n) or hasKeyword(a) or hasKeyword(o) then
                        -- JANGAN ubah properti prompt secara agresif.
                        -- Perubahan mendadak (HoldDuration=0, distance besar)
                        -- bisa ke-flag anti-cheat server.
                        table.insert(doors, {
                            part   = parent,
                            pos    = parent.Position,
                            prompt = obj
                        })
                    end
                end
            end
        end
    end
    return doors
end

local function stopAnimations(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end
end

-- ==================================================
-- GLIDE MOVE (biar tidak kelihatan teleport instan)
-- ==================================================
local function glideTo(root, targetPos)
    local startPos = root.Position
    local t0 = tick()
    local conn

    conn = RunService.Heartbeat:Connect(function()
        local alpha = math.clamp((tick() - t0) / MOVE_DURATION, 0, 1)
        local eased = alpha * alpha * (3 - 2 * alpha) -- smoothstep
        local newPos = startPos:Lerp(targetPos, eased)

        -- Set langsung ke CFrame (jangan pakai BodyVelocity — itu flag)
        local cf = root.CFrame
        root.CFrame = CFrame.new(newPos) * (cf - cf.Position)
        root.AssemblyLinearVelocity  = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        if alpha >= 1 then
            conn:Disconnect()
        end
    end)
end

-- ==================================================
-- LOGIK UTAMA (STEALTH)
-- ==================================================
local function executeStealth()
    if not getgenv().ZorxRunning then return end

    local char = player.Character
    if not char then
        task.wait(LOOP_WAIT)
        getgenv().ZorxThread = task.spawn(executeStealth)
        return
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        task.wait(LOOP_WAIT)
        getgenv().ZorxThread = task.spawn(executeStealth)
        return
    end

    local doors = collectAllDoors()
    if #doors == 0 then
        task.wait(0.5)
        getgenv().ZorxThread = task.spawn(executeStealth)
        return
    end

    local doorData = doors[1]

    -- 1. Stop animasi (biar tidak glitch saat glide)
    stopAnimations(char)

    -- 2. Glide halus ke depan pintu (bukan teleport instan)
    local targetPos = doorData.pos + TP_OFFSET
    glideTo(root, targetPos)

    -- Tunggu glide selesai
    task.wait(MOVE_DURATION + 0.02)

    -- 3. Fire prompt (native, tanpa ubah properti prompt)
    local prompt = doorData.prompt
    if prompt and prompt.Parent and prompt.Enabled then
        pcall(fireproximityprompt, prompt)
    end

    -- 4. Jeda sebelum siklus berikutnya (biar tidak spam)
    task.wait(PROMPT_WAIT + LOOP_WAIT)

    -- Lanjut
    if getgenv().ZorxRunning then
        getgenv().ZorxThread = task.spawn(executeStealth)
    end
end

-- ==================================================
-- JALANKAN
-- ==================================================
getgenv().ZorxThread = task.spawn(executeStealth)