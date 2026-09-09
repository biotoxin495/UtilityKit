--!strict

local VectorUtil = {}

export type Position = Vector2 | Vector3

--[=[
	Calculates the Euclidean distance between two positions. Both values must use
	the same Roblox vector type (`Vector2` or `Vector3`).

	@param left Position -- First position.
	@param right Position -- Second position using the same vector type as `left`.
	@return number -- Magnitude of the displacement between the two positions.
]=]
local function distanceBetween(left: Position, right: Position): number
	assert(typeof(left) == typeof(right), "Vector positions must use the same vector type")
	return (((left :: any) - (right :: any)).Magnitude :: number)
end

--[=[
	Resolves a searchable item into a Vector2 or Vector3 position. When a selector
	is supplied it is called with the item; otherwise the item itself is treated as the position.

	@param item T -- Source item being inspected.
	@param selector ((T) -> Position)? -- Optional function that extracts a position from the item.
	@return Position -- Resolved Vector2 or Vector3 position.
]=]
local function resolvePosition<T>(item: T, selector: ((T) -> Position)?): Position
	local position = if selector then selector(item) else (item :: any)
	local kind = typeof(position)
	assert(kind == "Vector2" or kind == "Vector3", "Vector item or selector result must be Vector2 or Vector3")
	return position
end

--[=[
	Finds the item whose resolved position is closest to a target position. Items
	may be vectors directly or arbitrary values mapped to positions with a selector.

	@param items {T} -- Array of items to search.
	@param target Position -- Position from which distances are measured.
	@param selector ((T) -> Position)? -- Optional position extractor for non-vector items.
	@return T? -- Closest item, or `nil` when the array is empty.
	@return number? -- One-based index of the closest item, or `nil` when empty.
	@return number? -- Distance from the closest item to `target`, or `nil` when empty.
]=]
function VectorUtil.Closest<T>(
	items: { T },
	target: Position,
	selector: ((T) -> Position)?
): (T?, number?, number?)
	local bestItem: T? = nil
	local bestIndex: number? = nil
	local bestDistance = math.huge

	for index, item in items do
		local distance = distanceBetween(resolvePosition(item, selector), target)
		if distance < bestDistance then
			bestItem = item
			bestIndex = index
			bestDistance = distance
		end
	end

	if bestItem == nil then
		return nil, nil, nil
	end

	return bestItem, bestIndex, bestDistance
end

--[=[
	Finds the item whose resolved position is furthest from a target position. Items
	may be vectors directly or arbitrary values mapped to positions with a selector.

	@param items {T} -- Array of items to search.
	@param target Position -- Position from which distances are measured.
	@param selector ((T) -> Position)? -- Optional position extractor for non-vector items.
	@return T? -- Furthest item, or `nil` when the array is empty.
	@return number? -- One-based index of the furthest item, or `nil` when empty.
	@return number? -- Distance from the furthest item to `target`, or `nil` when empty.
]=]
function VectorUtil.Furthest<T>(
	items: { T },
	target: Position,
	selector: ((T) -> Position)?
): (T?, number?, number?)
	local bestItem: T? = nil
	local bestIndex: number? = nil
	local bestDistance = -math.huge

	for index, item in items do
		local distance = distanceBetween(resolvePosition(item, selector), target)
		if distance > bestDistance then
			bestItem = item
			bestIndex = index
			bestDistance = distance
		end
	end

	if bestItem == nil then
		return nil, nil, nil
	end

	return bestItem, bestIndex, bestDistance
end

return table.freeze(VectorUtil)
