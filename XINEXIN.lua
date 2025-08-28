-- XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
-- Theme: Dark Yellow Premium
-- Font: Pixel (Arcade) Bold-styled
-- Window: Size UDim2.new(0, 735, 0, 379), Position UDim2.new(0.26607, 0, 0.26773, 0)
-- API:
--   UI.addPage(name)
--   UI.addNotify(message)
--   UI.addSelectPage(name)
--   UI.SetTheme(theme)               -- "DarkYellowPremium" or a table of colors
--   UI.Toggle()
-- Page:
--   Page.addSection(name)
--   Page.addResize(size)             -- Resizes main window to UDim2
-- Section:
--   Section:addButton(name, callback)
--   Section:addToggle(name, default, callback)
--   Section:addTextbox(name, default, callback)
--   Section:addKeybind(name, default, callback)  -- default: Enum.KeyCode or string name
--   Section:addColorPicker(name, default, callback) -- default Color3
--   Section:addSlider(name, min, max, default, callback)
--   Section:addDropdown(name, options, default, callback)
--   Section:Resize(size)             -- Resizes the section frame to UDim2

-- Single-file module export: return UI
-- Usage:
-- local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUser/YourRepo/main/xinexin_hub.lua"))()
-- local page = UI.addPage("Main")
-- local sec = page.addSection("Utilities")
-- sec:addButton("Hello", function() print("Hi") end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui") or Instance.new("PlayerGui", localPlayer)

-- Theme definition
local Themes = {
    DarkYellowPremium = {
        Background = Color3.fromRGB(15, 12, 5),
        Panel = Color3.fromRGB(26, 22, 12),
        Accent = Color3.fromRGB(235, 186, 22),
        AccentHover = Color3.fromRGB(255, 210, 40),
        Text = Color3.fromRGB(255, 255, 255),
        Muted = Color3.fromRGB(160, 140, 80),
        Outline = Color3.fromRGB(60, 50, 25),
        Shadow = Color3.fromRGB(0, 0, 0)
    }
}

-- Utils
local function tween(o, ti, props, es, ed)
    local info = TweenInfo.new(ti or 0.2, es or Enum.EasingStyle.Quad, ed or Enum.EasingDirection.Out)
    return TweenService:Create(o, info, props)
end

local function makeRound(frame, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = frame
    return c
end

local function makeStroke(frame, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = frame
    return s
end

local function makePadding(parent, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end

local function makeList(parent, dir, pad)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, pad or 6)
    l.Parent = parent
    return l
end

local function fontPixel(gui)
    -- Use Arcade as pixel-like bold font
    gui.Font = Enum.Font.Arcade
    gui.Text = gui.Text
end

local currentCamera = workspace.CurrentCamera

-- Library state
local UI = {}
UI.__index = UI

-- Internal registries for theme updates
local Registry = {
    Text = {},
    Panels = {},
    Accents = {},
    Strokes = {},
    MutedText = {},
    PageTabs = {},
    Window = nil,
    SectionPanels = {},
}
local AllConnections = {}

local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(AllConnections, c)
    return c
end

-- Build core GUI
local screen = Instance.new("ScreenGui")
screen.Name = "XINEXIN_HUB"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
screen.IgnoreGuiInset = true
screen.Parent = playerGui

-- Toggle icon (movable, shows/hides UI)
local toggleIcon = Instance.new("TextButton")
toggleIcon.Name = "Xinexin_Toggle"
toggleIcon.Size = UDim2.new(0, 44, 0, 44)
toggleIcon.Position = UDim2.new(1, -64, 1, -64)
toggleIcon.AnchorPoint = Vector2.new(0, 0)
toggleIcon.BackgroundColor3 = Themes.DarkYellowPremium.Accent
toggleIcon.TextColor3 = Themes.DarkYellowPremium.Background
toggleIcon.Text = "≡"
toggleIcon.AutoButtonColor = false
fontPixel(toggleIcon)
toggleIcon.TextSize = 22
toggleIcon.Parent = screen
makeRound(toggleIcon, 22)
makeStroke(toggleIcon, Themes.DarkYellowPremium.Outline, 1)

-- Root window
local main = Instance.new("Frame")
main.Name = "Xinexin_Window"
main.Size = UDim2.new(0, 735, 0, 379)
main.Position = UDim2.new(0.26607, 0, 0.26773, 0)
main.BackgroundColor3 = Themes.DarkYellowPremium.Background
main.Visible = false
main.Parent = screen
makeRound(main, 12)
makeStroke(main, Themes.DarkYellowPremium.Outline, 1)
Registry.Window = main
table.insert(Registry.Panels, main)

-- Top bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Themes.DarkYellowPremium.Panel
topBar.Parent = main
makeRound(topBar, 12)
makeStroke(topBar, Themes.DarkYellowPremium.Outline, 1)
table.insert(Registry.Panels, topBar)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "XINEXIN HUB"
title.TextColor3 = Themes.DarkYellowPremium.Text
fontPixel(title)
title.TextSize = 18
title.Parent = topBar
table.insert(Registry.Text, title)

-- Page bar (left)
local pageBar = Instance.new("Frame")
pageBar.Name = "PageBar"
pageBar.Size = UDim2.new(0, 170, 1, -40)
pageBar.Position = UDim2.new(0, 0, 0, 40)
pageBar.BackgroundColor3 = Themes.DarkYellowPremium.Panel
pageBar.Parent = main
makeStroke(pageBar, Themes.DarkYellowPremium.Outline, 1)
table.insert(Registry.Panels, pageBar)

makePadding(pageBar, 10, 10, 10, 10)
local pageList = Instance.new("Frame")
pageList.Name = "PageList"
pageList.BackgroundTransparency = 1
pageList.Size = UDim2.new(1, 0, 1, 0)
pageList.Parent = pageBar
local pageLayout = makeList(pageList, Enum.FillDirection.Vertical, 8)

-- Section area (right)
local sectionArea = Instance.new("Frame")
sectionArea.Name = "SectionArea"
sectionArea.Position = UDim2.new(0, 170, 0, 40)
sectionArea.Size = UDim2.new(1, -170, 1, -40)
sectionArea.BackgroundColor3 = Themes.DarkYellowPremium.Background
sectionArea.Parent = main
table.insert(Registry.Panels, sectionArea)

local pagesFolder = Instance.new("Folder")
pagesFolder.Name = "Pages"
pagesFolder.Parent = sectionArea

-- Notifications container (top-right)
local notifyContainer = Instance.new("Frame")
notifyContainer.Name = "NotifyContainer"
notifyContainer.AnchorPoint = Vector2.new(1, 0)
notifyContainer.Position = UDim2.new(1, -16, 0, 56)
notifyContainer.Size = UDim2.new(0, 280, 1, -72)
notifyContainer.BackgroundTransparency = 1
notifyContainer.Parent = main
local notifyLayout = makeList(notifyContainer, Enum.FillDirection.Vertical, 8)
notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- Blur effect (created on demand)
local blurEffect = nil

-- State
local STATE = {
    Theme = Themes.DarkYellowPremium,
    Open = false,
    CurrentPage = nil,
    Pages = {},       -- [name] = pageObject
    Keybinds = {},    -- for Section keybind components
}

-- Camera zoom punch when opening
local function zoomPunch()
    local startFOV = currentCamera.FieldOfView
    local target = math.clamp(startFOV - 8, 40, 120)
    local t1 = TweenService:Create(currentCamera, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = target})
    local t2 = TweenService:Create(currentCamera, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = startFOV})
    t1:Play()
    t1.Completed:Wait()
    t2:Play()
end

-- Drag logic for main window
do
    local dragging, dragStart, startPos
    connect(main.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local relY = mousePos.Y - main.AbsolutePosition.Y
            -- Drag only if grabbing topBar area
            if relY <= topBar.AbsoluteSize.Y + 6 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Drag logic for toggle icon
do
    local dragging, dragStart, startPos
    connect(toggleIcon.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = toggleIcon.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            toggleIcon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Toggle UI visibility, blur, and micro-zoom
local function setOpen(open)
    STATE.Open = open
    main.Visible = open
    if open then
        -- Blur in
        if not blurEffect then
            blurEffect = Instance.new("BlurEffect")
            blurEffect.Size = 0
            blurEffect.Parent = Lighting
        end
        tween(blurEffect, 0.2, {Size = 18}):Play()
        -- Window pop-in
        main.Size = UDim2.new(0, 735, 0, 379)
        main.BackgroundTransparency = 0
        main.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset)
        zoomPunch()
        -- slight alpha slide from top
        main.Visible = true
        main.ClipsDescendants = true
        for _, pg in pairs(STATE.Pages) do
            if pg.Root.Visible then
                -- slide sections container in
                pg.Container.Position = UDim2.new(0, 16, 0, 0)
                tween(pg.Container, 0.25, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
            end
        end
    else
        -- Blur out
        if blurEffect then
            local tw = tween(blurEffect, 0.2, {Size = 0})
            tw.Completed:Connect(function()
                if blurEffect then blurEffect:Destroy() blurEffect = nil end
            end)
            tw:Play()
        end
    end
end

connect(toggleIcon.MouseButton1Click, function()
    setOpen(not STATE.Open)
end)

-- Helper: hover bounce + color shift for page tabs
local function attachTabHover(btn, baseColor, hoverColor)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = btn

    connect(btn.MouseEnter, function()
        tween(btn, 0.12, {BackgroundColor3 = hoverColor}):Play()
        tween(scale, 0.12, {Scale = 1.05}, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    end)
    connect(btn.MouseLeave, function()
        tween(btn, 0.12, {BackgroundColor3 = baseColor}):Play()
        tween(scale, 0.12, {Scale = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
    end)
end

-- Theme application
local function applyTheme(theme)
    local th = theme or STATE.Theme
    main.BackgroundColor3 = th.Background
    pageBar.BackgroundColor3 = th.Panel
    topBar.BackgroundColor3 = th.Panel
    toggleIcon.BackgroundColor3 = th.Accent
    toggleIcon.TextColor3 = th.Background

    for _, f in ipairs(Registry.Panels) do
        if f and f.Parent then
            if f ~= pageBar and f ~= topBar and f ~= main then
                f.BackgroundColor3 = th.Panel
            end
        end
    end
    for _, s in ipairs(Registry.Strokes) do
        if s and s.Parent then s.Color = th.Outline end
    end
    for _, t in ipairs(Registry.Text) do
        if t and t.Parent then t.TextColor3 = th.Text end
    end
    for _, m in ipairs(Registry.MutedText) do
        if m and m.Parent then m.TextColor3 = th.Muted end
    end
    for _, tab in ipairs(Registry.PageTabs) do
        if tab and tab.Parent then
            tab.BackgroundColor3 = th.Accent
            tab:SetAttribute("BaseColorR", th.Accent.R)
            tab:SetAttribute("BaseColorG", th.Accent.G)
            tab:SetAttribute("BaseColorB", th.Accent.B)
        end
    end
end

-- Build a page object
local function newPage(name)
    local pageObj = {}
    pageObj.__index = pageObj
    pageObj.Name = name

    -- Tab button
    local tab = Instance.new("TextButton")
    tab.Name = "Tab_" .. name
    tab.Size = UDim2.new(1, 0, 0, 36)
    tab.BackgroundColor3 = STATE.Theme.Accent
    tab.TextColor3 = STATE.Theme.Background
    tab.Text = name
    tab.AutoButtonColor = false
    fontPixel(tab)
    tab.TextSize = 16
    tab.Parent = pageList
    makeRound(tab, 8)
    makeStroke(tab, STATE.Theme.Outline, 1)
    table.insert(Registry.PageTabs, tab)

    attachTabHover(tab, STATE.Theme.Accent, STATE.Theme.AccentHover)

    -- Page root (host inside section area)
    local root = Instance.new("Frame")
    root.Name = "Page_" .. name
    root.BackgroundTransparency = 1
    root.Size = UDim2.new(1, 0, 1, 0)
    root.Visible = false
    root.Parent = pagesFolder

    -- Container that slides in
    local container = Instance.new("ScrollingFrame")
    container.Name = "Container"
    container.Active = true
    container.ScrollingDirection = Enum.ScrollingDirection.Y
    container.ScrollBarImageColor3 = STATE.Theme.Muted
    container.ScrollBarThickness = 4
    container.BackgroundColor3 = STATE.Theme.Background
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Size = UDim2.new(1, 0, 1, 0)
    container.Parent = root
    table.insert(Registry.Panels, container)
    makePadding(container, 12, 12, 12, 12)
    local sectionList = makeList(container, Enum.FillDirection.Vertical, 8)

    -- Automatic canvas size
    connect(sectionList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        container.CanvasSize = UDim2.new(0, 0, 0, sectionList.AbsoluteContentSize.Y + 12)
    end)

    -- Tab click: select page and animate slide-in
    connect(tab.MouseButton1Click, function()
        for _, p in pairs(STATE.Pages) do
            p.Root.Visible = false
        end
        root.Visible = true
        container.Position = UDim2.new(0, 16, 0, 0)
        tween(container, 0.25, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
        STATE.CurrentPage = pageObj
    end)

    -- Add section builder
    function pageObj.addSection(secName)
        local section = {}
        section.__index = section

        local frame = Instance.new("Frame")
        frame.Name = "Section_" .. secName
        frame.Size = UDim2.new(1, 0, 0, 56)
        frame.BackgroundColor3 = STATE.Theme.Panel
        frame.Parent = container
        makeRound(frame, 10)
        local stroke = makeStroke(frame, STATE.Theme.Outline, 1)
        table.insert(Registry.Panels, frame)
        table.insert(Registry.Strokes, stroke)

        local header = Instance.new("TextLabel")
        header.Name = "Header"
        header.BackgroundTransparency = 1
        header.Size = UDim2.new(1, -12, 0, 22)
        header.Position = UDim2.new(0, 12, 0, 6)
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Text = secName
        header.TextColor3 = STATE.Theme.Text
        fontPixel(header)
        header.TextSize = 16
        header.Parent = frame
        table.insert(Registry.Text, header)

        local content = Instance.new("Frame")
        content.Name = "Content"
        content.BackgroundTransparency = 1
        content.Size = UDim2.new(1, -16, 0, 22)
        content.Position = UDim2.new(0, 8, 0, 30)
        content.Parent = frame
        local itemList = makeList(content, Enum.FillDirection.Vertical, 6)

        -- Resize section to fit content
        local function refit()
            local h = 30 + itemList.AbsoluteContentSize.Y + 8
            frame.Size = UDim2.new(1, 0, 0, h)
        end
        connect(itemList:GetPropertyChangedSignal("AbsoluteContentSize"), refit)
        refit()

        local function labelFor(nameText)
            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = nameText
            lbl.TextColor3 = STATE.Theme.Text
            fontPixel(lbl)
            lbl.TextSize = 14
            table.insert(Registry.Text, lbl)
            return lbl
        end

        local function baseItemRow(height)
            local row = Instance.new("Frame")
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, height)
            row.Parent = content

            local left = Instance.new("Frame")
            left.BackgroundTransparency = 1
            left.Size = UDim2.new(0.6, -6, 1, 0)
            left.Position = UDim2.new(0, 0, 0, 0)
            left.Parent = row

            local right = Instance.new("Frame")
            right.BackgroundTransparency = 1
            right.Size = UDim2.new(0.4, 0, 1, 0)
            right.Position = UDim2.new(0.6, 6, 0, 0)
            right.Parent = row

            return row, left, right
        end

        function section:addButton(btnName, callback)
            local row, left, right = baseItemRow(28)
            local lbl = labelFor(btnName)
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Parent = left

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 1, 0)
            btn.Position = UDim2.new(0, 0, 0, 0)
            btn.BackgroundColor3 = STATE.Theme.Accent
            btn.TextColor3 = STATE.Theme.Background
            btn.Text = "Run"
            btn.AutoButtonColor = false
            fontPixel(btn)
            btn.TextSize = 14
            btn.Parent = right
            makeRound(btn, 8)
            makeStroke(btn, STATE.Theme.Outline, 1)

            connect(btn.MouseEnter, function() tween(btn, 0.12, {BackgroundColor3 = STATE.Theme.AccentHover}):Play() end)
            connect(btn.MouseLeave, function() tween(btn, 0.12, {BackgroundColor3 = STATE.Theme.Accent}):Play() end)
            connect(btn.MouseButton1Click, function()
                if typeof(callback) == "function" then
                    task.spawn(callback)
                end
            end)
        end

        function section:addToggle(tName, default, callback)
            local state = default and true or false
            local row, left, right = baseItemRow(28)
            local lbl = labelFor(tName)
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Parent = left

            local outer = Instance.new("Frame")
            outer.Size = UDim2.new(0, 44, 0, 22)
            outer.Position = UDim2.new(0, 0, 0.5, -11)
            outer.BackgroundColor3 = STATE.Theme.Background
            outer.Parent = right
            makeRound(outer, 12)
            makeStroke(outer, STATE.Theme.Outline, 1)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.Position = UDim2.new(0, 2, 0, 2)
            knob.BackgroundColor3 = state and STATE.Theme.Accent or STATE.Theme.Panel
            knob.Parent = outer
            makeRound(knob, 9)

            local function setState(v, fire)
                state = v
                tween(knob, 0.12, {
                    Position = v and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2),
                    BackgroundColor3 = v and STATE.Theme.Accent or STATE.Theme.Panel
                }):Play()
                if fire and typeof(callback) == "function" then
                    task.spawn(callback, state)
                end
            end
            setState(state, false)

            connect(outer.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setState(not state, true)
                end
            end)
        end

        function section:addTextbox(tbName, default, callback)
            local row, left, right = baseItemRow(28)
            local lbl = labelFor(tbName)
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Parent = left

            local tb = Instance.new("TextBox")
            tb.Size = UDim2.new(1, -6, 1, 0)
            tb.BackgroundColor3 = STATE.Theme.Panel
            tb.TextColor3 = STATE.Theme.Text
            tb.PlaceholderColor3 = STATE.Theme.Muted
            tb.Text = typeof(default) == "string" and default or ""
            tb.ClearTextOnFocus = false
            fontPixel(tb)
            tb.TextSize = 14
            tb.Parent = right
            makeRound(tb, 6)
            makeStroke(tb, STATE.Theme.Outline, 1)

            connect(tb.FocusLost, function(enterPressed)
                if typeof(callback) == "function" then
                    task.spawn(callback, tb.Text, enterPressed)
                end
            end)
        end

        function section:addKeybind(kbName, default, callback)
            local row, left, right = baseItemRow(28)
            local lbl = labelFor(kbName)
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Parent = left

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 1, 0)
            btn.BackgroundColor3 = STATE.Theme.Panel
            btn.TextColor3 = STATE.Theme.Text
            btn.Text = "None"
            btn.AutoButtonColor = false
            fontPixel(btn)
            btn.TextSize = 14
            btn.Parent = right
            makeRound(btn, 6)
            makeStroke(btn, STATE.Theme.Outline, 1)

            local currentKey = nil
            if typeof(default) == "EnumItem" then
                currentKey = default
            elseif typeof(default) == "string" and Enum.KeyCode[default] then
                currentKey = Enum.KeyCode[default]
            end
            if currentKey then btn.Text = currentKey.Name end

            local listening = false
            connect(btn.MouseButton1Click, function()
                btn.Text = "Press a key..."
                listening = true
            end)

            connect(UserInputService.InputBegan, function(input, gp)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    currentKey = input.KeyCode
                    btn.Text = currentKey.Name
                end
            end)

            -- Trigger callback on key
            connect(UserInputService.InputBegan, function(input, gp)
                if gp then return end
                if currentKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                    if typeof(callback) == "function" then
                        task.spawn(callback, currentKey)
                    end
                end
            end)
        end

        function section:addColorPicker(cpName, default, callback)
            local row, left, right = baseItemRow(56)
            local lbl = labelFor(cpName)
            lbl.Size = UDim2.new(1, 0, 0, 22)
            lbl.Parent = left

            local swatch = Instance.new("TextButton")
            swatch.Size = UDim2.new(1, -6, 0, 22)
            swatch.Position = UDim2.new(0, 0, 0, 0)
            swatch.BackgroundColor3 = typeof(default) == "Color3" and default or Color3.fromRGB(255, 255, 255)
            swatch.Text = ""
            swatch.AutoButtonColor = false
            swatch.Parent = right
            makeRound(swatch, 6)
            makeStroke(swatch, STATE.Theme.Outline, 1)

            local picker = Instance.new("Frame")
            picker.Size = UDim2.new(1, -6, 0, 24)
            picker.Position = UDim2.new(0, 0, 0, 28)
            picker.BackgroundTransparency = 1
            picker.Parent = right

            local function makeSlider(label, init, cb)
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 0, 22)
                frame.BackgroundColor3 = STATE.Theme.Panel
                frame.Parent = picker
                makeRound(frame, 6)
                makeStroke(frame, STATE.Theme.Outline, 1)

                local text = Instance.new("TextLabel")
                text.BackgroundTransparency = 1
                text.Size = UDim2.new(0, 26, 1, 0)
                text.Position = UDim2.new(0, 6, 0, 0)
                text.Text = label
                text.TextColor3 = STATE.Theme.Muted
                fontPixel(text)
                text.TextSize = 12
                text.Parent = frame
                table.insert(Registry.MutedText, text)

                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(1, -46, 0, 6)
                bar.Position = UDim2.new(0, 36, 0.5, -3)
                bar.BackgroundColor3 = STATE.Theme.Background
                bar.Parent = frame
                makeRound(bar, 3)

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(init, 0, 1, 0)
                fill.BackgroundColor3 = STATE.Theme.Accent
                fill.Parent = bar
                makeRound(fill, 3)

                local value = init
                local dragging = false
                local function setFromX(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    value = rel
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    if cb then cb(value) end
                end

                connect(frame.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        setFromX(UserInputService:GetMouseLocation().X)
                    end
                end)
                connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                connect(UserInputService.InputChanged, function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setFromX(UserInputService:GetMouseLocation().X)
                    end
                end)

                return function() return value end
            end

            local h, s, v = 0, 0, 1
            local function updateSwatch(fire)
                local col = Color3.fromHSV(h, s, v)
                tween(swatch, 0.1, {BackgroundColor3 = col}):Play()
                if fire and typeof(callback) == "function" then
                    task.spawn(callback, col)
                end
            end

            makeList(picker, Enum.FillDirection.Vertical, 4)
            local getH = makeSlider("H", h, function(vv) h = vv; updateSwatch(true) end)
            local getS = makeSlider("S", s, function(vv) s = vv; updateSwatch(true) end)
            local getV = makeSlider("V", v, function(vv) v = vv; updateSwatch(true) end)

            connect(swatch.MouseButton1Click, function()
                -- subtle pulse
                local scale = Instance.new("UIScale", swatch)
                scale.Scale = 1
                tween(scale, 0.08, {Scale = 0.97}):Play()
                task.delay(0.08, function() tween(scale, 0.12, {Scale = 1}):Play(); task.delay(0.14, function() if scale then scale:Destroy() end end) end)
            end)

            updateSwatch(false)
        end

        function section:addSlider(slName, min, max, default, callback)
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            local value = math.clamp(tonumber(default) or min, min, max)

            local row, left, right = baseItemRow(36)
            local lbl = labelFor(slName)
            lbl.Size = UDim2.new(1, 0, 0, 16)
            lbl.Parent = left

            local valLbl = Instance.new("TextLabel")
            valLbl.BackgroundTransparency = 1
            valLbl.Size = UDim2.new(1, 0, 0, 16)
            valLbl.Position = UDim2.new(0, 0, 0, 16)
            valLbl.TextXAlignment = Enum.TextXAlignment.Left
            valLbl.Text = tostring(value)
            valLbl.TextColor3 = STATE.Theme.Muted
            fontPixel(valLbl)
            valLbl.TextSize = 12
            valLbl.Parent = left
            table.insert(Registry.MutedText, valLbl)

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -6, 0, 10)
            bar.Position = UDim2.new(0, 0, 0.5, -5)
            bar.BackgroundColor3 = STATE.Theme.Panel
            bar.Parent = right
            makeRound(bar, 5)
            makeStroke(bar, STATE.Theme.Outline, 1)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = STATE.Theme.Accent
            fill.Parent = bar
            makeRound(fill, 5)

            local dragging = false
            local function setFromX(x, fire)
                local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + rel * (max - min) + 0.5)
                value = val
                valLbl.Text = tostring(val)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                if fire and typeof(callback) == "function" then
                    task.spawn(callback, value)
                end
            end

            connect(bar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setFromX(UserInputService:GetMouseLocation().X, true)
                end
            end)
            connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            connect(UserInputService.InputChanged, function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromX(UserInputService:GetMouseLocation().X, true)
                end
            end)
        end

        function section:addDropdown(ddName, options, default, callback)
            options = options or {}
            local current = default or (options[1] or "None")

            local row, left, right = baseItemRow(28)
            local lbl = labelFor(ddName)
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Parent = left

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 1, 0)
            btn.BackgroundColor3 = STATE.Theme.Panel
            btn.TextColor3 = STATE.Theme.Text
            btn.Text = tostring(current)
            btn.AutoButtonColor = false
            fontPixel(btn)
            btn.TextSize = 14
            btn.Parent = right
            makeRound(btn, 6)
            makeStroke(btn, STATE.Theme.Outline, 1)

            local openList = false
            local list = Instance.new("Frame")
            list.Visible = false
            list.BackgroundColor3 = STATE.Theme.Panel
            list.Size = UDim2.new(1, -6, 0, math.min(#options, 6) * 24 + 8)
            list.Position = UDim2.new(0, 0, 1, 4)
            list.Parent = right
            makeRound(list, 6)
            makeStroke(list, STATE.Theme.Outline, 1)
            table.insert(Registry.Panels, list)

            local inner = Instance.new("Frame")
            inner.BackgroundTransparency = 1
            inner.Size = UDim2.new(1, -8, 1, -8)
            inner.Position = UDim2.new(0, 4, 0, 4)
            inner.Parent = list
            local il = makeList(inner, Enum.FillDirection.Vertical, 4)

            local function populate()
                inner:ClearAllChildren()
                makeList(inner, Enum.FillDirection.Vertical, 4).Parent = inner
                for _, opt in ipairs(options) do
                    local o = Instance.new("TextButton")
                    o.Size = UDim2.new(1, 0, 0, 22)
                    o.BackgroundColor3 = STATE.Theme.Background
                    o.TextColor3 = STATE.Theme.Text
                    o.Text = tostring(opt)
                    o.AutoButtonColor = false
                    fontPixel(o)
                    o.TextSize = 14
                    o.Parent = inner
                    makeRound(o, 4)
                    makeStroke(o, STATE.Theme.Outline, 1)

                    connect(o.MouseEnter, function() tween(o, 0.1, {BackgroundColor3 = STATE.Theme.Accent}):Play() o.TextColor3 = STATE.Theme.Background end)
                    connect(o.MouseLeave, function() tween(o, 0.1, {BackgroundColor3 = STATE.Theme.Background}):Play() o.TextColor3 = STATE.Theme.Text end)
                    connect(o.MouseButton1Click, function()
                        current = opt
                        btn.Text = tostring(opt)
                        list.Visible = false
                        openList = false
                        if typeof(callback) == "function" then
                            task.spawn(callback, current)
                        end
                    end)
                end
            end
            populate()

            connect(btn.MouseButton1Click, function()
                openList = not openList
                list.Visible = openList
            end)
        end

        function section:Resize(size)
            if typeof(size) == "UDim2" then
                frame.Size = size
            end
        end

        return section
    end

    -- Resize entire window via a page method
    function pageObj.addResize(size)
        if typeof(size) == "UDim2" then
            main.Size = size
        end
    end

    pageObj.Root = root
    pageObj.Container = container
    pageObj.Tab = tab
    return pageObj
end

-- Public API

function UI.addPage(name)
    local pg = newPage(name)
    STATE.Pages[name] = pg
    -- Select first page by default if none
    if not STATE.CurrentPage then
        pg.Tab.MouseButton1Click:Fire()
    end
    return pg
end

function UI.addNotify(message)
    local item = Instance.new("Frame")
    item.Size = UDim2.new(1, 0, 0, 36)
    item.BackgroundColor3 = STATE.Theme.Panel
    item.Parent = notifyContainer
    makeRound(item, 8)
    makeStroke(item, STATE.Theme.Outline, 1)
    table.insert(Registry.Panels, item)

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -16, 1, 0)
    text.Position = UDim2.new(0, 8, 0, 0)
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Text = tostring(message)
    text.TextColor3 = STATE.Theme.Text
    fontPixel(text)
    text.TextSize = 14
    text.Parent = item
    table.insert(Registry.Text, text)

    item.BackgroundTransparency = 1
    tween(item, 0.15, {BackgroundTransparency = 0}):Play()
    task.delay(2.2, function()
        local tw = tween(item, 0.2, {BackgroundTransparency = 1})
        tw.Completed:Connect(function()
            item:Destroy()
        end)
        tw:Play()
    end)
end

function UI.addSelectPage(name)
    local pg = STATE.Pages[name]
    if pg then
        pg.Tab.MouseButton1Click:Fire()
    end
end

function UI.SetTheme(theme)
    if typeof(theme) == "string" and Themes[theme] then
        STATE.Theme = Themes[theme]
    elseif typeof(theme) == "table" then
        -- Custom theme table with expected keys
        STATE.Theme = theme
    end
    applyTheme()
end

function UI.Toggle()
    setOpen(not STATE.Open)
end

-- Initial apply theme and show window once built externally
applyTheme(STATE.Theme)

-- Startup: show UI with effects on first toggle press
-- Keep hidden until user clicks toggle icon or calls UI.Toggle()

-- Improve page tab hover bounce color re-application when theme changes
for _, tab in ipairs(Registry.PageTabs) do
    attachTabHover(tab, STATE.Theme.Accent, STATE.Theme.AccentHover)
end

-- Top bar title hover micro effect
do
    connect(topBar.MouseEnter, function()
        tween(topBar, 0.12, {BackgroundColor3 = STATE.Theme.Background}):Play()
    end)
    connect(topBar.MouseLeave, function()
        tween(topBar, 0.12, {BackgroundColor3 = STATE.Theme.Panel}):Play()
    end)
end

return UI
