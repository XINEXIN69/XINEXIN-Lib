--[[
  XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
  Author: You
  License: MIT (optional)

  Theme: Dark Yellow Premium
  Font: Pixel/Bold style (Arcade)
  Text: White
  Window Size: UDim2.new(0, 735, 0, 379)
  Window Position: UDim2.new(0.26607, 0, 0.26773, 0)

  API:
    UI.addPage(name) -> Page
    UI.addNotify(message)
    UI.addSelectPage(name)
    UI.SetTheme(themeNameOrTable)
    UI.Toggle()

    Page.addSection(name) -> Section
    Page.addResize(sizeUDim2)

    Section:addButton(name, callback)
    Section:addToggle(name, default, callback)
    Section:addTextbox(name, default, callback)
    Section:addKeybind(name, defaultKeyCode, callback)
    Section:addColorPicker(name, defaultColor3, callback)
    Section:addSlider(name, min, max, default, callback)
    Section:addDropdown(name, optionsTable, defaultValue, callback)
    Section:Resize(sizeUDim2)

  Notes:
    - Minimal, flat, rounded UI with hover bounce, color change, slide-in on page select.
    - Draggable window; draggable floating toggle icon to show/hide UI.
    - Blur background + quick camera zoom on open; reversed on close.
    - Lightweight controls; no external dependencies.
--]]

local Xinexin = {}

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

--// Helpers
local function safeParent()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    if LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") then
        return LocalPlayer.PlayerGui
    end
    return game:GetService("StarterGui")
end

local function inst(cls, props, children)
    local o = Instance.new(cls)
    if props then
        for k, v in pairs(props) do
            o[k] = v
        end
    end
    if children then
        for _, c in ipairs(children) do
            c.Parent = o
        end
    end
    return o
end

local function tween(obj, time, props, style, dir)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    return TweenService:Create(obj, info, props)
end

local function dragify(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
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

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function mkCorner(rad)
    return inst("UICorner", { CornerRadius = UDim.new(0, rad or 8) })
end

local function hoverBounce(button, baseColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = hoverColor, Size = button.Size + UDim2.new(0, 4, 0, 2) }, Enum.EasingStyle.Back):Play()
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = baseColor, Size = UDim2.new(button.Size.X.Scale, math.max(0, button.Size.X.Offset - 4), button.Size.Y.Scale, math.max(0, button.Size.Y.Offset - 2)) }, Enum.EasingStyle.Quad):Play()
    end)
end

