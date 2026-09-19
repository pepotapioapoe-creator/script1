-- TRIDENT_FIND (ideal Real con hooks): encuentra cuerpos por estructura + GC + modulos.
-- Vivo, cerca de otros. Solo LEE, no instala nada.
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local function pathOf(inst)
    local path = inst.Name
    local par = inst.Parent
    local ups = 0
    while par and par ~= workspace and par ~= game and ups < 8 do
        path = par.Name .. "/" .. path
        par = par.Parent
        ups = ups + 1
    end
    return path
end
local function isBodyLike(m)
    if not m or not m:IsA("Model") then return false end
    if m.Name == "FPSArms" or m.Name == "LocalCharacter" or m.Name == "HLPart" then return false end
    if not m:FindFirstChild("Head", true) then return false end
    if not m:FindFirstChild("Torso", true) then return false end
    local np = 0
    for _, q in ipairs(m:GetDescendants()) do
        if q:IsA("BasePart") then np = np + 1 if np >= 6 then break end end
    end
    return np >= 6
end
print("=== A: cuerpos por estructura ===")
local foundA, seenA = 0, 0
for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Model") then
        seenA = seenA + 1
        if seenA > 1500 then break end
        if isBodyLike(d) then
            foundA = foundA + 1
            if foundA <= 20 then print("BODY:", pathOf(d)) end
        end
    end
end
print("A total:", foundA, "| modelos vistos:", seenA)
print("=== B: GC (quien referencia cuerpos) ===")
if type(getgc) ~= "function" or type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then
    print("sin getgc/debug en este executor (solo parte A)")
else
    local all = getgc()
    print("objetos GC:", #all)
    local checked, hits = 0, 0
    for _, v in ipairs(all) do
        if hits >= 10 then break end
        if type(v) == "function" then
            checked = checked + 1
            if checked > 2500 then break end
            local okU, ups = pcall(debug.getupvalues, v)
            if okU and type(ups) == "table" then
                for _, uv in pairs(ups) do
                    if typeof(uv) == "Instance" and isBodyLike(uv) then
                        local okI, nm = pcall(debug.info or function() return "?" end, v, "n")
                        print("HIT func:", tostring(nm), "| cuerpo:", pathOf(uv))
                        hits = hits + 1
                        break
                    end
                end
            end
        end
    end
    print("B funcs revisadas:", checked, "| hits:", hits)
end
print("=== C: modulos interesantes ===")
if type(getloadedmodules) == "function" then
    local okM, mods = pcall(getloadedmodules)
    if okM and type(mods) == "table" then
        local n = 0
        for _, m in ipairs(mods) do
            local nm = tostring(m and m.Name or "?"):lower()
            if nm:find("play") or nm:find("char") or nm:find("body") or nm:find("net")
            or nm:find("spawn") or nm:find("replic") or nm:find("entity") or nm:find("npc") then
                n = n + 1
                if n <= 30 then print("mod:", m.Name) end
            end
        end
        print("C total mods:", #mods, "| match:", n)
    else
        print("getloadedmodules fallo")
    end
else
    print("sin getloadedmodules")
end
print("FIN FIND")
