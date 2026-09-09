# UtilityKit — Dependency-free stateless utilities for Roblox

**UtilityKit**, a focused, dependency-free collection of stateless utilities for Roblox and Luau.

Common table operations, random selection, number and time formatting, vector searches, `UDim2` conversions, and string helpers are easy to reimplement inconsistently across a project.

**UtilityKit** collects those predictable operations behind a small namespaced API. It does not create Instances, connect events, read the current camera, manage UI state, or depend on project-specific configuration schemas.

## Quick example

```lua
local UtilityKit = require(path.To.UtilityKit)

local settings = UtilityKit.Table.DeepMerge(defaults, overrides)
local reward = UtilityKit.Random.WeightedChoice(weightedRewards)
local timeText = UtilityKit.Time.FormatDuration(3_661)
```

Every module is stateless apart from UtilityKit's shared default pseudorandom generator. Functions are suitable for both server and client code, and optional `Random` instances make random behavior reproducible.

## 🚀 Features

- Namespaced API with no global state beyond a default pseudorandom generator.
- Strict Luau annotations.
- No third-party runtime dependencies.
- Shared server and client support.
- Cycle-safe deep copying.
- Optional deterministic `Random` instances.
- Explicit mutation behavior.
- Rojo project and dependency-free Studio tests included.

## Project Structure

```text
UtilityKit/
├── src/
│   ├── init.lua
│   ├── Table.lua
│   ├── Random.lua
│   ├── Number.lua
│   ├── Time.lua
│   ├── Vector.lua
│   ├── UDim.lua
│   └── String.lua
├── tests/
│   └── init.server.lua
├── examples/
│   └── BasicUsage.client.lua
├── default.project.json
├── dev.project.json
├── wally.toml
├── stylua.toml
├── selene.toml
└── LICENSE
```

## 🛠️ Installation

### Manual

Copy the `src` directory into your project and make it a ModuleScript container named `UtilityKit`. The `init.lua` file is the package entry point and the other files become its child ModuleScripts.

```lua
local UtilityKit = require(game.ReplicatedStorage.UtilityKit)
```

### Rojo

The package-oriented `default.project.json` builds UtilityKit as a standalone ModuleScript. For development and tests, `dev.project.json` maps the library to `ReplicatedStorage.UtilityKit` and the runner to `ServerScriptService.UtilityKitTests`.

```bash
rojo serve dev.project.json
```

Start a Studio play session after connecting Rojo. The test runner prints a success message or reports individual failures in the output.

### Wally

Before publishing, replace `your-scope` in `wally.toml` with your Wally scope. After the package is published, consumers can add it to their dependencies and require it from their generated Packages folder.

## 📖 Basic Usage

All functions use dot syntax through their namespace:

```lua
UtilityKit.Table.Count(value)
UtilityKit.Random.Choice(items)
UtilityKit.Number.FormatCompact(value)
```

Functions return `nil` when an empty collection has no meaningful result, and invalid arguments that indicate programmer error raise an assertion or error. Functions are non-mutating unless their name ends in `InPlace` or explicitly documents mutation.

### Design Rules

- All functions use dot syntax: `UtilityKit.Table.Count(value)`.
- Functions do not require constructors or service loaders.
- Functions return `nil` when an empty collection has no meaningful result.
- Invalid arguments that indicate programmer error raise an assertion or error.
- Functions are non-mutating unless their name ends in `InPlace` or explicitly documents mutation.
- Random functions accept an optional `Random` instance for reproducible behavior.
- Modules and the root export are shallow-frozen.

### Example

```lua
local UtilityKit = require(game.ReplicatedStorage.UtilityKit)

local defaults = {
	Audio = {
		Music = true,
		SFX = true,
	},
}

local overrides = {
	Audio = {
		Music = false,
	},
}

local settings = UtilityKit.Table.DeepMerge(defaults, overrides)
print(settings.Audio.Music) -- false
print(defaults.Audio.Music) -- true; the original was not mutated

print(UtilityKit.Number.FormatThousands(1250000)) -- 1,250,000
print(UtilityKit.Time.FormatClock(65)) -- 01:05
print(UtilityKit.String.ToSnakeCase("Daily Reward Count")) -- daily_reward_count
```

