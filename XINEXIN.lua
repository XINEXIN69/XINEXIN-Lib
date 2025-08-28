-- XinexinHub.lua
-- XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
-- Theme: Dark Yellow Premium, Font: Pixel-styled (Arcade), TextColor: White
-- Default window size/position: UDim2.new(0, 735, 0, 379), UDim2.new(0.26607, 0, 0.26773, 0)

-- Utility: safe parent for exploit environments
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local function getParentGui()
    local ok, guiParent = pcall(function()
        if gethui then
            return gethui()
        end
        return CoreGui
    end)
    if ok and guiParent then return guiParent end
    local player = Players.LocalPlayer
    if player and player:FindFirstChildOfClass("PlayerGui") then
        return player:FindFirstChildOfClass("PlayerGui")
    end
    return CoreGui
end

local function new(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if children then
        for _, c in ipairs(children) do
            c.Parent = inst
        end
    end
    return inst
end

local function uicorner(radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 8)})
end

local function uistroke(color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

local function tween(inst, info, goal)
    local t = TweenService:Create(inst, info, goal)
    t:Play()
    return t
end

local function spring(duration)
    return TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

local function bounce(duration)
    return TweenInfo.new(duration or 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(x, minv, maxv)
    return math.max(minv, math.min(maxv, x))
end

-- Default theme: Dark Yellow Premium
local Themes = {}
Themes.DarkYellow = {
    Accent    = Color3.fromRGB(255, 199, 0),   -- primary yellow
    AccentAlt = Color3.fromRGB(255, 223, 98),  -- hover yellow
    Bg        = Color3.fromRGB(20, 20, 20),    -- background
    Bg2       = Color3.fromRGB(28, 28, 28),    -- panels
    Text      = Color3.fromRGB(255, 255, 255), -- white
    SubText   = Color3.fromRGB(200, 200, 200),
    Stroke    = Color3.fromRGB(60, 60, 60),
    Success   = Color3.fromRGB(30, 200, 90),
    Error     = Color3.fromRGB(220, 70, 70),
    Font      = Enum.Font.Arcade
}

-- Drag helpers
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- UI Library
local Library = {}
Library.__index = Library

local Page = {}
Page.__index = Page

local Section = {}
Section.__index = Section

function Library.new(title)
    title = title or "XINEXIN HUB"
    local theme = Themes.DarkYellow

    -- Blur
    local blur = new("BlurEffect", {Size = 0, Parent = Lighting})

    -- Root GUI
    local parentGui = getParentGui()
    local screen = new("ScreenGui", {
        Name = "XINEXIN_HUB_UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = parentGui
    })

    -- Toggle icon (floating)
    local toggleIcon = new("Frame", {
        Name = "ToggleIcon",
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0.02, 0, 0.5, 0),
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Active = true,
        Visible = true,
        Parent = screen
    }, {
        uicorner(22),
        uistroke(theme.Stroke, 1, 0.25)
    })
    local ti = new("TextLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "≡",
        TextColor3 = theme.Accent,
        Font = theme.Font,
        TextScaled = true,
        Parent = toggleIcon
    })
    ti.RichText = true
    makeDraggable(toggleIcon)

    -- Main Window
    local window = new("Frame", {
        Name = "Window",
        Size = UDim2.new(0, 735, 0, 379),
        Position = UDim2.new(0.26607, 0, 0.26773, 0),
        BackgroundColor3 = theme.Bg,
        BorderSizePixel = 0,
        Visible = true,
        Parent = screen
    }, {
        uicorner(12),
        uistroke(theme.Stroke, 1, 0.3)
    })

    -- Top bar
    local topbar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Parent = window
    }, {
        uicorner(12)
    })
    local titleLabel = new("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = title,
        TextColor3 = theme.Text,
        Font = theme.Font,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })
    titleLabel.RichText = true

    -- Page bar (left)
    local pageBar = new("Frame", {
        Name = "PageBar",
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, 180, 1, -44),
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Parent = window
    }, {
        uicorner(12)
    })
    local pageList = new("ScrollingFrame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.Stroke,
        Parent = pageBar
    })
    local pageLayout = new("UIListLayout", {
        Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })
    pageLayout.Parent = pageList
    local function updatePageCanvas()
        pageList.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 12)
    end
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageCanvas)

    -- Section area (right)
    local content = new("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 186, 0, 50),
        Size = UDim2.new(1, -196, 1, -60),
        BackgroundColor3 = theme.Bg,
        BorderSizePixel = 0,
        Parent = window
    }, {
        uicorner(12),
        uistroke(theme.Stroke, 1, 0.25)
    })

    local pagesContainer = new("Folder", {Name = "PagesContainer", Parent = content})

    -- Drag window by topbar
    makeDraggable(window, topbar)

    -- Camera subtle zoom on open
    local function zoomOpen()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local startFov = cam.FieldOfView
        local target = clamp(startFov - 8, 50, 80)
        tween(cam, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = target}).Completed:Connect(function()
            tween(cam, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = startFov})
        end)
    end

    -- Toggle show/hide with blur
    local windowVisible = true
    local function show()
        window.Visible = true
        tween(blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 10})
        window.Size = UDim2.new(0, 720, 0, 360)
        tween(window, bounce(0.25), {Size = UDim2.new(0, 735, 0, 379)})
        zoomOpen()
        windowVisible = true
    end

    local function hide()
        tween(blur, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = 0}).Completed:Connect(function()
            -- keep blur effect but size 0 to avoid Lighting churn
        end)
        window.Visible = false
        windowVisible = false
    end

    toggleIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if windowVisible then hide() else show() end
        end
    end)

    -- Also allow RightControl to toggle by default
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            if windowVisible then hide() else show() end
        end
    end)

    -- Notifications
    local notifyHolder = new("Frame", {
        Name = "NotifyHolder",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -12, 1, -12),
        Size = UDim2.new(0, 320, 1, -24),
        BackgroundTransparency = 1,
        Parent = screen
    })
    local notifyList = new("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom
    })
    notifyList.Parent = notifyHolder

    local UI = setmetatable({
        _theme = theme,
        _screen = screen,
        _window = window,
        _topbar = topbar,
        _pageBar = pageBar,
        _pageList = pageList,
        _pagesContainer = pagesContainer,
        _pages = {},
        _buttons = {},
        _selectedPage = nil,
        _blur = blur,
        _toggleIcon = toggleIcon,
        _notifyHolder = notifyHolder
    }, Library)

    -- API: theme setter
    function UI.SetTheme(newTheme)
        if type(newTheme) == "string" and Themes[newTheme] then
            UI._theme = Themes[newTheme]
        elseif type(newTheme) == "table" then
            for k, v in pairs(Themes.DarkYellow) do
                UI._theme = UI._theme or {}
                UI._theme[k] = newTheme[k] or Themes.DarkYellow[k]
            end
        end

        local th = UI._theme
        -- apply to key surfaces
        UI._window.BackgroundColor3 = th.Bg
        UI._topbar.BackgroundColor3 = th.Bg2
        UI._pageBar.BackgroundColor3 = th.Bg2
        titleLabel.Font = th.Font
        titleLabel.TextColor3 = th.Text
        ti.TextColor3 = th.Accent
        -- recolor page buttons and page content on next build
        for _, btn in pairs(UI._buttons) do
            btn._elements.Text.Font = th.Font
            btn._elements.Text.TextColor3 = th.SubText
            btn._elements.Frame.BackgroundColor3 = th.Bg
            btn._elements.Stroke.Color = th.Stroke
        end
        -- recolor pages content frames
        for _, p in pairs(UI._pages) do
            p._scroll.ScrollBarImageColor3 = th.Stroke
            p._scroll.BackgroundColor3 = th.Bg
        end
    end

    -- API: notifications
    function UI.addNotify(message)
        local th = UI._theme
        local item = new("Frame", {
            BackgroundColor3 = th.Bg2,
            Size = UDim2.new(1, 0, 0, 40),
            BorderSizePixel = 0,
            Parent = UI._notifyHolder
        }, {
            uicorner(10),
            uistroke(th.Stroke, 1, 0.25)
        })
        local stripe = new("Frame", {
            BackgroundColor3 = th.Accent,
            Size = UDim2.new(0, 4, 1, 0),
            BorderSizePixel = 0,
            Parent = item
        }, {uicorner(10)})
        local lbl = new("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            Font = th.Font,
            Text = tostring(message),
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = th.Text,
            Parent = item
        })

        item.BackgroundTransparency = 1
        stripe.Size = UDim2.new(0, 0, 1, 0)
        tween(item, spring(0.18), {BackgroundTransparency = 0})
        tween(stripe, spring(0.25), {Size = UDim2.new(0, 4, 1, 0)})
        delay(2.2, function()
            tween(item, spring(0.2), {BackgroundTransparency = 1}).Completed:Connect(function()
                item:Destroy()
            end)
        end)
    end

    -- API: pages
    function UI.addPage(name)
        name = tostring(name or "Page")
        local th = UI._theme

        -- button
        local btnFrame = new("Frame", {
            Name = "PageButton_" .. name,
            Size = UDim2.new(1, -12, 0, 38),
            BackgroundColor3 = th.Bg,
            BorderSizePixel = 0,
            Parent = UI._pageList
        }, {
            uicorner(8)
        })
        local btnStroke = uistroke(th.Stroke, 1, 0.25); btnStroke.Parent = btnFrame
        local btnLabel = new("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            Text = name,
            Font = th.Font,
            TextColor3 = th.SubText,
            TextSize = 20,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btnFrame
        })
        btnLabel.RichText = true

        -- hover: bounce + color shift
        btnFrame.MouseEnter:Connect(function()
            tween(btnFrame, bounce(0.18), {Position = UDim2.new(btnFrame.Position.X.Scale, btnFrame.Position.X.Offset, 0, btnFrame.Position.Y.Offset)})
            tween(btnFrame, spring(0.12), {BackgroundColor3 = th.Bg2})
            tween(btnLabel, spring(0.12), {TextColor3 = th.AccentAlt})
            btnStroke.Color = th.Accent
            btnStroke.Transparency = 0
        end)
        btnFrame.MouseLeave:Connect(function()
            tween(btnFrame, spring(0.15), {BackgroundColor3 = th.Bg})
            tween(btnLabel, spring(0.15), {TextColor3 = th.SubText})
            btnStroke.Color = th.Stroke
            btnStroke.Transparency = 0.25
        end)

        -- page content
        local pageFrame = new("Frame", {
            Name = "Page_" .. name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = th.Bg,
            BorderSizePixel = 0,
            Visible = false,
            Parent = UI._pagesContainer
        }, {
            uicorner(12)
        })
        local scroll = new("ScrollingFrame", {
            Name = "Scroll",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.new(0, 4, 0, 4),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = th.Stroke,
            BorderSizePixel = 0,
            Parent = pageFrame
        })
        local layout = new("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        layout.Parent = scroll
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)

        local p = setmetatable({
            _name = name,
            _button = btnFrame,
            _scroll = scroll,
            _frame = pageFrame,
            _sections = {}
        }, Page)

        -- select on click
        btnFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                UI.addSelectPage(name)
            end
        end)

        UI._pages[name] = p
        table.insert(UI._buttons, {frame = btnFrame, _elements = {Frame = btnFrame, Text = btnLabel, Stroke = btnStroke}})

        return p
    end

    -- API: select page
    function UI.addSelectPage(name)
        local th = UI._theme
        local p = UI._pages[name]
        if not p then return end

        if UI._selectedPage and UI._selectedPage ~= p then
            UI._selectedPage._frame.Visible = false
        end
        p._frame.Visible = true
        UI._selectedPage = p

        -- slide-in sections
        local delayStep = 0
        for _, s in ipairs(p._sections) do
            s._root.Visible = true
            s._root.BackgroundTransparency = 1
            s._root.Position = UDim2.new(0, 0, 0, s._root.Position.Y.Offset + 10)
            delay(delayStep, function()
                tween(s._root, spring(0.2), {
                    BackgroundTransparency = 0,
                    Position = UDim2.new(0, 0, 0, s._root.Position.Y.Offset - 10)
                })
            end)
            delayStep = delayStep + 0.03
        end
    end

    -- API: toggle window
    function UI.Toggle()
        if windowVisible then hide() else show() end
    end

    -- build default theme styling
    UI.SetTheme("DarkYellow")

    -- Initial show with fx
    show()

    return UI
