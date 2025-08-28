-- XinexinHub.lua
-- XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
-- Theme: Dark Yellow Premium | Font: Pixel Bold (Arcade) | Text Color: White
-- Window Size: UDim2.new(0, 735, 0, 379) | Window Position: UDim2.new(0.26607, 0, 0.26773, 0)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local function safeParent(gui)
    local ok = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function new(instance, props)
    local obj = Instance.new(instance)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    return obj
end

local function uicorner(parent, radius)
    local c = new("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
    c.Parent = parent
    return c
end

local function uistroke(parent, color, thickness, transparency)
    local s = new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    })
    s.Parent = parent
    return s
end

local function uilist(parent, padding, vertical, sort)
    local l = new("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        FillDirection = vertical and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = sort or Enum.SortOrder.LayoutOrder
    })
    l.Parent = parent
    return l
end

local function uipadding(parent, p)
    local pad = new("UIPadding", {
        PaddingTop = UDim.new(0, p),
        PaddingBottom = UDim.new(0, p),
        PaddingLeft = UDim.new(0, p),
        PaddingRight = UDim.new(0, p),
    })
    pad.Parent = parent
    return pad
end

local function tween(o, ti, goal)
    return TweenService:Create(o, ti, goal)
end

local function makeShadow(parent, opacity)
    local s = new("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageTransparency = 1 - (opacity or 0.1),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = parent.ZIndex - 1
    })
    s.Parent = parent
    return s
end

local ThemePresets = {
    ["Dark Yellow Premium"] = {
        Name = "Dark Yellow Premium",
        Background = Color3.fromRGB(18, 18, 18),
        BackgroundAlt = Color3.fromRGB(25, 25, 25),
        Panel = Color3.fromRGB(28, 28, 28),
        Accent = Color3.fromRGB(201, 162, 39), -- Premium dark yellow
        AccentHover = Color3.fromRGB(223, 184, 61),
        AccentMuted = Color3.fromRGB(90, 72, 20),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(200, 200, 200),
        Stroke = Color3.fromRGB(45, 45, 45),
        SliderTrack = Color3.fromRGB(40, 40, 40),
        SliderFill = Color3.fromRGB(201, 162, 39),
        ToggleOn = Color3.fromRGB(201, 162, 39),
        ToggleOff = Color3.fromRGB(60, 60, 60),
        DropdownBG = Color3.fromRGB(22, 22, 22),
        NotifyBG = Color3.fromRGB(25, 25, 25),
    }
}

local defaultTheme = ThemePresets["Dark Yellow Premium"]

local function applyHoverBounce(button, baseColor, hoverColor)
    local scale = new("UIScale", { Scale = 1 })
    scale.Parent = button
    local enterConn, leaveConn
    enterConn = button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = hoverColor }):Play()
        tween(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.05 }):Play()
    end)
    leaveConn = button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = baseColor }):Play()
        tween(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
    end)
    return function()
        enterConn:Disconnect()
        leaveConn:Disconnect()
    end
end

local function makeDraggable(frame, dragHandle)
    local dragging, dragStart, startPos
    dragHandle = dragHandle or frame
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
            local delta = input.Position - dragStart
            if dragging then
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

local function clamp(n, minv, maxv)
    return math.clamp(n, minv, maxv)
end

local Xinexin = {}

