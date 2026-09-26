--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  ZuzifyRBX Gen13.1.0 — Community Edition                  ║
    ║  Advanced ESP • Aim Detection • Threat Alerts             ║
    ║  UI: Fluent-modded (StyearX/Fluent-Modded)                ║
    ╚═══════════════════════════════════════════════════════════╝
]]

--============================================================
-- 🔧 DEVELOPER OVERRIDES
--============================================================
local FORCE_PAYMENT_MODE = nil   -- nil | "free" | "paid" | "paid_free"
local FORCE_SCRIPT_MODE  = nil   -- nil | "online" | "offline" | "maintenance"
local FORCE_MAINTENANCE_MSG = "ZuzifyRBX is under maintenance."

local SHOW_LOADING      = true   -- enabled by default (changelog)
local LOADING_MIN_TIME  = 0.6    -- faster boot (was 0.8)

--============================================================
-- SERVICES
--============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local VIM              = game:GetService("VirtualInputManager")
local CoreGui          = game:GetService("CoreGui")
local Debris           = game:GetService("Debris")
local Workspace        = game:GetService("Workspace")
local Stats            = game:GetService("Stats")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local MY_UID = LP.UserId
local MY_NAME = LP.Name

local SafeLog = function(tag, msg) pcall(function() print(string.format("[Zuzy][%s] %s", tostring(tag), tostring(msg))) end) end

--============================================================
-- LOADING (animated, shimmer, live % counter, fade-out)
--============================================================
local LoadingGui, LoadingLabel, LoadingFill, LoadingPct, LoadingTitle
local _loadingStart = tick()
local _loadingEnabled = SHOW_LOADING == true

local function _buildLoading()
    if not _loadingEnabled then return end
    pcall(function()
        LoadingGui = Instance.new("ScreenGui")
        LoadingGui.Name = "ZuzyLoading"; LoadingGui.ResetOnSpawn = false
        LoadingGui.IgnoreGuiInset = true; LoadingGui.DisplayOrder = 999; LoadingGui.Parent = CoreGui

        local bg = Instance.new("Frame"); bg.Size = UDim2.new(1,0,1,0)
        bg.BackgroundColor3 = Color3.fromRGB(4,4,8); bg.BorderSizePixel = 0; bg.Parent = LoadingGui

        local box = Instance.new("Frame"); box.Size = UDim2.new(0,460,0,200)
        box.Position = UDim2.new(0.5,-230,0.5,-100); box.BackgroundColor3 = Color3.fromRGB(11,11,16)
        box.BorderSizePixel = 0; box.Parent = LoadingGui
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,16)
        local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(0,220,180); st.Thickness = 1.5; st.Parent = box

        LoadingTitle = Instance.new("TextLabel"); LoadingTitle.Size = UDim2.new(1,-32,0,40); LoadingTitle.Position = UDim2.new(0,16,0,12)
        LoadingTitle.BackgroundTransparency = 1; LoadingTitle.Text = "ZuzifyRBX"; LoadingTitle.TextColor3 = Color3.fromRGB(0,235,195)
        LoadingTitle.Font = Enum.Font.GothamBlack; LoadingTitle.TextSize = 24; LoadingTitle.TextXAlignment = Enum.TextXAlignment.Left; LoadingTitle.Parent = box

        LoadingLabel = Instance.new("TextLabel"); LoadingLabel.Size = UDim2.new(1,-32,0,20); LoadingLabel.Position = UDim2.new(0,16,0,70)
        LoadingLabel.BackgroundTransparency = 1; LoadingLabel.Text = "Starting…"; LoadingLabel.TextColor3 = Color3.fromRGB(220,220,230)
        LoadingLabel.Font = Enum.Font.Gotham; LoadingLabel.TextSize = 13; LoadingLabel.TextXAlignment = Enum.TextXAlignment.Left; LoadingLabel.Parent = box

        local bar = Instance.new("Frame"); bar.Size = UDim2.new(1,-32,0,8); bar.Position = UDim2.new(0,16,0,110)
        bar.BackgroundColor3 = Color3.fromRGB(30,30,40); bar.BorderSizePixel = 0; bar.Parent = box
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
        LoadingFill = Instance.new("Frame"); LoadingFill.Size = UDim2.new(0,0,1,0); LoadingFill.BackgroundColor3 = Color3.fromRGB(0,220,180)
        LoadingFill.BorderSizePixel = 0; LoadingFill.Parent = bar
        Instance.new("UICorner", LoadingFill).CornerRadius = UDim.new(1,0)

        LoadingPct = Instance.new("TextLabel"); LoadingPct.Size = UDim2.new(1,-32,0,20); LoadingPct.Position = UDim2.new(0,16,0,132)
        LoadingPct.BackgroundTransparency = 1; LoadingPct.Text = "0%"; LoadingPct.TextColor3 = Color3.fromRGB(0,235,195)
        LoadingPct.Font = Enum.Font.GothamBold; LoadingPct.TextSize = 14; LoadingPct.TextXAlignment = Enum.TextXAlignment.Left; LoadingPct.Parent = box
    end)
end
_buildLoading()

local function SetLoading(pct, msg)
    if not _loadingEnabled then return end
    pcall(function()
        if LoadingLabel then LoadingLabel.Text = msg end
        if LoadingFill then LoadingFill.Size = UDim2.new(math.clamp(pct,0,1),0,1,0) end
        if LoadingPct then LoadingPct.Text = math.floor(math.clamp(pct,0,1)*100).."%" end
    end)
end
local function CloseLoading()
    if not _loadingEnabled then return end
    local el = tick() - _loadingStart
    if el < LOADING_MIN_TIME then task.wait(LOADING_MIN_TIME - el) end
    pcall(function()
        if LoadingGui then
            -- fade-out
            local tw = game:GetService("TweenService"):Create(LoadingGui, TweenInfo.new(0.3), {})
            -- just destroy after a tiny delay for smoothness
            task.wait(0.1)
            LoadingGui:Destroy()
        end
    end)
    LoadingGui = nil
end
SetLoading(0.02, "Initializing…")

--============================================================
-- CONFIG
--============================================================
local VERSION           = "Gen13.1.0"
-- Fluent‑modded: three fallback URLs (release asset → raw modded → original Fluent)
local FLUENT_URLS = {
    "https://github.com/StyearX/Fluent-Modded/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/StyearX/Fluent-modded/main/dist/main.lua",
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
}
local SUPABASE_URL      = "https://hfxpuqvishbfqlwxnnpe.supabase.co"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmeHB1cXZpc2hiZnFsd3hubnBlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwNzkyMTUsImV4cCI6MjEwNDY1NTIxNX0.p8YyuvBhAw45YmKc-o-iMyvKKTPDEdKdnBfT2EUGx18"
local OWNER_UIDS        = { 717544874 }

--============================================================
-- HTTP
--============================================================
local httpReq = http_request or request or (syn and syn.request) or (http and http.request)

local function http(method, url, headers, body)
    if not httpReq then return nil end
    local o = { Url = url, Method = method, Headers = headers or {} }
    if body then
        o.Body = type(body) == "string" and body or HttpService:JSONEncode(body)
        o.Headers["Content-Type"] = "application/json"
    end
    for _ = 1, 3 do
        local ok, res = pcall(httpReq, o)
        if ok and res then
            local d
            pcall(function() d = HttpService:JSONDecode(res.Body) end)
            return d, res.StatusCode
        end
        task.wait(0.15)
    end
    return nil
end
local function sbHdr(x)
    local h = { ["apikey"] = SUPABASE_ANON_KEY, ["Authorization"] = "Bearer "..SUPABASE_ANON_KEY,
                ["Content-Type"] = "application/json", ["Prefer"] = "return=representation" }
    if x then for k,v in pairs(x) do h[k]=v end end
    return h
end
local function sbGet(t,q)     return http("GET",   SUPABASE_URL.."/rest/v1/"..t..(q and ("?"..q) or ""), sbHdr()) end
local function sbPost(t,b)    return http("POST",  SUPABASE_URL.."/rest/v1/"..t, sbHdr(), b) end
local function sbPatch(t,q,b) return http("PATCH", SUPABASE_URL.."/rest/v1/"..t.."?"..q, sbHdr(), b) end
local function sbDelete(t,q)  return http("DELETE",SUPABASE_URL.."/rest/v1/"..t.."?"..q, sbHdr()) end
local function nowISO() return DateTime.now():ToIsoDate() end

SetLoading(0.05, "HTTP ready")

--============================================================
-- ROLES
--============================================================
local ROLE_ORDER = { user=0, free=0, basic=1, premium=2, trusted=2, moderator=3,
                    head_moderator=4, admin=5, head_admin=6, community_manager=7, developer=8, owner=9 }
local ROLE_LABELS = { user="User", basic="Basic", premium="Premium", trusted="Trusted",
                     moderator="Moderator", head_moderator="Head Moderator", admin="Admin",
                     head_admin="Head Admin", community_manager="Community Manager",
                     developer="Developer", owner="Owner" }
local function HasTier(c,m) return (ROLE_ORDER[c] or 0) >= (ROLE_ORDER[m] or 0) end
local function RoleLabel(r) return ROLE_LABELS[r] or r end

--============================================================
-- SETTINGS
--============================================================
SetLoading(0.10, "Loading settings…")

local GlobalSettings = {
    script_mode="online", payment_mode="paid_free", maintenance_msg="Offline.",
    min_version=VERSION, max_users="0", applications_open="true", tickets_open="true",
    announcement_poll_seconds="30",
}
local function refreshSettings()
    pcall(function()
        local d = sbGet("zuzify_settings", "select=*")
        if d then for _, r in ipairs(d) do GlobalSettings[r.key] = r.value end end
    end)
end
refreshSettings()

local IS_OWNER = table.find(OWNER_UIDS, MY_UID) ~= nil
local EFFECTIVE_SCRIPT_MODE  = FORCE_SCRIPT_MODE  or GlobalSettings.script_mode
local EFFECTIVE_PAYMENT_MODE = FORCE_PAYMENT_MODE or GlobalSettings.payment_mode
local EFFECTIVE_MAINT_MSG    = FORCE_MAINTENANCE_MSG or GlobalSettings.maintenance_msg

if EFFECTIVE_SCRIPT_MODE == "offline" and (FORCE_SCRIPT_MODE or not IS_OWNER) then
    pcall(function() LP:Kick("ZuzifyRBX is offline.") end); CloseLoading(); return
end
if EFFECTIVE_SCRIPT_MODE == "maintenance" and (FORCE_SCRIPT_MODE or not IS_OWNER) then
    pcall(function() LP:Kick("Maintenance: "..EFFECTIVE_MAINT_MSG) end); CloseLoading(); return
end

--============================================================
-- LICENSE POPUP (Enter key, debounce, no‑HTTP fallback)
--============================================================
SetLoading(0.20, "Checking license…")

local function showLicensePopup()
    local result = { done=false, tier="free", role="user", key=nil }
    if IS_OWNER then result.tier, result.role, result.key = "owner","owner","OWNER"; result.done=true; return result end
    if EFFECTIVE_PAYMENT_MODE == "free" then result.tier, result.role = "free","user"; result.done=true; return result end

    -- If HTTP is unavailable, gracefully fall back to free
    if not httpReq then
        result.tier, result.role = "free","user"; result.done=true
        return result
    end

    local gui
    local activationDebounce = false
    pcall(function()
        gui = Instance.new("ScreenGui"); gui.Name="ZuzyLic"; gui.ResetOnSpawn=false
        gui.IgnoreGuiInset=true; gui.DisplayOrder=998; gui.Parent = CoreGui

        local fr = Instance.new("Frame"); fr.Size = UDim2.new(0,560,0,420); fr.Position = UDim2.new(0.5,-280,0.5,-210)
        fr.BackgroundColor3 = Color3.fromRGB(8,8,12); fr.BorderSizePixel = 0; fr.Parent = gui
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0,12)
        local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(0,200,160); st.Thickness = 1.5; st.Parent = fr

        local t = Instance.new("TextLabel"); t.Size = UDim2.new(1,0,0,42); t.BackgroundTransparency = 1
        t.Text = "ZuzifyRBX "..VERSION.." — Activation"; t.TextColor3 = Color3.fromRGB(0,220,180)
        t.Font = Enum.Font.GothamBold; t.TextSize = 19; t.Parent = fr

        local info = Instance.new("TextLabel"); info.Size = UDim2.new(1,-40,0,70); info.Position = UDim2.new(0,20,0,48)
        info.BackgroundTransparency = 1
        info.Text = EFFECTIVE_PAYMENT_MODE == "paid"
            and "Enter your license key to continue.\n(ZUZIFY-XXXX-XXXX-XXXX)"
            or  "License key (ZUZIFY-XXXX-XXXX-XXXX)\nor Continue Free."
        info.TextColor3 = Color3.fromRGB(200,200,215); info.Font = Enum.Font.Gotham
        info.TextSize = 13; info.TextWrapped = true; info.Parent = fr

        local box = Instance.new("TextBox"); box.Size = UDim2.new(0.9,0,0,40); box.Position = UDim2.new(0.05,0,0.42,0)
        box.BackgroundColor3 = Color3.fromRGB(16,16,20); box.TextColor3 = Color3.new(1,1,1)
        box.PlaceholderText = "ZUZIFY-0000-0000-0001"; box.Font = Enum.Font.Gotham; box.TextSize = 14
        box.ClearTextOnFocus = false; box.Parent = fr
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)

        local msg = Instance.new("TextLabel"); msg.Size = UDim2.new(1,-40,0,22); msg.Position = UDim2.new(0,20,0.42,46)
        msg.BackgroundTransparency = 1; msg.Text = ""; msg.TextColor3 = Color3.fromRGB(255,120,120)
        msg.Font = Enum.Font.Gotham; msg.TextSize = 12; msg.Parent = fr

        local act = Instance.new("TextButton"); act.Size = UDim2.new(0.44,-20,0,42); act.Position = UDim2.new(0.05,0,0.78,0)
        act.BackgroundColor3 = Color3.fromRGB(0,160,130); act.Text = "Activate"; act.TextColor3 = Color3.new(1,1,1)
        act.Font = Enum.Font.GothamBold; act.TextSize = 14; act.Parent = fr
        Instance.new("UICorner", act).CornerRadius = UDim.new(0,8)

        local skip = Instance.new("TextButton"); skip.Size = UDim2.new(0.44,-20,0,42); skip.Position = UDim2.new(0.51,0,0.78,0)
        skip.BackgroundColor3 = Color3.fromRGB(40,40,48); skip.Text = "Continue Free"
        skip.TextColor3 = Color3.fromRGB(230,230,240); skip.Font = Enum.Font.GothamBold
        skip.TextSize = 14; skip.Parent = fr
        Instance.new("UICorner", skip).CornerRadius = UDim.new(0,8)

        if EFFECTIVE_PAYMENT_MODE == "paid" then
            skip.BackgroundColor3 = Color3.fromRGB(60,20,20); skip.Text = "Paid Only"; skip.AutoButtonColor = false
        end

        local function tryActivate()
            if activationDebounce then return end
            activationDebounce = true
            task.delay(1, function() activationDebounce = false end)
            local key = string.upper((box.Text:gsub("%s", "")))
            if #key < 10 then msg.Text = "Bad format."; return end
            msg.Text = "Checking…"; msg.TextColor3 = Color3.fromRGB(200,200,100)
            task.spawn(function()
                local ok = pcall(function()
                    local d = sbGet("zuzify_keys", "license_key=eq."..HttpService:UrlEncode(key).."&select=*")
                    if not d or #d == 0 then msg.Text = "Invalid."; msg.TextColor3 = Color3.fromRGB(255,120,120); return end
                    local k = d[1]
                    if not k.is_active then msg.Text = "Deactivated."; return end
                    if k.used_by and k.used_by ~= MY_UID then msg.Text = "Used."; return end
                    if k.expires_at then
                        local ok2, e = pcall(function() return DateTime.fromIsoDate(k.expires_at) end)
                        if ok2 and e and e.UnixTimestamp < os.time() then msg.Text = "Expired."; return end
                    end
                    local exp = k.duration_days and k.duration_days > 0
                        and DateTime.now():AddSeconds(k.duration_days*86400):ToIsoDate() or nil
                    sbPatch("zuzify_keys", "license_key=eq."..HttpService:UrlEncode(key),
                        { used_by = MY_UID, used_at = nowISO(), expires_at = exp })
                    sbPost("zuzify_key_redemptions", { license_key=key, user_id=MY_UID, username=MY_NAME, tier=k.tier })
                    result.tier = k.tier or "basic"
                    result.role = ROLE_ORDER[result.tier] and result.tier or "user"
                    result.key = key
                    result.done = true
                end)
                if not ok then msg.Text = "Network error."; msg.TextColor3 = Color3.fromRGB(255,120,120) end
            end)
        end

        act.MouseButton1Click:Connect(tryActivate)
        box.FocusLost:Connect(function(enterPressed) if enterPressed then tryActivate() end end)

        skip.MouseButton1Click:Connect(function()
            if EFFECTIVE_PAYMENT_MODE == "paid" and not IS_OWNER then
                msg.Text = "Free disabled."; return
            end
            result.done = true
        end)
    end)

    local startT = tick()
    while not result.done and tick() - startT < 300 do task.wait(0.1) end
    pcall(function() if gui then gui:Destroy() end end)
    return result
end

local licResult = showLicensePopup()
local acquiredTier, acquiredKey, acquiredRole = licResult.tier, licResult.key, licResult.role

--============================================================
-- REGISTER USER (parallel session start)
--============================================================
SetLoading(0.30, "Registering user…")
if IS_OWNER then acquiredTier, acquiredRole = "owner","owner" end

local userRow = { tier=acquiredTier, role=acquiredRole, is_trusted=false, show_username=false,
                  is_banned=false, warn_count=0, seen_announcements={}, theme_name="Dark" }

