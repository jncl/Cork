-- luacheck: ignore 212 (unused argument)
local _, ns = ...
local _G = _G

local _, ae = _G.LibStub:GetLibrary("LibDataBroker-1.1"), _G.LibStub("AceEvent-3.0")

local GetContainerNumSlots = _G.C_Container and _G.C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
local GetContainerItemID = _G.C_Container and _G.C_Container.GetContainerItemID or _G.GetContainerItemID

local dataobj    = ns:New("Capsules")
dataobj.tiptext  = "Notify you when you have items that grant a boon when used"
dataobj.corktype = "item"
dataobj.priority = 9

function dataobj:Init()
	ns.defaultspc[self.name .. "-enabled"] = true
end

local OPENABLE_IDS = {
	[139020] = true, -- Valarjar Insignia
	[139021] = true, -- Dreamweaver Insignia
	[139023] = true, -- Court of Farondis Insignia
	[139024] = true, -- Highmountain Tribe Insignia
	[139025] = true, -- Wardens Insignia
	[139026] = true, -- Nightfallen Insignia
	[139390] = true, -- Artifact Research Notes
	[140260] = true, -- Arcane Remnant of Falanaar
	[141870] = true, -- Arcane Tablet of Falanaar
	[141987] = true, -- Greater Valarjar Insignia
	[141988] = true, -- Greater Dreamweaver Insignia
	[141989] = true, -- Greater Court of Farondis Insignia
	[141990] = true, -- Greater Highmountain Tribe Insignia
	[141991] = true, -- Greater Wardens Insignia
	[141992] = true, -- Greater Nightfallen Insignia
}

local itemid
local function Test()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			itemid = GetContainerItemID(bag, slot)
			if itemid and OPENABLE_IDS[itemid] then return itemid, bag, slot end
			-- if itemid and OPENABLE_IDS[itemid] then return itemid end
		end
	end
end

local lastid, num, itemname, texture
function dataobj:Scan()
	if not ns.dbpc[self.name.."-enabled"] then
		self.player = nil
		return
	end

	lastid = Test()
	if lastid then
		num = _G.GetItemCount(lastid)
		itemname, _, _, _, _, _, _, _, _, texture = _G.GetItemInfo(lastid)
		if itemname ~= nil then
			self.player = ns.IconLine(texture, itemname.. " (".. num.. ")")
		else
			-- we probably haven't seen the item yet so it's not cached
			self.player = nil
		end
	else
		self.player = nil
	end
end

ae.RegisterEvent(dataobj, "BAG_UPDATE_DELAYED", "Scan")

function dataobj:CorkIt(frame)
	if lastid then
		return frame:SetManyAttributes("type1", "item", "item1", itemname)
		-- return frame:SetManyAttributes("type1", "item", "item1", bag .. " " .. slot)
		-- return frame:SetManyAttributes("type1", "item", "item1", "item:" .. lastid)
	end
end
