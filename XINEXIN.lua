--[[
XINEXIN HUB - Minimal / Flat UI Library
Theme: Dark Yellow Premium, Font: Pixel Bold, TextColor: White
Features: Blur & zoom on open, draggable window, draggable toggle icon,
page hover bounce + color, section slide-in animation, layout auto-arrange.

API:
local UI = XINEXIN.new({...})

UI.addPage(name)
UI.addNotify(message)
UI.addSelectPage(name)
UI.SetTheme(theme)
UI.Toggle()

Page.addSection(name)
Page.addResize(size)

Section:addButton(name, callback)
Section:addToggle(name, default, callback)
Section:addTextbox(name, default, callback)
Section:addKeybind(name, default, callback)
Section:addColorPicker(name, default, callback) -- simple hue slider
Section:addSlider(name, min, max, default, callback)
Section:addDropdown(name, options, default, callback)
Section:Resize(size)

MIT License
]]--

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local function safeParentGUI(gui)
    local parent = nil
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then parent = core end
    if not parent then
        local player = Players.LocalPlayer
        if player and player:FindFirstChildOfClass("PlayerGui") then
            parent = player:FindFirstChildOfClass("PlayerGui")
        end
    end
    gui.Parent = parent or game:GetService("StarterGui")
end

local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

local function tween(obj, info, props)
    return TweenService:Create(obj, info, props):Play()
end

local function newUIStroke(parent, thickness, color)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Color = color or Color3.fromRGB(35,35,35)
    s.Parent = parent
    return s
end

local function newCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function newPadding(parent, p)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, p); pad.PaddingRight = UDim.new(0, p)
    pad.PaddingTop = UDim.new(0, p); pad.PaddingBottom = UDim.new(0, p)
    pad.Parent = parent
    return pad
end

local function newListLayout(parent, dir, padding)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, padding or 6)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment = Enum.VerticalAlignment.Top
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function createBlur()
    local blur = Lighting:FindFirstChild("XINEXIN_BLUR") or Instance.new("BlurEffect")
    blur.Name = "XINEXIN_BLUR"
    blur.Size = 0
    blur.Enabled = false
    blur.Parent = Lighting
    return blur
end

local COLORS = {
    Dark = {
        BG = Color3.fromRGB(18, 18, 18),
        Panel = Color3.fromRGB(24, 24, 24),
        Accent = Color3.fromRGB(246, 191, 0), -- premium yellow
        AccentHover = Color3.fromRGB(255, 210, 60),
        Text = Color3.fromRGB(255, 255, 255),
        Muted = Color3.fromRGB(180, 180, 180),
        Stroke = Color3.fromRGB(40, 40, 40)
    }
}

local DEFAULTS = {
    Theme = "Dark Yellow Premium",
    Font = Enum.Font.GothamBold, -- fallback for "Pixel Bold"
    TextColor = Color3.fromRGB(255,255,255),
    Size = UDim2.new(0, 735, 0, 379),
    Position = UDim2.new(0.26607, 0, 0.26773, 0),
    HubName = "XINEXIN HUB"
}

local XINEXIN = {}
XINEXIN.__index = XINEXIN

local Page = {}
Page.__index = Page

local Section = {}
Section.__index = Section

-- UTIL: hover bounce + color
local function applyHoverBounce(button, baseColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = hoverColor, Size = button.Size + UDim2.new(0, 4, 0, 4)})
    end)
    button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = baseColor, Size = UDim2.new(0, button.Size.X.Offset - 4, 0, button.Size.Y.Offset - 4)})
    end)
end

