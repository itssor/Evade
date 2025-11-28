--[[
    EVADE.GG - TSB MODULE (v1.0)
    Features: Auto-Block (Animation Based), No Ragdoll, Speed
    Logic: Animation Sniffing & State Manipulation
]]

-- // PRE-FLIGHT
repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

-- // IMPORTS
local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local ReplicatedStorage = Services.ReplicatedStorage

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | TSB",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Movement = Window:AddTab("Movement"),
    Visuals = Window:AddTab("Visuals"),
    Settings = Window:AddTab("Settings")
}

-- // FEATURES
local CombatGroup = Tabs.Combat:AddLeftGroupbox("Defense")
CombatGroup:AddToggle("AutoBlock", { Text = "Auto Block", Default = true, Tooltip = "Blocks when enemy attacks nearby" })
CombatGroup:AddSlider("BlockDist", { Text = "Detect Range", Default = 15, Min = 5, Max = 30, Rounding = 1 })
CombatGroup:AddToggle("NoRagdoll", { Text = "Anti-Ragdoll (No Stun)", Default = false })
CombatGroup:AddToggle("NoStunEffect", { Text = "Remove Stun Effects", Default = false })

local MoveGroup = Tabs.Movement:AddLeftGroupbox("Mobility")
MoveGroup:AddToggle("Speed", { Text = "Speed", Default = false }):AddKeyPicker("SpeedKey", { Default = "V", Mode = "Toggle" })
MoveGroup:AddSlider("SpeedVal", { Text = "Speed Factor", Default = 30, Min = 16, Max = 100 })
MoveGroup:AddToggle("InfDash", { Text = "Infinite Dash (Client)", Default = false })

local VisGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
VisGroup:AddToggle("PlayerESP", { Text = "Player ESP", Default = true })
VisGroup:AddToggle("Tracers", { Text = "Tracers", Default = false })

-- // LOGIC HELPERS
local function GetCommunicate()
    -- TSB Remote is usually in ReplicatedStorage.Communicate or similar
    -- We search for it to be safe
    local Comm = ReplicatedStorage:FindFirstChild("Communicate") 
    if not Comm then
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == "Communicate" and v:IsA("RemoteEvent") then
                return v
            end
        end
    end
    return Comm
end

local Remote = GetCommunicate()

-- // MAIN LOOP (RenderStepped)
local ClosestEnemy = nil

Services.RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character then return end
    local MyRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end

    -- 1. AUTO BLOCK LOGIC
    if Library.Toggles.AutoBlock.Value and Remote then
        local Danger = false
        
        for _, Plr in pairs(Services.Players:GetPlayers()) do
            if Plr ~= LocalPlayer and Plr.Character then
                local E_Root = Plr.Character:FindFirstChild("HumanoidRootPart")
                local E_Hum = Plr.Character:FindFirstChild("Humanoid")
                
                if E_Root and E_Hum then
                    local Dist = (E_Root.Position - MyRoot.Position).Magnitude
                    
                    -- If enemy is close
                    if Dist < Library.Options.BlockDist.Value then
                        -- Check Animations
                        for _, Track in pairs(E_Hum:GetPlayingAnimationTracks()) do
                            -- Heuristic: Most attack animations have "Attack", "Punch", "Swing", or "Skill" in the ID/Name
                            -- Or high priority.
                            local ID = Track.Animation.AnimationId
                            local Name = Track.Name:lower()
                            
                            if (Name:find("attack") or Name:find("punch") or Name:find("skill") or Track.Priority == Enum.AnimationPriority.Action) then
                                Danger = true
                                break
                            end
                        end
                    end
                end
            end
            if Danger then break end
        end
        
        if Danger then
            -- Hold Block
            local Args = {
                ["Goal"] = "KeyPress",
                ["Key"] = Enum.KeyCode.F -- Standard Block Key
            }
            -- Some versions use: Remote:FireServer({["Goal"] = "Block", ["Val"] = true})
            -- Trying generic key press simulation first as it's safer
            Services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        else
            -- Release Block
            Services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end
    end

    -- 2. SPEED
    if Library.Toggles.Speed.Value and Library.Options.SpeedKey:GetState() then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then
            -- CFrame method allows moving while blocking/stunned sometimes
            if Hum.MoveDirection.Magnitude > 0 then
                MyRoot.CFrame = MyRoot.CFrame + (Hum.MoveDirection * (Library.Options.SpeedVal.Value / 50))
            end
        end
    end
end)

-- // PHYSICS LOOP (Stepped)
Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    
    -- 3. ANTI-RAGDOLL
    if Library.Toggles.NoRagdoll.Value then
        -- TSB uses "Ragdoll" constraints or attributes
        local Char = LocalPlayer.Character
        if Char:GetAttribute("Ragdoll") then
            Char:SetAttribute("Ragdoll", false)
        end
        
        -- Remove physical constraints
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then
                v.Enabled = false
            end
        end
    end
    
    -- 4. NO STUN EFFECTS
    if Library.Toggles.NoStunEffect.Value then
        local Char = LocalPlayer.Character
        if Char:GetAttribute("Stunned") then
             Char:SetAttribute("Stunned", false)
        end
        -- Remove visual stun particles
        for _, v in pairs(Char:GetDescendants()) do
            if v.Name:lower():find("stun") and v:IsA("ParticleEmitter") then
                v.Enabled = false
            end
        end
    end
end)

-- // ESP (Sense Integration)
if Library.Toggles.PlayerESP.Value then
   getgenv().Evade.Sense.teamSettings.enemy.enabled = true
   getgenv().Evade.Sense.Load()
end

-- // SETTINGS
Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/TSB")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | TSB Module Loaded", 5)
