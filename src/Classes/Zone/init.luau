--===========================================================================================================================>
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
local ZonerModule = script.Parent.Parent

-- Require the GoodSignal Utility Module for Creating Custom Signals:
local GoodSignal = require(ZonerModule.Utility.GoodSignal);
-- Require the Enum2 Module for Custom Enums:
local Enums      = require(ZonerModule.Utility.Enums);
-- Require the Trove Module for Cleanup:
local Trove      = require(ZonerModule.Utility.Trove);
-- Require the Utility Module for Utility:
local Utility    = require(ZonerModule.Utility.Utility);
-- Require the WorldModel Module for setting up the WorldModel:
local WorldModel = require(ZonerModule.Classes.WorldModel);
-- Require the Trove Module for Cleanup:
local ZonerConstants = require(ZonerModule.Children.Constants);

-- Require the Trove Module for Cleanup:
local ZoneConstants = require(script.Children.Constants);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.TypeDefinitions)


export type ZoneMetaData = TypeDefinitions.ZoneMetaData
export type ZoneModule   = TypeDefinitions.ZoneModule
export type Zone         = TypeDefinitions.Zone

export type ZoneCore = TypeDefinitions.ZoneCore

export type ZoneContainer = TypeDefinitions.ZoneContainer
export type ZonerFolder   = TypeDefinitions.ZonerFolder
export type RunScope      = 'Server'|'Client'

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- @Private
-- Constructor Function for this individual object:
function ZoneModule.New(ZonerFolder: ZonerFolder, RunScope: RunScope, Id: string, Container: ZoneContainer, Accuracy: number?, Detection: number?): Zone
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
		--====================================================>
		_ZonerFolder = ZonerFolder;
		--====================================================>
		_Tags = {
			ZonePart = `{Id}:ZonePart:{RunScope}`;
		};
		_States = {
			Active    = false;
			Destroyed = false;
			Relocated = false;
		};
		
		_Instances = {
			ZoneParts = {};
			Holders   = {};
		} :: any;

		_Counters = {
			ActivityCheck = {Counter = 0; CounterMax = 1.0};
			SettingsCheck = {Counter = 0; CounterMax = 5.0};
		};

		_ConnectionStats = {
			PlayerConnections      = 0;
			ItemConnections        = 0;
			LocalPlayerConnections = 0;
			PartConnections        = 0;
		};

		_ActiveTriggers = {
			LocalPlayer = false;
			Players     = false;
			Items       = false;
			Parts       = false;
		};

		_Properties = {};

		_Settings = {
			Accuracy   = Accuracy  or Enums.Enums.Accuracy.Automatic;
			Detection  = Detection or Enums.Enums.Detection.Automatic;
			Simulation = Enums.Enums.Simulation.PostSimulation;
			Rate       = Enums.Enums.Rate.Immediate;
		};

		--====================================================>
	} :: ZoneMetaData

	--=======================================================================================================>

	ZoneData._UpdateTrove = ZoneData._Trove:Extend()
	ZoneData._EventTrove  = ZoneData._Trove:Extend()

	ZoneData._HolderTrove = ZoneData._UpdateTrove:Extend()
	ZoneData._PartTrove   = ZoneData._UpdateTrove:Extend()

	--=======================================================================================================>

	-- Make the Signals Only Constructed when they're indexed:
	ZoneData._Signals = {
		--===================================================================>
		PlayerEntered      = ZoneData._Trove:Construct(GoodSignal);
		PlayerExited       = ZoneData._Trove:Construct(GoodSignal);

		PartEntered        = ZoneData._Trove:Construct(GoodSignal);
		PartExited         = ZoneData._Trove:Construct(GoodSignal);

		ItemEntered        = ZoneData._Trove:Construct(GoodSignal);
		ItemExited         = ZoneData._Trove:Construct(GoodSignal);

		-- Client only Signals:
		LocalPlayerEntered = if RunScope == 'Client' then ZoneData._Trove:Construct(GoodSignal) else nil :: any;
		LocalPlayerExited  = if RunScope == 'Client' then ZoneData._Trove:Construct(GoodSignal) else nil :: any;
		--===================================================================>
	};

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(ZoneData, ZoneModule)

	-- Start the Inventory:
	ZoneData:_Initialize()

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
	-- Send a Message to the ZoneCoreActor to Destroy itself:
	if self._CoreActor:IsDescendantOf(game) then self._CoreActor:SendMessage('Destroy') end
	-- Clean with Trove
	if self._Trove then self._Trove:Destroy() end
	--=======================================================================================================>
	-- Set the Attribute on the Folder to nil. Using the Identifier string as the name, this will clear the attribute from the Folder.
	-- Thus triggering a Cleaning and removal of the Zone from the Zoner Object:
	if self._ZonerFolder:IsDescendantOf(game) then self._ZonerFolder.Ids:SetAttribute(self._Identifier, nil) end
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ INITIALIZER FUNCTIONS: ]


