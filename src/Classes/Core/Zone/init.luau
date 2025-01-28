--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Define Module table
local ZoneModule = {}

--===========================================================================================================================>
--[ SERVICES: ]


-- Get the needed Services for the following Code:
local CollectionService = game:GetService('CollectionService')

--===========================================================================================================================>

-- Reference the Top Level Module so that we can easily Index our Modules
-- Use direct parenting instead of Ancestor in case someone changes the Module's name:
local ZonerModule = script.Parent.Parent.Parent

-- Require the GoodSignal Utility Module for Creating Custom Signals:
local GoodSignal = require(ZonerModule.Classes.Utilities.GoodSignal);
-- Require the Enum2 Module for Custom Enums:
local Enums      = require(ZonerModule.Classes.Utilities.Enums);
-- Require the Trove Module for Cleanup:
local Trove      = require(ZonerModule.Classes.Utilities.Trove);
-- Require the Utility Module for Utility:
local Utility    = require(ZonerModule.Classes.Utilities.Utility);
-- Require the WorldModel Module for setting up the WorldModel:
local WorldModel = require(ZonerModule.Classes.Core.WorldModel);
-- Require the Trove Module for Cleanup:
local ZonerConstants = require(ZonerModule.Children.Constants);
local Regions      = require(ZonerModule.Classes.Utilities.Regions);

-- Require the Trove Module for Cleanup:
local ZoneConstants = require(script.Children.Constants);

-- Require the Trove Module for Cleanup:
local ZoneUtilities = require(script.Children.ZoneUtilities);
-- Require the Trove Module for Cleanup:




--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types)


export type ZoneMetaData = TypeDefinitions.ZoneMetaData
export type Zone         = TypeDefinitions.Zone

export type ZoneContainer = TypeDefinitions.ZoneContainer
export type ZoneSettings  = TypeDefinitions.ZoneSettings
export type ZonerFolder   = TypeDefinitions.ZonerFolder
export type ZonerHolder   = TypeDefinitions.ZonerHolder
export type ZonerActor    = TypeDefinitions.ZonerActor
export type ZonerGroup    = TypeDefinitions.ZonerGroup
export type RunScope      = 'Server'|'Client'

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- @Private
-- Constructor Function for this individual object:
function ZoneModule.New(Container: ZoneContainer, Settings: ZoneSettings, Holder: ZonerHolder, RunScope: RunScope, Id: string): Zone
	--=======================================================================================================>

	-- Set a Memory Category for this Zoner:
	debug.setmemorycategory('Zoner: Zone')

	--=======================================================================================================>

	-- Define Data
	local ZoneData: ZoneMetaData = {
		--====================================================>
		_Trove = Trove.New();
		--====================================================>
		_RunScope = RunScope;
		--====================================================>
		-- Formerly "ZoneId". Same Purpose:
		_Identifier = Id;
		--====================================================>
		-- Reference to the Original Zone Container:
		_Container = Container;
		_ContainerType = ZoneUtilities:GetZoneContainerType(Container);
		--====================================================>
		_ZonerHolder     = Holder;
		_ZonerHolderType = if Holder:IsA('Actor') then 'A' else 'G';
		--====================================================>
		_Classes = {};
		--====================================================>
		_Tags = {
			ZonePart = `{Id}:ZonePart:{RunScope}`;
			Holder   = `{Id}:Holder:{RunScope}`;
		};
		_States = {
			Active    = false;
			Destroyed = false;
			Relocated = false;
			Paused    = false;
			Visible   = false;
		};
		
		_Instances = {
			ZoneParts  = {};
			Holders    = {};
		} :: any;

		_Counters = {
			ActivityCheck = {Counter = 0; CounterMax = 25.0};
		};

		_ConnectionStats = {
			PlayerConnections      = 0;
			ItemConnections        = 0;
			LocalPlayerConnections = 0;
			PartConnections        = 0;
		};

		_ActiveTargets = {
			LocalPlayer = false;
			Player      = false;
			Item        = false;
			Part        = false;
		};

		_Settings = table.clone(Settings) :: any;
		
		_Signals = {} :: any;
		--====================================================>
	} :: ZoneMetaData

	--=======================================================================================================>

	ZoneData._EventTrove  = ZoneData._Trove:Extend()
	ZoneData._HolderTrove = ZoneData._Trove:Extend()
	ZoneData._PartTrove   = ZoneData._Trove:Extend()
	
	-- Set the default Enter and Exit Detection Settings:
	ZoneData._Settings.ExitDetectionMode      = ZoneData._Settings.DetectionMode
	ZoneData._Settings.ExitDetectionCoverage  = ZoneData._Settings.DetectionCoverage
	ZoneData._Settings.EnterDetectionMode     = ZoneData._Settings.DetectionMode
	ZoneData._Settings.EnterDetectionCoverage = ZoneData._Settings.DetectionCoverage

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(ZoneData, ZoneModule)

	-- Start the Inventory:
	ZoneData:_Initialize()
	
	-- Check the Activity Initially:
	ZoneData:_CheckActivity()
	
	--=======================================================================================================>

	-- Return the MetaTable Data
	return table.freeze(ZoneData) :: any

	--=======================================================================================================>
end

