--===========================================================================================================================>
--!native
--!strict
--===========================================================================================================================>

-- Define Module table
local ZoneCoreModule = {}

--===========================================================================================================================>
--[ SERVICES: ]


-- Get the needed Services for the following Code:
local CollectionService = game:GetService('CollectionService')
local RunService        = game:GetService('RunService')
local Players           = game:GetService('Players')

--===========================================================================================================================>

-- Reference the Top Level Module so that we can easily Index our Modules
local ZonerModule = script.Parent.Parent.Parent.Parent

-- Require the Enum2 Module for Custom Enums:
local Enums   = require(ZonerModule.Utility.Enums);
-- Require the Trove Module for Cleanup:
local Trove   = require(ZonerModule.Utility.Trove);
-- Require the Trove Module for Cleanup:
local Utility = require(ZonerModule.Utility.Utility);

-- Require the Trove Module for Cleanup:
local Regions = require(ZonerModule.Utility.Regions);
-- Require the Trove Module for Cleanup:
local ItemTracker   = require(ZonerModule.Classes.ItemTracker);
local Plagger       = require(ZonerModule.Classes.Plagger);
local Detector      = require(ZonerModule.Classes.Detector);

-- Require the Trove Module for Cleanup:
local ZoneConstants = require(script.Parent.Parent.Children.Constants);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Parent.Parent.TypeDefinitions)


export type ZoneMetaData = TypeDefinitions.ZoneMetaData
export type ZoneModule   = TypeDefinitions.ZoneModule
export type Zone         = TypeDefinitions.Zone

export type ZoneCoreMetaData = TypeDefinitions.ZoneCoreMetaData
export type ZoneCoreModule   = TypeDefinitions.ZoneCoreModule
export type ZoneCore         = TypeDefinitions.ZoneCore

export type ZonePartProperties = TypeDefinitions.ZonePartProperties
export type ZoneContainer      = TypeDefinitions.ZoneContainer
export type ZoneTriggers       = TypeDefinitions.ZoneTriggers
export type ZoneParts          = TypeDefinitions.ZoneParts

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- Constructor Function for this individual object:
function ZoneCoreModule.New(Id: string, CoreActor: Actor, Container: ZoneContainer, RunScope: 'Server'|'Client'): ZoneCore
	--=======================================================================================================>

	-- Set a Memory Category for this Zoner:
	debug.setmemorycategory('Zoner: ZoneCore')

	--=======================================================================================================>

	-- Define Data
	local ZoneCoreData: ZoneCoreMetaData = {
		--====================================================>
		_Trove = Trove.New();
		--====================================================>
		_RunScope = RunScope;
		--====================================================>
		_Identifier = Id;
		--====================================================>
		_WorldModel = require(ZonerModule.Classes.WorldModel);
		--====================================================>
		-- Reference to the Original Zone Container:
		_Container = Container;
		--====================================================>
		_CoreActor = CoreActor;
		--====================================================>
		-- Dictionary of ZoneParts and their Properties:
		_ZoneParts = {};
		_Classes = {} :: any;
		_Settings = {};
		_Client = {};
		_Detectors = {};
		--====================================================>
		_Tags = {
			ZonePart = `{Id}:ZonePart:{RunScope}`;
		};
		--====================================================>
		_Instances = {
			Holders   = {};
		} :: any;
		_Events    = {} :: any;
		_OverlapParamaters = {
			PartsIncludeList = OverlapParams.new();
			PartsExcludeList = OverlapParams.new();
		};

		_States = {
			Active = false;
			Destroyed = false;
		};

		_Counters = {
			ZoneCalculations = {Counter = 0; CounterMax = Enums.Enums.Accuracy:GetProperty('High')};
		};

		_ActiveTriggers = {
			LocalPlayer = false;
			Players     = false;
			Items       = false;
			Parts       = false;
		};

		_Properties = {
			Region      = nil;
			ExactRegion = nil;
			Volume      = nil;
			BoundMind   = nil;
			BoundMax    = nil;

			AllZonePartsAreBlocks = false;
		} :: any;

		_Updates = {
			Region = false;
			Parts  = false;
		};
		--====================================================>

		_PartData = {
			CurrentPartsInZone  = {};
			PreviousPartsInZone = {};
		};

		--====================================================>
	} :: ZoneCoreMetaData

	--=======================================================================================================>

	ZoneCoreData._TriggerTroves = {
		LocalPlayer = if RunScope == 'Client' then ZoneCoreData._Trove:Extend() else nil :: any;
		Players     = ZoneCoreData._Trove:Extend();
		Items       = ZoneCoreData._Trove:Extend();
	}

	ZoneCoreData._PartTrove   = ZoneCoreData._Trove:Extend()
	ZoneCoreData._HolderTrove = ZoneCoreData._Trove:Extend()

	ZoneCoreData._EventTrove       = ZoneCoreData._Trove:Extend()
	ZoneCoreData._SimulationTrove  = ZoneCoreData._EventTrove:Extend()

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(ZoneCoreData, ZoneCoreModule)

	-- Start the Inventory:
	ZoneCoreData:Initialize()

	--=======================================================================================================>

	-- Return the MetaTable Data
	return ZoneCoreData :: any

	--=======================================================================================================>
