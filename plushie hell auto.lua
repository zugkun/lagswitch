--=== PLUSHIE HELL AUTO FARMER ===--
-- Otomatis aktif saat special round "Plushie Hell" terdeteksi
-- Menggunakan: UpdateServerStateRegistry > SpecialRound

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

-- ================================================================
--   PATH DARI HASIL DEBUG
-- ================================================================
local ticketsFolder = Workspace:WaitForChild("Effects"):WaitForChild("Tickets")
local Events        = ReplicatedStorage:WaitForChild("Events")

-- ================================================================
--   STATE
-- ================================================================
local State = {
    PlushieFarm    = false,
    IsPlushieHell  = false,
    AutoActivate   = true,
    SafeZonePos    = Vector3.new(0, 5000, 0),
    SafePlatform   = nil,
    MenuOpen       = true,
    TicketCount    = 0,
    RoundName      = "—",
    TicketVisuals  = true,
    _menuAnimating = false,
    -- Map Switch
    AutoSwitchMap  = true,
    RoundsDone     = 0,
    SwitchEvery    = 2,
}

local farmConnections = {}

-- ================================================================
--   GUI SYSTEM
-- ================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlushieHellUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
do
    local ok = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ok then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

-- ---------- MAIN PANEL ----------
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 510)
Main.Position = UDim2.new(0, 20, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(12, 8, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Visible = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = Color3.fromRGB(160, 80, 255)
mainStroke.Thickness = 1.5

-- Gradient background
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 10, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 5, 18)),
})
gradient.Rotation = 135
gradient.Parent = Main

-- ---------- HEADER ----------
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundColor3 = Color3.fromRGB(80, 20, 160)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
local hGrad = Instance.new("UIGradient")
hGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 40, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 10, 140)),
})
hGrad.Rotation = 90
hGrad.Parent = Header

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Text = "🧸"
TitleIcon.Size = UDim2.new(0, 40, 1, 0)
TitleIcon.Position = UDim2.new(0, 8, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.TextScaled = true
TitleIcon.Parent = Header

local TitleText = Instance.new("TextLabel")
TitleText.Text = "PLUSHIE HELL FARMER"
TitleText.Size = UDim2.new(1, -55, 0, 28)
TitleText.Position = UDim2.new(0, 50, 0, 4)
TitleText.BackgroundTransparency = 1
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = Header

local SubText = Instance.new("TextLabel")
SubText.Text = "[INSERT] Toggle"
SubText.Size = UDim2.new(1, -55, 0, 18)
SubText.Position = UDim2.new(0, 50, 0, 30)
SubText.BackgroundTransparency = 1
SubText.TextColor3 = Color3.fromRGB(200, 160, 255)
SubText.Font = Enum.Font.Gotham
SubText.TextSize = 11
SubText.TextXAlignment = Enum.TextXAlignment.Left
SubText.Parent = Header

-- ---------- STATUS BOX ----------
local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -20, 0, 70)
StatusBox.Position = UDim2.new(0, 10, 0, 65)
StatusBox.BackgroundColor3 = Color3.fromRGB(20, 12, 38)
StatusBox.BorderSizePixel = 0
StatusBox.Parent = Main
Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", StatusBox).Color = Color3.fromRGB(80, 40, 140)

local RoundStatusLabel = Instance.new("TextLabel")
RoundStatusLabel.Name = "RoundStatus"
RoundStatusLabel.Text = "🔍 Menunggu Plushie Hell..."
RoundStatusLabel.Size = UDim2.new(1, -10, 0, 28)
RoundStatusLabel.Position = UDim2.new(0, 5, 0, 4)
RoundStatusLabel.BackgroundTransparency = 1
RoundStatusLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
RoundStatusLabel.Font = Enum.Font.GothamSemibold
RoundStatusLabel.TextSize = 13
RoundStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
RoundStatusLabel.Parent = StatusBox