-- @Public
-- Destroyer Function which clears the entirity of the Data for the Object:
function ZoneModule.Destroy(self: Zone)
	--=======================================================================================================>
	-- If already Destroyed, return:
	if self._States.Destroyed then return end
	-- Set Zone State to Destroyed meaning the Method has been called:
	self._States.Destroyed = true;
	--=======================================================================================================>

	-- Set an Attribute on the ZoneFolder: "Destroying" to true to let the ZoneEngine know to ignore the AncestryChanged:
	self._ZoneFolder:SetAttribute('Destroying', true)

	-- If the ZonerHolder is still in Game and is an Actor, Send the Destroy Method:
	if self._ZonerHolder:IsDescendantOf(game) and self._ZonerHolderType == 'A' then
		-- Send a Message to the ZoneEngineActor to Destroy itself:
		self._ZonerActor:SendMessage('Destroy', self._Identifier)
	end

	--=======================================================================================================>

	-- Clean with Trove
	if self._Trove then self._Trove:Destroy() end
	
	-- If there is a ZoneEngine in this Object, then set it to nil:
	if self._Classes.ZoneEngine then self._Classes.ZoneEngine = nil :: any end
	
	-- If ZoneFolder is still in game, Destroy the ZoneFolder:
	if self._ZoneFolder:IsDescendantOf(game) then self._ZoneFolder:Destroy() end
	-- Set the Attribute on the Folder to nil. Using the Identifier string as the name, this will clear the attribute from the Folder.
	-- Thus triggering a Cleaning and removal of the Zone from the Zoner Object:
	if self._ZonerHolder:IsDescendantOf(game) and self._ZonerHolder.Ids:GetAttribute(self._Identifier) == true then
		self._ZonerHolder.Ids:SetAttribute(self._Identifier, false) 
	end
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._Initialize(self: Zone)
	for Index: number, Function: string in ipairs({'_SetData', '_SetInstances', '_SetEvents', '_SetCore'}) do self[Function](self) end
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._SetData(self: Zone)
	--=======================================================================================================>
	
	-- Grab the ZoneParts and Holders Array from the current Container:
	local ZoneParts: {BasePart}, Holders: {Instance} = ZoneUtilities:GetZonePartsFromContainer(self._Container)
	
	--=======================================================================================================>

	-- Loop through the ZoneParts to add tags:
	for Index: number, Holder: Instance in ipairs(Holders) do
		-- If the Part already has a Tag, then continue:
		-- Add the Holder tag to the Holder:
		if Holder:HasTag(self._Tags.Holder) then continue else 
			Holder:AddTag(self._Tags.Holder)
			self:_OnHolderInstanceUpdate('Add', Holder)
		end
	end
	
	for Index: number, Part: BasePart in ipairs(ZoneParts) do
		-- If the Part already has a Tag, then continue:
		-- Add the ZonePart tag to the ZonePart:
		if Part:HasTag(self._Tags.ZonePart) then continue else 
			Part:AddTag(self._Tags.ZonePart) 
			self:_OnZonePartUpdate('Add', Part)
		end
	end

	--=======================================================================================================>
	
	-- Determine Automatic Settings:
	-- [TO DO] Maybe move some Logic to ZoneUtilities or another module:
	do
		--=============================================================================>

		-- If the Bounds Setting is Automatic, Determine whether to Run PerPart or BoxExact:
		if self._Settings.Bounds == Enums.Enums.Bounds.Automatic then
			
			if self._ZoneBoxes then
				if #self._ZoneBoxes > 1 then
					self._Settings.Bounds = Enums.Enums.Bounds.PerPart
				else
					self._Settings.Bounds = Enums.Enums.Bounds.BoxExact
				end
			else
				if ZoneUtilities:ArePartsAllBlocks(self._Instances.ZoneParts) then 

					-- Define a Variable:
					local ZonePartsAreRotated: boolean = false;
					-- Loop through the ZoneParts to add tags:
					for Index: number, Part: BasePart in ipairs(self._Instances.ZoneParts) do
						if not Part.CFrame.Rotation:FuzzyEq(CFrame.new(), 0.00001) then ZonePartsAreRotated = true; break; end
					end

					if ZonePartsAreRotated or #self._Instances.ZoneParts > 1 then
						self._Settings.Bounds = Enums.Enums.Bounds.PerPart
					else
						self._Settings.Bounds = Enums.Enums.Bounds.BoxExact
					end
				else
					self._Settings.Bounds = Enums.Enums.Bounds.PerPart
				end
			end
			
		end
		
		-- If the DetectionMethod Setting is Automatic, Determine whether to Run Efficient, Simple or Complex:
		if self._Settings.DetectionMethod == Enums.Enums.DetectionMethod.Automatic then
			
			if self._Settings.Bounds == Enums.Enums.Bounds.BoxExact or self._Settings.Bounds == Enums.Enums.Bounds.BoxVoxel or self._ZoneBoxes then
				self._Settings.DetectionMethod = Enums.Enums.DetectionMethod.Efficient		
			else
				-- Define ZonePart Type Grouping Booleans:
				local AllSpheresAndBlocks: boolean = true
				local AllComplex:          boolean = true
				local AllSpheres:          boolean = true
				local AllBlocks:           boolean = true

				-- Loop through all the ZoneParts:
				for Index: number, ZonePart in ipairs(self._Instances.ZoneParts) do
					-- Grab the PartProperties of the ZonePart:
					local ZonePartType = Regions:GetPartType(ZonePart)
					-- Determine the Makeup of all the ZoneParts:
					if ZonePartType == 'Block' then
						AllSpheres, AllComplex = false, false
					elseif ZonePartType == 'Sphere' then
						AllBlocks, AllComplex  = false, false
					elseif ZonePartType == 'Complex' then
						AllBlocks, AllSpheres, AllSpheresAndBlocks = false, false, false
					end
				end

				-- If AllBlocks, AllSpheres or a Mix of Both, then Run Efficient.
				-- If AllComplex, then Run Complex.
				-- If its a mixed back of Spheres, Complex and Blocks, then Keep it Simple:
				if AllBlocks or AllSpheres or AllSpheresAndBlocks then
					self._Settings.DetectionMethod = Enums.Enums.DetectionMethod.Efficient
				else
					self._Settings.DetectionMethod = Enums.Enums.DetectionMethod.Complex
				end
			end
		
		end
		
		-- If our DetectionMethod is Complex, and our ContainerType is a TableOfBoxes, downgrade the DetectionMethod cause TableOfBoxes are incompatabile:
		if self._Settings.DetectionMethod == Enums.Enums.DetectionMethod.Complex and self._ContainerType == 'TableOBox' then
			self._Settings.DetectionMethod = Enums.Enums.DetectionMethod.Simple
		end
		
		--=============================================================================>
	end
	
	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._SetInstances(self: Zone)
	--=======================================================================================================>

	-- Create the Zone Core Actor and Script:
	do 
		--=============================================================================>
		-- Clone the ZoneEngine Actor Template:
		self._Instances.ZoneFolder = Instance.new('Folder') :: ZonerFolder
		self._Instances.ZoneFolder.Name = self._Identifier
		-- Parent the Actor to the CelestialBodies Folder:
		self._ZoneFolder.Parent = self._ZonerHolder.Zones
		--=============================================================================>
	end

	-- Create Zone Sub Folders:
	do
		--=============================================================================>
		local EventsFolder: Folder = Instance.new('Folder')
		EventsFolder.Name = 'Events'
		EventsFolder.Parent = self._ZoneFolder

		local PropertiesFolder: Configuration = Instance.new('Configuration')
		PropertiesFolder.Name = 'Properties'
		PropertiesFolder.Parent = self._ZoneFolder

		local StatesFolder: Configuration = Instance.new('Configuration')
		StatesFolder.Name = 'States'
		StatesFolder.Parent = self._ZoneFolder

		local TriggersFolder: Configuration = Instance.new('Configuration')
		TriggersFolder.Name = 'ActiveTargets'
		TriggersFolder.Parent = self._ZoneFolder

		local SettingsFolder: Configuration = Instance.new('Configuration')
		SettingsFolder.Name = 'Settings'
		SettingsFolder.Parent = self._ZoneFolder

		-- Create Bindable Events for Communication to the Core:
		for Index: number, Name: string in ipairs({'HoldersUpdate', 'ZoneSignals'}) do
			--=======================================================================>
			local Event: BindableEvent = Instance.new('BindableEvent')
			Event.Name = Name
			Event.Parent = EventsFolder
			--=======================================================================>
		end

		--=============================================================================>
	end
	
	-- Update Zone Folder's with default Attributes:
	do
		--=============================================================================>
		-- Loop through the States Table to Update the Attributes:
		for Key: string, Status: boolean in pairs(self._States) do
			self._ZoneFolder.States:SetAttribute(Key, Status)
		end

		-- Loop through the ActiveTargets Table to Update the Attributes:
		for Key: string, Status: boolean in pairs(self._ActiveTargets) do
			self._ZoneFolder.ActiveTargets:SetAttribute(Key, Status)
		end

		-- Loop through the Settings Table to Update the Attributes:
		for Key: string, Status: boolean in pairs(self._Settings) do
			self._ZoneFolder.Settings:SetAttribute(Key, Status)
		end
		--=============================================================================>
	end

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._SetEvents(self: Zone)
	--=======================================================================================================>
	-- Connect to the AncestryChanged event of the ZoneFolder:
	-- We then check if the ZoneFolder is still a decendent of the WorldModel, meaning it hasnt been destroyed.
	-- We do this to clear the Data in case the ZoneFolder is Destroyed:
	self._EventTrove:Connect(self._ZoneFolder.AncestryChanged, function()
		--====================================================================================>
		-- If the Destroying Attribute is true on the ZoneFolder, then ignore the Ancestry Changed:
		if self._ZoneFolder:GetAttribute('Destroying') == true then return end
		if self._ZoneFolder.Parent == nil or self._ZoneFolder:IsDescendantOf(game) == false then self:Destroy() end
		--====================================================================================>
	end)

	--=======================================================================================================>

	self._EventTrove:Connect(self._ZoneFolder.Events.ZoneSignals.Event, function(Purpose: string, ...)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Reference the Signal Via the Purpose Hash and Fire:
		self._Signals[ZoneConstants.ZoneSignalHash.Receive[Purpose]]:Fire(...)
		--================================================================================================>
	end)
	
	--=======================================================================================================>
	
	-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
	if self._ContainerType == 'TableOBox' then return end

	-- Connect to the ZonePart Tag Added Signal:
	-- Fires when a Part with the Zone Tag is added back to the Workspace:
	-- We will use this to reduce the Zone Based on Streaming:
	self._Trove:Connect(CollectionService:GetInstanceAddedSignal(self._Tags.ZonePart), function(ZonePart: BasePart)
		-- Call the ZonePartUpdate Function:
		self:_OnZonePartUpdate('Add', ZonePart)
		-- If the Zone is in Serial with a local ZoneEngine call ZonePartUpdate Function from here instead of the Engine:
		if self._Classes.ZoneEngine then self._Classes.ZoneEngine:OnZonePartUpdate('Add', ZonePart) end
	end)

	-- Connect to the ZonePart Tag Removed Signal:
	-- Fires when a Part with the Zone Tag is removed from the Workspace:
	-- We will use this to restore the Zone Based on Streaming:
	self._Trove:Connect(CollectionService:GetInstanceRemovedSignal(self._Tags.ZonePart), function(ZonePart: BasePart)
		-- Call the ZonePartUpdate Function:
		self:_OnZonePartUpdate('Remove', ZonePart)
		-- If the Zone is in Serial with a local ZoneEngine call ZonePartUpdate Function from here instead of the Engine:
		if self._Classes.ZoneEngine then self._Classes.ZoneEngine:OnZonePartUpdate('Remove', ZonePart) end
	end)
	
	-- If the Zone has Holder Instances at all Initially, then we can listen for them:
	if #self._Instances.Holders > 0 then
		-- Connect to the Holder Tag Added Signal:
		self._Trove:Connect(CollectionService:GetInstanceAddedSignal(self._Tags.Holder), function(Holder: Instance)
			-- Call the ZonePartUpdate Function:
			self:_OnHolderInstanceUpdate('Add', Holder)
			-- If the Zone is in Serial with a local ZoneEngine call HolderInstanceUpdate Function from here instead of the Engine:
			if self._Classes.ZoneEngine then self._Classes.ZoneEngine:OnHolderInstanceUpdate('Add', Holder) end
		end)
		-- Connect to the Holder Tag Removed Signal:
		self._Trove:Connect(CollectionService:GetInstanceRemovedSignal(self._Tags.Holder), function(Holder: Instance)
			-- Call the ZonePartUpdate Function:
			self:_OnHolderInstanceUpdate('Remove', Holder)
			-- If the Zone is in Serial with a local ZoneEngine call HolderInstanceUpdate Function from here instead of the Engine:
			if self._Classes.ZoneEngine then self._Classes.ZoneEngine:OnHolderInstanceUpdate('Remove', Holder) end
		end)
	end

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._SetCore(self: Zone)
	--=======================================================================================================>
	-- Grab the ZoneParts and Holders Array from the current Container:
	self._Instances.ZoneParts, self._Instances.Holders = ZoneUtilities:GetZonePartsFromContainer(self._Container, self._ContainerType)

	-- If the ZonerHolder is an Actor, send the Construct Message,
	-- Else create the Engine in the Object:
	if self._ZonerHolderType == 'A' then
		--==========================================================================================>
		if self._ZonerActor:GetAttribute('Binded') ~= true then
			-- Wait a Frame to allow the Actor Message to Bind and Connect:
			self._Trove:TaskSpawn(function()
				-- Redundancy incase things are slow:
				repeat task.wait() until self._ZonerActor:GetAttribute('Binded') == true;
				-- Send a Message to the Actor to Construct the ZoneEngine Object on a new Thread:
				-- We send the ModuleScript Instance (Core Class) so that it can be required over there on another thread:
				self._ZonerActor:SendMessage('Construct', script.Classes.ZoneEngine, self._Identifier, self._ZoneFolder, self._Container, self._RunScope)
			end)
		else
			-- Send a Message to the Actor to Construct the ZoneEngine Object on a new Thread:
			-- We send the ModuleScript Instance (Core Class) so that it can be required over there on another thread:
			self._ZonerActor:SendMessage('Construct', script.Classes.ZoneEngine, self._Identifier, self._ZoneFolder, self._Container, self._RunScope)
		end
		--==========================================================================================>
	else
		--==========================================================================================>
		
		-- Require the ZoneEngine Module:
		local ZoneEngineModule = require(script.Classes.ZoneEngine)
		
		-- Construct a ZoneEngine Object and Add it to the Classes Trove:
		self._Classes.ZoneEngine = self._Trove:Add(
			ZoneEngineModule.New(self._Identifier, self._ZoneFolder, self._Container, self._RunScope)
		)

		--==========================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ PUBLIC METHODS: ]

