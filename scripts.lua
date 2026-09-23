
if _G.__util_loaded then
    warn("already running")
    return
end
_G.__util_loaded = true

local VirtualInputManager = game:GetService("VirtualInputManager")
local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local TweenService         = game:GetService("TweenService")
local Lighting             = game:GetService("Lighting")
local HttpService          = game:GetService("HttpService")

local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled
    and not UserInputService.KeyboardEnabled

local CACHE_FOLDER = "UniversalScript"
local CACHE_FILE   = CACHE_FOLDER .. "/settings.json"

pcall(function()
    if makefolder and isfolder and not isfolder(CACHE_FOLDER) then
        makefolder(CACHE_FOLDER)
    end
end)

local ESP_COLOR = Color3.fromRGB(255, 255, 255)

local DefaultSettings = {
    ESP_Enabled            = true,
    ESP_Highlight          = true,
    ESP_Name               = true,
    ESP_Studs              = true,
    ESP_Tracer             = false,
    ESP_HealthBar          = true,
    ESP_BoxTransparency    = 0.5,
    ESP_MaxDistance        = 500,

    Aimbot_Enabled         = true,
    Aimbot_FOVRadius       = 100,
    Aimbot_WallCheck       = false,
    Aimbot_Smoothness      = 1,
    Aimbot_TeamCheck       = true,

    Triggerbot_Enabled     = true,
    Triggerbot_MaxDistance = 1000,

    InfJump_Enabled        = false,
    Speed_Enabled          = false,
    Speed_Value            = 32,
    Fly_Enabled            = false,
    Fly_Speed              = 60,
    Noclip_Enabled         = false,
    Fullbright_Enabled     = false,
    AntiAFK_Enabled        = true,
    HitboxExpander_Enabled = false,
    HitboxExpander_Size    = 5,
    CameraFOV_Enabled      = false,
    CameraFOV_Value        = 70,
}

local function loadSettings()
    local ok, result = pcall(function()
        if isfile and isfile(CACHE_FILE) then
            local decoded = HttpService:JSONDecode(readfile(CACHE_FILE))
            for k, v in pairs(DefaultSettings) do
                if decoded[k] == nil then
                    decoded[k] = v
                end
            end
            return decoded
        end
    end)
    if ok and result then return result end

    local t = {}
    for k, v in pairs(DefaultSettings) do t[k] = v end
    return t
end

local SERIALIZABLE = { boolean = true, number = true, string = true }

local function saveSettings(s)
    pcall(function()
        if not writefile then return end
        if makefolder and isfolder and not isfolder(CACHE_FOLDER) then
            makefolder(CACHE_FOLDER)
        end
        local clean = {}
        for k, v in pairs(s) do
            if SERIALIZABLE[typeof(v)] or v == nil then
                clean[k] = v
            end
        end
        writefile(CACHE_FILE, HttpService:JSONEncode(clean))
    end)
end

local Settings = loadSettings()
Settings.Triggerbot_MaxDistance = 1000

local _connections = {}
local function trackConn(c)
    table.insert(_connections, c)
    return c
end

local _killed     = false
local circleDraw  = nil
local tracerLines = {}

local function killScript()
    if _killed then return end
    _killed = true

    Settings.Aimbot_Enabled     = false
    Settings.Triggerbot_Enabled = false
    Settings.ESP_Enabled        = false
    Settings.InfJump_Enabled    = false
    Settings.Fly_Enabled        = false
    Settings.Noclip_Enabled     = false

    for _, c in ipairs(_connections) do
        pcall(function() c:Disconnect() end)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, name in ipairs({
                "ESP_Highlight", "ESP_Billboard",
                "HealthBackground", "HealthOutline"
            }) do
                local obj = player.Character:FindFirstChild(name)
                if obj then pcall(function() obj:Destroy() end) end
            end
        end
    end

    if circleDraw then
        pcall(function() circleDraw:Remove() end)
        circleDraw = nil
    end

    for _, line in pairs(tracerLines) do
        pcall(function()
            line.Visible = false
            line:Remove()
        end)
    end
    tracerLines = {}

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, name in ipairs({
            "UniversalMenu", "UniversalMobile", "UniversalStartup"
        }) do
            local g = playerGui:FindFirstChild(name)
            if g then pcall(function() g:Destroy() end) end
        end
    end

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") and v.Name == "UStartupBlur" then
            v:Destroy()
        end
    end

    _G.__util_loaded = nil
    print("script stopped")
end

-- Startup overlay

local function showStartup()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") and v.Name == "UStartupBlur" then
            v:Destroy()
        end
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("UniversalStartup")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name            = "UniversalStartup"
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.DisplayOrder    = 1000
    gui.Parent          = playerGui

    local blur = Instance.new("BlurEffect")
    blur.Name   = "UStartupBlur"
    blur.Size   = 18
    blur.Parent = Lighting

    local overlay = Instance.new("Frame")
    overlay.Size                   = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.18
    overlay.BorderSizePixel        = 0
    overlay.Parent                 = gui

    local card = Instance.new("Frame")
    card.AnchorPoint      = Vector2.new(0.5, 0.5)
    card.Position         = UDim2.fromScale(0.5, 0.5)
    card.Size             = UDim2.fromOffset(430, 210)
    card.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    card.BorderSizePixel  = 0
    card.Parent           = overlay

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(45, 45, 45)
    stroke.Thickness    = 1
    stroke.Transparency = 0.15
    stroke.Parent       = card

    local title = Instance.new("TextLabel")
    title.AnchorPoint            = Vector2.new(0.5, 0.5)
    title.Position               = UDim2.new(0.5, 0, 0.36, 0)
    title.Size                   = UDim2.new(1, -40, 0, 40)
    title.BackgroundTransparency = 1
    title.Text                   = "Utility Menu"
    title.TextColor3             = Color3.fromRGB(255, 255, 255)
    title.TextSize               = 25
    title.Font                   = Enum.Font.GothamBold
    title.Parent                 = card

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint            = Vector2.new(0.5, 0.5)
    sub.Position               = UDim2.new(0.5, 0, 0.55, 0)
    sub.Size                   = UDim2.new(1, -40, 0, 28)
    sub.BackgroundTransparency = 1
    sub.Text                   = isMobile
        and "Tap the <> button to open"
        or "Press Right Control to open"
    sub.TextColor3 = Color3.fromRGB(165, 165, 165)
    sub.TextSize   = 16
    sub.Font       = Enum.Font.GothamMedium
    sub.Parent     = card

    local line = Instance.new("Frame")
    line.AnchorPoint      = Vector2.new(0.5, 0.5)
    line.Position         = UDim2.new(0.5, 0, 0.70, 0)
    line.Size             = UDim2.new(0.72, 0, 0, 1)
    line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    line.BorderSizePixel  = 0
    line.Parent           = card

    local credit = Instance.new("TextLabel")
    credit.AnchorPoint            = Vector2.new(0.5, 0.5)
    credit.Position               = UDim2.new(0.5, 0, 0.84, 0)
    credit.Size                   = UDim2.new(1, -40, 0, 25)
    credit.BackgroundTransparency = 1
    credit.Text                   = "loaded"
    credit.TextColor3             = Color3.fromRGB(125, 125, 125)
    credit.TextSize               = 14
    credit.Font                   = Enum.Font.GothamMedium
    credit.Parent                 = card

    task.delay(2.5, function()
        if not gui.Parent then
            blur:Destroy()
            return
        end

        local fade = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _, obj in ipairs({ overlay, card }) do
            TweenService:Create(obj, fade, { BackgroundTransparency = 1 }):Play()
        end
        for _, obj in ipairs({ title, sub, credit }) do
            TweenService:Create(obj, fade, { TextTransparency = 1 }):Play()
        end
        TweenService:Create(line, fade, { BackgroundTransparency = 1 }):Play()

        task.wait(0.5)
        blur:Destroy()
        if gui.Parent then gui:Destroy() end
    end)
