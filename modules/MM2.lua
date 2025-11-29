-- // PRE-FLIGHT CHECK
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
local Mouse = Evade.Mouse
local Workspace = Services.Workspace

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | MM2 (Reforged)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Main = Window:AddTab("Main"),
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Settings = Window:AddTab("Settings")
}

-- // VARIABLES
local Roles = {}
local CoinContainer = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("CoinContainer")
local LockedTarget = nil

-- // FEATURES
local FarmGroup = Tabs.Main:AddLeftGroupbox("Farming")
FarmGroup:AddToggle("CoinFarm", { Text = "Auto Farm Coins", Default = false })
FarmGroup:AddToggle("AutoGun", { Text = "Auto Grab Gun", Default = true })

local RageGroup = Tabs.Main:AddRightGroupbox("Rage")
RageGroup:AddToggle("KillAll", { Text = "Kill All (Murderer)", Default = false })
RageGroup:AddToggle("Fling", { Text = "Fling Aura", Default = false })
RageGroup:AddToggle("GodMode", { Text = "Invisible God Mode", Default = false, Tooltip = "Resets character to apply" })

local CombatGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")
CombatGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
CombatGroup:AddSlider("SilentFOV", { Text = "FOV", Default = 150, Min = 10, Max = 800, Rounding = 0 })
CombatGroup:AddToggle("DrawFOV", { Text = "Draw FOV", Default = false })
CombatGroup:AddDropdown("SilentTarget", { Values = {"Murderer", "Sheriff", "All"}, Default = 1, Text = "Target Priority" })

local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
ESPGroup:AddToggle("RoleESP", { Text = "Role ESP", Default = true })
ESPGroup:AddToggle("CoinESP", { Text = "Coin ESP", Default = false })

-- // LOGIC: ROLE SCANNER
local function GetRole(Plr)
    if Plr.Character then
        if Plr.Character:FindFirstChild("Knife") then return "Murderer" end
        if Plr.Character:FindFirstChild("Gun") or Plr.Character:FindFirstChild("Revolver") then return "Sheriff" end
    end
    if Plr.Backpack then
        if Plr.Backpack:FindFirstChild("Knife") then return "Murderer" end
        if Plr.Backpack:FindFirstChild("Gun") or Plr.Backpack:FindFirstChild("Revolver") then return "Sheriff" end
    end
    return "Innocent"
end

task.spawn(function()
    while true do
        for _, v in pairs(Services.Players:GetPlayers()) do
            if v ~= LocalPlayer then
                Roles[v] = GetRole(v)
            end
        end
        task.wait(0.5)
    end
end)

-- // LOGIC: SILENT AIM (Hook Logic)
local function GetSilentTarget()
    local T = nil; local D = Library.Options.SilentFOV.Value
    local MousePos = Services.UserInputService:GetMouseLocation()
    
    for Plr, Role in pairs(Roles) do
        if Plr ~= LocalPlayer and Plr.Character and Plr.Character:FindFirstChild("Head") then
            local IsValid = false
            local Mode = Library.Options.SilentTarget.Value
            
            if Mode == "All" then IsValid = true
            elseif Mode == "Murderer" and Role == "Murderer" then IsValid = true
            elseif Mode == "Sheriff" and Role == "Sheriff" then IsValid = true 
            end

            -- Auto-Switch Logic: If I am Sheriff, shoot Murderer. If I am Murderer, shoot Sheriff.
            local MyRole = GetRole(LocalPlayer)
            if MyRole == "Sheriff" and Role == "Murderer" then IsValid = true end
            if MyRole == "Murderer" and Role == "Sheriff" then IsValid = true end

            if IsValid then
                local Pos, Vis = Camera:WorldToViewportPoint(Plr.Character.Head.Position)
                if Vis then
                    local Dist = (MousePos - Vector2.new(Pos.X, Pos.Y)).Magnitude
                    if Dist < D then D = Dist; T = Plr.Character.Head end
                end
            end
        end
    end
    return T
end

-- Hook Namecall for "Shoot" Remote
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Library.Toggles.SilentAim.Value and method == "FireServer" and tostring(self) == "Shoot" then
        local Target = GetSilentTarget()
        if Target then
            -- MM2 Shoot Remote args: (Position, ...)
            args[1] = Target.Position
            return oldNamecall(self, unpack(args))
        end
    end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- // LOGIC: COIN FARM (Tween)
task.spawn(function()
    while true do
        if Library.Toggles.CoinFarm.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Scan for coins (Dynamic Search)
            local Coins = {}
            if CoinContainer then
                for _, v in pairs(CoinContainer:GetChildren()) do
                    if v.Name == "Coin_Server" then table.insert(Coins, v) end
                end
            end
            -- Fallback scan
            if #Coins == 0 then
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v.Name == "Coin_Server" then table.insert(Coins, v) end
                end
            end

            for _, Coin in pairs(Coins) do
                if not Library.Toggles.CoinFarm.Value then break end
                if Coin:FindFirstChild("Coin") then -- The visual part
                    local Root = LocalPlayer.Character.HumanoidRootPart
                    local Tween = Services.TweenService:Create(Root, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = Coin.Coin.CFrame})
                    Tween:Play()
                    Tween.Completed:Wait()
                    firetouchinterest(Root, Coin.Coin, 0) -- Force touch
                    firetouchinterest(Root, Coin.Coin, 1)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- // LOGIC: KILL ALL
