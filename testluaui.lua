--============================================================
-- ZORX HUB - FULL UI + LICENSE SYSTEM (UTUH SEMPURNA)
--============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Penanganan fungsi HTTP Request
local reqFunc = (type(request) == "function" and request) 
	or (syn and type(syn.request) == "function" and syn.request) 
	or (http and type(http.request) == "function" and http.request) 
	or (type(http_request) == "function" and http_request) 
	or nil

-- ============================================================
-- SYSTEM BLOKIR / DESTROY
-- ============================================================
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
	local trialLabel = "Trial" 
	
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
						trialLabel = data.TrialText 
					end
				end
			end
		end)
	end
	
	return success, expireTimestamp, trialLabel
end

local isLicensed, expireTime, customTrialText = CheckLicense()

if not isLicensed or (os.time() * 1000) >= expireTime then
	warn("Lisensi tidak ditemukan atau sudah expired!")
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
		if ok and info and info.Name then
			name = info.Name
		else
			name = game.Name
		end
	end)
	if not name or name == "" then name = "Unknown Game" end
	return name
end

local function getExecutorName()
	if identifyexecutor then
		local success, name = pcall(identifyexecutor)
		if success and name then return name end
	elseif getexecutorname then
		local success, name = pcall(getexecutorname)
		if success and name then return name end
	end
	if syn then return "Synapse X"
	elseif fluxus then return "Fluxus"
	elseif hydrogen then return "Hydrogen"
	elseif delta or (identifyexecutor and pcall(identifyexecutor) and string.find(string.lower(identifyexecutor()), "delta")) then return "Delta"
	elseif codex then return "Codex"
	elseif arceus then return "Arceus X"
	elseif solara then return "Solara"
	elseif wave then return "Wave"
	else return "Unknown Executor" end
end

local detectedExecutor = getExecutorName()
print("Executor yang terdeteksi: " .. detectedExecutor)

