local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

-- // BEDWARS SPECIFIC SERVICES
local ReplicatedStorage = Services.ReplicatedStorage
local KnitClient = debug.getupvalue(require(LocalPlayer.PlayerScripts.TS.knit).setup, 6)
local ClientStore = require(LocalPlayer.PlayerScripts.TS.ui.store).ClientStore
local SwordController = KnitClient.Controllers.SwordController

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Bedwars",
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

-- // 1. COMBAT
local CombatGroup = Tabs.Combat:AddLeftGroupbox("Kill Aura")
CombatGroup:AddToggle("Killaura", { Text = "Kill Aura", Default = false })
CombatGroup:AddSlider("KillauraRange", { Text = "Range", Default = 18, Min = 1, Max = 25, Rounding = 1 })
CombatGroup:AddToggle("KillauraAnim", { Text = "Swing Animation", Default = true })

local ModsGroup = Tabs.Combat:AddRightGroupbox("Mods")
ModsGroup:AddToggle("Sprint", { Text = "Auto Sprint", Default = true })
ModsGroup:AddToggle("NoKnockback", { Text = "Velocity Modifier (Anti-KB)", Default = false })
ModsGroup:AddSlider("VelH", { Text = "Horizontal %", Default = 0, Min = 0, Max = 100, Rounding = 0 })
ModsGroup:AddSlider("VelV", { Text = "Vertical %", Default = 0, Min = 0, Max = 100, Rounding = 0 })

-- // 2. VISUALS (Bedwars Specific)
local BedGroup = Tabs.Visuals:AddLeftGroupbox("Game ESP")
BedGroup:AddToggle("BedESP", { Text = "Bed ESP", Default = true })
BedGroup:AddToggle("BedNuker", { Text = "Bed Nuker (Auto-Break)", Default = false })

-- // 3. MOVEMENT (Ported from Universal)
local MoveGroup = Tabs.Movement:AddLeftGroupbox("Flight")
MoveGroup:AddToggle("FlightEnabled", { Text = "Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
MoveGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 40, Min = 10, Max = 100, Rounding = 0 })

-- // LOGIC FUNCTIONS
local function GetNearestEntity(Range)
    local Nearest = nil
    local Dist = Range
    for _, Plr in pairs(Services.Players:GetPlayers()) do
        if Plr ~= LocalPlayer and Plr.Team ~= LocalPlayer.Team and Plr.Character then
            local Root = Plr.Character:FindFirstChild("HumanoidRootPart")
            local Hum = Plr.Character:FindFirstChild("Humanoid")
            if Root and Hum and Hum.Health > 0 then
                local Mag = (Root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Mag < Dist then
                    Dist = Mag
                    Nearest = Plr.Character
                end
            end
        end
    end
    return Nearest
end

local function Attack(Target)
    -- This uses the specific Bedwars controller to verify the hit logic
    -- bypassing basic checks
    if SwordController then
        -- Construct args safely
        pcall(function()
            SwordController:swingSwordAtMouse()
            local HitArgs = {
                ["chargedAttack"] = {["chargeRatio"] = 0},
                ["entityInstance"] = Target,
                ["validate"] = {
                    ["targetPosition"] = {
                        ["value"] = Target.HumanoidRootPart.Position
                    },
                    ["selfPosition"] = {
                        ["value"] = LocalPlayer.Character.HumanoidRootPart.Position
                    }
                }
            }
            -- Fire the remote directly if possible, or trigger via controller
            -- Using controller swing is safer for now
        end)
    end
end

-- // LOOPS
task.spawn(function()
    while true do
        if Library.Toggles.Killaura.Value and LocalPlayer.Character then
            local Target = GetNearestEntity(Library.Options.KillauraRange.Value)
            if Target then
                -- Face Target
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
                    LocalPlayer.Character.HumanoidRootPart.Position, 
                    Vector3.new(Target.HumanoidRootPart.Position.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, Target.HumanoidRootPart.Position.Z)
                )
                
                -- Swing
                if Library.Toggles.KillauraAnim.Value then
                    local Sword = LocalPlayer.Character:FindFirstChild("Sword") or LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                    if Sword then Sword:Activate() end
                end
                
                -- The "Logic" Hit
                Attack(Target)
            end
        end
        task.wait(0.1) -- 10 ticks/sec
    end
end)

-- Anti-Knockback Hook
local OldVelocity = nil
Services.RunService.Stepped:Connect(function()
    if Library.Toggles.Sprint.Value and LocalPlayer.Character then
        if LocalPlayer.Character.Humanoid.WalkSpeed < 23 then
            LocalPlayer.Character.Humanoid.WalkSpeed = 23
        end
    end
    
    if Library.Toggles.NoKnockback.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local HRP = LocalPlayer.Character.HumanoidRootPart
        if HRP.Velocity.Y > 10 or HRP.Velocity.Y < -50 or HRP.Velocity.Magnitude > 30 then
             -- Simple dampening
             HRP.Velocity = Vector3.new(
                 HRP.Velocity.X * (Library.Options.VelH.Value / 100),
                 HRP.Velocity.Y * (Library.Options.VelV.Value / 100),
                 HRP.Velocity.Z * (Library.Options.VelH.Value / 100)
             )
        end
    end
end)

-- Bed ESP
local BedDrawings = {}
Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(BedDrawings) do d:Remove() end
    BedDrawings = {}
    
    if Library.Toggles.BedESP.Value then
        -- Bedwars uses CollectionService for beds
        local Beds = game:GetService("CollectionService"):GetTagged("bed")
        for _, Bed in pairs(Beds) do
            -- Filter out your own team's bed logic here if needed
            -- Usually check Bed.Covers.BrickColor == LocalPlayer.TeamColor
            
            local Pos, OnScreen = Camera:WorldToViewportPoint(Bed.Position)
            if OnScreen then
                local Box = Drawing.new("Square")
                Box.Visible = true
                Box.Size = Vector2.new(30, 30)
                Box.Position = Vector2.new(Pos.X - 15, Pos.Y - 15)
                Box.Color = Bed.Color -- Matches team color
                Box.Thickness = 2
                Box.Filled = false
                table.insert(BedDrawings, Box)
                
                local Text = Drawing.new("Text")
                Text.Visible = true
                Text.Text = "BED"
                Text.Center = true
                Text.Outline = true
                Text.Color = Color3.new(1,1,1)
                Text.Position = Vector2.new(Pos.X, Pos.Y - 30)
                table.insert(BedDrawings, Text)
            end
        end
    end
end)

-- // SETTINGS & INIT
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

Library:Notify("Evade | Bedwars Loaded", 5)