end

-- Destroyer Function which clears the entirity of the Data for the Object:
function ZoneCoreModule.Destroy(self: ZoneCore)
	--=======================================================================================================>

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

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ INITIALIZER FUNCTIONS: ]


-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.Initialize(self: ZoneCore)
	for Index: number, Function: string in ipairs({'SetData', 'SetEvents'}) do self[Function](self) end
end

-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.SetData(self: ZoneCore)
	--=======================================================================================================>

	if self._RunScope == 'Client' then

		-- Yield until a LocalPlayer Exists:
		if not Players.LocalPlayer then repeat task.wait() until Players.LocalPlayer end

		self._Client.LocalPlayerName = Players.LocalPlayer.Name

	end

	local EventsChildren: {BindableEvent} = self._CoreActor.Events:GetChildren() :: any

	for Index: number, Event: BindableEvent in ipairs(EventsChildren) do
		self._Events[Event.Name] = Event
	end

	EventsChildren = nil :: any


	self._OverlapParamaters.PartsIncludeList.FilterType = Enum.RaycastFilterType.Include
	self._OverlapParamaters.PartsIncludeList.FilterDescendantsInstances = {}

	self._OverlapParamaters.PartsExcludeList.FilterType = Enum.RaycastFilterType.Exclude
	self._OverlapParamaters.PartsExcludeList.FilterDescendantsInstances = {} --self._ZoneParts :: {any}


	-- Check the CollectionService Tags for the ZoneParts already tagged:
	for Index: number, Part in ipairs(CollectionService:GetTagged(self._Tags.ZonePart)) do
		self:OnZonePartUpdate('Add', Part)
	end

	--=======================================================================================================>

	-- Update each of the Folder Attribute Dictionaries by grabbing their attributes dynamically via the Array:
	for Index: number, FolderName: string in ipairs({'States', 'Properties', 'Settings', 'ActiveTriggers'}) do
		--================================================================================================>
		-- Find the Folder (Configuration) as a Child of the Actor using the Name String passed:
		local Folder: Configuration = self._CoreActor:FindFirstChild(FolderName) :: Configuration
		-- Grab the Attributes on the Folders and update our copy of them:
		for Name: string, Value: any in Folder:GetAttributes() do self[`_{FolderName}`][Name] = Value end
		--================================================================================================>
	end
	
	--=======================================================================================================>

	-- Run the Update Zone Method:
	self:UpdateZone('All')

	-- Update the Rate Counter with the Setting:
	self:UpdateRate(self._Settings.Rate)

	--=======================================================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.SetEvents(self: ZoneCore)
	--=======================================================================================================>

	-- Connect to the RunService PostSimulation (Heartbeat) event:
	self._EventTrove:Connect(RunService.PostSimulation, function(DeltaTime: number)
		self:OnPostSimulation('Sync', DeltaTime)
	end)

	--=======================================================================================================>

	-- Fire when any Attribute Changes on the ActiveTriggers:
	self._EventTrove:ConnectParallel(self._CoreActor.ActiveTriggers.AttributeChanged, function(Trigger: string)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		self._ActiveTriggers[Trigger] = self._CoreActor.ActiveTriggers:GetAttribute(Trigger)
		--================================================================================================>
		-- Synchronize the thread:
		task.synchronize()
		--================================================================================================>
		-- Call the UpdateTrigger Method to Update Specific Things related to the Trigger State:
		self:UpdateTrigger(Trigger :: any, self._ActiveTriggers[Trigger])
		--================================================================================================>
	end)

	-- Fire when any Attribute Changes on the States:
	self._EventTrove:ConnectParallel(self._CoreActor.States.AttributeChanged, function(State: string)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		self._States[State] = self._CoreActor.States:GetAttribute(State)
		--================================================================================================>
	end)

	-- Fire when any Attribute Changes on the Settings:
	self._EventTrove:ConnectParallel(self._CoreActor.Settings.AttributeChanged, function(Setting: string)
		--================================================================================================>
		-- If already Destroyed, return:
		if self._States.Destroyed then return end
		--================================================================================================>
		-- Update this Objects Properties Attributes from the Changed Event firing:
		self._Settings[Setting] = self._CoreActor.Settings:GetAttribute(Setting)
		--================================================================================================>
		-- If the Setting is the Detection, then call the Method for it:
		if Setting == 'Detection'  then self:UpdateDetection(self._Settings[Setting])  end
		-- If the Setting is the Simulation, then call the Method for it:
		if Setting == 'Simulation' then self:UpdateSimulation(self._Settings[Setting]) end
		-- If the Setting is the Accuracy, then call the Method for it:
		if Setting == 'Accuracy'   then self:UpdateAccuracy(self._Settings[Setting])   end
		-- If the Setting is the Accuracy, then call the Method for it:
		if Setting == 'Rate'       then self:UpdateRate(self._Settings[Setting])       end
		--================================================================================================>
	end)

	--=======================================================================================================>

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

	--=======================================================================================================>

	-- Update the Simulation Events with the Setting:
	self:UpdateSimulation(self._Settings.Simulation)

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.GetZoneParts(self: ZoneCore): ({BasePart}, {Instance})
	--=======================================================================================================>

	-- Define a ZoneParts array and a Holders Array:
	local ZoneParts: {BasePart},  Holders: {Instance} = {}, {}

	--=======================================================================================================>

	-- Create a reference to the Container Instance or Table so that the Type can be seen as Any:
	local Container: any = self._Container
	-- Grab the String Type of the Container Variable:
	local ContainerType: string = typeof(Container)

	--=======================================================================================================>

	-- If the Container Type is a Table, get all the ZoneParts from inside the Table:
	-- Else if the Container Type is an Instance, get all the Decendants that are ZoneParts:
	if ContainerType == "table" then
		--============================================>
		-- Loop through Table or Array of ZoneParts:
		for Key, Part: BasePart in pairs(Container) do
			-- If Part is a BasePart, insert as a ZonePart:
			if Part:IsA("BasePart") then table.insert(ZoneParts, Part) end
		end
		--============================================>
	elseif ContainerType == "Instance" then
		--============================================>
		-- If the Container is a Single BasePart itself, insert it into ZoneParts:
		-- Else Loop through all the Children of the Instance and Place the Instance as a Holder Instance:
		if Container:IsA("BasePart") then
			-- Container is a ZonePart, insert it:
			table.insert(ZoneParts, Container)
		else
			--====================================>
			-- Container is a Holder Instance, so insert it:
			table.insert(Holders, Container)
			--====================================>
			-- Get all Descendants of Container:
			local ContainerDescendants: {BasePart} = Container:GetDescendants()

			-- Loop through all the descendants of the Container Holder to add as ZoneParts or Holders:
			for Index: number, Part: BasePart in ipairs(ContainerDescendants) do
				-- If its a BasePart, its a ZonePart, else a Holder:
				if Part:IsA("BasePart") then
					-- If Part is a BasePart, insert as a ZonePart:
					table.insert(ZoneParts, Part)
				else
					-- If Part is anything else, insert as a Holder:
					table.insert(Holders, Part)
				end
			end

			-- Clear from Memory:
			ContainerDescendants = nil :: any
			--====================================>
		end
		--============================================>
	end

	--=======================================================================================================>

	-- Return the two filled Arrays (possibly):
	return ZoneParts, Holders
	--=======================================================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.GetZonePartsFromContainer(self: ZoneCore, Container: any): ({BasePart}, {Instance})
	--=======================================================================================================>

	-- Define a ZoneParts array and a Holders Array:
	local ZoneParts: {BasePart},  Holders: {Instance} = {}, {}

	--=======================================================================================================>

	-- Grab the String Type of the Container Variable:
	local ContainerType: string = typeof(Container)

	--=======================================================================================================>

	-- If the Container Type is a Table, get all the ZoneParts from inside the Table:
	-- Else if the Container Type is an Instance, get all the Decendants that are ZoneParts:
	if ContainerType == "table" then
		--============================================>
		-- Loop through Table or Array of ZoneParts:
		for Key, Part: BasePart in pairs(Container) do
			-- If Part is a BasePart, insert as a ZonePart:
			if Part:IsA("BasePart") then table.insert(ZoneParts, Part) end
		end
		--============================================>
	elseif ContainerType == "Instance" then
		--============================================>
		-- If the Container is a Single BasePart itself, insert it into ZoneParts:
		-- Else Loop through all the Children of the Instance and Place the Instance as a Holder Instance:
		if Container:IsA("BasePart") then
			-- Container is a ZonePart, insert it:
			table.insert(ZoneParts, Container)
		else
			--====================================>
			-- Container is a Holder Instance, so insert it:
			table.insert(Holders, Container)
			--====================================>
			-- Get all Descendants of Container:
			local ContainerDescendants: {BasePart} = Container:GetDescendants()

			-- Loop through all the descendants of the Container Holder to add as ZoneParts or Holders:
			for Index: number, Part: BasePart in ipairs(ContainerDescendants) do
				-- If its a BasePart, its a ZonePart, else a Holder:
				if Part:IsA("BasePart") then
					-- If Part is a BasePart, insert as a ZonePart:
					table.insert(ZoneParts, Part)
				else
					-- If Part is anything else, insert as a Holder:
					table.insert(Holders, Part)
				end
			end

			-- Clear from Memory:
			ContainerDescendants = nil :: any
			--====================================>
		end
		--============================================>
	end

	--=======================================================================================================>

	-- Return the two filled Arrays (possibly):
	return ZoneParts, Holders
	--=======================================================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.GetZonePartsArray(self: ZoneCore, ZoneParts: ZoneParts): {BasePart}
	--=======================================================================================================>
	-- Define a ZoneParts Array:
	local ZonePartsArray: {BasePart} = {}
	-- Loop through ZonePart Dictionary taking every Part to add to Array:
	for Part: BasePart, Properties: ZonePartProperties in ZoneParts do table.insert(ZonePartsArray, Part) end
	-- Return Array:
	return ZonePartsArray
	--=======================================================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.GetZonePartProperties(self: ZoneCore, ZonePart: BasePart): ZonePartProperties
	--=======================================================================================================>

	-- Define the ZonePartProperties Dictionary:
	local ZonePartProperties: ZonePartProperties = {} :: ZonePartProperties

	-- Returns whether the ZonePart is a Block:
	local function IsBlock(Part: BasePart): boolean
		-- Cache the PartShape:
		local PartShape: Enum.PartType | false = Part:IsA('Part') and Part.Shape 
		-- Return the boolean whether the PartShape is a 'Block' or the Part is a MeshPart with no Id:
		return PartShape == Enum.PartType.Block or Part:IsA('MeshPart') and Part.MeshId == "" 
	end

	-- Returns whether the ZonePart is a Sphere:
	local function IsSphere(Part: BasePart): boolean
		-- Cache the PartShape:
		local PartShape: Enum.PartType | false = Part:IsA('Part') and Part.Shape 
		-- Return the boolean whether the PartShape is a 'Ball'
		return PartShape == Enum.PartType.Ball
	end

	--=======================================================================================================>

	-- Set the ZonePart Type of Block:
	ZonePartProperties.Type = if IsBlock(ZonePart) then 'Block' elseif IsSphere(ZonePart) then 'Sphere' else 'Complex'

	if ZonePartProperties.Type ~= 'Sphere' then

		-- Get the Region, BoundMin and BoundMax
		local Region: Region3, BoundMin: Vector3, BoundMax: Vector3 = Regions:GetCalculatedPartToRegion(ZonePart, true)

		-- Set the Bounds Table with the Vectors Min and Max:
		ZonePartProperties.Bounds = {Min = BoundMin, Max = BoundMax}

		ZonePartProperties.Region_Size   = Region.Size
		ZonePartProperties.Region_CFrame = Region.CFrame

		ZonePartProperties.Size   = ZonePart.Size
		ZonePartProperties.CFrame = ZonePart.CFrame

		-- Grab the Corners of the Part from the Region. If the Shape is that of a Block, get half the corners, else get all 8:
		ZonePartProperties.Corners = 
			Regions:GetCorners(Region.CFrame, Region.Size, if ZonePartProperties.Type == 'Complex' then false else true);

	else

		ZonePartProperties.Size   = ZonePart.Size
		ZonePartProperties.CFrame = ZonePart.CFrame

	end

	--=======================================================================================================>

	-- Return the ZonePartProperties Dictionary:
	return ZonePartProperties

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ ZONE UPDATE METHODS: ]


