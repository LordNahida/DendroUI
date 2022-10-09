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
            CornerRadius = UDim.new(0, 8);
        };
        Stroke = {
            Visible = false;
            Style = Enum.LineJoinMode.Round;
            Thickness = 1;
            PrimaryColor = Color3.fromRGB(165, 199, 58);
            SecondaryColor = Color3.fromRGB(165, 199, 58);
            DisabledColor = Color3.fromRGB(175, 199, 58);
            PrimaryTransparency = 0;
            SecondaryTransparency = 0;
            DisabledTransparency = 0.5;
        };
        Text = {
            Color = Color3.fromRGB(255, 255, 255);
            DisabledColor = Color3.fromRGB(198, 198, 198);
            StrokeColor = Color3.fromRGB(0, 0, 0);
            StrokeTransparency = 1;
        };
        General = {
            PrimaryColor = Color3.fromRGB(255, 255, 255);--Ex: Unchecked Checkboxes
            HighlightColor = Color3.fromRGB(165, 199, 58);--Ex: Checked Checkboxes
            DisabledColor = Color3.fromRGB(198, 198, 198);--Ex: Disabled Checkboxes
            DisabledHighlightColor = Color3.fromRGB(165, 199, 58);--Ex: Disabled Checked Checkboxes
            DisabledTransparency = 0.5;
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
        return (MetaDictionary[self] and MetaDictionary[self].Components.Main) or self;
    end;


    local DendroMeta = {
        __index = function (self, Field)
            local Self = self;
            self, Field = DendroUI.Functions.ApplyRouting(self, Field);
            if (Self ~= self) then return self[Field]; end;
            local Meta = MetaDictionary[self];
            if (Meta.ClassData.Methods[Field]) then return Meta.ClassData.Methods[Field]; end;
            if (Meta.ClassData.Attributes[Field]) then return Meta.Attributes[Field]; end;
            if (Meta.Events[Field]) then return Meta.Events[Field].Event; end;
            local Child = Meta.Components.ChildContainer;
            if (not Child) then error("Unable to index " .. Field .. "."); end;
            Child = DendroUI.Functions.GetProxy(Child:FindFirstChild(Field));
            if (not Child) then error("Unable to index ".. Field .. "."); end;
            return Child;
        end;
        __newindex = function (self, Field, Value)
            local Self, _Field = self, Field;
            local Meta = MetaDictionary[self];
            self, Field = DendroUI.Functions.ApplyRouting(self, Field);
            if (Self ~= self) then self[Field] = Value; return Meta.Events.Changed:Fire(_Field, Value); end;
            local TypeString = Meta.ClassData.Attributes[Field];
            if (not TypeString) then error("Unable to find " .. Field .. "."); end;
            TypeString = TypeString.TypeString;
            if (not DendroUI.Functions.CheckType(Value, TypeString)) then error("Invalid type for " .. Field .. "."); end;
            Meta.ClassData.Attributes[Field].Redraw(Self, Value, Field);
            Meta.Events.Changed:Fire(_Field, Value);
        end;
        __tostring = function (self)
            local Meta = MetaDictionary[self];
            return (Meta.Attributes.Name or Meta.Attributes.ClassName or Meta.Pointer or "DendroUIElement");
        end;
        __metatable = "This metatable is protected. Please use Dendro:GetMeta instead, and make sure to read the Advanced Documentation before interfering with core functions.";
    };

    local _ = function (self, Value, Field)
        local Meta = MetaDictionary[self];
        Meta.Attributes[Field] = Value;
        self:RenderGlow();
    end;
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
                    if (Meta.Destruct) then Meta.Destruct(); end;
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
            Events = {Changed = true};
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
            Attributes = {
                GlowVisible = {
                    TypeString = "\5boolean";
                    DefaultValue = false;
                    Redraw = _;
                };
                GlowTransparency = {
                    TypeString = "\5number";
                    DefaultValue = 0;
                    Redraw = _;
                };
                GlowRadius = {
                    TypeString = "\5UDim";
                    DefaultValue = UDim.new(0, 8);
                    Redraw = _;
                };
                GlowColor = {
                    TypeString = "\5Color3";
                    DefaultDictionary = DendroUI.Defaults.General;
                    DefaultValue = "HighlightColor";
                    Redraw = _;
                };
                GlowIntensity = {
                    TypeString = "\5number";
                    DefaultValue = 0;
                    Redraw = _;
                }
            };
            Methods = {
                ContainsGlow = function (self)
                    return MetaDictionary[self].Components.UIGlow ~= nil;
                end;
                CreateGlow = function (self)
                    local Meta = MetaDictionary[self];
                    local UIGlow = Sprout("ImageLabel", Meta.Components.Main);
                    UIGlow.BackgroundTransparency = 1;
                    UIGlow.BorderSizePixel = 0;
                    UIGlow.Image = "rbxassetid://11189076544";
                    UIGlow.ScaleType = Enum.ScaleType.Slice;
                    UIGlow.SliceCenter = Rect.new(250, 250, 251, 251);
                    UIGlow.ZIndex = Meta.Components.Background.ZIndex - 1;
                    UIGlow.Name = "UIGlow";
                    UIGlow.ImageTransparency = -1;
                    Meta.Components.UIGlow = UIGlow;
                end;
                DestroyGlow = function (self)
                    MetaDictionary[self].Components.UIGlow:Destroy();
                    MetaDictionary[self].Components.UIGlow = nil;
                end;
                RenderGlow = function (self)
                    local Background = MetaDictionary[self];
                    local UIGlow, Attributes = Background.Components.UIGlow, Background.Attributes;
                    local GlowTransparency, GlowVisible, GlowRadius = Attributes.GlowTransparency, Attributes.GlowVisible, Attributes.GlowRadius;
                    if (GlowTransparency >= 1 or not GlowVisible) then return; end;
                    if (not UIGlow) then self:CreateGlow(); UIGlow = Background.Components.UIGlow; end;
                    Background = Background.Components.Background;
                    UIGlow.ImageTransparency = GlowTransparency;
                    UIGlow.ImageColor3 = Attributes.GlowColor;
                    UIGlow.Visible = GlowVisible;
                    UIGlow.Size = UDim2.new(1 + GlowRadius.Scale, GlowRadius.Offset * 2, 1 + GlowRadius.Scale, GlowRadius.Offset * 2);
                    UIGlow.AnchorPoint = Vector2.new(0.5, 0.5);
                    UIGlow.Position = UDim2.new(0.5, 0, 0.5, 0);
                    local CornerRadius = MetaDictionary[self].Components.UICorner.CornerRadius;
                    local PixelCornerRadius = (math.min(Background.AbsoluteSize.X, Background.AbsoluteSize.Y) * CornerRadius.Scale / 2 + CornerRadius.Offset) * 2 ^ 0.5;
                    local MaxEmptySize = Background.AbsoluteSize - Vector2.new(PixelCornerRadius, PixelCornerRadius);
                    local MinScale = (math.min(UIGlow.AbsoluteSize.X - MaxEmptySize.X, UIGlow.AbsoluteSize.Y - MaxEmptySize.Y) + 10) / 500 / 2 ^ 0.5;
                    local MaxScale = math.min(UIGlow.AbsoluteSize.X, UIGlow.AbsoluteSize.Y) / 500;
                    local ScaleDelta = MaxScale - MinScale;
                    local GlowIntensity = 1 - math.max(0, math.min(1, Attributes.GlowIntensity));
                    UIGlow.SliceScale = MinScale + (ScaleDelta * GlowIntensity);
                end;
            };
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
        DendroText = {

        };
        DendroImage = {

        };
    };

    local function MakeDendroBackground(Background, IsPrimary, Components)
        local Corner = Sprout("UICorner", Background);
        local Stroke = Sprout("UIStroke", Background);
        Components.Background = Background;
        Components.UICorner = Corner;
        Components.UIStroke = Stroke;

        Background.BorderSizePixel = 0;

        local BGDefaults = DendroUI.Defaults.Background;
        local StrokeDefaults = DendroUI.Defaults.Stroke;
        Background.BackgroundColor3 = (IsPrimary and BGDefaults.PrimaryColor) or BGDefaults.SecondaryColor;
        Corner.CornerRadius = BGDefaults.CornerRadius;
        Stroke.Enabled = StrokeDefaults.Visible;
        Stroke.LineJoinMode = StrokeDefaults.Style;
        Stroke.Thickness = StrokeDefaults.Thickness;
        Stroke.Color = (IsPrimary and StrokeDefaults.PrimaryColor) or StrokeDefaults.SecondaryColor;
        Stroke.Transparency = (IsPrimary and StrokeDefaults.PrimaryTransparency) or StrokeDefaults.SecondaryTransparency;
    end;

    local DendroSprout, DendroAncestry, DendroRender, DendroBase2D, DendroInput, DendroBackground, DendroText, DendroImage;
    DendroSprout = BaseClasses.DendroSprout;
    DendroAncestry = BaseClasses.DendroAncestry;
    DendroRender = BaseClasses.DendroRender;
    DendroBase2D = BaseClasses.DendroBase2D;
    DendroInput = BaseClasses.DendroInput;
    DendroBackground = BaseClasses.DendroBackground;
    DendroText = BaseClasses.DendroText;
    DendroImage = BaseClasses.DendroImage;

    local CreatableClasses = {};
    DendroUI.Classes = {
        BaseClasses = BaseClasses;
        CreatableClasses = CreatableClasses;
    };
    local function InheritTable(Main, Inhertied)
        if (not Inhertied) then return; end;
        for Idx, Value in pairs(Inhertied) do
            Main[Idx] = Value;
        end;
        
        return Main;
    end;
    local function MassInherit(Main, InheritedField, Classes)
        for _, Class in pairs(Classes) do
            InheritTable(Main, Class[InheritedField]);
        end;

        return Main;
    end;
    local function CreateClass(Methods, Attributes, Events, Routing, Construct, Destruct, ClassName, ...)
        local Inheritance = {...};
        local Class = {
            Methods = MassInherit(Methods, "Methods", Inheritance);
            Attributes = MassInherit(Attributes, "Attributes", Inheritance);
            Events = MassInherit(Events, "Events", Inheritance);
            Routing = MassInherit(Routing, "Routing", Inheritance);
            Construct = Construct;
            Destruct = Destruct;
            ClassName = ClassName;
        };

        CreatableClasses[ClassName] = Class;
        return Class;
    end;

    local function CreateProxy(ClassData, Main)
        local Proxy, Meta = newproxy(true), nil;
        Meta = getmetatable(Proxy);

        Meta.__index = DendroMeta.__index;
        Meta.__newindex = DendroMeta.__newindex;
        Meta.__tostring = DendroMeta.__tostring;
        Meta.__metatable = DendroMeta.__metatable;

        MetaDictionary[Proxy] = Meta;
        ProxyDictionary[Proxy] = Main;
        ProxyDictionary[Main] = Proxy;

        local Attributes, Events = {}, {};
        for _, Attribute in pairs(ClassData.Attributes) do
            Attributes[_] = Attribute.DefaultValue;
            if (Attribute.DefaultDictionary) then
                Attributes[_] = Attribute.DefaultDictionary[Attribute.DefaultValue];
            end;
        end;

        for Event, _ in pairs(ClassData.Events) do
            Events[Event] = Sprout("BindableEvent", Main);
            Events[Event].Name = Event;
        end;

        Meta.ClassName = ClassData.ClassName;
        Meta.ClassData = ClassData;
        Meta.Components = {Main = Main};
        Meta.Attributes = Attributes;
        Meta.Events = Events;

        return Main, Proxy, Meta, Attributes, Events;
    end;

    local DendroLabel;
    DendroLabel = CreateClass({}, {}, {}, {}, function (Parent)
        local Main, Proxy, Meta = CreateProxy(DendroLabel, Sprout("Frame", DendroUI.Functions.GetRawInstance(Parent)));
        local Image = Sprout("ImageLabel", Main);
        local Text = Sprout("TextLabel", Main);
        
        Main.Name = "DendroLabel";
        Image.Name = "ImageRender";
        Text.Name = "TextRender";
        Text.Text = "DendroLabel";

        Main.Size = UDim2.new(0, 100, 0, 25);
        Image.Size = UDim2.new(1, 0, 1, 0);
        Image.AnchorPoint = Vector2.new(0.5, 0.5);
        Image.Position = UDim2.new(0.5, 0, 0.5, 0);
        Text.Size = UDim2.new(1, 0, 1, 0);
        Text.AnchorPoint = Vector2.new(0.5, 0.5);
        Text.Position = UDim2.new(0.5, 0, 0.5, 0);

        MakeDendroBackground(Image, false, Meta.Components);
        Main.BackgroundTransparency = 1;
        Main.BorderSizePixel = 0;
        Text.BackgroundTransparency = 1;
        Text.BorderSizePixel = 0;

        Meta.Components.InputObject = Image;

        return Proxy;
    end, nil, "Label", DendroSprout, DendroAncestry, DendroRender, DendroBase2D, DendroInput, DendroBackground, DendroText, DendroImage);
    CreatableClasses.DendroLabel = DendroLabel;
    CreatableClasses.TextLabel = DendroLabel;
    CreatableClasses.ImageLabel = DendroLabel;
end;
--#endregion
--#endregion

--#region DendroFunctions
DendroUI.Functions = {};
local function Init_RoutingSystem()
    function DendroUI.Functions.ApplyRouting(self, Field)
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

DendroUI:Initiate();
local Proxy = DendroUI.Classes.CreatableClasses.Label.Construct(script.Parent);

Proxy.Changed:Connect(print);
Proxy.Name = "Test";
Proxy.Color = Color3.new(1, 1, 1);
Proxy.AnchorPoint = Vector2.new(0.5, 0.5);
Proxy.Position = UDim2.new(0.5, 0, 0.5, 0);
Proxy.GlowVisible = true;
Proxy.GlowRadius = UDim.new(0, 8);
Proxy.GlowIntensity = 1;
Proxy.Size = UDim2.new(0, 500, 0, 500);

return DendroUI;
--#endregion