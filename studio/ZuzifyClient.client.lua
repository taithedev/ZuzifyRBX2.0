-- ZuzifyRBX 2.0 Studio client
-- Place in StarterPlayer > StarterPlayerScripts as ZuzifyClient.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("ZuzifyRBX", 15)
if not folder then warn("ZuzifyRBX server not installed"); return end
local request = folder:WaitForChild("Request")
local action = folder:WaitForChild("Action")

local status
local ok, result = pcall(function() return request:InvokeServer("GetStatus") end)
if ok and type(result) == "table" and result.ok then
    status = "Connected to server • v" .. tostring(result.version)
else
    status = "Server unavailable"
end

local gui = Instance.new("ScreenGui")
gui.Name = "ZuzifyRBX2"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -20, 0, 70)
panel.Size = UDim2.fromOffset(250, 105)
panel.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 38)
title.Position = UDim2.fromOffset(8, 4)
title.Text = status
title.TextWrapped = true
title.TextSize = 13
title.Font = Enum.Font.GothamMedium
title.TextColor3 = Color3.fromRGB(235, 240, 244)
title.BackgroundTransparency = 1
title.Parent = panel

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -16, 0, 44)
button.Position = UDim2.fromOffset(8, 51)
button.Text = "Sprint: OFF (Shift)"
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.TextColor3 = Color3.new(1, 1, 1)
button.BackgroundColor3 = Color3.fromRGB(36, 125, 116)
button.Parent = panel
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local sprinting = false
local function setSprint(value)
    if sprinting == value then return end
    sprinting = value
    button.Text = sprinting and "Sprint: ON (Shift)" or "Sprint: OFF (Shift)"
    action:FireServer("SetSprint", sprinting)
end
button.Activated:Connect(function() setSprint(not sprinting) end)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.LeftShift then setSprint(true) end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then setSprint(false) end
end)
