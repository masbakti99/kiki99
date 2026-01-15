local HttpService, CoreGui, Players, RbxAnalyticsService = game:GetService("HttpService"), game:GetService("CoreGui"), game:GetService("Players"), game:GetService("RbxAnalyticsService")
local cloneref, gethui = cloneref or function(o) return o end, gethui or function() return CoreGui end
CoreGui, Players = cloneref(game:GetService("CoreGui")), cloneref(game:GetService("Players"))
local VirtualInputManager, UserInputService, RunService, TweenService = cloneref(game:GetService("VirtualInputManager")), cloneref(game:GetService("UserInputService")), cloneref(game:GetService("RunService")), cloneref(game:GetService("TweenService"))
local LogService, GuiService = cloneref(game:GetService("LogService")), cloneref(game:GetService("GuiService"))
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local TOGGLE_KEY, MIN_CPM, MAX_CPM_LEGIT, MAX_CPM_BLATANT = Enum.KeyCode.RightControl, 50, 1500, 3000
math.randomseed(os.time())

local THEME = { Background = Color3.fromRGB(20, 20, 24), ItemBG = Color3.fromRGB(32, 32, 38), Accent = Color3.fromRGB(114, 100, 255), Text = Color3.fromRGB(240, 240, 240), SubText = Color3.fromRGB(150, 150, 160), Success = Color3.fromRGB(100, 255, 140), Warning = Color3.fromRGB(255, 200, 80), Slider = Color3.fromRGB(60, 60, 70) }
local function ColorToRGB(c) return string.format("%d,%d,%d", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)) end

local ConfigFile = "WordHelper_Config.json"
local Config = { CPM = 550, Blatant = false, Humanize = true, FingerModel = true, SortMode = "Random", SuffixMode = "", LengthMode = 0, AutoPlay = false, AutoJoin = false, AutoJoinSettings = { _1v1 = true, _4p = true, _8p = true }, PanicMode = true, ShowKeyboard = false, ErrorRate = 5, ThinkDelay = 0.8, RiskyMistakes = false, CustomWords = {}, MinTypeSpeed = 50, MaxTypeSpeed = 3000, KeyboardLayout = "QWERTY" }

local function SaveConfig() if writefile then writefile(ConfigFile, HttpService:JSONEncode(Config)) end end
local function LoadConfig() if isfile and isfile(ConfigFile) then local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end); if success and decoded then for k, v in pairs(decoded) do Config[k] = v end end end end
LoadConfig()

local currentCPM, isBlatant, useHumanization, useFingerModel = Config.CPM, Config.Blatant, Config.Humanize, Config.FingerModel
local sortMode, suffixMode, lengthMode, autoPlay = Config.SortMode, Config.SuffixMode or "", Config.LengthMode or 0, Config.AutoPlay
local autoJoin, panicMode, showKeyboard, errorRate = Config.AutoJoin, Config.PanicMode, Config.ShowKeyboard, Config.ErrorRate
local thinkDelayCurrent, riskyMistakes, keyboardLayout = Config.ThinkDelay, Config.RiskyMistakes, Config.KeyboardLayout or "QWERTY"

local isTyping, isAutoPlayScheduled, lastTypingStart, runConn, inputConn, logConn, unloaded = false, false, 0, nil, nil, nil, false
local isMyTurnLogDetected, logRequiredLetters, turnExpiryTime, Blacklist, UsedWords = false, "", 0, {}, {}
local RandomOrderCache, RandomPriority, lastDetected, lastLogicUpdate = {}, {}, "---", 0
local lastAutoJoinCheck, lastWordCheck, cachedDetected, cachedCensored = 0, 0, "", false
local LOGIC_RATE, AUTO_JOIN_RATE, UpdateList, ButtonCache, ButtonData, JoinDebounce = 0.1, 0.5, nil, {}, {}, {}
local thinkDelayMin, thinkDelayMax, listUpdatePending, forceUpdateList = 0.4, 1.2, false, false
local lastInputTime, LIST_DEBOUNCE, currentBestMatch = 0, 0.05, nil

if logConn then logConn:Disconnect() end
logConn = LogService.MessageOut:Connect(function(message, type)
    local wordPart, timePart = message:match("Word:%s*([A-Za-z]+)%s+Time to respond:%s*(%d+)")
    if wordPart and timePart then isMyTurnLogDetected = true; logRequiredLetters = wordPart; turnExpiryTime = tick() + tonumber(timePart) end
end)

local url, fileName = "https://raw.githubusercontent.com/skrylor/english-words/refs/heads/main/merged_english.txt", "ultimate_words_v4.txt"
local LoadingGui = Instance.new("ScreenGui"); LoadingGui.Name = "WordHelperLoading"
local success, parent = pcall(function() return gethui() end); if not success or not parent then parent = game:GetService("CoreGui") end
LoadingGui.Parent = parent; LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local LoadingFrame = Instance.new("Frame", LoadingGui); LoadingFrame.Size = UDim2.new(0, 300, 0, 100); LoadingFrame.Position = UDim2.new(0.5, -150, 0.4, 0); LoadingFrame.BackgroundColor3 = THEME.Background; LoadingFrame.BorderSizePixel = 0
Instance.new("UICorner", LoadingFrame).CornerRadius = UDim.new(0, 10); local LStroke = Instance.new("UIStroke", LoadingFrame); LStroke.Color = THEME.Accent; LStroke.Transparency = 0.5; LStroke.Thickness = 2
local LoadingTitle = Instance.new("TextLabel", LoadingFrame); LoadingTitle.Size = UDim2.new(1, 0, 0, 40); LoadingTitle.BackgroundTransparency = 1; LoadingTitle.Text = "WordHelper V4"; LoadingTitle.TextColor3 = THEME.Accent; LoadingTitle.Font = Enum.Font.GothamBold; LoadingTitle.TextSize = 18
local LoadingStatus = Instance.new("TextLabel", LoadingFrame); LoadingStatus.Size = UDim2.new(1, -20, 0, 30); LoadingStatus.Position = UDim2.new(0, 10, 0, 50); LoadingStatus.BackgroundTransparency = 1; LoadingStatus.Text = "Initializing..."; LoadingStatus.TextColor3 = THEME.Text; LoadingStatus.Font = Enum.Font.Gotham; LoadingStatus.TextSize = 14

local function UpdateStatus(text, color) LoadingStatus.Text = text; if color then LoadingStatus.TextColor3 = color end; game:GetService("RunService").RenderStepped:Wait() end
local function FetchWords()
    UpdateStatus("Fetching latest word list...", THEME.Warning); local success, res = pcall(function() return request({Url = url, Method = "GET"}) end)
    if success and res and res.Body then writefile(fileName, res.Body); UpdateStatus("Fetched successfully!", THEME.Success) else UpdateStatus("Fetch failed! Using cached.", Color3.fromRGB(255, 80, 80)) end
    task.wait(0.5)
end
FetchWords()

local Words, SeenWords = {}, {}
local function LoadList(fname)
    UpdateStatus("Parsing word list...", THEME.Warning)
    if isfile(fname) then
        local content = readfile(fname)
        for w in content:gmatch("[^\r\n]+") do local clean = w:gsub("[%s%c]+", ""):lower(); if #clean > 0 and not SeenWords[clean] then SeenWords[clean] = true; table.insert(Words, clean) end end
        UpdateStatus("Loaded " .. #Words .. " words!", THEME.Success)
    else UpdateStatus("No word list found!", Color3.fromRGB(255, 80, 80)) end
    task.wait(1)
end
LoadList(fileName); if LoadingGui then LoadingGui:Destroy() end

table.sort(Words); Buckets = {}
for _, w in ipairs(Words) do local c = w:sub(1,1) or ""; if c == "" then c = "#" end; Buckets[c] = Buckets[c] or {}; table.insert(Buckets[c], w) end
if Config.CustomWords then
    for _, w in ipairs(Config.CustomWords) do
        local clean = w:gsub("[%s%c]+", ""):lower()
        if #clean > 0 and not SeenWords[clean] then SeenWords[clean] = true; table.insert(Words, clean); local c = clean:sub(1,1) or ""; if c == "" then c = "#" end; Buckets[c] = Buckets[c] or {}; table.insert(Buckets[c], clean) end
    end
end
SeenWords = nil

local function shuffleTable(t) for i = #t, 2, -1 do local j = math.random(i); t[i], t[j] = t[j], t[i] end return t end
local HardLetterScores = { x = 10, z = 9, q = 9, j = 8, v = 6, k = 5, b = 4, f = 3, w = 3, y = 2, g = 2, p = 2 }
local function GetKillerScore(word) local lastChar = word:sub(-1); return HardLetterScores[lastChar] or 0 end
local function getDistance(s1, s2)
    if #s1 == 0 then return #s2 end if #s2 == 0 then return #s1 end if s1 == s2 then return 0 end
    local matrix = {}; for i = 0, #s1 do matrix[i] = {[0] = i} end for j = 0, #s2 do matrix[0][j] = j end
    for i = 1, #s1 do for j = 1, #s2 do local cost = (s1:sub(i,i) == s2:sub(j,j)) and 0 or 1; matrix[i][j] = math.min(matrix[i-1][j]+1, matrix[i][j-1]+1, matrix[i-1][j-1]+cost) end end
    return matrix[#s1][#s2]
end
local function Tween(obj, props, time) TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() end

local function GetCurrentGameWord(providedFrame)
    local frame = providedFrame or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("InGame") and Players.LocalPlayer.PlayerGui.InGame:FindFirstChild("Frame"))
    local container = frame and frame:FindFirstChild("CurrentWord"); if not container then return "", false end
    local detected, censored, letterData = "", false, {}
    for _, c in ipairs(container:GetChildren()) do
        if c:IsA("GuiObject") and c.Visible then local txt = c:FindFirstChild("Letter"); if txt and txt:IsA("TextLabel") and txt.TextTransparency < 1 then table.insert(letterData, { Obj = c, Txt = txt, X = c.AbsolutePosition.X, Id = tonumber(c.Name) or 0 }) end end
    end
    table.sort(letterData, function(a,b) if math.abs(a.X - b.X) > 2 then return a.X < b.X end return a.Id < b.Id end)
    for _, data in ipairs(letterData) do local t = tostring(data.Txt.Text); if t:find("#") or t:find("%*") then censored = true end; detected = detected .. t end
    return detected:lower():gsub(" ", ""), censored
end

local function GetTurnInfo(providedFrame)
    if isMyTurnLogDetected then if tick() < turnExpiryTime then return true, logRequiredLetters else isMyTurnLogDetected = false end end
    local frame = providedFrame or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("InGame") and Players.LocalPlayer.PlayerGui.InGame:FindFirstChild("Frame"))
    local typeLbl = frame and frame:FindFirstChild("Type")
    if typeLbl and typeLbl:IsA("TextLabel") then
        local text, player = typeLbl.Text, Players.LocalPlayer
        if text:sub(1, #player.Name) == player.Name or text:sub(1, #player.DisplayName) == player.DisplayName then return true, text:match("starting with:%s*([A-Za-z])") end
    end
    return false, nil
end

local function GetSecureParent()
    local s, r = pcall(function() return gethui() end); if s and r then return r end
    s, r = pcall(function() return CoreGui end); if s and r then return r end
    return Players.LocalPlayer.PlayerGui
end

local ParentTarget, GuiName = GetSecureParent(), tostring(math.random(1000000, 9999999))
local env = (getgenv and getgenv()) or _G
if env.WordHelperInstance and env.WordHelperInstance.Parent then env.WordHelperInstance:Destroy() end

local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = GuiName; ScreenGui.Parent = ParentTarget; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; env.WordHelperInstance = ScreenGui
local ToastContainer = Instance.new("Frame", ScreenGui); ToastContainer.Name = "ToastContainer"; ToastContainer.Size = UDim2.new(0, 300, 1, 0); ToastContainer.Position = UDim2.new(1, -320, 0, 20); ToastContainer.BackgroundTransparency = 1; ToastContainer.ZIndex = 100

local function ShowToast(message, type)
    local toast = Instance.new("Frame", ToastContainer); toast.Size = UDim2.new(1, 0, 0, 40); toast.BackgroundColor3 = THEME.ItemBG; toast.BorderSizePixel = 0; toast.BackgroundTransparency = 1
    local stroke = Instance.new("UIStroke", toast); stroke.Thickness = 1.5; stroke.Transparency = 1
    local color = (type == "success" and THEME.Success) or (type == "warning" and THEME.Warning) or (type == "error" and Color3.fromRGB(255, 80, 80)) or THEME.Text
    stroke.Color = color; Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", toast); lbl.Size = UDim2.new(1, -20, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = message; lbl.TextColor3 = color; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 14; lbl.TextWrapped = true; lbl.TextTransparency = 1
    Tween(toast, {BackgroundTransparency = 0.1}, 0.3); Tween(lbl, {TextTransparency = 0}, 0.3); Tween(stroke, {Transparency = 0.2}, 0.3)
    task.delay(3, function() if toast and toast.Parent then Tween(toast, {BackgroundTransparency = 1}, 0.5); Tween(lbl, {TextTransparency = 1}, 0.5); Tween(stroke, {Transparency = 1}, 0.5); task.wait(0.5); toast:Destroy() end end)
end

local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 300, 0, 500); MainFrame.Position = UDim2.new(0.8, -50, 0.4, 0); MainFrame.BackgroundColor3 = THEME.Background; MainFrame.BorderSizePixel = 0; MainFrame.Active = true; MainFrame.ClipsDescendants = true
local function EnableDragging(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = frame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
    frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end
EnableDragging(MainFrame); Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10); local Stroke = Instance.new("UIStroke", MainFrame); Stroke.Color = THEME.Accent; Stroke.Transparency = 0.5; Stroke.Thickness = 2

