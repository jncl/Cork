-- luacheck: ignore 111 112 113 631 (setting non-standard global variable|mutating non-standard global variable|accessing undefined variable|line is too long)
local _, Cork = ...
local _G = _G

if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then
	Cork.isRtl = true
elseif _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC then
	Cork.isClscERA = true
else
	Cork.isClsc = true
end

local ldb, ae = _G.LibStub:GetLibrary("LibDataBroker-1.1"), _G.LibStub("AceEvent-3.0")
local _

_, Cork.MYCLASS = _G.UnitClass("player")

Cork.corks, Cork.db, Cork.dbpc, Cork.defaultspc = {}, {}, {}, {}
Cork.sortedcorks = {}

local defaults = {point = "TOP", x = 0, y = -100, showanchor = true, debug = false, bindwheel = false}
local tooltip, anchor

for i = 1, _G.MAX_BOSS_FRAMES do Cork.keyblist["boss"..i] = true end

------------------------------
--      Initialization      --
------------------------------

ae.RegisterEvent("Cork", "ADDON_LOADED", function(_, addon)
	if addon:lower() ~= "cork" then return end

	CorkDB = _G.setmetatable(CorkDB or {}, {__index = defaults})
	CorkDBPC = CorkDBPC or {{},{},{},{}}
	if not CorkDBPC[1] then CorkDBPC = {CorkDBPC, {}, {}, {}} end
	for _, i in _G.ipairs({2,3,4, 5}) do
		if not CorkDBPC[i] then CorkDBPC[i] = {} end
	end
	Cork.db = CorkDB

	anchor:SetPoint(Cork.db.point, Cork.db.x, Cork.db.y)
	if not Cork.db.showanchor then anchor:Hide() end

	ae.UnregisterEvent("Cork", "ADDON_LOADED")
end)

local meta = {__index = Cork.defaultspc}
ae.RegisterEvent("Cork", "PLAYER_LOGIN", function()
	if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then
		local lastspec = _G.GetSpecialization()
		Cork.dbpc = _G.setmetatable(CorkDBPC[lastspec], meta)
		ae.RegisterEvent("Cork", "PLAYER_TALENT_UPDATE", function()
			if lastspec == _G.GetSpecialization() then return end

			lastspec = _G.GetSpecialization()
			for i, v in _G.pairs(Cork.defaultspc) do if Cork.dbpc[i] == v then Cork.dbpc[i] = nil end end
			Cork.dbpc = _G.setmetatable(CorkDBPC[lastspec], meta)

			if Cork.config.Update then Cork.config:Update() end
			for _, dataobj in _G.pairs(Cork.corks) do if dataobj.Init then dataobj:Init() end end
			for _, dataobj in _G.pairs(Cork.corks) do dataobj:Scan() end
		end)
	end

	for _,dataobj in _G.pairs(Cork.sortedcorks) do if dataobj.Init then dataobj:Init() end end
	for _,dataobj in _G.pairs(Cork.sortedcorks) do dataobj:Scan() end

	ae.RegisterEvent("Cork", "ZONE_CHANGED_NEW_AREA", Cork.Update)

	ae.UnregisterEvent("Cork", "PLAYER_LOGIN")
end)


ae.RegisterEvent("Cork", "PLAYER_LOGOUT", function()
	for i,v in _G.pairs(defaults) do if Cork.db[i] == v then Cork.db[i] = nil end end
	for i,v in _G.pairs(Cork.defaultspc) do if Cork.dbpc[i] == v then Cork.dbpc[i] = nil end end
end)

local onTaxi, petBattle
ae.RegisterEvent("Cork Core", "PLAYER_CONTROL_LOST", function()
	onTaxi = true
	Cork.Update()
end)

ae.RegisterEvent("Cork Core", "PLAYER_CONTROL_GAINED", function()
	onTaxi = nil
	Cork.Update()
end)

ae.RegisterEvent("Cork Core", "UNIT_ENTERED_VEHICLE", function()
	onTaxi = _G.UnitHasVehicleUI('player')
	Cork.Update()
end)
ae.RegisterEvent("Cork Core", "UNIT_EXITED_VEHICLE", function()
	onTaxi = nil
	Cork.Update()
end)

ae.RegisterEvent("Cork Core", "PET_BATTLE_OPENING_START", function()
	petBattle = true
	Cork.Update()
end)
ae.RegisterEvent("Cork Core", "PET_BATTLE_OVER", function()
	petBattle = nil
	Cork.Update()
end)

