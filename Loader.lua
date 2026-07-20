local BASE_URL = "https://raw.githubusercontent.com/notthecloudy/Relief/main/"

local function HttpGet(path)
    local success, result = pcall(function()
        local cacheBuster = "?t=" .. os.time()
        return game:HttpGet(BASE_URL .. path .. cacheBuster)
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
            -- DIAGNOSTIC PRINT: Tells you exactly which file is starting execution
            print("[Diagnostic] Attempting to execute file:", path)
            
            local ok, result = pcall(fn)
            if ok then 
                -- DIAGNOSTIC PRINT: Confirms this file didn't crash
                print("[Diagnostic] Successfully executed:", path)
                return result 
            end
            warn("[Loader] Error executing " .. path .. ":", result)
        else
            warn("[Loader] Error compiling " .. path .. ":", err)
        end
    end
    return nil
end

-- ==========================================
-- STEP 1: Load Rayfield Library first
local function LoadRayfield()
    local urls = {
        "https://sirius.menu/gen2",
        "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
    }
    
    for _, url in ipairs(urls) do
        local success, result = pcall(function()
            -- Safe URL formatting check
            local connector = url:find("%?") and "&" or "?"
            local cleanURL = url .. connector .. "t=" .. os.time()
            return game:HttpGet(cleanURL)
        end)
        
        if success and result and not result:find("^%s*<") and #result > 0 then
            local compiledFunc, compileError = loadstring(result)
            if compiledFunc then
                local runSuccess, runResult = pcall(compiledFunc)
                
                local targetLib = (type(runResult) == "table" and runResult) 
                    or _G.Rayfield 
                    or shared.Rayfield 
                    or (getgenv and getgenv().Rayfield)
                
                if targetLib and type(targetLib) == "table" then
                    print("[Loader] Successfully loaded Rayfield framework library via source link:", url)
                    return targetLib
                end
            end
        end
        warn("[Loader] Source failed or returned invalid data structure block:", url)
    end
    
    warn("[Loader] Critical Failure: All configured Rayfield source repository URLs failed!")
    return nil
end

-- ==========================================
-- STEP 2: Create Relief UI Wrapper (Rayfield Gen2 API)
-- ==========================================
local function CreateReliefUI(rayfield)
    if not rayfield then return nil end
    
    local Window = rayfield:CreateWindow({
        name = "Relief Hub v2.0",
        loadingTitle = "Relief Hub",
        loadingSubtitle = "by Atlas",
        configurationSaving = {
            Enabled = true,
            FolderName = "ReliefHub",
            FileName = "Config"
        },
        discord = {
            Enabled = true,
            Invite = "msFnMfhuhV",
            RememberJoins = true
        },
        keySystem = false
    })
    
    local ReliefWrapper = {}
    ReliefWrapper.Categories = {}
    ReliefWrapper.Modules = {}
    ReliefWrapper.Settings = {}
    ReliefWrapper.Envs = {}
    ReliefWrapper.Keybinds = {}
    ReliefWrapper.Commands = {}
    
    function ReliefWrapper.addCategory(name, icon)
        local tab = Window:CreateTab({ name = name, icon = icon })
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
            cat = Window:CreateTab({ name = category, icon = icons[category] or 1538581893 })
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
        
        local toggle = cat:CreateToggle({
            name = name,
            flag = moduleId .. "_Enabled",
            value = false,
            callback = function(value)
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
                        name = setting.Title,
                        flag = moduleId .. "_" .. setting.Title,
                        range = { setting.Min or 0, setting.Max or 100 },
                        increment = setting.Increment or 1,
                        value = setting.Default or setting.Min or 0,
                        suffix = setting.Suffix or "",
                        callback = setting.Callback or function() end
                    })
                elseif setting.Type == "Toggle" then
                    cat:CreateToggle({
                        name = setting.Title,
                        flag = moduleId .. "_" .. setting.Title,
                        value = setting.Default or false,
                        callback = setting.Callback or function() end
                    })
                elseif setting.Type == "Dropdown" then
                    cat:CreateDropdown({
                        name = setting.Title,
                        flag = moduleId .. "_" .. setting.Title,
                        options = setting.Options or {},
                        currentOption = setting.Default and { setting.Default } or {},
                        multiSelect = setting.Multiple or false,
                        callback = setting.Callback or function() end
                    })
                elseif setting.Type == "TextBox" then
                    cat:CreateInput({
                        name = setting.Title,
                        flag = moduleId .. "_" .. setting.Title,
                        placeholder = setting.Placeholder or "",
                        value = setting.Default or "",
                        numeric = setting.Numeric or false,
                        callback = setting.Callback or function() end
                    })
                elseif setting.Type == "Button" then
                    cat:CreateButton({
                        name = setting.Title,
                        callback = setting.Callback or function() end
                    })
                end
            end
        end
        
        if keybind then
            cat:CreateKeybind({
                name = name .. " Keybind",
                flag = moduleId .. "_Keybind",
                key = keybind,
                hold = false,
                callback = function()
                    moduleData.Toggled = not moduleData.Toggled
                    toggle:Set(moduleData.Toggled)
                end
            end)
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
        local cmdNames = type(names) == "table" and names or { names }
        for _, name in ipairs(cmdNames) do
            ReliefWrapper.Commands[name:lower()] = callback
        end
    end
    
    function ReliefWrapper.GetCommand(name)
        return ReliefWrapper.Commands[name:lower()]
    end
    
    function ReliefWrapper.Notify(text, duration, color)
        Window:Notify({
            title = "Relief Hub",
            content = text,
            duration = duration or 5,
            image = color and "circle-alert" or "info"
        })
    end
    
    function ReliefWrapper.Recolor(color)
        Window:ModifyTheme({ Default = color })
    end
    
    function ReliefWrapper.KillScript()
        for name, module in pairs(ReliefWrapper.Modules) do
            if module.Toggled and module.Callback then
                pcall(module.Callback, false)
            end
        end
        Window:Destroy()
    end
    
    function ReliefWrapper.AutoSaveName(name)
    end
    
    return ReliefWrapper
end

-- ==========================================
-- STEP 3: Main Initialization
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
                args = { code = "msFnMfhuhV" },
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
        -- semicolon key pressed
    end
end)

if GameRegistry then GameRegistry.AutoLoad() end

Relief.Notify("Relief Hub v2.0 Loaded | discord.gg/msFnMfhuhV", 5, Color3.new(0, 1, 0))

Loaded = true

return Relief