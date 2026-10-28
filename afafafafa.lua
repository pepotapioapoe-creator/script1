local RS = game:GetService("ReplicatedStorage")
local rem = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("GunFramework") and RS.Modules.GunFramework:FindFirstChild("Remotes")
print("Remotes folder:", rem and "SI" or "NO")
if rem then
    for _, v in ipairs(rem:GetChildren()) do
        print("  remote:", v.Name, "|", v.ClassName)
    end
end
local pos = rem and (rem:FindFirstChild("Position") or rem:FindFirstChildWhichIsA("RemoteEvent"))
print("hookfunction:", type(hookfunction) == "function")
local ok, old = pcall(hookfunction, rem.Position.FireServer, function(self, ...) print("HOOK VIVO! nargs:", select("#", ...)) return old(self, ...) end)
print("hook install:", ok)
