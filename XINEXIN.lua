--[[
    XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
    Theme: Dark Yellow Premium
    Font: Pixel Bold (emulated via Enum.Font.Arcade + bold styling)
    Text Color: White
    Window Size: UDim2.new(0, 735, 0, 379)
    Window Position: UDim2.new(0.26607, 0, 0.26773, 0)

    Public API
    UI:
      - UI.addPage(name)
      - UI.addNotify(message)
      - UI.addSelectPage(name)
      - UI.SetTheme(themeOrTable)
      - UI.Toggle()

    Page:
      - Page.addSection(name)
      - Page.addResize(size)

    Section:
      - Section:addButton(name, callback)
      - Section:addToggle(name, default, callback)
      - Section:addTextbox(name, default, callback)
      - Section:addKeybind(name, default, callback)
      - Section:addColorPicker(name, default, callback)
      - Section:addSlider(name, min, max, default, callback)
      - Section:addDropdown(name, options, default, callback)
      - Section:Resize(size)
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")

-- Helpers
local function safeParent(gui)
    gui.Name = "XINEXIN_HUB"
    local parent = (gethui and gethui()) or (syn and syn.protect_gui and game:GetService("CoreGui")) or game:GetService("CoreGui")
    -- protect if possible
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    end
    gui.Parent = parent
    return gui
end

local function make(instance, props, children)
    local obj = Instance.new(instance)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function corner(radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function padding(px)
    return make("UIPadding", {
        PaddingTop = UDim.new(0, px or 8),
        PaddingBottom = UDim.new(0, px or 8),
        PaddingLeft = UDim.new(0, px or 8),
        PaddingRight = UDim.new(0, px or 8),
    })
end

local function listlayout(dir, pad, sort)
    return make("UIListLayout", {
        FillDirection = dir or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, pad or 8),
        SortOrder = sort or Enum.SortOrder.LayoutOrder
    })
end

local function uiscale(scale)
    return make("UIScale", { Scale = scale or 1 })
end

local function tween(o, ti, goal)
    return TweenService:Create(o, ti, goal)
end

local function springBounce(btn)
    local s = btn:FindFirstChildOfClass("UIScale") or uiscale(1); s.Parent = btn
    local enter = tween(s, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.05 })
    local leave = tween(s, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 })
    btn.MouseEnter:Connect(function() enter:Play() end)
    btn.MouseLeave:Connect(function() leave:Play() end)
end