local TicketCountLabel = Instance.new("TextLabel")
TicketCountLabel.Name = "TicketCount"
TicketCountLabel.Text = "🎟 Ticket difarm: 0"
TicketCountLabel.Size = UDim2.new(1, -10, 0, 22)
TicketCountLabel.Position = UDim2.new(0, 5, 0, 30)
TicketCountLabel.BackgroundTransparency = 1
TicketCountLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
TicketCountLabel.Font = Enum.Font.GothamSemibold
TicketCountLabel.TextSize = 12
TicketCountLabel.TextXAlignment = Enum.TextXAlignment.Left
TicketCountLabel.Parent = StatusBox

local FarmStatusLabel = Instance.new("TextLabel")
FarmStatusLabel.Name = "FarmStatus"
FarmStatusLabel.Text = "⏸ Farm: Tidak Aktif"
FarmStatusLabel.Size = UDim2.new(1, -10, 0, 18)
FarmStatusLabel.Position = UDim2.new(0, 5, 0, 50)
FarmStatusLabel.BackgroundTransparency = 1
FarmStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
FarmStatusLabel.Font = Enum.Font.Gotham
FarmStatusLabel.TextSize = 11
FarmStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
FarmStatusLabel.Parent = StatusBox

-- ---------- HELPER: BUAT TOMBOL ----------
local function makeToggleBtn(name, labelOff, labelOn, yPos, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 28, 0, 18)
    dot.Position = UDim2.new(1, -38, 0.5, -9)
    dot.BorderSizePixel = 0
    dot.Parent = btn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local dotInner = Instance.new("Frame")
    dotInner.Name = "Inner"
    dotInner.Size = UDim2.new(0, 14, 0, 14)
    dotInner.Position = UDim2.new(0, 2, 0.5, -7)
    dotInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dotInner.BorderSizePixel = 0
    dotInner.Parent = dot
    Instance.new("UICorner", dotInner).CornerRadius = UDim.new(1, 0)

    local state = defaultState

    local function refresh()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = "  " .. labelOn
            dot.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
            TweenService:Create(dotInner, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 12, 0.5, -7)
            }):Play()
        else
            btn.BackgroundColor3 = Color3.fromRGB(35, 20, 55)
            btn.TextColor3 = Color3.fromRGB(160, 130, 200)
            btn.Text = "  " .. labelOff
            dot.BackgroundColor3 = Color3.fromRGB(70, 50, 100)
            TweenService:Create(dotInner, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 2, 0.5, -7)
            }):Play()
        end
    end

    refresh()

    btn.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        callback(state)
    end)

    return btn, function(newState)
        state = newState
        refresh()
    end
end

-- ---------- TOMBOL-TOMBOL ----------
local BtnAutoActivate, SetAutoActivate = makeToggleBtn(
    "BtnAutoActivate",
    "Auto-Activate: OFF",
    "Auto-Activate: ON ✓",
    148,
    State.AutoActivate,
    function(s)
        State.AutoActivate = s
        print("Auto-Activate: " .. tostring(s))
    end
)

local BtnFarm, SetFarmState = makeToggleBtn(
    "BtnFarm",
    "Farm Manual: OFF",
    "Farm Manual: ON ✓",
    196,
    false,
    function(s)
        State.PlushieFarm = s
        if s then
            FarmStatusLabel.Text = "▶ Farm: Aktif (Manual)"
            FarmStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        else
            FarmStatusLabel.Text = "⏸ Farm: Tidak Aktif"
            FarmStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
)

