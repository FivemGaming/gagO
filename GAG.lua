--[[
    Grow a Garden Auto-Farm Script (Rayfield UI Version)
    Author: depso (modified by ChatGPT)
]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

--// Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Grow a Garden | Depso",
	LoadingTitle = "Grow a Garden",
	LoadingSubtitle = "by depso",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "GrowAGardenAutoFarm",
		FileName = "settings"
	},
	Discord = { Enabled = false },
	KeySystem = false
})

--// Game folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

--// Globals
local SelectedSeed = { Selected = "" }
local SelectedSeedStock = { Selected = "" }
local AutoPlant = { Value = false }
local AutoPlantRandom = { Value = false }
local AutoHarvest = { Value = false }
local AutoBuy = { Value = false }
local AutoSell = { Value = false }
local SellThreshold = { Value = 15 }
local AutoWalk = { Value = false }
local AutoWalkAllowRandom = { Value = true }
local AutoWalkMaxWait = { Value = 10 }
local NoClip = { Value = false }

local HarvestIgnores = {
	Normal = false,
	Gold = false,
	Rainbow = false
}

local SeedStock = {}
local OwnedSeeds = {}
local IsSelling = false

--// Function helpers
local function Plant(Position, Seed)
	GameEvents.Plant_RE:FireServer(Position, Seed)
	wait(0.3)
end

local function GetFarms()
	return Farms:GetChildren()
end

local function GetFarmOwner(Farm)
	return Farm.Important.Data.Owner.Value
end

local function GetFarm(PlayerName)
	for _, Farm in pairs(GetFarms()) do
		if GetFarmOwner(Farm) == PlayerName then
			return Farm
		end
	end
end

local function SellInventory()
	if IsSelling then return end
	IsSelling = true

	local Character = LocalPlayer.Character
	local Previous = Character:GetPivot()
	local PreviousSheckles = ShecklesCount.Value
	Character:PivotTo(CFrame.new(62, 4, -26))

	repeat
		GameEvents.Sell_Inventory:FireServer()
		wait()
	until ShecklesCount.Value ~= PreviousSheckles

	Character:PivotTo(Previous)
	wait(0.2)
	IsSelling = false
end

local function BuySeed(Seed)
	GameEvents.BuySeedStock:FireServer(Seed)
end

local function BuyAllSelectedSeeds()
	local Seed = SelectedSeedStock.Selected
	local Stock = SeedStock[Seed]
	if not Stock or Stock <= 0 then return end
	for i = 1, Stock do BuySeed(Seed) end
end

local function GetSeedStock(ignoreZero)
	local SeedShop = PlayerGui.Seed_Shop
	local Items = SeedShop:FindFirstChild("Blueberry", true).Parent
	local list = {}

	for _, Item in pairs(Items:GetChildren()) do
		local StockText = Item.Main_Frame and Item.Main_Frame.Stock_Text.Text
		local StockCount = tonumber(StockText and StockText:match("%d+")) or 0
		if ignoreZero and StockCount <= 0 then continue end
		SeedStock[Item.Name] = StockCount
		list[#list+1] = Item.Name
	end
	return list
end

local function AutoPlantLoop()
	local Seed = SelectedSeed.Selected
	local Tool = OwnedSeeds[Seed] and OwnedSeeds[Seed].Tool
	local Count = OwnedSeeds[Seed] and OwnedSeeds[Seed].Count or 0
	if not Tool or Count <= 0 then return end

	local MyFarm = GetFarm(LocalPlayer.Name)
	local PlantLocations = MyFarm.Important.Plant_Locations
	local FarmLands = PlantLocations:GetChildren()

	for i = 1, Count do
		local Land = FarmLands[math.random(1, #FarmLands)]
		local Size = Land.Size
		local CFrame = Land.CFrame
		local pos = CFrame.Position + Vector3.new(math.random(-Size.X/2, Size.X/2), 0.1, math.random(-Size.Z/2, Size.Z/2))
		Plant(pos, Seed)
	end
end

local function HarvestPlants()
	local MyFarm = GetFarm(LocalPlayer.Name)
	local Plants = MyFarm.Important.Plants_Physical:GetChildren()
	for _, plant in pairs(Plants) do
		local prompt = plant:FindFirstChild("ProximityPrompt", true)
		local variant = plant:FindFirstChild("Variant")
		if prompt and prompt.Enabled and (not variant or not HarvestIgnores[variant.Value]) then
			fireproximityprompt(prompt)
		end
	end
end

--// Tabs and UI
local AutoPlantTab = Window:CreateTab("🌱 Auto Plant")
local SelectedSeedDropdown = AutoPlantTab:CreateDropdown({
	Name = "Select Seed",
	Options = {"Loading..."},
	CurrentOption = "",
	Callback = function(Value) SelectedSeed.Selected = Value end
})
AutoPlantTab:CreateToggle({Name = "Enable Auto Plant", CurrentValue = false, Callback = function(v) AutoPlant.Value = v end})
AutoPlantTab:CreateToggle({Name = "Plant at Random Points", CurrentValue = false, Callback = function(v) AutoPlantRandom.Value = v end})
AutoPlantTab:CreateButton({Name = "Plant All Now", Callback = AutoPlantLoop})

local HarvestTab = Window:CreateTab("🚜 Auto Harvest")
HarvestTab:CreateToggle({Name = "Enable Auto Harvest", CurrentValue = false, Callback = function(v) AutoHarvest.Value = v end})
for k, _ in pairs(HarvestIgnores) do
	HarvestTab:CreateToggle({Name = "Ignore " .. k, CurrentValue = false, Callback = function(v) HarvestIgnores[k] = v end})
end

local BuyTab = Window:CreateTab("🛒 Auto Buy")
local BuySeedDropdown = BuyTab:CreateDropdown({
	Name = "Seed to Buy",
	Options = {"Loading..."},
	CurrentOption = "",
	Callback = function(v) SelectedSeedStock.Selected = v end
})
BuyTab:CreateToggle({Name = "Enable Auto Buy", CurrentValue = false, Callback = function(v) AutoBuy.Value = v end})
BuyTab:CreateButton({Name = "Buy All", Callback = BuyAllSelectedSeeds})

local SellTab = Window:CreateTab("💰 Auto Sell")
SellTab:CreateButton({Name = "Sell Inventory", Callback = SellInventory})
SellTab:CreateToggle({Name = "Enable Auto Sell", CurrentValue = false, Callback = function(v) AutoSell.Value = v end})
SellTab:CreateSlider({Name = "Sell Threshold", Range = {1, 200}, Increment = 1, CurrentValue = 15, Callback = function(v) SellThreshold.Value = v end})

--// Update UI dynamically
spawn(function()
	while wait(5) do
		local stockList = GetSeedStock(true)
		SelectedSeedDropdown:Refresh(stockList, true)
		BuySeedDropdown:Refresh(stockList, true)
	end
end)

--// Background loops
spawn(function()
	while wait(1) do
		if AutoPlant.Value then AutoPlantLoop() end
		if AutoHarvest.Value then HarvestPlants() end
		if AutoBuy.Value then BuyAllSelectedSeeds() end
		if AutoSell.Value and #Backpack:GetChildren() >= SellThreshold.Value then SellInventory() end
	end
end)

RunService.Stepped:Connect(function()
	if NoClip.Value then
		for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end
end)
