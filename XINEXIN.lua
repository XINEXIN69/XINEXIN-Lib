-- xinexin.lua
-- XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
-- Theme: Dark Yellow | Font: Pixel Bold (Arcade) | Text: White
-- Window: Size UDim2.new(0,735,0,379), Position UDim2.new(0.26607,0,0.26773,0)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local XINEXIN = {}
XINEXIN._version = "1.0.0"

-- THEME -----------------------------------------------------------------------

local Themes = {
    DarkYellow = {
        Background = Color3.fromRGB(20, 20, 20),
        Background2 = Color3.fromRGB(26, 26, 26),
        Subtle = Color3.fromRGB(35, 35, 35),
        Border = Color3.fromRGB(60, 60, 60),
        Accent = Color3.fromRGB(255, 195, 0),
        AccentHover = Color3.fromRGB(255, 215, 64),
        Text = Color3.fromRGB(255, 255, 255),
        MutedText = Color3.fromRGB(205, 205, 205)
    }
}

local function t(instance, props)
    for k, v in pairs(props) do
        instance[k] = v
    end
    return instance
end

local function roundify(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = instance
    return c
end

local function padify(instance, pad)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, pad)
    p.PaddingRight = UDim.new(0, pad)
    p.PaddingTop = UDim.new(0, pad)
    p.PaddingBottom = UDim.new(0, pad)
    p.Parent = instance
    return p
end

local function uiStroke(instance, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = instance
    return s
end

local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragInput, mousePos, framePos

    local function update(input)
        local delta = input.Position - mousePos
        frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
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
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function tween(obj, info, props)
    return TweenService:Create(obj, info, props)
end

local function bounceHover(button, theme)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    local baseColor = button.BackgroundColor3
    local hoverColor = theme.AccentHover

    button.MouseEnter:Connect(function()
        tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.04}):Play()
        tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = hoverColor}):Play()
    end)

    button.MouseLeave:Connect(function()
        tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.0}):Play()
        tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = baseColor}):Play()
    end)
end

local function addBlur(tag)
    local blur = Lighting:FindFirstChild(tag) or Instance.new("BlurEffect")
    blur.Name = tag
    blur.Parent = Lighting
    blur.Enabled = true
    blur.Size = 0
    tween(blur, TweenInfo.new(0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = 12}):Play()
    return blur
end

local function removeBlur(blur)
    if blur and blur.Parent then
        local tw = tween(blur, TweenInfo.new(0.20, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = 0})
        tw:Play()
        tw.Completed:Wait()
        blur.Enabled = false
        blur:Destroy()
    end
end

