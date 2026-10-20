-- ============================================================
-- CHECK MAINTENANCE MODE + REAL-TIME AUTO REJOIN
-- ============================================================
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local reqFunc = request or (syn and syn.request) or (http and http.request) or http_request

local function triggerMaintenanceRejoin()
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "ZorX Hub - Maintenance Mode",
			Text = "Script dimatikan oleh Admin! Kamu akan di-rejoin otomatis dalam 3 detik...",
			Duration = 5
		})
	end)
	
	task.wait(3)

	pcall(function()
		if #Players:GetPlayers() <= 1 then
			TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
		end
	end)
end

-- 1. Pengecekan awal saat pertama kali execute
if reqFunc then
	local success, response = pcall(function()
		return reqFunc({
			Url = "https://zorx-broadcast-default-rtdb.firebaseio.com/info.json",
			Method = "GET"
		})
	end)

	if success and response and (response.StatusCode == 200 or response.Status == 200) then
		local data = HttpService:JSONDecode(response.Body)
		if data and data.Maintenance == true then
			triggerMaintenanceRejoin()
			return -- Menghentikan eksekusi script
		end
	end
end

-- 2. Pengecekan otomatis tiap 4 detik (Untuk player yang sedang memakai UI)
task.spawn(function()
	while task.wait(4) do
		if reqFunc then
			pcall(function()
				local response = reqFunc({
					Url = "https://zorx-broadcast-default-rtdb.firebaseio.com/info/Maintenance.json",
					Method = "GET"
				})
				if response and (response.StatusCode == 200 or response.Status == 200) then
					local isMaint = HttpService:JSONDecode(response.Body)
					if isMaint == true then
						triggerMaintenanceRejoin()
					end
				end
			end)
		end
	end
end)

--============================================================
-- ZORX HUB - FULL SERVICE (FIREBASE INFO, AUTO EXECUTOR & MAINTENANCE)
--============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- 1. SISTEM PENGECEKAN MAINTENANCE / KILL SWITCH DARI FIREBASE
-- ============================================================
local reqFunc = request or (syn and syn.request) or (http and http.request) or http_request

if reqFunc then
	local success, response = pcall(function()
		return reqFunc({
			Url = "https://zorx-broadcast-default-rtdb.firebaseio.com/info.json",
			Method = "GET"
		})
	end)

	if success and response and (response.StatusCode == 200 or response.Status == 200) then
		local data = HttpService:JSONDecode(response.Body)
		if data and data.Maintenance == true then
			pcall(function()
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "ZorX Hub - Maintenance",
					Text = "Script sedang dalam perbaikan! Silakan coba lagi nanti.",
					Duration = 10
				})
			end)
			warn("[ZorX Hub] Eksekusi dihentikan: Maintenance Mode Aktif.")
			return -- Menghentikan keseluruhan script agar tidak berjalan
		end
	end
end

-- Bersihkan UI lama jika ada
for _, gui in pairs(playerGui:GetChildren()) do
	if gui.Name == "ZorXHub" then
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

-- ============================================================
-- FUNGSI DETEKSI OTOMATIS EXECUTOR
-- ============================================================
local function getExecutorName()
	if identifyexecutor then
		local success, name = pcall(identifyexecutor)
		if success and name then
			return name
		end
	elseif getexecutorname then
		local success, name = pcall(getexecutorname)
		if success and name then
			return name
		end
	end

	if syn then
		return "Synapse X"
	elseif fluxus then
		return "Fluxus"
	elseif hydrogen then
		return "Hydrogen"
	elseif delta or (identifyexecutor and pcall(identifyexecutor) and string.find(string.lower(identifyexecutor()), "delta")) then
		return "Delta"
	elseif codex then
		return "Codex"
	elseif arceus then
		return "Arceus X"
	elseif solara then
		return "Solara"
	elseif wave then
		return "Wave"
	else
		return "Unknown Executor"
	end
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

local function getTodayDate()
	return os.date("%d/%m/%Y")
end

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

