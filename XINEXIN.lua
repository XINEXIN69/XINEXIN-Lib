

local XINEXIN = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

-- Utils
local function safeParent(gui)
    local parent
    pcall(function()
        parent = CoreGui
    end)
    if not parent then
        local player = Players.LocalPlayer
        if player and player:FindFirstChildOfClass("PlayerGui") then
            parent = player:FindFirstChildOfClass("PlayerGui")
        end
    end
    return parent
end

local function twn(inst, info, props)
    local tween = TweenService:Create(inst, info, props)
    tween:Play()
    return tween
end

local function newUIStroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function newCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 8)
    c.Parent = inst
    return c
end

local function newPadding(inst, left, top, right, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.Parent = inst
    return p
end

local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput then
            update(input)
        end
    end)
end

local function hoverBounce(inst, hoverProps, leaveProps, colorInst, hoverColor, leaveColor)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = inst

    inst.MouseEnter:Connect(function()
        twn(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.06})
        if colorInst and hoverColor then
            twn(colorInst, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextColor3 = hoverColor})
        end
        if hoverProps then
            twn(inst, unpack(hoverProps))
        end
    end)
    inst.MouseLeave:Connect(function()
        twn(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
        if colorInst and leaveColor then
            twn(colorInst, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextColor3 = leaveColor})
        end
        if leaveProps then
            twn(inst, unpack(leaveProps))
        end
    end)
end