# ⚙️ API Reference

## `UtilityKit.Table`

Utilities for dictionaries, arrays, nested data, copying, merging, and change detection.

### `Table.Count`

```lua
Table.Count(source: {[any]: any}): number
```

Returns the number of key-value entries in a table. Unlike `#source`, this works for dictionaries and mixed tables.

```lua
Table.Count({A = 1, B = 2}) -- 2
```

### `Table.Keys`

```lua
Table.Keys(source: {[any]: any}): {any}
```

Returns an array containing every key in `source`. Dictionary iteration order is not guaranteed.

```lua
local keys = Table.Keys({Coins = 10, Gems = 2})
```

### `Table.Values`

```lua
Table.Values(source: {[any]: any}): {any}
```

Returns an array containing every value in `source`. Dictionary iteration order is not guaranteed.

```lua
local values = Table.Values({Coins = 10, Gems = 2})
```

### `Table.ShallowCopy`

```lua
Table.ShallowCopy(source: {[any]: any}): {[any]: any}
```

Creates a shallow copy using `table.clone`. Nested tables remain shared with the original.

```lua
local copy = Table.ShallowCopy(original)
```

### `Table.DeepCopy`

```lua
Table.DeepCopy(value: any, preserveMetatable: boolean?): any
```

Recursively copies tables while preserving cycles and shared references. Non-table values are returned unchanged. Metatable references are preserved by default; pass `false` to omit metatables.

```lua
local shared = {Value = 5}
local source = {A = shared, B = shared}
source.Self = source

local copy = Table.DeepCopy(source)
assert(copy ~= source)
assert(copy.A == copy.B)
assert(copy.Self == copy)
```

Metatables are not recursively cloned. A copied table receives the same metatable reference when that metatable is accessible and is itself a table.

### `Table.DeepEqual`

```lua
Table.DeepEqual(left: any, right: any): boolean
```

Recursively compares values and supports cyclic tables. Metatables are ignored. Table keys are matched by normal Luau key equality rather than structurally deep-compared.

```lua
Table.DeepEqual({A = {B = 2}}, {A = {B = 2}}) -- true
```

### `Table.DeepMerge`

```lua
Table.DeepMerge(base: {[any]: any}, incoming: {[any]: any}): {[any]: any}
```

Returns a deep-copied merge without mutating either input. When both values at a key are tables, their entries are recursively merged. Otherwise, the incoming value replaces the base value.

```lua
local result = Table.DeepMerge(
	{Audio = {Music = true}},
	{Audio = {SFX = true}}
)

-- result.Audio contains Music and SFX
```

Numeric keys are merged like any other keys. This means arrays are merged by index and a shorter incoming array does not automatically truncate the original array.

### `Table.DeepMergeInPlace`

```lua
Table.DeepMergeInPlace(base: {[any]: any}, incoming: {[any]: any}): {[any]: any}
```

Recursively merges `incoming` into `base` and returns `base`. This function mutates `base`. Incoming replacement values are deep-copied before assignment.

```lua
Table.DeepMergeInPlace(settings, overrides)
```

### `Table.Unique`

```lua
Table.Unique(values: {any}): {any}
```

Returns the first occurrence of each unique array value while preserving encounter order.

```lua
Table.Unique({"A", "A", "B"}) -- {"A", "B"}
```

Values use normal table-key equality. This works well for strings, numbers, booleans, enums, instances, and reference-identity values.

### `Table.Difference`

```lua
Table.Difference(first: {any}, second: {any}): {any}
```

Returns unique values present in `first` but absent from `second`, preserving the order from `first`.

```lua
Table.Difference({1, 2, 3}, {2, 4}) -- {1, 3}
```

### `Table.Intersection`

```lua
Table.Intersection(first: {any}, second: {any}): {any}
```

Returns unique values present in both arrays, preserving their order from `first`.