-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._Initialize(self: Zone)
	for Index: number, Function: string in ipairs({'_SetData', '_SetInstances', '_SetEvents', '_SetCore'}) do self[Function](self) end
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._SetData(self: Zone)
	--=======================================================================================================>

	--self:_UpdateZone('All')

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._SetInstances(self: Zone)
	--=======================================================================================================>

	-- Create the Zone Core Actor and Script:
	do 
		--=============================================================================>
		-- Clone the ZoneCore Actor Template:
		self._Instances.CoreActor = script.Actors.ZoneTemplate:Clone()
		-- Parent the Actor to nil:
		self._CoreActor.Parent = nil

		-- Cache the Script:
		local UsedScript:   Script = self._CoreActor.Scripts:FindFirstChild(`ZoneCore.{self._RunScope}`) :: Script
		-- Cache the Script:
		local UnusedScript: Script = self._CoreActor.Scripts:FindFirstChild(`ZoneCore.{if self._RunScope == 'Client' then 'Server' else 'Client'}`) :: Script

		-- Name the ZoneCore Actor the Identifier of the ZoneCore + the RunScope:
		-- Name the Correct RunScope Script to a new Identifying ScriptName:
		self._CoreActor.Name, UsedScript.Name = `{self._Identifier}:{self._RunScope}`, `{self._Identifier}:ZoneCore:{self._RunScope}`

		-- Destroy the Other RunScope Script:
		UnusedScript:Destroy()

		-- Parent the Actor to the CelestialBodies Folder:
		self._CoreActor.Parent = self._ZonerFolder.Zones

		-- Enable the Correct RunScope Script:
		UsedScript.Enabled = true
		--=============================================================================>
	end

	--=======================================================================================================>

	local EventsFolder: Folder = Instance.new('Folder')
	EventsFolder.Name = 'Events'
	EventsFolder.Parent = self._CoreActor

	local PropertiesFolder: Configuration = Instance.new('Configuration')
	PropertiesFolder.Name = 'Properties'
	PropertiesFolder.Parent = self._CoreActor

	local StatesFolder: Configuration = Instance.new('Configuration')
	StatesFolder.Name = 'States'
	StatesFolder.Parent = self._CoreActor

	local TriggersFolder: Configuration = Instance.new('Configuration')
	TriggersFolder.Name = 'ActiveTriggers'
	TriggersFolder.Parent = self._CoreActor

	local SettingsFolder: Configuration = Instance.new('Configuration')
	SettingsFolder.Name = 'Settings'
	SettingsFolder.Parent = self._CoreActor

	--=======================================================================================================>

	for Index: number, Name: string in ipairs({'HoldersUpdate', 'ZoneSignals'}) do
		--=======================================================================>
		local Event: BindableEvent = Instance.new('BindableEvent')
		Event.Name = Name
		Event.Parent = EventsFolder
		--=======================================================================>
	end

	--=======================================================================================================>


	-- Loop through the States Table to Update the Attributes:
	for Key: string, Status: boolean in pairs(self._States) do
		self._CoreActor.States:SetAttribute(Key, Status)
	end

	-- Loop through the ActiveTriggers Table to Update the Attributes:
	for Key: string, Status: boolean in pairs(self._ActiveTriggers) do
		self._CoreActor.ActiveTriggers:SetAttribute(Key, Status)
	end

	-- Loop through the Settings Table to Update the Attributes:
	for Key: string, Status: boolean in pairs(self._Settings) do
		self._CoreActor.Settings:SetAttribute(Key, Status)
	end

	-- Check the CollectionService Tags for the ZoneParts already tagged:
	for Index: number, Part in ipairs(CollectionService:GetTagged(self._Tags.ZonePart)) do
		self:_OnZonePartUpdate('Add', Part)
	end

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._SetEvents(self: Zone)
	--=======================================================================================================>

	-- Fire when any Attribute Changes on the Properties:
	self._EventTrove:Connect(self._CoreActor.Properties.AttributeChanged, function(Attribute: string)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>

		-- Update this Objects Properties Attributes from the Changed Event firing:
		self._Properties[Attribute] = self._CoreActor.Properties:GetAttribute(Attribute)

		--================================================================================================>
		-- If the Attribute has to do with a Region, Recalculate/Reconstruct the Region3 Property using the Size and CFrame:
		if string.find(Attribute, 'ExactRegion') and self._Properties.ExactRegion_Size and self._Properties.ExactRegion_CFrame then
			--===========================================================================================>
			self._Properties['ExactRegion'] = 
				Utility.Get.Region3FromRegion3(self._Properties.ExactRegion_Size, self._Properties.ExactRegion_CFrame)
			--===========================================================================================>
		elseif string.find(Attribute, 'Region') and self._Properties.Region_Size and self._Properties.Region_CFrame then
			--===========================================================================================>
			self._Properties['Region'] = 
				Utility.Get.Region3FromRegion3(self._Properties.Region_Size, self._Properties.Region_CFrame)
			--===========================================================================================>
		end
		--================================================================================================>
	end)

	--=======================================================================================================>

	-- Connect to the ZonePart Tag Added Signal:
	-- Fires when a Part with the Zone Tag is added back to the Workspace:
	-- We will use this to reduce the Zone Based on Streaming:
	self._Trove:Connect(CollectionService:GetInstanceAddedSignal(self._Tags.ZonePart), function(ZonePart: BasePart)
		self:_OnZonePartUpdate('Add', ZonePart)
	end)

	-- Connect to the ZonePart Tag Removed Signal:
	-- Fires when a Part with the Zone Tag is removed from the Workspace:
	-- We will use this to restore the Zone Based on Streaming:
	self._Trove:Connect(CollectionService:GetInstanceRemovedSignal(self._Tags.ZonePart), function(ZonePart: BasePart)
		self:_OnZonePartUpdate('Remove', ZonePart)
	end)

	--=======================================================================================================>

	self._EventTrove:Connect(self._CoreActor.Events.HoldersUpdate.Event, function(Holders: {Instance})
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Update teh Instances Table:
		self._Instances.Holders = Holders

		-- Destroy all existing Events:
		self._HolderTrove:Destroy()

		-- If the Holders Array is greater than 0, it means its populated, so create Connections for the Holders:
		if #Holders > 0 then
			--==========================================================================================>

			-- Loop through the Holders Instances to Connect Events to each Part to Destroy the Zone if they are all destroyed:
			for Index: number, Part in ipairs(self._Instances.Holders) do
				--==============================================================================>
				-- Connect to the Destroying event of the Holder:
				-- We do this to clear the Data in case the Holder is Destroyed:
				self._HolderTrove:Connect(Part.Destroying, function()
					print('holder destorying')
					--======================================================================>
					if self.Destroy then self:Destroy() end
					--======================================================================>
				end)
				
				-- Only run the follow below on the Server, since the Client can unload things:
				if self._RunScope == 'Client' then continue end
				
				-- Connect to the AncestryChanged event of the Script:
				-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
				-- We do this to clear the Data in case the Script is Destroyed:
				self._HolderTrove:Connect(Part.AncestryChanged, function()
					--====================================================================================>
					if Part.Parent == nil or Part:IsDescendantOf(game) == false then if self.Destroy then self:Destroy() end end
					--====================================================================================>
				end)

				-- Connect to the GetPropertyChangedSignal(Parent) event of the Script:
				-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
				-- We do this to clear the Data in case the Script is Destroyed:
				self._HolderTrove:Connect(Part:GetPropertyChangedSignal('Parent'), function()
					--====================================================================================>
					if Part.Parent == nil or Part:IsDescendantOf(game) == false then if self.Destroy then self:Destroy() end end
					--====================================================================================>
				end)


				--==============================================================================>
			end

			--==========================================================================================>
		end
		--================================================================================================>
	end)

	self._EventTrove:Connect(self._CoreActor.Events.ZoneSignals.Event, function(Purpose: string, ...)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Reference the Signal Via the Purpose Hash and Fire:
		self._Signals[ZoneConstants.ZoneSignalHash.Receive[Purpose]]:Fire(...)
		--================================================================================================>
	end)

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._SetCore(self: Zone)
	--=======================================================================================================>

	-- Wait a Frame to allow the Actor Message to Bind and Connect:
	task.wait()

	-- Send a Message to the Actor to Construct the ZoneCore Object on a new Thread:
	-- We send the ModuleScript Instance (Core Class) so that it can be required over there on another thread:
	self._CoreActor:SendMessage('Construct', script.Classes.Core, self._Identifier, self._CoreActor, self._Container, self._RunScope)

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ PUBLIC METHODS: ]


