local BASE_URL = "https://raw.githubusercontent.com/notthecloudy/Relief/main/"

local function HttpGet(path)
    local success, result = pcall(function()
        return game:HttpGet(BASE_URL .. path)
    end)
    if success and result then
        return result
    end
    warn("[Loader] Failed to fetch:", path)
    return nil
end

local function LoadModule(path)
    local source = HttpGet(path)
    if source then
        local fn, err = loadstring(source)
        if fn then
            local ok, result = pcall(fn)
            if ok then return result end
            warn("[Loader] Error executing " .. path .. ":", result)
        else
            warn("[Loader] Error compiling " .. path .. ":", err)
        end
    end
    return nil
end

-- ==========================================
-- STEP 1: Load Rayfield Library first
-- ==========================================
local function LoadRayfield()
    local success, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua")
    end)
    
    if not success or not result then
        warn("[Loader] HTTP Fetch failed:", result)
        return nil
    end
    
    if result:find("^%s*<") then
        warn("[Loader] Rayfield source returned HTML (404?)")
        return nil
    end
    
    local compiledFunc, compileError = loadstring(result)
    if not compiledFunc then
        warn("[Loader] Compilation failed:", compileError)
        return nil
    end

    local runSuccess, runResult = pcall(compiledFunc)
    if not runSuccess then
        warn("[Loader] Execution crashed:", runResult)
        return nil
    elseif type(runResult) ~= "table" then
        if _G.Rayfield then
            return _G.Rayfield
        elseif shared.Rayfield then
            return shared.Rayfield
        else
            warn("[Loader] Rayfield did not return a valid table! Got type:", type(runResult))
            return nil
        end
    else
        return runResult
    end
end