local BtnSafeZone, SetSafeZone = makeToggleBtn(
    "BtnSafeZone",
    "Safe Zone: OFF",
    "Safe Zone: ON ✓",
    244,
    false,
    function(s)
        if s then
            -- Buat safe platform
            if not State.SafePlatform then
                local part = Instance.new("Part")
                part.Name = "PlushieSafeZone"
                part.Size = Vector3.new(50, 2, 50)
                part.Position = State.SafeZonePos - Vector3.new(0, 4, 0)
                part.Anchored = true
                part.CanCollide = true
                part.Transparency = 0.4
                part.Color = Color3.fromRGB(140, 50, 255)
                part.Material = Enum.Material.Neon
                part.Parent = Workspace
                State.SafePlatform = part
            end
        else
            if State.SafePlatform then
                State.SafePlatform:Destroy()
                State.SafePlatform = nil
            end
        end
    end
)

-- Tombol Ticket Visual Toggle
local BtnTicketVis, SetTicketVis = makeToggleBtn(
    "BtnTicketVis",
    "Ticket Visual: OFF",
    "Ticket Visual: ON ✓",
    292,
    State.TicketVisuals,
    function(s)
        State.TicketVisuals = s
        -- Update semua billboard yang sudah ada
        for _, v in ipairs(ticketsFolder:GetDescendants()) do
            if v:IsA("BasePart") then
                local bb = v:FindFirstChildOfClass("BillboardGui")
                if bb then bb.Enabled = s end
                local sl = v:FindFirstChildOfClass("SelectionBox")
                if sl then sl.Visible = s end
            end
        end
    end
)

-- Tombol Auto Switch Map (toggle)
local BtnAutoSwitch, SetAutoSwitch = makeToggleBtn(
    "BtnAutoSwitch",
    "Auto Switch Map: OFF",
    "Auto Switch Map: ON ✓",
    340,
    State.AutoSwitchMap,
    function(s)
        State.AutoSwitchMap = s
    end
)

-- Label counter round selesai
local RoundCounterLabel = Instance.new("TextLabel")
RoundCounterLabel.Name = "RoundCounter"
RoundCounterLabel.Text = "🔄 Round selesai: 0 / 2 → Drab"
RoundCounterLabel.Size = UDim2.new(1, -20, 0, 20)
RoundCounterLabel.Position = UDim2.new(0, 10, 0, 388)
RoundCounterLabel.BackgroundTransparency = 1
RoundCounterLabel.TextColor3 = Color3.fromRGB(160, 200, 255)
RoundCounterLabel.Font = Enum.Font.GothamSemibold
RoundCounterLabel.TextSize = 11
RoundCounterLabel.TextXAlignment = Enum.TextXAlignment.Left
RoundCounterLabel.Parent = Main

-- Tombol Instant Switch ke Drab
local BtnSwitchNow = Instance.new("TextButton")
BtnSwitchNow.Name = "BtnSwitchNow"
BtnSwitchNow.Size = UDim2.new(1, -20, 0, 36)
BtnSwitchNow.Position = UDim2.new(0, 10, 0, 412)
BtnSwitchNow.BackgroundColor3 = Color3.fromRGB(15, 70, 160)
BtnSwitchNow.TextColor3 = Color3.fromRGB(180, 220, 255)
BtnSwitchNow.Text = "🗺️ Switch ke Drab Sekarang"
BtnSwitchNow.Font = Enum.Font.GothamBold
BtnSwitchNow.TextSize = 12
BtnSwitchNow.BorderSizePixel = 0
BtnSwitchNow.Parent = Main
Instance.new("UICorner", BtnSwitchNow).CornerRadius = UDim.new(0, 8)
local sbStroke = Instance.new("UIStroke", BtnSwitchNow)
sbStroke.Color = Color3.fromRGB(80, 160, 255)
sbStroke.Thickness = 1.5