-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.UpdateTrigger(self: ZoneCore, Trigger: ZoneTriggers, State: boolean)
	--=======================================================================================================>

	-- If the Trigger is the LocalPlayer or Players, we will either create or destroy the PlayerHandler, since both triggers use it:
	if Trigger == 'LocalPlayer' or Trigger == 'Players' then
		--===============================================================================================>
		-- If the State is true, then Create an Object, else Destroy it:
		if State == true then
			--=======================================================================================>
			self._Detectors[Trigger] = self._Trove:Construct(Detector, Trigger, self._Settings.Detection)
			--=======================================================================================>
		else
			--=======================================================================================>
			if self._Detectors[Trigger] then self._Trove:Remove(self._Detectors[Trigger]); self._Detectors[Trigger] = nil end
			--=======================================================================================>
		end
		--===============================================================================================>
	end

	--=======================================================================================================>

	-- If the Trigger is being turned on or off for 'Parts', clear PartData tables:
	if Trigger == 'Parts' then
		table.clear(self._PartData.PreviousPartsInZone)
		table.clear(self._PartData.CurrentPartsInZone)
	end
	
	--=======================================================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function ZoneCoreModule.UpdateZone(self: ZoneCore, Purpose: 'Parts'|'Region'|'All'|'PartConnections'|'HolderConnections')
	--=======================================================================================================>

	if Purpose == 'Parts' then
		--=======================================================================================>

		-- Grab the ZoneParts and Holders Array from the current Container:
		local ZoneParts: {BasePart}, Holders: {Instance} = self:GetZoneParts()

		-- Set the Holders:
		self._Instances.Holders = Holders

		-- Fire The ZonePartsUpdate Event to Update the ZoneParts and Holders in Serial in the Parent Object:
		if #self._Holders > 0 then self._Events.HoldersUpdate:Fire(self._Holders) end

		--=======================================================================================>
		
		-- Determine whether the ZoneParts are all Blocks:
		self._Properties.AllZonePartsAreBlocks = Regions:ArePartsAllBlocks(self:GetZonePartsArray(self._ZoneParts))

		--=======================================================================================>

		-- Set the boolean to true to Update the Attribute Properties in Serial:
		self._Updates.Parts = true

		-- Sync the thread:
		task.synchronize()

		-- Loop through the ZoneParts to add tags:
		for Index: number, Part: BasePart in ipairs(ZoneParts) do
			-- If the Part already has a Tag, then continue:
			if Part:HasTag(self._Tags.ZonePart) then continue end
			-- Add the ZonePart tag to the ZonePart:
			Part:AddTag(self._Tags.ZonePart)
		end

		--=======================================================================================>
	elseif Purpose == 'Region' then
		--=======================================================================================>
		
		local ZoneParts = self:GetZonePartsArray(self._ZoneParts)
		
		-- Get the Region, BoundMin and BoundMax
		self._Properties.Region, self._Properties.BoundMin, self._Properties.BoundMax = 
			Regions:GetCalculatedPartToRegion(ZoneParts)
		
		-- Get the Size of the Region3:
		local RegionSize: Vector3 = self._Properties.Region.Size
		-- Calculate the Volume of the Region Via the Rounded Region's Size:
		self._Properties.Volume = RegionSize.X * RegionSize.Y * RegionSize.Z
		--=======================================================================================>

		-- Get the ExactRegion Region3:
		self._Properties.Exact_Region, self._Properties.Exact_BoundMin, self._Properties.Exact_BoundMax = 
			Regions:GetCalculatedPartToRegion(ZoneParts, true)
		
		-- Set its Value:
		self._Properties.ExactRegion_CFrame = self._Properties.Exact_Region.CFrame
		self._Properties.ExactRegion_Size   = self._Properties.Exact_Region.Size

		self._Properties.Region_CFrame = self._Properties.Region.CFrame
		self._Properties.Region_Size   = RegionSize

		--=======================================================================================>

		-- Set the boolean to true to Update the Attribute Properties in Serial:
		self._Updates.Region = true

		--=======================================================================================>
	elseif Purpose == 'PartConnections' then
		--=======================================================================================>

		-- Synchronize the thread:
		task.synchronize()

		-- Clear all the existing Update Connections:
		self._PartTrove:Destroy()

		-- Loop through all the ZoneParts and Connect ProperyChanged Connections for Size and Position.
		-- Update the Regions if their Properties Change:
		for Part: BasePart, Properties: ZonePartProperties in self._ZoneParts do
			--=============================================================================>

			self._PartTrove:ConnectParallel(Part:GetPropertyChangedSignal('Size'), function()
				self:UpdateZone('Region')
			end)

			self._PartTrove:ConnectParallel(Part:GetPropertyChangedSignal('Position'), function()
				self:UpdateZone('Region')
			end)

			--=============================================================================>
		end

		--=======================================================================================>
	elseif Purpose == 'HolderConnections' then
		--=======================================================================================>

		-- Synchronize the thread:
		task.synchronize()

		-- Clear all the existing Update Connections:
		self._HolderTrove:Destroy()

		-- Loop through all the Holder Instances, and Connect ChildAdded and Removed Connections:
		-- Update all Zone Data if a new part is added:
		for Index: number, HolderPart in ipairs(self._Holders) do
			--=============================================================================>
			-- Connect to the Holder's ChildAdded Event:
			self._HolderTrove:Connect(HolderPart.ChildAdded, function(Child: any)
				-- If not a BasePart, return:
				if not Child:IsA('BasePart') then return end
				-- Add the ZonePart tag to the Part if it doesnt have it:
				if Child:HasTag(self._Tags.ZonePart) == false then Child:AddTag(self._Tags.ZonePart) end
			end)

			--=============================================================================>
		end

		--=======================================================================================>
	elseif Purpose == 'All' then
		--=======================================================================================>
		self:UpdateZone('Parts')
		self:UpdateZone('Region')
		self:UpdateZone('PartConnections')
		self:UpdateZone('HolderConnections')
		--=======================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ SETTING UPDATE METHODS: ]


