--!strict
-- XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
-- Theme: Dark Yellow, Pixel Bold, White text
-- Window: Size UDim2.new(0, 735, 0, 379), Position UDim2.new(0.26607, 0, 0.26773, 0)
-- API:
--  UI.addPage(name) -> Page
--  UI.addNotify(message)
--  UI.addSelectPage(name)
--  UI.SetTheme(themeTable | "DarkYellow")
--  UI.Toggle()
-- Page:
--  Page.addSection(name) -> Section
--  Page.addResize(sizeUDim2)
-- Section:
--  Section:addButton(name, callback)
--  Section:addToggle(name, default, callback)
--  Section:addTextbox(name, default, callback)
--  Section:addKeybind(name, defaultKeyCode, callback)
--  Section:addColorPicker(name, defaultColor3, callback)
--  Section:addSlider(name, min, max, default, callback)
--  Section:addDropdown(name, optionsArray, default, callback)
--  Section:Resize(sizeUDim2)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local function safeParent(gui: Instance)
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then
        local plr = Players.LocalPlayer
        if plr and plr:FindFirstChildOfClass("PlayerGui") then
            gui.Parent = plr:FindFirstChildOfClass("PlayerGui")
        else
            gui.Parent = game
        end
    end
end

local function new(inst: string, props: table?, parent: Instance?)
    local obj = Instance.new(inst)
    if props then
        for k, v in pairs(props) do
            (obj :: any)[k] = v
        end
    end
    if parent then obj.Parent = parent end
    return obj
end

local function round(n: number, step: number)
    return math.floor((n / step) + 0.5) * step
end

