--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zone]: Engine')

-- Define Module table
local Engine = {}

--===========================================================================================================================>
--[ SERVICES: ]


-- Get the needed Services for the following Code:
local CollectionService = game:GetService('CollectionService')
local RunService        = game:GetService('RunService')

--===========================================================================================================================>
--[ GLOBALS: ]


-- [ Global Dependencies: ]

local Utility = require(`../Utility`);
local Helpers = require(`../Zone/Helpers`)
local Enums   = require(`../Enums`);

-- [ Local Dependencies: ]

local Detections = require(`@self/Detections`);

--===========================================================================================================================>
--[ CONSTANTS: ]


-- RANDOM GENERATOR:
local RANDOM = Random.new();

-- The RunContext of the Module:
local RUN_CONTEXT: 'Client'|'Server' = if RunService:IsServer() then 'Server' else 'Client'

--===========================================================================================================================>
--[ TYPES: ]


-- [ Require Types: ]

-- This will inject all types into this context.
local Types = require(`../../../Types`)

-- [ Register Types: ]

-- Signal function for direct callback to the zone object:
type ZoneSignalFunction = ((Purpose: string, ...any) -> ())

--- Create and Export the Module's Object Type:
export type Engine = typeof(setmetatable({} :: {
	--======================================>
	_Identifier:    string;
	_Container:     Types.ZoneContainer;
	_ContainerType: Types.ZoneContainerType;

	_Connections: {[string]: RBXScriptConnection};

	_ZoneFolder:    Types.ZoneFolder;
	--======================================>
	_ActiveTargets: Types.ZoneActiveTargetsTable;
	_ActiveSignals: Types.ZoneActiveSignalsTable;
	_Config:        Types.ZoneConfigTable;
	_States:        Types.ZoneStatesTable;
	--====================================================>
	_DetectionHandler: Detections.DetectionHandler;
	--======================================>
	_Tags: {ZonePart: string; Holder: string };

	_Instances: {
		Holders:   {Instance};
		ZoneParts: {BasePart};
	};

	_Counters: {
		EvaluateParallel: {Counter: number; CounterMax: number};
		EvaluateSerial:   {Counter: number; CounterMax: number};
	};
	--======================================>
	-- Meta Indexing:

	-- Whether the Zone has Connections:
	Active: boolean;

	_Holders:   {Instance};
	_ZoneBoxes: Types.ZoneBoxes;
	_ZoneParts: {BasePart};
	
	
	-- Added via the Parent Zone Object on SERIAL Objects only:
	FireSignal: ((Purpose: string, ...any) -> ())?;
	--======================================>
}, {} :: typeof(Engine)))

--===========================================================================================================================>
--[ LOCAL FUNCTIONS: ]


