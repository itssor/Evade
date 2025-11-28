local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local KnitClient = nil
local SwordCont = nil
local BlockCont = nil
local ClientStore = nil

local function GetKnit()
    repeat task.wait() until game:IsLoaded()
    local TS = Services.ReplicatedStorage:WaitForChild("TS", 10)
    local KnitPkg = TS and require(TS:WaitForChild("knit", 10))
    
    if not KnitPkg then return nil end
    
    local Setup = KnitPkg.setup
    if not Setup then return nil end
    
    for i = 1, 10 do
        local Val = debug.getupvalue(Setup, i)
        if type(Val) == "table" and Val.Controllers and Val.Services then
            return Val
        end
    end
    
    return nil
end

local function Init()
    local Start = tick()
    repeat 
        KnitClient = GetKnit()
        task.wait(0.1)
    until KnitClient or (tick() - Start > 10)
    
    if not KnitClient then return false end

    for Name, Cont in pairs(KnitClient.Controllers) do
        if Name:find("Sword") or (rawget(Cont, "swingSwordAtMouse") and rawget(Cont, "attackEntity")) then
            SwordCont = Cont
        elseif Name:find("Block") or rawget(Cont, "placeBlock") then
            BlockCont = Cont
        elseif Name:find("AntiCheat") or Name:find("Raven") then
            if rawget(Cont, "disable") then Cont:disable() end
            if rawget(Cont, "stop") then Cont:stop() end
        end
    end
    
    local UI = LocalPlayer.PlayerScripts:FindFirstChild("TS") and LocalPlayer.PlayerScripts.TS:FindFirstChild("ui")
    local Store = UI and UI:FindFirstChild("store")
    if Store then ClientStore = require(Store).ClientStore end
    
    return true
end

local Success = Init()
if not Success then 
    Library:Notify("Critical: Knit Hook Failed", 10) 
    return 
end

