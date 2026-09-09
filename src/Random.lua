--!strict

local RandomUtil = {}
local defaultRandom = Random.new()

export type WeightedItem<T> = {
	Value: T,
	Weight: number,
}

local function getRandom(random: Random?): Random
	return random or defaultRandom
end

local function assertFinite(value: number, name: string)
	assert(value == value and math.abs(value) ~= math.huge, `{name} must be finite`)
end

function RandomUtil.Integer(minimum: number, maximum: number, random: Random?): number
	assert(minimum % 1 == 0 and maximum % 1 == 0, "Random.Integer bounds must be integers")
	assert(minimum <= maximum, "Random.Integer minimum must not exceed maximum")
	return getRandom(random):NextInteger(minimum, maximum)
end

function RandomUtil.Float(minimum: number?, maximum: number?, random: Random?): number
	local minValue = minimum or 0
	local maxValue = maximum or 1
	assertFinite(minValue, "minimum")
	assertFinite(maxValue, "maximum")
	assert(minValue <= maxValue, "Random.Float minimum must not exceed maximum")
	return getRandom(random):NextNumber(minValue, maxValue)
end

function RandomUtil.Choice<T>(items: { T }, random: Random?): T?
	if #items == 0 then
		return nil
	end

	return items[getRandom(random):NextInteger(1, #items)]
end

function RandomUtil.DictionaryEntry(dictionary: { [any]: any }, random: Random?): (any?, any?)
	local keys = {}
	for key in dictionary do
		table.insert(keys, key)
	end

	local key = RandomUtil.Choice(keys, random)
	if key == nil then
		return nil, nil
	end

	return key, dictionary[key]
end

function RandomUtil.WeightedChoice<T>(items: { WeightedItem<T> }, random: Random?): T?
	local totalWeight = 0
	local lastPositiveValue: T? = nil

	for index, item in items do
		assertFinite(item.Weight, `items[{index}].Weight`)
		assert(item.Weight >= 0, `items[{index}].Weight must be non-negative`)

		if item.Weight > 0 then
			totalWeight += item.Weight
			lastPositiveValue = item.Value
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = getRandom(random):NextNumber(0, totalWeight)
	local cumulativeWeight = 0

	for _, item in items do
		if item.Weight > 0 then
			cumulativeWeight += item.Weight
			if roll <= cumulativeWeight then
				return item.Value
			end
		end
	end

	return lastPositiveValue
end

function RandomUtil.Shuffle<T>(items: { T }, random: Random?): { T }
	local result = table.clone(items)
	getRandom(random):Shuffle(result)
	return result
end

function RandomUtil.Sample<T>(items: { T }, count: number, random: Random?): { T }
	assert(count % 1 == 0 and count >= 0, "Random.Sample count must be a non-negative integer")
	assert(count <= #items, "Random.Sample count cannot exceed the number of items")

	local shuffled = RandomUtil.Shuffle(items, random)
	local result: { T } = table.create(count)

	for index = 1, count do
		result[index] = shuffled[index]
	end

	return result
end

return table.freeze(RandomUtil)
