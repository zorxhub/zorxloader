--============================================================
-- BAGIAN 1: LICENSE SYSTEM & UTILS
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
		local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
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
print("Executor terdeteksi: " .. detectedExecutor)

local ThemeColors = {
	None   = { bg = DefaultPillBg, stroke = DefaultPillStroke, text = DefaultPillText, border = DefaultBorder, infoLogo = InfoLogoBorder },
	Biru   = { bg = Color3.fromRGB(25,55,130), stroke = Color3.fromRGB(60,120,220), text = Color3.fromRGB(220,235,255), border = Color3.fromRGB(60,120,220), infoLogo = Color3.fromRGB(60,120,220) },
	Ungu   = { bg = Color3.fromRGB(80,35,130), stroke = Color3.fromRGB(160,90,220), text = Color3.fromRGB(235,220,255), border = Color3.fromRGB(160,90,220), infoLogo = Color3.fromRGB(160,90,220) },
	Hijau  = { bg = Color3.fromRGB(25,100,50), stroke = Color3.fromRGB(60,180,90), text = Color3.fromRGB(220,255,225), border = Color3.fromRGB(60,180,90), infoLogo = Color3.fromRGB(60,180,90) },
	Merah  = { bg = Color3.fromRGB(130,25,30), stroke = Color3.fromRGB(220,60,70), text = Color3.fromRGB(255,220,220), border = Color3.fromRGB(220,60,70), infoLogo = Color3.fromRGB(220,60,70) },
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

--============================================================
-- BAGIAN 2: MAIN UI & COUNTDOWN
--============================================================

-- Fungsi Notifikasi
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
	notif.Size = UDim2.new(0, 360, 0, 68) 
	notif.Position = UDim2.new(1, -20, 0, -100) 
	notif.AnchorPoint = Vector2.new(1, 0)
	notif.BackgroundColor3 = Colors.Background
	notif.Parent = container
	local nCorner = Instance.new("UICorner")
	nCorner.CornerRadius = UDim.new(0, 8)
	nCorner.Parent = notif
	local nIcon = Instance.new("ImageLabel")
	nIcon.Size = UDim2.new(0, 36, 0, 36)
	nIcon.Position = UDim2.new(0, 8, 0, 8)
	nIcon.BackgroundTransparency = 1
	nIcon.Image = "rbxassetid://" .. tostring(iconId or "134572030759999")
	nIcon.Parent = notif
	local nTitle = Instance.new("TextLabel")
	nTitle.Size = UDim2.new(1, -75, 0, 14)
	nTitle.Position = UDim2.new(0, 52, 0, 8)
	nTitle.BackgroundTransparency = 1
	nTitle.Text = titleText
	nTitle.TextColor3 = Colors.Text
	nTitle.Font = Enum.Font.GothamBold
	nTitle.TextSize = 12
	nTitle.TextXAlignment = Enum.TextXAlignment.Left
	nTitle.Parent = notif
	local nDesc = Instance.new("TextLabel")
	nDesc.Size = UDim2.new(1, -65, 0, 14)
	nDesc.Position = UDim2.new(0, 52, 0, 26)
	nDesc.BackgroundTransparency = 1
	nDesc.Text = messageText
	nDesc.TextColor3 = Colors.SubText
	nDesc.Font = Enum.Font.GothamMedium
	nDesc.TextSize = 10
	nDesc.TextXAlignment = Enum.TextXAlignment.Left
	nDesc.Parent = notif
	TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(1, -20, 0, 20) }):Play()
	task.delay(duration, function()
		local tw = TweenService:Create(notif, TweenInfo.new(0.3), { Position = UDim2.new(1, -20, 0, -100) })
		tw:Play()
		tw.Completed:Connect(function() notif:Destroy() end)
	end)
end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Size = UDim2.new(0, 480, 0, 300)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.BackgroundColor3 = Colors.Background
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = DefaultBorder

