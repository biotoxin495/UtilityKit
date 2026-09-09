--!strict

local UDimUtil = {}

function UDimUtil.ScaleToOffset(scale: Vector2, absoluteSize: Vector2): Vector2
	return Vector2.new(scale.X * absoluteSize.X, scale.Y * absoluteSize.Y)
end

function UDimUtil.OffsetToScale(offset: Vector2, absoluteSize: Vector2): Vector2
	assert(absoluteSize.X ~= 0 and absoluteSize.Y ~= 0, "UDim.OffsetToScale absoluteSize components must be non-zero")
	return Vector2.new(offset.X / absoluteSize.X, offset.Y / absoluteSize.Y)
end

function UDimUtil.Resolve(value: UDim2, absoluteSize: Vector2): Vector2
	return Vector2.new(
		value.X.Scale * absoluteSize.X + value.X.Offset,
		value.Y.Scale * absoluteSize.Y + value.Y.Offset
	)
end

return table.freeze(UDimUtil)