-- @Public
-- Method that will Relocate the Zone to a WorldModel not in the Workspace:
function ZoneModule.Relocate(self: Zone): Zone
	--=======================================================================================================>
	-- If the Container Type is a Table of Part Boxes then return from here:
	if self._ContainerType == 'TableOBox' then warn(`Zone has no parts associated with it to relocate, cant relocate.`); return self end
	-- If we have already Relocated this Zone, return:
	if self._States.Relocated then warn(`Zone is already Relocated! Cant Relocate again, so stop calling this method..`); return self end
	--=======================================================================================================>
	-- Set the Relocated State to true:	
	self:_SetState('Relocated', true)
	--=======================================================================================================>
	-- Grab the Current Container:
	local RelocationContainer: any = self._Container :: any
	-- If the Container is a table, then make the Container into a Folder and all parts to it:
	if typeof(RelocationContainer) == "table" then
		-- Create a Relocation Container Folder:
		RelocationContainer = Instance.new("Folder")
		RelocationContainer.Name = `{self._Identifier}:RelocationContainer`
		-- Loop through all the ZoneParts and Parent them to the Relocation Container:
		for Index: number, ZonePart in ipairs(self._ZoneParts) do 
			ZonePart.Parent = RelocationContainer :: any 
		end
	else
		-- Update the Name of the Container to be Id Specific:
		if RelocationContainer.Name == 'ZoneContainer' then
			RelocationContainer.Name = `{self._Identifier}:RelocationContainer`
		end
	end
	--=======================================================================================================>
	-- Set the RelocationContainer Variable to to the new Folder and add it to the Trove:
	self._Instances.RelocationContainer = self._Trove:Add(RelocationContainer)
	-- Set its Parent to the WorldModel:
	RelocationContainer.Parent = WorldModel:GetWorldModel()
	--=======================================================================================================>
	-- Return the self Object. So that this can be directly called on a constructing Object if we wanted:
	return self
	--=======================================================================================================>
