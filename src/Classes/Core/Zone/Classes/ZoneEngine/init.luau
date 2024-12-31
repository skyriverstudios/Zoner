--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Define Module table
local ZoneEngineModule = {}

--===========================================================================================================================>
--[ SERVICES: ]


-- Get the needed Services for the following Code:
local CollectionService = game:GetService('CollectionService')
local RunService        = game:GetService('RunService')

--===========================================================================================================================>

-- Reference the Top Level Module so that we can easily Index our Modules
local ZonerModule = script.Parent.Parent.Parent.Parent.Parent

-- Require the Enum2 Module for Custom Enums:
local Enums   = require(ZonerModule.Classes.Utilities.Enums);
-- Require the Trove Module for Cleanup:
local Trove   = require(ZonerModule.Classes.Utilities.Trove);
-- Require the Trove Module for Cleanup:
local Utility = require(ZonerModule.Classes.Utilities.Utility);
-- Require the Trove Module for Cleanup:
local Regions = require(ZonerModule.Classes.Utilities.Regions);

local WorldModel = require(ZonerModule.Classes.Core.WorldModel)

local ZoneConstants = require(script.Parent.Parent.Children.Constants);

local ZoneUtilities   = require(script.Parent.Parent.Children.ZoneUtilities)

local DetectionHandler = require(script.Classes.DetectionHandler);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types)

type ZoneContainer      = TypeDefinitions.ZoneContainer
type ZoneTargets        = TypeDefinitions.ZoneTargets
type ZoneFolder         = TypeDefinitions.ZoneFolder
type ZonerActor         = TypeDefinitions.ZonerActor

type ZoneEngine         = TypeDefinitions.ZoneEngine

type Enums              = Enums.Enums

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- Constructor Function for this individual object:
function ZoneEngineModule.New(Id: string, Folder: ZoneFolder, Container: ZoneContainer, RunScope: 'Server'|'Client'): ZoneEngine
	--=======================================================================================================>

	-- Set a Memory Category for this Zoner:
	debug.setmemorycategory('Zoner: ZoneEngine')

	--=======================================================================================================>
	-- Define Data
	local ZoneEngineData: TypeDefinitions.ZoneEngineMetaData = {
		--====================================================>
		-- Zone Engine's Main Trove:
		_Trove = Trove.New();
		--====================================================>
		-- Store the Current RunScope:
		_RunScope = RunScope;
		--====================================================>
		-- Store the Id of the Zone:
		_Identifier = Id;
		-- Reference to the Original Zone Container:
		_Container = Container;
		_ContainerType = ZoneUtilities:GetZoneContainerType(Container);
		--- Reference to the ZoneFolder in the Zoner:
		_ZoneFolder = Folder;
		--====================================================>
		-- Dictionary of ZoneParts and their Properties:
		_ZoneParts = {};
		_Settings = {};
		_Client = {};
		--====================================================>
		_Tags = {
			ZonePart = `{Id}:ZonePart:{RunScope}`;
			Holder   = `{Id}:Holder:{RunScope}`;
		};
		--====================================================>

		_Instances = {
			Holders   = {};
			ZoneParts = {};
		};

		_Events    = {} :: any;

		_States = {};
		_ActiveTargets = {};

		_Counters = {
			ZoneStep = {Counter = 0; CounterMax = 1};
		};

		_Updates = {
			Region = false;
			Parts  = false;
		};

		_Connections = {};
		--====================================================>
	} :: TypeDefinitions.ZoneEngineMetaData

	--=======================================================================================================>

	-- Update each of the Folder Attribute Dictionaries by grabbing their attributes dynamically via the Array:
	for Index: number, FolderName: string in ipairs({'States', 'Properties', 'Settings', 'ActiveTargets'}) do
		--================================================================================================>
		-- Find the Folder (Configuration) as a Child of the Actor using the Name String passed:
		local Folder: Configuration = ZoneEngineData._ZoneFolder:FindFirstChild(FolderName) :: Configuration
		-- Grab the Attributes on the Folders and update our copy of them:
		for Name: string, Value: any in Folder:GetAttributes() do ZoneEngineData[`_{FolderName}`][Name] = Value end
		--================================================================================================>
	end

	-- Construct a new Handler Object with the Trove and Set it in the Table:
	-- Index the Detection Specific Table with the DetectionMethod Name to gets its New Method:
	ZoneEngineData._DetectionHandler = ZoneEngineData._Trove:Construct(
		--===================================================================================>
		-- Get the Name 'string' of the DetectionMethod Enum and use it to Index the DetectionHandler Table:
		DetectionHandler[Enums.Enums.DetectionMethod:GetName(ZoneEngineData._Settings.DetectionMethod)],
		--===================================================================================>
		-- Pass in the ZoneEngine Settings Table:
		ZoneEngineData._Settings,
		-- Pass in the ZoneEngine States Table:
		ZoneEngineData._States,
		--===================================================================================>
	)

	ZoneEngineData._DetectionHandler:SetBoundsHandler(
		ZoneEngineData._Settings.Bounds, 
		ZoneEngineData._ZoneBoxes or ZoneEngineData._ZoneParts,
		ZoneEngineData._ContainerType,
	)

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(ZoneEngineData, ZoneEngineModule)

	-- Start the Inventory:
	ZoneEngineData:_Initialize()

	--=======================================================================================================>

	-- Return the MetaTable Data
	return ZoneEngineData :: any

	--=======================================================================================================>