task.spawn(function()
    pcall(function()
        local payload = { user_id=MY_UID, username=MY_NAME, license_key=acquiredKey,
                          tier=acquiredTier, role=acquiredRole, is_paid=(acquiredTier~="free"), last_seen=nowISO() }
        local d = sbGet("zuzify_users", "user_id=eq."..MY_UID.."&select=*")
        if d and #d > 0 then
            local cur = d[1]
            if IS_OWNER then payload.role, payload.tier = "owner","owner"
            else
                if cur.role and (ROLE_ORDER[cur.role] or 0) > (ROLE_ORDER[payload.role] or 0) then payload.role = cur.role end
                if cur.tier and (ROLE_ORDER[cur.tier] or 0) > (ROLE_ORDER[payload.tier] or 0) then payload.tier = cur.tier end
            end
            sbPatch("zuzify_users", "user_id=eq."..MY_UID, payload)
            userRow = cur
        else
            local c = sbPost("zuzify_users", payload)
            userRow = (c and #c > 0) and c[1] or userRow
        end
    end)
end)
task.wait(0.6)  -- faster boot (was 1s)

if userRow.is_banned then
    pcall(function() LP:Kick("Banned: "..(userRow.ban_reason or "No reason")) end); CloseLoading(); return
end

local MY_ROLE = userRow.role or acquiredRole or "user"
local MY_TIER = userRow.tier or acquiredTier or "free"
local MY_TRUSTED_FEATURES = userRow.trusted_features or {}
local MY_SEEN_ANN = userRow.seen_announcements or {}

local function IsTrusted() return HasTier(MY_TIER,"trusted") or userRow.is_trusted == true end
local function IsMod()     return HasTier(MY_ROLE,"moderator") end
local function IsAdmin()   return HasTier(MY_ROLE,"admin") end
local function IsOwner()   return HasTier(MY_ROLE,"owner") end
local function IsStaff()   return IsMod() end

--============================================================
-- SESSION (parallel start)
--============================================================
SetLoading(0.40, "Starting session…")
local JOB_ID = game.JobId
local PLACE_ID = game.PlaceId
local SESSION_ID = nil
local lastRole, lastTier = MY_ROLE, MY_TIER
local settingsRefresh = 0

task.spawn(function()
    pcall(function()
        local c = sbPost("zuzify_sessions", { user_id=MY_UID, username=userRow.show_username and MY_NAME or nil,
            show_username=userRow.show_username or false, role=MY_ROLE, tier=MY_TIER,
            place_id=PLACE_ID, job_id=JOB_ID, client_version=VERSION })
        if c and #c > 0 then
            SESSION_ID = c[1].id
            pcall(function() http("POST", SUPABASE_URL.."/rest/v1/rpc/zuzify_kill_old_sessions", sbHdr(),
                { new_session_id=SESSION_ID, uid=MY_UID }) end)
        end
    end)
    while true do
        task.wait(20)
        pcall(function()
            if SESSION_ID then sbPatch("zuzify_sessions", "id=eq."..SESSION_ID, { last_ping=nowISO() }) end
            local me = sbGet("zuzify_users",
                "user_id=eq."..MY_UID.."&select=is_banned,ban_reason,kick_signal,kick_reason,role,tier,is_trusted,warn_count,trusted_features,seen_announcements,theme_name")
            if me and #me > 0 then
                local m = me[1]
                if m.is_banned then pcall(function() LP:Kick("Banned: "..(m.ban_reason or "")) end) end
                if m.kick_signal then
                    sbPatch("zuzify_users", "user_id=eq."..MY_UID, { kick_signal=false, kick_reason="" })
                    pcall(function() LP:Kick("Kicked: "..(m.kick_reason or "")) end)
                end
                if m.role ~= lastRole or m.tier ~= lastTier then
                    lastRole, lastTier = m.role, m.tier
                    MY_ROLE = m.role or MY_ROLE; MY_TIER = m.tier or MY_TIER
                end
                userRow.warn_count = m.warn_count
                userRow.is_trusted = m.is_trusted
                MY_TRUSTED_FEATURES = m.trusted_features or MY_TRUSTED_FEATURES
                MY_SEEN_ANN = m.seen_announcements or MY_SEEN_ANN
                userRow.theme_name = m.theme_name or userRow.theme_name
            end
            if tick() - settingsRefresh > 60 then
                settingsRefresh = tick()
                refreshSettings()
                if not IS_OWNER then
                    local sm = FORCE_SCRIPT_MODE or GlobalSettings.script_mode
                    if sm == "offline" then pcall(function() LP:Kick("ZuzifyRBX is offline.") end) end
                    if sm == "maintenance" then pcall(function() LP:Kick("Maintenance: "..(FORCE_MAINTENANCE_MSG or GlobalSettings.maintenance_msg)) end) end
                end
            end
        end)
    end
end)

--============================================================
-- FEATURES
--============================================================
SetLoading(0.50, "Preparing features…")

local F = {
    -- ESP core
    ESP = false, ESP_Names = true, ESP_Distance = true, ESP_Health = true, ESP_Weapon = true,
    ESP_HealthBar = true, ESP_HealthBarStyle = "Horizontal",
    ESP_Chams = true, ESP_Boxes = true, ESP_BoxStyle = "Corners",
    ESP_Tracers = false, ESP_TracersMode = "Top",
    ESP_HeadDot = false, ESP_Skeleton = false, ESP_FacingArrow = true,
    ESP_Velocity = false, ESP_TeamCheck = false, ESP_DeadCheck = true,
    ESP_MaxDistance = 1500, ESP_RefreshRate = 0.08,
    ESP_ColorMode = "Threat",  -- "Role" | "Threat" | "Distance" | "Health" | "Rainbow"
    ESP_ShowOnlyMurderer = false, ESP_ShowOnlySheriff = false,
    ESP_FOVCircle = false, ESP_FOVRadius = 140, ESP_Through = true,
    ESP_FillTransparency = 0.55, ESP_OutlineTransparency = 0.1,
    ESP_TextSize = 15, ESP_NameOnly = false, ESP_Rainbow = false,
    ESP_TrustedColor = Color3.fromRGB(255,215,0), ESP_GoldESP = false,
    ESP_ShowNotes = true,
    ESP_VisibleCheck = false, ESP_OccludedFade = true,
    ESP_AimWarning = true, ESP_AimColorPulse = true,
    ESP_ThreatColorLow = Color3.fromRGB(80,255,120),
    ESP_ThreatColorMid = Color3.fromRGB(255,210,80),
    ESP_ThreatColorHigh = Color3.fromRGB(255,60,60),
    -- Alerts
    Alert_OnAim = true, Alert_OnClose = false, Alert_CloseDist = 20,
    Alert_Sound = true, Alert_Cooldown = 4,
    -- Movement / misc
    Fullbright = false, CustomFOV = 70,
    NoclipType = "None", FlyType = "None", FlySpeed = 60,
    InfiniteJump = false, WalkSpeed = 16, JumpPower = 50,
    SpeedBoost = false, SuperJump = false, BunnyHop = false, Dash = false,
    DashPower = 30, TeleportToMouse = false,
    CFrameSpeed = false, CFrameSpeedValue = 2,
    -- Combat
    Aimbot = false, SilentAim = false, AimbotFOV = 230,
    AutoKill = false, KnifeAura = false, AuraRange = 15, KillTarget = false, AutoShoot = false,
    SelectedTarget = nil,
    -- Troll
    FlingType = "Normal", FlingNearest = false, FlingAll = false, FlingTarget = false,
    Invisible = false, RainbowSelf = false, Orbit = false, OrbitDist = 6, LoopBehind = false,
    FreezeTarget = false, InvisibleTarget = false, SpinTarget = false, PlatformTarget = false,
    FreezeAll = false, SpinAll = false,
    Piggyback = false, FrontCarry = false, SideCarry = false,
    -- Anti
    AntiAFK = true, AntiFling = true, AntiDie = false, AntiVoid = false, AntiSit = false, AntiRagdoll = false,
    -- Meta
    SelectedEmote = nil, ShareUsername = userRow.show_username or false,
    Debug_Overlay = false,
    TrustedRainbowTrail = false, TrustedCustomTitle = "",
    TrustedAutoSave = false, TrustedPrivateNotify = true,
    ThemeName = userRow.theme_name or "Dark",
    CloudAutoSave = false, CloudAutoLoad = true,
}

--============================================================
-- THEMES
--============================================================
local ThemeNames = {
    "Dark","Light","Darker","Blood Red","Neon","Amethyst","Ocean","Midnight",
    "Sapphire","Rose","Neon Cyber","Arctic Frost","Cotton Candy","Cyanic",
    "Amber Glow","Bloomings","Crimson","Gold","Lavender Pink",
}
local function applyTheme(name)
    if not _G.__ZUZY_FLUENT then return end
    if not table.find(ThemeNames, name) then name = "Dark" end
    pcall(function() _G.__ZUZY_FLUENT:SetTheme(name) end)
end

--============================================================
-- CONFIG SERIALIZER
--============================================================
local function serializeConfig()
    local out = {}
    for k, v in pairs(F) do
        local t = typeof(v)
        if t == "boolean" or t == "number" or t == "string" then out[k] = v
        elseif t == "Color3" then out[k] = { __type="Color3", R=v.R, G=v.G, B=v.B } end
    end
    return out
end
local function deserializeConfig(cfg)
    if type(cfg) ~= "table" then return end
    for k, v in pairs(cfg) do
        if F[k] ~= nil then
            if type(v) == "table" and v.__type == "Color3" then F[k] = Color3.new(v.R,v.G,v.B)
            elseif type(v) == type(F[k]) then F[k] = v end
        end
    end
end
local function saveConfigToCloud()
    return pcall(function()
        sbPatch("zuzify_users", "user_id=eq."..MY_UID,
            { config = serializeConfig(), config_updated_at = nowISO(), theme_name = F.ThemeName })
    end)
end
local function loadConfigFromCloud()
    local d = sbGet("zuzify_users", "user_id=eq."..MY_UID.."&select=config,theme_name")
    if d and #d > 0 then
        if d[1].config then deserializeConfig(d[1].config) end
        if d[1].theme_name then F.ThemeName = d[1].theme_name end
        return true
    end
    return false
end

--============================================================
-- EMOTES (fixed)
--============================================================
local EmoteList = {}
local function E(n,i) table.insert(EmoteList, { Name=n, ID=i }) end
local eids = {"507770620","507771112","507771612","507771366","507771049","507771682","507771410","507771276","507771842","507771453","507771054","507771815","507771568","507771147","507771731","507771174","507771878","507771594","507771358","507771270"}
local enames = {"Dance","Robot","Floss","Twist","Whip","Wave","Point","Salute","Sit","Lay","Dab","Gangnam","Macarena","Harlem","Running Man","T-Pose","Cossack","Ballet","Sword","Karate"}
local ei = 0
for k = 1, #enames do ei = ei + 1; E(enames[k].." "..ei, "rbxassetid://"..eids[((k-1)%#eids)+1]) end

--============================================================
-- HELPERS
--============================================================
local RoleColors = { Murderer = Color3.fromRGB(255,55,55), Sheriff = Color3.fromRGB(55,145,255), Innocent = Color3.fromRGB(55,230,100) }
local MapTeleports = { Lobby=Vector3.new(-110,140,40), Bank=Vector3.new(0,5,0), Hotel=Vector3.new(50,5,0),
                       Hospital=Vector3.new(-50,5,0), Office=Vector3.new(0,5,50), House=Vector3.new(30,5,-30),
                       Museum=Vector3.new(20,5,40), Laboratory=Vector3.new(-40,5,-20) }
local CachedRoles = {}

local function GetRole(plr)
    if not plr then return "Innocent" end
    local c = CachedRoles[plr]
    if c and tick() - c.t < 1.5 then return c.r end
    local r = "Innocent"
    if plr.Character then
        local tool = plr.Character:FindFirstChildOfClass("Tool")
        if tool then
            local n = string.lower(tool.Name)
            if n:find("knife") or n:find("dagger") or n:find("blade") then r = "Murderer"
            elseif n:find("gun") or n:find("revolver") or n:find("pistol") then r = "Sheriff" end
        end
    end
    CachedRoles[plr] = { r = r, t = tick() }
    return r
end

local function GetMyRoot() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function GetMyHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function GetTarget() if not F.SelectedTarget then return nil end return Players:FindFirstChild(F.SelectedTarget) end
local function GetTargetRoot() local t = GetTarget(); return t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") end
local function GetClosest(maxD)
    local r = GetMyRoot(); if not r then return nil end
    local best, bd = nil, maxD or 9999
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and h and h.Health > 0 then
                local d = (r.Position - tr.Position).Magnitude
                if d < bd then bd = d; best = p end
            end
        end
    end
    return best
end

local function FormatTime(isoStr)
    if not isoStr then return "N/A" end
    local ok, dt = pcall(function() return DateTime.fromIsoDate(isoStr) end)
    if not ok or not dt then return tostring(isoStr):sub(1,19) end
    local diff = os.time() - dt.UnixTimestamp
    if diff < 60 then return diff.."s ago"
    elseif diff < 3600 then return math.floor(diff/60).."m ago"
    elseif diff < 86400 then return math.floor(diff/3600).."h ago"
    else return math.floor(diff/86400).."d ago" end
end

--============================================================
-- PLAYER NOTES
--============================================================
local NotesCache = {}
local function loadMyNotes()
    task.spawn(function()
        pcall(function()
            local d = sbGet("zuzify_notes", "owner_id=eq."..MY_UID.."&select=*")
            if d then
                NotesCache = {}
                for _, n in ipairs(d) do
                    NotesCache[tostring(n.target_id)] = { note=n.note or "", tag=n.tag or "",
                        color=n.color or "#ffffff", id=n.id, target_name=n.target_name }
                end
            end
        end)
    end)
end
loadMyNotes()

local function setNoteFor(targetId, targetName, note, tag, color)
    task.spawn(function()
        pcall(function()
            local d = sbGet("zuzify_notes", "owner_id=eq."..MY_UID.."&target_id=eq."..targetId.."&select=id")
            if d and #d > 0 then
                sbPatch("zuzify_notes", "owner_id=eq."..MY_UID.."&target_id=eq."..targetId,
                    { note=note, tag=tag, color=color, target_name=targetName, updated_at=nowISO() })
            else
                sbPost("zuzify_notes", { owner_id=MY_UID, target_id=targetId, target_name=targetName,
                    note=note, tag=tag, color=color })
            end
            NotesCache[tostring(targetId)] = { note=note, tag=tag, color=color, target_name=targetName }
        end)
    end)
end

local function deleteNote(targetId)
    task.spawn(function()
        pcall(function()
            sbDelete("zuzify_notes", "owner_id=eq."..MY_UID.."&target_id=eq."..targetId)
            NotesCache[tostring(targetId)] = nil
        end)
    end)
end

--============================================================
-- ⚡ ADVANCED ESP SYSTEM (rebuilt with hooks, no flicker)
--============================================================
local ESPObjects = {}
local FOVCircleObj = nil

local SKELETON_JOINTS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function clearESP(plr)
    local o = ESPObjects[plr]
    if o then
        for _, x in pairs(o) do
            if type(x) == "table" then
                for _, y in pairs(x) do
                    if y and y.Destroy then pcall(function() y:Destroy() end) end
                end
            elseif x and x.Destroy then pcall(function() x:Destroy() end) end
        end
        ESPObjects[plr] = nil
    end
end
local function clearAllESP() for p in pairs(ESPObjects) do clearESP(p) end end

-- Threat calculation (0 = safe, 1 = maximum threat)
local function getThreatLevel(plr, dist, isAiming)
    local score = 0
    if dist < 30 then score = score + 0.5
    elseif dist < 75 then score = score + 0.3
    elseif dist < 150 then score = score + 0.15 end
    local role = GetRole(plr)
    if role == "Murderer" then score = score + 0.35
    elseif role == "Sheriff" then score = score + 0.1 end
    if isAiming then score = score + 0.4 end
    local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if h and h.Health < h.MaxHealth * 0.3 then score = score - 0.15 end
    return math.clamp(score, 0, 1)
end

local function threatColor(level)
    if level < 0.35 then
        return F.ESP_ThreatColorLow:Lerp(F.ESP_ThreatColorMid, level / 0.35)
    else
        return F.ESP_ThreatColorMid:Lerp(F.ESP_ThreatColorHigh, (level - 0.35) / 0.65)
    end
end

-- Aim detection
local function isAimingAtMe(plr)
    if not plr or plr == LP then return false end
    local myRoot = GetMyRoot()
    local theirChar = plr.Character
    if not myRoot or not theirChar then return false end
    local theirHead = theirChar:FindFirstChild("Head")
    local theirRoot = theirChar:FindFirstChild("HumanoidRootPart")
    if not theirHead or not theirRoot then return false end

    local lookDir = theirHead.CFrame.LookVector
    local toMe = (myRoot.Position - theirHead.Position)
    if toMe.Magnitude < 0.1 then return true end
    local toMeUnit = toMe.Unit
    local dot = lookDir:Dot(toMeUnit)

    local flatLook = Vector3.new(lookDir.X, 0, lookDir.Z)
    local flatToMe = Vector3.new(toMeUnit.X, 0, toMeUnit.Z)
    local flatDot = 0
    if flatLook.Magnitude > 0.01 and flatToMe.Magnitude > 0.01 then
        flatDot = flatLook.Unit:Dot(flatToMe.Unit)
    end

    return dot > 0.85 or flatDot > 0.9
end

-- Visibility raycast (modern)
local function isVisible(plr)
    local myRoot = GetMyRoot()
    local theirChar = plr.Character
    if not myRoot or not theirChar then return false end
    local theirHead = theirChar:FindFirstChild("Head")
    if not theirHead then return false end
    local rayOrigin = myRoot.Position
    local rayDir = (theirHead.Position - rayOrigin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { LP.Character, theirChar, Camera }
    local result = Workspace:Raycast(rayOrigin, rayDir, rayParams)
    return result == nil or result.Instance:IsDescendantOf(theirChar)
end

local function getESPColor(plr, d, isAiming, threat)
    if F.ESP_Rainbow then return Color3.fromHSV((tick()*0.5) % 1, 1, 1) end
    if F.ESP_GoldESP and IsTrusted() then return F.ESP_TrustedColor end

    local noteData = NotesCache[tostring(plr.UserId)]
    if noteData and noteData.color and F.ESP_ShowNotes then
        local hex = tostring(noteData.color):gsub("#","")
        if #hex == 6 then
            return Color3.fromRGB(tonumber(hex:sub(1,2),16) or 255,
                                  tonumber(hex:sub(3,4),16) or 255,
                                  tonumber(hex:sub(5,6),16) or 255)
        end
    end

    if F.ESP_ColorMode == "Role" then
        return RoleColors[GetRole(plr)] or RoleColors.Innocent
    elseif F.ESP_ColorMode == "Distance" then
        local t = math.clamp(d/300, 0, 1); return Color3.fromRGB(255*(1-t), 255*t, 0)
    elseif F.ESP_ColorMode == "Health" then
        local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if h then local p = h.Health/math.max(h.MaxHealth, 1); return Color3.fromRGB(255*(1-p), 255*p, 0) end
        return Color3.fromRGB(0, 255, 0)
    elseif F.ESP_ColorMode == "Threat" then
        local col = threatColor(threat)
        if isAiming and F.ESP_AimColorPulse then
            local pulse = 0.7 + 0.3 * math.sin(tick() * 8)
            col = col:Lerp(Color3.fromRGB(255, 30, 30), pulse * 0.35)
        end
        return col
    end
    return Color3.fromRGB(0, 220, 180)
end

-- ESP creation (MaxDistance = infinite)
local function createESP(plr)
    if plr == LP or ESPObjects[plr] then return end
    local c = plr.Character; if not c then return end
    local head = c:FindFirstChild("Head"); local root = c:FindFirstChild("HumanoidRootPart")
    if not head or not root then return end
    local o = {}
    pcall(function()
        local bb = Instance.new("BillboardGui")
        bb.Name = "ZESP"; bb.Adornee = head
        bb.Size = UDim2.new(0, 320, 0, 180); bb.StudsOffset = Vector3.new(0, 3.6, 0)
        bb.AlwaysOnTop = F.ESP_Through; bb.MaxDistance = math.huge; bb.Parent = head; o.Billboard = bb

        o.NameLabel = Instance.new("TextLabel"); o.NameLabel.Size = UDim2.new(1,0,0.2,0)
        o.NameLabel.BackgroundTransparency = 1; o.NameLabel.TextColor3 = Color3.new(1,1,1)
        o.NameLabel.Font = Enum.Font.GothamBold; o.NameLabel.TextSize = F.ESP_TextSize; o.NameLabel.Parent = bb

        o.TagLabel = Instance.new("TextLabel"); o.TagLabel.Size = UDim2.new(1,0,0.14,0)
        o.TagLabel.Position = UDim2.new(0,0,0.2,0); o.TagLabel.BackgroundTransparency = 1
        o.TagLabel.Font = Enum.Font.GothamBold; o.TagLabel.TextSize = 12; o.TagLabel.Parent = bb

        o.DistLabel = Instance.new("TextLabel"); o.DistLabel.Size = UDim2.new(1,0,0.13,0)
        o.DistLabel.Position = UDim2.new(0,0,0.34,0); o.DistLabel.BackgroundTransparency = 1
        o.DistLabel.Font = Enum.Font.Gotham; o.DistLabel.TextSize = 12; o.DistLabel.Parent = bb

        o.HealthLabel = Instance.new("TextLabel"); o.HealthLabel.Size = UDim2.new(1,0,0.13,0)
        o.HealthLabel.Position = UDim2.new(0,0,0.47,0); o.HealthLabel.BackgroundTransparency = 1
        o.HealthLabel.Font = Enum.Font.Gotham; o.HealthLabel.TextSize = 12; o.HealthLabel.Parent = bb

        o.WeaponLabel = Instance.new("TextLabel"); o.WeaponLabel.Size = UDim2.new(1,0,0.13,0)
        o.WeaponLabel.Position = UDim2.new(0,0,0.6,0); o.WeaponLabel.BackgroundTransparency = 1
        o.WeaponLabel.TextColor3 = Color3.new(1,1,1); o.WeaponLabel.Font = Enum.Font.Gotham
        o.WeaponLabel.TextSize = 11; o.WeaponLabel.Parent = bb

        o.ThreatLabel = Instance.new("TextLabel"); o.ThreatLabel.Size = UDim2.new(1,0,0.13,0)
        o.ThreatLabel.Position = UDim2.new(0,0,0.73,0); o.ThreatLabel.BackgroundTransparency = 1
        o.ThreatLabel.Font = Enum.Font.GothamBold; o.ThreatLabel.TextSize = 11; o.ThreatLabel.Parent = bb

        if F.ESP_Boxes then
            local boxGui = Instance.new("BillboardGui")
            boxGui.Name = "ZBox2D"; boxGui.Adornee = root
            boxGui.Size = UDim2.new(0, 60, 0, 100)
            boxGui.StudsOffset = Vector3.new(0, 0, 0)
            boxGui.AlwaysOnTop = F.ESP_Through
            boxGui.MaxDistance = math.huge
            boxGui.LightInfluence = 1
            boxGui.Parent = root
            o.Box2D = boxGui

            if F.ESP_BoxStyle == "Corners" then
                o.BoxFrames = {}
                for i = 1, 8 do
                    local fr = Instance.new("Frame")
                    fr.BackgroundColor3 = Color3.new(1,1,1)
                    fr.BorderSizePixel = 0
                    fr.Parent = boxGui
                    o.BoxFrames[i] = fr
                end
            else
                o.BoxFrames = {}
                for i = 1, 4 do
                    local fr = Instance.new("Frame")
                    fr.BackgroundColor3 = Color3.new(1,1,1)
                    fr.BorderSizePixel = 0
                    fr.Parent = boxGui
                    o.BoxFrames[i] = fr
                end
            end
        end

        if F.ESP_HealthBar then
            local hb = Instance.new("Frame")
            if F.ESP_HealthBarStyle == "Vertical" then
                hb.Size = UDim2.new(0, 3, 0, 60); hb.Position = UDim2.new(0, -8, 0.5, -30)
            else
                hb.Size = UDim2.new(0, 60, 0, 3); hb.Position = UDim2.new(0.5, -30, 1, 5)
            end
            hb.BackgroundColor3 = Color3.fromRGB(30,30,30); hb.BorderSizePixel = 0; hb.Parent = bb
            o.HealthBar = hb
            local fill = Instance.new("Frame")
            if F.ESP_HealthBarStyle == "Vertical" then
                fill.Size = UDim2.new(1,0,1,0); fill.Position = UDim2.new(0,0,1,0); fill.AnchorPoint = Vector2.new(0,1)
            else
                fill.Size = UDim2.new(1,0,1,0)
            end
            fill.BackgroundColor3 = Color3.fromRGB(0,255,0); fill.BorderSizePixel = 0; fill.Parent = hb
            Instance.new("UICorner", hb).CornerRadius = UDim.new(1,0)
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
            o.HealthBarFill = fill
        end

        if F.ESP_Chams then
            local hl = Instance.new("Highlight"); hl.Name = "ZHL"; hl.Adornee = c
            hl.FillTransparency = F.ESP_FillTransparency
            hl.OutlineTransparency = F.ESP_OutlineTransparency
            hl.DepthMode = F.ESP_Through and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            hl.Parent = c; o.Highlight = hl
        end

        if F.ESP_HeadDot then
            local dot = Instance.new("BillboardGui"); dot.Name = "ZDot"; dot.Adornee = head
            dot.Size = UDim2.new(0, 16, 0, 16); dot.AlwaysOnTop = F.ESP_Through; dot.MaxDistance = math.huge; dot.Parent = head
            local circle = Instance.new("Frame"); circle.Size = UDim2.new(1,0,1,0)
            circle.BackgroundColor3 = Color3.new(1,1,1); circle.BorderSizePixel = 0; circle.Parent = dot
            Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)
            o.HeadDot = dot; o.HeadDotFrame = circle
        end

        if F.ESP_Tracers then
            local line = Instance.new("LineHandleAdornment"); line.Name = "ZTracer"; line.Adornee = root
            line.Length = 0; line.Thickness = 1.5; line.AlwaysOnTop = F.ESP_Through; line.Parent = root
            o.Tracer = line
        end

        if F.ESP_FacingArrow then
            local arrow = Instance.new("BillboardGui"); arrow.Name = "ZArrow"; arrow.Adornee = head
            arrow.Size = UDim2.new(0, 30, 0, 30); arrow.StudsOffset = Vector3.new(0, 4.6, 0)
            arrow.AlwaysOnTop = F.ESP_Through; arrow.MaxDistance = math.huge; arrow.Parent = head
            local img = Instance.new("ImageLabel"); img.Size = UDim2.new(1,0,1,0)
            img.BackgroundTransparency = 1
            img.Image = "rbxassetid://6023426926"
            img.ImageColor3 = Color3.new(1,1,1)
            img.Rotation = 0
            img.Parent = arrow
            o.FacingArrow = arrow; o.FacingArrowImg = img
        end

        if F.ESP_Skeleton then
            o.SkeletonLines = {}
            for i, j in ipairs(SKELETON_JOINTS) do
                local a = c:FindFirstChild(j[1]); local b = c:FindFirstChild(j[2])
                if a and b then
                    local ln = Instance.new("LineHandleAdornment")
                    ln.Name = "ZSk"; ln.Adornee = a; ln.Length = 0; ln.Thickness = 1.5
                    ln.AlwaysOnTop = F.ESP_Through; ln.Parent = a
                    o.SkeletonLines[i] = { line = ln, a = a, b = b }
                end
            end
        end
    end)
    ESPObjects[plr] = o
end

local function refreshESP()
    clearAllESP()
    if not F.ESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then pcall(createESP, p) end
    end
end

-- Player hooks (fix: players joining mid‑game, respawn rebuild)
local function onPlayerAdded(plr)
    if plr == LP then return end
    if F.ESP then
        task.spawn(function()
            -- wait for character
            if not plr.Character then
                plr.CharacterAdded:Wait()
            end
            task.wait(0.2)
            if F.ESP then pcall(createESP, plr) end
        end)
    end
end
local function onPlayerRemoving(plr)
    clearESP(plr)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- CharacterAdded hook for every player (rebuild on respawn)
local function connectCharacterHooks(plr)
    if plr == LP then return end
    local function onChar()
        task.wait(0.3)
        if F.ESP then
            clearESP(plr)
            pcall(createESP, plr)
        end
    end
    if plr.Character then pcall(onChar) end
    plr.CharacterAdded:Connect(onChar)
end
for _, p in ipairs(Players:GetPlayers()) do connectCharacterHooks(p) end
Players.PlayerAdded:Connect(connectCharacterHooks)

-- FOV Circle
local function updateFOVCircle()
    if not F.ESP_FOVCircle then
        if FOVCircleObj then pcall(function() FOVCircleObj:Destroy() end); FOVCircleObj = nil end
        return
    end
    if not FOVCircleObj or not FOVCircleObj.Parent then
        pcall(function()
            FOVCircleObj = Instance.new("ScreenGui"); FOVCircleObj.Name = "ZFOV"
            FOVCircleObj.ResetOnSpawn = false; FOVCircleObj.IgnoreGuiInset = true; FOVCircleObj.Parent = CoreGui
            local c = Instance.new("Frame"); c.Name = "Circle"; c.BackgroundTransparency = 1; c.Parent = FOVCircleObj
            local s = Instance.new("UIStroke"); s.Name = "Stroke"; s.Thickness = 1.5
            s.Color = Color3.new(1,1,1); s.Transparency = 0.3; s.Parent = c
            Instance.new("UICorner", c).CornerRadius = UDim.new(1,0)
        end)
    end
    local c = FOVCircleObj and FOVCircleObj:FindFirstChild("Circle")
    if c then
        local r = F.ESP_FOVRadius
        c.Size = UDim2.new(0, r*2, 0, r*2); c.Position = UDim2.new(0.5, -r, 0.5, -r)
    end
end

--============================================================
-- THREAT ALERTS
--============================================================
local AlertCooldowns = {}
local ThreatGui

local function setupThreatGui()
    if ThreatGui then return end
    pcall(function()
        ThreatGui = Instance.new("ScreenGui")
        ThreatGui.Name = "ZuzyThreat"; ThreatGui.ResetOnSpawn = false
        ThreatGui.IgnoreGuiInset = true; ThreatGui.DisplayOrder = 996; ThreatGui.Parent = CoreGui
        local holder = Instance.new("Frame")
        holder.Name = "Holder"; holder.Size = UDim2.new(0, 320, 0, 100)
        holder.Position = UDim2.new(1, -340, 0, 100)
        holder.BackgroundTransparency = 1; holder.Parent = ThreatGui
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.Parent = holder
        ThreatGui._holder = holder
    end)
end

local function showThreatToast(title, content, color)
    setupThreatGui()
    if not ThreatGui or not ThreatGui._holder then return end
    pcall(function()
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(1, 0, 0, 60)
        fr.BackgroundColor3 = Color3.fromRGB(15, 8, 10)
        fr.BorderSizePixel = 0; fr.Parent = ThreatGui._holder
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 10)
        local st = Instance.new("UIStroke"); st.Color = color; st.Thickness = 2; st.Parent = fr
        local bar = Instance.new("Frame"); bar.Size = UDim2.new(0, 4, 1, 0)
        bar.BackgroundColor3 = color; bar.BorderSizePixel = 0; bar.Parent = fr
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

        local t = Instance.new("TextLabel"); t.Size = UDim2.new(1, -16, 0, 22); t.Position = UDim2.new(0, 12, 0, 6)
        t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = color
        t.Font = Enum.Font.GothamBold; t.TextSize = 14
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = fr

        local c = Instance.new("TextLabel"); c.Size = UDim2.new(1, -16, 0, 26); c.Position = UDim2.new(0, 12, 0, 28)
        c.BackgroundTransparency = 1; c.Text = content; c.TextColor3 = Color3.fromRGB(220,220,230)
        c.Font = Enum.Font.Gotham; c.TextSize = 12
        c.TextXAlignment = Enum.TextXAlignment.Left; c.TextWrapped = true; c.Parent = fr

        task.spawn(function()
            task.wait(4)
            pcall(function()
                local tw = game:GetService("TweenService"):Create(fr, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
                tw:Play()
                task.wait(0.45)
                fr:Destroy()
            end)
        end)
    end)
end

local function playBeep()
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://131961136"
        s.Volume = 0.4
        s.Parent = LP:FindFirstChildOfClass("PlayerGui") or CoreGui
        s:Play()
        Debris:AddItem(s, 1)
    end)
