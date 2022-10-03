--[[
    DendroUI V 1.0
    Written By Fuanbi
--]]

--#region Setup
DendroUI = {
    Settings = {
        CreateBorders = false;

        DisplayIntro = true;
        PrintCredits = false;
    };
};
--#region Services
local InputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local Players = game:GetService("Players");
local CoreGui = game:GetService("CoreGui");
local Debris = game:GetService("Debris");
--#endregion
local Player = Players.LocalPlayer;
local PlayerGui = Player.PlayerGui;
local Mouse = Player:GetMouse();

local TrueInstance = Instance;
local Sprout = Instance.new;
--#endregion

--#region Libraries
--#region DendroEnums
local function Init_DendroEnums()
    DendroUI.Enums = {

    };
    DendroUI.Presets = DendroUI.Enums;
end;
--#endregion

--#region DendroDefaults
local function Init_DendroDefaults()
    DendroUI.Defaults = {
        Background = {
            PrimaryColor = Color3.fromRGB();--Frames
            SecondaryColor = Color3.fromRGB();--Buttons & Controls
            DisabledColor = Color3.fromRGB();--Diabled Controls
            Transparency = 0;
        };
        Border = {
            Visible = false;
            Color = Color3.fromRGB();
            Transparency = 0;
            Thickness = 0;
        };
        Text = {
            Color = Color3.fromRGB();
            DisabledColor = Color3.fromRGB();
            StrokeColor = Color3.fromRGB();
            StrokeTransparency = 1;
        };
        General = {
            PrimaryColor = Color3.fromRGB();--Ex: Unchecked Checkboxes
            HighlightColor = Color3.fromRGB();--Ex: Checked Checkboxes
            DisabledColor = Color3.fromRGB();--Ex: Disabled Checkboxes
            DisabledHighlightColor = Color3.fromRGB();--Ex: Disabled Checked Checkboxes
        };
    };
end;
--#endregion

--#region DendroUI
local function Init_DendroUI()
    
end;
--#endregion
--#endregion

--#region DendroFunctions
DendroUI.Functions = {};
local function Init_TypeLockSystem()
    local Routes = {
        BaseColor = {
            Color3 = true;
            ColorSequence = true;
        };
        BaseNumber = {
            number = true;
            NumberRange = true;
            NumberSequence = true;
        };
    };

    function DendroUI.Functions.CheckType(Value, TypeString)
        local ClassType = TypeString:byte();
        TypeString = TypeString:sub(2);
        if (ClassType == 0) then
            if (typeof(Value) ~= "Instance") then return false; end;
            return Value:IsA(TypeString);
        end;
        if (Routes[TypeString]) then
            return (Routes[TypeString][typeof(Value)] ~= nil);
        end;
        return typeof(Value) == TypeString;
    end;
end;

function DendroUI:Mask(State)
    if (State or State == nil) then
        DendroUI.new = DendroUI.Create;
        Instance = DendroUI;
        return;
    end;
    Instance = TrueInstance;
end;

function DendroUI:Initiate()
    Init_TypeLockSystem();
    Init_DendroDefaults();
    Init_DendroEnums();
    Init_DendroUI();
end;
--#endregion