local ThemeColors = {
	None   = { bg = DefaultPillBg,       stroke = DefaultPillStroke,           text = DefaultPillText,           border = DefaultBorder,  infoLogo = InfoLogoBorder },
	Biru   = { bg = Color3.fromRGB(25,55,130),   stroke = Color3.fromRGB(60,120,220),  text = Color3.fromRGB(220,235,255), border = Color3.fromRGB(60,120,220),  infoLogo = Color3.fromRGB(60,120,220) },
	Ungu   = { bg = Color3.fromRGB(80,35,130),   stroke = Color3.fromRGB(160,90,220),  text = Color3.fromRGB(235,220,255), border = Color3.fromRGB(160,90,220),  infoLogo = Color3.fromRGB(160,90,220) },
	Hijau  = { bg = Color3.fromRGB(25,100,50),   stroke = Color3.fromRGB(60,180,90),   text = Color3.fromRGB(220,255,225), border = Color3.fromRGB(60,180,90),   infoLogo = Color3.fromRGB(60,180,90) },
	Kuning = { bg = Color3.fromRGB(140,120,25),  stroke = Color3.fromRGB(220,200,60),  text = Color3.fromRGB(255,250,215), border = Color3.fromRGB(220,200,60),  infoLogo = Color3.fromRGB(220,200,60) },
	Oren   = { bg = Color3.fromRGB(150,75,20),   stroke = Color3.fromRGB(230,140,50),  text = Color3.fromRGB(255,235,215), border = Color3.fromRGB(230,140,50),  infoLogo = Color3.fromRGB(230,140,50) },
	Merah  = { bg = Color3.fromRGB(130,25,30),   stroke = Color3.fromRGB(220,60,70),   text = Color3.fromRGB(255,220,220), border = Color3.fromRGB(220,60,70),   infoLogo = Color3.fromRGB(220,60,70) },
	Pink   = { bg = Color3.fromRGB(140,40,90),   stroke = Color3.fromRGB(230,100,160), text = Color3.fromRGB(255,225,240), border = Color3.fromRGB(230,100,160), infoLogo = Color3.fromRGB(230,100,160) },
	Cyan   = { bg = Color3.fromRGB(20,100,110),  stroke = Color3.fromRGB(60,200,210),  text = Color3.fromRGB(215,250,255), border = Color3.fromRGB(60,200,210),  infoLogo = Color3.fromRGB(60,200,210) },
	Putih  = { bg = Color3.fromRGB(180,180,185), stroke = Color3.fromRGB(240,240,245), text = Color3.fromRGB(30,30,35),    border = Color3.fromRGB(240,240,245), infoLogo = Color3.fromRGB(240,240,245) },
	Hitam  = { bg = Color3.fromRGB(15,15,18),    stroke = Color3.fromRGB(50,50,55),    text = Color3.fromRGB(240,240,240), border = Color3.fromRGB(50,50,55),    infoLogo = Color3.fromRGB(50,50,55) },
	Emas   = { bg = Color3.fromRGB(140,100,20),  stroke = Color3.fromRGB(230,190,60),  text = Color3.fromRGB(255,245,210), border = Color3.fromRGB(230,190,60),  infoLogo = Color3.fromRGB(230,190,60) },
	Abu    = { bg = Color3.fromRGB(60,60,70),    stroke = Color3.fromRGB(120,120,135), text = Color3.fromRGB(240,240,240), border = Color3.fromRGB(120,120,135), infoLogo = Color3.fromRGB(120,120,135) },
	Lime   = { bg = Color3.fromRGB(80,140,25),   stroke = Color3.fromRGB(160,230,60),  text = Color3.fromRGB(240,255,215), border = Color3.fromRGB(160,230,60),  infoLogo = Color3.fromRGB(160,230,60) },
	Marun  = { bg = Color3.fromRGB(80,20,30),    stroke = Color3.fromRGB(150,50,60),   text = Color3.fromRGB(255,220,220), border = Color3.fromRGB(150,50,60),   infoLogo = Color3.fromRGB(150,50,60) },
	Navy   = { bg = Color3.fromRGB(15,25,70),    stroke = Color3.fromRGB(45,70,150),   text = Color3.fromRGB(215,225,255), border = Color3.fromRGB(45,70,150),   infoLogo = Color3.fromRGB(45,70,150) },
	Rainbow = { bg = DefaultPillBg, stroke = DefaultPillStroke, text = DefaultPillText, border = DefaultBorder, infoLogo = InfoLogoBorder },
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

-- ============================================================
-- NOTIFIKASI SYSTEM
-- ============================================================
local function createTopRightNotification(titleText, messageText, iconId, duration)
	duration = duration or 6
	local container = playerGui:FindFirstChild("ZorxTopNotifContainer")
	if not container then
		container = Instance.new("ScreenGui")
		container.Name = "ZorxTopNotifContainer"
		container.ResetOnSpawn = false
		container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		container.IgnoreGuiInset = true
		container.DisplayOrder = 999
		container.Parent = playerGui
	end
	
	local notif = Instance.new("Frame")
	notif.Name = "TopNotif"
	notif.Size = UDim2.new(0, 360, 0, 68) 
	notif.Position = UDim2.new(1, -20, 0, -100) 
	notif.AnchorPoint = Vector2.new(1, 0)
	notif.BackgroundColor3 = Color3.fromRGB(15, 15, 18) 
	notif.BorderSizePixel = 0
	notif.ClipsDescendants = true
	notif.ZIndex = 1000
	notif.Parent = container

	local nCorner = Instance.new("UICorner")
	nCorner.CornerRadius = UDim.new(0, 8)
	nCorner.Parent = notif

	local nStroke = Instance.new("UIStroke")
	nStroke.Color = Color3.fromRGB(45, 45, 55)
	nStroke.Thickness = 1.5
	nStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	nStroke.Parent = notif

	local nIcon = Instance.new("ImageLabel")
	nIcon.Size = UDim2.new(0, 36, 0, 36)
	nIcon.Position = UDim2.new(0, 8, 0, 8)
	nIcon.BackgroundTransparency = 1
	nIcon.Image = "rbxassetid://" .. tostring(iconId or "134572030759999")
	nIcon.ScaleType = Enum.ScaleType.Fit
	nIcon.ZIndex = 1002
	nIcon.Parent = notif

	local nTitle = Instance.new("TextLabel")
	nTitle.Size = UDim2.new(1, -75, 0, 14)
	nTitle.Position = UDim2.new(0, 52, 0, 8)
	nTitle.BackgroundTransparency = 1
	nTitle.Text = titleText or "System Announcement"
	nTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	nTitle.Font = Enum.Font.GothamBold
	nTitle.TextSize = 12
	nTitle.TextXAlignment = Enum.TextXAlignment.Left
	nTitle.ZIndex = 1001
	nTitle.Parent = notif

	local nDesc = Instance.new("TextLabel")
	nDesc.Size = UDim2.new(1, -65, 0, 14)
	nDesc.Position = UDim2.new(0, 52, 0, 26)
	nDesc.BackgroundTransparency = 1
	nDesc.Text = messageText or "Pesan..."
	nDesc.TextColor3 = Color3.fromRGB(200, 200, 210)
	nDesc.Font = Enum.Font.GothamMedium
	nDesc.TextSize = 10
	nDesc.TextXAlignment = Enum.TextXAlignment.Left
	nDesc.TextYAlignment = Enum.TextYAlignment.Center
	nDesc.TextWrapped = false
	nDesc.TextTruncate = Enum.TextTruncate.AtEnd
	nDesc.ZIndex = 1001
	nDesc.Parent = notif

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 18, 0, 18)
	closeBtn.Position = UDim2.new(1, -22, 0, 5)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = ""
	closeBtn.AutoButtonColor = false
	closeBtn.ZIndex = 1002
	closeBtn.Parent = notif

	local closeIcon = Instance.new("ImageLabel")
	closeIcon.Size = UDim2.new(0, 9, 0, 9)
	closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.BackgroundTransparency = 1
	closeIcon.Image = "rbxassetid://85435035697164"
	closeIcon.ImageColor3 = Color3.fromRGB(170, 170, 180)
	closeIcon.ScaleType = Enum.ScaleType.Fit
	closeIcon.ZIndex = 1003
	closeIcon.Parent = closeBtn

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -16, 0, 3) 
	barBg.Position = UDim2.new(0, 8, 1, -8)
	barBg.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	barBg.BorderSizePixel = 0
	barBg.ZIndex = 1001
	barBg.Parent = notif

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	barFill.BorderSizePixel = 0
	barFill.ZIndex = 1002
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = barFill

	TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -20, 0, 20)
	}):Play()

	TweenService:Create(barFill, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()

	local function dismiss()
		local slideUp = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Position = UDim2.new(1, -20, 0, -100)
		})
		slideUp:Play()
		slideUp.Completed:Connect(function()
			notif:Destroy()
		end)
	end

	closeBtn.MouseButton1Click:Connect(dismiss)
	task.delay(duration, function() if notif and notif.Parent then dismiss() end end)
