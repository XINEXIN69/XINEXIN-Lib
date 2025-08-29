--[[
  XINEXIN HUB - Minimal / Flat UI Library
  Theme: Dark Yellow Premium
  Font: Pixel (Arcade) Bold
  Text Color: White
  Window Size: UDim2.new(0, 735, 0, 379)
  Window Position: UDim2.new(0.26607, 0, 0.26773, 0)

  API:
    -- UI
    UI:addPage(name) -> Page
    UI:addNotify(message) -> void
    UI:addSelectPage(name) -> void
    UI:SetTheme(themeNameOrTable) -> void
    UI:Toggle() -> void

    -- Page
    Page:addSection(name) -> Section
    Page:addResize(sizeUDim2) -> void

    -- Section
    Section:addButton(name, callback) -> Button
    Section:addToggle(name, default, callback) -> Toggle
    Section:addTextbox(name, default, callback) -> Textbox
    Section:addKeybind(name, defaultKeyCode, callback) -> Keybind
    Section:addColorPicker(name, defaultColor3, callback) -> ColorPicker
    Section:addSlider(name, min, max, default, callback) -> Slider
    Section:addDropdown(name, optionsTable, default, callback) -> Dropdown
    Section:Resize(sizeUDim2) -> void
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local XinexinHub = {}

-- THEME
local Themes = {
  DarkYellowPremium = {
    Font = Enum.Font.Arcade,
    TextColor = Color3.fromRGB(255, 255, 255),
    WindowBg = Color3.fromRGB(16, 16, 16),
    PanelBg = Color3.fromRGB(22, 22, 22),
    Accent = Color3.fromRGB(255, 202, 40),
    AccentHover = Color3.fromRGB(255, 220, 90),
    AccentSoft = Color3.fromRGB(80, 60, 20),
    Outline = Color3.fromRGB(40, 40, 40),
    Shadow = Color3.fromRGB(0, 0, 0),
    PageIdle = Color3.fromRGB(60, 60, 60),
    PageHover = Color3.fromRGB(255, 202, 40),
    ControlBg = Color3.fromRGB(28, 28, 28),
    ControlHover = Color3.fromRGB(36, 36, 36),
    ToggleOn = Color3.fromRGB(255, 202, 40),
    ToggleOff = Color3.fromRGB(70, 70, 70),
    SliderFill = Color3.fromRGB(255, 202, 40),
    SliderBar = Color3.fromRGB(60, 60, 60),
    DropdownBg = Color3.fromRGB(24, 24, 24),
    NotifyBg = Color3.fromRGB(20, 20, 20)
  }
}

-- UTILS
local function corner(parent, radius)
  local c = Instance.new("UICorner")
  c.CornerRadius = UDim.new(0, radius or 6)
  c.Parent = parent
  return c
end

local function stroke(parent, color, thickness)
  local s = Instance.new("UIStroke")
  s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  s.Color = color
  s.Thickness = thickness or 1
  s.Parent = parent
  return s
end

local function padding(parent, px)
  local p = Instance.new("UIPadding")
  p.PaddingTop = UDim.new(0, px)
  p.PaddingBottom = UDim.new(0, px)
  p.PaddingLeft = UDim.new(0, px)
  p.PaddingRight = UDim.new(0, px)
  p.Parent = parent
  return p
end

local function vlist(parent, pad)
  local l = Instance.new("UIListLayout")
  l.FillDirection = Enum.FillDirection.Vertical
  l.HorizontalAlignment = Enum.HorizontalAlignment.Left
  l.VerticalAlignment = Enum.VerticalAlignment.Top
  l.SortOrder = Enum.SortOrder.LayoutOrder
  l.Padding = UDim.new(0, pad or 6)
  l.Parent = parent
  return l
end

local function hlist(parent, pad)
  local l = Instance.new("UIListLayout")
  l.FillDirection = Enum.FillDirection.Horizontal
  l.HorizontalAlignment = Enum.HorizontalAlignment.Left
  l.VerticalAlignment = Enum.VerticalAlignment.Center
  l.SortOrder = Enum.SortOrder.LayoutOrder
  l.Padding = UDim.new(0, pad or 6)
  l.Parent = parent
  return l
end

local function grid(parent, cellW, cellH, gap)
  local g = Instance.new("UIGridLayout")
  g.CellSize = UDim2.new(0, cellW, 0, cellH)
  g.CellPadding = UDim2.new(0, gap or 8, 0, gap or 8)
  g.SortOrder = Enum.SortOrder.LayoutOrder
  g.HorizontalAlignment = Enum.HorizontalAlignment.Left
  g.VerticalAlignment = Enum.VerticalAlignment.Top
  g.Parent = parent
  return g
end

local function tween(o, t, p)
  return TweenService:Create(o, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p or {})
end

local function draggable(frame, dragHandle)
  local dragging = false
  local startPos, startInputPos
  local handle = dragHandle or frame

  handle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

  UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
      local delta = input.Position - startInputPos
      frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
  end)
end

local function bounceHover(btn, baseColor, hoverColor)
  btn.MouseEnter:Connect(function()
    tween(btn, 0.12, {BackgroundColor3 = hoverColor, Size = btn.Size + UDim2.new(0, 4, 0, 4)}):Play()
  end)
  btn.MouseLeave:Connect(function()
    tween(btn, 0.12, {BackgroundColor3 = baseColor, Size = btn.Size - UDim2.new(0, 4, 0, 4)}):Play()
  end)
end

local function blurOpen(closeAfter)
  local b = Lighting:FindFirstChild("__XinexinBlur") or Instance.new("BlurEffect")
  b.Name = "__XinexinBlur"
  b.Size = 0
  b.Parent = Lighting
  tween(b, 0.18, {Size = 12}):Play()
  if closeAfter then
    task.delay(closeAfter, function()
      tween(b, 0.18, {Size = 0}):Play()
      task.delay(0.2, function() if b and b.Parent == Lighting then b:Destroy() end end)
    end)
  end
  return b
end

local function zoomPulse()
  local cam = workspace.CurrentCamera
  if not cam then return end
  local original = cam.FieldOfView
  local half = 0.08
  tween(cam, half, {FieldOfView = math.max(40, original - 8)}):Play()
  task.delay(half, function()
    tween(cam, half, {FieldOfView = original}):Play()
  end)
end

-- LIB CREATOR
function XinexinHub:Create(config)
  config = config or {}
  local theme = Themes.DarkYellowPremium
  local title = config.Title or "XINEXIN HUB"
  local size = UDim2.new(0, 735, 0, 379)
  local pos = UDim2.new(0.26607, 0, 0.26773, 0)

  local core = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

  -- ROOT GUI
  local screen = Instance.new("ScreenGui")
  screen.Name = "__XinexinHub"
  screen.ResetOnSpawn = false
  screen.IgnoreGuiInset = true
  screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  screen.Parent = core

  -- Toggle Icon
  local toggleIcon = Instance.new("TextButton")
  toggleIcon.Name = "ToggleIcon"
  toggleIcon.Size = UDim2.new(0, 34, 0, 34)
  toggleIcon.Position = UDim2.new(0, 12, 0.5, -17)
  toggleIcon.BackgroundColor3 = theme.Accent
  toggleIcon.Text = "≡"
  toggleIcon.Font = theme.Font
  toggleIcon.TextColor3 = theme.Shadow
  toggleIcon.TextSize = 18
  corner(toggleIcon, 8)
  stroke(toggleIcon, theme.Shadow, 1)
  toggleIcon.Active = true
  toggleIcon.Draggable = false -- custom draggable below
  toggleIcon.Parent = screen

  bounceHover(toggleIcon, theme.Accent, theme.AccentHover)
  draggable(toggleIcon, toggleIcon)

  -- WINDOW
  local window = Instance.new("Frame")
  window.Name = "Window"
  window.BackgroundColor3 = theme.WindowBg
  window.Size = size
  window.Position = pos
  window.Visible = false
  window.ClipsDescendants = true
  window.Parent = screen
  corner(window, 10)
  stroke(window, theme.Outline, 1)

  -- Top Bar
  local topbar = Instance.new("Frame")
  topbar.Name = "TopBar"
  topbar.BackgroundColor3 = theme.PanelBg
  topbar.Size = UDim2.new(1, 0, 0, 40)
  topbar.Parent = window
  stroke(topbar, theme.Outline, 1)

  local titleLbl = Instance.new("TextLabel")
  titleLbl.Name = "Title"
  titleLbl.BackgroundTransparency = 1
  titleLbl.Size = UDim2.new(1, -20, 1, 0)
  titleLbl.Position = UDim2.new(0, 10, 0, 0)
  titleLbl.Font = theme.Font
  titleLbl.Text = title
  titleLbl.TextColor3 = theme.TextColor
  titleLbl.TextXAlignment = Enum.TextXAlignment.Left
  titleLbl.TextSize = 20
  titleLbl.Parent = topbar

  -- Page Bar
  local pageBar = Instance.new("Frame")
  pageBar.Name = "PageBar"
  pageBar.BackgroundColor3 = theme.PanelBg
  pageBar.Size = UDim2.new(1, 0, 0, 42)
  pageBar.Position = UDim2.new(0, 0, 0, 40)
  pageBar.Parent = window
  stroke(pageBar, theme.Outline, 1)

  local pageBarPad = Instance.new("Frame")
  pageBarPad.Name = "Pad"
  pageBarPad.BackgroundTransparency = 1
  pageBarPad.Size = UDim2.new(1, -16, 1, -10)
  pageBarPad.Position = UDim2.new(0, 8, 0, 5)
  pageBarPad.Parent = pageBar

  local pageList = hlist(pageBarPad, 8)

  -- Section Area
  local sectionArea = Instance.new("Frame")
  sectionArea.Name = "SectionArea"
  sectionArea.BackgroundColor3 = theme.WindowBg
  sectionArea.Size = UDim2.new(1, 0, 1, -82)
  sectionArea.Position = UDim2.new(0, 0, 0, 82)
  sectionArea.Parent = window

  local sectionPad = Instance.new("Frame")
  sectionPad.Name = "Pad"
  sectionPad.BackgroundTransparency = 1
  sectionPad.Size = UDim2.new(1, -16, 1, -16)
  sectionPad.Position = UDim2.new(0, 8, 0, 8)
  sectionPad.Parent = sectionArea

  local sectionGrid = grid(sectionPad, 350, 150, 10)

  -- Drag window via top bar
  draggable(window, topbar)

  -- Blur + Zoom on open
  local activeBlur -- maintained when toggling

  local function showWindow(state)
    if state then
      window.Visible = true
      window.Size = UDim2.new(0, 0, 0, 0)
      window.Position = pos
      window.Size = size -- reset size base
      window.UIScale = window:FindFirstChild("OpenScale") or Instance.new("UIScale")
      window.UIScale.Name = "OpenScale"
      window.UIScale.Scale = 0.94
      window.UIScale.Parent = window
      tween(window.UIScale, 0.18, {Scale = 1}):Play()
      activeBlur = blurOpen()
      zoomPulse()
    else
      if activeBlur then tween(activeBlur, 0.18, {Size = 0}):Play() end
      tween(window, 0.12, {BackgroundTransparency = 1}):Play()
      task.delay(0.12, function()
        window.Visible = false
        window.BackgroundTransparency = 0
        if activeBlur then
          task.delay(0.06, function()
            if activeBlur then activeBlur:Destroy() end
            activeBlur = nil
          end)
        end
      end)
    end
  end

  toggleIcon.MouseButton1Click:Connect(function()
    showWindow(not window.Visible)
  end)

  -- NOTIFY STACK
  local notifyHolder = Instance.new("Frame")
  notifyHolder.Name = "NotifyHolder"
  notifyHolder.Parent = screen
  notifyHolder.AnchorPoint = Vector2.new(1, 1)
  notifyHolder.Position = UDim2.new(1, -16, 1, -16)
  notifyHolder.Size = UDim2.new(0, 320, 1, -32)
  notifyHolder.BackgroundTransparency = 1

  local notifyList = vlist(notifyHolder, 8)
  notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
  notifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom

  -- STATE
  local UI = {}
  UI.__index = UI

  local pages = {}           -- name -> PageObject
  local currentPage = nil    -- PageObject
  local pageButtons = {}     -- name -> button

  local function selectPage(name)
    local page = pages[name]
    if not page then return end

    -- update buttons visual
    for n, btn in pairs(pageButtons) do
      tween(btn, 0.15, {
        BackgroundColor3 = (n == name) and theme.PageHover or theme.PageIdle
      }):Play()
    end

    -- hide other sections
    for n, p in pairs(pages) do
      if n ~= name then
        for _, sec in ipairs(p.Sections) do
          sec.Frame.Visible = false
        end
      end
    end

    -- slide-in animation for this page's sections
    for i, sec in ipairs(page.Sections) do
      local f = sec.Frame
      f.Visible = true
      f.Position = UDim2.new(f.Position.X.Scale, f.Position.X.Offset + 24, f.Position.Y.Scale, f.Position.Y.Offset)
      tween(f, 0.14 + (i * 0.03), {Position = UDim2.new(f.Position.X.Scale, f.Position.X.Offset - 24, f.Position.Y.Scale, f.Position.Y.Offset)}):Play()
    end

    currentPage = page
  end

  function UI:addPage(name)
    assert(type(name) == "string" and #name > 0, "Page name required")
    local Page = {
      Name = name,
      Sections = {},
      addSection = nil,
      addResize = nil
    }

    -- Page button
    local btn = Instance.new("TextButton")
    btn.Name = "Page_" .. name
    btn.AutoButtonColor = false
    btn.Text = name
    btn.Font = theme.Font
    btn.TextSize = 16
    btn.TextColor3 = theme.Shadow
    btn.BackgroundColor3 = theme.PageIdle
    btn.Size = UDim2.new(0, math.clamp( math.floor(#name * 10) + 40, 96, 220), 1, 0)
    btn.Parent = pageBarPad
    corner(btn, 8)
    stroke(btn, theme.Outline, 1)
    bounceHover(btn, theme.PageIdle, theme.PageHover)

    pageButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
      selectPage(name)
    end)

    -- Page API
    function Page:addSection(secName)
      local section = {}
      section.__index = section

      local frame = Instance.new("Frame")
      frame.Name = "Section_" .. secName
      frame.BackgroundColor3 = theme.PanelBg
      frame.Size = UDim2.new(0, 350, 0, 150)
      frame.Parent = sectionPad
      corner(frame, 10)
      stroke(frame, theme.Outline, 1)
      frame.Visible = false

      local header = Instance.new("TextLabel")
      header.Name = "Header"
      header.BackgroundTransparency = 1
      header.Size = UDim2.new(1, -16, 0, 24)
      header.Position = UDim2.new(0, 8, 0, 6)
      header.Font = theme.Font
      header.Text = secName
      header.TextColor3 = theme.TextColor
      header.TextXAlignment = Enum.TextXAlignment.Left
      header.TextSize = 18
      header.Parent = frame

      local content = Instance.new("Frame")
      content.Name = "Content"
      content.BackgroundTransparency = 1
      content.Size = UDim2.new(1, -16, 1, -40)
      content.Position = UDim2.new(0, 8, 0, 32)
      content.Parent = frame

      local l = vlist(content, 6)

      local function mkRow(h)
        local r = Instance.new("Frame")
        r.Name = "Row"
        r.BackgroundColor3 = theme.ControlBg
        r.Size = UDim2.new(1, 0, 0, h or 32)
        r.Parent = content
        corner(r, 8)
        stroke(r, theme.Outline, 1)
        local pad = padding(r, 8)
        r.MouseEnter:Connect(function() tween(r, 0.1, {BackgroundColor3 = theme.ControlHover}):Play() end)
        r.MouseLeave:Connect(function() tween(r, 0.1, {BackgroundColor3 = theme.ControlBg}):Play() end)
        return r
      end

      -- Controls
      function section:addButton(name, callback)
        local row = mkRow(32)
        local btn = Instance.new("TextButton")
        btn.Name = "Button_" .. name
        btn.BackgroundTransparency = 1
        btn.Text = name
        btn.Font = theme.Font
        btn.TextSize = 16
        btn.TextColor3 = theme.TextColor
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Parent = row
        btn.AutoButtonColor = false
        btn.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end)
        return btn
      end

      function section:addToggle(name, default, callback)
        local row = mkRow(32)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = theme.Font
        lbl.TextSize = 16
        lbl.TextColor3 = theme.TextColor
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Parent = row

        local tbtn = Instance.new("TextButton")
        tbtn.Name = "Toggle"
        tbtn.AutoButtonColor = false
        tbtn.BackgroundColor3 = default and theme.ToggleOn or theme.ToggleOff
        tbtn.Text = default and "ON" or "OFF"
        tbtn.Font = theme.Font
        tbtn.TextSize = 14
        tbtn.TextColor3 = theme.Shadow
        tbtn.Size = UDim2.new(0, 54, 0, 24)
        tbtn.Position = UDim2.new(1, -62, 0.5, -12)
        tbtn.Parent = row
        corner(tbtn, 6)
        stroke(tbtn, theme.Outline, 1)

        local state = default and true or false
        tbtn.MouseButton1Click:Connect(function()
          state = not state
          tween(tbtn, 0.1, {
            BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff
          }):Play()
          tbtn.Text = state and "ON" or "OFF"
          if callback then task.spawn(callback, state) end
        end)

        return {
          Set = function(_, v)
            state = v and true or false
            tbtn.BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff
            tbtn.Text = state and "ON" or "OFF"
          end,
          Get = function() return state end
        }
      end

      function section:addTextbox(name, default, callback)
        local row = mkRow(32)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = theme.Font
        lbl.TextSize = 16
        lbl.TextColor3 = theme.TextColor
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(0.4, -8, 1, 0)
        lbl.Parent = row

        local box = Instance.new("TextBox")
        box.BackgroundColor3 = theme.WindowBg
        box.Text = default or ""
        box.Font = theme.Font
        box.TextSize = 16
        box.TextColor3 = theme.TextColor
        box.Size = UDim2.new(0.6, 0, 1, 0)
        box.Position = UDim2.new(0.4, 8, 0, 0)
        box.ClearTextOnFocus = false
        box.Parent = row
        corner(box, 6)
        stroke(box, theme.Outline, 1)
        box.FocusLost:Connect(function(enterPressed)
          if callback then task.spawn(callback, box.Text, enterPressed) end
        end)
        return box
      end

      function section:addKeybind(name, defaultKeyCode, callback)
        local row = mkRow(32)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = theme.Font
        lbl.TextSize = 16
        lbl.TextColor3 = theme.TextColor
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(0.6, -8, 1, 0)
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Text = (defaultKeyCode and defaultKeyCode.Name) or "None"
        btn.Font = theme.Font
        btn.TextSize = 16
        btn.TextColor3 = theme.Shadow
        btn.Size = UDim2.new(0.4, 0, 1, 0)
        btn.Position = UDim2.new(0.6, 8, 0, 0)
        btn.BackgroundColor3 = theme.Accent
        btn.AutoButtonColor = false
        btn.Parent = row
        corner(btn, 6)
        stroke(btn, theme.Outline, 1)

        local listening = false
        local bound = defaultKeyCode

        btn.MouseButton1Click:Connect(function()
          listening = true
          btn.Text = "Press key..."
        end)

        UserInputService.InputBegan:Connect(function(input, gp)
          if gp then return end
          if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            bound = input.KeyCode
            btn.Text = bound.Name
            listening = false
          end
          if bound and input.KeyCode == bound then
            if callback then task.spawn(callback, bound) end
          end
        end)

        return {
          Set = function(_, key) bound = key; btn.Text = key and key.Name or "None" end,
          Get = function() return bound end
        }
      end

      function section:addColorPicker(name, defaultColor3, callback)
        local row = mkRow(68)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = theme.Font
        lbl.TextSize = 16
        lbl.TextColor3 = theme.TextColor
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.Parent = row

        local preview = Instance.new("TextButton")
        preview.AutoButtonColor = false
        preview.Text = ""
        preview.Size = UDim2.new(0, 36, 0, 36)
        preview.Position = UDim2.new(0, 0, 0, 26)
        preview.BackgroundColor3 = defaultColor3 or Color3.fromRGB(255, 202, 40)
        preview.Parent = row
        corner(preview, 6)
        stroke(preview, theme.Outline, 1)

        local panel = Instance.new("Frame")
        panel.Visible = false
        panel.Size = UDim2.new(0, 220, 0, 80)
        panel.Position = UDim2.new(0, 44, 0, 22)
        panel.BackgroundColor3 = theme.DropdownBg
        panel.Parent = row
        corner(panel, 8)
        stroke(panel, theme.Outline, 1)

        local rv = Instance.new("TextBox")
        rv.Size = UDim2.new(0.3, -8, 0, 28)
        rv.Position = UDim2.new(0, 8, 0, 8)
        rv.Text = tostring(math.floor((preview.BackgroundColor3.R)*255))
        rv.Font = theme.Font
        rv.TextSize = 16
        rv.TextColor3 = theme.TextColor
        rv.BackgroundColor3 = theme.ControlBg
        rv.Parent = panel
        corner(rv, 6)
        stroke(rv, theme.Outline, 1)

        local gv = rv:Clone()
        gv.Position = UDim2.new(0.35, 0, 0, 8)
        gv.Text = tostring(math.floor((preview.BackgroundColor3.G)*255))
        gv.Parent = panel

        local bv = rv:Clone()
        bv.Position = UDim2.new(0.7, 0, 0, 8)
        bv.Text = tostring(math.floor((preview.BackgroundColor3.B)*255))
        bv.Parent = panel

        local apply = Instance.new("TextButton")
        apply.Text = "Apply"
        apply.Font = theme.Font
        apply.TextSize = 16
        apply.TextColor3 = theme.Shadow
        apply.BackgroundColor3 = theme.Accent
        apply.Size = UDim2.new(1, -16, 0, 28)
        apply.Position = UDim2.new(0, 8, 0, 44)
        apply.AutoButtonColor = false
        apply.Parent = panel
        corner(apply, 6)
        stroke(apply, theme.Outline, 1)

        local function clamp255(x)
          x = tonumber(x) or 0
          return math.clamp(math.floor(x + 0.5), 0, 255)
        end

        preview.MouseButton1Click:Connect(function()
          panel.Visible = not panel.Visible
          tween(panel, 0.12, {BackgroundTransparency = panel.Visible and 0 or 1}):Play()
        end)

        apply.MouseButton1Click:Connect(function()
          local r, g, b = clamp255(rv.Text), clamp255(gv.Text), clamp255(bv.Text)
          local c = Color3.fromRGB(r, g, b)
          preview.BackgroundColor3 = c
          if callback then task.spawn(callback, c) end
          panel.Visible = false
        end)

        return {
          Set = function(_, c)
            preview.BackgroundColor3 = c
            rv.Text = tostring(math.floor(c.R * 255))
            gv.Text = tostring(math.floor(c.G * 255))
            bv.Text = tostring(math.floor(c.B * 255))
          end,
          Get = function() return preview.BackgroundColor3 end
        }
      end

      function section:addSlider(name, min, max, default, callback)
        min, max = tonumber(min) or 0, tonumber(max) or 100
        local value = math.clamp(tonumber(default) or min, min, max)

        local row = mkRow(40)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = ("%s: %s"):format(name, value)
        lbl.Font = theme.Font
        lbl.TextSize = 16
        lbl.TextColor3 = theme.TextColor
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.Parent = row

        local bar = Instance.new("Frame")
        bar.BackgroundColor3 = theme.SliderBar
        bar.Size = UDim2.new(1, -16, 0, 8)
        bar.Position = UDim2.new(0, 8, 0, 24)
        bar.Parent = row
        corner(bar, 4)

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = theme.SliderFill
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.Parent = bar
        corner(fill, 4)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new(fill.Size.X.Scale, -6, 0.5, -6)
        knob.BackgroundColor3 = theme.Accent
        knob.Parent = bar
        corner(knob, 6)
        stroke(knob, theme.Outline, 1)

        local sliding = false

        local function setFromX(x)
          local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
          local newVal = math.floor(min + rel * (max - min) + 0.5)
          value = newVal
          lbl.Text = ("%s: %s"):format(name, value)
          fill.Size = UDim2.new(rel, 0, 1, 0)
          knob.Position = UDim2.new(rel, -6, 0.5, -6)
          if callback then task.spawn(callback, value) end
        end

        bar.InputBegan:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            setFromX(input.Position.X)
          end
        end)
        UserInputService.InputChanged:Connect(function(input)
          if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
          end
        end)
        UserInputService.InputEnded:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
          end
        end)

        return {
          Set = function(_, v) setFromX(bar.AbsolutePosition.X + ((math.clamp(v, min, max) - min)/(max-min)) * bar.AbsoluteSize.X) end,
          Get = function() return value end
        }
      end

      function section:addDropdown(name, options, default, callback)
        options = options or {}
        local current = default or options[1]

        local row = mkRow(68)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = theme.Font
        lbl.TextSize = 16
        lbl.TextColor3 = theme.TextColor
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.Parent = row

        local head = Instance.new("TextButton")
        head.AutoButtonColor = false
        head.Text = tostring(current or "Select")
        head.Font = theme.Font
        head.TextSize = 16
        head.TextColor3 = theme.Shadow
        head.BackgroundColor3 = theme.Accent
        head.Size = UDim2.new(1, 0, 0, 28)
        head.Position = UDim2.new(0, 0, 0, 26)
        head.Parent = row
        corner(head, 6)
        stroke(head, theme.Outline, 1)

        local listFrame = Instance.new("Frame")
        listFrame.Visible = false
        listFrame.BackgroundColor3 = theme.DropdownBg
        listFrame.Size = UDim2.new(1, 0, 0, math.min(150, (#options * 30) + 10))
        listFrame.Position = UDim2.new(0, 0, 0, 58)
        listFrame.Parent = row
        corner(listFrame, 8)
        stroke(listFrame, theme.Outline, 1)

        local listPad = Instance.new("Frame")
        listPad.BackgroundTransparency = 1
        listPad.Size = UDim2.new(1, -8, 1, -8)
        listPad.Position = UDim2.new(0, 4, 0, 4)
        listPad.Parent = listFrame
        local ll = vlist(listPad, 6)

        local function rebuild()
          listPad:ClearAllChildren()
          vlist(listPad, 6)
          for _, opt in ipairs(options) do
            local btn = Instance.new("TextButton")
            btn.AutoButtonColor = false
            btn.Text = tostring(opt)
            btn.Font = theme.Font
            btn.TextSize = 16
            btn.TextColor3 = theme.TextColor
            btn.BackgroundColor3 = theme.ControlBg
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.Parent = listPad
            corner(btn, 6)
            stroke(btn, theme.Outline, 1)
            btn.MouseEnter:Connect(function() tween(btn, 0.1, {BackgroundColor3 = theme.ControlHover}):Play() end)
            btn.MouseLeave:Connect(function() tween(btn, 0.1, {BackgroundColor3 = theme.ControlBg}):Play() end)
            btn.MouseButton1Click:Connect(function()
              current = opt
              head.Text = tostring(current)
              listFrame.Visible = false
              if callback then task.spawn(callback, current) end
            end)
          end
          listFrame.Size = UDim2.new(1, 0, 0, math.min(150, (#options * 30) + 10))
        end

        head.MouseButton1Click:Connect(function()
          listFrame.Visible = not listFrame.Visible
        end)

        rebuild()

        return {
          Set = function(_, v) current = v; head.Text = tostring(v) end,
          Get = function() return current end,
          SetOptions = function(_, newOpts) options = newOpts or {}; rebuild() end
        }
      end

      function section:Resize(sizeUDim2)
        frame.Size = sizeUDim2
      end

      section.Frame = frame
      table.insert(Page.Sections, section)
      return section
    end

    function Page:addResize(sizeUDim2)
      sectionArea.Size = sizeUDim2
    end

    pages[name] = Page
    return Page
  end

  function UI:addSelectPage(name)
    selectPage(name)
  end

  function UI:addNotify(message)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = theme.NotifyBg
    card.Size = UDim2.new(1, 0, 0, 40)
    card.Parent = notifyHolder
    corner(card, 8)
    stroke(card, theme.Outline, 1)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font = theme.Font
    lbl.Text = tostring(message)
    lbl.TextWrapped = true
    lbl.TextColor3 = theme.TextColor
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.Parent = card

    card.BackgroundTransparency = 1
    tween(card, 0.12, {BackgroundTransparency = 0}):Play()
    task.delay(2.0, function()
      tween(card, 0.12, {BackgroundTransparency = 1}):Play()
      task.delay(0.12, function() if card then card:Destroy() end end)
    end)
  end

  function UI:SetTheme(t)
    if type(t) == "string" then
      theme = Themes[t] or theme
    elseif type(t) == "table" then
      for k, v in pairs(t) do theme[k] = v end
    end
  end

  function UI:Toggle()
    showWindow(not window.Visible)
  end

  -- INITIAL OPEN
  showWindow(true)

  -- HOVER EFFECT for page bar already applied via bounceHover

  -- PUBLIC
  UI._screen = screen
  UI._window = window
  UI._toggleIcon = toggleIcon
  UI._theme = theme

  return setmetatable(UI, UI)
end

return XinexinHub
