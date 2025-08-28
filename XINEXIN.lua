-- XINEXIN HUB - Minimal / Flat UI Library
-- Theme: Dark Yellow, Pixel-like font, White text
-- Window size: UDim2.new(0, 735, 0, 379), Position: UDim2.new(0.26607, 0, 0.26773, 0)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Utils
local function tween(obj, tinfo, props)
    if not obj then return end
    local tw = TweenService:Create(obj, tinfo, props)
    tw:Play()
    return tw
end

local function make(instance, props, children)
    local inst = Instance.new(instance)
    for k,v in pairs(props or {}) do
        inst[k] = v
    end
    for _,child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function round(v, m) m = m or 1 return math.floor(v/m + 0.5)*m end

-- Theme system
local Themes = {
    DarkYellow = {
        Name = "DarkYellow",
        Background = Color3.fromRGB(18, 18, 18),
        BackgroundAlt = Color3.fromRGB(26, 26, 26),
        Accent = Color3.fromRGB(255, 204, 0),
        AccentSoft = Color3.fromRGB(155, 122, 0),
        Stroke = Color3.fromRGB(50, 50, 50),
        Text = Color3.fromRGB(255, 255, 255),
        Muted = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(38, 38, 38)
    }
}

-- Font (pixel-like)
local PIXEL_FONT = Enum.Font.Arcade -- closest built-in pixel font
local TEXT_SIZE = 14
local TITLE_SIZE = 16

-- Base objects
local CoreGui = game:GetService("CoreGui")
local Screen = make("ScreenGui", {
    Name = "XINEXIN_HUB",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- Global blur
local Blur = nil

-- Draggable helper
local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart, startPos
    dragHandle = dragHandle or frame

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
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Slide-in animation for sections
local function slideIn(frame, delayIndex)
    frame.Visible = true
    frame.Position = UDim2.new(0, 12, 0, frame.Position.Y.Offset + 6)
    frame.Transparency = 1
    for _,d in ipairs(frame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            d.TextTransparency = 1
        elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
            d.ImageTransparency = 1
        end
    end
    task.delay(0.03 * (delayIndex or 0), function()
        tween(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, frame.Position.Y.Offset - 6),
            Transparency = 0
        })
        for _,d in ipairs(frame:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                tween(d, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                tween(d, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0 })
            end
        end
    end)
end

-- Hover bounce
local function hoverBounce(btn, baseColor, hoverColor)
    btn.AutoButtonColor = false
    local baseSize = btn.Size
    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset, baseSize.Y.Scale, baseSize.Y.Offset + 2), BackgroundColor3 = hoverColor })
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset, btn.Position.Y.Scale, btn.Position.Y.Offset - 1) })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = baseSize, BackgroundColor3 = baseColor })
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset, btn.Position.Y.Scale, btn.Position.Y.Offset + 1) })
    end)
end

-- Notifier
local function createNotifier(root, theme)
    local holder = make("Frame", {
        Name = "Notifier",
        Parent = root,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -12, 1, -12),
        Size = UDim2.new(0, 260, 1, -24),
        BackgroundTransparency = 1
    }, {
        make("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })

    local function notify(msg)
        local item = make("Frame", {
            Parent = holder,
            BackgroundColor3 = theme.BackgroundAlt,
            Size = UDim2.new(0, 260, 0, 42),
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, {
            make("UICorner", { CornerRadius = UDim.new(0, 6) }),
            make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
            make("TextLabel", {
                Name = "Text",
                BackgroundTransparency = 1,
                Text = tostring(msg),
                Font = PIXEL_FONT,
                TextSize = TEXT_SIZE,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 1, 0)
            })
        })
        item.Size = UDim2.new(0, 260, 0, 0)
        item.ClipsDescendants = true
        tween(item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 260, 0, 42) })
        task.delay(2.2, function()
            tween(item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)), { Size = UDim2.new(0, 260, 0, 0) }
            task.delay(0.22, function() item:Destroy() end)
        end)
    end

    return notify
end

-- Toggle icon (floating)
local function createToggleIcon(theme, onToggle)
    local iconGui = make("ScreenGui", { Name = "XINEXIN_Toggle", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = CoreGui })
    local btn = make("TextButton", {
        Parent = iconGui,
        Name = "ToggleButton",
        Text = "≡",
        Font = PIXEL_FONT,
        TextSize = 18,
        TextColor3 = theme.Text,
        BackgroundColor3 = theme.Accent,
        Position = UDim2.new(1, -64, 1, -64),
        Size = UDim2.new(0, 44, 0, 44),
        BorderSizePixel = 0
    }, {
        make("UICorner", { CornerRadius = UDim.new(1, 0) }),
        make("UIStroke", { Color = theme.AccentSoft, Thickness = 2 })
    })
    hoverBounce(btn, theme.Accent, theme.AccentSoft)
    makeDraggable(btn, btn)
    btn.MouseButton1Click:Connect(function() onToggle() end)
    return iconGui, btn