-- Function that is called when the Detection Setting is updated:
function ZoneCoreModule.UpdateDetection(self: ZoneCore, Detection: number)
	--=======================================================================================================>

	if self._Detectors.Players     then self._Detectors.Players:SetDetection(Detection)    end
	if self._Detectors.LocalPlayer then self._Detectors.LocalPlayer:SetDetection(Detection) end

	--=======================================================================================================>
end

--- Function that is called when the Simulation Setting is updated:
function ZoneCoreModule.UpdateSimulation(self: ZoneCore, Simulation: number)
	--=======================================================================================================>

	-- Synchronize the thread:
	task.synchronize()

	--=======================================================================================================>

	-- Destroy all the Current Simulation Events so that we can recreate them on a new Event:
	self._SimulationTrove:Destroy()

	-- Connect to the RunService PostSimulation (Heartbeat) event:
	self._SimulationTrove:ConnectParallel(RunService[Enums.Enums.Simulation:GetName(Simulation)], function(DeltaTime: number)
		self:OnSimulation('Desync', DeltaTime)
	end)

	--=======================================================================================================>
end

--- Function that is called when the Accuracy Setting is updated:
function ZoneCoreModule.UpdateAccuracy(self: ZoneCore, Accuracy: number)
	--=======================================================================================================>

	-- Grab the AccuracyRate Number Vlaue:
	local ZoneAccuracy: Enums.Accuracies = Enums.Enums.Accuracy:GetValue(Accuracy)

	--=======================================================================================================>
