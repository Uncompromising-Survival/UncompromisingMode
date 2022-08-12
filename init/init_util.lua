--currently only used for IA, but if we ever need more advanced mod checks, put 'em here!


local env = env
GLOBAL.setfenv(1, GLOBAL)

--instead of checking for the mod, this checks for the world's tags, which should make it more compatible with 4-shard worlds.
--it still has a mod check for when TheWorld is still nil, such as postinits adding stuff like snowstorms.
function TestForIA()
    if TheWorld ~= nil and (TheWorld:HasTag("volcano") or TheWorld:HasTag("island")) then
        print("TheWorld island/volcano check")
        return true
    elseif KnownModIndex:IsModEnabled("workshop-1467214795") then
        print("mod check")
        return true
    else
        print("all checks passed.")
        return false
    end
end