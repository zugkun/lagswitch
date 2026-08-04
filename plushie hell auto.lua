local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local WEBHOOK_URL = "https://ptb.discord.com/api/webhooks/1511766816123392053/xfRbCzVmqLko999ARW4IiFuvexK-Zma6LaWYnDKeB4naycxu4pEe7DtZ39WU6v-JMMdi"

local function GetPing()
    local ok, ping = pcall(function()
        return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    if ok and ping then return ping end
    local ok2, ping2 = pcall(function()
        return math.floor(LocalPlayer:GetNetworkPing() * 1000)
    end)
    if ok2 and ping2 then return ping2 end
    return 0
end

local function GetMapName()
    local mapObj = Workspace:FindFirstChild("Map")
    if mapObj then
        local attr = mapObj:GetAttribute("MapName") or mapObj:GetAttribute("Name")
        if attr and type(attr) == "string" and #attr > 0 then
            return attr
        end
        if mapObj.Name ~= "Map" then
            return mapObj.Name
        end
        for _, child in ipairs(mapObj:GetChildren()) do
            if (child:IsA("Model") or child:IsA("Folder")) and child.Name ~= "Settings" then
                return child.Name
            end
        end
        return "Map"
    end
    local ok, res = pcall(function()
        local svc = ReplicatedStorage:FindFirstChild("Services")
        local data = svc and svc:FindFirstChild("Data")
        local regMod = data and data:FindFirstChild("ServerStateRegistryService")
        if regMod then
            return require(regMod):Get("MapName") or require(regMod):Get("Map")
        end
    end)
    if ok and res and type(res) == "string" and #res > 0 then
        return res
    end
    return "Intermission"
end

local ticketsFolder = nil
local function GetTicketsFolder()
    if ticketsFolder and ticketsFolder.Parent then return ticketsFolder end
    pcall(function()
        local eff = Workspace:FindFirstChild("Effects")
        if eff then
            ticketsFolder = eff:FindFirstChild("Tickets")
        end
        if not ticketsFolder then
            ticketsFolder = Workspace:FindFirstChild("Tickets")
        end
    end)
    return ticketsFolder
end

local function SendWebhook(title, description, color, fields)
    local requestFunc = (getgenv and (getgenv().request or getgenv().http_request)) 
        or (syn and syn.request) 
        or (http and http.request) 
        or http_request 
        or request
    if type(requestFunc) ~= "function" then return end

    local userId = 0
    pcall(function() userId = LocalPlayer.UserId end)
    if userId == 0 then return end

    local OSTime = os.time()
    local Time = os.date("!*t", OSTime)
    local placeId = game.PlaceId
    local jobId = game.JobId
    local playerUrl = string.format("https://www.roblox.com/users/%d/profile", userId)
    local joinUrl = string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)

    local embedFields = {
        { name = "👤 Player", value = string.format("[%s](%s) | UID: `%d`", LocalPlayer.Name, playerUrl, userId), inline = true },
        { name = "🎮 Server", value = string.format("[Join Server](%s)\nPlace ID: `%d`", joinUrl, placeId), inline = true }
    }

    if fields then
        for _, f in ipairs(fields) do
            table.insert(embedFields, f)
        end
    end

    local embed = {
        title = title,
        description = description,
        color = color or 5814783,
        fields = embedFields,
        timestamp = string.format("%d-%02d-%02dT%02d:%02d:%02dZ", Time.year, Time.month, Time.day, Time.hour, Time.min, Time.sec),
        footer = { text = "Evade AutoTicket v4 | Elite Farm", icon_url = "https://cdn.discordapp.com/embed/avatars/4.png" },
        thumbnail = { url = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png", userId) }
    }

    pcall(function()
        requestFunc({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ embeds = { embed } })
        })
    end)
end

local Events = nil
local SharedUD = nil
local ExchangeTickets = nil
local CurrencyChannel = nil
local CharacterTask = nil
local UpdateMap = nil