end

-- @Public
-- Method to Update/Set the Default Part/TrackedItem Detection of the Zone:
function ZoneModule.SetDetection(self: Zone, DetectionCoverage: Enums.DetectionCoverages | number, DetectionMode: Enums.DetectionModes | number)
	self:_SetSetting('DetectionCoverage', 'DetectionCoverage', DetectionCoverage)
	self:_SetSetting('DetectionMode', 'DetectionMode', DetectionMode)
end

-- @Public
-- Method to Update/Set the Default Rate of the Zone:
function ZoneModule.SetRate(self: Zone, Rate: Enums.Rates | number)
	self:_SetSetting('Rate', 'Rate', Rate)
end

-- @Public
-- Method to Update/Set the Default Simulation (RunService Event) of the Zone:
function ZoneModule.SetSimulation(self: Zone, Simulation: Enums.Simulations | number)
	--=======================================================================================================>
	-- Grab the Simulation Number Vlaue:
	local Simulation2: number | 'Failure' = Enums.Enums.Simulation:GetValue(Simulation)
	-- If Simulation is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if Simulation2 == 'Failure' then warn(ZonerConstants.Logs.Zone.SetSimulation1); return end
	--=======================================================================================================>
	-- Dont allow PreRender to be set on the Server:
	if Enums.Enums.Simulation:GetValue(Simulation2) == 'PreRender' and self._RunScope == 'Server' then
		-- Warn/Log to console the Error:
		warn(ZonerConstants.Logs.Zone.SetSimulation2)
	else
		-- Set the new Simulation in the Setting Table:
		self._Settings.Simulation = Simulation2 :: number
		-- If the Execution of the Zone is in Parallel, we will set the Attribute for Parallel Updating:
		if self._Settings.Execution == Enums.Enums.Execution.Parallel then
			-- Set the Attribute in a Deffered Function Synchronized in case this SetSetting function is called in Parallel by the User:
			self._Trove:TaskDefer(function() task.synchronize(); self._ZoneFolder.Settings:SetAttribute('Simulation', Simulation2) end)
		end
	end
	--=======================================================================================================>