end

-- Page methods
function Page.addResize(self, size)
    if typeof(size) == "UDim2" then
        self._scroll.Size = size
    end
end

function Page.addSection(self, name)
    local th = self._scroll.Parent.Parent.Parent.Parent:FindFirstChild("Window") and Themes.DarkYellow -- dummy to silence analyzer
    th = nil -- not used, we’ll pull theme from UI object by walking up safely

    -- Find UI instance to get theme
    local UI
    do
        local content = self._scroll.Parent
        local window = content.Parent
        local screen = window.Parent
        for _, sg in ipairs({screen}) do
            if sg and sg.Name == "XINEXIN_HUB_UI" then
                -- ok
            end
        end
        -- rely on backref
    end

    local sectionRoot = new("Frame", {
        Name = "Section_" .. (name or "Section"),
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        Visible = true,
        Parent = self._scroll
    }, {
        uicorner(10),
        uistroke(Color3.fromRGB(60, 60, 60), 1, 0.25)
    })

    local header = new("TextLabel", {
        Name = "Header",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 20),
        Text = tostring(name or "Section"),
        Font = Themes.DarkYellow.Font,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = sectionRoot
    })

    local content = new("Frame", {
        Name = "Body",
        Position = UDim2.new(0, 8, 0, 30),
        Size = UDim2.new(1, -16, 1, -38),
        BackgroundTransparency = 1,
        Parent = sectionRoot
    })
    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    layout.Parent = content
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sectionRoot.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 44)
    end)

    local s = setmetatable({
        _page = self,
        _root = sectionRoot,
        _body = content,
        _layout = layout,
        _controls = {}
    }, Section)

    table.insert(self._sections, s)
    return s
