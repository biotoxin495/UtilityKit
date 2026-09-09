--!strict

local UDimUtil = {}

--[=[
	Converts normalized two-axis scale values into absolute pixel offsets for a
	known container or viewport size.

	@param scale Vector2 -- X/Y scale components, typically taken from UDim scale values.
	@param absoluteSize Vector2 -- Absolute width and height used to resolve the scale components.
	@return Vector2 -- Absolute X/Y offsets produced by multiplying each scale component by the corresponding size.
]=]
function UDimUtil.ScaleToOffset(scale: Vector2, absoluteSize: Vector2): Vector2
	return Vector2.new(scale.X * absoluteSize.X, scale.Y * absoluteSize.Y)
end

--[=[
	Converts absolute X/Y offsets into normalized scale values relative to a known
	container or viewport size.

	@param offset Vector2 -- Absolute X/Y offsets to convert.
	@param absoluteSize Vector2 -- Non-zero absolute width and height used as the conversion basis.
	@return Vector2 -- Normalized X/Y scale components.
]=]
function UDimUtil.OffsetToScale(offset: Vector2, absoluteSize: Vector2): Vector2
	assert(absoluteSize.X ~= 0 and absoluteSize.Y ~= 0, "UDim.OffsetToScale absoluteSize components must be non-zero")
	return Vector2.new(offset.X / absoluteSize.X, offset.Y / absoluteSize.Y)
end

--[=[
	Resolves a UDim2 into its final absolute X/Y values for a supplied container
	size by combining each axis's scale and offset components.

	@param value UDim2 -- UDim2 whose X and Y components should be resolved.
	@param absoluteSize Vector2 -- Absolute width and height used for the scale portions.
	@return Vector2 -- Final absolute X/Y values represented by the UDim2.
]=]
function UDimUtil.Resolve(value: UDim2, absoluteSize: Vector2): Vector2
	return Vector2.new(
		value.X.Scale * absoluteSize.X + value.X.Offset,
		value.Y.Scale * absoluteSize.Y + value.Y.Offset
	)
end

return table.freeze(UDimUtil)