```lua
Table.Intersection({1, 2, 3}, {2, 4}) -- {2}
```

### `Table.GetPath`

```lua
Table.GetPath(root: any, path: {any}, defaultValue: any?): any
```

Reads a nested value using an array of keys. Returns `defaultValue` when the path cannot be traversed or the final value is `nil`.

```lua
local coins = Table.GetPath(data, {"Inventory", "Coins"}, 0)
```

An empty path returns `root`.

### `Table.SetPath`

```lua
Table.SetPath(root: {[any]: any}, path: {any}, value: any): {[any]: any}
```

Writes a nested value and creates missing intermediate tables. Returns `root` for chaining. It errors when the path is empty or an existing intermediate value is not a table.

```lua
Table.SetPath(data, {"Inventory", "Coins"}, 100)
```

This function mutates `root`.

### `Table.Diff`

```lua
Table.Diff(oldValue: {[any]: any}, newValue: {[any]: any}): {DiffOperation}
```

Produces structured operations describing how to transform `oldValue` into `newValue`.

```lua
export type DiffOperation = {
	Kind: "Set" | "Remove",
	Path: {any},
	Value: any?,
}
```

Example:

```lua
local operations = Table.Diff(
	{Coins = 10, OldItem = true},
	{Coins = 20, Gems = 2}
)
```

Possible operations include:

```lua
{
	{Kind = "Set", Path = {"Coins"}, Value = 20},
	{Kind = "Set", Path = {"Gems"}, Value = 2},
	{Kind = "Remove", Path = {"OldItem"}},
}
```

Operation order is not guaranteed for dictionary keys. Set values are deep-copied. Cyclic table pairs are guarded against, although diffs are primarily intended for ordinary serializable data tables.

## `UtilityKit.Random`

Random-selection helpers built on Roblox's `Random` datatype. Every function accepts an optional `Random` object; supplying one makes tests and procedural generation reproducible.

```lua
local random = Random.new(12345)
local item = RandomUtil.Choice(items, random)
```

When omitted, UtilityKit uses a shared internal generator.

### `Random.Integer`

```lua
Random.Integer(minimum: number, maximum: number, random: Random?): number
```

Returns an integer uniformly selected from the inclusive range `[minimum, maximum]`. Both bounds must be integers and `minimum` cannot exceed `maximum`.

```lua
RandomUtil.Integer(1, 6) -- inclusive dice roll
```

### `Random.Float`

```lua
Random.Float(minimum: number?, maximum: number?, random: Random?): number
```

Returns a pseudorandom number between the provided bounds. The defaults are `0` and `1`. Bounds must be finite and ordered.

```lua
RandomUtil.Float()       -- 0 to 1
RandomUtil.Float(-5, 5)  -- -5 to 5
```

### `Random.Choice`

```lua
Random.Choice<T>(items: {T}, random: Random?): T?
```

Returns one uniformly selected array item, or `nil` when the array is empty.

```lua
local color = RandomUtil.Choice({"Red", "Blue", "Green"})
```

### `Random.DictionaryEntry`

```lua
Random.DictionaryEntry(dictionary: {[any]: any}, random: Random?): (any?, any?)
```

Returns a randomly selected key and its value. Returns `nil, nil` when the dictionary is empty.

```lua
local key, value = RandomUtil.DictionaryEntry(rewards)
```

Each call allocates a temporary key array, so repeated selection from a large stable dictionary should use a cached key array instead.

### `Random.WeightedChoice`

```lua
Random.WeightedChoice<T>(items: {WeightedItem<T>}, random: Random?): T?
```

Weighted entries use this shape:

```lua
export type WeightedItem<T> = {
	Value: T,
	Weight: number,
}
```

Returns a value with probability proportional to its non-negative weight. Zero-weight entries are ignored. Returns `nil` when the list is empty or every weight is zero. Negative, infinite, and NaN weights raise an error.

```lua
local reward = RandomUtil.WeightedChoice({
	{Value = "Coins", Weight = 70},
	{Value = "Gems", Weight = 25},
	{Value = "RareItem", Weight = 5},
})
```

