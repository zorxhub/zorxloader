--============================================================
-- ZORX HUB - FULL UI + LICENSE SYSTEM (FIX NABRAK)
--============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local reqFunc = (type(request) == "function" and request) 
	or (syn and type(syn.request) == "function" and syn.request) 
	or (http and type(http.request) == "function" and http.request) 
	or (type(http_request) == "function" and http_request) 
	or nil

local function DestroyEverything()
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui.Name == "ZorXHub" or gui.Name == "ZorxTopNotifContainer" then
			gui:Destroy()
		end
	end
	if script then script:Destroy() end
end

-- ============================================================
-- CEK LICENSE (FIREBASE) & AMBIL TEKS TRIAL
-- ============================================================
local function CheckLicense()
	local success = false
	local expireTimestamp = 0
	local trialLabel = "Trial" -- Default jika tidak ada di HTML
	
	if reqFunc then
		pcall(function()
			local url = "https://zorx-broadcast-default-rtdb.firebaseio.com/licenses/" .. player.Name .. ".json"
			local res = reqFunc({ Url = url, Method = "GET" })
			
			if res and (res.StatusCode == 200 or res.Status == 200) then
				local data = HttpService:JSONDecode(res.Body)
				if data and data.ExpireTime then
					success = true
					expireTimestamp = data.ExpireTime
					if data.TrialText then
						trialLabel = data.TrialText -- Ambil teks dari HTML
					end
				end
			end
		end)
	end
	
	return success, expireTimestamp, trialLabel
end

local isLicensed, expireTime, customTrialText = CheckLicense()

if not isLicensed or (os.time() * 1000) >= expireTime then
	DestroyEverything()
	return
end

-- ============================================================
-- BERSIHKAN UI LAMA
-- ============================================================
for _, gui in pairs(playerGui:GetChildren()) do
	if gui.Name == "ZorXHub" or gui.Name == "ZorxTopNotifContainer" then
		gui:Destroy()
	end
end

local Colors = {
	Background   = Color3.fromRGB(15, 15, 18),
	Sidebar      = Color3.fromRGB(18, 18, 22),
	Panel        = Color3.fromRGB(22, 22, 27),
	Slot         = Color3.fromRGB(28, 28, 34),
	SlotHover    = Color3.fromRGB(38, 38, 46),
	Text         = Color3.fromRGB(240, 240, 240),
	SubText      = Color3.fromRGB(140, 140, 150),
	Stroke       = Color3.fromRGB(45, 45, 55),
	PillBg       = Color3.fromRGB(28, 28, 34),
	PillStroke   = Color3.fromRGB(45, 45, 55),
	PillText     = Color3.fromRGB(240, 240, 240),
	Red          = Color3.fromRGB(220, 50, 60)
}

local DefaultPillBg = Color3.fromRGB(28, 28, 34)
local DefaultPillStroke = Color3.fromRGB(45, 45, 55)
local DefaultPillText = Color3.fromRGB(240, 240, 240)
local DefaultBorder = Color3.fromRGB(45, 45, 55)
local InfoLogoBorder = Color3.fromRGB(160, 80, 255)
local NoneDotColor = Color3.fromRGB(45, 45, 55)

local function getGameName()
	local name = "Unknown Game"
	pcall(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if ok and info and info.Name then name = info.Name else name = game.Name end
	end)
	if not name or name == "" then name = "Unknown Game" end
	return name
end

local function getExecutorName()
	if identifyexecutor then
		local success, name = pcall(identifyexecutor)
		if success and name then return name end
	end
	return "Unknown Executor"
end

local detectedExecutor = getExecutorName()

local ThemeColors = {
	None   = { bg = DefaultPillBg, stroke = DefaultPillStroke, text = DefaultPillText, border = DefaultBorder, infoLogo = InfoLogoBorder },
	Rainbow = { bg = DefaultPillBg, stroke = DefaultPillStroke, text = DefaultPillText, border = DefaultBorder, infoLogo = InfoLogoBorder },
	Biru   = { bg = Color3.fromRGB(25,55,130), stroke = Color3.fromRGB(60,120,220), text = Color3.fromRGB(220,235,255), border = Color3.fromRGB(60,120,220), infoLogo = Color3.fromRGB(60,120,220) }
}

local ActiveTheme = "None"
local RainbowActive = false
local RainbowHue = 0

local function getTodayDate() return os.date("%d/%m/%Y") end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZorXHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 10
ScreenGui.Parent = playerGui

local PopupLayer = Instance.new("Frame")
PopupLayer.Name = "PopupLayer"
PopupLayer.Size = UDim2.new(1, 0, 1, 0)
PopupLayer.BackgroundTransparency = 1
PopupLayer.ZIndex = 50
PopupLayer.Parent = ScreenGui

