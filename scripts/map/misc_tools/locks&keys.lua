---- KoreanWaffle's LOCK/KEY initialization code. Mostly for Magma Biome for now.
local LOCKS = GLOBAL.LOCKS
local KEYS = GLOBAL.KEYS
local LOCKS_KEYS = GLOBAL.LOCKS_KEYS
-- keys
local keycount = 0
for k, v in pairs(KEYS) do
    keycount = keycount + 1
end


local function AddKey(name)
    keycount = keycount + 1
    KEYS[string.upper(name)] = keycount
end

local _keys = {
    "magma_caves",
    "magma_caves_tier1",
    "magma_caves_tier2",
    "magma_caves_tier3",
    "magma_caves_entrance",
    "magma_caves_sacred",
    "active_lava_zone",
    "grotto_tier1",
    "grotto_tier2",
    "grotto_tier3",
    "grotto_tier4"
}

for _, key in pairs(_keys) do
    AddKey(key)
end


-- locks
local lockcount = 0
for k, v in pairs(LOCKS) do
    lockcount = lockcount + 1
end

local function AddLock(name)
    lockcount = lockcount + 1
    LOCKS[string.upper(name)] = lockcount
end

local _locks = {
    "magma_caves",
    "magma_caves_tier1",
    "magma_caves_tier2",
    "magma_caves_tier3",
    "magma_caves_entrance",
    "magma_caves_sacred",
    "active_lava_zone",
    "grotto_tier1",
    "grotto_tier2",
    "grotto_tier3",
    "grotto_tier4"
}

for _, lock in pairs(_locks) do
    AddLock(lock)
end

-- link locks to keys
local function LinkLockKey(lock, keys)
    local __keys = {}

    if keys == nil then keys = lock end

    if type(keys) == "table" then
        for k, v in pairs(keys) do
            table.insert(__keys, KEYS[string.upper(v)])
        end
    else
        table.insert(__keys, KEYS[string.upper(keys)])
    end

    LOCKS_KEYS[LOCKS[string.upper(lock)]] = __keys
end

local _lock_n_keys = {
    "magma_caves",
    "magma_caves_entrance",
    "active_lava_zone",
    "magma_caves_sacred",
    ["grotto_tier1"] = { "grotto_tier1", "grotto_tier2" },
    ["grotto_tier2"] = { "grotto_tier2", "grotto_tier3" },
    ["grotto_tier3"] = { "grotto_tier3", "grotto_tier4" },
    "grotto_tier4"
}

for k, v in pairs(_lock_n_keys) do
    if type(k) == "number" then
        k = v
        v = nil
    end

    LinkLockKey(k, v)
end

