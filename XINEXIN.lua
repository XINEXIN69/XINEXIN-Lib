-- XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
-- Theme: Dark Yellow, Pixel (bold), White text
-- Window: Size UDim2.new(0, 735, 0, 379), Position UDim2.new(0.26607, 0, 0.26773, 0)
-- Author: You
-- License: MIT (update as you wish)
-- Version: 1.0.0

--[[ Public API
local UI = Xinexin.new({
    Name = "XINEXIN HUB",
    Theme = "DarkYellow", -- or pass a table to override
})

local Page = UI.addPage("Main")
local Section = Page.addSection("Utilities")

Section:addButton("Click Me", function() end)
Section:addToggle("God Mode", false, function(on) end)
Section:addTextbox("Player Name", "", function(text) end)
Section:addKeybind("Open/Close", Enum.KeyCode.RightShift, function(key) UI.Toggle() end)
Section:addColorPicker("Accent", Color3.fromRGB(255, 204, 0), function(c) end)
Section:addSlider("WalkSpeed", 16, 200, 16, function(v) end)
Section:addDropdown("Map", {"Forest","Desert","City"}, "Forest", function(v) end)

Page.addResize(UDim2.new(0, 800, 0, 420))
Section:Resize(UDim2.new(1, -10, 0, 220))

UI.addNotify("Welcome to XINEXIN HUB!")
UI.addSelectPage("Main")
UI.SetTheme("DarkYellow")
UI.Toggle() -- open/close
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local function safeParent()
    local cg = game:FindFirstChildOfClass("CoreGui")
    if cg then return cg end
    if LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") then
        return LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    return game:GetService("CoreGui")
end

local function destroyIfExists(parent, name)
    local old = parent:FindFirstChild(name)
    if old then old:Destroy() end
end

local function tween(obj, ti, goal)
    local info = typeof(ti) == "TweenInfo" and ti or TweenInfo.new(ti or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    return TweenService:Create(obj, info, goal)
end

local function addCorner(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = instance
    return c
end

local function addStroke(instance, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(255, 204, 0)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.2
    s.Parent = instance
    return s
end

local function addPadding(instance, pad)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, pad or 8)
    p.PaddingRight = UDim.new(0, pad or 8)
    p.PaddingTop = UDim.new(0, pad or 8)
    p.PaddingBottom = UDim.new(0, pad or 8)
    p.Parent = instance
    return p
end

local function addListLayout(parent, fillDir, sortOrder, pad, horizontalAlign, verticalAlign)
    local l = Instance.new("UIListLayout")
    l.FillDirection = fillDir or Enum.FillDirection.Vertical
    l.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
    if pad then l.Padding = UDim.new(0, pad) end
    if horizontalAlign then l.HorizontalAlignment = horizontalAlign end
    if verticalAlign then l.VerticalAlignment = verticalAlign end
    l.Parent = parent
    return l
end

local function addScale(parent, scale)
    local s = Instance.new("UIScale")
    s.Scale = scale or 1
    s.Parent = parent
    return s
end

local DEFAULT_THEME = {
    Name = "DarkYellow",
    Font = Enum.Font.Arcade,
    TextColor = Color3.fromRGB(255, 255, 255),
    WindowBg = Color3.fromRGB(18, 18, 18),
    Accent = Color3.fromRGB(255, 204, 0),
    AccentHover = Color3.fromRGB(255, 220, 70),
    AccentMuted = Color3.fromRGB(140, 110, 0),
    PanelBg = Color3.fromRGB(24, 24, 24),
    ButtonBg = Color3.fromRGB(28, 28, 28),
    ButtonHover = Color3.fromRGB(36, 36, 36),
    ToggleOn = Color3.fromRGB(255, 204, 0),
    ToggleOff = Color3.fromRGB(60, 60, 60),
    SliderTrack = Color3.fromRGB(60, 60, 60),
    SliderFill = Color3.fromRGB(255, 204, 0),
    DropdownBg = Color3.fromRGB(28, 28, 28),
    SectionStroke = Color3.fromRGB(255, 204, 0),
    PageHover = Color3.fromRGB(40, 40, 40),
    NotifyBg = Color3.fromRGB(28, 28, 28),
}

local Xinexin = {}
Xinexin.__index = Xinexin

function Xinexin.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Xinexin)

    self.Name = opts.Name or "XINEXIN HUB"
    self.Theme = DEFAULT_THEME
    if typeof(opts.Theme) == "string" then
        -- currently only one named theme; can expand later
        self.Theme = DEFAULT_THEME
    elseif typeof(opts.Theme) == "table" then
        local merged = {}
        for k, v in pairs(DEFAULT_THEME) do merged[k] = v end
        for k, v in pairs(opts.Theme) do merged[k] = v end
        self.Theme = merged
    end

    self._connections = {}
    self._pages = {}
    self._pageByName = {}
    self._currentPage = nil
    self._open = false
    self._cleanupBlur = false
    self._blur = nil
    self._camera = workspace.CurrentCamera
    self._cameraDefaultFOV = self._camera and self._camera.FieldOfView or 70

    -- Root
    local parent = safeParent()
    destroyIfExists(parent, "XINEXIN_HUB")
    local gui = Instance.new("ScreenGui")
    gui.Name = "XINEXIN_HUB"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent
    self.Gui = gui

    -- Window
    local window = Instance.new("Frame")
    window.Name = "Window"
    window.Size = UDim2.new(0, 735, 0, 379)
    window.Position = UDim2.new(0.26607, 0, 0.26773, 0)
    window.BackgroundColor3 = self.Theme.WindowBg
    window.BorderSizePixel = 0
    window.Visible = false
    window.Parent = gui
    addCorner(window, 10)
    addStroke(window, self.Theme.Accent, 1, 0.4)
    self.Window = window

    -- Top Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 36)
    topBar.BackgroundColor3 = self.Theme.PanelBg
    topBar.BorderSizePixel = 0
    topBar.Parent = window
    addCorner(topBar, 10)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -16, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = self.Name
    title.TextColor3 = self.Theme.TextColor
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = self.Theme.Font
    title.TextSize = 18
    title.Parent = topBar

    -- Bars
    local pageBar = Instance.new("Frame")
    pageBar.Name = "PageBar"
    pageBar.Size = UDim2.new(0, 170, 1, -36)
    pageBar.Position = UDim2.new(0, 0, 0, 36)
    pageBar.BackgroundColor3 = self.Theme.PanelBg
    pageBar.BorderSizePixel = 0
    pageBar.Parent = window
    addStroke(pageBar, self.Theme.Accent, 1, 0.7)

    local pageList = addListLayout(pageBar, Enum.FillDirection.Vertical, nil, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Begin)
    addPadding(pageBar, 8)

    local sectionArea = Instance.new("Frame")
    sectionArea.Name = "SectionArea"
    sectionArea.Size = UDim2.new(1, -170, 1, -36)
    sectionArea.Position = UDim2.new(0, 170, 0, 36)
    sectionArea.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    sectionArea.BorderSizePixel = 0
    sectionArea.Parent = window
    addPadding(sectionArea, 8)
    addListLayout(sectionArea, Enum.FillDirection.Vertical, nil, 8)

    self.PageBar = pageBar
    self.PageList = pageList
    self.SectionArea = sectionArea

    -- Toggle Icon (draggable + show/hide)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleIcon"
    toggleBtn.AnchorPoint = Vector2.new(1, 1)
    toggleBtn.Size = UDim2.new(0, 44, 0, 44)
    toggleBtn.Position = UDim2.new(1, -16, 1, -16)
    toggleBtn.BackgroundColor3 = self.Theme.Accent
    toggleBtn.Text = "≡"
    toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    toggleBtn.Font = self.Theme.Font
    toggleBtn.TextSize = 20
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = gui
    addCorner(toggleBtn, 12)
    addStroke(toggleBtn, Color3.new(0,0,0), 1, 0.7)
    addScale(toggleBtn, 1)

    -- Drag behavior helpers
    local function makeDraggable(dragHandle, dragTarget)
        dragTarget = dragTarget or dragHandle
        local dragging = false
        local dragStart, startPos

        local function onInputBegan(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = dragTarget.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end

        local function onInputChanged(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                dragTarget.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end

        table.insert(self._connections, dragHandle.InputBegan:Connect(onInputBegan))
        table.insert(self._connections, UserInputService.InputChanged:Connect(onInputChanged))
    end

    makeDraggable(topBar, window)
    makeDraggable(toggleBtn)

    -- Toggle icon hover scale
    toggleBtn.MouseEnter:Connect(function()
        tween(toggleBtn:FindFirstChildOfClass("UIScale"), TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.07}):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        tween(toggleBtn:FindFirstChildOfClass("UIScale"), TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        self.Toggle()
    end)

    -- Effects: blur + zoom
    local function ensureBlur()
        if self._blur and self._blur.Parent then return self._blur end
        local blur = Instance.new("BlurEffect")
        blur.Size = 0
        blur.Enabled = false
        blur.Parent = Lighting
        self._blur = blur
        self._cleanupBlur = true
        return blur
    end

    function self._openEffects(opening)
        local blur = ensureBlur()
        blur.Enabled = true
        local targetSize = opening and 20 or 0
        tween(blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()

        if self._camera then
            local fovTarget = opening and math.clamp((self._cameraDefaultFOV or 70) - 8, 40, 120) or self._cameraDefaultFOV
            tween(self._camera, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = fovTarget}):Play()
        end

        if not opening then
            task.delay(0.27, function()
                if blur then
                    blur.Enabled = false
                    blur.Size = 0
                end
            end)
        end
    end

    -- Public methods (bound later too)
    function self.SetTheme(theme)
        if typeof(theme) == "string" or theme == nil then
            theme = DEFAULT_THEME
        else
            local merged = {}
            for k, v in pairs(DEFAULT_THEME) do merged[k] = v end
            for k, v in pairs(theme) do merged[k] = v end
            theme = merged
        end
        self.Theme = theme

        -- apply to core elements
        window.BackgroundColor3 = theme.WindowBg
        topBar.BackgroundColor3 = theme.PanelBg
        title.TextColor3 = theme.TextColor
        pageBar.BackgroundColor3 = theme.PanelBg
        sectionArea.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
        toggleBtn.BackgroundColor3 = theme.Accent
        toggleBtn.TextColor3 = Color3.fromRGB(0,0,0)

        -- re-tint dynamic elements
        for _, p in ipairs(self._pages) do
            p:_applyTheme()
        end
    end

    function self.Toggle()
        self._open = not self._open
        window.Visible = self._open
        self._openEffects(self._open)
    end

    function self.addNotify(msg)
        local holder = gui:FindFirstChild("NotifyHolder")
        if not holder then
            holder = Instance.new("Frame")
            holder.Name = "NotifyHolder"
            holder.AnchorPoint = Vector2.new(1, 1)
            holder.Size = UDim2.new(0, 320, 1, -20)
            holder.Position = UDim2.new(1, -20, 1, -20)
            holder.BackgroundTransparency = 1
            holder.Parent = gui
            addListLayout(holder, Enum.FillDirection.Vertical, nil, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
        end

        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, 0, 0, 40)
        box.BackgroundColor3 = self.Theme.NotifyBg
        box.BorderSizePixel = 0
        box.Parent = holder
        addCorner(box, 8)
        addStroke(box, self.Theme.Accent, 1, 0.4)
        box.ClipsDescendants = true

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -16, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = self.Theme.Font
        lbl.Text = tostring(msg)
        lbl.TextColor3 = self.Theme.TextColor
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextSize = 16
        lbl.Parent = box

        box.BackgroundTransparency = 1
        lbl.TextTransparency = 1
        tween(box, 0.2, {BackgroundTransparency = 0}):Play()
        tween(lbl, 0.2, {TextTransparency = 0}):Play()

        task.delay(2.5, function()
            if box and box.Parent then
                local tw = tween(box, 0.25, {BackgroundTransparency = 1})
                tween(lbl, 0.25, {TextTransparency = 1}):Play()
                tw.Completed:Connect(function()
                    if box then box:Destroy() end
                end)
                tw:Play()
            end
        end)
    end

    function self.addSelectPage(name)
        for _, p in ipairs(self._pages) do
            if p.Name == name then
                p:Select()
                break
            end
        end
    end

    -- Page creation
    local Page = {}
    Page.__index = Page

    function Page:_applyTheme()
        if self.Button then
            self.Button.BackgroundColor3 = self._ui.Theme.ButtonBg
            self.Button.TextColor3 = self._ui.Theme.TextColor
        end
        if self.Container then
            self.Container.BackgroundColor3 = self._ui.Theme.PanelBg
        end
        -- refresh each section
        for _, s in ipairs(self._sections) do
            s:_applyTheme()
        end
    end

    function Page:Select()
        if self._ui._currentPage == self then return end
        local ui = self._ui

        -- deselect all buttons + hide containers
        for _, p in ipairs(ui._pages) do
            if p.Button and p.Button.Parent then
                tween(p.Button, 0.15, {BackgroundColor3 = ui.Theme.ButtonBg}):Play()
            end
            if p.Container and p.Container.Parent then
                p.Container.Visible = false
            end
        end

        -- select this page
        if self.Button then
            tween(self.Button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = ui.Theme.AccentMuted}):Play()
        end

        if self.Container then
            self.Container.Visible = true
            -- slide-in animation for sections
            for _, s in ipairs(self._sections) do
                if s.Root and s.Root.Parent then
                    s.Root.Position = UDim2.new(0, 20, s.Root.Position.Y.Scale, s.Root.Position.Y.Offset)
                    s.Root.AutoLocalize = false
                    tween(s.Root, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, s.Root.Position.Y.Scale, s.Root.Position.Y.Offset)}):Play()
                end
            end
        end

        ui._currentPage = self
    end

    function Page.addSection(_, name)
        local p = self -- ui table, not page; so we find current? Allow calling via returned Page object only.
        -- placeholder to satisfy API doc; real impl below inside constructor
    end

    function Page.addResize(_, size)
        self.Window.Size = size
    end

    -- Section object
    local Section = {}
    Section.__index = Section

    function Section:_applyTheme()
        if self.Root then
            self.Root.BackgroundColor3 = self._ui.Theme.PanelBg
            local st = self.Root:FindFirstChildOfClass("UIStroke")
            if st then st.Color = self._ui.Theme.SectionStroke end
        end
        -- recolor children text/buttons
        for _, child in ipairs(self.Content:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                child.TextColor3 = self._ui.Theme.TextColor
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = self._ui.Theme.ButtonBg
                end
            end
        end
    end

    function Section:_label(text)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Font = self._ui.Theme.Font
        lbl.Text = text
        lbl.TextColor3 = self._ui.Theme.TextColor
        lbl.TextSize = 16
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(1, 0, 0, 22)
        lbl.Parent = self.Content
        return lbl
    end

    local function hoverBounce(btn, ui)
        btn.MouseEnter:Connect(function()
            tween(btn, 0.12, {BackgroundColor3 = ui.Theme.ButtonHover}):Play()
            local sc = btn:FindFirstChildOfClass("UIScale") or addScale(btn, 1)
            tween(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.04}):Play()
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, 0.12, {BackgroundColor3 = ui.Theme.ButtonBg}):Play()
            local sc = btn:FindFirstChildOfClass("UIScale") or addScale(btn, 1)
            tween(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.0}):Play()
        end)
    end

    function Section:addButton(name, callback)
        local btn = Instance.new("TextButton")
        btn.Name = "Button_" .. name
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = self._ui.Theme.ButtonBg
        btn.AutoButtonColor = false
        btn.Text = name
        btn.TextColor3 = self._ui.Theme.TextColor
        btn.Font = self._ui.Theme.Font
        btn.TextSize = 16
        btn.Parent = self.Content
        addCorner(btn, 8)
        addStroke(btn, Color3.new(0,0,0), 1, 0.85)
        hoverBounce(btn, self._ui)

        btn.MouseButton1Click:Connect(function()
            if typeof(callback) == "function" then
                task.spawn(callback)
            end
        end)
        return btn
    end

    function Section:addToggle(name, default, callback)
        local root = Instance.new("Frame")
        root.Size = UDim2.new(1, 0, 0, 32)
        root.BackgroundTransparency = 1
        root.Parent = self.Content

        local btn = Instance.new("TextButton")
        btn.Name = "Toggle_" .. name
        btn.Size = UDim2.new(1, -60, 1, 0)
        btn.BackgroundColor3 = self._ui.Theme.ButtonBg
        btn.AutoButtonColor = false
        btn.Text = name
        btn.TextColor3 = self._ui.Theme.TextColor
        btn.Font = self._ui.Theme.Font
        btn.TextSize = 16
        btn.Parent = root
        addCorner(btn, 8); addStroke(btn, Color3.new(0,0,0), 1, 0.85)
        hoverBounce(btn, self._ui)

        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.AnchorPoint = Vector2.new(1, 0.5)
        knob.Size = UDim2.new(0, 44, 0, 22)
        knob.Position = UDim2.new(1, 0, 0.5, 0)
        knob.BackgroundColor3 = default and self._ui.Theme.ToggleOn or self._ui.Theme.ToggleOff
        knob.Parent = root
        addCorner(knob, 11)
        addStroke(knob, Color3.new(0,0,0), 1, 0.7)

        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.Size = UDim2.new(0, 18, 0, 18)
        dot.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        dot.AnchorPoint = Vector2.new(0, 0)
        dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
        dot.Parent = knob
        addCorner(dot, 9)

        local state = default and true or false
        local function setState(v)
            state = v
            tween(knob, 0.12, {BackgroundColor3 = v and self._ui.Theme.ToggleOn or self._ui.Theme.ToggleOff}):Play()
            tween(dot, 0.12, {Position = v and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play()
            if typeof(callback) == "function" then task.spawn(callback, state) end
        end

        btn.MouseButton1Click:Connect(function() setState(not state) end)
        knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then setState(not state) end end)

        return setState, function() return state end
    end

    function Section:addTextbox(name, default, callback)
        local root = Instance.new("Frame")
        root.Size = UDim2.new(1, 0, 0, 32)
        root.BackgroundTransparency = 1
        root.Parent = self.Content

        local lbl = self:_label(name)
        lbl.Parent = root
        lbl.Size = UDim2.new(0.4, -8, 1, 0)

        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(0.6, 0, 1, 0)
        tb.Position = UDim2.new(0.4, 8, 0, 0)
        tb.BackgroundColor3 = self._ui.Theme.ButtonBg
        tb.Text = default or ""
        tb.TextColor3 = self._ui.Theme.TextColor
        tb.Font = self._ui.Theme.Font
        tb.TextSize = 16
        tb.ClearTextOnFocus = false
        tb.Parent = root
        addCorner(tb, 8); addStroke(tb, Color3.new(0,0,0), 1, 0.85)

        tb.FocusLost:Connect(function(enter)
            if enter and typeof(callback) == "function" then task.spawn(callback, tb.Text) end
        end)
        return tb
    end

    function Section:addKeybind(name, defaultKey, callback)
        local root = Instance.new("Frame")
        root.Size = UDim2.new(1, 0, 0, 32)
        root.BackgroundTransparency = 1
        root.Parent = self.Content

        local lbl = self:_label(name)
        lbl.Parent = root
        lbl.Size = UDim2.new(0.4, -8, 1, 0)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.6, 0, 1, 0)
        btn.Position = UDim2.new(0.4, 8, 0, 0)
        btn.Text = defaultKey and tostring(defaultKey.Name) or "Unbound"
        btn.TextColor3 = self._ui.Theme.TextColor
        btn.BackgroundColor3 = self._ui.Theme.ButtonBg
        btn.Font = self._ui.Theme.Font
        btn.TextSize = 16
        btn.AutoButtonColor = false
        btn.Parent = root
        addCorner(btn, 8); addStroke(btn, Color3.new(0,0,0), 1, 0.85)
        hoverBounce(btn, self._ui)

        local capturing = false
        local boundKey = defaultKey

        btn.MouseButton1Click:Connect(function()
            capturing = true
            btn.Text = "Press a key..."
        end)

        local conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if capturing and input.UserInputType == Enum.UserInputType.Keyboard then
                boundKey = input.KeyCode
                btn.Text = tostring(boundKey.Name)
                capturing = false
            elseif not capturing and boundKey and input.KeyCode == boundKey then
                if typeof(callback) == "function" then task.spawn(callback, boundKey) end
            end
        end)
        table.insert(self._ui._connections, conn)
        return function(k)
            boundKey = k
            btn.Text = k and tostring(k.Name) or "Unbound"
        end
    end

    function Section:addColorPicker(name, default, callback)
        local root = Instance.new("Frame")
        root.Size = UDim2.new(1, 0, 0, 64)
        root.BackgroundTransparency = 1
        root.Parent = self.Content

        local lbl = self:_label(name)
        lbl.Parent = root
        lbl.Size = UDim2.new(0.4, -8, 0, 22)

        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(0.6, 0, 1, 0)
        panel.Position = UDim2.new(0.4, 8, 0, 0)
        panel.BackgroundColor3 = self._ui.Theme.ButtonBg
        panel.Parent = root
        addCorner(panel, 8); addStroke(panel, Color3.new(0,0,0), 1, 0.85)
        addPadding(panel, 8)

        -- Simple RGB sliders (compact and reliable)
        local current = default or Color3.new(1, 1, 0)
        local function sliderRow(labelText, initial, onChange)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 18)
            row.BackgroundTransparency = 1
            row.Parent = panel

            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(0, 16, 1, 0)
            tl.BackgroundTransparency = 1
            tl.Text = labelText
            tl.TextColor3 = self._ui.Theme.TextColor
            tl.Font = self._ui.Theme.Font
            tl.TextSize = 14
            tl.Parent = row

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -48, 0, 6)
            track.Position = UDim2.new(0, 22, 0.5, -3)
            track.BackgroundColor3 = self._ui.Theme.SliderTrack
            track.Parent = row
            addCorner(track, 3)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(initial, 0, 1, 0)
            fill.BackgroundColor3 = self._ui.Theme.SliderFill
            fill.Parent = track
            addCorner(fill, 3)

            local dragging = false
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            track.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    onChange(rel)
                end
            end)
            return {track = track, fill = fill}
        end

        local r,g,b = current.R, current.G, current.B
        sliderRow("R", r, function(v) r = v; current = Color3.new(r,g,b); if callback then task.spawn(callback, current) end end)
        sliderRow("G", g, function(v) g = v; current = Color3.new(r,g,b); if callback then task.spawn(callback, current) end end)
        sliderRow("B", b, function(v) b = v; current = Color3.new(r,g,b); if callback then task.spawn(callback, current) end end)

        -- Preview swatch
        local swatch = Instance.new("Frame")
        swatch.Size = UDim2.new(0, 24, 0, 24)
        swatch.Position = UDim2.new(1, -28, 0, 6)
        swatch.BackgroundColor3 = current
        swatch.Parent = panel
        addCorner(swatch, 6)
        addStroke(swatch, Color3.new(0,0,0), 1, 0.75)

        -- Update swatch when sliders move
        local function updateSwatch()
            swatch.BackgroundColor3 = current
        end
        panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSwatch)
        task.spawn(function()
            while swatch.Parent do
                updateSwatch()
                RunService.RenderStepped:Wait()
            end
        end)

        return function(c)
            current = c
            r,g,b = c.R, c.G, c.B
            swatch.BackgroundColor3 = c
            if callback then task.spawn(callback, current) end
        end
    end

    function Section:addSlider(name, min, max, default, callback)
        min, max = tonumber(min) or 0, tonumber(max) or 100
        default = tonumber(default) or min
        local value = math.clamp(default, min, max)

        local root = Instance.new("Frame")
        root.Size = UDim2.new(1, 0, 0, 40)
        root.BackgroundTransparency = 1
        root.Parent = self.Content

        local lbl = self:_label(name .. " (" .. tostring(value) .. ")")
        lbl.Parent = root
        lbl.Size = UDim2.new(1, 0, 0, 20)

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 8)
        track.Position = UDim2.new(0, 0, 0, 24)
        track.BackgroundColor3 = self._ui.Theme.SliderTrack
        track.Parent = root
        addCorner(track, 4)

        local fill = Instance.new("Frame")
        local rel = (value - min) / (max - min)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        fill.BackgroundColor3 = self._ui.Theme.SliderFill
        fill.Parent = track
        addCorner(fill, 4)

        local dragging = false
        local function setValueFromX(x)
            local relative = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor((min + relative * (max - min)) + 0.5)
            fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
            lbl.Text = name .. " (" .. tostring(value) .. ")"
            if callback then task.spawn(callback, value) end
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                setValueFromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                setValueFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        return function(v)
            value = math.clamp(v, min, max)
            fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
            lbl.Text = name .. " (" .. tostring(value) .. ")"
            if callback then task.spawn(callback, value) end
        end
    end

    function Section:addDropdown(name, options, default, callback)
        options = options or {}
        local current = default or options[1]

        local root = Instance.new("Frame")
        root.Size = UDim2.new(1, 0, 0, 34)
        root.BackgroundTransparency = 1
        root.Parent = self.Content

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = self._ui.Theme.ButtonBg
        btn.Text = string.format("%s: %s", name, tostring(current or "None"))
        btn.TextColor3 = self._ui.Theme.TextColor
        btn.Font = self._ui.Theme.Font
        btn.TextSize = 16
        btn.AutoButtonColor = false
        btn.Parent = root
        addCorner(btn, 8); addStroke(btn, Color3.new(0,0,0), 1, 0.85)
        hoverBounce(btn, self._ui)

        local open = false
        local listFrame = Instance.new("Frame")
        listFrame.Visible = false
        listFrame.Size = UDim2.new(1, 0, 0, math.min(#options, 5) * 28 + 8)
        listFrame.Position = UDim2.new(0, 0, 1, 6)
        listFrame.BackgroundColor3 = self._ui.Theme.DropdownBg
        listFrame.Parent = root
        addCorner(listFrame, 8); addStroke(listFrame, Color3.new(0,0,0), 1, 0.7)
        addPadding(listFrame, 6)
        addListLayout(listFrame, Enum.FillDirection.Vertical, nil, 6)

        local function setCurrent(v)
            current = v
            btn.Text = string.format("%s: %s", name, tostring(current))
            if callback then task.spawn(callback, current) end
        end

        local function rebuild()
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(options) do
                local o = Instance.new("TextButton")
                o.Size = UDim2.new(1, 0, 0, 24)
                o.BackgroundColor3 = self._ui.Theme.ButtonBg
                o.Text = tostring(opt)
                o.TextColor3 = self._ui.Theme.TextColor
                o.Font = self._ui.Theme.Font
                o.TextSize = 14
                o.AutoButtonColor = false
                o.Parent = listFrame
                addCorner(o, 6)
                hoverBounce(o, self._ui)
                o.MouseButton1Click:Connect(function()
                    setCurrent(opt)
                    open = false; listFrame.Visible = false
                end)
            end
        end
        rebuild()

        btn.MouseButton1Click:Connect(function()
            open = not open
            listFrame.Visible = open
        end)

        return {
            Set = setCurrent,
            SetOptions = function(new)
                options = new or {}
                rebuild()
            end,
            Get = function() return current end
        }
    end

    function Section:Resize(size)
        self.Root.Size = size
    end

    -- Build Page constructor
    local function newPage(ui, name)
        local p = setmetatable({}, Page)
        p._ui = ui
        p.Name = name
        p._sections = {}

        -- Page button in bar
        local btn = Instance.new("TextButton")
        btn.Name = "Page_" .. name
        btn.Size = UDim2.new(1, -8, 0, 32)
        btn.BackgroundColor3 = ui.Theme.ButtonBg
        btn.AutoButtonColor = false
        btn.Text = name
        btn.TextColor3 = ui.Theme.TextColor
        btn.Font = ui.Theme.Font
        btn.TextSize = 16
        btn.Parent = ui.PageBar
        addCorner(btn, 8)
        addStroke(btn, Color3.new(0,0,0), 1, 0.85)
        addScale(btn, 1)

        -- Hover: bounce + color change
        btn.MouseEnter:Connect(function()
            tween(btn, 0.12, {BackgroundColor3 = ui.Theme.PageHover}):Play()
            local sc = btn:FindFirstChildOfClass("UIScale") or addScale(btn, 1)
            tween(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.05}):Play()
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, 0.12, {BackgroundColor3 = ui.Theme.ButtonBg}):Play()
            local sc = btn:FindFirstChildOfClass("UIScale") or addScale(btn, 1)
            tween(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.0}):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            p:Select()
        end)
        p.Button = btn

        -- Content container
        local container = Instance.new("Frame")
        container.Name = "PageContainer_" .. name
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundColor3 = ui.Theme.PanelBg
        container.BorderSizePixel = 0
        container.Visible = false
        container.Parent = ui.SectionArea
        addCorner(container, 8)
        addPadding(container, 6)
        addListLayout(container, Enum.FillDirection.Vertical, nil, 8)
        p.Container = container

        -- Section API methods
        function p.addSection(_, sname)
            local s = setmetatable({}, Section)
            s._ui = ui
            s.Page = p

            local root = Instance.new("Frame")
            root.Name = "Section_" .. sname
            root.Size = UDim2.new(1, 0, 0, 160)
            root.BackgroundColor3 = ui.Theme.PanelBg
            root.Parent = container
            addCorner(root, 10)
            addStroke(root, ui.Theme.SectionStroke, 1, 0.65)
            addPadding(root, 8)

            local head = Instance.new("TextLabel")
            head.Name = "Header"
            head.Size = UDim2.new(1, 0, 0, 20)
            head.BackgroundTransparency = 1
            head.Text = sname
            head.TextColor3 = ui.Theme.TextColor
            head.Font = ui.Theme.Font
            head.TextSize = 16
            head.TextXAlignment = Enum.TextXAlignment.Left
            head.Parent = root

            local content = Instance.new("Frame")
            content.Name = "Content"
            content.Size = UDim2.new(1, 0, 1, -24)
            content.Position = UDim2.new(0, 0, 0, 24)
            content.BackgroundTransparency = 1
            content.Parent = root
            addListLayout(content, Enum.FillDirection.Vertical, nil, 6)

            s.Root = root
            s.Content = content

            function s:_applyTheme() Section._applyTheme(self) end

            table.insert(p._sections, s)
            return s
        end

        function p.addResize(_, size)
            ui.Window.Size = size
        end

        function p:_applyTheme() Page._applyTheme(self) end

        table.insert(ui._pages, p)
        ui._pageByName[name] = p
        return p
    end

    -- Public API on UI: addPage
    function self.addPage(name)
        return newPage(self, name)
    end

    -- Theme init
    self.SetTheme(self.Theme)

    -- Return public API table (stable methods)
    local api = {}

    function api.addPage(...) return self.addPage(...) end
    function api.addNotify(...) return self.addNotify(...) end
    function api.addSelectPage(...) return self.addSelectPage(...) end
    function api.SetTheme(...) return self.SetTheme(...) end
    function api.Toggle(...) return self.Toggle(...) end

    -- Expose for Page+Section methods via returned objects
    return api
end

-- Export
return { new = Xinexin.new }
