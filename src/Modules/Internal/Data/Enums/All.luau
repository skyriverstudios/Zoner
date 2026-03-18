--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

local DetectionCoverage = require('./DetectionCoverage');
local DetectionMethod   = require('./DetectionMethod');
local DetectionMode     = require('./DetectionMode');
local Simulation        = require('./Simulation');
local Execution         = require('./Execution');
local Bounds            = require('./Bounds');
local Rate              = require('./Rate');

--==========================================================================================================================>

export type DetectionCoverageEnum = DetectionCoverage.DetectionCoverageEnum
export type DetectionMethodEnum   = DetectionMethod.DetectionMethodEnum
export type DetectionModeEnum     = DetectionMode.DetectionModeEnum
export type SimulationEnum        = Simulation.SimulationEnum
export type ExecutionEnum         = Execution.ExecutionEnum
export type RateEnum              = Rate.RateEnum

--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Enums')

--[=[
	@class Enums

	Tables of related enums for use in Zoner. Each enum is a frozen table with both name and value lookups, 
	as well as optional associated properties.

	**Enums**
	- `DetectionMethod`, `DetectionMode`, `DetectionCoverage`
	- `Rate`, `Execution`, `Simulation`, `Bounds`
]=]

--[=[
	@interface EnumItem
	@within Enums
	@field Name string --Display name of the item (e.g. "Fast")
	@field Value number --Numeric id returned when indexing by name
]=]

--===========================================================================================================================>

--[=[
	@interface DetectionMethod
	@within Enums

	@field Automatic EnumItem --Auto-pick based on container shape & coverage/mode;
	@field Efficient EnumItem --Fastest. Uses simple CFrame and Size math checks to determine location in the Zone Volume.
	@field Simple    EnumItem --Balanced: may use `GetPartBoundsInBox/Radius` for modest cost and good fidelity. 
	@field Complex   EnumItem --Highest accuracy: per-part or mesh-aware paths like `GetPartsInPart`; most expensive. If ZoneContainer has no Instances, they will be created.
]=]
--[=[
	@prop DetectionMethod DetectionMethod
	@within Enums
	@readonly
]=]

--[=[
	@interface DetectionMode
	@within Enums

	@field Full  EnumItem --Target must be fully inside or outside the Zone bounds to trigger entrance or exit.
	@field Touch EnumItem --Any intersection with the zone boundary counts (partial overlap). (Doesn't actually use .Touched)
	@field Point EnumItem --One or more representative points must be inside (fastest). Often pairs with Efficient math tests.
]=]
--[=[
	@prop DetectionMode DetectionMode
	@within Enums
	@readonly
]=]

--[=[
	@interface DetectionCoverage
	@within Enums

	@field Center   EnumItem --Check only the target's center point (very fast). Often math-only.
	@field AllParts EnumItem --Every relevant part/point must satisfy `DetectionMode` (strict).
	@field AnyPart  EnumItem --At least one relevant part/point must satisfy `DetectionMode` (lenient).
]=]
--[=[
	@prop DetectionCoverage DetectionCoverage
	@within Enums
	@readonly
]=]

--[=[
	@interface Rate
	@within Enums

	@field Slow      EnumItem --Step period ≈ **1.0 s** between evaluations.
	@field Moderate  EnumItem --Step period ≈ **0.5 s**.
	@field Fast      EnumItem --Step period ≈ **0.1 s**.
	@field Immediate EnumItem --Step period **0 s** (continuous / every frame slice).
]=]
--[=[
	@prop Rate Rate
	@within Enums
	@readonly
]=]

--[=[
	@interface Execution
	@within Enums
	
	@field Serial   EnumItem --Single-threaded group holder. Supports manual stepping via `Zone:Step(...)` when `ManualStepping = true`.
	@field Parallel EnumItem --Actor-backed parallel evaluation. Manual stepping not exposed; runs on its own schedule. Fastest with lots of Zones.
]=]
--[=[
	@prop Execution Execution
	@within Enums
	@readonly
	@since 0.9.9
]=]

--[=[
	@interface Simulation
	@within Enums
	
	@field PostSimulation EnumItem --Run after physics; safe for effects based on final transforms.
	@field PreSimulation  EnumItem --Run before physics; good for preparing forces/constraints.
	@field PreRender      EnumItem --Run before rendering (client). On server, requests are coerced to PostSimulation.
]=]
--[=[
	@prop Simulation Simulation
	@within Enums
	@readonly
	@since 0.9.9
]=]

--[=[
	@interface Bounds
	@within Enums
	
	@field Automatic EnumItem --Auto-select bounds model from the container (boxes/spheres vs per-part).
	@field BoxExact  EnumItem --Automatically creates a Rotated Box (No Instance unless specified) that fits the sum of the ZoneContainer
	@field BoxVoxel  EnumItem --Automatically creates a Rotated Box (No Instance unless specified) that fits the sum of the ZoneContainer, then rounds to Voxel Grid
	@field PerPart   EnumItem --Evaluate each contained BasePart or {CFrame, Size} individually as the sum of the whole Zone.
]=]
--[=[
	@prop Bounds Bounds
	@within Enums
	@readonly
]=]

--===========================================================================================================================>

-- Return the Frozen Table:
return table.freeze({
	DetectionCoverage = DetectionCoverage;
	DetectionMethod   = DetectionMethod;
	DetectionMode     = DetectionMode;
	Simulation        = Simulation;
	Execution         = Execution;
	Bounds            = Bounds;
	Rate              = Rate;
})

--==========================================================================================================================>