local Header = Instance.new("Frame", MainFrame); Header.Size = UDim2.new(1, 0, 0, 45); Header.BackgroundColor3 = THEME.ItemBG; Header.BorderSizePixel = 0
local Title = Instance.new("TextLabel", Header); Title.Text = "Word<font color=\"rgb(114,100,255)\">Helper</font> V4"; Title.RichText = true; Title.Font = Enum.Font.GothamBold; Title.TextSize = 18; Title.TextColor3 = THEME.Text; Title.Size = UDim2.new(1, -50, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left
local MinBtn = Instance.new("TextButton", Header); MinBtn.Text = "-"; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 24; MinBtn.TextColor3 = THEME.SubText; MinBtn.Size = UDim2.new(0, 45, 1, 0); MinBtn.Position = UDim2.new(1, -90, 0, 0); MinBtn.BackgroundTransparency = 1
local CloseBtn = Instance.new("TextButton", Header); CloseBtn.Text = "X"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn.Size = UDim2.new(0, 45, 1, 0); CloseBtn.Position = UDim2.new(1, -45, 0, 0); CloseBtn.BackgroundTransparency = 1

CloseBtn.MouseButton1Click:Connect(function()
    unloaded = true; if runConn then runConn:Disconnect() runConn = nil end; if inputConn then inputConn:Disconnect() inputConn = nil end; if logConn then logConn:Disconnect() logConn = nil end
    for _, btn in ipairs(ButtonCache) do btn:Destroy() end; table.clear(ButtonCache); if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
end)

local StatusFrame = Instance.new("Frame", MainFrame); StatusFrame.Size = UDim2.new(1, -30, 0, 24); StatusFrame.Position = UDim2.new(0, 15, 0, 55); StatusFrame.BackgroundTransparency = 1
local StatusDot = Instance.new("Frame", StatusFrame); StatusDot.Size = UDim2.new(0, 8, 0, 8); StatusDot.Position = UDim2.new(0, 0, 0.5, -4); StatusDot.BackgroundColor3 = THEME.SubText; Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)
local StatusText = Instance.new("TextLabel", StatusFrame); StatusText.Text = "Idle..."; StatusText.RichText = true; StatusText.Font = Enum.Font.Gotham; StatusText.TextSize = 12; StatusText.TextColor3 = THEME.SubText; StatusText.Size = UDim2.new(1, -15, 1, 0); StatusText.Position = UDim2.new(0, 15, 0, 0); StatusText.BackgroundTransparency = 1; StatusText.TextXAlignment = Enum.TextXAlignment.Left

local SearchFrame = Instance.new("Frame", MainFrame); SearchFrame.Size = UDim2.new(1, -10, 0, 26); SearchFrame.Position = UDim2.new(0, 5, 0, 82); SearchFrame.BackgroundColor3 = THEME.ItemBG; Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0, 6)
local SearchBox = Instance.new("TextBox", SearchFrame); SearchBox.Size = UDim2.new(1, -20, 1, 0); SearchBox.Position = UDim2.new(0, 10, 0, 0); SearchBox.BackgroundTransparency = 1; SearchBox.Font = Enum.Font.Gotham; SearchBox.TextSize = 14; SearchBox.TextColor3 = THEME.Text; SearchBox.PlaceholderText = "Search words..."; SearchBox.PlaceholderColor3 = THEME.SubText; SearchBox.Text = ""; SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox:GetPropertyChangedSignal("Text"):Connect(function() if UpdateList then UpdateList(lastDetected, lastRequiredLetter) end end)

local ScrollList = Instance.new("ScrollingFrame", MainFrame); ScrollList.Size = UDim2.new(1, -10, 1, -220); ScrollList.Position = UDim2.new(0, 5, 0, 115); ScrollList.BackgroundTransparency = 1; ScrollList.ScrollBarThickness = 3; ScrollList.ScrollBarImageColor3 = THEME.Accent; ScrollList.CanvasSize = UDim2.new(0,0,0,0)
local UIListLayout = Instance.new("UIListLayout", ScrollList); UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 4)

local SettingsFrame = Instance.new("Frame", MainFrame); SettingsFrame.BackgroundColor3 = THEME.ItemBG; SettingsFrame.BorderSizePixel = 0; SettingsFrame.ClipsDescendants = true
local SlidersFrame = Instance.new("Frame", SettingsFrame); SlidersFrame.Size = UDim2.new(1, 0, 0, 125); SlidersFrame.BackgroundTransparency = 1
local TogglesFrame = Instance.new("Frame", SettingsFrame); TogglesFrame.Size = UDim2.new(1, 0, 0, 310); TogglesFrame.Position = UDim2.new(0, 0, 0, 125); TogglesFrame.BackgroundTransparency = 1; TogglesFrame.Visible = false
local sep = Instance.new("Frame", SettingsFrame); sep.Size = UDim2.new(1, 0, 0, 1); sep.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
local settingsCollapsed = true
local function UpdateLayout()
    if settingsCollapsed then Tween(SettingsFrame, {Size = UDim2.new(1, 0, 0, 125), Position = UDim2.new(0, 0, 1, -125)}); Tween(ScrollList, {Size = UDim2.new(1, -10, 1, -245)}); TogglesFrame.Visible = false
    else Tween(SettingsFrame, {Size = UDim2.new(1, 0, 0, 435), Position = UDim2.new(0, 0, 1, -435)}); Tween(ScrollList, {Size = UDim2.new(1, -10, 1, -555)}); TogglesFrame.Visible = true end
end
UpdateLayout()

local ExpandBtn = Instance.new("TextButton", SlidersFrame); ExpandBtn.Text = "v Show Settings v"; ExpandBtn.Font = Enum.Font.GothamBold; ExpandBtn.TextSize = 14; ExpandBtn.TextColor3 = THEME.Accent; ExpandBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); ExpandBtn.BackgroundTransparency = 0.5; ExpandBtn.Size = UDim2.new(1, -10, 0, 30); ExpandBtn.Position = UDim2.new(0, 5, 1, -35); Instance.new("UICorner", ExpandBtn).CornerRadius = UDim.new(0, 6)
ExpandBtn.MouseButton1Click:Connect(function() settingsCollapsed = not settingsCollapsed; ExpandBtn.Text = settingsCollapsed and "v Show Settings v" or "^ Hide Settings ^"; UpdateLayout() end)

local function SetupSlider(btn, bg, fill, callback)
    btn.MouseButton1Down:Connect(function()
        local move, rel
        local function Update() local mousePos = UserInputService:GetMouseLocation(); local relX = math.clamp(mousePos.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X); local pct = relX / bg.AbsoluteSize.X; callback(pct); Config.CPM, Config.ErrorRate, Config.ThinkDelay = currentCPM, errorRate, thinkDelayCurrent end
        Update(); move = RunService.RenderStepped:Connect(Update)
        rel = UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then if move then move:Disconnect() move = nil end; if rel then rel:Disconnect() rel = nil end; SaveConfig() end end)
    end)
end

local KeyboardFrame = Instance.new("Frame", ScreenGui); KeyboardFrame.Name = "KeyboardFrame"; KeyboardFrame.Size = UDim2.new(0, 400, 0, 160); KeyboardFrame.Position = UDim2.new(0.1, 0, 0.5, -80); KeyboardFrame.BackgroundColor3 = THEME.Background; KeyboardFrame.Visible = showKeyboard; EnableDragging(KeyboardFrame); Instance.new("UICorner", KeyboardFrame).CornerRadius = UDim.new(0, 8); local KStroke = Instance.new("UIStroke", KeyboardFrame); KStroke.Color = THEME.Accent; KStroke.Transparency = 0.6; KStroke.Thickness = 2
local Keys = {}
local function CreateKey(char, pos, size)
    local k = Instance.new("Frame", KeyboardFrame); k.Size = size or UDim2.new(0, 30, 0, 30); k.Position = pos; k.BackgroundColor3 = THEME.ItemBG; Instance.new("UICorner", k).CornerRadius = UDim.new(0, 4)
    local l = Instance.new("TextLabel", k); l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1; l.Text = char:upper(); l.TextColor3 = THEME.Text; l.Font = Enum.Font.GothamBold; l.TextSize = 14; Keys[char:lower()] = k; return k
end