local function Initialize(Engine: Engine)
	--=======================================================================================================>

	-- If the Execution Config is Parallel to use Parallel:
	-- Using this because 'Dynamic Property Access on Signals' is 'unsafe'
	local UseParallel = Engine._Config.Execution == Enums.Execution.Parallel

	--=======================================================================================================>

	-- Reference the Folder Instance:
	local ActiveSignals = Engine._ZoneFolder.ActiveSignals
	-- Index the Propert Connection Function/Signal based on 'UserParallel'
	local AC_ActiveSignals_Connect: ((RBXScriptSignal, (string) -> ()) -> RBXScriptConnection) = 
		(if UseParallel then ActiveSignals.AttributeChanged.ConnectParallel else ActiveSignals.AttributeChanged.Connect) :: any

	-- Fire when any Attribute Changes on the ActiveTargets:
	Engine._Connections['AC_ActiveSignals'] = AC_ActiveSignals_Connect(ActiveSignals.AttributeChanged, function(Target: string) 
		--================================================================================================>
		-- If already Destroyed, return:
		if Engine._States.Destroyed then return end
		-- Update this Objects Properties Attributes from the Changed Event firing:
		Engine._ActiveSignals[Target] = Engine._ZoneFolder.ActiveSignals:GetAttribute(Target)
		--================================================================================================>
	end)
	
	-- Reference the Folder Instance:
	local ActiveTargets = Engine._ZoneFolder.ActiveTargets
	-- Index the Propert Connection Function/Signal based on 'UserParallel'
	local AC_ActiveTargets_Connect: ((RBXScriptSignal, (string) -> ()) -> RBXScriptConnection) = 
		(if UseParallel then ActiveTargets.AttributeChanged.ConnectParallel else ActiveTargets.AttributeChanged.Connect) :: any

	-- Fire when any Attribute Changes on the ActiveTargets:
	Engine._Connections['AC_ActiveTargets'] = AC_ActiveTargets_Connect(ActiveTargets.AttributeChanged, function(Target: string) 
		--================================================================================================>
		-- If already Destroyed, return:
		if Engine._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		Engine._ActiveTargets[Target] = Engine._ZoneFolder.ActiveTargets:GetAttribute(Target)
		--================================================================================================>
		-- Synchronize the thread:
		if UseParallel then task.synchronize() end
		--================================================================================================>
		-- If the Target is Active then Add the TargetHandler on the DetectionHandler, else Remove it from the DetectionHandler:
		if Engine._ActiveTargets[Target] then 
			Engine._DetectionHandler:AddTargetHandler(Target :: any) 
		else
			Engine._DetectionHandler:RemoveTargetHandler(Target :: any) 
		end
		--================================================================================================>
	end)

	-- Reference the Folder Instance:
	local States = Engine._ZoneFolder.States
	-- Index the Propert Connection Function/Signal based on 'UserParallel'
	local AC_States_Connect: ((RBXScriptSignal, (string) -> ()) -> RBXScriptConnection) = 
		(if UseParallel then States.AttributeChanged.ConnectParallel else States.AttributeChanged.Connect) :: any

	-- Fire when any Attribute Changes on the States:
	Engine._Connections['AC_States'] = AC_States_Connect(States.AttributeChanged, function(State: string) 
		--================================================================================================>
		-- If already Destroyed, return:
		if Engine._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		Engine._States[State] = Engine._ZoneFolder.States:GetAttribute(State)
		--================================================================================================>
		-- If we are in parallel syncrhonize to serial:
		if Engine._Config.Execution == Enums.Execution.Parallel then task.synchronize() end
		--================================================================================================>
		-- If the State is Visible, thenm call the Function for Toggling Visibility On and Off:
		if State == 'Visible' then Engine:SetVisibility(Engine._States[State]) end
		if State == 'Relocated' and Engine._States[State] == true then 
			-- Synchronize the thread:
			if UseParallel then task.synchronize() end
			-- Call relocate on the bounds:
			Engine._DetectionHandler:GetBoundsHandler():Relocate()
		end
		if State == 'Paused' then
			Engine:SetSimulation(Engine._Config.Simulation, if Engine._States[State] == true then 'Off' else 'On')
		end
		if State == 'Active' then
			Engine:SetSimulation(Engine._Config.Simulation, if Engine._States[State] == false then 'Off' else 'On')
		end
		--================================================================================================>
	end)

	-- Reference the Folder Instance:
	local Config = Engine._ZoneFolder.Config
	-- Index the Propert Connection Function/Signal based on 'UserParallel'
	local AC_Config_Connect: ((RBXScriptSignal, (string) -> ()) -> RBXScriptConnection) = 
		(if UseParallel then Config.AttributeChanged.ConnectParallel else Config.AttributeChanged.Connect) :: any

	-- Fire when any Attribute Changes on the Config:
	Engine._Connections['AC_Config'] = AC_Config_Connect(Config.AttributeChanged, function(Config: string)
		--================================================================================================>
		-- If already Destroyed, return:
		if Engine._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		Engine._Config[Config] = Engine._ZoneFolder.Config:GetAttribute(Config)
		--================================================================================================>
		-- If the Config is the Detection, then call the Method for it:
		if string.gmatch(Config, 'Detection') then
			Engine:SetDetection(Engine._Config.DetectionCoverage, Engine._Config.DetectionMode, Engine._Config.DetectionMethod)
		end
		-- If the Config is the Simulation, then call the Method for it:
		if Config == 'Simulation' then Engine:SetSimulation(Engine._Config[Config], 'On') end
		-- If the Config is the Rate, then call the Method for it:
		if Config == 'Rate'       then Engine:SetRate(Engine._Config[Config])       end
		--================================================================================================>
	end)

	--=======================================================================================================>

	-- If the Engine is being Run in Parallel (on another actor) then 
	-- Connect Events that cant be reached by the Parent Zone Object:
	if Engine._Config.Execution == Enums.Execution.Parallel then
		--=========================================================================================>

		-- Connect to the AncestryChanged event of the ZoneFolder:
		-- We then check if the ZoneFolder is still a decendent of the WorldModel, meaning it hasnt been destroyed.
		-- We do this to clear the Data in case the ZoneFolder is Destroyed:
		Engine._Connections['AC_ZoneFolder'] = Engine._ZoneFolder.AncestryChanged:ConnectParallel(function()
			--====================================================================================>
			if not Engine._ZoneFolder then return end
			-- If the Destroying Attribute is true on the ZoneFolder, then ignore the Ancestry Changed:
			if Engine._ZoneFolder:GetAttribute('Destroying') == true then return end
			if Engine._ZoneFolder.Parent == nil or Engine._ZoneFolder:IsDescendantOf(game) == false then 
				print('Backup, Engine: Folder Ancestry Changed'); task.synchronize(); Engine:Destroy()
			end
			--====================================================================================>
		end)

		--=========================================================================================>

		-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
		if Engine._ContainerType == 'Boxes' then return end

		--=========================================================================================>

		-- Connect to the ZonePart Tag Added Signal:
		-- Fires when a Part with the Zone Tag is added back to the Workspace:
		-- We will use this to reduce the Zone Based on Streaming:

		-- I made this ConnectParallel, theres a few things that run after this signal fires that need to be in serial,
		-- And i try to check if those are needing to be ran before switching back to serial, if the gain is very little,
		-- might switch this back to Connect serial:
		Engine._Connections['CS_ZonePart_Add'] = 
			CollectionService:GetInstanceAddedSignal(Engine._Tags.ZonePart):ConnectParallel(function(ZonePart: BasePart)
				-- If Destroyed was already called then return:
				if not Engine.OnZonePartUpdate then return end
				Engine:OnZonePartUpdate('Add', ZonePart)
			end)

		-- Connect to the ZonePart Tag Removed Signal:
		-- Fires when a Part with the Zone Tag is removed from the Workspace:
		-- We will use this to restore the Zone Based on Streaming:
		Engine._Connections['CS_ZonePart_Remove'] = 
			CollectionService:GetInstanceRemovedSignal(Engine._Tags.ZonePart):ConnectParallel(function(ZonePart: BasePart)
				-- If Destroyed was already called then return:
				if not Engine.OnZonePartUpdate then return end
				Engine:OnZonePartUpdate('Remove', ZonePart)
			end)

		-- Connect to the Holder Tag Added Signal:
		Engine._Connections['CS_Holder_Add'] = 
			CollectionService:GetInstanceAddedSignal(Engine._Tags.Holder):ConnectParallel(function(Holder: Instance)
				-- If Destroyed was already called then return:
				if not Engine.OnHolderInstanceUpdate then return end
				Engine:OnHolderInstanceUpdate('Add', Holder)
			end)

		-- Connect to the Holder Tag Added Signal:
		Engine._Connections['CS_Holder_Remove'] = 
			CollectionService:GetInstanceRemovedSignal(Engine._Tags.Holder):ConnectParallel(function(Holder: Instance)
				-- If Destroyed was already called then return:
				if not Engine.OnHolderInstanceUpdate then return end
				Engine:OnHolderInstanceUpdate('Remove', Holder)
			end)

		--=========================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- Constructor Function for this individual object:
