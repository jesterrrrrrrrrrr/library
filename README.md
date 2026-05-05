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
	callback = function(choice <string>) -- 
		print(choice)
	end
})

--[[
:prompt() - Shows the dialog

]]

```

## Creating a Tab
```lua
local tab = window:CreateTab({
  name = "home",
  icon = nil,
})

--[[
name = <string> - The name of the tab
icon = <string> - The icon of the tab. (must be like "rbxassetid://*********")
]]
```

