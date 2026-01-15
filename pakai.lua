local ManageWordsBtn = Instance.new("TextButton", TogglesFrame); ManageWordsBtn.Text = "Manage Custom Words"; ManageWordsBtn.Font = Enum.Font.GothamMedium; ManageWordsBtn.TextSize = 11; ManageWordsBtn.TextColor3 = THEME.Accent; ManageWordsBtn.BackgroundColor3 = THEME.Background; ManageWordsBtn.Size = UDim2.new(0, 130, 0, 24); ManageWordsBtn.Position = UDim2.new(0, 15, 0, 145); Instance.new("UICorner", ManageWordsBtn).CornerRadius = UDim.new(0, 4)

local VirtualInputManager, UserInputService, RunService, TweenService = cloneref(game:GetService("VirtualInputManager")), cloneref(game:GetService("UserInputService")), cloneref(game:GetService("RunService")), cloneref(game:GetService("TweenService")); local LogService, GuiService = cloneref(game:GetService("LogService")), cloneref(game:GetService("GuiService")); local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request; local TOGGLE_KEY, MIN_CPM, MAX_CPM_LEGIT, MAX_CPM_BLATANT = Enum.KeyCode.RightControl, 50, 1500, 3000

local queryRaw, list, shownCount = CWSearchBox.Text, Config.CustomWords or {}, 0; local query = (queryRaw == "Search words...") and "" or queryRaw:lower():gsub("[%s%c]+", ""); for i, w in ipairs(list) do if query == "" or w:find(query, 1, true) then shownCount = shownCount + 1; local row = Instance.new("TextButton", CWScroll); row.Size = UDim2.new(1, -6, 0, 22); row.BackgroundColor3 = (shownCount % 2 == 0) and Color3.fromRGB(25,25,30) or Color3.fromRGB(30,30,35); row.BorderSizePixel = 0; row.Text = ""; row.AutoButtonColor = false; Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

local seconds = nil; if isVisible then local circle = frame:FindFirstChild("Circle"); local timerLbl = circle and circle:FindFirstChild("Timer") and circle.Timer:FindFirstChild("Seconds"); if timerLbl then seconds = tonumber(timerLbl.Text:match("([%d%.]+)")); StatsData.Frame.Visible = true; StatsData.Timer.Text = timerLbl.Text; StatsData.Timer.TextColor3 = (seconds and seconds < 3) and Color3.fromRGB(255, 80, 80) or THEME.Text end else StatsData.Frame.Visible = false end

row.MouseButton1Click:Connect(function() SmartType(w, lastDetected, true, true); Tween(row, {BackgroundColor3 = THEME.Accent}, 0.2); task.delay(0.2, function() Tween(row, {BackgroundColor3 = (shownCount % 2 == 0) and Color3.fromRGB(25,25,30) or Color3.fromRGB(30,30,35)}, 0.2) end) end); local lbl = Instance.new("TextLabel", row); lbl.Text = w; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextColor3 = THEME.Text; lbl.Size = UDim2.new(1, -30, 1, 0); lbl.Position = UDim2.new(0, 5, 0, 0); lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left

local isMyTurn, requiredLetter = GetTurnInfo(frame); if (now - lastWordCheck) > 0.05 then cachedDetected, cachedCensored = GetCurrentGameWord(frame); lastWordCheck = now end; local detected, censored = cachedDetected, cachedCensored

for _, w in ipairs(Config.CustomWords) do local clean = w:gsub("[%s%c]+", ""):lower(); if #clean > 0 and not SeenWords[clean] then SeenWords[clean] = true; table.insert(Words, clean); local c = clean:sub(1,1) or ""; if c == "" then c = "#" end; Buckets[c] = Buckets[c] or {}; table.insert(Buckets[c], clean) end end end; SeenWords = nil; local function shuffleTable(t) for i = #t, 2, -1 do local j = math.random(i); t[i], t[j] = t[j], t[i] end return t end; local HardLetterScores = { x = 10, z = 9, q = 9, j = 8, v = 6, k = 5, b = 4, f = 3, w = 3, y = 2, g = 2, p = 2 }

