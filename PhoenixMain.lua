-- ============================================================
-- 🔥 RIVALS MENU | ATTACK + ESP EDITION v5.2 (2026) — OPTIMIZED
-- ============================================================
-- Game   : Rivals (thegamer101) — Roblox
-- Executor: Synapse Z / Wave / Delta / Solara / Codex / Fluxus
-- Yêu cầu: hookmetamethod, checkcaller, getgc, cloneref
-- ============================================================
-- CHANGELOG v5.2:
--   [OPT-1] Pre-compute HitRemotesSet / AcRemotesSet: O(1) lookup trong __namecall
--   [OPT-2] Xóa vòng while-true GC tự động; ScanAndPatch chỉ chạy khi CharacterAdded
--           hoặc người dùng bấm nút ở tab Gun.
--   [OPT-3] Camera.CFrame fallback của Aimbot tách sang RenderStepped để không giật.
--   [OPT-4] Skeleton ESP bổ sung sanity checks đầy đủ (pA/pB là BasePart, .Position).
--   [OPT-5] Xóa wait() blocking trong luồng chính; code gọn + comment rõ ràng.
-- ============================================================

if _G.__RIVALS_LOADED then
    warn("[Rivals] Script đã inject. Bỏ qua.")
    return
end
_G.__RIVALS_LOADED = true

local function RivalsMain()

-- ════════════════════════════════════════════════════════════
-- [1] LOCAL ALIASES — Tối ưu hiệu năng tối đa
-- ════════════════════════════════════════════════════════════
local rawget   = rawget
local rawset   = rawset
local pairs    = pairs
local ipairs   = ipairs
local tostring = tostring
local type     = type
local pcall    = pcall
local unpack   = table.unpack
local insert   = table.insert
local format   = string.format
local lower    = string.lower
local find     = string.find
local byte     = string.byte
local char     = string.char
local concat   = table.concat
local rand     = math.random
local clamp    = math.clamp
local floor    = math.floor
local ceil     = math.ceil
local max      = math.max
local min      = math.min
local abs      = math.abs
local sqrt     = math.sqrt
local huge     = math.huge
local tw       = task.wait
local tspawn   = task.spawn

-- ════════════════════════════════════════════════════════════
-- [2] EXECUTOR CAPABILITIES
-- ════════════════════════════════════════════════════════════
local hasHook     = type(hookmetamethod) == "function"
local hasCheck    = type(checkcaller)    == "function"
local hasGC       = type(getgc)          == "function"
local hasSetRO    = type(setreadonly)    == "function"
local hasMakeW    = type(make_writeable) == "function"
local hasCloneRef = type(cloneref)       == "function"
local hasGetUpval = type(getupvalue)     == "function"
local hasSetUpval = type(setupvalue)     == "function"
local hasDrawing  = type(Drawing)        == "table"

-- ════════════════════════════════════════════════════════════
-- [3] UTILITIES
-- ════════════════════════════════════════════════════════════
local function jWait(base, v)
    v = v or base * 0.2
    local t = max(0.001, base + (rand() * 2 - 1) * v)
    tw(t); return t
end

-- ── Universal Team Check ─────────────────────────────────────────────────────
-- Kiểm tra xem targetPlayer và localPlayer có cùng team hay không,
-- hỗ trợ đầy đủ: Roblox default Team, TeamColor, custom Attribute, StringValue.
-- Trả về TRUE nếu cùng team, FALSE nếu là kẻ địch.
local function IsSameTeam(targetPlayer, localPlayer)
    if not targetPlayer or not localPlayer then return false end

    -- [1] Roblox default Team object (Team ~= nil means they have a team)
    local ok1, lpTeam  = pcall(function() return localPlayer.Team  end)
    local ok2, tgtTeam = pcall(function() return targetPlayer.Team end)
    if ok1 and ok2 then
        if lpTeam ~= nil and tgtTeam ~= nil then
            return lpTeam == tgtTeam
        end
    end

    -- [2] TeamColor (fallback khi Team object nil nhưng BrickColor vẫn set)
    local ok3, lpColor  = pcall(function() return localPlayer.TeamColor  end)
    local ok4, tgtColor = pcall(function() return targetPlayer.TeamColor end)
    if ok3 and ok4 and lpColor ~= nil and tgtColor ~= nil then
        if lpColor ~= BrickColor.new("White") or tgtColor ~= BrickColor.new("White") then
            -- Tránh false-positive khi cả 2 đều chưa được gán màu (mặc định trắng)
            return lpColor == tgtColor
        end
    end

    -- [3] Custom Attribute: "Team", "team", "TeamName"
    local ATTR_KEYS = { "Team", "team", "TeamName" }
    for _, key in ipairs(ATTR_KEYS) do
        local okA, lpAttr  = pcall(function() return localPlayer:GetAttribute(key)  end)
        local okB, tgtAttr = pcall(function() return targetPlayer:GetAttribute(key) end)
        if okA and okB and lpAttr ~= nil and tgtAttr ~= nil then
            return tostring(lpAttr) == tostring(tgtAttr)
        end
    end

    -- [4] StringValue children named "Team" hoặc "team"
    local STR_KEYS = { "Team", "team" }
    for _, key in ipairs(STR_KEYS) do
        local lpSV  = localPlayer:FindFirstChild(key)
        local tgtSV = targetPlayer:FindFirstChild(key)
        if lpSV and tgtSV
            and lpSV:IsA("StringValue")
            and tgtSV:IsA("StringValue")
            and lpSV.Value ~= "" then
            return lpSV.Value == tgtSV.Value
        end
    end

    -- Không tìm thấy thông tin team chung → xác nhận là kẻ địch
    return false
end
-- ─────────────────────────────────────────────────────────────────────────────

-- XOR Obfuscation (dùng bit32.bxor để tương thích mọi executor Roblox)
local OBF_KEY = 0x3F
local _bxor = bit32 and bit32.bxor or function(a, b)
    -- fallback thủ công nếu executor không có bit32
    local result, bit = 0, 1
    while a > 0 or b > 0 do
        local ra, rb = a % 2, b % 2
        if ra ~= rb then result = result + bit end
        a, b, bit = (a - ra) / 2, (b - rb) / 2, bit * 2
    end
    return result
end
local function xorStr(s, k)
    local t = {}
    for i = 1, #s do
        t[i] = char(_bxor(byte(s, i), k))
    end
    return concat(t)
end
local function dxor(ob, k) return xorStr(ob, k) end

-- ════════════════════════════════════════════════════════════
-- [4] ANTI-DETECT STRINGS — Pre-compute toàn bộ, KHÔNG decode trong hook
-- ════════════════════════════════════════════════════════════
-- [OPT-1]: Giải mã trước (pre-compute) tất cả các chuỗi OBF ngay khi load,
--          rồi đưa vào dictionary Set để lookup O(1) trong __namecall.
--          Tuyệt đối không gọi dxor() bên trong callback của hookmetamethod.

local RIVALS_AC_OBF = {
    xorStr("anticheat",OBF_KEY), xorStr("AntiCheat",OBF_KEY),
    xorStr("cheatdetect",OBF_KEY), xorStr("CheatDetect",OBF_KEY),
    xorStr("exploitcheck",OBF_KEY), xorStr("ExploitCheck",OBF_KEY),
    xorStr("kickplayer",OBF_KEY), xorStr("KickPlayer",OBF_KEY),
    xorStr("reportcheat",OBF_KEY), xorStr("ReportCheat",OBF_KEY),
    xorStr("verifyclient",OBF_KEY), xorStr("VerifyClient",OBF_KEY),
    xorStr("integritycheck",OBF_KEY), xorStr("AC",OBF_KEY),
    xorStr("BanPlayer",OBF_KEY), xorStr("FlagExploit",OBF_KEY),
}
-- Set cho exact match (lowercase) → O(1)
local RIVALS_AC_SET = {}
-- List cho substring match (vẫn cần loop nhưng chỉ chạy khi tên rất dài)
local RIVALS_AC_LIST = {}
for _, ob in ipairs(RIVALS_AC_OBF) do
    local decoded = lower(dxor(ob, OBF_KEY))
    RIVALS_AC_SET[decoded] = true
    insert(RIVALS_AC_LIST, decoded)
end

local RIVALS_HIT_OBF = {
    xorStr("hit",OBF_KEY), xorStr("Hit",OBF_KEY),
    xorStr("damage",OBF_KEY), xorStr("Damage",OBF_KEY),
    xorStr("shoot",OBF_KEY), xorStr("Shoot",OBF_KEY),
    xorStr("fire",OBF_KEY), xorStr("Fire",OBF_KEY),
    xorStr("bullet",OBF_KEY), xorStr("Bullet",OBF_KEY),
    xorStr("attack",OBF_KEY), xorStr("Attack",OBF_KEY),
    xorStr("gun",OBF_KEY), xorStr("shot",OBF_KEY),
    xorStr("ray",OBF_KEY), xorStr("projectile",OBF_KEY),
    xorStr("deal",OBF_KEY), xorStr("inflict",OBF_KEY),
}
-- [OPT-1]: Pre-decode HIT remotes → dictionary Set O(1) exact match
local HitRemotesSet  = {}   -- exact match O(1)
local HitRemotesList = {}   -- substring match fallback
for _, ob in ipairs(RIVALS_HIT_OBF) do
    local decoded = lower(dxor(ob, OBF_KEY))
    HitRemotesSet[decoded] = true
    insert(HitRemotesList, decoded)
end

-- [OPT-1]: isACRemote & isHitRemote — không gọi dxor() nữa, dùng pre-decoded list
local function isACRemote(name)
    if not name or name == "" then return false end
    local lo = lower(name)
    if RIVALS_AC_SET[lo] then return true end  -- O(1) exact
    -- substring fallback: chỉ chạy nếu exact miss
    for _, decoded in ipairs(RIVALS_AC_LIST) do
        if find(lo, decoded, 1, true) then return true end
    end
    return false
end

local function isHitRemote(name)
    if not name or name == "" then return false end
    local lo = lower(name)
    if HitRemotesSet[lo] then return true end  -- O(1) exact
    for _, decoded in ipairs(HitRemotesList) do
        if find(lo, decoded, 1, true) then return true end
    end
    return false
end

-- ════════════════════════════════════════════════════════════
-- [5] SERVICES
-- ════════════════════════════════════════════════════════════
local function safeService(n)
    local ok, s = pcall(function() return game:GetService(n) end)
    if not ok then return nil end
    if hasCloneRef then
        local ok2, c = pcall(cloneref, s)
        if ok2 then return c end
    end
    return s
end

local Players           = safeService("Players")
local RunService        = safeService("RunService")
local UserInputService  = safeService("UserInputService")
local Workspace         = safeService("Workspace")
local CoreGui           = safeService("CoreGui")
local Lighting          = safeService("Lighting")
local TweenService      = safeService("TweenService")
local HttpService       = safeService("HttpService")
local LP                = Players.LocalPlayer
local Camera            = Workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
-- [6] CONFIG TRUNG TÂM
-- ════════════════════════════════════════════════════════════
local Config = {
    -- ─── Aim ───
    Aim = {
        SilentAim      = false,
        Aimbot         = false,
        AimPart        = "Head",
        FOV            = 150,
        Smoothness     = 4,
        ShowFOV        = false,
        Prediction     = 0.12,
        Wallbang       = false,
        TeamCheck      = true,
        SilentStrength = 1.0,
        AimKey         = Enum.UserInputType.MouseButton2,
    },
    -- ─── ESP ─── (nâng cấp hoàn toàn)
    ESP = {
        Enabled         = false,
        TeamCheck       = true,

        -- Highlight (Chams 3D)
        Chams           = true,
        ChamsColor      = Color3.fromRGB(255, 60, 60),
        ChamsTrans      = 0.45,
        ChamsOutline    = true,
        ChamsOutlineCol = Color3.fromRGB(255, 255, 255),

        -- Corner Box (thay vì full box — nhìn pro hơn)
        CornerBox       = true,
        CornerBoxColor  = Color3.fromRGB(255, 60, 60),
        CornerLength    = 0.25,   -- Tỷ lệ chiều dài góc so với box (0-0.5)

        -- Full Box
        FullBox         = false,
        FullBoxColor    = Color3.fromRGB(255, 60, 60),

        -- Head Dot
        HeadDot         = true,
        HeadDotColor    = Color3.fromRGB(255, 255, 255),
        HeadDotSize     = 4,

        -- Skeleton
        Skeleton        = false,
        SkeletonColor   = Color3.fromRGB(255, 200, 60),
        SkeletonTrans   = 0.0,

        -- Tracers / Snaplines
        Tracers         = false,
        TracerOrigin    = "Bottom",  -- "Bottom", "Center", "Top"
        TracerColor     = Color3.fromRGB(255, 60, 60),

        -- Name Tag
        NameTag         = true,
        NameTagColor    = Color3.fromRGB(255, 255, 255),
        ShowUsername    = true,
        ShowDisplayName = false,

        -- Distance
        ShowDist        = true,
        DistColor       = Color3.fromRGB(180, 180, 255),
        MaxDistColor    = 200,  -- studs: trên này màu đỏ, dưới này màu xanh

        -- Health Bar
        HealthBar       = true,
        HealthBarSide   = "Left",  -- "Left", "Right"

        -- Weapon Tag
        WeaponTag       = false,
        WeaponColor     = Color3.fromRGB(255, 220, 60),

        -- Filled Box (fill mờ bên trong box)
        FilledBox       = false,
        FilledBoxTrans  = 0.85,

        -- Distance Color (gradient theo khoảng cách)
        DistGradient    = true,  -- Màu đổi theo khoảng cách: xanh (gần) → đỏ (xa)
    },
    -- ─── Gun Mods ───
    Gun = {
        NoRecoil      = false,
        NoSpread      = false,
        InfiniteAmmo  = false,
        InstantReload = false,
    },
    -- ─── TriggerBot ───
    TriggerBot = {
        Enabled   = false,
        HoldMode  = true,
        HoldKey   = Enum.KeyCode.CapsLock,
        FovCheck  = 12,
        Delay     = 0.03,
        RandDelay = 0.025,
        VisCheck  = true,
        TeamCheck = true,
        Hitbox    = "Head",
    },
    -- ─── Combat ───
    Combat = {
        KillAura      = false,
        KillAuraDist  = 8,
        AutoAbility   = false,
        AbilityDist   = 20,
        AutoDash      = false,
        DashDist      = 25,
        BunnyHop      = false,
        AutoParry     = false,
    },
    -- ─── FakeLag ───
    -- SimPing: delay toàn bộ outgoing packets → server thấy bạn ping cao thật sự
    -- Jitter  : random-freeze HRP CFrame → server thấy nhân vật giật/nhảy loạn
    -- Burst   : gom & xả packets theo chu kỳ → tạo hiệu ứng spike ping
    FakeLag = {
        Enabled   = false,
        -- ── Packet Delay (SimPing) ──
        SimPing   = true,        -- Bật/tắt delay packet
        PingMs    = 150,         -- Ping giả lập (ms) — địch thấy bạn lag từng này
        PingJitter= 30,          -- Thêm ±jitter ngẫu nhiên vào mỗi packet (ms)
        -- ── Position Jitter ──
        PosJitter = false,       -- Freeze HRP ngẫu nhiên → server thấy nhân vật giật
        JitterAmt = 0.08,        -- Tần suất jitter (0=không jitter, 1=luôn freeze)
        -- ── Burst Mode ──
        BurstMode = false,       -- Gom packets → xả burst → tạo spike ping
        BurstHold = 0.20,        -- Thời gian GOM packet (s)
        BurstFire = 0.05,        -- Thời gian XẢ packet (s)
        -- ── Lag Ghost (ảo ảnh lag) ──
        GhostShow  = false,      -- Hiển thị bóng ma vị trí lag phía sau bạn
        GhostTrans = 0.65,       -- Độ trong suốt ghost (0=đặc, 1=ẩn hoàn toàn)
        GhostColor = Color3.fromRGB(120, 180, 255),  -- Màu tint của ghost
    },
    -- ─── Misc ───
    Misc = {
        SpeedHack   = false,
        SpeedMult   = 1.6,
        JumpPower   = false,
        JumpPow     = 50,
        InfStamina  = false,
        NoFallDmg   = false,
        AntiRagdoll = false,
        AutoRespawn = false,
    },
    -- ─── Anti-Detect ───
    AntiDetect = {
        BlockAC    = true,
        NoiseDelay = true,
    },
}