end

--- Function that is called when the Rate Setting is updated:
function ZoneCoreModule.UpdateRate(self: ZoneCore, Rate: number)
	--=======================================================================================================>

	-- Grab the AccuracyRate Number Vlaue:
	Rate = Enums.Enums.Rate:GetProperty(Rate) :: number

	--=======================================================================================================>

	self._Counters.ZoneCalculations.CounterMax = Rate
	self._Counters.ZoneCalculations.Counter    = 0

	--=======================================================================================================>
end

--===========================================================================================================================>

--- Function that is called to Create/Clear a Tracker Dictionary:
function ZoneCoreModule.UpdateTracker(self: ZoneCore, Tracker: 'Players'|'Items', State: boolean)
	--=======================================================================================================>

	-- If the Tracker is of the 'Players' type:
	if Tracker == 'Players' then

		-- If the State is true, then we are creating a Dictionary to store the Tracker Data:
		if State == true then

		else
		
		end

	end

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ ZONE COMPUTATION METHODS: ]


-- Method called when a ZonePart tag is added or removed:
function ZoneCoreModule.CheckTrigger(self: ZoneCore, Trigger: ZoneTriggers)
	--=======================================================================================================>

	-- Begin Profiling:
	debug.profilebegin(`CheckTrigger: {Trigger}`)

	if Trigger == 'Parts' then
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

	if Trigger == '_Players' then
		--=============================================================================================>

		-- Create Local Arrays for Entered and Exited Objects:
		local EnteredPlayers: {Player}, ExitedPlayers: {Player} = {}, {}

		--=============================================================================================>

		-- Loop through the CurrentPartsInZone:
		for Name: string, TrackedPlayer in self._Trackers.Players do
			--===============================================================================>

			-- Get the Boolean as to where this ItemTracker is currently:
			local PlayerInZonePrevious = TrackedPlayer.InZone

			-- Returns whether any of the Parts of the Character are in the Zone Current Parts:
			local PlayerInZoneCurrent  = TrackedPlayer:DictionaryHasTrackedParts(self._PartData.CurrentPartsInZone)

			if PlayerInZoneCurrent then
				-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
				if PlayerInZonePrevious == false then table.insert(EnteredPlayers, self._PlayerHandler:GetPlayers()[Name]) end
			else
				-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
				if PlayerInZonePrevious == true  then table.insert(ExitedPlayers,  self._PlayerHandler:GetPlayers()[Name]) end
			end

			-- Set the Current Bool of the InZone Variable:
			TrackedPlayer.InZone = PlayerInZoneCurrent

			--===============================================================================>
		end

		--=============================================================================================>

		-- Loop through the EnteredParts:
		for Index: number, Player: Player in ipairs(EnteredPlayers) do self._Events.PlayerEntered:Fire(Player) end

		-- Loop through the ExitedParts:
		for Index: number, Player: Player in ipairs(ExitedPlayers) do self._Events.PlayerExited:Fire(Player) end

		--=============================================================================================>
	end


	if Trigger == 'Players' then
		--=============================================================================================>

		-- Create Local Arrays for Entered and Exited Objects:
		local EnteredPlayers: {Player}, ExitedPlayers: {Player} = {}, {}

		--=============================================================================================>
		
		-- Grab the Players Dictionary:
		local Players: {[string]: Player} = self._PlayerHandler:GetPlayers()
		
		-- Loop through the CurrentPartsInZone:
		for Name: string, TrackedPlayer in self._Trackers.Players do
			--===============================================================================>
			
			-- Get the Boolean as to where this ItemTracker is currently:
			local PlayerInZonePrevious = TrackedPlayer.InZone

			---- Returns whether any of the Parts of the Character are in the Zone Current Parts:
			--local PlayerInZoneCurrent = TrackedPlayer:IsInsideRegion(
			--	nil, self._Properties.ExactRegion_CFrame, self._Properties.ExactRegion_Size
			--)

			-- Returns whether any of the Parts of the Character are in the Zone Current Parts:
			local PlayerInZoneCurrent = TrackedPlayer:IsInsideBoundBox(
				self._Properties.Exact_BoundMin, self._Properties.Exact_BoundMax
			)

			--print('PlayerInZoneCurrent', PlayerInZoneCurrent)

			if PlayerInZoneCurrent then
				-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
				if PlayerInZonePrevious == false then table.insert(EnteredPlayers, Players[Name]) end
			else
				-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
				if PlayerInZonePrevious == true  then table.insert(ExitedPlayers,  Players[Name]) end
			end

			-- Set the Current Bool of the InZone Variable:
			TrackedPlayer.InZone = PlayerInZoneCurrent

			--===============================================================================>
		end

		--=============================================================================================>

		-- Loop through the EnteredParts:
		for Index: number, Player: Player in ipairs(EnteredPlayers) do 
			self._Events.ZoneSignals:Fire(ZoneConstants.ZoneSignalHash.Send['PlayerEntered'], Player)
		end

		-- Loop through the ExitedParts:
		for Index: number, Player: Player in ipairs(ExitedPlayers) do
			self._Events.ZoneSignals:Fire(ZoneConstants.ZoneSignalHash.Send['PlayerExited'], Player)
		end

		--=============================================================================================>
	end

	-- End Profiling:
	debug.profileend()

	--=======================================================================================================>
