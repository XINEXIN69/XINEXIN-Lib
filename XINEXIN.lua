--!strict
-- XINEXIN HUB - Minimal / Flat UI Library
-- Theme: Dark Yellow, Pixel/Bold, White text
-- Window Size: UDim2.new(0, 763, 0, 465)
-- Window Position: UDim2.new(0.5, 0, 0.49939, 0)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

type Theme = {
    ColorPrimary: Color3,
    ColorPrimaryHover: Color3,
    ColorAccent: Color3,
    ColorBackground: Color3,
    ColorForeground: Color3,
    ColorMuted: Color3,
    TextColor: Color3,
    FontMain: Enum.Font,
    FontBold: Enum.Font
}

local DEFAULT_THEME: Theme = {
    ColorPrimary = Color3.fromRGB(220, 170, 0), -- dark yellow
    ColorPrimaryHover = Color3.fromRGB(255, 196, 32),
    ColorAccent = Color3.fromRGB(255, 215, 64),
    ColorBackground = Color3.fromRGB(16,16,16),
    ColorForeground = Color3.fromRGB(28,28,28),
    ColorMuted = Color3.fromRGB(64,64,64),
    TextColor = Color3.fromRGB(255,255,255),
    FontMain = Enum.Font.Arcade, -- pixel-like
    FontBold = Enum.Font.GothamBold
}

local EASING_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EASING_BOUNCE = TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local EASING_SLIDE = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EASING_FADE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tween(obj: Instance, info: TweenInfo, props: {[string]: any})
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function mk(className: string, props: {[string]: any}?, parent: Instance?): Instance
    local inst = Instance.new(className)
    if props then
        for k,v in pairs(props) do
            (inst :: any)[k] = v
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function makeDraggable(frame: Frame, dragHandle: Instance?)
    local dragging = false
    local dragStart: Vector2? = nil
    local startPos: UDim2? = nil
    local handle = dragHandle or frame

    handle.InputBegan:Connect(function(input)
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

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - (dragStart :: Vector2)
            frame.Position = UDim2.new(
                (startPos :: UDim2).X.Scale,
                (startPos :: UDim2).X.Offset + delta.X,
                (startPos :: UDim2).Y.Scale,
                (startPos :: UDim2).Y.Offset + delta.Y
            )
        end
    end)
end

local function hoverBounceColor(button: GuiObject, normalColor: Color3, hoverColor: Color3)
    button.MouseEnter:Connect(function()
        tween(button, EASING_BOUNCE, {BackgroundColor3 = hoverColor})
    end)
    button.MouseLeave:Connect(function()
        tween(button, EASING_FAST, {BackgroundColor3 = normalColor})
    end)
end

local function addBlur(intensityTarget: number)
    local blur = Lighting:FindFirstChild("XINEXIN_Blur") :: BlurEffect
    if not blur then
        blur = mk("BlurEffect", {Name = "XINEXIN_Blur", Size = 0}, Lighting) :: BlurEffect
    end
    tween(blur, EASING_FAST, {Size = intensityTarget})
    return blur
end

