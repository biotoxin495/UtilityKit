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

--[=[
	Removes unnecessary trailing zeroes from the fractional part of a formatted
	number string, and removes the decimal point when no fractional digits remain.

	@param value string -- A decimal number string to clean up.
	@return string -- The cleaned number string.
]=]
local function trimTrailingZeros(value: string): string
	value = value:gsub("(%..-)0+$", "%1")
	value = value:gsub("%.$", "")
	return value
end

--[=[
	Checks whether a number is finite. NaN, positive infinity, and negative
	infinity are considered non-finite.

	@param value number -- The number to inspect.
	@return boolean -- `true` when the value is finite; otherwise `false`.
]=]
function NumberUtil.IsFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

--[=[
	Calculates the arithmetic mean of an array of numbers.

	@param values {number} -- The numbers to average.
	@return number? -- The average, or `nil` when the array is empty.
]=]
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

--[=[
	Finds the minimum and maximum values in a numeric array in a single pass.

	@param values {number} -- The numbers to inspect.
	@return number? -- The minimum value, or `nil` when the array is empty.
	@return number? -- The maximum value, or `nil` when the array is empty.
]=]
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

--[=[
	Rounds a number to a requested number of decimal places. Negative decimal
	places may be used to round to tens, hundreds, and larger positions.

	@param value number -- The value to round.
	@param decimalPlaces number? -- Integer number of decimal places; defaults to `0`.
	@return number -- The rounded value.
]=]
function NumberUtil.RoundTo(value: number, decimalPlaces: number?): number
	local places = decimalPlaces or 0
	assert(places % 1 == 0, "Number.RoundTo decimalPlaces must be an integer")

	local factor = 10 ^ places
	return math.round(value * factor) / factor
end

--[=[
	Rounds a number to the nearest multiple of a positive step size.

	@param value number -- The value to round.
	@param step number -- A positive, finite step such as `5`, `0.25`, or `100`.
	@return number -- The nearest multiple of `step`.
]=]
function NumberUtil.RoundToStep(value: number, step: number): number
	assert(step > 0 and NumberUtil.IsFinite(step), "Number.RoundToStep step must be a positive finite number")
	return math.round(value / step) * step
end

--[=[
	Normalizes a value from an arbitrary input range into the `0` to `1` range.
	The input range may be ascending or descending, but its endpoints must differ.

	@param value number -- The value to normalize.
	@param inputMinimum number -- The first endpoint of the input range.
	@param inputMaximum number -- The second endpoint of the input range.
	@param clampResult boolean? -- When `true`, clamps the result to the inclusive `0..1` range.
	@return number -- The normalized value.
]=]
function NumberUtil.Normalize(value: number, inputMinimum: number, inputMaximum: number, clampResult: boolean?): number
	assert(inputMinimum ~= inputMaximum, "Number.Normalize input range cannot have zero length")

	local normalized = (value - inputMinimum) / (inputMaximum - inputMinimum)
	if clampResult then
		return math.clamp(normalized, 0, 1)
	end

	return normalized
end

--[=[
	Remaps a value from one numeric range into another. When `clampResult` is
	enabled, the normalized input is clamped before it is mapped to the output range.

	@param value number -- The value to remap.
	@param inputMinimum number -- The first endpoint of the source range.
	@param inputMaximum number -- The second endpoint of the source range.
	@param outputMinimum number -- The first endpoint of the destination range.
	@param outputMaximum number -- The second endpoint of the destination range.
	@param clampResult boolean? -- When `true`, prevents extrapolation beyond the output range.
	@return number -- The remapped value.
]=]
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

--[=[
	Formats a finite number using grouped thousands and an optional fixed number
	of decimal places. Both the thousands and decimal separators are configurable.

	@param value number -- The finite number to format.
	@param decimalPlaces number? -- Optional non-negative fixed number of fractional digits.
	@param thousandsSeparator string? -- Separator between groups of three digits; defaults to `","`.
	@param decimalSeparator string? -- Fraction separator; defaults to `"."`.
	@return string -- The formatted number.
]=]
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

--[=[
	Formats a finite number into a compact suffix representation such as `1.2K`,
	`3.5M`, or `2B`. Values below one thousand remain unsuffixed.

	@param value number -- The finite number to format.
	@param decimalPlaces number? -- Non-negative number of fractional digits; defaults to `1`.
	@return string -- The compact representation with redundant trailing zeroes removed.
]=]
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

--[=[
	Calculates the percentage reduction from an original price to a new price.
	A result below zero represents an increase rather than a discount.

	@param oldPrice number -- The original price. Must be greater than zero.
	@param newPrice number -- The replacement price.
	@param roundStep number? -- Optional positive step used to round the percentage.
	@return number -- The discount percentage, optionally rounded to `roundStep`.
]=]
function NumberUtil.DiscountPercent(oldPrice: number, newPrice: number, roundStep: number?): number
	assert(oldPrice > 0, "Number.DiscountPercent oldPrice must be greater than zero")

	local discount = ((oldPrice - newPrice) / oldPrice) * 100
	if roundStep ~= nil then
		return NumberUtil.RoundToStep(discount, roundStep)
	end

	return discount
end

--[=[
	Returns the English ordinal suffix for a number. The absolute floored integer
	portion is used to determine the suffix, including the `11th` to `13th` exceptions.

	@param value number -- The number whose ordinal suffix should be determined.
	@return string -- One of `"st"`, `"nd"`, `"rd"`, or `"th"`.
]=]
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

--[=[
	Formats a number with its English ordinal suffix, for example `1st`, `22nd`,
	or `103rd`.

	@param value number -- The number to format.
	@return string -- The original number converted to text with its ordinal suffix appended.
]=]
function NumberUtil.FormatOrdinal(value: number): string
	return tostring(value) .. NumberUtil.OrdinalSuffix(value)
end

return table.freeze(NumberUtil)