end

showStartup()

-- GUI

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "UniversalMenu"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.Parent         = LocalPlayer:WaitForChild("PlayerGui")

local BackgroundFrame = Instance.new("Frame")
BackgroundFrame.Size                   = UDim2.fromScale(1, 1)
BackgroundFrame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
BackgroundFrame.BackgroundTransparency = 0.45
BackgroundFrame.BorderSizePixel        = 0
BackgroundFrame.Visible                = false
BackgroundFrame.ZIndex                 = 100
BackgroundFrame.Parent                 = ScreenGui

local MenuFrame = Instance.new("Frame")
MenuFrame.AnchorPoint      = Vector2.new(0.5, 0.5)
MenuFrame.Size             = UDim2.fromOffset(390, 0)
MenuFrame.Position         = UDim2.fromScale(0.5, 0.5)
MenuFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MenuFrame.BorderSizePixel  = 0
MenuFrame.Visible          = false
MenuFrame.ZIndex           = 101
MenuFrame.Parent           = ScreenGui

Instance.new("UICorner", MenuFrame).CornerRadius = UDim.new(0, 14)

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color        = Color3.fromRGB(42, 42, 42)
MenuStroke.Thickness    = 1
MenuStroke.Transparency = 0.1
MenuStroke.Parent       = MenuFrame

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size                   = UDim2.new(1, -40, 0, 42)
MenuTitle.Position               = UDim2.new(0, 20, 0, 12)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text                   = "Utility Menu"
MenuTitle.TextColor3             = Color3.fromRGB(255, 255, 255)
MenuTitle.Font                   = Enum.Font.GothamBold
MenuTitle.TextSize               = 25
MenuTitle.TextXAlignment         = Enum.TextXAlignment.Left
MenuTitle.ZIndex                 = 102
MenuTitle.Parent                 = MenuFrame

local MenuSubtitle = Instance.new("TextLabel")
MenuSubtitle.Size                   = UDim2.new(1, -40, 0, 20)
MenuSubtitle.Position               = UDim2.new(0, 20, 0, 45)
MenuSubtitle.BackgroundTransparency = 1
MenuSubtitle.Text                   = "Aimbot, ESP, Movement"
MenuSubtitle.TextColor3             = Color3.fromRGB(105, 105, 105)
MenuSubtitle.Font                   = Enum.Font.GothamMedium
MenuSubtitle.TextSize               = 13
MenuSubtitle.TextXAlignment         = Enum.TextXAlignment.Left
MenuSubtitle.ZIndex                 = 102
MenuSubtitle.Parent                 = MenuFrame

-- Kill button

local function showKillConfirm()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local old = playerGui:FindFirstChild("KillConfirmGui")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "KillConfirmGui"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder   = 2000
    gui.Parent         = playerGui

    local overlay = Instance.new("Frame")
    overlay.Size                   = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.55
    overlay.BorderSizePixel        = 0
    overlay.ZIndex                 = 200
    overlay.Parent                 = gui

    local card = Instance.new("Frame")
    card.AnchorPoint      = Vector2.new(0.5, 0.5)
    card.Position         = UDim2.fromScale(0.5, 0.5)
    card.Size             = UDim2.fromOffset(340, 148)
    card.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    card.BorderSizePixel  = 0
    card.ZIndex           = 201
    card.Parent           = overlay

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color        = Color3.fromRGB(55, 55, 55)
    cardStroke.Thickness    = 1
    cardStroke.Transparency = 0.1
    cardStroke.Parent       = card

    local title = Instance.new("TextLabel")
    title.Size                   = UDim2.new(1, -32, 0, 28)
    title.Position               = UDim2.new(0, 16, 0, 16)
    title.BackgroundTransparency = 1
    title.Text                   = "Stop Script"
    title.TextColor3             = Color3.fromRGB(255, 255, 255)
    title.Font                   = Enum.Font.GothamBold
    title.TextSize               = 17
    title.TextXAlignment         = Enum.TextXAlignment.Left
    title.ZIndex                 = 202
    title.Parent                 = card

    local body = Instance.new("TextLabel")
    body.Size                   = UDim2.new(1, -32, 0, 36)
    body.Position               = UDim2.new(0, 16, 0, 48)
    body.BackgroundTransparency = 1
    body.Text                   = "This fully shuts down the script. You will need to re-run it to use it again."
    body.TextColor3             = Color3.fromRGB(255, 255, 255)
    body.Font                   = Enum.Font.GothamMedium
    body.TextSize               = 12
    body.TextXAlignment         = Enum.TextXAlignment.Left
    body.TextWrapped            = true
    body.ZIndex                 = 202
    body.Parent                 = card

    local divider = Instance.new("Frame")
    divider.Size             = UDim2.new(1, -32, 0, 1)
    divider.Position         = UDim2.new(0, 16, 0, 96)
    divider.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    divider.BorderSizePixel  = 0
    divider.ZIndex           = 202
    divider.Parent           = card

    local cancel = Instance.new("TextButton")
    cancel.Size             = UDim2.new(0.5, -20, 0, 32)
    cancel.Position         = UDim2.new(0, 16, 0, 105)
    cancel.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    cancel.BorderSizePixel  = 0
    cancel.Text             = "Cancel"
    cancel.TextColor3       = Color3.fromRGB(255, 255, 255)
    cancel.Font             = Enum.Font.GothamMedium
    cancel.TextSize         = 13
    cancel.AutoButtonColor  = false
    cancel.ZIndex           = 202
    cancel.Parent           = card
    Instance.new("UICorner", cancel).CornerRadius = UDim.new(0, 8)

    local confirm = Instance.new("TextButton")
    confirm.Size             = UDim2.new(0.5, -20, 0, 32)
    confirm.Position         = UDim2.new(0.5, 4, 0, 105)
    confirm.BackgroundColor3 = Color3.fromRGB(140, 28, 28)
    confirm.BorderSizePixel  = 0
    confirm.Text             = "Stop"
    confirm.TextColor3       = Color3.fromRGB(255, 255, 255)
    confirm.Font             = Enum.Font.GothamBold
    confirm.TextSize         = 13
    confirm.AutoButtonColor  = false
    confirm.ZIndex           = 202
    confirm.Parent           = card
    Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 8)

    cancel.MouseButton1Click:Connect(function() gui:Destroy() end)
    confirm.MouseButton1Click:Connect(function()
        gui:Destroy()
        killScript()
    end)
end

local KillButton = Instance.new("TextButton")
KillButton.AnchorPoint      = Vector2.new(1, 1)
KillButton.Size             = UDim2.fromOffset(34, 34)
KillButton.Position         = UDim2.new(1, -18, 1, -18)
KillButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
KillButton.BorderSizePixel  = 0
KillButton.Text             = ""
KillButton.AutoButtonColor  = false
KillButton.Visible          = false
KillButton.ZIndex           = 110
KillButton.Parent           = ScreenGui

Instance.new("UICorner", KillButton).CornerRadius = UDim.new(0, 8)

local KillStroke = Instance.new("UIStroke")
KillStroke.Color        = Color3.fromRGB(70, 70, 70)
KillStroke.Thickness    = 1
KillStroke.Transparency = 0.3
KillStroke.Parent       = KillButton

local function makeXLine(parent, rot)
    local f = Instance.new("Frame")
    f.AnchorPoint      = Vector2.new(0.5, 0.5)
    f.Position         = UDim2.fromScale(0.5, 0.5)
    f.Size             = UDim2.new(0, 15, 0, 2)
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.BorderSizePixel  = 0
    f.Rotation         = rot
    f.ZIndex           = 111
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    return f
end