-- ============================================================
-- SYSTEM NOTIFIKASI CUSTOM BROADCAST
-- ============================================================
local function sendNotification(titleText, messageText, iconId, duration)
	duration = duration or 6

	local notif = Instance.new("Frame")
	notif.Name = "ZorxNotif"
	notif.Size = UDim2.new(0, 0, 0, 0)
	notif.Position = UDim2.new(0.5, 0, 0, 110)
	notif.AnchorPoint = Vector2.new(0.5, 0.5)
	notif.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	notif.BorderSizePixel = 0
	notif.ZIndex = 1000
	notif.ClipsDescendants = true
	notif.Parent = ScreenGui

	local nCorner = Instance.new("UICorner")
	nCorner.CornerRadius = UDim.new(0, 8)
	nCorner.Parent = notif

	local nStroke = Instance.new("UIStroke")
	nStroke.Color = Color3.fromRGB(45, 45, 55)
	nStroke.Thickness = 1.2
	nStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	nStroke.Parent = notif

	local iconBox = Instance.new("Frame")
	iconBox.Size = UDim2.new(0, 36, 0, 36)
	iconBox.Position = UDim2.new(0, 8, 0, 8)
	iconBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	iconBox.BorderSizePixel = 0
	iconBox.ZIndex = 1001
	iconBox.Parent = notif

	local ibCorner = Instance.new("UICorner")
	ibCorner.CornerRadius = UDim.new(0, 6)
	ibCorner.Parent = iconBox

	local ibStroke = Instance.new("UIStroke")
	ibStroke.Color = Color3.fromRGB(45, 45, 55)
	ibStroke.Thickness = 1
	ibStroke.Parent = iconBox

	local nIcon = Instance.new("ImageLabel")
	nIcon.Size = UDim2.new(1, 0, 1, 0)
	nIcon.Position = UDim2.new(0, 0, 0, 0)
	nIcon.BackgroundTransparency = 1
	nIcon.Image = "rbxassetid://" .. tostring(iconId or "134572030759999")
	nIcon.ScaleType = Enum.ScaleType.Fit
	nIcon.ZIndex = 1002
	nIcon.Parent = iconBox

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 6)
	imgCorner.Parent = nIcon

	local nTitle = Instance.new("TextLabel")
	nTitle.Size = UDim2.new(1, -75, 0, 14)
	nTitle.Position = UDim2.new(0, 52, 0, 6)
	nTitle.BackgroundTransparency = 1
	nTitle.Text = titleText or "ZorX Announcements"
	nTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	nTitle.Font = Enum.Font.GothamBold
	nTitle.TextSize = 11
	nTitle.TextXAlignment = Enum.TextXAlignment.Left
	nTitle.ZIndex = 1001
	nTitle.Parent = notif

	local subFrame = Instance.new("Frame")
	subFrame.Size = UDim2.new(1, -75, 0, 12)
	subFrame.Position = UDim2.new(0, 52, 0, 21)
	subFrame.BackgroundTransparency = 1
	subFrame.ZIndex = 1001
	subFrame.Parent = notif

	local subList = Instance.new("UIListLayout")
	subList.FillDirection = Enum.FillDirection.Horizontal
	subList.SortOrder = Enum.SortOrder.LayoutOrder
	subList.Padding = UDim.new(0, 4)
	subList.Parent = subFrame

	local fromLabel = Instance.new("TextLabel")
	fromLabel.Size = UDim2.new(0, 0, 1, 0)
	fromLabel.AutomaticSize = Enum.AutomaticSize.X
	fromLabel.BackgroundTransparency = 1
	fromLabel.Text = "From"
	fromLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
	fromLabel.Font = Enum.Font.Gotham
	fromLabel.TextSize = 9.5
	fromLabel.TextXAlignment = Enum.TextXAlignment.Left
	fromLabel.LayoutOrder = 1
	fromLabel.ZIndex = 1001
	fromLabel.Parent = subFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 0, 1, 0)
	nameLabel.AutomaticSize = Enum.AutomaticSize.X
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "ZorX"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 9.5
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.LayoutOrder = 2
	nameLabel.ZIndex = 1001
	nameLabel.Parent = subFrame

	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Size = UDim2.new(0, 0, 1, 0)
	ownerLabel.AutomaticSize = Enum.AutomaticSize.X
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Text = "[OWNER]"
	ownerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ownerLabel.Font = Enum.Font.GothamBold
	ownerLabel.TextSize = 9.5
	ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
	ownerLabel.LayoutOrder = 3
	ownerLabel.ZIndex = 1001
	ownerLabel.Parent = subFrame

	task.spawn(function()
		local hue = 0
		while ownerLabel and ownerLabel.Parent do
			hue = (hue + 0.01) % 1
			ownerLabel.TextColor3 = Color3.fromHSV(hue, 0.9, 1)
			task.wait(0.03)
		end
	end)

	local nDesc = Instance.new("TextLabel")
	nDesc.Size = UDim2.new(1, -60, 0, 24)
	nDesc.Position = UDim2.new(0, 52, 0, 35)
	nDesc.BackgroundTransparency = 1
	nDesc.Text = messageText or "Pesan broadcast..."
	nDesc.TextColor3 = Color3.fromRGB(255, 255, 255)
	nDesc.Font = Enum.Font.GothamMedium
	nDesc.TextSize = 9.5
	nDesc.TextXAlignment = Enum.TextXAlignment.Left
	nDesc.TextYAlignment = Enum.TextYAlignment.Top
	nDesc.TextWrapped = true
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
	barBg.Size = UDim2.new(1, -16, 0, 2.5)
	barBg.Position = UDim2.new(0, 8, 1, -5)
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

	TweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 330, 0, 68)
	}):Play()

	TweenService:Create(barFill, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()

	local function dismiss()
		local scaleDown = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		scaleDown:Play()
		scaleDown.Completed:Connect(function()
			notif:Destroy()
		end)
	end

	closeBtn.MouseButton1Click:Connect(dismiss)

	task.delay(duration, function()
		if notif and notif.Parent then
			dismiss()
		end
	end)
end

-- ============================================================
-- LIVE BROADCAST RECEIVER
-- ============================================================
task.spawn(function()
	local lastTimeChecked = 0
	while task.wait(3) do
		if reqFunc then
			pcall(function()
				local response = reqFunc({
					Url = "https://zorx-broadcast-default-rtdb.firebaseio.com/broadcast.json",
					Method = "GET"
				})
				if response and (response.StatusCode == 200 or response.Status == 200) then
					local data = HttpService:JSONDecode(response.Body)
					if data and data.Pesan and data.Waktu then
						if data.Waktu > lastTimeChecked then
							if lastTimeChecked ~= 0 then
								local fotoAsset = data.IconId or "134572030759999"
								sendNotification("ZorX Announcements", data.Pesan, fotoAsset, 7)
							end
							lastTimeChecked = data.Waktu
						end
					end
				end
			end)
		end
	end
end)

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
local function registerBorder(stroke)
	table.insert(allBorders, stroke)
end
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

local PillContainer = Instance.new("Frame")
PillContainer.Name = "PillContainer"
PillContainer.Size = UDim2.new(0, 0, 0, 22)
PillContainer.AutomaticSize = Enum.AutomaticSize.X
PillContainer.Position = UDim2.new(1, -72, 0.5, -11)
PillContainer.AnchorPoint = Vector2.new(1, 0)
PillContainer.BackgroundTransparency = 1
PillContainer.Parent = TopBar

local PillList = Instance.new("UIListLayout")
PillList.FillDirection = Enum.FillDirection.Horizontal
PillList.HorizontalAlignment = Enum.HorizontalAlignment.Right
PillList.VerticalAlignment = Enum.VerticalAlignment.Center
PillList.Padding = UDim.new(0, 4)
PillList.Parent = PillContainer

local allPills = {}
local allPillStrokes = {}
local allPillTexts = {}
local infoLogoBorders = {}

local function registerInfoLogoBorder(stroke)
	table.insert(infoLogoBorders, stroke)
end

local function createPill(textText, width, iconId)
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0, width, 0, 22)
	pill.BackgroundColor3 = DefaultPillBg
	pill.BorderSizePixel = 0
	pill.Parent = PillContainer

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 5)
	pCorner.Parent = pill

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = DefaultPillStroke
	pStroke.Thickness = 1
	pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pStroke.Parent = pill

	if iconId and iconId ~= "" then
		local pIcon = Instance.new("ImageLabel")
		pIcon.Size = UDim2.new(0, 15, 0, 15)
		pIcon.Position = UDim2.new(0, 9, 0.5, -7.5)
		pIcon.BackgroundTransparency = 1
		pIcon.Image = "rbxassetid://" .. iconId
		pIcon.ScaleType = Enum.ScaleType.Fit
		pIcon.Parent = pill
	end

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, iconId and -24 or 0, 1, 0)
	txt.Position = UDim2.new(0, iconId and 22 or 0, 0, 0)
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

