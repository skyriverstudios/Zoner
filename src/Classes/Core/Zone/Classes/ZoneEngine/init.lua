--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Define Module table
local ZoneEngineModule = {}

--===========================================================================================================================>
--[ SERVICES: ]


-- Get the needed Services for the following Code:
local CollectionService = game:GetService('CollectionService')
local RunService        = game:GetService('RunService')
local Players           = game:GetService('Players')

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

local TargetHandler = require(script.Classes.TargetHandler);
local BoundsHandler = require(script.Classes.BoundsHandler);

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
		_TargetHandlers = {};
		_BoundsHandlers = {};
		_BoundsHandler  = {} :: any;
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
		_OverlapParamaters = {
			PartsIncludeList = OverlapParams.new();
			PartsExcludeList = OverlapParams.new();
		};

		_States = {};
		_ActiveTargets = {};

		_Counters = {
			ZoneStep = {Counter = 0; CounterMax = 1};
		};

		_Properties = {
			AllZonePartsAreBlocks = false;
		} :: any;

		_Updates = {
			Region = false;
			Parts  = false;
		};

		_Connections = {};
		--====================================================>
	} :: TypeDefinitions.ZoneEngineMetaData

	--=======================================================================================================>

	ZoneEngineData._PartTrove   = ZoneEngineData._Trove:Extend()

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(ZoneEngineData, ZoneEngineModule)

	-- Start the Inventory:
	ZoneEngineData:Initialize()

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
	if self._Trove then self._Trove:Destroy() self._Trove = nil :: any end

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
function ZoneEngineModule.Initialize(self: ZoneEngine)
	for Index: number, Function: string in ipairs({'SetData', 'SetEvents', 'SetUpdates'}) do self[Function](self) end
end

-- Initialization function to start/setup the Object's initial data:
function ZoneEngineModule.SetData(self: ZoneEngine)
	--=======================================================================================================>

	local EventsChildren: {BindableEvent} = self._ZoneFolder.Events:GetChildren() :: any

	for Index: number, Event: BindableEvent in ipairs(EventsChildren) do self._Events[Event.Name] = Event end

	EventsChildren = nil :: any


	self._OverlapParamaters.PartsIncludeList.FilterType = Enum.RaycastFilterType.Include
	self._OverlapParamaters.PartsIncludeList.FilterDescendantsInstances = {}

	self._OverlapParamaters.PartsExcludeList.FilterType = Enum.RaycastFilterType.Exclude
	self._OverlapParamaters.PartsExcludeList.FilterDescendantsInstances = {} --self._ZoneParts :: {any}

	-- Update each of the Folder Attribute Dictionaries by grabbing their attributes dynamically via the Array:
	for Index: number, FolderName: string in ipairs({'States', 'Properties', 'Settings', 'ActiveTargets'}) do
		--================================================================================================>
		-- Find the Folder (Configuration) as a Child of the Actor using the Name String passed:
		local Folder: Configuration = self._ZoneFolder:FindFirstChild(FolderName) :: Configuration
		-- Grab the Attributes on the Folders and update our copy of them:
		for Name: string, Value: any in Folder:GetAttributes() do self[`_{FolderName}`][Name] = Value end
		--================================================================================================>
	end

	--=======================================================================================================>

	-- Create the Bounds Handler:
	do
		--==========================================================================>
		local BoundsName = Enums.Enums.Bounds:GetName(self._Settings.Bounds)

		-- Construct a new Handler Object with the Trove and Set it in the Table:
		self._BoundsHandlers[BoundsName] = self._Trove:Construct(
			-- Index the Target Specific Table with the Target Name to gets its New Method:
			BoundsHandler[BoundsName],
			-- Pass in the Current ZonePart's Array:
			self._ZoneBoxes or self._Instances.ZoneParts,
			-- Pass in whether the ZonePieces being sent are of Boxes or Parts:
			if self._ContainerType == 'TableOBox' then 'Box' else 'Part',
			-- Pass in the DetectionMethod Number:
			self._Settings.DetectionMethod,
			-- Send the Zone Id:
			self._Identifier,
			-- Pass in a Boolean on whether the Execution is Serial or not:
			self._Settings.Execution == Enums.Enums.Execution.Serial
		)

		-- Set the Individual reference to the BoundsHandler:
		self._BoundsHandler = self._BoundsHandlers[BoundsName]
		--==========================================================================>
	end

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
function ZoneEngineModule.SetEvents(self: ZoneEngine)
	--=======================================================================================================>

	-- Dynamically Create the Connect Function on the Trove based on if the Execution Setting is Serial or Parallel:
	-- Creates: "ConnectParallel" or "Connect"
	local ConnectFunctionName: string = `Connect{if self._Settings.Execution == Enums.Enums.Execution.Serial then '' else 'Parallel'}`

	-- Fire when any Attribute Changes on the ActiveTargets:
	self._Trove[ConnectFunctionName](self._Trove, self._ZoneFolder.ActiveTargets.AttributeChanged, function(Target: TargetHandler.TargetTypes)
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
		-- Call the UpdateTrigger Method to Update Specific Things related to the Trigger State:
		self:UpdateTargetHandler(Target, self._ActiveTargets[Target])
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
		if State == 'Visible' then self:ToggleVisibility(self._States[State]) end
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
		if Setting == 'DetectionCoverage' or Setting == 'DetectionMode' or Setting == 'DetectionMethod'  then
			self:UpdateDetection(self._Settings.DetectionCoverage, self._Settings.DetectionMode, self._Settings.DetectionMethod)
		end
		-- If the Setting is the Simulation, then call the Method for it:
		if Setting == 'Simulation' then self:UpdateSimulation(self._Settings[Setting]) end
		-- If the Setting is the Rate, then call the Method for it:
		if Setting == 'Rate'       then self:UpdateRate(self._Settings[Setting])       end
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
				print('Backup, ZoneEngine: Folder Ancestry Changed') self:Destroy()
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
function ZoneEngineModule.SetUpdates(self: ZoneEngine)
	--=======================================================================================================>

	-- Update the Rate Counter with the Setting:
	self:UpdateRate(self._Settings.Rate)
	-- Update the Detection with the Setting:
	self:UpdateDetection(self._Settings.DetectionCoverage, self._Settings.DetectionMode, self._Settings.DetectionMethod)
	-- Update the Simulation Events with the Setting:
	self:UpdateSimulation(self._Settings.Simulation)

	-- Update the Visiblity with the State:
	self:ToggleVisibility(self._States.Visible)

	-- Loop through the ActiveTargets and Create a TargetHandler for each one accordingly:
	for Target, State: boolean in pairs(self._ActiveTargets) do self:UpdateTargetHandler(Target, State) end

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ ZONE UPDATE METHODS: ]