end

-- @Public
-- Method to print out all the Setting Names:
function ZoneModule.LogSettings(self: Zone)
	--=======================================================================================================>

	local SettingLog: string = `{ZonerConstants.Logs.Zone[`LogSettingsPrefix`]}\n`

	for Key: string, Setting: any in pairs(self._Settings) do
		if Key == 'ManualStepping' then
			SettingLog = SettingLog..`{Key}: {Setting}\n`
		elseif string.match(Key, 'DetectionCoverage') then
			SettingLog = SettingLog..`{Key}: {Enums.Enums.DetectionCoverage:GetName(Setting)}\n`
		elseif string.match(Key, 'DetectionMode') then
			SettingLog = SettingLog..`{Key}: {Enums.Enums.DetectionMode:GetName(Setting)}\n`
		else
			SettingLog = SettingLog..`{Key}: {Enums.Enums[Key]:GetName(Setting)}\n`
		end
	end

	print(SettingLog)

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Method called on the PostSimulation (Heartbeat) RunService Event:
function ZoneModule.Step(self: Zone, DeltaTime: number) 
	--=======================================================================================================>
	-- If the Zoner Holder is not a Serial ZonerGroup then Error:
	if self._ZonerHolderType ~= 'G' then error(`Zone is not running in Serial, cant Step manually`); return end
	-- If the Zone Setting does not have ManualStepping as true, then an Internal Event is already Stepping, so return:
	if self._Settings.ManualStepping == false then warn(`Zone's Setting does not have 'ManualStepping' as true`); return end
	--=======================================================================================================>
	-- Begin Profiling:
	debug.profilebegin('Manual Step: Zone')
	-- If the ZoneEngine Class Exists, Step it:
	if self._Classes.ZoneEngine then self._Classes.ZoneEngine:Step(DeltaTime) end
	-- End Profiling:
	debug.profileend()
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Method to Update/Set the Setting of the Zone:
function ZoneModule._SetSetting(self: Zone, SettingName: any, EnumName: string, NameOrId: number | string)
	--=======================================================================================================>
	-- Grab the SettingValue Number Value:
	local SettingValue: number | 'Failure' = Enums.Enums[EnumName]:GetValue(NameOrId)
	-- If Detection is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if SettingValue == 'Failure' then warn(ZonerConstants.Logs.Zone[`Set{SettingName}`]); return end
	-- Set the new Detection in the Setting Table:
	self._Settings[SettingName] = SettingValue :: number
	-- Set the Attribute in a Deffered Function Synchronized in case this SetSetting function is called in Parallel by the User:
	self._ZoneFolder.Settings:SetAttribute(SettingName, SettingValue)
	--=======================================================================================================>