local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Colors.Background
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local LogoImg = Instance.new("ImageLabel", TopBar)
LogoImg.Size = UDim2.new(0, 18, 0, 18)
LogoImg.Position = UDim2.new(0, 14, 0.5, -9)
LogoImg.BackgroundTransparency = 1
LogoImg.Image = "rbxassetid://82414580295798"
LogoImg.Parent = TopBar

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0, 100, 1, 0)
Title.Position = UDim2.new(0, 38, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ZORX"
Title.TextColor3 = Colors.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local PillContainer = Instance.new("Frame", TopBar)
PillContainer.Size = UDim2.new(0, 0, 0, 22)
PillContainer.AutomaticSize = Enum.AutomaticSize.X
PillContainer.Position = UDim2.new(1, -85, 0.5, -11)
PillContainer.AnchorPoint = Vector2.new(1, 0)
PillContainer.BackgroundTransparency = 1
PillContainer.Parent = TopBar

local PillList = Instance.new("UIListLayout", PillContainer)
PillList.FillDirection = Enum.FillDirection.Horizontal
PillList.HorizontalAlignment = Enum.HorizontalAlignment.Right
PillList.Padding = UDim.new(0, 4)

local allPills, allPillStrokes, allPillTexts = {}, {}, {}
local function createPill(textText, width, iconId, layoutOrder, visible)
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0, width, 0, 22)
	pill.BackgroundColor3 = DefaultPillBg
	pill.LayoutOrder = layoutOrder or 0
	pill.Visible = visible
	pill.Parent = PillContainer
	Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 5)
	local pStroke = Instance.new("UIStroke", pill)
	pStroke.Color = DefaultPillStroke
	
	local hasIcon = (iconId and iconId ~= "")
	if hasIcon then
		local pIcon = Instance.new("ImageLabel", pill)
		pIcon.Size = UDim2.new(0, 15, 0, 15)
		pIcon.Position = UDim2.new(0, 9, 0.5, -7.5)
		pIcon.BackgroundTransparency = 1
		pIcon.Image = "rbxassetid://" .. iconId
		pIcon.Parent = pill
	end
	local txt = Instance.new("TextLabel", pill)
	txt.Size = UDim2.new(1, hasIcon and -24 or 0, 1, 0)
	txt.Position = UDim2.new(0, hasIcon and 22 or 0, 0, 0)
	txt.BackgroundTransparency = 1
	txt.Text = textText
	txt.TextColor3 = DefaultPillText
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 10
	txt.TextXAlignment = Enum.TextXAlignment.Center
	txt.TextTruncate = Enum.TextTruncate.AtEnd
	
	table.insert(allPills, pill)
	table.insert(allPillStrokes, pStroke)
	table.insert(allPillTexts, txt)
	return pill, txt
end

local function createAvatarPill(layoutOrder, visible)
	local pill = Instance.new("TextButton")
	pill.Size = UDim2.new(0, 22, 0, 22)
	pill.BackgroundColor3 = DefaultPillBg
	pill.LayoutOrder = layoutOrder or 0
	pill.Visible = visible
	pill.Text = ""
	pill.Parent = PillContainer
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
	local pStroke = Instance.new("UIStroke", pill)
	pStroke.Color = DefaultPillStroke
	local avatar = Instance.new("ImageLabel", pill)
	avatar.Size = UDim2.new(1, -2, 1, -2)
	avatar.Position = UDim2.new(0.5, 0, 0.5, 0)
	avatar.AnchorPoint = Vector2.new(0.5, 0.5)
	avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
	avatar.ScaleType = Enum.ScaleType.Crop
	Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
	
	pill.MouseButton1Click:Connect(function()
		local url = "https://www.roblox.com/users/" .. player.UserId .. "/profile"
		if setclipboard then setclipboard(url) end
	end)
	table.insert(allPills, pill)
	table.insert(allPillStrokes, pStroke)
	return pill
end

local avatarCard = createAvatarPill(0, false)
local namePillWidth = math.clamp(#player.Name * 6 + 16, 40, 80) 
local nickCard, nickText = createPill(player.Name, namePillWidth, "", 1, false)
local trialWidth = math.clamp(#customTrialText * 7 + 16, 40, 100)
local trialCard, trialText = createPill(customTrialText, trialWidth, "", 2, false)
local zeroCard, zeroText = createPill("000", 40, "", 3, false)
local gamePill, gameText = createPill(getGameName(), 145, "83907651602856", 4, true)
local fpsPill, fpsText = createPill("0", 48, "87621836182790", 5, true)
local execPill, execText = createPill(detectedExecutor, 68, "76551269066313", 6, true)

local function FormatTime(seconds)
	local d, h, m, s = math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600), math.floor((seconds % 3600) / 60), math.floor(seconds % 60)
	if d > 0 then return string.format("%dD %02dH %02dM", d, h, m)
	elseif h > 0 then return string.format("%02dH %02dM %02dS", h, m, s)
	else return string.format("%02dM %02dS", m, s) end
end

RunService.Heartbeat:Connect(function()
	local timeLeftMs = expireTime - (os.time() * 1000)
	if timeLeftMs > 0 then
		zeroText.Text = FormatTime(math.floor(timeLeftMs / 1000))
		zeroCard.Size = UDim2.new(0, zeroText.TextBounds.X + 16, 0, 22)
	else
		DestroyEverything()
	end
end)

-- Sisa tombol minimize, maximize, close, dll
local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -25, 0.5, -13) 
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Colors.Text
CloseBtn.Parent = TopBar