local x1 = makeXLine(KillButton, 45)
local x2 = makeXLine(KillButton, -45)

local function updateKillButtonPosition()
    if not MenuFrame.Visible then
        KillButton.Visible = false
        return
    end
    KillButton.Visible = true
    KillButton.Position = UDim2.new(
        1, isMobile and -10 or -18,
        1, isMobile and -10 or -18
    )
end

KillButton.MouseEnter:Connect(function()
    TweenService:Create(KillButton, TweenInfo.new(0.12),
        { BackgroundColor3 = Color3.fromRGB(60, 20, 20) }):Play()
end)
KillButton.MouseLeave:Connect(function()
    TweenService:Create(KillButton, TweenInfo.new(0.12),
        { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }):Play()
end)
KillButton.MouseButton1Click:Connect(showKillConfirm)

-- Toggle framework

local ToggleContainer = Instance.new("Frame")
ToggleContainer.Size                   = UDim2.new(1, -30, 0, 0)
ToggleContainer.Position               = UDim2.new(0, 15, 0, 70)
ToggleContainer.BackgroundTransparency = 1
ToggleContainer.BorderSizePixel        = 0
ToggleContainer.AutomaticSize          = Enum.AutomaticSize.Y
ToggleContainer.ZIndex                 = 103
ToggleContainer.Parent                 = MenuFrame

local ToggleList = Instance.new("UIListLayout")
ToggleList.Padding             = UDim.new(0, 5)
ToggleList.SortOrder           = Enum.SortOrder.LayoutOrder
ToggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ToggleList.Parent              = ToggleContainer

local SYNC_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local espChildren    = {}
local aimbotChildren = {}
local updateFOVVisual, updateFOVPosition

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function recalcMenuHeight()
    task.defer(function()
        task.wait(0.05)
        local h = ToggleContainer.AbsoluteSize.Y
        if h > 0 then
            MenuFrame.Size = UDim2.new(0, 390, 0, 70 + h + 15)
            updateKillButtonPosition()
        end
    end)
end

local function updateAllSubToggles()
    for _, fn in ipairs(espChildren)    do fn() end
    for _, fn in ipairs(aimbotChildren) do fn() end
    if updateFOVPosition then updateFOVPosition() end
end

local function createMasterToggle(name, getState, setState, order)
    local button = Instance.new("TextButton")
    button.Size             = UDim2.new(1, -6, 0, 39)
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    button.BorderSizePixel  = 0
    button.Text             = ""
    button.AutoButtonColor  = false
    button.LayoutOrder      = order
    button.ZIndex           = 104
    button.Parent           = ToggleContainer
    makeCorner(button, 9)

    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.new(1, -45, 1, 0)
    label.Position               = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text                   = name
    label.TextColor3             = Color3.fromRGB(235, 235, 235)
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 15
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.ZIndex                 = 105
    label.Parent                 = button

    local indicator = Instance.new("Frame")
    indicator.Size             = UDim2.fromOffset(9, 9)
    indicator.Position         = UDim2.new(1, -23, 0.5, -4.5)
    indicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    indicator.BorderSizePixel  = 0
    indicator.ZIndex           = 105
    indicator.Parent           = button
    makeCorner(indicator, 5)

    local function updateVisual()
        indicator.BackgroundColor3 = getState()
            and Color3.fromRGB(0, 190, 85)
            or Color3.fromRGB(100, 100, 100)
    end

    button.MouseButton1Click:Connect(function()
        setState(not getState())
        updateVisual()
        updateAllSubToggles()
        saveSettings(Settings)
    end)

    updateVisual()
    return button
end

local function createChildGroup(masterGetter, order)
    local group = Instance.new("Frame")
    group.Size                   = UDim2.new(1, -8, 0, 0)
    group.BackgroundTransparency = 1
    group.BorderSizePixel        = 0
    group.AutomaticSize          = Enum.AutomaticSize.Y
    group.LayoutOrder            = order
    group.ZIndex                 = 103
    group.Parent                 = ToggleContainer

    local branch = Instance.new("Frame")
    branch.Size             = UDim2.new(0, 2, 1, 0)
    branch.Position         = UDim2.new(0, 22, 0, 0)
    branch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    branch.BorderSizePixel  = 0
    branch.ZIndex           = 104
    branch.Parent           = group
    makeCorner(branch, 1)

    local content = Instance.new("Frame")
    content.Size                   = UDim2.new(1, -48, 0, 0)
    content.Position               = UDim2.new(0, 42, 0, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel        = 0
    content.AutomaticSize          = Enum.AutomaticSize.Y
    content.ZIndex                 = 105
    content.Parent                 = group

    local layout = Instance.new("UIListLayout")
    layout.Padding   = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent    = content

    return { Group = group, Branch = branch, Content = content, MasterGetter = masterGetter }
end

local function createChildToggle(name, getState, setState, masterGetter, list, parentGroup, order)
    local button = Instance.new("TextButton")
    button.Size             = UDim2.new(1, 0, 0, 32)
    button.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
    button.BorderSizePixel  = 0
    button.Text             = ""
    button.AutoButtonColor  = false
    button.LayoutOrder      = order
    button.ZIndex           = 105
    button.Parent           = parentGroup.Content
    makeCorner(button, 8)

    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.new(1, -42, 1, 0)
    label.Position               = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text                   = name
    label.TextColor3             = Color3.fromRGB(205, 205, 205)
    label.Font                   = Enum.Font.GothamMedium
    label.TextSize               = 13
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.ZIndex                 = 106
    label.Parent                 = button

    local indicator = Instance.new("Frame")
    indicator.Size             = UDim2.fromOffset(8, 8)
    indicator.Position         = UDim2.new(1, -20, 0.5, -4)
    indicator.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
    indicator.BorderSizePixel  = 0
    indicator.ZIndex           = 106
    indicator.Parent           = button
    makeCorner(indicator, 4)

    local function updateVisual()
        if not masterGetter() then
            button.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
            label.TextColor3        = Color3.fromRGB(65, 65, 65)
            indicator.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            parentGroup.Branch.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        else
            button.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
            label.TextColor3        = Color3.fromRGB(205, 205, 205)
            indicator.BackgroundColor3 = getState()
                and Color3.fromRGB(0, 190, 85)
                or Color3.fromRGB(95, 95, 95)
            parentGroup.Branch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end

    button.MouseButton1Click:Connect(function()
        if not masterGetter() then return end
        setState(not getState())
        updateVisual()
        saveSettings(Settings)
    end)

    updateVisual()
    table.insert(list, updateVisual)
    return button
end

local function createChildSlider(name, minVal, maxVal, getValue, setValue, masterGetter, parentGroup, order)
    local wrapper = Instance.new("Frame")
    wrapper.Size                   = UDim2.new(1, 0, 0, 47)
    wrapper.BackgroundTransparency = 1
    wrapper.BorderSizePixel        = 0
    wrapper.LayoutOrder            = order
    wrapper.ZIndex                 = 105
    wrapper.Parent                 = parentGroup.Content

    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text                   = name .. ": " .. tostring(getValue())
    label.TextColor3             = Color3.fromRGB(205, 205, 205)
    label.Font                   = Enum.Font.GothamMedium
    label.TextSize               = 13
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.ZIndex                 = 106
    label.Parent                 = wrapper

    local sliderLine = Instance.new("Frame")
    sliderLine.Size             = UDim2.new(1, -12, 0, 4)
    sliderLine.Position         = UDim2.new(0, 6, 0, 29)
    sliderLine.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    sliderLine.BorderSizePixel  = 0
    sliderLine.ZIndex           = 105
    sliderLine.Parent           = wrapper
    makeCorner(sliderLine, 2)

    local handle = Instance.new("TextButton")
    handle.Size             = UDim2.fromOffset(16, 16)
    handle.Position         = UDim2.new(0, -8, 0, 23)
    handle.BackgroundColor3 = Color3.fromRGB(170, 170, 170)
    handle.BorderSizePixel  = 0
    handle.Text             = ""
    handle.AutoButtonColor  = false
    handle.ZIndex           = 107
    handle.Parent           = wrapper
    makeCorner(handle, 8)

    local dragging = false

    local function updateVisual()
        if masterGetter() then
            label.TextColor3        = Color3.fromRGB(205, 205, 205)
            sliderLine.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
            handle.BackgroundColor3 = Color3.fromRGB(175, 175, 175)
            parentGroup.Branch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        else
            label.TextColor3        = Color3.fromRGB(65, 65, 65)
            sliderLine.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            handle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            parentGroup.Branch.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        end
    end

    local function updatePosition()
        local w = sliderLine.AbsoluteSize.X
        if w > 0 then
            local alpha = math.clamp((getValue() - minVal) / (maxVal - minVal), 0, 1)
            handle.Position = UDim2.new(0, alpha * w - 8, 0, 23)
        end
        label.Text = name .. ": " .. tostring(getValue())
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and masterGetter() then
            dragging = true
        end
    end)

    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    trackConn(UserInputService.InputChanged:Connect(function(input)
        if not dragging or not masterGetter() then
            dragging = false
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local startX = sliderLine.AbsolutePosition.X
            local w = sliderLine.AbsoluteSize.X
            if w > 0 then
                local rel = math.clamp(input.Position.X - startX, 0, w)
                local raw = minVal + (rel / w) * (maxVal - minVal)
                local step = (maxVal - minVal) >= 100 and 5 or 1
                local snapped = math.floor((raw + step / 2) / step) * step
                setValue(math.clamp(snapped, minVal, maxVal))
                label.Text = name .. ": " .. tostring(getValue())
                handle.Position = UDim2.new(0, rel - 8, 0, 23)
                saveSettings(Settings)
            end
        end
    end))

    task.defer(updatePosition)
    task.defer(updateVisual)

    return wrapper, updateVisual, updatePosition
