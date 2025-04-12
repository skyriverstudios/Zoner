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
--[ DEFINE CONSTANTS: ]


-- The RunContext/Scope of the Module:
local RUN_SCOPE: 'Client'|'Server' = if RunService:IsServer() then 'Server' else 'Client'

--===========================================================================================================================>
--[ DEFINE GLOBALS: ]


local Utility = require(`../Utility`);
local Helpers = require(`../Zone/Helpers`)
local Enums   = require(`../Enums`);

local Detections = require(script:WaitForChild('Detections'));

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local Types = require(`../../../Types`)

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
	_Settings:      Types.ZoneSettingsTable;
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

	--======================================>
}, {} :: typeof(Engine)))

--===========================================================================================================================>
--[ LOCAL FUNCTIONS: ]


local function Initialize(Engine: Engine)
	--=======================================================================================================>

	-- If the Execution Setting is Parallel to use Parallel:
	-- Using this because 'Dynamic Property Access on Signals' is 'unsafe'
	local UseParallel = Engine._Settings.Execution == Enums.Execution.Parallel

	--=======================================================================================================>

	-- Reference the Folder Instance:
	local ActiveTargets = Engine._ZoneFolder.ActiveTargets
	-- Index the Propert Connection Function/Signal based on 'UserParallel'
	local AC_ActiveTargets_Connect = 
		if UseParallel then ActiveTargets.AttributeChanged.Connect else ActiveTargets.AttributeChanged.ConnectParallel

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
	local AC_States_Connect = 
		if UseParallel then States.AttributeChanged.Connect else States.AttributeChanged.ConnectParallel

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
		if Engine._Settings.Execution == Enums.Execution.Parallel then task.synchronize() end
		--================================================================================================>
		-- If the State is Visible, thenm call the Function for Toggling Visibility On and Off:
		if State == 'Visible' then Engine:SetVisibility(Engine._States[State]) end
		if State == 'Relocated' then 
			Engine._DetectionHandler:GetBoundsHandler().Relocated = Engine._States.Relocated 
			-- Update the Bounds Visibility if its already visible after being relocated:
			if Engine._DetectionHandler:GetBoundsHandler().Visible then 
				--Engine._BoundsHandler:ToggleVisibility(false)
				--Engine._BoundsHandler:ToggleVisibility(true)
			end
		end
		if State == 'Paused' then
			Engine:SetSimulation(Engine._Settings.Simulation, if Engine._States[State] == true then 'Off' else 'On')
		end
		if State == 'Active' then
			Engine:SetSimulation(Engine._Settings.Simulation, if Engine._States[State] == false then 'Off' else 'On')
		end
		--================================================================================================>
	end)

	-- Reference the Folder Instance:
	local Settings = Engine._ZoneFolder.Settings
	-- Index the Propert Connection Function/Signal based on 'UserParallel'
	local AC_Settings_Connect = 
		if UseParallel then Settings.AttributeChanged.Connect else Settings.AttributeChanged.ConnectParallel

	-- Fire when any Attribute Changes on the Settings:
	Engine._Connections['AC_Settings'] = AC_Settings_Connect(Settings.AttributeChanged, function(Setting: string)
		--================================================================================================>
		-- If already Destroyed, return:
		if Engine._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		Engine._Settings[Setting] = Engine._ZoneFolder.Settings:GetAttribute(Setting)
		--================================================================================================>
		-- If the Setting is the Detection, then call the Method for it:
		if string.gmatch(Setting, 'Detection') then
			Engine:SetDetection(Engine._Settings.DetectionCoverage, Engine._Settings.DetectionMode, Engine._Settings.DetectionMethod)
		end
		-- If the Setting is the Simulation, then call the Method for it:
		if Setting == 'Simulation' then Engine:SetSimulation(Engine._Settings[Setting], 'On') end
		-- If the Setting is the Rate, then call the Method for it:
		if Setting == 'Rate'       then Engine:SetRate(Engine._Settings[Setting])       end
		--================================================================================================>
	end)

	--=======================================================================================================>

	-- If the Engine is being Run in Parallel (on another actor) then 
	-- Connect Events that cant be reached by the Parent Zone Object:
	if Engine._Settings.Execution == Enums.Execution.Parallel then
		--=========================================================================================>

		-- Connect to the AncestryChanged event of the ZoneFolder:
		-- We then check if the ZoneFolder is still a decendent of the WorldModel, meaning it hasnt been destroyed.
		-- We do this to clear the Data in case the ZoneFolder is Destroyed:
		Engine._Connections['AC_ZoneFolder'] = Engine._ZoneFolder.AncestryChanged:Connect(function()
			--====================================================================================>
			-- If the Destroying Attribute is true on the ZoneFolder, then ignore the Ancestry Changed:
			if Engine._ZoneFolder:GetAttribute('Destroying') == true then return end
			if Engine._ZoneFolder.Parent == nil or Engine._ZoneFolder:IsDescendantOf(game) == false then 
				print('Backup, Engine: Folder Ancestry Changed'); Engine:Destroy()
			end
			--====================================================================================>
		end)

		--=========================================================================================>

		-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
		if Engine._ContainerType == 'TableOBox' then return end

		--=========================================================================================>

		-- Connect to the ZonePart Tag Added Signal:
		-- Fires when a Part with the Zone Tag is added back to the Workspace:
		-- We will use this to reduce the Zone Based on Streaming:
		Engine._Connections['CS_ZonePart_Add'] = CollectionService:GetInstanceAddedSignal(Engine._Tags.ZonePart):Connect(function(ZonePart: BasePart)
			Engine:OnZonePartUpdate('Add', ZonePart)
		end)

		-- Connect to the ZonePart Tag Removed Signal:
		-- Fires when a Part with the Zone Tag is removed from the Workspace:
		-- We will use this to restore the Zone Based on Streaming:
		Engine._Connections['CS_ZonePart_Remove'] = CollectionService:GetInstanceRemovedSignal(Engine._Tags.ZonePart):Connect(function(ZonePart: BasePart)
			Engine:OnZonePartUpdate('Remove', ZonePart)
		end)

		-- Connect to the Holder Tag Added Signal:
		Engine._Connections['CS_Holder_Add'] = CollectionService:GetInstanceAddedSignal(Engine._Tags.Holder):ConnectParallel(function(Holder: Instance)
			Engine:OnHolderInstanceUpdate('Add', Holder)
		end)

		-- Connect to the Holder Tag Added Signal:
		Engine._Connections['CS_Holder_Remove'] = CollectionService:GetInstanceRemovedSignal(Engine._Tags.Holder):ConnectParallel(function(Holder: Instance)
			Engine:OnHolderInstanceUpdate('Remove', Holder)
		end)

		--=========================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- Constructor Function for this individual object:
