-- UI Library (keep your existing ReGui initialization)
local Window = ReGui:Window({
    Title = "🌱 Garden Automator Pro",
    Theme = "GardenTheme",
    Size = UDim2.fromOffset(400, 550),
    Position = UDim2.fromScale(0.5, 0.5) -- Center the window
})

-- Status Bar (shows current actions)
local StatusBar = Window:StatusBar({
    Text = "🟢 Ready | Seeds: 0 | Crops: 0",
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Main Tabs
local MainTab = Window:Tab({
    Title = "Main Controls",
    Icon = "📊"
})

local FarmingTab = Window:Tab({
    Title = "Farming",
    Icon = "🌾"
})

local ShopTab = Window:Tab({
    Title = "Shop",
    Icon = "🛒"
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "⚙️"
})

-- Main Tab Content
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

-- Farming Tab Content
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
    Items = {"Carrot Seed", "Blueberry Seed", "Pumpkin Seed", "Tomato Seed"}, -- Should be dynamic
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

-- Shop Tab Content
ShopTab:Checkbox({
    Label = "🔄 Auto-Buy Seeds",
    Value = false,
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

-- Settings Tab Content
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
    
    -- Update money and XP labels if available
    if Leaderstats and Leaderstats:FindFirstChild("Money") then
        MoneyLabel:SetText(string.format("💰 Money: $%d", Leaderstats.Money.Value))
    end
    
    if Leaderstats and Leaderstats:FindFirstChild("XP") then
        XPLabel:SetText(string.format("⭐ XP: %d", Leaderstats.XP.Value))
    end
end

-- Add this to your main loop
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
