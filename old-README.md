# Dropdown — Dependency-free dropdown UI controller for Roblox

**Dropdown**, a flexible, dependency-free dropdown UI controller for Roblox.

Turning a `GuiButton` into a dropdown usually means manually building option rendering, selection state, positioning, outside-click detection, and cleanup logic by hand.

**Dropdown** handles this for you. It can generate its own dropdown interface automatically, or it can control completely custom Studio-authored dropdowns and entry templates.

## Quick example

```lua
local Dropdown = require(ReplicatedStorage:WaitForChild("Dropdown"))

local dropdown = Dropdown.new(script.Parent.SortButton, {
	Options = {
		{ Id = "rarity", Text = "Rarity" },
		{ Id = "newest", Text = "Newest" },
		{ Id = "game", Text = "Game" },
	},
})

dropdown.Selected:Connect(function(option)
	print("Selected:", option.Id)
end)
```

The module automatically connects to the trigger button, creates the dropdown and its entries, positions the dropdown, handles selection, closes on outside clicks, and cleans up its connections when destroyed.

## 🚀 Features

- Attach a dropdown to any `GuiButton`
- Automatically generated dropdown UI
- Custom dropdown instances and templates
- Custom entry templates
- Custom entry renderers
- Single-selection dropdowns
- Multiple-selection dropdowns
- Action menus with no managed selection
- Dynamic option datasets
- Disabled options
- Automatic dropdown positioning
- Bottom, top, left, right, and automatic placement
- Automatic screen-edge flipping
- Screen-bound clamping
- Automatic sizing and scrolling
- Outside-click closing
- Escape-to-close support
- Exclusive dropdown behavior
- Optional trigger text synchronization
- Overlay rendering to avoid `ClipsDescendants`
- Lightweight open/close scale animation
- Per-dropdown state and connection management
- Complete lifecycle cleanup
- No external dependencies

## 🛠️ Installation

Place the `Dropdown` ModuleScript somewhere that client code can access it.

A common setup is:

```text
ReplicatedStorage
└── Dropdown
```

Then require it from a LocalScript:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dropdown = require(ReplicatedStorage:WaitForChild("Dropdown"))
```

`Dropdown` is intended for client-side UI code.

## 📖 Basic Usage

Create a dropdown by supplying a trigger button and a configuration table.

```lua
local dropdown = Dropdown.new(triggerButton, config)
```

`triggerButton` must be a `GuiButton`, such as a `TextButton` or `ImageButton`.

By default, pressing the trigger toggles the dropdown open and closed. Disable that with `ToggleOnTrigger = false` if you’d rather drive `Open`/`Close`/`Toggle` yourself.

When the dropdown is no longer needed, call `Destroy`:

```lua
dropdown:Destroy()
```

## Options

Dropdown options are data-driven.

A normal option can look like:

```lua
{
	Id = "rare",
	Text = "Rare",
	Value = 4,
	Disabled = false,
}
```

Only `Id` is important to the dropdown’s internal selection system.

### `Id`

```lua
Id = "rare"
```

Unique identifier for the option. IDs should be unique within a dropdown. If omitted, the option’s array index is used.

### `Text`

```lua
Text = "Rare"
```

Text displayed by the default renderer. If omitted, the module attempts to derive text from `Name`, `Value`, or `Id`.

### `Value`

```lua
Value = 4
```

Optional application-specific value associated with the option. This can be anything your application needs — the dropdown uses `Id` for selection state while your game can use `Value`.

### `Disabled`

```lua
Disabled = true
```

Prevents the option from being selected. Disabled generated entries also use the configured disabled visual style.

### Simple Values

Options do not have to be full tables.

```lua
Options = {
	"Rarity",
	"Newest",
	"Game",
}
```

The module automatically normalizes these into option objects. For more advanced dropdowns, explicit option tables are recommended.

## Selection Modes

There are three selection modes.

### Single Selection

The default mode.

```lua
local dropdown = Dropdown.new(Button, {
	SelectionMode = "Single",

	Options = {
		{ Id = "rarity", Text = "Rarity" },
		{ Id = "newest", Text = "Newest" },
		{ Id = "game", Text = "Game" },
	},
})
```

Only one option can be selected at a time. By default, the dropdown closes after a selection.

### Multiple Selection

Useful for filters and checklists.

```lua
local dropdown = Dropdown.new(Button, {
	SelectionMode = "Multiple",
	CloseOnSelect = false,

	Options = {
		{ Id = "common", Text = "Common" },
		{ Id = "rare", Text = "Rare" },
		{ Id = "epic", Text = "Epic" },
	},
})
```

Retrieve selected IDs with `dropdown:GetSelected()`, or full option objects with `dropdown:GetSelectedOptions()`.

### No Selection

Use `"None"` when the dropdown represents actions rather than persistent choices.

```lua
local dropdown = Dropdown.new(Button, {
	SelectionMode = "None",

	Options = {
		{ Id = "duplicate", Text = "Duplicate" },
		{ Id = "rename", Text = "Rename" },
		{ Id = "delete", Text = "Delete" },
	},
})