end

-- Method called when a ZonePart tag is added or removed:
function ZoneCoreModule.CheckZone(self: ZoneCore, Trigger: ZoneTriggers)
	--=======================================================================================================>

	-- Begin Profiling:
	debug.profilebegin(`CheckZone: {Trigger}`)

	if Trigger == 'Parts' then
		--=============================================================================================>

		table.clear(self._PartData.PreviousPartsInZone)

		for Part: BasePart, State: boolean in self._PartData.CurrentPartsInZone do
			self._PartData.PreviousPartsInZone[Part] = State
		end

		table.clear(self._PartData.CurrentPartsInZone)

		--=============================================================================================>

		-- Loop through the ZoneParts that make up the Zone:
		for Index: number, ZonePart: BasePart in ipairs(self._ZoneParts) do
			--===============================================================================>
			-- Get the Results of the Inidividual Part of the Zone:
			local ZonePartResults = self._WorldModel:GetPartBoundsInBox(
				ZonePart.CFrame, ZonePart.Size, self._OverlapParamaters.PartsExcludeList
			)
			--===============================================================================>
			-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
			-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
			for Index: number, Result: Instance in ipairs(ZonePartResults) do
				-- Check to see if the Result is already added, continue if so:
				if self._PartData.CurrentPartsInZone[Result :: BasePart] then continue end
				-- Insert Result to Results Table:
				self._PartData.CurrentPartsInZone[Result :: BasePart] = true
			end
			--===============================================================================>
		end

		--=============================================================================================>
	end
	
	-- End Profiling:
	debug.profileend()

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Method called when a ZonePart tag is added or removed:
function ZoneCoreModule.OnZonePartUpdate(self: ZoneCore, Purpose: 'Add'|'Remove', ZonePart: BasePart)
	--=======================================================================================================>

	-- Boolean on whether the ZonePart is stored or not in the Dictionary:
	local ZonePartIsStored: boolean = if self._ZoneParts[ZonePart] then true else false

	-- If the Purpose is 'Remove', then remove the Part, else add it:
	if Purpose == 'Remove' then
		--===============================================================================================>
	
		-- Client only Extra Check:
		if self._RunScope == 'Client' then
			-- If the ZonePart is in the Array, and is still a descendant of the Game, the only reason for the Tag being removed(probably),
			-- Is because the Server Tags are being updated on that Instance, meaning the client tags here are overwritten:
			if ZonePartIsStored and ZonePart:IsDescendantOf(game) and ZonePart.Parent ~= nil then ZonePart:AddTag(self._Tags.ZonePart); return end
		end

		-- If one is found, then Remove it from the Array:
		if ZonePartIsStored then 
			--================================================================>
			-- Remove the ZonePart from the Dictionary:
			self._ZoneParts[ZonePart] = nil :: any

			-- Update the Zone Region:
			self:UpdateZone('Region')
			-- Update the Zone Overlap:
			self:UpdateZone('Overlap')
			-- Update the Zone Part Connections:
			self:UpdateZone('PartConnections')
			--================================================================>
		else return end

		--===============================================================================================>
	else
		--===============================================================================================>

		-- If one is not found, then Add it to the Array:
		if not ZonePartIsStored then 
			--================================================================>
			-- Insert the ZonePart into the Dict:
			self._ZoneParts[ZonePart] = self:GetZonePartProperties(ZonePart)
			-- Update the Zone Region:
			self:UpdateZone('Region')
			-- Update the Zone Overlap:
			self:UpdateZone('Overlap')
			-- Update the Zone Part Connections:
			self:UpdateZone('PartConnections')
			--================================================================>
		else return end

		--===============================================================================================>
	end

	--=======================================================================================================>

	-- Determine whether the ZoneParts are all Blocks:
	self._Properties.AllZonePartsAreBlocks = Regions:ArePartsAllBlocks(self:GetZonePartsArray(self._ZoneParts))

	-- Set the boolean to true to Update the Attribute Properties in Serial:
	self._Updates.Parts = true

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Method called on the PostSimulation (Heartbeat) RunService Event:
function ZoneCoreModule.OnPostSimulation(self: ZoneCore, Type: 'Sync'|'Desync', DeltaTime: number)
	--=======================================================================================================>

	-- If the Region Boolean is true, then update all the Attributes:
	if self._Updates.Region then
		--================================================================================>
		-- Set the Boolean to false now that all the Attributes have been updated:
		self._Updates.Region = false
		--================================================================================>
		self._CoreActor.Properties:SetAttribute('Region_Size',   self._Properties.Region_Size)
		self._CoreActor.Properties:SetAttribute('Region_CFrame', self._Properties.Region_CFrame)
		--================================================================================>
		self._CoreActor.Properties:SetAttribute('ExactRegion_Size',   self._Properties.ExactRegion_Size)
		self._CoreActor.Properties:SetAttribute('ExactRegion_CFrame', self._Properties.ExactRegion_CFrame)
		--================================================================================>
		self._CoreActor.Properties:SetAttribute('Volume',   self._Properties.Volume)
		--================================================================================>
		self._CoreActor.Properties:SetAttribute('BoundMin',   self._Properties.BoundMin)
		self._CoreActor.Properties:SetAttribute('BoundMax',   self._Properties.BoundMax)
		--================================================================================>
	end

	-- If the Parts Boolean is true, then update all the Attributes:
	if self._Updates.Parts then
		--================================================================================>
		-- Set the Boolean to false now that all the Attributes have been updated:
		self._Updates.Parts = false
		--================================================================================>
		self._CoreActor.Properties:SetAttribute('AllZonePartsAreBlocks', self._Properties.AllZonePartsAreBlocks)
		--================================================================================>
	end

	--=======================================================================================================>
