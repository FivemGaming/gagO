--[[ 
    Grow a Garden Auto-Farm (Full Custom UI Version) 
    Author: depso (modded by ChatGPT) 
]]

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")

local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

--// Autofarm Globals
local AutoPlant = false
local AutoHarvest = false
local SelectedSeeds = {}
local IsSelling = false

--// UI Setup
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "GardenUI"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🌿 Grow a Garden Autofarm"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.new(1, 1, 1)

local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Size = UDim2.new(0, 120, 1, -40)
TabHolder.Position = UDim2.new(0, 0, 0, 40)
TabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Size = UDim2.new(1, -120, 1, -40)
PageContainer.Position = UDim2.new(0, 120, 0, 40)
PageContainer.BackgroundTransparency = 1

--// Tab Creation
local function CreateTab(name)
	local Button = Instance.new("TextButton", TabHolder)
	Button.Size = UDim2.new(1, 0, 0, 40)
	Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.Font = Enum.Font.Gotham
	Button.TextSize = 14
	Button.Text = name

	local Page = Instance.new("Frame", PageContainer)
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BackgroundTransparency = 1
	Page.Visible = false

	Button.MouseButton1Click:Connect(function()
		for _, page in ipairs(PageContainer:GetChildren()) do
			if page:IsA("Frame") then page.Visible = false end
		end
		Page.Visible = true
	end)

	return Page
end

local PlantPage = CreateTab("Auto Plant")
local HarvestPage = CreateTab("Auto Harvest")
local SellPage = CreateTab("Auto Sell")

--// Get Farm
local function GetFarm(PlayerName)
	for _, Farm in pairs(Farms:GetChildren()) do
		if Farm.Important.Data.Owner.Value == PlayerName then
			return Farm
		end
	end
end

--// Autofarm Logic
local function Plant(pos, seed)
	GameEvents.Plant_RE:FireServer(pos, seed)
end

local function AutoPlantLoop()
	local farm = GetFarm(LocalPlayer.Name)
	if not farm then return end

	local locations = farm.Important.Plant_Locations:GetChildren()
	local seeds = {}
	for name in pairs(SelectedSeeds) do table.insert(seeds, name) end
	if #seeds == 0 then return end

	local index = 1
	for _, spot in pairs(locations) do
		local seed = seeds[index]
		local pos = spot.Position + Vector3.new(math.random(-2,2), 0, math.random(-2,2))
		Plant(pos, seed)
		index = (index % #seeds) + 1
	end
end

local function HarvestPlants()
	local farm = GetFarm(LocalPlayer.Name)
	if not farm then return end
	local plants = farm.Important.Plants_Physical:GetChildren()

	for _, plant in ipairs(plants) do
		local prompt = plant:FindFirstChild("ProximityPrompt", true)
		if prompt and prompt.Enabled then
			fireproximityprompt(prompt)
		end
	end
end

--// Toggles
local function CreateToggle(parent, labelText, default, callback, posY)
	local Toggle = Instance.new("TextButton", parent)
	Toggle.Size = UDim2.new(0, 150, 0, 30)
	Toggle.Position = UDim2.new(0, 10, 0, posY)
	Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	Toggle.TextColor3 = Color3.new(1, 1, 1)
	Toggle.Font = Enum.Font.Gotham
	Toggle.TextSize = 14
	Toggle.Text = labelText .. ": " .. (default and "ON" or "OFF")

	local state = default
	Toggle.MouseButton1Click:Connect(function()
		state = not state
		Toggle.Text = labelText .. ": " .. (state and "ON" or "OFF")
		callback(state)
	end)
end

-- Auto Plant Toggle
CreateToggle(PlantPage, "Auto Plant", false, function(val)
	AutoPlant = val
end, 10)

-- Auto Harvest Toggle
CreateToggle(HarvestPage, "Auto Harvest", false, function(val)
	AutoHarvest = val
end, 10)

-- Seed Multi-Select Dropdown
local function GetSeedTools()
	local seeds = {}
	for _, container in pairs({Backpack, Character}) do
		for _, tool in ipairs(container:GetChildren()) do
			local plantName = tool:FindFirstChild("Plant_Name")
			if plantName then
				local name = plantName.Value
				seeds[name] = tool
			end
		end
	end
	return seeds
end

local SeedLabel = Instance.new("TextLabel", PlantPage)
SeedLabel.Size = UDim2.new(0, 300, 0, 20)
SeedLabel.Position = UDim2.new(0, 10, 0, 50)
SeedLabel.Text = "Select Seeds:"
SeedLabel.TextColor3 = Color3.new(1, 1, 1)
SeedLabel.Font = Enum.Font.GothamBold
SeedLabel.TextSize = 14
SeedLabel.BackgroundTransparency = 1
SeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local Scroll = Instance.new("ScrollingFrame", PlantPage)
Scroll.Size = UDim2.new(0, 300, 0, 120)
Scroll.Position = UDim2.new(0, 10, 0, 75)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness = 6
Scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Scroll.BorderSizePixel = 0

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 4)

local function RefreshSeedButtons()
	for _, child in pairs(Scroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local seeds = GetSeedTools()
	for name, tool in pairs(seeds) do
		local Button = Instance.new("TextButton", Scroll)
		Button.Size = UDim2.new(1, -8, 0, 25)
		Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		Button.TextColor3 = Color3.new(1, 1, 1)
		Button.Font = Enum.Font.Gotham
		Button.TextSize = 13
		Button.Text = "[OFF] " .. name

		Button.MouseButton1Click:Connect(function()
			if SelectedSeeds[name] then
				SelectedSeeds[name] = nil
				Button.Text = "[OFF] " .. name
				Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			else
				SelectedSeeds[name] = tool
				Button.Text = "[ON] " .. name
				Button.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
			end
		end)
	end

	task.wait(0.2)
	Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
end

task.spawn(function()
	while true do
		RefreshSeedButtons()
		task.wait(5)
	end
end)

--// Loops
task.spawn(function()
	while task.wait(1) do
		if AutoPlant then AutoPlantLoop() end
		if AutoHarvest then HarvestPlants() end
	end
end)

print("✅ Fully custom autofarm UI loaded.")
