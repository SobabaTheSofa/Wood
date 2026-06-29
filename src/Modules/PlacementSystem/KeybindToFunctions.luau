local Handler = {}
local Base

local KeyInputs = require(script.parent.parent.ModuleDictionaries.KeyInputs)

local Keybinds = {}
local InpBegan

local function KeybindListener(Input, InputType)
	local ValidInputName = Keybinds[(InputType.Name == "Keyboard" and InputType.Name) or "Mouse"]
	local Type = (InputType.Name == "Keyboard" and Input.KeyCode.Name) or Input.UserInputType.Name

	if not ValidInputName then
		return
	end

	local FunctionName = ValidInputName[Type]

	if FunctionName then
		Base[FunctionName](Base, Input)
	end
end

local function SetupKeybinds()
	Keybinds["Mouse"] = {}
	Keybinds["Keyboard"] = {}

	Keybinds.Keyboard = (KeyInputs.Keyboard ~= nil and KeyInputs.Keyboard)
	Keybinds.Mouse = (KeyInputs.Mouse ~= nil and KeyInputs.Mouse)

	InpBegan = game:GetService("UserInputService").InputBegan:Connect(function(Input, GP)
		if Input.UserInputType and not GP then
			KeybindListener(Input, Input.UserInputType)
		end
	end)
end

function Handler:Cleanup()
	Keybinds = nil
	Keybinds = {}

	if InpBegan then
		InpBegan:Disconnect()
	end
end

function Handler:Init(BaseEnv)
	Base = BaseEnv

	SetupKeybinds()
end

return Handler
