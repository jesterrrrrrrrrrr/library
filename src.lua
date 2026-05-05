local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local collectionService = game:GetService("CollectionService")

local replicatedStorage = game:GetService("ReplicatedStorage")
local replicatedFirst = game:GetService("ReplicatedFirst")

local debris = game:GetService("Debris")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildWhichIsA("Humanoid")
local rootPart = humanoid.RootPart

local mouse = player:GetMouse()

local library = {
	version = "1.0.0",
	connections = {
	},
	toggleKey = Enum.KeyCode.RightShift,
	visible = true,
	theme = {
		accent = Color3.fromRGB(255, 195, 9)
	},

}
library.isDialogOpen = false



--------------------------------------
-- utility ---------------------------
--------------------------------------
local utility = {}

function utility.create(class, props, children)
	local obj = Instance.new(class)

	local success, rt = pcall(function()
		return obj.RichText
	end)
	if success and rt ~= nil then
		obj.RichText = true
	end

	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	if props and props.Parent then
		obj.Parent = props.Parent
	end

	if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
		obj.BorderSizePixel = 0
	end

	return obj
end

function utility.callback(callback, context, ...)
	if type(callback) ~= "function" then
		return true
	end

	local success, result = pcall(callback, ...)

	if not success then
		warn(("callback error in '%s': %s"):format(context or "unknown", tostring(result)))
	end

	return success, result
end

function utility.tween(obj, duration, goal, style, direction)
	local tweenInfo = TweenInfo.new(
		duration,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)

	local tween = tweenService:Create(obj, tweenInfo, goal)
	tween:Play()

	return tween
end

function utility.roundUp(n, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(n * mult + 0.5) / mult
end


utility.active = nil
function utility.setupDrag(frame, handle, registry)
	if registry then
		table.insert(registry, library.connections)
	end
	
	handle = handle or frame

	local dragging = false
	local dragStart
	local startPos
	local targetPos = frame.Position
	local connections = {}

	local function getViewport()
		local cam = workspace.CurrentCamera
		return cam and cam.ViewportSize or Vector2.new(1920, 1080)
	end

	local function clampPosition(pos, scale)
		local screen = getViewport()
		local size = frame.AbsoluteSize
		local anchor = frame.AnchorPoint

		local absX = pos.X + scale.X * screen.X
		local absY = pos.Y + scale.Y * screen.Y

		local minX = size.X * anchor.X
		local minY = size.Y * anchor.Y
		local maxX = screen.X - size.X * (1 - anchor.X)
		local maxY = screen.Y - size.Y * (1 - anchor.Y)

		absX = math.clamp(absX, minX, maxX)
		absY = math.clamp(absY, minY, maxY)

		return absX - scale.X * screen.X, absY - scale.Y * screen.Y
	end

	local function updateTarget(input)
		if not dragging or utility.active ~= frame then
			return
		end

		local delta = input.Position - dragStart
		local newX = startPos.X.Offset + delta.X
		local newY = startPos.Y.Offset + delta.Y

		newX, newY = clampPosition(Vector2.new(newX, newY), Vector2.new(startPos.X.Scale, startPos.Y.Scale))

		targetPos = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
	end

	connections[#connections + 1] = handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		if utility.active and utility.active ~= frame then
			return
		end

		dragging = true
		utility.active = frame
		dragStart = input.Position
		startPos = frame.Position
		targetPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if utility.active == frame then
					utility.active = nil
				end
			end
		end)
	end)

	connections[#connections + 1] = userInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateTarget(input)
		end
	end)

	connections[#connections + 1] = userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false

			if utility.active == frame then
				utility.active = nil
			end
		end
	end)

	connections[#connections + 1] = runService.RenderStepped:Connect(function()
		frame.Position = frame.Position:Lerp(targetPos, 0.25)
	end)

	return connections
end

--------------------------------------
-- builder ---------------------------
--------------------------------------

local builder = {}
function builder.canvas(screen, size)
	local canvas: Frame = utility.create("Frame", {
		Name = "canvas",
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		Size = size,
		Position = UDim2.fromOffset(600, 300),
		AnchorPoint = Vector2.new(0.5,0.5),
		ClipsDescendants = true,
		Parent = screen,
		ZIndex = 1,
	}, {
		utility.create("UICorner", {
			Name = "UICorner",
			CornerRadius = UDim.new(0, 12)
		})
	})

	return canvas :: Frame
end

