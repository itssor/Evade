--[[
    EVADE.GG - BEDWARS BOOTSTRAPPER (Voidware Logic)
    Features: Signature Scanning, AC Bypass, Knit Hook
]]

local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera

-- // 1. THE BOOTSTRAPPER (Memory Scanner)
local Bedwars = {
    Knit = nil,
    Client = {},
    Controllers = {}
}

local function Status(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Evade Bootstrapper", Text = msg, Duration = 2})
end

Status("Hooking Knit Framework...")

-- A. WaitForGame
repeat task.wait() until game:IsLoaded()
repeat task.wait() until LocalPlayer.PlayerScripts
local TS = LocalPlayer.PlayerScripts:WaitForChild("TS", 10)
if not TS then error("TS Not Found") end

-- B. Extract Knit (Voidware Method)
local KnitScript = TS:WaitForChild("knit", 10)
local KnitPkg = require(KnitScript)
if not KnitPkg then error("Knit Failed") end

-- C. Recursive Upvalue Scan (The "Steal")
-- We scan the setup function's upvalues to find the main registry table
local function ScanForKnit(Func)
    for i = 1, 20 do
        local val = debug.getupvalue(Func, i)
        if type(val) == "table" and val.Controllers and val.Services then
            return val
        end
    end
    return nil
end

Bedwars.Knit = ScanForKnit(KnitPkg.setup)
if not Bedwars.Knit then error("Knit Table Not Found") end

Status("Scanning Controllers...")

-- D. Signature Mapping (The "Update Proofing")
-- We map internal names to our names based on what functions they contain
local ControllerSignatures = {
    ["SwordController"] = "swingSwordAtMouse",
    ["BlockController"] = "placeBlock",
    ["KnockbackTable"] = "registerKnockback",
    ["SprintController"] = "startSprinting",
    ["ViewmodelController"] = "playAnimation",
    ["AppController"] = "isAppOpen"
}

for Name, Controller in pairs(Bedwars.Knit.Controllers) do
    for MyName, FuncName in pairs(ControllerSignatures) do
        if rawget(Controller, FuncName) then
            Bedwars.Controllers[MyName] = Controller
            print("[Evade] Hooked: " .. MyName)
        end
    end
    
    -- E. Anticheat Bypass (Raven/AC Disable)
    if Name:find("AntiCheat") or Name:find("Raven") then
        if rawget(Controller, "disable") then Controller:disable() end
        if rawget(Controller, "stop") then Controller:stop() end
        print("[Evade] Disabled AC: " .. Name)
    end
end

-- // 2. UI CONSTRUCTION
local Window = Library:CreateWindow({
    Title = "Evade | Bedwars (Voidware)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Game = Window:AddTab("Bedwars"),
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

-- // 3. FEATURES (Using Hooked Controllers)

-- COMBAT
local CombatGroup = Tabs.Combat:AddLeftGroupbox("Kill Aura")
CombatGroup:AddToggle("Killaura", { Text = "Kill Aura", Default = false })
CombatGroup:AddSlider("KillauraRange", { Text = "Range", Default = 18, Min = 1, Max = 22, Rounding = 1 })
CombatGroup:AddToggle("KillauraAnim", { Text = "Swing Animation", Default = true })

local VelGroup = Tabs.Combat:AddRightGroupbox("Velocity")
VelGroup:AddToggle("Velocity", { Text = "Anti-Knockback", Default = false })
VelGroup:AddSlider("VelH", { Text = "Horizontal", Default = 0, Min = 0, Max = 100 })
VelGroup:AddSlider("VelV", { Text = "Vertical", Default = 0, Min = 0, Max = 100 })

-- MOVEMENT
local FlyGroup = Tabs.Movement:AddLeftGroupbox("Flight")
FlyGroup:AddToggle("Flight", { Text = "Flight", Default = false }):AddKeyPicker("FlyKey", { Default = "F", Mode = "Toggle" })
FlyGroup:AddSlider("FlySpeed", { Text = "Speed", Default = 40, Min = 10, Max = 80 })

local MoveGroup = Tabs.Movement:AddRightGroupbox("Mods")
MoveGroup:AddToggle("Sprint", { Text = "Omni-Sprint", Default = true })
MoveGroup:AddToggle("Speed", { Text = "Speed", Default = false })
MoveGroup:AddSlider("SpeedVal", { Text = "Factor", Default = 23, Min = 16, Max = 35 })
MoveGroup:AddToggle("Spider", { Text = "Spider", Default = false })
MoveGroup:AddToggle("NoFall", { Text = "No Fall", Default = true })

-- WORLD
local WorldGroup = Tabs.Game:AddLeftGroupbox("World")
WorldGroup:AddToggle("BedNuker", { Text = "Bed Nuker", Default = false })
WorldGroup:AddSlider("NukeRange", { Text = "Range", Default = 30, Min = 10, Max = 30 })
WorldGroup:AddToggle("ChestSteal", { Text = "Chest Stealer", Default = false })

local BuildGroup = Tabs.Game:AddRightGroupbox("Building")
BuildGroup:AddToggle("Scaffold", { Text = "Scaffold", Default = false })

-- VISUALS
local VisGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
VisGroup:AddToggle("BedESP", { Text = "Bed ESP", Default = true })
VisGroup:AddToggle("PlayerESP", { Text = "Player ESP", Default = true })

-- // 4. LOGIC ENGINE

-- Helpers
local function GetTarget(Dist)
    local T, D = nil, Dist
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChild("Humanoid")
            if r and h and h.Health > 0 then
                local mag = (r.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if mag < D then D = mag; T = p.Character end
            end
        end
    end
    return T
end

-- Main Loop
task.spawn(function()
    while true do
        if not LocalPlayer.Character then task.wait(); continue end
        local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        -- Killaura (Controller Method)
        if Library.Toggles.Killaura.Value and HRP then
            local Target = GetTarget(Library.Options.AuraRange.Value)
            if Target then
                -- Rotation
                HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(Target.HumanoidRootPart.Position.X, HRP.Position.Y, Target.HumanoidRootPart.Position.Z))
                
                -- Attack
                local Sword = Bedwars.Controllers.SwordController
                if Sword then
                    if Library.Toggles.AuraAnim.Value then Sword:swingSwordAtMouse() end
                    
                    -- Voidware Args
                    local args = {
                        ["chargedAttack"] = {["chargeRatio"] = 0},
                        ["entityInstance"] = Target,
                        ["validate"] = {
                            ["targetPosition"] = {["value"] = Target.HumanoidRootPart.Position},
                            ["selfPosition"] = {["value"] = HRP.Position}
                        }
                    }
                    -- Fire Remote Manually if Controller methods are hidden
                    -- (Most controllers store the remote in 'SwordHit' or similar)
                    Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.SwordHit:FireServer(args)
                end
            end
        end
        
        -- Bed Nuker
        if Library.Toggles.BedNuker.Value and HRP then
            local Beds = Services.CollectionService:GetTagged("bed")
            for _, B in pairs(Beds) do
                if B and B:FindFirstChild("Covers") and B.Covers.BrickColor ~= LocalPlayer.Team.TeamColor then
                    if (B.Position - HRP.Position).Magnitude < Library.Options.NukeRange.Value then
                        local A = {
                            ["blockRef"] = {["blockPosition"] = Vector3.new(math.round(B.Position.X/3), math.round(B.Position.Y/3), math.round(B.Position.Z/3))},
                            ["hitPosition"] = B.Position, ["hitNormal"] = Vector3.new(0,1,0)
                        }
                        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.DamageBlock:InvokeServer(A)
                    end
                end
            end
        end
        
        task.wait(0.1)
    end
end)

-- Physics Loop
Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    -- Scaffold (Block Placer)
    if Library.Toggles.Scaffold.Value and HRP and Bedwars.Controllers.BlockController then
        -- Simple block check logic
        local BlockType = "wool_white" -- Simplified; needs inventory check
        local Pos = HRP.Position + Vector3.new(0, -3.5, 0) + (HRP.Velocity * 0.2)
        local BPos = Vector3.new(math.round(Pos.X/3), math.round(Pos.Y/3), math.round(Pos.Z/3))
        
        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.PlaceBlock:InvokeServer({
            ["blockType"] = BlockType, ["blockData"] = 0, ["position"] = BPos
        })
    end
    
    -- Flight
    if Library.Toggles.Flight.Value and Library.Options.FlyKey:GetState() and HRP then
        local LV = HRP:FindFirstChild("VoidFly") or Instance.new("LinearVelocity", HRP); LV.Name = "VoidFly"
        LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
        local Att = HRP:FindFirstChild("VoidAtt") or Instance.new("Attachment", HRP); Att.Name = "VoidAtt"; LV.Attachment0 = Att
        
        local Dir = Vector3.zero
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end
        
        LV.VectorVelocity = Dir * Library.Options.FlySpeed.Value
        if HRP.Position.Y < -10 then HRP.Velocity = Vector3.new(0, 50, 0) end -- Void save
    else
        if HRP:FindFirstChild("VoidFly") then HRP.VoidFly:Destroy() end
    end
    
    -- Velocity
    if Library.Toggles.Velocity.Value and HRP then
        if HRP.Velocity.Magnitude > 20 or HRP.Velocity.Y > 10 then
             HRP.Velocity = Vector3.new(HRP.Velocity.X * (Library.Options.VelH.Value/100), HRP.Velocity.Y * (Library.Options.VelV.Value/100), HRP.Velocity.Z * (Library.Options.VelH.Value/100))
        end
    end
    
    -- Speed
    if Library.Toggles.Speed.Value and Hum then
        Hum.WalkSpeed = Library.Options.SpeedVal.Value
        if Bedwars.Controllers.SprintController then Bedwars.Controllers.SprintController:startSprinting() end
    end
    
    -- No Fall
    if Library.Toggles.NoFall.Value then
        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.GroundHit:FireServer()
    end
end)

-- ESP Loop
local Drawings = {}
Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}
    
    if Library.Toggles.BedESP.Value then
        for _, Bed in pairs(Services.CollectionService:GetTagged("bed")) do
            if Bed and Bed:FindFirstChild("Covers") then
                local Pos, Vis = Camera:WorldToViewportPoint(Bed.Position)
                if Vis then
                    local B = Drawing.new("Square"); B.Visible=true; B.Size=Vector2.new(30,30); B.Position=Vector2.new(Pos.X-15,Pos.Y-15)
                    B.Color = Bed.Covers.BrickColor.Color; B.Thickness=2; B.Filled=false; table.insert(Drawings, B)
                end
            end
        end
    end
    
    if Library.Toggles.PlayerESP.Value then
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local Pos, Vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if Vis then
                    local B = Drawing.new("Square"); B.Visible=true; B.Size=Vector2.new(2000/Pos.Z, 3000/Pos.Z); B.Position=Vector2.new(Pos.X-B.Size.X/2,Pos.Y-B.Size.Y/2)
                    B.Color = p.TeamColor.Color; B.Thickness=1; B.Filled=false; table.insert(Drawings, B)
                end
            end
        end
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
Evade.SaveManager:SetFolder("Evade/Bedwars")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Status("Loaded.")
