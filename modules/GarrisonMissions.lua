
local myname, ns = ...
local level = UnitLevel("player")
local ae = LibStub("AceEvent-3.0")


-- Items only available when you have a lvl3 garrison
if level < 90 then return end


local name = "Completed missions"
local iconline = ns.IconLine("Interface\\ICONS\\achievement_raregarrisonquests_x", name)


local dataobj    = ns:New(name)
dataobj.tiptext  = "Notify you when you are in your garrison and have completed missions"
dataobj.priority = 20
ns.defaultspc[name.."-enabled"] = true


local function Test(force)
	if not ns.InGarrison() then return end

	if force then return true end

	local items = C_Garrison.GetLandingPageItems(LE_GARRISON_TYPE_6_0)
	for i,item in ipairs(items) do
		if item.isComplete and not item.isBuilding then return true end
	end
end


function dataobj:Scan(event, ...)
	local force = event == "GARRISON_MISSION_FINISHED"

	if ns.dbpc[self.name.."-enabled"] and Test(force) then
		self.player = iconline
	else
		self.player = nil
	end
end


ae.RegisterEvent(dataobj, "ZONE_CHANGED", "Scan")
ae.RegisterEvent(dataobj, "GARRISON_MISSION_NPC_CLOSED", "Scan")
ae.RegisterEvent(dataobj, "GARRISON_MISSION_FINISHED", "Scan")