local function attachDrag(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Theme
local Themes = {
    DarkYellowPremium = {
        Background = Color3.fromRGB(18, 18, 18),
        Panel = Color3.fromRGB(26, 26, 26),
        Accent = Color3.fromRGB(255, 199, 44),
        AccentDim = Color3.fromRGB(205, 159, 35),
        Stroke = Color3.fromRGB(45, 45, 45),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(210, 210, 210),
        Hover = Color3.fromRGB(40, 40, 40),
        Good = Color3.fromRGB(80, 200, 120),
        Bad = Color3.fromRGB(255, 90, 90)
    }
}

-- State
local UI = {}
local _state = {
    Theme = Themes.DarkYellowPremium,
    Pages = {},
    PageOrder = {},
    CurrentPage = nil,
    Blur = nil,
    Root = nil,
    Main = nil,
    PageBar = nil,
    SectionArea = nil,
    ToggleIcon = nil,
    Open = true
}

-- Build GUI
local function buildRoot()
    local gui = make("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })
    safeParent(gui)

    -- Blur (enabled on open only)
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Enabled = false
    blur.Name = "XINEXIN_BLUR"
    blur.Parent = Lighting
    _state.Blur = blur

    -- Toggle icon (draggable)
    local toggle = make("ImageButton", {
        Name = "ToggleIcon",
        Size = UDim2.new(0, 42, 0, 42),
        Position = UDim2.new(0, 24, 0.8, 0),
        BackgroundColor3 = _state.Theme.Accent,
        AutoButtonColor = false,
        Image = "rbxassetid://0"
    }, {
        corner(16),
        uiscale(1)
    })
    toggle.Parent = gui
    attachDrag(toggle)
    springBounce(toggle)
    local tstroke = make("UIStroke", { Thickness = 1.5, Color = _state.Theme.Stroke })
    tstroke.Parent = toggle

    -- Window
    local main = make("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 735, 0, 379),
        Position = UDim2.new(0.26607, 0, 0.26773, 0),
        BackgroundColor3 = _state.Theme.Background,
        BorderSizePixel = 0,
        Visible = true,
        ClipsDescendants = false
    }, {
        corner(12),
        make("UIStroke", { Thickness = 1, Color = _state.Theme.Stroke }),
        uiscale(0.95) -- for open zoom tween
    })
    main.Parent = gui

    -- Top bar
    local topbar = make("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, -16, 0, 40),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = _state.Theme.Panel,
        BorderSizePixel = 0
    }, {
        corner(10),
        make("UIStroke", { Thickness = 1, Color = _state.Theme.Stroke })
    })
    topbar.Parent = main

    local title = make("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Text = "XINEXIN HUB",
        TextColor3 = _state.Theme.Text,
        Font = Enum.Font.Arcade,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    title.Parent = topbar

    -- Page bar
    local pagebar = make("Frame", {
        Name = "PageBar",
        Size = UDim2.new(0, 180, 1, -64),
        Position = UDim2.new(0, 8, 0, 56),
        BackgroundColor3 = _state.Theme.Panel,
        BorderSizePixel = 0
    }, {
        corner(10),
        make("UIStroke", { Thickness = 1, Color = _state.Theme.Stroke }),
        padding(8),
        listlayout(Enum.FillDirection.Vertical, 6)
    })
    pagebar.Parent = main

    -- Section area
    local sectionArea = make("Frame", {
        Name = "SectionArea",
        BackgroundColor3 = _state.Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -204, 1, -64),
        Position = UDim2.new(0, 196, 0, 56),
        ClipsDescendants = true
    }, {
        corner(10),
        make("UIStroke", { Thickness = 1, Color = _state.Theme.Stroke }),
        padding(10)
    })
    sectionArea.Parent = main

    -- Notification area
    local notifHolder = make("Frame", {
        Name = "NotifyHolder",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
    }, {
        padding(10)
    })
    notifHolder.Parent = gui

    local notifList = listlayout(Enum.FillDirection.Vertical, 6)
    notifList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifList.VerticalAlignment = Enum.VerticalAlignment.Top
    notifHolder:AddChild(notifList)

    -- Dragging main window
    attachDrag(main, topbar)

    -- Toggle behaviors
    toggle.MouseButton1Click:Connect(function()
        UI.Toggle()
    end)

    _state.Root = gui
    _state.Main = main
    _state.PageBar = pagebar
    _state.SectionArea = sectionArea
    _state.ToggleIcon = toggle

    -- Open animations (blur + zoom)
    local function openAnims(isOpen)
        if isOpen then
            _state.Blur.Enabled = true
            tween(_state.Blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 12 }):Play()
            tween(main:FindFirstChildOfClass("UIScale"), TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
        else
            tween(_state.Blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 }):Play()
            task.delay(0.25, function() _state.Blur.Enabled = false end)
            tween(main:FindFirstChildOfClass("UIScale"), TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
        end
    end
    openAnims(true)

    -- Theme ripple on load for title
    title.TextColor3 = _state.Theme.Text
end

-- Theme application
local function applyTheme()
    if not _state.Main then return end
    local theme = _state.Theme
    local function paint(obj)
        if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
            if obj.Name == "MainWindow" then
                obj.BackgroundColor3 = theme.Background
            else
                obj.BackgroundColor3 = theme.Panel
            end
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
            obj.TextColor3 = theme.Text
        elseif obj:IsA("UIStroke") then
            obj.Color = theme.Stroke
        elseif obj:IsA("ImageButton") or obj:IsA("ImageLabel") then
            -- toggle icon/backgrounds
        end
        for _, ch in ipairs(obj:GetChildren()) do
            paint(ch)
        end
    end
    paint(_state.Main)
    if _state.ToggleIcon then
        _state.ToggleIcon.BackgroundColor3 = theme.Accent
        local st = _state.ToggleIcon:FindFirstChildOfClass("UIStroke")
        if st then st.Color = theme.Stroke end
    end
end

-- UI Build once
buildRoot()
applyTheme()

-- Utilities
local function hoverColorize(btn, base, hover)
    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = hover }):Play()
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = base }):Play()
    end)
