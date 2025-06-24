--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Backpack = LocalPlayer:WaitForChild("Backpack")
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")

--// LOAD ReGui
local ReGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua"))()
ReGui:Init()

--// UI WINDOW
local Window = ReGui:Window({
    Title = "Grow a Garden - AutoFarm UI",
    Size = UDim2.fromOffset(300, 230)
})

--// TOGGLES
local AutoBuySeeds = false
local AutoBuyGear = false
local AutoBuyEggs = false
local AutoPlant = false
local AutoHarvest = false

--// AUTO FUNCTIONS
local function BuySeed()
    GameEvents.BuySeedStock:FireServer("Carrot") -- change to your preferred seed
end

local function BuyGear()
    GameEvents.BuyGear:FireServer("Watering_Can") -- example gear
end

local function BuyPetEgg()
    GameEvents.BuyPet:FireServer("Basic_Egg") -- replace with valid egg name
end

local function PlantAll()
    local Farm = workspace.Farm:FindFirstChild(LocalPlayer.Name)
    if not Farm then return end

    local Locations = Farm.Important:WaitForChild("Plant_Locations")
    for _, spot in ipairs(Locations:GetChildren()) do
        GameEvents.Plant_RE:FireServer(spot.Position, "Carrot") -- change to your seed
        wait(0.1)
    end
end

local function HarvestAll()
    local Plants = workspace.Farm:FindFirstChild(LocalPlayer.Name).Important.Plants_Physical
    for _, plant in ipairs(Plants:GetDescendants()) do
        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Enabled then
            fireproximityprompt(prompt)
            wait(0.1)
        end
    end
end

--// THREADS
task.spawn(function()
    while task.wait(2) do
        if AutoBuySeeds then BuySeed() end
        if AutoBuyGear then BuyGear() end
        if AutoBuyEggs then BuyPetEgg() end
    end
end)

task.spawn(function()
    while task.wait(5) do
        if AutoPlant then PlantAll() end
        if AutoHarvest then HarvestAll() end
    end
end)

--// UI NODES
local BuyNode = Window:TreeNode({Title = "Auto Buy 🛒"})
BuyNode:Checkbox({
    Label = "Seeds",
    Value = false,
    Callback = function(_, val) AutoBuySeeds = val end
})
BuyNode:Checkbox({
    Label = "Gear",
    Value = false,
    Callback = function(_, val) AutoBuyGear = val end
})
BuyNode:Checkbox({
    Label = "Pet Eggs",
    Value = false,
    Callback = function(_, val) AutoBuyEggs = val end
})

local FarmNode = Window:TreeNode({Title = "Auto Farm 🌱"})
FarmNode:Checkbox({
    Label = "Plant Seeds",
    Value = false,
    Callback = function(_, val) AutoPlant = val end
})
FarmNode:Checkbox({
    Label = "Harvest",
    Value = false,
    Callback = function(_, val) AutoHarvest = val end
})