local function GenerateKeyboard()
    for _, c in ipairs(KeyboardFrame:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end; Keys = {}
    local rows = (keyboardLayout == "QWERTZ" and {{"q","w","e","r","t","z","u","i","o","p"},{"a","s","d","f","g","h","j","k","l"},{"y","x","c","v","b","n","m"}}) or (keyboardLayout == "AZERTY" and {{"a","z","e","r","t","y","u","i","o","p"},{"q","s","d","f","g","h","j","k","l","m"},{"w","x","c","v","b","n"}}) or {{"q","w","e","r","t","y","u","i","o","p"},{"a","s","d","f","g","h","j","k","l"},{"z","x","c","v","b","n","m"}}
    local startY = 15; for r, rowChars in ipairs(rows) do local rowWidth = #rowChars * 35; local startX = (400 - rowWidth) / 2; for i, char in ipairs(rowChars) do CreateKey(char, UDim2.new(0, startX + (i-1)*35, 0, startY + (r-1)*35)) end end
    local space = CreateKey(" ", UDim2.new(0.5, -100, 0, startY + 3*35), UDim2.new(0, 200, 0, 30)); space.FindFirstChild(space, "TextLabel").Text = "SPACE"
end
GenerateKeyboard()

local function CreateDropdown(parent, text, options, default, callback)
    local container = Instance.new("Frame", parent); container.Size = UDim2.new(0, 130, 0, 24); container.BackgroundColor3 = THEME.Background; container.ZIndex = 10; Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)
    local mainBtn = Instance.new("TextButton", container); mainBtn.Size = UDim2.new(1, 0, 1, 0); mainBtn.BackgroundTransparency = 1; mainBtn.Text = text .. ": " .. default; mainBtn.Font = Enum.Font.GothamMedium; mainBtn.TextSize = 11; mainBtn.TextColor3 = THEME.Accent; mainBtn.ZIndex = 11
    local listFrame = Instance.new("Frame", container); listFrame.Size = UDim2.new(1, 0, 0, #options * 24); listFrame.Position = UDim2.new(0, 0, 1, 2); listFrame.BackgroundColor3 = THEME.ItemBG; listFrame.Visible = false; listFrame.ZIndex = 20; Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4)
    local isOpen = false
    mainBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; listFrame.Visible = isOpen end)
    for i, opt in ipairs(options) do
        local btn = Instance.new("TextButton", listFrame); btn.Size = UDim2.new(1, 0, 0, 24); btn.Position = UDim2.new(0, 0, 0, (i-1)*24); btn.BackgroundTransparency = 1; btn.Text = opt; btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.TextColor3 = THEME.Text; btn.ZIndex = 21
        btn.MouseButton1Click:Connect(function() mainBtn.Text = text .. ": " .. opt; isOpen = false; listFrame.Visible = false; callback(opt) end)
    end
    return container
end

local LayoutDropdown = CreateDropdown(TogglesFrame, "Layout", {"QWERTY", "QWERTZ", "AZERTY"}, keyboardLayout, function(val) keyboardLayout = val; Config.KeyboardLayout = keyboardLayout; GenerateKeyboard(); SaveConfig() end); LayoutDropdown.Position = UDim2.new(0, 150, 0, 145)

UserInputService.InputBegan:Connect(function(input)
    if not showKeyboard then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then local char = input.KeyCode.Name:lower(); if Keys[char] then Tween(Keys[char], {BackgroundColor3 = THEME.Accent}, 0.1) end; if input.KeyCode == Enum.KeyCode.Space then Tween(Keys[" "], {BackgroundColor3 = THEME.Accent}, 0.1) end end
end)
UserInputService.InputEnded:Connect(function(input)
    if not showKeyboard then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then local char = input.KeyCode.Name:lower(); if Keys[char] then Tween(Keys[char], {BackgroundColor3 = THEME.ItemBG}, 0.2) end; if input.KeyCode == Enum.KeyCode.Space then Tween(Keys[" "], {BackgroundColor3 = THEME.ItemBG}, 0.2) end end
end)

local SliderLabel = Instance.new("TextLabel", SlidersFrame); SliderLabel.Text = "Speed: " .. currentCPM .. " CPM"; SliderLabel.Font = Enum.Font.GothamMedium; SliderLabel.TextSize = 12; SliderLabel.TextColor3 = THEME.SubText; SliderLabel.Size = UDim2.new(1, -30, 0, 20); SliderLabel.Position = UDim2.new(0, 15, 0, 8); SliderLabel.BackgroundTransparency = 1; SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
local SliderBg = Instance.new("Frame", SlidersFrame); SliderBg.Size = UDim2.new(1, -30, 0, 6); SliderBg.Position = UDim2.new(0, 15, 0, 30); SliderBg.BackgroundColor3 = THEME.Slider; Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
local SliderFill = Instance.new("Frame", SliderBg); SliderFill.Size = UDim2.new(0.5, 0, 1, 0); SliderFill.BackgroundColor3 = THEME.Accent; Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0); local SliderBtn = Instance.new("TextButton", SliderBg); SliderBtn.Size = UDim2.new(1,0,1,0); SliderBtn.BackgroundTransparency = 1; SliderBtn.Text = ""

local ErrorLabel = Instance.new("TextLabel", SlidersFrame); ErrorLabel.Text = "Error Rate: " .. errorRate .. "%"; ErrorLabel.Font = Enum.Font.GothamMedium; ErrorLabel.TextSize = 11; ErrorLabel.TextColor3 = THEME.SubText; ErrorLabel.Size = UDim2.new(1, -30, 0, 18); ErrorLabel.Position = UDim2.new(0, 15, 0, 36); ErrorLabel.BackgroundTransparency = 1; ErrorLabel.TextXAlignment = Enum.TextXAlignment.Left
local ErrorBg = Instance.new("Frame", SlidersFrame); ErrorBg.Size = UDim2.new(1, -30, 0, 6); ErrorBg.Position = UDim2.new(0, 15, 0, 56); ErrorBg.BackgroundColor3 = THEME.Slider; Instance.new("UICorner", ErrorBg).CornerRadius = UDim.new(1, 0)
local ErrorFill = Instance.new("Frame", ErrorBg); ErrorFill.Size = UDim2.new(errorRate/30, 0, 1, 0); ErrorFill.BackgroundColor3 = Color3.fromRGB(200, 100, 100); Instance.new("UICorner", ErrorFill).CornerRadius = UDim.new(1, 0); local ErrorBtn = Instance.new("TextButton", ErrorBg); ErrorBtn.Size = UDim2.new(1,0,1,0); ErrorBtn.BackgroundTransparency = 1; ErrorBtn.Text = ""
SetupSlider(ErrorBtn, ErrorBg, ErrorFill, function(pct) errorRate = math.floor(pct * 30); Config.ErrorRate = errorRate; ErrorFill.Size = UDim2.new(pct, 0, 1, 0); ErrorLabel.Text = "Error Rate: " .. errorRate .. "% (per-letter)" end)

local ThinkLabel = Instance.new("TextLabel", SlidersFrame); ThinkLabel.Text = string.format("Think: %.2fs", thinkDelayCurrent); ThinkLabel.Font = Enum.Font.GothamMedium; ThinkLabel.TextSize = 11; ThinkLabel.TextColor3 = THEME.SubText; ThinkLabel.Size = UDim2.new(1, -30, 0, 18); ThinkLabel.Position = UDim2.new(0, 15, 0, 62); ThinkLabel.BackgroundTransparency = 1; ThinkLabel.TextXAlignment = Enum.TextXAlignment.Left
local ThinkBg = Instance.new("Frame", SlidersFrame); ThinkBg.Size = UDim2.new(1, -30, 0, 6); ThinkBg.Position = UDim2.new(0, 15, 0, 82); ThinkBg.BackgroundColor3 = THEME.Slider; Instance.new("UICorner", ThinkBg).CornerRadius = UDim.new(1, 0)
local ThinkFill = Instance.new("Frame", ThinkBg); local thinkPct = (thinkDelayCurrent - thinkDelayMin) / (thinkDelayMax - thinkDelayMin); ThinkFill.Size = UDim2.new(thinkPct, 0, 1, 0); ThinkFill.BackgroundColor3 = THEME.Accent; Instance.new("UICorner", ThinkFill).CornerRadius = UDim.new(1, 0); local ThinkBtn = Instance.new("TextButton", ThinkBg); ThinkBtn.Size = UDim2.new(1,0,1,0); ThinkBtn.BackgroundTransparency = 1; ThinkBtn.Text = ""
SetupSlider(ThinkBtn, ThinkBg, ThinkFill, function(pct) thinkDelayCurrent = thinkDelayMin + pct * (thinkDelayMax - thinkDelayMin); Config.ThinkDelay = thinkDelayCurrent; ThinkFill.Size = UDim2.new(pct, 0, 1, 0); ThinkLabel.Text = string.format("Think: %.2fs", thinkDelayCurrent) end)

local function CreateToggle(text, pos, callback)
    local btn = Instance.new("TextButton", TogglesFrame); btn.Text = text; btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11; btn.TextColor3 = THEME.Success; btn.BackgroundColor3 = THEME.Background; btn.Size = UDim2.new(0, 85, 0, 24); btn.Position = pos; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function() local newState, newText, newColor = callback(); btn.Text = newText; btn.TextColor3 = newColor; SaveConfig() end); return btn
end

local HumanizeBtn = CreateToggle("Humanize: "..(useHumanization and "ON" or "OFF"), UDim2.new(0, 15, 0, 5), function() useHumanization = not useHumanization; Config.Humanize = useHumanization; return useHumanization, "Humanize: "..(useHumanization and "ON" or "OFF"), useHumanization and THEME.Success or Color3.fromRGB(255, 100, 100) end)
HumanizeBtn.TextColor3 = useHumanization and THEME.Success or Color3.fromRGB(255, 100, 100)
local FingerBtn = CreateToggle("10-Finger: "..(useFingerModel and "ON" or "OFF"), UDim2.new(0, 105, 0, 5), function() useFingerModel = not useFingerModel; Config.FingerModel = useFingerModel; return useFingerModel, "10-Finger: "..(useFingerModel and "ON" or "OFF"), useFingerModel and THEME.Success or Color3.fromRGB(255, 100, 100) end)
FingerBtn.TextColor3 = useFingerModel and THEME.Success or Color3.fromRGB(255, 100, 100)
local KeyboardBtn = CreateToggle("Keyboard: "..(showKeyboard and "ON" or "OFF"), UDim2.new(0, 195, 0, 5), function() showKeyboard = not showKeyboard; Config.ShowKeyboard = showKeyboard; KeyboardFrame.Visible = showKeyboard; return showKeyboard, "Keyboard: "..(showKeyboard and "ON" or "OFF"), showKeyboard and THEME.Success or Color3.fromRGB(255, 100, 100) end)
KeyboardBtn.TextColor3 = showKeyboard and THEME.Success or Color3.fromRGB(255, 100, 100)
local SortBtn = CreateToggle("Sort: "..sortMode, UDim2.new(0, 15, 0, 33), function() sortMode = (sortMode == "Random" and "Shortest") or (sortMode == "Shortest" and "Longest") or (sortMode == "Longest" and "Killer") or "Random"; Config.SortMode = sortMode; lastDetected = "---"; return true, "Sort: "..sortMode, THEME.Accent end); SortBtn.TextColor3 = THEME.Accent; SortBtn.Size = UDim2.new(0, 130, 0, 24)
local AutoBtn = CreateToggle("Auto Play: "..(autoPlay and "ON" or "OFF"), UDim2.new(0, 150, 0, 33), function() autoPlay = not autoPlay; Config.AutoPlay = autoPlay; return autoPlay, "Auto Play: "..(autoPlay and "ON" or "OFF"), autoPlay and THEME.Success or Color3.fromRGB(255, 100, 100) end); AutoBtn.TextColor3 = autoPlay and THEME.Success or Color3.fromRGB(255, 100, 100); AutoBtn.Size = UDim2.new(0, 130, 0, 24)
local AutoJoinBtn = CreateToggle("Auto Join: "..(autoJoin and "ON" or "OFF"), UDim2.new(0, 15, 0, 61), function() autoJoin = not autoJoin; Config.AutoJoin = autoJoin; return autoJoin, "Auto Join: "..(autoJoin and "ON" or "OFF"), autoJoin and THEME.Success or Color3.fromRGB(255, 100, 100) end); AutoJoinBtn.TextColor3 = autoJoin and THEME.Success or Color3.fromRGB(255, 100, 100); AutoJoinBtn.Size = UDim2.new(0, 265, 0, 24)