-- Tombol Reset Counter
local BtnReset = Instance.new("TextButton")
BtnReset.Size = UDim2.new(1, -20, 0, 30)
BtnReset.Position = UDim2.new(0, 10, 0, 458)
BtnReset.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
BtnReset.TextColor3 = Color3.fromRGB(255, 150, 150)
BtnReset.Text = "🔄 Reset Counter"
BtnReset.Font = Enum.Font.GothamSemibold
BtnReset.TextSize = 12
BtnReset.BorderSizePixel = 0
BtnReset.Parent = Main
Instance.new("UICorner", BtnReset).CornerRadius = UDim.new(0, 8)
BtnReset.MouseButton1Click:Connect(function()
    State.TicketCount = 0
    State.RoundsDone  = 0
    TicketCountLabel.Text = "🎟 Ticket difarm: 0"
    RoundCounterLabel.Text = "🔄 Round selesai: 0 / 2 → Drab"
end)



-- ================================================================
--   TOGGLE MENU (dengan animasi slide)
-- ================================================================
local MENU_OPEN_X  = UDim2.new(0, 20, 0.5, -185)
local MENU_CLOSE_X = UDim2.new(0, -320, 0.5, -185)
Main.Position = MENU_OPEN_X

local function setMenuVisible(open, silent)
    if State._menuAnimating then return end
    State.MenuOpen = open
    if open then
        Main.Visible = true
        if not silent then
            State._menuAnimating = true
            TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = MENU_OPEN_X
            }):Play()
            task.delay(0.4, function() State._menuAnimating = false end)
        else
            Main.Position = MENU_OPEN_X
        end
    else
        if not silent then
            State._menuAnimating = true
            TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = MENU_CLOSE_X
            }):Play()
            task.delay(0.3, function()
                Main.Visible = false
                State._menuAnimating = false
            end)
        else
            Main.Position = MENU_CLOSE_X
            Main.Visible = false
        end
    end
end

-- Inisialisasi posisi GUI saat pertama jalan
Main.Visible = true
Main.Position = MENU_OPEN_X

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        setMenuVisible(not State.MenuOpen)
    end
end)

-- ================================================================
--   SAFE PLATFORM CREATION
-- ================================================================
local function ensureSafePlatform()
    if State.SafePlatform then return end
    local part = Instance.new("Part")
    part.Name = "PlushieSafeZone"
    part.Size = Vector3.new(50, 2, 50)
    part.Position = State.SafeZonePos - Vector3.new(0, 4, 0)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0.4
    part.Color = Color3.fromRGB(140, 50, 255)
    part.Material = Enum.Material.Neon
    part.Parent = Workspace
    State.SafePlatform = part
    SetSafeZone(true)
end

-- ================================================================
--   CORE FARM LOOP (EVENT-BASED)
-- ================================================================
task.spawn(function()
    while true do
        task.wait(0.3)
        if not State.PlushieFarm then continue end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local hrp = char.HumanoidRootPart

        -- Cari ticket terdekat
        local target = nil
        local closestDist = math.huge
        for _, v in ipairs(ticketsFolder:GetDescendants()) do
            if v:IsA("BasePart") and v.Parent then
                local d = (hrp.Position - v.Position).Magnitude
                if d < closestDist then
                    closestDist = d
                    target = v
                end
            end
        end

        if not target then
            -- Tidak ada ticket → tunggu di safe place
            if State.SafePlatform and (hrp.Position - State.SafeZonePos).Magnitude > 50 then
                hrp.CFrame = CFrame.new(State.SafeZonePos + Vector3.new(0, 3, 0))
            end
            FarmStatusLabel.Text = "🔍 Mencari ticket..."
            task.wait(0.8)
            continue
        end

        FarmStatusLabel.Text = "🎟 Farming: " .. target.Name

        -- EVENT-BASED: tunggu ticket hilang
        local pickedUp = false
        local conn = target.AncestryChanged:Connect(function(_, newParent)
            if newParent == nil then pickedUp = true end
        end)

        local timeout = 0
        repeat
            if not target.Parent then break end
            hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 2, 0))
            task.wait(0.08)
            timeout += 0.08
        until pickedUp or timeout >= 3 or not target.Parent

        conn:Disconnect()

        if pickedUp or not target.Parent then
            State.TicketCount += 1
            TicketCountLabel.Text = "🎟 Ticket difarm: " .. State.TicketCount
            FarmStatusLabel.Text = "✅ Picked! Total: " .. State.TicketCount

            -- Kembali ke safe zone
            task.wait(0.1)
            if State.SafePlatform then
                hrp.CFrame = CFrame.new(State.SafeZonePos + Vector3.new(0, 3, 0))
            end
            task.wait(0.3)
        else
            -- Timeout: skip ticket ini
            FarmStatusLabel.Text = "⚠ Timeout, skip..."
            task.wait(0.4)
        end
    end