end

-- Destroyer Function which clears the entirity of the Data for the Object:
function ZoneEngineModule.Destroy(self: ZoneEngine)
	--=======================================================================================================>
	print('destroying:', self._Identifier)
	-- If Destroyed was already called then return:
	if self._States.Destroyed then return end

	-- Set the Destroyed State to true:
	self._States.Destroyed = true

	--=======================================================================================================>

	-- Clean with Trove
	if self._Trove then self._Trove:Destroy(); self._Trove = nil :: any; end

	-- Clear all self data:
	for Index, Data in pairs(self) do self[Index] = nil end

	-- Set the Metatable to nil
	setmetatable(self :: any, nil)	

	print('destroy success:', self._Identifier)
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ INITIALIZER FUNCTIONS: ]


-- Initialization function to start/setup the Object's initial data:
function ZoneEngineModule._Initialize(self: ZoneEngine)
	for Index: number, Function: string in ipairs({'_SetData', '_SetEvents', '_SetValues'}) do self[Function](self) end
end

-- Initialization function to start/setup the Object's initial data:
function ZoneEngineModule._SetData(self: ZoneEngine)
	--=======================================================================================================>
	local EventsChildren: {BindableEvent} = self._ZoneFolder.Events:GetChildren() :: any

	for Index: number, Event: BindableEvent in ipairs(EventsChildren) do self._Events[Event.Name] = Event end

	EventsChildren = nil :: any

	--=======================================================================================================>

	-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
	if self._ContainerType == 'TableOBox' then return end

	--=======================================================================================================>

	-- Check the CollectionService Tags for the ZoneParts already tagged:
	for Index: number, Part in ipairs(CollectionService:GetTagged(self._Tags.ZonePart)) do
		self:OnZonePartUpdate('Add', Part)
	end

	-- Check the CollectionService Tags for the Holders already tagged:
	for Index: number, Holder in ipairs(CollectionService:GetTagged(self._Tags.Holder)) do
		self:OnHolderInstanceUpdate('Add', Holder)
	end

	--=======================================================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function ZoneEngineModule._SetEvents(self: ZoneEngine)
	--=======================================================================================================>
	-- Dynamically Create the Connect Function on the Trove based on if the Execution Setting is Serial or Parallel:
	-- Creates: "ConnectParallel" or "Connect"
	local ConnectFunctionName: string = `Connect{if self._Settings.Execution == Enums.Enums.Execution.Serial then '' else 'Parallel'}`

	-- Fire when any Attribute Changes on the ActiveTargets:
	self._Trove[ConnectFunctionName](self._Trove, self._ZoneFolder.ActiveTargets.AttributeChanged, function(Target: DetectionHandler.TargetTypes)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		self._ActiveTargets[Target] = self._ZoneFolder.ActiveTargets:GetAttribute(Target)
		--================================================================================================>
		-- Synchronize the thread:
		if ConnectFunctionName == 'ConnectParallel' then task.synchronize() end
		--================================================================================================>
		-- If the Target is Active then Add the TargetHandler on the DetectionHandler, else Remove it from the DetectionHandler:
		if self._ActiveTargets[Target] then self._DetectionHandler:AddTargetHandler(Target) else self._DetectionHandler:RemoveTargetHandler(Target) end
		--================================================================================================>
	end)

	-- Fire when any Attribute Changes on the States:
	self._Trove[ConnectFunctionName](self._Trove, self._ZoneFolder.States.AttributeChanged, function(State: string)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		self._States[State] = self._ZoneFolder.States:GetAttribute(State)
		--================================================================================================>
		-- If we are in parallel syncrhonize to serial:
		if self._Settings.Execution == Enums.Enums.Execution.Parallel then task.synchronize() end
		--================================================================================================>
		-- If the State is Visible, thenm call the Function for Toggling Visibility On and Off:
		if State == 'Visible' then self:SetVisibility(self._States[State]) end
		if State == 'Relocated' then 
			self._DetectionHandler:GetBoundsHandler().Relocated = self._States.Relocated 
			-- Update the Bounds Visibility if its already visible after being relocated:
			if self._DetectionHandler:GetBoundsHandler().Visible then 
				--self._BoundsHandler:ToggleVisibility(false)
				--self._BoundsHandler:ToggleVisibility(true)
			end
		end
		--================================================================================================>
	end)

	-- Fire when any Attribute Changes on the Settings:
	self._Trove[ConnectFunctionName](self._Trove, self._ZoneFolder.Settings.AttributeChanged, function(Setting: string)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		self._Settings[Setting] = self._ZoneFolder.Settings:GetAttribute(Setting)
		--================================================================================================>
		-- If the Setting is the Detection, then call the Method for it:
		if string.gmatch(Setting, 'Detection') then
			self:SetDetection(self._Settings.DetectionCoverage, self._Settings.DetectionMode, self._Settings.DetectionMethod)
		end
		-- If the Setting is the Simulation, then call the Method for it:
		if Setting == 'Simulation' then self:SetSimulation(self._Settings[Setting]) end
		-- If the Setting is the Rate, then call the Method for it:
		if Setting == 'Rate'       then self:SetRate(self._Settings[Setting])       end
		--================================================================================================>
	end)

	--=======================================================================================================>

	-- If the ZoneEngine is being Run in Parallel (on another actor) then 
	-- Connect Events that cant be reached by the Parent Zone Object:
	if self._Settings.Execution == Enums.Enums.Execution.Parallel then
		--=========================================================================================>

		-- Connect to the AncestryChanged event of the ZoneFolder:
		-- We then check if the ZoneFolder is still a decendent of the WorldModel, meaning it hasnt been destroyed.
		-- We do this to clear the Data in case the ZoneFolder is Destroyed:
		self._Trove:Connect(self._ZoneFolder.AncestryChanged, function()
			--====================================================================================>
			-- If the Destroying Attribute is true on the ZoneFolder, then ignore the Ancestry Changed:
			if self._ZoneFolder:GetAttribute('Destroying') == true then return end
			if self._ZoneFolder.Parent == nil or self._ZoneFolder:IsDescendantOf(game) == false then 
				print('Backup, ZoneEngine: Folder Ancestry Changed'); self:Destroy()
			end
			--====================================================================================>
		end)

		--=========================================================================================>

		-- Connect to the RunService PostSimulation (Heartbeat) event:
		self._Trove:Connect(RunService.PostSimulation, function(DeltaTime: number)
			self:OnPostSimulation('Sync', DeltaTime)
		end)

		-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
		if self._ContainerType == 'TableOBox' then return end

		-- Connect to the ZonePart Tag Added Signal:
		-- Fires when a Part with the Zone Tag is added back to the Workspace:
		-- We will use this to reduce the Zone Based on Streaming:
		self._Trove:Connect(CollectionService:GetInstanceAddedSignal(self._Tags.ZonePart), function(ZonePart: BasePart)
			self:OnZonePartUpdate('Add', ZonePart)
		end)

		-- Connect to the ZonePart Tag Removed Signal:
		-- Fires when a Part with the Zone Tag is removed from the Workspace:
		-- We will use this to restore the Zone Based on Streaming:
		self._Trove:Connect(CollectionService:GetInstanceRemovedSignal(self._Tags.ZonePart), function(ZonePart: BasePart)
			self:OnZonePartUpdate('Remove', ZonePart)
		end)

		-- Connect to the Holder Tag Added Signal:
		self._Trove:ConnectParallel(CollectionService:GetInstanceAddedSignal(self._Tags.Holder), function(Holder: Instance)
			-- Call the ZonePartUpdate Function:
			self:OnHolderInstanceUpdate('Add', Holder)
		end)

		-- Connect to the Holder Tag Removed Signal:
		self._Trove:ConnectParallel(CollectionService:GetInstanceRemovedSignal(self._Tags.Holder), function(Holder: Instance)
			-- Call the ZonePartUpdate Function:
			self:OnHolderInstanceUpdate('Remove', Holder)
		end)

		--=========================================================================================>
	end

	--=======================================================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function ZoneEngineModule._SetValues(self: ZoneEngine)
	--=======================================================================================================>
	-- Update the Rate Counter with the Setting:
	self:SetRate(self._Settings.Rate)
	-- Update the Detection with the Setting:
	self:SetDetection(self._Settings.DetectionCoverage, self._Settings.DetectionMode, self._Settings.DetectionMethod)
	-- Update the Simulation Events with the Setting:
	self:SetSimulation(self._Settings.Simulation)
	-- Update the Visiblity with the State:
	self:SetVisibility(self._States.Visible)
	--=======================================================================================================>
	-- Loop through the ActiveTargets and Create a TargetHandler for each one accordingly:
	for Target, State: boolean in pairs(self._ActiveTargets) do 
		if State then self._DetectionHandler:AddTargetHandler(Target) else self._DetectionHandler:RemoveTargetHandler(Target) end
	end
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ SETTING UPDATE METHODS: ]