-- ==========================================
-- STEP 2: Create Relief UI Wrapper
-- ==========================================
local function CreateReliefUI(rayfield)
    if not rayfield then return nil end
    
    local Window = rayfield:CreateWindow({
        Name = "Relief Hub v2.0",
        LoadingTitle = "Relief Hub",
        LoadingSubtitle = "by Atlas",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "ReliefHub",
            FileName = "Config"
        },
        Discord = {
            Enabled = true,
            Invite = "msFnMfhuhV",
            RememberJoins = true
        },
        KeySystem = false
    })
    
    local ReliefWrapper = {}
    ReliefWrapper.Categories = {}
    ReliefWrapper.Modules = {}
    ReliefWrapper.Settings = {}
    ReliefWrapper.Envs = {}
    ReliefWrapper.Keybinds = {}
    ReliefWrapper.Commands = {}
    
    function ReliefWrapper.addCategory(name, icon)
        local tab = Window:CreateTab(name, icon)
        ReliefWrapper.Categories[name] = tab
        return tab
    end
    
    function ReliefWrapper.addModule(category, name, callback, settings, keybind, hidden)
        local cat = ReliefWrapper.Categories[category]
        if not cat then
            local icons = {
                Movement = 1114393432,
                Combat = 7485051715,
                Render = 13321848320,
                Player = 16149111731,
                World = 17640958405,
                Utility = 1538581893,
            }
            cat = Window:CreateTab(category, icons[category] or 1538581893)
            ReliefWrapper.Categories[category] = cat
        end
        
        local moduleId = category .. "." .. name
        local moduleData = {
            Name = name,
            Category = category,
            Toggled = false,
            Keybind = keybind,
            Callback = callback,
            Settings = settings or {},
            Hidden = hidden
        }
        
        -- Use tab:CreateToggle directly (Rayfield classic API)
        local toggle = cat:CreateToggle({
            Name = name,
            CurrentValue = false,
            Flag = moduleId .. "_Enabled",
            Callback = function(value)
                moduleData.Toggled = value
                if callback then
                    pcall(callback, value)
                end
            end
        })
        
        if settings then
            for _, setting in ipairs(settings) do
                if setting.Type == "Slider" then
                    cat:CreateSlider({
                        Name = setting.Title,
                        Range = {setting.Min or 0, setting.Max or 100},
                        Increment = setting.Increment or 1,
                        CurrentValue = setting.Default or setting.Min or 0,
                        Suffix = setting.Suffix or "",
                        Flag = moduleId .. "_" .. setting.Title,
                        Callback = setting.Callback or function() end
                    })
                elseif setting.Type == "Toggle" then
                    cat:CreateToggle({
                        Name = setting.Title,
                        CurrentValue = setting.Default or false,
                        Flag = moduleId .. "_" .. setting.Title,
                        Callback = setting.Callback or function() end
                    })
                elseif setting.Type == "Dropdown" then
                    cat:CreateDropdown({
                        Name = setting.Title,
                        Options = setting.Options or {},
                        CurrentOption = setting.Default and {setting.Default} or {},
                        MultiOptions = setting.Multiple or false,
                        Flag = moduleId .. "_" .. setting.Title,
                        Callback = setting.Callback or function() end
                    })
                elseif setting.Type == "TextBox" then
                    cat:CreateInput({
                        Name = setting.Title,
                        PlaceholderText = setting.Placeholder or "",
                        RemoveTextAfterFocusLost = false,
                        Flag = moduleId .. "_" .. setting.Title,
                        Callback = setting.Callback or function() end
                    })
                elseif setting.Type == "Button" then
                    cat:CreateButton({
                        Name = setting.Title,
                        Callback = setting.Callback or function() end
                    })
                end
            end
        end
        
        if keybind then
            cat:CreateKeybind({
                Name = name .. " Keybind",
                CurrentKeybind = keybind,
                HoldToInteract = false,
                Flag = moduleId .. "_Keybind",
                Callback = function()
                    moduleData.Toggled = not moduleData.Toggled
                    toggle:Set(moduleData.Toggled)
                end
            })
        end
        
        ReliefWrapper.Modules[moduleId] = moduleData
        return moduleData
    end
    
    function ReliefWrapper.getModule(name)
        return ReliefWrapper.Modules[name]
    end
    
    function ReliefWrapper.getSetting(moduleName, settingName)
        local module = ReliefWrapper.Modules[moduleName]
        if module and module.Settings then
            for _, s in ipairs(module.Settings) do
                if s.Title == settingName then
                    return s.CurrentValue or s.Default
                end
            end
        end
        return nil
    end
    
    function ReliefWrapper.isToggled(name)
        local module = ReliefWrapper.Modules[name]
        return module and module.Toggled
    end
    
    function ReliefWrapper.getEnv(name)
        ReliefWrapper.Envs[name] = ReliefWrapper.Envs[name] or {}
        return ReliefWrapper.Envs[name]
    end
    
    function ReliefWrapper.AddCommand(names, callback)
        local cmdNames = type(names) == "table" and names or {names}
        for _, name in ipairs(cmdNames) do
            ReliefWrapper.Commands[name:lower()] = callback
        end
    end
    
    function ReliefWrapper.GetCommand(name)
        return ReliefWrapper.Commands[name:lower()]
    end
    
    function ReliefWrapper.Notify(text, duration, color)
        rayfield:Notify({
            Title = "Relief Hub",
            Content = text,
            Duration = duration or 5,
            Image = color and "circle-alert" or "info"
        })
    end
    
    function ReliefWrapper.Recolor(color)
        Window.ModifyTheme({Default = color})
    end
    
    function ReliefWrapper.KillScript()
        for name, module in pairs(ReliefWrapper.Modules) do
            if module.Toggled and module.Callback then
                pcall(module.Callback, false)
            end
        end
        rayfield:Destroy()
    end
    
    function ReliefWrapper.AutoSaveName(name)
    end
    
    return ReliefWrapper
end

-- ==========================================
-- STEP 3: Anti-Detection (run before modules)
-- ==========================================

-- Compatibility layer for executor-specific globals
local getrawmetatable = getrawmetatable or nil
local setreadonly = setreadonly or nil
local hookmetamethod = hookmetamethod or nil
local newcclosure = newcclosure or function(f) return f end
local getnamecallmethod = getnamecallmethod or nil