dropdown.Selected:Connect(function(option)
	print("Action:", option.Id)
end)
```

This is useful for context menus, action menus, overflow menus, and command lists.

## Default Selection

For single-selection dropdowns:

```lua
local dropdown = Dropdown.new(Button, {
	Selected = "newest",

	Options = {
		{ Id = "rarity", Text = "Rarity" },
		{ Id = "newest", Text = "Newest" },
	},
})
```

For multiple-selection dropdowns:

```lua
local dropdown = Dropdown.new(Button, {
	SelectionMode = "Multiple",
	Selected = { "common", "rare" },

	Options = {
		{ Id = "common", Text = "Common" },
		{ Id = "rare", Text = "Rare" },
		{ Id = "epic", Text = "Epic" },
	},
})
```

## Dynamic Options

Options can be replaced at runtime.

```lua
dropdown:SetOptions({
	{ Id = "one", Text = "One" },
	{ Id = "two", Text = "Two" },
	{ Id = "three", Text = "Three" },
})
```

The dropdown automatically rebuilds its entries and drops any selection values that no longer exist. Additional helpers are available:

```lua
dropdown:AddOption({ Id = "four", Text = "Four" })
dropdown:RemoveOption("two")
dropdown:ClearOptions()
```

## Reading Selection

### Single Selection

```lua
local selectedId = dropdown:GetSelected()

local option = dropdown:GetSelectedOption()
if option then
	print(option.Text)
	print(option.Value)
end
```

### Multiple Selection

```lua
local selectedIds = dropdown:GetSelected()
local selectedOptions = dropdown:GetSelectedOptions()
```

## Changing Selection

```lua
dropdown:SetSelected("rare")
```

For multiple-selection dropdowns:

```lua
dropdown:SetSelected("rare", true)
dropdown:SetSelected("epic", true)
dropdown:SetSelected("common", false)
```

Clear all selection with `dropdown:ClearSelection()`.

## Opening and Closing

```lua
dropdown:Open()
dropdown:Close()
dropdown:Toggle()

if dropdown:IsOpen() then
	print("Dropdown is open")
end
```

## Trigger Behavior

By default, pressing the supplied trigger button toggles the dropdown. Disable that behavior with:

```lua
ToggleOnTrigger = false
```

You can then control the dropdown manually:

```lua
Button.Activated:Connect(function()
	dropdown:Open()
end)
```

## Updating Trigger Text

Generated dropdowns do not modify the trigger’s text unless requested.

```lua
local dropdown = Dropdown.new(Button, {
	UpdateTriggerText = true,

	Options = {
		{ Id = "rarity", Text = "Rarity" },
		{ Id = "newest", Text = "Newest" },
	},
})
```

With single selection, the selected option text becomes the button text. With multiple selection, the trigger displays the number of selected options. For full control, use `RenderTrigger`.

## Dropdown Placement

The dropdown can automatically position itself relative to its trigger.

```lua
Placement = "Auto"
```

Supported values: `Auto`, `Bottom`, `Top`, `Left`, `Right`.

`Auto` prefers placing the dropdown beneath the trigger and flips it upward when there is not enough room.

### Alignment

```lua
Alignment = "Start"
```

Supported values: `Start`, `Center`, `End`.

### Offset

```lua
Offset = Vector2.new(0, 6)
```

This adds spacing between the trigger and dropdown.

### Automatic Flipping

Enabled by default:

```lua
AutoFlip = true
```

For example, a dropdown configured for `"Bottom"` can automatically open above its trigger if there is not enough room beneath it.

### Screen Clamping

Enabled by default:

```lua
ClampToScreen = true
ScreenPadding = 8
```

This prevents the dropdown from extending beyond the visible UI area.

## Automatic Sizing

Generated dropdowns size themselves from their option count.

```lua
Width = 220
MinWidth = 160
MaxHeight = 280