end

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

local allBorders = {}
local function registerBorder(stroke) table.insert(allBorders, stroke) end
registerBorder(MainStroke)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 45, 0, 45)
MinimizeBtn.Position = UDim2.new(0.5, -22, 0.5, -22)
MinimizeBtn.BackgroundColor3 = Colors.Background
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "Z"
MinimizeBtn.TextColor3 = Colors.Text
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 26
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Visible = false
MinimizeBtn.Active = true
MinimizeBtn.Draggable = true
MinimizeBtn.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 10)
MiniCorner.Parent = MinimizeBtn

local MinimizeStroke = Instance.new("UIStroke")
MinimizeStroke.Color = DefaultBorder
MinimizeStroke.Thickness = 1
MinimizeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MinimizeStroke.Parent = MinimizeBtn
registerBorder(MinimizeStroke)

local function setUIOpen(open)
	Main.Visible = open
	PopupLayer.Visible = open
	MinimizeBtn.Visible = not open
end

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Colors.Background
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local LogoImg = Instance.new("ImageLabel")
LogoImg.Size = UDim2.new(0, 18, 0, 18)
LogoImg.Position = UDim2.new(0, 14, 0.5, -9)
LogoImg.BackgroundTransparency = 1
LogoImg.Image = "rbxassetid://82414580295798"
LogoImg.ScaleType = Enum.ScaleType.Fit
LogoImg.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0, 100, 1, 0)
Title.Position = UDim2.new(0, 38, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ZORX"
Title.TextColor3 = Colors.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- CONTAINER PILL UTAMA
local PillContainer = Instance.new("Frame")
PillContainer.Name = "PillContainer"
PillContainer.Size = UDim2.new(0, 0, 0, 22)
PillContainer.AutomaticSize = Enum.AutomaticSize.X
PillContainer.Position = UDim2.new(1, -85, 0.5, -11) 
PillContainer.AnchorPoint = Vector2.new(1, 0)
PillContainer.BackgroundTransparency = 1
PillContainer.Parent = TopBar

local PillList = Instance.new("UIListLayout")
PillList.FillDirection = Enum.FillDirection.Horizontal
PillList.HorizontalAlignment = Enum.HorizontalAlignment.Right
PillList.VerticalAlignment = Enum.VerticalAlignment.Center
PillList.Padding = UDim.new(0, 4)
PillList.SortOrder = Enum.SortOrder.LayoutOrder
PillList.Parent = PillContainer

local allPills = {}
local allPillStrokes = {}
local allPillTexts = {}
local infoLogoBorders = {}

local function registerInfoLogoBorder(stroke) table.insert(infoLogoBorders, stroke) end

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

	pill.MouseButton1Click:Connect(function()
		local profileUrl = "https://www.roblox.com/users/" .. player.UserId .. "/profile"
		pcall(function()
			if setclipboard then setclipboard(profileUrl)
			elseif toclipboard then toclipboard(profileUrl) end
		end)
		createTopRightNotification("Profile Link", "Link profil berhasil di-copy!", "82414580295798", 4)
	end)

	table.insert(allPills, pill)
	table.insert(allPillStrokes, pStroke)
	return pill
end

-- PEMBUATAN PILL
local avatarCard = createAvatarPill(0, false)

local nameLength = #player.Name
local namePillWidth = math.clamp(nameLength * 6 + 16, 40, 80) 
local nickCard, nickText = createPill(player.Name, namePillWidth, "", 1, false)

local trialWidth = math.clamp(#customTrialText * 7 + 16, 40, 100)
local trialCard, trialText = createPill(customTrialText, trialWidth, "", 2, false)

local zeroCard, zeroText = createPill("000", 40, "", 3, false)

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
			
			zeroText.Text = formattedTime
			zeroCard.Size = UDim2.new(0, zeroText.TextBounds.X + 16, 0, 22)
		else
			licenseConnection:Disconnect()
			DestroyEverything()
		end
	end)
end
StartCountdown()

-- ============================================================
-- TOMBOL LONCENG, MINIMIZE, MAXIMIZE
-- ============================================================
local AnnouncBtn = Instance.new("TextButton")
AnnouncBtn.Name = "AnnouncBtn"
AnnouncBtn.Size = UDim2.new(0, 24, 0, 24)
AnnouncBtn.Position = UDim2.new(1, -75, 0.5, -12)
AnnouncBtn.BackgroundTransparency = 1
AnnouncBtn.Text = ""
AnnouncBtn.AutoButtonColor = false
AnnouncBtn.Parent = TopBar

local AnnouncIcon = Instance.new("ImageLabel")
AnnouncIcon.Size = UDim2.new(0, 18, 0, 18)
AnnouncIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
AnnouncIcon.AnchorPoint = Vector2.new(0.5, 0.5)
AnnouncIcon.BackgroundTransparency = 1
AnnouncIcon.Image = "rbxassetid://86611648211571"
AnnouncIcon.ScaleType = Enum.ScaleType.Fit
AnnouncIcon.Parent = AnnouncBtn

UnreadDot = Instance.new("Frame")
UnreadDot.Size = UDim2.new(0, 8, 0, 8)
UnreadDot.Position = UDim2.new(1, -6, 0, 0)
UnreadDot.BackgroundColor3 = Colors.Red
UnreadDot.BorderSizePixel = 0
UnreadDot.Visible = false
UnreadDot.ZIndex = 10
UnreadDot.Parent = AnnouncBtn
Instance.new("UICorner").Parent = UnreadDot

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
MaximizeIcon.ScaleType = Enum.ScaleType.Fit
MaximizeIcon.Parent = MaximizeBtn

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
CloseIcon.ScaleType = Enum.ScaleType.Fit
CloseIcon.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function() setUIOpen(false) end)
MinimizeBtn.MouseButton1Click:Connect(function() setUIOpen(true) end)

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