task.spawn(function()
    pcall(function() Events = ReplicatedStorage:WaitForChild("Events", 10) end)
    pcall(function()
        local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
        local UD = Shared:WaitForChild("UserData", 10)
        SharedUD = UD:WaitForChild("Events", 10)
    end)
    pcall(function()
        if SharedUD then
            ExchangeTickets = SharedUD:FindFirstChild("Requests") and SharedUD.Requests:FindFirstChild("ExchangeTickets")
            CurrencyChannel = SharedUD:FindFirstChild("Channels") and SharedUD.Channels:FindFirstChild("Currency")
        end
    end)
    pcall(function()
        if Events then
            CharacterTask = Events:FindFirstChild("CharacterTask")
            UpdateMap = Events:FindFirstChild("UpdateMap")
        end
    end)
end)

local State = {
    ESP = true,
    AutoFarm = false,
    AntiAFK = false,
    AutoRespawn = false,
    AutoPlushieHell = false,
    PlushieHellBusy = false,
    PlushieRoundConn = nil,
    MenuOpen = true,
    SafeZonePos = Vector3.new(0, 5000, 0),
    SafePlatform = nil,
    CurrentMap = "Unknown",
}

local ESP_Table = {}
local AntiAfkConn = nil
local AutoRespawnConn = nil
local MapConn = nil
local TicketsFarmed = 0
local RoundTicketsFarmed = 0
local LastRoundStatus = nil

local function CreateSafePlatform()
    if State.SafePlatform then return end
    local part = Instance.new("Part")
    part.Name = "SafeZonePlatform"
    part.Size = Vector3.new(50, 2, 50)
    part.Position = State.SafeZonePos - Vector3.new(0, 4, 0)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0.5
    part.Color = Color3.fromRGB(0, 255, 255)
    part.Material = Enum.Material.Neon
    part.Parent = Workspace
    State.SafePlatform = part
end

local function ToggleAntiAFK(enabled)
    if enabled then
        if AntiAfkConn then AntiAfkConn:Disconnect() end
        AntiAfkConn = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if AntiAfkConn then AntiAfkConn:Disconnect(); AntiAfkConn = nil end
    end
end

local function ToggleAutoRespawn(enabled)
    if enabled then
        if AutoRespawnConn then AutoRespawnConn:Disconnect() end
        AutoRespawnConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then
                task.spawn(function()
                    task.wait(0.5)
                    pcall(function()
                        if CharacterTask then CharacterTask:FireServer("Respawn") end
                    end)
                    task.wait(0.5)
                    if LocalPlayer.Character == char then
                        pcall(function() LocalPlayer:LoadCharacter() end)
                    end
                end)
            end
        end)
    else
        if AutoRespawnConn then AutoRespawnConn:Disconnect(); AutoRespawnConn = nil end
    end
end

local function TriggerPlushieHell()
    if State.PlushieHellBusy then return end
    State.PlushieHellBusy = true

    local EventsFolder = ReplicatedStorage:FindFirstChild("Events")
    local AdminFolder = EventsFolder and EventsFolder:FindFirstChild("Admin")

    pcall(function()
        local vipCmd = AdminFolder and AdminFolder:FindFirstChild("VIPCommand")
        if vipCmd then
            vipCmd:FireServer("!specialround Plushie_Hell")
            vipCmd:FireServer("!specialround Plushie Hell")
            vipCmd:FireServer("!special Plushie_Hell")
        end
    end)

    pcall(function()
        local vipCmd = AdminFolder and AdminFolder:FindFirstChild("VIPCommand")
        if vipCmd then
            vipCmd:FireServer("Gamemode", "Plushie_Hell")
            vipCmd:FireServer("SpecialRound", "Plushie_Hell")
        end
    end)

    pcall(function()
        local updReg = EventsFolder and EventsFolder:FindFirstChild("UpdateServerStateRegistry")
        if updReg then
            updReg:FireServer({ SpecialRound = "Plushie_Hell" })
        end
    end)

    pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        local stateSvc = shared and shared:FindFirstChild("StateService")
        local funcs = stateSvc and stateSvc:FindFirstChild("Functions")
        local relCommit = funcs and funcs:FindFirstChild("ReliableCommit")
        if relCommit then
            relCommit:InvokeServer({ SpecialRound = "Plushie_Hell" })
        end
    end)

    task.wait(3)
    State.PlushieHellBusy = false