EntryHeight = 38
EntryPadding = 4
ContentPadding = 6
```

When the option list becomes taller than `MaxHeight`, the generated dropdown becomes scrollable. If `Width` is omitted, the dropdown is at least as wide as its trigger.

## Open/Close Animation

Generated dropdowns animate open and closed with a `UIScale` tween by default.

```lua
Animation = {
	Enabled = true,
	Duration = 0.12,
	ClosedScale = 0.96,
	EasingStyle = Enum.EasingStyle.Quad,
	EasingDirection = Enum.EasingDirection.Out,
}
```

Set `Animation.Enabled = false` for the dropdown to appear and disappear instantly. When using an existing `DropdownInstance` or `DropdownTemplate` without a `UIScale`, the module creates one automatically so the animation still has something to drive.

## Styling Generated UI

The generated dropdown exposes property tables for its main visual states.

```lua
local dropdown = Dropdown.new(Button, {
	Style = {
		Container = {
			BackgroundColor3 = Color3.fromRGB(20, 22, 26),
		},

		Entry = {
			BackgroundColor3 = Color3.fromRGB(35, 38, 44),
			TextColor3 = Color3.fromRGB(240, 240, 240),
			TextSize = 16,
		},

		EntrySelected = {
			BackgroundColor3 = Color3.fromRGB(60, 110, 230),
		},

		EntryDisabled = {
			BackgroundTransparency = 0.35,
			TextTransparency = 0.45,
		},
	},
})
```

These tables are applied directly to the relevant generated Roblox Instances. Invalid properties produce a warning rather than breaking the dropdown.

## Custom Entry Templates

You can provide your own entry template.

```lua
local dropdown = Dropdown.new(Button, {
	EntryTemplate = EntryTemplate,
	Options = options,
})
```

The template is cloned once per option. If the entry itself is not a `GuiButton`, the module searches its descendants for one. For explicit control:

```lua
GetEntryButton = function(entry, option)
	return entry.Checkbox
end
```

## Custom Entry Rendering

For complete visual control, provide `RenderOption`.

```lua
local dropdown = Dropdown.new(Button, {
	EntryTemplate = EntryTemplate,

	GetEntryButton = function(entry)
		return entry.Checkbox
	end,

	RenderOption = function(entry, option, state)
		entry.TextLabel.Text = option.Text
		entry.SelectedIndicator.Visible = state.Selected
	end,

	Options = options,
})
```

The renderer receives `state.Selected`, `state.Disabled`, and `state.Index`. The module owns state and interactions while your renderer owns appearance.

## Custom Entry Creation

Instead of cloning `EntryTemplate`, entries can be created dynamically.

```lua
CreateEntry = function(option, index, dropdown)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40)
	button.Text = option.Text
	return button
end
```

The returned object must be a `GuiObject`.

## Custom Dropdown Templates

The entire dropdown container can also be replaced.

```lua
local dropdown = Dropdown.new(Button, {
	DropdownTemplate = MyDropdownTemplate,
	EntryTemplate = MyEntryTemplate,
	Options = options,
})
```

The dropdown template is cloned for this controller. The module still manages visibility, positioning, outside-click detection, selection, option rendering, lifecycle, and exclusivity.

### Entry Container

When using a custom dropdown template, tell the module where option entries should be parented:

```lua
EntryContainer = "Entries"
```

The name is searched recursively inside the dropdown. You can also provide the Instance directly, or use a resolver:

```lua
GetEntryContainer = function(dropdown)
	return dropdown.MainCategoryHolder.Scroll
