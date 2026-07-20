local Player = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

Player.Modules = {}

function Player.Init(Relief)
    Player.Relief = Relief
    Player.Thread = getgenv().Thread
    Player.Character = getgenv().Character
    Player.CreateModules()
end

local function getRoot()
    return Player.Character.GetRootPart()
end

local function getHumanoid()
    return Player.Character.GetHumanoid()
end

local function getCharacter()
    return Player.Character.GetCharacter()
end