local function CreateCheckbox(text, pos, key)
    local container = Instance.new("TextButton", TogglesFrame); container.Size = UDim2.new(0, 90, 0, 24); container.Position = pos; container.BackgroundColor3 = THEME.ItemBG; container.AutoButtonColor = false; container.Text = ""; Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)
    local box = Instance.new("Frame", container); box.Size = UDim2.new(0, 14, 0, 14); box.Position = UDim2.new(0, 5, 0.5, -7); box.BackgroundColor3 = THEME.Slider; Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)
    local check = Instance.new("Frame", box); check.Size = UDim2.new(0, 8, 0, 8); check.Position = UDim2.new(0.5, -4, 0.5, -4); check.BackgroundColor3 = THEME.Success; check.Visible = Config.AutoJoinSettings[key]; Instance.new("UICorner", check).CornerRadius = UDim.new(0, 2)
    local lbl = Instance.new("TextLabel", container); lbl.Text = text; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11; lbl.TextColor3 = THEME.SubText; lbl.Size = UDim2.new(1, -25, 1, 0); lbl.Position = UDim2.new(0, 25, 0, 0); lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    container.MouseButton1Click:Connect(function() Config.AutoJoinSettings[key] = not Config.AutoJoinSettings[key]; check.Visible = Config.AutoJoinSettings[key]; lbl.TextColor3 = Config.AutoJoinSettings[key] and THEME.Text or THEME.SubText; Tween(box, {BackgroundColor3 = Config.AutoJoinSettings[key] and THEME.Accent or THEME.Slider}, 0.2); SaveConfig() end)
    if Config.AutoJoinSettings[key] then lbl.TextColor3 = THEME.Text; box.BackgroundColor3 = THEME.Accent end
    return container
end

CreateCheckbox("1v1", UDim2.new(0, 15, 0, 88), "_1v1"); CreateCheckbox("4 Player", UDim2.new(0, 110, 0, 88), "_4p"); CreateCheckbox("8 Player", UDim2.new(0, 205, 0, 88), "_8p")

local BlatantBtn = CreateToggle("Blatant Mode: "..(isBlatant and "ON" or "OFF"), UDim2.new(0, 15, 0, 115), function() isBlatant = not isBlatant; Config.Blatant = isBlatant; return isBlatant, "Blatant Mode: "..(isBlatant and "ON" or "OFF"), isBlatant and Color3.fromRGB(255, 80, 80) or THEME.SubText end); BlatantBtn.TextColor3 = isBlatant and Color3.fromRGB(255, 80, 80) or THEME.SubText; BlatantBtn.Size = UDim2.new(0, 130, 0, 24)
local RiskyBtn = CreateToggle("Risky Mistakes: "..(riskyMistakes and "ON" or "OFF"), UDim2.new(0, 150, 0, 115), function() riskyMistakes = not riskyMistakes; Config.RiskyMistakes = riskyMistakes; return riskyMistakes, "Risky Mistakes: "..(riskyMistakes and "ON" or "OFF"), riskyMistakes and Color3.fromRGB(255, 80, 80) or THEME.SubText end); RiskyBtn.TextColor3 = riskyMistakes and Color3.fromRGB(255, 80, 80) or THEME.SubText; RiskyBtn.Size = UDim2.new(0, 130, 0, 24)

local ManageWordsBtn = Instance.new("TextButton", TogglesFrame); ManageWordsBtn.Text = "Manage Custom Words"; ManageWordsBtn.Font = Enum.Font.GothamMedium; ManageWordsBtn.TextSize = 11; ManageWordsBtn.TextColor3 = THEME.Accent; ManageWordsBtn.BackgroundColor3 = THEME.Background; ManageWordsBtn.Size = UDim2.new(0, 130, 0, 24); ManageWordsBtn.Position = UDim2.new(0, 15, 0, 145); Instance.new("UICorner", ManageWordsBtn).CornerRadius = UDim.new(0, 4)
local WordBrowserBtn = Instance.new("TextButton", TogglesFrame); WordBrowserBtn.Text = "Word Browser"; WordBrowserBtn.Font = Enum.Font.GothamMedium; WordBrowserBtn.TextSize = 11; WordBrowserBtn.TextColor3 = Color3.fromRGB(200, 150, 255); WordBrowserBtn.BackgroundColor3 = THEME.Background; WordBrowserBtn.Size = UDim2.new(0, 265, 0, 24); WordBrowserBtn.Position = UDim2.new(0, 15, 0, 175); Instance.new("UICorner", WordBrowserBtn).CornerRadius = UDim.new(0, 4)
local ServerBrowserBtn = Instance.new("TextButton", TogglesFrame); ServerBrowserBtn.Text = "Server Browser"; ServerBrowserBtn.Font = Enum.Font.GothamMedium; ServerBrowserBtn.TextSize = 11; ServerBrowserBtn.TextColor3 = Color3.fromRGB(100, 200, 255); ServerBrowserBtn.BackgroundColor3 = THEME.Background; ServerBrowserBtn.Size = UDim2.new(0, 265, 0, 24); ServerBrowserBtn.Position = UDim2.new(0, 15, 0, 205); Instance.new("UICorner", ServerBrowserBtn).CornerRadius = UDim.new(0, 4)

local CustomWordsFrame = Instance.new("Frame", ScreenGui); CustomWordsFrame.Name = "CustomWordsFrame"; CustomWordsFrame.Size = UDim2.new(0, 250, 0, 350); CustomWordsFrame.Position = UDim2.new(0.5, -125, 0.5, -175); CustomWordsFrame.BackgroundColor3 = THEME.Background; CustomWordsFrame.Visible = false; CustomWordsFrame.ClipsDescendants = true; EnableDragging(CustomWordsFrame); Instance.new("UICorner", CustomWordsFrame).CornerRadius = UDim.new(0, 8); local CWStroke = Instance.new("UIStroke", CustomWordsFrame); CWStroke.Color = THEME.Accent; CWStroke.Transparency = 0.5; CWStroke.Thickness = 2
local CWHeader = Instance.new("TextLabel", CustomWordsFrame); CWHeader.Text = "Custom Words Manager"; CWHeader.Font = Enum.Font.GothamBold; CWHeader.TextSize = 14; CWHeader.TextColor3 = THEME.Text; CWHeader.Size = UDim2.new(1, 0, 0, 35); CWHeader.BackgroundTransparency = 1
local CWCloseBtn = Instance.new("TextButton", CustomWordsFrame); CWCloseBtn.Text = "X"; CWCloseBtn.Font = Enum.Font.GothamBold; CWCloseBtn.TextSize = 14; CWCloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100); CWCloseBtn.Size = UDim2.new(0, 30, 0, 30); CWCloseBtn.Position = UDim2.new(1, -30, 0, 2); CWCloseBtn.BackgroundTransparency = 1; CWCloseBtn.MouseButton1Click:Connect(function() CustomWordsFrame.Visible = false end)
ManageWordsBtn.MouseButton1Click:Connect(function() CustomWordsFrame.Visible = not CustomWordsFrame.Visible; CustomWordsFrame.Parent = nil; CustomWordsFrame.Parent = ScreenGui end)

local function SetupPhantomBox(box, placeholder)
    box.Text = placeholder; box.TextColor3 = THEME.SubText; box.Focused:Connect(function() if box.Text == placeholder then box.Text = ""; box.TextColor3 = THEME.Text end end)
    box.FocusLost:Connect(function() if box.Text == "" then box.Text = placeholder; box.TextColor3 = THEME.SubText end end)
end

local CWSearchBox = Instance.new("TextBox", CustomWordsFrame); CWSearchBox.Font = Enum.Font.Gotham; CWSearchBox.TextSize = 12; CWSearchBox.BackgroundColor3 = THEME.ItemBG; CWSearchBox.Size = UDim2.new(1, -20, 0, 24); CWSearchBox.Position = UDim2.new(0, 10, 0, 35); Instance.new("UICorner", CWSearchBox).CornerRadius = UDim.new(0, 4); SetupPhantomBox(CWSearchBox, "Search words...")
local CWScroll = Instance.new("ScrollingFrame", CustomWordsFrame); CWScroll.Size = UDim2.new(1, -10, 1, -110); CWScroll.Position = UDim2.new(0, 5, 0, 65); CWScroll.BackgroundTransparency = 1; CWScroll.ScrollBarThickness = 2; CWScroll.ScrollBarImageColor3 = THEME.Accent; CWScroll.CanvasSize = UDim2.new(0,0,0,0); local CWListLayout = Instance.new("UIListLayout", CWScroll); CWListLayout.SortOrder = Enum.SortOrder.LayoutOrder; CWListLayout.Padding = UDim.new(0, 2)
local CWAddBox = Instance.new("TextBox", CustomWordsFrame); CWAddBox.Font = Enum.Font.Gotham; CWAddBox.TextSize = 12; CWAddBox.BackgroundColor3 = THEME.ItemBG; CWAddBox.Size = UDim2.new(0, 170, 0, 24); CWAddBox.Position = UDim2.new(0, 10, 1, -35); Instance.new("UICorner", CWAddBox).CornerRadius = UDim.new(0, 4); SetupPhantomBox(CWAddBox, "Add new word...")
local CWAddBtn = Instance.new("TextButton", CustomWordsFrame); CWAddBtn.Text = "Add"; CWAddBtn.Font = Enum.Font.GothamBold; CWAddBtn.TextSize = 11; CWAddBtn.TextColor3 = THEME.Success; CWAddBtn.BackgroundColor3 = THEME.ItemBG; CWAddBtn.Size = UDim2.new(0, 50, 0, 24); CWAddBtn.Position = UDim2.new(1, -60, 1, -35); Instance.new("UICorner", CWAddBtn).CornerRadius = UDim.new(0, 4)