Fractional weights are supported.

### `Random.Shuffle`

```lua
Random.Shuffle<T>(items: {T}, random: Random?): {T}
```

Returns a shuffled shallow copy. The input array is not mutated. Sparse arrays are not supported because Roblox's built-in shuffle operation requires a contiguous array.

```lua
local shuffled = RandomUtil.Shuffle({1, 2, 3, 4})
```

### `Random.Sample`

```lua
Random.Sample<T>(items: {T}, count: number, random: Random?): {T}
```

Returns `count` unique array entries sampled without replacement. The input is not mutated. `count` must be a non-negative integer no greater than the array length.

```lua
local selected = RandomUtil.Sample(players, 3)
```

## `UtilityKit.Number`

Numeric calculations and predictable display formatting.

### `Number.IsFinite`

```lua
Number.IsFinite(value: number): boolean
```

Returns `false` for positive infinity, negative infinity, and NaN; otherwise returns `true`.

```lua
NumberUtil.IsFinite(10)        -- true
NumberUtil.IsFinite(math.huge) -- false
```

### `Number.Average`

```lua
Number.Average(values: {number}): number?
```

Returns the arithmetic mean, or `nil` for an empty array.

```lua
NumberUtil.Average({2, 4, 6}) -- 4
```

### `Number.MinMax`

```lua
Number.MinMax(values: {number}): (number?, number?)
```

Returns the smallest and largest values in one pass. Returns `nil, nil` for an empty array.

```lua
local minimum, maximum = NumberUtil.MinMax({7, 2, 9})
```

### `Number.RoundTo`

```lua
Number.RoundTo(value: number, decimalPlaces: number?): number
```

Rounds to the requested number of decimal places. The default is `0`. Negative decimal places round to tens, hundreds, and larger powers of ten.

```lua
NumberUtil.RoundTo(1.235, 2) -- 1.24
NumberUtil.RoundTo(126, -1)  -- 130
```

### `Number.RoundToStep`

```lua
Number.RoundToStep(value: number, step: number): number
```

Rounds to the nearest multiple of a positive finite step.

```lua
NumberUtil.RoundToStep(27, 5) -- 25
```

### `Number.Normalize`

```lua
Number.Normalize(
	value: number,
	inputMinimum: number,
	inputMaximum: number,
	clampResult: boolean?
): number
```

Maps an input range to normalized space, where `inputMinimum` is `0` and `inputMaximum` is `1`. When `clampResult` is true, results are clamped to `[0, 1]`.

```lua
NumberUtil.Normalize(5, 0, 10) -- 0.5
```

The input range cannot have zero length. Reversed ranges are supported.

### `Number.MapRange`

```lua
Number.MapRange(
	value: number,
	inputMinimum: number,
	inputMaximum: number,
	outputMinimum: number,
	outputMaximum: number,
	clampResult: boolean?
): number
```

Maps a value from one numeric range into another. When `clampResult` is true, the normalized input is clamped before it is mapped.

```lua
NumberUtil.MapRange(5, 0, 10, 0, 100) -- 50
```

### `Number.FormatThousands`

```lua
Number.FormatThousands(
	value: number,
	decimalPlaces: number?,
	thousandsSeparator: string?,
	decimalSeparator: string?
): string
```

Formats a finite number with grouped thousands.

```lua
NumberUtil.FormatThousands(1234567)       -- "1,234,567"
NumberUtil.FormatThousands(1234.5, 2)     -- "1,234.50"
NumberUtil.FormatThousands(1234.5, 1, " ", ",") -- "1 234,5"
```

When `decimalPlaces` is omitted, UtilityKit preserves the ordinary decimal representation produced by `tostring`. Scientific-notation strings are returned unchanged.

### `Number.FormatCompact`

```lua
Number.FormatCompact(value: number, decimalPlaces: number?): string
```

Formats large finite values using compact suffixes: `K`, `M`, `B`, `T`, and `Q`. The default precision is one decimal place, and trailing zeroes are removed.

