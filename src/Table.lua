--!strict

local TableUtil = {}

export type Path = { any }
export type DiffKind = "Set" | "Remove"
export type DiffOperation = {
	Kind: DiffKind,
	Path: Path,
	Value: any?,
}

type Dictionary = { [any]: any }
type SeenTables = { [table]: { [table]: boolean } }

local function clonePath(path: Path): Path
	return table.clone(path)
end

local function appendPath(path: Path, key: any): Path
	local result = clonePath(path)
	table.insert(result, key)
	return result
end

function TableUtil.Count(source: Dictionary): number
	local count = 0
	for _ in source do
		count += 1
	end
	return count
end

function TableUtil.Keys(source: Dictionary): { any }
	local keys: { any } = {}
	for key in source do
		table.insert(keys, key)
	end
	return keys
end

function TableUtil.Values(source: Dictionary): { any }
	local values: { any } = {}
	for _, value in source do
		table.insert(values, value)
	end
	return values
end

function TableUtil.ShallowCopy(source: Dictionary): Dictionary
	return table.clone(source)
end

function TableUtil.DeepCopy(value: any, preserveMetatable: boolean?): any
	local shouldPreserveMetatable = preserveMetatable ~= false
	local seen: { [table]: table } = {}

	local function copy(current: any): any
		if type(current) ~= "table" then
			return current
		end

		local existing = seen[current]
		if existing then
			return existing
		end

		local result = {}
		seen[current] = result

		for key, item in current do
			result[copy(key)] = copy(item)
		end

		if shouldPreserveMetatable then
			local metatable = getmetatable(current)
			if type(metatable) == "table" then
				setmetatable(result, metatable)
			end
		end

		return result
	end

	return copy(value)
end

function TableUtil.DeepEqual(left: any, right: any): boolean
	if left == right then
		return true
	end

	if type(left) ~= type(right) then
		return false
	end

	if type(left) ~= "table" then
		return false
	end

	local seen: { [table]: table } = {}

	local function compare(a: any, b: any): boolean
		if a == b then
			return true
		end

		if type(a) ~= type(b) then
			return false
		end

		if type(a) ~= "table" then
			return false
		end

		local previouslyMatched = seen[a]
		if previouslyMatched then
			return previouslyMatched == b
		end
		seen[a] = b

		for key, value in a do
			if not compare(value, b[key]) then
				return false
			end
		end

		for key in b do
			if a[key] == nil then
				return false
			end
		end

		return true
	end

	return compare(left, right)
end

local function deepMergeInto(
	target: Dictionary,
	incoming: Dictionary,
	seen: SeenTables?
): Dictionary
	local visited = seen or {}
	local targets = visited[incoming]
	if not targets then
		targets = {}
		visited[incoming] = targets
	elseif targets[target] then
		return target
	end
	targets[target] = true

	for key, incomingValue in incoming do
		local targetValue = target[key]

		if type(targetValue) == "table" and type(incomingValue) == "table" then
			deepMergeInto(targetValue, incomingValue, visited)
		else
			target[key] = incomingValue
		end
	end

	return target
end

function TableUtil.DeepMerge(base: Dictionary, incoming: Dictionary): Dictionary
	return deepMergeInto(TableUtil.DeepCopy(base), TableUtil.DeepCopy(incoming))
end

function TableUtil.DeepMergeInPlace(base: Dictionary, incoming: Dictionary): Dictionary
	return deepMergeInto(base, TableUtil.DeepCopy(incoming))
end

function TableUtil.Unique(values: { any }): { any }
	local result: { any } = {}
	local seen: { [any]: boolean } = {}

	for _, value in values do
		if not seen[value] then
			seen[value] = true
			table.insert(result, value)
		end
	end

	return result
end

function TableUtil.Difference(first: { any }, second: { any }): { any }
	local excluded: { [any]: boolean } = {}
	for _, value in second do
		excluded[value] = true
	end

	local result: { any } = {}
	local included: { [any]: boolean } = {}
	for _, value in first do
		if not excluded[value] and not included[value] then
			included[value] = true
			table.insert(result, value)
		end
	end

	return result
end

function TableUtil.Intersection(first: { any }, second: { any }): { any }
	local available: { [any]: boolean } = {}
	for _, value in second do
		available[value] = true
	end

	local result: { any } = {}
	local included: { [any]: boolean } = {}
	for _, value in first do
		if available[value] and not included[value] then
			included[value] = true
			table.insert(result, value)
		end
	end

	return result
end

function TableUtil.GetPath(root: any, path: Path, defaultValue: any?): any
	local current = root

	for _, key in path do
		if type(current) ~= "table" then
			return defaultValue
		end

		current = current[key]
		if current == nil then
			return defaultValue
		end
	end

	return current
end

function TableUtil.SetPath(root: Dictionary, path: Path, value: any): Dictionary
	assert(#path > 0, "Table.SetPath requires a non-empty path")

	local current = root
	for index = 1, #path - 1 do
		local key = path[index]
		local nextValue = current[key]

		if nextValue == nil then
			nextValue = {}
			current[key] = nextValue
		elseif type(nextValue) ~= "table" then
			error(`Table.SetPath cannot traverse non-table value at path index {index}`, 2)
		end

		current = nextValue
	end

	current[path[#path]] = value
	return root
end

function TableUtil.Diff(oldValue: Dictionary, newValue: Dictionary): { DiffOperation }
	local operations: { DiffOperation } = {}
	local seen: SeenTables = {}

	local function markSeen(oldTable: table, newTable: table): boolean
		local matches = seen[oldTable]
		if not matches then
			matches = {}
			seen[oldTable] = matches
		end

		if matches[newTable] then
			return true
		end

		matches[newTable] = true
		return false
	end

	local function compare(oldTable: Dictionary, newTable: Dictionary, path: Path): ()
		if markSeen(oldTable, newTable) then
			return
		end

		for key, currentValue in newTable do
			local previousValue = oldTable[key]
			local currentPath = appendPath(path, key)

			if type(previousValue) == "table" and type(currentValue) == "table" then
				compare(previousValue, currentValue, currentPath)
			elseif not TableUtil.DeepEqual(previousValue, currentValue) then
				table.insert(operations, {
					Kind = "Set",
					Path = currentPath,
					Value = TableUtil.DeepCopy(currentValue),
				})
			end
		end

		for key in oldTable do
			if newTable[key] == nil then
				table.insert(operations, {
					Kind = "Remove",
					Path = appendPath(path, key),
				})
			end
		end
	end

	compare(oldValue, newValue, {})
	return operations
end

return table.freeze(TableUtil)
