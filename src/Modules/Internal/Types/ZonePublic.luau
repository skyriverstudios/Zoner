--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Types')

--===========================================================================================================================>
-- [WHOLE REASON THIS MODULE EXISTS:]
-- We have to ACTUALLY create the functions if we want to be able to have documentation with the functions:
--===========================================================================================================================>
--==[ DEPENDENCIES ]==--


--=[ Local Requires ]=--

local DetectionCoverage = require('../Data/Enums/DetectionCoverage')
local DetectionMode     = require('../Data/Enums/DetectionMode')
local Simulation        = require('../Data/Enums/Simulation')
local Rate              = require('../Data/Enums/Rate')

local Zignal = require(`../../External/Zignal`);

--===========================================================================================================================>

-- Define Module and set Index to self:
local ZoneModule = {}; ZoneModule.__index = ZoneModule;

--===========================================================================================================================>
--==[ TYPES ]==--

local ZonePrimitives = require(`./ZonePrimitives`);

-- Create and export the Object type.
-- We have to ACTUALLY create the functions if we want to be able to have documentation with the functions:

--[=[
	@class Zone
	@__index Zone
	@tag public_api

	Public facade for a single Zone created by:

	`Zoner.New(...)`, `Zoner.NewFromContainer(...)` `Zoner.NewZoneFromRegion(...)`, or `Zoner.NewZoneFromBox(...)`. 
	 
	Exposes read-only state, configuration helpers, signals, and utilities while hiding internal engine details.

	**Surface**
	- Read-only state: `Identifier`, `Active`, `Destroyed`, `Relocated`, `Paused`, `Visible`,
	  plus detection/simulation/rate fields.
	- Signals:
	  - `PlayerEntered`, `PlayerExited`
	  - `PartEntered`, `PartExited`
	  - `LocalPlayerEntered`, `LocalPlayerExited` (client only)
	- Configuration:
	  - `SetDetection(DetectionCoverage, DetectionMode)`
	  - `SetRate(Rate)`
	  - `SetSimulation(Simulation)`
	- Utilities:
	  - `GetRandomPoint()` — random point from part-backed or partless box bounds
	  - `GetTouchingParts()` — parts overlapping the zone’s bounds
	  - `Relocate()` — move content into a WorldModel for spatial queries
	  - `LogConfig()` — configuration dump
	- Grouping:
	  - `BindToGroup(name)`, `UnbindFromGroup(name)`, `InGroup(name)`

	**Bounds & detection**
	- Zones can be part-backed (Instances) or partless (CFrame/Size boxes).
	- Uses enums supplied by `Zoner.Enum` with sensible defaults.

	**Run-context**
	- `LocalPlayer*` signals are client-only.
	- Methods do not yield.

	**Example**
	```lua
	--!strict
	local Zoner = require(path.to.Zoner)

	local Zone: Zoner.Zone = Zoner.New(workspace.ZonePart, {
		Execution = Zoner.Enum.Execution.Parallel;
		Bounds    = Zoner.Enum.Bounds.Automatic;
	})

	Zone.PlayerEntered:Connect(function(Player: Player)
		print(player.Name, "Entered")
	end)

	Zone:SetDetection(Zoner.Enum.DetectionCoverage.Center, Zoner.Enum.DetectionMode.Point)
	```
]=]
export type Zone<MetaData = {[any]: any}?> = typeof(setmetatable({} :: {
	--====================================================>
	-- Zone Public Indexes:
	--====================================================>
	Identifier: string;
	--====================================================>
	Container:      ZonePrimitives.ZoneContainer;
	ContainerType:  ZonePrimitives.ZoneContainerType;
	--====================================================>
	Active:         boolean;
	Destroyed:      boolean;
	Relocated:      boolean;
	Paused:         boolean;
	Visible:        boolean;
	--====================================================>
	Detection:      number;
	Accuracy:       number;
	Simulation:     number;
	Execution:      number;
	EnterDetection: number;
	ExitDetection:  number;
	
	--====================================================>
	PlayerEntered: Zignal.Signal<Player>;
	PlayerExited:  Zignal.Signal<Player>;

	PartEntered: Zignal.Signal<Part>;
	PartExited:  Zignal.Signal<Part>;

	--ItemEntered: GoodSignal.Signal<Instance>;
	--ItemExited:  GoodSignal.Signal<Instance>;

	LocalPlayerEntered: Zignal.Signal<Player>;
	LocalPlayerExited:  Zignal.Signal<Player>;
	
	MetaData: MetaData?;
	--======================================>
}, {} :: typeof(ZoneModule)))

--===========================================================================================================================>
--[ PUBLIC METHODS: ]

--[=[
	@method Destroy
	@within Zone

	Cleans up signals, connections, tags, and backing instances for this Zone.
]=]
function ZoneModule.Destroy(self: Zone)end

--[=[
	Method that will Relocate the Zone to a WorldModel not in the Workspace

	@method Relocate
	@within Zone

	@return Zone -- Self Zone Object
]=]
function ZoneModule.Relocate(self: Zone): Zone return self end

--[=[
	Method to Update/Set the Default Part/TrackedItem Detection of the Zone:

	@method SetDetection
	@within Zone
	@param DetectionCoverage Enum.DetectionCoverages | number -- DetectionCoverages Enum or Enum Id.
	@param DetectionMode Enum.DetectionModes | number -- DetectionModes Enum or Enum Id.
]=]
function ZoneModule.SetDetection(self: Zone, DetectionCoverage: DetectionCoverage.DetectionCoverageEnum, DetectionMode: DetectionMode.DetectionModeEnum) end

