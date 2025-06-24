--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")

--// Load ReGui
local ReGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua"))()
ReGui:Init()

--// UI
local Window = ReGui:Window({
    Title = "Grow a Garden Auto UI",
    Size = UDim2.fromOffset(300, 200)
})

--// Auto-Toggles
local Flags = {
    AutoBuySeeds = false,
    AutoBuyGear = false,
    AutoBuyEggs = false,
    AutoPlant = false,
    AutoHarvest = false,
}

--// Automation Functions
local function BuySeed()
    GameEvents.BuySeedStock:FireServer("Carrot") -- Replace "Carrot" with desired seed
end

local function BuyGear()
    GameEvents.BuyGear:FireServer("Watering_Can") -- Replace with actual gear name
end

local function BuyEgg()
    GameEvents.BuyPet:FireServer("Basic_Egg") -- Replace with actual egg name
end

local function PlantAll()
    local farm = workspace.Farm:FindFirstChild(LocalPlayer.Name)
    if not farm then return end
    local locations = farm.Important:WaitForChild("Plant_Locations")
    for _, plot in ipairs(locations:GetChildren()) do
        GameEvents.Plant_RE:FireServer(plot.Position, "Carrot") -- Replace with your seed
        wait(0.1)
    end
end

local function HarvestAll()
    local plants = workspace.Farm:FindFirstChild(LocalPlayer.Name).Important.Plants_Physical
    for _, plant in ipairs(plants:GetDescendants()) do
        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Enabled then
            fireproximityprompt(prompt)
            wait(0.1)
        end
    end
end

--// Background Loops
task.spawn(function()
    while task.wait(2) do
        if Flags.AutoBuySeeds then BuySeed() end
        if Flags.AutoBuyGear then BuyGear() end
        if Flags.AutoBuyEggs then BuyEgg() end
    end
end)

task.spawn(function()
    while task.wait(4) do
        if Flags.AutoPlant then PlantAll() end
        if Flags.AutoHarvest then HarvestAll() end
    end
end)

--// UI Elements
local BuyTab = Window:TreeNode({Title = "Auto Buy"})
BuyTab:Checkbox({
    Label = "Seeds",
    Value = false,
    Callback = function(_, v) Flags.AutoBuySeeds = v end
})
BuyTab:Checkbox({
    Label = "Gear",
    Value = false,
    Callback = function(_, v) Flags.AutoBuyGear = v end
})
BuyTab:Checkbox({
    Label = "Pet Eggs",
    Value = false,
    Callback = function(_, v) Flags.AutoBuyEggs = v end
})

local PlantTab = Window:TreeNode({Title = "Auto Farm"})
PlantTab:Checkbox({
    Label = "Auto Plant",
    Value = false,
    Callback = function(_, v) Flags.AutoPlant = v end
})
PlantTab:Checkbox({
    Label = "Auto Harvest",
    Value = false,
    Callback = function(_, v) Flags.AutoHarvest = v end
})