end

-- build toggles

createMasterToggle("Triggerbot",
    function() return Settings.Triggerbot_Enabled end,
    function(v) Settings.Triggerbot_Enabled = v end, 1)

createMasterToggle("Inf Jump",
    function() return Settings.InfJump_Enabled end,
    function(v) Settings.InfJump_Enabled = v end, 2)

createMasterToggle("ESP",
    function() return Settings.ESP_Enabled end,
    function(v) Settings.ESP_Enabled = v end, 3)

local espGroup = createChildGroup(
    function() return Settings.ESP_Enabled end, 4)

createChildToggle("Highlight",
    function() return Settings.ESP_Highlight end,
    function(v) Settings.ESP_Highlight = v end,
    function() return Settings.ESP_Enabled end,
    espChildren, espGroup, 1)

createChildToggle("Name",
    function() return Settings.ESP_Name end,
    function(v) Settings.ESP_Name = v end,
    function() return Settings.ESP_Enabled end,
    espChildren, espGroup, 2)

createChildToggle("Distance",
    function() return Settings.ESP_Studs end,
    function(v) Settings.ESP_Studs = v end,
    function() return Settings.ESP_Enabled end,
    espChildren, espGroup, 3)

createChildToggle("Health Bar",
    function() return Settings.ESP_HealthBar end,
    function(v) Settings.ESP_HealthBar = v end,
    function() return Settings.ESP_Enabled end,
    espChildren, espGroup, 4)

createChildToggle("Tracer",
    function() return Settings.ESP_Tracer end,
    function(v) Settings.ESP_Tracer = v end,
    function() return Settings.ESP_Enabled end,
    espChildren, espGroup, 5)

createMasterToggle("Aimbot",
    function() return Settings.Aimbot_Enabled end,
    function(v) Settings.Aimbot_Enabled = v end, 5)

local aimbotGroup = createChildGroup(
    function() return Settings.Aimbot_Enabled end, 6)

createChildToggle("Wall Check",
    function() return Settings.Aimbot_WallCheck end,
    function(v) Settings.Aimbot_WallCheck = v end,
    function() return Settings.Aimbot_Enabled end,
    aimbotChildren, aimbotGroup, 1)

createChildToggle("Team Check",
    function() return Settings.Aimbot_TeamCheck end,
    function(v) Settings.Aimbot_TeamCheck = v end,
    function() return Settings.Aimbot_Enabled end,
    aimbotChildren, aimbotGroup, 2)

local _, fovVisual, fovPosition = createChildSlider(
    "FOV", 20, 500,
    function() return Settings.Aimbot_FOVRadius end,
    function(v) Settings.Aimbot_FOVRadius = v end,
    function() return Settings.Aimbot_Enabled end,
    aimbotGroup, 3)

updateFOVVisual   = fovVisual
updateFOVPosition = fovPosition
table.insert(aimbotChildren, updateFOVVisual)

createMasterToggle("Speed",
    function() return Settings.Speed_Enabled end,
    function(v) Settings.Speed_Enabled = v end, 7)

local speedGroup = createChildGroup(
    function() return Settings.Speed_Enabled end, 8)

createChildSlider("Speed", 16, 200,
    function() return Settings.Speed_Value end,
    function(v) Settings.Speed_Value = v end,
    function() return Settings.Speed_Enabled end,
    speedGroup, 1)

createMasterToggle("Fly",
    function() return Settings.Fly_Enabled end,
    function(v) Settings.Fly_Enabled = v end, 9)

local flyGroup = createChildGroup(
    function() return Settings.Fly_Enabled end, 10)

createChildSlider("Fly Speed", 10, 300,
    function() return Settings.Fly_Speed end,
    function(v) Settings.Fly_Speed = v end,
    function() return Settings.Fly_Enabled end,
    flyGroup, 1)

createMasterToggle("Noclip",
    function() return Settings.Noclip_Enabled end,
    function(v) Settings.Noclip_Enabled = v end, 11)

createMasterToggle("Fullbright",
    function() return Settings.Fullbright_Enabled end,
    function(v) Settings.Fullbright_Enabled = v end, 12)

createMasterToggle("Anti-AFK",
    function() return Settings.AntiAFK_Enabled end,
    function(v) Settings.AntiAFK_Enabled = v end, 13)

createMasterToggle("Hitbox Expander",
    function() return Settings.HitboxExpander_Enabled end,
    function(v) Settings.HitboxExpander_Enabled = v end, 14)

local hitboxGroup = createChildGroup(
    function() return Settings.HitboxExpander_Enabled end, 15)

createChildSlider("Hitbox Size", 1, 20,
    function() return Settings.HitboxExpander_Size end,
    function(v) Settings.HitboxExpander_Size = v end,
    function() return Settings.HitboxExpander_Enabled end,
    hitboxGroup, 1)

createMasterToggle("Camera FOV",
    function() return Settings.CameraFOV_Enabled end,
    function(v) Settings.CameraFOV_Enabled = v end, 16)

local camFovGroup = createChildGroup(
    function() return Settings.CameraFOV_Enabled end, 17)

createChildSlider("FOV Value", 30, 120,
    function() return Settings.CameraFOV_Value end,
    function(v) Settings.CameraFOV_Value = v end,
    function() return Settings.CameraFOV_Enabled end,
    camFovGroup, 1)

updateAllSubToggles()

task.defer(function()
    task.wait(0.1)
    local h = ToggleContainer.AbsoluteSize.Y
    if h > 0 then
        MenuFrame.Size = UDim2.new(0, 390, 0, 70 + h + 15)
        updateKillButtonPosition()
    end
end)

-- team helpers

local teamCache, teamCacheTime = {}, {}
local TEAM_CACHE_DURATION = 0.15