-- ════════════════════════════════════════════════════════════
-- [7] STATE
-- ════════════════════════════════════════════════════════════
local TargetRef    = nil
local TargetPlayer = nil
local ESP_Objects  = {}       -- [player] = { Box, HeadDot, Skeleton, ... }
local Highlights   = {}       -- [player] = Highlight instance
local FL_Thread    = nil
local FL_FrozenCF  = nil
-- FakeLag packet queue: { fn=function, fireAt=tick() }
local FL_PacketQueue = {}
local FL_QueueActive = false  -- true khi đang trong burst-hold (chặn packets)
local FL_JitterThread = nil
local FL_GhostModel   = nil   -- Model clone bán trong suốt (lag ghost)
local FL_GhostThread  = nil   -- Thread cập nhật vị trí ghost
local TB_Firing    = false
local TB_Held      = false
local _origSpeed   = 16
local _origJump    = 50
local _charDiedConn = nil
local STAMINA_THREAD = nil

-- [OPT-3]: Biến lưu CFrame cần set cho Aimbot fallback
--          Chỉ được ghi bởi Heartbeat, chỉ được đọc bởi RenderStepped
local _aimbotFallbackCF = nil

-- ════════════════════════════════════════════════════════════
-- [8] RAYCAST PARAMS
-- ════════════════════════════════════════════════════════════
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.FilterDescendantsInstances = { LP.Character or Instance.new("Folder"), Camera }

-- ════════════════════════════════════════════════════════════
-- [9] STEALTH LOAD
-- ════════════════════════════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end
jWait(0.9, 0.3)
local _hbc, _hbconn = 0, nil
_hbconn = RunService.Heartbeat:Connect(function()
    _hbc += 1
    if _hbc >= rand(18, 40) then _hbconn:Disconnect() end
end)
while _hbc < 15 do tw(0.016) end
jWait(0.2, 0.08)

-- ════════════════════════════════════════════════════════════
-- [10] LOAD RAYFIELD
-- ════════════════════════════════════════════════════════════
local Rayfield
do
    local attempts, ok, res = 0
    repeat
        attempts += 1
        ok, res = pcall(function()
            return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
        end)
        if not ok then
            warn("[Rivals] Rayfield lần " .. attempts .. ": " .. tostring(res))
            jWait(0.7, 0.2)
        end
    until ok or attempts >= 3
    if not ok or not res then
        warn("[Rivals] Không tải được Rayfield.")
        _G.__RIVALS_LOADED = nil; return
    end
    Rayfield = res
end

-- ════════════════════════════════════════════════════════════
-- [11] HOOK NAMECALL — TỐI ƯU O(1) LOOKUP
-- ════════════════════════════════════════════════════════════
-- [OPT-1]: Hook chỉ gọi isACRemote / isHitRemote (đã dùng pre-decoded Set).
--          Tuyệt đối không có dxor() hay xorStr() bên trong callback này.
-- [FIX-1]: InvokeServer KHÔNG BAO GIỜ bị queue — gọi thẳng OldNC ngay lập tức.
--          Chỉ FireServer mới được đẩy vào FL_PacketQueue.
--          Lý do: delay InvokeServer + return nil phá vỡ mọi LocalScript yield/wait.
if hasHook and hasCheck then
    local OldNC
    OldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()

        -- Block AC — O(1) exact match qua RIVALS_AC_SET
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            local nm = rawget(self, "Name") or ""
            if isACRemote(nm) then
                if method == "InvokeServer" then return false end
                return nil
            end
        end

        -- Silent Aim redirect — O(1) exact match qua HitRemotesSet
        if not checkcaller() and Config.Aim.SilentAim and TargetRef
            and method == "FireServer" and self:IsA("RemoteEvent") then
            local nm = rawget(self, "Name") or ""
            if isHitRemote(nm) then
                local args = {...}
                local aimPos = TargetRef.Position
                local predOk, predPos = pcall(function()
                    return TargetRef.Position + (TargetRef.Velocity or Vector3.zero) * Config.Aim.Prediction
                end)
                if predOk and predPos then aimPos = predPos end
                local modified = false
                for i, arg in ipairs(args) do
                    local t = typeof(arg)
                    if t == "CFrame" then
                        args[i] = args[i]:Lerp(CFrame.lookAt(arg.Position, aimPos), Config.Aim.SilentStrength)
                        modified = true
                    elseif t == "Vector3" and arg.Magnitude > 0.5 then
                        local dir = aimPos - Camera.CFrame.Position
                        if dir.Magnitude > 0.1 then args[i] = dir.Unit * arg.Magnitude; modified = true end
                    elseif t == "Instance" and pcall(function() return arg:IsA("BasePart") end) then
                        args[i] = TargetRef; modified = true
                    end
                end
                if modified then return OldNC(self, unpack(args)) end
            end
        end

        -- Raycast redirect
        if not checkcaller() and Config.Aim.SilentAim and TargetRef
            and method == "Raycast" and self == Workspace then
            local args = {...}
            if typeof(args[1]) == "Vector3" then
                local aimPos = TargetRef.Position
                local dir = aimPos - args[1]
                if dir.Magnitude > 0.1 then
                    args[2] = dir.Unit * 3000
                    return OldNC(self, unpack(args))
                end
            end
        end

        -- ┌─────────────────────────────────────────────────────┐
        -- │  [FIX-1] FL SimPing — CHỈ áp dụng cho FireServer   │
        -- │  InvokeServer đi thẳng xuống OldNC, không bao giờ  │
        -- │  bị delay (tránh phá LocalScript coroutine/yield).  │
        -- └─────────────────────────────────────────────────────┘
        if not checkcaller()
            and Config.FakeLag.Enabled
            and Config.FakeLag.SimPing
            and method == "FireServer" then          -- ← chỉ FireServer
            local _self = self
            local _args = {...}
            local queued = FL_QueuePacket(function()
                OldNC(_self, unpack(_args))
            end)
            if queued then return nil end            -- FireServer đã queue
        end
        -- InvokeServer + mọi method khác đều fall-through xuống đây:
        return OldNC(self, ...)
    end)
end

-- ════════════════════════════════════════════════════════════
-- [12] GC ENGINE — Gun Mods
-- ════════════════════════════════════════════════════════════
local RV_Cache = { Springs = {}, Modified = 0, Scanning = false }

-- Pre-decode toàn bộ key GC một lần duy nhất khi load script
-- [OPT-1 subsidiary]: ScanAndPatch cũng sẽ dùng pre-decoded keys, tránh dxor() lặp lại

local RV_RECOIL_OBF = {
    xorStr("recoil",OBF_KEY), xorStr("Recoil",OBF_KEY),
    xorStr("camKick",OBF_KEY), xorStr("CamKick",OBF_KEY),
    xorStr("kickback",OBF_KEY), xorStr("kick",OBF_KEY),
    xorStr("kickMin",OBF_KEY), xorStr("kickMax",OBF_KEY),
    xorStr("KickMin",OBF_KEY), xorStr("KickMax",OBF_KEY),
    xorStr("shake",OBF_KEY), xorStr("Shake",OBF_KEY),
    xorStr("sway",OBF_KEY), xorStr("Sway",OBF_KEY),
    xorStr("recoilX",OBF_KEY), xorStr("recoilY",OBF_KEY), xorStr("recoilZ",OBF_KEY),
    xorStr("RecoilX",OBF_KEY), xorStr("RecoilY",OBF_KEY), xorStr("RecoilZ",OBF_KEY),
    xorStr("gunKick",OBF_KEY), xorStr("GunKick",OBF_KEY),
    xorStr("CamKickMin",OBF_KEY), xorStr("CamKickMax",OBF_KEY),
}
local RV_SPREAD_OBF = {
    xorStr("spread",OBF_KEY), xorStr("Spread",OBF_KEY),
    xorStr("bloom",OBF_KEY), xorStr("Bloom",OBF_KEY),
    xorStr("accuracy",OBF_KEY), xorStr("inaccuracy",OBF_KEY),
    xorStr("hipSpread",OBF_KEY), xorStr("aimSpread",OBF_KEY),
    xorStr("HipSpread",OBF_KEY), xorStr("AimSpread",OBF_KEY),
    xorStr("minSpread",OBF_KEY), xorStr("MaxSpread",OBF_KEY),
    xorStr("spreadInc",OBF_KEY), xorStr("SpreadInc",OBF_KEY),
}
local RV_AMMO_OBF = {
    xorStr("ammo",OBF_KEY), xorStr("Ammo",OBF_KEY),
    xorStr("currentAmmo",OBF_KEY), xorStr("CurrentAmmo",OBF_KEY),
    xorStr("magAmmo",OBF_KEY), xorStr("MagAmmo",OBF_KEY),
    xorStr("ammoInMag",OBF_KEY), xorStr("AmmoInMag",OBF_KEY),
    xorStr("bullets",OBF_KEY), xorStr("clip",OBF_KEY),
    xorStr("magazine",OBF_KEY), xorStr("reserveAmmo",OBF_KEY),
}
local RV_RELOAD_OBF = {
    xorStr("reloadTime",OBF_KEY), xorStr("ReloadTime",OBF_KEY),
    xorStr("reloadDuration",OBF_KEY), xorStr("ReloadLength",OBF_KEY),
    xorStr("reloadSpeed",OBF_KEY), xorStr("ReloadSpeed",OBF_KEY),
}

-- Pre-decode GC keys thành plain list — ScanAndPatch không decode trong loop nữa
local RV_RECOIL  = {} ; for _, ob in ipairs(RV_RECOIL_OBF)  do insert(RV_RECOIL,  dxor(ob, OBF_KEY)) end
local RV_SPREAD  = {} ; for _, ob in ipairs(RV_SPREAD_OBF)  do insert(RV_SPREAD,  dxor(ob, OBF_KEY)) end
local RV_AMMO    = {} ; for _, ob in ipairs(RV_AMMO_OBF)    do insert(RV_AMMO,    dxor(ob, OBF_KEY)) end
local RV_RELOAD  = {} ; for _, ob in ipairs(RV_RELOAD_OBF)  do insert(RV_RELOAD,  dxor(ob, OBF_KEY)) end

local function ScanSprings()
    if not hasGC or RV_Cache.Scanning then return end
    RV_Cache.Scanning = true
    local found = {}
    pcall(function()
        for _, obj in pairs(getgc(true)) do
            if type(obj) == "table" then
                local p = rawget(obj,"Position") or rawget(obj,"p")
                local v = rawget(obj,"Velocity")  or rawget(obj,"v")
                local d = rawget(obj,"Damper")    or rawget(obj,"d")
                if p and v and d then insert(found, obj) end
            end
        end
    end)
    RV_Cache.Springs  = found
    RV_Cache.Scanning = false
end

local function NeutralizeRecoil()
    for _, s in ipairs(RV_Cache.Springs) do
        local function zf(k)
            local val = rawget(s, k)
            if not val then return end
            if type(val) == "number" then rawset(s, k, 0)
            elseif typeof(val) == "Vector3" then rawset(s, k, Vector3.zero) end
        end
        pcall(zf, "Position"); pcall(zf, "p")
        pcall(zf, "Velocity");  pcall(zf, "v")
        pcall(zf, "Target");    pcall(zf, "t")
    end
end

-- [OPT-1 subsidiary]: ScanAndPatch dùng pre-decoded keys (không gọi dxor trong loop)
local function ScanAndPatch()
    if not hasGC then return 0 end
    if not (Config.Gun.NoRecoil or Config.Gun.NoSpread or Config.Gun.InfiniteAmmo or Config.Gun.InstantReload) then return 0 end
    local count = 0
    pcall(function()
        for _, obj in pairs(getgc(true)) do
            if type(obj) == "table" then
                pcall(function()
                    if hasSetRO then pcall(setreadonly,    obj, false) end
                    if hasMakeW then pcall(make_writeable, obj, false) end
                    if Config.Gun.NoRecoil then
                        for _, k in ipairs(RV_RECOIL) do   -- k đã là plain string
                            local val = rawget(obj, k)
                            if val ~= nil then
                                if type(val) == "number" then rawset(obj, k, 0); count += 1
                                elseif typeof(val) == "Vector3" then rawset(obj, k, Vector3.zero); count += 1 end
                            end
                        end
                    end
                    if Config.Gun.NoSpread then
                        for _, k in ipairs(RV_SPREAD) do
                            local val = rawget(obj, k)
                            if val ~= nil and type(val) == "number" then rawset(obj, k, 0); count += 1 end
                        end
                    end
                    if Config.Gun.InfiniteAmmo then
                        for _, k in ipairs(RV_AMMO) do
                            local val = rawget(obj, k)
                            if val ~= nil and type(val) == "number" then rawset(obj, k, 9999); count += 1 end
                        end
                    end
                    if Config.Gun.InstantReload then
                        for _, k in ipairs(RV_RELOAD) do
                            local val = rawget(obj, k)
                            if val ~= nil and type(val) == "number" and val > 0.05 then rawset(obj, k, 0.001); count += 1 end
                        end
                    end
                end)
            end
        end
    end)
    RV_Cache.Modified = count
    return count
end

-- [OPT-2]: Quét 1 lần duy nhất khi bắt đầu (initial scan khi script vừa inject).
--          Vòng while-true tự động quét mỗi 5s ĐÃ BỊ XÓA.
--          Scan tiếp theo chỉ xảy ra khi: CharacterAdded, hoặc user bấm nút ở tab Gun.
tspawn(function() jWait(2.0, 0.5); ScanSprings(); jWait(0.4, 0.1); ScanAndPatch() end)

-- ════════════════════════════════════════════════════════════
-- [13] FOV CIRCLE
-- ════════════════════════════════════════════════════════════
local FOVCircle
if hasDrawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible      = false
    FOVCircle.Thickness    = 1.5
    FOVCircle.Color        = Color3.fromRGB(255, 100, 100)
    FOVCircle.Transparency = 0.6
    FOVCircle.NumSides     = 48  -- giảm từ 80 → 48 sides, mắt thường không phân biệt được
    FOVCircle.Filled       = false
