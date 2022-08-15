
local myname, ns = ...


function ns.IsHolidayActive(name)
	local d = C_DateAndTime.GetCurrentCalendarTime()
	local title, hour, sequenceType
	local i = 1
	repeat
		title, hour, _, _, sequenceType = C_Calendar.GetDayEvent(0, d.monthDay, i)
		if title == name then
			if sequenceType == "START" then
				return GetGameTime() >= hour
			elseif sequenceType == "END" then
				return GetGameTime() < hour
			else
				return true
			end
		end
		i = i + 1
	until not title
end