function builder.topbar(canvas, title, subtitle)
	local topbar = utility.create("Frame", {
		Name = "topbar",
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		Size = UDim2.new(1,0,0,48),
		Parent = canvas,
		ZIndex = 15
	}, {
		utility.create("UICorner", {
			CornerRadius = UDim.new(0, 12)
		}),
		utility.create("UIPadding", {
			PaddingLeft = UDim.new(0, 15),
			PaddingRight = UDim.new(0, 3),
		}),
	})

	utility.create("Frame", {
		Name = "block",
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		Size = UDim2.new(2,0,0.177,1),
		Position = UDim2.new(-0.5, 0, 0.8, 0),
		Parent = topbar,
		ZIndex = 15,
		Visible = false
	})

	utility.create("Frame", {
		Name = "divider",
		BackgroundColor3 = Color3.fromRGB(25,25,25),
		Size = UDim2.new(2,0,0,1),
		Position = UDim2.new(1.5,0,1,0),
		Parent = topbar,
		ZIndex = 15,
		AnchorPoint = Vector2.new(1,1)
	})


	--------------------------------------

	local title = utility.create("TextLabel", {
		Name = "title",
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255,255,255),
		Text = title,
		ZIndex = 15,
		Size = UDim2.new(0,164,0,12),
		Position = UDim2.new(0,0,0,10),
		FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Parent = topbar,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local subtitle = utility.create("TextLabel", {
		Name = "subtitle",
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(139,139,139),
		Text = subtitle,
		ZIndex = 15,
		Size = UDim2.new(0,169,0,11),
		Position = UDim2.new(0,0,0,23),
		FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Parent = topbar,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})



	--------------------------------------

	local nav = utility.create("Frame", {
		Name = "nav",
		BackgroundTransparency = 1,
		Size = UDim2.new(0,-58,0,46),
		ZIndex = 15,
		Position = UDim2.new(0.995,0,0,0),
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		Parent = topbar,
	})

	local close = utility.create("TextLabel", {
		Name = "close",
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		Size = UDim2.new(0,33,0,33),
		Position = UDim2.new(1,0,0.5,0),
		TextTransparency = 1,
		Parent = nav,
		AnchorPoint = Vector2.new(1,0.5),
	}, {
		utility.create("UICorner", {
			CornerRadius = UDim.new(0,6),
		}),

		utility.create("ImageLabel", {
			Name = "icon",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(.5, .5),
			AnchorPoint = Vector2.new(.5, .5),
			Size = UDim2.fromOffset(15,15),
			ZIndex = 15,
			Image = "rbxassetid://10747384394",
			ImageColor3 = Color3.fromRGB(100,100,100),
			ScaleType = Enum.ScaleType.Fit,

		})
	})

	close.MouseEnter:Connect(function()
		local icon = close:FindFirstChild("icon")
		if icon then
			utility.tween(icon, .5, {
				ImageColor3 = Color3.fromRGB(255,255,255)
			})
		end
	end)

	close.MouseLeave:Connect(function()
		local icon = close:FindFirstChild("icon")
		if icon then
			utility.tween(icon, .5, {
				ImageColor3 = Color3.fromRGB(100,100,100)
			})
		end
	end)


	local hide = utility.create("TextButton", {
		Name = "hide",
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		Size = UDim2.new(0,33,0,33),
		Position = UDim2.new(.4,0,0.5,0),
		AutoButtonColor = false,
		TextTransparency = 1,
		Parent = nav,
		Visible = true,
		AnchorPoint = Vector2.new(1,0.5),
	}, {
		utility.create("UICorner", {
			CornerRadius = UDim.new(0,6),
		}),

		utility.create("ImageLabel", {
			Name = "icon",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(.5, .5),
			AnchorPoint = Vector2.new(.5, .5),
			Size = UDim2.fromOffset(15,15),
			ZIndex = 15,
			Image = "rbxassetid://10734896206",
			ImageColor3 = Color3.fromRGB(100,100,100),
			ScaleType = Enum.ScaleType.Fit,

		})
	})
	
	hide.MouseEnter:Connect(function()
		local icon = hide:FindFirstChild("icon")
		if icon then
			utility.tween(icon, .5, {
				ImageColor3 = Color3.fromRGB(255,255,255)
			})
		end
	end)

	hide.MouseLeave:Connect(function()
		local icon = hide:FindFirstChild("icon")
		if icon then
			utility.tween(icon, .5, {
				ImageColor3 = Color3.fromRGB(100,100,100)
			})
		end
	end)

	return {
		frame = topbar,
		title = title,
		subtitle = subtitle,
		topbar = topbar,
		nav = {
			close = close,
			hide = hide,
		}
	}
end

function builder.sidebar(canvas)
	local sidebar = utility.create("Frame", {
		Name = "sidebar",
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 157, 1, 0),
		AnchorPoint = Vector2.new(0, 0),
		Visible = true,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.None,
		ClipsDescendants = false,
		Parent = canvas,
	}, {
		utility.create("UICorner", {
			CornerRadius = UDim.new(0, 12),
		})
	})

	utility.create("Frame", {
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 0,
		Name = "divider",
		Position = UDim2.new(1, 0, 0, 45),
		Visible = true,
		ZIndex = 5,
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(0, 1, 1, 0),
		Parent = sidebar,
	})


	local list = utility.create("ScrollingFrame", {
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 15,
		Name = "list",
		Position = UDim2.new(0, 0, 0, 55),
		Visible = true,
		ZIndex = 5,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 1, -80),
		Parent = sidebar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
	}, {
		utility.create("UIListLayout", {
			Name = "UIListLayout",
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		utility.create("UIPadding", {
			Name = "UIPadding",
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6)

		})
	})

	return {
		frame = sidebar,
		list = list
	}
end

function builder.dialog(content)

	local dialogFrame = utility.create("CanvasGroup", {
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 0.05,
		Name = "dialog",
		Position = UDim2.new(0, 0, 0, 15),
		Visible = true,
		ZIndex = 999,
		GroupTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
		Size = UDim2.new(1, 0, 1, 0),
		Parent = content,
		BorderSizePixel = 0,
	}, {
		utility.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0,
			Name = "frame",
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Visible = true,
			ZIndex = 1,
			BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			Size = UDim2.new(0, 300, 0, 200),
		}, {
			utility.create("UICorner", {
				Name = "UICorner",
				CornerRadius = UDim.new(0, 8),
			}),
			utility.create("UIStroke", {
				Name = "UIStroke",
				Color = Color3.fromRGB(25, 25, 25),
				ZIndex = 1,
			}),
			utility.create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Name = "buttons",
				Position = UDim2.new(0.5, 0, 0, 160),
				Visible = true,
				ZIndex = 1,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(1, -10, 0, 35),
			}, {
				utility.create("UIListLayout", {
					Name = "UIListLayout",
					Padding = UDim.new(0, 10),
					HorizontalFlex = "Fill",
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					FillDirection = Enum.FillDirection.Horizontal,
				}),
				utility.create("Frame", {
					AnchorPoint = Vector2.new(0, 0),
					BackgroundTransparency = 0,
					Name = "option",
					Position = UDim2.new(0, 0, 0, 0),
					Visible = false,
					ZIndex = 1,
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					Size = UDim2.new(0.5, 0, 1, 0),
				}, {
					utility.create("UICorner", {
						Name = "UICorner",
						CornerRadius = UDim.new(0, 5),
					}),
					utility.create("UIStroke", {
						Name = "UIStroke",
						Color = Color3.fromRGB(25, 25, 25),
						ZIndex = 1,
					}),
					utility.create("TextLabel", {
						Visible = true,
						FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						ZIndex = 1,
						Text = "Okay",
						Name = "label",
						TextXAlignment = Enum.TextXAlignment.Center,
						AnchorPoint = Vector2.new(0.5, 0.5),
						TextScaled = true,
						BackgroundTransparency = 1,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						TextYAlignment = Enum.TextYAlignment.Center,
						TextSize = 14,
						Size = UDim2.new(1, -15, 0, 15),
					})
				})
			}),
			utility.create("TextLabel", {
				Visible = true,
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				TextColor3 = Color3.fromRGB(100, 100, 100),
				ZIndex = 1,
				Text = "Lorem ipsum dolor sit amet",
				Name = "body",
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0),
				TextScaled = false,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 50),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				TextYAlignment = Enum.TextYAlignment.Top,
				TextSize = 13,
				Size = UDim2.new(1, -30, 1, -120),
			}),
			utility.create("TextLabel", {
				Visible = true,
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 1,
				Text = "Header",
				Name = "title",
				TextXAlignment = Enum.TextXAlignment.Center,
				AnchorPoint = Vector2.new(0, 0),
				TextScaled = true,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 20),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextSize = 14,
				Size = UDim2.new(1, -15, 0, 25),
			})
		}),
		utility.create("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
	})

	local frame = dialogFrame.frame
	local bodyLabel = frame.body
	local titleLabel = frame.title
	local buttonsFrame = frame.buttons


	local dialog = {}

	function dialog:prompt(config)
		if library.isDialogOpen then
			return
		end


		library.isDialogOpen = true

		config.title = config.title or "header"
		config.body = config.body or "Lorem ipsum dolor sit amet"
		config.buttons = config.buttons or nil
		config.duration = config.duration or 3
		config.callback = config.callback or function()

		end


		titleLabel.Text = config.title
		bodyLabel.Text = config.body


		if config.buttons ~= nil then
			for _, btn in buttonsFrame:GetChildren() do
				if btn.Name ~= "option" and btn:IsA("Frame") then
					btn:Destroy()
				end
			end

			for _, buttons in pairs(config.buttons) do
				task.wait()

				local clone = buttonsFrame.option:Clone()
				clone.Parent = buttonsFrame
				clone.label.Text = buttons
				clone.Name = buttons
				clone.Visible = true


				local connection
				connection = clone.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then

						config.callback(buttons)
						library.isDialogOpen = false

						utility.tween(dialogFrame, 0.5, {
							GroupTransparency = 1,

						})			

						if connection then
							connection:Disconnect()
						end

					end			
				end)

			end
		elseif config.buttons == nil then
			task.delay(config.duration, function()
				library.isDialogOpen = false

				utility.tween(dialogFrame, 0.5, {
					GroupTransparency = 1,
					Position = UDim2.new(0,0,0,15)
				})		
			end)
		end



		utility.tween(dialogFrame, 0.5, {
			GroupTransparency = 0,
			Position = UDim2.new(0,0,0,0)
		})


		local instance = {}


		return instance
	end

	dialog.frame = dialogFrame
	return dialog

