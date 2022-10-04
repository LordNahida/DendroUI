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
        };
        Stroke = {
            Visible = false;
            Style = Enum.LineJoinMode.Round;
            Thickness = 0;
            PrimaryColor = Color3.fromRGB();
            SecondaryColor = Color3.fromRGB();
            DisabledColor = Color3.fromRGB();
            PrimaryTransparency = 0;
            SecondaryTransparency = 0;
            DisabledTransparency = 0;
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

    function DendroUI.Functions.GetSproutMeta(self)
        return MetaDictionary[self];
    end;

    function DendroUI.Functions.GetProxy(self)
        if (not self) then return self; end;
        return (ProxyDictionary[self] or self);
    end;

    function DendroUI.Functions.GetRawInstance(self)
        return MetaDictionary[self].Components.Main;
    end;

    local DendroMeta = {
        __index = function (self, Field)
            local Self = self;
            self, Field = DendroUI.Functions.ApplyRouting(self, Field);
            if (Self ~= self) then return self[Field]; end;
            local Meta = MetaDictionary[self];
            if (Meta.ClassData.Methods[Field]) then return Meta.ClassData.Methods; end;
            if (Meta.ClassData.Attributes[Field]) then return Meta.Attributes[Field]; end;
            if (Meta.Events[Field]) then return Meta.Events[Field].Event; end;
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
        DendroSprout = {
            Methods = {
                Destroy = function (self)
                    local Meta = MetaDictionary[self];
                    ProxyDictionary[Meta.Components.Main] = nil;
                    for _, Component in pairs(Meta.Components) do
                        Component:Destroy();
                        Meta.Components[_] = nil;
                    end;
                    for _, Event in pairs(Meta.Events) do
                        Event:Destroy();
                    end;
                    for _, MetaField in pairs(Meta) do
                        Meta[MetaField] = nil;
                    end;
                    MetaDictionary[self] = nil;
                end;
                GetSproutMeta = DendroUI.Functions.GetSproutMeta;
                GetRawInstance = DendroUI.Functions.GetRawInstance;
            };
            Attributes = {
                ClassName = {};
            };
            Routing = {
                Name = "Main\0Name";
            };
            Events = {"Changed"};
        };
        DendroAncestry = {
            Attributes = {
                Parent = {
                    TypeString = "BaseInstance";
                    Redraw = function (self, Value)
                        Value = DendroUI.Functions.GetProxy(Value);
                        local Meta = MetaDictionary[self];
                        Meta.Main.Parent = DendroUI.Functions.GetRawInstance(Value);
                        Meta.Attributes.Parent = Value;
                    end;
                };
            };
            Methods = {
                GetChildren = function (self)
                    local Meta = MetaDictionary[self];
                    local Children = Meta.Components.ChildContainer:GetChildren();
                    for _, Child in pairs(Children) do if (ProxyDictionary[Child]) then Children[_] = ProxyDictionary[Child]; end; end;
                    return Children;
                end;
                GetSprouts = function (self)
                    local Meta = MetaDictionary[self];
                    local Children = {};
                    for _, Child in pairs(Meta.Components.ChildContainer:GetChildren()) do
                        if (ProxyDictionary[Child]) then
                            table.insert(Children, ProxyDictionary[Child]);
                        end;
                    end;
                    return Children;
                end;
                GetRawChildren = function (self)
                    return MetaDictionary[self].Components.ChildContainer:GetChildren();
                end;
                ClearAllChildren = function (self)
                    local Meta = MetaDictionary[self];
                    local Children = Meta.Components.ChildContainer:GetChildren();
                    for _, Child in pairs(Children) do DendroUI.Functions.GetProxy(Child):Destroy(); end;
                end;
                AddChild = function (self, Child)
                    local Meta = MetaDictionary[self];
                    Child.Parent = Meta.Components.ChildContainer;
                end;
            };
        };
        DendroRender = {
            Routing = {
                AbsoluteSize = "Main\0AbsoluteSize";
                AbsolutePosition = "Main\0AbsolutePosition";
                Visible = "Main\0Visible";
                ZIndex = "Main\0ZIndex";
            };
        };
        DendroBase2D = {
            Routing = {
                AutomaticSize = "Main\0AutomaticSize";
                LayoutOrder = "Main\0LayoutOrder";
                Position = "Main\0Position";
                Size = "Main\0Size";
                AnchorPoint = "Main\0AnchorPoint";
                Rotation = "Main\0Rotation";
                SizeConstraint = "Main\0SizeConstraint";
                TweenPosition = "Main\0TweenPosition";
                TweenSize = "Main\0TweenSize";
                TweenSizeAndPosition = "Main\0TweenSizeAndPosition";
            };
        };
        DendroInput = {
            Routing = {
                Active = "InputObject\0Active";
                InputBegan = "InputObject\0InputBegan";
                InputEnded = "InputObject\0InputEnded";
                MouseEnter = "InputObject\0MouseEnter";
                MouseLeave = "InputObject\0MouseLeave";
                MouseWheelForward = "InputObject\0MouseWheelForward";
                MouseWheelBackward = "InputObject\0MouseWheelBackward";
            };
        };
        DendroBackground = {
            Routing = {
                CornerRadius = "UICorner\0CornerRadius";
                Color = "Background\0BackgroundColor3";
                Transparency = "Background\0BackgroundTransparency";
                StrokeColor = "UIStroke\0Color";
                StrokeTransparency = "UIStroke\0Transparency";
                StrokeThickness = "UIStroke\0Thickness";
                StrokeMode = "UIStroke\0ApplyStokeMode";
                StrokeStyle = "UIStroke\0LineJoinMode";
                StrokeVisible = "UIStroke\0Enabled";
            };
        };
    };

    
end;
--#endregion
--#endregion

--#region DendroFunctions
DendroUI.Functions = {};
local function Init_RoutingSystem()
    function DendroUI.ApplyRouting(self, Field)
        local Meta = DendroUI.Functions.GetSproutMeta(self);
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
        if (TypeString == "BaseInstance") then return typeof(Value) == "Instance" or DendroUI.Functions.GetSproutMeta(Value) ~= nil; end;
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