-- @Public
-- Updates a target handler for a given target type in ZoneEngine.
-- If `State` is true, it creates a new TargetHandler object; if false, it removes the existing one.
-- Ensures only one handler exists per target type in `_TargetHandlers`.
function ZoneEngineModule.UpdateTargetHandler(self: ZoneEngine, Target: TargetHandler.TargetTypes, State: boolean)
	--=======================================================================================================>
	-- If the State is true, then Create an Object, else Destroy it:
	if State == true then
		--===============================================================================================>
		-- If a TargetHandler Object for this Target exists already, Call the same Function but with State as False to Destroy it,
		-- Then continue to make a new Object:
		if self._TargetHandlers[Target] then self:UpdateTargetHandler(Target, false) end

		-- Construct a new Handler Object with the Trove and Set it in the Table:
		self._TargetHandlers[Target] = self._Trove:Construct(
			-- Index the Target Specific Table with the Target Name to gets its New Method:
			TargetHandler[Target], 
			-- Pass in the DetectionCoverage Number:
			self._Settings.DetectionCoverage,
			-- Pass in the DetectionMode Number:
			self._Settings.DetectionMode,
			-- Pass in a Boolean on whether the Execution is Serial or not:
			self._Settings.Execution == Enums.Enums.Execution.Serial
		)
		--===============================================================================================>
	else
		--===============================================================================================>
		-- If a TargetHandler Object exists, then Remove/Destroy it in the Trove and Set its Table value to nil:
		if self._TargetHandlers[Target] then self._Trove:Remove(self._TargetHandlers[Target]); self._TargetHandlers[Target] = nil end
		--===============================================================================================>
	end
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ SETTING UPDATE METHODS: ]


-- Function that is called when the Detection Setting is updated:
function ZoneEngineModule.UpdateDetection(self: ZoneEngine, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?)
	--=======================================================================================================>	
	for Target, Handler in pairs(self._TargetHandlers) do Handler:SetDetection(DetectionCoverage, DetectionMode, DetectionMethod) end
	--=======================================================================================================>
