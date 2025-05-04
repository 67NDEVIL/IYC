--// Mobile Aimbot IYCHUB
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Aimbot Settings
getgenv().MobileAimbot = {
    Active = false, -- Starts OFF (toggle to enable)
    TeamCheck = false,
    AliveCheck = true,
    Sensitivity = 0.7, -- Stickiness (0.1 = loose, 1 = instant lock)
    LockPart = "Head",
    FOV = {
        Enabled = true,
        Amount = 90, -- Default FOV size
        Color = Color3.fromRGB(255, 255, 255),
        LockedColor = Color3.fromRGB(255, 70, 70), -- Red when locked
        Thickness = 1,
        Transparency = 1, -- Set transparency to 1 (fully visible)
        Filled = false, -- Set filled to false to make it an outline
        Min = 50,  -- Minimum FOV size
        Max = 200  -- Maximum FOV size
    }
}

local MA = getgenv().MobileAimbot
local LockedTarget = nil
local FOVCircle = Drawing.new("Circle")
FOVCircle.Transparency = MA.FOV.Transparency
FOVCircle.Filled = MA.FOV.Filled
FOVCircle.Thickness = MA.FOV.Thickness
FOVCircle.Color = MA.FOV.Color
FOVCircle.Visible = false

--// Mobile UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileAimbotUI"
ScreenGui.Parent = game.CoreGui

-- Toggle Button (Top-Right)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 100, 0, 40)
ToggleButton.Position = UDim2.new(1, -110, 0, 10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "🔴 AIM: OFF"
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 14
ToggleButton.Parent = ScreenGui

-- FOV Changer (Top-Center, Draggable)
local FOVFrame = Instance.new("Frame")
FOVFrame.Size = UDim2.new(0, 200, 0, 30)
FOVFrame.Position = UDim2.new(0.5, -100, 0, 60)
FOVFrame.BackgroundTransparency = 0.7
FOVFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FOVFrame.Active = true
FOVFrame.Selectable = true
FOVFrame.Parent = ScreenGui

local FOVSlider = Instance.new("Frame")
FOVSlider.Size = UDim2.new(0, 180, 0, 20)
FOVSlider.Position = UDim2.new(0.5, -90, 0.5, -10)
FOVSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
FOVSlider.Parent = FOVFrame

local FOVText = Instance.new("TextLabel")
FOVText.Size = UDim2.new(1, 0, 1, 0)
FOVText.BackgroundTransparency = 1
FOVText.Text = "FOV: " .. MA.FOV.Amount
FOVText.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVText.Font = Enum.Font.SourceSans
FOVText.TextSize = 14
FOVText.Parent = FOVFrame

--// Draggable FOV Slider
local draggingFOV = false
local sliderStartPos = 0

FOVSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingFOV = true
        sliderStartPos = input.Position.X
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingFOV = false
    end
end)

RunService.Heartbeat:Connect(function()
    if draggingFOV then
        local touchPos = UserInputService:GetMouseLocation()
        local delta = touchPos.X - sliderStartPos
        local percent = math.clamp(delta / FOVSlider.AbsoluteSize.X, 0, 1)
        
        MA.FOV.Amount = math.floor(MA.FOV.Min + (percent * (MA.FOV.Max - MA.FOV.Min)))
        FOVText.Text = "FOV: " .. MA.FOV.Amount
    end
end)

--// Update Toggle Appearance
local function UpdateToggle()
    if MA.Active then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70) -- Red
        ToggleButton.Text = "🔴 AIM: ON"
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Gray
        ToggleButton.Text = "⚪ AIM: OFF"
    end
end

--// PC-Like Sticky Aimbot
local function GetClosestPlayer()
    if not MA.Active then return end
    
    local closestPlayer = nil
    local closestDistance = MA.FOV.Amount
    local myTeam = LocalPlayer.Team
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local lockPart = player.Character:FindFirstChild(MA.LockPart)
            
            if humanoid and humanoid.Health > 0 and lockPart then
                if MA.TeamCheck and player.Team == myTeam then continue end
                
                local vector, onScreen = Camera:WorldToViewportPoint(lockPart.Position)
                if onScreen then
                    local screenPos = Vector2.new(vector.X, vector.Y)
                    local distance = (mousePos - screenPos).Magnitude
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    LockedTarget = closestPlayer
end

--// Smooth Lock-On (Identical to PC)
local function StickToTarget()
    if not (MA.Active and LockedTarget and LockedTarget.Character) then return end
    
    local lockPart = LockedTarget.Character:FindFirstChild(MA.LockPart)
    if not lockPart then return end
    
    -- PC-like sticky aiming
    Camera.CFrame = Camera.CFrame:Lerp(
        CFrame.new(Camera.CFrame.Position, lockPart.Position),
        MA.Sensitivity
    )
end

--// Main Loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if MA.FOV.Enabled then
        local touchPos = UserInputService:GetMouseLocation()
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(touchPos.X, touchPos.Y + 36)
        FOVCircle.Radius = MA.FOV.Amount
        FOVCircle.Color = LockedTarget and MA.FOV.LockedColor or MA.FOV.Color
    else
        FOVCircle.Visible = false
    end

    -- Aimbot Logic
    GetClosestPlayer()
    StickToTarget()
end)

--// Toggle Button
ToggleButton.MouseButton1Click:Connect(function()
    MA.Active = not MA.Active
    UpdateToggle()
    if not MA.Active then
        LockedTarget = nil
    end
end)

--// Initial Setup
UpdateToggle()

--// Cleanup
if getgenv().MobileAimbotCleanup then
    getgenv().MobileAimbotCleanup()
end

getgenv().MobileAimbotCleanup = function()
    ScreenGui:Destroy()
    FOVCircle:Remove()
    getgenv().MobileAimbot = nil
end
