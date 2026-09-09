--!strict

local NumberUtil = {}

type CompactSuffix = {
	Threshold: number,
	Suffix: string,
}

local COMPACT_SUFFIXES: { CompactSuffix } = {
	{ Threshold = 1e15, Suffix = "Q" },
	{ Threshold = 1e12, Suffix = "T" },
	{ Threshold = 1e9, Suffix = "B" },
	{ Threshold = 1e6, Suffix = "M" },
	{ Threshold = 1e3, Suffix = "K" },
}

local function trimTrailingZeros(value: string): string
	value = value:gsub("(%..-)0+$", "%1")
	value = value:gsub("%.$", "")
	return value
end

function NumberUtil.IsFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

function NumberUtil.Average(values: { number }): number?
	if #values == 0 then
		return nil
	end

	local sum = 0
	for _, value in values do
		sum += value
	end

	return sum / #values
end

function NumberUtil.MinMax(values: { number }): (number?, number?)
	if #values == 0 then
		return nil, nil
	end

	local minimum = values[1]
	local maximum = values[1]

	for index = 2, #values do
		local value = values[index]
		if value < minimum then
			minimum = value
		end
		if value > maximum then
			maximum = value
		end
	end

	return minimum, maximum
end

function NumberUtil.RoundTo(value: number, decimalPlaces: number?): number
	local places = decimalPlaces or 0
	assert(places % 1 == 0, "Number.RoundTo decimalPlaces must be an integer")

	local factor = 10 ^ places
	return math.round(value * factor) / factor
end

function NumberUtil.RoundToStep(value: number, step: number): number
	assert(step > 0 and NumberUtil.IsFinite(step), "Number.RoundToStep step must be a positive finite number")
	return math.round(value / step) * step
end

function NumberUtil.Normalize(value: number, inputMinimum: number, inputMaximum: number, clampResult: boolean?): number
	assert(inputMinimum ~= inputMaximum, "Number.Normalize input range cannot have zero length")

	local normalized = (value - inputMinimum) / (inputMaximum - inputMinimum)
	if clampResult then
		return math.clamp(normalized, 0, 1)
	end

	return normalized
end

function NumberUtil.MapRange(
	value: number,
	inputMinimum: number,
	inputMaximum: number,
	outputMinimum: number,
	outputMaximum: number,
	clampResult: boolean?
): number
	local normalized = NumberUtil.Normalize(value, inputMinimum, inputMaximum, clampResult)
	return outputMinimum + (outputMaximum - outputMinimum) * normalized
end

function NumberUtil.FormatThousands(
	value: number,
	decimalPlaces: number?,
	thousandsSeparator: string?,
	decimalSeparator: string?
): string
	assert(NumberUtil.IsFinite(value), "Number.FormatThousands value must be finite")

	local separator = thousandsSeparator or ","
	local decimalMark = decimalSeparator or "."
	local raw: string

	if decimalPlaces ~= nil then
		assert(decimalPlaces >= 0 and decimalPlaces % 1 == 0, "decimalPlaces must be a non-negative integer")
		raw = string.format(`%.{decimalPlaces}f`, value)
	else
		raw = tostring(value)
	end

	local sign, integerPart, fractionPart = raw:match("^([%-]?)(%d+)%.?(%d*)$")
	if not integerPart then
		return raw
	end
	-- `string.match` returns optional captures even when the pattern guarantees them.
	-- Normalize them after the failed-match guard for strict type checking.
	sign = sign or ""
	fractionPart = fractionPart or ""

	local grouped = integerPart
	while true do
		local updated, replacements = grouped:gsub("^(%d+)(%d%d%d)", "%1" .. separator .. "%2")
		grouped = updated
		if replacements == 0 then
			break
		end
	end

	local result = sign .. grouped
	if fractionPart ~= "" then
		result ..= decimalMark .. fractionPart
	end

	return result
end

function NumberUtil.FormatCompact(value: number, decimalPlaces: number?): string
	assert(NumberUtil.IsFinite(value), "Number.FormatCompact value must be finite")
	local places = decimalPlaces or 1
	assert(places >= 0 and places % 1 == 0, "decimalPlaces must be a non-negative integer")

	local absoluteValue = math.abs(value)
	for _, entry in COMPACT_SUFFIXES do
		if absoluteValue >= entry.Threshold then
			local scaled = NumberUtil.RoundTo(value / entry.Threshold, places)
			return trimTrailingZeros(string.format(`%.{places}f`, scaled)) .. entry.Suffix
		end
	end

	if value % 1 == 0 then
		return tostring(value)
	end

	return trimTrailingZeros(string.format(`%.{places}f`, value))
end

function NumberUtil.DiscountPercent(oldPrice: number, newPrice: number, roundStep: number?): number
	assert(oldPrice > 0, "Number.DiscountPercent oldPrice must be greater than zero")

	local discount = ((oldPrice - newPrice) / oldPrice) * 100
	if roundStep ~= nil then
		return NumberUtil.RoundToStep(discount, roundStep)
	end

	return discount
end

function NumberUtil.OrdinalSuffix(value: number): string
	local integer = math.abs(math.floor(value))
	local lastTwoDigits = integer % 100

	if lastTwoDigits >= 11 and lastTwoDigits <= 13 then
		return "th"
	end

	local lastDigit = integer % 10
	if lastDigit == 1 then
		return "st"
	elseif lastDigit == 2 then
		return "nd"
	elseif lastDigit == 3 then
		return "rd"
	end

	return "th"
end

function NumberUtil.FormatOrdinal(value: number): string
	return tostring(value) .. NumberUtil.OrdinalSuffix(value)
end

return table.freeze(NumberUtil)