------------------------------
--      Tooltip anchor      --
------------------------------

anchor = _G.CreateFrame("Button", nil, _G.UIParent, "BackdropTemplate")
anchor:SetHeight(24)
Cork.anchor = anchor

anchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = {left = 5, right = 5, top = 5, bottom = 5}, tile = true, tileSize = 16})
anchor:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
anchor:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

local text = anchor:CreateFontString(nil, nil, "GameFontNormalSmall")
text:SetPoint("CENTER")
text:SetText("Cork")
anchor:SetWidth(text:GetStringWidth() + 8)

anchor:SetMovable(true)
anchor:RegisterForDrag("LeftButton")

anchor:SetScript("OnClick", function(self) _G.InterfaceOptionsFrame_OpenToCategory(Cork.config) end) -- luacheck: ignore 212 (unused argument)

anchor:SetScript("OnDragStart", function(self)
	tooltip:Hide()
	self:StartMoving()
end)

anchor:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	Cork.db.point, Cork.db.x, Cork.db.y = "BOTTOMLEFT", self:GetLeft(), self:GetBottom()
	Cork.Update()
end)

-----------------------
--      Tooltip      --
-----------------------

tooltip = _G.CreateFrame("GameTooltip", "Corkboard", _G.UIParent, "GameTooltipTemplate")
tooltip:SetFrameStrata("MEDIUM")
if Cork.isRtl then
	tooltip.TextLeft1:SetFontObject(_G.GameTooltipText)
	tooltip.TextRight1:SetFontObject(_G.GameTooltipText)
else
	_G.CorkboardTextLeft1:SetFontObject(_G.GameTooltipText)
	_G.CorkboardTextRight1:SetFontObject(_G.GameTooltipText)