end

-- @Private
-- Method to Update/Set the State of the Zone:
function ZoneModule._SetState(self: Zone, StateName: string, State: boolean)
	--=======================================================================================================>
	-- If Detection is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if typeof(State) ~= 'boolean' then warn(ZonerConstants.Logs.Zone.SetState); return end
	-- Set the new Detection in the Setting Table:
	self._States[StateName] = State
	-- Set the Attribute in a Deffered Function Synchronized in case this SetState function is called in Parallel by the User:
	self._ZoneFolder.States:SetAttribute(StateName, State)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Method called on the PostSimulation (Heartbeat) RunService Event:
function ZoneModule._OnPostSimulation(self: Zone, Type: 'Sync'|'Desync', DeltaTime: number) 
	--=======================================================================================================>

	if not self._Classes.ZoneEngine then return end

	-- If the Zone is Paused then Dont Run this Code:
	if self._States.Paused then return end
	
	-- Begin Profiling:
	debug.profilebegin('OnPostSimulation: Zone')
	
	--=======================================================================================================>

	-- If the Counter is not at max, return to allow for varied update checking/polling:
	-- Checks every number interval as set in the Counters Table. It checks the connections and size of the ZonePart Array
	-- to determine the ActiveTargets and the Overall Active Status of the Zone:
	--if Utility.RateLimiter(self._Counters.ActivityCheck, DeltaTime) then self:_CheckActivity() end

	--=======================================================================================================>
	
	-- If the ZoneEngine Class Exists, then we will use the Zoner's PostSimulation Event to Call the ZoneEngine's Method,
	-- thus disabling the ZoneEngine's Internal PostSimulation Event::
	-- Begin Profiling:
	debug.profilebegin('OnPostSimulation: Serial Zone')
	-- Call the ZoneEngine's PostSimulation Function:
	self._Classes.ZoneEngine:OnPostSimulation(Type, DeltaTime)
	-- End Profiling:
	debug.profileend()

	--=======================================================================================================>
	
	-- End Profiling:
	debug.profileend()

	--=======================================================================================================>
end