-- Function that is called when the Detection Setting is updated:
function ZoneEngineModule.SetDetection(self: ZoneEngine, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?)
	self._DetectionHandler:SetDetection(DetectionCoverage, DetectionMode, DetectionMethod)
end

--- Function that is called when the Simulation Setting is updated:
function ZoneEngineModule.SetSimulation(self: ZoneEngine, Simulation: number)
	--=======================================================================================================>
	-- If ManualStepping is true then we do not connect the internal Simulation:
	if self._Settings.ManualStepping == true then return end
	-- Synchronize the thread:
	if self._Settings.Execution == Enums.Enums.Execution.Parallel then task.synchronize() end
	--=======================================================================================================>

	-- Destroy all the Current Simulation Events so that we can recreate them on a new Event:
	if self._Connections.Simulation then self._Trove:Remove(self._Connections.Simulation); self._Connections.Simulation = nil :: any; end

	-- Dynamically Index the RunService Event using the Name of the Simulation Setting Chose: (PostSimulation, PreSimulation etc)
	local RunServiceSignal: RBXScriptSignal = RunService[Enums.Enums.Simulation:GetName(Simulation)]

	-- Only doing this because Roblox Warns about 'Unsafe' Dynamic Connections:
	if self._Settings.Execution == Enums.Enums.Execution.Parallel then
		-- Connect to the RunService Event using the Simulation Trove and pass in all the Variables for Indexing:
		self._Connections.Simulation = RunServiceSignal:ConnectParallel(function(DeltaTime: number)
			self:OnSimulation('Desync', DeltaTime)
		end)
	else
		-- Connect to the RunService Event using the Simulation Trove and pass in all the Variables for Indexing:
		self._Connections.Simulation = RunServiceSignal:Connect(function(DeltaTime: number)
			self:OnSimulation('Desync', DeltaTime)
		end)
	end

	-- Add the Simulation to the Trove so it can be Cleaned up on Object Destroy:
	self._Trove:Add(self._Connections.Simulation)
	--=======================================================================================================>
