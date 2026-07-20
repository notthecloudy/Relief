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

local RayfieldWrapper = LoadModule("UI/RayfieldWrapper.lua")

local Relief = nil
local Loaded = false

local function LoadRayfield()
    local success, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua")
    end)
    
    if success and result then
        local rayfield = loadstring(result)()
        return rayfield
    end
    
    warn("[Loader] Failed to load Rayfield, using fallback UI")
    return nil
end

local function CreateReliefUI(rayfield)
    if rayfield then
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
                warn("[Relief] Category not found:", category)
                return
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
            
            local section = cat:CreateSection(name)
            local toggle = section:CreateToggle({
                Name = name,
                CurrentValue = false,
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
                        section:CreateSlider({
                            Name = setting.Title,
                            Range = {setting.Min or 0, setting.Max or 100},
                            Increment = setting.Increment or 1,
                            CurrentValue = setting.Default or setting.Min or 0,
                            Callback = setting.Callback or function() end
                        })
                    elseif setting.Type == "Toggle" then
                        section:CreateToggle({
                            Name = setting.Title,
                            CurrentValue = setting.Default or false,
                            Callback = setting.Callback or function() end
                        })
                    elseif setting.Type == "Dropdown" then
                        section:CreateDropdown({
                            Name = setting.Title,
                            Options = setting.Options or {},
                            CurrentOption = setting.Default and {setting.Default} or {},
                            Callback = setting.Callback or function() end
                        })
                    elseif setting.Type == "TextBox" then
                        section:CreateInput({
                            Name = setting.Title,
                            PlaceholderText = setting.Placeholder or "",
                            CurrentValue = setting.Default or "",
                            Callback = setting.Callback or function() end
                        })
                    elseif setting.Type == "Button" then
                        section:CreateButton({
                            Name = setting.Title,
                            Callback = setting.Callback or function() end
                        })
                    end
                end
            end
            
            if keybind then
                section:CreateKeybind({
                    Name = name .. " Keybind",
                    CurrentKeybind = keybind,
                    Callback = function()
                        moduleData.Toggled = not moduleData.Toggled
                        toggle:Set(moduleData.Toggled)
                    end
                })
            end
            
            ReliefWrapper.Modules[name] = moduleData
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
    else
        local FallbackUI = {}
        FallbackUI.Categories = {}
        FallbackUI.Modules = {}
        FallbackUI.Settings = {}
        FallbackUI.Envs = {}
        FallbackUI.Commands = {}
        
        function FallbackUI.addCategory(name, icon)
            FallbackUI.Categories[name] = {Name = name, Modules = {}}
            return FallbackUI.Categories[name]
        end
        
        function FallbackUI.addModule(category, name, callback, settings, keybind, hidden)
            local cat = FallbackUI.Categories[category]
            if not cat then return end
            
            local moduleData = {
                Name = name,
                Category = category,
                Toggled = false,
                Keybind = keybind,
                Callback = callback,
                Settings = settings or {},
                Hidden = hidden
            }
            
            cat.Modules[name] = moduleData
            FallbackUI.Modules[name] = moduleData
            return moduleData
        end
        
        function FallbackUI.getModule(name)
            return FallbackUI.Modules[name]
        end
        
        function FallbackUI.getSetting(moduleName, settingName)
            local module = FallbackUI.Modules[moduleName]
            if module and module.Settings then
                for _, s in ipairs(module.Settings) do
                    if s.Title == settingName then
                        return s.Default
                    end
                end
            end
            return nil
        end
        
        function FallbackUI.isToggled(name)
            local module = FallbackUI.Modules[name]
            return module and module.Toggled
        end
        
        function FallbackUI.getEnv(name)
            FallbackUI.Envs[name] = FallbackUI.Envs[name] or {}
            return FallbackUI.Envs[name]
        end
        
        function FallbackUI.AddCommand(names, callback)
            local cmdNames = type(names) == "table" and names or {names}
            for _, name in ipairs(cmdNames) do
                FallbackUI.Commands[name:lower()] = callback
            end
        end
        
        function FallbackUI.GetCommand(name)
            return FallbackUI.Commands[name:lower()]
        end
        
        function FallbackUI.Notify(text, duration, color)
            print("[Relief] " .. text)
        end
        
        function FallbackUI.Recolor(color)
        end
        
        function FallbackUI.KillScript()
            for name, module in pairs(FallbackUI.Modules) do
                if module.Toggled and module.Callback then
                    pcall(module.Callback, false)
                end
            end
        end
        
        function FallbackUI.AutoSaveName(name)
        end
        
        return FallbackUI
    end
end

local function AntiDetection()
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
                if hookfunction then
                    pcall(function() hookfunction(old, new) end)
                end
            end
        end
    end
end

local function Initialize()
    if Loaded then return end
    
    AntiDetection()
    
    local rayfield = LoadRayfield()
    Relief = CreateReliefUI(rayfield)
    getgenv().Relief = Relief
    
    if Movement then Movement.Init(Relief) end
    if Combat then Combat.Init(Relief) end
    if Render then Render.Init(Relief) end
    if Player then Player.Init(Relief) end
    if World then World.Init(Relief) end
    if Utility then Utility.Init(Relief) end
    if Commands then Commands.Init(Relief) end
    
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
end

Initialize()

return Relief