function Engine.New(Id: string, Folder: Types.ZoneFolder, Container: Types.ZoneContainer, SignalFunction: ZoneSignalFunction?): Engine
	--=======================================================================================================>

	-- Set a Memory Category for this Zoner:
	debug.setmemorycategory('[Zoner]: Engine')

	--=======================================================================================================>
	-- Define Data
	local EngineData: Engine = {
		--====================================================>
		-- Store the Id of the Zone:
		_Identifier = Id;
		-- Reference to the Original Zone Container:
		_Container = Container;
		_ContainerType = Helpers.GetZoneContainerType(Container) :: Types.ZoneContainerType;
		--- Reference to the ZoneFolder in the Zoner:
		_ZoneFolder = Folder;
		--====================================================>
		-- Dictionary of ZoneParts and their Properties:
		_Config = {};
		--====================================================>
		_Tags = {
			ZonePart = `{Id}:ZonePart:{RUN_CONTEXT}`;
			Holder   = `{Id}:Holder:{RUN_CONTEXT}`;
		};
		--====================================================>

		_Instances = {
			Holders   = {};
			ZoneParts = {};
		};

		_States = {};
		_ActiveTargets = {};
		_ActiveSignals = {};

		_Counters = {
			EvaluateParallel = {Counter = 0; CounterMax = 1};
			EvaluateSerial   = {Counter = 0; CounterMax = 1};
		};

		_Connections = {};
		--====================================================>
	} :: any

	--=======================================================================================================>

	-- Update each of the Folder Attribute Dictionaries by grabbing their attributes dynamically via the Array:
	for Index: number, FolderName: string in ipairs({'States', 'Config', 'ActiveTargets', 'ActiveSignals'}) do
		--================================================================================================>
		-- Find the Folder (Configuration) as a Child of the Actor using the Name String passed:
		local DataFolder: Configuration = EngineData._ZoneFolder:FindFirstChild(FolderName) :: Configuration
		-- Grab the Attributes on the Folders and update our copy of them:
		for Name: string, Value: any in DataFolder:GetAttributes() do EngineData[`_{FolderName}`][Name] = Value end
		--================================================================================================>
	end
	
	-- Construct a new Handler Object with the Trove and Set it in the Table:
	-- Index the Detection Specific Table with the DetectionMethod Name to gets its New Method:
	EngineData._DetectionHandler = Detections[Enums.DetectionMethod:GetName(EngineData._Config.DetectionMethod)].New({
		ZoneContainer     = EngineData._Container;
		ZoneContainerType = EngineData._ContainerType;
		ZoneConfig        = EngineData._Config;
		ZoneStates        = EngineData._States;
		ZoneFolder        = EngineData._ZoneFolder;
		ZonePieces        = if EngineData._ContainerType == 'Boxes' then EngineData._Container else EngineData._Instances.ZoneParts;
		
		-- Add the Zone Update bindable event if no Signal function was passed:
		ZoneSignalEvent    = 
			if not SignalFunction then script.Parent.Parent.Parent.Parent:WaitForChild('Events'):WaitForChild('Zone_Update') else nil;
		-- Add the Signal Function:
		ZoneSignalFunction = SignalFunction;
		
		ZoneId            = EngineData._Identifier;
	})

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(EngineData :: any, Engine)

	--=======================================================================================================>

	-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
	if EngineData._ContainerType ~= 'Boxes' then 
		-- Check the CollectionService Tags for the ZoneParts already tagged:
		for Index: number, Part in ipairs(CollectionService:GetTagged(EngineData._Tags.ZonePart)) do
			EngineData:OnZonePartUpdate('Add', Part)
		end
		-- Check the CollectionService Tags for the Holders already tagged:
		for Index: number, Holder in ipairs(CollectionService:GetTagged(EngineData._Tags.Holder)) do
			EngineData:OnHolderInstanceUpdate('Add', Holder)
		end
	end

	--=======================================================================================================>

	-- Start the Inventory:
	Initialize(EngineData)

	-- Update the Rate Counter with the Config:
	EngineData:SetRate(EngineData._Config.Rate)
	-- Update the Detection with the Config:
	EngineData:SetDetection(EngineData._Config.DetectionCoverage, EngineData._Config.DetectionMode, EngineData._Config.DetectionMethod)
	-- Update the Simulation Events with the Config:
	EngineData:SetSimulation(EngineData._Config.Simulation, 'On')
	
	-- If Relocated is already true, then call Relocate on the BoundsHandler:
	if EngineData._States.Relocated then
		EngineData._DetectionHandler:GetBoundsHandler():Relocate()
	end
	
	-- Update the Visiblity with the State:
	EngineData:SetVisibility(EngineData._States.Visible)

	--=======================================================================================================>

	-- Loop through the ActiveTargets and Create a TargetHandler for each one accordingly:
	for Target, State: boolean in pairs(EngineData._ActiveTargets) do 
		if State then EngineData._DetectionHandler:AddTargetHandler(Target) else EngineData._DetectionHandler:RemoveTargetHandler(Target) end
	end

	--=======================================================================================================>

	-- Return the MetaTable Data
	return EngineData :: any

	--=======================================================================================================>