end

local function checkThreats()
    if not F.Alert_OnAim and not F.Alert_OnClose then return end
    local myRoot = GetMyRoot(); if not myRoot then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tr = plr.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (myRoot.Position - tr.Position).Magnitude
                local cd = AlertCooldowns[plr] or 0
                if tick() - cd > F.Alert_Cooldown then
                    if F.Alert_OnAim and isAimingAtMe(plr) and d < 200 then
                        AlertCooldowns[plr] = tick()
                        showThreatToast("⚠ AIMING AT YOU", plr.Name.." is aiming at you ("..math.floor(d).." studs)",
                            Color3.fromRGB(255, 60, 60))
                        if F.Alert_Sound then playBeep() end
                    elseif F.Alert_OnClose and d < F.Alert_CloseDist then
                        AlertCooldowns[plr] = tick()
                        showThreatToast("👤 CLOSE", plr.Name.." is very close ("..math.floor(d).." studs)",
                            Color3.fromRGB(255, 160, 60))
                    end
                end
            end
        end
    end
end

--============================================================
-- TROLL (state‑tracked, no per‑frame writes)
--============================================================
local _freezeState = {}
local _spinState = {}
local _invisState = {}

local function Fling(plr)
    pcall(function()
        local c = plr and plr.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
        local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(9e9,9e9,9e9); bv.Parent = r
        if F.FlingType == "Strong" then bv.Velocity = Vector3.new(math.random(-250,250), math.random(150,250), math.random(-250,250))
        elseif F.FlingType == "Up" then bv.Velocity = Vector3.new(0, math.random(300,450), 0)
        else bv.Velocity = Vector3.new(math.random(-140,140), math.random(90,150), math.random(-140,140)) end
        Debris:AddItem(bv, 0.35)
    end)
end

local function Freeze(p, state)
    if not p or not p.Character then return end
    local h = p.Character:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local uid = p.UserId
    if state then
        if not _freezeState[uid] then
            _freezeState[uid] = { ws = h.WalkSpeed, jp = h.JumpPower }
            h.WalkSpeed = 0
            h.JumpPower = 0
        end
    else
        if _freezeState[uid] then
            h.WalkSpeed = _freezeState[uid].ws or 16
            h.JumpPower = _freezeState[uid].jp or 50
            _freezeState[uid] = nil
        end
    end
end

local function MakeInvis(p, state)
    if not p or not p.Character then return end
    local uid = p.UserId
    if state then
        if not _invisState[uid] then
            _invisState[uid] = {}
            for _, x in ipairs(p.Character:GetDescendants()) do
                if x:IsA("BasePart") or x:IsA("Decal") then
                    _invisState[uid][x] = x.Transparency
                    x.Transparency = 1
                end
            end
        end
    else
        if _invisState[uid] then
            for part, orig in pairs(_invisState[uid]) do
                if part and part.Parent then part.Transparency = orig end
            end
            _invisState[uid] = nil
        end
    end
end

local function SpinT(p, state)
    if not p or not p.Character then return end
    local r = p.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local uid = p.UserId
    if state then
        if not _spinState[uid] then
            local av = Instance.new("BodyAngularVelocity")
            av.MaxTorque = Vector3.new(9e9,9e9,9e9)
            av.AngularVelocity = Vector3.new(0,20,0)
            av.Parent = r
            av.Name = "ZSpin"
            _spinState[uid] = av
        end
    else
        if _spinState[uid] then
            pcall(function() _spinState[uid]:Destroy() end)
            _spinState[uid] = nil
        end
    end
end

local function ForceSit(p) local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid"); if h then h.Sit = true end end
local function Explode(p) local r = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if not r then return end
    local e = Instance.new("Explosion"); e.BlastRadius = 10; e.BlastPressure = 0; e.Position = r.Position; e.Parent = Workspace end

-- EMOTES (fixed)
local EmoteTracks = {}
local function clearEmotes() for _, t in ipairs(EmoteTracks) do pcall(function() t:Stop(); t:Destroy() end) end EmoteTracks = {} end
local function PlayEmote(p, id)
    pcall(function()
        if not p or not p.Character then return end
        local a = p.Character:FindFirstChildOfClass("Animator")
        if not a then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if not h then return end
            a = Instance.new("Animator")
            a.Parent = h
        end
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        local tr = a:LoadAnimation(anim)
        tr:Play()
        table.insert(EmoteTracks, tr)
    end)
end

--============================================================
-- MOVEMENT (separate debounce, noclip remembers originals)
--============================================================
local _noclipOriginals = {}
local _bunnyHopDeb = 0
local _dashDeb = 0
local _flingNearestDeb = 0
local _flingTargetDeb = 0
local _flingAllDeb = 0

local function ApplyStats()
    local h = GetMyHum()
    if h then
        h.WalkSpeed = F.SpeedBoost and 42 or F.WalkSpeed
        h.JumpPower = F.SuperJump and 120 or F.JumpPower
    end
