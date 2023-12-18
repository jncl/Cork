local _, ns = ...
local _G = _G

local _, ae = _G.LibStub:GetLibrary("LibDataBroker-1.1"), _G.LibStub("AceEvent-3.0")

local GetContainerNumSlots = _G.C_Container and _G.C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
local GetContainerItemID   = _G.C_Container and _G.C_Container.GetContainerItemID or _G.GetContainerItemID

local dataobj    = ns:New("Openable items")
dataobj.tiptext  = "Notify you when there are openable containers in your bags"
dataobj.corktype = "item"
dataobj.priority = 8


function dataobj:Init()
	ns.defaultspc[self.name .. "-enabled"] = true
end

local OPEN_CLAM = "Use: Open the clam!"
local openable_ids = {
	[120301] = true, -- Armor Enhancement Token
	[120302] = true, -- Weapon Enhancement Token
	-- Dragonflight
	[198868] = true, -- Small Valdraken Accord Supply Pack
	[205423] = true, -- Shadowflame Residue Sack
	[205247] = true, -- Clinking Dirt-Covered Pouch
}

local function IsOpenable(bag, slot, id)
	if openable_ids[id] ~= nil then return openable_ids[id] end

	if _G.C_TooltipInfo and _G.C_TooltipInfo.GetBagItem then
		local tooltipData = _G.C_TooltipInfo.GetBagItem(bag, slot)
		if tooltipData then
			_G.TooltipUtil.SurfaceArgs(tooltipData)
			for _, line in _G.ipairs(tooltipData.lines) do
				if line.leftText == _G.RETRIEVING_ITEM_INFO then return false end
				if line.leftText == _G.ITEM_OPENABLE
				or line.leftText == OPEN_CLAM
				then
					openable_ids[id] = true
					return true
				end
			end
		end
	else
		ns.scantip:SetBagItem(bag, slot)
		for i = 1, 5 do
			if ns.scantip.L[i] == _G.RETRIEVING_ITEM_INFO then return false end
			if ns.scantip.L[i] == _G.ITEM_OPENABLE
			or ns.scantip.L[i] == OPEN_CLAM
			then
				openable_ids[id] = true
				return true
			end
		end
	end
	openable_ids[id] = false
	return false
end

local function Test()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemid = GetContainerItemID(bag, slot)
			if itemid and IsOpenable(bag, slot, itemid) then return itemid end
			-- if itemid and IsOpenable(bag, slot, itemid) then return itemid end
		end
	end
end

local lastid, num, itemname, texture
function dataobj:Scan()
	if not ns.dbpc[self.name .. "-enabled"] then
		self.player = nil
		return
	end

	lastid = Test()
	if lastid then
		num = _G.GetItemCount(lastid)
		itemname, _, _, _, _, _, _, _, _, texture = _G.GetItemInfo(lastid)
		if itemname ~= nil then
			self.player = ns.IconLine(texture, itemname .. " (" .. num .. ")")
		else
			-- we probably haven't seen the item yet so it's not cached
			self.player = nil
		end
	else
		self.player = nil
	end
end

ae.RegisterEvent(dataobj, "BAG_UPDATE_DELAYED", "Scan")

function dataobj:CorkIt(frame) -- luacheck: ignore 212 (unused argument)
	if lastid then
		return frame:SetManyAttributes("type1", "item", "item1", "item:" .. lastid)
	end
end