local function normalizeTeamValue(value)
    if value == nil then return nil end
    local t = typeof(value)
    if t == "Instance" then return value end
    if t == "Color3" then
        return string.format("color:%.4f:%.4f:%.4f", value.R, value.G, value.B)
    end
    if t == "BrickColor" then return "brick:" .. value.Name end
    if t == "string" then return value ~= "" and ("string:" .. value) or nil end
    if t == "number" then return "number:" .. tostring(value) end
    if t == "boolean" then return "boolean:" .. tostring(value) end
    return nil
end

local function isTeamName(name)
    if typeof(name) ~= "string" then return false end
    local lowered = string.gsub(string.lower(name), "[%s_%-]", "")
    return lowered == "team" or lowered == "teamid"
        or lowered == "teamidentifier" or lowered == "teamindex"
        or lowered == "teamcolor" or lowered == "teamcolour"
        or string.find(lowered, "teamid", 1, true) ~= nil
end

local function getTeamFromAttributes(container)
    if not container then return nil end
    local ok, attrs = pcall(function() return container:GetAttributes() end)
    if not ok or not attrs then return nil end
    for name, value in pairs(attrs) do
        if isTeamName(name) then
            local n = normalizeTeamValue(value)
            if n ~= nil then return n end
        end
    end
    return nil
end

local function getTeamFromValues(container)
    if not container then return nil end
    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return nil end
    for _, obj in ipairs(children) do
        if isTeamName(obj.Name) then
            local n = normalizeTeamValue(obj.Value)
            if n then return n end
        end
    end
    return nil
end

local function getTeamSignature(player)
    if not player then return nil end
    local now = os.clock()
    if teamCache[player] ~= nil and teamCacheTime[player]
    and now - teamCacheTime[player] < TEAM_CACHE_DURATION then
        return teamCache[player]
    end

    local sig = player.Team
        or getTeamFromAttributes(player)
        or getTeamFromValues(player)
        or (player.Character and getTeamFromAttributes(player.Character))
        or (player.Character and getTeamFromValues(player.Character))

    if not sig then
        local ok, tc = pcall(function() return player.TeamColor end)
        if ok and tc and tc.Name ~= "Medium stone grey" then
            sig = "brick:" .. tc.Name
        end
    end

    teamCache[player]     = sig
    teamCacheTime[player] = now
    return sig
end

local function clearTeamCache(player)
    teamCache[player]     = nil
    teamCacheTime[player] = nil
end

trackConn(Players.PlayerAdded:Connect(function(player)
    clearTeamCache(player)
    trackConn(player:GetPropertyChangedSignal("Team"):Connect(
        function() clearTeamCache(player) end))
    trackConn(player:GetPropertyChangedSignal("TeamColor"):Connect(
        function() clearTeamCache(player) end))
    trackConn(player.CharacterAdded:Connect(function() clearTeamCache(player) end))
end))

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        trackConn(player:GetPropertyChangedSignal("Team"):Connect(
            function() clearTeamCache(player) end))
        trackConn(player:GetPropertyChangedSignal("TeamColor"):Connect(
            function() clearTeamCache(player) end))
        trackConn(player.CharacterAdded:Connect(function() clearTeamCache(player) end))
    end
end

trackConn(Players.PlayerRemoving:Connect(function(player)
    clearTeamCache(player)
end))

local function isTeammate(player)
    if not player or player == LocalPlayer then return true end

    if Settings.Aimbot_TeamCheck then
        local ok1, lTeam = pcall(function() return LocalPlayer.Team end)
        local ok2, pTeam = pcall(function() return player.Team end)
        if ok1 and ok2 and lTeam and pTeam then
            return lTeam == pTeam
        end

        local ls = getTeamSignature(LocalPlayer)
        local ts = getTeamSignature(player)
        if ls ~= nil and ts ~= nil then
            if typeof(ls) == "Instance" and typeof(ts) == "Instance" then
                return ls == ts
            end
            return tostring(ls) == tostring(ts)
        end

        local ok3, ltc = pcall(function() return LocalPlayer.TeamColor end)
        local ok4, ptc = pcall(function() return player.TeamColor end)
        if ok3 and ok4 and ltc and ptc then
            if ltc.Name ~= "Medium stone grey"
            and ptc.Name ~= "Medium stone grey" then
                return ltc.Name == ptc.Name
            end
        end
    end

    return false
end

local function isEnemy(player)
    if not player or player == LocalPlayer then return false end
    return not isTeammate(player)
end

local cachedEnemies, enemyCacheTime = {}, 0
local ENEMY_CACHE_TTL = 0.08

local function getEnemies()
    local now = os.clock()
    if now - enemyCacheTime < ENEMY_CACHE_TTL then
        return cachedEnemies
    end
    local result = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isEnemy(player) then
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                table.insert(result, player)
            end
        end
    end
    cachedEnemies  = result
    enemyCacheTime = now
    return result
end

local function getCrosshairPosition()
    if not Camera then return Vector2.new(0, 0) end
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X / 2, vp.Y / 2)
    end
    return UserInputService:GetMouseLocation()
end

local function worldToScreen(pos)
    if not Camera then return nil, false end
    local ok, r = pcall(function() return Camera:WorldToScreenPoint(pos) end)
    if not ok or not r then return nil, false end
    return Vector2.new(r.X, r.Y), r.Z > 0
end

local sharedRaycastParams = RaycastParams.new()
sharedRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
local raycastBlacklistDirty = true
local raycastBlacklistTime  = 0

trackConn(Players.PlayerRemoving:Connect(function()
    enemyCacheTime = 0; raycastBlacklistDirty = true
end))
trackConn(Players.PlayerAdded:Connect(function()
    enemyCacheTime = 0; raycastBlacklistDirty = true
end))

local function getSharedRaycastParams(targetCharacter)
    local now = os.clock()
    if raycastBlacklistDirty or now - raycastBlacklistTime > 0.5 then
        local bl = {}
        if LocalPlayer.Character then
            table.insert(bl, LocalPlayer.Character)
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character ~= targetCharacter then
                table.insert(bl, p.Character)
            end
        end
        sharedRaycastParams.FilterDescendantsInstances = bl
        raycastBlacklistDirty = false
        raycastBlacklistTime  = now
    end
    return sharedRaycastParams
end

local function hasLineOfSight(targetPart)
    if not targetPart or not Camera then return false end
    local parent = targetPart.Parent
    if not parent then return false end
    local camPos = Camera.CFrame.Position
    local ok_pos, targetPos = pcall(function() return targetPart.Position end)
    if not ok_pos then return false end
    local offset = targetPos - camPos
    local dist   = offset.Magnitude
    if dist <= 0 then return false end
    local ok, result = pcall(function()
        return workspace:Raycast(camPos, offset.Unit * dist,
            getSharedRaycastParams(parent))
    end)
    if not ok then return true end
    if not result or not result.Instance then return true end
    return result.Instance:IsDescendantOf(parent)
end

-- Inf jump

trackConn(UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump_Enabled then
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end))

-- Aimbot

local lockedTarget = nil