end)

-- ================================================================
--   SWITCH MAP KE DRAB
-- ================================================================
local function switchToDrab()
    -- Coba beberapa remote event umum untuk vote/switch map
    local tried = {}

    -- Metode 1: RemoteEvent VoteMap / MapVote / SetMap
    for _, name in ipairs({"VoteMap","MapVote","SetMap","ChangeMap","VoteForMap"}) do
        local ev = Events:FindFirstChild(name)
        if ev and ev:IsA("RemoteEvent") then
            pcall(function() ev:FireServer("Drab") end)
            pcall(function() ev:FireServer("drab") end)
            table.insert(tried, name)
        end
    end

    -- Metode 2: UpdateServerStateRegistry dengan key Map
    local sr = Events:FindFirstChild("UpdateServerStateRegistry")
    if sr and sr:IsA("RemoteEvent") then
        pcall(function() sr:FireServer("Map", "Drab") end)
        pcall(function() sr:FireServer("Map", "drab") end)
        table.insert(tried, "UpdateServerStateRegistry(Map)")
    end

    -- Metode 3: RemoteFunction
    for _, name in ipairs({"VoteMapFunction","MapFunction","SelectMap"}) do
        local fn = Events:FindFirstChild(name)
        if fn and fn:IsA("RemoteFunction") then
            pcall(function() fn:InvokeServer("Drab") end)
            table.insert(tried, name)
        end
    end

    local msg = #tried > 0
        and ("🗺️ Drab switch via: " .. table.concat(tried, ", "))
        or "🗺️ Switch Drab (tidak ada event ditemukan)"
    RoundStatusLabel.Text = msg
    RoundStatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    print("[MapSwitch] " .. msg)

    task.delay(3, function()
        if not State.IsPlushieHell then
            RoundStatusLabel.Text = "🔍 Menunggu Plushie Hell..."
            RoundStatusLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
        end
    end)
end

-- Koneksi tombol instant switch
BtnSwitchNow.MouseButton1Click:Connect(function()
    TweenService:Create(BtnSwitchNow, TweenInfo.new(0.1), {
        BackgroundColor3 = Color3.fromRGB(50, 130, 255)
    }):Play()
    task.delay(0.25, function()
        TweenService:Create(BtnSwitchNow, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(15, 70, 160)
        }):Play()
    end)
    switchToDrab()
end)

-- ================================================================
--   DETEKSI SPECIAL ROUND (dari UpdateServerStateRegistry)
-- ================================================================
local stateRegistry = Events:WaitForChild("UpdateServerStateRegistry", 10)