end
```

If nothing is specified, the module attempts to find `Entries`, `Scroll`, or `Content`, and then falls back to the first `ScrollingFrame`.

## Existing Dropdown Instances

Instead of cloning a template, the module can control an existing UI object.

```lua
local dropdown = Dropdown.new(Button, {
	DropdownInstance = ExistingDropdown,
	EntryContainer = ExistingDropdown.Scroll,
	EntryTemplate = EntryTemplate,
	Options = options,
})
```

The caller retains ownership of `DropdownInstance`. Calling `dropdown:Destroy()` does not destroy the supplied dropdown instance, and its original visibility state is restored.

## Overlay / Portal Rendering

Generated dropdowns are automatically placed inside a transparent overlay under the trigger’s `ScreenGui`. This prevents common clipping problems caused by a `ClipsDescendants` ancestor. You can override its parent with:

```lua
Parent = MyOverlayFrame
```

## Exclusive Dropdowns

By default:

```lua
Exclusive = true
```

When one exclusive dropdown opens, another currently open exclusive dropdown closes. This prevents multiple normal dropdown menus from stacking on top of one another. Disable this behavior when needed with `Exclusive = false`.

## Closing Behavior

```lua
CloseOnSelect = true
CloseOnOutsideClick = true
CloseOnEscape = true
```

If `CloseOnSelect` is omitted, `"Single"` closes after selection, `"None"` closes after activation, and `"Multiple"` stays open.

## Enabling / Disabling

```lua
dropdown:SetEnabled(false)
```

A disabled dropdown cannot be opened or interacted with, and closes immediately if it was open. Check the state with `dropdown:IsEnabled()`.

## Signals

Every controller exposes four signals.

### `Opened`

```lua
dropdown.Opened:Connect(function()
	print("Opened")
end)
```

### `Closed`

```lua
dropdown.Closed:Connect(function()
	print("Closed")
end)
```

### `Selected`

Fires whenever an enabled option is activated.

```lua
dropdown.Selected:Connect(function(option, index)
	print(option.Id, index)
end)
```

This signal also works when `SelectionMode = "None"`, making it useful for action menus.

### `SelectionChanged`

Fires whenever managed selection changes.

```lua
dropdown.SelectionChanged:Connect(function(selected, selectedOptions)
	print(selected)
end)
```

For single-selection dropdowns, `selected` is the selected ID. For multiple-selection dropdowns, `selected` is an array of selected IDs. `selectedOptions` is always an array containing the selected option objects.

## ⚙️ API Reference

### `Dropdown.new`

```lua
Dropdown.new(triggerButton: GuiButton, config: table?)
```

Creates a dropdown controller.

### Visibility

```lua
dropdown:Open()
dropdown:Close()
dropdown:Toggle()
dropdown:IsOpen()
```

### Enabled State

```lua
dropdown:SetEnabled(enabled)
dropdown:IsEnabled()
```

### Options

```lua
dropdown:SetOptions(options)
dropdown:GetOptions()
dropdown:GetOption(id)

dropdown:AddOption(option)
dropdown:RemoveOption(id)
dropdown:ClearOptions()
```

### Selection

```lua
dropdown:SetSelected(id, selected)
dropdown:GetSelected()

dropdown:GetSelectedOption()
dropdown:GetSelectedOptions()

dropdown:ClearSelection()
```

### `Refresh`

```lua
dropdown:Refresh()
```

Re-renders all entries, updates generated sizing, refreshes positioning when open, and refreshes the trigger renderer. Useful when external data used by a custom renderer changes.

### `Destroy`

```lua
dropdown:Destroy()
```

Disconnects all controller connections and destroys module-owned UI and signals. Always call `Destroy()` when a dropdown controller is permanently no longer needed.

## Configuration Reference

A representative configuration looks like:

```lua
local dropdown = Dropdown.new(Button, {
	Options = {},

	SelectionMode = "Single",
	Selected = nil,

	Enabled = true,
	ToggleOnTrigger = true,

	CloseOnSelect = nil,
	CloseOnOutsideClick = true,
	CloseOnEscape = true,

	Exclusive = true,

	Placement = "Auto",
	Alignment = "Start",
	Offset = Vector2.new(0, 6),

	ScreenPadding = 8,
	AutoFlip = true,
	ClampToScreen = true,

	Width = nil,
	MinWidth = 160,
	MaxHeight = 280,

	EntryHeight = 38,
	EntryPadding = 4,
	ContentPadding = 6,

	ZIndex = 100,

	UpdateTriggerText = false,

	Animation = {
		Enabled = true,
		Duration = 0.12,
		ClosedScale = 0.96,
		EasingStyle = Enum.EasingStyle.Quad,
		EasingDirection = Enum.EasingDirection.Out,
	},

	Style = {
		Container = {},
		Entry = {},
		EntrySelected = {},
		EntryDisabled = {},
	},

	-- Optional custom UI:
	Parent = nil,
	DropdownInstance = nil,
	DropdownTemplate = nil,
	EntryContainer = nil,
	EntryTemplate = nil,

	-- Optional callbacks:
	GetEntryContainer = nil,
	GetEntryButton = nil,
	GetEntryLabel = nil,
	CreateEntry = nil,
	RenderOption = nil,
	RenderTrigger = nil,
	OnEntryCreated = nil,
	OnEntryDestroyed = nil,
})
```

You only need to specify values that differ from the defaults.

## Custom Trigger Rendering

Instead of `UpdateTriggerText`, provide your own renderer.

```lua
RenderTrigger = function(trigger, selectedOptions, dropdown)
	if #selectedOptions == 0 then
		trigger.Text = "Select rarity"
	else
		trigger.Text = selectedOptions[1].Text
	end