function Engine.New(Id: string, Folder: Types.ZoneFolder, Container: Types.ZoneContainer): Engine
	--=======================================================================================================>

	-- Set a Memory Category for this Zoner:
	debug.setmemorycategory('[Zoner]: -> Zoner -> Zone -> (Engine)')

	--=======================================================================================================>
	-- Define Data
	local EngineData = {
		--====================================================>
		-- Store the Id of the Zone:
		_Identifier = Id;
		-- Reference to the Original Zone Container:
		_Container = Container;
		_ContainerType = Helpers:GetZoneContainerType(Container);
		--- Reference to the ZoneFolder in the Zoner:
		_ZoneFolder = Folder;
		--====================================================>
		-- Dictionary of ZoneParts and their Properties:
		_Settings = {};
		--====================================================>
		_Tags = {
			ZonePart = `{Id}:ZonePart:{RUN_SCOPE}`;
			Holder   = `{Id}:Holder:{RUN_SCOPE}`;
		};
		--====================================================>

		_Instances = {
			Holders   = {};
			ZoneParts = {};
		};

		_States = {};
		_ActiveTargets = {};

		_Counters = {
			EvaluateParallel = {Counter = 0; CounterMax = 1};
			EvaluateSerial   = {Counter = 0; CounterMax = 1};
		};

		_Connections = {};
		--====================================================>
	} :: any

	--=======================================================================================================>

	-- Update each of the Folder Attribute Dictionaries by grabbing their attributes dynamically via the Array:
	for Index: number, FolderName: string in ipairs({'States', 'Settings', 'ActiveTargets'}) do
		--================================================================================================>
		-- Find the Folder (Configuration) as a Child of the Actor using the Name String passed:
		local DataFolder: Configuration = EngineData._ZoneFolder:FindFirstChild(FolderName) :: Configuration
		-- Grab the Attributes on the Folders and update our copy of them:
		for Name: string, Value: any in DataFolder:GetAttributes() do EngineData[`_{FolderName}`][Name] = Value end
		--================================================================================================>
	end

	-- Construct a new Handler Object with the Trove and Set it in the Table:
	-- Index the Detection Specific Table with the DetectionMethod Name to gets its New Method:
	EngineData._DetectionHandler = Detections[Enums.DetectionMethod:GetName(EngineData._Settings.DetectionMethod)].New({
		ZoneContainerType = EngineData._ContainerType;
		ZoneSettings      = EngineData._Settings;
		ZoneStates        = EngineData._States;
		ZoneFolder        = EngineData._ZoneFolder;
		ZonePieces        = if EngineData._ContainerType == 'TableOBox' then EngineData._Container else EngineData._Instances.ZoneParts;
		ZoneSignal        = script.Parent.Parent.Parent.Parent:WaitForChild('ZoneSignal');
		ZoneId            = EngineData._Identifier;
	})

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(EngineData, Engine)

	--=======================================================================================================>

	-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
	if EngineData._ContainerType ~= 'TableOBox' then 
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

	-- Update the Rate Counter with the Setting:
	EngineData:SetRate(EngineData._Settings.Rate)
	-- Update the Detection with the Setting:
	EngineData:SetDetection(EngineData._Settings.DetectionCoverage, EngineData._Settings.DetectionMode, EngineData._Settings.DetectionMethod)
	-- Update the Simulation Events with the Setting:
	EngineData:SetSimulation(EngineData._Settings.Simulation, 'On')
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
--[ SETTING UPDATE METHODS: ]