function Xinexin.Create(config)
    config = config or {}
    local title = config.Title or "XINEXIN HUB"
    local theme = ThemePresets["Dark Yellow Premium"]
    local font = Enum.Font.Arcade -- Pixel-bold vibe
    local textColor = Color3.fromRGB(255, 255, 255)

    -- ScreenGuis
    local ScreenGui = new("ScreenGui", {
        Name = "XINEXIN_HUB",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })
    safeParent(ScreenGui)

    local ToggleGui = new("ScreenGui", {
        Name = "XINEXIN_TOGGLE",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })
    safeParent(ToggleGui)

    -- Blur effect (created on-demand)
    local blurEffect = nil
    local function setBlur(strength)
        if strength > 0 then
            if not blurEffect then
                blurEffect = new("BlurEffect", { Size = 0 })
                blurEffect.Parent = Lighting
            end
            tween(blurEffect, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = strength }):Play()
        else
            if blurEffect then
                tween(blurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 }):Play()
                task.delay(0.22, function()
                    if blurEffect then
                        blurEffect:Destroy()
                        blurEffect = nil
                    end
                end)
            end
        end
    end

    -- Main Window
    local Main = new("Frame", {
        Name = "Window",
        Parent = ScreenGui,
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 735, 0, 379),
        Position = UDim2.new(0.26607, 0, 0.26773, 0),
        Visible = true
    })
    uicorner(Main, 12)
    uistroke(Main, theme.Stroke, 1, 0.65)
    makeShadow(Main, 0.12)

    -- Zoom scale for open animation
    local WindowScale = new("UIScale", { Scale = 1 })
    WindowScale.Parent = Main

    -- Top Bar
    local TopBar = new("Frame", {
        Name = "TopBar",
        Parent = Main,
        BackgroundColor3 = theme.BackgroundAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40)
    })
    uicorner(TopBar, 12)
    uistroke(TopBar, theme.Stroke, 1, 0.6)

    local TitleLabel = new("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Font = font,
        Text = title,
        TextSize = 18,
        TextColor3 = textColor,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Page Bar (left)
    local PageBar = new("Frame", {
        Name = "PageBar",
        Parent = Main,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 180, 1, -40),
        Position = UDim2.new(0, 0, 0, 40)
    })
    uistroke(PageBar, theme.Stroke, 1, 0.6)
    uipadding(PageBar, 10)
    uicorner(PageBar, 12)

    local PageList = new("ScrollingFrame", {
        Parent = PageBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    uilist(PageList, 8, true)

    -- Section Area (right)
    local SectionArea = new("Frame", {
        Name = "SectionArea",
        Parent = Main,
        BackgroundColor3 = theme.BackgroundAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -180, 1, -40),
        Position = UDim2.new(0, 180, 0, 40),
        ClipsDescendants = true
    })
    uicorner(SectionArea, 12)
    uistroke(SectionArea, theme.Stroke, 1, 0.6)
    uipadding(SectionArea, 10)

    -- Notification container (top-right of screen)
    local NotifyHolder = new("Frame", {
        Name = "NotifyHolder",
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 0, 0, 10),
    })
    local NotifyList = uilist(NotifyHolder, 8, true)
    NotifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotifyList.VerticalAlignment = Enum.VerticalAlignment.Top

    -- Toggle Icon (floating, draggable)
    local ToggleButton = new("Frame", {
        Name = "ToggleIcon",
        Parent = ToggleGui,
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 20, 0.5, -18),
        Active = true
    })
    uicorner(ToggleButton, 18)
    uistroke(ToggleButton, theme.Stroke, 1, 0.3)
    makeShadow(ToggleButton, 0.15)

    local ToggleGlyph = new("TextLabel", {
        Parent = ToggleButton,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = font,
        Text = "≡",
        TextSize = 20,
        TextColor3 = Color3.fromRGB(0, 0, 0)
    })
    applyHoverBounce(ToggleButton, theme.Accent, theme.AccentHover)
    makeDraggable(ToggleButton)

    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- bounce tap feedback
            local sc = ToggleButton:FindFirstChildOfClass("UIScale")
            if sc then
                tween(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
                task.delay(0.12, function()
                    tween(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.05 }):Play()
                    tween(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
                end)
            end
            -- toggle
            Main.Visible = not Main.Visible
            if Main.Visible then
                setBlur(10)
                WindowScale.Scale = 0.94
                tween(WindowScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
            else
                setBlur(0)
            end
        end
    end)

    -- Drag main via TopBar
    makeDraggable(Main, TopBar)

    -- Open animation
    do
        Main.Visible = false
        task.delay(0.05, function()
            Main.Visible = true
            setBlur(10)
            WindowScale.Scale = 0.9
            tween(WindowScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end)
    end

    -- Internal State
    local UI = {}
    local Pages = {}
    local CurrentPage = nil
    local ControlsCleanup = {}
    local function cleanup()
        for _, f in ipairs(ControlsCleanup) do
            pcall(f)
        end
        ControlsCleanup = {}
    end

    local function selectPage(name)
        local page = Pages[name]
        if not page then return end
        if CurrentPage == page then return end

        -- Deselect previous button
        for n, p in pairs(Pages) do
            if p.Button then
                tween(p.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = theme.Background
                }):Play()
            end
        end

        -- Slide-out current
        if CurrentPage then
            local out = CurrentPage.Container
            out.Visible = true
            tween(out, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(-0.05, 0, 0, 0),
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.23, function()
                out.Visible = false
                out.BackgroundTransparency = 0
                out.Position = UDim2.new(0.05, 0, 0, 0)
            end)
        end

        -- Slide-in new
        CurrentPage = page
        local cont = page.Container
        cont.Visible = true
        cont.Position = UDim2.new(0.05, 0, 0, 0)
        tween(cont, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        -- Color select
        if page.Button then
            tween(page.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = theme.AccentMuted
            }):Play()
        end
    end

    -- Public API: UI.SetTheme
    function UI.SetTheme(name)
        local preset = ThemePresets[name] or ThemePresets["Dark Yellow Premium"]
        theme = preset

        -- Apply to static elements
        Main.BackgroundColor3 = theme.Panel
        TopBar.BackgroundColor3 = theme.BackgroundAlt
        PageBar.BackgroundColor3 = theme.Background
        SectionArea.BackgroundColor3 = theme.BackgroundAlt

        -- Toggle recolor
        ToggleButton.BackgroundColor3 = theme.Accent

        -- Recolor page buttons and controls
        for _, page in pairs(Pages) do
            if page.Button then
                page.Button.BackgroundColor3 = theme.Background
                page.Button.TextLabel.TextColor3 = theme.Text
            end
            if page.Container then
                for _, child in ipairs(page.Container:GetChildren()) do
                    if child:IsA("Frame") and child.Name == "Section" then
                        child.BackgroundColor3 = theme.Panel
                    end
                end
            end
        end
    end

    -- Public API: UI.Toggle
    function UI.Toggle()
        Main.Visible = not Main.Visible
        if Main.Visible then
            setBlur(10)
            WindowScale.Scale = 0.92
            tween(WindowScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        else
            setBlur(0)
        end
    end

    -- Public API: UI.addNotify
    function UI.addNotify(message)
        local toast = new("Frame", {
            Parent = NotifyHolder,
            BackgroundColor3 = theme.NotifyBG,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 280, 0, 38),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Transparency = 0
        })
        uicorner(toast, 10)
        uistroke(toast, theme.Stroke, 1, 0.6)

        local lbl = new("TextLabel", {
            Parent = toast,
            BackgroundTransparency = 1,
            Font = font,
            Text = tostring(message),
            TextSize = 16,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 12, 0, 0)
        })

        toast.BackgroundTransparency = 1
        tween(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()

        task.delay(2.2, function()
            tween(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
            task.wait(0.26)
            toast:Destroy()
        end)
    end

    -- Public API: UI.addPage
    function UI.addPage(name)
        name = tostring(name)

        -- Page Button (in PageBar)
        local Button = new("TextButton", {
            Parent = PageList,
            BackgroundColor3 = theme.Background,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 36),
            AutoButtonColor = false
        })
        uicorner(Button, 8)
        uistroke(Button, theme.Stroke, 1, 0.6)
        uipadding(Button, 10)

        local Text = new("TextLabel", {
            Name = "TextLabel",
            Parent = Button,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = font,
            Text = name,
            TextSize = 16,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local disconnectHover = applyHoverBounce(Button, theme.Background, theme.AccentMuted)

        -- Page Container (in SectionArea)
        local Container = new("Frame", {
            Name = "Page_" .. name,
            Parent = SectionArea,
            BackgroundColor3 = theme.BackgroundAlt,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Visible = false
        })
        Container.ClipsDescendants = true

        local SectionsHolder = new("ScrollingFrame", {
            Parent = Container,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        uilist(SectionsHolder, 10, true)
        uipadding(SectionsHolder, 10)

        local PageObj = {
            Name = name,
            Button = Button,
            Container = Container,
            SectionsHolder = SectionsHolder,
            Sections = {}
        }

        Button.MouseButton1Click:Connect(function()
            selectPage(name)
        end)

        Pages[name] = PageObj

        -- Page API
        local PageAPI = {}

        function PageAPI.addSection(sectionName)
            sectionName = tostring(sectionName)
            local Section = new("Frame", {
                Name = "Section",
                Parent = SectionsHolder,
                BackgroundColor3 = theme.Panel,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -8, 0, 60),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            uicorner(Section, 10)
            uistroke(Section, theme.Stroke, 1, 0.6)
            uipadding(Section, 10)
            local list = uilist(Section, 8, true)

            local Header = new("TextLabel", {
                Parent = Section,
                BackgroundTransparency = 1,
                Font = font,
                Text = sectionName,
                TextSize = 14,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 16)
            })

            local ControlsHolder = new("Frame", {
                Parent = Section,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            uilist(ControlsHolder, 8, true)

            local SectionAPI = {}

            function SectionAPI:Resize(size)
                Section.Size = size
            end

            local function makeControlBase(height)
                local frame = new("Frame", {
                    Parent = ControlsHolder,
                    BackgroundColor3 = theme.BackgroundAlt,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, height or 34)
                })
                uicorner(frame, 8)
                uistroke(frame, theme.Stroke, 1, 0.6)
                return frame
            end

            function SectionAPI:addButton(name, callback)
                local c = makeControlBase(34)
                local btn = new("TextButton", {
                    Parent = c,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = tostring(name),
                    Font = font,
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    AutoButtonColor = false
                })
                applyHoverBounce(c, theme.BackgroundAlt, theme.AccentMuted)
                btn.MouseButton1Click:Connect(function()
                    if typeof(callback) == "function" then
                        task.spawn(callback)
                    end
                end)
                return btn
            end

            function SectionAPI:addToggle(name, default, callback)
                local state = default and true or false
                local c = makeControlBase(34)

                local label = new("TextLabel", {
                    Parent = c,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    Font = font,
                    Text = tostring(name),
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local switch = new("Frame", {
                    Parent = c,
                    BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff,
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -52, 0.5, -10)
                })
                uicorner(switch, 10)
                local knob = new("Frame", {
                    Parent = switch,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                })
                uicorner(knob, 8)

                local function set(val, fire)
                    state = val
                    tween(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = state ? theme.ToggleOn : theme.ToggleOff
                    }):Play()
                    tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    }):Play()
                    if fire and typeof(callback) == "function" then
                        task.spawn(callback, state)
                    end
                end

                switch.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        set(not state, true)
                    end
                end)
                c.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        set(not state, true)
                    end
                end)

                return {
                    Set = function(_, v) set(v, false) end,
                    Get = function() return state end
                }
            end

            function SectionAPI:addTextbox(name, default, callback)
                local c = makeControlBase(34)

                local lbl = new("TextLabel", {
                    Parent = c,
                    BackgroundTransparency = 1,
                    Font = font,
                    Text = tostring(name),
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0)
                })

                local box = new("TextBox", {
                    Parent = c,
                    BackgroundColor3 = theme.Background,
                    Font = font,
                    Text = default and tostring(default) or "",
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    Size = UDim2.new(0.5, -20, 0, 26),
                    Position = UDim2.new(0.5, 10, 0.5, -13),
                    ClearTextOnFocus = false
                })
                uicorner(box, 6)
                uistroke(box, theme.Stroke, 1, 0.6)

                box.FocusLost:Connect(function(enter)
                    if typeof(callback) == "function" then
                        task.spawn(callback, box.Text, enter)
                    end
                end)
                return box
            end

            function SectionAPI:addKeybind(name, default, callback)
                local bindKey = default
                local listening = false

                local c = makeControlBase(34)
                local lbl = new("TextLabel", {
                    Parent = c,
                    BackgroundTransparency = 1,
                    Font = font,
                    Text = tostring(name),
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0)
                })

                local btn = new("TextButton", {
                    Parent = c,
                    BackgroundColor3 = theme.Background,
                    AutoButtonColor = false,
                    Font = font,
                    Text = bindKey and bindKey.Name or "Set Key",
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    Size = UDim2.new(0.35, 0, 0, 26),
                    Position = UDim2.new(1, -10 - math.floor(0.35 * (c.AbsoluteSize.X)), 0.5, -13)
                })
                uicorner(btn, 6)
                uistroke(btn, theme.Stroke, 1, 0.6)

                btn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    btn.Text = "Press key..."
                end)

                local inputConn
                inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if listening then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            bindKey = input.KeyCode
                            btn.Text = bindKey.Name
                            listening = false
                        end
                    else
                        if bindKey and input.KeyCode == bindKey then
                            if typeof(callback) == "function" then
                                task.spawn(callback, bindKey)
                            end
                        end
                    end
                end)

                table.insert(ControlsCleanup, function()
                    if inputConn then inputConn:Disconnect() end
                end)

                return {
                    Set = function(_, keycode) bindKey = keycode; btn.Text = keycode and keycode.Name or "Set Key" end,
                    Get = function() return bindKey end
                }
            end

            function SectionAPI:addColorPicker(name, default, callback)
                local h = 0
                local v = 1
                if typeof(default) == "Color3" then
                    local hh, ss, vv = default:ToHSV()
                    h, v = hh, vv
                end
                local color = Color3.fromHSV(h, 1, v)

                local c = makeControlBase(50)

                local lbl = new("TextLabel", {
                    Parent = c,
                    BackgroundTransparency = 1,
                    Font = font,
                    Text = tostring(name),
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0)
                })

                local preview = new("Frame", {
                    Parent = c,
                    BackgroundColor3 = color,
                    Size = UDim2.new(0, 36, 0, 36),
                    Position = UDim2.new(1, -46, 0.5, -18)
                })
                uicorner(preview, 6)
                uistroke(preview, theme.Stroke, 1, 0.4)

                local panel = new("Frame", {
                    Parent = c,
                    BackgroundColor3 = theme.DropdownBG,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 70),
                    Position = UDim2.new(0, 10, 1, 8),
                    Visible = false
                })
                uicorner(panel, 8)
                uistroke(panel, theme.Stroke, 1, 0.6)
                uipadding(panel, 8)

                local list = uilist(panel, 8, false)

                -- Hue slider
                local hueTrack = new("Frame", {
                    Parent = panel,
                    BackgroundColor3 = theme.SliderTrack,
                    Size = UDim2.new(0.6, 0, 0, 10)
                })
                uicorner(hueTrack, 5)

                local hueFill = new("Frame", {
                    Parent = hueTrack,
                    BackgroundColor3 = theme.SliderFill,
                    Size = UDim2.new(h, 0, 1, 0)
                })
                uicorner(hueFill, 5)

                -- Brightness slider
                local valTrack = new("Frame", {
                    Parent = panel,
                    BackgroundColor3 = theme.SliderTrack,
                    Size = UDim2.new(0.3, 0, 0, 10)
                })
                uicorner(valTrack, 5)

                local valFill = new("Frame", {
                    Parent = valTrack,
                    BackgroundColor3 = theme.SliderFill,
                    Size = UDim2.new(v, 0, 1, 0)
                })
                uicorner(valFill, 5)

                local function updateColor(fire)
                    color = Color3.fromHSV(h, 1, v)
                    preview.BackgroundColor3 = color
                    if fire and typeof(callback) == "function" then
                        task.spawn(callback, color)
                    end
                end

                local function bindSlider(track, fill, setter)
                    local dragging = false
                    track.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            local rel = (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                            rel = clamp(rel, 0, 1)
                            setter(rel)
                            fill.Size = UDim2.new(rel, 0, 1, 0)
                            updateColor(true)
                        end
                    end)
                    track.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)
                    track.InputChanged:Connect(function(i)
                        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                            local rel = (UserInputService:GetMouseLocation().X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                            rel = clamp(rel, 0, 1)
                            setter(rel)
                            fill.Size = UDim2.new(rel, 0, 1, 0)
                            updateColor(true)
                        end
                    end)
                end

                bindSlider(hueTrack, hueFill, function(n) h = n end)
                bindSlider(valTrack, valFill, function(n) v = n end)

                -- Toggle panel visibility
                preview.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        panel.Visible = not panel.Visible
                    end
                end)

                return {
                    Set = function(_, col) if typeof(col) == "Color3" then local hh, ss, vv = col:ToHSV(); h, v = hh, vv; hueFill.Size = UDim2.new(h, 0, 1, 0); valFill.Size = UDim2.new(v, 0, 1, 0); updateColor(false) end end,
                    Get = function() return color end
                }
            end

            function SectionAPI:addSlider(name, min, max, default, callback)
                min = tonumber(min) or 0
                max = tonumber(max) or 100
                default = clamp(tonumber(default) or min, min, max)
                local value = default

                local c = makeControlBase(42)

                local lbl = new("TextLabel", {
                    Parent = c,
                    BackgroundTransparency = 1,
                    Font = font,
                    Text = string.format("%s: %d", tostring(name), value),
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -10, 0, 22),
                    Position = UDim2.new(0, 10, 0, 4)
                })

                local track = new("Frame", {
                    Parent = c,
                    BackgroundColor3 = theme.SliderTrack,
                    Size = UDim2.new(1, -20, 0, 8),
                    Position = UDim2.new(0, 10, 0, 28)
                })
                uicorner(track, 4)

                local fill = new("Frame", {
                    Parent = track,
                    BackgroundColor3 = theme.SliderFill,
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                })
                uicorner(fill, 4)

                local function set(val, fire)
                    value = clamp(val, min, max)
                    local alpha = (value - min) / (max - min)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    lbl.Text = string.format("%s: %d", tostring(name), value)
                    if fire and typeof(callback) == "function" then
                        task.spawn(callback, value)
                    end
                end

                local dragging = false
                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local rel = (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                        set(min + rel * (max - min), true)
                    end
                end)
                track.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                track.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        local rel = (UserInputService:GetMouseLocation().X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                        set(min + rel * (max - min), true)
                    end
                end)

                set(default, false)

                return {
                    Set = function(_, v) set(v, false) end,
                    Get = function() return value end
                }
            end

            function SectionAPI:addDropdown(name, options, default, callback)
                options = options or {}
                local current = default or (options[1] or "")

                local c = makeControlBase(36)

                local lbl = new("TextLabel", {
                    Parent = c,
                    BackgroundTransparency = 1,
                    Font = font,
                    Text = tostring(name),
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0)
                })

                local box = new("TextButton", {
                    Parent = c,
                    BackgroundColor3 = theme.Background,
                    AutoButtonColor = false,
                    Font = font,
                    Text = tostring(current),
                    TextSize = 16,
                    TextColor3 = theme.Text,
                    Size = UDim2.new(0.5, 0, 0, 26),
                    Position = UDim2.new(1, -10 - math.floor(0.5 * c.AbsoluteSize.X), 0.5, -13)
                })
                uicorner(box, 6)
                uistroke(box, theme.Stroke, 1, 0.6)

                local listHolder = new("Frame", {
                    Parent = c,
                    BackgroundColor3 = theme.DropdownBG,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -20, 0, 0),
                    Position = UDim2.new(0, 10, 1, 6),
                    Visible = false,
                    ClipsDescendants = true
                })
                uicorner(listHolder, 8)
                uistroke(listHolder, theme.Stroke, 1, 0.6)
                uipadding(listHolder, 6)

                local itemHolder = new("Frame", {
                    Parent = listHolder,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                local layout = uilist(itemHolder, 6, true)

                local function populate()
                    for _, child in ipairs(itemHolder:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local it = new("TextButton", {
                            Parent = itemHolder,
                            BackgroundColor3 = theme.BackgroundAlt,
                            AutoButtonColor = false,
                            Font = font,
                            Text = tostring(opt),
                            TextSize = 16,
                            TextColor3 = theme.Text,
                            Size = UDim2.new(1, 0, 0, 26)
                        })
                        uicorner(it, 6)
                        applyHoverBounce(it, theme.BackgroundAlt, theme.AccentMuted)
                        it.MouseButton1Click:Connect(function()
                            current = opt
                            box.Text = tostring(opt)
                            listHolder.Visible = false
                            if typeof(callback) == "function" then
                                task.spawn(callback, current)
                            end
                        end)
                    end
                end
                populate()

                box.MouseButton1Click:Connect(function()
                    listHolder.Visible = not listHolder.Visible
                    if listHolder.Visible then
                        listHolder.Size = UDim2.new(1, -20, 0, 0)
                        tween(listHolder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, -20, 0, math.min(26 * #options + 12, 160)) }):Play()
                    end
                end)

                return {
                    Set = function(_, value)
                        current = value
                        box.Text = tostring(value)
                    end,
                    Get = function() return current end,
                    SetOptions = function(_, opts)
                        options = opts or {}
                        populate()
                    end
                }
            end

            PageObj.Sections[#PageObj.Sections + 1] = SectionAPI
            return SectionAPI
        end

        function PageAPI.addResize(size)
            PageObj.Container.Size = size
        end

        -- First page auto-select
        if not CurrentPage then
            selectPage(name)
        end

        return PageAPI
    end

    -- Public API: UI.addSelectPage
    function UI.addSelectPage(name)
        selectPage(name)
    end

    -- Select theme initially
    UI.SetTheme("Dark Yellow Premium")

    -- Return public interface
    return UI
end

return Xinexin
