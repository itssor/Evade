-- Evade.GG // modules/games/Fisch.lua
-- Structure: Module Pattern (Loader passes UI instance)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Fisch = {}

--// STATE
Fisch.Config = {
    AutoShake = false,
    AutoReel = false,
    AutoCast = false
}

--// REMOTES (Lazy Load)
local Remotes = { Cast = nil, Reel = nil }

local function GetRemotes()
    if not Remotes.Cast then
        local events = ReplicatedStorage:WaitForChild("events", 5)
        if events then
            Remotes.Cast = events:WaitForChild("cast", 1)
            Remotes.Reel = events:WaitForChild("reel", 1)
        end
    end
end

--// LOGIC FUNCTIONS
local function AutoShake()
    local shakeUI = PlayerGui:FindFirstChild("shakeui")
    if shakeUI and shakeUI.Enabled then
        local button = shakeUI:FindFirstChild("button")
        if button and button.Visible then
            GuiService.SelectedObject = button
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end
    end
end

local function AutoReel()
    local reelUI = PlayerGui:FindFirstChild("reel")
    if reelUI and reelUI.Enabled then
        local bar = reelUI:FindFirstChild("bar")
        if bar then
            local playerBar = bar:FindFirstChild("playerbar")
            local targetFish = bar:FindFirstChild("fish")
            if playerBar and targetFish and Remotes.Reel then
                if playerBar.Position.X.Scale < targetFish.Position.X.Scale then
                    Remotes.Reel:FireServer(100)
                end
            end
        end
    end
end

local function AutoCast()
    local char = LocalPlayer.Character
    if char then
        local rod = char:FindFirstChildOfClass("Tool")
        if rod and not rod:FindFirstChild("bobber") and Remotes.Cast then
            Remotes.Cast:FireServer(100)
        end
    end
end

--// INIT (The part you wouldn't shut up about)
-- We expect the Loader to pass the 'Library' and the main 'Window' or 'SaveManager'
function Fisch.Init(Library, Window)
    print("[Evade] Initializing Fisch Module...")
    GetRemotes()

    -- 1. Create the Tab using the passed Window
    local Tab = Window:AddTab("Fisch", "fish") -- Icon name is a guess, fix it later

    -- 2. Build the UI Elements (Obsidian Syntax)
    local Group = Tab:AddLeftGroupbox("Automation")

    Group:AddToggle("AutoCast", {
        Text = "Auto Cast",
        Default = false,
        Tooltip = "Automatically casts the rod when idle.",
        Callback = function(Value)
            Fisch.Config.AutoCast = Value
        end
    })

    Group:AddToggle("AutoShake", {
        Text = "Auto Shake",
        Default = false,
        Tooltip = "Completes the shake minigame automatically.",
        Callback = function(Value)
            Fisch.Config.AutoShake = Value
        end
    })

    Group:AddToggle("AutoReel", {
        Text = "Auto Reel",
        Default = false,
        Tooltip = "Reels in the fish automatically.",
        Callback = function(Value)
            Fisch.Config.AutoReel = Value
        end
    })

    -- 3. Start the Loop
    -- We bind to RenderStepped but check the Config table directly
    RunService.RenderStepped:Connect(function()
        if Fisch.Config.AutoShake then AutoShake() end
        if Fisch.Config.AutoReel then AutoReel() end
        if Fisch.Config.AutoCast then AutoCast() end
    end)
    
    -- Notification using the Library
    Library:Notify("Fisch Module Loaded", 5)
end

return Fisch