end

-- Method called on PostSimulation, PostRender, or PreSimulation RunService Event:
function ZoneCoreModule.OnSimulation(self: ZoneCore, Type: 'Sync'|'Desync', DeltaTime: number)
	--=======================================================================================================>

	if Type == 'Sync' then 
		--==============================================================================================>

		--==============================================================================================>
	else

		--==============================================================================================>

		-- Cache Previous Active Status:
		local ActiveStatus = self._Active

		-- If the Zone was Active Previously (Via ActiveStatus) and is now Deactivated, clear the PartData Tables:
		if self._Active == false and ActiveStatus == true then 
			table.clear(self._PartData.CurrentPartsInZone)
			table.clear(self._PartData.PreviousPartsInZone)
		end

		-- If the Zone is not Active, return and dont do any Checks:
		if self._Active == false then return end

		--==============================================================================================>

		-- If the Counter is not at max, return to allow for varied update checking/polling:
		-- Checks every number interval as set in the Counters Table. 
		if not Utility:RateLimiter(self._Counters.ZoneCalculations, DeltaTime) then return end
			
		-- Loop through the ActiveTriggers Dictionary, checking the State of whether its Active:
		-- If it is Active, Call the CheckZone Method for that Trigger, followed by calling the CheckTrigger Method:
		for Trigger: ZoneTriggers, State: boolean in pairs(self._ActiveTriggers) do
			if State == true then self:CheckZone(Trigger); self:CheckTrigger(Trigger) end
		end

		--==============================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ INDEXER FUNCTIONS: ]


-- Create the MetaIndex function:
function ZoneCoreModule.__index(self: ZoneCore, Index: string): any
	--=======================================================================================================>
	-- Specific Indexing:
	--=======================================================================================================>
	if Index == 'Container' then return self._Container end
	--=======================================================================================================>
	if self._Properties[Index] then return self._Properties[Index] end
	--=======================================================================================================>
	if Index == '_Active' or Index == 'Active' then return self._States.Active end
	--=======================================================================================================>
	if Index == '_PlayerHandler' then return self._Classes.PlayerHandler end
	--=======================================================================================================>
	if Index == '_Holders' then   return self._Instances.Holders end
	--=======================================================================================================>
	-- If Index is in the immediate Module tree, return that value:			
	if ZoneCoreModule[Index] then return ZoneCoreModule[Index] end
	--=======================================================================================================>
	-- Return False if all else fails!
	return false 
	--=======================================================================================================>
end

-- Create the New Index function:
function ZoneCoreModule.__newindex(self: ZoneCore, Index: string, Value: any)
	--=======================================================================================================>
	error(`"{Index}" cannot be added to ZoneCore`)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(ZoneCoreModule)

--===========================================================================================================================>