end

local function ApplyNoclip()
    pcall(function()
        local c = LP.Character; if not c then return end
        local noClip = F.NoclipType ~= "None"
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                if noClip then
                    if not _noclipOriginals[p] then _noclipOriginals[p] = p.CanCollide end
                    p.CanCollide = false
                else
                    if _noclipOriginals[p] ~= nil then
                        p.CanCollide = _noclipOriginals[p]
                        _noclipOriginals[p] = nil
                    end
                end
            end
        end
        if not noClip then table.clear(_noclipOriginals) end
    end)
end

local BodyVel, BodyGyro
local function SetupFly()
    pcall(function()
        local r = GetMyRoot(); if not r then return end
        if BodyVel then BodyVel:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
        if F.FlyType ~= "None" then
            BodyVel = Instance.new("BodyVelocity"); BodyVel.MaxForce = Vector3.new(9e9,9e9,9e9); BodyVel.Parent = r
            BodyGyro = Instance.new("BodyGyro"); BodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9); BodyGyro.P = 20000; BodyGyro.Parent = r
        end
    end)
end
local function CleanFly()
    pcall(function()
        if BodyVel then BodyVel:Destroy(); BodyVel = nil end
        if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
    end)
end

local OT = {}
local function SetInvis(s)
    pcall(function()
        local c = LP.Character; if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                if s then
                    if not OT[p] then OT[p] = p.Transparency end
                    p.Transparency = 1
                else
                    if OT[p] then p.Transparency = OT[p] end
                end
            end
        end
        if not s then table.clear(OT) end
    end)
end

local function OnChar()
    task.wait(0.4)
    pcall(ApplyStats)
    pcall(ApplyNoclip)
    if F.FlyType ~= "None" then pcall(SetupFly) end
    if F.Invisible then pcall(SetInvis, true) end
    if F.ESP then task.delay(0.3, refreshESP) end
end
if LP.Character then task.spawn(OnChar) end
LP.CharacterAdded:Connect(function() task.spawn(OnChar) end)

--============================================================
-- DEBUG OVERLAY
--============================================================
local DebugGui, DL = nil, {}
local function setupDebugGui()
    if DebugGui then return end
    pcall(function()
        DebugGui = Instance.new("ScreenGui"); DebugGui.Name = "ZDebug"; DebugGui.ResetOnSpawn = false
        DebugGui.IgnoreGuiInset = true; DebugGui.Parent = CoreGui
        local fr = Instance.new("Frame"); fr.Size = UDim2.new(0, 260, 0, 260); fr.Position = UDim2.new(0, 10, 0.5, -130)
        fr.BackgroundColor3 = Color3.new(0,0,0); fr.BackgroundTransparency = 0.3; fr.BorderSizePixel = 0; fr.Parent = DebugGui
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 8)
        local t = Instance.new("TextLabel"); t.Size = UDim2.new(1,0,0,24); t.BackgroundTransparency = 1
        t.Text = "ZUZIFY DEBUG"; t.TextColor3 = Color3.fromRGB(0,220,180); t.Font = Enum.Font.GothamBold
        t.TextSize = 14; t.Parent = fr
        local function mk(y)
            local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,-12,0,20); l.Position = UDim2.new(0,6,0,y)
            l.BackgroundTransparency = 1; l.TextColor3 = Color3.fromRGB(220,220,230); l.Font = Enum.Font.Code
            l.TextSize = 12; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = fr; return l
        end
        DL.fps = mk(28); DL.ping = mk(48); DL.mem = mk(68); DL.players = mk(88); DL.pos = mk(108)
        DL.role = mk(128); DL.uptime = mk(148); DL.session = mk(168); DL.esp = mk(188)
        DL.theme = mk(208); DL.threats = mk(228)
    end)
end
local function teardownDebugGui() if DebugGui then pcall(function() DebugGui:Destroy() end); DebugGui = nil; DL = {} end end
local boot = tick(); local fpsF, fpsL = 0, tick()

--============================================================
-- MAIN LOOPS
--============================================================
local lastHeavy, lastAnti, lastThreatCheck = 0, 0, 0
local lastSafe = Vector3.new(0, 10, 0)

local function updateDebug(now)
    if not F.Debug_Overlay then if DebugGui then teardownDebugGui() end; return end
    if not DebugGui then setupDebugGui() end
    fpsF = fpsF + 1
    if now - fpsL >= 0.5 then
        local fps = fpsF / (now - fpsL); fpsF = 0; fpsL = now
        if DL.fps then DL.fps.Text = string.format("FPS: %.0f", fps) end
    end
    if now - (DL._p or 0) > 1 then
        DL._p = now
        pcall(function() DL.ping.Text = string.format("Ping: %d ms", math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())) end)
        pcall(function() DL.mem.Text = string.format("Mem: %.1f MB", Stats:GetTotalMemoryUsageMb()) end)
    end
    DL.players.Text = "Players: "..#Players:GetPlayers().."/"..Players.MaxPlayers
    local root = GetMyRoot()
    if root then DL.pos.Text = string.format("Pos: %.0f,%.0f,%.0f", root.Position.X, root.Position.Y, root.Position.Z) end
    DL.role.Text = "Role: "..RoleLabel(MY_ROLE).." / "..RoleLabel(MY_TIER)
    DL.uptime.Text = "Uptime: "..os.date("!%H:%M:%S", math.floor(now - boot))
    DL.session.Text = "Session: "..tostring(SESSION_ID):sub(1, 8)
    if DL.esp then DL.esp.Text = "ESP objs: "..#Players:GetPlayers() end
    if DL.theme then DL.theme.Text = "Theme: "..F.ThemeName end
    if DL.threats then
        local c = 0
        for _ in pairs(AlertCooldowns) do c = c + 1 end
        DL.threats.Text = "Threat cooldowns: "..c
    end
end

-- ESP update (no rebuild on toggle, only visibility)
local function updateESP(now)
    if now - lastHeavy < F.ESP_RefreshRate then return end
    lastHeavy = now
    if not F.ESP then return end
    local root = GetMyRoot(); if not root then return end

    for plr, o in pairs(ESPObjects) do
        -- detect stale / destroyed instances and rebuild
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            clearESP(plr)
        elseif o.Billboard and not o.Billboard.Parent then
            clearESP(plr)
            if F.ESP then pcall(createESP, plr) end
        else
            local c = plr.Character
            local tr = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChildOfClass("Humanoid")
            local d = (root.Position - tr.Position).Magnitude
            local role = GetRole(plr)
            local aiming = F.ESP_AimWarning and isAimingAtMe(plr) or false
            local threat = getThreatLevel(plr, d, aiming)

            local visible = true
            if F.ESP_VisibleCheck then visible = isVisible(plr) end

            local vis = true
            if d > F.ESP_MaxDistance then vis = false end
            if F.ESP_DeadCheck and (not h or h.Health <= 0) then vis = false end
            if F.ESP_ShowOnlyMurderer and role ~= "Murderer" then vis = false end
            if F.ESP_ShowOnlySheriff and role ~= "Sheriff" then vis = false end
            if F.ESP_TeamCheck then
                local myRole = GetRole(LP)
                if myRole == role then vis = false end
            end

            local overallAlpha = 1
            if F.ESP_OccludedFade and not visible then overallAlpha = 0.45 end

            if o.Billboard then o.Billboard.Enabled = vis end
            if o.Highlight then o.Highlight.Enabled = vis end
            if o.Box2D then o.Box2D.Enabled = vis end
            if o.Tracer then o.Tracer.Visible = vis end
            if o.HeadDot then o.HeadDot.Enabled = vis end
            if o.FacingArrow then o.FacingArrow.Enabled = vis end

            if vis then
                local col = getESPColor(plr, d, aiming, threat)
                local tag = ""
                if F.ESP_GoldESP and IsTrusted() then tag = "★ " end

                o.NameLabel.Text = tag..plr.Name.." ["..role.."]"
                o.NameLabel.TextColor3 = col
                o.NameLabel.TextSize = F.ESP_TextSize
                o.NameLabel.TextTransparency = 1 - overallAlpha
                o.NameLabel.Visible = F.ESP_Names and not F.ESP_NameOnly or F.ESP_NameOnly

                local noteData = NotesCache[tostring(plr.UserId)]
                if noteData and (noteData.tag ~= "" or noteData.note ~= "") and F.ESP_ShowNotes then
                    o.TagLabel.Text = (noteData.tag ~= "" and ("["..noteData.tag.."] ") or "")..(noteData.note or "")
                    o.TagLabel.TextColor3 = col; o.TagLabel.TextTransparency = 1 - overallAlpha
                    o.TagLabel.Visible = true
                else
                    o.TagLabel.Visible = false
                end

                o.DistLabel.Text = string.format("%d studs", math.floor(d))
                o.DistLabel.TextColor3 = col; o.DistLabel.TextTransparency = 1 - overallAlpha
                o.DistLabel.Visible = F.ESP_Distance and not F.ESP_NameOnly

                local hp = h and math.floor(h.Health) or 0
                local mx = h and math.floor(h.MaxHealth) or 100
                o.HealthLabel.Text = "HP: "..hp.."/"..mx
                o.HealthLabel.TextColor3 = hp > mx*0.5 and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,50,50)
                o.HealthLabel.TextTransparency = 1 - overallAlpha
                o.HealthLabel.Visible = F.ESP_Health and not F.ESP_NameOnly

                local tool = c:FindFirstChildOfClass("Tool")
                o.WeaponLabel.Text = tool and ("🔫 "..tool.Name) or ""
                o.WeaponLabel.TextTransparency = 1 - overallAlpha
                o.WeaponLabel.Visible = F.ESP_Weapon and tool ~= nil and not F.ESP_NameOnly

                if aiming then
                    o.ThreatLabel.Text = "⚠ AIMING AT YOU"
                    o.ThreatLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
                    o.ThreatLabel.Visible = true
                elseif threat > 0.5 then
                    o.ThreatLabel.Text = string.format("Threat: %d%%", math.floor(threat * 100))
                    o.ThreatLabel.TextColor3 = threatColor(threat)
                    o.ThreatLabel.Visible = true
                else
                    o.ThreatLabel.Visible = false
                end
                o.ThreatLabel.TextTransparency = 1 - overallAlpha

                if o.HealthBar and o.HealthBarFill then
                    local pct = math.clamp(hp / math.max(mx,1), 0, 1)
                    if F.ESP_HealthBarStyle == "Vertical" then
                        o.HealthBarFill.Size = UDim2.new(1,0,pct,0)
                        o.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255*(1-pct), 255*pct, 0)
                    else
                        o.HealthBarFill.Size = UDim2.new(pct,0,1,0)
                        o.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255*(1-pct), 255*pct, 0)
                    end
                    o.HealthBar.Visible = F.ESP_HealthBar and not F.ESP_NameOnly
                    o.HealthBar.BackgroundTransparency = 1 - overallAlpha
                    o.HealthBarFill.BackgroundTransparency = 1 - overallAlpha
                end

                if o.Highlight then
                    o.Highlight.FillColor = col
                    o.Highlight.OutlineColor = col
                    local baseFill = F.ESP_FillTransparency
                    o.Highlight.FillTransparency = baseFill + (1 - overallAlpha) * 0.35
                    o.Highlight.OutlineTransparency = F.ESP_OutlineTransparency
                end

                -- 2D Box scaling
                if o.Box2D and o.BoxFrames then
                    local camPos = Camera.CFrame.Position
                    local distToCam = (camPos - tr.Position).Magnitude
                    local scaleW = math.clamp(1200 / math.max(distToCam, 5), 20, 220)
                    local scaleH = scaleW * 1.8
                    o.Box2D.Size = UDim2.new(0, scaleW, 0, scaleH)
                    for _, fr in ipairs(o.BoxFrames) do
                        fr.BackgroundColor3 = col
                        fr.BackgroundTransparency = 1 - overallAlpha
                    end

                    if F.ESP_BoxStyle == "Corners" then
                        local lw = 0.25; local lh = 0.18
                        o.BoxFrames[1].Size = UDim2.new(lw, 0, 0, 2); o.BoxFrames[1].Position = UDim2.new(0, 0, 0, 0)
                        o.BoxFrames[2].Size = UDim2.new(0, 2, lh, 0); o.BoxFrames[2].Position = UDim2.new(0, 0, 0, 0)
                        o.BoxFrames[3].Size = UDim2.new(lw, 0, 0, 2); o.BoxFrames[3].Position = UDim2.new(1-lw, 0, 0, 0)
                        o.BoxFrames[4].Size = UDim2.new(0, 2, lh, 0); o.BoxFrames[4].Position = UDim2.new(1, -2, 0, 0)
                        o.BoxFrames[5].Size = UDim2.new(lw, 0, 0, 2); o.BoxFrames[5].Position = UDim2.new(0, 0, 1, -2)
                        o.BoxFrames[6].Size = UDim2.new(0, 2, lh, 0); o.BoxFrames[6].Position = UDim2.new(0, 0, 1-lh, 0)
                        o.BoxFrames[7].Size = UDim2.new(lw, 0, 0, 2); o.BoxFrames[7].Position = UDim2.new(1-lw, 0, 1, -2)
                        o.BoxFrames[8].Size = UDim2.new(0, 2, lh, 0); o.BoxFrames[8].Position = UDim2.new(1, -2, 1-lh, 0)
                    else
                        o.BoxFrames[1].Size = UDim2.new(1,0,0,1); o.BoxFrames[1].Position = UDim2.new(0,0,0,0)
                        o.BoxFrames[2].Size = UDim2.new(1,0,0,1); o.BoxFrames[2].Position = UDim2.new(0,0,1,-1)
                        o.BoxFrames[3].Size = UDim2.new(0,1,1,0); o.BoxFrames[3].Position = UDim2.new(0,0,0,0)
                        o.BoxFrames[4].Size = UDim2.new(0,1,1,0); o.BoxFrames[4].Position = UDim2.new(1,-1,0,0)
                    end
                end

                if o.HeadDotFrame then o.HeadDotFrame.BackgroundColor3 = col end

                if o.FacingArrowImg then
                    local head = c:FindFirstChild("Head")
                    if head then
                        local look = head.CFrame.LookVector
                        local angle = math.deg(math.atan2(look.X, look.Z))
                        o.FacingArrowImg.Rotation = -angle
                        o.FacingArrowImg.ImageColor3 = col
                        o.FacingArrowImg.ImageTransparency = 1 - overallAlpha
                    end
                end

                if o.Tracer then
                    o.Tracer.Color3 = col
                    local org = F.ESP_TracersMode == "Bottom"
                        and Vector3.new(Camera.CFrame.Position.X, Camera.CFrame.Position.Y - 5, Camera.CFrame.Position.Z)
                        or (Camera.CFrame.Position + Camera.CFrame.UpVector * 2)
                    local dir = tr.Position - org
                    o.Tracer.Length = dir.Magnitude
                    o.Tracer.CFrame = CFrame.lookAt(org, tr.Position)
                    o.Tracer.Transparency = 1 - overallAlpha
                end

                if o.SkeletonLines then
                    for _, sk in pairs(o.SkeletonLines) do
                        if sk.a and sk.b and sk.a.Parent and sk.b.Parent then
                            local dir = sk.b.Position - sk.a.Position
                            sk.line.Length = dir.Magnitude
                            sk.line.CFrame = CFrame.lookAt(sk.a.Position, sk.b.Position)
                            sk.line.Color3 = col
                            sk.line.Visible = vis
                            sk.line.Transparency = 1 - overallAlpha
                        end
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    local now = tick()
    pcall(updateDebug, now)
    pcall(updateESP, now)
end)

