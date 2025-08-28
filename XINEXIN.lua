--[[
    XINEXIN HUB - Minimal / Flat UI Library for Delta Executor
    Theme: Dark Yellow (Premium)
    Font: Pixel Bold (using Enum.Font.Arcade)
    Text Color: White
    Window Size: UDim2.new(0, 735, 0, 379)
    Window Position: UDim2.new(0.26607, 0, 0.26773, 0)
    Author: XINEXIN
    License: MIT (optional, adjust as you wish)

    Usage:
        local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/your/repo/main/XINEXIN_HUB.lua"))()

        -- Build UI
        local page = UI:addPage("Main")
        local section = page:addSection("Utilities")
        section:addButton("Hello", function() print("Clicked") end)
        section:addToggle("God Mode", false, function(state) print("God Mode:", state) end)
        section:addSlider("WalkSpeed", 16, 200, 16, function(v) print("WS:", v) end)
        section:addDropdown("Team", {"Red", "Blue", "Neutral"}, "Neutral", function(opt) print("Team:", opt) end)
        section:addTextbox("Custom Name", "Player", function(text) print("Name:", text) end)
        section:addKeybind("Open/Close", Enum.KeyCode.RightControl, function() UI:Toggle() end)
        section:addColorPicker("Accent", Color3.fromRGB(212,175,55), function(color) UI:SetTheme({Accent=color}) end)

        UI:addNotify("XINEXIN HUB Loaded")
        UI:addSelectPage("Main")
]]

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local function safeParent()
    local ok, coregui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coregui then return coregui end
    if LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") then
        return LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    return game:GetService("CoreGui")
end

local function tween(obj, time, props, style, dir)
    local t = TS:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function roundify(gui, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Name = "UICorner"
    c.Parent = gui
    return c
end

local function padding(gui, pad)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, pad or 8)
    p.PaddingBottom = UDim.new(0, pad or 8)
    p.PaddingLeft = UDim.new(0, pad or 8)
    p.PaddingRight = UDim.new(0, pad or 8)
    p.Parent = gui
    return p
end

local function vlist(gui, pad)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, pad or 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = gui
    return l
end

local function hlist(gui, pad)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, pad or 6)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    l.Parent = gui
    return l
end

local function makeDraggable(dragHandle, targetFrame)
    local dragging = false
    local dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function hoverBounce(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, 0.15, {BackgroundColor3 = hoverColor})
        tween(button, 0.12, {Size = button.Size + UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Back)
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.15, {BackgroundColor3 = normalColor})
        tween(button, 0.12, {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0, math.max(button.AbsoluteSize.Y - 2, 28))})
    end)
end

local function tryFont(obj)
    obj.Font = Enum.Font.Arcade -- Pixel/retro feel; bold by default for this font
end

-- Default Theme (Dark Yellow Premium)
local defaultTheme = {
    Background = Color3.fromRGB(18, 18, 18),
    Panel = Color3.fromRGB(25, 25, 25),
    Accent = Color3.fromRGB(212, 175, 55),
    AccentHover = Color3.fromRGB(230, 195, 80),
    Text = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(160, 160, 160),
    Stroke = Color3.fromRGB(40, 40, 40),
    Slider = Color3.fromRGB(36, 36, 36),
    ToggleOff = Color3.fromRGB(70, 70, 70),
    ToggleOn = Color3.fromRGB(212, 175, 55),
}