-- @Private
-- Checks all the Event Connections to see if any are used, and then determine if the Zone is Active:
-- Checks every number interval as set in the Counters Table. It checks the connections and size of the ZonePart Array
-- to determine the ActiveTargets and the Overall Active Status of the Zone:
function ZoneModule._CheckActivity(self: Zone)
	--=======================================================================================================>

	-- Calculate the Total Number of Event Connections for the Player Events:
	self._ConnectionStats.PlayerConnections = 
		if self._Signals['PlayerExited']  then #self.PlayerExited:GetConnections()  else 0 +
		if self._Signals['PlayerEntered'] then #self.PlayerEntered:GetConnections() else 0
	-- Calculate the Total Number of Event Connections for the Item Events:
	self._ConnectionStats.ItemConnections = 
		if self._Signals['ItemExited']  then #self.ItemExited:GetConnections()  else 0 +
		if self._Signals['ItemEntered'] then #self.ItemEntered:GetConnections() else 0
	-- Calculate the Total Number of Event Connections for the Item Events:
	self._ConnectionStats.PartConnections = 
		if self._Signals['PartExited']  then #self.PartExited:GetConnections()  else 0 +
		if self._Signals['PartEntered'] then #self.PartEntered:GetConnections() else 0
	-- Calculate the Total Number of Event Connections for the LocalPlayer Events:
	self._ConnectionStats.LocalPlayerConnections = 
		if self._Signals['LocalPlayerExited']  then #self.LocalPlayerExited:GetConnections()  else 0 +
		if self._Signals['LocalPlayerEntered'] then #self.LocalPlayerEntered:GetConnections() else 0

	--=======================================================================================================>

	if self._ConnectionStats.LocalPlayerConnections > 0 then self._ActiveTargets.LocalPlayer = true end
	if self._ConnectionStats.PlayerConnections > 0      then self._ActiveTargets.Player     = true end
	if self._ConnectionStats.ItemConnections > 0        then self._ActiveTargets.Item       = true end
	if self._ConnectionStats.PartConnections > 0        then self._ActiveTargets.Part       = true end

	--=======================================================================================================>

	-- Cache Previous Active Status:
	local ActiveStatus = self._States.Active

	-- Loop through the ActiveTargets Table to Update the Attributes:
	for Target, Status in self._ActiveTargets do
		-- Set the Zone's Active Status to true or false depending on if any Triggers are Active:
		if Status == true then self._States.Active = true end
		-- If the ActiveTrigger Attribute Value is not up to date, then Update it on the Attribute:
		if self._ZoneFolder.ActiveTargets:GetAttribute(Target :: string) ~= Status then
			self._ZoneFolder.ActiveTargets:SetAttribute(Target :: string, Status)
		end
	end

	-- If the ZoneParts Array is Empty, meaning no ZoneParts are in workspace, then set active to false:
	if #(self._ZoneBoxes or self._ZoneParts) < 1 then self._States.Active = false end
	
	-- If the Zone Active Status is different then it previously was, Update the Attribute:
	if self._States.Active ~= ActiveStatus then self._ZoneFolder.States:SetAttribute('Active', self._States.Active) end

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._OnZonePartUpdate(self: Zone, Purpose: 'Add'|'Remove', ZonePart: BasePart)
	--=======================================================================================================>
	print(Purpose, ZonePart)
	-- If the Purpose is 'Remove', then remove the Part, else add it:
	if Purpose == 'Remove' then
		--===============================================================================================>

		-- Find the Index of the ZonePart in the Array:
		local ZonePartIndex: number? = table.find(self._Instances.ZoneParts, ZonePart) 

		-- Client only Extra Check:
		if self._RunScope == 'Client' then
			-- If the ZonePart is in the Array, and is still a descendant of the Game, the only reason for the Tag being removed(probably),
			-- Is because the Server Tags are being updated on that Instance, meaning the client tags here are overwritten:
			if ZonePartIndex and ZonePart:IsDescendantOf(game) and ZonePart.Parent ~= nil then ZonePart:AddTag(self._Tags.ZonePart); return end
		end

		-- If one is found, then Remove it from the Array:
		-- Remove the Part located at the Index from the Array:
		-- Return because theres nothing to update:
		if ZonePartIndex then table.remove(self._Instances.ZoneParts, ZonePartIndex) else return end
		--===============================================================================================>
	else
		--===============================================================================================>

		-- If one is not found, then Add it to the Array:
		-- Insert the ZonePart into the Array:
		-- Return because theres nothing to update:
		if not table.find(self._Instances.ZoneParts, ZonePart) then table.insert(self._Instances.ZoneParts, ZonePart) else return end
			
		-- If the Zone is Relocated and has a RelocationContainer, we need to make sure we didnt miss any Parts in the Zone
		-- due to streaming or something, and make sure all parts are added to the RelocationContainer:
		if self._States.Relocated and self._Instances.RelocationContainer then
			--================================================================>
			-- If the RelocationContainer is an Instance and a Folder, check if the ZonePart needs to be added back to the Container:
			if typeof(self._Instances.RelocationContainer) == "Instance" and self._Instances.RelocationContainer:IsA('Folder') then

				-- Loop through all the ZoneParts and Parent them to the Relocation Container, if they arent already:
				for Index: number, ZonePart in ipairs(self._Instances.ZoneParts) do 
					if ZonePart.Parent ~= self._Instances.RelocationContainer then
						ZonePart.Parent = self._Instances.RelocationContainer
					end
				end

			end
			--================================================================>
		end

		--===============================================================================================>
	end

	-- Destroy the Part Trove to destroy all Destroying Events:
	self._PartTrove:Destroy()

	-- Loop through the Holders Instances to Connect Events to each Part to Destroy the Zone if they are all destroyed:
	for Index: number, Part in ipairs(self._Instances.ZoneParts) do
		--==============================================================================>
		-- Connect to the Destroying event of the Script:
		-- We connect to this to check if the ZoneParts are ever all Destroyed in this Zone
		-- if so, we will Destroy this Zone Object:
		self._PartTrove:Connect(Part.Destroying, function()
			--======================================================================>
			if #self._Instances.ZoneParts < 1 then if self.Destroy then self:Destroy() end end
			--======================================================================>
		end)
		--==============================================================================>
	end

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._OnHolderInstanceUpdate(self: Zone, Purpose: 'Add'|'Remove', Holder: Instance)
	--=======================================================================================================>
	print('holder instance update', Purpose)
	-- If the Purpose is 'Remove', then remove the Part, else add it:
	if Purpose == 'Remove' then
		--===============================================================================================>

		-- Find the Index of the Holder in the Array:
		local HolderIndex: number? = table.find(self._Instances.Holders, Holder) 

		-- Client only Extra Check:
		if self._RunScope == 'Client' then
			-- If the ZonePart is in the Array, and is still a descendant of the Game, the only reason for the Tag being removed(probably),
			-- Is because the Server Tags are being updated on that Instance, meaning the client tags here are overwritten:
			if HolderIndex and Holder:IsDescendantOf(game) and Holder.Parent ~= nil then Holder:AddTag(self._Tags.Holder); return end
		end

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
		if not table.find(self._Instances.Holders, Holder) then
			table.insert(self._Instances.Holders, Holder)
		else 
			print('returning')
			return 
		end
		--===============================================================================================>
	end

print('made it here')
	--=======================================================================================================>
	
	-- Destroy the Part Trove to destroy all Destroying Events:
	self._HolderTrove:Destroy()

	-- Loop through the Holders Instances to Connect Events to each Part to Destroy the Zone if they are all destroyed:
	for Index: number, Holder in ipairs(self._Instances.Holders) do
		--==============================================================================>
		
		print('connect holder event')
		
		-- Connect to the Destroying event of the Holder:
		-- We do this to clear the Data in case the Holder is Destroyed:
		self._HolderTrove:Connect(Holder.Destroying, function()
			print('holder destorying')
			--======================================================================>
			if self.Destroy then self:Destroy() end
			--======================================================================>
		end)

		-- Connect to the Holder's ChildAdded Event:
		self._HolderTrove:Connect(Holder.ChildAdded, function(Child: any)
			print('holder added', Child)
			-- If not a BasePart, return:
			if not Child:IsA('BasePart') then return end
			-- Add the ZonePart tag to the Part if it doesnt have it:
			if Child:HasTag(self._Tags.ZonePart) == false then Child:AddTag(self._Tags.ZonePart) end
		end)
		
		-- Only run the follow below on the Server, since the Client can unload things:
		if self._RunScope == 'Client' then continue end

		-- Connect to the AncestryChanged event of the Script:
		-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
		-- We do this to clear the Data in case the Script is Destroyed:
		self._HolderTrove:Connect(Holder.AncestryChanged, function()
			--====================================================================================>
			if Holder.Parent == nil or Holder:IsDescendantOf(game) == false then if self.Destroy then self:Destroy() end end
			--====================================================================================>
		end)

		-- Connect to the GetPropertyChangedSignal(Parent) event of the Script:
		-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
		-- We do this to clear the Data in case the Script is Destroyed:
		self._HolderTrove:Connect(Holder:GetPropertyChangedSignal('Parent'), function()
			--====================================================================================>
			if Holder.Parent == nil or Holder:IsDescendantOf(game) == false then if self.Destroy then self:Destroy() end end
			--====================================================================================>
		end)
		--==============================================================================>
	end
	
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ INDEXER FUNCTIONS: ]