end

local function makePageButton(name)
    local theme = _state.Theme
    local btn = make("TextButton", {
        Name = "Page_" .. name,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BorderSizePixel = 0,
        Text = name,
        Font = Enum.Font.Arcade,
        TextSize = 16,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    }, {
        corner(8),
        make("UIStroke", { Thickness = 1, Color = theme.Stroke }),
        uiscale(1)
    })
    springBounce(btn)
    hoverColorize(btn, Color3.fromRGB(30,30,30), theme.Hover)
    return btn
end

local function slideInSections(container)
    local idx = 0
    for _, ch in ipairs(container:GetChildren()) do
        if ch:IsA("Frame") and ch.Visible then
            idx += 1
            local origin = ch.Position
            ch.Position = UDim2.new(origin.X.Scale, origin.X.Offset - 24, origin.Y.Scale, origin.Y.Offset)
            ch.BackgroundTransparency = 0.05
            task.delay(0.02 * idx, function()
                tween(ch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = origin
                }):Play()
            end)
        end
    end
end

-- API: UI.addNotify
function UI.addNotify(message)
    local theme = _state.Theme
    local holder = _state.Root:FindFirstChild("NotifyHolder")
    if not holder then return end

    local bubble = make("Frame", {
        Size = UDim2.new(0, 260, 0, 40),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 12),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0
    }, {
        corner(10),
        make("UIStroke", { Thickness = 1, Color = theme.Stroke }),
        padding(8)
    })
    bubble.Parent = holder

    local label = make("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = tostring(message),
        TextColor3 = theme.Text,
        Font = Enum.Font.Arcade,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    label.Parent = bubble

    bubble.BackgroundTransparency = 1
    tween(bubble, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    task.delay(2.0, function()
        local t = tween(bubble, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
        t:Play()
        t.Completed:Wait()
        bubble:Destroy()
    end)
end

-- UI.Toggle
function UI.Toggle()
    _state.Open = not _state.Open
    if not _state.Main then return end
    _state.Main.Visible = _state.Open
    -- Blur/Zoom transitions
    if _state.Open then
        _state.Blur.Enabled = true
        tween(_state.Blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 12 }):Play()
        tween(_state.Main:FindFirstChildOfClass("UIScale"), TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
    else
        tween(_state.Blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 }):Play()
        task.delay(0.25, function() _state.Blur.Enabled = false end)
        tween(_state.Main:FindFirstChildOfClass("UIScale"), TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
    end
end

-- UI.SetTheme
function UI.SetTheme(theme)
    if typeof(theme) == "string" and Themes[theme] then
        _state.Theme = Themes[theme]
    elseif typeof(theme) == "table" then
        _state.Theme = theme
    end
    applyTheme()
end

-- UI.addPage
function UI.addPage(name)
    name = tostring(name or "Page")
    local theme = _state.Theme

    local btn = makePageButton(name)
    btn.Parent = _state.PageBar

    local pageContainer = make("ScrollingFrame", {
        Name = "Page_" .. name,
        Active = true,
        ScrollBarThickness = 4,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        Visible = false
    }, {
        listlayout(Enum.FillDirection.Vertical, 10),
        padding(4)
    })
    pageContainer.Parent = _state.SectionArea

    local pageObj = {
        Name = name,
        Button = btn,
        Container = pageContainer,
        Sections = {}
    }

    -- Button hover color shift toward accent on focus
    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = theme.Accent }):Play()
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = theme.Text }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        UI.addSelectPage(name)
    end)

    -- Page public API
    function pageObj.addSection(secName)
        local section = {}

        local frame = make("Frame", {
            Name = "Section_" .. tostring(secName),
            BackgroundColor3 = theme.Background,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 56),
            ClipsDescendants = true
        }, {
            corner(10),
            make("UIStroke", { Thickness = 1, Color = theme.Stroke }),
            padding(8),
            listlayout(Enum.FillDirection.Vertical, 6)
        })
        frame.Parent = pageContainer

        local title = make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = tostring(secName),
            TextColor3 = theme.Accent,
            Font = Enum.Font.Arcade,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        title.Parent = frame

        -- Content holder
        local content = make("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y
        }, {
            listlayout(Enum.FillDirection.Vertical, 6)
        })
        content.Parent = frame

        local function makeRow(height)
            local row = make("Frame", {
                BackgroundColor3 = theme.Panel,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, height or 32)
            }, {
                corner(8),
                make("UIStroke", { Thickness = 1, Color = theme.Stroke }),
                padding(8)
            })
            row.Parent = content
            return row
        end

        local function autoResizeSection()
            -- Resize section to fit content
            local total = 18 + 8 -- title + top padding
            for _, ch in ipairs(content:GetChildren()) do
                if ch:IsA("Frame") then
                    total += ch.Size.Y.Offset + 6
                end
            end
            total += 8 -- bottom padding
            frame.Size = UDim2.new(1, 0, 0, total)
        end

        -- Components
        function section:addButton(label, callback)
            local row = makeRow(32)
            local btn = make("TextButton", {
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 120, 1, 0),
                Text = tostring(label),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextColor3 = Color3.new(0,0,0),
                AutoButtonColor = false
            }, {
                corner(8),
                uiscale(1)
            })
            btn.Parent = row
            springBounce(btn)
            hoverColorize(btn, theme.Accent, theme.AccentDim)
            btn.MouseButton1Click:Connect(function()
                if callback then pcall(callback) end
            end)
            autoResizeSection()
            return btn
        end

        function section:addToggle(label, default, callback)
            local row = makeRow(32)
            local left = make("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -80, 1, 0),
                Text = tostring(label),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = theme.Text
            })
            left.Parent = row

            local toggle = make("TextButton", {
                Size = UDim2.new(0, 64, 0, 26),
                Position = UDim2.new(1, -72, 0.5, -13),
                BackgroundColor3 = Color3.fromRGB(55,55,55),
                Text = "",
                AutoButtonColor = false
            }, {
                corner(13)
            })
            toggle.Parent = row

            local knob = make("Frame", {
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0, 1, 0.5, -12),
                BackgroundColor3 = Color3.fromRGB(200,200,200),
                BorderSizePixel = 0
            }, { corner(12) })
            knob.Parent = toggle

            local on = default and true or false
            local function render()
                tween(toggle, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = on and theme.Good or Color3.fromRGB(55,55,55)
                }):Play()
                tween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = on and UDim2.new(1, -25, 0.5, -12) or UDim2.new(0, 1, 0.5, -12),
                    BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
                }):Play()
            end
            render()

            toggle.MouseButton1Click:Connect(function()
                on = not on
                render()
                if callback then pcall(callback, on) end
            end)
            autoResizeSection()
            return toggle, function(v) on = v; render() end
        end

        function section:addTextbox(label, default, callback)
            local row = makeRow(32)
            local left = make("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -6, 1, 0),
                Text = tostring(label),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = theme.Text
            })
            left.Parent = row

            local box = make("TextBox", {
                Size = UDim2.new(0.5, -6, 1, 0),
                Position = UDim2.new(0.5, 6, 0, 0),
                BackgroundColor3 = Color3.fromRGB(34,34,34),
                Text = tostring(default or ""),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextColor3 = theme.Text,
                ClearTextOnFocus = false
            }, {
                corner(8),
                make("UIStroke", { Thickness = 1, Color = theme.Stroke }),
                padding(6)
            })
            box.Parent = row

            box.FocusLost:Connect(function(enterPressed)
                if callback then pcall(callback, box.Text) end
            end)
            autoResizeSection()
            return box
        end

        function section:addKeybind(label, defaultKeyCode, callback)
            local row = makeRow(32)
            local left = make("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -120, 1, 0),
                Text = tostring(label),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = theme.Text
            })
            left.Parent = row

            local btn = make("TextButton", {
                Size = UDim2.new(0, 110, 1, 0),
                Position = UDim2.new(1, -110, 0, 0),
                BackgroundColor3 = Color3.fromRGB(34,34,34),
                Text = defaultKeyCode and defaultKeyCode.Name or "Set Key",
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextColor3 = theme.SubText,
                AutoButtonColor = false
            }, { corner(8), make("UIStroke", { Thickness = 1, Color = theme.Stroke }) })
            btn.Parent = row
            hoverColorize(btn, Color3.fromRGB(34,34,34), theme.Hover)
            springBounce(btn)

            local current = defaultKeyCode
            btn.MouseButton1Click:Connect(function()
                btn.Text = "Press..."
                local conn; conn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        btn.Text = current.Name
                        if callback then pcall(callback, current) end
                        conn:Disconnect()
                    end
                end)
            end)

            -- Also invoke callback on key press
            UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if current and input.KeyCode == current then
                    if callback then pcall(callback, current, true) end
                end
            end)

            autoResizeSection()
            return function(setKeyCode)
                current = setKeyCode
                btn.Text = current and current.Name or "Set Key"
            end
        end

        function section:addColorPicker(label, defaultColor, callback)
            local row = makeRow(64)
            local left = make("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -160, 0, 20),
                Text = tostring(label),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = theme.Text
            })
            left.Parent = row

            local preview = make("Frame", {
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(1, -40, 0, 8),
                BackgroundColor3 = defaultColor or theme.Accent,
                BorderSizePixel = 0
            }, { corner(8), make("UIStroke", { Thickness = 1, Color = theme.Stroke }) })
            preview.Parent = row

            -- Simple palette
            local palette = make("Frame", {
                Size = UDim2.new(1, -60, 0, 32),
                Position = UDim2.new(0, 0, 0, 28),
                BackgroundTransparency = 1
            }, {
                listlayout(Enum.FillDirection.Horizontal, 6)
            })
            palette.Parent = row

            local colors = {
                theme.Accent, theme.AccentDim,
                Color3.fromRGB(255,90,90), Color3.fromRGB(80,200,120),
                Color3.fromRGB(90,170,255), Color3.fromRGB(190,90,255),
                Color3.fromRGB(255,160,70), Color3.fromRGB(255,255,255)
            }

            for _, c in ipairs(colors) do
                local swatch = make("TextButton", {
                    Size = UDim2.new(0, 28, 0, 28),
                    BackgroundColor3 = c,
                    Text = "",
                    AutoButtonColor = false
                }, { corner(6), make("UIStroke", { Thickness = 1, Color = theme.Stroke }) })
                swatch.Parent = palette
                hoverColorize(swatch, c, c:Lerp(Color3.new(1,1,1), 0.08))
                swatch.MouseButton1Click:Connect(function()
                    preview.BackgroundColor3 = c
                    if callback then pcall(callback, c) end
                end)
            end

            autoResizeSection()
            return function(c)
                preview.BackgroundColor3 = c
                if callback then pcall(callback, c) end
            end
        end

        function section:addSlider(label, min, max, default, callback)
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            default = math.clamp(tonumber(default) or min, min, max)

            local row = makeRow(40)
            local top = make("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Text = string.format("%s: %d", tostring(label), default),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = theme.Text
            })
            top.Parent = row

            local bar = make("Frame", {
                Size = UDim2.new(1, -4, 0, 8),
                Position = UDim2.new(0, 2, 0, 24),
                BackgroundColor3 = Color3.fromRGB(40,40,40),
                BorderSizePixel = 0
            }, { corner(4) })
            bar.Parent = row

            local fill = make("Frame", {
                Size = UDim2.new((default - min)/(max - min), 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0
            }, { corner(4) })
            fill.Parent = bar

            local dragging = false
            local function setFromX(x)
                local a = bar.AbsolutePosition.X
                local w = bar.AbsoluteSize.X
                local alpha = math.clamp((x - a) / math.max(1,w), 0, 1)
                local val = math.floor(min + alpha * (max - min) + 0.5)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                top.Text = string.format("%s: %d", tostring(label), val)
                if callback then pcall(callback, val) end
            end
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromX(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            autoResizeSection()
            return function(val)
                val = math.clamp(val, min, max)
                local alpha = (val - min) / (max - min)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                top.Text = string.format("%s: %d", tostring(label), val)
                if callback then pcall(callback, val) end
            end
        end

        function section:addDropdown(label, options, default, callback)
            options = options or {}
            local row = makeRow(32)
            local left = make("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -150, 1, 0),
                Text = tostring(label),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = theme.Text
            })
            left.Parent = row

            local btn = make("TextButton", {
                Size = UDim2.new(0, 140, 1, 0),
                Position = UDim2.new(1, -140, 0, 0),
                BackgroundColor3 = Color3.fromRGB(34,34,34),
                Text = tostring(default or "Select"),
                Font = Enum.Font.Arcade,
                TextSize = 16,
                TextColor3 = theme.SubText,
                AutoButtonColor = false
            }, { corner(8), make("UIStroke", { Thickness = 1, Color = theme.Stroke }) })
            btn.Parent = row
            hoverColorize(btn, Color3.fromRGB(34,34,34), theme.Hover)
            springBounce(btn)

            local listFrame = make("Frame", {
                Size = UDim2.new(0, 140, 0, 0),
                Position = UDim2.new(1, -140, 0, 34),
                BackgroundColor3 = Color3.fromRGB(26,26,26),
                BorderSizePixel = 0,
                Visible = false
            }, { corner(8), make("UIStroke", { Thickness = 1, Color = theme.Stroke }), padding(6), listlayout(Enum.FillDirection.Vertical, 6) })
            listFrame.Parent = row

            local function populate()
                for _, ch in ipairs(listFrame:GetChildren()) do
                    if ch:IsA("TextButton") then ch:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local o = make("TextButton", {
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = Color3.fromRGB(34,34,34),
                        Text = tostring(opt),
                        Font = Enum.Font.Arcade,
                        TextSize = 14,
                        TextColor3 = theme.Text,
                        AutoButtonColor = false
                    }, { corner(6) })
                    o.Parent = listFrame
                    hoverColorize(o, Color3.fromRGB(34,34,34), theme.Hover)
                    o.MouseButton1Click:Connect(function()
                        btn.Text = o.Text
                        listFrame.Visible = false
                        tween(listFrame, TweenInfo.new(0.12), { Size = UDim2.new(0, 140, 0, 0) }):Play()
                        if callback then pcall(callback, o.Text) end
                    end)
                end
                local count = #options
                tween(listFrame, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 140, 0, math.min(26*count + 12, 160))
                }):Play()
            end

            btn.MouseButton1Click:Connect(function()
                if listFrame.Visible then
                    listFrame.Visible = false
                    tween(listFrame, TweenInfo.new(0.12), { Size = UDim2.new(0, 140, 0, 0) }):Play()
                else
                    listFrame.Visible = true
                    populate()
                end
            end)

            autoResizeSection()
            return {
                SetOptions = function(newOptions)
                    options = newOptions or {}
                    if listFrame.Visible then populate() end
                end,
                SetValue = function(val)
                    btn.Text = tostring(val)
                    if callback then pcall(callback, btn.Text) end
                end
            }
        end

        function section:Resize(size)
            frame.Size = size
        end

        table.insert(pageObj.Sections, section)
        autoResizeSection()
        return section
    end

    function pageObj.addResize(size)
        pageContainer.Size = size
    end

    _state.Pages[name] = pageObj
    table.insert(_state.PageOrder, name)
    return pageObj
end

-- UI.addSelectPage
function UI.addSelectPage(name)
    local page = _state.Pages[name]
    if not page then return end
    for n, p in pairs(_state.Pages) do
        p.Container.Visible = false
        if p.Button then
            tween(p.Button, TweenInfo.new(0.12), { TextColor3 = _state.Theme.Text }):Play()
        end
    end
    page.Container.Visible = true
    tween(page.Button, TweenInfo.new(0.12), { TextColor3 = _state.Theme.Accent }):Play()
    _state.CurrentPage = name
    slideInSections(page.Container)
end

-- Close on RightControl default (optional usability)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        UI.Toggle()
    end
end)

-- Return library
return UI