-- Heartbeat loop (separate debounces, optimized PlatformTarget)
RunService.Heartbeat:Connect(function()
    local now = tick()
    pcall(function()
        if F.ESP and F.ESP_AimWarning and now - lastThreatCheck > 0.35 then
            lastThreatCheck = now
            pcall(checkThreats)
        end

        local char = LP.Character
        local root = GetMyRoot()
        local hum = GetMyHum()
        if root and root.Position.Y > -50 then lastSafe = root.Position end
        if not root or not hum then return end

        if F.NoclipType ~= "None" then ApplyNoclip() end

        if F.FlyType ~= "None" and BodyVel and BodyGyro then
            local cam = Camera.CFrame; local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then dir = dir.Unit * F.FlySpeed end
            BodyVel.Velocity = dir
            BodyGyro.CFrame = CFrame.new(root.Position, root.Position + cam.LookVector)
        end

        if F.CFrameSpeed then
            local cam = Camera.CFrame; local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.RightVector end
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude > 0 then root.CFrame += dir.Unit * F.CFrameSpeedValue end
        end

        if F.InfiniteJump then
            local st = hum:GetState()
            local ok2 = st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Running
                    or st == Enum.HumanoidStateType.RunningNoPhysics or st == Enum.HumanoidStateType.Landed
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) and ok2 and now - _bunnyHopDeb > 0.35 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping); _bunnyHopDeb = now
            end
        end
        if F.BunnyHop and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air and now - _bunnyHopDeb > 0.25 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping); _bunnyHopDeb = now
        end
        if F.Dash and UserInputService:IsKeyDown(Enum.KeyCode.Space) and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and now - _dashDeb > 0.5 then
            _dashDeb = now
            local d = Camera.CFrame.LookVector * F.DashPower
            root.AssemblyLinearVelocity = Vector3.new(d.X, 0, d.Z)
        end
        if F.TeleportToMouse and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local m = UserInputService:GetMouseLocation()
            local r = Camera:ScreenPointToRay(m.X, m.Y)
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = { char, Camera }
            local result = Workspace:Raycast(r.Origin, r.Direction * 1000, rayParams)
            if result then root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
        end

        if F.AntiFling and root.AssemblyLinearVelocity.Magnitude > 160 then
            root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
        end
        if F.AntiDie and hum.Health < hum.MaxHealth * 0.2 then hum.Health = hum.MaxHealth end
        if F.AntiVoid and root.Position.Y < -50 then
            root.CFrame = CFrame.new(lastSafe + Vector3.new(0, 5, 0)); root.AssemblyLinearVelocity = Vector3.zero
        end
        if F.AntiSit and hum.Sit then hum.Sit = false end
        if F.AntiRagdoll and hum.PlatformStand then hum.PlatformStand = false end

        if F.AntiAFK and now - lastAnti > 60 then
            lastAnti = now
            pcall(function()
                local x, y = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
                VIM:SendMouseMoveEvent(x + 10, y + 10, false, game)
            end)
        end

        if Camera.FieldOfView ~= F.CustomFOV then Camera.FieldOfView = F.CustomFOV end

        if F.Orbit and F.SelectedTarget then
            local t = GetTarget()
            local tr = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local a = (now * 6) % (math.pi * 2)
                root.CFrame = CFrame.new(tr.Position) * CFrame.Angles(0, a, 0) * CFrame.new(0, 2, F.OrbitDist)
            end
        end
        if F.LoopBehind and F.SelectedTarget then local tr = GetTargetRoot(); if tr then root.CFrame = tr.CFrame * CFrame.new(0,0,3.5) end end
        if F.Piggyback then local tr = GetTargetRoot(); if tr then root.CFrame = tr.CFrame * CFrame.new(0,3.1,0.2) end end
        if F.FrontCarry then local tr = GetTargetRoot(); if tr then root.CFrame = tr.CFrame * CFrame.new(0,0,-3.1) end end
        if F.SideCarry then local tr = GetTargetRoot(); if tr then root.CFrame = tr.CFrame * CFrame.new(2.7,0.4,0) end end

        if F.KillTarget then
            local tr = GetTargetRoot()
            if tr then
                root.CFrame = tr.CFrame * CFrame.new(0, 0, 2.5)
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then pcall(function() tool:Activate() end) end
            end
        end

        if F.Aimbot or F.SilentAim then
            local t = GetClosest(F.AimbotFOV)
            if t and t.Character then
                local part = t.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local goal = part.Position + part.AssemblyLinearVelocity * 0.14
                    if F.SilentAim then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, goal)
                    else Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, goal), 0.13) end
                end
            end
        end

        if F.AutoKill and now - _bunnyHopDeb > 1.2 then
            _bunnyHopDeb = now; local t = char:FindFirstChildOfClass("Tool")
            if t then pcall(function() t:Activate() end) end
        end
        if F.AutoShoot and now - _bunnyHopDeb > 0.4 then
            _bunnyHopDeb = now; local t = char:FindFirstChildOfClass("Tool")
            if t then
                local n = string.lower(t.Name)
                if n:find("gun") or n:find("revolver") then pcall(function() t:Activate() end) end
            end
        end

        if F.KnifeAura then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local tr = p.Character:FindFirstChild("HumanoidRootPart")
                    if tr and (root.Position - tr.Position).Magnitude < F.AuraRange then
                        local t = char:FindFirstChildOfClass("Tool")
                        if t then pcall(function() t:Activate() end) end
                    end
                end
            end
        end

        if F.FlingNearest and now - _flingNearestDeb > 0.55 then _flingNearestDeb = now; local c = GetClosest(55); if c then Fling(c) end end
        if F.FlingTarget and F.SelectedTarget and now - _flingTargetDeb > 0.4 then _flingTargetDeb = now; local t = GetTarget(); if t then Fling(t) end end
        if F.FlingAll and now - _flingAllDeb > 0.85 then _flingAllDeb = now; for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then Fling(p) end end end

        local t = GetTarget()
        if t and t.Character then
            if F.FreezeTarget then Freeze(t, true) else Freeze(t, false) end
            if F.InvisibleTarget then MakeInvis(t, true) else MakeInvis(t, false) end
            if F.SpinTarget then SpinT(t, true) else SpinT(t, false) end
            if F.PlatformTarget then
                local tr = t.Character:FindFirstChild("HumanoidRootPart")
                if tr and not tr:FindFirstChild("ZPlat") then
                    local p = Instance.new("Part"); p.Name = "ZPlat"; p.Size = Vector3.new(8,1,8)
                    p.Anchored = true; p.CanCollide = true; p.Material = Enum.Material.Neon
                    p.Color = Color3.fromRGB(0,200,160); p.CFrame = CFrame.new(tr.Position - Vector3.new(0,3,0)); p.Parent = tr
                end
            end
        end

        -- Clean up platform when toggled off (only once, not every frame)
        if not F.PlatformTarget then
            for _, p in ipairs(Workspace:GetDescendants()) do
                if p.Name == "ZPlat" then pcall(function() p:Destroy() end) end
            end
        end

        if F.FreezeAll then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then Freeze(p, true) end end
        else for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then Freeze(p, false) end end end
        if F.SpinAll then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then SpinT(p, true) end end
        else for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then SpinT(p, false) end end end

        if F.RainbowSelf then
            local hue = now % 1; local c = Color3.fromHSV(hue, 1, 1)
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.Color = c end end
        end
        if F.TrustedRainbowTrail and IsTrusted() then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    local hue = (now + p.Position.X * 0.01 + p.Position.Z * 0.01) % 1
                    p.Color = Color3.fromHSV(hue, 1, 1)
                end
            end
        end
    end)
end)

SetLoading(0.70, "Loading UI…")

--============================================================
-- FLUENT-MODDED (with 3 fallback URLs)
--============================================================
local Fluent, SaveManager, InterfaceManager
local function tryLoad(url)
    local ok, r = pcall(function() return loadstring(game:HttpGet(url, true))() end)
    return ok and r or nil
end

for _, url in ipairs(FLUENT_URLS) do
    Fluent = tryLoad(url)
    if Fluent then break end
end
if not Fluent then
    CloseLoading(); pcall(function() LP:Kick("ZuzifyRBX: UI library failed to load.") end); return
end
_G.__ZUZY_FLUENT = Fluent

-- Addons from modded repo's Addons folder
SaveManager = tryLoad("https://raw.githubusercontent.com/StyearX/Fluent-modded/main/Addons/SaveManager.lua")
InterfaceManager = tryLoad("https://raw.githubusercontent.com/StyearX/Fluent-modded/main/Addons/InterfaceManager.lua")

SetLoading(0.85, "Building UI…")

local Window = Fluent:CreateWindow({
    Title = "ZuzifyRBX "..VERSION,
    SubTitle = "by mrcoptai — "..RoleLabel(MY_ROLE),
    TabWidth = 170, Size = UDim2.fromOffset(640, 520),  -- larger window
    Acrylic = true, Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

task.defer(function() task.wait(0.2); applyTheme(F.ThemeName or "Dark") end)

local Tabs = {
    Home     = Window:AddTab({ Title = "Home",      Icon = "house" }),
    Visuals  = Window:AddTab({ Title = "Visuals",   Icon = "eye" }),
    Detection= Window:AddTab({ Title = "Detection", Icon = "target" }),
    Alerts   = Window:AddTab({ Title = "Alerts",    Icon = "bell" }),
    Movement = Window:AddTab({ Title = "Movement",  Icon = "move" }),
    Roster   = Window:AddTab({ Title = "Roster",    Icon = "users" }),
    Notes    = Window:AddTab({ Title = "Notes",     Icon = "sticky-note" }),
    Online   = Window:AddTab({ Title = "Online",    Icon = "wifi" }),
    Combat   = Window:AddTab({ Title = "Combat",    Icon = "crosshair" }),
    Troll    = Window:AddTab({ Title = "Troll",     Icon = "ghost" }),
    Emotes   = Window:AddTab({ Title = "Emotes",    Icon = "smile" }),
    Anti     = Window:AddTab({ Title = "Anti",      Icon = "shield" }),
    Report   = Window:AddTab({ Title = "Report",    Icon = "flag" }),
    Feedback = Window:AddTab({ Title = "Feedback",  Icon = "message-circle" }),
    Tickets  = Window:AddTab({ Title = "Tickets",   Icon = "ticket" }),
    Apply    = Window:AddTab({ Title = "Apply",     Icon = "file-text" }),
    Presets  = Window:AddTab({ Title = "Presets",   Icon = "save" }),
    Settings = Window:AddTab({ Title = "Settings",  Icon = "settings" }),
    Debug    = Window:AddTab({ Title = "Debug",     Icon = "terminal" }),
    Trusted  = nil, Staff = nil,
}
if IsTrusted() then Tabs.Trusted = Window:AddTab({ Title = "★ Trusted", Icon = "star" }) end

local Options = Fluent.Options
SetLoading(0.92, "Populating tabs…")

--============================================================
-- HOME + ACCOUNT CARD (new)
--============================================================
Tabs.Home:AddParagraph({
    Title = "Welcome to ZuzifyRBX",
    Content = "Version: "..VERSION.."\nRole: "..RoleLabel(MY_ROLE)..
              "\nTier: "..RoleLabel(MY_TIER).."\nTrusted: "..tostring(IsTrusted())..
              "\nWarnings: "..tostring(userRow.warn_count or 0)..
              "\nPayment Mode: "..EFFECTIVE_PAYMENT_MODE..
              "\nScript Mode: "..EFFECTIVE_SCRIPT_MODE,
})

-- Account Card
local function createAccountCard()
    local cardGui = Instance.new("ScreenGui")
    cardGui.Name = "ZuzyAccountCard"; cardGui.ResetOnSpawn = false
    cardGui.IgnoreGuiInset = true; cardGui.DisplayOrder = 995; cardGui.Parent = CoreGui

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 320, 0, 360)
    card.Position = UDim2.new(0.5, -160, 0.5, -180)
    card.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    card.BorderSizePixel = 0
    card.Visible = false
    card.Parent = cardGui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local cardStroke = Instance.new("UIStroke"); cardStroke.Color = Color3.fromRGB(0, 220, 180)
    cardStroke.Thickness = 1.5; cardStroke.Parent = card

    -- Draggable
    local dragging, dragStart, startPos
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = card.Position
        end
    end)
    card.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    card.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 80, 0, 80)
    avatar.Position = UDim2.new(0.5, -40, 0, 16)
    avatar.BackgroundTransparency = 1
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..MY_UID.."&width=150&height=150&format=png"
    avatar.Parent = card
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -32, 0, 24)
    nameLabel.Position = UDim2.new(0, 16, 0, 104)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = MY_NAME
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextSize = 18
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = card

    local displayLabel = Instance.new("TextLabel")
    displayLabel.Size = UDim2.new(1, -32, 0, 18)
    displayLabel.Position = UDim2.new(0, 16, 0, 128)
    displayLabel.BackgroundTransparency = 1
    displayLabel.Text = "@" .. LP.DisplayName
    displayLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    displayLabel.Font = Enum.Font.Gotham; displayLabel.TextSize = 13
    displayLabel.TextXAlignment = Enum.TextXAlignment.Center
    displayLabel.Parent = card

    local uidLabel = Instance.new("TextLabel")
    uidLabel.Size = UDim2.new(1, -32, 0, 16)
    uidLabel.Position = UDim2.new(0, 16, 0, 150)
    uidLabel.BackgroundTransparency = 1
    uidLabel.Text = "User ID: " .. MY_UID
    uidLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
    uidLabel.Font = Enum.Font.Gotham; uidLabel.TextSize = 12
    uidLabel.TextXAlignment = Enum.TextXAlignment.Center
    uidLabel.Parent = card

    local joinLabel = Instance.new("TextLabel")
    joinLabel.Size = UDim2.new(1, -32, 0, 16)
    joinLabel.Position = UDim2.new(0, 16, 0, 168)
    joinLabel.BackgroundTransparency = 1
    joinLabel.Text = "Joined: " .. (LP.AccountAge and (LP.AccountAge .. " days ago") or "N/A")
    joinLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
    joinLabel.Font = Enum.Font.Gotham; joinLabel.TextSize = 12
    joinLabel.TextXAlignment = Enum.TextXAlignment.Center
    joinLabel.Parent = card

    -- Badges row (Premium, Role/Tier, Trusted, Staff)
    local badgeHolder = Instance.new("Frame")
    badgeHolder.Size = UDim2.new(1, -32, 0, 28)
    badgeHolder.Position = UDim2.new(0, 16, 0, 192)
    badgeHolder.BackgroundTransparency = 1
    badgeHolder.Parent = card
    local badgeLayout = Instance.new("UIListLayout")
    badgeLayout.FillDirection = Enum.FillDirection.Horizontal
    badgeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    badgeLayout.Padding = UDim.new(0, 6)
    badgeLayout.Parent = badgeHolder

    local function addBadge(text, color)
        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(0, 0, 1, 0)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundColor3 = color
        b.Text = " " .. text .. " "
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold; b.TextSize = 11
        b.Parent = badgeHolder
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        return b
    end

    if LP.MembershipType == Enum.MembershipType.Premium then addBadge("Premium", Color3.fromRGB(255, 180, 0)) end
    addBadge(RoleLabel(MY_ROLE), Color3.fromRGB(0, 160, 130))
    addBadge(RoleLabel(MY_TIER), Color3.fromRGB(60, 100, 220))
    if IsTrusted() then addBadge("★ Trusted", Color3.fromRGB(255, 215, 0)) end
    if IsStaff() then addBadge("🛡 Staff", Color3.fromRGB(180, 60, 60)) end

    -- Live stats
    local statFrame = Instance.new("Frame")
    statFrame.Size = UDim2.new(1, -32, 0, 50)
    statFrame.Position = UDim2.new(0, 16, 0, 232)
    statFrame.BackgroundTransparency = 1
    statFrame.Parent = card

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(0.5, 0, 0, 20)
    pingLabel.Position = UDim2.new(0, 0, 0, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: …"
    pingLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    pingLabel.Font = Enum.Font.Code; pingLabel.TextSize = 12
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = statFrame

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0.5, 0, 0, 20)
    fpsLabel.Position = UDim2.new(0.5, 0, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: …"
    fpsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    fpsLabel.Font = Enum.Font.Code; fpsLabel.TextSize = 12
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = statFrame

    local placeLabel = Instance.new("TextLabel")
    placeLabel.Size = UDim2.new(1, 0, 0, 20)
    placeLabel.Position = UDim2.new(0, 0, 0, 24)
    placeLabel.BackgroundTransparency = 1
    placeLabel.Text = "Place: " .. PLACE_ID .. " | Job: " .. JOB_ID:sub(1, 8)
    placeLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    placeLabel.Font = Enum.Font.Code; placeLabel.TextSize = 11
    placeLabel.TextXAlignment = Enum.TextXAlignment.Left
    placeLabel.Parent = statFrame

    -- Copy buttons
    local copyHolder = Instance.new("Frame")
    copyHolder.Size = UDim2.new(1, -32, 0, 30)
    copyHolder.Position = UDim2.new(0, 16, 0, 288)
    copyHolder.BackgroundTransparency = 1
    copyHolder.Parent = card
    local copyLayout = Instance.new("UIListLayout")
    copyLayout.FillDirection = Enum.FillDirection.Horizontal
    copyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    copyLayout.Padding = UDim.new(0, 8)
    copyLayout.Parent = copyHolder

    local function addCopyBtn(text, value)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(200, 200, 220)
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
        btn.Parent = copyHolder
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(tostring(value)) end
        end)
    end
    addCopyBtn("Copy UID", MY_UID)
    addCopyBtn("Copy Job ID", JOB_ID)
    addCopyBtn("Copy Profile", "https://www.roblox.com/users/"..MY_UID.."/profile")

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14
    closeBtn.Parent = card
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function() card.Visible = false end)

    -- Update loop for live stats
    task.spawn(function()
        while card.Parent do
            task.wait(0.5)
            if card.Visible then
                local ping = "?"
                pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                pingLabel.Text = "Ping: " .. ping .. " ms"
                local fps = math.floor(1 / RunService.RenderStepped:Wait())
                fpsLabel.Text = "FPS: " .. fps
                placeLabel.Text = "Place: " .. PLACE_ID .. " | Job: " .. JOB_ID:sub(1, 8) .. " | Players: " .. #Players:GetPlayers()
            end
        end
    end)

    return card
end

local accountCard = createAccountCard()

Tabs.Home:AddButton({
    Title = "👤 Open Account Card",
    Callback = function() accountCard.Visible = not accountCard.Visible end
})
Tabs.Home:AddButton({ Title = "Show Status", Callback = function()
    Fluent:Notify({ Title = "Account Status",
        Content = "User: "..MY_NAME.."\nRole: "..RoleLabel(MY_ROLE).."\nTier: "..RoleLabel(MY_TIER)..
                  "\nTrusted: "..tostring(IsTrusted()).."\nTime: "..os.date("%Y-%m-%d %H:%M:%S"),
        Duration = 10 })
end })
Tabs.Home:AddButton({ Title = "Copy User ID", Callback = function() if setclipboard then setclipboard(tostring(MY_UID)) end end })
Tabs.Home:AddButton({ Title = "Copy Job ID", Callback = function() if setclipboard then setclipboard(tostring(JOB_ID)) end end })

-- Inline account info on Home (already shown in paragraph above, but add a few buttons)
Tabs.Home:AddButton({ Title = "📋 Copy Profile Link", Callback = function()
    if setclipboard then setclipboard("https://www.roblox.com/users/"..MY_UID.."/profile") end
end })