end

--- Function that is called when the Simulation Setting is updated:
function ZoneEngineModule.UpdateSimulation(self: ZoneEngine, Simulation: number)
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
function ZoneEngineModule.UpdateRate(self: ZoneEngine, Rate: number)
	--=======================================================================================================>
	self._Counters.ZoneStep.CounterMax, self._Counters.ZoneStep.Counter = Enums.Enums.Rate:GetProperty(Rate) :: number, 0
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ ZONE COMPUTATION METHODS: ]


-- Method called when a ZonePart tag is added or removed:
@native
function ZoneEngineModule.DetectTarget(self: ZoneEngine, Target: ZoneTargets)
	--=======================================================================================================>

	-- Begin Profiling:
	debug.profilebegin(`DetectTarget: {Target}`)

	if Target == 'Players' and self._TargetHandlers.Players then 
		--=============================================================================================>

		if self._BoundsHandlers.PerPart then


			if self._Settings.DetectionMethod == Enums.Enums.DetectionMethod.Complex then
				--=============================================================================>
				
				-- Loop through the ZoneParts that make up the Zone:
				for ZonePart, Details in self._BoundsHandlers.PerPart:GetZoneParts() do
					--===============================================================================>
					-- Get the Results of the Inidividual Part of the Zone:
					local ZonePartResults = WorldModel:GetPartsInPart(
						Details.Part, self._OverlapParamaters.PartsIncludeList
					)
					--===============================================================================>
					-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
					-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
					for Index: number, Result: Instance in ipairs(ZonePartResults) do
						-- Check to see if the Result is already added, continue if so:
						if self._TargetHandlers.Players.CurrentParts[Result :: BasePart] then continue end
						-- Insert Result to Results Table:
						self._TargetHandlers.Players.CurrentParts[Result :: BasePart] = true
					end
					--===============================================================================>
				end

				-- Loop through the CurrentPartsInZone:
				for Name: string, Tracker in self._TargetHandlers.Players.Trackers do
					--===============================================================================>
					-- Get the Boolean as to where this ItemTracker is currently:
					local PlayerInZonePrevious = Tracker.InZone
					-- If the Player is in the Zone:
					local PlayerInZoneCurrent = Tracker:IsInsideZoneParts(
						self._BoundsHandlers.PerPart:GetZonePieces(), Tracker:GetTargetPartsFromHitParts(self._TargetHandlers.Players.CurrentParts)
					)
					-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
					if PlayerInZoneCurrent then
						-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
						if PlayerInZonePrevious == false then
							table.insert(self._TargetHandlers.Players.Entered, self._TargetHandlers.Players:GetPlayer(Name))
						end
					else
						-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
						if PlayerInZonePrevious == true  then
							table.insert(self._TargetHandlers.Players.Exited,  self._TargetHandlers.Players:GetPlayer(Name))
						end
					end

					-- Set the Current Bool of the InZone Variable:
					Tracker.InZone = PlayerInZoneCurrent

					--===============================================================================>
				end

				table.clear(self._TargetHandlers.Players.CurrentParts)
				--=============================================================================>
			elseif self._Settings.DetectionMethod == Enums.Enums.DetectionMethod.Simple then
				--=============================================================================>
				
				for Key, Details in self._BoundsHandlers.PerPart:GetZonePieces() do
					--===============================================================================>

					-- Get the Results of the Inidividual Part of the Zone:
					local ZonePartResults = WorldModel:GetPartBoundsInBox(
						Details.CFrame or Details.Part.CFrame, Details.Size, self._OverlapParamaters.PartsIncludeList
					)

					-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
					-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
					for Index: number, Result: Instance in ipairs(ZonePartResults) do
						-- Check to see if the Result is already added, continue if so:
						if self._TargetHandlers.Players.CurrentParts[Result :: BasePart] then continue end
						-- Insert Result to Results Table:
						self._TargetHandlers.Players.CurrentParts[Result :: BasePart] = true
					end

					--===============================================================================>
				end

				-- Loop through the CurrentPartsInZone:
				for Name: string, Tracker in self._TargetHandlers.Players.Trackers do
					--===============================================================================>
					-- Get the Boolean as to where this ItemTracker is currently:
					local PlayerInZonePrevious = Tracker.InZone
					-- If the Player is in the Zone:
					local PlayerInZoneCurrent = Tracker:IsInsideZoneParts(
						self._BoundsHandlers.PerPart:GetZonePieces(), Tracker:GetTargetPartsFromHitParts(self._TargetHandlers.Players.CurrentParts)
					)
					-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
					if PlayerInZoneCurrent then
						-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
						if PlayerInZonePrevious == false then
							table.insert(self._TargetHandlers.Players.Entered, self._TargetHandlers.Players:GetPlayer(Name))
						end
					else
						-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
						if PlayerInZonePrevious == true  then
							table.insert(self._TargetHandlers.Players.Exited,  self._TargetHandlers.Players:GetPlayer(Name))
						end
					end
					-- Set the Current Bool of the InZone Variable:
					Tracker.InZone = PlayerInZoneCurrent

					--===============================================================================>
				end

				table.clear(self._TargetHandlers.Players.CurrentParts)

				--=============================================================================>

			elseif self._Settings.DetectionMethod == Enums.Enums.DetectionMethod.Efficient then
				--=============================================================================>

				-- Loop through the CurrentPartsInZone:
				for Name: string, Tracker in self._TargetHandlers.Players.Trackers do
					--===============================================================================>

					-- Get the Boolean as to where this ItemTracker is currently:
					local PlayerInZonePrevious = Tracker.InZone
					-- If the Player is in the Zone:
					local PlayerInZoneCurrent = Tracker:IsInsideZoneParts(self._BoundsHandlers.PerPart:GetZonePieces())
					
					-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
					if PlayerInZoneCurrent then
						-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
						if PlayerInZonePrevious == false then
							table.insert(self._TargetHandlers.Players.Entered, self._TargetHandlers.Players:GetPlayer(Name))
						end
					else
						-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
						if PlayerInZonePrevious == true  then
							table.insert(self._TargetHandlers.Players.Exited,  self._TargetHandlers.Players:GetPlayer(Name))
						end
					end
					-- Set the Current Bool of the InZone Variable:
					Tracker.InZone = PlayerInZoneCurrent

					--===============================================================================>
				end

				--=============================================================================>
			end

		else


			if self._Settings.DetectionMethod == Enums.Enums.DetectionMethod.Complex then
				--=============================================================================>

				local BoxParts

				--=============================================================================>

				if self._BoundsHandlers.BoxExact then
					--=============================================================================>
					BoxParts = self._BoundsHandlers.BoxExact.ZoneBoxData.Parts
					--=============================================================================>
				elseif self._BoundsHandlers.BoxVoxel then
					--=============================================================================>
					BoxParts = self._BoundsHandlers.BoxVoxel.ZoneBoxData.Parts
					--=============================================================================>
				end

				--=============================================================================>

				-- Loop through the CurrentPartsInZone:
				for Part: BasePart, Details in BoxParts do
					--===============================================================================>

					-- Get the Results of the Inidividual Part of the Zone:
					local ZonePartResults = WorldModel:GetPartsInPart(
						Details.Part, self._OverlapParamaters.PartsIncludeList
					)
					--===============================================================================>
					-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
					-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
					for Index: number, Result: Instance in ipairs(ZonePartResults) do
						-- Check to see if the Result is already added, continue if so:
						if self._TargetHandlers.Players.CurrentParts[Result :: BasePart] then continue end
						-- Insert Result to Results Table:
						self._TargetHandlers.Players.CurrentParts[Result :: BasePart] = true
					end
					--===============================================================================>
				end

				-- Loop through the CurrentPartsInZone:
				for Name: string, Tracker in self._TargetHandlers.Players.Trackers do
					--===============================================================================>
					-- Get the Boolean as to where this ItemTracker is currently:
					local PlayerInZonePrevious = Tracker.InZone
					-- If the Player is in the Zone:
					local PlayerInZoneCurrent = Tracker:IsInsideZoneParts(
						BoxParts, Tracker:GetTargetPartsFromHitParts(self._TargetHandlers.Players.CurrentParts)
					)

					-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
					if PlayerInZoneCurrent then
						-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
						if PlayerInZonePrevious == false then
							table.insert(self._TargetHandlers.Players.Entered, self._TargetHandlers.Players:GetPlayer(Name))
						end
					else
						-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
						if PlayerInZonePrevious == true  then
							table.insert(self._TargetHandlers.Players.Exited,  self._TargetHandlers.Players:GetPlayer(Name))
						end
					end

					-- Set the Current Bool of the InZone Variable:
					Tracker.InZone = PlayerInZoneCurrent

					--===============================================================================>
				end

				-- Clear the table of CurrentParts:
				table.clear(self._TargetHandlers.Players.CurrentParts)

				--=============================================================================>
			elseif self._Settings.DetectionMethod == Enums.Enums.DetectionMethod.Simple then
				--=============================================================================>

				local BoxCFrame: CFrame, BoxSize: Vector3;

				--=============================================================================>

				if self._BoundsHandlers.BoxExact then
					--=============================================================================>
					BoxCFrame, BoxSize = self._BoundsHandlers.BoxExact.CFrame, self._BoundsHandlers.BoxExact.Size
					--=============================================================================>
				elseif self._BoundsHandlers.BoxVoxel then
					--=============================================================================>
					BoxCFrame, BoxSize = self._BoundsHandlers.BoxVoxel.CFrame, self._BoundsHandlers.BoxVoxel.Size
					--=============================================================================>
				end

				--=============================================================================>

				-- Get the Results of the Inidividual Part of the Zone:
				local ZonePartResults = WorldModel:GetPartBoundsInBox(
					BoxCFrame, BoxSize, self._OverlapParamaters.PartsIncludeList
				)
				--=============================================================================>
				-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
				-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
				for Index: number, Result: Instance in ipairs(ZonePartResults) do
					-- Check to see if the Result is already added, continue if so:
					if self._TargetHandlers.Players.CurrentParts[Result :: BasePart] then continue end
					-- Insert Result to Results Table:
					self._TargetHandlers.Players.CurrentParts[Result :: BasePart] = true
				end

				-- Loop through the CurrentPartsInZone:
				for Name: string, Tracker in self._TargetHandlers.Players.Trackers do
					--===============================================================================>

					-- Get the Boolean as to where this ItemTracker is currently:
					local PlayerInZonePrevious = Tracker.InZone
					-- If the Player is in the Zone:
					local PlayerInZoneCurrent = Tracker:IsInsideBox(
						BoxCFrame, BoxSize/2, Tracker:GetTargetPartsFromHitParts(self._TargetHandlers.Players.CurrentParts)
					)

					-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
					if PlayerInZoneCurrent then
						-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
						if PlayerInZonePrevious == false then 
							table.insert(self._TargetHandlers.Players.Entered, self._TargetHandlers.Players:GetPlayer(Name))
						end
					else
						-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
						if PlayerInZonePrevious == true  then
							table.insert(self._TargetHandlers.Players.Exited,  self._TargetHandlers.Players:GetPlayer(Name))
						end
					end

					-- Set the Current Bool of the InZone Variable:
					Tracker.InZone = PlayerInZoneCurrent

					--===============================================================================>
				end

				-- Clear the table of CurrentParts:
				table.clear(self._TargetHandlers.Players.CurrentParts)

			elseif self._Settings.DetectionMethod == Enums.Enums.DetectionMethod.Efficient then
				--=============================================================================>

				local BoxCFrame: CFrame, BoxHalfSize: Vector3;

				--=============================================================================>

				if self._BoundsHandlers.BoxExact then
					--=============================================================================>
					BoxCFrame, BoxHalfSize = self._BoundsHandlers.BoxExact.CFrame, self._BoundsHandlers.BoxExact.HalfSize
					--=============================================================================>
				elseif self._BoundsHandlers.BoxVoxel then
					--=============================================================================>
					BoxCFrame, BoxHalfSize = self._BoundsHandlers.BoxVoxel.CFrame, self._BoundsHandlers.BoxVoxel.HalfSize
					--=============================================================================>
				end

				--=============================================================================>

				-- Loop through the CurrentPartsInZone:
				for Name: string, Tracker in self._TargetHandlers.Players.Trackers do
					--===============================================================================>
					-- Get the Boolean as to where this ItemTracker is currently:
					local PlayerInZonePrevious = Tracker.InZone
					-- If the Player is in the Zone:
					local PlayerInZoneCurrent = false --Tracker:IsInsideBox(BoxCFrame, BoxHalfSize)

					-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
					if PlayerInZoneCurrent then
						-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
						if PlayerInZonePrevious == false then 
							table.insert(self._TargetHandlers.Players.Entered, self._TargetHandlers.Players:GetPlayer(Name))
						end
					else
						-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
						if PlayerInZonePrevious == true  then
							table.insert(self._TargetHandlers.Players.Exited,  self._TargetHandlers.Players:GetPlayer(Name))
						end
					end

					-- Set the Current Bool of the InZone Variable:
					Tracker.InZone = PlayerInZoneCurrent

					--===============================================================================>
				end

				--=============================================================================>
			end


		end

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

		--=============================================================================================>
	end

	if Target == '_Parts' then
		--=============================================================================================>

		-- Create Local Arrays for Entered and Exited Objects:
		local EnteredParts: {BasePart}, ExitedParts: {BasePart} = {}, {}

		--=============================================================================================>

		-- Loop through the CurrentPartsInZone:
		for Part: BasePart, State: boolean in self._PartData.CurrentPartsInZone do
			--===============================================================================>
			-- If the CurrentPart was NOT in the Zone Previously:
			-- Then Add the Part to the Array of Parts that have just now ENTERED:
			if self._PartData.PreviousPartsInZone[Part] == nil then 
				table.insert(EnteredParts, Part)	
			end
			--===============================================================================>
		end

		-- Loop through the CurrentPartsInZone:
		for Part: BasePart, State: boolean in self._PartData.PreviousPartsInZone do
			--===============================================================================>
			-- If the PreviousPart is now NOT in the Current Zone Parts:
			-- Then Add the Part to the Array of Parts that have just now EXITED:
			if self._PartData.CurrentPartsInZone[Part] == nil then 
				table.insert(ExitedParts, Part)
			end
			--===============================================================================>
		end

		--=============================================================================================>

		-- Loop through the EnteredParts:
		for Index: number, Part: BasePart in ipairs(EnteredParts) do
			--===============================================================================>		
			self._Events.ZoneSignals:Fire(ZoneConstants.ZoneSignalHash.Send['PartEntered'], Part)
			--===============================================================================>
		end
		-- Loop through the ExitedParts:
		for Index: number, Part: BasePart in ipairs(ExitedParts) do
			--===============================================================================>
			self._Events.ZoneSignals:Fire(ZoneConstants.ZoneSignalHash.Send['PartExited'], Part)
			--===============================================================================>
		end

		--=============================================================================================>
	end

	-- End Profiling:
	debug.profileend()

	--=======================================================================================================>