local gamePill, gameText = createPill(getGameName(), 145, "83907651602856")
local fpsPill, fpsText = createPill("0", 48, "87621836182790")
local execPill, execText = createPill(detectedExecutor, 68, "76551269066313")

task.spawn(function()
	while task.wait(5) do
		local newName = getGameName()
		if gameText.Text ~= newName then
			gameText.Text = newName
		end
	end
end)

local MaximizeBtn = Instance.new("TextButton")
MaximizeBtn.Size = UDim2.new(0, 26, 0, 26)
MaximizeBtn.Position = UDim2.new(1, -60, 0.5, -13)
MaximizeBtn.BackgroundTransparency = 1
MaximizeBtn.Text = ""
MaximizeBtn.AutoButtonColor = false
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
CloseBtn.Position = UDim2.new(1, -30, 0.5, -13)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = ""
CloseBtn.AutoButtonColor = false
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

CloseBtn.MouseButton1Click:Connect(function()
	setUIOpen(false)
end)

MinimizeBtn.MouseButton1Click:Connect(function()
	setUIOpen(true)
end)

local isMaximized = false
MaximizeBtn.MouseButton1Click:Connect(function()
	isMaximized = not isMaximized
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
TopDivider.Name = "TopDivider"
TopDivider.Size = UDim2.new(1, 0, 0, 1)
TopDivider.Position = UDim2.new(0, 0, 0, 32)
TopDivider.BackgroundColor3 = DefaultBorder
TopDivider.BorderSizePixel = 0
TopDivider.Parent = Main

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
SearchContainer.Name = "SearchContainer"
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

local SearchIcon = Instance.new("ImageLabel")
SearchIcon.Size = UDim2.new(0, 12, 0, 12)
SearchIcon.Position = UDim2.new(0, 6, 0.5, -6)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Image = "rbxassetid://91301384227473"
SearchIcon.ImageColor3 = Colors.SubText
SearchIcon.ScaleType = Enum.ScaleType.Fit
SearchIcon.Parent = SearchContainer

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -24, 1, 0)
SearchBox.Position = UDim2.new(0, 22, 0, 0)
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
SidebarButtonContainer.Name = "ButtonContainer"
SidebarButtonContainer.Size = UDim2.new(1, 0, 1, -66)
SidebarButtonContainer.Position = UDim2.new(0, 0, 0, 34)
SidebarButtonContainer.BackgroundTransparency = 1
SidebarButtonContainer.ClipsDescendants = true
SidebarButtonContainer.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 2)
SidebarList.Parent = SidebarButtonContainer

local SidebarDivider = Instance.new("Frame")
SidebarDivider.Name = "SidebarDivider"
SidebarDivider.Size = UDim2.new(0, 1, 1, -33)
SidebarDivider.Position = UDim2.new(0, 120, 0, 33)
SidebarDivider.BackgroundColor3 = DefaultBorder
SidebarDivider.BorderSizePixel = 0
SidebarDivider.Parent = Main

local DiscordPill = Instance.new("TextButton")
DiscordPill.Name = "DiscordPill"
DiscordPill.Size = UDim2.new(1, 0, 0, 26)
DiscordPill.Position = UDim2.new(0, 0, 1, -26)
DiscordPill.BackgroundColor3 = DefaultPillBg
DiscordPill.BorderSizePixel = 0
DiscordPill.Text = ""
DiscordPill.AutoButtonColor = false
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
DiscordTitle.TextTruncate = Enum.TextTruncate.AtEnd
DiscordTitle.Parent = DiscordPill

