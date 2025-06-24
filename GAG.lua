--[[
    Grow a Garden Auto-Farm Script
    Features:
    - Remote harvesting (no movement)
    - Auto-planting
    - Auto-submit to events
    - Smart inventory management
    - NoClip support
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack

-- Constants
local Accent = {
    DarkGreen = Color3.fromRGB(45, 95, 25),
    Green = Color3.fromRGB(69, 142, 40),
    Brown = Color3.fromRGB(26, 20, 8),
}

-- Core Variables
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm
local MyFarm = Farms:FindFirstChild(LocalPlayer.Name)
local PlantLocations = MyFarm.Important.Plant_Locations
local PlantsPhysical = MyFarm.Important.Plants_Physical

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
local OwnedSeeds = {}

-- UI Library
local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
ReGui:Init()
-- UI Theme: Dark Orange Theme (Inspired by bold contrasts)
ReGui:DefineTheme("DarkOrangeTheme", {
    WindowBg = Color3.fromRGB(15, 15, 15),       -- Deep black
    TitleBarBg = Color3.fromRGB(30, 30, 30),     -- Dark gray
    FrameBg = Color3.fromRGB(20, 20, 20),        -- Mid-dark gray
    ButtonsBg = Color3.fromRGB(255, 102, 0),     -- Bright orange
    TextColor = Color3.fromRGB(255, 255, 255),   -- White text
})


-- Core Functions
local function GetFarmArea()
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

-- Remote Harvest Function (NEW)
local function RemoteHarvestPlant(Plant)
    -- Method 1: Try known harvest event
    local success, err = pcall(function()
        GameEvents.HarvestPlant_RE:FireServer(Plant:GetPivot().Position)
    end)
    
    -- Method 2: Fallback to proximity prompt
    if not success then
        local Prompt = Plant:FindFirstChildOfClass("ProximityPrompt")
        if Prompt then
            fireproximityprompt(Prompt)
        end
    end
end

local function HarvestAllPlants()
    if not AutoHarvest.Value then return end
    
    for _, Plant in pairs(PlantsPhysical:GetDescendants()) do
        if Plant:IsA("Model") and Plant:FindFirstChild("Fruits") then
            local Variant = Plant:FindFirstChild("Variant")
            if not Variant or not HarvestIgnores[Variant.Value] then
                RemoteHarvestPlant(Plant)
                task.wait(0.05) -- Fast but safe delay
            end
        end
    end
end

-- Auto-Plant Function
local function AutoPlantSeeds()
    if not AutoPlant.Value then return end
    
    local Seed = SelectedSeed.Selected
    if not Seed or Seed == "" then return end
    
    local SeedData = OwnedSeeds[Seed]
    if not SeedData or SeedData.Count <= 0 then return end

    if AutoPlantRandom.Value then
        for _ = 1, SeedData.Count do
            GameEvents.Plant_RE:FireServer(GetRandomFarmPoint(), Seed)
            task.wait(0.1)
        end
    else
        -- Grid planting logic...
    end
end

-- Auto-Submit to Events (NEW)
local function SubmitToEvents()
    if not HarvestEventEnabled.Value then return end
    
    local EventData = PlayerGui:FindFirstChild("HarvestEventUI")
    if not EventData then return end
    
    -- Get required items from event UI (example)
    local RequiredItems = {"Apple", "Carrot"} -- Would parse from UI
    
    -- Submit each matching item
    for _, Item in pairs(GetInvCrops()) do
        if table.find(RequiredItems, Item.Name) then
            GameEvents.SubmitEventItem:FireServer(Item.Name)
            task.wait(0.2)
        end
    end
end

-- Main Loops
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
    Title = "Grow a Garden Auto-Farm",
    Theme = "DarkOrangeTheme",
    Size = UDim2.fromOffset(350, 500)
})

-- Harvest Tab
local HarvestTab = Window:TreeNode({Title = "Harvesting"})
HarvestTab:Checkbox({
    Label = "Auto-Harvest",
    Value = false,
    Callback = function(_, val) AutoHarvest.Value = val end
})

HarvestTab:Separator({Text = "Ignore Types:"})
for variant, _ in pairs(HarvestIgnores) do
    HarvestTab:Checkbox({
        Label = variant,
        Value = false,
        Callback = function(_, val) HarvestIgnores[variant] = val end
    })
end

HarvestTab:Checkbox({
    Label = "Auto-Submit to Events",
    Value = false,
    Callback = function(_, val) HarvestEventEnabled.Value = val end
})

-- Plant Tab
local PlantTab = Window:TreeNode({Title = "Planting"})
PlantTab:Combo({
    Label = "Seed Type",
    Selected = "",
    Items = {"Carrot", "Blueberry", "Pumpkin"}, -- Would be dynamic
    Callback = function(_, val) SelectedSeed.Selected = val end
})

PlantTab:Checkbox({
    Label = "Auto-Plant",
    Value = false,
    Callback = function(_, val) AutoPlant.Value = val end
})

PlantTab:Checkbox({
    Label = "Random Placement",
    Value = false,
    Callback = function(_, val) AutoPlantRandom.Value = val end
})

-- Settings Tab
local SettingsTab = Window:TreeNode({Title = "Settings"})
SettingsTab:Checkbox({
    Label = "NoClip",
    Value = false,
    Callback = function(_, val) NoClip.Value = val end
})

SettingsTab:Slider({
    Label = "Sell Threshold",
    Value = 15,
    Min = 1,
    Max = 50,
    Callback = function(_, val) SellThreshold.Value = val end
})

-- Start Services
RunService.Stepped:Connect(NoclipLoop)

while task.wait(1) do
    HarvestAllPlants()
    AutoPlantSeeds()
    SubmitToEvents()
    
    -- Auto-sell when inventory full
    if AutoSell.Value and #GetInvCrops() >= SellThreshold.Value then
        GameEvents.Sell_Inventory:FireServer()
    end
end
