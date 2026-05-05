# Library
This documentation is for the use of my library.

## Booting the Library
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/jesterrrrrrrrrrr/library/refs/heads/main/src.lua"))()
```



## Creating a Window
```lua
local window = library.new({
	title = "library",
	subtitle = "this is a subtitle",
	size = UDim2.new(0, 700, 0, 400),
})

--[[
title = <string> - The title  of the interface.
subtitle = <string> - The subtitle of the interface.
size = <UDim2> - The size of the interface.

:toggle(state <boolean>) - Toggles the window's visibility.
:setToggleKey(bind <Enum.KeyCode>) - Sets the window's toggle keybind
]]
```


## Creating a Dialog
```lua
local dialog = window:dialog({
	title = "Confirm",
	body = "Are you sure?",
	buttons = {"no", "yes"},
	callback = function(choice) 
		print(choice)
	end
})

--[[
title = <string> - The title of the dialog.
body = <string> - The body text of the dialog.
buttons = <table> - The buttons of the dialog. 
callback = <function> - The function fired after choosing a button.
choice = <string> - The string returned of the button in the callback.

:prompt() - Shows the dialog.

]]
```

## Creating a Tab
```lua
local tab = window:createTab({
  name = "home",
  icon = nil,
})

--[[
name = <string> - The name of the tab
icon = <string> - The icon of the tab. (must be like "rbxassetid://*********")
]]
```


## Creating a Button
```lua
local button = tab:createButton({
  title = "button",
  description = "description",
  callback = function()
     print("clicked")
  end
})


--[[
title = <string> - The title of the button.
description = <string> - The description of the button.
callback = <function> - The function fired after pressing.
]]
```

## Creating a Toggle
```lua
local button = tab:createToggle({
  title = "toggle",
  default = false,
  description = "description",
  callback = function(state)
     print("toggled to:", state)
  end
})


--[[
title = <string> - The title of the toggle.
description = <string> - The description of the toggle.
callback = <function> - The function fired after pressing.
state = <boolean> - The value returned of the toggle.

:set(state)

]]
