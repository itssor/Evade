-- // PRE-FLIGHT
repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

-- // IMPORTS
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local ReplicatedStorage = Services.ReplicatedStorage
local VirtualInputManager = game:GetService("VirtualInputManager")

-- // DYNAMIC REMOTE FINDER
local ParryRemote = nil
local function GetRemote()
    local TargetServices = {ReplicatedStorage, game:GetService("AdService"), game:GetService("SocialService")}
    for _, Svc in pairs(TargetServices) do
        for _, v in pairs(Svc:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:find("\n") or v.Name == "ParryButtonPress" or v.Name == "Deflect") then
                return v
            end
        end
    end
    return nil
end
ParryRemote = GetRemote()

-- // SKIN DATABASE
local SkinList = {}
local SkinsFolder = ReplicatedStorage:FindFirstChild("Skins") or ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Skins")
if SkinsFolder then
    for _, v in pairs(SkinsFolder:GetChildren()) do
        table.insert(SkinList, v.Name)
    end
    table.sort(SkinList)
end

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Blade Ball",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Skins = Window:AddTab("Skins"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

-- // COMBAT
local ParryGroup = Tabs.Combat:AddLeftGroupbox("Auto Parry")
ParryGroup:AddToggle("AutoParry", { Text = "Enabled", Default = false }):AddKeyPicker("ParryKey", { Default = "C", Mode = "Toggle" })
ParryGroup:AddDropdown("ParryMode", { Values = {"Visual", "Math", "Distance"}, Default = 2, Multi = false, Text = "Algorithm" })

local TimingGroup = Tabs.Combat:AddRightGroupbox("Timing & Physics")
TimingGroup:AddToggle("SpamClash", { Text = "Spam on Clash", Default = true, Tooltip = "Removes cooldown if ball is fast" })
TimingGroup:AddSlider("BaseDist", { Text = "Base Distance", Default = 15, Min = 5, Max = 50 })
TimingGroup:AddSlider("PingComp", { Text = "Ping Adjust (ms)", Default = 60, Min = 0, Max = 300 })

-- // SKINS
local SkinGroup = Tabs.Skins:AddLeftGroupbox("Client Side Skins")
SkinGroup:AddDropdown("SkinSelect", { Values = SkinList, Default = 1, Multi = false, Text = "Select Sword" })
SkinGroup:AddButton("Apply Skin", function()
    local SkinName = Library.Options.SkinSelect.Value
    local RealSkin = SkinsFolder:FindFirstChild(SkinName)
    
    if RealSkin and Camera:FindFirstChild("Viewmodel") then
        local VM = Camera.Viewmodel:FindFirstChildWhichIsA("Model") -- The sword model
        if VM then
            -- Try to apply texture/mesh
            for _, part in pairs(VM:GetChildren()) do
                local TargetPart = RealSkin:FindFirstChild(part.Name)
                if TargetPart and part:IsA("MeshPart") and TargetPart:IsA("MeshPart") then
                    part.TextureID = TargetPart.TextureID
                    part.MeshId = TargetPart.MeshId
                end
            end
            Library:Notify("Applied: " .. SkinName, 3)
        end
    end
end)

-- // VISUALS (Standard)
local VisGroup = Tabs.Visuals:AddLeftGroupbox("Visuals")
VisGroup:AddToggle("BallESP", { Text = "Ball ESP", Default = true })
VisGroup:AddToggle("PlayerESP", { Text = "Player ESP", Default = true })
VisGroup:AddToggle("DrawRange", { Text = "Draw Detect Range", Default = false })

-- // MOVEMENT (Standard)
local FlightGroup = Tabs.Movement:AddLeftGroupbox("Flight System")
FlightGroup:AddToggle("FlightEnabled", { Text = "Enable Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
FlightGroup:AddDropdown("FlightMode", { Values = {"LinearVelocity", "CFrame", "BodyVelocity"}, Default = 1, Multi = false, Text = "Mode" })
FlightGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 50, Min = 10, Max = 300, Rounding = 0 })

