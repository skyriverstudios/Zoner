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

--- Create and export the Object type.
-- We have to ACTUALLY create the functions if we want to be able to have documentation with the functions:
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

--===========================================================================================================================>
--[ PUBLIC METHODS: ]

-- @Public
-- Destroyer Function which clears the entirity of the Data for the Object:
function ZoneModule.Destroy(self: Zone)end

-- @Public
-- Method that will Relocate the Zone to a WorldModel not in the Workspace:
function ZoneModule.Relocate(self: Zone): Zone return self end

-- @Public
-- Method to Update/Set the Default Part/TrackedItem Detection of the Zone:
function ZoneModule.SetDetection(self: Zone, DetectionCoverage: Enums.DetectionCoverages | number, DetectionMode: Enums.DetectionModes | number) end

-- @Public
-- Method to Update/Set the Default Rate of the Zone:
function ZoneModule.SetRate(self: Zone, Rate: Enums.Rates | number) end

-- @Public
-- Method to Update/Set the Default Simulation (RunService Event) of the Zone:
function ZoneModule.SetSimulation(self: Zone, Simulation: Enums.Simulations | number) end

-- @Public
-- Method to print out all the Config Names:
function ZoneModule.LogConfig(self: Zone) end

-- @Public
-- Method to return the array of ZoneParts:
function ZoneModule.GetZoneParts(self: Zone): {BasePart} return nil :: any end

-- @Public
-- Method to return the array of ZonePartHolders:
function ZoneModule.GetZonePartHolders(self: Zone): {Instance} return nil :: any end

-- @Public
-- Method to return a random Vector3 point within the Zone's bounds.
-- Will return a point inside a box or part depending on what the Zone is made of.
function ZoneModule.GetRandomPoint(self: Zone): Vector3 return nil :: any end

-- @Public
-- Method to return an array of all BaseParts currently touching this Zone.
-- Works for both Box-style and Part-style Zones.
function ZoneModule.GetTouchingParts(self: Zone): {BasePart} return nil :: any end

-- @Public
-- only if manualstepping Config is true and the holder type is a group, if not, this method is removed:
function ZoneModule.Step(self: Zone, DeltaTime: number) end

-- @Public
-- Method that will BIND the Zone to the passed Group:
function ZoneModule.BindToGroup(self: Zone, GroupName: string)  end

-- @Public
-- Method that will UNBIND the Zone from the passed Group:
function ZoneModule.UnbindFromGroup(self: Zone, GroupName: string)  end

--===========================================================================================================================>

----- Create and Export a public version of the Zone Object:
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