local MaximizeBtn = Instance.new("TextButton", TopBar)
MaximizeBtn.Size = UDim2.new(0, 26, 0, 26)
MaximizeBtn.Position = UDim2.new(1, -50, 0.5, -13) 
MaximizeBtn.BackgroundTransparency = 1
MaximizeBtn.Text = "[]"
MaximizeBtn.TextColor3 = Colors.Text
MaximizeBtn.Parent = TopBar

local isMaximized = false
MaximizeBtn.MouseButton1Click:Connect(function()
	isMaximized = not isMaximized
	for _, card in ipairs({avatarCard, nickCard, trialCard, zeroCard}) do
		card.Visible = isMaximized
	end
	TweenService:Create(Main, TweenInfo.new(0.3), {
		Size = isMaximized and UDim2.new(0, 620, 0, 390) or UDim2.new(0, 480, 0, 300)
	}):Play()
end)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

--============================================================
-- BAGIAN 3: SIDEBAR & PANELS
--============================================================

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 120, 1, -33)
Sidebar.Position = UDim2.new(0, 0, 0, 33)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local SidebarPad = Instance.new("UIPadding", Sidebar)
SidebarPad.PaddingTop = UDim.new(0, 8)
SidebarPad.PaddingLeft = UDim.new(0, 6)
SidebarPad.PaddingRight = UDim.new(0, 6)

local SearchContainer = Instance.new("Frame", Sidebar)
SearchContainer.Size = UDim2.new(1, 0, 0, 26)
SearchContainer.BackgroundColor3 = Colors.Slot
SearchContainer.Parent = Sidebar
Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 5)

local SearchBox = Instance.new("TextBox", SearchContainer)
SearchBox.Size = UDim2.new(1, -10, 1, 0)
SearchBox.Position = UDim2.new(0, 5, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search..."
SearchBox.TextColor3 = Colors.Text
SearchBox.TextSize = 10
SearchBox.TextXAlignment = Enum.TextXAlignment.Left

local SidebarButtonContainer = Instance.new("Frame", Sidebar)
SidebarButtonContainer.Size = UDim2.new(1, 0, 1, -66)
SidebarButtonContainer.Position = UDim2.new(0, 0, 0, 34)
SidebarButtonContainer.BackgroundTransparency = 1

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -121, 1, -33)
Content.Position = UDim2.new(0, 121, 0, 33)
Content.BackgroundColor3 = Colors.Panel
Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 10)

local Scroll = Instance.new("ScrollingFrame", Content)
Scroll.Size = UDim2.new(1, -12, 1, -10)
Scroll.Position = UDim2.new(0, 6, 0, 5)
Scroll.BackgroundTransparency = 1
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ScrollBarThickness = 4

local function createSidebarButton(text, order, iconId, onClick)
	local btn = Instance.new("TextButton", SidebarButtonContainer)
	btn.Size = UDim2.new(1, 0, 0, 26)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.LayoutOrder = order
	
	if iconId then
		local btnIcon = Instance.new("ImageLabel", btn)
		btnIcon.Size = UDim2.new(0, 14, 0, 14)
		btnIcon.Position = UDim2.new(0, 6, 0.5, -7)
		btnIcon.BackgroundTransparency = 1
		btnIcon.Image = "rbxassetid://" .. iconId
	end

	local textLabel = Instance.new("TextLabel", btn)
	textLabel.Size = UDim2.new(1, -24, 1, 0)
	textLabel.Position = UDim2.new(0, 24, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Colors.SubText
	textLabel.TextSize = 12
	textLabel.TextXAlignment = Enum.TextXAlignment.Left

	btn.MouseButton1Click:Connect(function()
		if onClick then onClick() end
	end)
end

-- Fungsi Load Panel About
createSidebarButton("About", 1, "135090089738327", function()
	for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end end
	local w = Instance.new("Frame", Scroll)
	w.Size = UDim2.new(1, 0, 0, 75)
	w.BackgroundColor3 = Colors.Slot
	Instance.new("UICorner", w)
	local txt = Instance.new("TextLabel", w)
	txt.Size = UDim2.new(1, -20, 1, -20)
	txt.Position = UDim2.new(0, 10, 0, 10)
	txt.BackgroundTransparency = 1
	txt.Text = "Welcome to Zorx!"
	txt.TextColor3 = Colors.Text
	txt.Font = Enum.Font.GothamBold
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextYAlignment = Enum.TextYAlignment.Top
end)

createSidebarButton("Farm", 2, "98852406765639", function() end)
createSidebarButton("Settings", 4, "117852848591099", function() end)
createSidebarButton("Info", 5, "117372440865704", function() end)

print("ZORX Hub - UI Loaded Successfully!")