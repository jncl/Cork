
local myname, Cork = ...
if Cork.MYCLASS ~= "ROGUE" then return end

local ae = LibStub("AceEvent-3.0")


local mainhand = GetInventorySlotInfo("MainHandSlot")
local onehandtypes = {
	INVTYPE_WEAPON = true,
	INVTYPE_WEAPONMAINHAND = true,
	INVTYPE_WEAPONOFFHAND = true,
}


local function UNIT_INVENTORY_CHANGED(self, event, unit)
	if unit == 'player' then self:Scan() end
end


local function Test(self, ...)
	local id = GetInventoryItemID('player', mainhand)
	if not id then return end

	local _, _, _, _, _, _, _, _, slot = GetItemInfo(id)
	if not slot or not onehandtypes[slot] then return end

	return self.oldtest(...)
end

local dataobj
-- Damage poisons
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	dataobj = Cork:GenerateAdvancedSelfBuffer("Lethal Poison", {2823, 8679, 315584}) -- Deadly, Wound, Instant
else
	dataobj = Cork:GenerateAdvancedSelfBuffer("Lethal Poison", {2823, 13218, 59242}) -- Deadly, Wound, Instant
end
dataobj.oldtest = dataobj.Test
dataobj.Test = Test
dataobj.UNIT_INVENTORY_CHANGED = UNIT_INVENTORY_CHANGED
dataobj.CanCorkStealthed = true
ae.RegisterEvent(dataobj, "UNIT_INVENTORY_CHANGED")


-- Utility poisons
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	dataobj = Cork:GenerateAdvancedSelfBuffer("Non-Lethal Poison", {3408, 5761, 108211}) -- Crippling, Numbing, Leeching
else
	dataobj = Cork:GenerateAdvancedSelfBuffer("Non-Lethal Poison", {3409}) -- Crippling
end
dataobj.oldtest = dataobj.Test
dataobj.Test = Test
dataobj.UNIT_INVENTORY_CHANGED = UNIT_INVENTORY_CHANGED
dataobj.CanCorkStealthed = true
ae.RegisterEvent(dataobj, "UNIT_INVENTORY_CHANGED")
