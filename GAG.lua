--[[
    Grow a Garden Auto-Farm Script (Custom UI Version)
    Author: depso (modified by ChatGPT)
]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Backpack = LocalPlayer:WaitForChild("Backpack")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

--// Game folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

--// Globals
local SelectedSeed = ""
local AutoPlant = false
local AutoHarvest = false
local AutoBuy = false
local AutoSell = false
local SellThreshold = 15
local HarvestIgnores = { Normal = false, Gold = false, Rainbow = false }
local SeedStock = {}
local OwnedSeeds = {}
local IsSelling = false

--// Create UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GardenUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(39, 39, 39)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🌱 Grow a Garden Autofarm"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = MainFrame

local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(0, 100, 1, -40)
TabHolder.Position = UDim2.new(0, 0, 0, 40)
TabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabHolder.Parent = MainFrame

local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -100, 1, -40)
PageContainer.Position = UDim2.new(0, 100, 0, 40)
PageContainer.BackgroundTransparency = 1
PageContainer.ClipsDescendants = true
PageContainer.Parent = MainFrame

local function CreateTab(name)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 40)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.Text = name
    Button.Parent = TabHolder

    local Page = Instance.new("Frame")
    Page.Name = name .. "Page"
    Page.Visible = false
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Parent = PageContainer

    Button.MouseButton1Click:Connect(function()
        for _, child in pairs(PageContainer:GetChildren()) do
            if child:IsA("Frame") then
                child.Visible = false
            end
        end
        Page.Visible = true
    end)

    return Page
end

local PlantPage = CreateTab("Auto Plant")
local HarvestPage = CreateTab("Auto Harvest")
local BuyPage = CreateTab("Auto Buy")
local SellPage = CreateTab("Auto Sell")

local PlantToggle = Instance.new("TextButton")
PlantToggle.Size = UDim2.new(0, 150, 0, 30)
PlantToggle.Position = UDim2.new(0, 10, 0, 10)
PlantToggle.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
PlantToggle.Text = "Auto Plant: OFF"
PlantToggle.TextColor3 = Color3.new(1, 1, 1)
PlantToggle.Font = Enum.Font.Gotham
PlantToggle.TextSize = 14
PlantToggle.Parent = PlantPage

PlantToggle.MouseButton1Click:Connect(function()
    AutoPlant = not AutoPlant
    PlantToggle.Text = "Auto Plant: " .. (AutoPlant and "ON" or "OFF")
end)

local HarvestToggle = Instance.new("TextButton")
HarvestToggle.Size = UDim2.new(0, 150, 0, 30)
HarvestToggle.Position = UDim2.new(0, 10, 0, 10)
HarvestToggle.BackgroundColor3 = Color3.fromRGB(200, 100, 40)
HarvestToggle.Text = "Auto Harvest: OFF"
HarvestToggle.TextColor3 = Color3.new(1, 1, 1)
HarvestToggle.Font = Enum.Font.Gotham
HarvestToggle.TextSize = 14
HarvestToggle.Parent = HarvestPage

HarvestToggle.MouseButton1Click:Connect(function()
    AutoHarvest = not AutoHarvest
    HarvestToggle.Text = "Auto Harvest: " .. (AutoHarvest and "ON" or "OFF")
end)

--// Core autofarm functions
local function GetFarm(PlayerName)
    for _, Farm in pairs(Farms:GetChildren()) do
        if Farm.Important.Data.Owner.Value == PlayerName then
            return Farm
        end
    end
end

local function Plant(Position, Seed)
    GameEvents.Plant_RE:FireServer(Position, Seed)
end

local function AutoPlantLoop()
    if SelectedSeed == "" then return end
    local MyFarm = GetFarm(LocalPlayer.Name)
    if not MyFarm then return end
    local Locations = MyFarm.Important.Plant_Locations:GetChildren()
    for _, loc in pairs(Locations) do
        local pos = loc.Position + Vector3.new(math.random(-2,2), 0, math.random(-2,2))
        Plant(pos, SelectedSeed)
    end
end

local function HarvestPlants()
    local MyFarm = GetFarm(LocalPlayer.Name)
    local Plants = MyFarm.Important.Plants_Physical:GetChildren()
    for _, plant in pairs(Plants) do
        local prompt = plant:FindFirstChild("ProximityPrompt", true)
        if prompt and prompt.Enabled then
            fireproximityprompt(prompt)
        end
    end
end

spawn(function()
    while task.wait(1) do
        if AutoPlant then AutoPlantLoop() end
        if AutoHarvest then HarvestPlants() end
    end
end)

print("✅ Custom UI loaded. You may expand other tabs with similar elements.")