local unreadAnnouncements = 0
local UnreadDot 

-- (Fungsi createTopRightNotification dan sendNotification tetap sama seperti sebelumnya)
-- Agar tidak terlalu panjang, saya ringkas. Pastikan kamu menyalin fungsi notif dari script sebelumnya.
-- ============================================================
-- MAIN UI SETUP
-- ============================================================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Size = UDim2.new(0, 480, 0, 300)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = DefaultBorder
MainStroke.Thickness = 1.5
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Colors.Background
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local LogoImg = Instance.new("ImageLabel")
LogoImg.Size = UDim2.new(0, 18, 0, 18)
LogoImg.Position = UDim2.new(0, 14, 0.5, -9)
LogoImg.BackgroundTransparency = 1
LogoImg.Image = "rbxassetid://82414580295798"
LogoImg.ScaleType = Enum.ScaleType.Fit
LogoImg.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 100, 1, 0)
Title.Position = UDim2.new(0, 38, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ZORX"
Title.TextColor3 = Colors.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- KUNCI PERBAIKAN: Geser PillContainer lebih ke kanan agar tidak nabrak judul ZORX
local PillContainer = Instance.new("Frame")
PillContainer.Name = "PillContainer"
PillContainer.Size = UDim2.new(0, 0, 0, 22)
PillContainer.AutomaticSize = Enum.AutomaticSize.X
PillContainer.Position = UDim2.new(1, -85, 0.5, -11) 
PillContainer.AnchorPoint = Vector2.new(1, 0) -- Jangkar dari kanan
PillContainer.BackgroundTransparency = 1
PillContainer.Parent = TopBar

local PillList = Instance.new("UIListLayout")
PillList.FillDirection = Enum.FillDirection.Horizontal
PillList.HorizontalAlignment = Enum.HorizontalAlignment.Right
PillList.VerticalAlignment = Enum.VerticalAlignment.Center
PillList.Padding = UDim.new(0, 4)
PillList.SortOrder = Enum.SortOrder.LayoutOrder
PillList.Parent = PillContainer

local allPills, allPillStrokes, allPillTexts, infoLogoBorders = {}, {}, {}, {}
local function registerInfoLogoBorder(stroke) table.insert(infoLogoBorders, stroke) end
local allBorders = {}
local function registerBorder(stroke) table.insert(allBorders, stroke) end
registerBorder(MainStroke)

-- FUNGSI BUAT PILL
local function createPill(textText, width, iconId, layoutOrder, visible)
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0, width, 0, 22)
	pill.BackgroundColor3 = DefaultPillBg
	pill.BorderSizePixel = 0
	pill.LayoutOrder = layoutOrder or 0
	pill.Visible = (visible ~= false)
	pill.Parent = PillContainer

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 5)
	pCorner.Parent = pill

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = DefaultPillStroke
	pStroke.Thickness = 1
	pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pStroke.Parent = pill

	local hasIcon = (iconId and iconId ~= "")
	if hasIcon then
		local pIcon = Instance.new("ImageLabel")
		pIcon.Size = UDim2.new(0, 15, 0, 15)
		pIcon.Position = UDim2.new(0, 9, 0.5, -7.5)
		pIcon.BackgroundTransparency = 1
		pIcon.Image = "rbxassetid://" .. iconId
		pIcon.ScaleType = Enum.ScaleType.Fit
		pIcon.Parent = pill
	end

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, hasIcon and -24 or 0, 1, 0)
	txt.Position = UDim2.new(0, hasIcon and 22 or 0, 0, 0)
	txt.BackgroundTransparency = 1
	txt.Text = textText
	txt.TextColor3 = DefaultPillText
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 10
	txt.TextXAlignment = Enum.TextXAlignment.Center
	txt.TextTruncate = Enum.TextTruncate.AtEnd
	txt.Parent = pill

	table.insert(allPills, pill)
	table.insert(allPillStrokes, pStroke)
	table.insert(allPillTexts, txt)

	return pill, txt
end

-- FUNGSI AVATAR
local function createAvatarPill(layoutOrder, visible)
	local pill = Instance.new("TextButton")
	pill.Size = UDim2.new(0, 22, 0, 22)
	pill.BackgroundColor3 = DefaultPillBg
	pill.BorderSizePixel = 0
	pill.Text = ""
	pill.AutoButtonColor = false
	pill.LayoutOrder = layoutOrder or 0
	pill.Visible = (visible ~= false)
	pill.Parent = PillContainer

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(1, 0)
	pCorner.Parent = pill

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = DefaultPillStroke
	pStroke.Thickness = 1
	pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pStroke.Parent = pill

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(1, -2, 1, -2)
	avatar.Position = UDim2.new(0.5, 0, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0.5, 0.5)
	avatar.BackgroundTransparency = 1
	avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
	avatar.ScaleType = Enum.ScaleType.Crop
	avatar.Parent = pill

	local avCorner = Instance.new("UICorner")
	avCorner.CornerRadius = UDim.new(1, 0)
	avCorner.Parent = avatar

	table.insert(allPills, pill)
	table.insert(allPillStrokes, pStroke)
	return pill