-- Class: XINEXIN
function XINEXIN.new(cfg)
    cfg = setmetatable(cfg or {}, {__index = DEFAULTS})
    local self = setmetatable({}, XINEXIN)

    self._theme = COLORS.Dark
    self._pages = {}
    self._currentPage = nil
    self._blur = createBlur()

    local gui = Instance.new("ScreenGui")
    gui.Name = "XINEXIN_HUB"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    safeParentGUI(gui)
    self.Gui = gui

    -- Floating toggle icon
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Text = "≡"
    toggleBtn.AutoButtonColor = false
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 18
    toggleBtn.TextColor3 = cfg.TextColor
    toggleBtn.BackgroundColor3 = self._theme.Accent
    toggleBtn.Size = UDim2.new(0, 36, 0, 36)
    toggleBtn.Position = UDim2.new(0, 20, 0.5, -18)
    newCorner(toggleBtn, 18)
    newUIStroke(toggleBtn, 1, self._theme.Stroke)
    toggleBtn.Parent = gui
    makeDraggable(toggleBtn)
    self._toggleBtn = toggleBtn

    -- Main window
    local main = Instance.new("Frame")
    main.Name = "Window"
    main.BackgroundColor3 = self._theme.BG
    main.Size = cfg.Size
    main.Position = cfg.Position
    main.Visible = true
    newCorner(main, 10)
    newUIStroke(main, 1, self._theme.Stroke)
    main.Parent = gui

    -- Zoom scale
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0.94
    uiScale.Parent = main

    -- Top bar
    local top = Instance.new("Frame")
    top.Name = "TopBar"
    top.BackgroundColor3 = self._theme.Panel
    top.Size = UDim2.new(1, 0, 0, 40)
    newCorner(top, 10)
    newUIStroke(top, 1, self._theme.Stroke)
    top.Parent = main

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Font = cfg.Font
    title.Text = cfg.HubName
    title.TextColor3 = cfg.TextColor
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 16, 0, 0)
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.Parent = top

    -- Drag by top bar
    makeDraggable(main, top)

    -- Page bar (left)
    local pageBar = Instance.new("Frame")
    pageBar.Name = "PageBar"
    pageBar.BackgroundColor3 = self._theme.Panel
    pageBar.Position = UDim2.new(0, 0, 0, 40)
    pageBar.Size = UDim2.new(0, 160, 1, -40)
    newUIStroke(pageBar, 1, self._theme.Stroke)
    pageBar.Parent = main

    local pageList = Instance.new("Frame")
    pageList.Name = "PageList"
    pageList.BackgroundTransparency = 1
    pageList.Size = UDim2.new(1, 0, 1, -12)
    pageList.Position = UDim2.new(0, 0, 0, 6)
    newListLayout(pageList, Enum.FillDirection.Vertical, 6)
    newPadding(pageList, 8)
    pageList.Parent = pageBar

    -- Section area (right, per-page container)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 160, 0, 40)
    content.Size = UDim2.new(1, -160, 1, -40)
    content.Parent = main

    self.Main = main
    self.PageBar = pageBar
    self.PageList = pageList
    self.Content = content

    -- Toggle behavior
    toggleBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Open animation
    self:_openAnimation()

    return self
end

function XINEXIN:_openAnimation()
    self._blur.Enabled = true
    tween(self._blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 16})
    local scale = self.Main:FindFirstChildOfClass("UIScale")
    if scale then
        tween(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    end
end

function XINEXIN:_closeAnimation()
    local scale = self.Main:FindFirstChildOfClass("UIScale")
    if scale then
        tween(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.94})
    end
    tween(self._blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)), {}
end

function XINEXIN:Toggle()
    local visible = not self.Main.Visible
    self.Main.Visible = visible
    if visible then
        self:_openAnimation()
    else
        self._blur.Enabled = false
        self._blur.Size = 0
    end
end

function XINEXIN:SetTheme(themeName)
    -- Currently one theme; hook for future themes
    return true
end

function XINEXIN:addNotify(message)
    local notifHolder = self.Gui:FindFirstChild("NotifHolder")
    if not notifHolder then
        notifHolder = Instance.new("Frame")
        notifHolder.Name = "NotifHolder"
        notifHolder.BackgroundTransparency = 1
        notifHolder.Size = UDim2.new(1, -20, 1, -20)
        notifHolder.Position = UDim2.new(0, 10, 0, 10)
        notifHolder.Parent = self.Gui
        local l = newListLayout(notifHolder, Enum.FillDirection.Vertical, 8)
        l.HorizontalAlignment = Enum.HorizontalAlignment.Right
        l.VerticalAlignment = Enum.VerticalAlignment.Top
    end

    local card = Instance.new("Frame")
    card.BackgroundColor3 = self._theme.Panel
    card.Size = UDim2.new(0, 260, 0, 44)
    newCorner(card, 8)
    newUIStroke(card, 1, self._theme.Stroke)
    card.Parent = notifHolder
    card.BackgroundTransparency = 1
    card.Position = UDim2.new(1, 0, 0, 0)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.Text = tostring(message)
    lbl.TextColor3 = self._theme.Text
    lbl.TextSize = 14
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(1, -16, 1, -16)
    lbl.Position = UDim2.new(0, 8, 0, 8)
    lbl.Parent = card

    -- slide in + fade
    card.BackgroundTransparency = 1
    tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0})
    delay(3, function()
        if card and card.Parent then
            tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
            wait(0.22)
            card:Destroy()
        end
    end)