end

-- Method called when the Visiblity State Changes:
function ZoneEngineModule.ToggleVisibility(self: ZoneEngine, State: boolean)
	--=======================================================================================================>
	-- Call function on BoundsHandler:
	self._BoundsHandler:ToggleVisibility(State)
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
			self._BoundsHandler:RemoveZonePart(ZonePart)
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
			self._BoundsHandler:AddZonePart(ZonePart)
			--================================================================>
		else return end
		--===============================================================================================>
	end

	--=======================================================================================================>

	-- Determine whether the ZoneParts are all Blocks:
	self._Properties.AllZonePartsAreBlocks = ZoneUtilities:ArePartsAllBlocks(self._Instances.ZoneParts)

	---- Set the boolean to true to Update the Attribute Properties in Serial:
	--self._Updates.Parts = true

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
@native
function ZoneEngineModule.OnSimulation(self: ZoneEngine, Type: 'Sync'|'Desync', DeltaTime: number)
	--=======================================================================================================>

	if Type == 'Sync' then 
		--==============================================================================================>




		--==============================================================================================>
	else

		--==============================================================================================>

		if self._States.Paused == true then return end

		-- If the Zone is not Active, return and dont do any Checks:
		if self._States.Active == false then return end

		--==============================================================================================>

		-- If the Counter is not at max, return to allow for varied update checking/polling:
		-- Checks every number interval as set in the Counters Table. 
		if not Utility:RateLimiter(self._Counters.ZoneStep, DeltaTime) then return end

		self:Step(DeltaTime)

		--==============================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Step Function for Zone Calculations:
@native
function ZoneEngineModule.Step(self: ZoneEngine, DeltaTime: number)
	--=======================================================================================================>

	if self._States.Paused == true then return end

	-- If the Zone is not Active, return and dont do any Checks:
	if self._States.Active == false then return end

	--==============================================================================================>

	-- Loop through the ActiveTargets Dictionary, checking the State of whether its Active:
	-- If it is Active, Call the CheckZone Method for that Trigger, followed by calling the CheckTrigger Method:
	for Target, State in self._ActiveTargets do if State == true then self:DetectTarget(Target :: ZoneTargets) end end

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
	if self._Properties[Index] then return self._Properties[Index] end
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