end

-- ════════════════════════════════════════════════════════════
-- [ESP PERF] Cache các giá trị hay dùng để tránh tạo object mới mỗi frame
-- ════════════════════════════════════════════════════════════
local V2_ZERO    = Vector2.new(0, 0)  -- placeholder khởi tạo
local C3_BLACK   = Color3.new(0, 0, 0)
local C3_WHITE   = Color3.new(1, 1, 1)

-- ════════════════════════════════════════════════════════════
-- [14] ESPN ENGINE — NÂNG CẤP HOÀN TOÀN
-- ════════════════════════════════════════════════════════════

-- Danh sách xương Rivals (R15 standard)
local SKELETON_JOINTS = {
    { "Head",               "UpperTorso"    },
    { "UpperTorso",         "LowerTorso"    },
    { "LowerTorso",         "HumanoidRootPart" },
    { "UpperTorso",         "RightUpperArm" },
    { "RightUpperArm",      "RightLowerArm" },
    { "RightLowerArm",      "RightHand"     },
    { "UpperTorso",         "LeftUpperArm"  },
    { "LeftUpperArm",       "LeftLowerArm"  },
    { "LeftLowerArm",       "LeftHand"      },
    { "LowerTorso",         "RightUpperLeg" },
    { "RightUpperLeg",      "RightLowerLeg" },
    { "RightLowerLeg",      "RightFoot"     },
    { "LowerTorso",         "LeftUpperLeg"  },
    { "LeftUpperLeg",       "LeftLowerLeg"  },
    { "LeftLowerLeg",       "LeftFoot"      },
}
-- R6 fallback
local SKELETON_JOINTS_R6 = {
    { "Head",   "Torso"         },
    { "Torso",  "HumanoidRootPart" },
    { "Torso",  "Right Arm"     },
    { "Right Arm", "Right Leg"  },
    { "Torso",  "Left Arm"      },
    { "Left Arm",  "Left Leg"   },
    { "Torso",  "Right Leg"     },
    { "Torso",  "Left Leg"      },
}
local JOINT_COUNT = #SKELETON_JOINTS

-- Helper: Tạo Drawing object an toàn
local function newDraw(type_)
    if not hasDrawing then return nil end
    local ok, d = pcall(function() return Drawing.new(type_) end)
    return ok and d or nil
end

-- ════════════════════════════════════════════════════════════
-- [ESP PERF] Tạo drawing objects per player — ĐÃ TỐI ƯU
-- Loại bỏ toàn bộ shadow/outline duplicate objects:
--   TRƯỚC: ~40+ Drawing objects/player (mỗi element có bản outline riêng)
--   SAU  : ~18 Drawing objects/player  (dùng .Outline=true built-in)
-- Tiết kiệm ~50% draw calls, ~50% RAM Drawing API
-- ════════════════════════════════════════════════════════════
local function MakeESPObjects()
    if not hasDrawing then return nil end
    local FONT_UI   = Drawing.Fonts and Drawing.Fonts.UI   or 2
    local FONT_MONO = Drawing.Fonts and Drawing.Fonts.Mono or 3
    local o = {
        -- Corner Box: 8 lines (4 góc × 2). KHÔNG có shadow layer riêng nữa.
        CornerTL1 = newDraw("Line"), CornerTL2 = newDraw("Line"),
        CornerTR1 = newDraw("Line"), CornerTR2 = newDraw("Line"),
        CornerBL1 = newDraw("Line"), CornerBL2 = newDraw("Line"),
        CornerBR1 = newDraw("Line"), CornerBR2 = newDraw("Line"),
        -- Full Box (1 object duy nhất, dùng Outline bằng Thickness lớn hơn)
        FullBox  = newDraw("Square"),
        -- Filled Box
        FillBox  = newDraw("Square"),
        -- Head Dot (1 circle, outline bằng Thickness)
        HeadDot  = newDraw("Circle"),
        -- Tracer (1 line)
        Tracer   = newDraw("Line"),
        -- Name Tag (1 text, .Outline = true built-in)
        NameTag  = newDraw("Text"),
        -- Distance tag
        DistTag  = newDraw("Text"),
        -- Weapon tag
        WeapTag  = newDraw("Text"),
        -- Health Bar: background line + foreground line
        HpBg     = newDraw("Line"),
        HpFg     = newDraw("Line"),
        -- Skeleton lines (không có shadow layer)
        Skel     = {},
    }
    -- Init skeleton lines — chỉ 1 layer
    for i = 1, JOINT_COUNT do
        o.Skel[i] = newDraw("Line")
    end

    -- ── Khởi tạo style mặc định ──
    local CORNER_KEYS = {"CornerTL1","CornerTL2","CornerTR1","CornerTR2",
                         "CornerBL1","CornerBL2","CornerBR1","CornerBR2"}
    for _, key in ipairs(CORNER_KEYS) do
        local d = o[key]
        if d then d.Thickness = 1.5; d.Visible = false end
    end

    if o.FullBox then
        o.FullBox.Filled    = false
        o.FullBox.Thickness = 1.5
        o.FullBox.Visible   = false
    end
    if o.FillBox then
        o.FillBox.Filled       = true
        o.FillBox.Thickness    = 0
        o.FillBox.Color        = Color3.fromRGB(255, 60, 60)
        o.FillBox.Transparency = 0.85
        o.FillBox.Visible      = false
    end
    if o.HeadDot then
        o.HeadDot.Filled    = true
        o.HeadDot.Thickness = 1   -- viền mỏng bằng Thickness thay cho object riêng
        o.HeadDot.NumSides  = 16  -- giảm từ 24 → 16, đủ tròn
        o.HeadDot.Visible   = false
    end
    if o.Tracer then
        o.Tracer.Thickness = 1.5
        o.Tracer.Visible   = false
    end
    if o.NameTag then
        o.NameTag.Size    = 13
        o.NameTag.Center  = true
        o.NameTag.Outline = true   -- built-in outline, không cần object riêng
        o.NameTag.Font    = FONT_UI
        o.NameTag.Visible = false
    end
    if o.DistTag then
        o.DistTag.Size    = 11
        o.DistTag.Center  = true
        o.DistTag.Outline = true
        o.DistTag.Font    = FONT_MONO
        o.DistTag.Visible = false
    end
    if o.WeapTag then
        o.WeapTag.Size    = 11
        o.WeapTag.Center  = true
        o.WeapTag.Outline = true
        o.WeapTag.Color   = Color3.fromRGB(255, 220, 60)
        o.WeapTag.Font    = FONT_UI
        o.WeapTag.Visible = false
    end
    -- HP bar: Bg dày hơn một chút để tạo viền (không cần object outline riêng)
    if o.HpBg then o.HpBg.Thickness = 4; o.HpBg.Color = C3_BLACK; o.HpBg.Visible = false end
    if o.HpFg then o.HpFg.Thickness = 2; o.HpFg.Visible = false end
    -- Skeleton
    for i = 1, JOINT_COUNT do
        local d = o.Skel[i]
        if d then d.Thickness = 1; d.Visible = false end
    end

    return o
end

-- Ẩn tất cả drawing objects của 1 player
local function HideAll(o)
    if not o then return end
    local function hide(d) if d and d.Visible then d.Visible = false end end
    hide(o.CornerTL1); hide(o.CornerTL2)
    hide(o.CornerTR1); hide(o.CornerTR2)
    hide(o.CornerBL1); hide(o.CornerBL2)
    hide(o.CornerBR1); hide(o.CornerBR2)
    hide(o.FullBox);  hide(o.FillBox)
    hide(o.HeadDot)
    hide(o.Tracer)
    hide(o.NameTag);  hide(o.DistTag); hide(o.WeapTag)
    hide(o.HpBg);     hide(o.HpFg)
    for i = 1, #o.Skel do hide(o.Skel[i]) end
end

-- Xóa và free drawing objects
local function DestroyESP(o)
    if not o then return end
    local function rm(d) pcall(function() if d then d:Remove() end end) end
    rm(o.CornerTL1); rm(o.CornerTL2); rm(o.CornerTR1); rm(o.CornerTR2)
    rm(o.CornerBL1); rm(o.CornerBL2); rm(o.CornerBR1); rm(o.CornerBR2)
    rm(o.FullBox);  rm(o.FillBox)
    rm(o.HeadDot)
    rm(o.Tracer)
    rm(o.NameTag); rm(o.DistTag); rm(o.WeapTag)
    rm(o.HpBg);    rm(o.HpFg)
    for i = 1, #o.Skel do rm(o.Skel[i]) end
end

-- Corner Box helper — vẽ 4 góc (không có shadow layer)
local function DrawCornerBox(o, x, y, w, h, col, cornerLen)
    local cw = w * cornerLen
    local ch = h * cornerLen
    local r  = x + w
    local b  = y + h
    -- Inline set để tránh overhead gọi hàm con
    local tl1 = o.CornerTL1; if tl1 then tl1.From = Vector2.new(x, y); tl1.To = Vector2.new(x+cw, y);   tl1.Color = col; tl1.Visible = true end
    local tl2 = o.CornerTL2; if tl2 then tl2.From = Vector2.new(x, y); tl2.To = Vector2.new(x, y+ch);   tl2.Color = col; tl2.Visible = true end
    local tr1 = o.CornerTR1; if tr1 then tr1.From = Vector2.new(r, y); tr1.To = Vector2.new(r-cw, y);   tr1.Color = col; tr1.Visible = true end
    local tr2 = o.CornerTR2; if tr2 then tr2.From = Vector2.new(r, y); tr2.To = Vector2.new(r, y+ch);   tr2.Color = col; tr2.Visible = true end
    local bl1 = o.CornerBL1; if bl1 then bl1.From = Vector2.new(x, b); bl1.To = Vector2.new(x+cw, b);   bl1.Color = col; bl1.Visible = true end
    local bl2 = o.CornerBL2; if bl2 then bl2.From = Vector2.new(x, b); bl2.To = Vector2.new(x, b-ch);   bl2.Color = col; bl2.Visible = true end
    local br1 = o.CornerBR1; if br1 then br1.From = Vector2.new(r, b); br1.To = Vector2.new(r-cw, b);   br1.Color = col; br1.Visible = true end
    local br2 = o.CornerBR2; if br2 then br2.From = Vector2.new(r, b); br2.To = Vector2.new(r, b-ch);   br2.Color = col; br2.Visible = true end
end

local function HideCornerBox(o)
    local f = false
    if o.CornerTL1 then o.CornerTL1.Visible = f end; if o.CornerTL2 then o.CornerTL2.Visible = f end
    if o.CornerTR1 then o.CornerTR1.Visible = f end; if o.CornerTR2 then o.CornerTR2.Visible = f end
    if o.CornerBL1 then o.CornerBL1.Visible = f end; if o.CornerBL2 then o.CornerBL2.Visible = f end
    if o.CornerBR1 then o.CornerBR1.Visible = f end; if o.CornerBR2 then o.CornerBR2.Visible = f end
end

-- Distance → gradient color (xanh lá gần → đỏ xa)
local function DistColor(dist3D, maxDist)
    local ratio = clamp(dist3D / maxDist, 0, 1)
    -- xanh (gần) → vàng → đỏ (xa)
    local r = floor(clamp(ratio * 2, 0, 1) * 255)
    local g = floor(clamp(2 - ratio * 2, 0, 1) * 220)
    local b = 40
    return Color3.fromRGB(r, g, b)
end

