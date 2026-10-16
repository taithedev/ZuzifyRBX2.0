-- ZuzifyRBX 2.0 server foundation
-- Place in ServerScriptService as ZuzifyServer.server.lua
-- Runs only in Roblox experiences you own or have permission to edit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("ZuzifyRBX") or Instance.new("Folder")
folder.Name = "ZuzifyRBX"
folder.Parent = ReplicatedStorage

local request = folder:FindFirstChild("Request") or Instance.new("RemoteFunction")
request.Name = "Request"
request.Parent = folder

local action = folder:FindFirstChild("Action") or Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = folder

local VERSION = "2.0.0"
local DEFAULT_SPEED = 16
local SPRINT_SPEED = 22
local cooldowns = {}
local sprinting = {}

local function applySpeed(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = sprinting[player] and SPRINT_SPEED or DEFAULT_SPEED
    end
end

local function authorized(player)
    return player and player:IsDescendantOf(Players)
end

request.OnServerInvoke = function(player, method)
    if not authorized(player) or type(method) ~= "string" then
        return {ok = false, error = "Invalid request"}
    end
    if method == "GetStatus" then
        return {ok = true, version = VERSION, serverTime = os.time(), sprintAvailable = true}
    end
    return {ok = false, error = "Unknown method"}
end

action.OnServerEvent:Connect(function(player, method, value)
    if not authorized(player) or method ~= "SetSprint" or type(value) ~= "boolean" then
        return
    end
    local now = os.clock()
    if cooldowns[player] and now - cooldowns[player] < 0.15 then return end
    cooldowns[player] = now
    sprinting[player] = value
    applySpeed(player)
end)

Players.PlayerAdded:Connect(function(player)
    sprinting[player] = false
    player.CharacterAdded:Connect(function()
        task.defer(function() applySpeed(player) end)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    cooldowns[player] = nil
    sprinting[player] = nil
end)
