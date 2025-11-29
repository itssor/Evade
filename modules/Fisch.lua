repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = Services.ReplicatedStorage

local Window = Library:CreateWindow({
    Title = "Evade | Fisch",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Main = Window:AddTab("Main"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

-- // MAIN FEATURES
local FishGroup = Tabs.Main:AddLeftGroupbox("Fishing")
FishGroup:AddToggle("AutoCast", { Text = "Auto Cast", Default = false })
FishGroup:AddToggle("AutoShake", { Text = "Auto Shake", Default = false })
FishGroup:AddToggle("AutoReel", { Text = "Auto Reel", Default = false })

local FarmGroup = Tabs.Main:AddRightGroupbox("Farming")
FarmGroup:AddToggle("InfiniteOxygen", { Text = "Infinite Oxygen", Default = true })
FarmGroup:AddToggle("FreezePlayer", { Text = "Freeze Character", Default = false })

-- // VISUALS (Zone Only)
local VisGroup = Tabs.Visuals:AddLeftGroupbox("Navigation")
VisGroup:AddToggle("WhirlpoolESP", { Text = "Whirlpool ESP", Default = true })
VisGroup:AddToggle("ZoneESP", { Text = "Fishing Zones", Default = false })
VisGroup:AddToggle("CrateESP", { Text = "Crate/Loot ESP", Default = false })

-- // MOVEMENT (The Heavy Engine)
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
MiscMove:AddToggle("WalkOnWater", { Text = "Walk On Water", Default = false })

-- // LOGIC: AUTO FISHING
task.spawn(function()
    while true do
        if LocalPlayer.Character then
            local Rod = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            
            -- Auto Cast
            if Library.Toggles.AutoCast.Value and Rod and Rod:FindFirstChild("events") then
                local Bobber = LocalPlayer.Character:FindFirstChild("bobber")
                if not Bobber then
                    local CastRemote = Rod.events:FindFirstChild("cast")
                    if CastRemote then CastRemote:FireServer(100, 1) end
                end
            end
            
            -- Auto Shake
            if Library.Toggles.AutoShake.Value then
                local ShakeUI = LocalPlayer.PlayerGui:FindFirstChild("shakeui")
                if ShakeUI and ShakeUI.Enabled then
                    local SafeZone = ShakeUI:FindFirstChild("safezone")
                    if SafeZone then
                        local Button = SafeZone:FindFirstChild("button")
                        if Button and Button.Visible then
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        end
                    end
                end
            end
            
            -- Auto Reel
            if Library.Toggles.AutoReel.Value then
                local ReelUI = LocalPlayer.PlayerGui:FindFirstChild("reel")
                if ReelUI and ReelUI.Enabled then
                    local Events = ReplicatedStorage:FindFirstChild("events")
                    if Events and Events:FindFirstChild("reelfinished") then
                         Events.reelfinished:FireServer(100, true)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- // LOGIC: PHYSICS LOOP
Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    -- Infinite Oxygen
    if Library.Toggles.InfiniteOxygen.Value and LocalPlayer.Character then
        local Oxygen = LocalPlayer.Character:FindFirstChild("client") and LocalPlayer.Character.client:FindFirstChild("oxygen")
        if Oxygen then Oxygen.Value = 100 end
    end

    -- Freeze
    if Library.Toggles.FreezePlayer.Value and HRP then
        HRP.Anchored = true
    elseif HRP and not Library.Toggles.FlightEnabled.Value then 
        HRP.Anchored = false
    end
    
    -- Walk On Water
    if Library.Toggles.WalkOnWater.Value and HRP then
        if HRP.Position.Y < 135 then -- Approx Sea Level
             HRP.Velocity = Vector3.new(HRP.Velocity.X, 0, HRP.Velocity.Z)
             HRP.CFrame = CFrame.new(HRP.Position.X, 135, HRP.Position.Z)
        end
    end

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

-- // RENDER LOOP (Zone ESP)
local Drawings = {}
Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}
    
    local function Draw(Obj, Text, Color)
        local Pos, Vis = Camera:WorldToViewportPoint(Obj.Position)
        if Vis then
            local T = Drawing.new("Text")
            T.Visible = true
            T.Text = Text
            T.Center = true
            T.Outline = true
            T.Color = Color
            T.Size = 14
            T.Position = Vector2.new(Pos.X, Pos.Y)
            table.insert(Drawings, T)
        end
    end

    -- Whirlpools
    if Library.Toggles.WhirlpoolESP.Value then
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "Whirlpool" and v:IsA("Model") and v.PrimaryPart then
                Draw(v.PrimaryPart, "Whirlpool", Color3.fromRGB(0, 100, 255))
            end
        end
    end

    -- Zones (Fishing Areas)
    if Library.Toggles.ZoneESP.Value then
        local Zones = workspace:FindFirstChild("zones")
        if Zones then
            for _, v in pairs(Zones:GetChildren()) do
                if v:IsA("BasePart") or v:IsA("Model") then
                    local Target = v:IsA("Model") and v.PrimaryPart or v
                    if Target then
                        Draw(Target, v.Name, Color3.fromRGB(0, 255, 100))
                    end
                end
            end
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
Evade.SaveManager:SetFolder("Evade/Fisch")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Fisch Loaded", 5)