end

--- Function that is called when the Rate Setting is updated:
function ZoneEngineModule.SetRate(self: ZoneEngine, Rate: number)
	self._Counters.ZoneStep.CounterMax, self._Counters.ZoneStep.Counter = Enums.Enums.Rate:GetProperty(Rate) :: number, 0
end

-- Method called when the Visiblity State Changes:
function ZoneEngineModule.SetVisibility(self: ZoneEngine, State: boolean)
	-- Call function on BoundsHandler:
	self._DetectionHandler:GetBoundsHandler():ToggleVisibility(State)
end

--===========================================================================================================================>
--[ ZONE COMPUTATION METHODS: ]


-- Method called when a ZonePart tag is added or removed:
@native
function ZoneEngineModule.DetectTarget(self: ZoneEngine, Target: ZoneTargets)
	--=======================================================================================================>

	-- Begin Profiling:
	debug.profilebegin(`DetectTarget: {Target}`)


	if Target == '_Parts' then
		--=============================================================================================>

		-- Loop through Entered and Exited Arrays and Fire Signals and clear tables:
		do
			--==========================================================================>

			-- Loop through the CurrentPartsInZone:
			for Part: BasePart, State: boolean in self._TargetHandlers.Parts.CurrentParts do
				--===============================================================================>
				-- If the CurrentPart was NOT in the Zone Previously:
				-- Then Add the Part to the Array of Parts that have just now ENTERED:
				if self._TargetHandlers.Parts.PreviousParts[Part] == nil then 
					table.insert(self._TargetHandlers.Parts.Entered, Part)	
				end
				--===============================================================================>
			end

			-- Loop through the CurrentPartsInZone:
			for Part: BasePart, State: boolean in self._TargetHandlers.Parts.PreviousParts do
				--===============================================================================>
				-- If the PreviousPart is now NOT in the Current Zone Parts:
				-- Then Add the Part to the Array of Parts that have just now EXITED:
				if self._TargetHandlers.Parts.CurrentParts[Part] == nil then 
					table.insert(self._TargetHandlers.Parts.Exited, Part)
				end
				--===============================================================================>
			end

			-- Loop through the EnteredParts:
			for Index: number, Part: BasePart in ipairs(self._TargetHandlers.Parts.Entered) do 
				self._Events.ZoneSignals:Fire(ZoneConstants.ZoneSignalHash.Send['PartEntered'], Part)
			end

			-- Loop through the ExitedParts:
			for Index: number, Part: BasePart in ipairs(self._TargetHandlers.Parts.Exited) do
				self._Events.ZoneSignals:Fire(ZoneConstants.ZoneSignalHash.Send['PartExited'], Part)
			end

			--==========================================================================>

			table.clear(self._TargetHandlers.Parts.Entered)
			table.clear(self._TargetHandlers.Parts.Exited)

			--==========================================================================>
		end

		--=============================================================================================>
	end

	local poop = false

	if poop == true then

		-- Loop through Entered and Exited Arrays and Fire Signals and clear tables:
		do
			--==========================================================================>

			-- Loop through the EnteredParts:
			for Index: number, Player: Player in ipairs(self._TargetHandlers.Players.Entered) do 
				self._Events.ZoneSignals:Fire(ZoneConstants.ZoneSignalHash.Send['PlayerEntered'], Player)
			end

			-- Loop through the ExitedParts:
			for Index: number, Player: Player in ipairs(self._TargetHandlers.Players.Exited) do
				self._Events.ZoneSignals:Fire(ZoneConstants.ZoneSignalHash.Send['PlayerExited'], Player)
			end

			--==========================================================================>

			table.clear(self._TargetHandlers.Players.Entered)
			table.clear(self._TargetHandlers.Players.Exited)

			--==========================================================================>
		end

	end


	-- End Profiling:
	debug.profileend()

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Method called when a ZonePart tag is added or removed:
function ZoneEngineModule.OnZonePartUpdate(self: ZoneEngine, Purpose: 'Add'|'Remove', ZonePart: BasePart)
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
function ZoneEngineModule.OnHolderInstanceUpdate(self: ZoneEngine, Purpose: 'Add'|'Remove', Holder: Instance)
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