end

function builder.notification(screen)

	local notificationFrame = utility.create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Name = "notification",
		Position = UDim2.new(0.9900000095367432, 0, 0.9900000095367432, 0),
		Visible = true,
		ZIndex = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, 224, 0, 224),
		Parent = screen
	}, {
		utility.create("UIListLayout", {
			Name = "UIListLayout",
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 5),
		})
	})


	local instance = {}
	instance.frame = notificationFrame

	function instance:notify(config)
		config = config or {}
		local title = config.title or "notification"
		local body = config.body or "body"
		local duration = config.duration or 3

		local templateFrame = utility.create("CanvasGroup", {
			AnchorPoint = Vector2.new(0, 0),
			BackgroundTransparency = 0,
			Name = "template",
			Position = UDim2.new(0, 0, 0, 0),
			Visible = false,
			ZIndex = 1,
			BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			GroupTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = notificationFrame,
		}, {
			utility.create("UICorner", {
				Name = "UICorner",
				CornerRadius = UDim.new(0, 12),
			}),
			utility.create("TextLabel", {
				Visible = true,
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				TextColor3 = Color3.fromRGB(100, 100, 100),
				ZIndex = 1,
				Text = "Lorem ipsum dolor sit amet",
				Name = "body",
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0.5),
				TextScaled = true,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.949999988079071, 0, 0.65, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextSize = 14,
				Size = UDim2.new(1, -15, 0, 13),
			}),
			utility.create("TextLabel", {
				Visible = true,
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 1,
				Text = "Header",
				Name = "title",
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0.5),
				TextScaled = true,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.949999988079071, 0, 0.30000001192092896, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				TextYAlignment = Enum.TextYAlignment.Center,
				TextSize = 14,
				Size = UDim2.new(1, -15, 0, 15),
			}),
			utility.create("Frame", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundTransparency = 0,
				Name = "timer",
				Position = UDim2.new(0, 0, 1, -2),
				Visible = true,
				ZIndex = 1,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 0, 0, 2),
			})
		})
		local titleLabel = templateFrame.title
		local bodyLabel = templateFrame.body

		titleLabel.Text = title
		bodyLabel.Text = body

		templateFrame.Visible = true

		utility.tween(templateFrame, .5, {
			GroupTransparency = 0,
			Size = UDim2.new(1, 0, 0, 50)
		})

		utility.tween(templateFrame.timer, duration, {
			Size = UDim2.new(1, 0, 0, 2),

		}, Enum.EasingStyle.Linear)

		task.delay(duration, function()
			utility.tween(templateFrame, .5, {
				GroupTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0)
			})
			debris:AddItem(templateFrame, .5)
		end)
	end

	return instance
end
--------------------------------------
-- library ---------------------------
--------------------------------------

