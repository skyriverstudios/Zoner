--=======================================================================================================>
--!strict
--=======================================================================================================>
-- [WHOLE REASON THIS MODULE EXISTS:]
-- We have to ACTUALLY create the functions if we want to be able to have documentation with the functions:
--=======================================================================================================>

-- Require parent types:
local Types = require(script.Parent)

--=======================================================================================================>

-- Import more types:
local GoodSignal = require(`../Modules/External/GoodSignal`);
local Enums      = require(`../Modules/Internal/Enums`);

--=======================================================================================================>

-- Define Module and set Index to self:
local ZoneModule = {}; ZoneModule.__index = ZoneModule;

--=======================================================================================================>

-- Create and export the Object type.
-- We have to ACTUALLY create the functions if we want to be able to have documentation with the functions:

--[=[

	@class Zone
	@__index Zone

]=]
export type Zone<MetaData = {[any]: any}?> = typeof(setmetatable({} :: {
	--====================================================>
	-- Zone Public Indexes:
	--====================================================>
	Identifier: string;
	--====================================================>
	Container:  Types.ZoneContainer;
	ContainerType:   Types.ZoneContainerType;
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
	PlayerEntered: GoodSignal.Signal<Player>;
	PlayerExited:  GoodSignal.Signal<Player>;

	PartEntered: GoodSignal.Signal<Part>;
	PartExited:  GoodSignal.Signal<Part>;

	--ItemEntered: GoodSignal.Signal<Instance>;
	--ItemExited:  GoodSignal.Signal<Instance>;

	LocalPlayerEntered: GoodSignal.Signal<Player>;
	LocalPlayerExited:  GoodSignal.Signal<Player>;
	
	MetaData: MetaData?;
	--======================================>
}, {} :: typeof(ZoneModule)))

--[=[
	@prop Identifier string
	@within Zone
	@readonly

	Identifier

	Accessed: `Zone.Identifier`
]=]
--[=[
	@prop MetaData any
	@within Zone

	Accessed: `Zone.MetaData`
]=]
--[=[
	@prop PlayerEntered Signal.Signal<Player>
	@within Zone
	@tag event_signal
	@readonly
	Accessed: `Zone.PlayerEntered`
]=]
--[=[
	@prop PlayerExited Signal.Signal<Player>
	@within Zone
	@tag event_signal
	@readonly
	Accessed: `Zone.PlayerExited`
]=]
--[=[
	@prop LocalPlayerEntered Signal.Signal<Player>
	@within Zone
	@tag event_signal
	@client
	@readonly
	Accessed: `Zone.LocalPlayerEntered`
]=]
--[=[
	@prop LocalPlayerExited Signal.Signal<Player>
	@within Zone
	@tag event_signal
	@client
	@readonly
	Accessed: `Zone.LocalPlayerExited`
]=]
--[=[
	@prop PartEntered Signal.Signal<BasePart>
	@within Zone
	@tag event_signal
	@readonly
	Accessed: `Zone.PartEntered`
]=]
--[=[
	@prop PartExited Signal.Signal<BasePart>
	@within Zone
	@tag event_signal
	@readonly
	Accessed: `Zone.PartExited`
]=]
--===========================================================================================================================>
--[ PUBLIC METHODS: ]

--[=[
	Cleanup method which clears the entirity of the Data for the Object

	@method Destroy
	@within Zone
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
function ZoneModule.SetDetection(self: Zone, DetectionCoverage: Enums.DetectionCoverages | number, DetectionMode: Enums.DetectionModes | number) end

--[=[
	Method to Update/Set the Default Rate of the Zone:

	@method SetRate
	@within Zone
	@param Rate Enum.Rates | number -- Rates Enum or Enum Id.
]=]
function ZoneModule.SetRate(self: Zone, Rate: Enums.Rates | number) end

--[=[
	Method to Update/Set the Default Simulation (RunService Event) of the Zone:
	
	@method SetSimulation
	@within Zone
	@param Simulation Enum.Simulations | number -- Simulation Enum or Enum Id.
]=]
function ZoneModule.SetSimulation(self: Zone, Simulation: Enums.Simulations | number) end

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

-- @Public
-- Method to return a random Vector3 point within the Zone's bounds.
-- Will return a point inside a box or part depending on what the Zone is made of.
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

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>