local function punchScale(guiObject)
    local scale = guiObject:FindFirstChild("OpenUIScale") or Instance.new("UIScale")
    scale.Name = "OpenUIScale"
    scale.Scale = 0.94
    scale.Parent = guiObject
    tween(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

-- UI OBJECT -------------------------------------------------------------------

function XINEXIN.new(config)
    config = config or {}
    local theme = Themes.DarkYellow

    -- Root gui
    local gui = Instance.new("ScreenGui")
    gui.Name = "XINEXIN_HUB"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Enabled = true
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Toggle icon (floating)
    local toggleIcon = t(Instance.new("ImageButton"), {
        Name = "ToggleIcon",
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 16, 0.5, -18),
        BackgroundColor3 = theme.Accent,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Image = "rbxassetid://3926305904", -- UI icon sheet
        ImageRectOffset = Vector2.new(764, 764), -- bolt icon-ish
        ImageRectSize = Vector2.new(36, 36),
        ZIndex = 1000
    })
    roundify(toggleIcon, 8)
    uiStroke(toggleIcon, theme.Border, 1)
    toggleIcon.Parent = gui
    makeDraggable(toggleIcon, toggleIcon)

    -- Main window
    local main = t(Instance.new("Frame"), {
        Name = "MainWindow",
        Size = UDim2.new(0, 735, 0, 379),
        Position = UDim2.new(0.26607, 0, 0.26773, 0),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Visible = true
    })
    roundify(main, 10)
    uiStroke(main, theme.Border, 1)
    main.Parent = gui

    -- Top bar
    local top = t(Instance.new("Frame"), {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.Background2,
        BorderSizePixel = 0
    })
    top.Parent = main
    roundify(top, 10)

    local title = t(Instance.new("TextLabel"), {
        Name = "Title",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = "XINEXIN HUB",
        TextColor3 = theme.Text,
        Font = Enum.Font.Arcade,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    title.Parent = top

    makeDraggable(main, top)

    -- Page bar (left)
    local pageBar = t(Instance.new("ScrollingFrame"), {
        Name = "PageBar",
        Size = UDim2.new(0, 180, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        BackgroundColor3 = theme.Background2,
        BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    pageBar.Parent = main
    roundify(pageBar, 10)
    uiStroke(pageBar, theme.Border, 1)
    padify(pageBar, 8)

    local pageList = Instance.new("UIListLayout")
    pageList.FillDirection = Enum.FillDirection.Vertical
    pageList.Padding = UDim.new(0, 8)
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Parent = pageBar

    -- Section area (right)
    local sectionArea = t(Instance.new("ScrollingFrame"), {
        Name = "SectionArea",
        Size = UDim2.new(1, -180, 1, -40),
        Position = UDim2.new(0, 180, 0, 40),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 6,
        BackgroundColor3 = theme.Background2,
        BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    sectionArea.Parent = main
    roundify(sectionArea, 10)
    uiStroke(sectionArea, theme.Border, 1)
    padify(sectionArea, 10)

    local sectionList = Instance.new("UIListLayout")
    sectionList.Name = "SectionList"
    sectionList.FillDirection = Enum.FillDirection.Vertical
    sectionList.Padding = UDim.new(0, 10)
    sectionList.SortOrder = Enum.SortOrder.LayoutOrder
    sectionList.Parent = sectionArea

    -- Notifications container
    local notifyContainer = t(Instance.new("Frame"), {
        Name = "NotifyContainer",
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.new(0, 300, 1, -50),
        Position = UDim2.new(1, -10, 0, 50),
        BackgroundTransparency = 1
    })
    notifyContainer.Parent = main

    local notifyList = Instance.new("UIListLayout")
    notifyList.FillDirection = Enum.FillDirection.Vertical
    notifyList.Padding = UDim.new(0, 8)
    notifyList.SortOrder = Enum.SortOrder.LayoutOrder
    notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifyList.Parent = notifyContainer

    -- State
    local PAGES = {}
    local ACTIVE_PAGE = nil
    local BLUR_TAG = "XINEXIN_BLUR"
    local isOpen = true

    -- Helpers
    local function selectPage(name)
        local page = PAGES[name]
        if not page then return end

        -- Tab highlight
        for _, p in pairs(PAGES) do
            p._tab.TextColor3 = theme.MutedText
            p._tab.BackgroundColor3 = theme.Accent
        end
        page._tab.TextColor3 = theme.Text

        -- Clear section area
        for _, c in ipairs(sectionArea:GetChildren()) do
            if c:IsA("Frame") and c.Name == "SectionFrame" then
                c:Destroy()
            end
        end

        -- Build sections
        for _, section in ipairs(page._sections) do
            local sFrame = t(Instance.new("Frame"), {
                Name = "SectionFrame",
                Size = section._size or UDim2.new(1, -4, 0, 72),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0
            })
            roundify(sFrame, 8)
            uiStroke(sFrame, theme.Border, 1)
            sFrame.Parent = sectionArea

            local sTitle = t(Instance.new("TextLabel"), {
                Name = "SectionTitle",
                Size = UDim2.new(1, -16, 0, 22),
                Position = UDim2.new(0, 8, 0, 6),
                BackgroundTransparency = 1,
                Text = section.name,
                TextColor3 = theme.Text,
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            sTitle.Parent = sFrame

            local content = t(Instance.new("Frame"), {
                Name = "Content",
                Size = UDim2.new(1, -16, 1, -34),
                Position = UDim2.new(0, 8, 0, 30),
                BackgroundTransparency = 1
            })
            content.Parent = sFrame

            local grid = Instance.new("UIListLayout")
            grid.FillDirection = Enum.FillDirection.Vertical
            grid.Padding = UDim.new(0, 6)
            grid.SortOrder = Enum.SortOrder.LayoutOrder
            grid.Parent = content

            -- Render items
            for _, item in ipairs(section._items) do
                item._render(content, theme)
            end

            -- Slide-in animation
            sFrame.Position = UDim2.new(0, 12, 0, sFrame.Position.Y.Offset + 10)
            sFrame.BackgroundTransparency = 0.12
            tween(sFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, sFrame.Position.Y.Scale, sFrame.Position.Y.Offset - 10),
                BackgroundTransparency = 0
            }):Play()
        end

        ACTIVE_PAGE = name
    end

    local function createTab(name)
        local tab = t(Instance.new("TextButton"), {
            Name = "PageTab_" .. name,
            Size = UDim2.new(1, -4, 0, 34),
            BackgroundColor3 = theme.Accent,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Text = name,
            TextColor3 = theme.MutedText,
            Font = Enum.Font.Arcade,
            TextSize = 16
        })
        tab.Parent = pageBar
        roundify(tab, 8)
        uiStroke(tab, theme.Border, 1)
        bounceHover(tab, theme)

        tab.MouseButton1Click:Connect(function()
            selectPage(name)
        end)

        return tab
    end

    local function addNotify(msg)
        local toast = t(Instance.new("Frame"), {
            Name = "Toast",
            Size = UDim2.new(0, 260, 0, 36),
            BackgroundColor3 = theme.Background,
            BorderSizePixel = 0
        })
        roundify(toast, 8)
        uiStroke(toast, theme.Border, 1)
        toast.Parent = notifyContainer

        local text = t(Instance.new("TextLabel"), {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(msg),
            TextColor3 = theme.Text,
            Font = Enum.Font.Arcade,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        text.Parent = toast

        toast.BackgroundTransparency = 0.1
        toast.Position = UDim2.new(1, 0, 0, 0)
        local twIn = tween(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
        twIn:Play()

        task.delay(2.0, function()
            local twOut = tween(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 0.3})
            twOut:Play()
            twOut.Completed:Wait()
            toast:Destroy()
        end)
    end

    local function toggleUI()
        isOpen = not isOpen
        main.Visible = isOpen
        if isOpen then
            local b = addBlur(BLUR_TAG)
            punchScale(main)
            task.delay(0.25, function()
                removeBlur(b)
            end)
        end
    end

    toggleIcon.MouseButton1Click:Connect(toggleUI)

    -- PUBLIC API --------------------------------------------------------------

    local UI = {}

    function UI.addPage(name)
        name = tostring(name)
        if PAGES[name] then return PAGES[name] end

        local page = {
            name = name,
            _sections = {},
            _tab = createTab(name)
        }

        function page.addSection(sName)
            local section = {
                name = tostring(sName),
                _size = UDim2.new(1, -4, 0, 72),
                _items = {}
            }

            -- Controls -------------------------------------------------------

            function section:addButton(text, callback)
                local label = tostring(text)
                table.insert(self._items, {
                    _render = function(parent, th)
                        local btn = t(Instance.new("TextButton"), {
                            Name = "Button",
                            Size = UDim2.new(1, 0, 0, 34),
                            BackgroundColor3 = th.Accent,
                            BorderSizePixel = 0,
                            Text = label,
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            AutoButtonColor = false
                        })
                        roundify(btn, 8)
                        uiStroke(btn, th.Border, 1)
                        btn.Parent = parent
                        bounceHover(btn, th)

                        btn.MouseButton1Click:Connect(function()
                            if typeof(callback) == "function" then
                                task.spawn(callback)
                            end
                        end)
                    end
                })
                return self
            end

            function section:addToggle(text, default, callback)
                local label = tostring(text)
                local state = default and true or false
                table.insert(self._items, {
                    _render = function(parent, th)
                        local row = t(Instance.new("Frame"), {
                            Name = "Toggle",
                            Size = UDim2.new(1, 0, 0, 34),
                            BackgroundColor3 = th.Subtle,
                            BorderSizePixel = 0
                        })
                        row.Parent = parent
                        roundify(row, 8)
                        uiStroke(row, th.Border, 1)

                        local txt = t(Instance.new("TextLabel"), {
                            Size = UDim2.new(1, -70, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            BackgroundTransparency = 1,
                            Text = label,
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        txt.Parent = row

                        local knob = t(Instance.new("TextButton"), {
                            Size = UDim2.new(0, 48, 0, 24),
                            Position = UDim2.new(1, -58, 0.5, -12),
                            BackgroundColor3 = state and th.Accent or th.Border,
                            BorderSizePixel = 0,
                            Text = "",
                            AutoButtonColor = false
                        })
                        knob.Parent = row
                        roundify(knob, 12)
                        uiStroke(knob, th.Border, 1)

                        local inner = t(Instance.new("Frame"), {
                            Size = UDim2.new(0, 20, 0, 20),
                            Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            BorderSizePixel = 0
                        })
                        inner.Parent = knob
                        roundify(inner, 10)

                        local function setState(v)
                            state = v
                            tween(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                BackgroundColor3 = state and th.Accent or th.Border
                            }):Play()
                            tween(inner, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                            }):Play()
                            if typeof(callback) == "function" then
                                task.spawn(callback, state)
                            end
                        end

                        knob.MouseButton1Click:Connect(function()
                            setState(not state)
                        end)
                    end
                })
                return self
            end

            function section:addTextbox(text, default, callback)
                local label = tostring(text)
                local init = default ~= nil and tostring(default) or ""
                table.insert(self._items, {
                    _render = function(parent, th)
                        local row = t(Instance.new("Frame"), {
                            Name = "Textbox",
                            Size = UDim2.new(1, 0, 0, 34),
                            BackgroundColor3 = th.Subtle,
                            BorderSizePixel = 0
                        })
                        row.Parent = parent
                        roundify(row, 8)
                        uiStroke(row, th.Border, 1)

                        local txt = t(Instance.new("TextLabel"), {
                            Size = UDim2.new(0.4, -10, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            BackgroundTransparency = 1,
                            Text = label,
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        txt.Parent = row

                        local box = t(Instance.new("TextBox"), {
                            Size = UDim2.new(0.6, -20, 0, 24),
                            Position = UDim2.new(0.4, 10, 0.5, -12),
                            BackgroundColor3 = th.Background,
                            Text = init,
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            BorderSizePixel = 0,
                            PlaceholderText = ""
                        })
                        box.Parent = row
                        roundify(box, 8)
                        uiStroke(box, th.Border, 1)

                        box.FocusLost:Connect(function(enterPressed)
                            if typeof(callback) == "function" then
                                task.spawn(callback, box.Text, enterPressed)
                            end
                        end)
                    end
                })
                return self
            end

            function section:addKeybind(text, default, callback)
                local label = tostring(text)
                local key = default or Enum.KeyCode.RightShift
                local listening = false
                table.insert(self._items, {
                    _render = function(parent, th)
                        local row = t(Instance.new("Frame"), {
                            Name = "Keybind",
                            Size = UDim2.new(1, 0, 0, 34),
                            BackgroundColor3 = th.Subtle,
                            BorderSizePixel = 0
                        })
                        row.Parent = parent
                        roundify(row, 8)
                        uiStroke(row, th.Border, 1)

                        local txt = t(Instance.new("TextLabel"), {
                            Size = UDim2.new(0.6, -10, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            BackgroundTransparency = 1,
                            Text = label,
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        txt.Parent = row

                        local btn = t(Instance.new("TextButton"), {
                            Size = UDim2.new(0.4, -20, 0, 24),
                            Position = UDim2.new(0.6, 10, 0.5, -12),
                            BackgroundColor3 = th.Background,
                            BorderSizePixel = 0,
                            Text = key.Name,
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            AutoButtonColor = false
                        })
                        btn.Parent = row
                        roundify(btn, 8)
                        uiStroke(btn, th.Border, 1)
                        bounceHover(btn, th)

                        btn.MouseButton1Click:Connect(function()
                            listening = true
                            btn.Text = "..."
                        end)

                        UserInputService.InputBegan:Connect(function(input, gpe)
                            if gpe then return end
                            if listening then
                                if input.UserInputType == Enum.UserInputType.Keyboard then
                                    key = input.KeyCode
                                    btn.Text = key.Name
                                    listening = false
                                end
                            else
                                if input.KeyCode == key then
                                    if typeof(callback) == "function" then
                                        task.spawn(callback, key)
                                    end
                                end
                            end
                        end)
                    end
                })
                return self
            end

            function section:addColorPicker(text, default, callback)
                local label = tostring(text)
                local color = default or Color3.fromRGB(255, 195, 0)
                table.insert(self._items, {
                    _render = function(parent, th)
                        local row = t(Instance.new("Frame"), {
                            Name = "ColorPicker",
                            Size = UDim2.new(1, 0, 0, 38),
                            BackgroundColor3 = th.Subtle,
                            BorderSizePixel = 0
                        })
                        row.Parent = parent
                        roundify(row, 8)
                        uiStroke(row, th.Border, 1)

                        local txt = t(Instance.new("TextLabel"), {
                            Size = UDim2.new(0.6, -10, 1, 0),
                            Position = UDim2.new(0, 10, 0, 0),
                            BackgroundTransparency = 1,
                            Text = label,
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        txt.Parent = row

                        local swatch = t(Instance.new("TextButton"), {
                            Size = UDim2.new(0, 28, 0, 28),
                            Position = UDim2.new(1, -38, 0.5, -14),
                            BackgroundColor3 = color,
                            BorderSizePixel = 0,
                            Text = "",
                            AutoButtonColor = false
                        })
                        swatch.Parent = row
                        roundify(swatch, 6)
                        uiStroke(swatch, th.Border, 1)

                        -- Minimal popup with hue slider
                        local popup = t(Instance.new("Frame"), {
                            Name = "PickerPopup",
                            Size = UDim2.new(0, 180, 0, 60),
                            Position = UDim2.new(1, -192, 0, 40),
                            BackgroundColor3 = th.Background,
                            BorderSizePixel = 0,
                            Visible = false
                        })
                        popup.Parent = row
                        roundify(popup, 8)
                        uiStroke(popup, th.Border, 1)
                        padify(popup, 8)

                        local hueBar = t(Instance.new("Frame"), {
                            Size = UDim2.new(1, -16, 0, 14),
                            Position = UDim2.new(0, 8, 0, 8),
                            BorderSizePixel = 0,
                            BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        })
                        hueBar.Parent = popup
                        roundify(hueBar, 6)

                        local grad = Instance.new("UIGradient")
                        grad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                        })
                        grad.Rotation = 0
                        grad.Parent = hueBar

                        local knob = t(Instance.new("Frame"), {
                            Size = UDim2.new(0, 10, 0, 18),
                            Position = UDim2.new(0, 0, 0.5, -9),
                            BackgroundColor3 = th.Text,
                            BorderSizePixel = 0
                        })
                        knob.Parent = hueBar
                        roundify(knob, 4)

                        local preview = t(Instance.new("TextLabel"), {
                            Size = UDim2.new(1, -16, 0, 16),
                            Position = UDim2.new(0, 8, 0, 36),
                            BackgroundTransparency = 1,
                            Text = "Color",
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        preview.Parent = popup

                        local dragging = false
                        local function updateFromX(x)
                            local rel = math.clamp((x - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                            knob.Position = UDim2.new(rel, -5, 0.5, -9)
                            local hue = rel
                            local r, g, b = Color3.fromHSV(hue, 1, 1).R, Color3.fromHSV(hue, 1, 1).G, Color3.fromHSV(hue, 1, 1).B
                            color = Color3.fromRGB(r * 255, g * 255, b * 255)
                            swatch.BackgroundColor3 = color
                            preview.Text = ("R:%d G:%d B:%d"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
                            if typeof(callback) == "function" then
                                task.spawn(callback, color)
                            end
                        end

                        hueBar.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = true
                                updateFromX(input.Position.X)
                            end
                        end)

                        UserInputService.InputChanged:Connect(function(input)
                            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                updateFromX(input.Position.X)
                            end
                        end)

                        UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = false
                            end
                        end)

                        swatch.MouseButton1Click:Connect(function()
                            popup.Visible = not popup.Visible
                        end)
                    end
                })
                return self
            end

            function section:addSlider(text, min, max, default, callback)
                local label = tostring(text)
                local vMin = tonumber(min) or 0
                local vMax = tonumber(max) or 100
                local value = math.clamp(tonumber(default) or vMin, vMin, vMax)
                table.insert(self._items, {
                    _render = function(parent, th)
                        local row = t(Instance.new("Frame"), {
                            Name = "Slider",
                            Size = UDim2.new(1, 0, 0, 40),
                            BackgroundColor3 = th.Subtle,
                            BorderSizePixel = 0
                        })
                        row.Parent = parent
                        roundify(row, 8)
                        uiStroke(row, th.Border, 1)

                        local txt = t(Instance.new("TextLabel"), {
                            Size = UDim2.new(0.6, -10, 1, -10),
                            Position = UDim2.new(0, 10, 0, 0),
                            BackgroundTransparency = 1,
                            Text = ("%s: %s"):format(label, tostring(value)),
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        txt.Parent = row

                        local bar = t(Instance.new("Frame"), {
                            Size = UDim2.new(0.6, 0, 0, 8),
                            Position = UDim2.new(0.4, 10, 1, -16),
                            BackgroundColor3 = th.Background,
                            BorderSizePixel = 0
                        })
                        bar.Parent = row
                        roundify(bar, 4)
                        uiStroke(bar, th.Border, 1)

                        local fill = t(Instance.new("Frame"), {
                            Size = UDim2.new((value - vMin) / (vMax - vMin), 0, 1, 0),
                            BackgroundColor3 = th.Accent,
                            BorderSizePixel = 0
                        })
                        fill.Parent = bar
                        roundify(fill, 4)

                        local dragging = false
                        local function setFromX(x)
                            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                            value = math.floor(vMin + rel * (vMax - vMin) + 0.5)
                            fill.Size = UDim2.new(rel, 0, 1, 0)
                            txt.Text = ("%s: %s"):format(label, tostring(value))
                            if typeof(callback) == "function" then
                                task.spawn(callback, value)
                            end
                        end

                        bar.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = true
                                setFromX(input.Position.X)
                            end
                        end)

                        UserInputService.InputChanged:Connect(function(input)
                            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                setFromX(input.Position.X)
                            end
                        end)

                        UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = false
                            end
                        end)
                    end
                })
                return self
            end

            function section:addDropdown(text, options, default, callback)
                local label = tostring(text)
                local opt = options or {}
                local selected = default or (opt[1] or "")
                table.insert(self._items, {
                    _render = function(parent, th)
                        local row = t(Instance.new("Frame"), {
                            Name = "Dropdown",
                            Size = UDim2.new(1, 0, 0, 34),
                            BackgroundColor3 = th.Subtle,
                            BorderSizePixel = 0
                        })
                        row.Parent = parent
                        roundify(row, 8)
                        uiStroke(row, th.Border, 1)

                        local btn = t(Instance.new("TextButton"), {
                            Size = UDim2.new(1, -10, 1, 0),
                            Position = UDim2.new(0, 5, 0, 0),
                            BackgroundColor3 = th.Background,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Text = ("%s: %s"):format(label, tostring(selected)),
                            TextColor3 = th.Text,
                            Font = Enum.Font.Arcade,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        btn.Parent = row
                        roundify(btn, 8)
                        uiStroke(btn, th.Border, 1)
                        bounceHover(btn, th)

                        local listFrame = t(Instance.new("Frame"), {
                            Size = UDim2.new(1, -10, 0, 0),
                            Position = UDim2.new(0, 5, 1, 6),
                            BackgroundColor3 = th.Background,
                            BorderSizePixel = 0,
                            Visible = false
                        })
                        listFrame.Parent = row
                        roundify(listFrame, 8)
                        uiStroke(listFrame, th.Border, 1)
                        padify(listFrame, 6)

                        local listLayout = Instance.new("UIListLayout")
                        listLayout.Padding = UDim.new(0, 4)
                        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        listLayout.Parent = listFrame

                        local function rebuild()
                            for _, c in ipairs(listFrame:GetChildren()) do
                                if c:IsA("TextButton") then c:Destroy() end
                            end
                            for _, v in ipairs(opt) do
                                local o = t(Instance.new("TextButton"), {
                                    Size = UDim2.new(1, 0, 0, 24),
                                    BackgroundColor3 = th.Subtle,
                                    BorderSizePixel = 0,
                                    AutoButtonColor = false,
                                    Text = tostring(v),
                                    TextColor3 = th.Text,
                                    Font = Enum.Font.Arcade,
                                    TextSize = 16
                                })
                                o.Parent = listFrame
                                roundify(o, 6)
                                uiStroke(o, th.Border, 1)
                                bounceHover(o, th)
                                o.MouseButton1Click:Connect(function()
                                    selected = v
                                    btn.Text = ("%s: %s"):format(label, tostring(selected))
                                    listFrame.Visible = false
                                    listFrame.Size = UDim2.new(1, -10, 0, 0)
                                    if typeof(callback) == "function" then
                                        task.spawn(callback, selected)
                                    end
                                end)
                            end
                            local height = #opt * 28 + 8
                            listFrame.Size = UDim2.new(1, -10, 0, height)
                        end

                        rebuild()

                        btn.MouseButton1Click:Connect(function()
                            local willShow = not listFrame.Visible
                            listFrame.Visible = willShow
                            if willShow then
                                rebuild()
                            end
                        end)
                    end
                })
                return self
            end

            function section:Resize(size)
                self._size = size
                return self
            end

            -- Add section to page
            table.insert(page._sections, section)
            return section
        end

        function page.addResize(size)
            main.Size = size
            return page
        end

        PAGES[name] = page
        if not ACTIVE_PAGE then
            selectPage(name)
        end
        return page
    end

    function UI.addNotify(message)
        addNotify(message)
    end

    function UI.addSelectPage(name)
        selectPage(name)
    end

    function UI.SetTheme(nameOrTable)
        if typeof(nameOrTable) == "string" and Themes[nameOrTable] then
            theme = Themes[nameOrTable]
        elseif typeof(nameOrTable) == "table" then
            theme = nameOrTable
        end
        -- You can extend to re-style existing elements if needed.
    end

    function UI.Toggle()
        toggleUI()
    end

    -- Open effects on start
    local blur = addBlur(BLUR_TAG)
    punchScale(main)
    task.delay(0.25, function()
        removeBlur(blur)
    end)

    return UI
end

return XINEXIN