local function mkStroke(o, color, thickness, trans)
    local s = inst("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = trans or 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    })
    s.Parent = o
    return s
end

--// Themes
local Themes = {
    DarkYellowPremium = {
        Font = Enum.Font.Arcade,
        TextColor = Color3.fromRGB(255, 255, 255),

        Bg = Color3.fromRGB(18, 18, 16),
        Bg2 = Color3.fromRGB(24, 24, 20),
        Bg3 = Color3.fromRGB(30, 30, 26),

        Accent = Color3.fromRGB(255, 196, 0),
        AccentHover = Color3.fromRGB(255, 214, 64),
        AccentSoft = Color3.fromRGB(78, 62, 12),

        Stroke = Color3.fromRGB(255, 220, 90),

        Button = Color3.fromRGB(34, 34, 30),
        ButtonHover = Color3.fromRGB(44, 44, 38),

        SliderTrack = Color3.fromRGB(40, 40, 36),
        SliderFill = Color3.fromRGB(255, 196, 0),

        Dropdown = Color3.fromRGB(36, 36, 32),
        DropdownItemHover = Color3.fromRGB(52, 52, 46),

        NotifyBg = Color3.fromRGB(26, 26, 23),
        NotifyAccent = Color3.fromRGB(255, 196, 0),
    }
}

--// Library
function XinexinHub.Create(config)
    config = config or {}
    local theme = Themes.DarkYellowPremium
    local font = config.Font or theme.Font
    local textColor = config.TextColor or theme.TextColor

    local defaultSize = config.WindowSize or UDim2.new(0, 735, 0, 379)
    local defaultPos = config.WindowPosition or UDim2.new(0.26607, 0, 0.26773, 0)
    local titleText = config.Title or "XINEXIN HUB"

    -- ScreenGui
    local parent = safeParent()
    local sg = inst("ScreenGui", {
        Name = "XinexinHubUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })
    sg.Parent = parent

    -- Notification container
    local notifyRoot = inst("Frame", {
        Name = "NotifyRoot",
        Parent = sg,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 300, 1, -32),
        BackgroundTransparency = 1,
    }, {
        inst("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })

    -- Toggle Icon (floating, draggable)
    local toggleIcon = inst("TextButton", {
        Name = "ToggleIcon",
        Parent = sg,
        Text = "≡",
        Font = font,
        TextColor3 = textColor,
        TextSize = 18,
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 16, 0, 16),
        AutoButtonColor = false
    }, { mkCorner(8), mkStroke(nil, theme.Stroke, 1, 0.2) })
    dragify(toggleIcon)

    -- Main Window
    local window = inst("Frame", {
        Name = "Window",
        Parent = sg,
        BackgroundColor3 = theme.Bg,
        Size = defaultSize,
        Position = defaultPos,
        Visible = true
    }, { mkCorner(12), mkStroke(nil, theme.Stroke, 1.2, 0.35) })
    dragify(window)

    -- Top Bar
    local topbar = inst("Frame", {
        Name = "TopBar",
        Parent = window,
        BackgroundColor3 = theme.Bg2,
        Size = UDim2.new(1, 0, 0, 36)
    }, { mkCorner(12), mkStroke(nil, theme.Stroke, 1, 0.25) })

    local title = inst("TextLabel", {
        Parent = topbar,
        Text = titleText,
        Font = font,
        TextColor3 = textColor,
        TextSize = 18,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Page bar
    local pageBar = inst("Frame", {
        Name = "PageBar",
        Parent = window,
        BackgroundColor3 = theme.Bg2,
        Size = UDim2.new(0, 180, 1, -36),
        Position = UDim2.new(0, 0, 0, 36)
    }, { mkCorner(12), mkStroke(nil, theme.Stroke, 1, 0.25) })

    local pageList = inst("UIListLayout", {
        Parent = pageBar,
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local pagePadding = inst("UIPadding", {
        Parent = pageBar,
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12)
    })

    -- Section Area (pages container)
    local sectionArea = inst("Frame", {
        Name = "SectionArea",
        Parent = window,
        BackgroundColor3 = theme.Bg3,
        Position = UDim2.new(0, 188, 0, 44),
        Size = UDim2.new(1, -196, 1, -52)
    }, { mkCorner(12), mkStroke(nil, theme.Stroke, 1, 0.25) })

    local areaClipper = inst("Frame", {
        Name = "AreaClipper",
        Parent = sectionArea,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        ClipsDescendants = true
    })

    -- Layout for sections inside a page
    local function makePageContainer(name)
        local pageFrame = inst("Frame", {
            Name = name .. "_Page",
            Parent = areaClipper,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false
        })
        local grid = inst("UIGridLayout", {
            Parent = pageFrame,
            CellPadding = UDim2.new(0, 12, 0, 12),
            CellSize = UDim2.new(0, 235, 0, 160),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirectionMaxCells = 3
        })
        return pageFrame
    end

    -- Effects: Blur + Camera Zoom on open
    local blurEffect
    local camera = workspace.CurrentCamera
    local baseFOV = camera and camera.FieldOfView or 70
    local function openEffects()
        if not blurEffect then
            blurEffect = inst("BlurEffect", { Size = 0, Parent = Lighting })
        end
        tween(blurEffect, 0.18, { Size = 12 }):Play()
        if camera then
            local twIn = tween(camera, 0.12, { FieldOfView = baseFOV - 4 }, Enum.EasingStyle.Quad)
            twIn:Play()
            task.delay(0.15, function()
                if camera then tween(camera, 0.18, { FieldOfView = baseFOV }, Enum.EasingStyle.Quad):Play() end
            end)
        end
    end
    local function closeEffects()
        if blurEffect then
            local t = tween(blurEffect, 0.18, { Size = 0 })
            t:Play()
            t.Completed:Connect(function() if blurEffect then blurEffect:Destroy() blurEffect = nil end end)
        end
    end

    -- Toggle visibility
    local isOpen = true
    local function setVisible(state)
        isOpen = state
        if state then
            window.Visible = true
            window.BackgroundTransparency = 1
            topbar.BackgroundTransparency = 1
            pageBar.BackgroundTransparency = 1
            sectionArea.BackgroundTransparency = 1
            tween(window, 0.15, { BackgroundTransparency = 0 }):Play()
            tween(topbar, 0.15, { BackgroundTransparency = 0 }):Play()
            tween(pageBar, 0.15, { BackgroundTransparency = 0 }):Play()
            tween(sectionArea, 0.15, { BackgroundTransparency = 0 }):Play()
            openEffects()
        else
            local t1 = tween(window, 0.15, { BackgroundTransparency = 1 })
            t1:Play()
            closeEffects()
            task.delay(0.15, function()
                window.Visible = false
                -- Clean camera FOV if needed
                if camera then camera.FieldOfView = baseFOV end
            end)
        end
    end

    toggleIcon.MouseButton1Click:Connect(function()
        setVisible(not isOpen)
    end)

    -- State
    local UI = {}
    local pages = {}          -- [name] = { Button = btn, Frame = pageFrame, Sections = {} }
    local pageOrder = {}
    local currentPage

    -- Theme application
    local function applyTheme(th)
        theme = th
        -- Base surfaces
        window.BackgroundColor3 = theme.Bg
        topbar.BackgroundColor3 = theme.Bg2
        pageBar.BackgroundColor3 = theme.Bg2
        sectionArea.BackgroundColor3 = theme.Bg3

        title.TextColor3 = theme.TextColor
        title.Font = theme.Font
        toggleIcon.BackgroundColor3 = theme.Accent
        toggleIcon.TextColor3 = theme.TextColor
        toggleIcon.Font = theme.Font
    end

    applyTheme(theme)

    -- Notifications
    function UI.addNotify(message)
        local card = inst("Frame", {
            Parent = notifyRoot,
            BackgroundColor3 = theme.NotifyBg,
            Size = UDim2.new(0, 280, 0, 40)
        }, { mkCorner(10), mkStroke(nil, theme.Stroke, 1, 0.2) })

        local bar = inst("Frame", {
            Parent = card,
            BackgroundColor3 = theme.NotifyAccent,
            Size = UDim2.new(0, 3, 1, 0)
        }, { mkCorner(10) })

        local lbl = inst("TextLabel", {
            Parent = card,
            BackgroundTransparency = 1,
            Text = tostring(message),
            Font = theme.Font,
            TextColor3 = theme.TextColor,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -16, 1, 0)
        })

        card.BackgroundTransparency = 1
        lbl.TextTransparency = 1
        tween(card, 0.15, { BackgroundTransparency = 0 }):Play()
        tween(lbl, 0.15, { TextTransparency = 0 }):Play()

        task.delay(3, function()
            local t1 = tween(lbl, 0.12, { TextTransparency = 1 })
            local t2 = tween(card, 0.12, { BackgroundTransparency = 1 })
            t1:Play(); t2:Play()
            t2.Completed:Connect(function() card:Destroy() end)
        end)
    end

    -- Theme setter
    function UI.SetTheme(th)
        if type(th) == "string" and Themes[th] then
            applyTheme(Themes[th])
        elseif type(th) == "table" then
            for k, v in pairs(th) do theme[k] = v end
            applyTheme(theme)
        end
    end

    -- Toggle UI
    function UI.Toggle()
        setVisible(not isOpen)
    end

    -- Select page by name
    function UI.addSelectPage(name)
        if not pages[name] then return end
        if currentPage == name then return end

        -- Deactivate all page buttons
        for n, p in pairs(pages) do
            p.Button.BackgroundColor3 = theme.Button
            p.Button.TextColor3 = theme.TextColor
            p.Frame.Visible = false
        end

        -- Activate target
        local page = pages[name]
        page.Button.BackgroundColor3 = theme.AccentSoft
        page.Button.TextColor3 = theme.TextColor

        -- Slide-in animation
        page.Frame.Visible = true
        page.Frame.Position = UDim2.new(1, 12, 0, 0)
        tween(page.Frame, 0.2, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quad):Play()

        currentPage = name
    end

    -- Add page
    function UI.addPage(name)
        name = tostring(name or ("Page" .. tostring(#pageOrder + 1)))

        -- Left bar button
        local btn = inst("TextButton", {
            Parent = pageBar,
            Text = name,
            Font = theme.Font,
            TextColor3 = theme.TextColor,
            TextSize = 16,
            BackgroundColor3 = theme.Button,
            Size = UDim2.new(1, -24, 0, 32),
            AutoButtonColor = false
        }, { mkCorner(10), mkStroke(nil, theme.Stroke, 1, 0.15) })
        hoverBounce(btn, theme.Button, theme.ButtonHover)

        -- Page container
        local pageFrame = makePageContainer(name)

        local pObj = {
            Name = name,
            Button = btn,
            Frame = pageFrame,
            Sections = {}
        }

        -- Click switch
        btn.MouseButton1Click:Connect(function()
            UI.addSelectPage(name)
        end)

        pages[name] = pObj
        table.insert(pageOrder, name)

        -- Page API
        local Page = {}

        function Page.addResize(sizeUDim2)
            pageFrame.Size = sizeUDim2
        end

        function Page.addSection(secName)
            secName = tostring(secName or "Section")
            local sectionFrame = inst("Frame", {
                Parent = pageFrame,
                BackgroundColor3 = theme.Bg2,
                Size = UDim2.new(0, 235, 0, 160)
            }, { mkCorner(10), mkStroke(nil, theme.Stroke, 1, 0.2) })

            local secTitle = inst("TextLabel", {
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Text = secName,
                Font = theme.Font,
                TextColor3 = theme.TextColor,
                TextSize = 16,
                Position = UDim2.new(0, 10, 0, 6),
                Size = UDim2.new(1, -20, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local content = inst("Frame", {
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 28),
                Size = UDim2.new(1, -20, 1, -38)
            })
            local list = inst("UIListLayout", {
                Parent = content,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            local function mkRow(height)
                local row = inst("Frame", {
                    Parent = content,
                    BackgroundColor3 = theme.Button,
                    Size = UDim2.new(1, 0, 0, height or 30)
                }, { mkCorner(8), mkStroke(nil, theme.Stroke, 1, 0.1) })
                return row
            end

            local Section = {}

            function Section:Resize(sizeUDim2)
                sectionFrame.Size = sizeUDim2
            end

            function Section:addButton(label, callback)
                local row = mkRow(30)
                local btn = inst("TextButton", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Text = tostring(label or "Button"),
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 16,
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    AutoButtonColor = false
                })
                hoverBounce(row, theme.Button, theme.ButtonHover)
                btn.MouseButton1Click:Connect(function()
                    if typeof(callback) == "function" then callback() end
                end)
                return btn
            end

            function Section:addToggle(label, default, callback)
                local state = default and true or false
                local row = mkRow(30)
                local lbl = inst("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Text = tostring(label or "Toggle"),
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(1, -50, 1, 0)
                })
                local box = inst("TextButton", {
                    Parent = row,
                    Text = state and "ON" or "OFF",
                    Font = theme.Font,
                    TextColor3 = state and theme.TextColor or Color3.fromRGB(190, 190, 190),
                    TextSize = 14,
                    BackgroundColor3 = state ? theme.Accent : theme.ButtonHover,
                    Size = UDim2.new(0, 46, 0, 22),
                    Position = UDim2.new(1, -56, 0.5, -11),
                    AutoButtonColor = false
                }, { mkCorner(8), mkStroke(nil, theme.Stroke, 1, 0.15) })
                local function set(v)
                    state = v
                    tween(box, 0.12, {
                        BackgroundColor3 = state and theme.Accent or theme.ButtonHover
                    }):Play()
                    box.Text = state and "ON" or "OFF"
                    box.TextColor3 = state and theme.TextColor or Color3.fromRGB(190, 190, 190)
                    if typeof(callback) == "function" then callback(state) end
                end
                box.MouseButton1Click:Connect(function() set(not state) end)
                -- Init
                set(state)
                return {
                    Set = set,
                    Get = function() return state end
                }
            end

            function Section:addTextbox(label, default, callback)
                local row = mkRow(30)
                local lbl = inst("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Text = tostring(label or "Input"),
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(0.4, 0, 1, 0)
                })
                local box = inst("TextBox", {
                    Parent = row,
                    Text = tostring(default or ""),
                    PlaceholderText = "",
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 16,
                    BackgroundColor3 = theme.Dropdown,
                    Position = UDim2.new(0.42, 0, 0.5, -12),
                    Size = UDim2.new(0.58, -8, 0, 24),
                    ClearTextOnFocus = false
                }, { mkCorner(8), mkStroke(nil, theme.Stroke, 1, 0.15) })
                box.FocusLost:Connect(function(enter)
                    if typeof(callback) == "function" then callback(box.Text, enter) end
                end)
                return box
            end

            function Section:addKeybind(label, defaultKeyCode, callback)
                local bound = defaultKeyCode or Enum.KeyCode.None
                local row = mkRow(30)
                local lbl = inst("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Text = tostring(label or "Keybind"),
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0)
                })
                local btn = inst("TextButton", {
                    Parent = row,
                    Text = (bound ~= Enum.KeyCode.None) and bound.Name or "Set",
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 14,
                    BackgroundColor3 = theme.ButtonHover,
                    Position = UDim2.new(1, -90, 0.5, -11),
                    Size = UDim2.new(0, 82, 0, 22),
                    AutoButtonColor = false
                }, { mkCorner(8), mkStroke(nil, theme.Stroke, 1, 0.15) })

                local listening = false
                btn.MouseButton1Click:Connect(function()
                    listening = true
                    btn.Text = "..."
                    btn.TextColor3 = theme.Accent
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        bound = input.KeyCode
                        btn.Text = bound.Name
                        btn.TextColor3 = theme.TextColor
                        listening = false
                    elseif input.UserInputType == Enum.UserInputType.Keyboard then
                        if bound ~= Enum.KeyCode.None and input.KeyCode == bound then
                            if typeof(callback) == "function" then callback(bound) end
                        end
                    end
                end)

                return {
                    Set = function(kc) bound = kc or Enum.KeyCode.None; btn.Text = (bound ~= Enum.KeyCode.None) and bound.Name or "Set" end,
                    Get = function() return bound end
                }
            end

            function Section:addColorPicker(label, default, callback)
                local color = default or Color3.fromRGB(255, 196, 0)
                local row = mkRow(30)
                local lbl = inst("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Text = tostring(label or "Color"),
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0)
                })
                local swatch = inst("TextButton", {
                    Parent = row,
                    BackgroundColor3 = color,
                    Text = "",
                    Position = UDim2.new(1, -50, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20),
                    AutoButtonColor = false
                }, { mkCorner(6), mkStroke(nil, theme.Stroke, 1, 0.15) })

                -- Popup panel with 3 sliders (R,G,B)
                local popup = inst("Frame", {
                    Parent = sg,
                    BackgroundColor3 = theme.Dropdown,
                    Size = UDim2.new(0, 220, 0, 130),
                    Visible = false
                }, { mkCorner(10), mkStroke(nil, theme.Stroke, 1, 0.2) })
                popup.Position = UDim2.new(0, 0, 0, 0)

                local function makeSlider(y, name, init, onChange)
                    local label = inst("TextLabel", {
                        Parent = popup,
                        BackgroundTransparency = 1,
                        Text = name,
                        Font = theme.Font,
                        TextColor3 = theme.TextColor,
                        TextSize = 14,
                        Position = UDim2.new(0, 10, 0, y),
                        Size = UDim2.new(0, 30, 0, 18)
                    })
                    local track = inst("Frame", {
                        Parent = popup,
                        BackgroundColor3 = theme.SliderTrack,
                        Position = UDim2.new(0, 44, 0, y + 6),
                        Size = UDim2.new(1, -60, 0, 8)
                    }, { mkCorner(6) })
                    local fill = inst("Frame", {
                        Parent = track,
                        BackgroundColor3 = theme.SliderFill,
                        Size = UDim2.new(init, 0, 1, 0)
                    }, { mkCorner(6) })

                    local function setPercent(p)
                        p = math.clamp(p, 0, 1)
                        fill.Size = UDim2.new(p, 0, 1, 0)
                        onChange(p)
                    end

                    local dragging = false
                    track.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            local rel = (input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X
                            setPercent(rel)
                        end
                    end)
                    track.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local rel = (input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X
                            setPercent(rel)
                        end
                    end)

                    return setPercent
                end

                local r, g, b = color.R, color.G, color.B
                local setR = makeSlider(12, "R", r, function(p) r = p; color = Color3.new(r, g, b); swatch.BackgroundColor3 = color; if callback then callback(color) end end)
                local setG = makeSlider(48, "G", g, function(p) g = p; color = Color3.new(r, g, b); swatch.BackgroundColor3 = color; if callback then callback(color) end end)
                local setB = makeSlider(84, "B", b, function(p) b = p; color = Color3.new(r, g, b); swatch.BackgroundColor3 = color; if callback then callback(color) end end)

                local function placePopup()
                    local x = swatch.AbsolutePosition.X
                    local y = swatch.AbsolutePosition.Y + swatch.AbsoluteSize.Y + 6
                    popup.Position = UDim2.new(0, x, 0, y)
                end

                swatch.MouseButton1Click:Connect(function()
                    placePopup()
                    popup.Visible = not popup.Visible
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if popup.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local pos = input.Position
                        local absPos = popup.AbsolutePosition
                        local absSize = popup.AbsoluteSize
                        local inside = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
                        if not inside then popup.Visible = false end
                    end
                end)

                return {
                    Set = function(c)
                        color = c
                        r, g, b = color.R, color.G, color.B
                        swatch.BackgroundColor3 = color
                        setR(r); setG(g); setB(b)
                        if callback then callback(color) end
                    end,
                    Get = function() return color end
                }
            end

            function Section:addSlider(label, min, max, default, callback)
                min = tonumber(min) or 0
                max = tonumber(max) or 100
                default = tonumber(default) or min

                local value = math.clamp(default, min, max)
                local row = mkRow(36)

                local lbl = inst("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Text = string.format("%s: %d", tostring(label or "Slider"), value),
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(1, -16, 0, 16)
                })

                local track = inst("Frame", {
                    Parent = row,
                    BackgroundColor3 = theme.SliderTrack,
                    Position = UDim2.new(0, 8, 0, 20),
                    Size = UDim2.new(1, -16, 0, 8)
                }, { mkCorner(6) })

                local fill = inst("Frame", {
                    Parent = track,
                    BackgroundColor3 = theme.SliderFill,
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                }, { mkCorner(6) })

                local function setValue(v)
                    v = math.clamp(v, min, max)
                    value = v
                    local pct = (value - min) / (max - min)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    lbl.Text = string.format("%s: %d", tostring(label or "Slider"), value)
                    if typeof(callback) == "function" then callback(value) end
                end

                local dragging = false
                local function xToValue(x)
                    local rel = (x - track.AbsolutePosition.X)/track.AbsoluteSize.X
                    rel = math.clamp(rel, 0, 1)
                    return math.floor(min + rel * (max - min) + 0.5)
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        setValue(xToValue(input.Position.X))
                    end
                end)
                track.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setValue(xToValue(input.Position.X))
                    end
                end)

                setValue(value)
                return { Set = setValue, Get = function() return value end }
            end

            function Section:addDropdown(label, options, default, callback)
                options = options or {}
                local selected = default

                local row = mkRow(30)
                local lbl = inst("TextLabel", {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Text = tostring(label or "Dropdown"),
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0)
                })
                local btn = inst("TextButton", {
                    Parent = row,
                    Text = selected and tostring(selected) or "Select",
                    Font = theme.Font,
                    TextColor3 = theme.TextColor,
                    TextSize = 14,
                    BackgroundColor3 = theme.Dropdown,
                    Position = UDim2.new(1, -120, 0.5, -11),
                    Size = UDim2.new(0, 112, 0, 22),
                    AutoButtonColor = false
                }, { mkCorner(8), mkStroke(nil, theme.Stroke, 1, 0.15) })

                local listPopup = inst("Frame", {
                    Parent = sg,
                    BackgroundColor3 = theme.Dropdown,
                    Size = UDim2.new(0, 180, 0, math.min(24 * (#options), 180)),
                    Visible = false,
                    ClipsDescendants = true
                }, { mkCorner(10), mkStroke(nil, theme.Stroke, 1, 0.2) })

                local scroll = inst("ScrollingFrame", {
                    Parent = listPopup,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -8, 1, -8),
                    Position = UDim2.new(0, 4, 0, 4),
                    CanvasSize = UDim2.new(0, 0, 0, 24 * (#options)),
                    ScrollBarThickness = 4
                })
                inst("UIListLayout", {
                    Parent = scroll,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                local function placePopup()
                    local x = btn.AbsolutePosition.X
                    local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 6
                    listPopup.Position = UDim2.new(0, x, 0, y)
                end

                local function select(val)
                    selected = val
                    btn.Text = tostring(val)
                    if typeof(callback) == "function" then callback(val) end
                end

                local function makeItem(text)
                    local item = inst("TextButton", {
                        Parent = scroll,
                        BackgroundColor3 = theme.Button,
                        Text = tostring(text),
                        Font = theme.Font,
                        TextColor3 = theme.TextColor,
                        TextSize = 14,
                        Size = UDim2.new(1, -4, 0, 22),
                        AutoButtonColor = false
                    }, { mkCorner(6), mkStroke(nil, theme.Stroke, 1, 0.1) })
                    item.MouseEnter:Connect(function() tween(item, 0.1, { BackgroundColor3 = theme.DropdownItemHover }):Play() end)
                    item.MouseLeave:Connect(function() tween(item, 0.1, { BackgroundColor3 = theme.Button }):Play() end)
                    item.MouseButton1Click:Connect(function()
                        select(text)
                        listPopup.Visible = false
                    end)
                end

                for _, opt in ipairs(options) do
                    makeItem(opt)
                end

                btn.MouseButton1Click:Connect(function()
                    placePopup()
                    listPopup.Visible = not listPopup.Visible
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if listPopup.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local pos = input.Position
                        local absPos = listPopup.AbsolutePosition
                        local absSize = listPopup.AbsoluteSize
                        local inside = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
                        if not inside then listPopup.Visible = false end
                    end
                end)

                if selected ~= nil then select(selected) end

                return {
                    Set = select,
                    Get = function() return selected end,
                    SetOptions = function(newOpts)
                        scroll:ClearAllChildren()
                        inst("UIListLayout", {
                            Parent = scroll,
                            Padding = UDim.new(0, 4),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        })
                        options = newOpts or {}
                        scroll.CanvasSize = UDim2.new(0, 0, 0, 24 * (#options))
                        for _, opt in ipairs(options) do makeItem(opt) end
                    end
                }
            end

            table.insert(pObj.Sections, Section)
            return Section
        end

        -- Auto select first page
        if not currentPage then
            task.defer(function()
                UI.addSelectPage(name)
            end)
        end

        return Page
    end

    -- Initialize open animation
    task.defer(function()
        openEffects()
    end)

    -- Return UI handle
    return UI
end

return Xinexin