--[=[
	Method to Update/Set the Default Rate of the Zone:

	@method SetRate
	@within Zone
	@param Rate Enum.Rates | number -- Rates Enum or Enum Id.
]=]
function ZoneModule.SetRate(self: Zone, Rate: Rate.RateEnum) end

--[=[
	Method to Update/Set the Default Simulation (RunService Event) of the Zone:
	
	@method SetSimulation
	@within Zone
	@param Simulation Enum.Simulations | number -- Simulation Enum or Enum Id.
]=]
function ZoneModule.SetSimulation(self: Zone, Simulation: Simulation.SimulationEnum) end

--[=[
	Method to print out all the Config Names

	@method LogConfig
	@within Zone
]=]
function ZoneModule.LogConfig(self: Zone) end

--[=[
	Method to return the array of ZoneParts

	@method GetZoneParts
	@within Zone

	@return {BasePart}
]=]
function ZoneModule.GetZoneParts(self: Zone): {BasePart} return nil :: any end

--[=[
	Method to return the array of ZonePartHolders

	@method GetZonePartHolders
	@within Zone

	@return {Instance}
]=]
function ZoneModule.GetZonePartHolders(self: Zone): {Instance} return nil :: any end

--[=[
	@method GetRandomPoint
	@within Zone

	Returns a random point within this Zone’s bounds.  
	Works with partless boxes (math) and part-backed zones (shape-aware).

	@return Vector3 --Point inside the zone volume
]=]
function ZoneModule.GetRandomPoint(self: Zone): Vector3 return nil :: any end

--[=[
	Method to return an array of all BaseParts currently touching this Zone.
	
	Works for both Box-style and Part-style Zones

	@method GetTouchingParts
	@within Zone

	@return {BasePart}
]=]
function ZoneModule.GetTouchingParts(self: Zone): {BasePart} return nil :: any end

--[=[
	Method that can be called manually in a custom RunService event to step the Zone's detection logic
	
	Only present if `ManualStepping` Config is true and the holder type is a group, if not, this method is removed

	@method Step
	@within Zone
	@param DeltaTime number -- RunService event DeltaTime.
]=]
function ZoneModule.Step(self: Zone, DeltaTime: number) end

--[=[
	Method that will BIND the Zone to the passed Group:

	@method BindToGroup
	@within Zone
	@param GroupName string -- Name of the already created group to bind the Zone to
]=]
function ZoneModule.BindToGroup(self: Zone, GroupName: string)  end

--[=[
	Method that will UNBIND the Zone to the passed Group:

	@method UnbindFromGroup
	@within Zone
	@param GroupName string -- Name of the already created group to bind the Zone to
]=]
function ZoneModule.UnbindFromGroup(self: Zone, GroupName: string)  end

--[=[
	Method to return whether the Zone is in the group or not

	@method InGroup
	@within Zone
	@param GroupName string -- Name of the group to check

	@return boolean
]=]
function ZoneModule.InGroup(self: Zone, GroupName: string): boolean return false end 

--===========================================================================================================================>

-- Create and Export a public version of the Zone Object:
--export type Zone = {
--	--====================================================>
--	-- Zone Public Indexes:
--	--====================================================>
--	Identifier: string;
--	--====================================================>
--	Container:  Types.ZoneContainer;
--	ContainerType:   Types.ZoneContainerType;
--	--====================================================>
--	Active:         boolean;
--	Destroyed:      boolean;
--	Relocated:      boolean;
--	Paused:         boolean;
--	--====================================================>
--	Detection:      number;
--	Accuracy:       number;
--	Simulation:     number;
--	Execution:      number;
--	EnterDetection: number;
--	ExitDetection:  number;
--	--====================================================>
--	PlayerEntered: GoodSignal.Signal<Player>;
--	PlayerExited:  GoodSignal.Signal<Player>;

--	PartEntered: GoodSignal.Signal<Part>;
--	PartExited:  GoodSignal.Signal<Part>;

--	--ItemEntered: GoodSignal.Signal<Instance>;
--	--ItemExited:  GoodSignal.Signal<Instance>;

--	LocalPlayerEntered: GoodSignal.Signal<Player>;
--	LocalPlayerExited:  GoodSignal.Signal<Player>;
--	--======================================>
--	-- [Methods]:

--	-- @Public
--	-- Destroyer Function which clears the entirity of the Data for the Object:
--	Destroy: (self: Zone) -> ();
--	-- @Public
--	-- Method that will Relocate the Zone to a WorldModel not in the Workspace:
--	Relocate: (self: Zone) -> Zone;
--	-- @Public
--	-- Method to Update/Set the Default Part/TrackedItem Detection of the Zone:
--	SetDetection: (self: Zone, DetectionCoverage: Enums.DetectionCoverages | number, DetectionMode: Enums.DetectionModes | number) -> ();
--	-- @Public
--	-- Method to Update/Set the Default Rate of the Zone:
--	SetRate: (self: Zone, Rate: Enums.Rates | number) -> ();
--	-- @Public
--	-- Method to Update/Set the Default Simulation (RunService Event) of the Zone:
--	SetSimulation: (self: Zone, Simulation: Enums.Simulations | number) -> ();
--	-- @Public
--	-- Method to print out all the Setting Names:
--	LogSettings: (self: Zone) -> ();
--	-- @Public
--	-- only if manualstepping setting is true and the holder type is a group, if not, this method is removed:
--	Step: (self: Zone, DeltaTime: number) -> ();
--	--======================================>
--}

--===========================================================================================================================>

-- Return an empty table:
return table.freeze({})

--===========================================================================================================================>