end

-- UI factory
local function createWindow(theme)
    local Root = make("Frame", {
        Name = "Window",
        Parent = Screen,
        BackgroundColor3 = theme.Background,
        Size = UDim2.new(0, 735, 0, 379),
        Position = UDim2.new(0.26607, 0, 0.26773, 0),
        BorderSizePixel = 0,
        Visible = true
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 8) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local UIScale = make("UIScale", { Parent = Root, Scale = 0.96 })

    local TopBar = make("Frame", {
        Name = "TopBar",
        Parent = Root,
        BackgroundColor3 = theme.BackgroundAlt,
        Size = UDim2.new(1, 0, 0, 36),
        BorderSizePixel = 0
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 8) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
        make("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Text = "XINEXIN HUB",
            Font = PIXEL_FONT,
            TextSize = TITLE_SIZE,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -24, 1, 0)
        })
    })

    local Body = make("Frame", {
        Name = "Body",
        Parent = Root,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, -52),
        Position = UDim2.new(0, 8, 0, 44)
    })

    local PageBar = make("Frame", {
        Name = "PageBar",
        Parent = Body,
        BackgroundColor3 = theme.BackgroundAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 180, 1, 0)
    }, {
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("ScrollingFrame", {
            Name = "List",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4
        }, {
            make("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            make("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8)
            })
        })
    })

    local Pages = make("Frame", {
        Name = "Pages",
        Parent = Body,
        BackgroundColor3 = theme.BackgroundAlt,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 196, 0, 0),
        Size = UDim2.new(1, -196, 1, 0)
    }, {
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
        make("UICorner", { CornerRadius = UDim.new(0, 6) })
    })

    -- Dragging via TopBar
    makeDraggable(Root, TopBar)

    -- Return assembled
    return Root, TopBar, PageBar, Pages, UIScale
end

-- COMPONENT BUILDERS
local function buildPageButton(parent, text, theme)
    local btn = make("TextButton", {
        Name = text,
        Parent = parent,
        Text = text,
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Text,
        BackgroundColor3 = theme.Background,
        Size = UDim2.new(1, 0, 0, 32),
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })
    hoverBounce(btn, theme.Background, theme.Hover)
    return btn
end

local function recalcCanvas(sf)
    local layout = sf:FindFirstChildOfClass("UIListLayout")
    if not layout then return end
    local total = 0
    for _,child in ipairs(sf:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
            total += child.AbsoluteSize.Y + (layout.Padding.Offset or 0)
        end
    end
    sf.CanvasSize = UDim2.new(0, 0, 0, total + 12)
end

local function buildPageContainer(parent, name)
    local page = make("ScrollingFrame", {
        Name = name,
        Parent = parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    }, {
        make("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        make("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        })
    })
    page:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() recalcCanvas(page) end)
    return page
end