local function zoomPop(guiObject: GuiObject)
    local scale = mk("UIScale", {Scale = 0.92}, guiObject)
    tween(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    task.delay(0.22, function()
        -- cleanup tiny easing jitter
        scale.Scale = 1
    end)
end

-- Object models
export type UI = {
    addPage: (self: UI, name: string) -> any,
    addNotify: (self: UI, message: string) -> (),
    addSelectPage: (self: UI, name: string) -> (),
    SetTheme: (self: UI, theme: Theme) -> (),
    Toggle: (self: UI) -> (),
    _root: ScreenGui
}

export type Page = {
    addSection: (self: Page, name: string) -> any,
    addResize: (self: Page, size: UDim2) -> (),
    _frame: Frame,
    _listItem: TextButton,
    _sections: {any}
}

export type Section = {
    addButton: (self: Section, name: string, callback: (() -> ())?) -> TextButton,
    addToggle: (self: Section, name: string, default: boolean?, callback: ((boolean) -> ())?) -> Frame,
    addTextbox: (self: Section, name: string, default: string?, callback: ((string) -> ())?) -> TextBox,
    addKeybind: (self: Section, name: string, default: Enum.KeyCode?, callback: ((Enum.KeyCode) -> ())?) -> TextButton,
    addColorPicker: (self: Section, name: string, default: Color3?, callback: ((Color3) -> ())?) -> Frame,
    addSlider: (self: Section, name: string, min: number, max: number, default: number, callback: ((number) -> ())?) -> Frame,
    addDropdown: (self: Section, name: string, options: {string}, default: string?, callback: ((string) -> ())?) -> Frame,
    Resize: (self: Section, size: UDim2) -> (),
    _frame: Frame
}

local XINEXIN = {}

function XINEXIN.new(titleText: string?, initialTheme: Theme?): UI
    local theme = initialTheme or DEFAULT_THEME

    -- ScreenGui
    local screen = mk("ScreenGui", {
        Name = "XINEXIN_HUB",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, LocalPlayer:WaitForChild("PlayerGui")) :: ScreenGui

    -- Toggle Icon (floating)
    local toggleIcon = mk("ImageButton", {
        Name = "ToggleIcon",
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.fromOffset(16, 200),
        BackgroundColor3 = theme.ColorPrimary,
        BorderSizePixel = 0,
        Image = "rbxassetid://3926305904", -- UI icon sheet
        ImageRectOffset = Vector2.new(244, 204),
        ImageRectSize = Vector2.new(36, 36),
        AutoButtonColor = false
    }, screen)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, toggleIcon)
    hoverBounceColor(toggleIcon, theme.ColorPrimary, theme.ColorPrimaryHover)
    makeDraggable(toggleIcon)

    -- Main window
    local main = mk("Frame", {
        Name = "Window",
        Size = UDim2.new(0, 763, 0, 465),
        Position = UDim2.new(0.5, 0, 0.49939, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.ColorBackground,
        BorderSizePixel = 0,
        Visible = false
    }, screen) :: Frame
    mk("UICorner", {CornerRadius = UDim.new(0, 12)}, main)
    mk("UIStroke", {Thickness = 1, Color = theme.ColorMuted, Transparency = 0.3}, main)

    -- Top bar
    local top = mk("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = theme.ColorForeground,
        BorderSizePixel = 0
    }, main) :: Frame
    mk("UICorner", {CornerRadius = UDim.new(0, 12)}, top)
    local title = mk("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text = titleText or "XINEXIN HUB",
        TextColor3 = theme.TextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = theme.FontBold,
        TextSize = 20
    }, top) :: TextLabel

    local closeBtn = mk("TextButton", {
        Name = "Close",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -36, 0.5, 0),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = theme.ColorPrimary,
        Text = "×",
        TextColor3 = theme.TextColor,
        Font = theme.FontBold,
        TextSize = 18,
        AutoButtonColor = false,
        BorderSizePixel = 0
    }, top) :: TextButton
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, closeBtn)
    hoverBounceColor(closeBtn, theme.ColorPrimary, theme.ColorPrimaryHover)

    -- Page bar (left)
    local pageBar = mk("Frame", {
        Name = "PageBar",
        Size = UDim2.new(0, 180, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = theme.ColorForeground,
        BorderSizePixel = 0
    }, main) :: Frame
    local pageList = mk("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, pageBar) :: UIListLayout
    mk("UIPadding", {PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10)}, pageBar)

    -- Section area (right)
    local content = mk("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -180, 1, -44),
        Position = UDim2.new(0, 180, 0, 44),
        BackgroundColor3 = theme.ColorBackground,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, main) :: Frame

    -- Notifications holder
    local notifHolder = mk("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1,0),
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.new(0, 320, 1, -24),
        BackgroundTransparency = 1
    }, main) :: Frame
    local notifList = mk("UIListLayout", {
        Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, notifHolder) :: UIListLayout

    -- Drag window by top bar
    makeDraggable(main, top)

    -- Toggle logic
    local function openGUI()
        main.Visible = true
        addBlur(12)
        zoomPop(main)
    end
    local function closeGUI()
        main.Visible = false
        addBlur(0)
    end
    toggleIcon.MouseButton1Click:Connect(function()
        if not main.Visible then openGUI() else closeGUI() end
    end)
    closeBtn.MouseButton1Click:Connect(closeGUI)

    -- Public UI object
    local ui: any = {
        _theme = theme,
        _root = screen,
        _main = main,
        _pageBar = pageBar,
        _content = content,
        _pages = {},
        _activePage = nil
    }

    function ui:addNotify(message: string)
        local item = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = self._theme.ColorForeground,
            BorderSizePixel = 0,
            Text = message,
            TextColor3 = self._theme.TextColor,
            Font = self._theme.FontBold,
            TextSize = 14
        }, notifHolder) :: TextLabel
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, item)
        item.BackgroundTransparency = 1
        item.TextTransparency = 1
        tween(item, EASING_FADE, {BackgroundTransparency = 0, TextTransparency = 0})
        task.delay(2.2, function()
            if item and item.Parent then
                local t1 = tween(item, EASING_FADE, {BackgroundTransparency = 1, TextTransparency = 1})
                t1.Completed:Wait()
                item:Destroy()
            end
        end)
    end

    function ui:SetTheme(newTheme: Theme)
        self._theme = newTheme
        -- Apply immediately to top-level elements
        main.BackgroundColor3 = newTheme.ColorBackground
        pageBar.BackgroundColor3 = newTheme.ColorForeground
        top.BackgroundColor3 = newTheme.ColorForeground
        closeBtn.BackgroundColor3 = newTheme.ColorPrimary
        title.TextColor3 = newTheme.TextColor
    end

    local function deselectAllPages()
        for _, p in pairs(ui._pages) do
            p._listItem.BackgroundColor3 = ui._theme.ColorForeground
            p._listItem.TextColor3 = ui._theme.TextColor
            p._frame.Visible = false
        end
    end

    function ui:addSelectPage(name: string)
        local p = self._pages[name]
        if not p then return end
        deselectAllPages()
        self._activePage = p
        p._listItem.BackgroundColor3 = self._theme.ColorPrimary
        p._listItem.TextColor3 = self._theme.TextColor
        p._frame.Visible = true
        -- Slide-in animation for section area
        p._frame.Position = UDim2.new(0, content.AbsoluteSize.X, 0, 0)
        tween(p._frame, EASING_SLIDE, {Position = UDim2.fromOffset(0,0)})
    end

    function ui:Toggle()
        if main.Visible then
            closeGUI()
        else
            openGUI()
        end
    end

    -- Pages
    local pageMT = {}
    pageMT.__index = pageMT

    function ui:addPage(name: string)
        local btn = mk("TextButton", {
            Name = "Page_"..name,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = self._theme.ColorForeground,
            BorderSizePixel = 0,
            Text = name,
            TextColor3 = self._theme.TextColor,
            Font = self._theme.FontMain,
            TextSize = 16,
            AutoButtonColor = false
        }, pageBar) :: TextButton
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
        hoverBounceColor(btn, self._theme.ColorForeground, self._theme.ColorPrimary)
        btn.MouseEnter:Connect(function()
            -- Color change + bounce already handled; add subtle text tint
            tween(btn, EASING_FAST, {TextColor3 = self._theme.TextColor})
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, EASING_FAST, {TextColor3 = self._theme.TextColor})
        end)

        local pageFrame = mk("Frame", {
            Name = "Page_"..name.."_Content",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false
        }, content) :: Frame

        local pageScroll = mk("ScrollingFrame", {
            Name = "Scroll",
            Size = UDim2.new(1, -24, 1, -24),
            Position = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(0,0,0,0),
            ScrollBarThickness = 4,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, pageFrame) :: ScrollingFrame
        local sectionList = mk("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, pageScroll) :: UIListLayout

        local page: any = {
            _parentUI = self,
            _frame = pageFrame,
            _scroll = pageScroll,
            _listItem = btn,
            _sections = {}
        }
        setmetatable(page, pageMT)

        btn.MouseButton1Click:Connect(function()
            self:addSelectPage(name)
        end)

        self._pages[name] = page

        -- Return page object
        return page
    end

    function pageMT:addResize(size: UDim2)
        -- Resize the main window when this page is active
        self._parentUI._main.Size = size
    end

    -- Sections
    local sectionMT = {}
    sectionMT.__index = sectionMT

    local function makeSectionCard(pageScroll: ScrollingFrame, theme: Theme, headerText: string)
        local card = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 80),
            BackgroundColor3 = theme.ColorForeground,
            BorderSizePixel = 0
        }, pageScroll) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(0, 10)}, card)
        local padding = mk("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        }, card) :: UIPadding
        local list = mk("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, card) :: UIListLayout

        local header = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = headerText,
            TextColor3 = theme.TextColor,
            Font = theme.FontBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left
        }, card) :: TextLabel

        return card
    end

    function pageMT:addSection(name: string)
        local card = makeSectionCard(self._scroll, self._parentUI._theme, name)
        local section: any = {
            _parentPage = self,
            _frame = card
        }
        setmetatable(section, sectionMT)
        table.insert(self._sections, section)
        return section
    end

    -- Controls
    local function labeledRow(sectionFrame: Frame, theme: Theme, labelText: string, height: number)
        local row = mk("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = theme.ColorBackground,
            BorderSizePixel = 0
        }, sectionFrame) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
        mk("UIStroke", {Color = theme.ColorMuted, Transparency = 0.3, Thickness = 1}, row)
        local label = mk("TextLabel", {
            Size = UDim2.new(0.5, -10, 1, 0),
            Position = UDim2.fromOffset(10,0),
            BackgroundTransparency = 1,
            Text = labelText,
            TextColor3 = theme.TextColor,
            Font = theme.FontMain,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)
        return row
    end

    function sectionMT:addButton(name: string, callback: (() -> ())?)
        local row = labeledRow(self._frame, self._parentPage._parentUI._theme, name, 36)
        local btn = mk("TextButton", {
            Size = UDim2.new(0, 120, 0, 28),
            Position = UDim2.new(1, -130, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = self._parentPage._parentUI._theme.ColorPrimary,
            Text = "Run",
            TextColor3 = self._parentPage._parentUI._theme.TextColor,
            Font = self._parentPage._parentUI._theme.FontBold,
            TextSize = 14,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Parent = row
        }) :: TextButton
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
        hoverBounceColor(btn, self._parentPage._parentUI._theme.ColorPrimary, self._parentPage._parentUI._theme.ColorPrimaryHover)
        btn.MouseButton1Click:Connect(function()
            if callback then
                task.spawn(callback)
            end
        end)
        return btn
    end

    function sectionMT:addToggle(name: string, default: boolean?, callback: ((boolean) -> ())?)
        local row = labeledRow(self._frame, self._parentPage._parentUI._theme, name, 36)
        local knob = mk("Frame", {
            Size = UDim2.fromOffset(44, 24),
            Position = UDim2.new(1, -50, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = self._parentPage._parentUI._theme.ColorMuted,
            BorderSizePixel = 0
        }, row) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
        local dot = mk("Frame", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.fromOffset(3, 3),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            BorderSizePixel = 0
        }, knob) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)

        local state = default == true
        local function render()
            tween(knob, EASING_FAST, {BackgroundColor3 = state and self._parentPage._parentUI._theme.ColorPrimary or self._parentPage._parentUI._theme.ColorMuted})
            tween(dot, EASING_FAST, {Position = state and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3)})
        end
        render()

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                state = not state
                render()
                if callback then task.spawn(callback, state) end
            end
        end)

        return knob
    end

    function sectionMT:addTextbox(name: string, default: string?, callback: ((string) -> ())?)
        local row = labeledRow(self._frame, self._parentPage._parentUI._theme, name, 36)
        local box = mk("TextBox", {
            Size = UDim2.new(0, 220, 0, 28),
            Position = UDim2.new(1, -230, 0.5, 0),
            AnchorPoint = Vector2.new(0.5,0.5),
            BackgroundColor3 = self._parentPage._parentUI._theme.ColorForeground,
            BorderSizePixel = 0,
            Text = default or "",
            PlaceholderText = "Enter text",
            TextColor3 = self._parentPage._parentUI._theme.TextColor,
            PlaceholderColor3 = Color3.fromRGB(180,180,180),
            Font = self._parentPage._parentUI._theme.FontMain,
            TextSize = 14,
            ClearTextOnFocus = false,
            Parent = row
        }) :: TextBox
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, box)
        mk("UIStroke", {Color = self._parentPage._parentUI._theme.ColorMuted, Transparency = 0.3}, box)

        box.FocusLost:Connect(function(enterPressed)
            if callback then task.spawn(callback, box.Text) end
        end)
        return box
    end

    function sectionMT:addKeybind(name: string, default: Enum.KeyCode?, callback: ((Enum.KeyCode) -> ())?)
        local current = default or Enum.KeyCode.F
        local row = labeledRow(self._frame, self._parentPage._parentUI._theme, name, 36)
        local btn = mk("TextButton", {
            Size = UDim2.fromOffset(120, 28),
            Position = UDim2.new(1, -130, 0.5, 0),
            AnchorPoint = Vector2.new(0.5,0.5),
            BackgroundColor3 = self._parentPage._parentUI._theme.ColorForeground,
            Text = current.Name,
            TextColor3 = self._parentPage._parentUI._theme.TextColor,
            Font = self._parentPage._parentUI._theme.FontBold,
            TextSize = 14,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Parent = row
        }) :: TextButton
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
        hoverBounceColor(btn, self._parentPage._parentUI._theme.ColorForeground, self._parentPage._parentUI._theme.ColorPrimary)

        local binding = false
        btn.MouseButton1Click:Connect(function()
            binding = true
            btn.Text = "Press key..."
        end)

        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode
                btn.Text = current.Name
                binding = false
                if callback then task.spawn(callback, current) end
            end
        end)

        return btn
    end

    function sectionMT:addColorPicker(name: string, default: Color3?, callback: ((Color3) -> ())?)
        local row = labeledRow(self._frame, self._parentPage._parentUI._theme, name, 60)
        local swatch = mk("Frame", {
            Size = UDim2.fromOffset(60, 28),
            Position = UDim2.new(1, -70, 0, 16),
            BackgroundColor3 = default or Color3.fromRGB(255, 196, 32),
            BorderSizePixel = 0,
            Parent = row
        }) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(0, 6)}, swatch)
        mk("UIStroke", {Color = self._parentPage._parentUI._theme.ColorMuted, Transparency = 0.3}, swatch)

        -- Simple palette
        local palette = {
            Color3.fromRGB(255,196,32),
            Color3.fromRGB(255,90,90),
            Color3.fromRGB(90,200,120),
            Color3.fromRGB(90,160,255),
            Color3.fromRGB(180,90,255),
            Color3.fromRGB(255,140,90)
        }
        local rowPal = mk("Frame", {
            Size = UDim2.new(0, 220, 0, 28),
            Position = UDim2.new(1, -300, 0, 16),
            BackgroundTransparency = 1,
            Parent = row
        }) :: Frame
        local palList = mk("UIListLayout", {Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Horizontal}, rowPal) :: UIListLayout

        for _, c in ipairs(palette) do
            local chip = mk("TextButton", {
                Size = UDim2.fromOffset(28, 28),
                BackgroundColor3 = c,
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Parent = rowPal
            }) :: TextButton
            mk("UICorner", {CornerRadius = UDim.new(0, 6)}, chip)
            hoverBounceColor(chip, c, c:Lerp(Color3.new(1,1,1), 0.12))
            chip.MouseButton1Click:Connect(function()
                swatch.BackgroundColor3 = c
                if callback then task.spawn(callback, c) end
            end)
        end
        return row
    end

    function sectionMT:addSlider(name: string, min: number, max: number, default: number, callback: ((number) -> ())?)
        min = min or 0; max = max or 100
        default = math.clamp(default or min, min, max)

        local row = labeledRow(self._frame, self._parentPage._parentUI._theme, name, 48)
        local bar = mk("Frame", {
            Size = UDim2.new(0, 260, 0, 6),
            Position = UDim2.new(1, -280, 0.5, 0),
            AnchorPoint = Vector2.new(0.5,0.5),
            BackgroundColor3 = self._parentPage._parentUI._theme.ColorForeground,
            BorderSizePixel = 0,
            Parent = row
        }) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(1, 0)}, bar)

        local fill = mk("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = self._parentPage._parentUI._theme.ColorPrimary,
            BorderSizePixel = 0,
            Parent = bar
        }) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)

        local knob = mk("Frame", {
            Size = UDim2.fromOffset(12, 12),
            Position = UDim2.fromOffset(0, -3),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            BorderSizePixel = 0,
            Parent = fill
        }) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

        local valueLabel = mk("TextLabel", {
            Size = UDim2.fromOffset(60, 16),
            Position = UDim2.new(1, -60, 0, 4),
            BackgroundTransparency = 1,
            Text = tostring(default),
            TextColor3 = self._parentPage._parentUI._theme.TextColor,
            Font = self._parentPage._parentUI._theme.FontBold,
            TextSize = 14,
            Parent = row
        }) :: TextLabel

        local function setValue(v: number)
            local alpha = (v - min) / (max - min)
            alpha = math.clamp(alpha, 0, 1)
            tween(fill, EASING_FAST, {Size = UDim2.new(alpha, 0, 1, 0)})
            valueLabel.Text = tostring(math.floor(v + 0.5))
            if callback then task.spawn(callback, v) end
        end

        local dragging = false
        local function updateFromInput(x: number)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = min + rel * (max - min)
            setValue(v)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        setValue(default)
        return row
    end

    function sectionMT:addDropdown(name: string, options: {string}, default: string?, callback: ((string) -> ())?)
        local row = labeledRow(self._frame, self._parentPage._parentUI._theme, name, 36)
        local btn = mk("TextButton", {
            Size = UDim2.fromOffset(220, 28),
            Position = UDim2.new(1, -230, 0.5, 0),
            AnchorPoint = Vector2.new(0.5,0.5),
            BackgroundColor3 = self._parentPage._parentUI._theme.ColorForeground,
            Text = default or (options[1] or "Select"),
            TextColor3 = self._parentPage._parentUI._theme.TextColor,
            Font = self._parentPage._parentUI._theme.FontMain,
            TextSize = 14,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Parent = row
        }) :: TextButton
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
        hoverBounceColor(btn, self._parentPage._parentUI._theme.ColorForeground, self._parentPage._parentUI._theme.ColorPrimary)

        local listFrame = mk("Frame", {
            Size = UDim2.new(0, 220, 0, 0),
            Position = UDim2.new(1, -230, 0, 36),
            BackgroundColor3 = self._parentPage._parentUI._theme.ColorForeground,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = false,
            Parent = row
        }) :: Frame
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, listFrame)
        local inner = mk("Frame", {
            Size = UDim2.new(1, -8, 0, #options * 28 + 8),
            Position = UDim2.fromOffset(4,4),
            BackgroundTransparency = 1,
            Parent = listFrame
        }) :: Frame
        local ilist = mk("UIListLayout", {Padding = UDim.new(0,6)}, inner) :: UIListLayout

        for _,opt in ipairs(options) do
            local o = mk("TextButton", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = self._parentPage._parentUI._theme.ColorBackground,
                Text = opt,
                TextColor3 = self._parentPage._parentUI._theme.TextColor,
                Font = self._parentPage._parentUI._theme.FontMain,
                TextSize = 14,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Parent = inner
            }) :: TextButton
            mk("UICorner", {CornerRadius = UDim.new(0, 6)}, o)
            hoverBounceColor(o, self._parentPage._parentUI._theme.ColorBackground, self._parentPage._parentUI._theme.ColorPrimary)
            o.MouseButton1Click:Connect(function()
                btn.Text = opt
                if callback then task.spawn(callback, opt) end
                tween(listFrame, EASING_FAST, {Size = UDim2.new(0, 220, 0, 0)})
                task.delay(0.18, function() listFrame.Visible = false end)
            end)
        end

        btn.MouseButton1Click:Connect(function()
            local open = not listFrame.Visible
            listFrame.Visible = true
            tween(listFrame, EASING_FAST, {Size = open and UDim2.new(0, 220, 0, math.min(#options, 6)*28 + 16) or UDim2.new(0, 220, 0, 0)})
            if not open then
                task.delay(0.18, function() listFrame.Visible = false end)
            end
        end)

        return row
    end

    function sectionMT:Resize(size: UDim2)
        self._frame.Size = size
    end

    -- Open initially (optional)
    main.Visible = true
    addBlur(12)
    zoomPop(main)

    return ui :: UI
end

return XINEXIN