local Window = Library:CreateWindow({
    Title = "Evade | Bedwars (Deep Hook)",
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

local Aura = Tabs.Combat:AddLeftGroupbox("Kill Aura")
Aura:AddToggle("Killaura", { Text = "Enabled", Default = false })
Aura:AddSlider("AuraRange", { Text = "Range", Default = 18, Min = 1, Max = 22, Rounding = 1 })
Aura:AddToggle("AuraAnim", { Text = "Swing Animation", Default = true })

local Vel = Tabs.Combat:AddRightGroupbox("Mods")
Vel:AddToggle("Sprint", { Text = "Omni-Sprint", Default = true })
Vel:AddToggle("Velocity", { Text = "Anti-Knockback", Default = false })
Vel:AddSlider("VelH", { Text = "Horizontal", Default = 0, Min = 0, Max = 100 })
Vel:AddSlider("VelV", { Text = "Vertical", Default = 0, Min = 0, Max = 100 })

local Vis = Tabs.Visuals:AddLeftGroupbox("ESP")
Vis:AddToggle("BedESP", { Text = "Bed ESP", Default = true })
Vis:AddToggle("PlayerESP", { Text = "Player ESP", Default = true })

local Fly = Tabs.Movement:AddLeftGroupbox("Flight")
Fly:AddToggle("Flight", { Text = "Flight", Default = false }):AddKeyPicker("FlyKey", { Default = "F", Mode = "Toggle" })
Fly:AddSlider("FlySpeed", { Text = "Speed", Default = 40, Min = 10, Max = 80 })

local Move = Tabs.Movement:AddRightGroupbox("Movement")
Move:AddToggle("Speed", { Text = "Speed", Default = false })
Move:AddSlider("SpeedVal", { Text = "Factor", Default = 20, Min = 16, Max = 35 })
Move:AddToggle("NoFall", { Text = "No Fall Damage", Default = true })
Move:AddToggle("Spider", { Text = "Spider", Default = false })

local World = Tabs.Game:AddLeftGroupbox("World")
World:AddToggle("BedNuker", { Text = "Bed Nuker", Default = false })
World:AddSlider("NukeRange", { Text = "Range", Default = 30, Min = 10, Max = 30 })
World:AddToggle("ChestSteal", { Text = "Chest Stealer", Default = false })

local Build = Tabs.Game:AddRightGroupbox("Building")
Build:AddToggle("Scaffold", { Text = "Scaffold", Default = false })

local function GetEntity(Range)
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
            local Net = Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged
            if Net:FindFirstChild("SwordHit") then
                Net.SwordHit:FireServer(args)
            else
                for _, r in pairs(Net:GetChildren()) do
                    if r.Name:find("Sword") and r.Name:find("Hit") then
                        r:FireServer(args)
                        break
                    end
                end
            end
        end)
    end
end

local function GetBlock()
    if not ClientStore then return nil end
    local Inv = Services.HttpService:JSONDecode(ClientStore:getState().Inventory.observedInventory.inventory).items
    for _, item in pairs(Inv) do
        if item.itemType:find("wool") or item.itemType:find("wood") or item.itemType:find("stone") then
            return item.itemType
        end
    end
    return nil
end

task.spawn(function()
    while true do
        if Library.Toggles.Killaura.Value and LocalPlayer.Character then
            local T = GetEntity(Library.Options.AuraRange.Value)
            if T then
                local LA = LocalPlayer.Character.HumanoidRootPart.CFrame
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LA.Position, Vector3.new(T.HumanoidRootPart.Position.X, LA.Position.Y, T.HumanoidRootPart.Position.Z))
                Attack(T)
            end
        end
        
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

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if Library.Toggles.Scaffold.Value and HRP then
        local Block = GetBlock()
        if Block then
            local Pos = HRP.Position + Vector3.new(0, -3.5, 0)
            local BlockPos = Vector3.new(math.round(Pos.X/3), math.round(Pos.Y/3), math.round(Pos.Z/3))
            local Args = {
                ["blockType"] = Block,
                ["blockData"] = 0,
                ["position"] = BlockPos
            }
            Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.PlaceBlock:InvokeServer(Args)
        end
    end
    
    if Library.Toggles.Velocity.Value and HRP then
        if HRP.Velocity.Magnitude > 20 or HRP.Velocity.Y > 10 then
             HRP.Velocity = Vector3.new(
                 HRP.Velocity.X * (Library.Options.VelH.Value/100),
                 HRP.Velocity.Y * (Library.Options.VelV.Value/100),
                 HRP.Velocity.Z * (Library.Options.VelH.Value/100)
             )
        end
    end
    
    if Library.Toggles.Flight.Value and Library.Options.FlyKey:GetState() and HRP then
        local LV = HRP:FindFirstChild("VoidFly") or Instance.new("LinearVelocity", HRP); LV.Name = "VoidFly"
        LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
        local Att = HRP:FindFirstChild("VoidAtt") or Instance.new("Attachment", HRP); Att.Name = "VoidAtt"; LV.Attachment0 = Att
        
        local Dir = Vector3.zero
        local CF = Camera.CFrame
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + CF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - CF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - CF.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + CF.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then Dir = Dir + Vector3.new(0,1,0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then Dir = Dir - Vector3.new(0,1,0) end
        
        LV.VectorVelocity = Dir * Library.Options.FlySpeed.Value
        
        if HRP.Position.Y < -10 then
            HRP.Velocity = Vector3.new(0, 50, 0)
        end
    else
        if HRP:FindFirstChild("VoidFly") then HRP.VoidFly:Destroy() end
    end
    
    if Library.Toggles.Speed.Value and Hum then
        Hum.WalkSpeed = Library.Options.SpeedVal.Value
    end
    
    if Library.Toggles.NoFall.Value then
        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.GroundHit:FireServer()
    end
    
    if Library.Toggles.Spider.Value and HRP then
        local Ray = Ray.new(HRP.Position, HRP.CFrame.LookVector * 2)
        local Part = workspace:FindPartOnRay(Ray, LocalPlayer.Character)
        if Part and Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            HRP.Velocity = Vector3.new(HRP.Velocity.X, 35, HRP.Velocity.Z)
        end
    end
end)

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
