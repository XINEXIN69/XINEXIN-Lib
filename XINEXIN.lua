-- XINEXIN HUB - Minimal / Flat UI Library for Roblox
-- Author: You
-- License: MIT
-- API:
--   local UIlib = require(...) or loadstring(...)
--   local UI = UIlib.new(titleString)
--   UI.addPage(name) -> Page
--   UI.addNotify(message)
--   UI.addSelectPage(name)
--   UI.SetTheme(themeStringOrTable)
--   UI.Toggle()
-- Page:
--   Page.addSection(name) -> Section
--   Page.addResize(sizeUDim2)
-- Section:
--   Section:addButton(name, callback)
--   Section:addToggle(name, defaultBool, callback)
--   Section:addTextbox(name, defaultText, callback)
--   Section:addKeybind(name, defaultKeyCode, callback)
--   Section:addColorPicker(name, defaultColor3, callback)
--   Section:addSlider(name, minNumber, maxNumber, defaultNumber, callback)
--   Section:addDropdown(name, optionsArray, defaultString, callback)
--   Section:Resize(sizeUDim2)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local UIlib = {}
UIlib.__index = UIlib

-- Defaults and theme
local DEFAULT_TITLE = "XINEXIN HUB"
local THEMES = {
    ["Dark Yellow Premium"] = {
        Background = Color3.fromRGB(18, 18, 18),
        Primary = Color3.fromRGB(22, 22, 22),
        Accent = Color3.fromRGB(241, 196, 15),
        AccentDark = Color3.fromRGB(213, 166, 0),
        Text = Color3.fromRGB(255, 255, 255),
        Muted = Color3.fromRGB(130, 130, 130),
        Hover = Color3.fromRGB(35, 35, 35),
        PageIdle = Color3.fromRGB(28, 28, 28),
        PageHover = Color3.fromRGB(45, 45, 45),
        Shadow = Color3.fromRGB(0, 0, 0)
    }
}

-- Utility: UICorner helper
local function addCorner(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = instance
    return c
end

-- Utility: UIStroke helper
local function addStroke(instance, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = instance
    return s
end

-- Utility: Hover bounce
local function bounce(instance)
    local orig = instance.Position
    local tw1 = TweenService:Create(instance, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = orig - UDim2.new(0, 0, 0, 2)})
    local tw2 = TweenService:Create(instance, TweenInfo.new(0.12, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Position = orig})
    tw1:Play()
    tw1.Completed:Connect(function()
        tw2:Play()
    end)
end

-- Utility: drag handler
local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragStart, startPos
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
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not dragging then
                    if connection then connection:Disconnect() end
                    return
                end
                local delta = UserInputService:GetMouseLocation() - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end)
        end
    end)
end

-- Utility: blur+zoom
local function ensureBlur()
    local blur = Lighting:FindFirstChild("XINEXIN_BLUR")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "XINEXIN_BLUR"
        blur.Enabled = false
        blur.Size = 0
        blur.Parent = Lighting
    end
    return blur
end

-- Utility: create text label
local function makeText(parent, text, theme, size, bold)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text = text or ""
    lbl.TextColor3 = theme.Text
    lbl.Font = Enum.Font.Arcade
    lbl.TextSize = size or 16
    lbl.RichText = false
    lbl.Parent = parent
    return lbl
end

-- Utility: tween color on hover
local function hoverColorize(button, idleColor, hoverColor)
    button.BackgroundColor3 = idleColor
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
        bounce(button)
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = idleColor}):Play()
    end)
end