-- ════════════════════════════════════════════════════════════
-- [ESP PERF] UpdateESP — tối ưu draw calls & WorldToViewportPoint calls
-- - Tái dụng headVP cho HeadDot (giảm 1 WTVP call/player)
-- - pcall bọc toàn bộ skeleton loop thay vì từng joint
-- - Chỉ update .Visible khi giá trị thực sự thay đổi (dirty flag)
-- ════════════════════════════════════════════════════════════
local function UpdateESP()
    if not Config.ESP.Enabled then return end
    local cfg        = Config.ESP
    local allPlayers = Players:GetPlayers()
    local camPos     = Camera.CFrame.Position
    local vp         = Camera.ViewportSize

    for _, p in ipairs(allPlayers) do
        if p == LP then continue end

        local char = p.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local isEnemy = not cfg.TeamCheck or not IsSameTeam(p, LP)
        local valid   = hum and hum.Health > 0 and hrp and head and isEnemy

        -- ── Highlight (Chams 3D) ──
        local hl = Highlights[p]
        if valid and cfg.Chams then
            if not hl then
                hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = CoreGui
                Highlights[p] = hl
            end
            hl.Adornee           = char
            hl.FillColor         = cfg.ChamsColor
            hl.FillTransparency  = cfg.ChamsTrans
            hl.OutlineColor      = cfg.ChamsOutline and cfg.ChamsOutlineCol or Color3.new(0,0,0)
            hl.OutlineTransparency = cfg.ChamsOutline and 0 or 1
            hl.Enabled           = true
        elseif hl then
            hl.Enabled = false
        end

        -- Nếu không cần vẽ 2D thì bỏ qua
        if not hasDrawing then continue end

        local objs = ESP_Objects[p]
        if not valid then
            if objs then HideAll(objs) end
            continue
        end

        -- Lấy vị trí camera space
        local rootVP, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            if objs then HideAll(objs) end
            continue
        end

        -- Tạo objects nếu chưa có
        if not objs then
            objs = MakeESPObjects()
            ESP_Objects[p] = objs
        end
        if not objs then continue end

        -- ── Tính kích thước box ──
        -- [PERF]: headVP dùng lại cho HeadDot → tiết kiệm 1 WorldToViewportPoint call
        local headVP = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
        local legVP  = Camera:WorldToViewportPoint(hrp.Position  - Vector3.new(0, 3.2, 0))
        local boxH   = max(abs(headVP.Y - legVP.Y), 1)
        local boxW   = boxH / 1.7
        local topY   = min(headVP.Y, legVP.Y)
        local bx     = rootVP.X - boxW / 2
        local dist3D = (camPos - hrp.Position).Magnitude

        -- Distance-based color
        local dynColor = cfg.DistGradient
            and DistColor(dist3D, cfg.MaxDistColor)
            or cfg.ChamsColor

        -- ── Corner Box ──
        if cfg.CornerBox then
            DrawCornerBox(objs, bx, topY, boxW, boxH, dynColor, cfg.CornerLength)
        else
            HideCornerBox(objs)
        end

        -- ── Full Box ──
        if cfg.FullBox then
            local fb = objs.FullBox
            if fb then fb.Size = Vector2.new(boxW, boxH); fb.Position = Vector2.new(bx, topY); fb.Color = dynColor; fb.Visible = true end
        else
            local fb = objs.FullBox; if fb and fb.Visible then fb.Visible = false end
        end

        -- ── Filled Box ──
        if cfg.FilledBox then
            local fill = objs.FillBox
            if fill then
                fill.Size = Vector2.new(boxW, boxH); fill.Position = Vector2.new(bx, topY)
                fill.Color = dynColor; fill.Transparency = cfg.FilledBoxTrans; fill.Visible = true
            end
        else
            local fill = objs.FillBox; if fill and fill.Visible then fill.Visible = false end
        end

        -- ── Head Dot — tái dụng headVP luôn (không gọi WorldToViewportPoint thêm lần nữa) ──
        if cfg.HeadDot then
            local hd = objs.HeadDot
            if hd then
                hd.Position = Vector2.new(headVP.X, headVP.Y)  -- headVP đã tính ở trên
                hd.Radius   = max(floor(boxW * 0.15), 3)
                hd.Color    = cfg.HeadDotColor
                hd.Visible  = true
            end
        else
            local hd = objs.HeadDot; if hd and hd.Visible then hd.Visible = false end
        end

        -- ── Tracers / Snaplines ──
        if cfg.Tracers then
            local fromY = cfg.TracerOrigin == "Center" and (vp.Y * 0.5)
                       or cfg.TracerOrigin == "Top"    and 0
                       or vp.Y
            local tr = objs.Tracer
            if tr then
                tr.From  = Vector2.new(vp.X * 0.5, fromY)
                tr.To    = Vector2.new(rootVP.X, topY + boxH)
                tr.Color = dynColor; tr.Visible = true
            end
        else
            local tr = objs.Tracer; if tr and tr.Visible then tr.Visible = false end
        end

        -- ── Name Tag ──
        local tagY = topY - 15
        local displayText = cfg.ShowDisplayName
            and (cfg.ShowUsername and (p.DisplayName .. " [" .. p.Name .. "]") or p.DisplayName)
            or p.Name

        local nt = objs.NameTag
        if cfg.NameTag then
            if nt then nt.Text = displayText; nt.Position = Vector2.new(rootVP.X, tagY); nt.Color = cfg.NameTagColor; nt.Visible = true end
            tagY = tagY - 13
        else
            if nt and nt.Visible then nt.Visible = false end
        end

        -- ── Distance Tag ──
        local dt = objs.DistTag
        if cfg.ShowDist then
            if dt then
                dt.Text     = floor(dist3D) .. "m"
                dt.Position = Vector2.new(rootVP.X, tagY)
                dt.Color    = cfg.DistGradient and dynColor or cfg.DistColor
                dt.Visible  = true
            end
            tagY = tagY - 12
        else
            if dt and dt.Visible then dt.Visible = false end
        end

        -- ── Weapon Tag ──
        local wt = objs.WeapTag
        if cfg.WeaponTag then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                if wt then wt.Text = tool.Name; wt.Position = Vector2.new(rootVP.X, topY + boxH + 2); wt.Color = cfg.WeaponColor; wt.Visible = true end
            elseif wt and wt.Visible then wt.Visible = false end
        else
            if wt and wt.Visible then wt.Visible = false end
        end

        -- ── Health Bar ──
        -- [PERF]: Bỏ HpText riêng, gộp số HP vào đọc qua NameTag đã có Outline
        --         Chỉ cần 2 Line objects (Bg + Fg) thay vì 3
        if cfg.HealthBar then
            local ratio = clamp(hum.Health / hum.MaxHealth, 0, 1)
            local hpCol = Color3.fromRGB(floor(255*(1-ratio)), floor(255*ratio), 30)
            local barX  = cfg.HealthBarSide == "Right" and (bx + boxW + 4) or (bx - 6)
            local btm   = topY + boxH
            local bg = objs.HpBg; local fg = objs.HpFg
            if bg then bg.From = Vector2.new(barX, topY); bg.To = Vector2.new(barX, btm); bg.Visible = true end
            if fg then fg.From = Vector2.new(barX, btm);  fg.To = Vector2.new(barX, btm - boxH*ratio); fg.Color = hpCol; fg.Visible = true end
        else
            local bg = objs.HpBg; local fg = objs.HpFg
            if bg and bg.Visible then bg.Visible = false end
            if fg and fg.Visible then fg.Visible = false end
        end

        -- ── Skeleton ──
        -- [PERF]: Bỏ SkelO (shadow layer). 1 pcall bọc cả loop thay vì pcall từng joint.
        --         Kiểm tra IsA("BasePart") để đảm bảo safety.
        if cfg.Skeleton then
            local joints = char:FindFirstChild("Torso") and SKELETON_JOINTS_R6 or SKELETON_JOINTS
            local skelColor = cfg.SkeletonColor
            local skelTrans = cfg.SkeletonTrans
            local skel      = objs.Skel
            pcall(function()  -- 1 pcall bọc toàn bộ: nhanh hơn nhiều so với pcall từng joint
                for i, jPair in ipairs(joints) do
                    local line = skel[i]
                    if not line then continue end
                    local pA = char:FindFirstChild(jPair[1])
                    local pB = char:FindFirstChild(jPair[2])
                    if pA and pB and pA:IsA("BasePart") and pB:IsA("BasePart") then
                        local spA, onA = Camera:WorldToViewportPoint(pA.Position)
                        local spB, onB = Camera:WorldToViewportPoint(pB.Position)
                        if onA and onB then
                            line.From  = Vector2.new(spA.X, spA.Y)
                            line.To    = Vector2.new(spB.X, spB.Y)
                            line.Color = skelColor
                            line.Transparency = skelTrans
                            line.Visible = true
                        else
                            if line.Visible then line.Visible = false end
                        end
                    else
                        if line.Visible then line.Visible = false end
                    end
                end
            end)
            -- Ẩn line thừa (R6 có ít joint hơn R15)
            for i = #joints + 1, JOINT_COUNT do
                local l = skel[i]; if l and l.Visible then l.Visible = false end
            end
        else
            local skel = objs.Skel
            for i = 1, JOINT_COUNT do
                local l = skel[i]; if l and l.Visible then l.Visible = false end
            end
        end
    end -- end for players
end

-- Dọn dẹp khi player rời game
Players.PlayerRemoving:Connect(function(p)
    if ESP_Objects[p] then DestroyESP(ESP_Objects[p]); ESP_Objects[p] = nil end
    if Highlights[p]  then pcall(function() Highlights[p]:Destroy() end); Highlights[p] = nil end
end)

-- ════════════════════════════════════════════════════════════
-- [15] TARGET FINDER
-- ════════════════════════════════════════════════════════════
local function GetTarget()
    local lpChar = LP.Character; if not lpChar then return nil end
    local bestDist = Config.Aim.FOV
    local bestPart = nil
    local sc = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local camPos = Camera.CFrame.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if Config.Aim.TeamCheck and IsSameTeam(p, LP) then continue end
        local char = p.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local part = char and char:FindFirstChild(Config.Aim.AimPart)
        if not (hum and hum.Health > 0 and part) then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist2D = (Vector2.new(sp.X, sp.Y) - sc).Magnitude
        if dist2D < bestDist then
            if not Config.Aim.Wallbang then
                local dir = part.Position - camPos
                if dir.Magnitude > 0.1 then
                    local ray = Workspace:Raycast(camPos, dir, RayParams)
                    if ray and not ray.Instance:IsDescendantOf(char) then continue end
                end
            end
            bestDist = dist2D; bestPart = part; TargetPlayer = p
        end
    end
    if not bestPart then TargetPlayer = nil end
    return bestPart
end

local function GetNearest3D(maxDist)
    local lpChar = LP.Character
    local lpHrp  = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    if not lpHrp then return nil, nil end
    local best, bestP, bestDist = nil, nil, maxDist
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if Config.Aim.TeamCheck and IsSameTeam(p, LP) then continue end
        local char = p.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and hum.Health > 0 and hrp) then continue end
        local d = (lpHrp.Position - hrp.Position).Magnitude
        if d < bestDist then bestDist = d; best = hrp; bestP = p end
    end
    return best, bestP
end

-- ════════════════════════════════════════════════════════════
-- [16] TRIGGERBOT
-- ════════════════════════════════════════════════════════════
local function IsCrosshairOnEnemy()
    local lpChar = LP.Character; if not lpChar then return false end
    local sc     = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local camPos = Camera.CFrame.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if Config.TriggerBot.TeamCheck and IsSameTeam(p, LP) then continue end
        local char = p.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local part = char and (char:FindFirstChild(Config.TriggerBot.Hitbox) or char:FindFirstChild("Head"))
        if not (hum and hum.Health > 0 and part) then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        if (Vector2.new(sp.X, sp.Y) - sc).Magnitude > Config.TriggerBot.FovCheck then continue end
        if Config.TriggerBot.VisCheck then
            local dir = part.Position - camPos
            if dir.Magnitude < 0.1 then continue end
            local ray = Workspace:Raycast(camPos, dir, RayParams)
            if ray and not ray.Instance:IsDescendantOf(char) then continue end
        end
        return true
    end
    return false
end

local function TBFire()
    if TB_Firing then return end
    TB_Firing = true
    tspawn(function()
        local d = Config.TriggerBot.Delay + rand() * Config.TriggerBot.RandDelay
        if Config.AntiDetect.NoiseDelay then d = d + (rand() * 0.008 - 0.004) end
        tw(max(0.005, d))
        if IsCrosshairOnEnemy() then
            pcall(mouse1press); tw(rand(35,90)/1000); pcall(mouse1release)
        end
        tw(0.07 + rand() * 0.04); TB_Firing = false
    end)
end

-- ════════════════════════════════════════════════════════════
-- [17] COMBAT FEATURES
-- ════════════════════════════════════════════════════════════
local KA_CD, AD_CD = 0, 0

local function UpdateKillAura()
    if not Config.Combat.KillAura or tick() - KA_CD < 0.12 then return end
    local _, nearP = GetNearest3D(Config.Combat.KillAuraDist)
    if not nearP then return end
    local lpChar = LP.Character; if not lpChar then return end
    local tool = lpChar:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end); KA_CD = tick() end
end

local function UpdateAutoDash()
    if not Config.Combat.AutoDash or tick() - AD_CD < 1.0 then return end
    local _, nearP = GetNearest3D(Config.Combat.DashDist)
    if not nearP then return end
    local lpChar = LP.Character; if not lpChar then return end
    local hrp = lpChar:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local tChar = nearP.Character
    local tHrp  = tChar and tChar:FindFirstChild("HumanoidRootPart"); if not tHrp then return end
    local dir = (tHrp.Position - hrp.Position).Unit
    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
    tspawn(function() pcall(function() keypress(0x10) end); tw(0.05); pcall(function() keyrelease(0x10) end) end)
    AD_CD = tick()
end

local function UpdateBunnyHop()
    if not Config.Combat.BunnyHop then return end
    local lpChar = LP.Character; if not lpChar then return end
    local hum = lpChar:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if hum.FloorMaterial ~= Enum.Material.Air then
        tspawn(function() pcall(function() hum.Jump = true end) end)
    end
end

local function ApplyAntiRagdoll(char)
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then
            pcall(function() v.Enabled = false end)
        end
    end
end

local function StartInfStamina()
    if STAMINA_THREAD then return end
    STAMINA_THREAD = tspawn(function()
        while Config.Misc.InfStamina do
            local lpChar = LP.Character
            if lpChar then
                local hum = lpChar:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(function()
                        local maxS = hum:GetAttribute("MaxStamina") or 100
                        hum:SetAttribute("Stamina", maxS)
                    end)
                    local sv = lpChar:FindFirstChild("Stamina", true)
                    if sv and sv:IsA("NumberValue") then
                        sv.Value = sv:GetAttribute("Max") or 100
                    end
                end
            end
            tw(0.1)
        end
        STAMINA_THREAD = nil
    end)
end

-- ════════════════════════════════════════════════════════════
-- [18] FAKELAG v2 — Packet Delay + Jitter + Burst  (FIXED v5.2.1)
-- ════════════════════════════════════════════════════════════
--
-- TÓM TẮT 3 LỖI ĐÃ SỬA:
--
--  [BUG-1] Burst Mode không hoạt động:
--          FL_QueueActive được set bởi BurstCycle nhưng Worker KHÔNG
--          kiểm tra nó → packets luôn được fire ngay, burst vô nghĩa.
--    FIX → Worker chỉ fire khi FL_QueueActive == false (pha Fire).
--          Khi FL_QueueActive == true (pha Hold), packets chỉ nằm chờ.
--
--  [BUG-2] Ring-Buffer phình index + bỏ sót gói out-of-order:
--          head = i + 1 nhảy cóc qua các slot có fireAt muộn hơn,
--          và data table phình vô hạn vì index chỉ tăng không giảm.
--    FIX → Dùng simple array queue + compact khi head > 64:
--          duyệt head→tail, fire gói đến hạn, xóa slot đó;
--          compact bằng cách dồn data[] về [1..n] khi head quá lớn.
--
--  [BUG-3] Jitter ép Vector3.zero → mất trọng lực, không nhảy được:
--          Reset velocity = zero xóa cả thành phần Y (gravity).
--    FIX → Lưu oldVel trước khi cộng noise, reset về oldVel (không
--          phải zero). Noise chỉ trên X/Z (Y luôn = 0).
--
--  [GIỮ NGUYÊN] FL_CancelToken + cấu trúc giao tiếp UI (StartFakeLag/
--               StopFakeLag) + InvokeServer bypass (xem hook [11]).
-- ════════════════════════════════════════════════════════════

-- ── Simple Array Queue (thay Ring-Buffer tự chế) ───────────
-- Cấu trúc: { data = {}, head = 1, tail = 0 }
--   • Push: tail++, data[tail] = item                    O(1)
--   • Fire: data[i] = nil (gán rỗng slot đã gửi)        O(1)
--   • Compact: khi head > 64, dồn data[] về [1..n]       O(n) amortized
-- Không dùng table.remove(t,1) tránh O(n) shift mỗi lần pop.
-- ───────────────────────────────────────────────────────────

local function Q_New()
    return { data = {}, head = 1, tail = 0 }
end

local function Q_Push(q, item)
    q.tail           = q.tail + 1
    q.data[q.tail]   = item
end

local function Q_IsEmpty(q)
    -- Queue rỗng khi mọi slot từ head→tail đều nil hoặc head > tail
    return q.head > q.tail
end

--- Compact: dồn các phần tử còn sống về [1..n] để chống phình index.
--- Chỉ gọi khi head > 64 (amortized O(1) trung bình).
local function Q_Compact(q)
    local newData = {}
    local n = 0
    for i = q.head, q.tail do
        if q.data[i] then
            n = n + 1
            newData[n] = q.data[i]
        end
    end
    q.data = newData
    q.head = 1
    q.tail = n
end

--- Reset sạch (khi stop FakeLag): tạo lại bảng mới
local function Q_Reset(q)
    q.data = {}
    q.head = 1
    q.tail = 0
end

-- Khởi tạo queue ngay khi load
FL_PacketQueue = Q_New()

-- ── Cancellation Token ─────────────────────────────────────
-- Token là 1 table {dead=bool}. Worker giữ upvalue → check mỗi frame.
-- StopFakeLag đặt token.dead = true → thread thoát ngay lập tức.
local FL_CancelToken = nil

