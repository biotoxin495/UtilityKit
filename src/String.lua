--!strict

local StringUtil = {}

--[=[
	Splits a mixed-format identifier or phrase into lowercase word components.
	CamelCase and acronym boundaries are separated, and non-alphanumeric characters
	(other than underscores) are treated as delimiters.

	@param value string -- The source string to split into words.
	@return {string} -- Lowercase word components in their original order.
]=]
local function words(value: string): { string }
	local prepared = value
		:gsub("(%u)(%u%l)", "%1 %2")
		:gsub("(%l)(%u)", "%1 %2")
		:gsub("[^%w]+", " ")

	local result = {}
	for word in prepared:gmatch("%w+") do
		table.insert(result, word:lower())
	end
	return result
end

--[=[
	Uppercases the first character of a word and lowercases the remainder.

	@param value string -- The word to capitalize.
	@return string -- The capitalized word, or an empty string when given one.
]=]
local function capitalize(value: string): string
	if value == "" then
		return value
	end
	return value:sub(1, 1):upper() .. value:sub(2):lower()
end

--[=[
	Removes whitespace from both the beginning and end of a string while leaving
	internal whitespace unchanged.

	@param value string -- The string to trim.
	@return string -- The trimmed string.
]=]
function StringUtil.Trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

--[=[
	Checks whether a string begins with an exact prefix.

	@param value string -- The string to inspect.
	@param prefix string -- The prefix to look for. An empty prefix always matches.
	@return boolean -- `true` when `value` starts with `prefix`; otherwise `false`.
]=]
function StringUtil.StartsWith(value: string, prefix: string): boolean
	return value:sub(1, #prefix) == prefix
end

--[=[
	Checks whether a string ends with an exact suffix.

	@param value string -- The string to inspect.
	@param suffix string -- The suffix to look for. An empty suffix always matches.
	@return boolean -- `true` when `value` ends with `suffix`; otherwise `false`.
]=]
function StringUtil.EndsWith(value: string, suffix: string): boolean
	if suffix == "" then
		return true
	end
	return value:sub(-#suffix) == suffix
end

--[=[
	Escapes characters with special meaning in Lua/Luau string patterns so the
	result can be safely embedded as literal pattern text.

	@param value string -- Literal text that should be escaped for pattern use.
	@return string -- Pattern-safe text with special characters escaped by `%`.
]=]
function StringUtil.EscapePattern(value: string): string
	return (value:gsub("([^%w])", "%%%1"))
end

--[=[
	Converts a phrase or mixed-case identifier to lowercase snake_case.

	@param value string -- The source phrase or identifier.
	@return string -- Lowercase words joined with underscores.
]=]
function StringUtil.ToSnakeCase(value: string): string
	return table.concat(words(value), "_")
end

--[=[
	Converts a phrase or mixed-case identifier to lowercase kebab-case.

	@param value string -- The source phrase or identifier.
	@return string -- Lowercase words joined with hyphens.
]=]
function StringUtil.ToKebabCase(value: string): string
	return table.concat(words(value), "-")
end

--[=[
	Converts a phrase or mixed-case identifier to PascalCase.

	@param value string -- The source phrase or identifier.
	@return string -- Capitalized word components joined without separators.
]=]
function StringUtil.ToPascalCase(value: string): string
	local result = {}
	for _, word in words(value) do
		table.insert(result, capitalize(word))
	end
	return table.concat(result)
end

--[=[
	Converts a phrase or mixed-case identifier to camelCase.

	@param value string -- The source phrase or identifier.
	@return string -- Lowercase first word followed by capitalized remaining words, or `""` when no words are found.
]=]
function StringUtil.ToCamelCase(value: string): string
	local separatedWords = words(value)
	if #separatedWords == 0 then
		return ""
	end

	local result = { separatedWords[1] }
	for index = 2, #separatedWords do
		table.insert(result, capitalize(separatedWords[index]))
	end
	return table.concat(result)
end

return table.freeze(StringUtil)