-- Constructor
function UIlib.new(title)
    title = title or DEFAULT_TITLE
    local self = setmetatable({}, UIlib)

    -- Theme state
    self.Theme = THEMES["Dark Yellow Premium"]

    -- ScreenGui
    local screen = Instance.new("ScreenGui")
    screen.Name = "XINEXIN_UI"
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.Parent = game:GetService("CoreGui")

    -- UIScale for zoom-in
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0.95
    uiScale.Parent = screen

    -- Toggle icon
    local toggleIcon = Instance.new("TextButton")
    toggleIcon.Name = "ToggleIcon"
    toggleIcon.Size = UDim2.new(0, 34, 0, 34)
    toggleIcon.Position = UDim2.new(0, 20, 0.5, 0)
    toggleIcon.BackgroundColor3 = self.Theme.Accent
    toggleIcon.Text = "≡"
    toggleIcon.TextColor3 = Color3.fromRGB(0, 0, 0)
    toggleIcon.Font = Enum.Font.Arcade
    toggleIcon.TextSize = 18
    addCorner(toggleIcon, 8)
    addStroke(toggleIcon, self.Theme.AccentDark, 1, 0.2)
    toggleIcon.Parent = screen
    makeDraggable(toggleIcon)

    -- Main window
    local main = Instance.new("Frame")
    main.Name = "Window"
    main.Size = UDim2.new(0, 735, 0, 379)
    main.Position = UDim2.new(0.26607, 0, 0.26773, 0)
    main.BackgroundColor3 = self.Theme.Background
    addCorner(main, 10)
    addStroke(main, self.Theme.Shadow, 1, 0.8)
    main.Parent = screen

    -- Shadow (subtle)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24, 24, 276, 276)
    shadow.Size = UDim2.new(1, 24, 1, 24)
    shadow.Position = UDim2.new(0, -12, 0, -8)
    shadow.ZIndex = 0
    shadow.Parent = main

    -- Top bar
    local topbar = Instance.new("Frame")
    topbar.Name = "TopBar"
    topbar.Size = UDim2.new(1, 0, 0, 40)
    topbar.BackgroundColor3 = self.Theme.Primary
    addCorner(topbar, 10)
    topbar.Parent = main

    local titleLbl = makeText(topbar, title, self.Theme, 18, true)
    titleLbl.Size = UDim2.new(1, -20, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Page bar
    local pagebar = Instance.new("Frame")
    pagebar.Name = "PageBar"
    pagebar.Size = UDim2.new(0, 180, 1, -40)
    pagebar.Position = UDim2.new(0, 0, 0, 40)
    pagebar.BackgroundColor3 = self.Theme.Primary
    addCorner(pagebar, 10)
    pagebar.Parent = main

    local pageList = Instance.new("UIListLayout")
    pageList.Padding = UDim.new(0, 6)
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    pageList.VerticalAlignment = Enum.VerticalAlignment.Top
    pageList.Parent = pagebar

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingTop = UDim.new(0, 10)
    pagePad.PaddingLeft = UDim.new(0, 10)
    pagePad.PaddingRight = UDim.new(0, 10)
    pagePad.Parent = pagebar

    -- Section area
    local sectionArea = Instance.new("Frame")
    sectionArea.Name = "SectionArea"
    sectionArea.Size = UDim2.new(1, -200, 1, -50)
    sectionArea.Position = UDim2.new(0, 190, 0, 45)
    sectionArea.BackgroundColor3 = self.Theme.Primary
    addCorner(sectionArea, 10)
    sectionArea.Parent = main

    local sectionContainer = Instance.new("Frame")
    sectionContainer.Name = "Pages"
    sectionContainer.BackgroundTransparency = 1
    sectionContainer.Size = UDim2.new(1, -16, 1, -16)
    sectionContainer.Position = UDim2.new(0, 8, 0, 8)
    sectionContainer.Parent = sectionArea

    -- Layout of pages (stack but only 1 visible)
    local pagesFolder = Instance.new("Folder")
    pagesFolder.Name = "PageStorage"
    pagesFolder.Parent = sectionContainer

    -- State
    self._screen = screen
    self._main = main
    self._toggleIcon = toggleIcon
    self._uiScale = uiScale
    self._topbar = topbar
    self._pagebar = pagebar
    self._sectionArea = sectionArea
    self._pagesFolder = pagesFolder
    self._pageButtons = {}
    self._pages = {}
    self._selected = nil
    self._blur = ensureBlur()
    self._visible = true

    -- Drag window
    makeDraggable(main, topbar)

    -- Toggle logic
    toggleIcon.MouseButton1Click:Connect(function()
        self.Toggle()
    end)

    -- Open with blur + zoom
    local function openAnim()
        self._blur.Enabled = true
        TweenService:Create(self._blur, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = 18}):Play()
        TweenService:Create(uiScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
        main.Visible = true
        toggleIcon.BackgroundColor3 = self.Theme.Accent
    end
    local function closeAnim()
        TweenService:Create(self._blur, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = 0}):Play()
        task.delay(0.2, function()
            self._blur.Enabled = false
        end)
        TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.96}):Play()
        main.Visible = false
        toggleIcon.BackgroundColor3 = self.Theme.AccentDark
    end

    function self.Toggle()
        self._visible = not self._visible
        if self._visible then openAnim() else closeAnim() end
    end

    -- Notifications container
    local notifyContainer = Instance.new("Frame")
    notifyContainer.Name = "Notifications"
    notifyContainer.AnchorPoint = Vector2.new(1, 0)
    notifyContainer.Position = UDim2.new(1, -14, 0, 14)
    notifyContainer.Size = UDim2.new(0, 280, 1, -28)
    notifyContainer.BackgroundTransparency = 1
    notifyContainer.Parent = screen

    local notifyList = Instance.new("UIListLayout")
    notifyList.SortOrder = Enum.SortOrder.LayoutOrder
    notifyList.Padding = UDim.new(0, 8)
    notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifyList.Parent = notifyContainer

    -- API: addNotify
    function self.addNotify(message)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 280, 0, 46)
        card.BackgroundColor3 = self.Theme.Primary
        card.BackgroundTransparency = 0.05
        card.AnchorPoint = Vector2.new(1, 0)
        addCorner(card, 8)
        addStroke(card, self.Theme.Accent, 1, 0.5)
        card.Parent = notifyContainer

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 4, 1, 0)
        bar.Position = UDim2.new(0, 0, 0, 0)
        bar.BackgroundColor3 = self.Theme.Accent
        addCorner(bar, 4)
        bar.Parent = card

        local txt = makeText(card, tostring(message), self.Theme, 16, true)
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.Position = UDim2.new(0, 10, 0, 0)
        txt.Size = UDim2.new(1, -20, 1, 0)

        card.BackgroundTransparency = 1
        txt.TextTransparency = 1
        bar.Size = UDim2.new(0, 0, 1, 0)

        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
        TweenService:Create(txt, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        TweenService:Create(bar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 6, 1, 0)}):Play()

        task.delay(2.2, function()
            local t1 = TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            local t2 = TweenService:Create(txt, TweenInfo.new(0.2), {TextTransparency = 1})
            local t3 = TweenService:Create(bar, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 1, 0)})
            t1:Play(); t2:Play(); t3:Play()
            t1.Completed:Connect(function()
                card:Destroy()
            end)
        end)
    end

    -- API: SetTheme
    function self.SetTheme(t)
        if type(t) == "string" then
            local found = THEMES[t]
            if found then self.Theme = found end
        elseif type(t) == "table" then
            self.Theme = t
        end
        -- Apply key surfaces
        topbar.BackgroundColor3 = self.Theme.Primary
        pagebar.BackgroundColor3 = self.Theme.Primary
        sectionArea.BackgroundColor3 = self.Theme.Primary
        main.BackgroundColor3 = self.Theme.Background
        titleLbl.TextColor3 = self.Theme.Text
        toggleIcon.BackgroundColor3 = self._visible and self.Theme.Accent or self.Theme.AccentDark
    end

    -- API: addPage
    function self.addPage(name)
        name = tostring(name or "Page")
        local pageButton = Instance.new("TextButton")
        pageButton.Name = "Page_" .. name
        pageButton.Size = UDim2.new(1, -20, 0, 34)
        pageButton.BackgroundColor3 = self.Theme.PageIdle
        pageButton.Text = name
        pageButton.TextColor3 = self.Theme.Text
        pageButton.TextSize = 16
        pageButton.Font = Enum.Font.Arcade
        pageButton.AutoButtonColor = false
        addCorner(pageButton, 8)
        addStroke(pageButton, self.Theme.Shadow, 1, 0.85)
        pageButton.Parent = pagebar
        hoverColorize(pageButton, self.Theme.PageIdle, self.Theme.PageHover)

        local pageFrame = Instance.new("Frame")
        pageFrame.Name = "PageFrame_" .. name
        pageFrame.BackgroundTransparency = 1
        pageFrame.Visible = false
        pageFrame.Size = UDim2.new(1, 0, 1, 0)
        pageFrame.Parent = pagesFolder

        local pageScroll = Instance.new("ScrollingFrame")
        pageScroll.Name = "SectionScroll"
        pageScroll.BackgroundTransparency = 1
        pageScroll.BorderSizePixel = 0
        pageScroll.ScrollBarThickness = 6
        pageScroll.ScrollBarImageColor3 = self.Theme.Accent
        pageScroll.Size = UDim2.new(1, 0, 1, 0)
        pageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        pageScroll.Parent = pageFrame

        local sectionList = Instance.new("UIListLayout")
        sectionList.Padding = UDim.new(0, 10)
        sectionList.SortOrder = Enum.SortOrder.LayoutOrder
        sectionList.Parent = pageScroll

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.Parent = pageScroll

        sectionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            pageScroll.CanvasSize = UDim2.new(0, 0, 0, sectionList.AbsoluteContentSize.Y + 20)
        end)

        local Page = {}
        Page._name = name
        Page._button = pageButton
        Page._frame = pageFrame
        Page._scroll = pageScroll
        Page._sections = {}

        function Page.addResize(size)
            pageScroll.Size = size
        end

        -- Select logic
        pageButton.MouseButton1Click:Connect(function()
            self.addSelectPage(name)
        end)

        -- API: addSection
        function Page.addSection(sectionName)
            sectionName = tostring(sectionName or "Section")
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Name = "Section_" .. sectionName
            sectionFrame.Size = UDim2.new(1, -10, 0, 56)
            sectionFrame.BackgroundColor3 = self.Theme.Background
            addCorner(sectionFrame, 8)
            addStroke(sectionFrame, self.Theme.Shadow, 1, 0.85)
            sectionFrame.Parent = pageScroll

            local header = makeText(sectionFrame, sectionName, self.Theme, 16, true)
            header.Size = UDim2.new(1, -20, 0, 22)
            header.Position = UDim2.new(0, 10, 0, 6)
            header.TextXAlignment = Enum.TextXAlignment.Left

            local content = Instance.new("Frame")
            content.Name = "Content"
            content.BackgroundTransparency = 1
            content.Size = UDim2.new(1, -20, 1, -32)
            content.Position = UDim2.new(0, 10, 0, 28)
            content.Parent = sectionFrame

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 6)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = content

            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sectionFrame.Size = UDim2.new(1, -10, 0, math.max(56, layout.AbsoluteContentSize.Y + 38))
            end)

            -- Helper control factory
            local function baseControl(height)
                local holder = Instance.new("Frame")
                holder.BackgroundColor3 = self.Theme.Primary
                holder.Size = UDim2.new(1, 0, 0, height)
                addCorner(holder, 6)
                addStroke(holder, self.Theme.Shadow, 1, 0.85)
                holder.Parent = content
                return holder
            end

            local Section = {}
            Section._frame = sectionFrame
            Section._content = content

            function Section:Resize(size)
                sectionFrame.Size = size
            end

            -- Button
            function Section:addButton(text, callback)
                local holder = baseControl(34)
                local btn = Instance.new("TextButton")
                btn.BackgroundTransparency = 1
                btn.Size = UDim2.new(1, -14, 1, 0)
                btn.Position = UDim2.new(0, 7, 0, 0)
                btn.Text = tostring(text or "Button")
                btn.TextColor3 = self.Theme.Text
                btn.Font = Enum.Font.Arcade
                btn.TextSize = 16
                btn.AutoButtonColor = false
                btn.Parent = holder
                hoverColorize(holder, self.Theme.Primary, self.Theme.Hover)
                btn.MouseButton1Click:Connect(function()
                    if callback then
                        task.spawn(callback)
                    end
                end)
                return btn
            end

            -- Toggle
            function Section:addToggle(text, default, callback)
                default = default == true
                local holder = baseControl(34)
                hoverColorize(holder, self.Theme.Primary, self.Theme.Hover)

                local lbl = makeText(holder, tostring(text or "Toggle"), self.Theme, 16, true)
                lbl.Size = UDim2.new(1, -60, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local tgl = Instance.new("TextButton")
                tgl.Size = UDim2.new(0, 40, 0, 22)
                tgl.Position = UDim2.new(1, -50, 0.5, -11)
                tgl.BackgroundColor3 = default and self.Theme.Accent or self.Theme.PageIdle
                tgl.Text = ""
                addCorner(tgl, 22)
                addStroke(tgl, self.Theme.Shadow, 1, 0.85)
                tgl.Parent = holder

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 18, 0, 18)
                dot.Position = UDim2.new(default and 1 or 0, default and -20 or 2, 0.5, -9)
                dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                addCorner(dot, 18)
                dot.Parent = tgl

                local state = default
                local function setState(v)
                    state = v
                    TweenService:Create(tgl, TweenInfo.new(0.15), {BackgroundColor3 = v and self.Theme.Accent or self.Theme.PageIdle}):Play()
                    TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(v and 1 or 0, v and -20 or 2, 0.5, -9)}):Play()
                    if callback then task.spawn(callback, state) end
                end

                tgl.MouseButton1Click:Connect(function() setState(not state) end)
                return function(v) setState(v) end
            end

            -- Textbox
            function Section:addTextbox(text, default, callback)
                local holder = baseControl(34)
                hoverColorize(holder, self.Theme.Primary, self.Theme.Hover)

                local lbl = makeText(holder, tostring(text or "Textbox"), self.Theme, 16, true)
                lbl.Size = UDim2.new(1, -180, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local tb = Instance.new("TextBox")
                tb.Size = UDim2.new(0, 160, 0, 26)
                tb.Position = UDim2.new(1, -170, 0.5, -13)
                tb.BackgroundColor3 = self.Theme.PageIdle
                tb.Text = tostring(default or "")
                tb.TextColor3 = self.Theme.Text
                tb.PlaceholderText = ""
                tb.Font = Enum.Font.Arcade
                tb.TextSize = 16
                addCorner(tb, 6)
                addStroke(tb, self.Theme.Shadow, 1, 0.85)
                tb.Parent = holder

                tb.FocusLost:Connect(function(enterPressed)
                    if callback then task.spawn(callback, tb.Text) end
                end)
                return tb
            end

            -- Keybind
            function Section:addKeybind(text, defaultKey, callback)
                local holder = baseControl(34)
                hoverColorize(holder, self.Theme.Primary, self.Theme.Hover)

                local lbl = makeText(holder, tostring(text or "Keybind"), self.Theme, 16, true)
                lbl.Size = UDim2.new(1, -180, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 120, 0, 26)
                btn.Position = UDim2.new(1, -130, 0.5, -13)
                btn.BackgroundColor3 = self.Theme.PageIdle
                btn.Text = defaultKey and defaultKey.Name or "None"
                btn.TextColor3 = self.Theme.Text
                btn.Font = Enum.Font.Arcade
                btn.TextSize = 16
                addCorner(btn, 6)
                addStroke(btn, self.Theme.Shadow, 1, 0.85)
                btn.Parent = holder

                local capturing = false
                local current = defaultKey

                btn.MouseButton1Click:Connect(function()
                    capturing = true
                    btn.Text = "Press..."
                    btn.BackgroundColor3 = self.Theme.PageHover
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if capturing and input.UserInputType == Enum.UserInputType.Keyboard then
                        capturing = false
                        current = input.KeyCode
                        btn.Text = current.Name
                        btn.BackgroundColor3 = self.Theme.PageIdle
                    elseif not capturing and current and input.KeyCode == current then
                        if callback then task.spawn(callback, current) end
                    end
                end)

                return function(newKey)
                    current = newKey
                    btn.Text = newKey and newKey.Name or "None"
                end
            end

            -- Color Picker (simple hue bar)
            function Section:addColorPicker(text, default, callback)
                local holder = baseControl(48)
                hoverColorize(holder, self.Theme.Primary, self.Theme.Hover)

                local lbl = makeText(holder, tostring(text or "Color"), self.Theme, 16, true)
                lbl.Size = UDim2.new(1, -180, 0, 20)
                lbl.Position = UDim2.new(0, 10, 0, 4)
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local preview = Instance.new("Frame")
                preview.Size = UDim2.new(0, 26, 0, 26)
                preview.Position = UDim2.new(1, -36, 0, 6)
                preview.BackgroundColor3 = default or Color3.fromRGB(241, 196, 15)
                addCorner(preview, 6)
                addStroke(preview, self.Theme.Shadow, 1, 0.85)
                preview.Parent = holder

                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(1, -80, 0, 14)
                bar.Position = UDim2.new(0, 10, 0, 26)
                bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                addCorner(bar, 6)
                addStroke(bar, self.Theme.Shadow, 1, 0.85)
                bar.Parent = holder

                local uiGradient = Instance.new("UIGradient")
                uiGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0, 1, 1)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1, 1, 1)),
                }
                uiGradient.Rotation = 0
                uiGradient.Parent = bar

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 6, 1, 0)
                knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                knob.Parent = bar

                addCorner(knob, 3)

                local hue = 0
                local function setHueFromX(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    hue = rel
                    local c = Color3.fromHSV(hue, 1, 1)
                    preview.BackgroundColor3 = c
                    knob.Position = UDim2.new(rel, -3, 0, 0)
                    if callback then task.spawn(callback, c) end
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setHueFromX(UserInputService:GetMouseLocation().X)
                        local moveConn, upConn
                        moveConn = UserInputService.InputChanged:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseMovement then
                                setHueFromX(UserInputService:GetMouseLocation().X)
                            end
                        end)
                        upConn = UserInputService.InputEnded:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                                if moveConn then moveConn:Disconnect() end
                                if upConn then upConn:Disconnect() end
                            end
                        end)
                    end
                end)

                if default then
                    local h, s, v = default:ToHSV()
                    hue = h
                    preview.BackgroundColor3 = default
                    knob.Position = UDim2.new(h, -3, 0, 0)
                end

                return function(c3)
                    local h, s, v = c3:ToHSV()
                    hue = h
                    preview.BackgroundColor3 = c3
                    knob.Position = UDim2.new(h, -3, 0, 0)
                    if callback then task.spawn(callback, c3) end
                end
            end

            -- Slider
            function Section:addSlider(text, min, max, default, callback)
                min = tonumber(min) or 0
                max = tonumber(max) or 100
                default = math.clamp(tonumber(default) or min, min, max)

                local holder = baseControl(48)
                hoverColorize(holder, self.Theme.Primary, self.Theme.Hover)

                local lbl = makeText(holder, tostring(text or "Slider"), self.Theme, 16, true)
                lbl.Size = UDim2.new(1, -80, 0, 20)
                lbl.Position = UDim2.new(0, 10, 0, 4)
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local valueLbl = makeText(holder, tostring(default), self.Theme, 14, true)
                valueLbl.Size = UDim2.new(0, 80, 0, 20)
                valueLbl.Position = UDim2.new(1, -80, 0, 4)
                valueLbl.TextXAlignment = Enum.TextXAlignment.Right

                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(1, -20, 0, 12)
                bar.Position = UDim2.new(0, 10, 0, 28)
                bar.BackgroundColor3 = self.Theme.PageIdle
                addCorner(bar, 6)
                addStroke(bar, self.Theme.Shadow, 1, 0.85)
                bar.Parent = holder

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                fill.BackgroundColor3 = self.Theme.Accent
                addCorner(fill, 6)
                fill.Parent = bar

                local function setFromX(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    local val = math.floor(min + (max - min) * rel + 0.5)
                    valueLbl.Text = tostring(val)
                    TweenService:Create(fill, TweenInfo.new(0.06), {Size = UDim2.new(rel, 0, 1, 0)}):Play()
                    if callback then task.spawn(callback, val) end
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setFromX(UserInputService:GetMouseLocation().X)
                        local moveConn, upConn
                        moveConn = UserInputService.InputChanged:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseMovement then
                                setFromX(UserInputService:GetMouseLocation().X)
                            end
                        end)
                        upConn = UserInputService.InputEnded:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                                if moveConn then moveConn:Disconnect() end
                                if upConn then upConn:Disconnect() end
                            end
                        end)
                    end
                end)

                return function(val)
                    val = math.clamp(tonumber(val) or default, min, max)
                    local rel = (val - min) / (max - min)
                    valueLbl.Text = tostring(val)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    if callback then task.spawn(callback, val) end
                end
            end

            -- Dropdown
            function Section:addDropdown(text, options, default, callback)
                options = options or {}
                local holder = baseControl(34)
                hoverColorize(holder, self.Theme.Primary, self.Theme.Hover)

                local lbl = makeText(holder, tostring(text or "Dropdown"), self.Theme, 16, true)
                lbl.Size = UDim2.new(1, -180, 1, 0)
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 160, 0, 26)
                btn.Position = UDim2.new(1, -170, 0.5, -13)
                btn.BackgroundColor3 = self.Theme.PageIdle
                btn.Text = tostring(default or "Select")
                btn.TextColor3 = self.Theme.Text
                btn.Font = Enum.Font.Arcade
                btn.TextSize = 16
                btn.AutoButtonColor = false
                addCorner(btn, 6)
                addStroke(btn, self.Theme.Shadow, 1, 0.85)
                btn.Parent = holder

                local open = false
                local listFrame = Instance.new("Frame")
                listFrame.Visible = false
                listFrame.Size = UDim2.new(0, 160, 0, 120)
                listFrame.Position = UDim2.new(1, -170, 1, 6)
                listFrame.BackgroundColor3 = self.Theme.Primary
                addCorner(listFrame, 6)
                addStroke(listFrame, self.Theme.Shadow, 1, 0.85)
                listFrame.Parent = holder

                local sf = Instance.new("ScrollingFrame")
                sf.BackgroundTransparency = 1
                sf.Size = UDim2.new(1, 0, 1, 0)
                sf.CanvasSize = UDim2.new(0, 0, 0, 0)
                sf.ScrollBarThickness = 6
                sf.ScrollBarImageColor3 = self.Theme.Accent
                sf.Parent = listFrame

                local list = Instance.new("UIListLayout")
                list.Padding = UDim.new(0, 4)
                list.Parent = sf

                list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    sf.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 6)
                end)

                local function setChoice(choice)
                    btn.Text = tostring(choice)
                    if callback then task.spawn(callback, choice) end
                end

                local function refreshOptions()
                    for _, child in ipairs(sf:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local o = Instance.new("TextButton")
                        o.Size = UDim2.new(1, -8, 0, 26)
                        o.Position = UDim2.new(0, 4, 0, 0)
                        o.BackgroundColor3 = self.Theme.PageIdle
                        o.Text = tostring(opt)
                        o.TextColor3 = self.Theme.Text
                        o.Font = Enum.Font.Arcade
                        o.TextSize = 16
                        o.AutoButtonColor = false
                        addCorner(o, 6)
                        addStroke(o, self.Theme.Shadow, 1, 0.85)
                        o.Parent = sf
                        hoverColorize(o, self.Theme.PageIdle, self.Theme.PageHover)
                        o.MouseButton1Click:Connect(function()
                            setChoice(opt)
                            open = false
                            listFrame.Visible = false
                        end)
                    end
                end

                refreshOptions()
                if default then setChoice(default) end

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    listFrame.Visible = open
                end)

                return {
                    Set = setChoice,
                    SetOptions = function(newOptions)
                        options = newOptions or {}
                        refreshOptions()
                    end
                }
            end

            Page._sections[#Page._sections+1] = Section
            return Section
        end

        self._pages[name] = Page
        self._pageButtons[name] = pageButton

        return Page
    end

    -- API: addSelectPage
    function self.addSelectPage(name)
        for pname, page in pairs(self._pages) do
            local active = (pname == name)
            if page and page._frame then
                if active then
                    -- Slide-in effect
                    page._frame.Visible = true
                    page._frame.Position = UDim2.new(0, 20, 0, 0)
                    TweenService:Create(page._frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
                else
                    page._frame.Visible = false
                end
            end
            if self._pageButtons[pname] then
                self._pageButtons[pname].BackgroundColor3 = active and self.Theme.Accent or self.Theme.PageIdle
                self._pageButtons[pname].TextColor3 = active and Color3.fromRGB(0, 0, 0) or self.Theme.Text
            end
        end
        self._selected = name
    end

    -- Initial open anim
    task.delay(0.05, function()
        self._visible = true
        self.SetTheme("Dark Yellow Premium")
        TweenService:Create(self._uiScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
        self._blur.Enabled = true
        TweenService:Create(self._blur, TweenInfo.new(0.25), {Size = 18}):Play()
    end)

    return self
end

return UIlib