local function tween(obj: Instance, time: number, style, dir, props: table)
    local ti = TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function makeDraggable(frame: Frame, dragHandle: GuiObject?)
    local drag = dragHandle or frame
    local dragging = false
    local startPos, startInputPos
    drag.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = frame.Position
            startInputPos = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    drag.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging and startPos and startInputPos then
            local delta = input.Position - startInputPos
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function addCorner(inst: GuiObject, radius: number?)
    new("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, inst)
end

local DEFAULT_THEME = {
    Name = "DarkYellow",
    Background = Color3.fromRGB(20, 20, 16),
    Secondary = Color3.fromRGB(32, 32, 26),
    Accent = Color3.fromRGB(255, 202, 40),
    AccentHover = Color3.fromRGB(255, 226, 88),
    Stroke = Color3.fromRGB(60, 60, 45),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(220, 210, 170),
    Element = Color3.fromRGB(40, 40, 32),
    ElementHover = Color3.fromRGB(52, 52, 40),
}

local PIXEL_FONT = Enum.Font.Arcade

local Library = {}

function Library.new(config: {Name: string}?)
    local cfgName = (config and config.Name) or "XINEXIN HUB"
    local Theme = table.clone(DEFAULT_THEME)
    local Connections = {}
    local KeybindCallbacks: {[Enum.KeyCode]: {cb: (()->()), tag: string}} = {}
    local SelectedPageName: string? = nil
    local Pages: {[string]: Frame} = {}
    local PageButtons: {[string]: TextButton} = {}
    local SectionsByPage: {[string]: {GuiObject}} = {}
    local IsOpen = true
    local BlurEffect: BlurEffect? = nil

    -- Root GUI
    local Screen = new("ScreenGui", {
        Name = "XINEXIN_HUB",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    safeParent(Screen)

    -- Notifications container
    local Toasts = new("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 300, 1, -32),
        BackgroundTransparency = 1,
    }, Screen)
    local ToastLayout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Toasts)

    -- Toggle icon (floating)
    local ToggleIcon = new("TextButton", {
        Name = "ToggleIcon",
        Text = "≡",
        Font = PIXEL_FONT,
        TextSize = 18,
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Accent,
        TextColor3 = Theme.Background,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 16, 0.5, -18),
    }, Screen)
    addCorner(ToggleIcon, 18)
    new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Stroke, Thickness = 1}, ToggleIcon)

    -- Main window
    local Window = new("Frame", {
        Name = "Window",
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(0, 735, 0, 379),
        Position = UDim2.new(0.26607, 0, 0.26773, 0),
        ClipsDescendants = true,
    }, Screen)
    addCorner(Window, 10)
    new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Stroke, Thickness = 1.5}, Window)
    local UIScale = new("UIScale", {Scale = 1}, Window)

    -- Top bar (drag handle + HUB name)
    local TopBar = new("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 40),
    }, Window)
    addCorner(TopBar, 10)
    new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Stroke, Thickness = 1}, TopBar)

    local Title = new("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = PIXEL_FONT,
        Text = cfgName,
        TextColor3 = Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -32, 1, 0),
    }, TopBar)

    -- Content area
    local Body = new("Frame", {
        Name = "Body",
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(1, -0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
    }, Window)
    addCorner(Body, 10)

    -- Page bar (left)
    local PageBar = new("Frame", {
        Name = "PageBar",
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 180, 1, 0),
    }, Body)
    addCorner(PageBar, 10)
    new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Stroke, Thickness = 1}, PageBar)

    local PageList = new("ScrollingFrame", {
        Name = "PageList",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, PageBar)
    local PageLayout = new("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, PageList)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, PageList)

    -- Section area (right)
    local SectionArea = new("Frame", {
        Name = "SectionArea",
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0, 188, 0, 0),
        Size = UDim2.new(1, -196, 1, 0),
        ClipsDescendants = true,
    }, Body)
    addCorner(SectionArea, 10)
    new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Stroke, Thickness = 1}, SectionArea)

    local function updateCanvas(scroller: ScrollingFrame)
        scroller.CanvasSize = UDim2.new(0, 0, 0, (PageLayout.AbsoluteContentSize.Y))
    end
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        updateCanvas(PageList)
    end)

    -- Effects: blur + open zoom
    local function ensureBlur()
        if not BlurEffect or not BlurEffect.Parent then
            local blur = Instance.new("BlurEffect")
            blur.Size = 0
            blur.Enabled = false
            blur.Parent = Lighting
            BlurEffect = blur
        end
        return BlurEffect
    end

    local function openEffects()
        local blur = ensureBlur()
        blur.Enabled = true
        tween(blur, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = 12})
        UIScale.Scale = 0.95
        Window.Visible = true
        tween(UIScale, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Scale = 1})
        tween(Window, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0})
    end

    local function closeEffects()
        if BlurEffect then tween(BlurEffect, 0.2, nil, nil, {Size = 0}) end
        tween(UIScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {Scale = 0.96}).Completed:Wait()
        if BlurEffect then BlurEffect.Enabled = false end
        Window.Visible = false
    end

    -- Toggle icon behavior
    ToggleIcon.MouseButton1Click:Connect(function()
        IsOpen = not IsOpen
        if IsOpen then openEffects() else closeEffects() end
    end)
    ToggleIcon.MouseEnter:Connect(function()
        tween(ToggleIcon, 0.12, nil, nil, {BackgroundColor3 = Theme.AccentHover})
    end)
    ToggleIcon.MouseLeave:Connect(function()
        tween(ToggleIcon, 0.12, nil, nil, {BackgroundColor3 = Theme.Accent})
    end)
    makeDraggable(ToggleIcon)

    -- Drag main window by topbar
    makeDraggable(Window, TopBar)

    -- Input routing for keybind callbacks
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local kc = input.KeyCode
            if KeybindCallbacks[kc] then
                local bundle = KeybindCallbacks[kc]
                if bundle.cb then
                    task.spawn(bundle.cb)
                end
            end
        end
    end))

    -- Selection helpers
    local function setSelectedPage(name: string)
    for pName, frame in pairs(Pages) do
        frame.Visible = (pName == name)
    end
    for bName, btn in pairs(PageButtons) do
        if bName == name then
            tween(btn, 0.12, nil, nil, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background})
        else
            tween(btn, 0.12, nil, nil, {BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text})
        end
    end
    SelectedPageName = name

    -- Section slide-in animation
    local secs = SectionsByPage[name]
    if secs then
        for i, sec in ipairs(secs) do
            local content = sec:FindFirstChild("Content")
            if content and content:IsA("Frame") then
                -- เริ่มเลื่อนจาก offset เล็กน้อย
                content.Position = UDim2.new(0, 8, 0, 0)

                -- ✅ ไม่ยุ่งกับ TextTransparency / ImageTransparency อีก
                task.delay(0.02 * (i - 1), function()
                    tween(content, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                        Position = UDim2.new(0, 0, 0, 0)
                    })
                end)
            end
        end
    end
