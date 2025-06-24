--[[
    Grow a Garden Auto-Farm Script v2.0
    Features:
    - Modern, organized UI with status tracking
    - Remote harvesting (no movement)
    - Smart auto-planting with seed tracking
    - Auto-submit to events
    - Shop automation (buy all seeds)
    - Inventory management with auto-sell
    - NoClip support
    - Performance controls
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Player References
local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Backpack = LocalPlayer:WaitForChild("Backpack")

-- Constants
local Accent = {
    DarkGreen = Color3.fromRGB(45, 95, 25),
    Green = Color3.fromRGB(69, 142, 40),
    Brown = Color3.fromRGB(26, 20, 8),
}

-- Core Variables
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Farms = workspace:WaitForChild("Farm")
local MyFarm = Farms:WaitForChild(LocalPlayer.Name)
local PlantLocations = MyFarm:WaitForChild("Important"):WaitForChild("Plant_Locations")
local PlantsPhysical = MyFarm:WaitForChild("Important"):WaitForChild("Plants_Physical")

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
local AutoBuySeeds = {Value = false}
local BuyPriority = "Cheapest First"
local HarvestDelay = 0.05

-- Seed Tracking
local SeedStock = {}
local OwnedSeeds = {}

-- UI Library
local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
ReGui:Init()
ReGui:DefineTheme("GardenTheme", {
    WindowBg = Accent.Brown,
    TitleBarBg = Accent.DarkGreen,
    FrameBg = Accent.DarkGreen,
    ButtonsBg = Accent.Green,
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

local function GetInvCrops()
    local crops = {}
    if Backpack then
        for _, item in ipairs(Backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(crops, item)
            end
        end
    end
    return crops
end

local function GetSeedCount()
    local count = 0
    for _, seed in pairs(OwnedSeeds) do
        count = count + (seed.Count or 0)
    end
    return count
end

local function GetCropCount()
    return #GetInvCrops()
end

local function UpdateSeedList()
    -- This should be implemented to get actual seed data from the game
    -- Placeholder implementation
    OwnedSeeds = {
        ["Carrot Seed"] = {Count = 5},
        ["Blueberry Seed"] = {Count = 3},
        ["Pumpkin Seed"] = {Count = 2}
    }
end

-- Remote Harvest Function
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
                task.wait(HarvestDelay)
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
        -- Grid planting logic would go here
        GameEvents.Plant_RE:FireServer(GetRandomFarmPoint(), Seed)
        task.wait(0.1)
    end
end

-- Auto-Submit to Events
local function SubmitToEvents()
    if not HarvestEventEnabled.Value then return end
    
    local EventData = PlayerGui:FindFirstChild("HarvestEventUI")
    if not EventData then return end
    
    -- Get required items from event UI
    local RequiredItems = {"Apple", "Carrot"} -- Should parse from actual UI
    
    -- Submit each matching item
    for _, Item in pairs(GetInvCrops()) do
        if table.find(RequiredItems, Item.Name) then
            GameEvents.SubmitEventItem:FireServer(Item.Name)
            task.wait(0.2)
        end
    end
end

-- Shop Functions
local function BuyAllSeeds()
    if not AutoBuySeeds.Value then return end
    
    local Shop = ReplicatedStorage:FindFirstChild("Shop") or workspace:FindFirstChild("Shop")
    if not Shop then return end
    
    -- Placeholder seed list - should be populated from actual game data
    local SeedTypes = {"Carrot Seed", "Blueberry Seed", "Pumpkin Seed"}
    
    for _, seedName in ipairs(SeedTypes) do
        local seed = Shop:FindFirstChild(seedName)
        if seed then
            pcall(function()
                GameEvents.BuyItem:FireServer(seedName)
                task.wait(0.2)
            end)
        end
    end
end

-- NoClip Function
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
    Title = "🌱 Garden Automator Pro",
    Theme = "GardenTheme",
    Size = UDim2.fromOffset(400, 550),
    Position = UDim2.fromScale(0.5, 0.5)
})

-- Status Bar
local StatusBar = Window:StatusBar({
    Text = "🟢 Ready | Seeds: 0 | Crops: 0",
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Main Tab
local MainTab = Window:Tab({
    Title = "Main Controls",
    Icon = "📊"
})

MainTab:Label({
    Text = "Garden Automator Pro v2.0",
    TextSize = 18,
    TextColor = Accent.Green,
    CenterText = true
})

MainTab:Separator({Text = "Quick Actions"})

local StartAll = MainTab:Button({
    Label = "▶️ Start All Automation",
    Callback = function()
        AutoHarvest.Value = true
        AutoPlant.Value = true
        AutoSell.Value = true
        HarvestEventEnabled.Value = true
        AutoBuySeeds.Value = true
        ReGui:Notify("All automation features enabled!")
    end
})

local StopAll = MainTab:Button({
    Label = "⏹️ Stop All Automation",
    Callback = function()
        AutoHarvest.Value = false
        AutoPlant.Value = false
        AutoSell.Value = false
        HarvestEventEnabled.Value = false
        AutoBuySeeds.Value = false
        ReGui:Notify("All automation features disabled!")
    end
})

MainTab:Separator({Text = "Statistics"})

local MoneyLabel = MainTab:Label({
    Text = "💰 Money: $0",
    TextSize = 14
})

local XPLabel = MainTab:Label({
    Text = "⭐ XP: 0",
    TextSize = 14
})

-- Farming Tab
local FarmingTab = Window:Tab({
    Title = "Farming",
    Icon = "🌾"
})

FarmingTab:Checkbox({
    Label = "🌻 Auto-Harvest Plants",
    Value = AutoHarvest.Value,
    Callback = function(_, val) AutoHarvest.Value = val end
})

FarmingTab:Dropdown({
    Label = "Harvest Filter",
    Items = {"All Plants", "Normal Only", "Gold Only", "Rainbow Only", "Custom"},
    Callback = function(_, val)
        if val == "All Plants" then
            HarvestIgnores.Normal = false
            HarvestIgnores.Gold = false
            HarvestIgnores.Rainbow = false
        elseif val == "Normal Only" then
            HarvestIgnores.Normal = false
            HarvestIgnores.Gold = true
            HarvestIgnores.Rainbow = true
        elseif val == "Gold Only" then
            HarvestIgnores.Normal = true
            HarvestIgnores.Gold = false
            HarvestIgnores.Rainbow = true
        elseif val == "Rainbow Only" then
            HarvestIgnores.Normal = true
            HarvestIgnores.Gold = true
            HarvestIgnores.Rainbow = false
        end
    end
})

FarmingTab:Separator({Text = "Planting"})

local SeedDropdown = FarmingTab:Dropdown({
    Label = "🌱 Select Seed",
    Items = {"Carrot Seed", "Blueberry Seed", "Pumpkin Seed", "Tomato Seed"},
    Callback = function(_, val) SelectedSeed.Selected = val end
})

FarmingTab:Checkbox({
    Label = "🔄 Auto-Plant Selected Seed",
    Value = AutoPlant.Value,
    Callback = function(_, val) AutoPlant.Value = val end
})

FarmingTab:Checkbox({
    Label = "🎲 Random Placement",
    Value = AutoPlantRandom.Value,
    Callback = function(_, val) AutoPlantRandom.Value = val end
})

FarmingTab:Checkbox({
    Label = "🏆 Auto-Submit to Events",
    Value = HarvestEventEnabled.Value,
    Callback = function(_, val) HarvestEventEnabled.Value = val end
})

-- Shop Tab
local ShopTab = Window:Tab({
    Title = "Shop",
    Icon = "🛒"
})

ShopTab:Checkbox({
    Label = "🔄 Auto-Buy Seeds",
    Value = AutoBuySeeds.Value,
    Callback = function(_, val) AutoBuySeeds.Value = val end
})

ShopTab:Dropdown({
    Label = "💵 Buy Priority",
    Items = {"Cheapest First", "Most Needed", "Random", "Highest Value"},
    Callback = function(_, val) BuyPriority = val end
})

ShopTab:Button({
    Label = "🛒 Buy All Seeds Now",
    Callback = function()
        BuyAllSeeds()
        ReGui:Notify("Purchased all available seeds!")
    end
})

ShopTab:Separator({Text = "Seed Inventory"})

local SeedInventoryFrame = ShopTab:Frame({
    Size = UDim2.new(1, 0, 0, 150)
})

-- Settings Tab
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "⚙️"
})

SettingsTab:Checkbox({
    Label = "👻 NoClip Mode",
    Value = NoClip.Value,
    Callback = function(_, val) NoClip.Value = val end
})

SettingsTab:Slider({
    Label = "📦 Auto-Sell Threshold",
    Value = SellThreshold.Value,
    Min = 1,
    Max = 100,
    Callback = function(_, val) SellThreshold.Value = val end
})

SettingsTab:Checkbox({
    Label = "💰 Auto-Sell When Full",
    Value = AutoSell.Value,
    Callback = function(_, val) AutoSell.Value = val end
})

SettingsTab:Separator({Text = "Performance"})

SettingsTab:Slider({
    Label = "⚡ Harvest Speed",
    Value = 5,
    Min = 1,
    Max = 10,
    Callback = function(_, val) HarvestDelay = 0.1 / val end
})

SettingsTab:Button({
    Label = "🔄 Refresh Seed List",
    Callback = function()
        UpdateSeedList()
        ReGui:Notify("Seed list refreshed!")
    end
})

-- Update function for the status bar
local function UpdateStatus()
    local statusText = AutoHarvest.Value and "🟢 Running" or "🔴 Stopped"
    local seedCount = GetSeedCount()
    local cropCount = GetCropCount()
    
    StatusBar:SetText(string.format("%s | Seeds: %d | Crops: %d", statusText, seedCount, cropCount))
    
    if Leaderstats and Leaderstats:FindFirstChild("Money") then
        MoneyLabel:SetText(string.format("💰 Money: $%d", Leaderstats.Money.Value))
    end
    
    if Leaderstats and Leaderstats:FindFirstChild("XP") then
        XPLabel:SetText(string.format("⭐ XP: %d", Leaderstats.XP.Value))
    end
end

-- Initialize seed list
UpdateSeedList()

-- Start Services
RunService.Stepped:Connect(NoclipLoop)

-- Main Loop
while task.wait(1) do
    HarvestAllPlants()
    AutoPlantSeeds()
    SubmitToEvents()
    BuyAllSeeds()
    UpdateStatus()
    
    if AutoSell.Value and #GetInvCrops() >= SellThreshold.Value then
        GameEvents.Sell_Inventory:FireServer()
    end
end