end

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", frame, "BOTTOMLEFT" end
	local hhalf = (x > _G.UIParent:GetWidth()*2/3) and "RIGHT" or (x < _G.UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > _G.UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function CorkSorter(a, b)
	return a and b and a.sortname < b.sortname
end

local function SetSort(dataobj)
	local downcase = dataobj.name:lower()
	dataobj.sortname = string.format("%02d %s", (dataobj.priority or 5), downcase)
end

local activecorks, usedcorks = {}, {}
local raidunits = {player = true}
for i = 1, 4 do raidunits["party"..i] = true end
for i = 1, 40 do raidunits["raid"..i] = true end
function Cork.Update(_, _, attr, value, dataobj)
	if attr == "name" then
		Cork.corks[value] = dataobj
	end

	if attr == "priority" or attr == "name" then
		SetSort(dataobj)
		_G.table.sort(Cork.sortedcorks, CorkSorter)
	end

	if Cork.keyblist[attr] then return end

	tooltip:Hide()

	_G.table.wipe(activecorks)
	_G.table.wipe(usedcorks)

	local inbg = _G.GetZonePVPInfo() == "combat" or _G.select(2, _G.IsInInstance()) == "pvp"

	for _, dObj in _G.ipairs(Cork.sortedcorks) do
		if dObj.nobg and inbg then usedcorks[dObj] = true end
	end

	for _, dObj in _G.ipairs(Cork.sortedcorks) do
		if not usedcorks[dObj] and dObj.player then
			_G.table.insert(activecorks, dObj)
			usedcorks[dObj] = true
		end
	end

	for _, dObj in _G.ipairs(Cork.sortedcorks) do
		if not usedcorks[dObj] then
			_G.table.insert(activecorks, dObj)
			usedcorks[dObj] = true
	  end
	end

	tooltip:ClearLines()
	tooltip:SetOwner(anchor, "ANCHOR_NONE")
	tooltip:SetPoint(GetTipAnchor(anchor))

	if Cork.db.showbg or not inbg then
		local count = 0
		for _, dObj in _G.ipairs(activecorks) do
			if not (dObj.nobg and inbg) then
				local inneed, numr, prefix = 0, _G.GetNumGroupMembers(), _G.IsInRaid() and "raid" or "party"
				for i = 1, numr do if dObj.RaidLine and dObj[prefix..i] then inneed = inneed + 1 end end
				if dObj.RaidLine and numr > 0 and dObj["player"] then inneed = inneed + 1 end
				if inneed > 1 and count < 10 then -- Hard limit, show 10 lines at most
					if Cork.db.debug then tooltip:AddDoubleLine(string.format(dObj.RaidLine, inneed), "raid") else tooltip:AddLine(string.format(dObj.RaidLine, inneed)) end
					count = count + 1
				end
				for i, v in ldb:pairs(dObj) do
					if v ~= false and not Cork.keyblist[i] and (inneed <= 1 or not raidunits[i]) and count < 10 then
						if Cork.db.debug then tooltip:AddDoubleLine(v, i) else tooltip:AddLine(v) end
						count = count + 1
					end
				end
			end
		end
	end

	if tooltip:NumLines() > 0 and not onTaxi and not petBattle then
		tooltip:Show()
	end
end

-------------------------
--      LDB stuff      --
-------------------------

local function NewDataobject(_s, name, dataobj)
	if dataobj.type ~= "cork" then return end
	if not dataobj.name then dataobj.name = name:gsub("Cork ", "") end
	SetSort(dataobj)
	Cork.corks[name] = dataobj
	table.insert(Cork.sortedcorks, dataobj)
	table.sort(Cork.sortedcorks, CorkSorter)
	ldb.RegisterCallback("Corker", "LibDataBroker_AttributeChanged_"..name, Cork.Update)
end

ldb.RegisterCallback("Corker", "LibDataBroker_DataObjectCreated", NewDataobject)

function Cork:New(name) -- luacheck: ignore 212 (unused argument)
	return ldb:NewDataObject("Cork " .. name, {type = "cork", name = name})
end

----------------------------
--      Secure frame      --
----------------------------

local secureframe = _G.CreateFrame("Button", "CorkFrame", _G.UIParent, "SecureActionButtonTemplate")

secureframe.SetManyAttributes = function(self, ...)
	for i = 1, select("#", ...), 2 do
		local att, val = select(i, ...)
		if not att then return end
		self:SetAttribute(att, val)
		-- _G.print("SetManyAttributes", att, val)
	end
	return true
end

secureframe:SetScript("PreClick", function(self)
	if onTaxi or _G.InCombatLockdown() then return end
	for _, dataobj in _G.ipairs(activecorks) do
		if dataobj.CorkIt and (not _G.IsStealthed() or dataobj.CanCorkStealthed) and dataobj:CorkIt(self) then return end
	end
end)

secureframe:SetScript("PostClick", function()
	if _G.InCombatLockdown() then return end
	secureframe:SetManyAttributes("type1", _G.ATTRIBUTE_NOOP, "bag1", nil, "slot1", nil, "item1", nil, "spell", nil, "unit", nil, "macrotext1", nil)
end)

--------------------------------
--      Shared functions      --
--------------------------------

function Cork.IsSpellInRange(spell, unit)
	return _G.IsSpellInRange(spell, unit) == 1
end

function Cork.SpellCastableOnUnit(spell, unit)
	return _G.UnitExists(unit) and _G.UnitCanAssist("player", unit) and _G.UnitIsVisible(unit) and _G.UnitIsConnected(unit) and not _G.UnitIsDeadOrGhost(unit) and Cork.IsSpellInRange(spell, unit)
end

function Cork.IconLine(icon, linetext, token)
	return "|T" .. (icon or "") .. ":24:24:0:0:64:64:4:60:4:60|t " .. (token and ("|cff" .. Cork.colors[token]) or "") .. linetext
end

function Cork.UnitAura(unit, aura)
	for i = 1, _G.BUFF_MAX_DISPLAY do
		if aura == select('#', _G.UnitAura(unit, i)) then
			return true
		end
	end
	return false
end

if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then
	local last_thresh
	function Cork.RaidThresh()
		if not last_thresh then
			local _, _, _, _, maxPlayers, _, _ = _G.GetInstanceInfo()
			last_thresh = maxPlayers < 10 and 8 or maxPlayers / 5
		end
		return last_thresh
	end

	local function FlushThresh()
		last_thresh = nil
		for _, dataobj in _G.pairs(Cork.corks) do dataobj:Scan() end
	end
	ae.RegisterEvent("Cork Core", "PLAYER_DIFFICULTY_CHANGED", FlushThresh)
	ae.RegisterEvent("Cork Core", "UPDATE_INSTANCE_INFO", FlushThresh)
	-- ae.RegisterEvent("Cork Core", "GUILD_PARTY_STATE_UPDATED", FlushThresh)
	-- ae.RegisterEvent("Cork Core", "PLAYER_GUILD_UPDATE", FlushThresh)
end
