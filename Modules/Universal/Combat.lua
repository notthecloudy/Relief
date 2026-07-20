local Combat = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

Combat.Modules = {}

function Combat.Init(Relief)
    Combat.Relief = Relief
    Combat.Thread = getgenv().Thread
    Combat.Character = getgenv().Character
    Combat.CreateModules()
end

local function getRoot()
    return Combat.Character.GetRootPart()
end

local function getHumanoid()
    return Combat.Character.GetHumanoid()
end

local function getCharacter()
    return Combat.Character.GetCharacter()
end