-- @Public
-- Method that will Relocate the Zone to a WorldModel not in the Workspace:
function ZoneModule.Relocate(self: Zone): Zone
	--=======================================================================================================>

	-- If we have already Relocated this Zone, return:
	if self._States.Relocated then warn(`Zone is already Relocated! Cant Relocate again, so stop calling this method..`); return self end

	--=======================================================================================================>

	-- Grab the WorldModel for Zones:
	local WorldModel = WorldModel:SetupWorldModel(self._ZonerFolder)

	-- Set the Relocated State to true:
	self._States.Relocated = true

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
	RelocationContainer.Parent = WorldModel

	--=======================================================================================================>

	-- Return the self Object. So that this can be directly called on a constructing Object if we wanted:
	return self

	--=======================================================================================================>
end

-- @Public
-- Method to have the Zone begin Tracking the Item:
function ZoneModule.TrackItem(self: Zone, Item: BasePart | Model)
	--=======================================================================================================>


	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Method to Update/Set the Default Part/TrackedItem Detection of the Zone:
function ZoneModule.SetDetection(self: Zone, NameOrId: number | string)
	--=======================================================================================================>
	-- Grab the Detection Number Vlaue:
	local Detection: number | 'Failure' = Enums.Enums.Detection:GetValue(NameOrId)
	-- If Detection is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if Detection == 'Failure' then warn(ZonerConstants.Logs.Zone.SetDetection); return end
	-- Set the new Detection in the Setting Table:
	self._Settings.Detection = Detection :: number
	--=======================================================================================================>