if isVisible and isMyTurn and not isTyping and seconds and seconds < 1.5 then local b = Buckets[(requiredLetter or ""):lower()]; if b then local bestWord, bestLen = nil, 999; for _, w in ipairs(b) do if not Blacklist[w] and not UsedWords[w] and w:sub(1, #detected) == detected and #w < bestLen then bestWord = w; bestLen = #w end end; if bestWord then StatusText.Text = "PANIC SAVE!"; StatusText.TextColor3 = Color3.fromRGB(255, 50, 50); SmartType(bestWord, detected, false) end end end; if autoJoin and (now - lastAutoJoinCheck > AUTO_JOIN_RATE) then lastAutoJoinCheck = now; task.spawn(function()

CWAddBtn.MouseButton1Click:Connect(function() local text = CWAddBox.Text; if text == "Add new word..." then return end; text = text:gsub("[%s%c]+", ""):lower(); if #text < 2 then return end; if not Config.CustomWords then Config.CustomWords = {} end; for _, w in ipairs(Config.CustomWords) do if w == text then ShowToast("Word already in custom list!", "warning"); return end end; local existsInMain, c = false, text:sub(1,1); if Buckets and Buckets[c] then for _, w in ipairs(Buckets[c]) do if w == text then existsInMain = true break end end end

local function Tween(obj, props, time) TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() end; local function GetCurrentGameWord(providedFrame) local frame = providedFrame or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("InGame") and Players.LocalPlayer.PlayerGui.InGame:FindFirstChild("Frame")); local container = frame and frame:FindFirstChild("CurrentWord"); if not container then return "", false end; local detected, censored, letterData = "", false, {}

if idx then allowed = (idx >= 1 and idx <= 4 and Config.AutoJoinSettings._1v1) or (idx >= 5 and idx <= 8 and Config.AutoJoinSettings._4p) or (idx == 9 and Config.AutoJoinSettings._8p) end; if jb and jb.Visible and isLL and allowed and (tick() - (JoinDebounce[mf.Name] or 0)) > 2 then JoinDebounce[mf.Name] = tick(); task.wait(0.5); local clicked = false; if getconnections then local s, c = pcall(function() return getconnections(jb.MouseButton1Click) end); if s and c then for _, cn in ipairs(c) do cn:Fire(); if cn.Function then task.spawn(cn.Function) end; clicked = true end end end

math.randomseed(os.time()); local THEME = { Background = Color3.fromRGB(20, 20, 24), ItemBG = Color3.fromRGB(32, 32, 38), Accent = Color3.fromRGB(114, 100, 255), Text = Color3.fromRGB(240, 240, 240), SubText = Color3.fromRGB(150, 150, 160), Success = Color3.fromRGB(100, 255, 140), Warning = Color3.fromRGB(255, 200, 80), Slider = Color3.fromRGB(60, 60, 70) }; local function ColorToRGB(c) return string.format("%d,%d,%d", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)) end; local ConfigFile = "WordHelper_Config.json"

elseif detected ~= lastDetected or requiredLetter ~= lastRequiredLetter or forceUpdateList then currentBestMatch = nil; lastDetected = detected; lastRequiredLetter = requiredLetter; if detected == "" and not forceUpdateList then StatusText.Text = "Waiting..."; StatusText.TextColor3 = THEME.SubText; Tween(StatusDot, {BackgroundColor3 = THEME.SubText}); UpdateList("", requiredLetter); listUpdatePending = false; local vc = 0; for _, b in ipairs(ButtonCache) do if b.Visible then vc = vc + 1 end end; StatsData.Count.Text = "Words: " .. vc .. "+" else