local DiscordLink = Instance.new("TextLabel")
DiscordLink.Size = UDim2.new(1, -26, 0, 10)
DiscordLink.Position = UDim2.new(0, 24, 0, 13)
DiscordLink.BackgroundTransparency = 1
DiscordLink.Text = "discord.gg/cvWW5DBZKR"
DiscordLink.TextColor3 = Color3.fromRGB(140, 140, 150)
DiscordLink.Font = Enum.Font.Gotham
DiscordLink.TextSize = 7
DiscordLink.TextXAlignment = Enum.TextXAlignment.Left
DiscordLink.TextTruncate = Enum.TextTruncate.AtEnd
DiscordLink.Parent = DiscordPill

table.insert(allPills, DiscordPill)
table.insert(allPillStrokes, dpStroke)
table.insert(allPillTexts, DiscordTitle)

DiscordPill.MouseEnter:Connect(function()
	TweenService:Create(DiscordPill, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(45, 45, 55) }):Play()
end)
DiscordPill.MouseLeave:Connect(function()
	if RainbowActive then return end
	local theme = ThemeColors[ActiveTheme]
	TweenService:Create(DiscordPill, TweenInfo.new(0.15), { BackgroundColor3 = theme.bg }):Play()
end)

DiscordPill.MouseButton1Click:Connect(function()
	pcall(function()
		if setclipboard then
			setclipboard("https://discord.gg/3MrpqYycs")
		elseif toclipboard then
			toclipboard("https://discord.gg/3MrpqYycs")
		end
	end)
end)

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

local WatermarkLogo = Instance.new("ImageLabel")
WatermarkLogo.Name = "WatermarkLogo"
WatermarkLogo.Size = UDim2.new(0, 240, 0, 240)
WatermarkLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
WatermarkLogo.AnchorPoint = Vector2.new(0.5, 0.5)
WatermarkLogo.BackgroundTransparency = 1
WatermarkLogo.Image = "rbxassetid://134572030759999"
WatermarkLogo.ImageTransparency = 0.88
WatermarkLogo.ScaleType = Enum.ScaleType.Fit
WatermarkLogo.ZIndex = 1
WatermarkLogo.Parent = Content

local Scroll = Instance.new("ScrollingFrame")
Scroll.Name = "Scroll"
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

local ScrollPad = Instance.new("UIPadding")
ScrollPad.PaddingTop = UDim.new(0, 6)
ScrollPad.PaddingRight = UDim.new(0, 2)
ScrollPad.PaddingLeft = UDim.new(0, 2)
ScrollPad.Parent = Scroll

local ScrollList = Instance.new("UIListLayout")
ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
ScrollList.Padding = UDim.new(0, 8)
ScrollList.Parent = Scroll

local sidebarButtons = {}
local activeTab = nil

local function createSidebarButton(text, order, iconId, onClick)
	local btn = Instance.new("TextButton")
	btn.Name = text
	btn.Size = UDim2.new(1, 0, 0, 26)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = SidebarButtonContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = btn

	if iconId and iconId ~= "" then
		local btnIcon = Instance.new("ImageLabel")
		btnIcon.Name = "Icon"
		btnIcon.Size = UDim2.new(0, 14, 0, 14)
		btnIcon.Position = UDim2.new(0, 6, 0.5, -7)
		btnIcon.BackgroundTransparency = 1
		btnIcon.Image = "rbxassetid://" .. iconId
		btnIcon.ScaleType = Enum.ScaleType.Fit
		btnIcon.Parent = btn
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Label"
	textLabel.Size = UDim2.new(1, iconId and -24 or -16, 1, 0)
	textLabel.Position = UDim2.new(0, iconId and 24 or 8, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Colors.SubText
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextSize = 12
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = btn

	btn.MouseEnter:Connect(function()
		if activeTab ~= btn then
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.7, BackgroundColor3 = Colors.SlotHover }):Play()
			TweenService:Create(textLabel, TweenInfo.new(0.15), { TextColor3 = Colors.Text }):Play()
		end
	end)

	btn.MouseLeave:Connect(function()
		if activeTab ~= btn then
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(textLabel, TweenInfo.new(0.15), { TextColor3 = Colors.SubText }):Play()
		end
	end)

	btn.MouseButton1Click:Connect(function()
		for _, b in pairs(sidebarButtons) do
			TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
			local lbl = b:FindFirstChild("Label")
			if lbl then TweenService:Create(lbl, TweenInfo.new(0.15), { TextColor3 = Colors.SubText }):Play() end
		end
		activeTab = btn
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.5, BackgroundColor3 = Colors.SlotHover }):Play()
		TweenService:Create(textLabel, TweenInfo.new(0.15), { TextColor3 = Colors.Text }):Play()
		if onClick then onClick() end
	end)

	table.insert(sidebarButtons, btn)
	return btn
end

local function clearContent()
	for _, child in pairs(Scroll:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	for _, child in pairs(PopupLayer:GetChildren()) do
		child.Visible = false
	end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = SearchBox.Text:lower()
	for _, btn in pairs(SidebarButtonContainer:GetChildren()) do
		if btn:IsA("TextButton") then
			local label = btn:FindFirstChild("Label")
			if label then
				btn.Visible = (query == "" or label.Text:lower():find(query) ~= nil)
			end
		end
	end
end)