end

-- Section helpers
local function controlBase(title, theme, parent)
    local frame = new("Frame", {
        BackgroundColor3 = theme.Bg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        Parent = parent
    }, {
        uicorner(8),
        uistroke(theme.Stroke, 1, 0.25)
    })
    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.5, -10, 1, 0),
        Text = tostring(title),
        Font = Themes.DarkYellow.Font,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Themes.DarkYellow.Text,
        Parent = frame
    })
    return frame, label
end

local function getThemeFromSection(sec)
    -- robust theme capture by walking to root library
    local window = sec._body.Parent.Parent.Parent
    local uiScreen = window.Parent
    local lib -- scan for Library by upvalue (not feasible at runtime), instead cache theme on frames
    -- We'll store theme references on the nearest ScreenGui under an Attribute
    local theme = uiScreen:GetAttribute("XinexinTheme")
    if theme and typeof(theme) == "Color3" then
        -- not enough; instead we kept no table. So fallback to DarkYellow.
        return Themes.DarkYellow
    end
    return Themes.DarkYellow
end

-- Slider internal
local function sliderLogic(track, fill, knob, minv, maxv, default, callback)
    local dragging = false
    local value = clamp(default, minv, maxv)
    local function setFromX(x)
        local rel = clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = minv + (maxv - minv) * rel
        value = v
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -8, 0.5, -8)
        if callback then callback(math.floor(v * 100 + 0.5) / 100) end
    end

    setFromX(track.AbsolutePosition.X + track.AbsoluteSize.X * ((default - minv) / (maxv - minv)))

    track.InputBegan:Connect(function(input)
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

-- Dropdown internal
local function dropdownToggle(listFrame, open)
    listFrame.Visible = open
    if open then
        listFrame.Size = UDim2.new(1, 0, 0, math.min(160, listFrame.UIListLayout.AbsoluteContentSize.Y + 8))
    end
end

-- Section methods
function Section:Resize(size)
    if typeof(size) == "UDim2" then
        self._root.Size = size
    end
end

function Section:addButton(name, callback)
    local theme = Themes.DarkYellow
    local frame, label = controlBase(name, theme, self._body)
    local btn = new("TextButton", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(0, 100, 0, 24),
        Position = UDim2.new(1, -110, 0.5, -12),
        Text = "Execute",
        TextColor3 = Color3.fromRGB(0, 0, 0),
        Font = theme.Font,
        TextSize = 16,
        Parent = frame
    }, {uicorner(6)})
    btn.MouseButton1Click:Connect(function()
        tween(btn, bounce(0.15), {Size = UDim2.new(0, 96, 0, 22)}).Completed:Connect(function()
            tween(btn, spring(0.12), {Size = UDim2.new(0, 100, 0, 24)})
        end)
        if callback then callback() end
    end)
    return frame