task.delay(3, function() if toast and toast.Parent then Tween(toast, {BackgroundTransparency = 1}, 0.5); Tween(lbl, {TextTransparency = 1}, 0.5); Tween(stroke, {Transparency = 1}, 0.5); task.wait(0.5); toast:Destroy() end end) end; local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 300, 0, 500); MainFrame.Position = UDim2.new(0.8, -50, 0.4, 0); MainFrame.BackgroundColor3 = THEME.Background; MainFrame.BorderSizePixel = 0; MainFrame.Active = true; MainFrame.ClipsDescendants = true; local function EnableDragging(frame)

listUpdatePending = true; lastInputTime = forceUpdateList and 0 or now; forceUpdateList = false; end; end; if autoPlay and not isTyping and not isAutoPlayScheduled and currentBestMatch and detected == lastDetected and GetTurnInfo(frame) then isAutoPlayScheduled = true; local targetWord, snapshotDetected = currentBestMatch, lastDetected; task.spawn(function() task.wait(isBlatant and 0.15 or (0.8 + math.random() * 0.5)); if autoPlay and not isTyping and GetCurrentGameWord() == snapshotDetected and GetTurnInfo() then SmartType(targetWord, snapshotDetected, false) end; isAutoPlayScheduled = false end) end

join.Text = "Joining..."; ShowToast("Teleporting...", "success"); if queue_on_teleport then queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/skrylor/Last-Letter-Script/refs/heads/main/Last%20Letter.lua"))()') end; task.spawn(function() local success, err = pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, srv.id, Players.LocalPlayer) end); if not success then join.Text = "Failed"; ShowToast("Teleport Failed: " .. tostring(err), "error"); task.wait(2); join.Text = "Join" end end) end) end end

local Config = { CPM = 550, Blatant = "off", Humanize = true, FingerModel = true, SortMode = "Random", SuffixMode = "", LengthMode = 0, AutoPlay = false, AutoJoin = false, AutoJoinSettings = { _1v1 = true, _4p = true, _8p = true }, PanicMode = true, ShowKeyboard = false, ErrorRate = 5, ThinkDelay = 0.8, RiskyMistakes = false, CustomWords = {}, MinTypeSpeed = 50, MaxTypeSpeed = 3000, KeyboardLayout = "QWERTY", BlatantThreshold = 7, BlatantMode = "off", OriginalHumanize = true, OriginalErrorRate = 5, OriginalSortMode = "Random" }; local function SaveConfig() if writefile then writefile(ConfigFile, HttpService:JSONEncode(Config)) end end

local CustomWordsFrame = Instance.new("Frame", ScreenGui); CustomWordsFrame.Name = "CustomWordsFrame"; CustomWordsFrame.Size = UDim2.new(0, 250, 0, 350); CustomWordsFrame.Position = UDim2.new(0.5, -125, 0.5, -175); CustomWordsFrame.BackgroundColor3 = THEME.Background; CustomWordsFrame.Visible = false; CustomWordsFrame.ClipsDescendants = true; EnableDragging(CustomWordsFrame); Instance.new("UICorner", CustomWordsFrame).CornerRadius = UDim.new(0, 8); local CWStroke = Instance.new("UIStroke", CustomWordsFrame); CWStroke.Color = THEME.Accent; CWStroke.Transparency = 0.5; CWStroke.Thickness = 2