-- Library factory
local function XINEXIN(initConfig)
    initConfig = initConfig or {}
    local Theme = table.clone(defaultTheme)
    for k, v in pairs(initConfig.Theme or {}) do Theme[k] = v end

    -- Build ScreenGui
    local parent = safeParent()
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.Name = "XINEXIN_HUB"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = parent

    -- Root container (scale for zoom-in)
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.Parent = gui

    local rootScale = Instance.new("UIScale", root)
    rootScale.Scale = 0.94

    -- Toggle icon (floating)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleIcon"
    toggleBtn.Size = UDim2.new(0, 38, 0, 38)
    toggleBtn.Position = UDim2.new(0, 18, 0.8, 0)
    toggleBtn.Text = "☰"
    toggleBtn.TextSize = 18
    tryFont(toggleBtn)
    toggleBtn.TextColor3 = Theme.Text
    toggleBtn.BackgroundColor3 = Theme.Accent
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = gui
    roundify(toggleBtn, 10)
    makeDraggable(toggleBtn, toggleBtn)
    hoverBounce(toggleBtn, Theme.Accent, Theme.AccentHover)

    -- Main window
    local window = Instance.new("Frame")
    window.Name = "Window"
    window.Size = UDim2.new(0, 735, 0, 379)
    window.Position = UDim2.new(0.26607, 0, 0.26773, 0)
    window.BackgroundColor3 = Theme.Background
    window.BorderSizePixel = 0
    window.Parent = root
    roundify(window, 12)

    local stroke = Instance.new("UIStroke", window)
    stroke.Thickness = 1
    stroke.Color = Theme.Stroke
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Top bar
    local topbar = Instance.new("Frame")
    topbar.Name = "TopBar"
    topbar.Size = UDim2.new(1, 0, 0, 36)
    topbar.BackgroundColor3 = Theme.Panel
    topbar.BorderSizePixel = 0
    topbar.Parent = window
    roundify(topbar, 12)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.AnchorPoint = Vector2.new(0, 0.5)
    title.Position = UDim2.new(0, 12, 0.5, 0)
    title.Size = UDim2.new(0.5, 0, 1, -8)
    title.BackgroundTransparency = 1
    title.Text = "XINEXIN HUB"
    tryFont(title)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Theme.Text
    title.Parent = topbar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, -8, 0.5, 0)
    closeBtn.Size = UDim2.new(0, 32, 0, 24)
    closeBtn.BackgroundColor3 = Theme.Accent
    closeBtn.Text = "×"
    closeBtn.TextSize = 16
    tryFont(closeBtn)
    closeBtn.TextColor3 = Theme.Text
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = topbar
    roundify(closeBtn, 8)
    hoverBounce(closeBtn, Theme.Accent, Theme.AccentHover)

    makeDraggable(topbar, window)

    -- Page bar
    local pagebar = Instance.new("Frame")
    pagebar.Name = "PageBar"
    pagebar.AnchorPoint = Vector2.new(0, 0)
    pagebar.Position = UDim2.new(0, 0, 0, 36)
    pagebar.Size = UDim2.new(0, 160, 1, -36)
    pagebar.BackgroundColor3 = Theme.Panel
    pagebar.BorderSizePixel = 0
    pagebar.Parent = window

    local pageList = Instance.new("ScrollingFrame")
    pageList.Name = "PageList"
    pageList.Size = UDim2.new(1, 0, 1, 0)
    pageList.CanvasSize = UDim2.new(0, 0, 0, 0)
    pageList.ScrollBarThickness = 3
    pageList.BackgroundTransparency = 1
    pageList.Parent = pagebar

    padding(pageList, 8)
    local pageLayout = vlist(pageList, 6)

    -- Section/content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.new(0, 160, 0, 36)
    content.Size = UDim2.new(1, -160, 1, -36)
    content.BackgroundColor3 = Theme.Background
    content.BorderSizePixel = 0
    content.Parent = window
    roundify(content, 12)

    local pageContainer = Instance.new("Frame")
    pageContainer.Name = "PageContainer"
    pageContainer.BackgroundTransparency = 1
    pageContainer.Size = UDim2.new(1, -16, 1, -16)
    pageContainer.Position = UDim2.new(0, 8, 0, 8)
    pageContainer.Parent = content

    -- Notifications container
    local notifyRoot = Instance.new("Frame")
    notifyRoot.Name = "Notifications"
    notifyRoot.BackgroundTransparency = 1
    notifyRoot.Size = UDim2.new(1, -20, 1, -20)
    notifyRoot.Position = UDim2.new(0, 10, 0, 10)
    notifyRoot.Parent = gui

    local notifyList = Instance.new("Frame")
    notifyList.Name = "NotifyList"
    notifyList.AnchorPoint = Vector2.new(1, 1)
    notifyList.Position = UDim2.new(1, 0, 1, 0)
    notifyList.Size = UDim2.new(0, 360, 1, -16)
    notifyList.BackgroundTransparency = 1
    notifyList.Parent = notifyRoot

    local notifyLayout = vlist(notifyList, 6)
    notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    -- Blur effect control
    local blur
    local function setBlur(on)
        if on then
            if not blur then
                blur = Instance.new("BlurEffect")
                blur.Size = 0
                blur.Parent = Lighting
            end
            tween(blur, 0.25, {Size = 12})
        else
            if blur then
                local tw = tween(blur, 0.2, {Size = 0})
                tw.Completed:Connect(function()
                    if blur then blur:Destroy() blur = nil end
                end)
            end
        end
    end

    -- Zoom animation (root scale)
    local function zoomOpen()
        tween(rootScale, 0.22, {Scale = 1})
    end
    local function zoomClose()
        tween(rootScale, 0.2, {Scale = 0.94})
    end

    -- State
    local UI = {}
    UI._Theme = Theme
    UI._Pages = {}
    UI._ActivePage = nil
    UI._Visible = true
    UI._Window = window
    UI._ToggleBtn = toggleBtn
    UI._Topbar = topbar
    UI._PageBar = pagebar
    UI._Content = content
    UI._PageContainer = pageContainer
    UI._NotifyList = notifyList

    -- Core behaviors
    local function selectPage(pageObj)
        if UI._ActivePage == pageObj then return end

        -- Deselect old
        if UI._ActivePage and UI._ActivePage._Tab then
            tween(UI._ActivePage._Tab, 0.15, {BackgroundColor3 = Theme.Panel})
        end

        UI._ActivePage = pageObj

        -- Bounce + hover color on tab
        if pageObj._Tab then
            tween(pageObj._Tab, 0.08, {BackgroundColor3 = Theme.Accent})
            tween(pageObj._TabText, 0.08, {TextColor3 = Theme.Text})
            tween(pageObj._Tab, 0.12, {Size = pageObj._Tab.Size + UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Back)
            task.delay(0.12, function()
                if pageObj._Tab then
                    tween(pageObj._Tab, 0.08, {Size = UDim2.new(pageObj._Tab.Size.X.Scale, pageObj._Tab.Size.X.Offset, 0, math.max(pageObj._Tab.AbsoluteSize.Y-2, 32))})
                end
            end)
        end

        -- Animate in selected page
        for _, p in pairs(UI._Pages) do
            if p._Body then
                p._Body.Visible = false
                p._Body.Position = UDim2.new(1, 0, 0, 0)
            end
        end

        if pageObj._Body then
            pageObj._Body.Visible = true
            pageObj._Body.Position = UDim2.new(1, 12, 0, 0)
            tween(pageObj._Body, 0.22, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Quad)
        end
    end

    -- Toggle visibility
    function UI:Toggle()
        UI._Visible = not UI._Visible
        window.Visible = UI._Visible
        if UI._Visible then
            setBlur(true)
            zoomOpen()
        else
            zoomClose()
            setBlur(false)
        end
    end

    -- Theme setter (partial override allowed)
    function UI:SetTheme(themeTable)
        for k, v in pairs(themeTable or {}) do
            if Theme[k] ~= nil then Theme[k] = v end
        end
        -- Apply key colors live
        window.BackgroundColor3 = Theme.Background
        topbar.BackgroundColor3 = Theme.Panel
        stroke.Color = Theme.Stroke
        toggleBtn.BackgroundColor3 = Theme.Accent
        toggleBtn.TextColor3 = Theme.Text
        closeBtn.BackgroundColor3 = Theme.Accent
        closeBtn.TextColor3 = Theme.Text
        -- Update existing tabs and pages
        for _, page in pairs(UI._Pages) do
            if page._Tab then
                page._Tab.BackgroundColor3 = (UI._ActivePage == page) and Theme.Accent or Theme.Panel
                page._TabText.TextColor3 = Theme.Text
            end
            if page._Body then
                page._Body.BackgroundColor3 = Theme.Background
            end
        end
    end

    -- Notifications
    function UI:addNotify(message)
        local note = Instance.new("Frame")
        note.Name = "Notify"
        note.Parent = UI._NotifyList
        note.BackgroundColor3 = Theme.Panel
        note.BorderSizePixel = 0
        note.Size = UDim2.new(0, 300, 0, 34)
        roundify(note, 10)

        local strokeN = Instance.new("UIStroke", note)
        strokeN.Color = Theme.Stroke
        strokeN.Thickness = 1

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -16, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.Text = tostring(message)
        tryFont(lbl)
        lbl.TextSize = 14
        lbl.TextColor3 = Theme.Text
        lbl.Parent = note

        note.BackgroundTransparency = 1
        lbl.TextTransparency = 1
        tween(note, 0.18, {BackgroundTransparency = 0})
        tween(lbl, 0.18, {TextTransparency = 0})

        task.delay(2.0, function()
            if note.Parent then
                tween(note, 0.18, {BackgroundTransparency = 1})
                tween(lbl, 0.18, {TextTransparency = 1}).Completed:Connect(function()
                    note:Destroy()
                end)
            end
        end)
    end

    -- Add Page
    function UI:addPage(name)
        name = tostring(name or ("Page " .. #UI._Pages + 1))

        -- Tab
        local tab = Instance.new("TextButton")
        tab.Name = "Tab_" .. name
        tab.Parent = pageList
        tab.Size = UDim2.new(1, -8, 0, 32)
        tab.BackgroundColor3 = Theme.Panel
        tab.Text = ""
        tab.AutoButtonColor = false
        roundify(tab, 8)

        local tabText = Instance.new("TextLabel")
        tabText.BackgroundTransparency = 1
        tabText.Size = UDim2.new(1, -16, 1, 0)
        tabText.Position = UDim2.new(0, 8, 0, 0)
        tabText.TextXAlignment = Enum.TextXAlignment.Left
        tabText.TextYAlignment = Enum.TextYAlignment.Center
        tabText.Text = name
        tryFont(tabText)
        tabText.TextSize = 14
        tabText.TextColor3 = Theme.Text
        tabText.Parent = tab

        hoverBounce(tab, Theme.Panel, Theme.AccentHover)

        tab.MouseEnter:Connect(function()
            if UI._ActivePage and UI._ActivePage._Tab == tab then return end
            tween(tab, 0.15, {BackgroundColor3 = Theme.AccentHover})
        end)
        tab.MouseLeave:Connect(function()
            if UI._ActivePage and UI._ActivePage._Tab == tab then return end
            tween(tab, 0.15, {BackgroundColor3 = Theme.Panel})
        end)

        -- Body
        local body = Instance.new("Frame")
        body.Name = "Body_" .. name
        body.Parent = pageContainer
        body.Size = UDim2.new(1, 0, 1, 0)
        body.Position = UDim2.new(1, 0, 0, 0)
        body.BackgroundColor3 = Theme.Background
        body.BorderSizePixel = 0
        body.Visible = false

        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "Scroll"
        scroll.Parent = body
        scroll.BackgroundTransparency = 1
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.ScrollBarThickness = 4

        padding(scroll, 10)
        local sectionLayout = vlist(scroll, 10)

        -- Page object
        local Page = {
            _UI = UI,
            _Name = name,
            _Tab = tab,
            _TabText = tabText,
            _Body = body,
            _Scroll = scroll,
            _Layout = sectionLayout,
            _Sections = {}
        }

        function Page:addSection(titleText)
            local section = Instance.new("Frame")
            section.Name = "Section_" .. tostring(titleText or "Untitled")
            section.Parent = scroll
            section.Size = UDim2.new(1, -4, 0, 64)
            section.BackgroundColor3 = Theme.Panel
            section.BorderSizePixel = 0
            roundify(section, 10)

            local sectionStroke = Instance.new("UIStroke", section)
            sectionStroke.Color = Theme.Stroke
            sectionStroke.Thickness = 1

            local container = Instance.new("Frame")
            container.Name = "Container"
            container.Parent = section
            container.BackgroundTransparency = 1
            container.Size = UDim2.new(1, -16, 1, -16)
            container.Position = UDim2.new(0, 8, 0, 8)

            local title = Instance.new("TextLabel")
            title.Name = "Title"
            title.Parent = container
            title.BackgroundTransparency = 1
            title.Size = UDim2.new(1, 0, 0, 18)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Text = tostring(titleText or "Section")
            tryFont(title)
            title.TextSize = 14
            title.TextColor3 = Theme.Text

            local items = Instance.new("Frame")
            items.Name = "Items"
            items.Parent = container
            items.BackgroundTransparency = 1
            items.Position = UDim2.new(0, 0, 0, 22)
            items.Size = UDim2.new(1, 0, 1, -22)

            local layout = vlist(items, 6)

            local Section = {
                _Page = Page,
                _Frame = section,
                _Items = items,
                _Layout = layout,
            }

            local function autoHeight()
                task.defer(function()
                    local total = 28 -- title + padding baseline
                    for _, child in ipairs(items:GetChildren()) do
                        if child:IsA("GuiObject") then
                            total += child.AbsoluteSize.Y + 6
                        end
                    end
                    tween(section, 0.12, {Size = UDim2.new(1, -4, 0, math.max(total + 14, 64))})
                    scroll.CanvasSize = UDim2.new(0, 0, 0, scroll.UIListLayout and scroll.UIListLayout.AbsoluteContentSize.Y or scroll.AbsoluteSize.Y)
                end)
            end

            items.ChildAdded:Connect(autoHeight)
            items.ChildRemoved:Connect(autoHeight)
            autoHeight()

            -- Controls factory
            local function baseRow(height)
                local row = Instance.new("Frame")
                row.Name = "Row"
                row.Size = UDim2.new(1, 0, 0, height or 32)
                row.BackgroundColor3 = Theme.Background
                row.BorderSizePixel = 0
                roundify(row, 8)
                local st = Instance.new("UIStroke", row)
                st.Color = Theme.Stroke
                st.Thickness = 1
                return row
            end

            local function label(parent, text)
                local t = Instance.new("TextLabel")
                t.BackgroundTransparency = 1
                t.Text = tostring(text or "")
                tryFont(t)
                t.TextSize = 14
                t.TextColor3 = Theme.Text
                t.TextXAlignment = Enum.TextXAlignment.Left
                t.TextTruncate = Enum.TextTruncate.AtEnd
                t.Parent = parent
                return t
            end

            function Section:addButton(name, callback)
                local row = baseRow(32)
                row.Parent = items

                local btn = Instance.new("TextButton")
                btn.BackgroundTransparency = 1
                btn.Size = UDim2.new(1, -16, 1, 0)
                btn.Position = UDim2.new(0, 8, 0, 0)
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Text = tostring(name or "Button")
                tryFont(btn)
                btn.TextSize = 14
                btn.TextColor3 = Theme.Text
                btn.AutoButtonColor = false
                btn.Parent = row

                btn.MouseEnter:Connect(function()
                    tween(row, 0.12, {BackgroundColor3 = Theme.Panel})
                end)
                btn.MouseLeave:Connect(function()
                    tween(row, 0.12, {BackgroundColor3 = Theme.Background})
                end)
                btn.MouseButton1Click:Connect(function()
                    if typeof(callback) == "function" then
                        task.spawn(callback)
                    end
                end)
                return row
            end

            function Section:addToggle(name, default, callback)
                local state = default and true or false
                local row = baseRow(32)
                row.Parent = items

                local text = label(row, name or "Toggle")
                text.Position = UDim2.new(0, 10, 0, 0)
                text.Size = UDim2.new(1, -70, 1, 0)

                local toggle = Instance.new("TextButton")
                toggle.AnchorPoint = Vector2.new(1, 0.5)
                toggle.Position = UDim2.new(1, -10, 0.5, 0)
                toggle.Size = UDim2.new(0, 42, 0, 20)
                toggle.AutoButtonColor = false
                toggle.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
                toggle.Text = ""
                toggle.Parent = row
                roundify(toggle, 10)

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 18, 0, 18)
                knob.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                knob.AnchorPoint = Vector2.new(0, 0)
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.Parent = toggle
                roundify(knob, 9)

                toggle.MouseButton1Click:Connect(function()
                    state = not state
                    tween(toggle, 0.12, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
                    tween(knob, 0.12, {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)})
                    if typeof(callback) == "function" then task.spawn(callback, state) end
                end)
                return {
                    Frame = row,
                    Set = function(_, v)
                        state = v and true or false
                        toggle.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
                        knob.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                    end,
                    Get = function() return state end
                }
            end

            function Section:addTextbox(name, default, callback)
                local row = baseRow(34)
                row.Parent = items

                local text = label(row, name or "Textbox")
                text.Position = UDim2.new(0, 10, 0, 0)
                text.Size = UDim2.new(0.6, -20, 1, 0)

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.4, -14, 0, 24)
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.Position = UDim2.new(1, -10, 0.5, 0)
                box.BackgroundColor3 = Theme.Panel
                box.Text = tostring(default or "")
                tryFont(box)
                box.TextSize = 14
                box.TextColor3 = Theme.Text
                box.ClearTextOnFocus = false
                box.Parent = row
                roundify(box, 8)

                box.FocusLost:Connect(function(enterPressed)
                    if typeof(callback) == "function" then task.spawn(callback, box.Text) end
                end)
                return {
                    Frame = row,
                    Set = function(_, v) box.Text = tostring(v or "") end,
                    Get = function() return box.Text end
                }
            end

            function Section:addKeybind(name, default, callback)
                local row = baseRow(32)
                row.Parent = items

                local text = label(row, name or "Keybind")
                text.Position = UDim2.new(0, 10, 0, 0)
                text.Size = UDim2.new(0.6, -20, 1, 0)

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.4, -14, 0, 24)
                btn.AnchorPoint = Vector2.new(1, 0.5)
                btn.Position = UDim2.new(1, -10, 0.5, 0)
                btn.BackgroundColor3 = Theme.Panel
                btn.Text = default and default.Name or "Unbound"
                tryFont(btn)
                btn.TextSize = 14
                btn.TextColor3 = Theme.Text
                btn.AutoButtonColor = false
                btn.Parent = row
                roundify(btn, 8)

                local current = default
                local capturing = false

                btn.MouseButton1Click:Connect(function()
                    capturing = true
                    btn.Text = "Press key..."
                    tween(btn, 0.12, {BackgroundColor3 = Theme.Accent})
                end)

                UIS.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if capturing then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            current = input.KeyCode
                            btn.Text = current.Name
                            tween(btn, 0.12, {BackgroundColor3 = Theme.Panel})
                            capturing = false
                        end
                    else
                        if current and input.KeyCode == current then
                            if typeof(callback) == "function" then task.spawn(callback) end
                        end
                    end
                end)

                return {
                    Frame = row,
                    Set = function(_, keycode)
                        current = keycode
                        btn.Text = current and current.Name or "Unbound"
                    end,
                    Get = function() return current end
                }
            end

            function Section:addColorPicker(name, default, callback)
                local row = baseRow(36)
                row.Parent = items

                local text = label(row, name or "Color")
                text.Position = UDim2.new(0, 10, 0, 0)
                text.Size = UDim2.new(1, -70, 1, 0)

                local swatch = Instance.new("TextButton")
                swatch.AnchorPoint = Vector2.new(1, 0.5)
                swatch.Position = UDim2.new(1, -10, 0.5, 0)
                swatch.Size = UDim2.new(0, 42, 0, 22)
                swatch.BackgroundColor3 = default or Theme.Accent
                swatch.Text = ""
                swatch.AutoButtonColor = false
                swatch.Parent = row
                roundify(swatch, 6)

                local palette = Instance.new("Frame")
                palette.Visible = false
                palette.Parent = row
                palette.Size = UDim2.new(0, 160, 0, 80)
                palette.Position = UDim2.new(1, -10, 0, 36)
                palette.BackgroundColor3 = Theme.Panel
                roundify(palette, 8)
                local palStroke = Instance.new("UIStroke", palette)
                palStroke.Color = Theme.Stroke

                local palCont = Instance.new("Frame")
                palCont.Parent = palette
                palCont.BackgroundTransparency = 1
                palCont.Size = UDim2.new(1, -8, 1, -8)
                palCont.Position = UDim2.new(0, 4, 0, 4)
                local grid = Instance.new("UIGridLayout", palCont)
                grid.CellPadding = UDim2.new(0, 6, 0, 6)
                grid.CellSize = UDim2.new(0, 22, 0, 22)

                local colors = {
                    Color3.fromRGB(212,175,55), Color3.fromRGB(255,204,0), Color3.fromRGB(255,170,0),
                    Color3.fromRGB(255,99,71), Color3.fromRGB(255,80,80), Color3.fromRGB(255,60,120),
                    Color3.fromRGB(120,120,255), Color3.fromRGB(80,180,255), Color3.fromRGB(80,220,180),
                    Color3.fromRGB(120,255,120), Color3.fromRGB(180,180,180), Color3.fromRGB(40,40,40)
                }
                for _, c in ipairs(colors) do
                    local cell = Instance.new("TextButton")
                    cell.Text = ""
                    cell.AutoButtonColor = false
                    cell.BackgroundColor3 = c
                    cell.Parent = palCont
                    roundify(cell, 6)
                    cell.MouseButton1Click:Connect(function()
                        swatch.BackgroundColor3 = c
                        if typeof(callback) == "function" then task.spawn(callback, c) end
                        tween(palette, 0.12, {BackgroundTransparency = 1})
                        palette.Visible = false
                        palette.BackgroundTransparency = 0
                    end)
                end

                swatch.MouseButton1Click:Connect(function()
                    palette.Visible = not palette.Visible
                    if palette.Visible then
                        palette.BackgroundTransparency = 1
                        tween(palette, 0.12, {BackgroundTransparency = 0})
                    end
                end)

                return {
                    Frame = row,
                    Set = function(_, c) swatch.BackgroundColor3 = c end,
                    Get = function() return swatch.BackgroundColor3 end
                }
            end

            function Section:addSlider(name, min, max, default, callback)
                min = tonumber(min) or 0
                max = tonumber(max) or 100
                local value = math.clamp(tonumber(default) or min, min, max)

                local row = baseRow(36)
                row.Parent = items

                local text = label(row, string.format("%s: %s", name or "Slider", value))
                text.Position = UDim2.new(0, 10, 0, 0)
                text.Size = UDim2.new(1, -20, 0, 16)

                local bar = Instance.new("Frame")
                bar.AnchorPoint = Vector2.new(0, 1)
                bar.Position = UDim2.new(0, 10, 1, -8)
                bar.Size = UDim2.new(1, -20, 0, 8)
                bar.BackgroundColor3 = Theme.Slider
                bar.Parent = row
                roundify(bar, 4)

                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = Theme.Accent
                fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                fill.Parent = bar
                roundify(fill, 4)

                local knob = Instance.new("Frame")
                knob.AnchorPoint = Vector2.new(0.5, 0.5)
                knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
                knob.Size = UDim2.new(0, 12, 0, 12)
                knob.BackgroundColor3 = Theme.Accent
                knob.Parent = bar
                roundify(knob, 6)

                local sliding = false
                local function setValueFromX(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + rel * (max - min) + 0.5)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, 0, 0.5, 0)
                    text.Text = string.format("%s: %s", name or "Slider", value)
                    if typeof(callback) == "function" then task.spawn(callback, value) end
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        setValueFromX(input.Position.X)
                    end
                end)
                UIS.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setValueFromX(input.Position.X)
                    end
                end)
                UIS.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)

                return {
                    Frame = row,
                    Set = function(_, v)
                        value = math.clamp(tonumber(v) or value, min, max)
                        local rel = (value - min) / (max - min)
                        fill.Size = UDim2.new(rel, 0, 1, 0)
                        knob.Position = UDim2.new(rel, 0, 0.5, 0)
                        text.Text = string.format("%s: %s", name or "Slider", value)
                    end,
                    Get = function() return value end
                }
            end

            function Section:addDropdown(name, options, default, callback)
                options = options or {}
                local current = default or (options[1] or "")

                local row = baseRow(34)
                row.Parent = items

                local text = label(row, name or "Dropdown")
                text.Position = UDim2.new(0, 10, 0, 0)
                text.Size = UDim2.new(0.6, -20, 1, 0)

                local box = Instance.new("TextButton")
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.Position = UDim2.new(1, -10, 0.5, 0)
                box.Size = UDim2.new(0.4, -14, 0, 24)
                box.BackgroundColor3 = Theme.Panel
                box.Text = tostring(current)
                tryFont(box)
                box.TextSize = 14
                box.TextColor3 = Theme.Text
                box.AutoButtonColor = false
                box.Parent = row
                roundify(box, 8)

                local list = Instance.new("Frame")
                list.Parent = row
                list.Visible = false
                list.AnchorPoint = Vector2.new(1, 0)
                list.Position = UDim2.new(1, -10, 0, 36)
                list.Size = UDim2.new(0, 180, 0, 0)
                list.BackgroundColor3 = Theme.Panel
                roundify(list, 8)
                local lstStroke = Instance.new("UIStroke", list)
                lstStroke.Color = Theme.Stroke

                local inner = Instance.new("ScrollingFrame")
                inner.BackgroundTransparency = 1
                inner.Size = UDim2.new(1, -8, 1, -8)
                inner.Position = UDim2.new(0, 4, 0, 4)
                inner.ScrollBarThickness = 3
                inner.Parent = list
                local innerLayout = vlist(inner, 4)

                local function rebuild()
                    inner:ClearAllChildren()
                    for _, opt in ipairs(options) do
                        local o = Instance.new("TextButton")
                        o.Size = UDim2.new(1, 0, 0, 24)
                        o.BackgroundColor3 = Theme.Background
                        o.Text = tostring(opt)
                        tryFont(o)
                        o.TextSize = 14
                        o.TextColor3 = Theme.Text
                        o.AutoButtonColor = false
                        o.Parent = inner
                        roundify(o, 6)
                        o.MouseEnter:Connect(function()
                            tween(o, 0.12, {BackgroundColor3 = Theme.AccentHover})
                        end)
                        o.MouseLeave:Connect(function()
                            tween(o, 0.12, {BackgroundColor3 = Theme.Background})
                        end)
                        o.MouseButton1Click:Connect(function()
                            current = opt
                            box.Text = tostring(opt)
                            if typeof(callback) == "function" then task.spawn(callback, current) end
                            tween(list, 0.12, {Size = UDim2.new(0, 180, 0, 0)})
                            list.Visible = false
                        end)
                    end
                    inner.CanvasSize = UDim2.new(0, 0, 0, innerLayout.AbsoluteContentSize.Y + 8)
                end
                rebuild()

                box.MouseButton1Click:Connect(function()
                    list.Visible = not list.Visible
                    if list.Visible then
                        tween(list, 0.12, {Size = UDim2.new(0, 180, 0, math.min(innerLayout.AbsoluteContentSize.Y + 12, 140))})
                    else
                        tween(list, 0.12, {Size = UDim2.new(0, 180, 0, 0)})
                    end
                end)

                return {
                    Frame = row,
                    Set = function(_, v)
                        current = v
                        box.Text = tostring(v)
                    end,
                    Get = function() return current end,
                    SetOptions = function(_, opts)
                        options = opts or {}
                        rebuild()
                    end
                }
            end

            function Section:Resize(size)
                if typeof(size) == "UDim2" then
                    section.Size = size
                elseif typeof(size) == "Vector2" then
                    section.Size = UDim2.new(0, size.X, 0, size.Y)
                elseif tonumber(size) then
                    section.Size = UDim2.new(1, -4, 0, tonumber(size))
                end
            end

            -- Smooth slide-in when Page is selected: handled by selectPage() when body becomes visible

            table.insert(Page._Sections, Section)
            return Section
        end

        function Page:addResize(size)
            if typeof(size) == "UDim2" then
                body.Size = size
            elseif typeof(size) == "Vector2" then
                body.Size = UDim2.new(0, size.X, 0, size.Y)
            elseif tonumber(size) then
                body.Size = UDim2.new(1, 0, 0, tonumber(size))
            end
        end

        -- Tab interactions
        tab.MouseButton1Click:Connect(function()
            selectPage(Page)
        end)

        table.insert(UI._Pages, Page)
        pageList.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 12)

        return Page
    end

    function UI:addSelectPage(name)
        for _, page in ipairs(UI._Pages) do
            if page._Name == name then
                selectPage(page)
                return page
            end
        end
        return nil
    end

    -- Aliases to match both dot and colon usage
    UI.AddPage = UI.addPage
    UI.AddNotify = UI.addNotify
    UI.AddSelectPage = UI.addSelectPage
    UI.SetTheme = UI.SetTheme
    UI.Toggle = UI.Toggle

    -- Controls: toggle icon
    toggleBtn.MouseButton1Click:Connect(function() UI:Toggle() end)
    closeBtn.MouseButton1Click:Connect(function() UI:Toggle() end)

    -- Initial open effects
    setBlur(true)
    zoomOpen()

    -- Public return
    return UI
end

-- Return the library instance (created immediately for ease-of-use) OR the factory.
-- For executors, users commonly call: local UI = loadstring(... )()
-- We return an instance by default; pass a config like: ()({ Theme = { Accent = Color3.from
