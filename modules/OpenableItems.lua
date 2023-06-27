
local _, ns = ...

local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")

local GetContainerNumSlots = _G.C_Container and _G.C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
local GetContainerItemID = _G.C_Container and _G.C_Container.GetContainerItemID or _G.GetContainerItemID

local dataobj    = ns:New("Openable items")
dataobj.tiptext  = "Notify you when there are openable containers in your bags"
dataobj.corktype = "item"
dataobj.priority = 8


function dataobj:Init()
	ns.defaultspc[self.name.."-enabled"] = true
end


local OPEN_CLAM = "Use: Open the clam!"
local openable_ids = {
	[120301] = true, -- Armor Enhancement Token
	[120302] = true, -- Weapon Enhancement Token
}
local function IsOpenable(bag, slot, id)
	if openable_ids[id] ~= nil then return openable_ids[id] end

	if _G.C_TooltipInfo and _G.C_TooltipInfo.GetBagItem then
		local tooltipData = _G.C_TooltipInfo.GetBagItem(bag, slot)
		if tooltipData then
			_G.TooltipUtil.SurfaceArgs(tooltipData)
			for i = 1, 5 do
				if tooltipData.lines[i] == RETRIEVING_ITEM_INFO then return false end
				if tooltipData.lines[i] == ITEM_OPENABLE
				or tooltipData.lines[i] == OPEN_CLAM
				then
					openable_ids[id] = true
					return true
				end
			end
			-- info[4] = tooltipData.repairCost and tooltipData.repairCost or 0
		end
	else
		ns.scantip:SetBagItem(bag, slot)
		for i=1,5 do
			if ns.scantip.L[i] == RETRIEVING_ITEM_INFO then return false end
			if ns.scantip.L[i] == ITEM_OPENABLE or ns.scantip.L[i] == OPEN_CLAM then
				openable_ids[id] = true
				return true
			end
		end
	end
	openable_ids[id] = false
	return false
end


local function Test()
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local itemid = GetContainerItemID(bag, slot)
			if itemid and IsOpenable(bag, slot, itemid) then return itemid end
		end
	end
end


local lastid
function dataobj:Scan()
	if not ns.dbpc[self.name.."-enabled"] then
		self.player = nil
		return
	end

	lastid = Test()
	if lastid then
		local num = GetItemCount(lastid)
		local itemname, _, _, _, _, _, _, _, _, texture = GetItemInfo(lastid)
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


function dataobj:CorkIt(frame) -- luacheck: ignore self
	if lastid then
		return frame:SetManyAttributes("type1", "item", "item1", "item:"..lastid)
	end
end