```lua
NumberUtil.FormatCompact(1500)       -- "1.5K"
NumberUtil.FormatCompact(2000000)    -- "2M"
```

### `Number.DiscountPercent`

```lua
Number.DiscountPercent(oldPrice: number, newPrice: number, roundStep: number?): number
```

Calculates the percentage reduction from `oldPrice` to `newPrice`. `oldPrice` must be greater than zero. Supplying `roundStep` rounds the result to the nearest step.

```lua
NumberUtil.DiscountPercent(100, 72)    -- 28
NumberUtil.DiscountPercent(100, 72, 5) -- 30
```

A negative result represents a price increase.

### `Number.OrdinalSuffix`

```lua
Number.OrdinalSuffix(value: number): string
```

Returns the English ordinal suffix for the integer portion of a value.

```lua
NumberUtil.OrdinalSuffix(1)  -- "st"
NumberUtil.OrdinalSuffix(12) -- "th"
NumberUtil.OrdinalSuffix(23) -- "rd"
```

### `Number.FormatOrdinal`

```lua
Number.FormatOrdinal(value: number): string
```

Appends the English ordinal suffix to the original value.

```lua
NumberUtil.FormatOrdinal(23) -- "23rd"
```

## `UtilityKit.Time`

Duration, clock, relative-time, ISO, date, and day-part utilities.

### `Time.SplitDuration`

```lua
Time.SplitDuration(totalSeconds: number): DurationParts
```

Returns whole day, hour, minute, and second components based on the absolute, floored duration.

```lua
export type DurationParts = {
	IsNegative: boolean,
	Days: number,
	Hours: number,
	Minutes: number,
	Seconds: number,
}
```

```lua
local parts = TimeUtil.SplitDuration(90061)
-- Days = 1, Hours = 1, Minutes = 1, Seconds = 1
```

### `Time.FormatClock`

```lua
Time.FormatClock(totalSeconds: number, options: ClockOptions?): string
```

Options:

```lua
export type ClockOptions = {
	AlwaysShowHours: boolean?,
	DecimalPlaces: number?,
}
```

Formats a duration as `MM:SS` or `HH:MM:SS`. Hours appear when non-zero or when `AlwaysShowHours` is true. `DecimalPlaces` controls fractional seconds and defaults to zero.

```lua
TimeUtil.FormatClock(65) -- "01:05"
TimeUtil.FormatClock(65, {AlwaysShowHours = true}) -- "00:01:05"
TimeUtil.FormatClock(65.25, {DecimalPlaces = 2}) -- "01:05.25"
```

Negative durations receive a leading minus sign.

### `Time.FormatDuration`

```lua
Time.FormatDuration(totalSeconds: number, maxUnits: number?): string
```

Returns a compact duration using `d`, `h`, `m`, and `s`. At most two non-zero units are shown by default.

```lua
TimeUtil.FormatDuration(3661)    -- "1h 1m"
TimeUtil.FormatDuration(3661, 3) -- "1h 1m 1s"
TimeUtil.FormatDuration(0)       -- "0s"
```

### `Time.FormatRelative`

```lua
Time.FormatRelative(targetUnix: number, options: RelativeOptions?): string
```

Options:

```lua
export type RelativeOptions = {
	Now: number?,
}
```

Returns English relative text such as `"in 3 hours"`, `"2 days ago"`, or `"now"`. By default, the current timestamp comes from `DateTime.now().UnixTimestamp`. Pass `Now` for deterministic tests or snapshots.

```lua
TimeUtil.FormatRelative(1060, {Now = 1000}) -- "in 1 minute"
```

Months and years use average Gregorian durations, so this is human-readable approximation rather than calendar arithmetic.

### `Time.FormatDate`

```lua
Time.FormatDate(unixTimestamp: number, options: DateOptions?): string
```

Options:

```lua
export type DateOptions = {
	UTC: boolean?,          -- default true
	IncludeYear: boolean?,  -- default true
	Separator: string?,     -- default "/"
	Order: "DMY" | "MDY" | "YMD"?, -- default "DMY"
}
```

