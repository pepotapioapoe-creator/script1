local g = Instance.new("ScreenGui")
g.Name = "TestGui789"
g.Parent = game:GetService("Players").LocalPlayer.PlayerGui
local words = {"Aimbot","Silent Aim","ESP","Triggerbot","Wallbang","Hitbox","Spinbot","Fly","Noclip","Speed","Silent","Magic","ZVOLT","Fling","Troll"}
for i, w in ipairs(words) do
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0, 200, 0, 20)
    t.Position = UDim2.new(0, 10, 0, i * 22)
    t.Text = w
    t.Parent = g
end
print("done-b")