local function buildSection(parent, titleText, theme)
    local section = make("Frame", {
        Name = titleText,
        Parent = parent,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 56)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local header = make("TextLabel", {
        Parent = section,
        BackgroundTransparency = 1,
        Text = titleText,
        Font = PIXEL_FONT,
        TextSize = TITLE_SIZE,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -20, 0, 18)
    })

    local area = make("Frame", {
        Parent = section,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 28),
        Size = UDim2.new(1, -16, 1, -36)
    }, {
        make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })

    -- Auto-resize section height based on children
    local function updateHeight()
        local h = 36
        for _,c in ipairs(area:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then
                h += c.AbsoluteSize.Y + 8
            end
        end
        section.Size = UDim2.new(1, -4, 0, math.max(h, 56))
    end
    area.ChildAdded:Connect(function() task.wait(); updateHeight() end)
    area.ChildRemoved:Connect(updateHeight)

    return section, area, updateHeight
end

local function buildToggle(parent, name, default, theme, callback)
    local frame = make("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.BackgroundAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 }),
    })

    local label = make("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Text = name,
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -60, 1, 0)
    })

    local btn = make("TextButton", {
        Parent = frame,
        Text = "",
        BackgroundColor3 = default and theme.Accent or theme.Background,
        AutoButtonColor = false,
        Position = UDim2.new(1, -46, 0.5, -10),
        Size = UDim2.new(0, 36, 0, 20),
        BorderSizePixel = 0
    }, {
        make("UICorner", { CornerRadius = UDim.new(1, 0) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local knob = make("Frame", {
        Parent = btn,
        BackgroundColor3 = Color3.new(1,1,1),
        Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        BorderSizePixel = 0
    }, {
        make("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    local state = default
    local function setState(v)
        state = v
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = v and theme.Accent or theme.Background })
        tween(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) })
        if callback then task.spawn(callback, state) end
    end

    btn.MouseButton1Click:Connect(function() setState(not state) end)

    return {
        Set = setState,
        Get = function() return state end,
        Frame = frame
    }
end

local function buildButton(parent, name, theme, callback)
    local btn = make("TextButton", {
        Parent = parent,
        Text = name,
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Text,
        BackgroundColor3 = theme.Background,
        Size = UDim2.new(1, 0, 0, 30),
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })
    hoverBounce(btn, theme.Background, theme.Hover)
    btn.MouseButton1Click:Connect(function()
        if callback then task.spawn(callback) end
    end)
    return btn
end

local function buildTextbox(parent, name, default, theme, callback)
    local frame = make("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local label = make("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Text = name,
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.4, -10, 1, 0)
    })

    local box = make("TextBox", {
        Parent = frame,
        BackgroundTransparency = 1,
        Text = tostring(default or ""),
        ClearTextOnFocus = false,
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0.4, 10, 0, 0),
        Size = UDim2.new(0.6, -20, 1, 0)
    })
    box.FocusLost:Connect(function(enterPressed)
        if callback then task.spawn(callback, box.Text) end
    end)
    return frame, box
end

local function buildKeybind(parent, name, defaultKeyCode, theme, callback)
    local frame = make("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local label = make("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Text = name,
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.6, -10, 1, 0)
    })

    local btn = make("TextButton", {
        Parent = frame,
        Text = defaultKeyCode and defaultKeyCode.Name or "None",
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Muted,
        BackgroundColor3 = theme.BackgroundAlt,
        AutoButtonColor = false,
        Position = UDim2.new(0.6, 10, 0, 4),
        Size = UDim2.new(0.4, -14, 0, 22),
        BorderSizePixel = 0
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 4) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local listening = false
    local current = defaultKeyCode

    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "Press..."
        local conn; conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                current = input.KeyCode
                btn.Text = current.Name
                btn.TextColor3 = theme.Text
                listening = false
                conn:Disconnect()
            end
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if current and input.KeyCode == current then
            if callback then task.spawn(callback, current) end
        end
    end)

    return {
        Set = function(kc) current = kc; btn.Text = kc and kc.Name or "None" end,
        Get = function() return current end,
        Frame = frame
    }
end

local function buildSlider(parent, name, min, max, default, theme, callback)
    min = tonumber(min) or 0
    max = tonumber(max) or 100
    default = math.clamp(tonumber(default) or min, min, max)

    local frame = make("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local label = make("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Text = name .. " [" .. tostring(default) .. "]",
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 4),
        Size = UDim2.new(1, -20, 0, 16)
    })

    local bar = make("Frame", {
        Parent = frame,
        BackgroundColor3 = theme.BackgroundAlt,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 22),
        Size = UDim2.new(1, -20, 0, 10)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 5) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local fill = make("Frame", {
        Parent = bar,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 5) })
    })

    local dragging = false
    local value = default

    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        value = round(min + rel * (max - min), 1)
        fill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
        label.Text = name .. " [" .. tostring(value) .. "]"
        if callback then task.spawn(callback, value) end
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

    return {
        Set = function(v) setFromX(bar.AbsolutePosition.X + ((math.clamp(v, min, max)-min)/(max-min))*bar.AbsoluteSize.X) end,
        Get = function() return value end,
        Frame = frame
    }
end