local function AntiDetection()
    if not getrawmetatable or not setreadonly then
        warn("[AntiDetection] Required functions not available, skipping")
        return
    end
    
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    local oldNewindex = mt.__newindex
    
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "Kick" or method == "kick" then
            return warn("[AntiDetection] Blocked Kick attempt")
        end
        
        if method == "FireServer" or method == "InvokeServer" then
            local remote = self
            if remote.Name:lower():find("anticheat") or remote.Name:lower():find("ac") then
                return warn("[AntiDetection] Blocked suspicious remote:", remote.Name)
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    mt.__index = newcclosure(function(self, key)
        if key == "Kick" or key == "kick" then
            return function() warn("[AntiDetection] Blocked Kick property access") end
        end
        return oldIndex(self, key)
    end)
    
    setreadonly(mt, true)
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local oldKick = LocalPlayer.Kick
    LocalPlayer.Kick = function(self, ...)
        warn("[AntiDetection] Kick attempt blocked")
    end
    
    for _, v in pairs(getgc(true)) do
        if type(v) == "function" then
            local info = debug.getinfo(v)
            if info.name and info.name:lower():find("kick") then
                local old = v
                local new = function(...) warn("[AntiDetection] Blocked kick function") end
                pcall(function() hookfunction(old, new) end)
            end
        end
    end
end

-- ==========================================
-- STEP 4: Main Initialization
-- ==========================================
local Relief = nil
local Loaded = false

-- 1. Load Rayfield
local rayfield = LoadRayfield()
if not rayfield then
    error("[Loader] Critical failure: Rayfield UI Library could not be loaded!")
end

-- 2. Create Relief UI and expose globally
Relief = CreateReliefUI(rayfield)
_G.Relief = Relief
shared.Relief = Relief

-- 3. Define categories BEFORE loading modules
Relief.addCategory("Movement", 1114393432)
Relief.addCategory("Combat", 7485051715)
Relief.addCategory("Render", 13321848320)
Relief.addCategory("Player", 16149111731)
Relief.addCategory("World", 17640958405)
Relief.addCategory("Utility", 1538581893)

-- 4. Anti-detection
AntiDetection()

-- 5. NOW safe to load modules (they can use Relief.addModule)
local Init = LoadModule("Core/Init.lua")
local Services = LoadModule("Core/Services.lua")
local Thread = LoadModule("Core/Thread.lua")
local Utilities = LoadModule("Core/Utilities.lua")
local Character = LoadModule("Core/Character.lua")
local Whitelist = LoadModule("Core/Whitelist.lua")

local Movement = LoadModule("Modules/Universal/Movement.lua")
local Combat = LoadModule("Modules/Universal/Combat.lua")
local Render = LoadModule("Modules/Universal/Render.lua")
local Player = LoadModule("Modules/Universal/Player.lua")
local World = LoadModule("Modules/Universal/World.lua")
local Utility = LoadModule("Modules/Universal/Utility.lua")
local Commands = LoadModule("Modules/Universal/Commands.lua")

local GameRegistry = LoadModule("Games/GameRegistry.lua")

-- 6. Initialize modules
if Movement then Movement.Init(Relief) end
if Combat then Combat.Init(Relief) end
if Render then Render.Init(Relief) end
if Player then Player.Init(Relief) end
if World then World.Init(Relief) end
if Utility then Utility.Init(Relief) end
if Commands then Commands.Init(Relief) end

-- 6. Game registry
if GameRegistry then GameRegistry.AutoLoad() end

-- 7. Final setup
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if setclipboard then
    setclipboard("discord.gg/msFnMfhuhV")
end

local req = syn and syn.request or request or http_request or fluxus and fluxus.request or httprequest
if req then
    task.spawn(function()
        req({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com",
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = {code = "msFnMfhuhV"},
                nonce = HttpService:GenerateGUID(false)
            })
        })
    end)
end

local function HookChat()
    TextChatService.OnIncomingMessage = function(message)
        local source = message.TextSource
        if source then
            local sender = Players:GetPlayerByUserId(source.UserId)
            if sender and sender ~= LocalPlayer then
                local text = message.Text
                if text:sub(1, 1) == ";" then
                    message.Text = '<u><font color="#FFFF00">' .. text .. '</font></u>'
                end
            end
        end
    end
end
HookChat()

local function ProcessCommands(text)
    if text:sub(1, 1) == ";" then
        local args = text:sub(2):split(" ")
        local cmdName = args[1]:lower()
        table.remove(args, 1)
        
        local cmd = Commands and Commands.Get(cmdName)
        if cmd then
            task.spawn(function()
                pcall(cmd, args)
            end)
            return true
        end
    end
    return false
end

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Semicolon then
    end
end)

if GameRegistry then GameRegistry.AutoLoad() end

Relief.Notify("Relief Hub v2.0 Loaded | discord.gg/msFnMfhuhV", 5, Color3.new(0, 1, 0))

Loaded = true
print("[Relief] Script completely initialized!")

return Relief