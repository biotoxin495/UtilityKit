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

--[=[
	Creates a shallow copy of a path array before it is extended by internal
	path-building operations.

	@param path Path -- The path array to copy.
	@return Path -- A new array containing the same path segments.
]=]
local function clonePath(path: Path): Path
	return table.clone(path)
end

--[=[
	Returns a new path containing all existing path segments followed by one new key.
	The original path is not modified.

	@param path Path -- The existing path segments.
	@param key any -- The key to append to the path.
	@return Path -- A copied and extended path array.
]=]
local function appendPath(path: Path, key: any): Path
	local result = clonePath(path)
	table.insert(result, key)
	return result
end

--[=[
	Counts the number of key/value entries in a table, including dictionary keys
	that are not part of its array portion.

	@param source {[any]: any} -- The table whose entries should be counted.
	@return number -- The total number of entries in `source`.
]=]
function TableUtil.Count(source: Dictionary): number
	local count = 0
	for _ in source do
		count += 1
	end
	return count
end

--[=[
	Collects every key from a table into a new array. Dictionary iteration order is
	not guaranteed, so the returned key order should not be relied upon.

	@param source {[any]: any} -- The table to inspect.
	@return {any} -- A new array containing each key from `source`.
]=]
function TableUtil.Keys(source: Dictionary): { any }
	local keys: { any } = {}
	for key in source do
		table.insert(keys, key)
	end
	return keys
end

--[=[
	Collects every value from a table into a new array. Dictionary iteration order
	is not guaranteed, so the returned value order should not be relied upon.

	@param source {[any]: any} -- The table to inspect.
	@return {any} -- A new array containing each value from `source`.
]=]
function TableUtil.Values(source: Dictionary): { any }
	local values: { any } = {}
	for _, value in source do
		table.insert(values, value)
	end
	return values
end

--[=[
	Creates a shallow copy of a table. Nested tables and other referenced values are
	shared between the original and the copy.

	@param source {[any]: any} -- The table to copy.
	@return {[any]: any} -- A new table containing the same immediate keys and values.
]=]
function TableUtil.ShallowCopy(source: Dictionary): Dictionary
	return table.clone(source)
end

--[=[
	Creates a recursive copy of a value. Non-table values are returned unchanged;
	tables are copied recursively with cycle detection and shared-reference identity
	preserved within the copied graph.

	@param value any -- The value or table graph to copy.
	@param preserveMetatable boolean? -- When omitted or `true`, table metatables are preserved by reference; `false` omits them.
	@return any -- The copied value or root table.
]=]
function TableUtil.DeepCopy(value: any, preserveMetatable: boolean?): any
	local shouldPreserveMetatable = preserveMetatable ~= false
	local seen: { [table]: table } = {}

	--[=[
		Recursively copies one value while using `seen` to resolve cycles and reuse
		already-created copies for repeated table references.

		@param current any -- The current value being copied.
		@return any -- The corresponding copied value.
	]=]
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

--[=[
	Recursively compares two values for structural equality. Table keys and values
	are compared deeply, and cyclic table graphs are handled without infinite recursion.
	Metatables are not compared.

	@param left any -- The first value to compare.
	@param right any -- The second value to compare.
	@return boolean -- `true` when both values are structurally equivalent; otherwise `false`.
]=]
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

	--[=[
		Recursively compares a pair of values while remembering which left-side
		tables have already been matched to right-side tables.

		@param a any -- Current value from the left graph.
		@param b any -- Current value from the right graph.
		@return boolean -- Whether the current values are structurally equal.
	]=]
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

--[=[
	Recursively merges one dictionary into another. When both sides contain tables
	at the same key, those tables are merged recursively; otherwise the incoming
	value replaces the target value. Internal cycle tracking prevents repeated
	merges of the same incoming/target table pair.

	@param target {[any]: any} -- Table that receives merged values and is mutated in place.
	@param incoming {[any]: any} -- Table whose values are merged into `target`.
	@param seen SeenTables? -- Internal cycle-tracking map shared by recursive calls.
	@return {[any]: any} -- The mutated `target` table.
]=]
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

