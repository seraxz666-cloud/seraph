-- Studio-safe Camera Lock Panel
-- Put this LocalScript in:
-- StarterPlayer > StarterPlayerScripts
--
-- Includes the same dark-blue panel style, draggable top bar,
-- ON/OFF button, keybind button, target display, and a
-- Smoothness slider from 0.15 to 1.00.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local lockedTarget = nil
local lockEnabled = false
local systemEnabled = true

local maxDistance = 10000
local smoothness = 0.20
local minSmoothness = 0.15
local maxSmoothness = 1.00

local keybind = Enum.KeyCode.X
local waitingForKeybind = false

local function validTarget(target)
	if not target or target == player then
		return false
	end

	local character = target.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or humanoid.Health <= 0 or not head or not root then
		return false
	end

	local distance = (camera.CFrame.Position - root.Position).Magnitude
	return distance <= maxDistance
end

local function closestTarget()
	local bestTarget = nil
	local bestDistance = math.huge
	local viewport = camera.ViewportSize
	local screenCenter = Vector2.new(viewport.X / 2, viewport.Y / 2)

	for _, target in ipairs(Players:GetPlayers()) do
		if validTarget(target) then
			local head = target.Character.Head
			local screenPos, visible = camera:WorldToViewportPoint(head.Position)

			if visible and screenPos.Z > 0 then
				local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					bestTarget = target
				end
			end
		end
	end

	return bestTarget
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernCamLockUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 300, 0, 215)
main.Position = UDim2.new(0, 25, 0.5, -107)
main.BackgroundColor3 = Color3.fromRGB(12, 14, 28)
main.BorderSizePixel = 0
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(65, 115, 255)
stroke.Thickness = 2
stroke.Transparency = 0
stroke.Parent = main

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
topBar.BorderSizePixel = 0
topBar.Parent = main

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 18)
topCorner.Parent = topBar

local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, 0, 0, 2)
accent.Position = UDim2.new(0, 0, 0, 40)
accent.BackgroundColor3 = Color3.fromRGB(65, 115, 255)
accent.BorderSizePixel = 0
accent.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 15, 0, 5)
title.Size = UDim2.new(1, -30, 0, 22)
title.Font = Enum.Font.GothamBold
title.Text = "Cam Lock Panel"
title.TextColor3 = Color3.fromRGB(245, 247, 255)
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 15, 0, 42)
subtitle.Size = UDim2.new(1, -30, 0, 24)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Press chosen key to lock to nearest head"
subtitle.TextColor3 = Color3.fromRGB(155, 162, 185)
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = main

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 15, 0, 67)
status.Size = UDim2.new(1, -30, 0, 22)
status.Font = Enum.Font.GothamMedium
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local targetLabel = Instance.new("TextLabel")
targetLabel.BackgroundTransparency = 1
targetLabel.Position = UDim2.new(0, 15, 0, 88)
targetLabel.Size = UDim2.new(1, -30, 0, 22)
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextColor3 = Color3.fromRGB(180, 186, 210)
targetLabel.TextSize = 11
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Text = "Target: None"
targetLabel.Parent = main

-- Smoothness label
local smoothLabel = Instance.new("TextLabel")
smoothLabel.BackgroundTransparency = 1
smoothLabel.Position = UDim2.new(0, 15, 0, 112)
smoothLabel.Size = UDim2.new(1, -80, 0, 18)
smoothLabel.Font = Enum.Font.GothamMedium
smoothLabel.TextColor3 = Color3.fromRGB(205, 210, 230)
smoothLabel.TextSize = 11
smoothLabel.TextXAlignment = Enum.TextXAlignment.Left
smoothLabel.Parent = main

local smoothValue = Instance.new("TextLabel")
smoothValue.BackgroundTransparency = 1
smoothValue.Position = UDim2.new(1, -65, 0, 112)
smoothValue.Size = UDim2.new(0, 50, 0, 18)
smoothValue.Font = Enum.Font.GothamBold
smoothValue.TextColor3 = Color3.fromRGB(95, 145, 255)
smoothValue.TextSize = 11
smoothValue.TextXAlignment = Enum.TextXAlignment.Right
smoothValue.Parent = main

local sliderBack = Instance.new("Frame")
sliderBack.Name = "SmoothnessSlider"
sliderBack.Position = UDim2.new(0, 15, 0, 133)
sliderBack.Size = UDim2.new(1, -30, 0, 7)
sliderBack.BackgroundColor3 = Color3.fromRGB(35, 40, 62)
sliderBack.BorderSizePixel = 0
sliderBack.Parent = main

local sliderBackCorner = Instance.new("UICorner")
sliderBackCorner.CornerRadius = UDim.new(1, 0)
sliderBackCorner.Parent = sliderBack