end

local function StartAutoPlushieHell()
    if State.PlushieRoundConn then
        State.PlushieRoundConn:Disconnect()
        State.PlushieRoundConn = nil
    end

    pcall(function()
        local remoteEvt = ReplicatedStorage:FindFirstChild("Events")
        local updMap = remoteEvt and remoteEvt:FindFirstChild("UpdateMap")
        if updMap then
            State.PlushieRoundConn = updMap.OnClientEvent:Connect(function(isReset)
                if not State.AutoPlushieHell then return end
                task.wait(2)
                task.spawn(TriggerPlushieHell)
            end)
        end
    end)
end

local function StopAutoPlushieHell()
    if State.PlushieRoundConn then
        State.PlushieRoundConn:Disconnect()
        State.PlushieRoundConn = nil
    end
end

local function SetupMapDetection()
    if MapConn then MapConn:Disconnect() end

    local remoteEv = ReplicatedStorage:FindFirstChild("Events")
    local updMap = remoteEv and remoteEv:FindFirstChild("UpdateMap")
    if updMap then
        MapConn = updMap.OnClientEvent:Connect(function(isReset)
            task.wait(0.8)
            local newMap = GetMapName()
            if newMap ~= State.CurrentMap then
                State.CurrentMap = newMap
                local mapType = isReset and "Reset" or "New Map"
                SendWebhook(
                    "🗺️ Map Changed!",
                    string.format("Map berubah ke **%s** (%s). AutoFarm tetap berjalan...", newMap, mapType),
                    3447003,
                    {
                        { name = "🎯 Map", value = newMap, inline = true },
                        { name = "🔄 Type", value = mapType, inline = true },
                        { name = "📶 Ping", value = string.format("%d ms", GetPing()), inline = true }
                    }
                )
            end
        end)
    end

    pcall(function()
        local svcData = ReplicatedStorage:FindFirstChild("Services")
        local dataF = svcData and svcData:FindFirstChild("Data")
        local regSvc = dataF and dataF:FindFirstChild("ServerStateRegistryService")
        local chgEv = regSvc and regSvc:FindFirstChild("ChangedEvent")
        if chgEv then
            chgEv.Event:Connect(function(key, value)
                if key == "RoundStatus" then
                    if LastRoundStatus == 1 and (value == 2 or value == 0) then
                        SendWebhook(
                            "🏁 Round Finished!",
                            string.format("Round di map **%s** telah selesai!", State.CurrentMap),
                            65280,
                            {
                                { name = "🎯 Map", value = State.CurrentMap, inline = true },
                                { name = "🎫 Round Tickets", value = tostring(RoundTicketsFarmed), inline = true },
                                { name = "📊 Total Tickets", value = tostring(TicketsFarmed), inline = true },
                                { name = "📶 Ping", value = string.format("%d ms", GetPing()), inline = true }
                            }
                        )
                        RoundTicketsFarmed = 0
                    elseif value == 1 then
                        RoundTicketsFarmed = 0
                    end
                    LastRoundStatus = value
                elseif key == "MapName" and value then
                    State.CurrentMap = tostring(value)
                end
            end)
        end
    end)
