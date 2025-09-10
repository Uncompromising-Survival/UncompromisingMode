---- KoreanWaffle's LOCK/KEY initialization code. Mostly for Magma Biome for now.
local LOCKS = GLOBAL.LOCKS
local KEYS = GLOBAL.KEYS
local LOCKS_KEYS = GLOBAL.LOCKS_KEYS
-- keys
local keycount = 0
for k, v in pairs(KEYS) do
	keycount = keycount + 1
end
KEYS["MAGMA_CAVES"] = keycount + 1
KEYS["MAGMA_CAVES_TIER1"] = keycount + 1
KEYS["MAGMA_CAVES_TIER2"] = keycount + 1
KEYS["MAGMA_CAVES_TIER3"] = keycount + 1
KEYS["MAGMA_CAVES_ENTRANCE"] = keycount + 1

-- locks
local lockcount = 0
for k, v in pairs(LOCKS) do
	lockcount = lockcount + 1
end
LOCKS["MAGMA_CAVES"] = lockcount + 1
LOCKS["MAGMA_CAVES_TIER1"] = lockcount + 1
LOCKS["MAGMA_CAVES_TIER2"] = lockcount + 1
LOCKS["MAGMA_CAVES_TIER3"] = lockcount + 1
LOCKS["MAGMA_CAVES_ENTRANCE"] = lockcount + 1

-- link keys to locks
LOCKS_KEYS[LOCKS.MAGMA_CAVES] = { KEYS.MAGMA_CAVES}
LOCKS_KEYS[LOCKS.MAGMA_CAVES_TIER1] = { KEYS.MAGMA_CAVES_TIER1}
LOCKS_KEYS[LOCKS.MAGMA_CAVES_TIER2] = { KEYS.MAGMA_CAVES_TIER2}
LOCKS_KEYS[LOCKS.MAGMA_CAVES_TIER3] = { KEYS.MAGMA_CAVES_TIER3}
LOCKS_KEYS[LOCKS.MAGMA_CAVES_ENTRANCE] = { KEYS.MAGMA_CAVES_ENTRANCE}