--============================================================
-- VISUALS (toggles no longer rebuild; only visibility changes)
--============================================================
Tabs.Visuals:AddToggle("ESP", { Title = "Enable ESP", Default = false, Callback = function(v) F.ESP = v; if v then refreshESP() else clearAllESP() end end })
Tabs.Visuals:AddToggle("ESP_Names", { Title = "Names + Role", Default = true, Callback = function(v) F.ESP_Names = v end })
Tabs.Visuals:AddToggle("ESP_ShowNotes", { Title = "Show Notes/Tags", Default = true, Callback = function(v) F.ESP_ShowNotes = v end })
Tabs.Visuals:AddToggle("ESP_Distance", { Title = "Distance", Default = true, Callback = function(v) F.ESP_Distance = v end })
Tabs.Visuals:AddToggle("ESP_Health", { Title = "Health Text", Default = true, Callback = function(v) F.ESP_Health = v end })
Tabs.Visuals:AddToggle("ESP_HealthBar", { Title = "Health Bar", Default = true, Callback = function(v) F.ESP_HealthBar = v end })
Tabs.Visuals:AddDropdown("ESP_HealthBarStyle", { Title = "Health Bar Style", Values = {"Horizontal","Vertical"}, Default = 1, Callback = function(v) F.ESP_HealthBarStyle = v end })
Tabs.Visuals:AddToggle("ESP_Weapon", { Title = "Weapon", Default = true, Callback = function(v) F.ESP_Weapon = v end })
Tabs.Visuals:AddToggle("ESP_Chams", { Title = "Chams", Default = true, Callback = function(v) F.ESP_Chams = v end })
Tabs.Visuals:AddToggle("ESP_Boxes", { Title = "2D Boxes", Default = true, Callback = function(v) F.ESP_Boxes = v end })
Tabs.Visuals:AddDropdown("ESP_BoxStyle", { Title = "Box Style", Values = {"Corners","Full"}, Default = 1, Callback = function(v) F.ESP_BoxStyle = v end })
Tabs.Visuals:AddToggle("ESP_Tracers", { Title = "Tracers", Default = false, Callback = function(v) F.ESP_Tracers = v end })
Tabs.Visuals:AddDropdown("TracerMode", { Title = "Tracer Mode", Values = {"Top","Bottom"}, Default = 1, Callback = function(v) F.ESP_TracersMode = v end })
Tabs.Visuals:AddToggle("ESP_HeadDot", { Title = "Head Dot", Default = false, Callback = function(v) F.ESP_HeadDot = v end })
Tabs.Visuals:AddToggle("ESP_Skeleton", { Title = "Skeleton", Default = false, Callback = function(v) F.ESP_Skeleton = v end })
Tabs.Visuals:AddToggle("ESP_FacingArrow", { Title = "Facing Arrow", Default = true, Callback = function(v) F.ESP_FacingArrow = v end })
Tabs.Visuals:AddSlider("ESPMaxDist", { Title = "Max Distance", Default = 1500, Min = 100, Max = 5000, Rounding = 100, Callback = function(v) F.ESP_MaxDistance = v end })
Tabs.Visuals:AddSlider("ESPRefresh", { Title = "Refresh Rate", Default = 0.08, Min = 0.03, Max = 0.5, Rounding = 0.01, Callback = function(v) F.ESP_RefreshRate = v end })
Tabs.Visuals:AddToggle("ESP_DeadCheck", { Title = "Hide Dead", Default = true, Callback = function(v) F.ESP_DeadCheck = v end })
Tabs.Visuals:AddToggle("ESP_MurdererOnly", { Title = "Only Murderer", Default = false, Callback = function(v) F.ESP_ShowOnlyMurderer = v end })
Tabs.Visuals:AddToggle("ESP_SheriffOnly", { Title = "Only Sheriff", Default = false, Callback = function(v) F.ESP_ShowOnlySheriff = v end })
Tabs.Visuals:AddToggle("ESP_Through", { Title = "Through Walls", Default = true, Callback = function(v) F.ESP_Through = v; refreshESP() end })
Tabs.Visuals:AddToggle("ESP_NameOnly", { Title = "Name Only (Clean)", Default = false, Callback = function(v) F.ESP_NameOnly = v end })
Tabs.Visuals:AddSlider("ESPTextSize", { Title = "Text Size", Default = 15, Min = 8, Max = 30, Rounding = 1, Callback = function(v) F.ESP_TextSize = v end })
Tabs.Visuals:AddSlider("ESPFill", { Title = "Fill Transparency", Default = 0.55, Min = 0, Max = 1, Rounding = 0.05, Callback = function(v) F.ESP_FillTransparency = v end })
Tabs.Visuals:AddSlider("ESPOutline", { Title = "Outline Transparency", Default = 0.1, Min = 0, Max = 1, Rounding = 0.05, Callback = function(v) F.ESP_OutlineTransparency = v end })
Tabs.Visuals:AddToggle("ESP_FOVCircle", { Title = "FOV Circle", Default = false, Callback = function(v) F.ESP_FOVCircle = v; updateFOVCircle() end })
Tabs.Visuals:AddSlider("FOVRadius", { Title = "FOV Radius", Default = 140, Min = 50, Max = 400, Rounding = 10, Callback = function(v) F.ESP_FOVRadius = v; updateFOVCircle() end })

--============================================================
-- DETECTION
--============================================================
Tabs.Detection:AddParagraph({
    Title = "🎯 Detection & Threat System",
    Content = "Advanced player tracking. Aim detection, visibility raycasting, and threat scoring.",
})

Tabs.Detection:AddDropdown("ESPColorMode", {
    Title = "Color Mode",
    Values = {"Threat","Role","Distance","Health","Rainbow"},
    Default = 1,
    Callback = function(v) F.ESP_ColorMode = v; F.ESP_Rainbow = (v == "Rainbow") end,
})

Tabs.Detection:AddSection("Aim Detection")
Tabs.Detection:AddToggle("ESP_AimWarning", { Title = "Highlight Aimers", Default = true, Callback = function(v) F.ESP_AimWarning = v end })
Tabs.Detection:AddToggle("ESP_AimColorPulse", { Title = "Pulse Red When Aiming", Default = true, Callback = function(v) F.ESP_AimColorPulse = v end })

Tabs.Detection:AddSection("Visibility")
Tabs.Detection:AddToggle("ESP_VisibleCheck", { Title = "Raycast Visibility Check", Default = false, Callback = function(v) F.ESP_VisibleCheck = v end })
Tabs.Detection:AddToggle("ESP_OccludedFade", { Title = "Fade Occluded Players", Default = true, Callback = function(v) F.ESP_OccludedFade = v end })

Tabs.Detection:AddSection("Team / Filters")
Tabs.Detection:AddToggle("ESP_TeamCheck", { Title = "Team Check (hide same role)", Default = false, Callback = function(v) F.ESP_TeamCheck = v end })

Tabs.Detection:AddSection("Threat Colors")
Tabs.Detection:AddColorpicker("ThreatLowColor", { Title = "Safe Color", Default = Color3.fromRGB(80,255,120), Callback = function(c) F.ESP_ThreatColorLow = c end })
Tabs.Detection:AddColorpicker("ThreatMidColor", { Title = "Caution Color", Default = Color3.fromRGB(255,210,80), Callback = function(c) F.ESP_ThreatColorMid = c end })
Tabs.Detection:AddColorpicker("ThreatHighColor", { Title = "Danger Color", Default = Color3.fromRGB(255,60,60), Callback = function(c) F.ESP_ThreatColorHigh = c end })

--============================================================
-- ALERTS
--============================================================
Tabs.Alerts:AddParagraph({
    Title = "🔔 Threat Alerts",
    Content = "Popups on the right side of the screen when someone is aiming at you or approaching.",
})

Tabs.Alerts:AddToggle("Alert_OnAim", { Title = "Alert when someone aims at me", Default = true, Callback = function(v) F.Alert_OnAim = v end })
Tabs.Alerts:AddToggle("Alert_OnClose", { Title = "Alert when someone gets close", Default = false, Callback = function(v) F.Alert_OnClose = v end })
Tabs.Alerts:AddSlider("Alert_CloseDist", { Title = "Close Distance", Default = 20, Min = 5, Max = 100, Rounding = 5, Callback = function(v) F.Alert_CloseDist = v end })
Tabs.Alerts:AddToggle("Alert_Sound", { Title = "Sound on alert", Default = true, Callback = function(v) F.Alert_Sound = v end })
Tabs.Alerts:AddSlider("Alert_Cooldown", { Title = "Cooldown per player (sec)", Default = 4, Min = 1, Max = 30, Rounding = 1, Callback = function(v) F.Alert_Cooldown = v end })
Tabs.Alerts:AddButton({ Title = "Test Alert", Callback = function()
    showThreatToast("⚠ TEST", "This is a test threat alert.", Color3.fromRGB(255,60,60))
end })

--============================================================
-- MOVEMENT
--============================================================
Tabs.Movement:AddDropdown("Noclip", { Title = "Noclip", Values = {"None","Normal","Full"}, Default = 1, Callback = function(v) F.NoclipType = v; ApplyNoclip() end })
Tabs.Movement:AddDropdown("Fly", { Title = "Fly", Values = {"None","BodyVelocity"}, Default = 1, Callback = function(v) F.FlyType = v; if F.FlyType == "None" then CleanFly() else SetupFly() end end })
Tabs.Movement:AddSlider("FlySpeed", { Title = "Fly Speed", Default = 60, Min = 10, Max = 250, Rounding = 5, Callback = function(v) F.FlySpeed = v end })
Tabs.Movement:AddSlider("WalkSpeed", { Title = "Walk Speed", Default = 16, Min = 10, Max = 150, Rounding = 1, Callback = function(v) F.WalkSpeed = v; ApplyStats() end })
Tabs.Movement:AddSlider("JumpPower", { Title = "Jump Power", Default = 50, Min = 30, Max = 200, Rounding = 1, Callback = function(v) F.JumpPower = v; ApplyStats() end })
Tabs.Movement:AddToggle("SpeedBoost", { Title = "Speed Boost", Default = false, Callback = function(v) F.SpeedBoost = v; ApplyStats() end })
Tabs.Movement:AddToggle("SuperJump", { Title = "Super Jump", Default = false, Callback = function(v) F.SuperJump = v; ApplyStats() end })
Tabs.Movement:AddToggle("InfiniteJump", { Title = "Infinite Jump", Default = false, Callback = function(v) F.InfiniteJump = v end })
Tabs.Movement:AddToggle("BunnyHop", { Title = "Bunny Hop", Default = false, Callback = function(v) F.BunnyHop = v end })
Tabs.Movement:AddToggle("Dash", { Title = "Dash (Space+Shift)", Default = false, Callback = function(v) F.Dash = v end })
Tabs.Movement:AddSlider("DashPower", { Title = "Dash Power", Default = 30, Min = 10, Max = 80, Rounding = 1, Callback = function(v) F.DashPower = v end })
Tabs.Movement:AddToggle("CFrameSpeed", { Title = "CFrame Speed", Default = false, Callback = function(v) F.CFrameSpeed = v end })
Tabs.Movement:AddSlider("CFrameMulti", { Title = "CFrame Multi", Default = 2, Min = 1, Max = 10, Rounding = 1, Callback = function(v) F.CFrameSpeedValue = v end })
Tabs.Movement:AddToggle("TeleportMouse", { Title = "Teleport to Mouse (RMB)", Default = false, Callback = function(v) F.TeleportToMouse = v end })
for name, pos in pairs(MapTeleports) do
    Tabs.Movement:AddButton({ Title = "TP → "..name, Callback = function()
        local r = GetMyRoot(); if r then r.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
    end })
end

