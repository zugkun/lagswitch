--// SERVICES
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

--// SETTINGS
local bounceKey = Enum.KeyCode.Q
local bouncePower = 90
local cooldown = 0.4
local canBounce = true

local flying = false
local flySpeed = 60

-- Freeze system
local freezeTime = 0.25 -- lama freeze fake lag

--------------------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 260)
frame.Position = UDim2.new(0.5, -130, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.BorderSizePixel = 0
frame.Visible = false

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = " Movement Menu"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)

-- Drag UI
local dragging = false
local dragPos

title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragPos = i.Position
    end
end)

title.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragPos
        frame.Position = UDim2.new(
            frame.Position.X.Scale, frame.Position.X.Offset + delta.X,
            frame.Position.Y.Scale, frame.Position.Y.Offset + delta.Y
        )
        dragPos = i.Position
    end
end)

--------------------------------------------------------------------------------------------
-- BOUNCE & KEYBIND UI
--------------------------------------------------------------------------------------------
local bounceLabel = Instance.new("TextLabel", frame)
bounceLabel.Position = UDim2.new(0, 10, 0, 40)
bounceLabel.Size = UDim2.new(1, -20, 0, 20)
bounceLabel.Text = "Bounce Hotkey:"
bounceLabel.BackgroundTransparency = 1
bounceLabel.TextColor3 = Color3.new(1,1,1)
bounceLabel.Font = Enum.Font.Gotham
bounceLabel.TextSize = 14

local setBounceKey = Instance.new("TextButton", frame)
setBounceKey.Position = UDim2.new(0, 10, 0, 65)
setBounceKey.Size = UDim2.new(1, -20, 0, 30)
setBounceKey.Text = "Q"
setBounceKey.BackgroundColor3 = Color3.fromRGB(60,60,60)
setBounceKey.TextColor3 = Color3.new(1,1,1)
setBounceKey.Font = Enum.Font.Gotham
setBounceKey.TextSize = 14

local waitingKey = false
setBounceKey.MouseButton1Click:Connect(function()
    waitingKey = true
    setBounceKey.Text = "Press key..."
end)

UIS.InputBegan:Connect(function(input)
    if waitingKey and input.KeyCode.Name ~= "Unknown" then
        bounceKey = input.KeyCode
        setBounceKey.Text = input.KeyCode.Name
        waitingKey = false
    end
end)

local powerBox = Instance.new("TextBox", frame)
powerBox.Position = UDim2.new(0, 10, 0, 105)
powerBox.Size = UDim2.new(1, -20, 0, 30)
powerBox.Text = tostring(bouncePower)
powerBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
powerBox.TextColor3 = Color3.new(1,1,1)
powerBox.Font = Enum.Font.Gotham
powerBox.TextSize = 14

powerBox.FocusLost:Connect(function()
    local val = tonumber(powerBox.Text)
    if val then bouncePower = val else powerBox.Text = bouncePower end
end)

--------------------------------------------------------------------------------------------
-- FLY UI
--------------------------------------------------------------------------------------------
local flyButton = Instance.new("TextButton", frame)
flyButton.Position = UDim2.new(0, 10, 0, 150)
flyButton.Size = UDim2.new(1, -20, 0, 30)
flyButton.Text = "Fly: OFF"
flyButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
flyButton.TextColor3 = Color3.new(1,1,1)
flyButton.Font = Enum.Font.Gotham
flyButton.TextSize = 14

flyButton.MouseButton1Click:Connect(function()
    flying = not flying
    flyButton.Text = flying and "Fly: ON" or "Fly: OFF"
    hrp.Anchored = flying
end)

local flySpeedBox = Instance.new("TextBox", frame)
flySpeedBox.Position = UDim2.new(0, 10, 0, 185)
flySpeedBox.Size = UDim2.new(1, -20, 0, 30)
flySpeedBox.Text = tostring(flySpeed)
flySpeedBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
flySpeedBox.TextColor3 = Color3.new(1,1,1)
flySpeedBox.Font = Enum.Font.Gotham
flySpeedBox.TextSize = 14

flySpeedBox.FocusLost:Connect(function()
    local s = tonumber(flySpeedBox.Text)
    if s then flySpeed = s else flySpeedBox.Text = flySpeed end
end)

--------------------------------------------------------------------------------------------
-- UNLOAD GUI BUTTON
--------------------------------------------------------------------------------------------
local unload = Instance.new("TextButton", frame)
unload.Position = UDim2.new(0, 10, 0, 225)
unload.Size = UDim2.new(1, -20, 0, 30)
unload.Text = "Unload Menu"
unload.BackgroundColor3 = Color3.fromRGB(90,0,0)
unload.TextColor3 = Color3.new(1,1,1)
unload.Font = Enum.Font.GothamBold
unload.TextSize = 15

unload.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

--------------------------------------------------------------------------------------------
-- FAKE FREEZE (0 FPS)
--------------------------------------------------------------------------------------------
local function fakeFreeze()
    -- hard freeze
    local t = os.clock()
    while os.clock() - t < freezeTime do end
end

--------------------------------------------------------------------------------------------
-- MAIN INPUTS
--------------------------------------------------------------------------------------------
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.Delete then
        frame.Visible = not frame.Visible
    end

    if input.KeyCode == bounceKey and canBounce then
        canBounce = false
        
        -- freeze dulu
        fakeFreeze()

        -- lalu bounce
        local v = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(v.X, bouncePower, v.Z)

        task.delay(cooldown, function()
            canBounce = true
        end)
    end
end)

--------------------------------------------------------------------------------------------
-- MOVEMENT LOOP
--------------------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    if flying then
        local dir = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end

        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end

        hrp.CFrame = hrp.CFrame + dir * dt * flySpeed
    end
end)

--------------------------------------------------------------------------------------------
-- ANTI RESET (GUI tidak hilang saat respawn)
--------------------------------------------------------------------------------------------
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
end)