local function getAimTarget()
    local crosshair = getCrosshairPosition()
    local lc = LocalPlayer.Character
    if not lc then return nil end
    local lr = lc:FindFirstChild("HumanoidRootPart")
    if not lr then return nil end

    if lockedTarget then
        if not isEnemy(lockedTarget) then
            lockedTarget = nil
        else
            local c = lockedTarget.Character
            local head = c and c:FindFirstChild("Head")
            local h    = c and c:FindFirstChildOfClass("Humanoid")
            if head and h and h.Health > 0 then
                local d = (lr.Position - head.Position).Magnitude
                if d > Settings.Triggerbot_MaxDistance then
                    lockedTarget = nil
                elseif Settings.Aimbot_WallCheck and not hasLineOfSight(head) then
                    lockedTarget = nil
                else
                    return head
                end
            else
                lockedTarget = nil
            end
        end
    end

    local best, bestDist = nil, math.huge

    for _, player in ipairs(getEnemies()) do
        local c = player.Character
        if c then
            local head = c:FindFirstChild("Head")
            if head then
                local d3 = (lr.Position - head.Position).Magnitude
                if d3 <= Settings.Triggerbot_MaxDistance then
                    local sp, onScreen = worldToScreen(head.Position)
                    if sp and onScreen then
                        local d2 = (sp - crosshair).Magnitude
                        if d2 <= Settings.Aimbot_FOVRadius then
                            if not Settings.Aimbot_WallCheck or hasLineOfSight(head) then
                                if d2 < bestDist then
                                    bestDist = d2
                                    best     = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if best then
        lockedTarget = best
        return best.Character:FindFirstChild("Head")
    end
    return nil
end

local function forceAimAtHead(head)
    if not head or not head.Parent or not Camera then return false end
    local c = LocalPlayer.Character
    if not c then return false end
    local rp = c:FindFirstChild("HumanoidRootPart")
    if not rp then return false end

    local ok, headPos = pcall(function() return head.Position end)
    if not ok then return false end

    local camPos = Camera.CFrame.Position
    Camera.CFrame = CFrame.lookAt(camPos, headPos, Vector3.new(0, 1, 0))

    local rootPos = rp.Position
    rp.CFrame = CFrame.lookAt(rootPos,
        Vector3.new(headPos.X, rootPos.Y, headPos.Z),
        Vector3.new(0, 1, 0))
    return true
end

local function updateLockedBody()
    if not Settings.Aimbot_Enabled or not lockedTarget then return end
    if not isEnemy(lockedTarget) then lockedTarget = nil; return end

    local c = lockedTarget.Character
    local head = c and c:FindFirstChild("Head")
    local h    = c and c:FindFirstChildOfClass("Humanoid")

    if not c or not head or not h or h.Health <= 0 then
        lockedTarget = nil
        return
    end

    local lc = LocalPlayer.Character
    if lc then
        local lr = lc:FindFirstChild("HumanoidRootPart")
        if lr then
            local ok, hp = pcall(function() return head.Position end)
            if ok and (lr.Position - hp).Magnitude > Settings.Triggerbot_MaxDistance then
                lockedTarget = nil
                return
            end
        end
    end

    if Settings.Aimbot_WallCheck and not hasLineOfSight(head) then
        lockedTarget = nil
        return
    end

    forceAimAtHead(head)
end

local HITBOX_PARTS = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
}

local function getHitboxScreenBounds(part)
    if not Camera or not part or not part.Parent then return nil end
    local ok, cf, size = pcall(function()
        return part.CFrame, part.Size * 0.5
    end)
    if not ok or not cf or not size then return nil end

    local sx, sy, sz = size.X, size.Y, size.Z
    local corners = {
        cf * Vector3.new( sx,  sy,  sz),
        cf * Vector3.new(-sx,  sy,  sz),
        cf * Vector3.new( sx, -sy,  sz),
        cf * Vector3.new(-sx, -sy,  sz),
        cf * Vector3.new( sx,  sy, -sz),
        cf * Vector3.new(-sx,  sy, -sz),
        cf * Vector3.new( sx, -sy, -sz),
        cf * Vector3.new(-sx, -sy, -sz),
    }

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyOnScreen = false

    for _, corner in ipairs(corners) do
        local ok2, r = pcall(function() return Camera:WorldToScreenPoint(corner) end)
        if ok2 and r and r.Z > 0 then
            anyOnScreen = true
            if r.X < minX then minX = r.X end
            if r.Y < minY then minY = r.Y end
            if r.X > maxX then maxX = r.X end
            if r.Y > maxY then maxY = r.Y end
        end
    end

    if not anyOnScreen then return nil end
    return minX, minY, maxX, maxY
end

local function shouldFire()
    if not Camera then return false end

    if Settings.Aimbot_Enabled and lockedTarget and isEnemy(lockedTarget) then
        local c = lockedTarget.Character
        local head = c and c:FindFirstChild("Head")
        local h    = c and c:FindFirstChildOfClass("Humanoid")
        if head and h and h.Health > 0 then
            if hasLineOfSight(head) then
                if forceAimAtHead(head) then return true end
            else
                lockedTarget = nil
            end
        else
            lockedTarget = nil
        end
    end

    if not Settings.Triggerbot_Enabled then return false end

    local crosshair = getCrosshairPosition()
    local cx, cy = crosshair.X, crosshair.Y
    local camPos = Camera.CFrame.Position

    for _, player in ipairs(getEnemies()) do
        local c = player.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                local root = c:FindFirstChild("HumanoidRootPart")
                if root and root.Parent then
                    local ok_rp, rootPos = pcall(function() return root.Position end)
                    if ok_rp and (rootPos - camPos).Magnitude
                            <= Settings.Triggerbot_MaxDistance then
                        for _, partName in ipairs(HITBOX_PARTS) do
                            local part = c:FindFirstChild(partName)
                            if part and hasLineOfSight(part) then
                                local minX, minY, maxX, maxY =
                                    getHitboxScreenBounds(part)
                                if minX and cx >= minX and cx <= maxX
                                and cy >= minY and cy <= maxY then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

-- Tracers

local function getTracerLine(player)
    if tracerLines[player] then return tracerLines[player] end
    local ok, r = pcall(function()
        local d = Drawing.new("Line")
        d.Thickness = 1.5
        d.Color = Color3.fromRGB(255, 255, 255)
        d.Transparency = 1
        d.Visible = false
        return d
    end)
    if ok and r then
        tracerLines[player] = r
        return r
    end
    return nil
end

local function removeTracerLine(player)
    local line = tracerLines[player]
    if line then
        tracerLines[player] = nil
        pcall(function()
            line.Visible = false
            line:Remove()
        end)
    end
end

local function hideTracerLines()
    for _, line in pairs(tracerLines) do
        pcall(function() line.Visible = false end)
    end
end

trackConn(Players.PlayerRemoving:Connect(function(player)
    removeTracerLine(player)
    clearTeamCache(player)
    enemyCacheTime = 0
    raycastBlacklistDirty = true
end))

local function updateTracer()
    if not Settings.ESP_Enabled or not Settings.ESP_Tracer
    or MenuFrame.Visible then
        hideTracerLines()
        return
    end

    local lc = LocalPlayer.Character
    local lr = lc and lc:FindFirstChild("HumanoidRootPart")
    if not lr or not Camera then
        hideTracerLines()
        return
    end

    local vp = Camera.ViewportSize
    local origin = Vector2.new(vp.X / 2, vp.Y / 2)
    local seen = {}

    for _, player in ipairs(getEnemies()) do
        local c = player.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if h and h.Health > 0 and r then
            local ok_rp, rootPos = pcall(function() return r.Position end)
            if ok_rp and (rootPos - lr.Position).Magnitude <= 1000 then
                local head = c:FindFirstChild("Head")
                local ok_hp, targetPos = pcall(function()
                    return head and head.Position or r.Position
                end)
                if ok_hp then
                    local ok_sp, sp = pcall(function()
                        return Camera:WorldToViewportPoint(targetPos)
                    end)
                    if ok_sp and sp.Z > 0 then
                        local line = getTracerLine(player)
                        if line then
                            line.From = origin
                            line.To = Vector2.new(sp.X, sp.Y)
                            line.Visible = true
                            seen[player] = true
                        end
                    end
                end
            end
        end
    end

    for player, line in pairs(tracerLines) do
        if not seen[player] then
            pcall(function() line.Visible = false end)
        end
    end
end