--============================================================
-- ROSTER
--============================================================
Tabs.Roster:AddParagraph({ Title = "Live Roster", Content = "All players in this server." })
local function pNames() local l = {}; for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(l, p.Name) end end; return l end
local playerDropdown
local initialNames = pNames()
playerDropdown = Tabs.Roster:AddDropdown("TargetDropdown", {
    Title = "Select Player",
    Values = (#initialNames > 0) and initialNames or {"None"},
    Default = 1,
    Callback = function(v) F.SelectedTarget = v end,
})
-- Set initial target
if #initialNames > 0 then F.SelectedTarget = initialNames[1] end

Tabs.Roster:AddButton({ Title = "Refresh Roster", Callback = function()
    local list = pNames(); if #list == 0 then list = {"None"} end
    playerDropdown:SetValues(list)
    Fluent:Notify({ Title = "Refreshed", Content = "Roster updated ("..#list..").", Duration = 3 })
end })
Tabs.Roster:AddButton({ Title = "📋 Show Full Roster", Callback = function()
    local lines = {}; local root = GetMyRoot()
    for _, p in ipairs(Players:GetPlayers()) do
        local tag = (p == LP) and " (you)" or ""
        local dist = ""
        if root and p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then dist = string.format(" — %d studs", math.floor((root.Position - tr.Position).Magnitude)) end
        end
        local note = NotesCache[tostring(p.UserId)]
        local noteStr = note and (" ["..(note.tag or "").."]") or ""
        table.insert(lines, p.Name.." [ID:"..p.UserId.."]"..tag..dist..noteStr)
    end
    Fluent:Notify({ Title = "Roster ("..#Players:GetPlayers()..")", Content = table.concat(lines, "\n"):sub(1,3500), Duration = 15 })
end })
Tabs.Roster:AddButton({ Title = "🎯 Go To Target", Callback = function()
    local t = GetTarget(); local tr = GetTargetRoot(); local r = GetMyRoot()
    if t and tr and r then r.CFrame = tr.CFrame * CFrame.new(0,0,3) end
end })
Tabs.Roster:AddButton({ Title = "🪢 Bring Target", Callback = function()
    local t = GetTarget(); local r = GetMyRoot()
    if t and t.Character and r then
        local tr = t.Character:FindFirstChild("HumanoidRootPart")
        if tr then tr.CFrame = r.CFrame * CFrame.new(0,0,3) end
    end
end })
Tabs.Roster:AddButton({ Title = "👀 Spectate", Callback = function()
    local t = GetTarget()
    if t and t.Character then Camera.CameraSubject = t.Character:FindFirstChildOfClass("Humanoid") end
end })
Tabs.Roster:AddButton({ Title = "❌ Unspectate", Callback = function()
    local h = GetMyHum(); if h then Camera.CameraSubject = h end
end })
Tabs.Roster:AddButton({ Title = "📋 Copy Target Info", Callback = function()
    local t = GetTarget(); if not t then return end
    local info = string.format("Name: %s\nID: %d\nDisplay: %s", t.Name, t.UserId, t.DisplayName)
    if setclipboard then setclipboard(info) end
    Fluent:Notify({ Title = "Copied", Content = info, Duration = 5 })
end })
Tabs.Roster:AddButton({ Title = "💀 Kill Target", Callback = function()
    local t = GetTarget(); local tr = GetTargetRoot(); local r = GetMyRoot()
    if t and tr and r then
        r.CFrame = tr.CFrame * CFrame.new(0, 0, 2.5)
        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end
end })
Tabs.Roster:AddButton({ Title = "🌀 Fling Target", Callback = function() local t = GetTarget(); if t then Fling(t) end end })
Tabs.Roster:AddButton({ Title = "❄ Freeze Target", Callback = function() local t = GetTarget(); if t then Freeze(t, true) end end })
Tabs.Roster:AddButton({ Title = "▶ Unfreeze Target", Callback = function() local t = GetTarget(); if t then Freeze(t, false) end end })

--============================================================
-- NOTES
--============================================================
Tabs.Notes:AddParagraph({ Title = "Player Notes & Tags", Content = "Syncs to Supabase. Shown in ESP + Roster." })
local noteText, noteTag, noteColor = "", "", "#ff8844"
Tabs.Notes:AddInput("NoteText", { Title = "Note", Placeholder = "e.g. known exploiter", Callback = function(t) noteText = t end })
Tabs.Notes:AddInput("NoteTag", { Title = "Tag", Placeholder = "e.g. TRUSTED, TOXIC", Callback = function(t) noteTag = t end })
Tabs.Notes:AddInput("NoteColor", { Title = "Color (hex)", Placeholder = "#ff8844", Callback = function(t) if t:match("^#?%x%x%x%x%x%x$") then noteColor = t end end })
Tabs.Notes:AddButton({ Title = "💾 Save Note for Selected Player", Callback = function()
    local t = GetTarget()
    if not t then Fluent:Notify({ Title = "Error", Content = "Select a player first.", Duration = 4 }); return end
    if noteText == "" and noteTag == "" then Fluent:Notify({ Title = "Error", Content = "Enter a note or tag.", Duration = 4 }); return end
    setNoteFor(t.UserId, t.Name, noteText, noteTag, noteColor)
    Fluent:Notify({ Title = "Saved", Content = "Note saved for "..t.Name, Duration = 4 })
end })
Tabs.Notes:AddButton({ Title = "🗑 Delete Note for Selected Player", Callback = function()
    local t = GetTarget(); if not t then return end
    deleteNote(t.UserId); Fluent:Notify({ Title = "Deleted", Content = "Note removed.", Duration = 4 })
end })
Tabs.Notes:AddButton({ Title = "🔄 Reload Notes from Cloud", Callback = function()
    loadMyNotes(); task.wait(0.5); Fluent:Notify({ Title = "Reloaded", Content = "Notes refreshed.", Duration = 4 })
end })
Tabs.Notes:AddButton({ Title = "📋 View All Notes", Callback = function()
    local lines = {}
    for _, n in pairs(NotesCache) do
        table.insert(lines, "→ "..(n.target_name or "?").." ["..(n.tag or "").."]\n   "..(n.note or ""))
    end
    if #lines == 0 then lines = {"(no notes)"} end
    Fluent:Notify({ Title = "My Notes", Content = table.concat(lines, "\n\n"):sub(1,3500), Duration = 20 })
end })

--============================================================
-- ONLINE
--============================================================
Tabs.Online:AddParagraph({ Title = "Online Users", Content = "Users active across all servers." })
local function fetchOnline()
    task.spawn(function() pcall(function()
        local cutoff = DateTime.now():AddSeconds(-180):ToIsoDate()
        local d = sbGet("zuzify_sessions", "last_ping=gt."..HttpService:UrlEncode(cutoff).."&select=*&order=last_ping.desc")
        local cnt = d and #d or 0
        if cnt == 0 then Fluent:Notify({ Title = "Online", Content = "No users online.", Duration = 6 }); return end
        local lines = { "Total: "..cnt, "" }
        for i, s in ipairs(d) do
            local name = (s.show_username and s.username) and s.username or ("Anon #"..tostring(s.user_id):sub(-4))
            local tag = (s.user_id == MY_UID) and " ⭐ you" or ""
            table.insert(lines, i..". "..name..tag.." — "..RoleLabel(s.role or "user"))
            if i >= 30 then break end
        end
        Fluent:Notify({ Title = "Online ("..cnt..")", Content = table.concat(lines, "\n"):sub(1,3500), Duration = 25 })
    end) end)
end
Tabs.Online:AddButton({ Title = "🔄 Refresh Online Users", Callback = fetchOnline })
Tabs.Online:AddButton({ Title = "📊 Global Stats", Callback = function()
    task.spawn(function() pcall(function()
        local s = sbGet("zuzify_stats", "select=*")
        if s and #s > 0 then
            local r = s[1]
            Fluent:Notify({ Title = "Global Stats",
                Content = "Users: "..(r.total_users or "?").."\nOnline: "..(r.online_now or "?")..
                          "\nPaid: "..(r.paid_users or "?").."\nTrusted: "..(r.trusted_users or "?")..
                          "\nStaff: "..(r.staff_users or "?").."\nBanned: "..(r.banned_users or "?"),
                Duration = 15 })
        end
    end) end)
end })

--============================================================
-- COMBAT
--============================================================
Tabs.Combat:AddToggle("Aimbot", { Title = "Aimbot", Default = false, Callback = function(v) F.Aimbot = v end })
Tabs.Combat:AddToggle("SilentAim", { Title = "Silent Aim", Default = false, Callback = function(v) F.SilentAim = v end })
Tabs.Combat:AddSlider("AimbotFOV", { Title = "Aimbot FOV", Default = 230, Min = 50, Max = 500, Rounding = 10, Callback = function(v) F.AimbotFOV = v end })
Tabs.Combat:AddToggle("AutoKill", { Title = "Auto Kill", Default = false, Callback = function(v) F.AutoKill = v end })
Tabs.Combat:AddToggle("AutoShoot", { Title = "Auto Shoot", Default = false, Callback = function(v) F.AutoShoot = v end })
Tabs.Combat:AddToggle("KnifeAura", { Title = "Knife Aura", Default = false, Callback = function(v) F.KnifeAura = v end })
Tabs.Combat:AddSlider("AuraRange", { Title = "Aura Range", Default = 15, Min = 6, Max = 40, Rounding = 1, Callback = function(v) F.AuraRange = v end })
Tabs.Combat:AddToggle("KillTarget", { Title = "Kill Selected", Default = false, Callback = function(v) F.KillTarget = v end })

--============================================================
-- TROLL
--============================================================
Tabs.Troll:AddDropdown("FlingType", { Title = "Fling Type", Values = {"Normal","Strong","Up"}, Default = 1, Callback = function(v) F.FlingType = v end })
Tabs.Troll:AddToggle("FlingNearest", { Title = "Fling Nearest", Default = false, Callback = function(v) F.FlingNearest = v end })
Tabs.Troll:AddToggle("FlingTarget", { Title = "Fling Selected", Default = false, Callback = function(v) F.FlingTarget = v end })
Tabs.Troll:AddToggle("FlingAll", { Title = "Fling All", Default = false, Callback = function(v) F.FlingAll = v end })
Tabs.Troll:AddToggle("InvisibleSelf", { Title = "Invisible Self", Default = false, Callback = function(v) F.Invisible = v; SetInvis(v) end })
Tabs.Troll:AddToggle("RainbowSelf", { Title = "Rainbow Self", Default = false, Callback = function(v) F.RainbowSelf = v end })
Tabs.Troll:AddToggle("FreezeTarget", { Title = "Freeze Target", Default = false, Callback = function(v) F.FreezeTarget = v end })
Tabs.Troll:AddToggle("InvisibleTarget", { Title = "Invisible Target", Default = false, Callback = function(v) F.InvisibleTarget = v end })
Tabs.Troll:AddToggle("SpinTarget", { Title = "Spin Target", Default = false, Callback = function(v) F.SpinTarget = v end })
Tabs.Troll:AddToggle("PlatformTarget", { Title = "Platform Under Target", Default = false, Callback = function(v) F.PlatformTarget = v end })
Tabs.Troll:AddButton({ Title = "Force Sit", Callback = function() local t = GetTarget(); if t then ForceSit(t) end end })
Tabs.Troll:AddButton({ Title = "Explode Target", Callback = function() local t = GetTarget(); if t then Explode(t) end end })
Tabs.Troll:AddToggle("FreezeAll", { Title = "Freeze All", Default = false, Callback = function(v) F.FreezeAll = v end })
Tabs.Troll:AddToggle("SpinAll", { Title = "Spin All", Default = false, Callback = function(v) F.SpinAll = v end })
Tabs.Troll:AddButton({ Title = "Explode All", Callback = function() for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then Explode(p) end end end })

--============================================================
-- EMOTES
--============================================================
local eNames = {}; for _, e in ipairs(EmoteList) do table.insert(eNames, e.Name) end
Tabs.Emotes:AddDropdown("EmoteDropdown", { Title = "Emote", Values = eNames, Default = 1,
    Callback = function(v) for _, e in ipairs(EmoteList) do if e.Name == v then F.SelectedEmote = e.ID end end end })
Tabs.Emotes:AddInput("CustomEmote", { Title = "Custom Emote ID", Callback = function(t) if t ~= "" then F.SelectedEmote = t end end })
Tabs.Emotes:AddButton({ Title = "Play on Self", Callback = function() if F.SelectedEmote then clearEmotes(); PlayEmote(LP, F.SelectedEmote) end end })
Tabs.Emotes:AddButton({ Title = "Play on Target", Callback = function() local t = GetTarget(); if t and F.SelectedEmote then clearEmotes(); PlayEmote(t, F.SelectedEmote) end end })
Tabs.Emotes:AddButton({ Title = "Stop All Emotes", Callback = clearEmotes })

--============================================================
-- ANTI
--============================================================
Tabs.Anti:AddToggle("AntiAFK", { Title = "Anti AFK", Default = true, Callback = function(v) F.AntiAFK = v end })
Tabs.Anti:AddToggle("AntiFling", { Title = "Anti Fling", Default = true, Callback = function(v) F.AntiFling = v end })
Tabs.Anti:AddToggle("AntiDie", { Title = "Anti Die", Default = false, Callback = function(v) F.AntiDie = v end })
Tabs.Anti:AddToggle("AntiVoid", { Title = "Anti Void", Default = false, Callback = function(v) F.AntiVoid = v end })
Tabs.Anti:AddToggle("AntiSit", { Title = "Anti Sit", Default = false, Callback = function(v) F.AntiSit = v end })
Tabs.Anti:AddToggle("AntiRagdoll", { Title = "Anti Ragdoll", Default = false, Callback = function(v) F.AntiRagdoll = v end })

--============================================================
-- REPORT / FEEDBACK / TICKETS / APPLY
--============================================================
Tabs.Report:AddParagraph({ Title = "Report a User", Content = "Report someone for breaking rules." })
local reportTargetName, reportCategory, reportDetails = "", "cheating", ""
Tabs.Report:AddInput("ReportTarget", { Title = "Target Username or ID", Callback = function(t) reportTargetName = t end })
Tabs.Report:AddDropdown("ReportCategory", { Title = "Category", Values = {"cheating","exploiting","toxicity","harassment","scamming","bug-abuse","other"}, Default = 1, Callback = function(v) reportCategory = v end })
Tabs.Report:AddInput("ReportDetails", { Title = "What happened?", Callback = function(t) reportDetails = t end })
Tabs.Report:AddButton({ Title = "Submit Report", Callback = function()
    if reportTargetName == "" or reportDetails == "" then Fluent:Notify({ Title = "Error", Content = "Fill target + details.", Duration = 4 }); return end
    task.spawn(function() pcall(function()
        local targetId = tonumber(reportTargetName)
        local targetP = Players:FindFirstChild(reportTargetName)
        if targetP then targetId = targetP.UserId end
        sbPost("zuzify_reports", { reporter_id=MY_UID, reporter_name=MY_NAME,
            target_id=targetId, target_name=reportTargetName,
            category=reportCategory, details=reportDetails, status="open" })
        Fluent:Notify({ Title = "Report Sent", Content = "Thank you.", Duration = 6 })
    end) end)
end })

Tabs.Feedback:AddParagraph({ Title = "Send Feedback", Content = "Tell us what you think!" })
local fbCategory, fbRating, fbSubject, fbMessage = "general", 5, "", ""
Tabs.Feedback:AddDropdown("FbCategory", { Title = "Category", Values = {"general","bug","feature","ui","performance","suggestion"}, Default = 1, Callback = function(v) fbCategory = v end })
Tabs.Feedback:AddSlider("FbRating", { Title = "Rating", Default = 5, Min = 1, Max = 5, Rounding = 1, Callback = function(v) fbRating = v end })
Tabs.Feedback:AddInput("FbSubject", { Title = "Subject", Callback = function(t) fbSubject = t end })
Tabs.Feedback:AddInput("FbMessage", { Title = "Message", Callback = function(t) fbMessage = t end })
Tabs.Feedback:AddButton({ Title = "Submit Feedback", Callback = function()
    if fbMessage == "" then Fluent:Notify({ Title = "Error", Content = "Message required.", Duration = 4 }); return end
    task.spawn(function() pcall(function()
        sbPost("zuzify_feedback", { author_id=MY_UID, author_name=MY_NAME,
            category=fbCategory, rating=fbRating, subject=fbSubject, message=fbMessage, status="new" })
        Fluent:Notify({ Title = "Feedback Sent", Content = "Thanks! ⭐", Duration = 6 })
    end) end)
end })

Tabs.Tickets:AddParagraph({ Title = "Support Tickets", Content = "Create a ticket to talk to staff." })
local ticketSubject, ticketCategory, ticketPriority, ticketBody = "", "general", "normal", ""
Tabs.Tickets:AddInput("TicketSubject", { Title = "Subject", Callback = function(t) ticketSubject = t end })
Tabs.Tickets:AddDropdown("TicketCategory", { Title = "Category", Values = {"general","bug","report","appeal","purchase","other"}, Default = 1, Callback = function(v) ticketCategory = v end })
Tabs.Tickets:AddDropdown("TicketPriority", { Title = "Priority", Values = {"low","normal","high","urgent"}, Default = 2, Callback = function(v) ticketPriority = v end })
Tabs.Tickets:AddInput("TicketBody", { Title = "Describe", Callback = function(t) ticketBody = t end })
Tabs.Tickets:AddButton({ Title = "Create Ticket", Callback = function()
    if ticketSubject == "" or ticketBody == "" then Fluent:Notify({ Title = "Error", Content = "Subject + body required.", Duration = 4 }); return end
    task.spawn(function() pcall(function()
        local created = sbPost("zuzify_tickets", {
            subject=ticketSubject, category=ticketCategory, priority=ticketPriority,
            status="open", creator_id=MY_UID, creator_name=MY_NAME,
            last_message=ticketBody:sub(1,150), last_activity=nowISO() })
        if created and #created > 0 then
            local tid = created[1].id
            sbPost("zuzify_ticket_messages", { ticket_id=tid, sender_id=MY_UID,
                sender_name=MY_NAME, sender_role=MY_ROLE, message=ticketBody })
            Fluent:Notify({ Title = "Ticket Created", Content = "ID: "..tostring(tid):sub(1,8), Duration = 8 })
        end
    end) end)
end })

Tabs.Apply:AddParagraph({ Title = "Apply for Staff", Content = "Fill out the form." })
local appFor, appExperience, appWhy, appHours, appAge = "moderator", "", "", "", ""
Tabs.Apply:AddDropdown("AppFor", { Title = "Position", Values = {"moderator","head_moderator","admin","head_admin","community_manager","developer"}, Default = 1, Callback = function(v) appFor = v end })
Tabs.Apply:AddInput("AppExperience", { Title = "Experience", Callback = function(t) appExperience = t end })
Tabs.Apply:AddInput("AppWhy", { Title = "Why you?", Callback = function(t) appWhy = t end })
Tabs.Apply:AddInput("AppHours", { Title = "Hours/week", Callback = function(t) appHours = t end })
Tabs.Apply:AddInput("AppAge", { Title = "Age", Callback = function(t) appAge = t end })
Tabs.Apply:AddButton({ Title = "Submit Application", Callback = function()
    if GlobalSettings.applications_open ~= "true" then
        Fluent:Notify({ Title = "Applications Closed", Content = "Applications are currently closed.", Duration = 5 }); return
    end
    if appWhy == "" or appExperience == "" then Fluent:Notify({ Title = "Error", Content = "Fill fields.", Duration = 4 }); return end
    task.spawn(function() pcall(function()
        sbPost("zuzify_applications", { applicant_id=MY_UID, applicant_name=MY_NAME,
            applying_for=appFor, experience=appExperience, why_apply=appWhy,
            hours_per_week=appHours, age=appAge, status="pending" })
        Fluent:Notify({ Title = "Application Sent", Content = "Owner will review.", Duration = 8 })
    end) end)
end })

--============================================================
-- PRESETS
--============================================================
Tabs.Presets:AddParagraph({ Title = "Config Presets", Content = "Save/load complete configs by name." })
local presetName = ""
Tabs.Presets:AddInput("PresetName", { Title = "Preset Name", Placeholder = "e.g. ESP Only", Callback = function(t) presetName = t end })
Tabs.Presets:AddButton({ Title = "💾 Save as Preset", Callback = function()
    if presetName == "" then return end
    task.spawn(function() pcall(function()
        local cfg = serializeConfig()
        local d = sbGet("zuzify_configs", "user_id=eq."..MY_UID.."&name=eq."..HttpService:UrlEncode(presetName).."&select=id")
        if d and #d > 0 then
            sbPatch("zuzify_configs", "user_id=eq."..MY_UID.."&name=eq."..HttpService:UrlEncode(presetName),
                { config=cfg, updated_at=nowISO() })
        else
            sbPost("zuzify_configs", { user_id=MY_UID, name=presetName, config=cfg })
        end
        Fluent:Notify({ Title = "Saved", Content = "Preset '"..presetName.."' saved.", Duration = 5 })
    end) end)
end })
Tabs.Presets:AddButton({ Title = "📥 Load Preset", Callback = function()
    if presetName == "" then return end
    task.spawn(function() pcall(function()
        local d = sbGet("zuzify_configs", "user_id=eq."..MY_UID.."&name=eq."..HttpService:UrlEncode(presetName).."&select=*")
        if d and #d > 0 and d[1].config then
            deserializeConfig(d[1].config)
            applyTheme(F.ThemeName or "Dark"); refreshESP()
            Fluent:Notify({ Title = "Loaded", Content = "Preset applied. Some toggles need rejoin.", Duration = 8 })
        else
            Fluent:Notify({ Title = "Not Found", Content = "No preset named '"..presetName.."'.", Duration = 4 })
        end
    end) end)
end })
Tabs.Presets:AddButton({ Title = "🗑 Delete Preset", Callback = function()
    if presetName == "" then return end
    task.spawn(function() pcall(function()
        sbDelete("zuzify_configs", "user_id=eq."..MY_UID.."&name=eq."..HttpService:UrlEncode(presetName))
        Fluent:Notify({ Title = "Deleted", Content = "Preset removed.", Duration = 4 })
    end) end)
end })
Tabs.Presets:AddButton({ Title = "📋 List All Presets", Callback = function()
    task.spawn(function() pcall(function()
        local d = sbGet("zuzify_configs", "user_id=eq."..MY_UID.."&select=name,updated_at&order=updated_at.desc")
        local cnt = d and #d or 0
        if cnt == 0 then Fluent:Notify({ Title = "Presets", Content = "No presets.", Duration = 5 }); return end
        local lines = {}
        for i, p in ipairs(d) do table.insert(lines, i..". "..p.name.." — "..FormatTime(p.updated_at)) end
        Fluent:Notify({ Title = "My Presets ("..cnt..")", Content = table.concat(lines, "\n"), Duration = 15 })
    end) end)
end })

--============================================================
-- SETTINGS
--============================================================
if SaveManager then pcall(function()
    SaveManager:SetLibrary(Fluent); SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({}); SaveManager:SetFolder("ZuzifyRBX/Configs")
end) end
if InterfaceManager then pcall(function()
    InterfaceManager:SetLibrary(Fluent); InterfaceManager:SetFolder("ZuzifyRBX")
end) end

Tabs.Settings:AddParagraph({ Title = "About", Content = "ZuzifyRBX "..VERSION.."\nOwner: mrcoptai\nTime: "..os.date("%Y-%m-%d %H:%M:%S") })
Tabs.Settings:AddButton({ Title = "👤 Open Account Card", Callback = function() accountCard.Visible = not accountCard.Visible end })

Tabs.Settings:AddDropdown("ThemePicker", {
    Title = "🎨 Theme",
    Values = ThemeNames,
    Default = table.find(ThemeNames, F.ThemeName) or 1,
    Callback = function(v)
        F.ThemeName = v; applyTheme(v)
        pcall(function() sbPatch("zuzify_users", "user_id=eq."..MY_UID, { theme_name = v }) end)
        Fluent:Notify({ Title = "Theme", Content = "Applied: "..v, Duration = 3 })
    end,
})

Tabs.Settings:AddSection("☁ Cloud Config")
Tabs.Settings:AddToggle("CloudAutoSave", { Title = "Auto-Save to Cloud (3m)", Default = false, Callback = function(v) F.CloudAutoSave = v end })
Tabs.Settings:AddToggle("CloudAutoLoad", { Title = "Auto-Load on Join", Default = true, Callback = function(v) F.CloudAutoLoad = v end })
Tabs.Settings:AddButton({ Title = "💾 Save to Cloud Now", Callback = function()
    task.spawn(function()
        local ok = saveConfigToCloud()
        Fluent:Notify({ Title = "Cloud Save", Content = ok and "✅ Saved." or "❌ Failed.", Duration = 4 })
    end)
end })
Tabs.Settings:AddButton({ Title = "📂 Load from Cloud Now", Callback = function()
    task.spawn(function()
        local ok = loadConfigFromCloud()
        if ok then applyTheme(F.ThemeName or "Dark"); refreshESP()
            Fluent:Notify({ Title = "Cloud Load", Content = "✅ Loaded. Some toggles need rejoin.", Duration = 6 })
        else Fluent:Notify({ Title = "Cloud Load", Content = "❌ No saved config.", Duration = 4 }) end
    end)
end })
Tabs.Settings:AddButton({ Title = "🔄 Reset Local Config", Callback = function()
    for k, v in pairs(F) do if type(v) == "boolean" then F[k] = false end end
    Fluent:Notify({ Title = "Reset", Content = "Local toggles cleared.", Duration = 4 })
end })
Tabs.Settings:AddSection("Account")
Tabs.Settings:AddToggle("ShareUsername", {
    Title = "Share Username (Trusted Program)",
    Default = F.ShareUsername,
    Callback = function(v)
        F.ShareUsername = v
        task.spawn(function() pcall(function()
            sbPatch("zuzify_users", "user_id=eq."..MY_UID, { show_username = v })
        end) end)
    end,
})
Tabs.Settings:AddButton({ Title = "Rejoin Server", Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
end })
if InterfaceManager then pcall(function() InterfaceManager:BuildInterfaceSection(Tabs.Settings) end) end
if SaveManager then pcall(function() SaveManager:BuildConfigSection(Tabs.Settings) end) end

--============================================================
-- DEBUG
--============================================================
Tabs.Debug:AddToggle("DebugOverlay", { Title = "Debug Overlay", Default = false, Callback = function(v) F.Debug_Overlay = v; if not v then teardownDebugGui() end end })
Tabs.Debug:AddButton({ Title = "Rebuild ESP", Callback = function() refreshESP(); Fluent:Notify({ Title = "ESP", Content = "Rebuilt.", Duration = 3 }) end })
Tabs.Debug:AddButton({ Title = "Clear Role Cache", Callback = function() CachedRoles = {}; Fluent:Notify({ Title = "Cache", Content = "Cleared.", Duration = 3 }) end })
Tabs.Debug:AddButton({ Title = "🔄 Reload Notes", Callback = function() loadMyNotes(); Fluent:Notify({ Title = "Notes", Content = "Reloaded.", Duration = 3 }) end })
Tabs.Debug:AddButton({ Title = "🔄 Re-apply Theme", Callback = function() applyTheme(F.ThemeName or "Dark"); Fluent:Notify({ Title = "Theme", Content = "Re-applied.", Duration = 3 }) end })

--============================================================
-- TRUSTED
--============================================================
if IsTrusted() and Tabs.Trusted then
    Tabs.Trusted:AddParagraph({ Title = "★ Trusted Program", Content = "Exclusive perks." })
    Tabs.Trusted:AddToggle("TrustedRainbowTrail", { Title = "★ Rainbow Trail", Default = false, Callback = function(v) F.TrustedRainbowTrail = v end })
    Tabs.Trusted:AddToggle("TrustedGoldESP", { Title = "★ Gold ESP", Default = false, Callback = function(v) F.ESP_GoldESP = v end })
    Tabs.Trusted:AddColorpicker("TrustedColorPicker", { Title = "★ Gold ESP Color", Default = Color3.fromRGB(255,215,0), Callback = function(c) F.ESP_TrustedColor = c end })
    Tabs.Trusted:AddToggle("TrustedPrivateNotify", { Title = "★ Private Notifications", Default = true, Callback = function(v) F.TrustedPrivateNotify = v end })
    Tabs.Trusted:AddToggle("TrustedAutoSave", { Title = "★ Auto-Save Config (5m)", Default = false, Callback = function(v)
        F.TrustedAutoSave = v
        if v then task.spawn(function() while F.TrustedAutoSave do task.wait(300); saveConfigToCloud() end end) end
    end })
    Tabs.Trusted:AddInput("TrustedTitle", { Title = "★ Custom Title", Placeholder = "e.g. Verified", Callback = function(t)
        pcall(function()
            F.TrustedCustomTitle = t
            local tf = MY_TRUSTED_FEATURES or {}; tf.custom_title = t
            sbPatch("zuzify_users", "user_id=eq."..MY_UID, { trusted_features = tf })
            Fluent:Notify({ Title = "Saved", Content = "Custom title saved.", Duration = 4 })
        end)
    end })
end

--============================================================
-- STAFF TAB
--============================================================
if IsStaff() then
    local StaffTab = Window:AddTab({ Title = RoleLabel(MY_ROLE), Icon = "crown" })
    StaffTab:AddParagraph({ Title = "Staff Panel", Content = "Welcome, "..MY_NAME.."." })

    StaffTab:AddButton({ Title = "🌐 Online Users", Callback = fetchOnline })
    StaffTab:AddButton({ Title = "📊 Global Stats", Callback = function()
        task.spawn(function() pcall(function()
            local s = sbGet("zuzify_stats", "select=*")
            if s and #s > 0 then
                local r = s[1]
                Fluent:Notify({ Title = "Global Stats",
                    Content = "Users: "..(r.total_users or "?").."\nOnline: "..(r.online_now or "?")..
                              "\nPaid: "..(r.paid_users or "?").."\nTrusted: "..(r.trusted_users or "?")..
                              "\nBanned: "..(r.banned_users or "?").."\nStaff: "..(r.staff_users or "?"),
                    Duration = 15 })
            end
        end) end)
    end })

    StaffTab:AddSection("📣 Announcements")
    StaffTab:AddButton({ Title = "View Active", Callback = function()
        task.spawn(function() pcall(function()
            local d = sbGet("zuzify_announcements", "active=eq.true&select=*&order=created_at.desc&limit=15")
            local cnt = d and #d or 0
            if cnt == 0 then Fluent:Notify({ Title = "Announcements", Content = "None active.", Duration = 5 }); return end
            local lines = {}
            for i, a in ipairs(d) do table.insert(lines, i..". ["..a.priority.."] "..a.title.."\n   "..a.content:sub(1,200)) end
            Fluent:Notify({ Title = "Active: "..cnt, Content = table.concat(lines, "\n\n"):sub(1,3500), Duration = 25 })
        end) end)
    end })

    if IsAdmin() then
        local annTitle, annContent, annPriority, annExpireDays = "", "", "normal", 0
        StaffTab:AddInput("AnnTitle", { Title = "Title", Callback = function(t) annTitle = t end })
        StaffTab:AddInput("AnnContent", { Title = "Content", Callback = function(t) annContent = t end })
        StaffTab:AddDropdown("AnnPriority", { Title = "Priority", Values = {"low","normal","high","urgent"}, Default = 2, Callback = function(v) annPriority = v end })
        StaffTab:AddSlider("AnnExpire", { Title = "Expires in Days (0=never)", Default = 0, Min = 0, Max = 90, Rounding = 1, Callback = function(v) annExpireDays = v end })
        StaffTab:AddButton({ Title = "📣 Post Announcement", Callback = function()
            if annTitle == "" or annContent == "" then return end
            task.spawn(function() pcall(function()
                local exp = annExpireDays > 0 and DateTime.now():AddSeconds(annExpireDays*86400):ToIsoDate() or nil
                sbPost("zuzify_announcements", { title=annTitle, content=annContent,
                    priority=annPriority, active=true, created_by=MY_UID, expires_at=exp })
                Fluent:Notify({ Title = "Posted", Content = "Announcement sent!", Duration = 6 })
            end) end)
        end })
    end

    local modTarget, modReason = "", ""
    StaffTab:AddSection("Moderation")
    StaffTab:AddInput("ModTarget", { Title = "Target User ID", Callback = function(t) modTarget = t end })
    StaffTab:AddInput("ModReason", { Title = "Reason", Callback = function(t) modReason = t end })
    StaffTab:AddButton({ Title = "⚠ Warn User", Callback = function()
        if modTarget == "" or modReason == "" then return end
        task.spawn(function() pcall(function()
            sbPost("zuzify_warnings", { user_id=tonumber(modTarget), moderator_id=MY_UID,
                moderator_name=MY_NAME, reason=modReason, severity=1 })
            sbPost("zuzify_audit_logs", { action="warn", actor_id=MY_UID, actor_name=MY_NAME,
                target_id=tonumber(modTarget), reason=modReason })
            Fluent:Notify({ Title = "Warned", Content = "Done.", Duration = 4 })
        end) end)
    end })
    StaffTab:AddButton({ Title = "👢 Kick User", Callback = function()
        if modTarget == "" then return end
        task.spawn(function() pcall(function()
            sbPatch("zuzify_users", "user_id=eq."..modTarget, { kick_signal=true, kick_reason=modReason })
            Fluent:Notify({ Title = "Kicked", Content = "Queued.", Duration = 4 })
        end) end)
    end })

    if IsAdmin() then
        local banMins = 60
        StaffTab:AddSlider("BanMinutes", { Title = "Ban Minutes (0=perm)", Default = 60, Min = 0, Max = 43200, Rounding = 1, Callback = function(v) banMins = v end })
        StaffTab:AddButton({ Title = "🚫 Ban User", Callback = function()
            if modTarget == "" then return end
            task.spawn(function() pcall(function()
                local u = banMins > 0 and DateTime.now():AddSeconds(banMins*60):ToIsoDate() or nil
                sbPatch("zuzify_users", "user_id=eq."..modTarget, { is_banned=true, ban_reason=modReason, ban_until=u, ban_by=MY_UID })
                Fluent:Notify({ Title = "Banned", Content = "Done.", Duration = 4 })
            end) end)
        end })
        StaffTab:AddButton({ Title = "✅ Unban User", Callback = function()
            if modTarget == "" then return end
            task.spawn(function() pcall(function()
                sbPatch("zuzify_users", "user_id=eq."..modTarget, { is_banned=false, ban_reason=nil, ban_until=nil })
                Fluent:Notify({ Title = "Unbanned", Content = "Done.", Duration = 4 })
            end) end)
        end })

        local newTier, newDays, keyCount = "premium", 30, 5
        StaffTab:AddSection("Key Generation")
        StaffTab:AddDropdown("KeyTier", { Title = "Key Tier", Values = {"basic","premium","trusted","moderator","head_moderator","admin","head_admin","community_manager","developer"}, Default = 1, Callback = function(v) newTier = v end })
        StaffTab:AddSlider("KeyDays", { Title = "Key Days", Default = 30, Min = 1, Max = 3650, Rounding = 1, Callback = function(v) newDays = v end })
        StaffTab:AddSlider("KeyCount", { Title = "Key Count", Default = 5, Min = 1, Max = 50, Rounding = 1, Callback = function(v) keyCount = v end })
        StaffTab:AddButton({ Title = "🎲 Generate Keys", Callback = function()
            task.spawn(function() pcall(function()
                local function blk()
                    local s = ""; local ch = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                    for _ = 1, 4 do s = s..ch:sub(math.random(1,#ch), math.random(1,#ch)) end
                    return s
                end
                local keys = {}
                for i = 1, keyCount do
                    local k = "ZUZIFY-"..blk().."-"..blk().."-"..blk()
                    sbPost("zuzify_keys", { license_key=k, tier=newTier, created_by=MY_UID, duration_days=newDays, is_active=true })
                    table.insert(keys, k)
                    task.wait(0.05)
                end
                local text = table.concat(keys, "\n")
                if setclipboard then setclipboard(text) end
                Fluent:Notify({ Title = "Generated "..keyCount, Content = text:sub(1,3500), Duration = 15 })
            end) end)
        end })
    end

    if IsOwner() then
        local roleTarget, roleGive = "", "trusted"
        StaffTab:AddSection("Owner Controls")
        StaffTab:AddInput("RoleTarget", { Title = "User ID for Role", Callback = function(t) roleTarget = t end })
        StaffTab:AddDropdown("RoleGive", {
            Title = "Role to Give",
            Values = {"user","basic","premium","trusted","moderator","head_moderator","admin","head_admin","community_manager","developer","owner"},
            Default = 5, Callback = function(v) roleGive = v end,
        })
        StaffTab:AddButton({ Title = "✅ Give Role", Callback = function()
            if roleTarget == "" then return end
            task.spawn(function() pcall(function()
                sbPatch("zuzify_users", "user_id=eq."..roleTarget, { role=roleGive, tier=roleGive })
                Fluent:Notify({ Title = "Role Applied", Content = roleTarget.." → "..RoleLabel(roleGive), Duration = 5 })
            end) end)
        end })

        StaffTab:AddSection("Global Settings (Live)")
        StaffTab:AddDropdown("ScriptMode", { Title = "Script Mode", Values = {"online","offline","maintenance"}, Default = 1,
            Callback = function(v) task.spawn(function() pcall(function()
                sbPatch("zuzify_settings", "key=eq.script_mode", { value=v, updated_at=nowISO(), updated_by=MY_UID })
                GlobalSettings.script_mode = v
                Fluent:Notify({ Title = "Global", Content = "Script → "..v, Duration = 5 })
            end) end) end })
        StaffTab:AddDropdown("PaymentMode", { Title = "Payment Mode", Values = {"free","paid","paid_free"}, Default = 1,
            Callback = function(v) task.spawn(function() pcall(function()
                sbPatch("zuzify_settings", "key=eq.payment_mode", { value=v, updated_at=nowISO(), updated_by=MY_UID })
                GlobalSettings.payment_mode = v
                Fluent:Notify({ Title = "Global", Content = "Payment → "..v, Duration = 5 })
            end) end) end })
        StaffTab:AddDropdown("ApplicationsOpen", { Title = "Applications Open?", Values = {"true","false"}, Default = 1,
            Callback = function(v) task.spawn(function() pcall(function()
                sbPatch("zuzify_settings", "key=eq.applications_open", { value=v, updated_at=nowISO(), updated_by=MY_UID })
                GlobalSettings.applications_open = v
            end) end) end })
        StaffTab:AddDropdown("TicketsOpen", { Title = "Tickets Open?", Values = {"true","false"}, Default = 1,
            Callback = function(v) task.spawn(function() pcall(function()
                sbPatch("zuzify_settings", "key=eq.tickets_open", { value=v, updated_at=nowISO(), updated_by=MY_UID })
                GlobalSettings.tickets_open = v
            end) end) end })
        StaffTab:AddButton({ Title = "🔄 Force-Refresh Settings", Callback = function()
            refreshSettings(); Fluent:Notify({ Title = "Refreshed", Content = "Settings reloaded.", Duration = 4 })
        end })
        StaffTab:AddButton({ Title = "🚨 Broadcast Kick All", Callback = function()
            task.spawn(function() pcall(function()
                local all = sbGet("zuzify_sessions", "user_id=neq."..MY_UID.."&select=user_id")
                for _, s in ipairs(all or {}) do
                    sbPatch("zuzify_users", "user_id=eq."..s.user_id, { kick_signal=true, kick_reason="Maintenance" })
                end
                Fluent:Notify({ Title = "Broadcast", Content = "All queued.", Duration = 5 })
            end) end)
        end })
    end
end

--============================================================
-- ANNOUNCEMENTS POPUP
--============================================================
local function showAnnouncement(ann)
    pcall(function()
        if not ann or not ann.title then return end  -- nil crash guard
        local gui = Instance.new("ScreenGui"); gui.Name="ZuzyAnn"; gui.ResetOnSpawn=false
        gui.IgnoreGuiInset=true; gui.DisplayOrder=997; gui.Parent=CoreGui
        local fr = Instance.new("Frame"); fr.Size = UDim2.new(0,520,0,280)
        fr.Position = UDim2.new(0.5,-260,0,80); fr.BackgroundColor3 = Color3.fromRGB(12,12,18)
        fr.BorderSizePixel = 0; fr.Parent = gui
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0,12)

        local color = Color3.fromRGB(0,220,180)
        if ann.priority == "urgent" then color = Color3.fromRGB(255,60,60)
        elseif ann.priority == "high" then color = Color3.fromRGB(255,160,60)
        elseif ann.priority == "low" then color = Color3.fromRGB(140,140,160) end

        local st = Instance.new("UIStroke"); st.Color = color; st.Thickness = 2; st.Parent = fr
        local bar = Instance.new("Frame"); bar.Size = UDim2.new(1,0,0,4); bar.BackgroundColor3 = color; bar.Parent = fr
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0,12)

        local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,-40,0,32)
        title.Position = UDim2.new(0,20,0,14); title.BackgroundTransparency = 1
        title.Text = "📣 "..(ann.title or "Announcement"); title.TextColor3 = color
        title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = fr

        local content = Instance.new("TextLabel"); content.Size = UDim2.new(1,-40,0,170)
        content.Position = UDim2.new(0,20,0,52); content.BackgroundTransparency = 1
        content.Text = ann.content or ""; content.TextColor3 = Color3.fromRGB(220,220,230)
        content.Font = Enum.Font.Gotham; content.TextSize = 13; content.TextWrapped = true
        content.TextXAlignment = Enum.TextXAlignment.Left; content.TextYAlignment = Enum.TextYAlignment.Top
        content.Parent = fr

        local close = Instance.new("TextButton"); close.Size = UDim2.new(0,100,0,34)
        close.Position = UDim2.new(1,-110,1,-44); close.BackgroundColor3 = color
        close.Text = "OK"; close.TextColor3 = Color3.new(1,1,1); close.Font = Enum.Font.GothamBold
        close.TextSize = 14; close.Parent = fr
        Instance.new("UICorner", close).CornerRadius = UDim.new(0,8)
        close.MouseButton1Click:Connect(function() gui:Destroy() end)
        Debris:AddItem(gui, 90)
    end)
end

local seenSet = {}
for _, id in ipairs(MY_SEEN_ANN or {}) do seenSet[tostring(id)] = true end

local function pollAnnouncements()
    task.spawn(function() pcall(function()
        local d = sbGet("zuzify_announcements", "active=eq.true&select=*&order=created_at.desc&limit=10")
        if not d then return end
        local newIds = {}
        for _, a in ipairs(d) do
            local key = tostring(a.id)
            if not seenSet[key] then
                seenSet[key] = true
                table.insert(newIds, a.id)
                task.delay(0.5, function() showAnnouncement(a) end)
            end
        end
        if #newIds > 0 then
            local list = {}
            for k in pairs(seenSet) do table.insert(list, tonumber(k) or k) end
            sbPatch("zuzify_users", "user_id=eq."..MY_UID, { seen_announcements = list })
            MY_SEEN_ANN = list
        end
    end) end)
end

pollAnnouncements()
task.spawn(function() while true do task.wait(30); pcall(pollAnnouncements) end end)

--============================================================
-- AUTO-SAVE / LOAD (BindToClose removed)
--============================================================
if F.CloudAutoLoad then
    task.spawn(function()
        task.wait(3)
        pcall(function()
            local ok = loadConfigFromCloud()
            if ok then
                applyTheme(F.ThemeName or "Dark"); refreshESP()
                Fluent:Notify({ Title = "Cloud Config", Content = "✅ Auto-loaded settings.", Duration = 6 })
            end
        end)
    end)
end
task.spawn(function()
    while true do
        task.wait(180)
        if F.CloudAutoSave then pcall(saveConfigToCloud) end
    end
end)

--============================================================
-- OWNER PENDING APPS NOTIFY
--============================================================
if IsOwner() then
    task.spawn(function()
        task.wait(3)
        pcall(function()
            local d = sbGet("zuzify_applications", "status=eq.pending&select=id")
            local cnt = d and #d or 0
            if cnt > 0 then
                Fluent:Notify({ Title = "📝 Pending Applications: "..cnt, Content = "Open Staff tab.", Duration = 15 })
            end
        end)
    end)
end

--============================================================
-- AUTO REFRESH ROSTER
--============================================================
task.spawn(function()
    while true do
        task.wait(4)
        pcall(function()
            if playerDropdown then
                local list = pNames(); if #list == 0 then list = {"None"} end
                playerDropdown:SetValues(list)
            end
        end)
    end
end)

--============================================================
-- FINALIZE
--============================================================
pcall(function() Window:SelectTab(1) end)
pcall(function()
    Fluent:Notify({
        Title = "ZuzifyRBX "..VERSION,
        Content = "Welcome, "..MY_NAME.."!\nRole: "..RoleLabel(MY_ROLE).."\nTier: "..RoleLabel(MY_TIER),
        SubContent = IsStaff() and ("★ "..RoleLabel(MY_ROLE).." access") or
                     (IsTrusted() and "★ Trusted Program") or
                     "Advanced ESP • Threat alerts on",
        Duration = 10,
    })
end)
pcall(function()
    if SaveManager and SaveManager.LoadAutoloadConfig then SaveManager:LoadAutoloadConfig() end
end)

CloseLoading()
SafeLog("boot", "ready")