-- Create the MetaIndex function:
function ZoneModule.__index(self: Zone, Index: string): any
	--=======================================================================================================>
	-- Specific Indexing:
	--=======================================================================================================>
	-- Things for users to index and access:
	if Index == 'Container' then return self._Container end
	if Index == 'Identifier' or Index == 'Id' then return self._Identifier end

	if Index == 'DetectionMode'     then return self._Settings.DetectionMode end
	if Index == 'DetectionCoverage' then return self._Settings.DetectionCoverage end
	if Index == 'DetectionMethod'   then return self._Settings.DetectionMethod end

	if Index == 'Simulation' then return self._Settings.Simulation end
	if Index == 'Rate'       then return self._Settings.Rate end

	if Index == 'ExitDetectionMode'      then return self._Settings.ExitDetectionMode end
	if Index == 'EnterDetectionMode'     then return self._Settings.EnterDetectionMode end
	if Index == 'EnterDetectionCoverage' then return self._Settings.EnterDetectionCoverage end
	if Index == 'ExitDetectionCoverage'  then return self._Settings.ExitDetectionCoverage end

	if Index == 'Destroyed' then return self._States.Destroyed end
	if Index == 'Active'    then return self._States.Active end
	if Index == 'Relocated' then return self._States.Relocated end
	if Index == 'Paused'    then return self._States.Paused end
	if Index == 'Visible'   then return self._States.Visible end

	--=======================================================================================================>
	if Index == '_ZoneFolder' then return self._Instances.ZoneFolder end
	if Index == '_ZonerActor' then return self._ZonerHolder end
	if Index == '_ZonerGroup' then return self._ZonerHolder end
	-- Return a ZoneBoxes Index which is just the Container if the Container Type is Table Of Boxes:
	if Index == '_ZoneBoxes' or Index == 'ZoneBoxes' then return if self._ContainerType == 'TableOBox' then self._Container else nil end
	--=======================================================================================================>
	if Index == '_ZoneParts' or Index == 'ZoneParts' then return self._Instances.ZoneParts end
	if Index == '_Holders'   then return self._Instances.Holders end
	--=======================================================================================================>
	-- Index the Event Signal in the Signals Table and return it if it exists:
	if self._Signals[Index]    then return self._Signals[Index]    end
	-- Check if the Index is one of the Signal Names and then Check if it doesnt exist.
	-- If it doesnt exist, dynamically create the Signal and then Return it:
	if (Index == 'PartEntered' or Index == 'PartExited' or 
		Index == 'PlayerEntered' or Index == 'PlayerExited' or
		Index == 'ItemEntered' or Index == 'ItemExited') and not self._Signals[Index] 
	then
		self._Signals[Index] = self._Trove:Construct(GoodSignal)
		self._Signals[Index]:_SetOnConnectionCallback(function()self:_CheckActivity()end)
		self._Signals[Index]:_SetOnDisconnectionCallback(function()self:_CheckActivity()end)
		return self._Signals[Index]
	end
	-- Check if the Index is one of the Signal Names and then Check if it doesnt exist.
	-- If it doesnt exist, dynamically create the Signal and then Return it:
	if (Index == 'LocalPlayerEntered' or Index == 'LocalPlayerExited') and not self._Signals[Index] then
		if self._RunScope ~= 'Client' then return nil end
		self._Signals[Index] = self._Trove:Construct(GoodSignal)
		self._Signals[Index]:_SetOnConnectionCallback(function() self:_CheckActivity() end)
		self._Signals[Index]:_SetOnDisconnectionCallback(function() self:_CheckActivity() end)
		return self._Signals[Index]
	end
	--=======================================================================================================>
	-- If Index is in the immediate Module tree, return that value:			
	if ZoneModule[Index] then return ZoneModule[Index] end
	--=======================================================================================================>
	-- Return False if all else fails!
	return false 
	--=======================================================================================================>
end

-- Create the New Index function:
function ZoneModule.__newindex(self: Zone, Index: string, Value: any)
	--=======================================================================================================>
	if Index == 'EnterDetection' then self:_SetSetting('EnterDetection', 'Detection', Value); return end
	if Index == 'ExitDetection'  then self:_SetSetting('ExitDetection', 'Detection', Value);  return end
	--=======================================================================================================>
	if Index == 'Paused'  then self:_SetState('Paused', Value);  return end 
	if Index == 'Visible' then self:_SetState('Visible', Value); return end 
	--=======================================================================================================>
	error(`"{Index}" cannot be added to Zone`)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(ZoneModule)

--===========================================================================================================================>