-- Function that is called when the Detection Setting is updated:
function Engine.SetDetection(self: Engine, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?)
	self._DetectionHandler:SetDetection(DetectionCoverage, DetectionMode, DetectionMethod)
end

--- Function that is called when the Simulation Setting is updated:
function Engine.SetSimulation(self: Engine, Simulation: number, Status: 'On'|'Off')
	--=======================================================================================================>
	-- If ManualStepping is true then we do not connect the internal Simulation:
	if self._Settings.ManualStepping == true then return end
	-- Synchronize the thread:
	if self._Settings.Execution == Enums.Execution.Parallel then task.synchronize() end
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
	-- Dynamically Index the RunService Event using the Name of the Simulation Setting Chose: (PostSimulation, PreSimulation etc)
	local RunServiceSignal: RBXScriptSignal = RunService[Enums.Simulation:GetName(Simulation)]
	--=======================================================================================================>
	-- Whether the use Parallel or Serial Connection:
	local UseParallel = self._Settings.Execution == Enums.Execution.Parallel

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
		-- Connect the Simulation Event Dynamically:
		self._Connections.Simulation_EvaluateSerial = RunServiceSignal.Connect(RunServiceSignal, function(DeltaTime: number) 
			--==============================================================================>
			-- If the Counter is not at max, return to allow for varied update checking/polling:
			-- Checks every number interval as set in the Counters Table. 
			if Utility.RateLimiter(self._Counters.EvaluateSerial, DeltaTime) then self:EvaluateSerial(DeltaTime) end
			--==============================================================================>
		end)
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

--- Function that is called when the Rate Setting is updated:
function Engine.SetRate(self: Engine, Rate: number)
	self._Counters.EvaluateSerial.CounterMax,   self._Counters.EvaluateSerial.Counter   = Enums.Rate:GetProperty(Rate) :: number, 0
	self._Counters.EvaluateParallel.CounterMax, self._Counters.EvaluateParallel.Counter = Enums.Rate:GetProperty(Rate) :: number, 0
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
			self._DetectionHandler:GetBoundsHandler():RemoveZonePart(ZonePart)
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
			self._DetectionHandler:GetBoundsHandler():AddZonePart(ZonePart)
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
function Engine.EvaluateParallel(self: Engine, DeltaTime: number)
	--=======================================================================================================>

	-- Loop through the ActiveTargets Dictionary, checking the State of whether its Active:
	-- If it is Active, Call the CheckZone Method for that Trigger, followed by calling the CheckTrigger Method:
	--for Target, State in self._ActiveTargets do if State == true then self:DetectTarget(Target :: ZoneTargets) end end

	-- Run the Target Detection logic by the Zone:
	self._DetectionHandler:RunDetection()
	-- Fire Signals for the Detected:
	self._DetectionHandler:FireSignals()

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
	if Index == '_ZoneBoxes' then return (if self._ContainerType == 'TableOBox' then self._Container else nil) end
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

-- Return a Frozen Module Table:
return table.freeze({New = Engine.New})

--===========================================================================================================================>