local function slideIn(inst, offset, time)
    inst.Position = UDim2.new(0, offset, inst.Position.Y.Scale, inst.Position.Y.Offset)
    inst.BackgroundTransparency = 1
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            d.TextTransparency = 1
        elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
            d.ImageTransparency = 1
        end
    end
    twn(inst, TweenInfo.new(time or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, inst.Position.Y.Scale, inst.Position.Y.Offset),
        BackgroundTransparency = 0
    })
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            twn(d, TweenInfo.new(time or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
        elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
            twn(d, TweenInfo.new(time or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0})
        end
    end
end

-- Theme system
local THEMES = {
    ["Dark Yellow Premium"] = {
        BG = Color3.fromRGB(22, 22, 22),
        BG2 = Color3.fromRGB(28, 28, 28),
        BG3 = Color3.fromRGB(36, 36, 36),
        Accent = Color3.fromRGB(255, 186, 46),
        AccentDim = Color3.fromRGB(200, 145, 35),
        Stroke = Color3.fromRGB(70, 70, 70),
        StrokeAccent = Color3.fromRGB(255, 186, 46),
        Text = Color3.fromRGB(255, 255, 255)
    }
}

local PIXEL_FONTS = {
    ["Pixel Bold"] = Enum.Font.Arcade -- closest native pixel-bold style
}

-- Constructor
function XINEXIN.new(cfg)
    cfg = cfg or {}
    local theme = THEMES[cfg.Theme or "Dark Yellow Premium"] or THEMES["Dark Yellow Premium"]
    local font = PIXEL_FONTS[cfg.Font or "Pixel Bold"] or Enum.Font.Arcade
    local textColor = cfg.TextColor or theme.Text
    local size = cfg.Size or UDim2.new(0, 763, 0, 465)
    local pos = cfg.Position or UDim2.new(0.5, 0, 0.5, 0)
    local hubName = cfg.HubName or "XINEXIN HUB"

    -- Root GUI
    local parent = safeParent()
    local screen = Instance.new("ScreenGui")
    screen.Name = "XINEXIN_HUB"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = parent

    -- Toggle icon (floating, draggable)
    local toggleIcon = Instance.new("TextButton")
    toggleIcon.Name = "ToggleIcon"
    toggleIcon.Size = UDim2.new(0, 42, 0, 42)
    toggleIcon.Position = UDim2.new(0, 24, 0.5, -21)
    toggleIcon.BackgroundColor3 = theme.BG2
    toggleIcon.AutoButtonColor = false
    toggleIcon.Text = "≡"
    toggleIcon.Font = font
    toggleIcon.TextScaled = true
    toggleIcon.TextColor3 = textColor
    toggleIcon.Parent = screen
    newCorner(toggleIcon, UDim.new(0, 10))
    newUIStroke(toggleIcon, theme.Stroke, 1)
    makeDraggable(toggleIcon, toggleIcon)
    hoverBounce(toggleIcon)

    -- Main Window
    local window = Instance.new("Frame")
    window.Name = "Window"
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Size = size
    window.Position = pos
    window.BackgroundColor3 = theme.BG
    window.BorderSizePixel = 0
    window.Visible = true
    window.Parent = screen
    newCorner(window, UDim.new(0, 12))
    newUIStroke(window, theme.Stroke, 1)

    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 44)
    topBar.BackgroundColor3 = theme.BG2
    topBar.BorderSizePixel = 0
    topBar.Parent = window
    newCorner(topBar, UDim.new(0, 12))
    newUIStroke(topBar, theme.Stroke, 1, 0.2)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = hubName
    title.Font = font
    title.TextSize = 20
    title.TextColor3 = textColor
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    makeDraggable(window, topBar)

    -- Page bar
    local pageBar = Instance.new("Frame")
    pageBar.Name = "PageBar"
    pageBar.Size = UDim2.new(1, 0, 0, 40)
    pageBar.Position = UDim2.new(0, 0, 0, 44)
    pageBar.BackgroundColor3 = theme.BG3
    pageBar.BorderSizePixel = 0
    pageBar.Parent = window
    newUIStroke(pageBar, theme.Stroke, 1, 0.5)

    local pageList = Instance.new("UIListLayout")
    pageList.FillDirection = Enum.FillDirection.Horizontal
    pageList.Padding = UDim.new(0, 8)
    pageList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    pageList.VerticalAlignment = Enum.VerticalAlignment.Center
    pageList.Parent = pageBar
    newPadding(pageBar, 10, 4, 10, 4)

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundColor3 = theme.BG2
    content.BorderSizePixel = 0
    content.Position = UDim2.new(0, 0, 0, 84)
    content.Size = UDim2.new(1, 0, 1, -84)
    content.Parent = window
    newUIStroke(content, theme.Stroke, 1, 0.4)

    -- Notifications container (top-right)
    local notifyContainer = Instance.new("Frame")
    notifyContainer.Name = "NotifyContainer"
    notifyContainer.BackgroundTransparency = 1
    notifyContainer.AnchorPoint = Vector2.new(1, 0)
    notifyContainer.Position = UDim2.new(1, -16, 0, 16)
    notifyContainer.Size = UDim2.new(0, 320, 1, -32)
    notifyContainer.Parent = screen

    local notifyList = Instance.new("UIListLayout")
    notifyList.FillDirection = Enum.FillDirection.Vertical
    notifyList.Padding = UDim.new(0, 8)
    notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifyList.SortOrder = Enum.SortOrder.LayoutOrder
    notifyList.Parent = notifyContainer

    -- Blur + Zoom support
    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Size = 0
    blurEffect.Enabled = false
    blurEffect.Parent = Lighting

    local currentCamera = workspace.CurrentCamera
    local defaultFOV = currentCamera and currentCamera.FieldOfView or 70

    local STATE = {
        theme = theme,
        font = font,
        textColor = textColor,
        pages = {},      -- [name] = { TabButton, ContentFrame, Sections = {} }
        selected = nil,  -- name
        shown = true
    }

    -- Internal: Apply theme to static parts
    local function applyTheme(t)
        window.BackgroundColor3 = t.BG
        topBar.BackgroundColor3 = t.BG2
        title.TextColor3 = t.Text
        pageBar.BackgroundColor3 = t.BG3
        content.BackgroundColor3 = t.BG2

        toggleIcon.BackgroundColor3 = t.BG2
        toggleIcon.TextColor3 = t.Text

        -- Update strokes
        for _, inst in ipairs({window, topBar, pageBar, content, toggleIcon}) do
            for _, d in ipairs(inst:GetChildren()) do
                if d:IsA("UIStroke") then
                    d.Color = (inst == topBar) and t.Stroke or t.Stroke
                end
            end
        end

        -- Update all pages/sections/widgets
        for _, page in pairs(STATE.pages) do
            page.TabButton.TextColor3 = t.Text
            page.TabButton.BackgroundColor3 = t.BG2
            page.Content.BackgroundColor3 = t.BG2
            for _, section in ipairs(page.Sections) do
                section.Frame.BackgroundColor3 = t.BG3
            end
        end
    end

    -- Internal: Select page
    local function selectPage(name)
        if not STATE.pages[name] then return end
        STATE.selected = name
        for pName, p in pairs(STATE.pages) do
            local active = (pName == name)
            p.Content.Visible = active
            p.TabButton.TextColor3 = active and STATE.theme.Accent or STATE.theme.Text
        end
        -- Slide-in sections for current page
        local page = STATE.pages[name]
        for i, section in ipairs(page.Sections) do
            slideIn(section.Frame, 20, 0.22 + (i - 1) * 0.03)
        end
    end

    -- Internal: Toggle open/close with blur + zoom
    local function doToggle()
        STATE.shown = not STATE.shown
        if STATE.shown then
            window.Visible = true
            blurEffect.Enabled = true
            twn(blurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = 12})
            if currentCamera then
                currentCamera.FieldOfView = defaultFOV + 6
                twn(currentCamera, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = defaultFOV})
            end
            twn(window, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = size})
            twn(window, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        else
            twn(blurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = 0}).Completed:Connect(function()
                blurEffect.Enabled = false
            end)
            if currentCamera then
                twn(currentCamera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = defaultFOV + 3})
            end
            twn(window, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1})
            twn(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(size.X.Scale, math.max(0, size.X.Offset - 6), size.Y.Scale, math.max(0, size.Y.Offset - 6))}).Completed:Connect(function()
                window.Visible = false
            end)
        end
    end

    toggleIcon.MouseButton1Click:Connect(doToggle)

    -- Public UI object
    local UI = {}

    function UI.addPage(name)
        name = tostring(name or ("Page" .. tostring(#STATE.pages + 1))))
        if STATE.pages[name] then
            -- Ensure uniqueness
            local i = 2
            while STATE.pages[name .. " " .. i] do i += 1 end
            name = name .. " " .. i
        end

        -- Tab
        local tab = Instance.new("TextButton")
        tab.Name = "Tab_" .. name
        tab.AutoButtonColor = false
        tab.BackgroundColor3 = STATE.theme.BG2
        tab.TextColor3 = STATE.theme.Text
        tab.Font = STATE.font
        tab.TextSize = 16
        tab.Text = name
        tab.Size = UDim2.new(0, math.max(90, #name * 10), 1, -8)
        tab.Parent = pageBar
        newCorner(tab, UDim.new(0, 8))
        newUIStroke(tab, STATE.theme.Stroke, 1, 0.8)

        hoverBounce(tab, nil, nil, tab, STATE.theme.Accent, STATE.theme.Text)

        -- Page content
        local pageFrame = Instance.new("ScrollingFrame")
        pageFrame.Name = "Page_" .. name
        pageFrame.BackgroundColor3 = STATE.theme.BG2
        pageFrame.BorderSizePixel = 0
        pageFrame.Size = UDim2.new(1, -16, 1, -16)
        pageFrame.Position = UDim2.new(0, 8, 0, 8)
        pageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        pageFrame.ScrollBarThickness = 6
        pageFrame.ScrollBarImageColor3 = STATE.theme.AccentDim
        pageFrame.Visible = false
        pageFrame.Parent = content
        newCorner(pageFrame, UDim.new(0, 10))
        newUIStroke(pageFrame, STATE.theme.Stroke, 1, 0.9)

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = pageFrame

        local function updateCanvas()
            pageFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

        local pageObj = {
            TabButton = tab,
            Content = pageFrame,
            Sections = {},
            name = name
        }
        STATE.pages[name] = pageObj

        tab.MouseButton1Click:Connect(function()
            selectPage(name)
        end)

        -- Page-level API
        local Page = {}

        function Page.addSection(secName)
            secName = tostring(secName or "Section")
            local secFrame = Instance.new("Frame")
            secFrame.Name = "Section_" .. secName
            secFrame.BackgroundColor3 = STATE.theme.BG3
            secFrame.BorderSizePixel = 0
            secFrame.Size = UDim2.new(1, -8, 0, 80)
            secFrame.Parent = pageFrame
            newCorner(secFrame, UDim.new(0, 10))
            newUIStroke(secFrame, STATE.theme.Stroke, 1, 0.6)
            newPadding(secFrame, 12, 10, 12, 12)

            local secTitle = Instance.new("TextLabel")
            secTitle.Name = "Title"
            secTitle.BackgroundTransparency = 1
            secTitle.Text = secName
            secTitle.Font = STATE.font
            secTitle.TextSize = 16
            secTitle.TextColor3 = STATE.theme.Accent
            secTitle.TextXAlignment = Enum.TextXAlignment.Left
            secTitle.Size = UDim2.new(1, 0, 0, 20)
            secTitle.Parent = secFrame

            local items = Instance.new("Frame")
            items.Name = "Items"
            items.BackgroundTransparency = 1
            items.Size = UDim2.new(1, 0, 1, -24)
            items.Position = UDim2.new(0, 0, 0, 24)
            items.Parent = secFrame

            local itemsLayout = Instance.new("UIListLayout")
            itemsLayout.FillDirection = Enum.FillDirection.Vertical
            itemsLayout.Padding = UDim.new(0, 8)
            itemsLayout.Parent = items

            local function autoHeight()
                secFrame.Size = UDim2.new(1, -8, 0, math.max(60, itemsLayout.AbsoluteContentSize.Y + 28))
            end
            itemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoHeight)
            autoHeight()

            local Section = {}

            local function baseItem(height)
                local item = Instance.new("Frame")
                item.Name = "Item"
                item.BackgroundColor3 = STATE.theme.BG2
                item.Size = UDim2.new(1, 0, 0, height)
                item.Parent = items
                newCorner(item, UDim.new(0, 8))
                newUIStroke(item, STATE.theme.Stroke, 1, 0.85)
                return item
            end

            function Section:addButton(name, callback)
                local f = baseItem(36)
                local btn = Instance.new("TextButton")
                btn.Name = "Button"
                btn.BackgroundTransparency = 1
                btn.Size = UDim2.new(1, -12, 1, 0)
                btn.Position = UDim2.new(0, 6, 0, 0)
                btn.Text = tostring(name or "Button")
                btn.Font = STATE.font
                btn.TextColor3 = STATE.theme.Text
                btn.TextSize = 16
                btn.AutoButtonColor = false
                btn.Parent = f
                hoverBounce(btn, nil, nil, btn, STATE.theme.Accent, STATE.theme.Text)
                btn.MouseButton1Click:Connect(function()
                    if typeof(callback) == "function" then
                        task.spawn(callback)
                    end
                end)
                return self
            end

            function Section:addToggle(name, default, callback)
                local f = baseItem(36)
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(1, -48, 1, 0)
                label.Position = UDim2.new(0, 12, 0, 0)
                label.Text = tostring(name or "Toggle")
                label.Font = STATE.font
                label.TextSize = 16
                label.TextColor3 = STATE.theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = f

                local box = Instance.new("TextButton")
                box.Size = UDim2.new(0, 28, 0, 28)
                box.Position = UDim2.new(1, -36, 0.5, -14)
                box.BackgroundColor3 = STATE.theme.BG3
                box.Text = ""
                box.AutoButtonColor = false
                box.Parent = f
                newCorner(box, UDim.new(0, 6))
                newUIStroke(box, STATE.theme.Stroke, 1, 0.6)

                local tick = Instance.new("TextLabel")
                tick.BackgroundTransparency = 1
                tick.Size = UDim2.new(1, 0, 1, 0)
                tick.Text = "✓"
                tick.TextScaled = true
                tick.Font = STATE.font
                tick.TextColor3 = STATE.theme.Accent
                tick.Visible = default and true or false
                tick.Parent = box

                local state = not not default
                local function setState(v)
                    state = not not v
                    tick.Visible = state
                    if typeof(callback) == "function" then
                        task.spawn(callback, state)
                    end
                end

                box.MouseButton1Click:Connect(function()
                    setState(not state)
                end)

                return self
            end

            function Section:addTextbox(name, default, callback)
                local f = baseItem(36)
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(0.4, -12, 1, 0)
                label.Position = UDim2.new(0, 12, 0, 0)
                label.Text = tostring(name or "Textbox")
                label.Font = STATE.font
                label.TextSize = 16
                label.TextColor3 = STATE.theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = f

                local tb = Instance.new("TextBox")
                tb.Size = UDim2.new(0.6, -12, 0, 28)
                tb.Position = UDim2.new(0.4, 0, 0.5, -14)
                tb.BackgroundColor3 = STATE.theme.BG3
                tb.Text = tostring(default or "")
                tb.PlaceholderText = ""
                tb.TextColor3 = STATE.theme.Text
                tb.Font = STATE.font
                tb.TextSize = 16
                tb.ClearTextOnFocus = false
                tb.Parent = f
                newCorner(tb, UDim.new(0, 6))
                newUIStroke(tb, STATE.theme.Stroke, 1, 0.6)

                tb.FocusLost:Connect(function(enterPressed)
                    if typeof(callback) == "function" then
                        task.spawn(callback, tb.Text)
                    end
                end)
                return self
            end

            function Section:addKeybind(name, default, callback)
                local f = baseItem(36)
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(0.6, -12, 1, 0)
                label.Position = UDim2.new(0, 12, 0, 0)
                label.Text = tostring(name or "Keybind")
                label.Font = STATE.font
                label.TextSize = 16
                label.TextColor3 = STATE.theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = f

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.4, -12, 0, 28)
                btn.Position = UDim2.new(0.6, 0, 0.5, -14)
                btn.BackgroundColor3 = STATE.theme.BG3
                btn.AutoButtonColor = false
                btn.TextColor3 = STATE.theme.Accent
                btn.Font = STATE.font
                btn.TextSize = 16
                btn.Text = tostring(default or "None")
                btn.Parent = f
                newCorner(btn, UDim.new(0, 6))
                newUIStroke(btn, STATE.theme.Stroke, 1, 0.6)

                local binding = default or nil
                local listening = false

                btn.MouseButton1Click:Connect(function()
                    listening = true
                    btn.Text = "Press..."
                    btn.TextColor3 = STATE.theme.Text
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        binding = input.KeyCode.Name
                        btn.Text = binding
                        btn.TextColor3 = STATE.theme.Accent
                    elseif binding and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == binding then
                            if typeof(callback) == "function" then
                                task.spawn(callback)
                            end
                        end
                    end
                end)

                return self
            end

            function Section:addColorPicker(name, default, callback)
                local f = baseItem(44)
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(0.6, -12, 1, 0)
                label.Position = UDim2.new(0, 12, 0, 0)
                label.Text = tostring(name or "Color")
                label.Font = STATE.font
                label.TextSize = 16
                label.TextColor3 = STATE.theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = f

                local pick = Instance.new("TextButton")
                pick.Size = UDim2.new(0.4, -12, 0, 32)
                pick.Position = UDim2.new(0.6, 0, 0.5, -16)
                pick.BackgroundColor3 = default or Color3.fromRGB(255, 186, 46)
                pick.AutoButtonColor = false
                pick.Text = ""
                pick.Parent = f
                newCorner(pick, UDim.new(0, 8))
                newUIStroke(pick, STATE.theme.Stroke, 1, 0.6)

                -- Simple palette popover
                local palette = Instance.new("Frame")
                palette.Visible = false
                palette.Size = UDim2.new(0, 200, 0, 96)
                palette.Position = UDim2.new(1, -200, 1, 6)
                palette.BackgroundColor3 = STATE.theme.BG3
                palette.BorderSizePixel = 0
                palette.Parent = f
                newCorner(palette, UDim.new(0, 8))
                newUIStroke(palette, STATE.theme.Stroke, 1, 0.6)
                newPadding(palette, 8, 8, 8, 8)

                local grid = Instance.new("UIGridLayout")
                grid.CellSize = UDim2.new(0, 28, 0, 28)
                grid.CellPadding = UDim2.new(0, 8, 0, 8)
                grid.FillDirectionMaxCells = 6
                grid.Parent = palette

                local colors = {
                    Color3.fromRGB(255,186,46), Color3.fromRGB(255,255,255), Color3.fromRGB(200,145,35),
                    Color3.fromRGB(255,99,71),  Color3.fromRGB(135,206,235), Color3.fromRGB(124,252,0),
                    Color3.fromRGB(186,85,211), Color3.fromRGB(173,216,230), Color3.fromRGB(255,215,0),
                    Color3.fromRGB(255,140,0),  Color3.fromRGB(64,224,208),  Color3.fromRGB(240,128,128)
                }

                for _, c in ipairs(colors) do
                    local sw = Instance.new("TextButton")
                    sw.BackgroundColor3 = c
                    sw.Text = ""
                    sw.AutoButtonColor = false
                    sw.Parent = palette
                    newCorner(sw, UDim.new(0, 6))
                    newUIStroke(sw, STATE.theme.Stroke, 1, 0.7)
                    sw.MouseButton1Click:Connect(function()
                        pick.BackgroundColor3 = c
                        palette.Visible = false
                        if typeof(callback) == "function" then
                            task.spawn(callback, c)
                        end
                    end)
                end

                pick.MouseButton1Click:Connect(function()
                    palette.Visible = not palette.Visible
                end)

                return self
            end

            function Section:addSlider(name, min, max, default, callback)
                min = tonumber(min) or 0
                max = tonumber(max) or 100
                local value = math.clamp(tonumber(default) or min, min, max)

                local f = baseItem(44)
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(0.6, -12, 1, 0)
                label.Position = UDim2.new(0, 12, 0, 0)
                label.Text = ("%s: %s"):format(tostring(name or "Slider"), tostring(value))
                label.Font = STATE.font
                label.TextSize = 16
                label.TextColor3 = STATE.theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = f

                local track = Instance.new("Frame")
                track.Size = UDim2.new(0.4, -12, 0, 6)
                track.Position = UDim2.new(0.6, 0, 0.5, 12)
                track.BackgroundColor3 = STATE.theme.BG3
                track.Parent = f
                newCorner(track, UDim.new(0, 4))

                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = STATE.theme.Accent
                fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
                fill.Parent = track
                newCorner(fill, UDim.new(0, 4))

                local handle = Instance.new("TextButton")
                handle.Size = UDim2.new(0, 16, 0, 16)
                handle.Position = UDim2.new((value - min)/(max - min), -8, 0.5, -8)
                handle.BackgroundColor3 = STATE.theme.Accent
                handle.Text = ""
                handle.AutoButtonColor = false
                handle.Parent = track
                newCorner(handle, UDim.new(1, 0))

                local dragging = false
                local function setValueFromX(x)
                    local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
                    value = math.floor((min + (max - min) * rel) + 0.5)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    handle.Position = UDim2.new(rel, -8, 0.5, -8)
                    label.Text = ("%s: %s"):format(tostring(name or "Slider"), tostring(value))
                    if typeof(callback) == "function" then
                        task.spawn(callback, value)
                    end
                end

                handle.MouseButton1Down:Connect(function()
                    dragging = true
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setValueFromX(input.Position.X)
                    end
                end)

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setValueFromX(input.Position.X)
                    end
                end)

                return self
            end

            function Section:addDropdown(name, options, default, callback)
                options = options or {}
                local selected = default or (options[1] or "None")

                local f = baseItem(36)
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(0.6, -12, 1, 0)
                label.Position = UDim2.new(0, 12, 0, 0)
                label.Text = tostring(name or "Dropdown")
                label.Font = STATE.font
                label.TextSize = 16
                label.TextColor3 = STATE.theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = f

                local dd = Instance.new("TextButton")
                dd.Size = UDim2.new(0.4, -12, 0, 28)
                dd.Position = UDim2.new(0.6, 0, 0.5, -14)
                dd.BackgroundColor3 = STATE.theme.BG3
                dd.AutoButtonColor = false
                dd.Text = tostring(selected)
                dd.TextColor3 = STATE.theme.Accent
                dd.Font = STATE.font
                dd.TextSize = 16
                dd.Parent = f
                newCorner(dd, UDim.new(0, 6))
                newUIStroke(dd, STATE.theme.Stroke, 1, 0.6)

                local list = Instance.new("Frame")
                list.Visible = false
                list.Size = UDim2.new(0, dd.AbsoluteSize.X, 0, 6 + (#options * 28 + (#options-1)*6))
                list.Position = UDim2.new(1, -dd.AbsoluteSize.X, 1, 6)
                list.BackgroundColor3 = STATE.theme.BG3
                list.BorderSizePixel = 0
                list.Parent = f
                newCorner(list, UDim.new(0, 8))
                newUIStroke(list, STATE.theme.Stroke, 1, 0.6)
                newPadding(list, 6, 6, 6, 6)

                local l = Instance.new("UIListLayout")
                l.FillDirection = Enum.FillDirection.Vertical
                l.Padding = UDim.new(0, 6)
                l.Parent = list

                local function rebuild()
                    for _, c in ipairs(list:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local it = Instance.new("TextButton")
                        it.Size = UDim2.new(1, 0, 0, 28)
                        it.BackgroundColor3 = STATE.theme.BG2
                        it.TextColor3 = STATE.theme.Text
                        it.Font = STATE.font
                        it.Text = tostring(opt)
                        it.TextSize = 16
                        it.AutoButtonColor = false
                        it.Parent = list
                        newCorner(it, UDim.new(0, 6))
                        newUIStroke(it, STATE.theme.Stroke, 1, 0.8)
                        hoverBounce(it, nil, nil, it, STATE.theme.Accent, STATE.theme.Text)
                        it.MouseButton1Click:Connect(function()
                            selected = opt
                            dd.Text = tostring(selected)
                            list.Visible = false
                            if typeof(callback) == "function" then
                                task.spawn(callback, selected)
                            end
                        end)
                    end
                    list.Size = UDim2.new(0, dd.AbsoluteSize.X, 0, 6 + (#options * 34))
                end
                rebuild()

                dd.MouseButton1Click:Connect(function()
                    list.Visible = not list.Visible
                end)

                return self
            end

            function Section:Resize(sizeUDim2)
                if typeof(sizeUDim2) == "UDim2" then
                    secFrame.Size = sizeUDim2
                end
                return self
            end

            table.insert(pageObj.Sections, {Frame = secFrame})

            return Section
        end

        function Page.addResize(sizeUDim2)
            if typeof(sizeUDim2) == "UDim2" then
                pageFrame.Size = sizeUDim2
            end
        end

        -- Show first page by default
        if not STATE.selected then
            selectPage(name)
        end

        return Page
    end

    function UI.addNotify(message)
        local note = Instance.new("Frame")
        note.BackgroundColor3 = STATE.theme.BG2
        note.Size = UDim2.new(1, 0, 0, 40)
        note.Parent = notifyContainer
        newCorner(note, UDim.new(0, 8))
        newUIStroke(note, STATE.theme.Stroke, 1, 0.6)
        newPadding(note, 10, 8, 10, 8)

        local txt = Instance.new("TextLabel")
        txt.BackgroundTransparency = 1
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.TextWrapped = true
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.TextYAlignment = Enum.TextYAlignment.Center
        txt.Text = tostring(message or "")
        txt.Font = STATE.font
        txt.TextSize = 16
        txt.TextColor3 = STATE.theme.Text
        txt.Parent = note

        note.BackgroundTransparency = 1
        txt.TextTransparency = 1
        twn(note, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        twn(txt, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})

        task.delay(3, function()
            twn(note, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            local tw = twn(txt, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
            tw.Completed:Connect(function()
                note:Destroy()
            end)
        end)
    end

    function UI.addSelectPage(name)
        selectPage(name)
    end

    function UI.SetTheme(name)
        if THEMES[name] then
            STATE.theme = THEMES[name]
            applyTheme(STATE.theme)
        end
    end

    function UI.Toggle()
        doToggle()
    end

    -- Initial theme apply
    applyTheme(STATE.theme)

    -- Return UI object
    return UI
end

-- Return module table for loadstring(...)() use
return library