if stateRegistry then
    stateRegistry.OnClientEvent:Connect(function(key, value)

        -- ── Plushie Hell MULAI ──
        if key == "SpecialRound" and type(value) == "string" then
            State.RoundName = value
            local isPlushie = value:lower():find("plushie") ~= nil

            if isPlushie then
                State.IsPlushieHell = true
                RoundStatusLabel.Text = "🧸 PLUSHIE HELL AKTIF!"
                RoundStatusLabel.TextColor3 = Color3.fromRGB(220, 140, 255)
                mainStroke.Color = Color3.fromRGB(220, 80, 255)

                if State.AutoActivate then
                    -- Auto aktifkan farm + safe zone (TIDAK sentuh tombol Manual)
                    ensureSafePlatform()
                    State.PlushieFarm = true
                    FarmStatusLabel.Text = "▶ Farm: Aktif (Auto)"
                    FarmStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
                end

            else
                -- Round lain
                State.IsPlushieHell = false
                RoundStatusLabel.Text = "⚡ Round: " .. value
                RoundStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                mainStroke.Color = Color3.fromRGB(160, 80, 255)
            end

        -- ── Special Round SELESAI ──
        elseif key == "SpecialRound" and (value == false or value == "false") then
            if State.IsPlushieHell and State.AutoActivate then
                -- Auto matikan farm (TIDAK sentuh tombol Manual)
                State.PlushieFarm = false
                FarmStatusLabel.Text = "⏸ Farm: Selesai (Auto)"
                FarmStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end

            State.IsPlushieHell = false
            State.RoundName = "—"
            RoundStatusLabel.Text = "🔍 Menunggu Plushie Hell..."
            RoundStatusLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
            mainStroke.Color = Color3.fromRGB(160, 80, 255)

            -- ── Hitung round & auto switch map ──
            State.RoundsDone += 1
            RoundCounterLabel.Text = "🔄 Round selesai: " .. State.RoundsDone .. " / " .. State.SwitchEvery .. " → Drab"
            if State.AutoSwitchMap and State.RoundsDone >= State.SwitchEvery then
                State.RoundsDone = 0
                RoundCounterLabel.Text = "🔄 Switching ke Drab... (0 / " .. State.SwitchEvery .. ")"
                task.delay(2, function()
                    switchToDrab()
                    RoundCounterLabel.Text = "🔄 Round selesai: 0 / " .. State.SwitchEvery .. " → Drab"
                end)
            end
        end
    end)

    print("✅ PLUSHIE HELL DETECTOR: Aktif")
else
    warn("❌ UpdateServerStateRegistry tidak ditemukan!")
    RoundStatusLabel.Text = "❌ Event tidak ditemukan!"
    RoundStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
end

-- ================================================================
--   VISUAL HIGHLIGHT PADA TIKET
-- ================================================================
local ticketHighlights = {}

local function addTicketVisual(part)
    if not part:IsA("BasePart") then return end
    if part:FindFirstChildOfClass("BillboardGui") then return end

    -- BillboardGui label
    local bb = Instance.new("BillboardGui")
    bb.Name = "TicketLabel"
    bb.Size = UDim2.new(0, 60, 0, 30)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = State.TicketVisuals
    bb.Parent = part

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundColor3 = Color3.fromRGB(20, 8, 40)
    lbl.BackgroundTransparency = 0.3
    lbl.TextColor3 = Color3.fromRGB(255, 220, 80)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.Text = "🎟 TICKET"
    lbl.Parent = bb
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
    local ls = Instance.new("UIStroke", lbl)
    ls.Color = Color3.fromRGB(255, 180, 0)
    ls.Thickness = 1.5

    -- SelectionBox glow
    local sel = Instance.new("SelectionBox")
    sel.Adornee = part
    sel.Color3 = Color3.fromRGB(255, 210, 0)
    sel.LineThickness = 0.06
    sel.SurfaceTransparency = 0.75
    sel.SurfaceColor3 = Color3.fromRGB(255, 230, 80)
    sel.Visible = State.TicketVisuals
    sel.Parent = part

    -- Pulse animasi warna label
    task.spawn(function()
        local hue = 0
        while part and part.Parent do
            hue = (hue + 2) % 360
            local c = Color3.fromHSV(hue/360, 0.9, 1)
            lbl.TextColor3 = c
            ls.Color = c
            task.wait(0.05)
        end
    end)

    ticketHighlights[part] = { bb = bb, sel = sel }
end

local function removeTicketVisual(part)
    local h = ticketHighlights[part]
    if h then
        if h.bb and h.bb.Parent then h.bb:Destroy() end
        if h.sel and h.sel.Parent then h.sel:Destroy() end
        ticketHighlights[part] = nil
    end
