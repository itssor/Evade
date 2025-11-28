local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

-- // SERVICES & CONTROLLERS (Dynamic Capture)
local ReplicatedStorage = Services.ReplicatedStorage
local KnitClient = debug.getupvalue(require(LocalPlayer.PlayerScripts.TS.knit).setup, 6)
local ClientStore = require(LocalPlayer.PlayerScripts.TS.ui.store).ClientStore

-- Dynamic Controller/Remote Grabber
local function GetController(Match)
    for Name, Cont in pairs(KnitClient.Controllers) do
        if tostring(Name):find(Match) then return Cont end
    end
    return nil
end

local SwordCont = GetController("Sword")
local BlockCont = GetController("Block")
local SprintCont = GetController("Sprint")
local ViewmodelCont = GetController("Viewmodel")

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Bedwars (Voidware)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Game = Window:AddTab("Bedwars"),
    Combat = Window:AddTab("Combat"),
    Blatant = Window:AddTab("Blatant"),
    Utility = Window:AddTab("Utility"),
    Visuals = Window:AddTab("Visuals"),
    Settings = Window:AddTab("Settings")
}

-- // 1. COMBAT
local AuraGroup = Tabs.Combat:AddLeftGroupbox("Kill Aura")
AuraGroup:AddToggle("Killaura", { Text = "Enabled", Default = false })
AuraGroup:AddSlider("AuraRange", { Text = "Range", Default = 18, Min = 1, Max = 22, Rounding = 1 })
AuraGroup:AddToggle("AuraAnim", { Text = "Swing Animation", Default = true })
AuraGroup:AddToggle("AutoToxic", { Text = "Auto Toxic", Default = false })

local VelGroup = Tabs.Combat:AddRightGroupbox("Velocity")
VelGroup:AddToggle("Velocity", { Text = "Anti-Knockback", Default = false })
VelGroup:AddSlider("VelH", { Text = "Horizontal %", Default = 0, Min = 0, Max = 100 })
VelGroup:AddSlider("VelV", { Text = "Vertical %", Default = 0, Min = 0, Max = 100 })

-- // 2. BLATANT
local FlyGroup = Tabs.Blatant:AddLeftGroupbox("Flight")
FlyGroup:AddToggle("Flight", { Text = "Flight", Default = false }):AddKeyPicker("FlyKey", { Default = "F", Mode = "Toggle" })
FlyGroup:AddSlider("FlySpeed", { Text = "Speed", Default = 40, Min = 10, Max = 80 })
FlyGroup:AddToggle("HighJump", { Text = "High Jump", Default = false }):AddKeyPicker("JumpKey", { Default = "G", Mode = "Toggle" })

local MoveGroup = Tabs.Blatant:AddRightGroupbox("Movement")
MoveGroup:AddToggle("Sprint", { Text = "Omni-Sprint", Default = true })
MoveGroup:AddToggle("Speed", { Text = "Speed", Default = false })
MoveGroup:AddSlider("SpeedVal", { Text = "Factor", Default = 20, Min = 16, Max = 35 })
MoveGroup:AddToggle("NoFall", { Text = "No Fall Damage", Default = true })
MoveGroup:AddToggle("Spider", { Text = "Spider (Climb Walls)", Default = false })

-- // 3. UTILITY
local BuildGroup = Tabs.Utility:AddLeftGroupbox("Scaffold")
BuildGroup:AddToggle("Scaffold", { Text = "Enabled", Default = false })
BuildGroup:AddToggle("ScaffExpand", { Text = "Expand (Prediction)", Default = false })

local WorldGroup = Tabs.Utility:AddRightGroupbox("World Interaction")
WorldGroup:AddToggle("BedNuker", { Text = "Bed Nuker", Default = false })
WorldGroup:AddSlider("NukeRange", { Text = "Range", Default = 30, Min = 10, Max = 30 })
WorldGroup:AddToggle("ChestSteal", { Text = "Chest Stealer", Default = false })
WorldGroup:AddToggle("FastEat", { Text = "Fast Eat", Default = false })

-- // 4. VISUALS
local VisGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
VisGroup:AddToggle("BedESP", { Text = "Bed ESP", Default = true })
VisGroup:AddToggle("PlayerESP", { Text = "Player ESP", Default = true })