end

-- @Public
-- Method to Update/Set the Default Accuracy of the Zone:
function ZoneModule.SetAccuracy(self: Zone, NameOrId: number | string)
	--=======================================================================================================>
	-- Grab the Accuracy Number Vlaue:
	local Accuracy: number | 'Failure' = Enums.Enums.Accuracy:GetValue(NameOrId)
	-- If Accuracy is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if Accuracy == 'Failure' then warn(ZonerConstants.Logs.Zone.SetAccuracy); return end
	-- Set the new Accuracy in the Setting Table:
	self._Settings.Accuracy = Accuracy :: number
	--=======================================================================================================>
end

-- @Public
-- Method to Update/Set the Default Simulation (RunService Event) of the Zone:
function ZoneModule.SetSimulation(self: Zone, NameOrId: number | string)
	--=======================================================================================================>
	-- Grab the Simulation Number Vlaue:
	local Simulation: number | 'Failure' = Enums.Enums.Simulation:GetValue(NameOrId)
	-- If Simulation is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if Simulation == 'Failure' then warn(ZonerConstants.Logs.Zone.SetSimulation1); return end
	--=======================================================================================================>
	-- Dont allow PreRender to be set on the Server:
	if Enums.Enums.Simulation:GetValue(Simulation) == 'PreRender' and self._RunScope == 'Server' then
		-- Warn/Log to console the Error:
		warn(ZonerConstants.Logs.Zone.SetSimulation2)
	else
		-- Set the new Simulation in the Setting Table:
		self._Settings.Simulation = Simulation :: number
	end
	--=======================================================================================================>