-- ── Helper: đẩy FireServer vào queue ──────────────────────
-- Được gọi từ hook [11]. Trả về true = đã queue (caller return nil).
local function FL_QueuePacket(fn)
    if not Config.FakeLag.Enabled or not Config.FakeLag.SimPing then
        return false
    end
    -- Tính thời điểm gửi = now + PingMs ± PingJitter
    local jitterMs = Config.FakeLag.PingJitter
    local delayMs  = Config.FakeLag.PingMs + rand(-jitterMs, jitterMs)
    local fireAt   = tick() + max(0.005, delayMs / 1000)
    Q_Push(FL_PacketQueue, { fn = fn, fireAt = fireAt })
    return true
end

-- ── Worker Thread: gửi packets đúng lúc ────────────────────
-- [BUG-1 FIX]: Worker kiểm tra FL_QueueActive mỗi frame:
--   • FL_QueueActive == true  (Burst Hold) → KHÔNG fire, chỉ chờ.
--   • FL_QueueActive == false (Burst Fire / SimPing thuần) → fire
--     tất cả gói đến hạn fireAt.
-- [BUG-2 FIX]: Duyệt head→tail, fire bất kỳ slot nào đến hạn
--   (không phụ thuộc thứ tự index), xóa slot bằng gán nil.
--   Compact khi head > 64 để chống phình memory.
local function StartPacketWorker(token)
    tspawn(function()
        while not token.dead do
            local now = tick()
            local q   = FL_PacketQueue

            -- Compact nếu head đã trôi quá xa → chống phình index/memory
            if q.head > 64 then
                Q_Compact(q)
            end

            -- Nếu queue rỗng hoàn toàn → reset về trạng thái ban đầu
            if Q_IsEmpty(q) then
                Q_Reset(q)
            end

            -- ┌──────────────────────────────────────────────┐
            -- │ [BUG-1 FIX] Chỉ fire khi KHÔNG trong burst  │
            -- │ hold. FL_QueueActive == true → bỏ qua frame  │
            -- │ này, packets nằm yên trong queue chờ xả.     │
            -- └──────────────────────────────────────────────┘
            if not FL_QueueActive then
                -- Duyệt toàn bộ head→tail, fire bất kỳ gói nào đến hạn
                -- (duyệt hết, KHÔNG break sớm → xử lý out-of-order fireAt)
                local newHead = q.tail + 1  -- giả sử mọi thứ đã xử lý
                for i = q.head, q.tail do
                    if token.dead then break end
                    local pkt = q.data[i]
                    if pkt then
                        if now >= pkt.fireAt then
                            -- Gói đến hạn → fire ngay
                            pcall(pkt.fn)
                            q.data[i] = nil  -- xóa slot đã gửi
                        else
                            -- Gói chưa đến hạn → slot vẫn còn sống
                            -- Cập nhật newHead = slot sống đầu tiên
                            if i < newHead then
                                newHead = i
                            end
                        end
                    end
                end
                -- Cập nhật head = slot sống đầu tiên còn lại
                q.head = newHead
            end
            -- Nếu FL_QueueActive == true: không làm gì, packets tiếp
            -- tục được Q_Push từ hook [11] và nằm chờ trong queue.

            RunService.Heartbeat:Wait()
        end

        -- ── Flush queue còn lại khi token.dead (StopFakeLag) ──
        -- Gửi hết mọi gói chưa fire để không mất packet quan trọng
        local q = FL_PacketQueue
        for i = q.head, q.tail do
            local pkt = q.data[i]
            if pkt then pcall(pkt.fn) end
        end
        Q_Reset(q)
    end)
end

-- ── Burst Cycle Thread ─────────────────────────────────────
-- Chu kỳ: Hold (FL_QueueActive=true) → Fire (FL_QueueActive=false)
-- Khi Hold: worker bỏ qua fire → packets gom lại trong queue.
-- Khi Fire: worker xả toàn bộ → tạo hiệu ứng spike ping.
local function StartBurstCycle(token)
    tspawn(function()
        while not token.dead and Config.FakeLag.BurstMode do
            -- ── Pha Hold: gom packets ──
            FL_QueueActive = true
            tw(Config.FakeLag.BurstHold)
            if token.dead then break end
            -- ── Pha Fire: xả packets ──
            FL_QueueActive = false
            tw(Config.FakeLag.BurstFire)
        end
        FL_QueueActive = false
    end)
end

-- ── Position Jitter Thread ─────────────────────────────────
-- [BUG-3 FIX]:
--   • Lưu oldVel = hrp.AssemblyLinearVelocity TRƯỚC khi cộng noise.
--   • Noise chỉ trên trục X và Z (Y = 0) → KHÔNG ảnh hưởng trọng lực.
--   • Reset về oldVel (không phải Vector3.zero) → giữ nguyên gravity
--     và vận tốc di chuyển gốc, nhân vật vẫn nhảy và rơi bình thường.
local function StartJitter(token)
    if FL_JitterThread then return end
    FL_JitterThread = tspawn(function()
        local jitterOn = false
        local savedVel = nil  -- lưu vận tốc gốc trước khi cộng noise
        while not token.dead and Config.FakeLag.PosJitter do
            local lpChar = LP.Character
            local hrp = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
            if hrp then
                if rand() < Config.FakeLag.JitterAmt then
                    if not jitterOn then
                        -- [BUG-3 FIX] Lưu vận tốc gốc (bao gồm gravity Y)
                        pcall(function()
                            savedVel = hrp.AssemblyLinearVelocity
                        end)
                        -- Áp dụng xung lực ngẫu nhiên NHỎ trên X/Z
                        -- Y = 0 tuyệt đối → KHÔNG bay lên trời
                        local mag = 12 + rand() * 8  -- 12-20 studs/s
                        local noise = Vector3.new(
                            (rand() * 2 - 1) * mag,
                            0,                        -- ← Y luôn = 0
                            (rand() * 2 - 1) * mag
                        )
                        pcall(function()
                            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + noise
                        end)
                        jitterOn = true
                    end
                else
                    if jitterOn then
                        -- [BUG-3 FIX] Khôi phục vận tốc gốc (KHÔNG reset zero)
                        -- → Giữ nguyên trọng lực (Y) và momentum di chuyển
                        pcall(function()
                            if savedVel then
                                hrp.AssemblyLinearVelocity = savedVel
                            end
                        end)
                        savedVel = nil
                        jitterOn = false
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
        -- Cleanup khi thoát: khôi phục velocity gốc nếu đang jitter
        if jitterOn and savedVel then
            local lpChar = LP.Character
            local hrp = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() hrp.AssemblyLinearVelocity = savedVel end)
            end
        end
        FL_JitterThread = nil
    end)
end

-- ── Lag Ghost: ảo ảnh vị trí lag (chỉ bạn thấy) ──────────
-- Tạo bản clone bán trong suốt của nhân vật, đặt ở vị trí
-- "delay" (PingMs trước đó) để bạn biết kẻ địch nhìn thấy bạn ở đâu.
-- Dùng position history buffer: ghi CFrame mỗi frame, playback
-- tại thời điểm (now - PingMs) bằng lerp giữa 2 sample gần nhất.
-- ───────────────────────────────────────────────────────────

--- Hủy và xóa ghost model hiện tại
local function DestroyGhost()
    if FL_GhostModel then
        pcall(function() FL_GhostModel:Destroy() end)
        FL_GhostModel = nil
    end
end

--- Tạo ghost model từ character hiện tại (đã lọc Accessories/Hats để tránh lag)
-- [FIX-4] Chỉ clone BasePart con TRỰC TIẾP của character (body parts),
--         bỏ qua toàn bộ descendants của Accessory/Hat/Tool.
local function CreateGhost(sourceChar)
    DestroyGhost()
    if not sourceChar then return nil end

    local ok, ghost = pcall(function()
        local g = Instance.new("Model")
        g.Name = "_FL_Ghost"

        local trans = Config.FakeLag.GhostTrans
        local color = Config.FakeLag.GhostColor
        -- Material có thể đổi: ForceField cho hiệu ứng hologram, Neon cho glow
        local MAT   = Enum.Material.ForceField

        -- Tập hợp các class cần bỏ qua (Accessories, Tools, Scripts...)
        local SKIP_CLASS = { Accessory=true, Tool=true, Script=true,
                             LocalScript=true, ModuleScript=true, Hat=true }

        for _, part in ipairs(sourceChar:GetChildren()) do
            -- [FIX-4] Chỉ lấy children trực tiếp là BasePart (không đệ quy vào Accessory)
            if part:IsA("BasePart") and not SKIP_CLASS[part.ClassName] then
                local clone = Instance.new("Part")
                clone.Name        = part.Name
                clone.Size        = part.Size
                clone.CFrame      = part.CFrame
                clone.Anchored    = true
                clone.CanCollide  = false
                clone.CanTouch    = false
                clone.CanQuery    = false
                clone.CastShadow  = false
                clone.Material    = MAT
                clone.Color       = color
                clone.Transparency = (part.Name == "HumanoidRootPart") and 1 or trans
                -- Copy SpecialMesh nếu có (giữ hình dạng head/torso)
                local mesh = part:FindFirstChildOfClass("SpecialMesh")
                    or part:FindFirstChildOfClass("DataModelMesh")
                if mesh then mesh:Clone().Parent = clone end
                clone.Parent = g
            end
        end

        -- PrimaryPart cho SetPrimaryPartCFrame
        local hrpClone = g:FindFirstChild("HumanoidRootPart")
        if hrpClone then g.PrimaryPart = hrpClone end

        g.Parent = Workspace
        return g
    end)

    if ok and ghost then
        FL_GhostModel = ghost
        return ghost
    end
    return nil
end

--- [FIX-5] Cập nhật vị trí từng part ghost theo world-space CFrame của source parts.
--- Thay vì tính offset tương đối (dễ sai khi rotation), ta tính delta world-transform
--- từ HRP source → HRP delay, rồi áp delta đó lên từng part.
local function UpdateGhostCFrame(sourceChar, ghost, delayCF)
    if not sourceChar or not ghost then return end
    local srcHRP = sourceChar:FindFirstChild("HumanoidRootPart")
    if not srcHRP then return end

    -- Delta transform: delayCF * srcHRP.CFrame:Inverse()
    -- → áp lên bất kỳ part nào: newCF = delta * part.CFrame
    local delta = delayCF * srcHRP.CFrame:Inverse()

    for _, gPart in ipairs(ghost:GetChildren()) do
        if gPart:IsA("BasePart") then
            local srcPart = sourceChar:FindFirstChild(gPart.Name)
            if srcPart and srcPart:IsA("BasePart") then
                -- [FIX-5] Dùng world-space delta, không dùng relative offset sai
                pcall(function()
                    gPart.CFrame = delta * srcPart.CFrame
                end)
            end
        end
    end
end

--- Thread chính: ghi position history + playback ghost ở vị trí delay.
local function StartGhostThread(token)
    if FL_GhostThread then return end
    FL_GhostThread = tspawn(function()
        -- Position History Buffer: { {time, CFrame}, ... }
        -- Giữ tối đa 3 giây lịch sử (đủ cho PingMs ≤ 2000)
        local history     = {}
        local MAX_HISTORY  = 3.0  -- giây
        local ghost       = nil
        local rebuildCD   = 0     -- cooldown rebuild ghost model

        while not token.dead and Config.FakeLag.Enabled do
            local now    = tick()
            local lpChar = LP.Character
            local hrp    = lpChar and lpChar:FindFirstChild("HumanoidRootPart")

            if hrp and Config.FakeLag.GhostShow then
                -- ── Ghi CFrame hiện tại vào history ──
                insert(history, { t = now, cf = hrp.CFrame })

                -- ── Dọn history cũ (> MAX_HISTORY giây) ──
                local cutoff = now - MAX_HISTORY
                while #history > 2 and history[1].t < cutoff do
                    -- Dùng table.remove(1) ở đây OK vì history nhỏ (~180 entries max)
                    table.remove(history, 1)
                end

                -- ── Tạo/rebuild ghost model nếu chưa có ──
                if (not ghost or not ghost.Parent) and now > rebuildCD then
                    ghost = CreateGhost(lpChar)
                    rebuildCD = now + 2.0  -- tránh spam rebuild
                end

                -- ── Tính thời điểm delay playback ──
                local delayS   = Config.FakeLag.PingMs / 1000
                local playTime = now - delayS

                -- ── Tìm 2 sample gần nhất để lerp ──
                local before, after = nil, nil
                for i = #history, 1, -1 do
                    if history[i].t <= playTime then
                        before = history[i]
                        if i < #history then
                            after = history[i + 1]
                        end
                        break
                    end
                end

                if before and ghost then
                    local delayCF
                    if after then
                        -- Lerp giữa before và after
                        local span  = after.t - before.t
                        local alpha = (span > 0.001) and clamp((playTime - before.t) / span, 0, 1) or 0
                        delayCF = before.cf:Lerp(after.cf, alpha)
                    else
                        delayCF = before.cf
                    end
                    -- Cập nhật ghost parts
                    UpdateGhostCFrame(lpChar, ghost, delayCF)
                end

                -- Cập nhật transparency/color realtime (nếu user thay đổi qua UI)
                if ghost then
                    local trans = Config.FakeLag.GhostTrans
                    local color = Config.FakeLag.GhostColor
                    for _, gPart in ipairs(ghost:GetChildren()) do
                        if gPart:IsA("BasePart") and gPart.Name ~= "HumanoidRootPart" then
                            if gPart.Transparency ~= trans then gPart.Transparency = trans end
                            if gPart.Color ~= color then gPart.Color = color end
                        end
                    end
                end
            else
                -- Ghost disabled hoặc không có character → ẩn ghost
                if ghost and ghost.Parent then
                    DestroyGhost()
                    ghost = nil
                end
                history = {}  -- reset history
            end

            RunService.Heartbeat:Wait()
        end

        -- Cleanup khi thoát
        DestroyGhost()
        ghost = nil
        history = nil
        FL_GhostThread = nil
    end)
end

-- ── StartFakeLag / StopFakeLag ────────────────────────────
local function StartFakeLag()
    if FL_Thread then return end
    -- Tạo cancellation token mới cho lần chạy này
    FL_CancelToken = { dead = false }
    Q_Reset(FL_PacketQueue)
    FL_QueueActive = false
    StartPacketWorker(FL_CancelToken)
    if Config.FakeLag.BurstMode  then StartBurstCycle(FL_CancelToken)  end
    if Config.FakeLag.PosJitter  then StartJitter(FL_CancelToken)      end
    -- Lag Ghost: luôn start thread (thread tự check GhostShow mỗi frame)
    StartGhostThread(FL_CancelToken)
    FL_Thread = true
end

local function StopFakeLag()
    Config.FakeLag.Enabled = false
    FL_QueueActive = false
    -- Đặt token.dead = true → TẤT CẢ threads liên quan break ngay
    -- (Worker, BurstCycle, Jitter, Ghost đều check token mỗi Heartbeat)
    if FL_CancelToken then
        FL_CancelToken.dead = true
        FL_CancelToken = nil
    end
    -- Hủy ghost model ngay lập tức
    DestroyGhost()
    -- Set về nil để StartFakeLag() có thể gọi lại
    FL_Thread = nil
    FL_JitterThread = nil
    FL_GhostThread  = nil
end