local frameCount = 0
local lastTime = tick()
RunService.RenderStepped:Connect(function()
	frameCount = frameCount + 1
	if tick() - lastTime >= 1 then
		fpsText.Text = tostring(frameCount)
		frameCount = 0
		lastTime = tick()
	end
end)

local TopDivider = Instance.new("Frame")
TopDivider.Size = UDim2.new(1, 0, 0, 1)
TopDivider.Position = UDim2.new(0, 0, 0, 32)
TopDivider.BackgroundColor3 = DefaultBorder
TopDivider.BorderSizePixel = 0
TopDivider.Parent = Main

-- ============================================================
-- SIDEBAR & CONTENT
-- ============================================================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 120, 1, -33)
Sidebar.Position = UDim2.new(0, 0, 0, 33)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local SidebarPad = Instance.new("UIPadding")
SidebarPad.PaddingTop = UDim.new(0, 8)
SidebarPad.PaddingLeft = UDim.new(0, 6)
SidebarPad.PaddingRight = UDim.new(0, 6)
SidebarPad.PaddingBottom = UDim.new(0, 8)
SidebarPad.Parent = Sidebar

local SearchContainer = Instance.new("Frame")
SearchContainer.Size = UDim2.new(1, 0, 0, 26)
SearchContainer.BackgroundColor3 = Colors.Slot
SearchContainer.BorderSizePixel = 0
SearchContainer.Parent = Sidebar

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 5)
SearchCorner.Parent = SearchContainer

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = DefaultBorder
SearchStroke.Thickness = 1
SearchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SearchStroke.Parent = SearchContainer
registerBorder(SearchStroke)

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -10, 1, 0)
SearchBox.Position = UDim2.new(0, 5, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search..."
SearchBox.PlaceholderColor3 = Colors.SubText
SearchBox.TextColor3 = Colors.Text
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 10
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchContainer

local SidebarButtonContainer = Instance.new("Frame")
SidebarButtonContainer.Size = UDim2.new(1, 0, 1, -66)
SidebarButtonContainer.Position = UDim2.new(0, 0, 0, 34)
SidebarButtonContainer.BackgroundTransparency = 1
SidebarButtonContainer.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 2)
SidebarList.Parent = SidebarButtonContainer

