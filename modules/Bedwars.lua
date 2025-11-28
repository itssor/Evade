local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local ReplicatedStorage = Services.ReplicatedStorage
local KnitClient = debug.getupvalue(require(LocalPlayer.PlayerScripts.TS.knit).setup, 6)
local ClientStore = require(LocalPlayer.PlayerScripts.TS.ui.store).ClientStore
local SwordCont = KnitClient.Controllers.SwordController
local BlockCont = KnitClient.Controllers.BlockController
local SprintCont = KnitClient.Controllers.SprintController

local Window = Library:CreateWindow({
    Title = "Evade | Bedwars",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Blatant = Window:AddTab("Blatant"),
    Utility = Window:AddTab("Utility"),
    Visuals = Window:AddTab("Visuals"),
    World = Window:AddTab("World"),
    Settings = Window:AddTab("Settings")
}

local Aura = Tabs.Combat:AddLeftGroupbox("Kill Aura")
Aura:AddToggle("Killaura", { Text = "Enabled", Default = false })
Aura:AddSlider("AuraRange", { Text = "Range", Default = 18, Min = 1, Max = 22, Rounding = 1 })
Aura:AddToggle("AuraAnim", { Text = "Swing Animation", Default = true })
Aura:AddToggle("AutoToxic", { Text = "Auto Toxic", Default = false })

local Vel = Tabs.Combat:AddRightGroupbox("Velocity")
Vel:AddToggle("Velocity", { Text = "Anti-Knockback", Default = false })
Vel:AddSlider("VelH", { Text = "Horizontal %", Default = 0, Min = 0, Max = 100, Rounding = 0 })
Vel:AddSlider("VelV", { Text = "Vertical %", Default = 0, Min = 0, Max = 100, Rounding = 0 })

local Fly = Tabs.Blatant:AddLeftGroupbox("Flight")
Fly:AddToggle("Flight", { Text = "Flight", Default = false }):AddKeyPicker("FlyKey", { Default = "F", Mode = "Toggle" })
Fly:AddSlider("FlySpeed", { Text = "Speed", Default = 40, Min = 10, Max = 100, Rounding = 0 })
Fly:AddToggle("HighJump", { Text = "High Jump", Default = false }):AddKeyPicker("JumpKey", { Default = "G", Mode = "Toggle" })

local Speed = Tabs.Blatant:AddRightGroupbox("Movement")
Speed:AddToggle("Speed", { Text = "Speed", Default = false })
Speed:AddSlider("SpeedVal", { Text = "Value", Default = 23, Min = 16, Max = 50, Rounding = 1 })
Speed:AddToggle("Spider", { Text = "Spider (Climb Walls)", Default = false })
Speed:AddToggle("NoFall", { Text = "No Fall Damage", Default = true })
Speed:AddToggle("Phase", { Text = "Phase (Noclip)", Default = false })

local Scaff = Tabs.Utility:AddLeftGroupbox("Building")
Scaff:AddToggle("Scaffold", { Text = "Scaffold", Default = false })
Scaff:AddToggle("ScaffExpand", { Text = "Expand", Default = false })

local Stealer = Tabs.Utility:AddRightGroupbox("Loot")
Stealer:AddToggle("ChestSteal", { Text = "Chest Stealer", Default = false })
Stealer:AddSlider("StealRange", { Text = "Range", Default = 30, Min = 10, Max = 60, Rounding = 0 })

local Nuke = Tabs.World:AddLeftGroupbox("Nuker")
Nuke:AddToggle("BedNuker", { Text = "Bed Nuker", Default = false })
Nuke:AddSlider("NukeRange", { Text = "Range", Default = 30, Min = 10, Max = 30, Rounding = 0 })

local Vis = Tabs.Visuals:AddLeftGroupbox("ESP")
Vis:AddToggle("BedESP", { Text = "Bed ESP", Default = true })
Vis:AddToggle("PlayerESP", { Text = "Player ESP", Default = true })

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

local function SwordHit(T)
    if SwordCont then
        pcall(function()
            local args = {
                ["chargedAttack"] = {["chargeRatio"] = 0},
                ["entityInstance"] = T,
                ["validate"] = {
                    ["targetPosition"] = {["value"] = T.HumanoidRootPart.Position},
                    ["selfPosition"] = {["value"] = LocalPlayer.Character.HumanoidRootPart.Position}
                }
            }
            KnitClient.Controllers.SwordController:swingSwordAtMouse()
            ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.SwordHit:FireServer(args)
        end)
    end
end

local ToxicMsgs = {"Ez", "L", "Trash", "Evade On Top", "Get Good", "Lag?"}
Services.Players.PlayerRemoving:Connect(function(p)
    if Library.Toggles.AutoToxic.Value and p.Team ~= LocalPlayer.Team then
        Services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(ToxicMsgs[math.random(#ToxicMsgs)], "All")
    end
end)

task.spawn(function()
    while true do
        if Library.Toggles.Killaura.Value and LocalPlayer.Character then
            local T = GetTarget(Library.Options.AuraRange.Value)
            if T then
                SwordHit(T)
                if Library.Toggles.AuraAnim.Value then
                    local S = LocalPlayer.Character:FindFirstChild("Sword") or LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                    if S then S:Activate() end
                end
            end
        end
        
        if Library.Toggles.BedNuker.Value and LocalPlayer.Character then
            local Beds = game:GetService("CollectionService"):GetTagged("bed")
            for _, B in pairs(Beds) do
                if B and B:FindFirstChild("Covers") and B.Covers.BrickColor ~= LocalPlayer.Team.TeamColor then
                    local Mag = (B.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if Mag < Library.Options.NukeRange.Value then
                        game:GetService("ReplicatedStorage").rbxts_include.node_modules["@rbxts"].net.out._NetManaged.DamageBlock:InvokeServer({
                            ["blockRef"] = {["blockPosition"] = Vector3.new(math.round(B.Position.X/3), math.round(B.Position.Y/3), math.round(B.Position.Z/3))},
                            ["hitPosition"] = B.Position,
                            ["hitNormal"] = Vector3.new(0,1,0)
                        })
                    end
                end
            end
        end
        
        if Library.Toggles.ChestSteal.Value and LocalPlayer.Character then
            for _, v in pairs(game:GetService("CollectionService"):GetTagged("chest")) do
                if (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < Library.Options.StealRange.Value then
                    local ChestFolder = v:FindFirstChild("ChestFolderValue")
                    if ChestFolder then
                        local C = ChestFolder.Value
                        if C then
                            for _, Item in pairs(C:GetChildren()) do
                                if Item:IsA("Accessory") then
                                    game:GetService("ReplicatedStorage").rbxts_include.node_modules["@rbxts"].net.out._NetManaged.Inventory:InvokeServer({
                                        ["chest"] = v,
                                        ["invItem"] = Item
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if Library.Toggles.Flight.Value and Library.Options.FlyKey:GetState() and HRP then
        local LV = HRP:FindFirstChild("BWFly") or Instance.new("LinearVelocity", HRP); LV.Name = "BWFly"
        LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
        local Att = HRP:FindFirstChild("BWAtt") or Instance.new("Attachment", HRP); Att.Name = "BWAtt"; LV.Attachment0 = Att
        
        local Dir = Vector3.zero
        local CF = Camera.CFrame
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + CF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - CF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - CF.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + CF.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then Dir = Dir + Vector3.new(0,1,0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then Dir = Dir - Vector3.new(0,1,0) end
        
        LV.VectorVelocity = Dir * Library.Options.FlySpeed.Value
    else
        if HRP:FindFirstChild("BWFly") then HRP.BWFly:Destroy() end
    end
    
    if Library.Toggles.Velocity.Value and HRP then
        if HRP.Velocity.Y > 0 then HRP.Velocity = Vector3.new(HRP.Velocity.X, HRP.Velocity.Y * (Library.Options.VelV.Value/100), HRP.Velocity.Z) end
        if HRP.Velocity.Magnitude > 10 then
            HRP.Velocity = Vector3.new(HRP.Velocity.X * (Library.Options.VelH.Value/100), HRP.Velocity.Y, HRP.Velocity.Z * (Library.Options.VelH.Value/100))
        end
    end
    
    if Library.Toggles.Spider.Value and HRP then
        local Ray = Ray.new(HRP.Position, HRP.CFrame.LookVector * 2)
        local Part = workspace:FindPartOnRay(Ray, LocalPlayer.Character)
        if Part and Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            HRP.Velocity = Vector3.new(0, 35, 0)
        end
    end
    
    if Library.Toggles.NoFall.Value then
        game:GetService("ReplicatedStorage").rbxts_include.node_modules["@rbxts"].net.out._NetManaged.GroundHit:FireServer()
    end
    
    if Library.Toggles.HighJump.Value and Library.Options.JumpKey:GetState() and HRP then
        HRP.Velocity = Vector3.new(HRP.Velocity.X, 60, HRP.Velocity.Z)
    end
    
    if Library.Toggles.Speed.Value and Hum then
        Hum.WalkSpeed = Library.Options.SpeedVal.Value
        if SprintCont then SprintCont:startSprinting() end
    end
    
    if Library.Toggles.Phase.Value and HRP then
        for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
    
    if Library.Toggles.Scaffold.Value and HRP then
        local Block = nil
        for _, v in pairs(Services.HttpService:JSONDecode(ClientStore:getState().Inventory.observedInventory.inventory).items) do
            if v.itemType:find("wool") or v.itemType:find("wood") or v.itemType:find("stone") then Block = v.itemType; break end
        end
        if Block then
            local Pos = HRP.Position + Vector3.new(0, -3.5, 0)
            if Library.Toggles.ScaffExpand.Value then Pos = Pos + (HRP.Velocity * 0.2) end
            local BlockPos = Vector3.new(math.round(Pos.X/3), math.round(Pos.Y/3), math.round(Pos.Z/3))
            game:GetService("ReplicatedStorage").rbxts_include.node_modules["@rbxts"].net.out._NetManaged.PlaceBlock:InvokeServer({
                ["blockType"] = Block,
                ["blockData"] = 0,
                ["position"] = BlockPos
            })
        end
    end
end)

local BedDrawings = {}
Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(BedDrawings) do d:Remove() end
    BedDrawings = {}
    
    if Library.Toggles.BedESP.Value then
        for _, Bed in pairs(game:GetService("CollectionService"):GetTagged("bed")) do
            if Bed and Bed:FindFirstChild("Covers") then
                local Pos, Vis = Camera:WorldToViewportPoint(Bed.Position)
                if Vis then
                    local B = Drawing.new("Square"); B.Visible=true; B.Size=Vector2.new(30,30); B.Position=Vector2.new(Pos.X-15,Pos.Y-15)
                    B.Color = Bed.Covers.BrickColor.Color; B.Thickness=2; B.Filled=false; table.insert(BedDrawings, B)
                    local T = Drawing.new("Text"); T.Visible=true; T.Text="BED"; T.Color=B.Color; T.Center=true; T.Position=Vector2.new(Pos.X,Pos.Y-25)
                    table.insert(BedDrawings, T)
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
                    B.Color = p.TeamColor.Color; B.Thickness=1; B.Filled=false; table.insert(BedDrawings, B)
                end
            end
        end
    end
end)

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

Library:Notify("Evade | Bedwars Module Loaded", 5)