end

function XINEXIN:addPage(name)
    name = tostring(name)
    local btn = Instance.new("TextButton")
    btn.Name = "Page_" .. name
    btn.Text = name
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = self._theme.Text
    btn.BackgroundColor3 = self._theme.Accent
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Parent = self.PageList
    newCorner(btn, 8)
    newUIStroke(btn, 1, self._theme.Stroke)
    applyHoverBounce(btn, self._theme.Accent, self._theme.AccentHover)

    local pageFrame = Instance.new("ScrollingFrame")
    pageFrame.Name = "PageFrame_" .. name
    pageFrame.Active = true
    pageFrame.BorderSizePixel = 0
    pageFrame.BackgroundTransparency = 1
    pageFrame.ScrollBarThickness = 4
    pageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    pageFrame.Visible = false
    pageFrame.Size = UDim2.new(1, -20, 1, -20)
    pageFrame.Position = UDim2.new(0, 10, 0, 10)
    pageFrame.Parent = self.Content

    local layout = newListLayout(pageFrame, Enum.FillDirection.Vertical, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    newPadding(pageFrame, 10)

    layout.Changed:Connect(function(prop)
        if prop == "AbsoluteContentSize" then
            pageFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end
    end)

    local pageObj = setmetatable({
        _ui = self,
        Name = name,
        Button = btn,
        Frame = pageFrame,
        Sections = {},
    }, Page)

    self._pages[name] = pageObj

    btn.MouseButton1Click:Connect(function()
        self:addSelectPage(name)
    end)

    if not self._currentPage then
        self:addSelectPage(name)
    end

    return pageObj
end

function XINEXIN:addSelectPage(name)
    for n, page in pairs(self._pages) do
        page.Frame.Visible = (n == name)
    end
    self._currentPage = self._pages[name]
    if self._currentPage then
        -- slide-in animation for sections
        for _, s in ipairs(self._currentPage.Sections) do
            if s and s.Frame then
                s.Frame.Position = UDim2.new(0, -20, 0, s.Frame.Position.Y.Offset)
                s.Frame.BackgroundTransparency = 1
                tween(s.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 0, 0, s.Frame.Position.Y.Offset), BackgroundTransparency = 0})
            end
        end
    end
end

-- Class: Page
function Page:addResize(size)
    self.Frame.Size = size
end

function Page:addSection(name)
    name = tostring(name)
    local section = Instance.new("Frame")
    section.Name = "Section_" .. name
    section.BackgroundColor3 = self._ui._theme.Panel
    section.Size = UDim2.new(1, -10, 0, 80)
    newCorner(section, 8)
    newUIStroke(section, 1, self._ui._theme.Stroke)
    section.Parent = self.Frame

    local header = Instance.new("TextLabel")
    header.BackgroundTransparency = 1
    header.Text = name
    header.TextColor3 = self._ui._theme.Text
    header.Font = Enum.Font.GothamBold
    header.TextSize = 16
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Size = UDim2.new(1, -16, 0, 26)
    header.Position = UDim2.new(0, 8, 0, 6)
    header.Parent = section

    local container = Instance.new("Frame")
    container.Name = "Items"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -16, 1, -38)
    container.Position = UDim2.new(0, 8, 0, 32)
    newListLayout(container, Enum.FillDirection.Vertical, 6)
    container.Parent = section

    local secObj = setmetatable({
        _ui = self._ui,
        _page = self,
        Name = name,
        Frame = section,
        Container = container,
    }, Section)

    table.insert(self.Sections, secObj)
    -- autosize on content
    local layout = container:FindFirstChildOfClass("UIListLayout")
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        section.Size = UDim2.new(1, -10, 0, 38 + layout.AbsoluteContentSize.Y + 8)
    end)

    return secObj
end

-- Class: Section controls
local function controlBase(section, height)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = section._ui._theme.BG
    frame.Size = UDim2.new(1, 0, 0, height or 32)
    newCorner(frame, 6)
    newUIStroke(frame, 1, section._ui._theme.Stroke)
    frame.Parent = section.Container
    return frame
end