-- Method called on the PostSimulation (Heartbeat) RunService Event:
function ZoneEngineModule.OnPostSimulation(self: ZoneEngine, Type: 'Sync'|'Desync', DeltaTime: number)
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

	---- If the Region Boolean is true, then update all the Attributes:
	--if self._Updates.Region then
	--	--================================================================================>
	--	-- Set the Boolean to false now that all the Attributes have been updated:
	--	self._Updates.Region = false
	--	--================================================================================>
	--end

	---- If the Parts Boolean is true, then update all the Attributes:
	--if self._Updates.Parts then
	--	--================================================================================>
	--	-- Set the Boolean to false now that all the Attributes have been updated:
	--	self._Updates.Parts = false
	--	--================================================================================>
	--end

	--=======================================================================================================>
end

-- Method called on PostSimulation, PostRender, or PreSimulation RunService Event:
function ZoneEngineModule.OnSimulation(self: ZoneEngine, Type: 'Sync'|'Desync', DeltaTime: number)
	--=======================================================================================================>

	if Type == 'Sync' then 
		--==============================================================================================>



		--==============================================================================================>
	else
		--==============================================================================================>
		-- If the Zone is Paused, then return and dont do any Detection:
		if self._States.Paused == true then return end
		-- If the Zone is not Active, return and dont do any Detection:
		if self._States.Active == false then return end
		--==============================================================================================>
		-- If the Counter is not at max, return to allow for varied update checking/polling:
		-- Checks every number interval as set in the Counters Table. 
		if not Utility:RateLimiter(self._Counters.ZoneStep, DeltaTime) then return end
		--=======================================================================================================>
		-- Call the Step Method in the Internal Simulation Function:
		self:Step(DeltaTime)
		--==============================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Step Function for Zone Calculations:
