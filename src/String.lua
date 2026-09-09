--!strict

local StringUtil = {}

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

local function capitalize(value: string): string
	if value == "" then
		return value
	end
	return value:sub(1, 1):upper() .. value:sub(2):lower()
end

function StringUtil.Trim(value: string): string
	return value:match("^%s*(.-)%s*$") or ""
end

function StringUtil.StartsWith(value: string, prefix: string): boolean
	return value:sub(1, #prefix) == prefix
end

function StringUtil.EndsWith(value: string, suffix: string): boolean
	if suffix == "" then
		return true
	end
	return value:sub(-#suffix) == suffix
end

function StringUtil.EscapePattern(value: string): string
	return (value:gsub("([^%w])", "%%%1"))
end

function StringUtil.ToSnakeCase(value: string): string
	return table.concat(words(value), "_")
end

function StringUtil.ToKebabCase(value: string): string
	return table.concat(words(value), "-")
end

function StringUtil.ToPascalCase(value: string): string
	local result = {}
	for _, word in words(value) do
		table.insert(result, capitalize(word))
	end
	return table.concat(result)
end

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
