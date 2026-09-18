local g = Instance.new("ScreenGui")
g.Name = "TestGui456"
g.Parent = game:GetService("Players").LocalPlayer.PlayerGui
for i = 1, 500 do
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 100, 0, 30)
    f.Parent = g
    local t = Instance.new("TextLabel")
    t.Text = "Option " .. i
    t.Parent = f
end
print("done")