local function buildDropdown(parent, name, options, default, theme, callback)
    options = options or {}
    local frame = make("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        ClipsDescendants = true
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local btn = make("TextButton", {
        Parent = frame,
        Text = name .. ": " .. (default or "Select"),
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Size = UDim2.new(1, -8, 0, 32),
        Position = UDim2.new(0, 8, 0, 0)
    })

    local list = make("Frame", {
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 36),
        Size = UDim2.new(1, -16, 0, 0)
    }, {
        make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    })

    local open = false
    local current = default

    local function set(v)
        current = v
        btn.Text = name .. ": " .. tostring(v)
        if callback then task.spawn(callback, v) end
    end

    local function rebuild()
        for _,c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _,opt in ipairs(options) do
            local o = make("TextButton", {
                Parent = list,
                Text = tostring(opt),
                Font = PIXEL_FONT,
                TextSize = TEXT_SIZE,
                TextColor3 = theme.Text,
                BackgroundColor3 = theme.BackgroundAlt,
                AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, 26),
                BorderSizePixel = 0
            }, {
                make("UICorner", { CornerRadius = UDim.new(0, 4) }),
                make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
            })
            hoverBounce(o, theme.BackgroundAlt, theme.Hover)
            o.MouseButton1Click:Connect(function() set(opt); btn:ReleaseFocus(); end)
        end
    end
    rebuild()

    btn.MouseButton1Click:Connect(function()
        open = not open
        local target = open and (#options * 32) or 0
        tween(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 32 + target + (target>0 and 8 or 0)) })
        list.Size = UDim2.new(1, -16, 0, target)
    end)

    return {
        Set = set,
        Get = function() return current end,
        SetOptions = function(newOpts) options = newOpts or {}; rebuild() end,
        Frame = frame
    }
end

-- Minimal color picker (Hue + Value)
local function buildColorPicker(parent, name, default, theme, callback)
    local defaultC = default or Color3.fromRGB(255, 204, 0)
    local h, s, v = Color3.toHSV(defaultC); if s == 0 then s = 1 end

    local frame = make("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 90),
        ClipsDescendants = true
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 6) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local label = make("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Text = name,
        Font = PIXEL_FONT,
        TextSize = TEXT_SIZE,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -20, 0, 16)
    })

    -- Hue bar
    local hueBar = make("Frame", {
        Parent = frame,
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 28),
        Size = UDim2.new(1, -20, 0, 10)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 5) }),
        make("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
                ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
                ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
                ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
                ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66,1,1)),
                ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1)),
            }
        })
    })

    -- Value bar
    local valueBar = make("Frame", {
        Parent = frame,
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(1, -20, 0, 10)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 5) }),
    })

    local preview = make("Frame", {
        Parent = frame,
        BackgroundColor3 = defaultC,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 66),
        Size = UDim2.new(1, -20, 0, 18)
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 5) }),
        make("UIStroke", { Color = theme.Stroke, Thickness = 1 })
    })

    local function updateValueGradient()
        local col = Color3.fromHSV(h, 1, 1)
        valueBar:ClearAllChildren()
        make("UICorner", { CornerRadius = UDim.new(0, 5), Parent = valueBar })
        make("UIGradient", {
            Parent = valueBar,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                ColorSequenceKeypoint.new(1, col),
            }
        })
    end
    updateValueGradient()

    local function fire()
        local c = Color3.fromHSV(h, 1, v)
        preview.BackgroundColor3 = c
        if callback then task.spawn(callback, c) end
    end

    local draggingHue, draggingVal = false, false
    local function setHueFromX(x)
        local rel = math.clamp((x - hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0, 1)
        h = rel
        updateValueGradient()
        fire()
    end
    local function setValFromX(x)
        local rel = math.clamp((x - valueBar.AbsolutePosition.X)/valueBar.AbsoluteSize.X, 0, 1)
        v = rel
        fire()
    end

    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue = true
            setHueFromX(input.Position.X)
        end
    end)
    valueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingVal = true
            setValFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if draggingHue then setHueFromX(input.Position.X) end
            if draggingVal then setValFromX(input.Position.X) end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue, draggingVal = false, false
        end
    end)

    return {
        Set = function(c) local H,S,V = Color3.toHSV(c); h, v = H, V; updateValueGradient(); preview.BackgroundColor3 = c; fire() end,
        Get = function() return preview.BackgroundColor3 end,
        Frame = frame
    }
end

-- PUBLIC API
local UI = {}
UI._theme = Themes.DarkYellow
UI._pages = {}
UI._currentPage = nil
UI._isOpen = true

local notifyFn
local toggleGui

function UI.SetTheme(themeName)
    UI._theme = Themes[themeName] or Themes.DarkYellow
end

function UI.init()
    Screen.Parent = CoreGui
    local root, topBar, pageBar, pages, uiscale = createWindow(UI._theme)
    UI._root = root
    UI._topBar = topBar
    UI._pageBar = pageBar
    UI._pagesContainer = pages
    UI._scale = uiscale
    notifyFn = createNotifier(Screen, UI._theme)

    -- Blur + zoom on open
    Blur = make("BlurEffect", { Size = 0, Parent = Lighting })
    tween(Blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 10 })
    tween(uiscale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })

    -- Toggle icon
    toggleGui = select(1, createToggleIcon(UI._theme, function() UI.Toggle() end))
end

