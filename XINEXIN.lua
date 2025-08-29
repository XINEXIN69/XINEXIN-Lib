--[[
    XINEXIN HUB - Minimal / Flat UI Library
    Theme: Dark Yellow
    Font: Pixel Bold (PressStart2P)
    Text Color: White
    Window Size: UDim2.new(0, 735, 0, 379)
    Window Position: UDim2.new(0.26607, 0, 0.26773, 0)

    API (UI):
      UI.addPage(name) -> Page
      UI.addNotify(message)
      UI.addSelectPage(name)
      UI.SetTheme(themeTableOrName)
      UI.Toggle()

    API (Page):
      Page.addSection(name) -> Section
      Page.addResize(sizeUDim2)

    API (Section):
      Section:addButton(name, callback)
      Section:addToggle(name, defaultBool, callback)
      Section:addTextbox(name, defaultText, callback)
      Section:addKeybind(name, defaultKeyCode, callback)
      Section:addColorPicker(name, defaultColor3, callback)
      Section:addSlider(name, min, max, defaultNumber, callback)
      Section:addDropdown(name, optionsTable, defaultValue, callback)
      Section:Resize(sizeUDim2)

    Notes:
      - Safe, self-contained UI-only library.
      - Animations: blur background, zoom-in on open, hover bounce + color, section slide-in.
      - Toggle icon: show/hide UI, draggable.
      - Auto layout: pages, sections, and controls flow automatically.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = (LOCAL_PLAYER and LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")) or nil

-- Utils
local function t(target, props, info)
    return TweenService:Create(target, info or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

local function make(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = inst
    end
    return inst
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function round(n, step)
    step = step or 1
    return math.floor(n/step + 0.5) * step
end

local function safeUDim2(value, fallback)
    if typeof(value) == "UDim2" then return value end
    return fallback
end

-- Theme presets
local Themes = {
    DarkYellow = {
        Font = Enum.Font.Arcade -- pixel-styled bold font
        TextColor = rgb(255,255,255),
        Backdrop = rgb(18,18,18),
        Window = rgb(24,24,24),
        Accent = rgb(255,204,0),
        AccentSoft = rgb(120,90,0),
        Stroke = rgb(50,50,50),
        PageIdle = rgb(40,40,40),
        PageHover = rgb(60,60,60),
        Control = rgb(32,32,32),
        ControlHover = rgb(48,48,48),
        ToggleOn = rgb(255,214,10),
        ToggleOff = rgb(90,90,90),
        SliderFill = rgb(255,204,0),
        Dropdown = rgb(28,28,28),
        Notify = rgb(35,35,35),
    }
}

-- Blur manager
local BlurControl = {}
do
    local blur
    function BlurControl.Enable(targetSize)
        if not blur then
            blur = Instance.new("BlurEffect")
            blur.Size = 0
            blur.Parent = Lighting
        end
        t(blur, { Size = targetSize or 12 }, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
    end
    function BlurControl.Disable()
        if not blur then return end
        local tw = t(blur, { Size = 0 }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        tw.Completed:Connect(function()
            if blur then blur:Destroy(); blur = nil end
        end)
        tw:Play()
    end
end

-- Drag helper
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

-- Hover bounce
local function bounce(uiObject)
    pcall(function()
        t(uiObject, { Size = uiObject.Size + UDim2.new(0, 2, 0, 2) }, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
        task.delay(0.12, function()
            if uiObject then
                t(uiObject, { Size = uiObject.Size - UDim2.new(0, 2, 0, 2) }, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)):Play()
            end
        end)
    end)
end

-- Slide-in list animation
local function slideIn(container)
    local i = 0
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") then
            i += 1
            local original = child.Position
            child.Position = original + UDim2.new(0, -20, 0, 0)
            child.Transparency = 1
            task.delay(0.02 * i, function()
                if child then
                    t(child, { Position = original, Transparency = 0 }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
                end
            end)
        end
    end
end

-- UI Library
local function CreateLibrary()
    local UI = {}
    local State = {
        Theme = Themes.DarkYellow,
        Pages = {},
        PageMap = {},
        SelectedPage = nil,
        Open = true,
    }

    -- Root gui
    local screenGui = make("ScreenGui", {
        Name = "XINEXIN_HUB",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })

    -- Toggle icon (freely movable)
    local toggleIcon = make("TextButton", {
        Name = "ToggleIcon",
        Parent = screenGui,
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 20, 0.5, -22),
        Text = "≡",
        TextScaled = true,
        BackgroundColor3 = Themes.DarkYellow.Accent,
        TextColor3 = Themes.DarkYellow.TextColor,
        Font = Themes.DarkYellow.Font,
        AutoButtonColor = false,
    }, {
        make("UICorner", { CornerRadius = UDim.new(1,0) }),
        make("UIStroke", { Color = Themes.DarkYellow.Stroke, Thickness = 1 }),
    })

    -- Main window
    local window = make("Frame", {
        Name = "Window",
        Parent = screenGui,
        Size = UDim2.new(0, 735, 0, 379),
        Position = UDim2.new(0.26607, 0, 0.26773, 0),
        BackgroundColor3 = Themes.DarkYellow.Window,
        BorderSizePixel = 0,
        Visible = true
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 10) }),
        make("UIStroke", { Color = Themes.DarkYellow.Stroke, Thickness = 1 }),
    })

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = window

    -- Top bar
    local topBar = make("Frame", {
        Name = "TopBar",
        Parent = window,
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Themes.DarkYellow.Backdrop,
        BorderSizePixel = 0
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 10) }),
        make("UIStroke", { Color = Themes.DarkYellow.Stroke, Thickness = 1 }),
    })

    local hubTitle = make("TextLabel", {
        Name = "Title",
        Parent = topBar,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "XINEXIN HUB",
        TextColor3 = Themes.DarkYellow.TextColor,
        Font = Themes.DarkYellow.Font,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    makeDraggable(window, topBar)

    -- Page bar
    local pageBar = make("Frame", {
        Name = "PageBar",
        Parent = window,
        Size = UDim2.new(0, 170, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = Themes.DarkYellow.Backdrop,
        BorderSizePixel = 0
    }, {
        make("UIStroke", { Color = Themes.DarkYellow.Stroke, Thickness = 1 }),
    })

    local pageList = make("UIListLayout", {
        Parent = pageBar,
        Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Begin,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local pagePad = make("UIPadding", {
        Parent = pageBar,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })

    -- Section area
    local sectionArea = make("Frame", {
        Name = "SectionArea",
        Parent = window,
        Size = UDim2.new(1, -170, 1, -44),
        Position = UDim2.new(0, 170, 0, 44),
        BackgroundColor3 = Themes.DarkYellow.Window,
        BorderSizePixel = 0
    }, {
        make("UIStroke", { Color = Themes.DarkYellow.Stroke, Thickness = 1 }),
    })

    local sectionPages = {} -- pageName -> scrollingFrame

    -- Notifications holder
    local notifyHolder = make("Frame", {
        Name = "NotifyHolder",
        Parent = screenGui,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 320, 1, -40),
        BackgroundTransparency = 1
    }, {
        make("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })

    -- Toggle behavior (icon)
    local function toggleUI()
        State.Open = not State.Open
        if State.Open then
            screenGui.Enabled = true
            window.Visible = true
            scale.Scale = 0.9
            BlurControl.Enable(12)
            t(scale, { Scale = 1 }, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
        else
            BlurControl.Disable()
            local tw = t(scale, { Scale = 0.92 }, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
            tw.Completed:Connect(function()
                if window then window.Visible = false end
                screenGui.Enabled = false
            end)
            tw:Play()
        end
    end

    toggleIcon.MouseButton1Click:Connect(function()
        toggleUI()
        bounce(toggleIcon)
    end)
    makeDraggable(toggleIcon, toggleIcon)

    -- Attach to PlayerGui (or CoreGui if needed)
    local parentTarget = PLAYER_GUI or game:GetService("CoreGui")
    screenGui.Parent = parentTarget

    -- Theme application
    local function applyTheme(th)
        State.Theme = th
        local theme = th

        toggleIcon.BackgroundColor3 = theme.Accent
        toggleIcon.TextColor3 = theme.TextColor
        toggleIcon.Font = theme.Font

        window.BackgroundColor3 = theme.Window
        topBar.BackgroundColor3 = theme.Backdrop
        hubTitle.TextColor3 = theme.TextColor
        hubTitle.Font = theme.Font

        pageBar.BackgroundColor3 = theme.Backdrop

        for _, obj in ipairs({window, topBar, pageBar, sectionArea}) do
            local stroke = obj:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = theme.Stroke end
        end

        -- Update all dynamic children (pages, sections, controls)
        for _, page in pairs(State.Pages) do
            if page._button then
                page._button.BackgroundColor3 = theme.PageIdle
                page._button.TextColor3 = theme.TextColor
                page._button.Font = theme.Font
            end
            local container = sectionPages[page.Name]
            if container then
                container.ScrollBarImageColor3 = theme.Accent
                for _, sec in ipairs(container:GetChildren()) do
                    if sec:IsA("Frame") and sec:FindFirstChild("Header") then
                        sec.BackgroundColor3 = theme.Control
                        local stroke = sec:FindFirstChildOfClass("UIStroke")
                        if stroke then stroke.Color = theme.Stroke end
                        local header = sec.Header
                        header.TextColor3 = theme.TextColor
                        header.Font = theme.Font
                    end
                end
            end
        end
    end

    -- Public API: UI
    function UI.SetTheme(theme)
        if typeof(theme) == "string" and Themes[theme] then
            applyTheme(Themes[theme])
        elseif typeof(theme) == "table" then
            applyTheme(theme)
        else
            applyTheme(Themes.DarkYellow)
        end
    end

    function UI.Toggle()
        toggleUI()
    end

    function UI.addNotify(message)
        local theme = State.Theme
        local note = make("Frame", {
            Parent = notifyHolder,
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = theme.Notify,
            BorderSizePixel = 0,
            Transparency = 1
        }, {
            make("UICorner", { CornerRadius = UDim.new(0, 8) }),
            make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
        })
        local label = make("TextLabel", {
            Parent = note,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            Text = tostring(message or ""),
            TextColor3 = theme.TextColor,
            Font = theme.Font,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        t(note, { Transparency = 0 }, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
        task.delay(2.2, function()
            if note then
                local tw = t(note, { Transparency = 1 }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
                tw.Completed:Connect(function()
                    if note then note:Destroy() end
                end)
                tw:Play()
            end
        end)
    end

    function UI.addSelectPage(name)
        local page = State.PageMap[name]
        if not page then return end
        if State.SelectedPage == page then return end

        -- Update buttons
        for _, p in pairs(State.Pages) do
            if p._button then
                t(p._button, { BackgroundColor3 = State.Theme.PageIdle }, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
            end
        end
        if page._button then
            t(page._button, { BackgroundColor3 = State.Theme.PageHover }, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
        end

        -- Show selected page container
        for pname, cont in pairs(sectionPages) do
            cont.Visible = (pname == name)
        end
        State.SelectedPage = page

        local cont = sectionPages[name]
        if cont then slideIn(cont) end
    end

    function UI.addPage(name)
        name = tostring(name or ("Page" .. tostring(#State.Pages + 1)))
        if State.PageMap[name] then return State.PageMap[name] end

        local theme = State.Theme

        -- Create page button
        local btn = make("TextButton", {
            Parent = pageBar,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.PageIdle,
            Text = name,
            TextColor3 = theme.TextColor,
            Font = theme.Font,
            TextSize = 12,
            AutoButtonColor = false
        }, {
            make("UICorner", { CornerRadius = UDim.new(0, 8) }),
            make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
        })

        btn.MouseEnter:Connect(function()
            bounce(btn)
            t(btn, { BackgroundColor3 = theme.PageHover }, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
        end)
        btn.MouseLeave:Connect(function()
            if State.SelectedPage and State.SelectedPage.Name == name then return end
            t(btn, { BackgroundColor3 = theme.PageIdle }, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            UI.addSelectPage(name)
        end)

        -- Page container
        local scroll = make("ScrollingFrame", {
            Parent = sectionArea,
            Name = name,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarImageColor3 = theme.Accent
        })
        sectionPages[name] = scroll

        local list = make("UIListLayout", {
            Parent = scroll,
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Begin,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        local pad = make("UIPadding", {
            Parent = scroll,
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        })
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
        end)

        local Page = {
            Name = name,
            _button = btn,
            _container = scroll
        }

        function Page.addResize(sizeUDim2)
            Page._container.Size = safeUDim2(sizeUDim2, Page._container.Size)
        end

        function Page.addSection(secName)
            local section = make("Frame", {
                Parent = scroll,
                Size = UDim2.new(1, 0, 0, 72),
                BackgroundColor3 = theme.Control,
                BorderSizePixel = 0
            }, {
                make("UICorner", { CornerRadius = UDim.new(0, 8) }),
                make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
            })

            local secHeader = make("TextLabel", {
                Name = "Header",
                Parent = section,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -24, 0, 18),
                Font = theme.Font,
                Text = tostring(secName or "Section"),
                TextColor3 = theme.TextColor,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local content = make("Frame", {
                Parent = section,
                Position = UDim2.new(0, 10, 0, 28),
                Size = UDim2.new(1, -20, 1, -38),
                BackgroundTransparency = 1
            }, {
                make("UIListLayout", {
                    Padding = UDim.new(0, 6),
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Begin,
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            })

            local function makeControlBase(height)
                local f = make("Frame", {
                    Parent = content,
                    Size = UDim2.new(1, 0, 0, height or 34),
                    BackgroundColor3 = theme.Control,
                    BorderSizePixel = 0
                }, {
                    make("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
                })
                f.MouseEnter:Connect(function()
                    t(f, { BackgroundColor3 = theme.ControlHover }, TweenInfo.new(0.1)):Play()
                end)
                f.MouseLeave:Connect(function()
                    t(f, { BackgroundColor3 = theme.Control }, TweenInfo.new(0.1)):Play()
                end)
                return f
            end

            local Section = {}

            function Section:Resize(sizeUDim2)
                section.Size = safeUDim2(sizeUDim2, section.Size)
            end

            function Section:addButton(text, callback)
                local base = makeControlBase(34)
                local lbl = make("TextLabel", {
                    Parent = base,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = theme.Font,
                    Text = tostring(text or "Button"),
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local btn = make("TextButton", {
                    Parent = base,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 90, 0, 26),
                    Text = "RUN",
                    Font = theme.Font,
                    TextSize = 10,
                    TextColor3 = theme.Backdrop,
                    BackgroundColor3 = theme.Accent,
                    AutoButtonColor = false
                }, {
                    make("UICorner", { CornerRadius = UDim.new(0, 6) })
                })
                btn.MouseEnter:Connect(function() bounce(btn) end)
                btn.MouseButton1Click:Connect(function()
                    if callback then
                        task.spawn(callback)
                    end
                end)
                return base
            end

            function Section:addToggle(text, default, callback)
                local base = makeControlBase(34)
                local lbl = make("TextLabel", {
                    Parent = base,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -60, 1, 0),
                    Font = theme.Font,
                    Text = tostring(text or "Toggle"),
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local state = default and true or false
                local sw = make("TextButton", {
                    Parent = base,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 54, 0, 22),
                    BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff,
                    Text = "",
                    AutoButtonColor = false
                }, {
                    make("UICorner", { CornerRadius = UDim.new(1, 0) })
                })
                local knob = make("Frame", {
                    Parent = sw,
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = state and UDim2.new(1, -22, 0, 1) or UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = theme.Backdrop,
                    BorderSizePixel = 0
                }, {
                    make("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                sw.MouseButton1Click:Connect(function()
                    state = not state
                    t(sw, { BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff }, TweenInfo.new(0.1)):Play()
                    t(knob, { Position = state and UDim2.new(1, -22, 0, 1) or UDim2.new(0, 1, 0, 1) }, TweenInfo.new(0.1)):Play()
                    if callback then task.spawn(callback, state) end
                end)
                return {
                    Set = function(_, v)
                        state = not not v
                        sw.BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff
                        knob.Position = state and UDim2.new(1, -22, 0, 1) or UDim2.new(0, 1, 0, 1)
                        if callback then task.spawn(callback, state) end
                    end,
                    Get = function() return state end,
                }
            end

            function Section:addTextbox(text, default, callback)
                local base = makeControlBase(40)
                local lbl = make("TextLabel", {
                    Parent = base,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -160, 1, 0),
                    Font = theme.Font,
                    Text = tostring(text or "Textbox"),
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local box = make("TextBox", {
                    Parent = base,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 140, 0, 28),
                    Text = tostring(default or ""),
                    Font = theme.Font,
                    TextSize = 10,
                    TextColor3 = theme.TextColor,
                    BackgroundColor3 = theme.Dropdown
                }, {
                    make("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
                })
                box.FocusLost:Connect(function(enterPressed)
                    if callback then task.spawn(callback, box.Text) end
                end)
                return {
                    Set = function(_, v) box.Text = tostring(v or "") end,
                    Get = function() return box.Text end
                }
            end

            function Section:addKeybind(text, defaultKeyCode, callback)
                local base = makeControlBase(34)
                local lbl = make("TextLabel", {
                    Parent = base,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -140, 1, 0),
                    Font = theme.Font,
                    Text = tostring(text or "Keybind"),
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local current = defaultKeyCode or Enum.KeyCode.RightShift
                local bindBtn = make("TextButton", {
                    Parent = base,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 120, 0, 26),
                    Text = current.Name,
                    Font = theme.Font,
                    TextSize = 10,
                    TextColor3 = theme.TextColor,
                    BackgroundColor3 = theme.Dropdown,
                    AutoButtonColor = false
                }, {
                    make("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
                })

                local listening = false
                bindBtn.MouseButton1Click:Connect(function()
                    listening = true
                    bindBtn.Text = "Press..."
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
                        listening = false
                        current = input.KeyCode
                        bindBtn.Text = current.Name
                        if callback then task.spawn(callback, current) end
                    elseif input.KeyCode == current then
                        if callback then task.spawn(callback, current, "fired") end
                    end
                end)

                return {
                    Set = function(_, kc)
                        if typeof(kc) == "EnumItem" and kc.EnumType == Enum.KeyCode then
                            current = kc
                            bindBtn.Text = current.Name
                            if callback then task.spawn(callback, current) end
                        end
                    end,
                    Get = function() return current end
                }
            end

            function Section:addColorPicker(text, default, callback)
                local base = makeControlBase(34)
                local lbl = make("TextLabel", {
                    Parent = base,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -140, 1, 0),
                    Font = theme.Font,
                    Text = tostring(text or "Color"),
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local color = default or rgb(255,204,0)
                local preview = make("TextButton", {
                    Parent = base,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 120, 0, 24),
                    Text = "",
                    BackgroundColor3 = color,
                    AutoButtonColor = false
                }, {
                    make("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
                })

                -- Simple palette popup
                local popup = make("Frame", {
                    Parent = base,
                    Position = UDim2.new(1, -130, 1, 6),
                    Size = UDim2.new(0, 120, 0, 84),
                    BackgroundColor3 = theme.Dropdown,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 5
                }, {
                    make("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
                    make("UIListLayout", {
                        Padding = UDim.new(0, 4),
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Wraps = true
                    }),
                    make("UIPadding", {
                        PaddingTop = UDim.new(0, 6),
                        PaddingLeft = UDim.new(0, 6),
                        PaddingRight = UDim.new(0, 6),
                        PaddingBottom = UDim.new(0, 6),
                    })
                })

                local presets = {
                    rgb(255,204,0), rgb(255,214,10), rgb(255,255,255), rgb(200,200,200), rgb(140,140,140),
                    rgb(255,90,90), rgb(90,255,120), rgb(90,180,255), rgb(180,90,255), rgb(255,140,90)
                }
                for _, c in ipairs(presets) do
                    local chip = make("TextButton", {
                        Parent = popup,
                        Size = UDim2.new(0, 32, 0, 24),
                        Text = "",
                        BackgroundColor3 = c,
                        AutoButtonColor = true
                    }, {
                        make("UICorner", { CornerRadius = UDim.new(0, 4) })
                    })
                    chip.MouseButton1Click:Connect(function()
                        color = c
                        preview.BackgroundColor3 = color
                        popup.Visible = false
                        if callback then task.spawn(callback, color) end
                    end)
                end

                preview.MouseButton1Click:Connect(function()
                    popup.Visible = not popup.Visible
                end)

                return {
                    Set = function(_, c)
                        if typeof(c) == "Color3" then
                            color = c
                            preview.BackgroundColor3 = c
                            if callback then task.spawn(callback, c) end
                        end
                    end,
                    Get = function() return color end
                }
            end

            function Section:addSlider(text, min, max, defaultValue, callback)
                min, max = tonumber(min) or 0, tonumber(max) or 100
                local value = math.clamp(tonumber(defaultValue) or min, min, max)

                local base = makeControlBase(40)
                local lbl = make("TextLabel", {
                    Parent = base,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -160, 1, 0),
                    Font = theme.Font,
                    Text = string.format("%s: %s", tostring(text or "Slider"), tostring(value)),
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local bar = make("Frame", {
                    Parent = base,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 160, 0, 8),
                    BackgroundColor3 = theme.Dropdown,
                    BorderSizePixel = 0
                }, {
                    make("UICorner", { CornerRadius = UDim.new(1, 0) })
                })
                local fill = make("Frame", {
                    Parent = bar,
                    Size = UDim2.new((value - min)/(max - min), 0, 1, 0),
                    BackgroundColor3 = theme.SliderFill,
                    BorderSizePixel = 0
                }, {
                    make("UICorner", { CornerRadius = UDim.new(1, 0) })
                })
                local knob = make("Frame", {
                    Parent = bar,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((value - min)/(max - min), 0, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0
                }, {
                    make("UICorner", { CornerRadius = UDim.new(1, 0) })
                })

                local dragging = false
                local function setFromX(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
                    value = round(min + rel * (max - min), 1)
                    fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
                    knob.Position = UDim2.new((value - min)/(max - min), 0, 0.5, 0)
                    lbl.Text = string.format("%s: %s", tostring(text or "Slider"), tostring(value))
                    if callback then task.spawn(callback, value) end
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        setFromX(input.Position.X)
                    end
                end)
                bar.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        setFromX(input.Position.X)
                    end
                end)

                return {
                    Set = function(_, v)
                        value = math.clamp(tonumber(v) or value, min, max)
                        fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
                        knob.Position = UDim2.new((value - min)/(max - min), 0, 0.5, 0)
                        lbl.Text = string.format("%s: %s", tostring(text or "Slider"), tostring(value))
                        if callback then task.spawn(callback, value) end
                    end,
                    Get = function() return value end
                }
            end

            function Section:addDropdown(text, options, defaultValue, callback)
                options = options or {}
                local current = defaultValue or (options[1] or "")

                local base = makeControlBase(34)
                local lbl = make("TextLabel", {
                    Parent = base,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -160, 1, 0),
                    Font = theme.Font,
                    Text = tostring(text or "Dropdown"),
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local main = make("TextButton", {
                    Parent = base,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 140, 0, 26),
                    Text = tostring(current),
                    Font = theme.Font,
                    TextSize = 10,
                    TextColor3 = theme.TextColor,
                    BackgroundColor3 = theme.Dropdown,
                    AutoButtonColor = false
                }, {
                    make("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
                })
                local list = make("Frame", {
                    Parent = base,
                    Position = UDim2.new(1, -150, 1, 6),
                    Size = UDim2.new(0, 140, 0, 120),
                    BackgroundColor3 = theme.Dropdown,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 4
                }, {
                    make("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
                    make("UIListLayout", {
                        Padding = UDim.new(0, 4),
                        FillDirection = Enum.FillDirection.Vertical,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        VerticalAlignment = Enum.VerticalAlignment.Begin,
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    make("UIPadding", {
                        PaddingTop = UDim.new(0, 6),
                        PaddingLeft = UDim.new(0, 6),
                        PaddingRight = UDim.new(0, 6),
                        PaddingBottom = UDim.new(0, 6),
                    })
                })

                local function rebuild()
                    for _, c in ipairs(list:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local btn = make("TextButton", {
                            Parent = list,
                            Size = UDim2.new(1, 0, 0, 24),
                            Text = tostring(opt),
                            Font = theme.Font,
                            TextSize = 10,
                            TextColor3 = theme.TextColor,
                            BackgroundColor3 = theme.Control,
                            AutoButtonColor = true
                        }, {
                            make("UICorner", { CornerRadius = UDim.new(0, 4) })
                        })
                        btn.MouseEnter:Connect(function() t(btn, { BackgroundColor3 = theme.ControlHover }, TweenInfo.new(0.08)):Play() end)
                        btn.MouseLeave:Connect(function() t(btn, { BackgroundColor3 = theme.Control }, TweenInfo.new(0.08)):Play() end)
                        btn.MouseButton1Click:Connect(function()
                            current = opt
                            main.Text = tostring(current)
                            list.Visible = false
                            if callback then task.spawn(callback, current) end
                        end)
                    end
                end
                rebuild()

                main.MouseButton1Click:Connect(function()
                    list.Visible = not list.Visible
                    if list.Visible then bounce(main) end
                end)

                return {
                    Set = function(_, val)
                        current = val
                        main.Text = tostring(current)
                        if callback then task.spawn(callback, current) end
                    end,
                    Get = function() return current end,
                    SetOptions = function(_, newOptions)
                        options = newOptions or {}
                        rebuild()
                    end
                }
            end

            return Section
        end

        table.insert(State.Pages, Page)
        State.PageMap[name] = Page

        -- Auto-select first page
        if not State.SelectedPage then
            UI.addSelectPage(name)
        end

        return Page
    end

    -- Initialize theme + entrance effects
    UI.SetTheme("DarkYellow")
    BlurControl.Enable(12)
    scale.Scale = 0.9
    t(scale, { Scale = 1 }, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)):Play()

    -- Close on RightShift by default (matches common toggles)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            UI.Toggle()
        end
    end)

    return UI
end

-- Return library for require()
return CreateLibrary()