end

-- Destroyer Function which clears the entirity of the Data for the Object:
function Engine.Destroy(self: Engine)
	--=======================================================================================================>
	-- If Destroyed was already called then return:
	if self._States.Destroyed then return end
	-- Set the Destroyed State to true:
	self._States.Destroyed = true
	--=======================================================================================================>
	-- Clear all self data:
	for Key, Connection in pairs(self._Connections) do self._Connections[Key]:Disconnect() end
	table.clear(self._Connections)

	self._DetectionHandler:Destroy()
	rawset(self :: any, '_DetectionHandler', nil)

	-- Clear all self data:
	for Index, Data in pairs(self) do self[Index] = nil end
	-- Set the Metatable to nil
	setmetatable(self :: any, nil)	
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ CONFIG UPDATE METHODS: ]


-- Function that is called when the Detection Config is updated:
function Engine.SetDetection(self: Engine, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?)
	self._DetectionHandler:UpdateDetectionCoverage()
end

--- Function that is called when the Simulation Config is updated:
@native
function Engine.SetSimulation(self: Engine, Simulation: number, Status: 'On'|'Off')
	--=======================================================================================================>
	-- If ManualStepping is true then we do not connect the internal Simulation:
	if self._Config.ManualStepping == true then return end
	-- Synchronize the thread:
	if self._Config.Execution == Enums.Execution.Parallel then task.synchronize() end
	--=======================================================================================================>
	-- Destroy all the Current Simulation Events so that we can recreate them on a new Event:
	if self._Connections.Simulation_EvaluateParallel then 
		self._Connections.Simulation_EvaluateParallel:Disconnect()
		self._Connections.Simulation_EvaluateParallel = nil :: any;
	end
	-- Destroy all the Current Simulation Events so that we can recreate them on a new Event:
	if self._Connections.Simulation_EvaluateSerial then
		self._Connections.Simulation_EvaluateSerial:Disconnect()
		self._Connections.Simulation_EvaluateSerial = nil :: any;
	end
	--=======================================================================================================>
	-- If Status is Off, we just Disconnect and Clear Connection if its initialized:
	if Status == 'Off' then return end
	--=======================================================================================================>
	-- Dynamically Index the RunService Event using the Name of the Simulation Config Chose: (PostSimulation, PreSimulation etc)
	local RunServiceSignal: RBXScriptSignal = RunService[Enums.Simulation:GetName(Simulation)]
	--=======================================================================================================>
	-- Whether the use Parallel or Serial Connection:
	local UseParallel = self._Config.Execution == Enums.Execution.Parallel

	-- If UseParallel is true, then we will connect a serial and parallel service event, else, run them both in Serial:
	if UseParallel then
		-- Connect the Simulation Event Dynamically:
		self._Connections.Simulation_EvaluateParallel = RunServiceSignal.ConnectParallel(RunServiceSignal, function(DeltaTime: number) 
			--==============================================================================>
			-- If the Counter is not at max, return to allow for varied update checking/polling:
			-- Checks every number interval as set in the Counters Table. 
			if Utility.RateLimiter(self._Counters.EvaluateParallel, DeltaTime) then self:EvaluateParallel(DeltaTime) end
			--==============================================================================>
		end)
		
		-- MAYBE ADD FOR PART FILTERING IN OVERLAP PARAMS:
		
		---- Connect the Simulation Event Dynamically:
		--self._Connections.Simulation_EvaluateSerial = RunServiceSignal.Connect(RunServiceSignal, function(DeltaTime: number) 
		--	--==============================================================================>
		--	-- If the Counter is not at max, return to allow for varied update checking/polling:
		--	-- Checks every number interval as set in the Counters Table. 
		--	if Utility.RateLimiter(self._Counters.EvaluateSerial, DeltaTime) then self:EvaluateSerial(DeltaTime) end
		--	--==============================================================================>
		--end)
		
	else
		-- Connect the Simulation Event Dynamically:
		self._Connections.Simulation_EvaluateSerial = RunServiceSignal.Connect(RunServiceSignal, function(DeltaTime: number) 
			--==============================================================================>
			-- If the Counter is not at max, return to allow for varied update checking/polling:
			-- Checks every number interval as set in the Counters Table. 
			if Utility.RateLimiter(self._Counters.EvaluateParallel, DeltaTime) then self:EvaluateParallel(DeltaTime) end
			if Utility.RateLimiter(self._Counters.EvaluateSerial, DeltaTime)   then self:EvaluateSerial(DeltaTime)   end
			--==============================================================================>
		end)
	end

	--=======================================================================================================>
