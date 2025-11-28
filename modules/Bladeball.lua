local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local ReplicatedStorage = Services.ReplicatedStorage
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = Services.RunService

-- // 1. DYNAMIC REMOTE FINDER
-- Blade Ball obfuscates remote names with newlines or whitespace
local ParryRemote = nil

local function GetRemote()
    local TargetServices = {ReplicatedStorage, game:GetService("AdService"), game:GetService("SocialService")}
    for _, Svc in pairs(TargetServices) do
        for _, v in pairs(Svc:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                -- Check for suspicious names (newlines, spaces, or specific known names)
                if v.Name:find("\n") or v.Name == "ParryButtonPress" or v.Name == "Deflect" then
                    return v
                end
            end
        end
    end
    return nil
end
ParryRemote = GetRemote()

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Blade Ball (Pro)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

-- // COMBAT
local Parry = Tabs.Combat:AddLeftGroupbox("Auto Parry")
Parry:AddToggle("AutoParry", { Text = "Auto Parry", Default = false }):AddKeyPicker("ParryKey", { Default = "C", Mode = "Toggle" })
Parry:AddToggle("SpamParry", { Text = "Spam Mode (Clash)", Default = false })
Parry:AddSlider("BaseDist", { Text = "Base Distance", Default = 15, Min = 10, Max = 50 })
Parry:AddSlider("PingComp", { Text = "Ping Compensation", Default = 100, Min = 0, Max = 300, Suffix = "ms" })

-- // VISUALS
local Vis = Tabs.Visuals:AddLeftGroupbox("Visuals")
Vis:AddToggle("BallESP", { Text = "Ball ESP", Default = true })
Vis:AddToggle("TargetESP", { Text = "Target Highlight", Default = true })

-- // LOGIC FUNCTIONS
local function IsTargetingMe(Ball)
    -- Method 1: Attribute Check (Most reliable)
    local Target = Ball:GetAttribute("target")
    if Target and Target == LocalPlayer.Name then return true end
    
    -- Method 2: Visual Highlight Check
    -- When targeted, your character usually gets a specific Highlight instance
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Highlight") then
        return true 
    end

    return false
end

local function GetTime(Distance, Velocity)
    return Distance / Velocity
end

local function PerformParry()
    if ParryRemote then
        -- Remote Method (Fastest)
        -- Blade Ball args usually: Offset, CFrame, CharacterMap, Direction
        local Args = {
            0.5, 
            Camera.CFrame, 
            {[LocalPlayer.Name] = LocalPlayer.Character}, 
            LocalPlayer.Character.HumanoidRootPart.Position
        }
        ParryRemote:FireServer(unpack(Args))
    else
        -- Virtual Click Method (Fallback)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

-- // MAIN PHYSICS LOOP
local DebugBall = nil -- For ESP

task.spawn(function()
    while true do
        -- Ultra-Fast Loop for reaction time
        if Library.Toggles.AutoParry.Value and LocalPlayer.Character then
            local Balls = workspace:WaitForChild("Balls", 1)
            
            if Balls then
                for _, Ball in pairs(Balls:GetChildren()) do
                    if not Ball:GetAttribute("realBall") then continue end
                    DebugBall = Ball
                    
                    local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if Root then
                        -- 1. Physics Calculations
                        local Distance = (Ball.Position - Root.Position).Magnitude
                        local Velocity = Ball.Velocity.Magnitude
                        
                        -- 2. Curve Detection (Dot Product)
                        -- Vector to Player
                        local DirToPlayer = (Root.Position - Ball.Position).Unit
                        -- Vector of Ball Movement
                        local VelocityDir = Ball.Velocity.Unit
                        -- Dot > 0 means moving towards us. Dot < 0 means moving away.
                        local Dot = DirToPlayer:Dot(VelocityDir)
                        
                        if Dot > 0 then -- Only calculate if ball is coming AT us
                            
                            -- 3. Timing Math
                            -- Dynamic Range based on speed + Ping
                            local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
                            local PingVal = tonumber(Ping:match("%d+")) or 50
                            local PingOffset = (PingVal + Library.Options.PingComp.Value) / 1000
                            
                            -- If ball is super fast, we need more distance
                            local SpeedFactor = math.clamp(Velocity / 10, 1, 5)
                            local Reach = Library.Options.BaseDist.Value * SpeedFactor
                            
                            -- 4. Execution
                            -- Check if targeted OR if ball is extremely close (Panic Block)
                            if (IsTargetingMe(Ball) or Distance < 25) and Distance <= Reach then
                                PerformParry()
                                
                                -- Anti-Spam / Clash Logic
                                if Library.Toggles.SpamParry.Value then
                                    -- Spam mode: No cooldown
                                else
                                    -- Normal mode: Wait based on ball speed
                                    -- Fast ball = Short wait. Slow ball = Long wait.
                                    local Cooldown = math.clamp(Distance / Velocity, 0.1, 0.5)
                                    task.wait(Cooldown) 
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Run as fast as possible (Heartbeat wait is too slow for Blade Ball)
        task.wait() 
    end
end)

-- // VISUALS LOOP
local Drawings = {}
Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}
    
    if Library.Toggles.BallESP.Value and DebugBall and DebugBall.Parent then
        local Pos, OnScreen = Camera:WorldToViewportPoint(DebugBall.Position)
        if OnScreen then
            local Circle = Drawing.new("Circle")
            Circle.Visible = true
            Circle.Radius = 10
            Circle.Color = Color3.fromRGB(255, 0, 0)
            Circle.Thickness = 2
            Circle.Filled = false
            Circle.Position = Vector2.new(Pos.X, Pos.Y)
            table.insert(Drawings, Circle)
        end
    end
end)

-- // SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() getgenv().EvadeLoaded = false; Library:Unload(); end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/BladeBall")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Blade Ball (Pro) Loaded", 5)