local sliderFill = Instance.new("Frame")
sliderFill.BorderSizePixel = 0
sliderFill.BackgroundColor3 = Color3.fromRGB(65, 115, 255)
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.Parent = sliderBack

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

local sliderKnob = Instance.new("TextButton")
sliderKnob.AutoButtonColor = false
sliderKnob.Text = ""
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(235, 240, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderBack

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = sliderKnob

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.new(0, 105, 0, 34)
toggle.Position = UDim2.new(1, -120, 1, -48)
toggle.BackgroundColor3 = Color3.fromRGB(65, 115, 255)
toggle.BorderSizePixel = 0
toggle.Font = Enum.Font.GothamBold
toggle.Text = "ON"
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.TextSize = 12
toggle.Parent = main

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = toggle

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(95, 145, 255)
toggleStroke.Thickness = 1
toggleStroke.Parent = toggle

local keybindTag = Instance.new("TextButton")
keybindTag.Name = "Keybind"
keybindTag.Size = UDim2.new(0, 70, 0, 24)
keybindTag.Position = UDim2.new(0, 15, 1, -43)
keybindTag.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
keybindTag.BorderSizePixel = 0
keybindTag.Font = Enum.Font.GothamMedium
keybindTag.TextColor3 = Color3.fromRGB(205, 210, 230)
keybindTag.TextSize = 10
keybindTag.Text = "Key: X"
keybindTag.Parent = main

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 7)
keyCorner.Parent = keybindTag

local keyStroke = Instance.new("UIStroke")
keyStroke.Color = Color3.fromRGB(55, 65, 95)
keyStroke.Thickness = 1
keyStroke.Parent = keybindTag

local function updateSlider()
	local alpha = (smoothness - minSmoothness) / (maxSmoothness - minSmoothness)
	alpha = math.clamp(alpha, 0, 1)

	sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	sliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	smoothValue.Text = string.format("%.2f", smoothness)
end

local function setSmoothnessFromX(x)
	local left = sliderBack.AbsolutePosition.X
	local width = sliderBack.AbsoluteSize.X
	local alpha = math.clamp((x - left) / width, 0, 1)

	smoothness = minSmoothness + (maxSmoothness - minSmoothness) * alpha
	smoothness = math.floor(smoothness * 100 + 0.5) / 100
	updateSlider()
end

local sliderDragging = false

sliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliderDragging = true
	end
end)

sliderBack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliderDragging = true
		setSmoothnessFromX(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		setSmoothnessFromX(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliderDragging = false
	end
end)

local function updateUI()
	status.Text = "Status: " .. (systemEnabled and "Enabled" or "Disabled")
	status.TextColor3 = systemEnabled
		and Color3.fromRGB(75, 220, 125)
		or Color3.fromRGB(240, 90, 90)

	toggle.Text = systemEnabled and "ON" or "OFF"
	toggle.BackgroundColor3 = systemEnabled
		and Color3.fromRGB(65, 115, 255)
		or Color3.fromRGB(65, 70, 90)

	keybindTag.Text = waitingForKeybind and "Press Key" or ("Key: " .. keybind.Name)

	if lockedTarget and validTarget(lockedTarget) then
		targetLabel.Text = "Target: " .. lockedTarget.Name
	else
		targetLabel.Text = "Target: None"
	end

	updateSlider()
end

toggle.MouseButton1Click:Connect(function()
	systemEnabled = not systemEnabled

	if not systemEnabled then
		lockEnabled = false
		lockedTarget = nil
	end

	updateUI()
end)

keybindTag.MouseButton1Click:Connect(function()
	waitingForKeybind = true
	keybindTag.Text = "Press Key"
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if waitingForKeybind then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keybind = input.KeyCode
			waitingForKeybind = false
			updateUI()
		end
		return
	end

	if systemEnabled and input.UserInputType == Enum.UserInputType.Keyboard
		and input.KeyCode == keybind then

		lockEnabled = not lockEnabled

		if lockEnabled then
			lockedTarget = closestTarget()
		else
			lockedTarget = nil
		end

		updateUI()
	end
end)

-- Draggable top bar
local dragging = false
local dragStart
local startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

RunService.RenderStepped:Connect(function()
	if not systemEnabled or not lockEnabled then
		return
	end

	if not validTarget(lockedTarget) then
		lockedTarget = closestTarget()
		updateUI()
	end

	if lockedTarget and validTarget(lockedTarget) then
		local head = lockedTarget.Character:FindFirstChild("Head")

		if head then
			local camPos = camera.CFrame.Position
			local targetCF = CFrame.lookAt(camPos, head.Position)

			camera.CFrame = camera.CFrame:Lerp(targetCF, smoothness)
		end
	end
end)

updateUI()