-- ════════════════════════════════════════════════════════════
-- [19] MISC
-- ════════════════════════════════════════════════════════════
local function ApplySpeed(en, mult)
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if en then _origSpeed = hum.WalkSpeed; hum.WalkSpeed = 16*(mult or 1.6)
    else hum.WalkSpeed = _origSpeed end
end

local function ApplyJump(en, pow)
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if en then _origJump = hum.JumpPower; hum.JumpPower = pow or 50
    else hum.JumpPower = _origJump end
end

-- ════════════════════════════════════════════════════════════
-- [20] CHARACTER EVENTS
-- ════════════════════════════════════════════════════════════
-- [OPT-2]: ScanAndPatch được gọi ngay khi CharacterAdded (cầm súng mới/respawn)
--          Không còn vòng while-true tự quét nữa.
LP.CharacterAdded:Connect(function(char)
    tw(0.5)  -- Đợi character load đủ bộ phận (không dùng jWait để tránh blocking)
    RayParams.FilterDescendantsInstances = {char, Camera}
    if Config.Misc.AntiRagdoll then ApplyAntiRagdoll(char) end
    if Config.Misc.SpeedHack   then ApplySpeed(true,  Config.Misc.SpeedMult) end
    if Config.Misc.JumpPower   then ApplyJump(true,   Config.Misc.JumpPow)   end
    -- [OPT-2]: Quét gun mods khi nhân vật spawn (cầm vũ khí mới)
    tspawn(function() tw(1.5); ScanSprings(); ScanAndPatch() end)
    if _charDiedConn then _charDiedConn:Disconnect(); _charDiedConn = nil end
    if Config.Misc.AutoRespawn then
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            _charDiedConn = hum.Died:Connect(function() tw(1.5); LP:LoadCharacter() end)
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [21] AIMBOT — mousemoverel (hoạt động với mọi camera mode)
-- ════════════════════════════════════════════════════════════
-- Cách đúng để aimbot trong Roblox:
-- Camera.CFrame = ... bị game override ngay frame tiếp theo.
-- Phải dùng mousemoverel(dx, dy) để di chuyển chuột thật,
-- để camera script của game tự xử lý → luôn hoạt động.
-- [OPT-3]: Nếu không có mousemoverel, chỉ tính _aimbotFallbackCF ở Heartbeat,
--          còn việc SET Camera.CFrame thực hiện trong RenderStepped để đồng bộ render.

local hasMoveRel = type(mousemoverel) == "function"

local function AimbotTick()
    if not Config.Aim.Aimbot then _aimbotFallbackCF = nil; return end
    if not TargetRef then _aimbotFallbackCF = nil; return end

    -- Kiểm tra phím giữ
    local keyHeld = false
    if Config.Aim.AimKey == Enum.UserInputType.MouseButton2 then
        keyHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    else
        keyHeld = UserInputService:IsKeyDown(Config.Aim.AimKey)
    end
    if not keyHeld then _aimbotFallbackCF = nil; return end

    -- Tính vị trí aim (với velocity prediction)
    local aimPos = TargetRef.Position
    local ok, predPos = pcall(function()
        local vel = TargetRef.Velocity or Vector3.zero
        return TargetRef.Position + vel * Config.Aim.Prediction
    end)
    if ok and predPos then aimPos = predPos end

    -- Chuyển sang screen space
    local sp, onScreen = Camera:WorldToViewportPoint(aimPos)
    if not onScreen then _aimbotFallbackCF = nil; return end

    local vp = Camera.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2

    -- Delta từ tâm màn hình đến target
    local dx = sp.X - cx
    local dy = sp.Y - cy
    local distPx = sqrt(dx*dx + dy*dy)

    -- Không di chuyển nếu đã rất gần tâm (dead zone)
    if distPx < 1.5 then _aimbotFallbackCF = nil; return end

    -- Smooth: chia cho smoothness → di chuyển từng bước nhỏ
    local smooth = max(Config.Aim.Smoothness, 1)
    local moveX  = dx / smooth
    local moveY  = dy / smooth

    if hasMoveRel then
        -- Primary: dùng mousemoverel để di chuyển chuột thật → không giật
        pcall(mousemoverel, moveX, moveY)
        _aimbotFallbackCF = nil
    else
        -- [OPT-3]: Fallback: KHÔNG set Camera.CFrame ở đây (Heartbeat).
        --          Chỉ tính toán và lưu vào _aimbotFallbackCF,
        --          RenderStepped sẽ apply vào đúng thời điểm render → không giật màn hình.
        local targetCF = CFrame.lookAt(Camera.CFrame.Position, aimPos)
        _aimbotFallbackCF = Camera.CFrame:Lerp(targetCF, 1 / smooth)
    end
end

-- ════════════════════════════════════════════════════════════
-- [21B] ESP + CAMERA FALLBACK — TÁCH RIÊNG VÀO RENDERSTEPPED
-- ════════════════════════════════════════════════════════════
-- ESP chạy trên RenderStepped (sync với render) thay vì Heartbeat
-- Throttle: skip N frame để giảm CPU cost ~50-70%
-- [OPT-3]: Aimbot Camera.CFrame fallback cũng được apply ở đây
local ESP_FRAME_SKIP = 2   -- Cập nhật ESP mỗi 2 frame (~30fps) → mượt + nhẹ
local _espFrameCount = 0

RunService.RenderStepped:Connect(function()
    -- [OPT-3]: Apply Camera.CFrame fallback của Aimbot ở RenderStepped
    --          để đồng bộ với render engine, tránh giật màn hình
    if _aimbotFallbackCF then
        pcall(function() Camera.CFrame = _aimbotFallbackCF end)
    end

    -- ESP Frame throttle
    _espFrameCount = _espFrameCount + 1
    if _espFrameCount < ESP_FRAME_SKIP then return end
    _espFrameCount = 0
    UpdateESP()

    -- FOV Circle (update mỗi frame để không lag)
    if FOVCircle then
        if Config.Aim.ShowFOV and (Config.Aim.Aimbot or Config.Aim.SilentAim) then
            FOVCircle.Visible  = true
            FOVCircle.Radius   = Config.Aim.FOV
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        else
            FOVCircle.Visible = false
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [21C] MAIN HEARTBEAT — Logic only (không ESP, không Camera set)
-- ════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    -- Target finder chạy mỗi frame để aimbot/silent aim chính xác
    TargetRef = GetTarget()

    -- Aimbot (tính toán dx/dy, set _aimbotFallbackCF nếu cần)
    AimbotTick()

    -- TriggerBot
    if Config.TriggerBot.Enabled then
        if not Config.TriggerBot.HoldMode or TB_Held then
            if IsCrosshairOnEnemy() then TBFire() end
        end
    end

    -- No Recoil (mỗi frame)
    if Config.Gun.NoRecoil then NeutralizeRecoil() end

    -- Combat
    UpdateKillAura()
    UpdateAutoDash()
    UpdateBunnyHop()

    -- Infinite Stamina
    if Config.Misc.InfStamina and not STAMINA_THREAD then StartInfStamina() end
end)

-- ════════════════════════════════════════════════════════════
-- [22] INPUT
-- ════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if Config.TriggerBot.Enabled and Config.TriggerBot.HoldMode and inp.KeyCode == Config.TriggerBot.HoldKey then
        TB_Held = true
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Config.TriggerBot.HoldKey then TB_Held = false end
end)

-- ════════════════════════════════════════════════════════════
-- [23] RAYFIELD UI
-- ════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name            = "🔥 Rivals Menu | v5.2 2026",
    LoadingTitle    = "Rivals Stealth Loader",
    LoadingSubtitle = "v5.2 — Khởi động...",
    ConfigurationSaving = { Enabled = true, FolderName = "RivalsPhoenix", FileName = "Config2026" },
    Discord   = { Enabled = false },
    KeySystem  = false,
    KeybindOptions = { Keybind = Enum.KeyCode.End },
})

local T_Aim     = Window:CreateTab("🎯 Aim",       "crosshair")
local T_ESP     = Window:CreateTab("👁 ESP",        "eye")
local T_Combat  = Window:CreateTab("⚔ Combat",     "sword")
local T_Gun     = Window:CreateTab("🔫 Gun",        "zap")
local T_Trigger = Window:CreateTab("⚡ TriggerBot","zap")
local T_FakeLag = Window:CreateTab("🌀 FakeLag",   "wifi-off")
local T_Misc    = Window:CreateTab("⚙ Misc",       "settings")
local T_Config  = Window:CreateTab("💾 Config",    "save")
local T_Info    = Window:CreateTab("📊 Info",       "info")

-- ================================================================
-- 🎯 AIM TAB
-- ================================================================
T_Aim:CreateSection("Silent Aim")
T_Aim:CreateToggle({ Name="Bật Silent Aim", CurrentValue=Config.Aim.SilentAim, Flag="SA_En",
    Callback=function(v) Config.Aim.SilentAim=v end })
T_Aim:CreateSlider({ Name="Silent Strength", Range={0.1,1.0}, Increment=0.05,
    CurrentValue=Config.Aim.SilentStrength, Flag="SA_Str",
    Callback=function(v) Config.Aim.SilentStrength=v end })
T_Aim:CreateSection("Aimbot")
T_Aim:CreateToggle({ Name="Bật Aimbot (giữ Chuột Phải)", CurrentValue=Config.Aim.Aimbot, Flag="AB_En",
    Callback=function(v) Config.Aim.Aimbot=v end })
T_Aim:CreateToggle({ Name="Wallbang (xuyên tường)", CurrentValue=Config.Aim.Wallbang, Flag="AB_WB",
    Callback=function(v) Config.Aim.Wallbang=v end })
T_Aim:CreateToggle({ Name="Team Check", CurrentValue=Config.Aim.TeamCheck, Flag="AB_TC",
    Callback=function(v) Config.Aim.TeamCheck=v end })
T_Aim:CreateDropdown({ Name="Aim Part", Options={"Head","Torso","HumanoidRootPart"},
    CurrentOption={"Head"}, Flag="AB_Part",
    Callback=function(o) Config.Aim.AimPart=o[1] end })
T_Aim:CreateSlider({ Name="FOV Radius (px)", Range={30,800}, Increment=10,
    CurrentValue=Config.Aim.FOV, Flag="AB_FOV",
    Callback=function(v) Config.Aim.FOV=v end })
T_Aim:CreateSlider({ Name="Smoothness (1=snap)", Range={1,20}, Increment=1,
    CurrentValue=Config.Aim.Smoothness, Flag="AB_Sm",
    Callback=function(v) Config.Aim.Smoothness=v end })
T_Aim:CreateSlider({ Name="Prediction (s)", Range={0,0.4}, Increment=0.01, Suffix="s",
    CurrentValue=Config.Aim.Prediction, Flag="AB_Pred",
    Callback=function(v) Config.Aim.Prediction=v end })
T_Aim:CreateToggle({ Name="Hiện FOV Circle", CurrentValue=Config.Aim.ShowFOV, Flag="AB_SFOV",
    Callback=function(v) Config.Aim.ShowFOV=v end })
T_Aim:CreateParagraph({ Title="ℹ️ Aimbot — Cách dùng",
    Content="• Giữ Chuột Phải để Aimbot hoạt động.\n"
        .. "• Dùng mousemoverel(dx, dy) — hoạt động với mọi camera mode.\n"
        .. "• Executor cần có mousemoverel (Synapse Z, Wave, Delta...).\n"
        .. "• Smoothness 1 = snap ngay, 2-4 = tự nhiên, 10+ = rất mềm.\n"
        .. "• [v5.2] Fallback Camera.CFrame dời sang RenderStepped → không giật."
})

-- ================================================================
-- 👁 ESP TAB — nâng cấp hoàn toàn
-- ================================================================
T_ESP:CreateSection("🔌 ESP Chính")
T_ESP:CreateToggle({ Name="BẬT ESP", CurrentValue=Config.ESP.Enabled, Flag="ESP_En",
    Callback=function(v)
        Config.ESP.Enabled=v
        if not v then
            for _,hl in pairs(Highlights) do pcall(function() hl.Enabled=false end) end
            for _,o  in pairs(ESP_Objects) do HideAll(o) end
        end
    end })
T_ESP:CreateToggle({ Name="Team Check (chỉ đối thủ)", CurrentValue=Config.ESP.TeamCheck, Flag="ESP_TC",
    Callback=function(v) Config.ESP.TeamCheck=v end })
T_ESP:CreateToggle({ Name="Distance Gradient (màu theo khoảng cách)", CurrentValue=Config.ESP.DistGradient, Flag="ESP_DG",
    Callback=function(v) Config.ESP.DistGradient=v end })
T_ESP:CreateSlider({ Name="Max Dist cho Gradient (studs)", Range={50,500}, Increment=10,
    CurrentValue=Config.ESP.MaxDistColor, Flag="ESP_MDC",
    Callback=function(v) Config.ESP.MaxDistColor=v end })
T_ESP:CreateSlider({ Name="⚡ ESP Frame Skip (1=60fps, 2=30fps, 3=20fps)", Range={1,4}, Increment=1,
    CurrentValue=ESP_FRAME_SKIP, Flag="ESP_FSkip",
    Callback=function(v) ESP_FRAME_SKIP=v end })

T_ESP:CreateSection("🎨 Chams 3D (Highlight)")
T_ESP:CreateToggle({ Name="Bật Chams / Highlight 3D", CurrentValue=Config.ESP.Chams, Flag="ESP_Chams",
    Callback=function(v) Config.ESP.Chams=v
        if not v then for _,hl in pairs(Highlights) do pcall(function() hl.Enabled=false end) end end
    end })
T_ESP:CreateColorPicker({ Name="Màu Chams", Color=Config.ESP.ChamsColor, Flag="ESP_ChCol",
    Callback=function(v) Config.ESP.ChamsColor=v end })
T_ESP:CreateSlider({ Name="Chams Transparency", Range={0,1}, Increment=0.05,
    CurrentValue=Config.ESP.ChamsTrans, Flag="ESP_ChTr",
    Callback=function(v) Config.ESP.ChamsTrans=v end })
T_ESP:CreateToggle({ Name="Outline (viền trắng)", CurrentValue=Config.ESP.ChamsOutline, Flag="ESP_ChOut",
    Callback=function(v) Config.ESP.ChamsOutline=v end })

T_ESP:CreateSection("📦 Box")
T_ESP:CreateToggle({ Name="Corner Box (góc — pro style)", CurrentValue=Config.ESP.CornerBox, Flag="ESP_CB",
    Callback=function(v) Config.ESP.CornerBox=v
        if not v then for _,o in pairs(ESP_Objects) do HideCornerBox(o) end end
    end })
T_ESP:CreateColorPicker({ Name="Màu Corner Box", Color=Config.ESP.CornerBoxColor, Flag="ESP_CBCol",
    Callback=function(v) Config.ESP.CornerBoxColor=v end })
T_ESP:CreateSlider({ Name="Độ dài góc (0.05-0.45)", Range={0.05,0.45}, Increment=0.05,
    CurrentValue=Config.ESP.CornerLength, Flag="ESP_CLen",
    Callback=function(v) Config.ESP.CornerLength=v end })