end
        -- Section slide-in animation
        local secs = SectionsByPage[name]
        if secs then
            for i, sec in ipairs(secs) do
                local content = sec:FindFirstChild("Content")
                if content and content:IsA("Frame") then
                    content.Position = UDim2.new(0, 8, 0, 0)
                    content.BackgroundTransparency = content.BackgroundTransparency -- keep
                    for _, child in ipairs(content:GetDescendants()) do
                        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                            child.TextTransparency = 1
                        elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                            child.ImageTransparency = 1
                        end
                    end
                    task.delay(0.02 * (i - 1), function()
                        tween(content, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = UDim2.new(0, 0, 0, 0)})
                        for _, child in ipairs(content:GetDescendants()) do
                            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                                tween(child, 0.25, nil, nil, {TextTransparency = 0})
                            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                                tween(child, 0.25, nil, nil, {ImageTransparency = 0})
                            end
                        end
                    end)
                end
            end
        end
    end

    -- Page factory
    local function createPage(name: string)
        -- Button in PageBar
        local Btn = new("TextButton", {
            Name = "Page_" .. name,
            Text = name,
            Font = PIXEL_FONT,
            TextSize = 16,
            TextColor3 = Theme.Text,
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Element,
            Size = UDim2.new(1, -8, 0, 34),
        }, PageList)
        addCorner(Btn, 8)
        new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Stroke, Thickness = 1}, Btn)
        PageButtons[name] = Btn

        -- Hover: bounce + color
        Btn.MouseEnter:Connect(function()
            tween(Btn, 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Position = Btn.Position + UDim2.new(0, 0, 0, -2)})
            tween(Btn, 0.1, nil, nil, {BackgroundColor3 = Theme.ElementHover, TextColor3 = Theme.AccentHover})
        end)
        Btn.MouseLeave:Connect(function()
            tween(Btn, 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Position = UDim2.new(Btn.Position.X.Scale, Btn.Position.X.Offset, Btn.Position.Y.Scale, 0)})
            if SelectedPageName == name then
                tween(Btn, 0.12, nil, nil, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background})
            else
                tween(Btn, 0.12, nil, nil, {BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text})
            end
        end)
        Btn.MouseButton1Click:Connect(function()
            setSelectedPage(name)
        end)

        -- Page content (ScrollingFrame)
        local PageFrame = new("ScrollingFrame", {
            Name = "Page_" .. name .. "_Content",
            Parent = SectionArea,
            BackgroundTransparency = 1,
            Visible = false,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
        })
        Pages[name] = PageFrame

        local PageContentLayout = new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }, PageFrame)
        new("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
        }, PageFrame)

        PageContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PageFrame.CanvasSize = UDim2.new(0, 0, 0, PageContentLayout.AbsoluteContentSize.Y + 20)
        end)

        SectionsByPage[name] = {}

        local PageAPI = {}

        function PageAPI.addSection(secName: string)
            local Section = new("Frame", {
                Name = "Section_" .. secName,
                BackgroundColor3 = Theme.Secondary,
                Size = UDim2.new(1, 0, 0, 80),
            }, PageFrame)
            addCorner(Section, 8)
            new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Stroke, Thickness = 1}, Section)

            local Header = new("TextLabel", {
                Name = "Header",
                BackgroundTransparency = 1,
                Text = secName,
                Font = PIXEL_FONT,
                TextSize = 16,
                TextColor3 = Theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 10, 0, 6),
                Size = UDim2.new(1, -20, 0, 18),
            }, Section)

            local Content = new("Frame", {
                Name = "Content",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 28),
                Size = UDim2.new(1, -20, 1, -38),
            }, Section)

            local Layout = new("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            }, Content)

            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local contentHeight = Layout.AbsoluteContentSize.Y
                Section.Size = UDim2.new(1, 0, 0, math.max(80, contentHeight + 40))
            end)

            table.insert(SectionsByPage[name], Section)

            local SectionAPI = {}

            local function makeRowBase(height: number)
                local Row = new("Frame", {
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, height),
                }, Content)
                addCorner(Row, 6)
                new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Stroke, Thickness = 1}, Row)

                Row.MouseEnter:Connect(function()
                    tween(Row, 0.1, nil, nil, {BackgroundColor3 = Theme.ElementHover})
                end)
                Row.MouseLeave:Connect(function()
                    tween(Row, 0.12, nil, nil, {BackgroundColor3 = Theme.Element})
                end)

                return Row
            end

            local function label(parent: Instance, text: string)
                return new("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = PIXEL_FONT,
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                }, parent)
            end

            function SectionAPI:addButton(btnName: string, callback: (() -> ())?)
                local Row = makeRowBase(32)
                local Btn = new("TextButton", {
                    BackgroundTransparency = 1,
                    Text = btnName,
                    Font = PIXEL_FONT,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    AutoButtonColor = false,
                    Size = UDim2.new(1, 0, 1, 0),
                }, Row)
                Btn.MouseEnter:Connect(function()
                    tween(Btn, 0.08, nil, nil, {TextColor3 = Theme.AccentHover})
                end)
                Btn.MouseLeave:Connect(function()
                    tween(Btn, 0.12, nil, nil, {TextColor3 = Theme.Text})
                end)
                Btn.MouseButton1Click:Connect(function()
                    tween(Row, 0.06, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 30)}).Completed:Wait()
                    tween(Row, 0.06, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, 32)})
                    if callback then task.spawn(callback) end
                end)
                return Btn
            end

            function SectionAPI:addToggle(tName: string, default: boolean?, callback: ((state: boolean) -> ())?)
                local state = default == true
                local Row = makeRowBase(32)
                label(Row, tName)

                local Switch = new("TextButton", {
                    BackgroundColor3 = state and Theme.Accent or Theme.Background,
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.new(0, 44, 0, 22),
                    Position = UDim2.new(1, -54, 0.5, -11),
                }, Row)
                addCorner(Switch, 11)
                new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Switch)

                local Knob = new("Frame", {
                    BackgroundColor3 = state and Theme.Background or Theme.ElementHover,
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                }, Switch)
                addCorner(Knob, 9)

                local function setState(s: boolean)
                    state = s
                    tween(Switch, 0.12, nil, nil, {BackgroundColor3 = s and Theme.Accent or Theme.Background})
                    tween(Knob, 0.12, nil, nil, {Position = s and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = s and Theme.Background or Theme.ElementHover})
                    if callback then task.spawn(callback, state) end
                end

                Switch.MouseButton1Click:Connect(function()
                    setState(not state)
                end)

                return {
                    Set = function(v: boolean) setState(v) end,
                    Get = function() return state end
                }
            end

            function SectionAPI:addTextbox(tbName: string, default: string?, callback: ((text: string) -> ())?)
                local Row = makeRowBase(34)
                label(Row, tbName)
                local Box = new("TextBox", {
                    BackgroundColor3 = Theme.Background,
                    Text = default or "",
                    PlaceholderText = "",
                    Font = PIXEL_FONT,
                    TextSize = 14,
                    TextColor3 = Theme.Text,
                    ClearTextOnFocus = false,
                    Size = UDim2.new(0, 220, 0, 26),
                    Position = UDim2.new(1, -230, 0.5, -13),
                }, Row)
                addCorner(Box, 6)
                new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Box)
                Box.Focused:Connect(function()
                    tween(Box, 0.08, nil, nil, {BackgroundColor3 = Theme.ElementHover})
                end)
                Box.FocusLost:Connect(function(enterPressed)
                    tween(Box, 0.12, nil, nil, {BackgroundColor3 = Theme.Background})
                    if callback then task.spawn(callback, Box.Text) end
                end)
                return Box
            end

            function SectionAPI:addKeybind(kbName: string, defaultKey: Enum.KeyCode?, callback: (() -> ())?)
                local Row = makeRowBase(32)
                label(Row, kbName)
                local Listening = false
                local Current = defaultKey or Enum.KeyCode.RightControl

                local Btn = new("TextButton", {
                    BackgroundColor3 = Theme.Background,
                    AutoButtonColor = false,
                    Text = Current.Name,
                    Font = PIXEL_FONT,
                    TextSize = 14,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(0, 140, 0, 24),
                    Position = UDim2.new(1, -150, 0.5, -12),
                }, Row)
                addCorner(Btn, 6)
                new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Btn)

                local function updateBind(kc: Enum.KeyCode)
                    -- remove previous
                    if KeybindCallbacks[Current] then
                        KeybindCallbacks[Current] = nil
                    end
                    Current = kc
                    Btn.Text = Current.Name
                    if callback then
                        KeybindCallbacks[Current] = {cb = callback, tag = kbName}
                    end
                end

                if callback then
                    KeybindCallbacks[Current] = {cb = callback, tag = kbName}
                end

                Btn.MouseButton1Click:Connect(function()
                    Listening = true
                    Btn.Text = "Press key"
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            updateBind(input.KeyCode)
                            Listening = false
                            if conn then conn:Disconnect() end
                        end
                    end)
                end)

                return {
                    Set = function(kc: Enum.KeyCode) updateBind(kc) end,
                    Get = function() return Current end
                }
            end

            function SectionAPI:addColorPicker(cpName: string, defaultColor: Color3?, callback: ((c: Color3) -> ())?)
                local Row = makeRowBase(36)
                label(Row, cpName)
                local Value = defaultColor or Theme.Accent

                local Swatch = new("TextButton", {
                    BackgroundColor3 = Value,
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.new(0, 44, 0, 24),
                    Position = UDim2.new(1, -54, 0.5, -12),
                }, Row)
                addCorner(Swatch, 6)
                new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Swatch)

                -- Picker popup
                local Popup = new("Frame", {
                    Name = "Picker",
                    Visible = false,
                    BackgroundColor3 = Theme.Secondary,
                    Size = UDim2.new(0, 180, 0, 86),
                    Position = UDim2.new(1, -190, 0, 38),
                }, Row)
                addCorner(Popup, 8)
                new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Popup)

                local HueBar = new("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                    Size = UDim2.new(1, -20, 0, 14),
                    Position = UDim2.new(0, 10, 0, 10),
                }, Popup)
                addCorner(HueBar, 6)
                local grad = new("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.51, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.68, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.85, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                    }
                }, HueBar)

                local SatVal = new("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    Size = UDim2.new(1, -20, 0, 40),
                    Position = UDim2.new(0, 10, 0, 34),
                }, Popup)
                addCorner(SatVal, 6)
                local satGrad = new("UIGradient", {
                    Color = ColorSequence.new(Color3.new(1,1,1), Value),
                    Rotation = 0,
                }, SatVal)

                local valOverlay = new("Frame", {
                    BackgroundColor3 = Color3.new(0,0,0),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                }, SatVal)
                local valGrad = new("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
                    },
                    Rotation = 90,
                }, valOverlay)

                local Hue, Sat, Val = 0, 1, 1

                local function HSVtoRGB(h, s, v)
                    return Color3.fromHSV(h, s, v)
                end
                local function updateFromHSV()
                    local c = HSVtoRGB(Hue, Sat, Val)
                    Value = c
                    Swatch.BackgroundColor3 = c
                    satGrad.Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromHSV(Hue, 1, 1))
                    if callback then task.spawn(callback, c) end
                end

                local function pickHue(x)
                    local abs = HueBar.AbsoluteSize.X
                    local left = HueBar.AbsolutePosition.X
                    Hue = math.clamp((x - left) / math.max(1, abs), 0, 1)
                    updateFromHSV()
                end
                local function pickSatVal(x)
                    local abs = SatVal.AbsoluteSize.X
                    local left = SatVal.AbsolutePosition.X
                    Sat = math.clamp((x - left) / math.max(1, abs), 0, 1)
                    updateFromHSV()
                end

                HueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickHue(input.Position.X)
                        local moveConn
                        moveConn = UserInputService.InputChanged:Connect(function(i2)
                            if i2.UserInputType == Enum.UserInputType.MouseMovement then
                                pickHue(i2.Position.X)
                            end
                        end)
                        local endConn
                        endConn = UserInputService.InputEnded:Connect(function(i3)
                            if i3.UserInputType == Enum.UserInputType.MouseButton1 then
                                if moveConn then moveConn:Disconnect() end
                                if endConn then endConn:Disconnect() end
                            end
                        end)
                    end
                end)

                SatVal.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickSatVal(input.Position.X)
                        local moveConn
                        moveConn = UserInputService.InputChanged:Connect(function(i2)
                            if i2.UserInputType == Enum.UserInputType.MouseMovement then
                                pickSatVal(i2.Position.X)
                            end
                        end)
                        local endConn
                        endConn = UserInputService.InputEnded:Connect(function(i3)
                            if i3.UserInputType == Enum.UserInputType.MouseButton1 then
                                if moveConn then moveConn:Disconnect() end
                                if endConn then endConn:Disconnect() end
                            end
                        end)
                    end
                end)

                Swatch.MouseButton1Click:Connect(function()
                    Popup.Visible = not Popup.Visible
                    if Popup.Visible then
                        tween(Popup, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(0, 180, 0, 86)})
                    end
                end)

                -- initialize
                do
                    local h,s,v = Value:ToHSV()
                    Hue, Sat, Val = h, s, v
                    updateFromHSV()
                end

                return {
                    Set = function(c: Color3)
                        local h,s,v = c:ToHSV()
                        Hue, Sat, Val = h, s, v
                        updateFromHSV()
                    end,
                    Get = function() return Value end
                }
            end

            function SectionAPI:addSlider(slName: string, min: number, max: number, default: number, callback: ((value: number) -> ())?)
                local Row = makeRowBase(40)
                label(Row, string.format("%s (%d - %d)", slName, min, max))

                local Value = math.clamp(default or min, min, max)
                local Bar = new("Frame", {
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(0, 260, 0, 8),
                    Position = UDim2.new(1, -270, 0.5, -4),
                }, Row)
                addCorner(Bar, 4)
                new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Bar)

                local Fill = new("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new((Value - min) / math.max(1, max - min), 0, 1, 0),
                }, Bar)
                addCorner(Fill, 4)

                local Knob = new("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new((Value - min) / math.max(1, max - min), -6, 0.5, -6),
                }, Bar)
                addCorner(Knob, 6)

                local ValLabel = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = tostring(Value),
                    Font = PIXEL_FONT,
                    TextSize = 14,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(0, 40, 1, 0),
                    Position = UDim2.new(1, -40, 0, -2),
                }, Row)

                local function setValueFromX(x)
                    local abs = Bar.AbsoluteSize.X
                    local left = Bar.AbsolutePosition.X
                    local alpha = math.clamp((x - left) / math.max(1, abs), 0, 1)
                    local v = min + alpha * (max - min)
                    v = round(v, 1)
                    Value = math.clamp(v, min, max)
                    Fill.Size = UDim2.new(alpha, 0, 1, 0)
                    Knob.Position = UDim2.new(alpha, -6, 0.5, -6)
                    ValLabel.Text = tostring(Value)
                    if callback then task.spawn(callback, Value) end
                end

                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setValueFromX(input.Position.X)
                        local moveConn
                        moveConn = UserInputService.InputChanged:Connect(function(i2)
                            if i2.UserInputType == Enum.UserInputType.MouseMovement then
                                setValueFromX(i2.Position.X)
                            end
                        end)
                        local endConn
                        endConn = UserInputService.InputEnded:Connect(function(i3)
                            if i3.UserInputType == Enum.UserInputType.MouseButton1 then
                                if moveConn then moveConn:Disconnect() end
                                if endConn then endConn:Disconnect() end
                            end
                        end)
                    end
                end)

                return {
                    Set = function(v: number)
                        v = math.clamp(v, min, max)
                        local alpha = (v - min) / math.max(1, max - min)
                        Value = v
                        Fill.Size = UDim2.new(alpha, 0, 1, 0)
                        Knob.Position = UDim2.new(alpha, -6, 0.5, -6)
                        ValLabel.Text = tostring(Value)
                        if callback then task.spawn(callback, Value) end
                    end,
                    Get = function() return Value end
                }
            end

                    function SectionAPI:addDropdown(ddName: string, options: {string}, default: string?, callback: ((opt: string) -> ())?)
            local Row = makeRowBase(34)
            label(Row, ddName)
        
            local Current = default or (options and options[1]) or ""
            local Btn = new("TextButton", {
                BackgroundColor3 = Theme.Background,
                AutoButtonColor = false,
                Text = Current,
                Font = PIXEL_FONT,
                TextSize = 14,
                TextColor3 = Theme.Text,
                Size = UDim2.new(0, 200, 0, 26),
                Position = UDim2.new(1, -210, 0.5, -13),
                ZIndex = 50, -- ปุ่มอยู่บน
            }, Row)
            addCorner(Btn, 6)
            new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Btn)
        
            -- ✅ ย้าย Popup ไปอยู่ใน ScreenGui เพื่อไม่โดน Clip
            local Popup = new("Frame", {
                Visible = false,
                BackgroundColor3 = Theme.Secondary,
                Size = UDim2.new(0, 200, 0, 6 + (#options * 28)),
                ClipsDescendants = false,
                ZIndex = 100, -- อยู่บนสุด
                Parent = Screen, -- อยู่บนสุดของ UI
            })
        
            addCorner(Popup, 6)
            new("UIStroke", {Color = Theme.Stroke, Thickness = 1}, Popup)
        
            local OptList = new("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, Popup)
            new("UIPadding", {
                PaddingTop = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
            }, Popup)
        
            local function choose(opt: string)
                Current = opt
                Btn.Text = opt
                Popup.Visible = false
                if callback then task.spawn(callback, opt) end
            end
        
            for _, opt in ipairs(options or {}) do
                local Opt = new("TextButton", {
                    BackgroundColor3 = Theme.Element,
                    AutoButtonColor = false,
                    Text = opt,
                    Font = PIXEL_FONT,
                    TextSize = 14,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(1, 0, 0, 24),
                    ZIndex = 101, -- สูงกว่า Popup
                }, Popup)
                addCorner(Opt, 4)
                Opt.MouseEnter:Connect(function()
                    tween(Opt, 0.08, nil, nil, {BackgroundColor3 = Theme.ElementHover})
                end)
                Opt.MouseLeave:Connect(function()
                    tween(Opt, 0.12, nil, nil, {BackgroundColor3 = Theme.Element})
                end)
                Opt.MouseButton1Click:Connect(function() choose(opt) end)
            end
        
            Btn.MouseButton1Click:Connect(function()
                -- คำนวณตำแหน่ง Popup ให้ตรงกับปุ่ม
                local absPos = Btn.AbsolutePosition
                local absSize = Btn.AbsoluteSize
                Popup.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y)
                Popup.Visible = not Popup.Visible
            end)
        
            return {
                Set = function(opt: string) choose(opt) end,
                Get = function() return Current end
            }
        end


            function SectionAPI:Resize(size: UDim2)
                Section.Size = size
            end

            return SectionAPI
        end

        function PageAPI.addResize(size: UDim2)
            Window.Size = size
        end

        return PageAPI
    end

    -- Public UI API
    local UI = {}

    function UI.addPage(name: string)
        if Pages[name] then return error("Page already exists: " .. name) end
        local page = createPage(name)
        if not SelectedPageName then
            setSelectedPage(name)
        end
        return page
    end

    function UI.addNotify(message, duration)
    duration = duration or 3
    message = tostring(message)

    -- สร้าง/หา container ด้านขวาบน
    local ToastContainer = Screen:FindFirstChild("ToastContainer")
    if not ToastContainer then
        ToastContainer = Instance.new("Frame")
        ToastContainer.Name = "ToastContainer"
        ToastContainer.AnchorPoint = Vector2.new(1, 0)
        ToastContainer.Position = UDim2.new(1, -20, 0, 20)
        ToastContainer.Size = UDim2.new(0, 300, 1, -40)
        ToastContainer.BackgroundTransparency = 1
        ToastContainer.ZIndex = 200
        ToastContainer.Parent = Screen

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = ToastContainer
    end

    -- กล่อง toast
    local Toast = Instance.new("Frame")
    Toast.Name = "Toast"
    Toast.Size = UDim2.new(0, 0, 0, 36) -- เริ่ม 0 เพื่อนไหลเข้า
    Toast.BackgroundColor3 = Theme.Secondary
    Toast.BackgroundTransparency = 0
    Toast.BorderSizePixel = 0
    Toast.ClipsDescendants = true
    Toast.ZIndex = 201
    Toast.Parent = ToastContainer

    addCorner(Toast, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Stroke
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Toast

    local Label = Instance.new("TextLabel")
    Label.Name = "Text"
    Label.BackgroundTransparency = 1
    Label.Font = PIXEL_FONT
    Label.Text = message
    Label.TextColor3 = Theme.Text
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -16, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.ZIndex = 202
    Label.Parent = Toast

    -- คำนวณความกว้างให้พอดีข้อความ
    local TextService = game:GetService("TextService")
    local bounds = TextService:GetTextSize(message, 14, PIXEL_FONT, Vector2.new(300, 36))
    local targetW = math.clamp(bounds.X + 24, 140, 300)

    -- สไลด์เข้าด้วยการขยายความกว้าง (ลักษณะเหมือนเลื่อนจากขวา)
    tween(Toast, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
        Size = UDim2.new(0, targetW, 0, 36)
    })

    -- รอแล้วสไลด์ออก
    task.delay(duration, function()
        if Toast and Toast.Parent then
            local tw = tween(Toast, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
                Size = UDim2.new(0, 0, 0, 36)
            })
            if tw and tw.Completed then
                pcall(function() tw.Completed:Wait() end)
            end
            if Toast then Toast:Destroy() end
        end
    end)
end

    function UI.addSelectPage(name: string)
        if not Pages[name] then return end
        setSelectedPage(name)
    end

    function UI.SetTheme(theme: any)
        -- Accept preset name or table overrides
        if typeof(theme) == "string" and theme:lower() == "darkyellow" then
            Theme = table.clone(DEFAULT_THEME)
        elseif typeof(theme) == "table" then
            for k, v in pairs(theme) do
                Theme[k] = v
            end
        end
        -- Repaint core UI
        Window.BackgroundColor3 = Theme.Background
        TopBar.BackgroundColor3 = Theme.Secondary
        Title.TextColor3 = Theme.Text
        PageBar.BackgroundColor3 = Theme.Secondary
        SectionArea.BackgroundColor3 = Theme.Background
        ToggleIcon.BackgroundColor3 = Theme.Accent
        ToggleIcon.TextColor3 = Theme.Background

        -- Repaint dynamic elements
        for _, inst in ipairs(Screen:GetDescendants()) do
            if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                (inst :: any).Font = PIXEL_FONT
                if inst ~= Title then
                    if inst:IsA("TextBox") then
                        -- leave color set by element maker
                    else
                        inst.TextColor3 = inst.Parent == ToggleIcon and Theme.Background or Theme.Text
                    end
                end
            elseif inst:IsA("Frame") or inst:IsA("ScrollingFrame") then
                if inst.Name == "PageBar" or inst.Name:find("Section") then
                    -- leave; already set
                end
            elseif inst:IsA("UIStroke") then
                inst.Color = Theme.Stroke
            end
        end
        -- Refresh selected page button color
        if SelectedPageName and PageButtons[SelectedPageName] then
            setSelectedPage(SelectedPageName)
        end
    end

    function UI.Toggle()
        IsOpen = not IsOpen
        if IsOpen then openEffects() else closeEffects() end
    end

    -- Initialize effects
    openEffects()

    -- Return Page API via UI.addPage, and others
    return UI
end

-- Return the library module
return Library