end

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.InProgress then
        SendWebhook(
            "🔌 Disconnect / Teleport Detected",
            "Player diteleport atau disconnected dari server!",
            15158332,
            {{ name = "⚠️ Status", value = "Meninggalkan server...", inline = true }}
        )
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TicketEliteUI_v4"
ScreenGui.ResetOnSpawn = false

local guiParent = nil
if pcall(function() guiParent = game:GetService("CoreGui") end) and guiParent then
    ScreenGui.Parent = guiParent
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 330, 0, 365)
MainFrame.Position = UDim2.new(0.5, -165, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 200, 255)
Stroke.Thickness = 2
Stroke.Parent = MainFrame

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Text = "🎫 ELITE TICKET FARM v4 (CLEAN)"
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = TitleBar

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "StatsLabel"
StatsLabel.Text = "🎫 Tickets: 0 | 🗺️ Map: Intermission | 📶 0ms"
StatsLabel.Size = UDim2.new(1, -10, 0, 22)
StatsLabel.Position = UDim2.new(0, 5, 0, 42)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextSize = 11
StatsLabel.TextXAlignment = Enum.TextXAlignment.Center
StatsLabel.Parent = MainFrame

local ToggleIconButton = Instance.new("TextButton")
ToggleIconButton.Name = "MobileToggleIcon"
ToggleIconButton.Size = UDim2.new(0, 45, 0, 45)
ToggleIconButton.Position = UDim2.new(0, 15, 0.4, 0)
ToggleIconButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
ToggleIconButton.Text = "🎫"
ToggleIconButton.TextSize = 22
ToggleIconButton.Active = true
ToggleIconButton.Draggable = true
ToggleIconButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleIconButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 255, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleIconButton

ToggleIconButton.MouseButton1Click:Connect(function()
    State.MenuOpen = not State.MenuOpen
    MainFrame.Visible = State.MenuOpen
end)

local CursorFixBtn = Instance.new("TextButton")
CursorFixBtn.BackgroundTransparency = 1
CursorFixBtn.Modal = true
CursorFixBtn.Text = ""
CursorFixBtn.Size = UDim2.new(0, 0, 0, 0)
CursorFixBtn.Parent = MainFrame

local function CreateButton(name, text, yPos, defaultOn, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.9, 0, 0, 36)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Text = text .. (defaultOn and ": ON" or ": OFF")
    btn.TextColor3 = defaultOn and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(255, 80, 80)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = MainFrame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = defaultOn and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 60, 60)
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local newState = callback()
        if newState then
            btn.TextColor3 = Color3.fromRGB(0, 255, 130)
            btn.Text = text .. ": ON"
            stroke.Color = Color3.fromRGB(0, 200, 100)
        else
            btn.TextColor3 = Color3.fromRGB(255, 80, 80)
            btn.Text = text .. ": OFF"
            stroke.Color = Color3.fromRGB(200, 60, 60)
        end
    end)
    return btn
end

local BtnESP = CreateButton("BtnESP", "🔴 Ticket ESP", 68, true, function()
    State.ESP = not State.ESP
    if not State.ESP then
        for _, d in pairs(ESP_Table) do
            if d.Highlight then d.Highlight.Enabled = false end
            if d.Billboard then d.Billboard.Enabled = false end
        end
    else
        for _, d in pairs(ESP_Table) do
            if d.Highlight then d.Highlight.Enabled = true end
            if d.Billboard then d.Billboard.Enabled = true end
        end
    end
    return State.ESP
end)

local BtnFarm = CreateButton("BtnFarm", "🎫 Auto Collect", 112, false, function()
    State.AutoFarm = not State.AutoFarm
    if State.AutoFarm then
        CreateSafePlatform()
    end
    return State.AutoFarm
end)

local BtnAFK = CreateButton("BtnAFK", "🚫 Anti-AFK", 156, false, function()
    State.AntiAFK = not State.AntiAFK
    ToggleAntiAFK(State.AntiAFK)
    return State.AntiAFK
end)

