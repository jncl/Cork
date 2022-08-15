local myname, Cork = ...
if Cork.MYCLASS ~= "DEATHKNIGHT" then return end

-- Path of Frost
local spellname, _, icon = GetSpellInfo(3714)
Cork:GenerateSelfBuffer(spellname, icon)


-- Horn of Winter
local spellname, _, icon = GetSpellInfo(57330)
local str_earth = GetSpellInfo(58646) -- Strength of Earth
Cork:GenerateSelfBuffer(spellname, icon, str_earth)