pcall(function()
    if Drawing then
        circleDraw = Drawing.new("Circle")
        circleDraw.Thickness = 2
        circleDraw.Color = Color3.fromRGB(255, 0, 0)
        circleDraw.Filled = false
        circleDraw.Visible = false
    end
end)

local function updateCircle()
    if not circleDraw then return end
    if Settings.Aimbot_Enabled and not MenuFrame.Visible then
        circleDraw.Position = getCrosshairPosition()
        circleDraw.Radius   = Settings.Aimbot_FOVRadius
        circleDraw.Visible  = true
    else
        circleDraw.Visible = false
    end
end

-- Menu open/close

local tabHeld = false

local function holdTab()
    if not tabHeld then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Tab, false, game)
        tabHeld = true
    end
end

local function releaseTab()
    if tabHeld then
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Tab, false, game)
        tabHeld = false
    end
end

local AutoclickActive = false

local function closeMenu()
    if not MenuFrame.Visible then return end
    MenuFrame.Visible       = false
    BackgroundFrame.Visible = false
    KillButton.Visible      = false
    AutoclickActive         = false
    releaseTab()
end

local function openMenu()
    if MenuFrame.Visible then return end
    MenuFrame.Visible       = true
    BackgroundFrame.Visible = true
    lockedTarget            = nil
    AutoclickActive         = false
    hideTracerLines()
    updateAllSubToggles()
    recalcMenuHeight()
    holdTab()
    task.defer(updateKillButtonPosition)
end

trackConn(UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightControl then
        if MenuFrame.Visible then closeMenu() else openMenu() end
        return
    end

    if not MenuFrame.Visible then return end

    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local mfPos, mfSize = MenuFrame.AbsolutePosition, MenuFrame.AbsoluteSize
    local clickX, clickY = input.Position.X, input.Position.Y

    local insideMenu = clickX >= mfPos.X and clickX <= mfPos.X + mfSize.X
        and clickY >= mfPos.Y and clickY <= mfPos.Y + mfSize.Y

    local kbPos, kbSize = KillButton.AbsolutePosition, KillButton.AbsoluteSize
    local insideKill = clickX >= kbPos.X and clickX <= kbPos.X + kbSize.X
        and clickY >= kbPos.Y and clickY <= kbPos.Y + kbSize.Y

    if not insideMenu and not insideKill then
        closeMenu()
    end
end))

if isMobile then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name           = "UniversalMobile"
    mobileGui.ResetOnSpawn   = false
    mobileGui.IgnoreGuiInset = true
    mobileGui.DisplayOrder   = 1001
    mobileGui.Parent         = LocalPlayer:WaitForChild("PlayerGui")

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size             = UDim2.fromOffset(44, 44)
    toggleBtn.Position         = UDim2.new(1, -60, 1, -60)
    toggleBtn.AnchorPoint      = Vector2.new(1, 1)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    toggleBtn.BorderSizePixel  = 0
    toggleBtn.Text             = "<>"
    toggleBtn.TextColor3       = Color3.fromRGB(210, 210, 210)
    toggleBtn.Font             = Enum.Font.GothamBold
    toggleBtn.TextSize         = 14
    toggleBtn.AutoButtonColor  = false
    toggleBtn.ZIndex           = 200
    toggleBtn.Parent           = mobileGui
    makeCorner(toggleBtn, 12)

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color        = Color3.fromRGB(55, 55, 55)
    btnStroke.Thickness    = 1
    btnStroke.Transparency = 0.2
    btnStroke.Parent       = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        if MenuFrame.Visible then closeMenu() else openMenu() end
    end)
end

-- ESP

local function removeESPObjects(character)
    if not character then return end
    for _, name in ipairs({
        "ESP_Highlight", "ESP_Billboard",
        "ESP_HealthBar", "HealthBackground", "HealthOutline"
    }) do
        local obj = character:FindFirstChild(name)
        if obj then obj:Destroy() end
    end
end

local ESP_GUI_WIDTH     = 220
local ESP_GUI_HEIGHT    = 58
local HEALTH_BAR_WIDTH  = 120
local HEALTH_BAR_HEIGHT = 7