local function applyPillTheme(themeName)
	ActiveTheme = themeName
	RainbowActive = (themeName == "Rainbow")
	if RainbowActive then return end

	local theme = ThemeColors[themeName]
	if not theme then return end

	for _, pill in pairs(allPills) do
		TweenService:Create(pill, TweenInfo.new(0.2), { BackgroundColor3 = theme.bg }):Play()
	end
	for _, stroke in pairs(allPillStrokes) do
		TweenService:Create(stroke, TweenInfo.new(0.2), { Color = theme.stroke }):Play()
	end
	for _, txt in pairs(allPillTexts) do
		TweenService:Create(txt, TweenInfo.new(0.2), { TextColor3 = theme.text }):Play()
	end
	TweenService:Create(DiscordLink, TweenInfo.new(0.2), { TextColor3 = theme.text }):Play()

	for _, border in pairs(allBorders) do
		if border and border.Parent then
			TweenService:Create(border, TweenInfo.new(0.2), { Color = theme.border }):Play()
		end
	end
	TopDivider.BackgroundColor3 = theme.border
	SidebarDivider.BackgroundColor3 = theme.border

	for _, border in pairs(infoLogoBorders) do
		if border and border.Parent then
			TweenService:Create(border, TweenInfo.new(0.2), { Color = theme.infoLogo or theme.border }):Play()
		end
	end
end

RunService.Heartbeat:Connect(function()
	if not RainbowActive then return end

	RainbowHue = (RainbowHue + 0.005) % 1
	local rainbowColor = Color3.fromHSV(RainbowHue, 0.8, 1)
	local rainbowDark = Color3.fromHSV(RainbowHue, 0.8, 0.4)
	local rainbowText = Color3.fromHSV(RainbowHue, 0.3, 1)

	for _, pill in pairs(allPills) do pill.BackgroundColor3 = rainbowDark end
	for _, stroke in pairs(allPillStrokes) do stroke.Color = rainbowColor end
	for _, txt in pairs(allPillTexts) do txt.TextColor3 = rainbowText end
	DiscordLink.TextColor3 = rainbowText

	for _, border in pairs(allBorders) do if border and border.Parent then border.Color = rainbowColor end end
	for _, border in pairs(infoLogoBorders) do if border and border.Parent then border.Color = rainbowColor end end
	TopDivider.BackgroundColor3 = rainbowColor
	SidebarDivider.BackgroundColor3 = rainbowColor
end)

local function loadAboutPanel()
	clearContent()

	local welcomeCard = Instance.new("Frame")
	welcomeCard.Name = "WelcomeCard"
	welcomeCard.Size = UDim2.new(1, 0, 0, 75)
	welcomeCard.Position = UDim2.new(0, 0, 0, 0)
	welcomeCard.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	welcomeCard.BorderSizePixel = 0
	welcomeCard.LayoutOrder = 1
	welcomeCard.Parent = Scroll

	local wCorner = Instance.new("UICorner")
	wCorner.CornerRadius = UDim.new(0, 8)
	wCorner.Parent = welcomeCard

	local wStroke = Instance.new("UIStroke")
	wStroke.Color = ThemeColors[ActiveTheme].border
	wStroke.Thickness = 1
	wStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	wStroke.Parent = welcomeCard
	registerBorder(wStroke)

	local wTitle = Instance.new("TextLabel")
	wTitle.Size = UDim2.new(1, -30, 0, 20)
	wTitle.Position = UDim2.new(0, 14, 0, 8)
	wTitle.BackgroundTransparency = 1
	wTitle.Text = "Welcome to Zorx"
	wTitle.TextColor3 = Colors.Text
	wTitle.Font = Enum.Font.GothamBold
	wTitle.TextSize = 13
	wTitle.TextXAlignment = Enum.TextXAlignment.Left
	wTitle.Parent = welcomeCard

	local wDesc = Instance.new("TextLabel")
	wDesc.Size = UDim2.new(1, -28, 0, 38)
	wDesc.Position = UDim2.new(0, 14, 0, 30)
	wDesc.BackgroundTransparency = 1
	wDesc.Text = "Welcome! This hub is designed to keep every feature organized, responsive, and easy to use. Select a tab from the sidebar to get started."
	wDesc.TextColor3 = Color3.fromRGB(170, 170, 190)
	wDesc.Font = Enum.Font.Gotham
	wDesc.TextSize = 9.5
	wDesc.TextXAlignment = Enum.TextXAlignment.Left
	wDesc.TextYAlignment = Enum.TextYAlignment.Top
	wDesc.TextWrapped = true
	wDesc.Parent = welcomeCard

	local imageCard = Instance.new("Frame")
	imageCard.Name = "ImageCard"
	imageCard.Size = UDim2.new(1, 0, 0, 140)
	imageCard.Position = UDim2.new(0, 0, 0, 0)
	imageCard.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	imageCard.BorderSizePixel = 0
	imageCard.ClipsDescendants = true
	imageCard.LayoutOrder = 2
	imageCard.Parent = Scroll

	local iCorner = Instance.new("UICorner")
	iCorner.CornerRadius = UDim.new(0, 8)
	iCorner.Parent = imageCard

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(1, 0, 1, 0)
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Image = "rbxassetid://91006115016356"
	img.ScaleType = Enum.ScaleType.Stretch
	img.ClipsDescendants = true
	img.Parent = imageCard

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 7)
	imgCorner.Parent = img

	local iStroke = Instance.new("UIStroke")
	iStroke.Color = ThemeColors[ActiveTheme].border
	iStroke.Thickness = 1
	iStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	iStroke.Parent = imageCard
	registerBorder(iStroke)
end