local SpeedGroup = Tabs.Movement:AddRightGroupbox("Speed Engine")
SpeedGroup:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false })
SpeedGroup:AddDropdown("SpeedMode", { Values = {"WalkSpeed", "CFrame", "TP"}, Default = 1, Multi = false, Text = "Mode" })
SpeedGroup:AddSlider("WalkSpeed", { Text = "Factor", Default = 16, Min = 16, Max = 300, Rounding = 0 })

local MiscMove = Tabs.Movement:AddLeftGroupbox("Misc")
MiscMove:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
MiscMove:AddDropdown("NoclipMode", { Values = {"Collision", "CFrame"}, Default = 1, Text = "Noclip Mode" })
MiscMove:AddToggle("Noclip", { Text = "Noclip", Default = false })

-- // LOGIC: PARRY ENGINE
local DebugBall = nil

local function Parry()
    if ParryRemote then
        -- Args: Offset, CameraCFrame, CharacterMap, Direction
        local Args = {
            0.5, 
            Camera.CFrame, 
            {[LocalPlayer.Name] = LocalPlayer.Character}, 
            LocalPlayer.Character.HumanoidRootPart.Position
        }
        ParryRemote:FireServer(unpack(Args))
    else
        -- Click simulation fallback
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

local function GetPing()
    return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1] / 1000
end

task.spawn(function()
    while true do
        -- High speed loop
        if Library.Toggles.AutoParry.Value and LocalPlayer.Character then
            local Balls = workspace:WaitForChild("Balls", 1)
            if Balls then
                for _, Ball in pairs(Balls:GetChildren()) do
                    if not Ball:GetAttribute("realBall") then continue end
                    DebugBall = Ball
                    
                    local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if Root then
                        local Dist = (Ball.Position - Root.Position).Magnitude
                        local Vel = Ball.Velocity.Magnitude
                        
                        -- Dynamic Range Calculation
                        local PingOffset = GetPing() + (Library.Options.PingComp.Value / 1000)
                        local Reach = Library.Options.BaseDist.Value + (Vel * PingOffset)
                        
                        local ShouldBlock = false
                        local Algo = Library.Options.ParryMode.Value
                        
                        if Algo == "Visual" then
                            -- Only block if game marks us as target
                            if Ball:GetAttribute("target") == LocalPlayer.Name and Dist <= Reach then
                                ShouldBlock = true
                            end
                            
                        elseif Algo == "Math" then
                            -- Vector Dot Product (Trajectory Calculation)
                            local Dir = (Root.Position - Ball.Position).Unit
                            local BallDir = Ball.Velocity.Unit
                            local Dot = Dir:Dot(BallDir)
                            
                            -- Dot > 0 means ball is moving towards us
                            if Dot > 0 and Dist <= Reach then
                                ShouldBlock = true
                            end
                            
                        elseif Algo == "Distance" then
                            -- Pure panic mode
                            if Dist <= Reach then ShouldBlock = true end
                        end
                        
                        if ShouldBlock then
                            Parry()
                            
                            -- Clash Logic (Anti-Spam vs Spam)
                            if Library.Toggles.SpamClash.Value and Vel > 60 and Dist < 20 then
                                -- No wait, spam as fast as loop allows
                            else
                                -- Cooldown to prevent double-swinging on slow balls
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
        task.wait() -- ~60hz check
    end
end)