function library.new(config)
	if library.window then
		print("cant make two windows")
		return
	end
	
	config = config or {}

	local title = config.title or "my script"
	local subtitle = config.subtitle or ""

	local size = config.size or UDim2.fromOffset(700,400)

	local screen = utility.create("ScreenGui", {
		Name = title,
		Parent = game.CoreGui,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.None,
	})


	local canvas = builder.canvas(screen, size)
	local notification = builder.notification(screen)

	local topbar = builder.topbar(canvas, title, subtitle)
	local sidebar = builder.sidebar(canvas)
	local content = utility.create("Frame", {
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 1,
		Name = "content",
		Position = UDim2.new(0, 165, 0, 0),
		Visible = true,
		ZIndex = 10,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, -170, 1, 0),
		Parent = canvas
	}, {
		utility.create("Frame", {
			AnchorPoint = Vector2.new(0, 0),
			BackgroundTransparency = 1,
			Name = "container",
			Position = UDim2.new(0, 0, 0, 48),
			Visible = true,
			ZIndex = 10,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.new(1, 0, 1, -50),
		})
	})
	local dialog = builder.dialog(content)

	--------------------------------------
	-- library funcs ---------------------
	--------------------------------------

	function library:notify(config)
		config.title = config.title or "Notification"
		config.body = config.body or "Lorem ipsum dolor sit amet"
		config.duration = config.duration or 3

		notification:notify(config)

	end

	--------------------------------------
	-- window funcs ----------------------
	--------------------------------------

	local window
	window = {
		canvas = canvas,
		topbar = topbar,
		sidebar = sidebar,
		screen = screen,

	}
	window.originalSize = canvas.Size
	window.isOpen = true
	utility.setupDrag(canvas, topbar.frame)
	topbar.nav.close.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			window:dialog({
				title = "close window?",
				body = "are you sure you want to unload the interface?",
				buttons = {
					"no",
					"yes",
				},
				callback = function(choice)
					if choice == "yes" then
						library:unload()
					end
				end,
			})
		end
	end)
	
	topbar.nav.hide.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			window:toggle(false)
		end
	end)
	
	library.window = window


	function window:toggle(state)
		if state == nil then
			state = not window.isOpen
		end

		window.isOpen = state

		if state then
			utility.tween(canvas, 0.3, {
				Size = window.originalSize
			}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		else
			utility.tween(canvas, 0.3, {
				Size = UDim2.new(
					window.originalSize.X.Scale,
					window.originalSize.X.Offset,
					0,
					0
				)
			},  Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		end
	end

	function window:setToggleKey(bind: Enum.KeyCode)
		library.toggleKey = bind
	end

	function window:dialog(config)
		config.title = config.title or "header"
		config.body = config.body or "Lorem ipsum dolor sit amet"
		config.buttons = config.buttons or nil
		config.duration = config.duration or 3
		config.callback = config.callback or function()

		end

		dialog:prompt(config)
	end


	
	userInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end

		if input.KeyCode == library.toggleKey then
			window:toggle(not window.isOpen)
		end
	end)

	--------------------------------------
	-- tab  ------------------------------
	--------------------------------------

	local tabs = {}
	local currentTab = nil

	function window:createSection(name)
		local sectionOrder = #sidebar.list:GetChildren() + 1
		local sectionFrame = utility.create("Frame", {
			AnchorPoint = Vector2.new(0, 0),
			BackgroundTransparency = 1,
			Name = "section",
			Parent = sidebar.list,

			Position = UDim2.new(0, 0, 0, 0),
			Visible = true,

			ZIndex = 5,
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),

			Size = UDim2.new(0, 145, 0, 19),
			LayoutOrder = sectionOrder,
		}, {
			utility.create("TextLabel", {
				Visible = true,
				TextColor3 = Color3.fromRGB(100, 100, 100),
				Text = name,

				AnchorPoint = Vector2.new(0.5, 0.5),
				Name = "label",
				BackgroundTransparency = 1,

				Position = UDim2.new(0.5, 0, 0.5, 0),
				ZIndex = 5,

				TextSize = 14,
				Size = UDim2.new(0.9, 0, 0.57, 0),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,

				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			})
		})



		return sectionFrame
	end

	function window:createDivider()
		local dividerOrder = #sidebar.list:GetChildren() + 1
		local dividerFrame = utility.create("Frame", {
			AnchorPoint = Vector2.new(0, 0),
			BackgroundTransparency = 1,
			Name = "divider",
			Position = UDim2.new(0, 0, 0.11538461595773697, 0),
			Visible = true,
			ZIndex = 5,
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			Size = UDim2.new(0, 145, 0, 11),
			Parent = sidebar.list,
			LayoutOrder = dividerOrder,
		}, {
			utility.create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 0,
				Name = "Frame",
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Visible = true,
				ZIndex = 5,
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				Size = UDim2.new(0.800000011920929, 0, 0, 1),
			})
		})

		return dividerFrame
	end

	function window:createTab(config)
		local tabName = config.name or "Tab"
		local tabIcon = config.icon or "rbxassetid://10723407389"
		local tabOrder = config.order or (#sidebar.list:GetChildren() + 1)
		if not sidebar then
			sidebar = builder.sidebar(canvas)
			window.sidebar = sidebar
		end

		local tab = {}

		local tabBtn
		local tabContent

		tabBtn = utility.create("TextLabel", {
			Visible = true,
			TextColor3 = Color3.fromRGB(0, 0, 0),
			Text = tabName,
			AnchorPoint = Vector2.new(0, 0),
			Name = "tab",
			BackgroundTransparency = 0,
			TextTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			ZIndex = 5,
			TextSize = 14,
			Size = UDim2.new(1, 0, -0.01, 38),
			LayoutOrder = tabOrder,
			Parent = sidebar.list
		}, {
			utility.create("ImageLabel", {
				Visible = true,
				AnchorPoint = Vector2.new(0, 0.5),
				Image = tabIcon,
				ImageColor3 = Color3.fromRGB(100, 100, 100),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0.5, -1),
				Name = "icon",
				ZIndex = 5,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 16, 0, 16),
			}),
			utility.create("TextLabel", {
				Visible = true,
				TextColor3 = Color3.fromRGB(100, 100, 100),
				Text = tabName,
				AnchorPoint = Vector2.new(0, 0.5),
				Name = "label",
				BackgroundTransparency = 1,
				Position = UDim2.new(-0.041, 40, 0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 5,
				TextSize = 14,
				Size = UDim2.new(1, -56, 0.39, 0),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			}),
			utility.create("UICorner", {
				Name = "UICorner",
				CornerRadius = UDim.new(0, 10),
			})
		})

		tabContent = utility.create("CanvasGroup", {
			AnchorPoint = Vector2.new(0, 0),
			BackgroundTransparency = 1,
			Name = tabName,
			Position = UDim2.new(0, 0, 0, 0),
			Visible = false,
			ZIndex = 10,
			BackgroundColor3 = Color3.fromRGB(200, 200, 200),
			Size = UDim2.new(1, 0, 1, -15),
			Parent = content.container
		}, {
			utility.create("ScrollingFrame", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundTransparency = 1,
				Name = "list",
				Position = UDim2.new(0, 0, 0, 0),
				Visible = true,
				ZIndex = 10,
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarThickness = 5,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
			}, {
				utility.create("UIListLayout", {
					Name = "UIListLayout",
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				utility.create("UIPadding", {
					PaddingTop = UDim.new(0, 14),
					Name = "UIPadding",
					PaddingBottom = UDim.new(0, 0),
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}),
			})

		})


		tab.button = tabBtn
		tab.name = tabName
		tab.order = tabOrder
		tab.content = tabContent
		tab.list = tabContent.list

		table.insert(tabs, tab)

		task.defer(function()
			if not currentTab or #tabs == 1 then
				window:selectTab(tab)
			end
		end)

		tabBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				window:selectTab(tab)
			end
		end)


		--------------------------------------
		-- tab funcs -------------------------
		--------------------------------------
		
		function tab:createDivider()
			utility.create("Frame", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundTransparency = 1,
				Name = "divider",
				Position = UDim2.new(0, 0, 0.11538461595773697, 0),
				Visible = true,
				ZIndex = 5,
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				Size = UDim2.new(1, 0, 0, 11),
				Parent = tab.list,
			}, {
				utility.create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 0,
					Name = "Frame",
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Visible = true,
					ZIndex = 5,
					BackgroundColor3 = Color3.fromRGB(25, 25, 25),
					Size = UDim2.new(1, -10, 0, 1),
				})
			})
		end
		
		function tab:createDropdown(config)
			local title = config.title or "Dropdown"
			local description = config.description

			local options = config.options or {}
			local default = config.default
			local callback = config.callback or function() end

			local selected = ""
			local expanded = false

			local dropdownFrame = utility.create("Frame", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundTransparency = 0,
				Name = "dropdown",
				Position = UDim2.new(0, 0, 0.3115122616291046, 0),
				Visible = true,
				ZIndex = 10,
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				Size = UDim2.new(1, 0, 0, (description and 54 or 44)),
				Parent = tab.list,
			}, {
				utility.create("Frame", {
					AnchorPoint = Vector2.new(0, 0),
					BackgroundTransparency = 0,
					Name = "options",
					Position = UDim2.new(1, -198, 0, 7),
					Visible = true,
					ZIndex = 15,
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					Size = UDim2.new(0, 190, 1, -15),
					ClipsDescendants = true,

				}, {
					utility.create("Frame", {
						AnchorPoint = Vector2.new(0, 0),
						BackgroundTransparency = 1,
						Name = "list",
						Position = UDim2.new(0, 5, 0, 50),
						Visible = true,
						ZIndex = 1,
						BackgroundColor3 = Color3.fromRGB(25, 25, 25),
						Size = UDim2.new(1, 50, 0, 50),
					}, {
						utility.create("UICorner", {
							Name = "UICorner",
							CornerRadius = UDim.new(0, 5),
						}),
						utility.create("UIListLayout", {
							Name = "UIListLayout",
							Padding = UDim.new(0, 8),
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						}),
						utility.create("UIPadding", {
							PaddingTop = UDim.new(0, 5),
							Name = "UIPadding",
							PaddingBottom = UDim.new(0, 0),
							PaddingLeft = UDim.new(0, 0),
							PaddingRight = UDim.new(0, 0),
						}),

					}),
					utility.create("ImageLabel", {
						Visible = true,
						AnchorPoint = Vector2.new(0, 0),
						Image = "rbxassetid://10709791523",
						BackgroundTransparency = 1,
						Position = UDim2.new(1, -25, 0, (description and 12 or 7)),
						Name = "chevron",
						ZIndex = 15,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						Size = UDim2.new(0, 15, 0, 15),
					}),
					utility.create("TextLabel", {
						Visible = true,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Text = default or "",
						AnchorPoint = Vector2.new(0, 0),
						Name = "value",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 10, 0, (description and 13 or 8)),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						ZIndex = 15,
						TextSize = 14,
						Size = UDim2.new(0, 145, 0, 13),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextScaled = true,

						FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium),
					}),
					utility.create("UIStroke", {
						Name = "UIStroke",
						Color = Color3.fromRGB(25, 25, 25),
						Thickness = 1,
						ZIndex = 1,
					}),
					utility.create("UICorner", {
						Name = "UICorner",
						CornerRadius = UDim.new(0, 5),
					}),
					utility.create("Frame", {
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundTransparency = 1,
						Name = "divider",
						Position = UDim2.new(0.5, 0, 0, 40),
						Visible = true,
						ZIndex = 5,
						BackgroundColor3 = Color3.fromRGB(25, 25, 25),
						Size = UDim2.new(1, 0, 0, 11),
					}, {
						utility.create("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 0,
							Name = "Frame",
							Position = UDim2.new(0.5, 0, 0.5, 0),
							Visible = true,
							ZIndex = 5,
							BackgroundColor3 = Color3.fromRGB(25, 25, 25),
							Size = UDim2.new(1, 0, 0, 1),
						})
					})
				}),


				utility.create("TextLabel", {
					Visible = true,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Text = "Dropdown",
					AnchorPoint = Vector2.new(0, 0),
					Name = "title",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 15, 0, 14),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					ZIndex = 10,
					TextSize = 14,
					Size = UDim2.new(0.88416987657547, -15, 0, 13),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium),
				}),
				utility.create("UICorner", {
					Name = "UICorner",
					CornerRadius = UDim.new(0, 5),
				})
			})

			local optionsFrame = dropdownFrame.options
			local listFrame = optionsFrame.list 

			local titleLabel = dropdownFrame.title
			local valueLabel = optionsFrame.value

			local chevron = optionsFrame.chevron

			local baseHeight = 50
			local lastOptions = {}

			if description then
				utility.create("TextLabel", {
					Name = "description",
					Parent = dropdownFrame,

					Position = UDim2.new(0, 15, 0, 28),
					Size = UDim2.new(1, -15, 0, 12),
					BackgroundTransparency = 1,

					Text = description,
					TextColor3 = Color3.fromRGB(100, 100, 100),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular),
				})
			end

			local function update()
				
				
				local listHeight = listFrame.UIListLayout.AbsoluteContentSize.Y	+ 10
				local totalHeight = listHeight - (description and 0 or -10)


				utility.tween(optionsFrame, 0.3, {
					Size = UDim2.new(
						0,
						190,
						1,
						expanded and totalHeight or -15
					)
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

				utility.tween(listFrame, 0.3, {
					Size = expanded
						and UDim2.new(1, -10, 0, listHeight)
						or UDim2.new(1, -10, 0, 0)
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

				utility.tween(chevron, 0.3, {
					Rotation = expanded and -180 or 0
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

				utility.tween(optionsFrame.UIStroke, 0.1, {
					Transparency = expanded and 0 or 1
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

				dropdownFrame.ZIndex = expanded and 999 or 15

				local function optionsChanged()
					if #lastOptions ~= #options then
						return true
					end

					for i, v in ipairs(options) do
						if lastOptions[i] ~= v then
							return true
						end
					end

					return false
				end

				if not optionsChanged() then return end

				for _, child in pairs(listFrame:GetChildren()) do
					if child:IsA("Frame") then
						child:Destroy()
					end
				end

				lastOptions = table.clone(options)

				for index, option in ipairs(options) do
					local button = utility.create("Frame", {
						Name = "option",
						Size = UDim2.new(1, -10, 0, 30),
						ZIndex = 1,
						BackgroundColor3 = Color3.fromRGB(45, 45, 45),
						LayoutOrder = index,
						Parent = listFrame,
					}, {
						utility.create("UICorner", {
							CornerRadius = UDim.new(0, 5),
						}),
						utility.create("TextLabel", {
							Visible = true,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							Text = option,
							AnchorPoint = Vector2.new(0, 0),
							Name = "label",
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 10, 0, 9),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							ZIndex = 15,
							TextSize = 14,
							TextScaled = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
							Size = UDim2.new(0, 145, 0, 13),
						})
					})

					button.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							selected = option
							valueLabel.Text = option
							callback(selected)
						end
					end)
				end
			end

			local function toggleExpand()
				expanded = not expanded
				update()
			end
			
			local conn1,conn2
			
			conn1 = listFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				if expanded then
					update()
				end
			end)
			
			table.insert(library.connections, conn1)

			conn2 = optionsFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					toggleExpand()
				end
			end)		
			
			table.insert(library.connections, conn2)


			return {
				frame = optionsFrame,
				setOptions = function(_, new)
					options = new
					update()
				end,
			}
		end

		function tab:createToggle(config)
			config = config or {}

			local title = config.title or "Toggle"
			local description = config.description
			local callback = config.callback or function() end
			local order = config.order or (#tab.list:GetChildren() + 1)

			local enabled = config.default or false

			local toggleFrame = utility.create("Frame", {
				Name = title,
				Parent = tab.list,

				LayoutOrder = order,
				Size = UDim2.new(1, 0, 0, (description and 54 or 44)),
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			}, {
				utility.create("Frame", {
					Name = "toggleBg",

					Position = UDim2.new(1, -51, 0.5, -12),
					Size = UDim2.new(0, 44, 0, 24),

					BackgroundColor3 = enabled and library.theme.accent or Color3.fromRGB(25, 25, 25),
				}, {
					utility.create("Frame", {
						Name = "knob",

						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = enabled and UDim2.new(0.7, 0, 0.5, 0) or UDim2.new(0.3, 0, 0.5, 0),
						Size = UDim2.new(0, 18, 0, 18),

						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					}, {
						utility.create("UICorner", {
							CornerRadius = UDim.new(1, 0)
						})
					}),

					utility.create("UICorner", {
						CornerRadius = UDim.new(1, 0)
					})
				}),

				utility.create("UICorner", {
					CornerRadius = UDim.new(0, 5)
				})
			})

			local toggleBg = toggleFrame.toggleBg
			local knob = toggleBg.knob

			utility.create("TextLabel", {
				Name = "title",
				Parent = toggleFrame,

				Position = UDim2.new(0, 15, 0, 14),
				Size = UDim2.new(1, -15, 0, 13),
				BackgroundTransparency = 1,

				Text = title,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 14,
				TextScaled = true,

				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium),
			})

			if description then
				utility.create("TextLabel", {
					Name = "description",
					Parent = toggleFrame,

					Position = UDim2.new(0, 15, 0, 28),
					Size = UDim2.new(1, -15, 0, 12),
					BackgroundTransparency = 1,

					Text = description,
					TextColor3 = Color3.fromRGB(100, 100, 100),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular),
				})
			end

			local function update(state, skip)
				enabled = state

				utility.tween(knob, 0.3, {
					Position = enabled and UDim2.new(0.7, 0, 0.5, 0) or UDim2.new(0.3, 0, 0.5, 0)
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

				utility.tween(toggleBg, 0.3, {
					BackgroundColor3 = enabled and library.theme.accent or Color3.fromRGB(25, 25, 25)
				})

				if not skip then
					callback(enabled)
				end
			end


			toggleBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					update(not enabled)
				end
			end)


			update(enabled, true)

			return {
				frame = toggleFrame,
				value = function()
					return enabled
				end,
				set = function(_, state, skip)
					update(state, skip)
				end,
				toggle = function(skip)
					update(not enabled, skip)
				end
			}
		end

		function tab:createSlider(config)
			config = config or {}

			local title = config.title or "Toggle"
			local description = config.description
			local callback = config.callback or function() end
			local min = config.min or 0
			local max = config.max or 100
			local increment = config.increment or 1
			local display = config.display or ""

			local value = math.clamp(config.default or min, min, max)

			local sliderFrame = utility.create("Frame", {
				Name = title,
				Parent = tab.list,

				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, (description and 72 or 54)),

				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				BackgroundTransparency = 0,

				ZIndex = 10,
			}, {
				utility.create("Frame", {
					Name = "sliderBg",

					Position = UDim2.new(0, 14, 1, -20),
					Size = UDim2.new(1, -28, 0, 8),

					BackgroundColor3 = Color3.fromRGB(25, 25, 25),

					ZIndex = 10,
				}, {
					utility.create("Frame", {
						Name = "fill",

						Size = UDim2.new(0, 0, 1, 0),

						BackgroundColor3 = library.theme.accent,

						ZIndex = 10,
					}, {
						utility.create("UICorner", {
							CornerRadius = UDim.new(1, 0)
						})
					}),
					utility.create("Frame", {
						Name = "knob",

						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(0, 16, 0, 16),

						BackgroundColor3 = Color3.fromRGB(255, 255, 255),

						ZIndex = 10,
					}, {
						utility.create("UICorner", {
							CornerRadius = UDim.new(1, 0)
						})
					}),
					utility.create("UICorner", {
						CornerRadius = UDim.new(1, 0)
					})
				}),
				utility.create("UICorner", {
					CornerRadius = UDim.new(0, 5)
				})
			})

			local sliderBg = sliderFrame.sliderBg
			local fill = sliderBg.fill
			local knob = sliderBg.knob

			local titleLabel = utility.create("TextLabel", {
				Name = "title",

				Position = UDim2.new(0, 15, 0, 14),
				Size = UDim2.new(1, -15, 0, 13),
				BackgroundTransparency = 1,

				Text = title,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 14,
				TextScaled = true,

				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium),

				Parent = sliderFrame
			})

			local displayLabel = utility.create("TextLabel", {
				Name = "display",
				Parent = sliderFrame,

				Position = UDim2.new(1, -60, 0, 14),
				Size = UDim2.new(0, 50, 0, 12),
				BackgroundTransparency = 1,

				Text = value .. display,
				TextColor3 = Color3.fromRGB(100, 100, 100),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextSize = 14,
				TextScaled = true,

				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular),
			})

			if description then
				utility.create("TextLabel", {
					Name = "description",
					Parent = sliderFrame,

					Position = UDim2.new(0, 15, 0, 28),
					Size = UDim2.new(1, -100, 0, 12),
					BackgroundTransparency = 1,

					Text = description,
					TextColor3 = Color3.fromRGB(100, 100, 100),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular),

				})
			end

			local dragging = false

			local function update(newValue, skip)
				newValue = math.clamp(newValue, min, max)
				newValue = math.floor(newValue / increment + 0.5) * increment
				value = utility.roundUp(newValue, 2)

				local percent = (value - min) / (max - min)

				utility.tween(knob, 0.2, {
					Position = UDim2.new(percent, 0, 0.5, 0)
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

				utility.tween(fill, 0.2, {
					Size = UDim2.new(percent, 0, 1, 0)
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

				displayLabel.Text = value .. display

				if not skip then
					callback(value)
				end
			end

			local function updateFromInput(x)
				local absPos = sliderBg.AbsolutePosition.X
				local absSize = sliderBg.AbsoluteSize.X
				local percent = math.clamp((x - absPos) / absSize, 0, 1)
				update(min + percent * (max - min))
			end

			sliderBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromInput(input.Position.X)
				end
			end)

			local inputChangedConn = userInputService.InputChanged:Connect(function(input)
				if not dragging then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					updateFromInput(input.Position.X)
				end
			end)

			table.insert(library.connections, inputChangedConn)

			local inputEndedConn = userInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			table.insert(library.connections, inputEndedConn)

			update(value, true)

			return {
				frame = sliderFrame,
				value = function()
					return value
				end,
				set = function(_, newValue, skip)
					update(newValue, skip)
				end,
			}
		end

		function tab:createLabel(config)
			config = config or {}
			local text = config.text or "text"

			local labelFrame = utility.create("Frame", {
				Name = text,
				Parent = tab.list,

				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
			}, {
				utility.create("TextLabel", {
					Name = "label",

					Position = UDim2.new(0, 0, 0, 5),
					Size = UDim2.new(1, 0, 0, 13),
					BackgroundTransparency = 1,

					Text = text,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				})
			})

			local label = labelFrame.label

			return {
				frame = labelFrame,
				set = function(_, newText)
					text = newText
					label.Text = newText
					labelFrame.Name = newText
				end
			}
		end

		function tab:createParagraph(config)
			config = config or {}

			local title = config.title or "title"
			local body = config.body or "body"

			local paragraphFrame = utility.create("Frame", {
				Name = title,
				Parent = tab.list,

				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
			}, {
				utility.create("TextLabel", {
					Name = "body",

					Position = UDim2.new(0, 0, 0, 20),
					Size = UDim2.new(1, 0, 0, 11),
					BackgroundTransparency = 1,

					Text = body,
					TextColor3 = Color3.fromRGB(100, 100, 100),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				}),
				utility.create("TextLabel", {
					Name = "title",

					Position = UDim2.new(0, 0, 0, 5),
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,

					Text = title,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),

				})
			})

			local titleLabel = paragraphFrame.title
			local bodyLabel = paragraphFrame.body

			return {
				frame = paragraphFrame,
				set = function(_, newTitle, newText)
					if newTitle then
						titleLabel.Text = newTitle
						paragraphFrame.Name = newTitle
					end

					if newText then
						bodyLabel.Text = newText
						bodyLabel.Text = newText
					end
				end
			}
		end

		function tab:createButton(config)
			config = config or {}
			local title = config.title or "button"
			local callback = config.callback or function() end
			local description = config.description


			local buttonFrame = utility.create("Frame", {
				Name = title,
				Parent = tab.list,

				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, (description and 54 or 44)),

				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				BackgroundTransparency = 0,

				Visible = true,
				ZIndex = 10,
			}, {
				utility.create("TextLabel", {
					Name = "title",

					Position = UDim2.new(0, 15, 0, 14),
					Size = UDim2.new(0.88416987657547, -15, 0, 13),

					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,

					Visible = true,
					ZIndex = 10,

					Text = title,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				}),
				utility.create("TextLabel", {
					Name = "display",

					Position = UDim2.new(1, -60, 0.5, 0),
					Size = UDim2.new(0, 50, 0, 10),

					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,

					Visible = true,
					ZIndex = 10,

					Text = "button",
					TextColor3 = Color3.fromRGB(50, 50, 50),
					TextXAlignment = Enum.TextXAlignment.Right,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				}),
				utility.create("UICorner", {
					Name = "UICorner",
					CornerRadius = UDim.new(0, 5),
				})
			})

			if description then
				utility.create("TextLabel", {
					Name = "description",
					Parent = buttonFrame,

					Position = UDim2.new(0, 15, 0, 28),
					Size = UDim2.new(1, -15, 0, 12),

					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,

					ZIndex = 10,

					Text = description,
					TextColor3 = Color3.fromRGB(100, 100, 100),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					TextScaled = true,

					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				})
			end

			buttonFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					callback()
				end
			end)

			return {
				frame = buttonFrame,
				setText = function(_, text)
					buttonFrame.display.Text = text
				end,
			}
		end

		function tab:createKeybind(config)
			config = config or {}

			local title = config.title or "keybind"
			local callback = config.callback or function() end
			local changedCallback = config.changedCallback or function() end
			local description = config.description
			local default = config.default or Enum.KeyCode.Unknown

			local mode = config.type
			if mode ~= "toggle" and mode ~= "hold" then
				mode = "toggle"
			end

			local key = default
			local isBinding = false
			local state = false
			local suppressRelease = false
			local lastSet = 0
			local ignoreInput = false

			local keybindFrame = utility.create("Frame", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundTransparency = 0,
				Name = title,
				Position = UDim2.new(0, 0, 0, 0),
				Visible = true,
				ZIndex = 10,
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				Size = UDim2.new(1, 0, 0, description and 54 or 40),
				Parent = tab.list,
			}, {
				utility.create("Frame", {
					AnchorPoint = Vector2.new(1, .5),
					BackgroundTransparency = 0,
					Name = "keybindBg",
					Position = UDim2.new(1, -8, 0.5, 0),
					Visible = true,
					ZIndex = 10,
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					Size = UDim2.new(0, 0, 0, 30),
				}, {
					utility.create("UICorner", {
						Name = "UICorner",
						CornerRadius = UDim.new(0, 6),
					}),
					utility.create("UIStroke", {
						Name = "UIStroke",
						ZIndex = 1,
						Color = Color3.fromRGB(25, 25, 25),
						Transparency = 1,
					}),
					utility.create("TextLabel", {
						Visible = true,
						FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						ZIndex = 1,
						Text = "",
						Name = "label",
						TextXAlignment = Enum.TextXAlignment.Center,
						AnchorPoint = Vector2.new(.5, 0.5),
						TextScaled = false,
						BackgroundTransparency = 1,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						TextYAlignment = Enum.TextYAlignment.Center,
						TextSize = 14,
						Size = UDim2.new(0, 0, 0, 15),
						AutomaticSize = Enum.AutomaticSize.X,
					})
				}),

				utility.create("TextLabel", {
					Visible = true,
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					ZIndex = 10,
					Text = title,
					Name = "title",
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0),
					TextScaled = true,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 15, 0, 14),
					TextYAlignment = Enum.TextYAlignment.Center,
					TextSize = 14,
					Size = UDim2.new(1, -145, 0, 13),
				}),
				utility.create("UICorner", {
					Name = "UICorner",
					CornerRadius = UDim.new(0, 5),
				})
			})

			local keybindBg = keybindFrame.keybindBg
			local keyLabel = keybindBg.label
			local stroke = keybindBg.UIStroke

			local function stringify(input)
				if input == Enum.KeyCode.Unknown then
					return "Unknown"
				end

				if typeof(input) == "EnumItem" and input.EnumType == Enum.UserInputType then
					if input == Enum.UserInputType.MouseButton1 then return "LMB" end
					if input == Enum.UserInputType.MouseButton2 then return "RMB" end
					if input == Enum.UserInputType.MouseButton3 then return "MMB" end
					return tostring(input):gsub("Enum.UserInputType.", "")
				end

				return tostring(input):gsub("Enum.KeyCode.", "")
			end

			local function refresh()
				keyLabel.Text = isBinding and "..." or stringify(key)

				task.defer(function()
					local bounds = keyLabel.TextBounds
					utility.tween(keybindBg, .3, {
						Size = UDim2.new(0, bounds.X + 20, 0, 30)
					}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end)
			end

			local function setKey(newKey)
				isBinding = false

				utility.tween(stroke, .3, {
					Transparency = 1
				})

				if newKey ~= nil then
					key = newKey
					changedCallback(key)

					if mode == "hold" then
						suppressRelease = true
						lastSet = tick()
					end
				end

				refresh()
			end

			refresh()

			local function isMatch(input)
				if key == Enum.KeyCode.Unknown then return false end

				if key.EnumType == Enum.KeyCode then
					return input.KeyCode == key
				end

				if key.EnumType == Enum.UserInputType then
					return input.UserInputType == key
				end

				return false
			end

			keybindBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then

					isBinding = not isBinding

					if isBinding then
						ignoreInput = true

						utility.tween(stroke, .3, {
							Transparency = 0
						})

						task.delay(0.01, function()
							ignoreInput = false

						end)
					end

					refresh()
				end
			end)

			local beganConn = userInputService.InputBegan:Connect(function(input, gp)
				if ignoreInput then return end

				if isBinding then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						if input.KeyCode == Enum.KeyCode.Escape then
							setKey()
						elseif input.KeyCode == Enum.KeyCode.Backspace then
							setKey(Enum.KeyCode.Unknown)
						else
							setKey(input.KeyCode)
						end
					elseif tostring(input.UserInputType):find("MouseButton") then
						setKey(input.UserInputType)
					end
					return
				end

				if gp or key == Enum.KeyCode.Unknown then
					return
				end

				if not isMatch(input) then return end

				if mode == "toggle" then
					state = not state
					callback(state)
				else
					callback(true)
				end
			end)

			table.insert(library.connections, beganConn)

			if mode == "hold" then
				local endedConn = userInputService.InputEnded:Connect(function(input)
					if key == Enum.KeyCode.Unknown then return end
					if not isMatch(input) then return end

					if suppressRelease and (tick() - lastSet < 0.3) then
						suppressRelease = false
						return
					end

					callback(false)
				end)

				table.insert(library.connections, endedConn)

				local focusConn = userInputService.WindowFocusReleased:Connect(function()
					callback(false)
				end)

				table.insert(library.connections, focusConn)
			end

			if description then
				utility.create("TextLabel", {
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					TextColor3 = Color3.fromRGB(100, 100, 100),
					ZIndex = 10,
					Text = description,
					Name = "description",
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0),
					TextScaled = true,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 15, 0, 28),
					TextYAlignment = Enum.TextYAlignment.Center,
					TextSize = 14,
					Visible = true,
					Size = UDim2.new(1, -145, 0, 12),
					Parent = keybindFrame
				})
			end
			
			return {
				frame = keybindFrame,
				value = function()
					return key
				end,
				set = function(_, new)
					key = new
					refresh()
					
				end,
				
			}
		end
		
		function tab:createInput(config)
			config = config or {}
			local title = config.title or "input"
			local description = config.description
			local default = config.default or ""
			local placeholder = config.placeholder or "..."
			local callback = config.callback or function()
				
			end
			
			local value = default
			local clear = config.clear or false
			local numerical = config.numerical or false
			local limit = config.limit or 50
			
			local inputFrame = utility.create("Frame", {
				AnchorPoint = Vector2.new(0, 0),
				BackgroundTransparency = 0,
				Name = title,
				Position = UDim2.new(0, 0, 0, 0),
				Visible = true,
				ZIndex = 10,
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				Size = UDim2.new(1, 0, 0, (description and 54 or 44)),
				Parent = tab.list
			}, {
				utility.create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 0,
					Name = "inputBg",
					Position = UDim2.new(1, -7, 0.5, 0),
					Visible = true,
					ZIndex = 10,
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					Size = UDim2.new(0, 124, 0, 30),
				}, {
					utility.create("TextBox", {
						Visible = true,
						FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						ZIndex = 1,
						Text = default,
						Name = "label",
						TextXAlignment = Enum.TextXAlignment.Center,
						AnchorPoint = Vector2.new(0.5, 0.5),
						TextScaled = false,
						BackgroundTransparency = 1,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						TextYAlignment = Enum.TextYAlignment.Center,
						TextSize = 14,
						Size = UDim2.new(0, 0, 0, 15),
						ClearTextOnFocus = clear,
						PlaceholderText = placeholder,
						AutomaticSize = Enum.AutomaticSize.X,
					}),
					utility.create("UIStroke", {
						Name = "UIStroke",
						ZIndex = 1,
						Color = Color3.fromRGB(25, 25, 25),
						Transparency = 1,
					}),
					utility.create("UICorner", {
						Name = "UICorner",
						CornerRadius = UDim.new(0, 6),
					})
				}),
				utility.create("UICorner", {
					Name = "UICorner",
					CornerRadius = UDim.new(0, 5),
				}),
				
				utility.create("TextLabel", {
					Visible = true,
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					ZIndex = 10,
					Text = "Input",
					Name = "title",
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0),
					TextScaled = true,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 15, 0, 14),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					TextYAlignment = Enum.TextYAlignment.Center,
					TextSize = 14,
					Size = UDim2.new(1, -145, 0, 13),
				})
			})
			
			local titleLabel = inputFrame.title
			
			local inputBg = inputFrame.inputBg
			local inputBox = inputBg.label
			
			local function update()
				
				if numerical then
					inputBox.Text = inputBox.Text:gsub('%D+', '')
				end
				
				
				
				
				task.defer(function()
					local bounds = inputBox.TextBounds
					utility.tween(inputBg, .3, {
						Size = UDim2.new(0, bounds.X + 20, 0, 30)
					}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end)
				
				inputBox.Text = string.sub(inputBox.Text, 1, limit)
				
			end
			
			local conn1,conn2
			
			inputBox.Focused:Connect(function()
				utility.tween(inputBg.UIStroke, 0.3, {
					Transparency = 0
				})
			end)
			
			inputBox.FocusLost:Connect(function()
				utility.tween(inputBg.UIStroke, 0.3, {
					Transparency = 1
				})
				
				value = inputBox.Text
				callback(value)
			end)
			conn1 = inputBox:GetPropertyChangedSignal("Text"):Connect(function()
				update()
			end)
			
			table.insert(library.connections, conn1)
			
			
			titleLabel.Text = title
			if description then
				utility.create("TextLabel", {
					Visible = true,
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					TextColor3 = Color3.fromRGB(100, 100, 100),
					ZIndex = 10,
					Text = description,
					Name = "description",
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0),
					TextScaled = true,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 15, 0, 28),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					TextYAlignment = Enum.TextYAlignment.Center,
					TextSize = 14,
					Size = UDim2.new(1, -145, 0, 12),
					Parent = inputFrame,
				})
			end
			
			update()
		end
		
		return tab
	end

	function window:selectTab(target)
		if not target or currentTab == target then return end

		currentTab = target

		for _, tab in ipairs(tabs) do
			local button = tab.button
			local content = tab.content

			local isActive = tab == target

			if button then
				local icon = button:FindFirstChild("icon")
				local label = button:FindFirstChild("label")

				local goalColor = isActive and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(100, 100, 100)

				if icon then
					tweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						ImageColor3 = goalColor
					}):Play()
				end

				if label then
					tweenService:Create(label, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						TextColor3 = goalColor
					}):Play()
				end
			end

			if content then
				if isActive then
					content.Visible = true
					content.GroupTransparency = 1
					content.Position = UDim2.new(0, 0, 0.02, 0)

					task.delay(0.12, function()
						if currentTab ~= tab then return end

						tweenService:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							GroupTransparency = 0,
							Position = UDim2.new(0, 0, 0, 0)
						}):Play()
					end)
				else
					tweenService:Create(content, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						GroupTransparency = 1
					}):Play()

					task.delay(0.15, function()
						if currentTab ~= tab then
							content.Visible = false
						end
					end)
				end
			end
		end
	end

	return window
end

function library:unload()
	if self.window then
		self.window.canvas:Destroy()
		self.window = nil
	end

	for _, connection in pairs(self.connections) do
		if connection then
			connection:Disconnect()
		end
	end

	self.connections = {}

	self.isDialogOpen = false
	self.visible = false

	print("unloaded")
end


return library