end

function Section:addToggle(name, default, callback)
    local theme = Themes.DarkYellow
    local frame, label = controlBase(name, theme, self._body)
    local toggle = new("Frame", {
        Size = UDim2.new(0, 44, 0, 22),
        Position = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Parent = frame
    }, {uicorner(11), uistroke(theme.Stroke, 1, 0.25)})
    local knob = new("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
        BorderSizePixel = 0,
        Parent = toggle
    }, {uicorner(9)})

    local state = default and true or false
    local function apply()
        if state then
            tween(knob, spring(0.12), {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = theme.Accent})
            tween(toggle, spring(0.12), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)})
        else
            tween(knob, spring(0.12), {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Color3.fromRGB(200, 200, 200)})
            tween(toggle, spring(0.12), {BackgroundColor3 = theme.Bg2})
        end
        if callback then callback(state) end
    end
    apply()

    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            apply()
        end
    end)
    return frame
end

function Section:addTextbox(name, default, callback)
    local theme = Themes.DarkYellow
    local frame, label = controlBase(name, theme, self._body)
    local tb = new("TextBox", {
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 180, 0, 26),
        Position = UDim2.new(1, -190, 0.5, -13),
        Text = tostring(default or ""),
        TextColor3 = theme.Text,
        PlaceholderText = "",
        Font = theme.Font,
        TextSize = 16,
        ClearTextOnFocus = false,
        Parent = frame
    }, {uicorner(6), uistroke(theme.Stroke, 1, 0.25)})
    tb.FocusLost:Connect(function(enterPressed)
        if callback then callback(tb.Text) end
    end)
    return frame