local function label(parent, text)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextColor3 = Color3.fromRGB(255,255,255)
    l.TextSize = 14
    l.Text = text
    l.Size = UDim2.new(1, -10, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.Parent = parent
    return l
end

function Section:Resize(size)
    self.Frame.Size = size
end

function Section:addButton(name, callback)
    local f = controlBase(self, 32)
    label(f, name)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = self._ui._theme.Accent
    btn.Text = "Run"
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(0,0,0)
    btn.Size = UDim2.new(0, 72, 0, 24)
    btn.Position = UDim2.new(1, -82, 0.5, -12)
    newCorner(btn, 6)
    newUIStroke(btn, 1, self._ui._theme.Stroke)
    btn.Parent = f

    applyHoverBounce(btn, self._ui._theme.Accent, self._ui._theme.AccentHover)

    btn.MouseButton1Click:Connect(function()
        if typeof(callback) == "function" then
            task.spawn(callback)
        end
    end)

    return btn
end

function Section:addToggle(name, default, callback)
    local f = controlBase(self, 32)
    label(f, name)
    local toggle = Instance.new("TextButton")
    toggle.AutoButtonColor = false
    toggle.Size = UDim2.new(0, 48, 0, 24)
    toggle.Position = UDim2.new(1, -58, 0.5, -12)
    toggle.BackgroundColor3 = default and self._ui._theme.Accent or Color3.fromRGB(70,70,70)
    newCorner(toggle, 12)
    newUIStroke(toggle, 1, self._ui._theme.Stroke)
    toggle.Parent = f

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    newCorner(knob, 10)
    knob.Parent = toggle

    local state = default and true or false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        tween(toggle, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = state and self._ui._theme.Accent or Color3.fromRGB(70,70,70)})
        tween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)})
        if typeof(callback) == "function" then
            task.spawn(callback, state)
        end
    end)

    return {
        Get = function() return state end,
        Set = function(v)
            state = v and true or false
            toggle.BackgroundColor3 = state and self._ui._theme.Accent or Color3.fromRGB(70,70,70)
            knob.Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        end
    }
end

function Section:addTextbox(name, default, callback)
    local f = controlBase(self, 32)
    label(f, name)
    local box = Instance.new("TextBox")
    box.Text = default or ""
    box.PlaceholderText = ""
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.BackgroundTransparency = 1
    box.Size = UDim2.new(0, 180, 1, 0)
    box.Position = UDim2.new(1, -190, 0, 0)
    box.Parent = f
    box.FocusLost:Connect(function(enterPressed)
        if typeof(callback) == "function" then
            task.spawn(callback, box.Text, enterPressed)
        end
    end)
    return box
end

function Section:addKeybind(name, default, callback)
    local f = controlBase(self, 32)
    local lbl = label(f, name)
    local btn = Instance.new("TextButton")
    btn.Text = default and default.Name or "Set Key"
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = UDim2.new(1, -110, 0, 0)
    btn.Parent = f

    local binding = default
    local capturing = false

    btn.MouseButton1Click:Connect(function()
        btn.Text = "Press a key..."
        capturing = true
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if capturing and input.UserInputType == Enum.UserInputType.Keyboard then
            binding = input.KeyCode
            btn.Text = binding.Name
            capturing = false
        elseif binding and input.KeyCode == binding then
            if typeof(callback) == "function" then
                task.spawn(callback)
            end
        end
    end)

    return {
        Get = function() return binding end,
        Set = function(kc) binding = kc; btn.Text = kc and kc.Name or "Set Key" end
    }
end

function Section:addColorPicker(name, default, callback)
    local f = controlBase(self, 48)
    label(f, name)

    local hue = 0
    if typeof(default) == "Color3" then
        local h, s, v = Color3.toHSV(default); hue = h
    end

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 32, 0, 32)
    swatch.Position = UDim2.new(1, -42, 0.5, -16)
    swatch.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
    newCorner(swatch, 6)
    newUIStroke(swatch, 1, self._ui._theme.Stroke)
    swatch.Parent = f

    local slider = Instance.new("Frame")
    slider.BackgroundTransparency = 1
    slider.Size = UDim2.new(1, -84, 0, 12)
    slider.Position = UDim2.new(0, 10, 0.5, -6)
    slider.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
    newCorner(bar, 6)
    newUIStroke(bar, 1, self._ui._theme.Stroke)
    bar.Parent = slider

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = self._ui._theme.Accent
    fill.Size = UDim2.new(hue, 0, 1, 0)
    newCorner(fill, 6)
    fill.Parent = bar

    local function setHue(xScale)
        hue = math.clamp(xScale, 0, 1)
        swatch.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        fill.Size = UDim2.new(hue, 0, 1, 0)
        if typeof(callback) == "function" then
            task.spawn(callback, Color3.fromHSV(hue, 1, 1))
        end
    end

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            setHue(rel)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            setHue(rel)
        end
    end)

    return {
        Get = function() return Color3.fromHSV(hue, 1, 1) end,
        Set = function(c) local h = Color3.toHSV(c); setHue(h) end
    }