end

-- @Public
-- Method to Update/Set the Default Rate of the Zone:
function ZoneModule.SetRate(self: Zone, NameOrId: number | string)
	--=======================================================================================================>
	-- Grab the Rate Number Vlaue:
	local Rate: number | 'Failure' = Enums.Enums.Rate:GetValue(NameOrId)
	-- If Rate is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if Rate == 'Failure' then warn(ZonerConstants.Logs.Zone.SetRate); return end
	-- Set the new Rate in the Setting Table:
	self._Settings.Rate = Rate :: number
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Checks all the Event Connections to see if any are used, and then determine if the Zone is Active:
-- Checks every number interval as set in the Counters Table. It checks the connections and size of the ZonePart Array
-- to determine the ActiveTriggers and the Overall Active Status of the Zone:
function ZoneModule._CheckActivity(self: Zone)
	--=======================================================================================================>

	-- Calculate the Total Number of Event Connections for the Player Events:
	self._ConnectionStats.PlayerConnections = #self.PlayerExited:GetConnections() + #self.PlayerEntered:GetConnections()
	-- Calculate the Total Number of Event Connections for the Item Events:
	self._ConnectionStats.ItemConnections   = #self.ItemExited:GetConnections()   + #self.ItemEntered:GetConnections()
	-- Calculate the Total Number of Event Connections for the Item Events:
	self._ConnectionStats.PartConnections   = #self.PartExited:GetConnections()   + #self.PartEntered:GetConnections()

	-- Calculate the Total Number of Event Connections for the LocalPlayer Events:
	self._ConnectionStats.LocalPlayerConnections = if self._RunScope == 'Client' then
		#self.LocalPlayerExited:GetConnections() + #self.LocalPlayerEntered:GetConnections() else 0

	--=======================================================================================================>

	if self._ConnectionStats.LocalPlayerConnections > 0 then self._ActiveTriggers.LocalPlayer = true end
	if self._ConnectionStats.PlayerConnections > 0      then self._ActiveTriggers.Players     = true end
	if self._ConnectionStats.ItemConnections > 0        then self._ActiveTriggers.Items       = true end
	if self._ConnectionStats.PartConnections > 0        then self._ActiveTriggers.Parts       = true end

	--=======================================================================================================>

	-- Cache Previous Active Status:
	local ActiveStatus = self._States.Active

	-- Loop through the ActiveTriggers Table to Update the Attributes:
	for Key: string, Status: boolean in pairs(self._ActiveTriggers) do

		-- Set the Zone's Active Status to true or false depending on if any Triggers are Active:
		if Status == true then self._States.Active = true end

		-- If the ActiveTrigger Attribute Value is not up to date, then Update it on the Attribute:
		if self._CoreActor.ActiveTriggers:GetAttribute(Key) ~= Status then
			self._CoreActor.ActiveTriggers:SetAttribute(Key, Status)
		end

	end

	-- If the ZoneParts Array is Empty, meaning no ZoneParts are in workspace, then set active to false:
	if #self._ZoneParts < 1 then self._States.Active = false end

	-- If the Zone Active Status is different then it previously was, Update the Attribute:
	if self._States.Active ~= ActiveStatus then self._CoreActor.States:SetAttribute('Active', self._States.Active) end

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZoneModule._OnZonePartUpdate(self: Zone, Purpose: 'Add'|'Remove', ZonePart: BasePart)
	--=======================================================================================================>

	-- If the Purpose is 'Remove', then remove the Part, else add it:
	if Purpose == 'Remove' then
		--===============================================================================================>

		-- Find the Index of the ZonePart in the Array:
		local ZonePartIndex: number? = table.find(self._Instances.ZoneParts, ZonePart) 

		-- Client only Extra Check:
		if self._RunScope == 'Client' then
			-- If the ZonePart is in the Array, and is still a descendant of the Game, the only reason for the Tag being removed(probably),
			-- Is because the Server Tags are being updated on that Instance, meaning the client tags here are overwritten:
			if ZonePartIndex and ZonePart:IsDescendantOf(game) and ZonePart.Parent ~= nil then return end
		end

		-- If one is found, then Remove it from the Array:
		if ZonePartIndex then 
			--================================================================>
			-- Remove the Part located at the Index from the Array:
			table.remove(self._Instances.ZoneParts, ZonePartIndex)
			--================================================================>
		else
			--================================================================>
			-- Return because theres nothing to update:
			return
		end

		--===============================================================================================>
	else
		--===============================================================================================>

		-- Find the Index of the ZonePart in the Array:
		local ZonePartIndex: number? = table.find(self._Instances.ZoneParts, ZonePart) 

		-- If one is not found, then Add it to the Array:
		if not ZonePartIndex then 
			--================================================================>
			-- Insert the ZonePart into the Array:
			table.insert(self._Instances.ZoneParts, ZonePart)
			--================================================================>
		else
			--================================================================>
			-- Return because theres nothing to update:
			return
		end

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
		-- We do this to clear the Data in case the Script is Destroyed:
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
-- Method called on the PostSimulation (Heartbeat) RunService Event:
function ZoneModule._OnPostSimulation(self: Zone, Type: 'Sync'|'Desync', DeltaTime: number) 
	--=======================================================================================================>

	-- Begin Profiling:
	debug.profilebegin('OnPostSimulation: Zone')

	-- If the Counter is not at max, return to allow for varied update checking/polling:
	-- Checks every number interval as set in the Counters Table. It checks the connections and size of the ZonePart Array
	-- to determine the ActiveTriggers and the Overall Active Status of the Zone:
	if Utility:RateLimiter(self._Counters.ActivityCheck, DeltaTime) then self:_CheckActivity() end

	-- If the Counter is not at max, return to allow for varied update checking/polling:
	-- Update the Settings rate limited so that its not constantly checking and setting attributes:
	if Utility:RateLimiter(self._Counters.SettingsCheck, DeltaTime) then 
		--==========================================================================================>
		-- Loop through the Settings Table to Update Each Setting Attribute:
		for Key: string, Value: number in pairs(self._Settings) do 
			-- Check if the Attribute and Variable have a difference, if they do, Update the Attribute:
			if Value ~= self._CoreActor.Settings:GetAttribute(Key) then self._CoreActor.Settings:SetAttribute(Key, Value) end
		end
		--==========================================================================================>
	end

	-- End Profiling:
	debug.profileend()

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ INDEXER FUNCTIONS: ]


-- Create the MetaIndex function:
function ZoneModule.__index(self: Zone, Index: string): any
	--=======================================================================================================>
	-- Specific Indexing:
	--=======================================================================================================>
	if Index == 'Container' then return self._Container end
	--=======================================================================================================>
	if Index == '_CoreActor' then return self._Instances.CoreActor end
	--=======================================================================================================>
	if Index == '_Active' or Index == 'Active' then return self._States.Active end
	--=======================================================================================================>
	if Index == '_ZoneParts' then return self._Instances.ZoneParts end
	if Index == '_Holders' then return self._Instances.Holders end
	--=======================================================================================================>
	if Index == 'Accuracy'   then return self._Settings.Accuracy end
	if Index == 'Detection'  then return self._Settings.Detection end
	if Index == 'Simulation' then return self._Settings.Simulation end
	--=======================================================================================================>
	if self._Properties[Index] then return self._Properties[Index] end
	if self._Signals[Index]    then return self._Signals[Index]    end
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
	error(`"{Index}" cannot be added to Zone`)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(ZoneModule)

--===========================================================================================================================>