end

--- Function that is called when the Rate Config is updated:
function Engine.SetRate(self: Engine, Rate: number)
	-- Does the second Counter value as a random number from 0 - to the max counter value, so that Runs can be offset:
	self._Counters.EvaluateSerial.CounterMax,   self._Counters.EvaluateSerial.Counter   =
		Enums.Rate:GetProperty(Rate) :: number, RANDOM:NextInteger(0, Enums.Rate:GetProperty(Rate) :: number)
	-- Does the second Counter value as a random number from 0 - to the max counter value, so that Runs can be offset:
	self._Counters.EvaluateParallel.CounterMax, self._Counters.EvaluateParallel.Counter = 
		Enums.Rate:GetProperty(Rate) :: number, RANDOM:NextInteger(0, Enums.Rate:GetProperty(Rate) :: number)
end

-- Method called when the Visiblity State Changes:
function Engine.SetVisibility(self: Engine, State: boolean)
	-- Call function on BoundsHandler:
	self._DetectionHandler:GetBoundsHandler():ToggleVisibility(State)
end

--===========================================================================================================================>

-- @Private
-- Method called when a ZonePart tag is added or removed:
function Engine.OnZonePartUpdate(self: Engine, Purpose: 'Add'|'Remove', ZonePart: BasePart)
	--=======================================================================================================>
	-- Boolean on whether the ZonePart is stored or not in the Dictionary:
	local ZonePartStoreIndex: number? = table.find(self._Instances.ZoneParts, ZonePart)
	-- If the Purpose is 'Remove', then remove the Part, else add it:
	if Purpose == 'Remove' then
		--===============================================================================================>
		-- If one is found, then Remove it from the Array:
		if ZonePartStoreIndex then 
			--================================================================>
			-- Remove the ZonePart from the Array:
			table.remove(self._Instances.ZoneParts, ZonePartStoreIndex)
			-- Call the RemoveZonePart function from whatever BoundsHandler Object is stored:
			-- Removes the ZonePart and its Details from its Internal Object Data:
			self._DetectionHandler:GetBoundsHandler():RemoveZonePiece(ZonePart)
			--================================================================>
		else return end
		--===============================================================================================>
	else
		--===============================================================================================>
		-- If one is not found, then Add it to the Array:
		if not ZonePartStoreIndex then 
			--================================================================>
			-- Store the ZonePart in an Array:
			table.insert(self._Instances.ZoneParts, ZonePart)
			-- Call the AddZonePart function from whatever BoundsHandler Object is stored:
			-- Adds the ZonePart and its Details to its Internal Object Data:
			self._DetectionHandler:GetBoundsHandler():AddZonePiece(ZonePart)
			--================================================================>
		else return end
		--===============================================================================================>
	end
	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function Engine.OnHolderInstanceUpdate(self: Engine, Purpose: 'Add'|'Remove', Holder: Instance)
	--=======================================================================================================>
	-- If the Purpose is 'Remove', then remove the Part, else add it:
	if Purpose == 'Remove' then
		--===============================================================================================>
		-- Find the Index of the Holder in the Array:
		local HolderIndex: number? = table.find(self._Instances.Holders, Holder) 
		-- If one is found, then Remove it from the Array:
		-- Remove the Part located at the Index from the Array:
		-- Return because theres nothing to update:
		if HolderIndex then table.remove(self._Instances.Holders, HolderIndex) else return end
		--===============================================================================================>
	else
		--===============================================================================================>
		-- If one is not found, then Add it to the Array:
		-- Insert the Holder into the Array:
		-- Return because theres nothing to update:
		if not table.find(self._Instances.Holders, Holder) then table.insert(self._Instances.Holders, Holder) else return end
		--===============================================================================================>
	end
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Step Function for Zone Calculations:
@native
function Engine.EvaluateSerial(self: Engine, DeltaTime: number)
	--=======================================================================================================>
	-- do something that loops through all the targets trackers and checks a 
	-- boolean that says whether their parts have changed and then update the array only then

	--if self._TargetHandlers.Players then

	--	local FilterIncludeArray = {}

	--	-- Loop through the CurrentPartsInZone:
	--	for Name: string, Tracker in self._TargetHandlers.Players.Trackers do
	--		Tracker:FillFilterArray(FilterIncludeArray)
	--	end

	--	self._OverlapParamaters.PartsIncludeList.FilterDescendantsInstances = FilterIncludeArray

	--end

	--=======================================================================================================>