end

function Section:addSlider(name, min, max, default, callback)
    min = tonumber(min) or 0
    max = tonumber(max) or 100
    local val = math.clamp(tonumber(default) or min, min, max)

    local f = controlBase(self, 48)
    local lbl = label(f, string.format("%s (%d)", name, val))

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 12)
    bar.Position = UDim2.new(0, 10, 0.5, -6)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
    newCorner(bar, 6)
    newUIStroke(bar, 1, self._ui._theme.Stroke)
    bar.Parent = f

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = self._ui._theme.Accent
    fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
    newCorner(fill, 6)
    fill.Parent = bar

    local dragging = false
    local function setFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        val = math.floor(min + alpha*(max-min))
        fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
        lbl.Text = string.format("%s (%d)", name, val)
        if typeof(callback) == "function" then
            task.spawn(callback, val)
        end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)

    return {
        Get = function() return val end,
        Set = function(v)
            val = math.clamp(tonumber(v) or min, min, max)
            fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
            lbl.Text = string.format("%s (%d)", name, val)
        end
    }
end

function Section:addDropdown(name, options, default, callback)
    options = options or {}
    local f = controlBase(self, 32)
    label(f, name)

    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = self._ui._theme.Panel
    btn.AutoButtonColor = false
    btn.Text = default or "Select..."
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Size = UDim2.new(0, 160, 0, 24)
    btn.Position = UDim2.new(1, -170, 0.5, -12)
    newCorner(btn, 6)
    newUIStroke(btn, 1, self._ui._theme.Stroke)
    btn.Parent = f

    local open = false
    local list = Instance.new("Frame")
    list.Visible = false
    list.BackgroundColor3 = self._ui._theme.Panel
    list.Size = UDim2.new(0, 160, 0, math.min(150, 6 + #options*28))
    list.Position = UDim2.new(1, -170, 0.5, 16)
    newCorner(list, 6)
    newUIStroke(list, 1, self._ui._theme.Stroke)
    list.Parent = f

    local ll = newListLayout(list, Enum.FillDirection.Vertical, 4)
    newPadding(list, 6)

    local function setChoice(text)
        btn.Text = text
        if typeof(callback) == "function" then
            task.spawn(callback, text)
        end
    end

    for _, opt in ipairs(options) do
        local o = Instance.new("TextButton")
        o.Text = tostring(opt)
        o.AutoButtonColor = false
        o.Font = Enum.Font.Gotham
        o.TextSize = 14
        o.BackgroundColor3 = self._ui._theme.BG
        o.TextColor3 = Color3.fromRGB(255,255,255)
        o.Size = UDim2.new(1, 0, 0, 24)
        newCorner(o, 4)
        newUIStroke(o, 1, self._ui._theme.Stroke)
        o.Parent = list
        applyHoverBounce(o, self._ui._theme.BG, Color3.fromRGB(45,45,45))
        o.MouseButton1Click:Connect(function()
            setChoice(o.Text)
            open = false
            list.Visible = false
        end)
    end

    btn.MouseButton1Click:Connect(function()
        open = not open
        list.Visible = open
    end)

    if default then setChoice(default) end
    return {
        Get = function() return btn.Text end,
        Set = function(v) setChoice(tostring(v)) end,
        SetOptions = function(newOpts)
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            options = newOpts or {}
            list.Size = UDim2.new(0, 160, 0, math.min(150, 6 + #options*28))
            for _, opt in ipairs(options) do
                local o = Instance.new("TextButton")
                o.Text = tostring(opt)
                o.AutoButtonColor = false
                o.Font = Enum.Font.Gotham
                o.TextSize = 14
                o.BackgroundColor3 = self._ui._theme.BG
                o.TextColor3 = Color3.fromRGB(255,255,255)
                o.Size = UDim2.new(1, 0, 0, 24)
                newCorner(o, 4)
                newUIStroke(o, 1, self._ui._theme.Stroke)
                o.Parent = list
                applyHoverBounce(o, self._ui._theme.BG, Color3.fromRGB(45,45,45))
                o.MouseButton1Click:Connect(function()
                    setChoice(o.Text)
                    open = false
                    list.Visible = false
                end)
            end
        end
    }
end

return XINEXIN