local SidebarDivider = Instance.new("Frame")
SidebarDivider.Size = UDim2.new(0, 1, 1, -33)
SidebarDivider.Position = UDim2.new(0, 120, 0, 33)
SidebarDivider.BackgroundColor3 = DefaultBorder
SidebarDivider.BorderSizePixel = 0
SidebarDivider.Parent = Main

local DiscordPill = Instance.new("TextButton")
DiscordPill.Size = UDim2.new(1, 0, 0, 26)
DiscordPill.Position = UDim2.new(0, 0, 1, -26)
DiscordPill.BackgroundColor3 = DefaultPillBg
DiscordPill.BorderSizePixel = 0
DiscordPill.Text = ""
DiscordPill.Parent = Sidebar

local dpCorner = Instance.new("UICorner")
dpCorner.CornerRadius = UDim.new(0, 5)
dpCorner.Parent = DiscordPill

local dpStroke = Instance.new("UIStroke")
dpStroke.Color = DefaultPillStroke
dpStroke.Thickness = 1
dpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
dpStroke.Parent = DiscordPill

local DiscordIcon = Instance.new("ImageLabel")
DiscordIcon.Size = UDim2.new(0, 14, 0, 14)
DiscordIcon.Position = UDim2.new(0, 6, 0.5, -7)
DiscordIcon.BackgroundTransparency = 1
DiscordIcon.Image = "rbxassetid://98671378613860"
DiscordIcon.ScaleType = Enum.ScaleType.Fit
DiscordIcon.Parent = DiscordPill