Formats a numeric date with zero-padded day and month components.

```lua
TimeUtil.FormatDate(0) -- "01/01/1970"
TimeUtil.FormatDate(0, {Order = "YMD", Separator = "-"}) -- "1970-01-01"
TimeUtil.FormatDate(0, {IncludeYear = false}) -- "01/01"
```

Set `UTC = false` to use the runtime's local date representation.

### `Time.IsoToUnix`

```lua
Time.IsoToUnix(isoDate: string): number?
```

Parses an ISO-8601 date using Roblox's `DateTime.fromIsoDate`. Returns its Unix timestamp, or `nil` when parsing fails.

```lua
local timestamp = TimeUtil.IsoToUnix("2026-08-07T00:00:00Z")
```

### `Time.UnixToIso`

```lua
Time.UnixToIso(unixTimestamp: number): string
```

Converts a Unix timestamp into Roblox's ISO-8601 representation using `DateTime:ToIsoDate`.

```lua
local iso = TimeUtil.UnixToIso(1700000000)
```

### `Time.GetDayPart`

```lua
Time.GetDayPart(hour: number, divisions: {DayPart}?): (string?, number?)
```

Returns the matching day-part name and its one-based index. `hour` must be in `[0, 24)`.

Default divisions:

| Hours | Name |
|---|---|
| `[0, 4)` | Late Night |
| `[4, 8)` | Early Morning |
| `[8, 12)` | Morning |
| `[12, 16)` | Afternoon |
| `[16, 20)` | Evening |
| `[20, 24)` | Late Evening |

```lua
local name, index = TimeUtil.GetDayPart(14)
-- "Afternoon", 4
```

Custom entries use:

```lua
export type DayPart = {
	Name: string,
	StartHour: number,
	EndHour: number,
}
```

Intervals include `StartHour` and exclude `EndHour`. Returns `nil, nil` when custom divisions do not cover the requested hour.

## `UtilityKit.Vector`

Nearest and furthest lookup for `Vector2` and `Vector3` values.

### `Vector.Closest`

```lua
Vector.Closest<T>(
	items: {T},
	target: Vector2 | Vector3,
	selector: ((T) -> (Vector2 | Vector3))?
): (T?, number?, number?)
```

Returns the closest item, its one-based index, and its distance. Returns `nil, nil, nil` for an empty array.

```lua
local position, index, distance = VectorUtil.Closest(
	{Vector3.new(1, 0, 0), Vector3.new(5, 0, 0)},
	Vector3.zero
)
```

Use a selector for records or instances:

```lua
local player, index, distance = VectorUtil.Closest(players, origin, function(candidate)
	return candidate.Character:GetPivot().Position
end)
```

The target and every selected position must use the same vector type.

### `Vector.Furthest`

```lua
Vector.Furthest<T>(
	items: {T},
	target: Vector2 | Vector3,
	selector: ((T) -> (Vector2 | Vector3))?
): (T?, number?, number?)
```

Returns the furthest item, its one-based index, and its distance. Behavior and selector requirements match `Vector.Closest`.

## `UtilityKit.UDim`

Conversions that require an explicit absolute size rather than reading the current camera or GUI hierarchy.

### `UDim.ScaleToOffset`

```lua
UDim.ScaleToOffset(scale: Vector2, absoluteSize: Vector2): Vector2
```

Converts X/Y scale components to pixel offsets.

```lua
UDimUtil.ScaleToOffset(
	Vector2.new(0.5, 0.25),
	Vector2.new(200, 400)
) -- Vector2.new(100, 100)
```

### `UDim.OffsetToScale`

```lua
UDim.OffsetToScale(offset: Vector2, absoluteSize: Vector2): Vector2
```

Converts pixel offsets to X/Y scale components. Both components of `absoluteSize` must be non-zero.

```lua
UDimUtil.OffsetToScale(
	Vector2.new(100, 100),
	Vector2.new(200, 400)
) -- Vector2.new(0.5, 0.25)
```

### `UDim.Resolve`

```lua
UDim.Resolve(value: UDim2, absoluteSize: Vector2): Vector2
```