local BtnRespawn = CreateButton("BtnRespawn", "💀 Auto Respawn", 200, false, function()
    State.AutoRespawn = not State.AutoRespawn
    ToggleAutoRespawn(State.AutoRespawn)
    return State.AutoRespawn
end)

local BtnPlushie = Instance.new("TextButton")
BtnPlushie.Name = "BtnPlushie"
BtnPlushie.Size = UDim2.new(0.9, 0, 0, 38)
BtnPlushie.Position = UDim2.new(0.05, 0, 0, 244)
BtnPlushie.BackgroundColor3 = Color3.fromRGB(45, 0, 80)
BtnPlushie.Text = "🪆 VIP PlushieHell: OFF"
BtnPlushie.TextColor3 = Color3.fromRGB(180, 80, 255)
BtnPlushie.Font = Enum.Font.GothamBold
BtnPlushie.TextSize = 13
BtnPlushie.Parent = MainFrame

local PlushieCorner = Instance.new("UICorner")
PlushieCorner.CornerRadius = UDim.new(0, 6)
PlushieCorner.Parent = BtnPlushie

local PlushieStroke = Instance.new("UIStroke")
PlushieStroke.Color = Color3.fromRGB(150, 0, 255)
PlushieStroke.Thickness = 1.5
PlushieStroke.Parent = BtnPlushie

BtnPlushie.MouseButton1Click:Connect(function()
    State.AutoPlushieHell = not State.AutoPlushieHell
    if State.AutoPlushieHell then
        BtnPlushie.Text = "🪆 VIP PlushieHell: ON"
        BtnPlushie.TextColor3 = Color3.fromRGB(220, 130, 255)
        BtnPlushie.BackgroundColor3 = Color3.fromRGB(70, 0, 120)
        PlushieStroke.Color = Color3.fromRGB(200, 100, 255)
        StartAutoPlushieHell()
        if State.AutoFarm then
            task.spawn(TriggerPlushieHell)
        end
    else
        BtnPlushie.Text = "🪆 VIP PlushieHell: OFF"
        BtnPlushie.TextColor3 = Color3.fromRGB(180, 80, 255)
        BtnPlushie.BackgroundColor3 = Color3.fromRGB(45, 0, 80)
        PlushieStroke.Color = Color3.fromRGB(150, 0, 255)
        StopAutoPlushieHell()
    end
end)

local Credits = Instance.new("TextLabel")
Credits.Text = "R-SHIFT / Tap Icon: Toggle Menu | v4 Clean"
Credits.Size = UDim2.new(1, 0, 0, 18)
Credits.Position = UDim2.new(0, 0, 1, -22)
Credits.BackgroundTransparency = 1
Credits.TextColor3 = Color3.fromRGB(80, 80, 80)
Credits.Font = Enum.Font.Gotham
Credits.TextSize = 9
Credits.TextXAlignment = Enum.TextXAlignment.Center
Credits.Parent = MainFrame

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightControl and State.AutoPlushieHell then
        task.spawn(TriggerPlushieHell)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightShift then
        State.MenuOpen = not State.MenuOpen
        MainFrame.Visible = State.MenuOpen
    end
end)

local function removeESP(obj)
    if ESP_Table[obj] then
        if ESP_Table[obj].Highlight then ESP_Table[obj].Highlight:Destroy() end
        if ESP_Table[obj].Billboard then ESP_Table[obj].Billboard:Destroy() end
        ESP_Table[obj] = nil
    end
end

local function createESP(obj)
    if ESP_Table[obj] then return end
    local h = Instance.new("Highlight")
    h.FillColor = Color3.fromRGB(0, 200, 255)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.Enabled = State.ESP
    h.Parent = obj

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 70, 0, 20)
    bb.AlwaysOnTop = true
    bb.Enabled = State.ESP
    bb.Parent = obj
    bb.StudsOffset = Vector3.new(0, 3, 0)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = "🎫 TICKET"
    t.TextColor3 = Color3.fromRGB(0, 230, 255)
    t.TextScaled = true
    t.Font = Enum.Font.GothamBold
    t.Parent = bb

    ESP_Table[obj] = { Highlight = h, Billboard = bb, Part = obj }
    obj.AncestryChanged:Connect(function(_, p)
        if not p then removeESP(obj) end
    end)