function UI.addNotify(message)
    if notifyFn then notifyFn(message) end
end

function UI.addPage(name)
    local theme = UI._theme
    local list = UI._pageBar:FindFirstChild("List")
    local btn = buildPageButton(list, name, theme)
    local page = buildPageContainer(UI._pagesContainer, name)

    local pageObj = {
        Name = name,
        _sections = {},
        _page = page,
        _button = btn
    }

    function pageObj.addSection(secName)
        local s, area = buildSection(page, secName, theme)
        table.insert(pageObj._sections, { Frame = s, Area = area })
        slideIn(s, #pageObj._sections)
        return {
            addButton = function(itemName, callback)
                local b = buildButton(area, itemName, theme, callback)
                return b
            end,
            addToggle = function(itemName, default, callback)
                local t = buildToggle(area, itemName, default or false, theme, callback)
                return t
            end,
            addTextbox = function(itemName, default, callback)
                local f, bx = buildTextbox(area, itemName, default, theme, callback)
                return f, bx
            end,
            addKeybind = function(itemName, defaultKeyCode, callback)
                local kb = buildKeybind(area, itemName, defaultKeyCode, theme, callback)
                return kb
            end,
            addColorPicker = function(itemName, defaultColor, callback)
                local cp = buildColorPicker(area, itemName, defaultColor, theme, callback)
                return cp
            end,
            addSlider = function(itemName, min, max, defaultValue, callback)
                local sl = buildSlider(area, itemName, min, max, defaultValue, theme, callback)
                return sl
            end,
            addDropdown = function(itemName, options, defaultValue, callback)
                local dd = buildDropdown(area, itemName, options, defaultValue, theme, callback)
                return dd
            end,
            Resize = function(sizeUDim2)
                if typeof(sizeUDim2) == "UDim2" then
                    s.Size = sizeUDim2
                end
            end
        }
    end

    function pageObj.addResize(sizeUDim2)
        if typeof(sizeUDim2) == "UDim2" then
            page.Size = sizeUDim2
        end
    end

    btn.MouseButton1Click:Connect(function()
        for _,p in pairs(UI._pages) do
            p._page.Visible = false
        end
        page.Visible = true
        -- Smooth slide-in sections when selected
        for i,sec in ipairs(pageObj._sections) do
            slideIn(sec.Frame, i)
        end
    end)

    -- Update page list canvas
    local sf = list
    task.defer(function()
        local layout = sf:FindFirstChildOfClass("UIListLayout")
        if layout then
            sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
            end)
        end
    end)

    table.insert(UI._pages, pageObj)
    if not UI._currentPage then
        UI._currentPage = pageObj
        btn.MouseButton1Click:Fire()
    end

    return pageObj
end

function UI.addSelectPage(name)
    for _,p in ipairs(UI._pages) do
        if p.Name == name then
            p._button.MouseButton1Click:Fire()
            UI._currentPage = p
            break
        end
    end
end

function UI.Toggle()
    UI._isOpen = not UI._isOpen
    if UI._isOpen then
        UI._root.Visible = true
        if not Blur or not Blur.Parent then Blur = make("BlurEffect", { Size = 0, Parent = Lighting }) end
        tween(Blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 10 })
        UI._root.UIScale = UI._root.UIScale or UI._scale
        tween(UI._scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
    else
        tween(UI._scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.96 })
        tween(Blur, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = 0 })
        task.delay(0.16, function()
            if Blur then Blur:Destroy() Blur = nil end
            UI._root.Visible = false
        end)
    end
end

-- Initialize immediately
task.defer(function() UI.init() end)

-- Expose window drag separately if needed
function UI.enableDrag()
    if UI._root and UI._topBar then makeDraggable(UI._root, UI._topBar) end
end

-- Theme swap at runtime
function UI.applyTheme(themeName)
    UI.SetTheme(themeName)
    -- Basic recolor pass
    local theme = UI._theme
    for _,d in ipairs(Screen:GetDescendants()) do
        if d:IsA("Frame") or d:IsA("TextButton") or d:IsA("TextLabel") or d:IsA("TextBox") then
            if d.Name == "TopBar" or d.Parent and d.Parent.Name == "TopBar" then
                if d:IsA("Frame") then d.BackgroundColor3 = theme.BackgroundAlt end
            elseif d:IsA("TextLabel") then
                d.TextColor3 = theme.Text
            elseif d:IsA("TextButton") then
                d.TextColor3 = d.Text and theme.Text or d.TextColor3
            end
        elseif d:IsA("UIStroke") then
            d.Color = theme.Stroke
        end
    end
end

return UI