-- // LOGIC FUNCTIONS
local function GetTarget(Range)
    local T = nil; local D = Range
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChild("Humanoid")
            if r and h and h.Health > 0 then
                local dist = (r.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < D then D = dist; T = p.Character end
            end
        end
    end
    return T
end

local function Attack(Target)
    if SwordCont then
        pcall(function()
            if Library.Toggles.AuraAnim.Value then SwordCont:swingSwordAtMouse() end
            local args = {
                ["chargedAttack"] = {["chargeRatio"] = 0},
                ["entityInstance"] = Target,
                ["validate"] = {
                    ["targetPosition"] = {["value"] = Target.HumanoidRootPart.Position},
                    ["selfPosition"] = {["value"] = LocalPlayer.Character.HumanoidRootPart.Position}
                }
            }
            -- Use the controller's internal remote reference if possible, else standard path
            local Remote = Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.SwordHit
            Remote:FireServer(args)
        end)
    end
end

local function GetBlock()
    local Inv = Services.HttpService:JSONDecode(ClientStore:getState().Inventory.observedInventory.inventory).items
    for _, item in pairs(Inv) do
        if item.itemType:find("wool") or item.itemType:find("wood") or item.itemType:find("stone") then
            return item.itemType
        end
    end
    return nil
end

local ToxicMsgs = {"Ez", "L", "Trash", "Evade On Top", "Get Good", "Lag?", "Voidware Who?"}
Services.Players.PlayerRemoving:Connect(function(p)
    if Library.Toggles.AutoToxic.Value and p.Team ~= LocalPlayer.Team then
        Services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(ToxicMsgs[math.random(#ToxicMsgs)], "All")
    end
end)

-- // MAIN LOOPS
task.spawn(function()
    while true do
        if not LocalPlayer.Character then task.wait(); continue end
        
        -- Killaura
        if Library.Toggles.Killaura.Value then
            local T = GetTarget(Library.Options.AuraRange.Value)
            if T then
                -- Silent Rotations (Voidware Style)
                local LA = LocalPlayer.Character.HumanoidRootPart.CFrame
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LA.Position, Vector3.new(T.HumanoidRootPart.Position.X, LA.Position.Y, T.HumanoidRootPart.Position.Z))
                Attack(T)
            end
        end
        
        -- Bed Nuker
        if Library.Toggles.BedNuker.Value then
            local Beds = Services.CollectionService:GetTagged("bed")
            for _, B in pairs(Beds) do
                if B and B:FindFirstChild("Covers") and B.Covers.BrickColor ~= LocalPlayer.Team.TeamColor then
                    local Mag = (B.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if Mag < Library.Options.NukeRange.Value then
                        local Args = {
                            ["blockRef"] = {["blockPosition"] = Vector3.new(math.round(B.Position.X/3), math.round(B.Position.Y/3), math.round(B.Position.Z/3))},
                            ["hitPosition"] = B.Position,
                            ["hitNormal"] = Vector3.new(0, 1, 0)
                        }
                        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.DamageBlock:InvokeServer(Args)
                    end
                end
            end
        end
        
        -- Chest Stealer
        if Library.Toggles.ChestSteal.Value then
            for _, v in pairs(Services.CollectionService:GetTagged("chest")) do
                if (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 30 then
                    local Folder = v:FindFirstChild("ChestFolderValue")
                    if Folder and Folder.Value then
                        for _, Item in pairs(Folder.Value:GetChildren()) do
                            if Item:IsA("Accessory") then
                                Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.Inventory:InvokeServer({
                                    ["chest"] = v, ["invItem"] = Item
                                })
                            end
                        end
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
    
    -- Scaffold
    if Library.Toggles.Scaffold.Value and HRP then
        local Block = GetBlock()
        if Block then
            local Pos = HRP.Position + Vector3.new(0, -3.5, 0)
            if Library.Toggles.ScaffExpand.Value then Pos = Pos + (HRP.Velocity * 0.3) end
            
            local BlockPos = Vector3.new(math.round(Pos.X/3), math.round(Pos.Y/3), math.round(Pos.Z/3))
            local Args = {
                ["blockType"] = Block,
                ["blockData"] = 0,
                ["position"] = BlockPos
            }
            Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.PlaceBlock:InvokeServer(Args)
            
            -- Visual Animation
            if ViewmodelCont and ViewmodelCont.playAnimation then
                ViewmodelCont:playAnimation(15) 
            end
        end
    end
    
    -- Velocity
    if Library.Toggles.Velocity.Value and HRP then
        if HRP.Velocity.Magnitude > 20 or HRP.Velocity.Y > 10 then
             HRP.Velocity = Vector3.new(
                 HRP.Velocity.X * (Library.Options.VelH.Value/100),
                 HRP.Velocity.Y * (Library.Options.VelV.Value/100),
                 HRP.Velocity.Z * (Library.Options.VelH.Value/100)
             )
        end
    end
    
    -- Flight (LinearVelocity)
    if Library.Toggles.Flight.Value and Library.Options.FlyKey:GetState() and HRP then
        local LV = HRP:FindFirstChild("VoidFly") or Instance.new("LinearVelocity", HRP); LV.Name = "VoidFly"
        LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
        local Att = HRP:FindFirstChild("VoidAtt") or Instance.new("Attachment", HRP); Att.Name = "VoidAtt"; LV.Attachment0 = Att
        
        local Dir = Vector3.zero
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then Dir = Dir + Vector3.new(0,1,0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then Dir = Dir - Vector3.new(0,1,0) end
        
        LV.VectorVelocity = Dir * Library.Options.FlySpeed.Value
    else
        if HRP:FindFirstChild("VoidFly") then HRP.VoidFly:Destroy() end
    end
    
    -- Speed
    if Library.Toggles.Speed.Value and Hum then
        Hum.WalkSpeed = Library.Options.SpeedVal.Value
        if SprintCont then SprintCont:startSprinting() end
    end
    
    -- No Fall
    if Library.Toggles.NoFall.Value then
        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.GroundHit:FireServer()
    end
    
    -- Spider
    if Library.Toggles.Spider.Value and HRP then
        local Ray = Ray.new(HRP.Position, HRP.CFrame.LookVector * 2)
        local Part = workspace:FindPartOnRay(Ray, LocalPlayer.Character)
        if Part and Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            HRP.Velocity = Vector3.new(HRP.Velocity.X, 35, HRP.Velocity.Z)
        end
    end
    
    -- High Jump
    if Library.Toggles.HighJump.Value and Library.Options.JumpKey:GetState() and HRP then
        HRP.Velocity = Vector3.new(HRP.Velocity.X, 60, HRP.Velocity.Z)
    end
end)

-- Fast Eat (Consumable Controller)
-- Hooks into the tool activation to consume faster
-- (Simplified for stability: Loops the Consume Remote)
if Library.Toggles.FastEat.Value then
    -- Logic usually requires hooking the specific consumable item controller
    -- Placeholder for future expansion
end

-- // ESP LOOP
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

Library:Notify("Evade | Bedwars Loaded", 5)