end

task.spawn(function()
    while true do
        local tFolder = GetTicketsFolder()
        if tFolder then
            for _, v in ipairs(tFolder:GetDescendants()) do
                if v:IsA("BasePart") then createESP(v) end
            end
            tFolder.DescendantAdded:Connect(function(v)
                if v:IsA("BasePart") then createESP(v) end
            end)
            break
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local ping = GetPing()
        local currentMap = GetMapName()
        State.CurrentMap = currentMap
        StatsLabel.Text = string.format("🎫 Tickets: %d | 🗺️ %s | 📶 %dms", TicketsFarmed, State.CurrentMap, ping)
    end
end)

task.spawn(function()
    task.spawn(function()
        while not CurrencyChannel do task.wait(0.5) end
        CurrencyChannel.OnClientEvent:Connect(function()
            TicketsFarmed += 1
            RoundTicketsFarmed += 1
        end)
    end)

    while true do
        task.wait(0.3)
        if not State.AutoFarm then continue end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            task.wait(1)
            continue
        end

        local hrp = char.HumanoidRootPart
        local tFolder = GetTicketsFolder()

        local targetTicket = nil
        local closestDist = math.huge
        if tFolder then
            for _, v in ipairs(tFolder:GetDescendants()) do
                if v:IsA("BasePart") and v.Parent then
                    local dist = (hrp.Position - v.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        targetTicket = v
                    end
                end
            end
        end

        if not targetTicket then
            if State.SafePlatform and (hrp.Position - State.SafeZonePos).Magnitude > 50 then
                hrp.CFrame = CFrame.new(State.SafeZonePos + Vector3.new(0, 3, 0))
            end
            if State.AutoPlushieHell and not State.PlushieHellBusy then
                task.spawn(TriggerPlushieHell)
            end
            task.wait(1)
            continue
        end

        local ticketPickedUp = false
        local conn = targetTicket.AncestryChanged:Connect(function(_, newParent)
            if newParent == nil then
                ticketPickedUp = true
            end
        end)

        local timeoutCounter = 0
        repeat
            if not targetTicket.Parent then break end
            hrp.CFrame = CFrame.new(targetTicket.Position + Vector3.new(0, 2, 0))
            task.wait(0.08)
            timeoutCounter += 0.08
        until ticketPickedUp or timeoutCounter >= 4 or not targetTicket.Parent

        conn:Disconnect()

        if ticketPickedUp or not targetTicket.Parent then
            TicketsFarmed += 1
            RoundTicketsFarmed += 1
            task.wait(0.1)
            if State.SafePlatform then
                hrp.CFrame = CFrame.new(State.SafeZonePos + Vector3.new(0, 3, 0))
            end
            task.wait(0.3)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    task.wait(2)
    SendWebhook(
        "🚀 Elite Ticket Farm v4 Launched!",
        string.format("Script berhasil dijalankan oleh **%s** di game Evade!", LocalPlayer.Name),
        5763719,
        {
            { name = "🎮 Game", value = "Evade [🌊 ]", inline = true },
            { name = "📋 Version", value = "v4 Clean | Delta Ready", inline = true },
            { name = "📶 Ping", value = string.format("%d ms", GetPing()), inline = true },
            { name = "⚙️ Fitur", value = "ESP, AutoFarm, AutoRespawn, AntiAFK, MapDetect, Webhook", inline = false }
        }
    )
    SetupMapDetection()
end)

print("✅ ELITE TICKET FARM v4 (CLEAN): Loaded")
