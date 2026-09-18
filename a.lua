local ok, msg = pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(...) return old(...) end)
    print("HOOKS OK")
end)
if not ok then print("HOOKS FAIL:", msg) end