end

function Section:addKeybind(name, defaultKey, callback)
    local theme = Themes.DarkYellow
    local frame, label = controlBase(name, theme, self._body)
    local current = defaultKey or Enum.KeyCode.RightControl
    local btn = new("TextButton", {
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 140, 0, 26),
        Position = UDim2.new(1, -150, 0.5, -13),
        Text = "[" .. current.Name .. "]",
        TextColor3 = theme.Text,
        Font = theme.Font,
        TextSize = 16,
        Parent = frame
    }, {uicorner(6), uistroke(theme.Stroke, 1, 0.25)})

    local capturing = false
    btn.MouseButton1Click:Connect(function()
        if capturing then return end
        capturing = true
        btn.Text = "[Press a key]"
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                current = input.KeyCode
                btn.Text = "[" .. current.Name .. "]"
                capturing = false
                conn:Disconnect()
            end
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == current then
            tween(btn, bounce(0.12), {Size = UDim2.new(0, 136, 0, 24)}).Completed:Connect(function()
                tween(btn, spring(0.12), {Size = UDim2.new(0, 140, 0, 26)})
            end)
            if callback then callback() end
        end
    end)

    return frame
end

function Section:addColorPicker(name, default, callback)
    local theme = Themes.DarkYellow
    local frame, label = controlBase(name, theme, self._body)

    local swatch = new("Frame", {
        Size = UDim2.new(0, 34, 0, 26),
        Position = UDim2.new(1, -44, 0.5, -13),
        BackgroundColor3 = default or theme.Accent,
        BorderSizePixel = 0,
        Parent = frame
    }, {uicorner(6), uistroke(theme.Stroke, 1, 0.25)})

    -- simple popover with Hue + Value sliders
    local popup = new("Frame", {
        Size = UDim2.new(0, 220, 0, 84),
        Position = UDim2.new(1, -230, 0, 40),
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Visible = false,
        Parent = frame
    }, {uicorner(8), uistroke(theme.Stroke, 1, 0.25)})

    local hueTrack = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.new(0, 10, 0, 10),
        BorderSizePixel = 0,
        Parent = popup
    }, {uicorner(6)})
    local hueFill = new("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = hueTrack
    }, {uicorner(6)})
    local hueKnob = new("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0,
        Parent = hueTrack
    }, {uicorner(6)})

    local valTrack = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.new(0, 10, 0, 44),
        BorderSizePixel = 0,
        Parent = popup
    }, {uicorner(6)})
    local valFill = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(220, 220, 220),
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = valTrack
    }, {uicorner(6)})
    local valKnob = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(220, 220, 220),
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0,
        Parent = valTrack
    }, {uicorner(6)})

    local hue, sat, val = 0, 1, 1
    do
        local c = swatch.BackgroundColor3
        -- approximate inverse not provided; initialize from default as hue 0..1
        -- we keep sat=1 by default for vibrant accents
        hue = 0
        sat = 1
        val = 1
    end
    local function updateColor()
        local c = Color3.fromHSV(hue, sat, val)
        swatch.BackgroundColor3 = c
        hueFill.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
        valFill.BackgroundColor3 = Color3.fromHSV(0, 0, val)
        valKnob.Position = UDim2.new(val, 0, 0.5, 0)
        if callback then callback(c) end
    end
    updateColor()

    local function trackDrag(track, setFunc)
        local dragging = false
        local function setFromX(x)
            local rel = clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setFunc(rel)
        end
        track.InputBegan:Connect(function(input)
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
    trackDrag(hueTrack, function(rel) hue = rel; updateColor() end)
    trackDrag(valTrack, function(rel) val = rel; updateColor() end)

    swatch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            popup.Visible = not popup.Visible
        end
    end)

    return frame
