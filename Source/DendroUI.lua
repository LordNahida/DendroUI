--[[
    DendroUI V 1.0
    Written By Fuanbi
--]]

--#region Setup
DendroUI = {
    Settings = {
        CreateCorners = true;
        CreateBorders = true;

        DisplayIntro = true;
        PrintWatermark = false;
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
    local ProxyDictionary = {};
    local MetaDictionary = {};
    function DendroUI.Functions.GetMeta(self)
        return MetaDictionary[self];
    end;

    function DendroUI.Functions.GetProxy(self)
        if (not self) then return self; end;
        return (ProxyDictionary[self] or self);
    end;

    local DendroMeta = {
        __index = function (self, Field)
            local Self = self;
            self, Field = DendroUI.Functions.ApplyRouting(self, Field);
            if (Self ~= self) then return self[Field]; end;
            local Meta = MetaDictionary[self];
            if (Meta.ClassData.Methods[Field]) then return Meta.ClassData.Methods; end;
            if (Meta.ClassData.Attributes[Field]) then return Meta.Attributes[Field]; end;
            local Child = Meta.Components.ChildContainer;
            if (not Child) then error("Unable to index " .. Field .. "."); end;
            Child = DendroUI.Functions.GetProxy(Child:FindFirstChild(Field));
            if (not Child) then error("Unable to index ".. Field .. "."); end;
            return Child;
        end;
        __newindex = function (self, Field, Value)
            local Self = self;
            self, Field = DendroUI.Functions.ApplyRouting(self, Field);
            if (Self ~= self) then self[Field] = Value; return; end;
            local Meta = MetaDictionary[self];
            local TypeString = Meta.ClassData.Attributes[Field];
            if (not TypeString) then error("Unable to find " .. Field .. "."); end;
            TypeString = TypeString.TypeString;
            if (not DendroUI.CheckType(Value, TypeString)) then error("Invalid type for " .. Field .. "."); end;
            Meta.ClassData.Attributes[Field].Redraw(self, Value);
        end;
        __tostring = function (self)
            local Meta = MetaDictionary[self];
            return (Meta.Attributes.Name or Meta.Attributes.ClassName or Meta.Pointer or "DendroUIElement");
        end;
    };

    local BaseClasses = {
        BaseInstance = {
            Methods = {
                AddChild = function (self, Child)
                    Child.Parent = MetaDictionary[self].ChildContainer;
                end;
                GetChildren = function (self)
                    local Meta = MetaDictionary[self];
                    local Children = Meta.Components.ChildContainer;
                    if (not Children) then error("This Element cannot contain children."); end;
                    Children = Children:GetChildren();
                    for _, Child in pairs(Children) do
                        Children[_] = DendroUI.Functions.GetProxy(Child);
                    end;
                end;
                GetDendroChildren = function (self)
                    local Meta = MetaDictionary[self];
                    local Children = Meta.Components.ChildContainer;
                    if (not Children) then error("This Element cannot contain children."); end;
                    Children = Children:GetChildren();
                    local DendroChildren = {};
                    for _, Child in pairs(Children) do
                        Child = ProxyDictionary[Child];
                        if (Child) then table.insert(DendroChildren, Child); end;
                    end;
                end;
            };
            Attributes = {
                Parent = {
                    TypeString = "\3Instance";
                    Redraw = function (self, Value)
                        local Meta = MetaDictionary[self];
                        Meta.Components.Main.Parent = Value;
                    end;
                };
                Name = {
                    TypeString = "\3string";
                    Redraw = function (self, Value)
                        local Meta = MetaDictionary[self];
                        Meta.Components.Main.Name = Value;
                    end;
                };
            };
        };
    }
end;
--#endregion
--#endregion

--#region DendroFunctions
DendroUI.Functions = {};
local function Init_RoutingSystem()
    function DendroUI.ApplyRouting(self, Field)
        local Meta = DendroUI.Functions.GetMeta(self);
        if (not Meta) then error("The first argument must be a DendroUI Element."); end;
        local RoutingString = Meta.ClassData.Routing[Field];
        if (not RoutingString) then return self, Field; end;
        if (RoutingString:find("\0")) then--IndirectRouting
            local Component = RoutingString:sub(1, RoutingString:find("\0") - 1);
            Field = RoutingString:sub(RoutingString:find("\0") + 1);
            return Meta.Components[Component], Field;
        else--DirectRouting
            return self, RoutingString;
        end;
    end;
end;

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
    --[[
        ClassType Guide:
        NULL: Attribute is Read-Only.
        0: Accepts all values, including nil.
        1: Accepts all values, except nil.
        2: Accepts Instance values of a certain type, can be nil.
        3: Accepts values of a certain type, can be nil.
        4: Accepts Instance values of a certain type, can't be nil.
        5: Accepts values of a certain type, can't be nil.
    --]]
    function DendroUI.Functions.CheckType(Value, TypeString)
        if (not TypeString or #TypeString == 0) then error("This Attribute is Read-Only."); end;
        local ClassType = TypeString:byte();
        TypeString = TypeString:sub(2);
        if (ClassType == 0) then return true; end;--Attribute accepts any value.
        if (ClassType == 1 and Value ~= nil) then return true; end;
        if ((ClassType == 2 or ClassType == 3) and Value == nil) then return true; end;--Attribute accepts nil values.
        if (ClassType == 2 or ClassType == 4) then--IsA Check
            if (typeof(Value) ~= "Instance") then return false; end;
            return Value:IsA(TypeString);
        end;
        if (Routes[TypeString]) then--typeof Check
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
    Init_RoutingSystem();
    Init_DendroEnums();
    Init_DendroUI();
    DendroUI._Settings = DendroUI.Settings;
    DendroUI.Settings = nil;
end;

return DendroUI;
--#endregion