-- ============================================================
-- TAB INFO (OTOMATIS TARIK VERSI & CHANGELOG DARI FIREBASE)
-- ============================================================
local function loadInfoPanel()
	clearContent()

	local communityCard = Instance.new("Frame")
	communityCard.Name = "CommunityCard"
	communityCard.Size = UDim2.new(1, 0, 0, 145)
	communityCard.Position = UDim2.new(0, 0, 0, 0)
	communityCard.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	communityCard.BorderSizePixel = 0
	communityCard.LayoutOrder = 1
	communityCard.Parent = Scroll

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 8)
	cCorner.Parent = communityCard

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = ThemeColors[ActiveTheme].border
	cStroke.Thickness = 1
	cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cStroke.Parent = communityCard
	registerBorder(cStroke)

	local logoBox = Instance.new("Frame")
	logoBox.Size = UDim2.new(0, 56, 0, 56)
	logoBox.Position = UDim2.new(0, 14, 0, 14)
	logoBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	logoBox.BorderSizePixel = 0
	logoBox.ClipsDescendants = true
	logoBox.Parent = communityCard

	local logoCorner = Instance.new("UICorner")
	logoCorner.CornerRadius = UDim.new(0, 7)
	logoCorner.Parent = logoBox

	local logoStroke = Instance.new("UIStroke")
	logoStroke.Color = ThemeColors[ActiveTheme].infoLogo or ThemeColors[ActiveTheme].border
	logoStroke.Thickness = 1
	logoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	logoStroke.Parent = logoBox
	registerInfoLogoBorder(logoStroke)

	local logoImg2 = Instance.new("ImageLabel")
	logoImg2.Size = UDim2.new(1, 0, 1, 0)
	logoImg2.Position = UDim2.new(0, 0, 0, 0)
	logoImg2.BackgroundTransparency = 1
	logoImg2.BorderSizePixel = 0
	logoImg2.Image = "rbxassetid://77776661633653"
	logoImg2.ScaleType = Enum.ScaleType.Stretch 
	logoImg2.ClipsDescendants = true
	logoImg2.Parent = logoBox

	local logoImgCorner = Instance.new("UICorner")
	logoImgCorner.CornerRadius = UDim.new(0, 6)
	logoImgCorner.Parent = logoImg2

	local cTitle = Instance.new("TextLabel")
	cTitle.Size = UDim2.new(1, -85, 0, 18)
	cTitle.Position = UDim2.new(0, 80, 0, 16)
	cTitle.BackgroundTransparency = 1
	cTitle.Text = "Zorx Community"
	cTitle.TextColor3 = Colors.Text
	cTitle.Font = Enum.Font.GothamBold
	cTitle.TextSize = 12
	cTitle.TextXAlignment = Enum.TextXAlignment.Left
	cTitle.Parent = communityCard

	local cInfo = Instance.new("TextLabel")
	cInfo.Size = UDim2.new(1, -85, 0, 30)
	cInfo.Position = UDim2.new(0, 80, 0, 36)
	cInfo.BackgroundTransparency = 1
	cInfo.Text = "- Version: Loading...\n- Last Update: Loading..."
	cInfo.TextColor3 = Color3.fromRGB(170, 170, 190)
	cInfo.Font = Enum.Font.Gotham
	cInfo.TextSize = 10
	cInfo.TextXAlignment = Enum.TextXAlignment.Left
	cInfo.TextYAlignment = Enum.TextYAlignment.Top
	cInfo.Parent = communityCard

	local function fetchLiveInfo()
		task.spawn(function()
			if reqFunc then
				pcall(function()
					local response = reqFunc({
						Url = "https://zorx-broadcast-default-rtdb.firebaseio.com/info.json",
						Method = "GET"
					})
					if response and (response.StatusCode == 200 or response.Status == 200) then
						local data = HttpService:JSONDecode(response.Body)
						if data then
							local ver = data.Version or "v1.0"
							local updateDate = data.LastUpdate or getTodayDate()
							cInfo.Text = "- Version: " .. ver .. "\n- Last Update: " .. updateDate
						end
					end
				end)
			end
		end)
	end

	fetchLiveInfo()

	local copyDiscordBtn = Instance.new("TextButton")
	copyDiscordBtn.Size = UDim2.new(0.5, -18, 0, 32)
	copyDiscordBtn.Position = UDim2.new(0, 14, 0, 96)
	copyDiscordBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 32)
	copyDiscordBtn.BorderSizePixel = 0
	copyDiscordBtn.Text = ""
	copyDiscordBtn.AutoButtonColor = false
	copyDiscordBtn.Parent = communityCard

	local cdCorner = Instance.new("UICorner")
	cdCorner.CornerRadius = UDim.new(0, 6)
	cdCorner.Parent = copyDiscordBtn

	local cdStroke = Instance.new("UIStroke")
	cdStroke.Color = ThemeColors[ActiveTheme].border
	cdStroke.Thickness = 1
	cdStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cdStroke.Parent = copyDiscordBtn
	registerBorder(cdStroke)

	local cdText = Instance.new("TextLabel")
	cdText.Size = UDim2.new(1, -45, 1, 0)
	cdText.Position = UDim2.new(0, 12, 0, 0)
	cdText.BackgroundTransparency = 1
	cdText.Text = "Copy Discord Invite"
	cdText.TextColor3 = Color3.fromRGB(230, 240, 235)
	cdText.Font = Enum.Font.GothamBold
	cdText.TextSize = 10
	cdText.TextXAlignment = Enum.TextXAlignment.Left
	cdText.Parent = copyDiscordBtn

	local cdIcon = Instance.new("ImageLabel")
	cdIcon.Size = UDim2.new(0, 14, 0, 14)
	cdIcon.Position = UDim2.new(1, -22, 0.5, -7)
	cdIcon.BackgroundTransparency = 1
	cdIcon.Image = "rbxassetid://101397742551590"
	cdIcon.ScaleType = Enum.ScaleType.Fit
	cdIcon.Parent = copyDiscordBtn

	local updateBtn = Instance.new("TextButton")
	updateBtn.Size = UDim2.new(0.5, -18, 0, 32)
	updateBtn.Position = UDim2.new(0.5, 4, 0, 96)
	updateBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 32)
	updateBtn.BorderSizePixel = 0
	updateBtn.Text = ""
	updateBtn.AutoButtonColor = false
	updateBtn.Parent = communityCard

	local udCorner = Instance.new("UICorner")
	udCorner.CornerRadius = UDim.new(0, 6)
	udCorner.Parent = updateBtn

	local udStroke = Instance.new("UIStroke")
	udStroke.Color = ThemeColors[ActiveTheme].border
	udStroke.Thickness = 1
	udStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	udStroke.Parent = updateBtn
	registerBorder(udStroke)

	local udText = Instance.new("TextLabel")
	udText.Size = UDim2.new(1, -45, 1, 0)
	udText.Position = UDim2.new(0, 12, 0, 0)
	udText.BackgroundTransparency = 1
	udText.Text = "Refresh Info"
	udText.TextColor3 = Color3.fromRGB(230, 240, 235)
	udText.Font = Enum.Font.GothamBold
	udText.TextSize = 10
	udText.TextXAlignment = Enum.TextXAlignment.Left
	udText.Parent = updateBtn

	local udIcon = Instance.new("ImageLabel")
	udIcon.Size = UDim2.new(0, 14, 0, 14)
	udIcon.Position = UDim2.new(1, -22, 0.5, -7)
	udIcon.BackgroundTransparency = 1
	udIcon.Image = "rbxassetid://137170375224448"
	udIcon.ScaleType = Enum.ScaleType.Fit
	udIcon.Parent = updateBtn

	copyDiscordBtn.MouseButton1Click:Connect(function()
		pcall(function()
			if setclipboard then
				setclipboard("https://discord.gg/3MrpqYycs")
			elseif toclipboard then
				toclipboard("https://discord.gg/3MrpqYycs")
			end
		end)
	end)

	updateBtn.MouseButton1Click:Connect(function()
		local rotateInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		TweenService:Create(udIcon, rotateInfo, {Rotation = 360}):Play()
		fetchLiveInfo()
		task.wait(0.8)
		udIcon.Rotation = 0
	end)