local function createESPBillboard(character, head)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = Settings.ESP_MaxDistance
    bb.Size = UDim2.fromOffset(ESP_GUI_WIDTH, ESP_GUI_HEIGHT)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 2.7, 0)
    bb.ClipsDescendants = false
    bb.Parent = character

    local healthOutline = Instance.new("Frame")
    healthOutline.Name = "HealthOutline"
    healthOutline.Position = UDim2.fromOffset(
        (ESP_GUI_WIDTH - HEALTH_BAR_WIDTH) / 2 - 1, 1)
    healthOutline.Size = UDim2.fromOffset(
        HEALTH_BAR_WIDTH + 2, HEALTH_BAR_HEIGHT + 2)
    healthOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthOutline.BackgroundTransparency = 0.15
    healthOutline.BorderSizePixel = 0
    healthOutline.ZIndex = 5
    healthOutline.Parent = bb
    makeCorner(healthOutline, 4)

    local healthBackground = Instance.new("Frame")
    healthBackground.Name = "HealthBackground"
    healthBackground.Position = UDim2.fromOffset(1, 1)
    healthBackground.Size = UDim2.fromOffset(
        HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
    healthBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    healthBackground.BorderSizePixel = 0
    healthBackground.ZIndex = 6
    healthBackground.Parent = healthOutline
    makeCorner(healthBackground, 3)

    local healthBar = Instance.new("Frame")
    healthBar.Name = "ESP_HealthBar"
    healthBar.Size = UDim2.fromOffset(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
    healthBar.BorderSizePixel = 0
    healthBar.ZIndex = 7
    healthBar.Parent = healthBackground
    makeCorner(healthBar, 3)

    local info = Instance.new("TextLabel")
    info.Name = "ESP_Info"
    info.Position = UDim2.fromOffset(0, 14)
    info.Size = UDim2.fromOffset(ESP_GUI_WIDTH, 22)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.GothamBold
    info.TextSize = 14
    info.TextColor3 = Color3.fromRGB(255, 255, 255)
    info.TextStrokeTransparency = 0.45
    info.TextXAlignment = Enum.TextXAlignment.Center
    info.TextYAlignment = Enum.TextYAlignment.Center
    info.Text = ""
    info.ZIndex = 8
    info.Parent = bb

    return bb
end

local function updateESP()
    if not Settings.ESP_Enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                removeESPObjects(player.Character)
            end
        end
        return
    end

    local lc = LocalPlayer.Character
    local lr = lc and lc:FindFirstChild("HumanoidRootPart")
    if not lr or not Camera then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local c = player.Character
            if c then
                if not isEnemy(player) then
                    removeESPObjects(c)
                else
                    local h    = c:FindFirstChildOfClass("Humanoid")
                    local root = c:FindFirstChild("HumanoidRootPart")
                    local head = c:FindFirstChild("Head")
                    if not h or h.Health <= 0 or not root or not head then
                        removeESPObjects(c)
                    else
                        local ok_rp, rootPos = pcall(function() return root.Position end)
                        if not ok_rp then
                            removeESPObjects(c)
                        else
                            local d = (rootPos - lr.Position).Magnitude
                            if d > Settings.ESP_MaxDistance then
                                removeESPObjects(c)
                            else
                                local hl = c:FindFirstChild("ESP_Highlight")
                                if Settings.ESP_Highlight then
                                    if not hl then
                                        hl = Instance.new("Highlight")
                                        hl.Name = "ESP_Highlight"
                                        hl.Adornee = c
                                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                        hl.Parent = c
                                    end
                                    hl.FillColor = ESP_COLOR
                                    hl.FillTransparency = Settings.ESP_BoxTransparency
                                    hl.OutlineColor = ESP_COLOR
                                    hl.OutlineTransparency = 0
                                    hl.Enabled = true
                                elseif hl then
                                    hl:Destroy()
                                end

                                local bb = c:FindFirstChild("ESP_Billboard")
                                if not bb or not bb:IsA("BillboardGui") then
                                    if bb then bb:Destroy() end
                                    bb = createESPBillboard(c, head)
                                end

                                bb.Adornee = head
                                bb.Enabled = true
                                bb.MaxDistance = Settings.ESP_MaxDistance

                                local ho = bb:FindFirstChild("HealthOutline")
                                local hb = ho and ho:FindFirstChild("HealthBackground")
                                local bar = hb and hb:FindFirstChild("ESP_HealthBar")

                                if not ho or not hb or not bar then
                                    bb:Destroy()
                                    bb = createESPBillboard(c, head)
                                    ho = bb:FindFirstChild("HealthOutline")
                                    hb = ho and ho:FindFirstChild("HealthBackground")
                                    bar = hb and hb:FindFirstChild("ESP_HealthBar")
                                end

                                if bar then
                                    ho.Visible = Settings.ESP_HealthBar
                                    local pct = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
                                    bar.Size = UDim2.fromOffset(
                                        math.max(0, math.floor(HEALTH_BAR_WIDTH * pct)),
                                        HEALTH_BAR_HEIGHT)
                                    if pct > 0.6 then
                                        bar.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
                                    elseif pct > 0.3 then
                                        bar.BackgroundColor3 = Color3.fromRGB(255, 190, 0)
                                    else
                                        bar.BackgroundColor3 = Color3.fromRGB(235, 45, 45)
                                    end
                                end

                                local info = bb:FindFirstChild("ESP_Info")
                                if info then
                                    local parts = {}
                                    if Settings.ESP_Name  then table.insert(parts, player.Name) end
                                    if Settings.ESP_Studs then
                                        table.insert(parts, string.format("%.1f studs", d))
                                    end
                                    if #parts > 0 then
                                        info.Text = table.concat(parts, " | ")
                                        info.Visible = true
                                    else
                                        info.Text = ""
                                        info.Visible = false
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Movement / character effects

local flyBodyVel, flyGyro, flyActive = nil, nil, false
local flyBV, flyBG
local noclippedParts = {}

local function stopFly()
    flyActive = false
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
    flyBodyVel = nil
    flyGyro = nil
end

local function startFly()
    local c = LocalPlayer.Character
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart")
    local h    = c:FindFirstChildOfClass("Humanoid")
    if not root or not h then return end

    stopFly()

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 1000
    flyBG.D = 50
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root

    flyActive = true
end

local function updateFly()
    if not flyActive then return end
    local c = LocalPlayer.Character
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root or not flyBV or not flyBG then return end

    local cam = Camera
    if not cam then return end

    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

    if dir.Magnitude > 0 then
        dir = dir.Unit
    end

    flyBV.Velocity = dir * Settings.Fly_Speed
    flyBG.CFrame = cam.CFrame
end

local function updateSpeed()
    local c = LocalPlayer.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    if Settings.Speed_Enabled then
        h.WalkSpeed = Settings.Speed_Value
    else
        h.WalkSpeed = 16
    end
end

local function updateNoclip()
    local c = LocalPlayer.Character
    if not c then
        noclippedParts = {}
        return
    end

    if Settings.Noclip_Enabled then
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
                noclippedParts[part] = true
            end
        end
    else
        for part in pairs(noclippedParts) do
            if part and part.Parent then
                pcall(function() part.CanCollide = true end)
            end
        end
        noclippedParts = {}
    end
end

local savedLighting = {}

local function updateFullbright()
    if Settings.Fullbright_Enabled then
        if savedLighting.Brightness == nil then
            savedLighting.Brightness = Lighting.Brightness
            savedLighting.Ambient    = Lighting.Ambient
            savedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
            savedLighting.ClockTime  = Lighting.ClockTime
            savedLighting.FogEnd     = Lighting.FogEnd
        end
        Lighting.Brightness     = 2
        Lighting.Ambient        = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.ClockTime      = 14
        Lighting.FogEnd         = 1e6
    else
        if savedLighting.Brightness ~= nil then
            Lighting.Brightness     = savedLighting.Brightness
            Lighting.Ambient        = savedLighting.Ambient
            Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
            Lighting.ClockTime      = savedLighting.ClockTime
            Lighting.FogEnd         = savedLighting.FogEnd
            savedLighting = {}
        end
    end
end

local hitboxOriginalSizes = {}

local function updateHitboxExpander()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, partName in ipairs({"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}) do
                local part = player.Character:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    if Settings.HitboxExpander_Enabled then
                        if not hitboxOriginalSizes[part] then
                            hitboxOriginalSizes[part] = part.Size
                        end
                        local orig = hitboxOriginalSizes[part]
                        if Settings.HitboxExpander_Size > 1 then
                            part.Size = Vector3.new(
                                orig.X * Settings.HitboxExpander_Size,
                                orig.Y * Settings.HitboxExpander_Size,
                                orig.Z * Settings.HitboxExpander_Size)
                        end
                    else
                        if hitboxOriginalSizes[part] then
                            pcall(function() part.Size = hitboxOriginalSizes[part] end)
                            hitboxOriginalSizes[part] = nil
                        end
                    end
                end
            end
        end
    end
end

local function updateCameraFOV()
    if not Camera then return end
    if Settings.CameraFOV_Enabled then
        Camera.FieldOfView = Settings.CameraFOV_Value
    else
        Camera.FieldOfView = 70
    end
end

-- Anti AFK

task.spawn(function()
    while not _killed do
        task.wait(60)
        if Settings.AntiAFK_Enabled and VirtualUser then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- Autoclick loop

task.spawn(function()
    while not _killed do
        if AutoclickActive then
            if not Camera then Camera = workspace.CurrentCamera end
            if Camera then
                local vp = Camera.ViewportSize
                if vp then
                    VirtualInputManager:SendMouseButtonEvent(
                        vp.X / 2, vp.Y / 2, 0, true, game, 0)
                    VirtualInputManager:SendMouseButtonEvent(
                        vp.X / 2, vp.Y / 2, 0, false, game, 0)
                end
            end
        end
        task.wait()
    end
end)

-- Main render loop

local flyWasOn = false

trackConn(RunService.RenderStepped:Connect(function()
    if _killed then return end

    if not Camera then Camera = workspace.CurrentCamera end
    if not Camera then return end
    if not LocalPlayer.Character then return end

    updateCircle()
    updateTracer()

    if flyWasOn ~= Settings.Fly_Enabled then
        flyWasOn = Settings.Fly_Enabled
        if flyWasOn then startFly() else stopFly() end
    end
    if flyWasOn then updateFly() end

    updateSpeed()
    updateNoclip()

    if MenuFrame.Visible then
        AutoclickActive = false
        return
    end

    if Settings.Aimbot_Enabled then
        if lockedTarget then
            updateLockedBody()
        else
            local head = getAimTarget()
            if head then forceAimAtHead(head) end
        end
    else
        lockedTarget = nil
    end

    if Settings.Triggerbot_Enabled then
        AutoclickActive = shouldFire()
    else
        AutoclickActive = false
    end
end))

-- Periodic updates

task.spawn(function()
    while not _killed do
        task.wait(0.15)
        if not _killed then
            pcall(updateESP)
            pcall(updateHitboxExpander)
            pcall(updateFullbright)
            pcall(updateCameraFOV)
        end
    end
end)

-- Reset effects on respawn

trackConn(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    noclippedParts = {}
    hitboxOriginalSizes = {}
    stopFly()
    flyWasOn = false
end))

print("loaded. " .. (isMobile and "Tap <> to open" or "Right Control to open"))
