--[[
    Grow a Garden Auto-Farm Script (Minimalist UI Edition)
    Features:
    - Remote harvesting
    - Smart planting system
    - Event automation
    - Inventory management
    - NoClip support
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlayerGui = game:GetService("PlayerGui")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack

-- UI Theme
local MinimalTheme = {
    WindowBg = Color3.fromRGB(40, 40, 40),
    TitleBarBg = Color3.fromRGB(30, 30, 30),
    FrameBg = Color3.fromRGB(50, 50, 50),
    ButtonsBg = Color3.fromRGB(0, 180, 180),
    TextColor = Color3.fromRGB(220, 220, 220),
    AccentColor = Color3.fromRGB(0, 150, 150),
    BorderColor = Color3.fromRGB(70, 70, 70)
}

-- Core Variables
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm
local MyFarm = Farms:FindFirstChild(LocalPlayer.Name)
local PlantLocations = MyFarm and MyFarm.Important.Plant_Locations
local PlantsPhysical = MyFarm and MyFarm.Important.Plants_Physical

-- Harvesting
local HarvestIgnores = {
    Normal = false,
    Gold = false,
    Rainbow = false
}

-- Auto-Farm Toggles
local AutoHarvest = {Value = false}
local AutoPlant = {Value = false}
local AutoPlantRandom = {Value = false}
local SelectedSeed = {Selected = ""}
local NoClip = {Value = false}
local AutoSell = {Value = false}
local SellThreshold = {Value = 15}
local HarvestEventEnabled = {Value = false}

-- Seed Tracking
local SeedStock = {}
local OwnedSeeds = {
    Carrot = {Count = 0},
    Blueberry = {Count = 0},
    Pumpkin = {Count = 0}
    -- Add more seeds as needed
}

-- Connections
local connections = {}

-- UI Library
local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
ReGui:Init()
ReGui:DefineTheme("MinimalCyan", MinimalTheme)

-- Core Functions
local function SafeGetFarm()
    if not MyFarm or not MyFarm.Parent then
        MyFarm = Farms:FindFirstChild(LocalPlayer.Name)
        if not MyFarm then
            warn("Farm not found!")
            return nil
        end
        PlantLocations = MyFarm.Important.Plant_Locations
        PlantsPhysical = MyFarm.Important.Plants_Physical
    end
    return MyFarm
end

local function GetFarmArea()
    if not SafeGetFarm() then return nil end
    
    local Dirt = PlantLocations:FindFirstChildOfClass("Part")
    local Center = Dirt:GetPivot()
    local Size = Dirt.Size
    return {
        X1 = math.ceil(Center.X - (Size.X/2)),
        Z1 = math.ceil(Center.Z - (Size.Z/2)),
        X2 = math.floor(Center.X + (Size.X/2)),
        Z2 = math.floor(Center.Z + (Size.Z/2))
    }
end

local farmArea = GetFarmArea()

local function GetRandomFarmPoint()
    return Vector3.new(
        math.random(farmArea.X1, farmArea.X2),
        4,
        math.random(farmArea.Z1, farmArea.Z2)
    )
end

local function GetInvCrops()
    local crops = {}
    if LocalPlayer:FindFirstChild("Player_Inventory") then
        for _, item in ipairs(LocalPlayer.Player_Inventory:GetChildren()) do
            if item:IsA("NumberValue") then
                table.insert(crops, {
                    Name = item.Name,
                    Value = item.Value
                })
            end
        end
    end
    return crops
end

local function RemoteHarvestPlant(Plant)
    local success, err = pcall(function()
        GameEvents.HarvestPlant_RE:FireServer(Plant:GetPivot().Position)
    end)
    
    if not success then
        local Prompt = Plant:FindFirstChildOfClass("ProximityPrompt")
        if Prompt then
            fireproximityprompt(Prompt)
        end
    end
end

local function HarvestAllPlants()
    if not AutoHarvest.Value or not SafeGetFarm() then return end
    
    for _, Plant in pairs(PlantsPhysical:GetDescendants()) do
        if Plant:IsA("Model") and Plant:FindFirstChild("Fruits") then
            local Variant = Plant:FindFirstChild("Variant")
            if not Variant or not HarvestIgnores[Variant.Value] then
                RemoteHarvestPlant(Plant)
                task.wait(0.05)
            end
        end
    end
end

local function AutoPlantSeeds()
    if not AutoPlant.Value or not SelectedSeed.Selected or SelectedSeed.Selected == "" then return end
    
    local SeedData = OwnedSeeds[SelectedSeed.Selected]
    if not SeedData or SeedData.Count <= 0 then return end

    if AutoPlantRandom.Value then
        for _ = 1, math.min(SeedData.Count, 10) do -- Limit to 10 plants per cycle
            GameEvents.Plant_RE:FireServer(GetRandomFarmPoint(), SelectedSeed.Selected)
            task.wait(0.1)
        end
    else
        -- Grid planting logic would go here
    end
end

local function SubmitToEvents()
    if not HarvestEventEnabled.Value then return end
    
    local EventData = PlayerGui:FindFirstChild("HarvestEventUI")
    if not EventData then return end
    
    for _, Item in pairs(GetInvCrops()) do
        -- This would need actual event item detection logic
        if Item.Value > 0 then
            GameEvents.SubmitEventItem:FireServer(Item.Name)
            task.wait(0.2)
        end
    end
end

local function NoclipLoop()
    if not NoClip.Value or not LocalPlayer.Character then return end
    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- UI Creation
local Window = ReGui:Window({
    Title = "Garden Auto-Farm",
    Theme = "MinimalCyan",
    Size = UDim2.fromOffset(300, 450),
    TitleCentered = true
})

-- Status Bar
Window:Label({
    Text = "Status: Ready",
    Centered = true,
    TextSize = 12,
    TextColor = MinimalTheme.ButtonsBg
})

-- Harvest Section
local HarvestSection = Window:TreeNode({
    Title = "HARVEST",
    DefaultOpen = false
})

HarvestSection:Checkbox({
    Label = "Auto-Harvest",
    Value = false,
    Callback = function(_, val) 
        AutoHarvest.Value = val 
        Window:UpdateLabel("Status", "Status: "..(val and "Harvesting" or "Ready"))
    end
})

HarvestSection:Label({Text = "Ignore Types:", Centered = true})

local IgnoreRow = HarvestSection:Horizontal({Ratio = {1, 1, 1}})
IgnoreRow:Checkbox({Label = "Normal", Callback = function(_, val) HarvestIgnores.Normal = val end})
IgnoreRow:Checkbox({Label = "Gold", Callback = function(_, val) HarvestIgnores.Gold = val end})
IgnoreRow:Checkbox({Label = "Rainbow", Callback = function(_, val) HarvestIgnores.Rainbow = val end})

HarvestSection:Checkbox({
    Label = "Auto-Submit Events",
    Value = false,
    Callback = function(_, val) HarvestEventEnabled.Value = val end
})

-- Planting Section
local PlantSection = Window:TreeNode({
    Title = "PLANTING",
    DefaultOpen = false
})

local seedNames = {}
for name,_ in pairs(OwnedSeeds) do table.insert(seedNames, name) end

PlantSection:Combo({
    Label = "Seed Type",
    Selected = "",
    Items = seedNames,
    Callback = function(_, val) SelectedSeed.Selected = val end
})

PlantSection:Checkbox({
    Label = "Auto-Plant",
    Value = false,
    Callback = function(_, val) 
        AutoPlant.Value = val
        Window:UpdateLabel("Status", "Status: "..(val and "Planting" or "Ready"))
    end
})

PlantSection:Checkbox({
    Label = "Random Placement",
    Value = false,
    Callback = function(_, val) AutoPlantRandom.Value = val end
})

-- Settings Section
local SettingsSection = Window:TreeNode({
    Title = "SETTINGS",
    DefaultOpen = false
})

SettingsSection:Checkbox({
    Label = "Enable NoClip",
    Value = false,
    Callback = function(_, val) 
        NoClip.Value = val
        Window:UpdateLabel("Status", "Status: "..(val and "NoClip Active" or "Ready"))
    end
})

SettingsSection:Slider({
    Label = "Sell Threshold: 15",
    Value = 15,
    Min = 1,
    Max = 50,
    Callback = function(_, val) 
        SellThreshold.Value = val
        return "Sell Threshold: "..val
    end
})

SettingsSection:Checkbox({
    Label = "Auto-Sell When Full",
    Value = false,
    Callback = function(_, val) AutoSell.Value = val end
})

-- Main Loop
table.insert(connections, RunService.Stepped:Connect(NoclipLoop))

local function MainLoop()
    while task.wait(1) do
        local status = "Ready"
        
        HarvestAllPlants()
        AutoPlantSeeds()
        SubmitToEvents()
        
        if AutoHarvest.Value then status = "Harvesting" end
        if AutoPlant.Value then status = status.." + Planting" end
        if NoClip.Value then status = status.." (NoClip)" end
        
        Window:UpdateLabel("Status", "Status: "..status)
        
        if AutoSell.Value and #GetInvCrops() >= SellThreshold.Value then
            GameEvents.Sell_Inventory:FireServer()
        end
    end
end

-- Start
MainLoop()

-- Cleanup on script termination
game:GetService("UserInputService").WindowFocused:Connect(function()
    for _, conn in ipairs(connections) do 
        conn:Disconnect() 
    end
end)