local function RefreshCustomWords()
    for _, c in ipairs(CWScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local queryRaw, list, shownCount = CWSearchBox.Text, Config.CustomWords or {}, 0; local query = (queryRaw == "Search words...") and "" or queryRaw:lower():gsub("[%s%c]+", "")
    for i, w in ipairs(list) do
        if query == "" or w:find(query, 1, true) then
            shownCount = shownCount + 1; local row = Instance.new("TextButton", CWScroll); row.Size = UDim2.new(1, -6, 0, 22); row.BackgroundColor3 = (shownCount % 2 == 0) and Color3.fromRGB(25,25,30) or Color3.fromRGB(30,30,35); row.BorderSizePixel = 0; row.Text = ""; row.AutoButtonColor = false; Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            row.MouseButton1Click:Connect(function() SmartType(w, lastDetected, true, true); Tween(row, {BackgroundColor3 = THEME.Accent}, 0.2); task.delay(0.2, function() Tween(row, {BackgroundColor3 = (shownCount % 2 == 0) and Color3.fromRGB(25,25,30) or Color3.fromRGB(30,30,35)}, 0.2) end) end)
            local lbl = Instance.new("TextLabel", row); lbl.Text = w; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextColor3 = THEME.Text; lbl.Size = UDim2.new(1, -30, 1, 0); lbl.Position = UDim2.new(0, 5, 0, 0); lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
            local del = Instance.new("TextButton", row); del.Text = "X"; del.Font = Enum.Font.GothamBold; del.TextSize = 11; del.TextColor3 = Color3.fromRGB(255, 80, 80); del.Size = UDim2.new(0, 22, 1, 0); del.Position = UDim2.new(1, -22, 0, 0); del.BackgroundTransparency = 1
            del.MouseButton1Click:Connect(function() table.remove(Config.CustomWords, i); SaveConfig(); Blacklist[w] = true; RefreshCustomWords(); ShowToast("Removed: " .. w, "warning") end)
        end
    end
    CWScroll.CanvasSize = UDim2.new(0, 0, 0, shownCount * 24)
end
CWSearchBox:GetPropertyChangedSignal("Text"):Connect(RefreshCustomWords)

CWAddBtn.MouseButton1Click:Connect(function()
    local text = CWAddBox.Text; if text == "Add new word..." then return end
    text = text:gsub("[%s%c]+", ""):lower(); if #text < 2 then return end
    if not Config.CustomWords then Config.CustomWords = {} end
    for _, w in ipairs(Config.CustomWords) do if w == text then ShowToast("Word already in custom list!", "warning"); return end end
    local existsInMain, c = false, text:sub(1,1); if Buckets and Buckets[c] then for _, w in ipairs(Buckets[c]) do if w == text then existsInMain = true break end end end
    if existsInMain then ShowToast("Word already in main dictionary!", "error"); return end
    table.insert(Config.CustomWords, text); SaveConfig(); table.insert(Words, text); if c == "" then c = "#" end; Buckets[c] = Buckets[c] or {}; table.insert(Buckets[c], text)
    CWAddBox.Text = ""; CWAddBox:ReleaseFocus(); RefreshCustomWords(); ShowToast("Added custom word: " .. text, "success")
end)
RefreshCustomWords()

local ServerFrame = Instance.new("Frame", ScreenGui); ServerFrame.Name = "ServerBrowser"; ServerFrame.Size = UDim2.new(0, 350, 0, 400); ServerFrame.Position = UDim2.new(0.5, -175, 0.5, -200); ServerFrame.BackgroundColor3 = THEME.Background; ServerFrame.Visible = false; ServerFrame.ClipsDescendants = true; EnableDragging(ServerFrame); Instance.new("UICorner", ServerFrame).CornerRadius = UDim.new(0, 8); local SBStroke = Instance.new("UIStroke", ServerFrame); SBStroke.Color = THEME.Accent; SBStroke.Transparency = 0.5; SBStroke.Thickness = 2
local SBHeader = Instance.new("TextLabel", ServerFrame); SBHeader.Text = "Server Browser"; SBHeader.Font = Enum.Font.GothamBold; SBHeader.TextSize = 16; SBHeader.TextColor3 = THEME.Text; SBHeader.Size = UDim2.new(1, 0, 0, 40); SBHeader.BackgroundTransparency = 1
local SBClose = Instance.new("TextButton", ServerFrame); SBClose.Text = "X"; SBClose.Font = Enum.Font.GothamBold; SBClose.TextSize = 16; SBClose.TextColor3 = Color3.fromRGB(255, 100, 100); SBClose.Size = UDim2.new(0, 40, 0, 40); SBClose.Position = UDim2.new(1, -40, 0, 0); SBClose.BackgroundTransparency = 1; SBClose.MouseButton1Click:Connect(function() ServerFrame.Visible = false end)
local SBList = Instance.new("ScrollingFrame", ServerFrame); SBList.Size = UDim2.new(1, -20, 1, -90); SBList.Position = UDim2.new(0, 10, 0, 50); SBList.BackgroundTransparency = 1; SBList.ScrollBarThickness = 3; SBList.ScrollBarImageColor3 = THEME.Accent
local SBLayout = Instance.new("UIListLayout", SBList); SBLayout.Padding = UDim.new(0, 5); SBLayout.SortOrder = Enum.SortOrder.LayoutOrder
local ServerSortMode = "Smallest"

local SBSortBtn = Instance.new("TextButton", ServerFrame); SBSortBtn.Text = "Sort: Smallest"; SBSortBtn.Font = Enum.Font.GothamBold; SBSortBtn.TextSize = 12; SBSortBtn.BackgroundColor3 = THEME.ItemBG; SBSortBtn.TextColor3 = THEME.SubText; SBSortBtn.Size = UDim2.new(0.5, -15, 0, 30); SBSortBtn.Position = UDim2.new(0, 10, 1, -40); Instance.new("UICorner", SBSortBtn).CornerRadius = UDim.new(0, 6)
local SBRefresh = Instance.new("TextButton", ServerFrame); SBRefresh.Text = "Refresh"; SBRefresh.Font = Enum.Font.GothamBold; SBRefresh.TextSize = 12; SBRefresh.BackgroundColor3 = THEME.Accent; SBRefresh.Size = UDim2.new(0.5, -15, 0, 30); SBRefresh.Position = UDim2.new(0.5, 5, 1, -40); Instance.new("UICorner", SBRefresh).CornerRadius = UDim.new(0, 6)

local function FetchServers()
    SBRefresh.Text = "..."; for _, c in ipairs(SBList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    task.spawn(function()
        local success, result = pcall(function() return request({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET"}) end)
        if success and result and result.Body then
            local data = HttpService:JSONDecode(result.Body)
            if data and data.data then
                local servers = data.data; table.sort(servers, function(a,b) return (ServerSortMode == "Smallest") and ((a.playing or 0) < (b.playing or 0)) or ((a.playing or 0) > (b.playing or 0)) end)
                for _, srv in ipairs(servers) do
                    if srv.playing and srv.maxPlayers and srv.id ~= game.JobId then
                        local row = Instance.new("Frame", SBList); row.Size = UDim2.new(1, -6, 0, 45); row.BackgroundColor3 = THEME.ItemBG; Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                        local info = Instance.new("TextLabel", row); info.Text = "Players: " .. srv.playing .. " / " .. srv.maxPlayers .. "\nPing: " .. (srv.ping or "?") .. "ms"; info.Size = UDim2.new(0.6, 0, 1, 0); info.Position = UDim2.new(0, 10, 0, 0); info.BackgroundTransparency = 1; info.TextColor3 = THEME.Text; info.Font = Enum.Font.Gotham; info.TextSize = 12; info.TextXAlignment = Enum.TextXAlignment.Left
                        local join = Instance.new("TextButton", row); join.Text = "Join"; join.BackgroundColor3 = Color3.fromRGB(100, 200, 100); join.Size = UDim2.new(0, 80, 0, 25); join.Position = UDim2.new(1, -90, 0.5, -12.5); join.Font = Enum.Font.GothamBold; join.TextSize = 12; join.TextColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", join).CornerRadius = UDim.new(0, 4)
                        join.MouseButton1Click:Connect(function()
                            join.Text = "Joining..."; ShowToast("Teleporting...", "success"); if queue_on_teleport then queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/skrylor/Last-Letter-Script/refs/heads/main/Last%20Letter.lua"))()') end
                            task.spawn(function() local success, err = pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, srv.id, Players.LocalPlayer) end); if not success then join.Text = "Failed"; ShowToast("Teleport Failed: " .. tostring(err), "error"); task.wait(2); join.Text = "Join" end end)
                        end)
                    end
                end
                SBList.CanvasSize = UDim2.new(0,0,0, SBLayout.AbsoluteContentSize.Y)
            end
        else ShowToast("Failed to fetch servers", "error") end
        SBRefresh.Text = "Refresh"
    end)
end
SBSortBtn.MouseButton1Click:Connect(function() ServerSortMode = (ServerSortMode == "Smallest" and "Largest") or "Smallest"; SBSortBtn.Text = "Sort: " .. ServerSortMode; FetchServers() end)
SBRefresh.MouseButton1Click:Connect(FetchServers); ServerBrowserBtn.MouseButton1Click:Connect(function() ServerFrame.Visible = not ServerFrame.Visible; ServerFrame.Parent = nil; ServerFrame.Parent = ScreenGui; if ServerFrame.Visible then FetchServers() end end)

do
    local WordBrowserFrame = Instance.new("Frame", ScreenGui); WordBrowserFrame.Name = "WordBrowser"; WordBrowserFrame.Size = UDim2.new(0, 300, 0, 400); WordBrowserFrame.Position = UDim2.new(0.5, -150, 0.5, -200); WordBrowserFrame.BackgroundColor3 = THEME.Background; WordBrowserFrame.Visible = false; WordBrowserFrame.ClipsDescendants = true; EnableDragging(WordBrowserFrame); Instance.new("UICorner", WordBrowserFrame).CornerRadius = UDim.new(0, 8); local WBStroke = Instance.new("UIStroke", WordBrowserFrame); WBStroke.Color = THEME.Accent; WBStroke.Transparency = 0.5; WBStroke.Thickness = 2
    local WBHeader = Instance.new("TextLabel", WordBrowserFrame); WBHeader.Text = "Word Browser"; WBHeader.Font = Enum.Font.GothamBold; WBHeader.TextSize = 16; WBHeader.TextColor3 = THEME.Text; WBHeader.Size = UDim2.new(1, 0, 0, 40); WBHeader.BackgroundTransparency = 1
    local WBClose = Instance.new("TextButton", WordBrowserFrame); WBClose.Text = "X"; WBClose.Font = Enum.Font.GothamBold; WBClose.TextSize = 16; WBClose.TextColor3 = Color3.fromRGB(255, 100, 100); WBClose.Size = UDim2.new(0, 40, 0, 40); WBClose.Position = UDim2.new(1, -40, 0, 0); WBClose.BackgroundTransparency = 1; WBClose.MouseButton1Click:Connect(function() WordBrowserFrame.Visible = false end)
    local WBStartBox = Instance.new("TextBox", WordBrowserFrame); WBStartBox.Font = Enum.Font.Gotham; WBStartBox.TextSize = 12; WBStartBox.BackgroundColor3 = THEME.ItemBG; WBStartBox.Size = UDim2.new(0.4, 0, 0, 24); WBStartBox.Position = UDim2.new(0, 10, 0, 45); Instance.new("UICorner", WBStartBox).CornerRadius = UDim.new(0, 4); SetupPhantomBox(WBStartBox, "Starts with...")
    local WBEndBox = Instance.new("TextBox", WordBrowserFrame); WBEndBox.Font = Enum.Font.Gotham; WBEndBox.TextSize = 12; WBEndBox.BackgroundColor3 = THEME.ItemBG; WBEndBox.Size = UDim2.new(0.4, 0, 0, 24); WBEndBox.Position = UDim2.new(0.45, 0, 0, 45); Instance.new("UICorner", WBEndBox).CornerRadius = UDim.new(0, 4); SetupPhantomBox(WBEndBox, "Ends with...")
    local WBLengthBox = Instance.new("TextBox", WordBrowserFrame); WBLengthBox.Font = Enum.Font.Gotham; WBLengthBox.TextSize = 12; WBLengthBox.BackgroundColor3 = THEME.ItemBG; WBLengthBox.Size = UDim2.new(0.2, 0, 0, 24); WBLengthBox.Position = UDim2.new(0.02, 0, 0, 80); Instance.new("UICorner", WBLengthBox).CornerRadius = UDim.new(0, 4); SetupPhantomBox(WBLengthBox, "Len...")
    local WBSearchBtn = Instance.new("TextButton", WordBrowserFrame); WBSearchBtn.Text = "Go"; WBSearchBtn.Font = Enum.Font.GothamBold; WBSearchBtn.TextSize = 12; WBSearchBtn.BackgroundColor3 = THEME.Accent; WBSearchBtn.Size = UDim2.new(0.1, 0, 0, 24); WBSearchBtn.Position = UDim2.new(0.88, 0, 0, 45); Instance.new("UICorner", WBSearchBtn).CornerRadius = UDim.new(0, 4)
    local WBList = Instance.new("ScrollingFrame", WordBrowserFrame); WBList.Size = UDim2.new(1, -20, 1, -125); WBList.Position = UDim2.new(0, 10, 0, 115); WBList.BackgroundTransparency = 1; WBList.ScrollBarThickness = 3; WBList.ScrollBarImageColor3 = THEME.Accent; WBList.CanvasSize = UDim2.new(0,0,0,0); local WBLayout = Instance.new("UIListLayout", WBList); WBLayout.Padding = UDim.new(0, 2); WBLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function SearchWords()
        for _, c in ipairs(WBList:GetChildren()) do if c:IsA("GuiObject") and c.Name ~= "UIListLayout" then c:Destroy() end end
        local sVal, eVal, lVal = WBStartBox.Text, WBEndBox.Text, tonumber(WBLengthBox.Text); if sVal == "Starts with..." then sVal = "" end; if eVal == "Ends with..." then eVal = "" end
        sVal = sVal:lower():gsub("[%s%c]+", ""); eVal = eVal:lower():gsub("[%s%c]+", ""); suffixMode = eVal; Config.SuffixMode = eVal; lengthMode = lVal or 0; Config.LengthMode = lengthMode
        if UpdateList then UpdateList(lastDetected, lastRequiredLetter) end; if sVal == "" and eVal == "" and not lVal then return end
        local results, bucket = {}, Words; if sVal ~= "" and Buckets and Buckets[sVal:sub(1,1)] then bucket = Buckets[sVal:sub(1,1)] end
        for _, w in ipairs(bucket) do if ((sVal == "") or (w:sub(1, #sVal) == sVal)) and ((eVal == "") or (w:sub(-#eVal) == eVal)) and ((not lVal) or (#w == lVal)) then table.insert(results, w); if #results >= 200 then break end end end
        for i, w in ipairs(results) do
            local row = Instance.new("TextButton", WBList); row.Size = UDim2.new(1, -6, 0, 22); row.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(25,25,30) or Color3.fromRGB(30,30,35); row.Text = ""; row.AutoButtonColor = false; Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            row.MouseButton1Click:Connect(function() SmartType(w, lastDetected, true, true); Tween(row, {BackgroundColor3 = THEME.Accent}, 0.2); task.delay(0.2, function() Tween(row, {BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(25,25,30) or Color3.fromRGB(30,30,35)}, 0.2) end) end)
            local lbl = Instance.new("TextLabel", row); lbl.Text = w; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextColor3 = THEME.Text; lbl.Size = UDim2.new(1, -10, 1, 0); lbl.Position = UDim2.new(0, 5, 0, 0); lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
        end
        WBList.CanvasSize = UDim2.new(0,0,0, WBLayout.AbsoluteContentSize.Y)
    end
    WBSearchBtn.MouseButton1Click:Connect(SearchWords); WBStartBox.FocusLost:Connect(function(enter) if enter then SearchWords() end end); WBEndBox.FocusLost:Connect(function(enter) if enter then SearchWords() end end); WBLengthBox.FocusLost:Connect(function(enter) if enter then SearchWords() end end)
    WordBrowserBtn.MouseButton1Click:Connect(function() WordBrowserFrame.Visible = not WordBrowserFrame.Visible; WordBrowserFrame.Parent = nil; WordBrowserFrame.Parent = ScreenGui end)
end

local function CalculateDelay() local baseDelay = 60 / currentCPM; local variance = baseDelay * 0.4; return useHumanization and (baseDelay + math.random()*variance - (variance/2)) or baseDelay end
local KEY_POS = {}; do local row1, row2, row3 = "qwertyuiop", "asdfghjkl", "zxcvbnm"; for i=1,#row1 do KEY_POS[row1:sub(i,i)]={x=i,y=1} end for i=1,#row2 do KEY_POS[row2:sub(i,i)]={x=i+0.5,y=2} end for i=1,#row3 do KEY_POS[row3:sub(i,i)]={x=i+1,y=3} end end
local function KeyDistance(a, b) if not a or not b then return 1 end; a, b = a:lower(), b:lower(); local pa, pb = KEY_POS[a], KEY_POS[b]; if not pa or not pb then return 1 end; local dx, dy = pa.x - pb.x, pa.y - pb.y; return math.sqrt(dx*dx + dy*dy) end
local lastKey = nil
local function CalculateDelayForKeys(prevChar, nextChar)
    if isBlatant then return 60 / currentCPM end
    local baseDelay, variance, extra = 60 / currentCPM, (60 / currentCPM) * 0.35, 0
    if useHumanization and useFingerModel and prevChar and nextChar and prevChar ~= "" then
        extra = KeyDistance(prevChar, nextChar) * 0.018 * (550 / math.max(150, currentCPM)); local pa, pb = KEY_POS[prevChar:lower()], KEY_POS[nextChar:lower()]
        if pa and pb and ((pa.x <= 5 and pb.x <= 5) or (pa.x > 5 and pb.x > 5)) then extra = extra * 0.8 end
    end
    if useHumanization then local r = (math.random() + math.random() + math.random()) / 3; return math.max(0.005, baseDelay + extra + ((r * 2 - 1) * variance)) else return baseDelay end
end

local VirtualUser, isMobile = game:GetService("VirtualUser"), UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local function GetKeyCode(char)
    local layout = Config.KeyboardLayout or "QWERTY"
    if type(char) == "string" and #char == 1 then char = char:lower(); if layout == "QWERTZ" then if char == "z" then return Enum.KeyCode.Y elseif char == "y" then return Enum.KeyCode.Z end elseif layout == "AZERTY" then if char == "a" then return Enum.KeyCode.Q elseif char == "q" then return Enum.KeyCode.A elseif char == "z" then return Enum.KeyCode.W elseif char == "w" then return Enum.KeyCode.Z elseif char == "m" then return Enum.KeyCode.Semicolon end end return Enum.KeyCode[char:upper()] end
    return nil
end

local function SimulateKey(input)
    if typeof(input) == "string" and #input == 1 then
         local char, vimSuccess = input, pcall(function() VirtualInputManager:SendTextInput(input) end)
         if not vimSuccess then
             local key; pcall(function() key = GetKeyCode(input) end); if not key then pcall(function() key = Enum.KeyCode[input:upper()] end) end
             if key then pcall(function() VirtualInputManager:SendKeyEvent(true, key, false, game); task.wait(0.01); VirtualInputManager:SendKeyEvent(false, key, false, game) end) end
         end; return
    end
    local key; if typeof(input) == "EnumItem" then key = input else pcall(function() key = Enum.KeyCode[input:upper()] end) end
    if key then
        local baseHold = math.clamp(12 / currentCPM, 0.015, 0.05); local hold = isBlatant and 0.002 or (baseHold + (math.random() * 0.01) - 0.005)
        if not pcall(function() VirtualInputManager:SendKeyEvent(true, key, false, game); task.wait(hold); VirtualInputManager:SendKeyEvent(false, key, false, game) end) then pcall(function() VirtualUser:TypeKey(key) end) end
    end
end

local function Backspace(count)
    local focused = UserInputService:GetFocusedTextBox(); if focused and focused:IsDescendantOf(game) and focused.TextEditable then focused.Text = focused.Text:sub(1, -count - 1); lastKey = nil; return end
    local key = Enum.KeyCode.Backspace; for i = 1, count do pcall(function() VirtualInputManager:SendKeyEvent(true, key, false, game); VirtualInputManager:SendKeyEvent(false, key, false, game) end); if i % 20 == 0 then task.wait() end end; lastKey = nil
end
local function PressEnter() SimulateKey(Enum.KeyCode.Return); lastKey = nil end
local function GetGameTextBox()
    local player = Players.LocalPlayer; local gui = player and player:FindFirstChild("PlayerGui"); local inGame = gui and gui:FindFirstChild("InGame")
    if inGame then
        local frame = inGame:FindFirstChild("Frame"); if frame then for _, c in ipairs(frame:GetDescendants()) do if c:IsA("TextBox") and c.Visible then return c end end end
        for _, c in ipairs(inGame:GetDescendants()) do if c:IsA("TextBox") and c.Visible then return c end end
    end
    return UserInputService:GetFocusedTextBox()
end

local function SmartType(targetWord, currentDetected, isCorrection, bypassTurn)
    if unloaded then return end
    if isTyping then if (tick() - lastTypingStart) > 15 then isTyping = false; isAutoPlayScheduled = false; StatusText.Text = "Typing State Reset (Timeout)"; StatusText.TextColor3 = THEME.Warning else return end end
    isTyping = true; lastTypingStart = tick(); local targetBox = GetGameTextBox(); if targetBox then targetBox:CaptureFocus(); task.wait(0.1) end
    StatusText.Text = "Typing..."; StatusText.TextColor3 = THEME.Accent; Tween(StatusDot, {BackgroundColor3 = THEME.Accent})

    local success, err = pcall(function()
        if isCorrection then
            local commonLen, minLen = 0, math.min(#targetWord, #currentDetected)
            for i = 1, minLen do if targetWord:sub(i,i) == currentDetected:sub(i,i) then commonLen = i else break end end
            if #currentDetected - commonLen > 0 then Backspace(#currentDetected - commonLen); task.wait(0.15) end
            local toType = targetWord:sub(commonLen + 1)
            for i = 1, #toType do
                if not bypassTurn and not GetTurnInfo() then task.wait(0.05); if not GetTurnInfo() then break end end
                local ch = toType:sub(i, i); SimulateKey(ch); task.wait(CalculateDelayForKeys(lastKey, ch)); lastKey = ch; if useHumanization and math.random() < 0.03 then task.wait(0.15 + math.random() * 0.45) end
            end
            if not riskyMistakes then task.wait(0.1); local finalCheck = GetGameTextBox(); if finalCheck and finalCheck.Text ~= targetWord then StatusText.Text = "Typing mismatch!"; StatusText.TextColor3 = THEME.Warning; Backspace(#finalCheck.Text); isTyping = false; forceUpdateList = true; return end end
            PressEnter(); local verifyStart, accepted = tick(), false
            while (tick() - verifyStart) < 1.5 do local currentCheck = GetCurrentGameWord(); if currentCheck == "" or (currentCheck ~= targetWord and currentCheck ~= currentDetected) then accepted = true; break end; task.wait(0.05) end
            if not accepted then
                Blacklist[targetWord] = true; RandomPriority[targetWord] = nil; for k, list in pairs(RandomOrderCache) do for i = #list, 1, -1 do if list[i] == targetWord then table.remove(list, i) end end end
                StatusText.Text = "Rejected: removed '" .. targetWord .. "'"; StatusText.TextColor3 = THEME.Warning; local focused = UserInputService:GetFocusedTextBox(); if focused and focused:IsDescendantOf(game) and focused.TextEditable then focused.Text = "" else Backspace(#targetWord + 5) end
                lastDetected = "---"; isTyping = false; forceUpdateList = true; return
            else StatusText.Text = "Word Cleared (Corrected)"; StatusText.TextColor3 = THEME.SubText; local current = GetCurrentGameWord(); if #current > 0 then Backspace(#current) end; UsedWords[targetWord] = true; isMyTurnLogDetected = false; task.wait(0.2) end
        else
            local missingPart = (targetWord:sub(1, #currentDetected) == currentDetected) and targetWord:sub(#currentDetected + 1) or targetWord
            local letters = "abcdefghijklmnopqrstuvwxyz"
            for i = 1, #missingPart do
                if not bypassTurn and not GetTurnInfo() then task.wait(0.05); if not GetTurnInfo() then break end end
                local ch = missingPart:sub(i, i)
                if errorRate > 0 and (math.random() < (errorRate / 100)) then
                    local typoChar; repeat local idx = math.random(1, #letters); typoChar = letters:sub(idx, idx) until typoChar ~= ch
                    SimulateKey(typoChar); if riskyMistakes then task.wait(0.05 + math.random() * 0.1); PressEnter() end
                    task.wait(CalculateDelayForKeys(lastKey, typoChar)); lastKey = typoChar; task.wait(thinkDelayCurrent * (0.6 + math.random() * 0.8)); SimulateKey(Enum.KeyCode.Backspace); lastKey = nil; task.wait(0.05 + math.random() * 0.08); SimulateKey(ch); task.wait(CalculateDelayForKeys(lastKey, ch)); lastKey = ch
                else SimulateKey(ch); task.wait(CalculateDelayForKeys(lastKey, ch)); lastKey = ch end
                if useHumanization and math.random() < 0.03 then task.wait(0.12 + math.random() * 0.5) end
            end
            if not riskyMistakes then task.wait(0.1); local finalCheck = GetGameTextBox(); if finalCheck and finalCheck.Text ~= targetWord then StatusText.Text = "Typing mismatch!"; StatusText.TextColor3 = THEME.Warning; Backspace(#finalCheck.Text); isTyping = false; forceUpdateList = true; return end end
            PressEnter(); local verifyStart, accepted = tick(), false
            while (tick() - verifyStart) < 1.5 do local currentCheck = GetCurrentGameWord(); if currentCheck == "" or (currentCheck ~= targetWord and currentCheck ~= currentDetected) then accepted = true; break end; task.wait(0.05) end
            if not accepted then
                local postCheck = GetGameTextBox(); if postCheck and postCheck.Text == targetWord then StatusText.Text = "Retrying..."; PressEnter(); task.wait(0.5); if GetCurrentGameWord() == currentDetected then StatusText.Text = "Failed (Lag?)"; StatusText.TextColor3 = THEME.Warning; Backspace(#targetWord); isTyping = false; forceUpdateList = true; return end end
                Blacklist[targetWord] = true; for k, list in pairs(RandomOrderCache) do for i = #list, 1, -1 do if list[i] == targetWord then table.remove(list, i) end end end
                StatusText.Text = "Rejected: removed '" .. targetWord .. "'"; StatusText.TextColor3 = THEME.Warning; local focused = UserInputService:GetFocusedTextBox(); if focused and focused:IsDescendantOf(game) and focused.TextEditable then focused.Text = "" else Backspace(#targetWord + 5) end
                isTyping = false; lastDetected = "---"; forceUpdateList = true; task.spawn(function() task.wait(0.1); local _, req = GetTurnInfo(); UpdateList(currentDetected, req) end); return
            else StatusText.Text = "Verification Failed"; StatusText.TextColor3 = THEME.Warning; local current = GetCurrentGameWord(); if #current > 0 then Backspace(#current) end; UsedWords[targetWord] = true; isMyTurnLogDetected = false; task.wait(0.2) end
        end
    end)
    isTyping = false; forceUpdateList = true
end

local function GetMatchLength(str, prefix) local len = 0; for i = 1, math.min(#str, #prefix) do if string.byte(prefix, i) == 35 or string.byte(prefix, i) == string.byte(str, i) then len = i else break end end return len end
local function BinarySearchStart(list, prefix)
    local left, right, result, pLen = 1, #list, -1, #prefix
    while left <= right do local mid = math.floor((left + right) / 2); local word = list[mid]; local sub = word:sub(1, pLen); if sub == prefix then result = mid; right = mid - 1 elseif sub < prefix then left = mid + 1 else right = mid - 1 end end
    return result
end

UpdateList = function(detectedText, requiredLetter)
    local matches, searchPrefix, isBacktracked, manualSearch = {}, detectedText, false, false
    if SearchBox and SearchBox.Text ~= "" then searchPrefix = SearchBox.Text:lower():gsub("[%s%c]+", ""); manualSearch = true; if requiredLetter and searchPrefix:sub(1,1) ~= requiredLetter:sub(1,1):lower() then requiredLetter = nil end end
    if not manualSearch and requiredLetter and #requiredLetter > 0 then local reqLen = GetMatchLength(requiredLetter, searchPrefix); if reqLen == #searchPrefix and #requiredLetter > #searchPrefix then searchPrefix = requiredLetter end end
    local firstChar = searchPrefix:sub(1,1); if firstChar == "#" then firstChar = nil end; if (not firstChar or firstChar == "") and requiredLetter then firstChar = requiredLetter:sub(1,1):lower() end
    local bucket = (firstChar and firstChar ~= "" and Buckets and Buckets[firstChar]) or Words
    local function CollectMatches(prefix, tryFallbackLengths)
        local exacts, partials, maxPartialLen = {}, {}, 0
        if bucket then
            local checkWord = function(w)
                if Blacklist[w] or UsedWords[w] then return end
                if suffixMode ~= "" and w:sub(-#suffixMode) ~= suffixMode then return end
                if (not tryFallbackLengths and lengthMode > 0 and #w ~= lengthMode) then return end
                local mLen = GetMatchLength(w, prefix)
                if mLen == #prefix then table.insert(exacts, w) elseif #exacts == 0 then if mLen > maxPartialLen then maxPartialLen = mLen; partials = {w} elseif mLen == maxPartialLen and mLen > 0 and #partials < 50 then table.insert(partials, w) end end
            end
            local useBinary = not (prefix:find("#") or prefix:find("%*")); if useBinary and #prefix > 0 then local startIndex = BinarySearchStart(bucket, prefix); if startIndex ~= -1 then local count = 0; for i = startIndex, #bucket do if bucket[i]:sub(1, #prefix) ~= prefix then break end; checkWord(bucket[i]); count = count + 1; if count >= 3000 then break end end end else local limit = (sortMode == "Random") and 1000 or 100; for _, w in ipairs(bucket) do checkWord(w); if #exacts >= limit then break end end end
            if sortMode == "Random" and #exacts > 0 then shuffleTable(exacts) end
        end
        return exacts, partials, maxPartialLen
    end

    local exacts, partials, pLen = CollectMatches(searchPrefix, false)
    if #exacts == 0 and lengthMode > 0 then local fe, fp, fpl = CollectMatches(searchPrefix, true); if #fe > 0 then exacts = fe end end

    if #exacts > 0 then matches = exacts elseif pLen > 0 then matches = partials; searchPrefix = searchPrefix:sub(1, pLen); isBacktracked = true elseif requiredLetter and #requiredLetter > 0 then
        local reqChar = requiredLetter:sub(1,1):lower(); if searchPrefix:sub(1,1):lower() ~= reqChar then local fb = (Buckets and Buckets[reqChar]) or Words; if fb then for _, w in ipairs(fb) do if not Blacklist[w] and not UsedWords[w] and GetMatchLength(w, requiredLetter) == #requiredLetter then table.insert(matches, w); if #matches >= 100 then break end end end end end; if #matches > 0 then searchPrefix = requiredLetter; isBacktracked = true end
    end
    
    if #matches > 0 then
        if sortMode == "Longest" then table.sort(matches, function(a, b) return #a > #b end) elseif sortMode == "Shortest" then table.sort(matches, function(a, b) return #a < #b end) elseif sortMode == "Killer" then table.sort(matches, function(a, b) local sA, sB = GetKillerScore(a), GetKillerScore(b); return (sA == sB and #a < #b) or sA > sB end) end
    end
    
    local displayList = {}; for i = 1, math.min(40, #matches) do table.insert(displayList, matches[i]) end
    if showKeyboard and KeyboardFrame.Visible then
        local colors, targetKeys = {Color3.fromRGB(100, 255, 140), Color3.fromRGB(255, 180, 200), Color3.fromRGB(100, 200, 255)}, {}
        for i = 1, math.min(3, #displayList) do local n = displayList[i]:sub(#searchPrefix + 1, #searchPrefix + 1); if n ~= "" then targetKeys[n:lower()] = targetKeys[n:lower()] or i end end
        for char, k in pairs(Keys) do local p = targetKeys[char]; if p then k.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Tween(k, {BackgroundColor3 = colors[p]}, 0.3) else Tween(k, {BackgroundColor3 = THEME.ItemBG}, 0.2) end end
    end

    currentBestMatch = (#matches > 0 and not isBacktracked) and matches[1] or nil
    if isBacktracked then StatusText.Text = "No match: <font color=\"rgb(" .. ColorToRGB(THEME.Accent) .. ")\">" .. searchPrefix .. "</font><font color=\"rgb(255,80,80)\">" .. detectedText:sub(#searchPrefix + 1) .. "</font>"; StatusText.TextColor3 = THEME.SubText elseif #exacts == 0 and lengthMode > 0 and suffixMode ~= "" then StatusText.Text = "No len match (showing all)"; StatusText.TextColor3 = THEME.Warning end

    for i = 1, math.max(#displayList, #ButtonCache) do
        local w, btn = displayList[i], ButtonCache[i]
        if w then
            local lbl; if not btn then
                btn = Instance.new("TextButton", ScrollList); btn.Size = UDim2.new(1, -6, 0, 30); btn.BackgroundColor3 = THEME.ItemBG; btn.Text = ""; btn.AutoButtonColor = false; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                lbl = Instance.new("TextLabel", btn); lbl.Name = "Label"; lbl.Size = UDim2.new(1, -20, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.RichText = true
                btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Color3.fromRGB(45,45,55)}) end); btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = THEME.ItemBG}) end)
                btn.MouseButton1Click:Connect(function() local d = ButtonData[btn]; if d then SmartType(d.word, d.detected, true); local l = btn:FindFirstChild("Label"); if l then l.TextColor3 = THEME.Success end; Tween(btn, {BackgroundColor3 = Color3.fromRGB(30,60,40)}) end end)
                table.insert(ButtonCache, btn)
            else lbl = btn:FindFirstChild("Label"); btn.Visible = true; btn.BackgroundColor3 = THEME.ItemBG; if lbl then lbl.TextColor3 = THEME.Text end end
            ButtonData[btn] = {word = w, detected = detectedText}; local accentRGB = (i == 1 and "100,255,140") or (i == 2 and "255,180,200") or (i == 3 and "100,200,255") or ColorToRGB(THEME.Accent)
            if lbl then lbl.Text = "<font color=\"rgb(" .. accentRGB .. ")\">" .. w:sub(1, #(isBacktracked and searchPrefix or detectedText)) .. "</font><font color=\"rgb(" .. ColorToRGB(THEME.Text) .. ")\">" .. w:sub(#(isBacktracked and searchPrefix or detectedText) + 1) .. "</font>" end
        else if btn then btn.Visible = false; ButtonData[btn] = nil end end
    end
    ScrollList.CanvasSize = UDim2.new(0,0,0, UIListLayout.AbsoluteContentSize.Y)
end

SetupSlider(SliderBtn, SliderBg, SliderFill, function(pct) local max = isBlatant and MAX_CPM_BLATANT or MAX_CPM_LEGIT; currentCPM = math.floor(MIN_CPM + (pct * (max - MIN_CPM))); SliderFill.Size = UDim2.new(pct, 0, 1, 0); SliderLabel.Text = "Speed: " .. currentCPM .. " CPM"; Tween(SliderFill, {BackgroundColor3 = currentCPM > 900 and Color3.fromRGB(255,80,80) or THEME.Accent}) end)
MinBtn.MouseButton1Click:Connect(function() local isMin = MainFrame.Size.Y.Offset < 100; if not isMin then Tween(MainFrame, {Size = UDim2.new(0, 300, 0, 45)}); ScrollList.Visible = false; SettingsFrame.Visible = false; StatusFrame.Visible = false; MinBtn.Text = "+" else Tween(MainFrame, {Size = UDim2.new(0, 300, 0, 500)}); task.wait(0.2); ScrollList.Visible = true; SettingsFrame.Visible = true; StatusFrame.Visible = true; MinBtn.Text = "-" end end)

local lastTypeVisible, lastRequiredLetter, StatsData = false, "", {}
do
    local sf = Instance.new("Frame", ScreenGui); sf.Name = "StatsFrame"; sf.Size = UDim2.new(0, 120, 0, 60); sf.Position = UDim2.new(0.5, -60, 0, 10); sf.BackgroundColor3 = THEME.Background; sf.Visible = false; EnableDragging(sf); Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", sf).Color = THEME.Accent; StatsData.Frame = sf
    local st = Instance.new("TextLabel", sf); st.Size = UDim2.new(1, 0, 0, 25); st.Position = UDim2.new(0, 0, 0, 5); st.BackgroundTransparency = 1; st.TextColor3 = THEME.Text; st.Font = Enum.Font.GothamBold; st.TextSize = 20; st.Text = "--"; StatsData.Timer = st
    local sc = Instance.new("TextLabel", sf); sc.Size = UDim2.new(1, 0, 0, 20); sc.Position = UDim2.new(0, 0, 0, 30); sc.BackgroundTransparency = 1; sc.TextColor3 = THEME.SubText; sc.Font = Enum.Font.Gotham; sc.TextSize = 12; sc.Text = "Words: 0"; StatsData.Count = sc
end

runConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        local now, player = tick(), Players.LocalPlayer; local gui = player and player:FindFirstChild("PlayerGui"); local frame = gui and gui:FindFirstChild("InGame") and gui.InGame:FindFirstChild("Frame")
        if isTyping and (now - lastTypingStart) > 15 then isTyping = false; isAutoPlayScheduled = false; StatusText.Text = "Typing State Reset (Watchdog)"; StatusText.TextColor3 = THEME.Warning end
        local isVisible = (frame and frame.Parent and ((frame.Parent:IsA("ScreenGui") and frame.Parent.Enabled) or (frame.Parent:IsA("GuiObject") and frame.Parent.Visible)))
        local seconds = nil; if isVisible then local circle = frame:FindFirstChild("Circle"); local timerLbl = circle and circle:FindFirstChild("Timer") and circle.Timer:FindFirstChild("Seconds"); if timerLbl then seconds = tonumber(timerLbl.Text:match("([%d%.]+)")); StatsData.Frame.Visible = true; StatsData.Timer.Text = timerLbl.Text; StatsData.Timer.TextColor3 = (seconds and seconds < 3) and Color3.fromRGB(255, 80, 80) or THEME.Text end else StatsData.Frame.Visible = false end

        local isMyTurn, requiredLetter = GetTurnInfo(frame); if (now - lastWordCheck) > 0.05 then cachedDetected, cachedCensored = GetCurrentGameWord(frame); lastWordCheck = now end; local detected, censored = cachedDetected, cachedCensored
        if isVisible and isMyTurn and not isTyping and seconds and seconds < 1.5 then local b = Buckets[(requiredLetter or ""):lower()]; if b then local bestWord, bestLen = nil, 999; for _, w in ipairs(b) do if not Blacklist[w] and not UsedWords[w] and w:sub(1, #detected) == detected and #w < bestLen then bestWord = w; bestLen = #w end end; if bestWord then StatusText.Text = "PANIC SAVE!"; StatusText.TextColor3 = Color3.fromRGB(255, 50, 50); SmartType(bestWord, detected, false) end end end

        if autoJoin and (now - lastAutoJoinCheck > AUTO_JOIN_RATE) then
            lastAutoJoinCheck = now; task.spawn(function()
                local matches = gui and gui:FindFirstChild("DisplayMatch") and gui.DisplayMatch:FindFirstChild("Frame") and gui.DisplayMatch.Frame:FindFirstChild("Matches")
                if matches then
                    for _, mf in ipairs(matches:GetChildren()) do
                        if (mf:IsA("Frame") or mf:IsA("GuiObject")) and mf.Name ~= "UIListLayout" then
                            local jb, ttl = mf:FindFirstChild("Join"), mf:FindFirstChild("Title"); local isLL, allowed, idx = false, true, tonumber(mf.Name)
                            if ttl and ttl.Text:find("Last Letter") then isLL = true end
                            if idx then allowed = (idx >= 1 and idx <= 4 and Config.AutoJoinSettings._1v1) or (idx >= 5 and idx <= 8 and Config.AutoJoinSettings._4p) or (idx == 9 and Config.AutoJoinSettings._8p) end
                            if jb and jb.Visible and isLL and allowed and (tick() - (JoinDebounce[mf.Name] or 0)) > 2 then
                                JoinDebounce[mf.Name] = tick(); task.wait(0.5); local clicked = false
                                if getconnections then local s, c = pcall(function() return getconnections(jb.MouseButton1Click) end); if s and c then for _, cn in ipairs(c) do cn:Fire(); if cn.Function then task.spawn(cn.Function) end; clicked = true end end end
                                if not clicked then local cd = jb:FindFirstChildWhichIsA("ClickDetector"); if cd then fireclickdetector(cd); clicked = true end end
                                if not clicked then local ap, as = jb.AbsolutePosition, jb.AbsoluteSize; VirtualInputManager:SendMouseButtonEvent(ap.X + as.X/2, ap.Y + as.Y/2, 0, true, game, 1); task.wait(0.05); VirtualInputManager:SendMouseButtonEvent(ap.X + as.X/2, ap.Y + as.Y/2, 0, false, game, 1) end
                                break
                            end
                        end
                    end
                end
            end)
        end

        local typeVisible = frame and frame:FindFirstChild("Type") and frame:FindFirstChild("Type").Visible; if typeVisible and not lastTypeVisible then UsedWords = {}; StatusText.Text = "New Round - Words Reset"; StatusText.TextColor3 = THEME.Success end; lastTypeVisible = typeVisible
        if censored then if StatusText.Text ~= "Word is Censored" then StatusText.Text = "Word is Censored"; StatusText.TextColor3 = THEME.Warning; Tween(StatusDot, {BackgroundColor3 = THEME.Warning}); for _, btn in ipairs(ButtonCache) do btn.Visible = false end; StatsData.Count.Text = "Words: 0" end; listUpdatePending = false; forceUpdateList = false; currentBestMatch = nil; lastDetected = detected; lastRequiredLetter = requiredLetter end
        if listUpdatePending and (now - lastInputTime > LIST_DEBOUNCE) then listUpdatePending = false; UpdateList(lastDetected, lastRequiredLetter); local vc = 0; for _, b in ipairs(ButtonCache) do if b.Visible then vc = vc + 1 end end; StatsData.Count.Text = "Words: " .. vc .. "+" end

        if not isVisible then
            if StatusText.Text ~= "Not in Round" then StatusText.Text = "Not in Round"; StatusText.TextColor3 = THEME.SubText; Tween(StatusDot, {BackgroundColor3 = THEME.SubText}); for _, btn in ipairs(ButtonCache) do btn.Visible = false end; StatsData.Count.Text = "Words: 0" end; lastDetected = "---"
        elseif detected ~= lastDetected or requiredLetter ~= lastRequiredLetter or forceUpdateList then
            currentBestMatch = nil; lastDetected = detected; lastRequiredLetter = requiredLetter
            if detected == "" and not forceUpdateList then StatusText.Text = "Waiting..."; StatusText.TextColor3 = THEME.SubText; Tween(StatusDot, {BackgroundColor3 = THEME.SubText}); UpdateList("", requiredLetter); listUpdatePending = false; local vc = 0; for _, b in ipairs(ButtonCache) do if b.Visible then vc = vc + 1 end end; StatsData.Count.Text = "Words: " .. vc .. "+"
            else
                if detected ~= "" then local isC = (#detected > 2 and detected:sub(1,1) ~= "#" and Buckets and Buckets[detected:sub(1,1)] and (function() for _, w in ipairs(Buckets[detected:sub(1,1)]) do if w == detected then return true end end end)()); if isC then StatusText.Text = "Completed: " .. detected .. " <font color=\"rgb(100,255,140)\">✓</font>"; StatusText.TextColor3 = THEME.Success; Tween(StatusDot, {BackgroundColor3 = THEME.Success}) else StatusText.Text = "Input: " .. detected; StatusText.TextColor3 = THEME.Accent; Tween(StatusDot, {BackgroundColor3 = THEME.Warning}) end end
                listUpdatePending = true; lastInputTime = forceUpdateList and 0 or now; forceUpdateList = false
            end
        end

        if autoPlay and not isTyping and not isAutoPlayScheduled and currentBestMatch and detected == lastDetected and GetTurnInfo(frame) then
            isAutoPlayScheduled = true; local targetWord, snapshotDetected = currentBestMatch, lastDetected
            task.spawn(function() task.wait(isBlatant and 0.15 or (0.8 + math.random() * 0.5)); if autoPlay and not isTyping and GetCurrentGameWord() == snapshotDetected and GetTurnInfo() then SmartType(targetWord, snapshotDetected, false) end; isAutoPlayScheduled = false end)
        end
    end)
end)

inputConn = UserInputService.InputBegan:Connect(function(input) if unloaded then return end; if input.KeyCode == TOGGLE_KEY then ScreenGui.Enabled = not ScreenGui.Enabled end end)
