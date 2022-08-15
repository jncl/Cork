if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local myname, Cork = ...
if Cork.MYCLASS ~= "WARLOCK" then return end


local myname, Cork = ...
local IconLine = Cork.IconLine
local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")


local soulburn = GetSpellInfo(74434) --19393
--
local knowssoulburn
local spellidlist = {688, 697, 712, 691, 1122, 30146, 157757} -- imp, voidwalker, succubus, felhunter, infernal
local buffnames, icons, known = {}, {}, {}
for _,id in pairs(spellidlist) do
	local spellname, _, icon = GetSpellInfo(id)
	_G.print("Warlock Pets", spellname, icon)
	if spellname then
		buffnames[id], icons[spellname] = spellname, icon
	end
end

Cork.defaultspc["Summon demon-spell"] = buffnames[spellidlist[1]]

local dataobj = ldb:NewDataObject("Cork Summon demon", {type = "cork"})

local function RefreshKnownSpells() -- Refresh in case the player has learned this since login
	for buff in pairs(icons) do if known[buff] == nil then known[buff] = GetSpellInfo(buff) end end
end

function dataobj:Init() RefreshKnownSpells() Cork.defaultspc["Summon demon-enabled"] = known[buffnames[spellidlist[1]]] ~= nil end
function dataobj:Scan()
	_G.print("WP Scan", Cork.dbpc["Summon demon-spell"])
	if IsMounted() or not Cork.dbpc["Summon demon-enabled"] or UnitExists("pet") then dataobj.player = nil
	else dataobj.player = IconLine(icons[Cork.dbpc["Summon demon-spell"]], Cork.dbpc["Summon demon-spell"]) end

end

ae.RegisterEvent("Cork Summon demon", "UNIT_PET", function(event, unit) if unit == "player" then dataobj:Scan() end end)
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	ae.RegisterEvent("Cork mount check", "COMPANION_UPDATE", function(event, type) if type == "MOUNT" then dataobj:Scan() end end)
end
function dataobj:CorkIt(frame)
	if self.player then
		knowssoulburn = knowssoulburn or GetSpellInfo(soulburn)
		if knowssoulburn then
			return frame:SetManyAttributes("type1", "macro", "macrotext1", "/cast ".. soulburn.. "\n/cast ".. Cork.dbpc["Summon demon-spell"])
		else
			return frame:SetManyAttributes("type1", "spell", "spell", Cork.dbpc["Summon demon-spell"])
		end
	end
end


----------------------
--      Config      --
----------------------

local frame = CreateFrame("Frame", nil, Cork.config)
frame:SetWidth(1) frame:SetHeight(1)
dataobj.configframe = frame
frame:Hide()

frame:SetScript("OnShow", function()
	local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 16, 18, 2, 4
	local buffbuttons = {}

	local function OnClick(self)
		Cork.dbpc["Summon demon-spell"] = self.buff
		for buff,butt in pairs(buffbuttons) do butt:SetChecked(butt == self) end
		dataobj:Scan()
	end

	local function OnEnter(self)
		_G.print("WP OnEnter", self.buff, GetSpellLink(self.buff))
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(GetSpellLink(self.buff))
	end
	local function OnLeave() GameTooltip:Hide() end


	local lasticon
	for _,id in ipairs(spellidlist) do
		local buff = buffnames[id]

		local butt = CreateFrame("CheckButton", nil, frame)
		butt:SetWidth(ROWHEIGHT) butt:SetHeight(ROWHEIGHT)

		local tex = butt:CreateTexture(nil, "BACKGROUND")
		tex:SetAllPoints()
		tex:SetTexture(icons[buff])
		tex:SetTexCoord(4/48, 44/48, 4/48, 44/48)
		butt.icon = tex

		butt:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		butt:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		butt:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")

		if lasticon then lasticon:SetPoint("RIGHT", butt, "LEFT", -ROWGAP, 0) end

		butt.buff = buff
		butt:SetScript("OnClick", OnClick)
		butt:SetScript("OnEnter", OnEnter)
		butt:SetScript("OnLeave", OnLeave)

		buffbuttons[buff], lasticon = butt, butt
	end
	lasticon:SetPoint("RIGHT", 0, 0)

	local function Update(self)
		RefreshKnownSpells()

		for buff,butt in pairs(buffbuttons) do
			butt:SetChecked(Cork.dbpc["Summon demon-spell"] == buff)
			if known[buff] then
				butt:Enable()
				butt.icon:SetVertexColor(1.0, 1.0, 1.0)
			else
				butt:Disable()
				butt.icon:SetVertexColor(0.4, 0.4, 0.4)
			end
		end
	end

	frame:SetScript("OnShow", Update)
	Update(frame)
end)