--[=[
	Deep-merges two dictionaries into a new table without mutating either input.
	Nested tables present on both sides are recursively merged; conflicting
	non-table values use the incoming value.

	@param base {[any]: any} -- Base dictionary whose values form the initial result.
	@param incoming {[any]: any} -- Dictionary whose values override or extend the base.
	@return {[any]: any} -- A new deeply copied and merged dictionary.
]=]
function TableUtil.DeepMerge(base: Dictionary, incoming: Dictionary): Dictionary
	return deepMergeInto(TableUtil.DeepCopy(base), TableUtil.DeepCopy(incoming))
end

--[=[
	Deep-merges an incoming dictionary into an existing base table. The base is
	mutated, while the incoming table is deep-copied before merging so its nested
	tables are not inserted into the base by direct reference.

	@param base {[any]: any} -- Destination dictionary to mutate.
	@param incoming {[any]: any} -- Dictionary whose values should be merged into `base`.
	@return {[any]: any} -- The same mutated `base` table.
]=]
function TableUtil.DeepMergeInPlace(base: Dictionary, incoming: Dictionary): Dictionary
	return deepMergeInto(base, TableUtil.DeepCopy(incoming))
end

--[=[
	Removes duplicate values from an array while preserving the order of each
	value's first appearance. Values must be usable as table keys.

	@param values {any} -- Array whose duplicate values should be removed.
	@return {any} -- A new array containing only the first occurrence of each value.
]=]
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

--[=[
	Computes a one-way set difference: values that occur in `first` but do not
	occur in `second`. Duplicate results are removed while first-array order is preserved.

	@param first {any} -- Source array whose values may be included in the result.
	@param second {any} -- Array of values to exclude.
	@return {any} -- Unique values present in `first` and absent from `second`.
]=]
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

--[=[
	Finds values shared by two arrays. Each matching value appears at most once,
	and the result follows the order of matching values in `first`.

	@param first {any} -- Array whose ordering is used for the result.
	@param second {any} -- Array used to determine membership.
	@return {any} -- Unique values that occur in both arrays.
]=]
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

--[=[
	Traverses a table graph using an array of keys. If traversal encounters a
	non-table or a missing key, the supplied default value is returned instead.

	@param root any -- Root value from which traversal begins.
	@param path Path -- Ordered keys to follow through nested tables.
	@param defaultValue any? -- Value returned when the requested path cannot be resolved.
	@return any -- The value found at the path, or `defaultValue` when unresolved.
]=]
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

--[=[
	Assigns a value at a nested table path, creating missing intermediate tables as
	needed. Existing non-table intermediate values cause an error rather than being overwritten.

	@param root {[any]: any} -- Root dictionary to mutate.
	@param path Path -- Non-empty ordered keys identifying the destination.
	@param value any -- Value to assign at the final path key.
	@return {[any]: any} -- The same mutated `root` table.
]=]
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

--[=[
	Builds a structured list of changes required to transform one dictionary into
	another. Changes are returned as `Set` or `Remove` operations with path arrays;
	set values are deep-copied into the result. Cyclic table pairs are tracked safely.

	@param oldValue {[any]: any} -- Previous dictionary state.
	@param newValue {[any]: any} -- New dictionary state to compare against the previous state.
	@return {DiffOperation} -- Structured operations describing additions, changes, and removals.
]=]
function TableUtil.Diff(oldValue: Dictionary, newValue: Dictionary): { DiffOperation }
	local operations: { DiffOperation } = {}
	local seen: SeenTables = {}

	--[=[
		Records an old/new table pair and reports whether that exact pair has already
		been visited during the current diff traversal.

		@param oldTable table -- Table from the old state.
		@param newTable table -- Corresponding table from the new state.
		@return boolean -- `true` when the pair was already seen; otherwise `false`.
	]=]
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

	--[=[
		Recursively compares one old/new dictionary pair and appends detected set or
		remove operations to the enclosing `operations` array.

		@param oldTable {[any]: any} -- Current dictionary from the old state.
		@param newTable {[any]: any} -- Current dictionary from the new state.
		@param path Path -- Path leading to the current dictionary pair.
		@return nil -- Results are appended to the enclosing `operations` array.
	]=]
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