task.spawn(function()
    while true do
        if Library.Toggles.KillAll.Value and LocalPlayer.Character then
            local Knife = LocalPlayer.Character:FindFirstChild("Knife")
            if not Knife and LocalPlayer.Backpack:FindFirstChild("Knife") then
                LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack.Knife)
                Knife = LocalPlayer.Character:FindFirstChild("Knife")
            end

            if Knife then
                for _, Target in pairs(Services.Players:GetPlayers()) do
                    if Target ~= LocalPlayer and Target.Character and Target.Character:FindFirstChild("HumanoidRootPart") and Target.Character.Humanoid.Health > 0 then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = Target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                        task.wait(0.1)
                        if Knife.Parent == LocalPlayer.Character then Knife:Activate() end
                        task.wait(0.25)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- // LOGIC: FLING
Services.RunService.Stepped:Connect(function()
    if Library.Toggles.Fling.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local Root = LocalPlayer.Character.HumanoidRootPart
        local Vel = Root:FindFirstChild("EvadeFling") or Instance.new("BodyAngularVelocity", Root)
        Vel.Name = "EvadeFling"
        Vel.AngularVelocity = Vector3.new(0, 9999, 0)
        Vel.MaxTorque = Vector3.new(0, math.huge, 0)
        
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        
        -- Move to nearest player
        for _, P in pairs(Services.Players:GetPlayers()) do
            if P ~= LocalPlayer and P.Character and P.Character:FindFirstChild("HumanoidRootPart") then
                if (P.Character.HumanoidRootPart.Position - Root.Position).Magnitude < 10 then
                    Root.CFrame = P.Character.HumanoidRootPart.CFrame
                end
            end
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character.HumanoidRootPart:FindFirstChild("EvadeFling") then
                LocalPlayer.Character.HumanoidRootPart.EvadeFling:Destroy()
            end
        end
    end
end)

-- // LOGIC: GOD MODE
Services.RunService.RenderStepped:Connect(function()
    if Library.Toggles.GodMode.Value and LocalPlayer.Character then
        -- Simple Sit Glitch Godmode
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then Hum.Sit = true end
    end
end)

-- // VISUALS LOOP
local Drawings = {}
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false

Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}

    -- FOV
    if Library.Toggles.DrawFOV.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true
        FOVCircle.Radius = Library.Options.SilentFOV.Value
        FOVCircle.Position = Services.UserInputService:GetMouseLocation()
        FOVCircle.Color = Color3.fromRGB(255, 0, 0)
    else
        FOVCircle.Visible = false
    end

    -- Coin ESP
    if Library.Toggles.CoinESP.Value then
        local Coins = {}
        if CoinContainer then 
             for _,v in pairs(CoinContainer:GetChildren()) do table.insert(Coins, v) end 
        end
        for _, Coin in pairs(Coins) do
            if Coin.Name == "Coin_Server" and Coin:FindFirstChild("Coin") then
                local Pos, Vis = Camera:WorldToViewportPoint(Coin.Coin.Position)
                if Vis then
                    local T = Drawing.new("Text"); T.Visible=true; T.Text="."; T.Color=Color3.fromRGB(255,255,0); T.Center=true; T.Size=20; T.Position=Vector2.new(Pos.X, Pos.Y)
                    table.insert(Drawings, T)
                end
            end
        end
    end

    -- Role ESP
    if Library.Toggles.RoleESP.Value then
        for Plr, Role in pairs(Roles) do
            if Plr ~= LocalPlayer and Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
                local Pos, Vis = Camera:WorldToViewportPoint(Plr.Character.HumanoidRootPart.Position)
                if Vis then
                    local Color = Color3.fromRGB(0, 255, 0) -- Innocent
                    local Text = "Innocent"
                    if Role == "Murderer" then Color = Color3.fromRGB(255, 0, 0); Text = "MURDERER" end
                    if Role == "Sheriff" then Color = Color3.fromRGB(0, 0, 255); Text = "SHERIFF" end
                    
                    if Role ~= "Innocent" then -- Only show special roles
                        local T = Drawing.new("Text"); T.Visible=true; T.Text=Text; T.Color=Color; T.Center=true; T.Outline=true; T.Position=Vector2.new(Pos.X, Pos.Y - 40)
                        table.insert(Drawings, T)
                        
                        local B = Drawing.new("Square"); B.Visible=true; B.Color=Color; B.Thickness=1; B.Filled=false
                        B.Size = Vector2.new(2000/Pos.Z, 3000/Pos.Z); B.Position = Vector2.new(Pos.X-B.Size.X/2, Pos.Y-B.Size.Y/2)
                        table.insert(Drawings, B)
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
Evade.SaveManager:SetFolder("Evade/MM2")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | MM2 (Reforged) Loaded", 5)