Resolves a `UDim2` into its final pixel-space vector using `scale * absoluteSize + offset` for both axes.

```lua
UDimUtil.Resolve(
	UDim2.new(0.5, 10, 0.25, -5),
	Vector2.new(200, 400)
) -- Vector2.new(110, 95)
```

## `UtilityKit.String`

Small string predicates, Lua-pattern safety, and identifier-style conversion.

### `String.Trim`

```lua
String.Trim(value: string): string
```

Removes leading and trailing whitespace.

```lua
StringUtil.Trim("  hello  ") -- "hello"
```

### `String.StartsWith`

```lua
String.StartsWith(value: string, prefix: string): boolean
```

Returns whether `value` begins with `prefix`. An empty prefix returns true.

```lua
StringUtil.StartsWith("UtilityKit", "Utility") -- true
```

### `String.EndsWith`

```lua
String.EndsWith(value: string, suffix: string): boolean
```

Returns whether `value` ends with `suffix`. An empty suffix returns true.

```lua
StringUtil.EndsWith("UtilityKit", "Kit") -- true
```

### `String.EscapePattern`

```lua
String.EscapePattern(value: string): string
```

Escapes non-alphanumeric characters so a string can be used as literal content inside a Luau pattern.

```lua
local literal = StringUtil.EscapePattern("a+b") -- "a%+b"
string.find("value a+b here", literal)
```

For plain searching, `string.find(haystack, needle, 1, true)` is usually simpler and avoids pattern processing entirely.

### `String.ToSnakeCase`

```lua
String.ToSnakeCase(value: string): string
```

Splits separators and common camel/Pascal-case boundaries, lowercases words, and joins them with underscores.

```lua
StringUtil.ToSnakeCase("DailyReward Count") -- "daily_reward_count"
```

### `String.ToKebabCase`

```lua
String.ToKebabCase(value: string): string
```

Converts text to lowercase kebab case.

```lua
StringUtil.ToKebabCase("DailyReward Count") -- "daily-reward-count"
```

### `String.ToPascalCase`

```lua
String.ToPascalCase(value: string): string
```

Converts text to PascalCase.

```lua
StringUtil.ToPascalCase("daily_reward count") -- "DailyRewardCount"
```

### `String.ToCamelCase`

```lua
String.ToCamelCase(value: string): string
```

Converts text to camelCase.

```lua
StringUtil.ToCamelCase("daily_reward count") -- "dailyRewardCount"
```

Case conversion is ASCII-oriented and intended for identifiers rather than natural-language localization.

# 🧪 Testing

The repository includes a dependency-free Studio test runner covering every public entry.

1. Sync the project through Rojo.
2. Start a server or local play session.
3. Read the Studio output.

Successful output ends with:

```text
UtilityKit tests passed: 7
```

Each number represents one module-level test group. Individual assertions within those groups cover every exported function.

# 📝 Notes

## Scope Decisions

The following utilities from the original internal collection are intentionally not part of UtilityKit:

- Tween and animation helpers.
- GUI visibility and tap-outside controllers.
- Connection lifecycle storage.
- Text counting animations.
- Automatic text measurement and resizing.
- Current-camera or viewport lookups.
- Badge-schema queries.
- Project service-loader fields such as `ServiceName` and `__index`.
- Random values described as Roblox user IDs.

Those features either hold state, mutate Instances, require services or project configuration, or deserve focused packages of their own.

## Versioning

UtilityKit follows Semantic Versioning:

- Patch releases fix behavior without changing the documented API.
- Minor releases add backward-compatible entries.
- Major releases may rename, remove, or change established behavior.

## License

UtilityKit is available under the MIT License. See [`LICENSE`](LICENSE).

## Platform References

- Roblox [`Random`](https://create.roblox.com/docs/reference/engine/datatypes/Random)
- Roblox [`DateTime`](https://create.roblox.com/docs/reference/engine/datatypes/DateTime)
- Luau standard library, including `table.clone` and `table.freeze`: <https://luau.org/library/>
