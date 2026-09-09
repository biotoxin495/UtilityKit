--!strict

local RandomUtil = {}
local defaultRandom = Random.new()

export type WeightedItem<T> = {
	Value: T,
	Weight: number,
}

--[=[
	Resolves the random number generator used by a random utility call.

	@param random Random? -- Optional caller-provided generator for deterministic or seeded behavior.
	@return Random -- The provided generator, or UtilityKit's shared default generator when omitted.
]=]
local function getRandom(random: Random?): Random
	return random or defaultRandom
end

--[=[
	Validates that a numeric argument is finite before it is used by a random operation.

	@param value number -- The number to validate.
	@param name string -- Human-readable argument name used in the assertion message.
	@return nil -- Returns normally when the value is finite; otherwise raises an assertion.
]=]
local function assertFinite(value: number, name: string)
	assert(value == value and math.abs(value) ~= math.huge, `{name} must be finite`)
end

--[=[
	Generates an integer within an inclusive range.

	@param minimum number -- Inclusive integer lower bound.
	@param maximum number -- Inclusive integer upper bound. Must be greater than or equal to `minimum`.
	@param random Random? -- Optional generator used instead of the shared default generator.
	@return number -- A random integer in the inclusive `[minimum, maximum]` range.
]=]
function RandomUtil.Integer(minimum: number, maximum: number, random: Random?): number
	assert(minimum % 1 == 0 and maximum % 1 == 0, "Random.Integer bounds must be integers")
	assert(minimum <= maximum, "Random.Integer minimum must not exceed maximum")
	return getRandom(random):NextInteger(minimum, maximum)
end

--[=[
	Generates a random floating-point number within a configurable range.

	@param minimum number? -- Lower bound; defaults to `0`.
	@param maximum number? -- Upper bound; defaults to `1`.
	@param random Random? -- Optional generator used instead of the shared default generator.
	@return number -- A random floating-point number produced by `Random:NextNumber`.
]=]
function RandomUtil.Float(minimum: number?, maximum: number?, random: Random?): number
	local minValue = minimum or 0
	local maxValue = maximum or 1
	assertFinite(minValue, "minimum")
	assertFinite(maxValue, "maximum")
	assert(minValue <= maxValue, "Random.Float minimum must not exceed maximum")
	return getRandom(random):NextNumber(minValue, maxValue)
end

--[=[
	Chooses one element uniformly from an array without modifying the array.

	@param items {T} -- Array to choose from.
	@param random Random? -- Optional generator used instead of the shared default generator.
	@return T? -- The selected item, or `nil` when `items` is empty.
]=]
function RandomUtil.Choice<T>(items: { T }, random: Random?): T?
	if #items == 0 then
		return nil
	end

	return items[getRandom(random):NextInteger(1, #items)]
end

--[=[
	Chooses one key/value pair uniformly from a dictionary.

	@param dictionary {[any]: any} -- Dictionary whose keys are eligible for selection.
	@param random Random? -- Optional generator used instead of the shared default generator.
	@return any? -- The selected key, or `nil` when the dictionary is empty.
	@return any? -- The value associated with the selected key, or `nil` when the dictionary is empty.
]=]
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

--[=[
	Chooses a value according to non-negative numeric weights. Zero-weight entries
	are ignored, and weights may be fractional. The input array is not modified.

	@param items {WeightedItem<T>} -- Weighted entries containing `Value` and non-negative finite `Weight` fields.
	@param random Random? -- Optional generator used instead of the shared default generator.
	@return T? -- The selected value, or `nil` when the array is empty or all weights are zero.
]=]
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

--[=[
	Returns a shuffled copy of an array using Roblox's `Random:Shuffle` operation.
	The original array remains unchanged.

	@param items {T} -- Array to shuffle.
	@param random Random? -- Optional generator used instead of the shared default generator.
	@return {T} -- A new array containing the same values in randomized order.
]=]
function RandomUtil.Shuffle<T>(items: { T }, random: Random?): { T }
	local result = table.clone(items)
	getRandom(random):Shuffle(result)
	return result
end

--[=[
	Selects a requested number of unique array entries without replacement.
	The original array remains unchanged, and the returned order is randomized.

	@param items {T} -- Source array to sample from.
	@param count number -- Non-negative integer number of entries to return; cannot exceed `#items`.
	@param random Random? -- Optional generator used instead of the shared default generator.
	@return {T} -- A new array containing `count` unique sampled entries.
]=]
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