ExpandBtn.MouseButton1Click:Connect(function() settingsCollapsed = not settingsCollapsed; ExpandBtn.Text = settingsCollapsed and "v Show Settings v" or "^ Hide Settings ^"; UpdateLayout() end); local function SetupSlider(btn, bg, fill, callback) btn.MouseButton1Down:Connect(function() local move, rel

local function Update() local mousePos = UserInputService:GetMouseLocation(); local relX = math.clamp(mousePos.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X); local pct = relX / bg.AbsoluteSize.X; callback(pct); Config.CPM, Config.ErrorRate, Config.ThinkDelay = currentCPM, errorRate, thinkDelayCurrent end; Update(); move = RunService.RenderStepped:Connect(Update)

local function LoadConfig() if isfile and isfile(ConfigFile) then local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end); if success and decoded then for k, v in pairs(decoded) do Config[k] = v end end end end; LoadConfig(); local currentCPM, isBlatant, useHumanization, useFingerModel = Config.CPM, Config.BlatantMode == "on", Config.Humanize, Config.FingerModel; local sortMode, suffixMode, lengthMode, autoPlay = Config.SortMode, Config.SuffixMode or "", Config.LengthMode or 0, Config.AutoPlay

local function KeyDistance(a, b) if not a or not b then return 1 end; a, b = a:lower(), b:lower(); local pa, pb = KEY_POS[a], KEY_POS[b]; if not pa or not pb then return 1 end; local dx, dy = pa.x - pb.x, pa.y - pb.y; return math.sqrt(dx*dx + dy*dy) end; local lastKey = nil; local function CalculateDelayForKeys(prevChar, nextChar) if isBlatant then return 60 / currentCPM end; local baseDelay, variance, extra = 60 / currentCPM, (60 / currentCPM) * 0.35, 0; if useHumanization and useFingerModel and prevChar and nextChar and prevChar ~= "" then