local DiscordTitle = Instance.new("TextLabel")
DiscordTitle.Size = UDim2.new(1, -26, 0, 11)
DiscordTitle.Position = UDim2.new(0, 24, 0, 2)
DiscordTitle.BackgroundTransparency = 1
DiscordTitle.Text = "Discord"
DiscordTitle.TextColor3 = DefaultPillText
DiscordTitle.Font = Enum.Font.GothamBold
DiscordTitle.TextSize = 9
DiscordTitle.TextXAlignment = Enum.TextXAlignment.Left
DiscordTitle.Parent = DiscordPill

table.insert(allPills, DiscordPill)
table.insert(allPillStrokes, dpStroke)
table.insert(allPillTexts, DiscordTitle)

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -121, 1, -33)
Content.Position = UDim2.new(0, 121, 0, 33)
Content.BackgroundColor3 = Colors.Panel
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.Parent = Main

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = Content

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -12, 1, -10)
Scroll.Position = UDim2.new(0, 6, 0, 5)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Colors.Stroke
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ZIndex = 2
Scroll.Parent = Content

local ScrollList = Instance.new("UIListLayout")
ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
ScrollList.Padding = UDim.new(0, 8)
ScrollList.Parent = Scroll

-- ============================================================
-- PANELS
-- ============================================================
local function createSidebarButton(text, order, iconId, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 26)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = SidebarButtonContainer

	if iconId and iconId ~= "" then
		local btnIcon = Instance.new("ImageLabel")
		btnIcon.Size = UDim2.new(0, 14, 0, 14)
		btnIcon.Position = UDim2.new(0, 6, 0.5, -7)
		btnIcon.BackgroundTransparency = 1
		btnIcon.Image = "rbxassetid://" .. iconId
		btnIcon.ScaleType = Enum.ScaleType.Fit
		btnIcon.Parent = btn
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -24, 1, 0)
	textLabel.Position = UDim2.new(0, 24, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Colors.SubText
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextSize = 12
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = btn

	btn.MouseButton1Click:Connect(function()
		for _, v in pairs(SidebarButtonContainer:GetChildren()) do
			if v:IsA("TextButton") then
				local lbl = v:FindFirstChildOfClass("TextLabel")
				if lbl then lbl.TextColor3 = Colors.SubText end
			end
		end
		textLabel.TextColor3 = Colors.Text
		if onClick then onClick() end
	end)
end

local function loadAboutPanel()
	for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end end
	local w = Instance.new("Frame")
	w.Size = UDim2.new(1, 0, 0, 75)
	w.BackgroundColor3 = Colors.Slot
	w.Parent = Scroll
	Instance.new("UICorner", w).CornerRadius = UDim.new(0, 8)
	local txt = Instance.new("TextLabel", w)
	txt.Size = UDim2.new(1, -20, 1, -20)
	txt.Position = UDim2.new(0, 10, 0, 10)
	txt.BackgroundTransparency = 1
	txt.Text = "Welcome to Zorx!"
	txt.TextColor3 = Colors.Text
	txt.Font = Enum.Font.GothamBold
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextYAlignment = Enum.TextYAlignment.Top
end

createSidebarButton("About", 1, "135090089738327", loadAboutPanel)
createSidebarButton("Farm", 2, "98852406765639", function() end)
createSidebarButton("Settings", 4, "117852848591099", function() end)
createSidebarButton("Info", 5, "117372440865704", function() end)

loadAboutPanel()

print("ZORX Hub - UI Loaded Successfully!")