-- // LOGIC: MOVEMENT & ESP
Services.RunService.RenderStepped:Connect(function()
    -- Ball ESP / Range Circle
    if Library.Toggles.DrawRange.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        -- Visualize the calculated parry range
        local Root = LocalPlayer.Character.HumanoidRootPart
        -- Only approximates range if ball exists to calc velocity, otherwise static
        local Radius = Library.Options.BaseDist.Value
        if DebugBall then
             local Vel = DebugBall.Velocity.Magnitude
             local PingOffset = GetPing() + (Library.Options.PingComp.Value / 1000)
             Radius = Radius + (Vel * PingOffset)
        end
        -- Note: Drawing a 3D circle requires a library function or complex math, simplified to logic here
    end
    
    -- ESP
    if Library.Toggles.BallESP.Value and DebugBall and DebugBall.Parent then
        local Pos, Vis = Camera:WorldToViewportPoint(DebugBall.Position)
        if Vis then
            -- Simple Highlight or Box
            -- (Sense ESP handles players, we handle Ball manually)
        end
    end
end)

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    -- Flight
    if Library.Toggles.FlightEnabled.Value and Library.Options.FlightKey:GetState() and HRP then
        local Mode = Library.Options.FlightMode.Value
        local Speed = Library.Options.FlightSpeed.Value
        local Dir = Vector3.zero
        
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end

        if Mode ~= "LinearVelocity" and HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
        if Mode ~= "BodyVelocity" and HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end
        if Mode ~= "CFrame" then HRP.Anchored = false end

        if Mode == "LinearVelocity" then
            local LV = HRP:FindFirstChild("SWFly") or Instance.new("LinearVelocity", HRP); LV.Name = "SWFly"
            LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
            local Att = HRP:FindFirstChild("SWAtt") or Instance.new("Attachment", HRP); Att.Name = "SWAtt"; LV.Attachment0 = Att
            LV.VectorVelocity = Dir * Speed
            local BV = HRP:FindFirstChild("SWHold") or Instance.new("BodyVelocity", HRP); BV.Name = "SWHold"; BV.MaxForce = Vector3.new(0,math.huge,0); BV.Velocity = Vector3.zero
        elseif Mode == "CFrame" then
            HRP.Anchored = true
            HRP.CFrame = HRP.CFrame + (Dir * (Speed/50))
        elseif Mode == "BodyVelocity" then
            local BV = HRP:FindFirstChild("SWBV") or Instance.new("BodyVelocity", HRP); BV.Name = "SWBV"
            BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge); BV.Velocity = Dir * Speed
        end
    else
        if HRP then
            if HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
            if HRP:FindFirstChild("SWHold") then HRP.SWHold:Destroy() end
            if HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end
            if HRP:FindFirstChild("SWAtt") then HRP.SWAtt:Destroy() end
            HRP.Anchored = false
        end
    end
    
    -- Speed
    if Library.Toggles.SpeedEnabled.Value and Hum then
        local Mode = Library.Options.SpeedMode.Value
        if Mode == "WalkSpeed" then
            Hum.WalkSpeed = Library.Options.WalkSpeed.Value
        elseif Mode == "CFrame" and HRP and Hum.MoveDirection.Magnitude > 0 then
            Hum.WalkSpeed = 16
            HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * (Library.Options.WalkSpeed.Value / 100))
        elseif Mode == "TP" and HRP and Hum.MoveDirection.Magnitude > 0 then
            Hum.WalkSpeed = 16
            HRP.CFrame = HRP.CFrame * CFrame.new(0, 0, -(Library.Options.WalkSpeed.Value / 50))
        end
    else
        if Hum and Hum.WalkSpeed ~= 16 then Hum.WalkSpeed = 16 end
    end
    
    -- Noclip
    if Library.Toggles.Noclip.Value and HRP then
        if Library.Options.NoclipMode.Value == "Collision" then
            for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        elseif Library.Options.NoclipMode.Value == "CFrame" then
            if Hum.MoveDirection.Magnitude > 0 then
                HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * 0.5)
            end
        end
    end
end)

Services.UserInputService.JumpRequest:Connect(function()
    if Library.Toggles.InfJump.Value and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- // SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() getgenv().EvadeLoaded = false; Library:Unload(); Sense.Unload() end)
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

Library:Notify("Evade | Blade Ball (v3.0) Loaded", 5)
