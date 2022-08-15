
local myname, Cork = ...
local SpellCastableOnUnit = Cork.SpellCastableOnUnit
local ldb, ae, ah = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0"), LibStub("AceHook-3.0")

local IconLine = Cork.IconLine("Interface\\Icons\\Ability_Marksmanship", "Unspent talent points")
Cork.defaultspc["Talents-enabled"] = true

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(
  "Cork Talents",
  {type = "cork", tiptext = "Warn when you have unspent talent points."}
)

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	function dataobj:Init()
		if Cork.dbpc["Talents-enabled"] then MicroButtonPulseStop(TalentMicroButton) end
	end
end

local function talentlesshack()
	local numPoints = GetNumUnspentTalents and GetNumUnspentTalents() or UnitCharacterPoints("player")
 	return numPoints > 0
end
local function Test()
  return Cork.dbpc["Talents-enabled"] and talentlesshack() and IconLine
end

function dataobj:Scan() dataobj.player = Test() end

ae.RegisterEvent("Cork Talents", "CHARACTER_POINTS_CHANGED", dataobj.Scan)
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
	ae.RegisterEvent("Cork Talents", "SPELLS_CHANGED", dataobj.Scan)
else
	ae.RegisterEvent("Cork Talents", "PLAYER_TALENT_UPDATE", dataobj.Scan)
	ae.RegisterEvent("Cork Talents", "ACTIVE_TALENT_GROUP_CHANGED", dataobj.Scan)
end

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	ah:RawHook(TalentMicroButton, "EvaluateAlertVisibility", function(this)
		local response = ah.hooks[this].EvaluateAlertVisibility(this)
		if response then
			if Cork.dbpc["Talents-enabled"] then
				MicroButtonPulseStop(this)
				this.suggestedTab = nil
				response = false
			end
		end
		return response
	end, true)
end