end

-- Step Function for Zone Calculations:
@native
function Engine.EvaluateParallel(self: Engine, DeltaTime: number)
	--=======================================================================================================>
	-- Run the Target Detection logic by the Zone:
	self._DetectionHandler:Evaluate()
	-- Fire Signals for the Detected:
	self._DetectionHandler:FireSignals(self._ActiveSignals)
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ INDEXER FUNCTIONS: ]


-- Create the MetaIndex function:
function Engine.__index(self: Engine, Index: string): any
	--=======================================================================================================>
	-- Specific Indexing:
	--=======================================================================================================>
	if Index == 'Container' then return self._Container end
	-- Return a ZoneBoxes Index which is just the Container if the Container Type is Table Of Boxes:
	if Index == '_ZoneBoxes' then return (if self._ContainerType == 'Boxes' then self._Container else nil) end
	if Index == '_ZoneParts' then return self._Instances.ZoneParts end
	if Index == '_Holders' then   return self._Instances.Holders end
	--=======================================================================================================>
	if Index == 'Active' then return self._States.Active end
	--=======================================================================================================>
	-- If Index is in the immediate Module tree, return that value:			
	if Engine[Index] then return Engine[Index] end
	--=======================================================================================================>
	-- Return False if all else fails!
	return false 
	--=======================================================================================================>
end

-- Create the New Index function:
function Engine.__newindex(self: Engine, Index: string, Value: any)
	error(`"{Index}" cannot be added to Engine`)
end

--===========================================================================================================================>

--- Called from the Actor running this Module, to update some global scope:
function Engine.UpdateGlobalScope(ZonerHolder: Types.ZonerHolder)
	Detections.UpdateGlobalScope(ZonerHolder)
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze({New = Engine.New, UpdateGlobalScope = Engine.UpdateGlobalScope})

--===========================================================================================================================>