end

-- Pasang visual pada tiket yang sudah ada
for _, v in ipairs(ticketsFolder:GetDescendants()) do
    pcall(addTicketVisual, v)
end

-- Deteksi tiket baru
ticketsFolder.DescendantAdded:Connect(function(v)
    task.wait(0.05)
    pcall(addTicketVisual, v)
end)

ticketsFolder.DescendantRemoving:Connect(function(v)
    removeTicketVisual(v)
end)

-- ================================================================
--   GLOBAL API untuk VIP Menu
-- ================================================================
-- VIP menu atau script lain bisa panggil:
--   _PlushieHell.setFarm(true/false)
--   _PlushieHell.setMenu(true/false)
--   _PlushieHell.setAutoActivate(true/false)
--   _PlushieHell.setTicketVisual(true/false)
_G._PlushieHell = {
    setFarm = function(active)
        State.PlushieFarm = active
        SetFarmState(active)
        if active then
            FarmStatusLabel.Text = "▶ Farm: Aktif (VIP)"
            FarmStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        else
            FarmStatusLabel.Text = "⏸ Farm: Tidak Aktif"
            FarmStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end,
    setMenu = function(open)
        setMenuVisible(open)
    end,
    setAutoActivate = function(active)
        State.AutoActivate = active
        SetAutoActivate(active)
    end,
    setTicketVisual = function(enabled)
        State.TicketVisuals = enabled
        SetTicketVis(enabled)
        for _, v in ipairs(ticketsFolder:GetDescendants()) do
            if v:IsA("BasePart") then
                local bb = v:FindFirstChildOfClass("BillboardGui")
                if bb then bb.Enabled = enabled end
                local sl = v:FindFirstChildOfClass("SelectionBox")
                if sl then sl.Visible = enabled end
            end
        end
    end,
    getState = function()
        return {
            farmActive     = State.PlushieFarm,
            isPlushieHell  = State.IsPlushieHell,
            autoActivate   = State.AutoActivate,
            ticketVisuals  = State.TicketVisuals,
            ticketCount    = State.TicketCount,
            menuOpen       = State.MenuOpen,
        }
    end,
}

-- ================================================================
--   ANTI-AFK
-- ================================================================
local AntiAfkLabel = Instance.new("TextLabel")
AntiAfkLabel.Name = "AntiAfkStatus"
AntiAfkLabel.Text = "🟢 Anti-AFK: Aktif"
AntiAfkLabel.Size = UDim2.new(1, -10, 0, 18)
AntiAfkLabel.Position = UDim2.new(0, 5, 1, -22)
AntiAfkLabel.BackgroundTransparency = 1
AntiAfkLabel.TextColor3 = Color3.fromRGB(100, 255, 160)
AntiAfkLabel.Font = Enum.Font.Gotham
AntiAfkLabel.TextSize = 11
AntiAfkLabel.TextXAlignment = Enum.TextXAlignment.Left
AntiAfkLabel.Parent = StatusBox

-- Perluas StatusBox sedikit untuk label baru
StatusBox.Size = UDim2.new(1, -20, 0, 90)

local VirtualUser = game:GetService("VirtualUser")

-- Cegah kick AFK via VirtualUser (paling reliable)
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- Loop tambahan: simulasi mouse move setiap 60 detik sebagai lapisan kedua
task.spawn(function()
    local tick = 0
    while true do
        task.wait(60)
        tick += 1
        -- Simulasi klik kecil yang tidak terlihat
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
        -- Update label dengan waktu terakhir ping
        AntiAfkLabel.Text = "🟢 Anti-AFK: Aktif (ping #" .. tick .. ")"
    end
end)

print("🧸 Plushie Hell Auto Farmer siap! [INSERT] = toggle GUI")
print("📡 Global API tersedia di _G._PlushieHell")
print("🛡️ Anti-AFK aktif")