function ZoneEngineModule.Step(self: ZoneEngine, DeltaTime: number)
	--=======================================================================================================>
	
	-- If the Zone is Paused, then return and dont do any Detection:
	if self._States.Paused == true then return end
	-- If the Zone is not Active, return and dont do any Detection:
	if self._States.Active == false then return end

	--=======================================================================================================>

	-- Loop through the ActiveTargets Dictionary, checking the State of whether its Active:
	-- If it is Active, Call the CheckZone Method for that Trigger, followed by calling the CheckTrigger Method:
	--for Target, State in self._ActiveTargets do if State == true then self:DetectTarget(Target :: ZoneTargets) end end
	
	-- Run the Target Detection logic by the Zone:
	self._DetectionHandler:RunDetection()
	
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ INDEXER FUNCTIONS: ]


-- Create the MetaIndex function:
function ZoneEngineModule.__index(self: ZoneEngine, Index: string): any
	--=======================================================================================================>
	-- Specific Indexing:
	--=======================================================================================================>
	if Index == 'Container' then return self._Container end
	-- Return a ZoneBoxes Index which is just the Container if the Container Type is Table Of Boxes:
	if Index == '_ZoneBoxes' then return if self._ContainerType == 'TableOBox' then self._Container else nil end
	--=======================================================================================================>
	if Index == '_Active' or Index == 'Active' then return self._States.Active end
	--=======================================================================================================>
	if Index == '_Holders' then   return self._Instances.Holders end
	--=======================================================================================================>
	-- If Index is in the immediate Module tree, return that value:			
	if ZoneEngineModule[Index] then return ZoneEngineModule[Index] end
	--=======================================================================================================>
	-- Return False if all else fails!
	return false 
	--=======================================================================================================>
end

-- Create the New Index function:
function ZoneEngineModule.__newindex(self: ZoneEngine, Index: string, Value: any)
	--=======================================================================================================>
	error(`"{Index}" cannot be added to ZoneEngine`)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(ZoneEngineModule)

--===========================================================================================================================>