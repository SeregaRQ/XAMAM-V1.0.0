-- Main.lua
-- XAMAM core script (legal Roblox Studio plugin / module entry)
-- Licensed under Unlicense (see LICENSE)

-- This file is intended as the main entry for the XAMAM project.
-- It provides a Studio plugin UI when run inside Roblox Studio (as a PluginScript),
-- and exports a safe utility API when required as a ModuleScript in-game.

local XAMAM = {}
XAMAM.Version = "1.0.0"

-- Internal utilities
local function isStudio()
    -- In Roblox environment, 'plugin' is only available inside Studio plugins.
    local ok, plugin = pcall(function() return plugin end)
    if ok and typeof(plugin) == "Instance" then
        return true
    end
    -- Another check: game:GetService should exist in Roblox Lua environment,
    -- but when running outside Studio (e.g., tests) we may not have that API.
    return false
end

-- Safe logger
function XAMAM.log(message)
    if type(message) ~= "string" then
        message = tostring(message)
    end
    if isStudio() then
        print("[XAMAM] " .. message)
    else
        -- When used outside Studio, also print to stdout if available
        print("[XAMAM] " .. message)
    end
end

-- Simple configuration store (in-memory). For Studio plugin you can extend
-- this to persist settings using Plugin:GetSetting / SetSetting.
XAMAM.config = {
    lastModuleName = "XAMAM_CustomModule",
}

-- Module helper: create a ModuleScript in ServerScriptService (Studio only)
function XAMAM.saveModuleToService(moduleName, source)
    if not isStudio() then
        XAMAM.log("saveModuleToService is only available in Studio environment")
        return nil, "not_in_studio"
    end

    local ServerScriptService = game:GetService("ServerScriptService")
    local module = Instance.new("ModuleScript")
    module.Name = moduleName or XAMAM.config.lastModuleName or "XAMAM_Module"
    module.Source = source or "-- XAMAM module"
    module.Parent = ServerScriptService
    XAMAM.log("Saved module: " .. module.Name .. " to " .. ServerScriptService.Name)
    XAMAM.config.lastModuleName = module.Name
    return module
end

-- Basic Studio UI: dockable widget with textbox and save button.
local function createStudioWidget()
    -- guard: only run in plugin
    if not isStudio() then return end

    -- 'plugin' is a global provided by Studio when running a plugin script
    local toolbar = plugin:CreateToolbar("XAMAM")
    local button = toolbar:CreateButton("OpenXAMAM", "Open XAMAM panel", "")

    local DockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Float,
        false,
        true,
        420,
        320,
        300,
        180
    )

    local widget = plugin:CreateDockWidgetPluginGui("XAMAM_Widget", DockWidgetPluginGuiInfo)
    widget.Title = "XAMAM"

    -- Build UI (simple, with basic layout)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = widget

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0.75, -20)
    textBox.Position = UDim2.new(0, 10, 0, 10)
    textBox.MultiLine = true
    textBox.TextWrapped = true
    textBox.ClearTextOnFocus = false
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 14
    textBox.PlaceholderText = "-- Введите Lua-код для сохранения как ModuleScript"
    textBox.Parent = frame

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 140, 0, 32)
    saveBtn.Position = UDim2.new(0, 10, 0.78, -10)
    saveBtn.Text = "Save as Module"
    saveBtn.Font = Enum.Font.SourceSansBold
    saveBtn.TextSize = 14
    saveBtn.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -160, 0, 32)
    status.Position = UDim2.new(0, 160, 0.78, -10)
    status.Text = ""
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.SourceSans
    status.TextSize = 14
    status.Parent = frame

    local function saveAction()
        local code = textBox.Text
        if code == nil or code == "" then
            status.Text = "Нет кода для сохранения."
            return
        end
        local ok, result = pcall(function()
            return XAMAM.saveModuleToService(XAMAM.config.lastModuleName, code)
        end)
        if ok and result then
            status.Text = "Saved: " .. tostring(result.Name)
        else
            status.Text = "Error saving module"
            XAMAM.log("Error saving module: " .. tostring(result))
        end
    end

    saveBtn.MouseButton1Click:Connect(saveAction)

    button.Click:Connect(function()
        widget.Enabled = not widget.Enabled
    end)

    XAMAM.log("Studio widget created")
end

-- Initialization
function XAMAM.init()
    XAMAM.log("Initializing XAMAM v" .. XAMAM.Version)
    if isStudio() then
        -- create UI for Studio plugin usage
        createStudioWidget()
    else
        XAMAM.log("Running outside Studio — only module API is available")
    end
end

-- If the script is executed (not just required), auto-init in Studio
pcall(function()
    if isStudio() then
        XAMAM.init()
    end
end)

return XAMAM