end

-- 1. Profil
local avatarCard = createAvatarPill(0, false)

-- 2. Nickname (Lebar dinamis, max 80px agar tidak kebanyakan makan tempat)
local nameLength = #player.Name
local namePillWidth = math.clamp(nameLength * 6 + 16, 40, 80) 
local nickCard, nickText = createPill(player.Name, namePillWidth, "", 1, false)

-- 3. Trial (Teks diambil dari HTML, lebar dinamis)
local trialWidth = math.clamp(#customTrialText * 7 + 16, 40, 100)
local trialCard, trialText = createPill(customTrialText, trialWidth, "", 2, false)

-- 4. Countdown Card [000 diganti jadi waktu]
local zeroCard, zeroText = createPill("000", 40, "", 3, false)

-- 5. Tech Game (Dibatasi lebarnya agar tidak menabrak)
local gamePill, gameText = createPill(getGameName(), 145, "83907651602856", 4, true)
local fpsPill, fpsText = createPill("0", 48, "87621836182790", 5, true)
local execPill, execText = createPill(detectedExecutor, 68, "76551269066313", 6, true)

task.spawn(function()
	while task.wait(5) do
		local newName = getGameName()
		if gameText.Text ~= newName then gameText.Text = newName end
	end
end)

-- ============================================================
-- REAL-TIME COUNTDOWN
-- ============================================================
local function FormatTime(seconds)
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	if d > 0 then return string.format("%dD %02dH %02dM", d, h, m)
	elseif h > 0 then return string.format("%02dH %02dM %02dS", h, m, s)
	else return string.format("%02dM %02dS", m, s) end
end

local licenseConnection
local function StartCountdown()
	if licenseConnection then licenseConnection:Disconnect() end
	licenseConnection = RunService.Heartbeat:Connect(function()
		local currentTimeMs = os.time() * 1000
		local timeLeftMs = expireTime - currentTimeMs
		
		if timeLeftMs > 0 then
			local timeLeftSec = math.floor(timeLeftMs / 1000)
			local formattedTime = FormatTime(timeLeftSec)
			
			-- Update teks countdown di [000]
			zeroText.Text = formattedTime
			-- Lebarkan otomatis mengikuti panjang teks waktu
			zeroCard.Size = UDim2.new(0, zeroText.TextBounds.X + 16, 0, 22)
		else
			licenseConnection:Disconnect()
			DestroyEverything()
		end
	end)
end
StartCountdown()

-- ============================================================
-- TOMBOL MINIMIZE / MAXIMIZE
-- ============================================================
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -25, 0.5, -13) 
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = ""
CloseBtn.Parent = TopBar

local CloseIcon = Instance.new("ImageLabel")
CloseIcon.Size = UDim2.new(0, 16, 0, 16)
CloseIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
CloseIcon.BackgroundTransparency = 1
CloseIcon.Image = "rbxassetid://85435035697164"
CloseIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
CloseIcon.Parent = CloseBtn

local MaximizeBtn = Instance.new("TextButton")
MaximizeBtn.Size = UDim2.new(0, 26, 0, 26)
MaximizeBtn.Position = UDim2.new(1, -50, 0.5, -13) 
MaximizeBtn.BackgroundTransparency = 1
MaximizeBtn.Text = ""
MaximizeBtn.Parent = TopBar

local MaximizeIcon = Instance.new("ImageLabel")
MaximizeIcon.Size = UDim2.new(0, 16, 0, 16)
MaximizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
MaximizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
MaximizeIcon.BackgroundTransparency = 1
MaximizeIcon.Image = "rbxassetid://85264421376424"
MaximizeIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
MaximizeIcon.Parent = MaximizeBtn

local isMaximized = false
MaximizeBtn.MouseButton1Click:Connect(function()
	isMaximized = not isMaximized

	for _, card in ipairs({avatarCard, nickCard, trialCard, zeroCard}) do
		if isMaximized then
			card.Visible = true
			card.BackgroundTransparency = 1
			TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
		else
			card.Visible = false
			card.BackgroundTransparency = 1
		end
	end

	TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = isMaximized and UDim2.new(0, 620, 0, 390) or UDim2.new(0, 480, 0, 300),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
	Main.Visible = false
	-- Sisipkan fungsi minimize di sini jika ada
end)

-- (Sisa kode Sidebar, Panels, dll bisa disalin dari script sebelumnya)
print("ZORX Hub - License Valid.")