end

local function loadSetingsPanel()
	clearContent()

	local header = Instance.new("TextLabel")
	header.Name = "Header_Colours"
	header.Size = UDim2.new(1, 0, 0, 16)
	header.BackgroundTransparency = 1
	header.Text = "COLOURS"
	header.TextColor3 = Colors.SubText
	header.Font = Enum.Font.GothamBold
	header.TextSize = 10
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.LayoutOrder = 1
	header.Parent = Scroll

	local dropdownRow = Instance.new("Frame")
	dropdownRow.Name = "Dropdown_Colours"
	dropdownRow.Size = UDim2.new(1, 0, 0, 42)
	dropdownRow.BackgroundColor3 = Colors.Slot
	dropdownRow.BorderSizePixel = 0
	dropdownRow.LayoutOrder = 2
	dropdownRow.Parent = Scroll

	local drCorner = Instance.new("UICorner")
	drCorner.CornerRadius = UDim.new(0, 6)
	drCorner.Parent = dropdownRow

	local drStroke = Instance.new("UIStroke")
	drStroke.Color = ThemeColors[ActiveTheme].border
	drStroke.Thickness = 1
	drStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	drStroke.Parent = dropdownRow
	registerBorder(drStroke)

	local drTitle = Instance.new("TextLabel")
	drTitle.Size = UDim2.new(1, -130, 0, 16)
	drTitle.Position = UDim2.new(0, 10, 0, 6)
	drTitle.BackgroundTransparency = 1
	drTitle.Text = "Warna UI"
	drTitle.TextColor3 = Colors.Text
	drTitle.Font = Enum.Font.GothamMedium
	drTitle.TextSize = 11
	drTitle.TextXAlignment = Enum.TextXAlignment.Left
	drTitle.Parent = dropdownRow

	local drDesc = Instance.new("TextLabel")
	drDesc.Size = UDim2.new(1, -130, 0, 12)
	drDesc.Position = UDim2.new(0, 10, 0, 22)
	drDesc.BackgroundTransparency = 1
	drDesc.Text = "Ganti warna pill + border"
	drDesc.TextColor3 = Colors.SubText
	drDesc.Font = Enum.Font.Gotham
	drDesc.TextSize = 9
	drDesc.TextXAlignment = Enum.TextXAlignment.Left
	drDesc.Parent = dropdownRow

	local dropBox = Instance.new("TextButton")
	dropBox.Size = UDim2.new(0, 110, 0, 24)
	dropBox.Position = UDim2.new(1, -120, 0.5, -12)
	dropBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	dropBox.BorderSizePixel = 0
	dropBox.Text = ActiveTheme
	dropBox.TextColor3 = Colors.Text
	dropBox.Font = Enum.Font.Gotham
	dropBox.TextSize = 10
	dropBox.AutoButtonColor = false
	dropBox.Parent = dropdownRow

	local dbCorner = Instance.new("UICorner")
	dbCorner.CornerRadius = UDim.new(0, 5)
	dbCorner.Parent = dropBox

	local popup = Instance.new("Frame")
	popup.Name = "Popup_Colours"
	popup.Size = UDim2.new(0, 110, 0, 0)
	popup.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.ZIndex = 100
	popup.ClipsDescendants = true
	popup.Parent = PopupLayer

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 5)
	popupCorner.Parent = popup

	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = Colors.Stroke
	popupStroke.Thickness = 1
	popupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	popupStroke.Parent = popup

	local popupScroll = Instance.new("ScrollingFrame")
	popupScroll.Size = UDim2.new(1, 0, 1, 0)
	popupScroll.BackgroundTransparency = 1
	popupScroll.BorderSizePixel = 0
	popupScroll.ScrollBarThickness = 3
	popupScroll.ScrollBarImageColor3 = Colors.Stroke
	popupScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	popupScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	popupScroll.Parent = popup

	local popupList = Instance.new("UIListLayout")
	popupList.SortOrder = Enum.SortOrder.LayoutOrder
	popupList.Padding = UDim.new(0, 2)
	popupList.Parent = popupScroll

	local popupPad = Instance.new("UIPadding")
	popupPad.PaddingTop = UDim.new(0, 4)
	popupPad.PaddingBottom = UDim.new(0, 4)
	popupPad.PaddingLeft = UDim.new(0, 4)
	popupPad.PaddingRight = UDim.new(0, 4)
	popupPad.Parent = popupScroll

	local isOpen = false

	local themeList = {
		"None", "Rainbow", "Biru", "Ungu", "Hijau", "Kuning", "Oren",
		"Merah", "Pink", "Cyan", "Putih", "Hitam", "Emas",
		"Abu", "Lime", "Marun", "Navy"
	}

	local function refreshPopup()
		for _, child in pairs(popupScroll:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		local count = 0
		for _, themeName in ipairs(themeList) do
			count += 1
			local themeData = ThemeColors[themeName]
			local dotColor
			if themeName == "Rainbow" then
				dotColor = Color3.fromHSV(tick() % 1, 0.8, 1)
			elseif themeName == "None" then
				dotColor = NoneDotColor
			else
				dotColor = themeData and themeData.stroke or DefaultPillStroke
			end

			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, -6, 0, 24)
			item.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
			item.BackgroundTransparency = 1
			item.BorderSizePixel = 0
			item.Text = ""
			item.AutoButtonColor = false
			item.LayoutOrder = count
			item.Parent = popupScroll

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 4)
			itemCorner.Parent = item

			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 12, 0, 12)
			dot.Position = UDim2.new(0, 6, 0.5, -6)
			dot.BackgroundColor3 = dotColor
			dot.BorderSizePixel = 0
			dot.Parent = item

			local dotCorner = Instance.new("UICorner")
			dotCorner.CornerRadius = UDim.new(1, 0)
			dotCorner.Parent = dot

			local dotStroke = Instance.new("UIStroke")
			dotStroke.Color = Color3.fromRGB(80, 80, 90)
			dotStroke.Thickness = 1
			dotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			dotStroke.Parent = dot

			local itemText = Instance.new("TextLabel")
			itemText.Size = UDim2.new(1, -30, 1, 0)
			itemText.Position = UDim2.new(0, 24, 0, 0)
			itemText.BackgroundTransparency = 1
			itemText.Text = themeName
			itemText.TextColor3 = Colors.Text
			itemText.Font = Enum.Font.Gotham
			itemText.TextSize = 10
			itemText.TextXAlignment = Enum.TextXAlignment.Left
			itemText.Parent = item

			if ActiveTheme == themeName then
				item.BackgroundTransparency = 0.5
				item.BackgroundColor3 = Colors.SlotHover
			end

			item.MouseEnter:Connect(function()
				item.BackgroundTransparency = 0.5
				item.BackgroundColor3 = Colors.SlotHover
			end)

			item.MouseLeave:Connect(function()
				if ActiveTheme ~= themeName then
					item.BackgroundTransparency = 1
				end
			end)

			item.MouseButton1Click:Connect(function()
				applyPillTheme(themeName)
				dropBox.Text = themeName
				isOpen = false
				popup.Visible = false
				popup.Size = UDim2.new(0, 110, 0, 0)
			end)
		end

		return count
	end

	dropBox.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			local count = refreshPopup()
			local absPos = dropBox.AbsolutePosition
			local absSize = dropBox.AbsoluteSize
			popup.Position = UDim2.new(0, absPos.X - 3, 0, absPos.Y + absSize.Y + 2)
			popup.Visible = true
			local h = math.max(math.min(count, 8) * 26 + 8, 30)
			popup.Size = UDim2.new(0, 110, 0, h)
		else
			popup.Visible = false
			popup.Size = UDim2.new(0, 110, 0, 0)
		end
	end)
end

local miscLockedText = "M\226\128\139i\226\128\139s\226\128\139c"

createSidebarButton("About", 1, "135090089738327", loadAboutPanel)
createSidebarButton("Farm", 2, "98852406765639", function() end)
createSidebarButton(miscLockedText, 3, "112245774650566", function() end)
createSidebarButton("Setings", 4, "117852848591099", loadSetingsPanel)
createSidebarButton("Info", 5, "117372440865704", loadInfoPanel)

task.wait(0.1)

activeTab = sidebarButtons[1]
if sidebarButtons[1] then
	local lbl = sidebarButtons[1]:FindFirstChild("Label")
	if lbl then
		lbl.TextColor3 = Colors.Text
	end
	TweenService:Create(sidebarButtons[1], TweenInfo.new(0.15), {
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Colors.SlotHover
	}):Play()
end

loadAboutPanel()

print("ZORX Hub - Full Service Loaded Successfully!")
