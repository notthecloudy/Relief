local RayfieldWrapper = {}

local Rayfield = nil
local Window = nil
local Tabs = {}
local Modules = {}
local SettingsCache = {}
local ConfigFolder = "ReliefHub"
local ConfigFile = "Settings"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

function RayfieldWrapper.Load()
    if Rayfield then return RayfieldWrapper end

    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
    end)

    if not success then
        warn("[RayfieldWrapper] Failed to load Rayfield:", result)
        return RayfieldWrapper.CreateFallback()
    end

    Rayfield = result

    Window = Rayfield:CreateWindow({
        Name = "Relief Hub v2",
        LoadingTitle = "Relief Hub",
        LoadingSubtitle = "by Atlas",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = ConfigFolder,
            FileName = ConfigFile
        },
        Discord = {
            Enabled = true,
            Invite = "aZfFCkqYyA",
            RememberJoins = true
        },
        KeySystem = false
    })

    RayfieldWrapper.CreateDefaultTabs()
    RayfieldWrapper.HookGlobalAPI()

    return RayfieldWrapper
end

function RayfieldWrapper.CreateDefaultTabs()
    local categories = {
        {name = "Movement", icon = 1114393432},
        {name = "Combat", icon = 7485051715},
        {name = "Render", icon = 13321848320},
        {name = "Player", icon = 16149111731},
        {name = "World", icon = 17640958405},
        {name = "Utility", icon = 1538581893},
        {name = "Settings", icon = 6031075938}
    }

    for _, cat in ipairs(categories) do
        Tabs[cat.name] = Window:CreateTab(cat.name, cat.icon)
    end

    Tabs.Settings:CreateSection("Configuration")
    Tabs.Settings:CreateButton({
        Name = "Save Config",
        Callback = function()
            RayfieldWrapper.SaveConfig()
            Rayfield:Notify({Title = "Config", Content = "Configuration saved", Duration = 3})
        end
    })
    Tabs.Settings:CreateButton({
        Name = "Load Config",
        Callback = function()
            RayfieldWrapper.LoadConfig()
            Rayfield:Notify({Title = "Config", Content = "Configuration loaded", Duration = 3})
        end
    })
    Tabs.Settings:CreateButton({
        Name = "Unload Script",
        Callback = function()
            RayfieldWrapper.Unload()
        end
    })
end

function RayfieldWrapper.CreateFallback()
    warn("[RayfieldWrapper] Using fallback UI")
    local fallback = {}
    fallback.Tabs = {}
    fallback.Modules = {}

    function fallback.CreateTab(name)
        fallback.Tabs[name] = {
            CreateToggle = function() end,
            CreateSlider = function() end,
            CreateDropdown = function() end,
            CreateButton = function() end,
            CreateLabel = function() end,
            CreateInput = function() end,
            CreateKeybind = function() end,
            CreateSection = function() end
        }
        return fallback.Tabs[name]
    end

    return fallback
end

function RayfieldWrapper.GetTab(category)
    return Tabs[category] or Tabs.Utility
end

function RayfieldWrapper.AddModule(category, name, callback, settings, keybind, isRender)
    local tab = RayfieldWrapper.GetTab(category)
    if not tab then return end

    local moduleId = category .. "." .. name
    local env = {}

    local elements = {}

    if settings then
        for _, setting in ipairs(settings) do
            local stype = setting.Type
            if stype == "Toggle" then
                elements[setting.Title] = tab:CreateToggle({
                    Name = setting.Title,
                    CurrentValue = setting.Default or false,
                    Flag = moduleId .. "_" .. setting.Title,
                    Callback = function(value)
                        if setting.Callback then setting.Callback(value) end
                    end
                })
            elseif stype == "Slider" then
                elements[setting.Title] = tab:CreateSlider({
                    Name = setting.Title,
                    Range = {setting.Min or 0, setting.Max or 100},
                    Increment = setting.Increment or 1,
                    Suffix = setting.Suffix or "",
                    CurrentValue = setting.Default or setting.Min or 0,
                    Flag = moduleId .. "_" .. setting.Title,
                    Callback = function(value)
                        if setting.Callback then setting.Callback(value) end
                    end
                })
            elseif stype == "Dropdown" then
                elements[setting.Title] = tab:CreateDropdown({
                    Name = setting.Title,
                    Options = setting.Options or {},
                    CurrentOption = setting.Default and {setting.Default} or {},
                    MultipleOptions = setting.Multiple or false,
                    Flag = moduleId .. "_" .. setting.Title,
                    Callback = function(selected)
                        if setting.Callback then setting.Callback(selected[1]) end
                    end
                })
            elseif stype == "TextBox" then
                elements[setting.Title] = tab:CreateInput({
                    Name = setting.Title,
                    PlaceholderText = setting.Placeholder or "",
                    RemoveTextAfterFocusLost = false,
                    Callback = function(text)
                        if setting.Callback then setting.Callback(text) end
                    end
                })
            elseif stype == "Keybind" then
                elements[setting.Title] = tab:CreateKeybind({
                    Name = setting.Title,
                    CurrentKeybind = setting.Default or "None",
                    HoldToInteract = setting.Hold or false,
                    Flag = moduleId .. "_" .. setting.Title,
                    Callback = function(key)
                        if setting.Callback then setting.Callback(key) end
                    end
                })
            elseif stype == "Button" then
                tab:CreateButton({
                    Name = setting.Title,
                    Callback = setting.Callback or function() end
                })
            end
        end
    end

    Modules[moduleId] = {
        Name = name,
        Category = category,
        Callback = callback,
        Elements = elements,
        Env = env,
        Toggled = false,
        Keybind = keybind
    }

    local toggle = tab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Flag = moduleId .. "_Enabled",
        Callback = function(state)
            Modules[moduleId].Toggled = state
            pcall(callback, state)
        end
    })

    Modules[moduleId].ToggleElement = toggle

    if keybind then
        local kb = tab:CreateKeybind({
            Name = name .. " Keybind",
            CurrentKeybind = keybind,
            HoldToInteract = false,
            Flag = moduleId .. "_Keybind",
            Callback = function()
                local mod = Modules[moduleId]
                mod.Toggled = not mod.Toggled
                toggle:Set(mod.Toggled)
                pcall(mod.Callback, mod.Toggled)
            end
        })
        Modules[moduleId].KeybindElement = kb
    end

    return Modules[moduleId]