end
```

For multi-selection:

```lua
RenderTrigger = function(trigger, selectedOptions)
	trigger.Text = string.format("Filters (%d)", #selectedOptions)
end
```

## Entry Lifecycle Hooks

Integrate other UI systems without making them dependencies of `Dropdown`.

```lua
OnEntryCreated = function(entry, option, dropdown)
	GuiButtonEffects:Setup(entry)
end,

OnEntryDestroyed = function(entry, option, dropdown)
	GuiButtonEffects:Clear(entry)
end,
```

This makes it possible to use `Dropdown` alongside custom effect, sound, or accessibility systems while keeping the module completely standalone.

## Example: Sort Dropdown

```lua
local sortDropdown = Dropdown.new(SortButton, {
	UpdateTriggerText = true,
	Selected = "newest",

	Options = {
		{ Id = "rarity", Text = "Rarity", Value = "Rarity" },
		{ Id = "newest", Text = "Newest", Value = "Newest" },
		{ Id = "game", Text = "Game", Value = "Game" },
	},
})

sortDropdown.Selected:Connect(function(option)
	CurrentSort = option.Value
	refreshCollectibles()
end)
```

## Example: Filter Dropdown

```lua
local rarityDropdown = Dropdown.new(FilterButton, {
	SelectionMode = "Multiple",
	CloseOnSelect = false,

	Options = {
		{ Id = 1, Text = "Common", Value = 1 },
		{ Id = 2, Text = "Uncommon", Value = 2 },
		{ Id = 3, Text = "Rare", Value = 3 },
		{ Id = 4, Text = "Epic", Value = 4 },
		{ Id = 5, Text = "Legendary", Value = 5 },
	},
})

rarityDropdown.SelectionChanged:Connect(function(_, selectedOptions)
	local rarities = {}

	for _, option in ipairs(selectedOptions) do
		table.insert(rarities, option.Value)
	end

	applyRarityFilter(rarities)
end)
```

## Example: Custom Studio UI

Suppose your existing UI looks like:

```text
CollectiblesSortDropdown
└── MainCategoryHolder
    └── Scroll

DropdownEntryTemplate
├── TextLabel
└── Checkbox
```

You can use it without changing the structure:

```lua
local dropdown = Dropdown.new(SortButton, {
	DropdownInstance = CollectiblesSortDropdown,
	EntryContainer = CollectiblesSortDropdown.MainCategoryHolder.Scroll,
	EntryTemplate = DropdownEntryTemplate,

	GetEntryButton = function(entry)
		return entry.Checkbox
	end,

	RenderOption = function(entry, option, state)
		entry.TextLabel.Text = option.Text
		entry.Checkbox.BackgroundColor3 = state.Selected
			and Color3.fromRGB(31, 173, 41)
			or Color3.fromRGB(31, 141, 173)
	end,

	Options = {
		{ Id = "rarity", Text = "Rarity" },
		{ Id = "newest", Text = "Newest" },
		{ Id = "game", Text = "Game" },
	},
})
```

This is the intended split: `Dropdown` owns behavior and state, your UI owns presentation.

## Design Goals

`Dropdown` is designed around a few principles.

### Data should own dropdown state

Options and selection live in the controller rather than relying on UI names or Attributes as application state.

### UI should remain replaceable

The default renderer is intended to make the module usable immediately, not to force a particular visual design.

### Every dropdown should be independent

Each controller owns its own connections, entries, options, selection, enabled state, and visibility. There is no singleton dropdown state.

### External systems should remain optional

Button-effect systems, sound systems, scrolling utilities, and other frameworks can integrate through hooks without becoming required dependencies.

## Showcase

The included showcase creates its complete interface dynamically with `Instance.new`. It demonstrates generated single-selection dropdowns, multi-selection filters, action menus, dynamic datasets, disabled entries, custom entry templates, and custom dropdown containers.

To run it:

```text
ReplicatedStorage
└── Dropdown

StarterPlayer
└── StarterPlayerScripts
    └── DropdownShowcase
```

Place the supplied files in those locations and press Play.

## 📝 Notes

- Only `Id` is required for the dropdown’s internal selection system — `Text` and `Value` are convenience fields.
- IDs should be unique within a dropdown; a duplicate `Id` passed to `SetOptions` throws an error.
- If `Text` is omitted, the module derives it from `Name`, then `Value`, then `Id`.
- Disabled options cannot be selected and are excluded from the hover/press interactions of custom activation logic.
- Generated dropdowns size themselves from the option count and become scrollable once content exceeds `MaxHeight`.
- A dropdown’s trigger must be a descendant of a `ScreenGui` unless a custom `Parent` or `DropdownInstance` is supplied.
- A custom `DropdownInstance` remains owned by the caller and is not destroyed by `Destroy()`; its original visibility is restored instead.
- The module is intended to be required and used from client-side UI code.

## License

Choose and include the license you want to distribute the module under before publishing it publicly.

---

made with ❤️ by biotoxin495
