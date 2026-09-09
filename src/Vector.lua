--!strict

local VectorUtil = {}

export type Position = Vector2 | Vector3

local function distanceBetween(left: Position, right: Position): number
	assert(typeof(left) == typeof(right), "Vector positions must use the same vector type")
	return (((left :: any) - (right :: any)).Magnitude :: number)
end

local function resolvePosition<T>(item: T, selector: ((T) -> Position)?): Position
	local position = if selector then selector(item) else (item :: any)
	local kind = typeof(position)
	assert(kind == "Vector2" or kind == "Vector3", "Vector item or selector result must be Vector2 or Vector3")
	return position
end

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