extra = KeyDistance(prevChar, nextChar) * 0.018 * (550 / math.max(150, currentCPM)); local pa, pb = KEY_POS[prevChar:lower()], KEY_POS[nextChar:lower()]; if pa and pb and ((pa.x <= 5 and pb.x <= 5) or (pa.x > 5 and pb.x > 5)) then extra = extra * 0.8 end; end; if useHumanization then local r = (math.random() + math.random() + math.random()) / 3; return math.max(0.005, baseDelay + extra + ((r * 2 - 1) * variance)) else return baseDelay end end; local VirtualUser, isMobile = game:GetService("VirtualUser"), UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local listFrame = Instance.new("Frame", container); listFrame.Size = UDim2.new(1, 0, 0, #options * 24); listFrame.Position = UDim2.new(0, 0, 1, 2); listFrame.BackgroundColor3 = THEME.ItemBG; listFrame.Visible = false; listFrame.ZIndex = 20; Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4); local isOpen = false; mainBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; listFrame.Visible = isOpen end); for i, opt in ipairs(options) do

local LayoutDropdown = CreateDropdown(TogglesFrame, "Layout", {"QWERTY", "QWERTZ", "AZERTY"}, keyboardLayout, function(val) keyboardLayout = val; Config.KeyboardLayout = keyboardLayout; GenerateKeyboard(); SaveConfig() end); LayoutDropdown.Position = UDim2.new(0, 150, 0, 145); UserInputService.InputBegan:Connect(function(input) if not showKeyboard then return end

if isTyping then if (tick() - lastTypingStart) > 15 then isTyping = false; isAutoPlayScheduled = false; StatusText.Text = "Typing State Reset (Timeout)"; StatusText.TextColor3 = THEME.Warning else return end end; isTyping = true; lastTypingStart = tick(); local targetBox = GetGameTextBox(); if targetBox then targetBox:CaptureFocus(); task.wait(0.1) end; StatusText.Text = "Typing..."; StatusText.TextColor3 = THEME.Accent; Tween(StatusDot, {BackgroundColor3 = THEME.Accent}); local success, err = pcall(function() if isCorrection then local commonLen, minLen = 0, math.min(#targetWord, #currentDetected)

local autoJoin, panicMode, showKeyboard, errorRate = Config.AutoJoin, Config.PanicMode, Config.ShowKeyboard, Config.ErrorRate; local thinkDelayCurrent, riskyMistakes, keyboardLayout = Config.ThinkDelay, Config.RiskyMistakes, Config.KeyboardLayout or "QWERTY"; local isTyping, isAutoPlayScheduled, lastTypingStart, runConn, inputConn, logConn, unloaded = false, false, 0, nil, nil, nil, false; local isMyTurnLogDetected, logRequiredLetters, turnExpiryTime, Blacklist, UsedWords = false, "", 0, {}, {}; local RandomOrderCache, RandomPriority, lastDetected, lastLogicUpdate = {}, {}, "-", 0

if not riskyMistakes then task.wait(0.1); local finalCheck = GetGameTextBox(); if finalCheck and finalCheck.Text ~= targetWord then StatusText.Text = "Typing mismatch!"; StatusText.TextColor3 = THEME.Warning; Backspace(#finalCheck.Text); isTyping = false; forceUpdateList = true; return end end; PressEnter(); local verifyStart, accepted = tick(), false; while (tick() - verifyStart) < 1.5 do local currentCheck = GetCurrentGameWord(); if currentCheck == "" or (currentCheck ~= targetWord and currentCheck ~= currentDetected) then accepted = true; break end; task.wait(0.05) end; if not accepted then

local ErrorLabel = Instance.new("TextLabel", SlidersFrame); ErrorLabel.Text = "Error Rate: " .. errorRate .. "%"; ErrorLabel.Font = Enum.Font.GothamMedium; ErrorLabel.TextSize = 11; ErrorLabel.TextColor3 = THEME.SubText; ErrorLabel.Size = UDim2.new(1, -30, 0, 18); ErrorLabel.Position = UDim2.new(0, 15, 0, 36); ErrorLabel.BackgroundTransparency = 1; ErrorLabel.TextXAlignment = Enum.TextXAlignment.Left

else StatusText.Text = "Word Cleared (Corrected)"; StatusText.TextColor3 = THEME.SubText; local current = GetCurrentGameWord(); if #current > 0 then Backspace(#current) end; UsedWords[targetWord] = true; isMyTurnLogDetected = false; task.wait(0.2) end; else local missingPart = (targetWord:sub(1, #currentDetected) == currentDetected) and targetWord:sub(#currentDetected + 1) or targetWord; local letters = "abcdefghijklmnopqrstuvwxyz"; for i = 1, #missingPart do if not bypassTurn and not GetTurnInfo() then task.wait(0.05); if not GetTurnInfo() then break end end; local ch = missingPart:sub(i, i)

if errorRate > 0 and (math.random() < (errorRate / 100)) then local typoChar; repeat local idx = math.random(1, #letters); typoChar = letters:sub(idx, idx) until typoChar ~= ch; SimulateKey(typoChar); if riskyMistakes then task.wait(0.05 + math.random() * 0.1); PressEnter() end; task.wait(CalculateDelayForKeys(lastKey, typoChar)); lastKey = typoChar; task.wait(0.05 + math.random() * 0.08); SimulateKey(Enum.KeyCode.Backspace); lastKey = nil; task.wait(0.05 + math.random() * 0.08); SimulateKey(ch); task.wait(CalculateDelayForKeys(lastKey, ch)); lastKey = ch

SetupSlider(ErrorBtn, ErrorBg, ErrorFill, function(pct) errorRate = math.floor(pct * 30); Config.ErrorRate = errorRate; ErrorFill.Size = UDim2.new(pct, 0, 1, 0); ErrorLabel.Text = "Error Rate: " .. errorRate .. "% (per-letter)" end)

else SimulateKey(ch); task.wait(CalculateDelayForKeys(lastKey, ch)); lastKey = ch end; if useHumanization and math.random() < 0.03 then task.wait(0.12 + math.random() * 0.5) end; end; if not riskyMistakes then task.wait(0.1); local finalCheck = GetGameTextBox(); if finalCheck and finalCheck.Text ~= targetWord then StatusText.Text = "Typing mismatch!"; StatusText.TextColor3 = THEME.Warning; Backspace(#finalCheck.Text); isTyping = false; forceUpdateList = true; return end end; PressEnter(); local verifyStart, accepted = tick(), false

isTyping = false; lastDetected = "-"; forceUpdateList = true; task.spawn(function() task.wait(0.1); local _, req = GetTurnInfo(); UpdateList(currentDetected, req) end); return; else StatusText.Text = "Verification Failed"; StatusText.TextColor3 = THEME.Warning; local current = GetCurrentGameWord(); if #current > 0 then Backspace(#current) end; UsedWords[targetWord] = true; isMyTurnLogDetected = false; task.wait(0.2) end; end; end); isTyping = false; forceUpdateList = true; end

local lastAutoJoinCheck, lastWordCheck, cachedDetected, cachedCensored = 0, 0, "", false; local LOGIC_RATE, AUTO_JOIN_RATE, UpdateList, ButtonCache, ButtonData, JoinDebounce = 0.1, 0.5, nil, {}, {}, {}; local thinkDelayMin, thinkDelayMax, listUpdatePending, forceUpdateList = 0.4, 1.2, false, false; local lastInputTime, LIST_DEBOUNCE, currentBestMatch = 0, 0.05, nil; if logConn then logConn:Disconnect() end; logConn = LogService.MessageOut:Connect(function(message, type) local wordPart, timePart = message:match("Word:%s*([A-Za-z]+)%s+Time to respond:%s*(%d+)")

ManageWordsBtn.MouseButton1Click:Connect(function() CustomWordsFrame.Visible = not CustomWordsFrame.Visible; CustomWordsFrame.Parent = nil; CustomWordsFrame.Parent = ScreenGui end); local function SetupPhantomBox(box, placeholder) box.Text = placeholder; box.TextColor3 = THEME.SubText; box.Focused:Connect(function() if box.Text == placeholder then box.Text = ""; box.TextColor3 = THEME.Text end end); box.FocusLost:Connect(function() if box.Text == "" then box.Text = placeholder; box.TextColor3 = THEME.SubText end end) end

local HumanizeBtn = CreateToggle("Humanize: "..(useHumanization and "ON" or "OFF"), UDim2.new(0, 15, 0, 5), function() useHumanization = not useHumanization; Config.Humanize = useHumanization; return useHumanization, "Humanize: "..(useHumanization and "ON" or "OFF"), useHumanization and THEME.Success or Color3.fromRGB(255, 100, 100) end); HumanizeBtn.TextColor3 = useHumanization and THEME.Success or Color3.fromRGB(255, 100, 100)

local FingerBtn = CreateToggle("10-Finger: "..(useFingerModel and "ON" or "OFF"), UDim2.new(0, 105, 0, 5), function() useFingerModel = not useFingerModel; Config.FingerModel = useFingerModel; return useFingerModel, "10-Finger: "..(useFingerModel and "ON" or "OFF"), useFingerModel and THEME.Success or Color3.fromRGB(255, 100, 100) end); FingerBtn.TextColor3 = useFingerModel and THEME.Success or Color3.fromRGB(255, 100, 100)

local KeyboardBtn = CreateToggle("Keyboard: "..(showKeyboard and "ON" or "OFF"), UDim2.new(0, 195, 0, 5), function() showKeyboard = not showKeyboard; Config.ShowKeyboard = showKeyboard; KeyboardFrame.Visible = showKeyboard; return showKeyboard, "Keyboard: "..(showKeyboard and "ON" or "OFF"), showKeyboard and THEME.Success or Color3.fromRGB(255, 100, 100) end); KeyboardBtn.TextColor3 = showKeyboard and THEME.Success or Color3.fromRGB(255, 100, 100)

local SortBtn = CreateToggle("Sort: "..sortMode, UDim2.new(0, 15, 0, 33), function() sortMode = (sortMode == "Random" and "Shortest") or (sortMode == "Shortest" and "Longest") or (sortMode == "Longest" and "Killer") or "Random"; Config.SortMode = sortMode; lastDetected = "-"; return true, "Sort: "..sortMode, THEME.Accent end); SortBtn.TextColor3 = THEME.Accent; SortBtn.Size = UDim2.new(0, 130, 0, 24)

local AutoBtn = CreateToggle("Auto Play: "..(autoPlay and "ON" or "OFF"), UDim2.new(0, 150, 0, 33), function() autoPlay = not autoPlay; Config.AutoPlay = autoPlay; return autoPlay, "Auto Play: "..(autoPlay and "ON" or "OFF"), autoPlay and THEME.Success or Color3.fromRGB(255, 100, 100) end); AutoBtn.TextColor3 = autoPlay and THEME.Success or Color3.fromRGB(255, 100, 100); AutoBtn.Size = UDim2.new(0, 130, 0, 24)

local AutoJoinBtn = CreateToggle("Auto Join: "..(autoJoin and "ON" or "OFF"), UDim2.new(0, 15, 0, 61), function() autoJoin = not autoJoin; Config.AutoJoin = autoJoin; return autoJoin, "Auto Join: "..(autoJoin and "ON" or "OFF"), autoJoin and THEME.Success or Color3.fromRGB(255, 100, 100) end); AutoJoinBtn.TextColor3 = autoJoin and THEME.Success or Color3.fromRGB(255, 100, 100); AutoJoinBtn.Size = UDim2.new(0, 265, 0, 24); local function CreateCheckbox(text, pos, key)

local check = Instance.new("Frame", box); check.Size = UDim2.new(0, 8, 0, 8); check.Position = UDim2.new(0.5, -4, 0.5, -4); check.BackgroundColor3 = THEME.Success; check.Visible = Config.AutoJoinSettings[key]; Instance.new("UICorner", check).CornerRadius = UDim.new(0, 2); local lbl = Instance.new("TextLabel", container); lbl.Text = text; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11; lbl.TextColor3 = THEME.SubText; lbl.Size = UDim2.new(1, -25, 1, 0); lbl.Position = UDim2.new(0, 25, 0, 0); lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left

container.MouseButton1Click:Connect(function() Config.AutoJoinSettings[key] = not Config.AutoJoinSettings[key]; check.Visible = Config.AutoJoinSettings[key]; lbl.TextColor3 = Config.AutoJoinSettings[key] and THEME.Text or THEME.SubText; Tween(box, {BackgroundColor3 = Config.AutoJoinSettings[key] and THEME.Accent or THEME.Slider}, 0.2); SaveConfig() end); if Config.AutoJoinSettings[key] then lbl.TextColor3 = THEME.Text; box.BackgroundColor3 = THEME.Accent end; return container; end

SetupSlider(SliderBtn, SliderBg, SliderFill, function(pct) local max = isBlatant and MAX_CPM_BLATANT or MAX_CPM_LEGIT; currentCPM = math.floor(MIN_CPM + (pct * (max - MIN_CPM))); SliderFill.Size = UDim2.new(pct, 0, 1, 0); SliderLabel.Text = "Speed: " .. currentCPM .. " CPM"; Tween(SliderFill, {BackgroundColor3 = currentCPM > 900 and Color3.fromRGB(255,80,80) or THEME.Accent}) end)

if wordPart and timePart then isMyTurnLogDetected = true; logRequiredLetters = wordPart; turnExpiryTime = tick() + tonumber(timePart) end; end); local url, fileName = "https://raw.githubusercontent.com/skrylor/english-words/refs/heads/main/merged_english.txt", "ultimate_words_v4.txt"; local LoadingGui = Instance.new("ScreenGui"); LoadingGui.Name = "WordHelperLoading"; local success, parent = pcall(function() return gethui() end); if not success or not parent then parent = game:GetService("CoreGui") end; LoadingGui.Parent = parent; LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local BlatantBtn = CreateToggle("Blatant: "..(Config.BlatantMode == "on" and "ON" or Config.BlatantMode == "auto" and "AUTO" or "OFF"), UDim2.new(0, 15, 0, 115), function()
    local modes = { "off", "on", "auto" }
    local currentIndex = 1
    for i, v in ipairs(modes) do if v == Config.BlatantMode then currentIndex = i break end end
    local nextIndex = (currentIndex % 3) + 1
    Config.BlatantMode = modes[nextIndex]
    return true, "Blatant: "..(Config.BlatantMode == "on" and "ON" or Config.BlatantMode == "auto" and "AUTO" or "OFF"), Config.BlatantMode == "on" and Color3.fromRGB(255, 80, 80) or Config.BlatantMode == "auto" and Color3.fromRGB(255, 165, 0) or THEME.SubText
end)
BlatantBtn.TextColor3 = Config.BlatantMode == "on" and Color3.fromRGB(255, 80, 80) or Config.BlatantMode == "auto" and Color3.fromRGB(255, 165, 0) or THEME.SubText
BlatantBtn.Size = UDim2.new(0, 130, 0, 24)

local RiskyBtn = CreateToggle("Risky Mistakes: "..(riskyMistakes and "ON" or "OFF"), UDim2.new(0, 150, 0, 115), function() riskyMistakes = not riskyMistakes; Config.RiskyMistakes = riskyMistakes; return riskyMistakes, "Risky Mistakes: "..(riskyMistakes and "ON" or "OFF"), riskyMistakes and Color3.fromRGB(255, 80, 80) or THEME.SubText end); RiskyBtn.TextColor3 = riskyMistakes and Color3.fromRGB(255, 80, 80) or THEME.SubText; RiskyBtn.Size = UDim2.new(0, 130, 0, 24)

local BlatantThresholdOptions = {}
for i = 1, 14 do table.insert(BlatantThresholdOptions, i.."s") end
local BlatantThresholdDropdown = CreateDropdown(TogglesFrame, "Threshold", BlatantThresholdOptions, Config.BlatantThreshold.."s", function(val) Config.BlatantThreshold = tonumber(val:sub(1, -2)); SaveConfig() end)
BlatantThresholdDropdown.Position = UDim2.new(0, 15, 0, 170)

local originalHumanizeState = Config.OriginalHumanize
local originalErrorRateValue = Config.OriginalErrorRate
local originalSortModeValue = Config.OriginalSortMode
local isBlatantActive = false

local function UpdateBlatantState(active)
    if active and not isBlatantActive then
        Config.OriginalHumanize = useHumanization
        Config.OriginalErrorRate = errorRate
        Config.OriginalSortMode = sortMode
        SaveConfig()
        useHumanization = false
        errorRate = 0
        sortMode = "Shortest"
        isBlatantActive = true
        StatusText.Text = "BLATANT MODE ACTIVATED"
        StatusText.TextColor3 = Color3.fromRGB(255, 80, 80)
    elseif not active and isBlatantActive then
        useHumanization = Config.OriginalHumanize
        errorRate = Config.OriginalErrorRate
        sortMode = Config.OriginalSortMode
        isBlatantActive = false
        StatusText.Text = "BLATANT MODE DEACTIVATED"
        StatusText.TextColor3 = THEME.Text
    end
end

RunService.Heartbeat:Connect(function()
    if Config.BlatantMode == "on" then
        UpdateBlatantState(true)
    elseif Config.BlatantMode == "off" then
        UpdateBlatantState(false)
    elseif Config.BlatantMode == "auto" then
        local inGameFrame = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("InGame")
        if inGameFrame and inGameFrame:FindFirstChild("Frame") then
            local currentSeconds = seconds
            if currentSeconds and currentSeconds <= Config.BlatantThreshold then
                UpdateBlatantState(true)
            else
                UpdateBlatantState(false)
            end
        else
            UpdateBlatantState(false)
        end
    end
end)
