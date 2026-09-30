-- Camera Lock + Smoothness Slider
-- For your own Roblox Studio experience.
-- Place/use as a LocalScript under StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local smoothness = 0.20
local minSmoothness = 0.15
local maxSmoothness = 1.00

local locked = false
local target = nil

local gui = Instance.new("ScreenGui")
gui.Name = "CameraLockGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 150)
frame.Position = UDim2.new(0.5, -130, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Text = "Camera Lock"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = frame

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, -20, 0, 25)
valueLabel.Position = UDim2.fromOffset(10, 42)
valueLabel.BackgroundTransparency = 1
valueLabel.TextColor3 = Color3.new(1, 1, 1)
valueLabel.TextSize = 14
valueLabel.Font = Enum.Font.Gotham
valueLabel.Text = "Smoothness: 0.20"
valueLabel.Parent = frame

local slider = Instance.new("Frame")
slider.Size = UDim2.new(1, -40, 0, 8)
slider.Position = UDim2.fromOffset(20, 73)
slider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
slider.BorderSizePixel = 0
slider.Parent = frame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = slider

local fill = Instance.new("Frame")
fill.Size = UDim2.new(
	(smoothness - minSmoothness) / (maxSmoothness - minSmoothness),
	0, 1, 0
)
fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fill.BorderSizePixel = 0
fill.Parent = slider

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local knob = Instance.new("TextButton")
knob.Size = UDim2.fromOffset(16, 16)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(
	(smoothness - minSmoothness) / (maxSmoothness - minSmoothness),
	0, 0.5, 0
)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.Text = ""
knob.AutoButtonColor = false
knob.Parent = slider

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = knob

local lockButton = Instance.new("TextButton")
lockButton.Size = UDim2.fromOffset(105, 32)
lockButton.Position = UDim2.fromOffset(15, 105)
lockButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
lockButton.TextColor3 = Color3.new(1, 1, 1)
lockButton.Text = "Lock Camera"
lockButton.TextSize = 13
lockButton.Font = Enum.Font.GothamBold
lockButton.Parent = frame

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 7)
lockCorner.Parent = lockButton

local exitButton = Instance.new("TextButton")
exitButton.Size = UDim2.fromOffset(105, 32)
exitButton.Position = UDim2.fromOffset(140, 105)
exitButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
exitButton.TextColor3 = Color3.new(1, 1, 1)
exitButton.Text = "Exit"
exitButton.TextSize = 13
exitButton.Font = Enum.Font.GothamBold
exitButton.Parent = frame

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 7)
exitCorner.Parent = exitButton

local function getNearestPlayer()
	local nearest
	local nearestDistance = math.huge

	local character = player.Character
	if not character then return nil end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")

			if otherRoot and humanoid and humanoid.Health > 0 then
				local distance = (root.Position - otherRoot.Position).Magnitude

				if distance < nearestDistance then
					nearestDistance = distance
					nearest = otherPlayer
				end
			end
		end
	end

	return nearest
end

local dragging = false

local function updateSlider(inputX)
	local relative = math.clamp(
		(inputX - slider.AbsolutePosition.X) / slider.AbsoluteSize.X,
		0, 1
	)

	smoothness = minSmoothness + (maxSmoothness - minSmoothness) * relative
	smoothness = math.floor(smoothness * 100 + 0.5) / 100

	fill.Size = UDim2.new(relative, 0, 1, 0)
	knob.Position = UDim2.new(relative, 0, 0.5, 0)
	valueLabel.Text = string.format("Smoothness: %.2f", smoothness)
end

knob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
	end
end)

slider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		updateSlider(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		updateSlider(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

lockButton.MouseButton1Click:Connect(function()
	if locked then
		locked = false
		target = nil
		lockButton.Text = "Lock Camera"
	else
		target = getNearestPlayer()

		if target then
			locked = true
			lockButton.Text = "Unlock Camera"
		end
	end
end)

exitButton.MouseButton1Click:Connect(function()
	locked = false
	target = nil

	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end

	gui:Destroy()
end)

RunService.RenderStepped:Connect(function()
	if not locked or not target then return end

	local character = target.Character
	if not character then
		locked = false
		target = nil
		return
	end

	local targetPart = character:FindFirstChild("Head")
	if not targetPart then return end

	local targetCF = CFrame.lookAt(
		camera.CFrame.Position,
		targetPart.Position
	)

	camera.CFrame = camera.CFrame:Lerp(targetCF, smoothness)
end)