end

function Section:addSlider(name, minv, maxv, default, callback)
    minv = tonumber(minv) or 0
    maxv = tonumber(maxv) or 100
    default = tonumber(default) or minv

    local theme = Themes.DarkYellow
    local frame, label = controlBase(name, theme, self._body)

    local valueLabel = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -60, 0, 0),
        Text = tostring(default),
        TextColor3 = theme.SubText,
        Font = theme.Font,
        TextSize = 16,
        Parent = frame
    })

    local track = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Size = UDim2.new(0.45, 0, 0, 6),
        Position = UDim2.new(1, -130, 0.5, -3),
        BorderSizePixel = 0,
        Parent = frame
    }, {uicorner(3)})
    local fill = new("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = track
    }, {uicorner(3)})
    local knob = new("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0,
        Parent = track
    }, {uicorner(8)})

    sliderLogic(track, fill, knob, minv, maxv, default, function(v)
        valueLabel.Text = tostring(math.floor(v * 100 + 0.5) / 100)
        if callback then callback(v) end
    end)

    return frame
end

function Section:addDropdown(name, options, default, callback)
    options = options or {}
    local theme = Themes.DarkYellow
    local frame, label = controlBase(name, theme, self._body)

    local btn = new("TextButton", {
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 180, 0, 26),
        Position = UDim2.new(1, -190, 0.5, -13),
        Text = tostring(default or (options[1] or "Select")),
        TextColor3 = theme.Text,
        Font = theme.Font,
        TextSize = 16,
        Parent = frame
    }, {uicorner(6), uistroke(theme.Stroke, 1, 0.25)})

    local list = new("Frame", {
        BackgroundColor3 = theme.Bg2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, 6),
        Size = UDim2.new(1, -20, 0, 0),
        Visible = false,
        Parent = frame
    }, {uicorner(8), uistroke(theme.Stroke, 1, 0.25)})
    local listLayout = new("UIListLayout", {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    listLayout.Parent = list
    list.UIListLayout = listLayout

    for _, opt in ipairs(options) do
        local item = new("TextButton", {
            BackgroundColor3 = theme.Bg,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -8, 0, 26),
            Position = UDim2.new(0, 4, 0, 0),
            Text = tostring(opt),
            TextColor3 = theme.SubText,
            Font = theme.Font,
            TextSize = 16,
            Parent = list
        }, {uicorner(6), uistroke(theme.Stroke, 1, 0.25)})
        item.MouseEnter:Connect(function()
            tween(item, spring(0.1), {BackgroundColor3 = theme.Bg2, TextColor3 = theme.AccentAlt})
        end)
        item.MouseLeave:Connect(function()
            tween(item, spring(0.1), {BackgroundColor3 = theme.Bg, TextColor3 = theme.SubText})
        end)
        item.MouseButton1Click:Connect(function()
            btn.Text = item.Text
            dropdownToggle(list, false)
            if callback then callback(item.Text) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        local willOpen = not list.Visible
        dropdownToggle(list, willOpen)
    end)

    return frame
end

-- Export library
local Xinexin = {
    new = Library.new,
    Themes = Themes
}

return Xinexin