end

function RayfieldWrapper.GetModule(category, name)
    return Modules[category .. "." .. name]
end

function RayfieldWrapper.IsToggled(category, name)
    local mod = RayfieldWrapper.GetModule(category, name)
    return mod and mod.Toggled or false
end

function RayfieldWrapper.GetSetting(category, name, setting)
    local mod = RayfieldWrapper.GetModule(category, name)
    if mod and mod.Elements[setting] then
        return mod.Elements[setting].CurrentValue
    end
    return nil
end

function RayfieldWrapper.GetEnv(category, name)
    local mod = RayfieldWrapper.GetModule(category, name)
    return mod and mod.Env or {}
end

function RayfieldWrapper.Notify(text, duration, color)
    if Rayfield then
        Rayfield:Notify({
            Title = "Relief Hub",
            Content = text,
            Duration = duration or 5,
            Image = color and 4483345998 or nil
        })
    end
end

function RayfieldWrapper.AddCommand(aliases, callback)
    if not getgenv().Commands then getgenv().Commands = {} end
    if not getgenv().AddCommand then
        getgenv().AddCommand = function(names, cb)
            for _, n in ipairs(names) do
                getgenv().Commands[n:lower()] = cb
            end
        end
    end
    getgenv().AddCommand(aliases, callback)
end

function RayfieldWrapper.GetCommand(name)
    return getgenv().Commands and getgenv().Commands[name:lower()]
end

function RayfieldWrapper.KillScript()
    for _, mod in pairs(Modules) do
        if mod.Toggled then
            pcall(mod.Callback, false)
        end
    end
    if Window then Window:Destroy() end
    getgenv().Relief = nil
end

function RayfieldWrapper.Recolor(color)
    if Rayfield and Window then
        pcall(function()
            Window:ModifyTheme({
                TextColor = color,
                ElementBackground = color:Lerp(Color3.new(0.1, 0.1, 0.1), 0.7),
                ElementStroke = color:Lerp(Color3.new(0.3, 0.3, 0.3), 0.5)
            })
        end)
    end
end

function RayfieldWrapper.AutoSaveName(name)
    SettingsCache.AutoSaveName = name
end

function RayfieldWrapper.ModuleListVisible(visible)
    if Window then Window:Toggle(visible) end
end

function RayfieldWrapper.MobileButtonVisible(visible)
end

function RayfieldWrapper.HookGlobalAPI()
    getgenv().Relief = {
        addModule = function(cat, name, cb, settings, keybind, isRender)
            return RayfieldWrapper.AddModule(cat, name, cb, settings, keybind, isRender)
        end,
        addCategory = function(name, icon)
            if not Tabs[name] then
                Tabs[name] = Window:CreateTab(name, icon)
            end
        end,
        getModule = function(name)
            for _, mod in pairs(Modules) do
                if mod.Name == name then return mod end
            end
            return nil
        end,
        isToggled = function(name)
            for _, mod in pairs(Modules) do
                if mod.Name == name then return mod.Toggled end
            end
            return false
        end,
        getSetting = function(moduleName, settingName)
            for _, mod in pairs(Modules) do
                if mod.Name == moduleName and mod.Elements[settingName] then
                    return mod.Elements[settingName].CurrentValue
                end
            end
            return nil
        end,
        getEnv = function(moduleName)
            for _, mod in pairs(Modules) do
                if mod.Name == moduleName then return mod.Env end
            end
            return {}
        end,
        Notify = RayfieldWrapper.Notify,
        AddCommand = RayfieldWrapper.AddCommand,
        GetCommand = RayfieldWrapper.GetCommand,
        KillScript = RayfieldWrapper.KillScript,
        Recolor = RayfieldWrapper.Recolor,
        AutoSaveName = RayfieldWrapper.AutoSaveName,
        ModuleList = { Visible = true },
        MobileButton = { Visible = true },
        Arrow = { Visible = true }
    }
end

function RayfieldWrapper.SaveConfig()
    if Rayfield then
        pcall(function() Rayfield:SaveConfig() end)
    end
end

function RayfieldWrapper.LoadConfig()
    if Rayfield then
        pcall(function() Rayfield:LoadConfig() end)
    end
end

function RayfieldWrapper.Unload()
    RayfieldWrapper.KillScript()
    Rayfield = nil
    Window = nil
    Tabs = {}
    Modules = {}
end

return RayfieldWrapper