T_ESP:CreateToggle({ Name="Full Box (4 cạnh đầy đủ)", CurrentValue=Config.ESP.FullBox, Flag="ESP_FB",
    Callback=function(v) Config.ESP.FullBox=v end })
T_ESP:CreateToggle({ Name="Filled Box (fill mờ bên trong)", CurrentValue=Config.ESP.FilledBox, Flag="ESP_FillB",
    Callback=function(v) Config.ESP.FilledBox=v end })
T_ESP:CreateSlider({ Name="Filled Box Transparency", Range={0.5,1.0}, Increment=0.05,
    CurrentValue=Config.ESP.FilledBoxTrans, Flag="ESP_FillBT",
    Callback=function(v) Config.ESP.FilledBoxTrans=v end })

T_ESP:CreateSection("🎯 Head Dot")
T_ESP:CreateToggle({ Name="Head Dot (chấm đầu)", CurrentValue=Config.ESP.HeadDot, Flag="ESP_HD",
    Callback=function(v) Config.ESP.HeadDot=v
        if not v then
            for _,o in pairs(ESP_Objects) do
                if o.HeadDot  then o.HeadDot.Visible  = false end
                if o.HeadDotO then o.HeadDotO.Visible = false end
            end
        end
    end })
T_ESP:CreateColorPicker({ Name="Màu Head Dot", Color=Config.ESP.HeadDotColor, Flag="ESP_HDCol",
    Callback=function(v) Config.ESP.HeadDotColor=v end })
T_ESP:CreateSlider({ Name="Head Dot Size", Range={2,10}, Increment=1,
    CurrentValue=Config.ESP.HeadDotSize, Flag="ESP_HDS",
    Callback=function(v) Config.ESP.HeadDotSize=v end })

T_ESP:CreateSection("🦴 Skeleton ESP")
T_ESP:CreateToggle({ Name="Skeleton (hiện xương)", CurrentValue=Config.ESP.Skeleton, Flag="ESP_Skel",
    Callback=function(v) Config.ESP.Skeleton=v end })
T_ESP:CreateColorPicker({ Name="Màu Skeleton", Color=Config.ESP.SkeletonColor, Flag="ESP_SkelCol",
    Callback=function(v) Config.ESP.SkeletonColor=v end })

T_ESP:CreateSection("🧵 Tracers / Snaplines")
T_ESP:CreateToggle({ Name="Bật Tracers", CurrentValue=Config.ESP.Tracers, Flag="ESP_Tr",
    Callback=function(v) Config.ESP.Tracers=v
        if not v then for _,o in pairs(ESP_Objects) do
            if o.Tracer  then o.Tracer.Visible  = false end
            if o.TracerO then o.TracerO.Visible = false end
        end end
    end })
T_ESP:CreateColorPicker({ Name="Màu Tracer", Color=Config.ESP.TracerColor, Flag="ESP_TrCol",
    Callback=function(v) Config.ESP.TracerColor=v end })
T_ESP:CreateDropdown({ Name="Điểm xuất phát Tracer", Options={"Bottom","Center","Top"},
    CurrentOption={"Bottom"}, Flag="ESP_TrOri",
    Callback=function(o) Config.ESP.TracerOrigin=o[1] end })

T_ESP:CreateSection("💬 Tags / Text")
T_ESP:CreateToggle({ Name="Name Tag (tên người chơi)", CurrentValue=Config.ESP.NameTag, Flag="ESP_NT",
    Callback=function(v) Config.ESP.NameTag=v end })
T_ESP:CreateToggle({ Name="Hiện Username", CurrentValue=Config.ESP.ShowUsername, Flag="ESP_UN",
    Callback=function(v) Config.ESP.ShowUsername=v end })
T_ESP:CreateToggle({ Name="Hiện Display Name", CurrentValue=Config.ESP.ShowDisplayName, Flag="ESP_DN",
    Callback=function(v) Config.ESP.ShowDisplayName=v end })
T_ESP:CreateColorPicker({ Name="Màu Name Tag", Color=Config.ESP.NameTagColor, Flag="ESP_NTCol",
    Callback=function(v) Config.ESP.NameTagColor=v end })
T_ESP:CreateToggle({ Name="Khoảng cách (studs)", CurrentValue=Config.ESP.ShowDist, Flag="ESP_Dist",
    Callback=function(v) Config.ESP.ShowDist=v end })
T_ESP:CreateToggle({ Name="Weapon Tag (tên vũ khí)", CurrentValue=Config.ESP.WeaponTag, Flag="ESP_Weap",
    Callback=function(v) Config.ESP.WeaponTag=v end })
T_ESP:CreateColorPicker({ Name="Màu Weapon Tag", Color=Config.ESP.WeaponColor, Flag="ESP_WeapCol",
    Callback=function(v) Config.ESP.WeaponColor=v end })

T_ESP:CreateSection("❤️ Health Bar")
T_ESP:CreateToggle({ Name="Health Bar", CurrentValue=Config.ESP.HealthBar, Flag="ESP_HP",
    Callback=function(v) Config.ESP.HealthBar=v end })
T_ESP:CreateDropdown({ Name="Vị trí HP Bar", Options={"Left","Right"},
    CurrentOption={"Left"}, Flag="ESP_HPS",
    Callback=function(o) Config.ESP.HealthBarSide=o[1] end })

-- ================================================================
-- ⚔ COMBAT TAB
-- ================================================================
T_Combat:CreateSection("KillAura")
T_Combat:CreateToggle({ Name="KillAura (tự tấn công địch gần)", CurrentValue=Config.Combat.KillAura, Flag="KC_En",
    Callback=function(v) Config.Combat.KillAura=v end })
T_Combat:CreateSlider({ Name="KillAura Range (studs)", Range={3,30}, Increment=1,
    CurrentValue=Config.Combat.KillAuraDist, Suffix=" studs", Flag="KC_Dist",
    Callback=function(v) Config.Combat.KillAuraDist=v end })
T_Combat:CreateSection("Mobility")
T_Combat:CreateToggle({ Name="AutoDash (dash vào địch)", CurrentValue=Config.Combat.AutoDash, Flag="AD_En",
    Callback=function(v) Config.Combat.AutoDash=v end })
T_Combat:CreateSlider({ Name="Dash Range", Range={5,60}, Increment=1,
    CurrentValue=Config.Combat.DashDist, Suffix=" studs", Flag="AD_Dist",
    Callback=function(v) Config.Combat.DashDist=v end })
T_Combat:CreateToggle({ Name="BunnyHop", CurrentValue=Config.Combat.BunnyHop, Flag="BH_En",
    Callback=function(v) Config.Combat.BunnyHop=v end })

-- ================================================================
-- 🔫 GUN TAB
-- [OPT-2]: Nút "Quét & Apply ngay" là cách DUY NHẤT để trigger scan thủ công
-- ================================================================
T_Gun:CreateSection("GC Patch — Gun Mods")
T_Gun:CreateToggle({ Name="No Recoil", CurrentValue=Config.Gun.NoRecoil, Flag="GN_NR",
    Callback=function(v) Config.Gun.NoRecoil=v; if v then tspawn(ScanSprings) end; tspawn(ScanAndPatch) end })
T_Gun:CreateToggle({ Name="No Spread", CurrentValue=Config.Gun.NoSpread, Flag="GN_NS",
    Callback=function(v) Config.Gun.NoSpread=v; tspawn(ScanAndPatch) end })
T_Gun:CreateToggle({ Name="Infinite Ammo", CurrentValue=Config.Gun.InfiniteAmmo, Flag="GN_IA",
    Callback=function(v) Config.Gun.InfiniteAmmo=v; if v then tspawn(ScanAndPatch) end end })
T_Gun:CreateToggle({ Name="Instant Reload", CurrentValue=Config.Gun.InstantReload, Flag="GN_IR",
    Callback=function(v) Config.Gun.InstantReload=v; if v then tspawn(ScanAndPatch) end end })
