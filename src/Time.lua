--!strict

local TimeUtil = {}

export type DurationParts = {
	IsNegative: boolean,
	Days: number,
	Hours: number,
	Minutes: number,
	Seconds: number,
}

export type ClockOptions = {
	AlwaysShowHours: boolean?,
	DecimalPlaces: number?,
}

export type RelativeOptions = {
	Now: number?,
}

export type DateOrder = "DMY" | "MDY" | "YMD"
export type DateOptions = {
	UTC: boolean?,
	IncludeYear: boolean?,
	Separator: string?,
	Order: DateOrder?,
}

export type DayPart = {
	Name: string,
	StartHour: number,
	EndHour: number,
}

type RelativeUnit = {
	Name: string,
	Seconds: number,
}

type DurationEntry = {
	Value: number,
	Suffix: string,
}

local DEFAULT_DAY_PARTS: { DayPart } = {
	{ Name = "Late Night", StartHour = 0, EndHour = 4 },
	{ Name = "Early Morning", StartHour = 4, EndHour = 8 },
	{ Name = "Morning", StartHour = 8, EndHour = 12 },
	{ Name = "Afternoon", StartHour = 12, EndHour = 16 },
	{ Name = "Evening", StartHour = 16, EndHour = 20 },
	{ Name = "Late Evening", StartHour = 20, EndHour = 24 },
}

local RELATIVE_UNITS: { RelativeUnit } = {
	{ Name = "year", Seconds = 31_557_600 },
	{ Name = "month", Seconds = 2_629_800 },
	{ Name = "week", Seconds = 604_800 },
	{ Name = "day", Seconds = 86_400 },
	{ Name = "hour", Seconds = 3_600 },
	{ Name = "minute", Seconds = 60 },
	{ Name = "second", Seconds = 1 },
}

local function padTwo(value: number): string
	return string.format("%02d", value)
end

function TimeUtil.SplitDuration(totalSeconds: number): DurationParts
	local isNegative = totalSeconds < 0
	local remaining = math.floor(math.abs(totalSeconds))

	local days = math.floor(remaining / 86_400)
	remaining %= 86_400

	local hours = math.floor(remaining / 3_600)
	remaining %= 3_600

	local minutes = math.floor(remaining / 60)
	local seconds = remaining % 60

	return {
		IsNegative = isNegative,
		Days = days,
		Hours = hours,
		Minutes = minutes,
		Seconds = seconds,
	}
end

function TimeUtil.FormatClock(totalSeconds: number, options: ClockOptions?): string
	local config: ClockOptions = options or {}
	local decimalPlaces = config.DecimalPlaces or 0
	assert(decimalPlaces >= 0 and decimalPlaces % 1 == 0, "Time.FormatClock DecimalPlaces must be a non-negative integer")

	local factor = 10 ^ decimalPlaces
	local rounded = math.round(math.abs(totalSeconds) * factor) / factor
	local hours = math.floor(rounded / 3_600)
	local minutes = math.floor((rounded % 3_600) / 60)
	local seconds = rounded % 60

	local secondsText: string
	if decimalPlaces == 0 then
		secondsText = padTwo(math.floor(seconds))
	else
		secondsText = string.format(`%0{decimalPlaces + 3}.{decimalPlaces}f`, seconds)
	end

	local result: string
	if config.AlwaysShowHours or hours > 0 then
		result = `{padTwo(hours)}:{padTwo(minutes)}:{secondsText}`
	else
		result = `{padTwo(minutes)}:{secondsText}`
	end

	if totalSeconds < 0 then
		return "-" .. result
	end

	return result
end

function TimeUtil.FormatDuration(totalSeconds: number, maxUnits: number?): string
	local unitLimit = maxUnits or 2
	assert(unitLimit >= 1 and unitLimit % 1 == 0, "Time.FormatDuration maxUnits must be a positive integer")

	local parts = TimeUtil.SplitDuration(totalSeconds)
	local entries: { DurationEntry } = {
		{ Value = parts.Days, Suffix = "d" },
		{ Value = parts.Hours, Suffix = "h" },
		{ Value = parts.Minutes, Suffix = "m" },
		{ Value = parts.Seconds, Suffix = "s" },
	}

	local result: { string } = {}
	for _, entry in entries do
		if entry.Value > 0 then
			table.insert(result, tostring(entry.Value) .. entry.Suffix)
			if #result >= unitLimit then
				break
			end
		end
	end

	if #result == 0 then
		return "0s"
	end

	local formatted = table.concat(result, " ")
	if parts.IsNegative then
		return "-" .. formatted
	end

	return formatted
end

function TimeUtil.FormatRelative(targetUnix: number, options: RelativeOptions?): string
	local now = if options and options.Now ~= nil then options.Now else DateTime.now().UnixTimestamp
	local difference = targetUnix - now
	local absoluteDifference = math.abs(difference)

	if absoluteDifference < 1 then
		return "now"
	end

	for _, unit in RELATIVE_UNITS do
		if absoluteDifference >= unit.Seconds then
			local amount = math.max(1, math.floor(absoluteDifference / unit.Seconds + 0.5))
			local name = unit.Name .. (if amount == 1 then "" else "s")

			if difference > 0 then
				return `in {amount} {name}`
			end

			return `{amount} {name} ago`
		end
	end

	return "now"
end

function TimeUtil.FormatDate(unixTimestamp: number, options: DateOptions?): string
	local config: DateOptions = options or {}
	local useUtc = config.UTC ~= false
	local includeYear = config.IncludeYear ~= false
	local separator = config.Separator or "/"
	local order = config.Order or "DMY"
	local date = os.date(if useUtc then "!*t" else "*t", unixTimestamp) :: any

	local day = padTwo(date.day)
	local month = padTwo(date.month)
	local year = tostring(date.year)
	local values: { string }

	if order == "MDY" then
		values = { month, day }
	elseif order == "YMD" then
		values = if includeYear then { year, month, day } else { month, day }
	else
		values = { day, month }
	end

	if includeYear and order ~= "YMD" then
		table.insert(values, year)
	end

	return table.concat(values, separator)
end

function TimeUtil.IsoToUnix(isoDate: string): number?
	local success, result = pcall(function()
		return DateTime.fromIsoDate(isoDate)
	end)
	if not success or result == nil then
		return nil
	end

	return (result :: DateTime).UnixTimestamp
end

function TimeUtil.UnixToIso(unixTimestamp: number): string
	return DateTime.fromUnixTimestamp(unixTimestamp):ToIsoDate()
end

function TimeUtil.GetDayPart(hour: number, divisions: { DayPart }?): (string?, number?)
	assert(hour >= 0 and hour < 24, "Time.GetDayPart hour must be in the range [0, 24)")

	local availableDivisions = divisions or DEFAULT_DAY_PARTS
	for index, division in availableDivisions do
		assert(division.StartHour >= 0 and division.EndHour <= 24, `Invalid day-part range at index {index}`)
		assert(division.StartHour < division.EndHour, `Day-part start must be before end at index {index}`)

		if hour >= division.StartHour and hour < division.EndHour then
			return division.Name, index
		end
	end

	return nil, nil
end

return table.freeze(TimeUtil)
