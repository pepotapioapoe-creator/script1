-- TRIDENT_FIND2 (Real): lee el entorno de los modulos de entidades. Vivo, cerca de otros.
local want = {EntityClient = true, PlayerNPCShared = true, PlayerClient = true,
    PhysicsReplicatorClient = true, Character = true, NPCClient = true,
    PlaceEntityClient = true, EntityGhosts = true, Spawner = true}
if type(getloadedmodules) ~= "function" or type(getsenv) ~= "function" then
    print("sin getloadedmodules/getsenv")
    return
end
local okM, mods = pcall(getloadedmodules)
if not okM or type(mods) ~= "table" then print("mods fallo") return end
for _, m in ipairs(mods) do
    if m and want[m.Name] then
        print("=== ENV:", m.Name, "===")
        local okE, env = pcall(getsenv, m)
        if not okE or type(env) ~= "table" then
            print("  getsenv fallo")
        else
            local n = 0
            for k, v in pairs(env) do
                n = n + 1
                if n <= 45 then
                    local t = typeof(v)
                    local extra = ""
                    if t == "table" then
                        local c = 0
                        for _ in pairs(v) do c = c + 1 if c > 5 then break end end
                        extra = "keys~" .. c
                    elseif t == "Instance" then
                        extra = v.ClassName .. ":" .. v.Name
                    else
                        extra = tostring(v):sub(1, 40)
                    end
                    print("  " .. tostring(k) .. " [" .. t .. "] " .. extra)
                end
            end
            print("  total keys:", n)
        end
    end
end
print("FIN FIND2")