T_Gun:CreateButton({ Name="🔧 Quét & Apply ngay",
    Callback=function()
        -- [OPT-2]: Đây là trigger thủ công duy nhất ngoài CharacterAdded
        local ok, err = pcall(function()
            ScanSprings(); local c = ScanAndPatch()
            Rayfield:Notify({ Title="✅ Gun Mods Applied",
                Content=format("Patched %d props | Springs: %d", c, #RV_Cache.Springs),
                Duration=5, Image=4483362458 })
        end)
        if not ok then
            Rayfield:Notify({ Title="❌ Lỗi", Content=tostring(err), Duration=5, Image=4483362458 })
        end
    end })

-- ================================================================
-- ⚡ TRIGGERBOT
-- ================================================================
T_Trigger:CreateSection("TriggerBot")
T_Trigger:CreateToggle({ Name="Bật TriggerBot", CurrentValue=Config.TriggerBot.Enabled, Flag="TB_En",
    Callback=function(v) Config.TriggerBot.Enabled=v end })
T_Trigger:CreateToggle({ Name="Hold Mode (giữ CapsLock)", CurrentValue=Config.TriggerBot.HoldMode, Flag="TB_Hold",
    Callback=function(v) Config.TriggerBot.HoldMode=v end })
T_Trigger:CreateToggle({ Name="Team Check", CurrentValue=Config.TriggerBot.TeamCheck, Flag="TB_TC",
    Callback=function(v) Config.TriggerBot.TeamCheck=v end })
T_Trigger:CreateToggle({ Name="Visibility Check", CurrentValue=Config.TriggerBot.VisCheck, Flag="TB_VC",
    Callback=function(v) Config.TriggerBot.VisCheck=v end })
T_Trigger:CreateDropdown({ Name="Hitbox", Options={"Head","Torso","HumanoidRootPart"},
    CurrentOption={Config.TriggerBot.Hitbox}, Flag="TB_Part",
    Callback=function(o) Config.TriggerBot.Hitbox=o[1] end })
T_Trigger:CreateSlider({ Name="FOV Check (px)", Range={2,80}, Increment=1, Suffix="px",
    CurrentValue=Config.TriggerBot.FovCheck, Flag="TB_FOV",
    Callback=function(v) Config.TriggerBot.FovCheck=v end })
T_Trigger:CreateSlider({ Name="Pre-Fire Delay (s)", Range={0,0.3}, Increment=0.005, Suffix="s",
    CurrentValue=Config.TriggerBot.Delay, Flag="TB_Del",
    Callback=function(v) Config.TriggerBot.Delay=v end })
T_Trigger:CreateSlider({ Name="Random Delay (s)", Range={0,0.1}, Increment=0.005, Suffix="s",
    CurrentValue=Config.TriggerBot.RandDelay, Flag="TB_RDel",
    Callback=function(v) Config.TriggerBot.RandDelay=v end })

-- ================================================================
-- 🌀 FAKELAG v2 — Packet Delay + Jitter + Burst
-- ================================================================
T_FakeLag:CreateSection("🌐 Packet Delay (SimPing)")
T_FakeLag:CreateToggle({ Name="Bật FakeLag", CurrentValue=Config.FakeLag.Enabled, Flag="FL_En",
    Callback=function(v)
        Config.FakeLag.Enabled = v
        if v then StartFakeLag() else StopFakeLag() end
    end })
T_FakeLag:CreateToggle({ Name="SimPing — Delay Packets (địch thấy bạn lag)", CurrentValue=Config.FakeLag.SimPing, Flag="FL_SP",
    Callback=function(v) Config.FakeLag.SimPing=v end })
T_FakeLag:CreateSlider({ Name="Ping giả (ms)", Range={50,500}, Increment=10, Suffix="ms",
    CurrentValue=Config.FakeLag.PingMs, Flag="FL_PMs",
    Callback=function(v) Config.FakeLag.PingMs=v end })
T_FakeLag:CreateSlider({ Name="Ping Jitter ±(ms)", Range={0,100}, Increment=5, Suffix="ms",
    CurrentValue=Config.FakeLag.PingJitter, Flag="FL_PJit",
    Callback=function(v) Config.FakeLag.PingJitter=v end })
T_FakeLag:CreateParagraph({ Title="ℹ️ SimPing hoạt động thế nào?",
    Content="Trì hoãn toàn bộ FireServer/InvokeServer của bạn đúng (Ping ± Jitter) ms\n"
         .. "trước khi gửi lên server → server hiện ping thật sự cao.\n"
         .. "Bạn vẫn chơi bình thường (client-side), chỉ server thấy lag." })

T_FakeLag:CreateSection("💥 Burst Mode (Spike Ping)")
T_FakeLag:CreateToggle({ Name="Burst Mode — Gom & Xả packets", CurrentValue=Config.FakeLag.BurstMode, Flag="FL_Burst",
    Callback=function(v)
        Config.FakeLag.BurstMode = v
        if Config.FakeLag.Enabled then
            StopFakeLag()
            Config.FakeLag.Enabled = true
            StartFakeLag()
        end
    end })
T_FakeLag:CreateSlider({ Name="Burst Hold — Thời gian GOM (s)", Range={0.05,1.0}, Increment=0.05, Suffix="s",
    CurrentValue=Config.FakeLag.BurstHold, Flag="FL_BH",
    Callback=function(v) Config.FakeLag.BurstHold=v end })
T_FakeLag:CreateSlider({ Name="Burst Fire — Thời gian XẢ (s)", Range={0.02,0.3}, Increment=0.01, Suffix="s",
    CurrentValue=Config.FakeLag.BurstFire, Flag="FL_BF",
    Callback=function(v) Config.FakeLag.BurstFire=v end })

T_FakeLag:CreateSection("🫨 Position Jitter (Server-side Stutter)")
T_FakeLag:CreateToggle({ Name="Position Jitter — Nhân vật giật phía server", CurrentValue=Config.FakeLag.PosJitter, Flag="FL_PJ",
    Callback=function(v)
        Config.FakeLag.PosJitter = v
        if v and Config.FakeLag.Enabled and FL_CancelToken then StartJitter(FL_CancelToken) end
    end })
T_FakeLag:CreateSlider({ Name="Jitter Amount (0=tắt, 1=luôn freeze)", Range={0.01,0.95}, Increment=0.01,
    CurrentValue=Config.FakeLag.JitterAmt, Flag="FL_JA",
    Callback=function(v) Config.FakeLag.JitterAmt=v end })
T_FakeLag:CreateParagraph({ Title="ℹ️ Jitter hoạt động thế nào?",
    Content="Ngẫu nhiên freeze vị trí HumanoidRootPart.\n"
         .. "Server thấy nhân vật bạn đứng yên rồi teleport → khó nhắm rất.\n"
         .. "Client-side bạn không bị ảnh hưởng gì." })
T_FakeLag:CreateSection("👻 Ghost Lag (Lag Chams / Ảo Ảnh)")
-- [PART-2] Ghost Lag UI — bóng ma hiện vị trí server đang nhận diện bạn
T_FakeLag:CreateToggle({ Name="Ghost Lag — Hiện bóng ma vị trí lag", CurrentValue=Config.FakeLag.GhostShow, Flag="FL_Ghost",
    Callback=function(v)
        Config.FakeLag.GhostShow = v
        -- Nếu tắt: destroy ghost ngay lập tức (memory cleanup)
        if not v then DestroyGhost() end
    end })
T_FakeLag:CreateColorPicker({ Name="Màu Ghost (Color3)", Color=Config.FakeLag.GhostColor, Flag="FL_GhostCol",
    Callback=function(v)
        Config.FakeLag.GhostColor = v
        -- Update live nếu ghost đang tồn tại
        if FL_GhostModel then
            for _, p in ipairs(FL_GhostModel:GetChildren()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Color = v
                end
            end
        end
    end })
T_FakeLag:CreateSlider({ Name="Ghost Transparency (0=đặc, 1=ẩn)", Range={0.1,0.95}, Increment=0.05,
    CurrentValue=Config.FakeLag.GhostTrans, Flag="FL_GhostTr",
    Callback=function(v)
        Config.FakeLag.GhostTrans = v
        -- Update live
        if FL_GhostModel then
            for _, p in ipairs(FL_GhostModel:GetChildren()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Transparency = v
                end
            end
        end
    end })
T_FakeLag:CreateDropdown({ Name="Ghost Material", Options={"ForceField","Neon","SmoothPlastic"},
    CurrentOption={"ForceField"}, Flag="FL_GhostMat",
    Callback=function(o)
        -- Áp material mới lên ghost đang tồn tại ngay lập tức
        local matMap = { ForceField=Enum.Material.ForceField, Neon=Enum.Material.Neon, SmoothPlastic=Enum.Material.SmoothPlastic }
        local mat = matMap[o[1]] or Enum.Material.ForceField
        if FL_GhostModel then
            for _, p in ipairs(FL_GhostModel:GetChildren()) do
                if p:IsA("BasePart") then p.Material = mat end
            end
        end
    end })
T_FakeLag:CreateButton({ Name="🔄 Rebuild Ghost ngay",
    Callback=function()
        -- Force rebuild ghost model (dùng khi character đổi skin/outfit)
        DestroyGhost()
        local char = LP.Character
        if char and Config.FakeLag.GhostShow then
            local g = CreateGhost(char)
            Rayfield:Notify({ Title="👻 Ghost", Content=g and "Rebuild thành công!" or "Thất bại (chưa spawn?)", Duration=3, Image=4483362458 })
        else
            Rayfield:Notify({ Title="👻 Ghost", Content="Bật Ghost Show trước!", Duration=3, Image=4483362458 })
        end
    end })
T_FakeLag:CreateParagraph({ Title="ℹ️ Ghost Lag hoạt động thế nào?",
    Content="Tạo bản sao bán trong suốt của nhân vật, đứng ở vị trí lag (PingMs giây trước).\n"
         .. "→ Bạn thấy được chính xác server đang nhìn thấy bạn ở đâu.\n"
         .. "Chỉ client thấy ghost, server không nhận — không vi phạm thêm." })

T_FakeLag:CreateSection("⚡ Control")
T_FakeLag:CreateButton({ Name="⚡ Flush Queue (Gửi hết packets đọng)",
    Callback=function()
        -- [FIX] FL_PacketQueue là Queue struct {data,head,tail}, không phải array thường
        local q = FL_PacketQueue
        local count = 0
        FL_QueueActive = false
        for i = q.head, q.tail do
            local pkt = q.data[i]
            if pkt then pcall(pkt.fn); count = count + 1 end
        end
        Q_Reset(q)
        Rayfield:Notify({ Title="⚡ Flushed", Content=count.." packets đã được gửi.", Duration=3, Image=4483362458 })
    end })
T_FakeLag:CreateButton({ Name="📊 Xem trạng thái Queue",
    Callback=function()
        -- [FIX] Đếm đúng từ Queue struct
        local q = FL_PacketQueue
        local qCount = 0
        for i = q.head, q.tail do if q.data[i] then qCount = qCount + 1 end end
        Rayfield:Notify({
            Title   = "🌀 FakeLag Status",
            Content = format("Queue: %d packets\nSimPing: %dms ±%dms\nBurst: %s | Jitter: %s\nGhost: %s",
                qCount,
                Config.FakeLag.PingMs, Config.FakeLag.PingJitter,
                Config.FakeLag.BurstMode and "ON" or "OFF",
                Config.FakeLag.PosJitter and "ON" or "OFF",
                Config.FakeLag.GhostShow and "ON" or "OFF"),
            Duration = 5, Image = 4483362458
        })
    end })

-- ================================================================
-- ⚙ MISC
-- ================================================================
T_Misc:CreateSection("Movement")
T_Misc:CreateToggle({ Name="Speed Hack", CurrentValue=Config.Misc.SpeedHack, Flag="MS_Sp",
    Callback=function(v) Config.Misc.SpeedHack=v; ApplySpeed(v, Config.Misc.SpeedMult) end })
T_Misc:CreateSlider({ Name="Speed Multiplier", Range={1.1,6}, Increment=0.1, Suffix="x",
    CurrentValue=Config.Misc.SpeedMult, Flag="MS_SpM",
    Callback=function(v) Config.Misc.SpeedMult=v; if Config.Misc.SpeedHack then ApplySpeed(true,v) end end })
T_Misc:CreateToggle({ Name="High Jump", CurrentValue=Config.Misc.JumpPower, Flag="MS_JP",
    Callback=function(v) Config.Misc.JumpPower=v; ApplyJump(v, Config.Misc.JumpPow) end })
T_Misc:CreateSlider({ Name="Jump Power", Range={50,300}, Increment=5,
    CurrentValue=Config.Misc.JumpPow, Flag="MS_JPow",
    Callback=function(v) Config.Misc.JumpPow=v; if Config.Misc.JumpPower then ApplyJump(true,v) end end })
T_Misc:CreateSection("Survival")
T_Misc:CreateToggle({ Name="Infinite Stamina", CurrentValue=Config.Misc.InfStamina, Flag="MS_Stam",
    Callback=function(v) Config.Misc.InfStamina=v; if v then StartInfStamina() end end })
T_Misc:CreateToggle({ Name="Anti Ragdoll", CurrentValue=Config.Misc.AntiRagdoll, Flag="MS_ARag",
    Callback=function(v) Config.Misc.AntiRagdoll=v; if v then ApplyAntiRagdoll(LP.Character) end end })
T_Misc:CreateToggle({ Name="Auto Respawn", CurrentValue=Config.Misc.AutoRespawn, Flag="MS_AR",
    Callback=function(v) Config.Misc.AutoRespawn=v end })
T_Misc:CreateSection("Performance")
T_Misc:CreateButton({ Name="🔥 FPS Boost",
    Callback=function()
        local n=0
        for _,v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Texture") or v:IsA("Decal") then pcall(function() v:Destroy() end); n+=1
            elseif v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
                pcall(function() v.Enabled=false end); n+=1
            end
        end
        pcall(function() Lighting.GlobalShadows=false; Lighting.FogEnd=100000
            settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
        Rayfield:Notify({ Title="🔥 FPS Boost", Content=n.." objects processed.", Duration=4, Image=4483362458 })
    end })

-- ================================================================
-- 💾 CONFIG TAB (QUẢN LÝ LƯU/TẢI CONFIG)
-- ================================================================
local CONFIG_FOLDER = "Rivals_v5_Configs"
if isfolder and not isfolder(CONFIG_FOLDER) then pcall(function() makefolder(CONFIG_FOLDER) end) end

local _CurrentCfgName = ""
local _SelectedCfg = ""

local function GetConfigList()
    local list = {}
    if listfiles and isfolder(CONFIG_FOLDER) then
        local ok, files = pcall(function() return listfiles(CONFIG_FOLDER) end)
        if ok then
            for _, file in ipairs(files) do
                local name = file:match("([^/%\\]+)%.json$")
                if name then table.insert(list, name) end
            end
        end
    end
    return list
end

local function SaveCustomConfig(name)
    if not writefile then return false end
    local data = {}
    for flag, obj in pairs(Rayfield.Flags) do
        -- Bỏ qua dropdown list của chính tab này để tránh đúp data
        if flag ~= "CFG_List" then
            local val = obj.CurrentValue
            if typeof(val) == "Color3" then
                data[flag] = { _t = "Color3", R = val.R, G = val.G, B = val.B }
            elseif typeof(val) == "EnumItem" then
                data[flag] = { _t = "Enum", E = tostring(val.EnumType), N = val.Name }
            else
                data[flag] = val
            end
        end
    end
    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then
        pcall(function() writefile(CONFIG_FOLDER .. "/" .. name .. ".json", json) end)
        return true
    end
    return false
end

local function LoadCustomConfig(name)
    if not readfile then return false end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile or not isfile(path) then return false end

    local ok1, txt = pcall(function() return readfile(path) end)
    if not ok1 then return false end

    local ok2, data = pcall(function() return HttpService:JSONDecode(txt) end)
    if not ok2 or type(data) ~= "table" then return false end

    for flag, saved in pairs(data) do
        local obj = Rayfield.Flags[flag]
        if obj then
            local realVal = saved
            if type(saved) == "table" then
                if saved._t == "Color3" then
                    realVal = Color3.new(saved.R, saved.G, saved.B)
                elseif saved._t == "Enum" then
                    pcall(function() realVal = Enum[saved.E][saved.N] end)
                end
            end
            pcall(function() obj:Set(realVal) end)
        end
    end
    return true
end

T_Config:CreateSection("Lưu Config Mới")
T_Config:CreateInput({
    Name = "Tên Config Mới",
    PlaceholderText = "Nhập tên (vd: Legit, Rage)...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt) _CurrentCfgName = txt end
})
T_Config:CreateButton({ Name = "💾 Lưu Config",
    Callback = function()
        if _CurrentCfgName == "" then
            return Rayfield:Notify({Title="Lỗi", Content="Vui lòng nhập tên!", Duration=2})
        end
        if SaveCustomConfig(_CurrentCfgName) then
            Rayfield:Notify({Title="Thành công", Content="Đã lưu " .. _CurrentCfgName, Duration=3, Image=4483362458})
            Rayfield.Flags["CFG_List"]:Refresh(GetConfigList(), true)
        else
            Rayfield:Notify({Title="Lỗi", Content="Executor không hỗ trợ ghi file (writefile)", Duration=3})
        end
    end
})

T_Config:CreateSection("Quản lý Config Đã Lưu")
T_Config:CreateDropdown({
    Name = "Danh sách Config",
    Options = GetConfigList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "CFG_List",
    Callback = function(opt) _SelectedCfg = opt[1] end
})
T_Config:CreateButton({ Name = "📂 Tải (Load) Config nảy",
    Callback = function()
        if not _SelectedCfg or _SelectedCfg == "" then return end
        if LoadCustomConfig(_SelectedCfg) then
            Rayfield:Notify({Title="Thành công", Content="Đã tải " .. _SelectedCfg, Duration=3, Image=4483362458})
        else
            Rayfield:Notify({Title="Lỗi", Content="Tải thất bại (file hỏng hoặc lỗi executor).", Duration=3})
        end
    end
})
T_Config:CreateButton({ Name = "❌ Xóa (Delete) Config này",
    Callback = function()
        if not _SelectedCfg or _SelectedCfg == "" then return end
        local path = CONFIG_FOLDER .. "/" .. _SelectedCfg .. ".json"
        if isfile and delfile and isfile(path) then
            pcall(function() delfile(path) end)
            Rayfield:Notify({Title="Đã xóa", Content="Đã xóa config " .. _SelectedCfg, Duration=3, Image=4483362458})
            Rayfield.Flags["CFG_List"]:Refresh(GetConfigList(), true)
        end
    end
})
T_Config:CreateButton({ Name = "🔄 Làm mới danh sách",
    Callback = function()
        Rayfield.Flags["CFG_List"]:Refresh(GetConfigList(), true)
        Rayfield:Notify({Title="Config", Content="Đã cập nhật danh sách.", Duration=2, Image=4483362458})
    end
})

-- ================================================================
-- 📊 INFO TAB
-- ================================================================
T_Info:CreateSection("Executor Capabilities")
T_Info:CreateParagraph({ Title="🔍 Status",
    Content=format(
        "hookmetamethod : %s\ncheckcaller     : %s\ngetgc           : %s\ngetupvalue      : %s\nsetreadonly     : %s\ncloneref        : %s\nDrawing API     : %s",
        hasHook     and "✅" or "❌",
        hasCheck    and "✅" or "❌",
        hasGC       and "✅" or "❌",
        hasGetUpval and "✅" or "❌",
        hasSetRO    and "✅" or "❌",
        hasCloneRef and "✅" or "❌",
        hasDrawing  and "✅" or "❌"
    ) })
T_Info:CreateSection("Anti-Detect")
T_Info:CreateToggle({ Name="Block AC Remotes", CurrentValue=Config.AntiDetect.BlockAC, Flag="AD_BAC",
    Callback=function(v) Config.AntiDetect.BlockAC=v end })
T_Info:CreateToggle({ Name="Noise Delay", CurrentValue=Config.AntiDetect.NoiseDelay, Flag="AD_ND",
    Callback=function(v) Config.AntiDetect.NoiseDelay=v end })
T_Info:CreateButton({ Name="🧹 Clean Global Trace",
    Callback=function()
        pcall(function() _G["__RIVALS_LOADED"]=nil end)
        Rayfield:Notify({ Title="🧹 Cleaned", Content="Global trace cleared.", Duration=3, Image=4483362458 })
    end })
T_Info:CreateButton({ Name="🔄 Re-Scan Gun Mods",
    Callback=function()
        -- [OPT-2]: Cho phép user trigger scan thủ công bất cứ lúc nào từ Info tab
        tspawn(function()
            ScanSprings(); local c=ScanAndPatch()
            Rayfield:Notify({ Title="🔄 Re-Scanned", Content=format("Patched %d props.",c), Duration=3, Image=4483362458 })
        end)
    end })
T_Info:CreateParagraph({ Title="📋 ESP Features v5.2 (Optimized)",
    Content = [[
• Chams 3D (Highlight — AlwaysOnTop)
• Corner Box (4 góc — pro style + outline)
• Full Box + Filled Box (fill mờ)
• Head Dot (circle đầu + outline)
• Skeleton ESP (R15 + R6 fallback, 15 joints) — với đầy đủ safety checks
• Tracers (Bottom/Center/Top origin)
• Name Tag (Username + DisplayName)
• Distance Tag (gradient màu theo khoảng cách)
• Weapon Tag (tên vũ khí hiện tại)
• Health Bar (trái/phải + số HP)
• Distance Gradient (xanh→đỏ)
• Shadow/outline cho mọi drawing element
[v5.2 OPT] __namecall: O(1) lookup — không còn dxor() trong hook
[v5.2 OPT] GC scan: kích hoạt theo CharacterAdded, không còn while-true
[v5.2 OPT] Aimbot fallback: Camera.CFrame set trong RenderStepped
[v5.2 OPT] Skeleton: full sanity checks, không còn error console
]] })

-- Notify
Rayfield:Notify({
    Title   = "🔥 Rivals Menu v5.2 Loaded!",
    Content = "ESP + Attack Edition (Optimized)\nStealth: ON | Drawing: " .. (hasDrawing and "✅" or "❌"),
    Duration = 6,
    Image    = 4483362458,
})

end -- /RivalsMain
RivalsMain()
