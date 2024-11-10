--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>
-- [Name]:
-- ZonerModule

-- [Author]:
-- IISato

-- [Start]:
-- July 12, 2024

-- [Version]:
-- August 6, 2024
-- 0.1.1

-- [Description]:
-- Based on the ZonePlus Module by Nanoblox:
-- https://devforum.roblox.com/t/zoneplus-v320-construct-dynamic-zones-and-effectively-determine-players-and-parts-within-their-boundaries/1017701
-- Based on:  Version: 3.2.0

-- This Module acts as new version of the ZoneController Module.
-- Basically a Zone Handler meant to be required once:
--===========================================================================================================================>

-- [Class Dependencies]:

-- PlayerHandler | by: IISato              | IISato Original
-- TrackedItem   | by: IISato              | IISato Original
-- WorldModel    | by: IISato              | IISato Rewrite (ForeverHD)
-- Zone          | by: IISato              | IISato Original

-- [Utility Dependencies]:

-- Trove      | by: Stephen Leitnick       | IISato TypeChecked
-- GoodSignal | by: stravant & sleitnick   | IISato TypeChecked
-- Enums      | by: IISato                 | IISato Rewrite (ForeverHD)
-- Utility    | by: IISato                 | IISato Original
-- Regions    | by: IISato                 | IISato Original

--===========================================================================================================================>

-- Define Module table
local ZonerModule: ZonerModule = {} :: ZonerModule
-- Set the Meta Index:
ZonerModule.__index = ZonerModule

--===========================================================================================================================>
--[ SERVICES: ]


-- Get the needed Services for the following Code:
local RunService = game:GetService('RunService')

--===========================================================================================================================>

-- Require the Trove Module for Cleanup:
local Trove      = require(script.Classes.Utilities.Trove);
-- Require the Utility Module:
local Utility    = require(script.Classes.Utilities.Utility.Classes.Get);
-- Require the ZoneUtility:
local Regions    = require(script.Classes.Utilities.Regions);
-- Require the Constants Module:
local Constants  = require(script.Children.Constants);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types.ZonerTypes)

-- The Main Enums Module Type:
-- The Enums Variable Type:
export type ZonerModule   = TypeDefinitions.ZonerModule
export type ZonerHolder   = TypeDefinitions.ZonerHolder
export type ZonerActor    = TypeDefinitions.ZonerActor
export type ZonerGroup    = TypeDefinitions.ZonerGroup

export type Zoner         = TypeDefinitions.Zoner

export type ZoneContainer = TypeDefinitions.ZoneContainer
export type ZoneCollector = TypeDefinitions.ZoneCollector
export type ZoneSettings  = TypeDefinitions.ZoneSettings
export type Zone          = TypeDefinitions.Zone

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- Constructor Function for this individual object:
function ZonerModule._Start(): Zoner
	--=======================================================================================================>

	-- Set a Memory Category for this Zoner:
	debug.setmemorycategory('Zoner')

	--=======================================================================================================>

	-- Define Data
	local ZonerData: TypeDefinitions.ZonerMetaData = {
		--====================================================>
		_Trove = Trove.New();
		--====================================================>
		_RunScope = if RunService:IsServer() then 'Server' else 'Client';
		--====================================================>
		_ZoneModule = require(script.Classes.Core.Zone);
		-- Require the Enum2 Module for Custom Enums:
		-- For referencing the Enums from other scripts:
		_Enum =  require(script.Classes.Utilities.Enums).Enums;
		--====================================================>
		_SettingsFolder = script:WaitForChild('Settings');
		--====================================================>
		_ZonerHolders  = {};
		--====================================================>
		_Zones = {};
		--====================================================>
		_Initialized = script:GetAttribute('Initialized') or false
		--====================================================>
	} :: TypeDefinitions.ZonerMetaData

	--=======================================================================================================>

	-- if the Initialized Attribute is false, set the Script's Attribute to true:
	if ZonerData._Initialized == false then script:SetAttribute('Initialized', true) end

	-- Exetend the Trove to make a Trove Specific For Zones:
	ZonerData._ZoneTrove = ZonerData._Trove:Extend()

	-- Construct the PlayerHandler:
	ZonerData._PlayerHandler = ZonerData._Trove:Construct(require(script.Classes.Core.Plagger), false)

	-- Default Zone Settings to reuse:
	ZonerData._DefaultZoneSettings = {
		DetectionCoverage = ZonerData._Enum.DetectionCoverage.Center,
		DetectionMethod   = ZonerData._Enum.DetectionMethod.Automatic,
		DetectionMode     = ZonerData._Enum.DetectionMode.Full,
		Simulation        = ZonerData._Enum.Simulation.PostSimulation;
		Execution         = ZonerData._Enum.Execution.Parallel;
		Bounds            = ZonerData._Enum.Bounds.Automatic;
		Rate              = ZonerData._Enum.Rate.Fast;

		ManualStepping = false;
	}

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(ZonerData, ZonerModule)

	-- Start the Inventory:
	ZonerData:_Initialize()

	--=======================================================================================================>

	-- Return the MetaTable Data
	return ZonerData

	--=======================================================================================================>
end

-- Destroyer Function which clears the entirity of the Data for the Object:
function ZonerModule.Destroy(self: Zoner)
	--=======================================================================================================>

	-- Clean with Trove
	if self._Trove then self._Trove:Destroy() end

	---- Clear all self data:
	--for Index, Data in pairs(self) do self[Index] = nil end

	---- Set the Metatable to nil
	--setmetatable(self :: any, nil)	

	--=======================================================================================================>
end

--===========================================================================================================================>


-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZonerModule._Initialize(self: Zoner)
	for Index: number, Function: string in ipairs({'_SetData', '_SetEvents'}) do self[Function](self) end
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZonerModule._SetData(self: Zoner)
	--=======================================================================================================>

	-- Check if a Folder named 'Zoners' already exists:
	local ZonerPointer = script:FindFirstChild(`ZonerPointer:{self._RunScope}`, false)

	-- If no ZonersPointer was found for the RunScope, create one:
	if not ZonerPointer then
		ZonerPointer = self._Trove:Construct(Instance, 'ObjectValue')
		ZonerPointer.Name = `ZonerPointer:{self._RunScope}`
		ZonerPointer.Parent = script
	end

	if not ZonerPointer.Value then
		-- If one Already Exists, set the reference to it, if not, construct a new Folder:
		self._ZonerFolder = self._Trove:Construct(Instance, 'Folder')
		-- Set ZonersFolder Parent to nil for no replication:
		self._ZonerFolder.Parent = nil
		-- Name said Folder (again possibly):
		self._ZonerFolder.Name = `Zoner:{self._RunScope}` :: any

		-- Set a Counter to Keep Track of the Zones Created:
		self._ZonerFolder:SetAttribute('ZoneCounter', 0)

		local HoldersFolder: Folder = Instance.new('Folder')
		HoldersFolder.Name = 'Holders'
		HoldersFolder.Parent = self._ZonerFolder

		--local IdsFolder: Configuration = Instance.new('Configuration')
		--IdsFolder.Name = 'Ids'
		--IdsFolder.Parent = self._ZonerFolder

		if self._RunScope == 'Server' then
			-- Boolean to check whether the Module is under ServerScriptService, or ServerStorage:
			local ScriptInServerOnlyLocation: boolean = 
				script:IsDescendantOf(game.ServerScriptService) or
				script:IsDescendantOf(game.ServerStorage)

			-- Set ZonersFolder Parent to the Script if the Script is a descendant of a Server Service, else set to Server Service:
			self._ZonerFolder.Parent = if ScriptInServerOnlyLocation then script else game.ServerScriptService
		else
			-- Set ZonersFolder Parent to the Script:
			self._ZonerFolder.Parent = script
		end

		-- Set the ObjectValue to Point to the Folder:
		ZonerPointer.Value = self._ZonerFolder
	else
		self._ZonerFolder = ZonerPointer.Value
	end

	-- Check Settings and if needed, Correct, Settings:
	do
		if not self._SettingsFolder then error('Dont delete the Settings Folder on Zoner') end

		if self._SettingsFolder:GetAttribute('ZonerMaxActorCapacity') == nil then
			self._SettingsFolder:SetAttribute('ZonerMaxActorCapacity', 5)
		elseif self._SettingsFolder:GetAttribute('ZonerMaxActorCapacity') < 1 then
			self._SettingsFolder:SetAttribute('ZonerMaxActorCapacity', 5)
		end

		if self._SettingsFolder:GetAttribute('ZonerMaxGroupCapacity') == nil then
			self._SettingsFolder:SetAttribute('ZonerMaxGroupCapacity', 10)
		elseif self._SettingsFolder:GetAttribute('ZonerMaxGroupCapacity') < 1 then
			self._SettingsFolder:SetAttribute('ZonerMaxGroupCapacity', 10)
		end

		if self._SettingsFolder:GetAttribute('ZonerMaxThreads') == nil then
			self._SettingsFolder:SetAttribute('ZonerMaxThreads', 8)
		elseif self._SettingsFolder:GetAttribute('ZonerMaxThreads') < 1 then
			self._SettingsFolder:SetAttribute('ZonerMaxThreads', 8)
		end
	end

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZonerModule._SetEvents(self: Zoner)
	--=======================================================================================================>

	-- Connect to the AncestryChanged event of the Script:
	-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
	-- We do this to clear the Data in case the Script is Destroyed:
	self._Trove:Connect(script.AncestryChanged, function()
		--====================================================================================>
		if script.Parent == nil or script:IsDescendantOf(game) == false then if self.Destroy then self:Destroy() end end
		--====================================================================================>
	end)

	-- Connect to the GetPropertyChangedSignal(Parent) event of the Script:
	-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
	-- We do this to clear the Data in case the Script is Destroyed:
	self._Trove:Connect(script:GetPropertyChangedSignal('Parent'), function()
		--====================================================================================>
		if script.Parent == nil or script:IsDescendantOf(game) == false then if self.Destroy then self:Destroy() end end
		--====================================================================================>
	end)

	-- Connect to the Destroying event of the Script:
	-- We do this to clear the Data in case the Script is Destroyed:
	self._Trove:Connect(script.Destroying, function()
		--====================================================================================>
		if self.Destroy then self:Destroy() end
		--====================================================================================>
	end)

	--=======================================================================================================>

	-- Connect to the RunService PostSimulation (Heartbeat) event:
	self._Trove:Connect(RunService.PostSimulation, function(DeltaTime: number)
		--====================================================================================>
		self:_OnPostSimulation('Sync', DeltaTime)
		--====================================================================================>
	end)

	--=======================================================================================================>

	-- Connect to the ZoneFolder AttributeChanged Event which is used to detect when a Zone Id Attribute is removed:
	-- When that Zone Id Attribute is removed, we know to Destroy the Zone:

	-- Replaced with Per ZonerHolder Ids:

	--self._Trove:Connect(self._ZonerFolder.Ids.AttributeChanged, function(Identifier: string)
	--	--====================================================================================>
	--	-- Get the Current Boolean State of the Identifier Attribute:
	--	local ZoneState: boolean = self._ZonerFolder.Ids:GetAttribute(Identifier) :: boolean
	--	-- If the ZoneState is not True, meaning false or nil, we remove the Zone:
	--	if ZoneState ~= true then self:_RemoveZone(Identifier) end
	--	--====================================================================================>
	--end)

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Clear out the Data and Remove/Destroy a ZonerHolder thats passed:
function ZonerModule._RemoveZonerHolder(self: Zoner, ZonerHodler: ZonerHolder)
	--=======================================================================================================>

	local HolderType: 'A'|'G' = self._ZonerHolders[ZonerHodler].Type

	self._ZonerHolders[ZonerHodler].IdsEvent:Disconnect()
	self._ZonerHolders[ZonerHodler].IdsEvent = nil :: any
	self._ZonerHolders[ZonerHodler].Holder   = nil :: any
	self._ZonerHolders[ZonerHodler].Capacity = nil :: any
	self._ZonerHolders[ZonerHodler].Type     = nil :: any

	--=======================================================================================================>

	-- If the ZonerHolder is a ZonerActor, send a Message to the Actor to Remove its Folder:
	if HolderType == 'A' then local ZonerActor: Actor = ZonerHodler; ZonerActor:SendMessage('Remove') end

	-- Remove said Instance (ZonerInstance) from the Trove and Destroy it if its not an Actor:
	self._Trove:Remove(ZonerHodler, if HolderType == 'A' then true else false)

	-- Clear its Reference in the ZonerHolders Dictionary:
	self._ZonerHolders[ZonerHodler] = nil :: any

	--=======================================================================================================>

	-- Count and Rename all ZonerHolders of the Type to Reorder them:
	do
		--================================================================================>
		-- Initialize a variable to count ZonerActors:
		local NumberOfHolder: number = 0

		-- Loop through the Dictionary of ZonerHolders and Add all the ZonerGroups up:
		for Holder: Instance, HolderData in self._ZonerHolders do
			-- If Holder is not of the Same Holder Type that we are counting, continue:
			if HolderData.Type ~= HolderType then continue end
			-- Increment the Amount of Holders:
			NumberOfHolder += 1 
			-- Rename the Holder with the new order:
			Holder.Name =
				`Zoner{if HolderType == 'A' then 'Actor' else 'Group'}{NumberOfHolder}` :: string; 
		end
		--================================================================================>
	end

	--=======================================================================================================>
end

-- @Private
-- Function to Get a ZonerHolder, whether a new one, an open one, or an existing one:
function ZonerModule._GetZonerHolder(self: Zoner, Purpose: 'New'|'Open'|'Id', Type: 'G'|'A'|'?', ZoneId: string?): ZonerHolder?
	--=======================================================================================================>
	if Purpose == 'Open' then
		--======================================================================================>
		-- Loop through the Array of ZonerActors:
		for ZonerHolder: ZonerHolder, HolderData in self._ZonerHolders do
			-- If the Type is not the Type Passed, continue:
			if Type ~= '?' then if HolderData.Type ~= Type then continue end end
			-- If the Actor's Min is less than its Max then there is an opening:
			if HolderData.Capacity.Min < HolderData.Capacity.Max then return ZonerHolder else continue end
		end
		--======================================================================================>
	elseif Purpose == 'Id' and ZoneId then
		--======================================================================================>
		-- Loop through the Array of ZonerActors:
		for ZonerHolder: ZonerHolder, HolderData in self._ZonerHolders do
			-- If the Type is not the Type Passed, continue:
			if Type ~= '?' then if HolderData.Type ~= Type then continue end end
			if HolderData.Holder.Ids:GetAttribute(ZoneId) ~= nil then return ZonerHolder end
		end
		--======================================================================================>
	elseif Purpose == 'New' then
		--======================================================================================>
		-- If Type is 'A' then it is a ZonerActor and do things accordingly:
		-- If the Type is 'G' then it is a ZonerGroup:
		if Type == 'A' then
			--===========================================================================>

			-- Grab the Setting Values:
			local ZonerMaxActorCapacity: number = self._SettingsFolder:GetAttribute('ZonerMaxActorCapacity')
			local ZonerMaxThreads:       number = self._SettingsFolder:GetAttribute('ZonerMaxThreads')

			-- Initialize a variable to count ZonerActors:
			local NumberOfZonerActors: number = 0
			local Capacity: NumberRange

			-- Loop through the Dictionary of ZonerHolders and Add all the ZonerActors up:
			for ZonerHolder: ZonerHolder, HolderData in self._ZonerHolders do
				if HolderData.Type == Type then NumberOfZonerActors += 1 end
			end

			-- Clone the ZonerActor from the Actors Folder and Set it to the Variable and Add it to the Trove:
			local ZonerActor: ZonerActor = self._Trove:Clone(script.Holders:WaitForChild('ZonerActor')) :: ZonerActor

			-- Parent the ZoneActor to nil while properties are being changed:
			ZonerActor.Parent = nil
			-- Set the ZoneActor's Name:
			ZonerActor.Name = `ZonerActor{NumberOfZonerActors + 1}` :: any

			--===========================================================================>

			-- Enable the proper Script:
			do 
				-- Cache the Script:
				local UsedScript:   Script = ZonerActor.Scripts:FindFirstChild(`ZoneEngine.{self._RunScope}`) :: Script
				-- Cache the Script:
				local UnusedScript: Script = ZonerActor.Scripts:FindFirstChild(`ZoneEngine.{if self._RunScope == 'Client' then 'Server' else 'Client'}`) :: Script

				-- Destroy the Other RunScope Script:
				UnusedScript:Destroy()

				-- Enable the Correct RunScope Script:
				UsedScript.Enabled = true
			end

			-- Get the Starting Capacity:
			do
				-- If number of zone actors is greater than 7 (8) then increase all Zone Capacity to ZonerMaxThreads:
				if NumberOfZonerActors > ZonerMaxThreads then
					-- Loop through the Dictionary of ZonerHolders and Update all the ZonerActor's Capacity Values:
					for ZonerHolder: ZonerHolder, HolderData in self._ZonerHolders do
						-- If the HolderType is not an Actor Conitnue:
						if HolderData.Type ~= Type then continue end
						-- Update the Holder's Capacity Value:
						HolderData.Capacity = NumberRange.new(HolderData.Capacity.Min, ZonerMaxActorCapacity)
					end
					-- Set the Capacity Variable to a NumberRange:			
					Capacity = NumberRange.new(0, ZonerMaxActorCapacity)
				else
					Capacity = NumberRange.new(0, 1)
				end
			end

			--===========================================================================>

			-- Insert the Holder with Data into the Dictionary:
			self._ZonerHolders[ZonerActor] = {
				-- Set a Reference to the Holder Instance:
				Holder = ZonerActor; 
				-- Set the Holder's Capacity:
				Capacity = Capacity;
				-- Set the Holder's Type:
				Type = 'A';
				-- Connect the Id's Event and Store it in the Table:
				IdsEvent = ZonerActor.Ids.AttributeChanged:Connect(function(Identifier: string)
					--====================================================================================>
					-- Loop through the ZonerHolders Dictionary to find the ZonerActor this Identifier refers to,
					-- without keeping a direct reference to the ZonerActor..
					for Holder, Data in self._ZonerHolders do
						-- If the Holder Type is not an Actor, continue:
						if Data.Type ~= 'A' then continue end
						-- Access the Holder's Ids Table and GetAttribute. If the Attribute Value
						-- returned using the Identifier as Key, is nil, then that means this Ids folder does not have that attribute:
						if Data.Holder.Ids:GetAttribute(Identifier) == nil then continue end
						-- Get the Current Boolean State of the Identifier Attribute:
						local ZoneState: boolean = Data.Holder.Ids:GetAttribute(Identifier) :: boolean
						-- If the ZoneState is not True, meaning false or nil, we remove the Zone:
						if ZoneState == false then self:_RemoveZone(Identifier) end
						-- Break this Loop:
						break
					end
					--====================================================================================>
				end)
			}

			-- Parent the Holder into the ZonerFolder:
			ZonerActor.Parent = self._ZonerFolder.Holders

			--===========================================================================>

			-- Return the new ZonerActor:
			return ZonerActor

			--===========================================================================>
		elseif Type == 'G' then
			--===========================================================================>

			-- Initialize a variable to count ZonerActors:
			local NumberOfZonerGroups: number = 0

			-- Loop through the Dictionary of ZonerHolders and Add all the ZonerGroups up:
			for ZonerHolder: ZonerHolder, HolderData in self._ZonerHolders do
				if HolderData.Type == Type then NumberOfZonerGroups += 1 end
			end

			-- Clone the ZonerActor from the Actors Folder and Set it to the Variable and Add it to the Trove:
			local ZonerGroup: ZonerGroup = self._Trove:Clone(script.Holders:WaitForChild('ZonerGroup')) :: ZonerGroup

			-- Parent the ZonerGroup to nil while properties are being changed:
			ZonerGroup.Parent = nil
			-- Set the ZonerGroup's Name:
			ZonerGroup.Name = `ZonerGroup{NumberOfZonerGroups + 1}` :: any

			--===========================================================================>

			-- Insert the Holder with Data into the Dictionary:
			self._ZonerHolders[ZonerGroup] = {
				-- Set a Reference to the Holder Instance:
				Holder = ZonerGroup; 
				-- Set the Holder's Capacity:
				Capacity = NumberRange.new(0, self._SettingsFolder:GetAttribute('ZonerMaxGroupCapacity'));
				-- Set the Holder's Type:
				Type = 'G';
				-- Connect the Id's Event and Store it in the Table:
				IdsEvent = ZonerGroup.Ids.AttributeChanged:Connect(function(Identifier: string)
					--====================================================================================>
					-- Loop through the ZonerHolders Dictionary to find the ZonerActor this Identifier refers to,
					-- without keeping a direct reference to the ZonerActor..
					for Holder, Data in self._ZonerHolders do
						-- If the Holder Type is not an Actor, continue:
						if Data.Type ~= 'G' then continue end
						-- Access the Holder's Ids Table and GetAttribute. If the Attribute Value
						-- returned using the Identifier as Key, is nil, then that means this Ids folder does not have that attribute:
						if Data.Holder.Ids:GetAttribute(Identifier) == nil then continue end
						-- Get the Current Boolean State of the Identifier Attribute:
						local ZoneState: boolean = Data.Holder.Ids:GetAttribute(Identifier) :: boolean
						-- If the ZoneState is not True, meaning false or nil, we remove the Zone:
						if ZoneState ~= true then self:_RemoveZone(Identifier) end
						-- Break this Loop:
						break
					end
					--====================================================================================>
				end)
			}

			-- Parent the Holder into the ZonerFolder:
			ZonerGroup.Parent = self._ZonerFolder.Holders

			--===========================================================================>

			-- Return the new ZonerGroup:
			return ZonerGroup

			--===========================================================================>
		end
		--======================================================================================>
	end
	--=======================================================================================================>
	-- Return nothing:
	return nil
	--=======================================================================================================>
end

-- @Private
-- Construct and Add a Zone Object to the Zoner's Table and return the Zone:
function ZonerModule._AddZone(self: Zoner, Container: ZoneContainer, ZoneSettings: ZoneSettings): Zone
	--=======================================================================================================>

	-- Create and get a new Unique Identifier string:
	local Identifier: string = `{self._ZonerFolder:GetAttribute('ZoneCounter') + 1}` -- Utility.Identifier(false, false, true, 9)

	-- Check if a Zone with that ID is stored in the Zones Table, if so, warn and return:
	if self._Zones[Identifier] then warn(`Could not Add Zone with Id: "{Identifier}" because Zone already exists!`); return nil :: any end

	--=======================================================================================================>

	local HolderType: 'A'|'G' = if ZoneSettings.Execution == self._Enum.Execution.Serial then 'G' else 'A'

	-- Get either an Open ZonerActor, or a new ZonerActor:
	local ZonerHolder: ZonerHolder = self:_GetZonerHolder('Open', HolderType) or self:_GetZonerHolder('New', HolderType) :: ZonerHolder

	-- Increment the Capacity of the ZonerActor by One to Add the Zone to it:
	self._ZonerHolders[ZonerHolder].Capacity = 
		NumberRange.new(self._ZonerHolders[ZonerHolder].Capacity.Min + 1, self._ZonerHolders[ZonerHolder].Capacity.Max)

	-- Set the Identifier onto the Ids Folder to Store it:
	ZonerHolder.Ids:SetAttribute(Identifier, true)

	-- Update the ZoneCounter Attribute on the ZonerFolder:
	self._ZonerFolder:SetAttribute('ZoneCounter', self._ZonerFolder:GetAttribute('ZoneCounter') + 1)

	--=======================================================================================================>

	-- Construct the Zone Object and add it to the Zones Table with Identifier as the Key:
	self._Zones[Identifier] = self._ZoneTrove:Add(self._ZoneModule.New(
		Container,
		ZoneSettings,
		ZonerHolder,
		self._RunScope,
		Identifier)
	)

	-- Return a REFERENCE to the Zone Object stored in the Table:
	return self._Zones[Identifier] :: any

	--=======================================================================================================>
end

-- @Private
-- Remove a Zone from the Table and Destroy it:
function ZonerModule._RemoveZone(self: Zoner, Identifier: string)
	--=======================================================================================================>
	warn('remove zone!')
	-- Check if a Zone with that ID is stored in the Zones Table, if not, warn and return:
	if not self._Zones[Identifier] then warn(`Could not Remove Zone with Id: "{Identifier}" because Zone was not found!`); return end

	--=======================================================================================================>

	-- Adjust ZonerHolder Capacity/Remove ZonerHolder if Empty:
	do
		--================================================================================>
		-- Find the ZonerHolder which Holds the Zone being Removed:
		local ZonerHolder: ZonerHolder? = self:_GetZonerHolder('Id', '?', Identifier)

		-- If a ZonerHolder is found and Returned and it has a Dictionary Reference:
		if ZonerHolder and self._ZonerHolders[ZonerHolder] then
			-- Update the ZonerHolder's Capacity by decreasing it by 1:
			self._ZonerHolders[ZonerHolder].Capacity = 
				NumberRange.new(math.max(0, self._ZonerHolders[ZonerHolder].Capacity.Min - 1), self._ZonerHolders[ZonerHolder].Capacity.Max)

			-- Set the Identifier Attribute on the Ids Folder to NIL to fully delete it from the Ids folder (currently it woudl be false):
			ZonerHolder.Ids:SetAttribute(Identifier, nil)

			-- If the ZonerHolder Capacity is at Min of 0, meaning Empty, then Remove the ZonerHolder:
			if self._ZonerHolders[ZonerHolder].Capacity.Min == 0 then self:_RemoveZonerHolder(ZonerHolder) end
		end
		--================================================================================>
	end

	--=======================================================================================================>

	-- Remove the Zone Object from the Trove, Destroying it in the Process:
	self._ZoneTrove:Remove(self._Zones[Identifier])

	-- Clear it from the Dictionary:
	self._Zones[Identifier] = nil :: any

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function ZonerModule._RelocateZonerFolder(self: Zoner, Location: Instance?)
	--=======================================================================================================>
	-- If we are running on the Server:
	if self._RunScope == 'Server' then
		-- If Locations is nil, return the 
		if Location then 
			-- Boolean to check whether the Parent Location is under ServerScriptService, ReplicatedStorage, or ServerStorage:
			local IsInOkayLocation = 
				Location:IsDescendantOf(game.ServerScriptService) or
				Location:IsDescendantOf(game.ReplicatedStorage) or 
				Location:IsDescendantOf(game.ServerStorage)
			-- If its not in an Okay Location, Make it Parent Directly to ServerScriptService:
			if not IsInOkayLocation then 
				warn(`ZonerFolder Relocation Failed because Folder was not under a Service`) return 
			end
		else
			Location = script 
		end
		-- Reparent the ZonerFolder:
		self._ZonerFolder.Parent = Location :: Instance
	end
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Method to Construct a New Zone Object and Add it to the Zoner Handler, and then Return the Object:
function ZonerModule.NewZone(self: Zoner, ZoneContainer: ZoneContainer, ZoneSettings: ZoneSettings?): Zone
	--=======================================================================================================>

	-- Assert Statements for Paramaters:
	do
		--=============================================================================================>
		-- Assert whether the Provided Container is of the proper Instance or Table type:
		assert((typeof(ZoneContainer) == "table" or typeof(ZoneContainer) == "Instance"), Constants.Logs.Zoner.ContainerType)

		-- If the Container Type is an Instance, check type of Instance:
		if typeof(ZoneContainer) == "Instance" then 
			-- Assert the Specifics of the Instance Type:
			assert(
				ZoneContainer:IsA('BasePart') or ZoneContainer:IsA('Model') or ZoneContainer:IsA('Folder') or ZoneContainer:IsA('Configuration'),
				Constants.Logs.Zoner.ContainerInstanceType
			)
			-- Assert the Specifics of the Instance Type:
			assert(
				not (ZoneContainer:IsA('Terrain') or ZoneContainer:IsA('Workspace')),
				Constants.Logs.Zoner.ContainerInstanceType
			)
		else
			-- Loop through the Container Table to make sure each Value in the table is an Instance:
			for Index, Unknown in pairs(ZoneContainer) do
				if typeof(Unknown) == "table" then
					if Unknown['CFrame'] and Unknown['Size'] then continue else error(Constants.Logs.Zoner.ContainerBoxTable) end
				elseif typeof(Unknown) == "Instance" then
					if not Unknown:IsA('BasePart') then
						error(Constants.Logs.Zoner.ContainerPartTable1)
					end
				elseif typeof(Unknown) ~= "Instance" then
					error(Constants.Logs.Zoner.ContainerPartTable2)
				end
			end
		end

		if ZoneSettings then
			-- Assert that the DetectionCoverage Number sent is the right Enum value:
			if ZoneSettings.DetectionCoverage then 
				assert(self._Enum.DetectionCoverage:GetName(ZoneSettings.DetectionCoverage) ~= 'Failure', Constants.Logs.Zoner.DetectionCoverage)
			end
			-- Assert that the DetectionCoverage Number sent is the right Enum value:
			if ZoneSettings.DetectionMethod then 
				assert(self._Enum.DetectionMethod:GetName(ZoneSettings.DetectionMethod) ~= 'Failure', Constants.Logs.Zoner.DetectionMethod)
			end
			-- Assert that the DetectionCoverage Number sent is the right Enum value:
			if ZoneSettings.DetectionMode then 
				assert(self._Enum.DetectionMode:GetName(ZoneSettings.DetectionMode) ~= 'Failure', Constants.Logs.Zoner.DetectionMode)
			end
			-- Assert that the Simulation Number sent is the right Enum value:
			if ZoneSettings.Simulation then 
				assert(self._Enum.Simulation:GetName(ZoneSettings.Simulation) ~= 'Failure', Constants.Logs.Zoner.Simulation)
			end
			-- Assert that the Execution Number sent is the right Enum value:
			if ZoneSettings.Execution then 
				assert(self._Enum.Execution:GetName(ZoneSettings.Execution) ~= 'Failure', Constants.Logs.Zoner.Execution)
			end
			-- Assert that the Bounds Number sent is the right Enum value:
			if ZoneSettings.Bounds then 
				assert(self._Enum.Bounds:GetName(ZoneSettings.Bounds) ~= 'Failure', Constants.Logs.Zoner.Bounds)
			end
			-- Assert that the Rate Number sent is the right Enum value:
			if ZoneSettings.Rate then 
				assert(self._Enum.Rate:GetName(ZoneSettings.Rate) ~= 'Failure', Constants.Logs.Zoner.Rate)
			end
			-- Assert that the ManualStepping sent is a boolean:
			if ZoneSettings.ManualStepping then 
				assert(typeof(ZoneSettings.ManualStepping) == 'boolean', Constants.Logs.Zoner.ManualStepping)
			end
		end
		--=============================================================================================>
	end

	--=======================================================================================================>

	-- If no ZoneSettings were sent, we are Filling it out with default values:
	if ZoneSettings then
		-- Loop through the Default Zone Settings and use them to replace any missing settings in the ZoneSettings Table:
		for Key: string, Setting in pairs(self._DefaultZoneSettings) do
			if ZoneSettings[Key] == nil then ZoneSettings[Key] = Setting end
		end
		-- Loop through the Default Zone Settings and use them to replace any missing settings in the ZoneSettings Table:
		for Key: string, Setting in pairs(ZoneSettings) do
			-- Don't do clean for booleans:
			if typeof(Setting) == 'boolean' then continue end
			-- If the Setting is not the Number Version, (ie: they put in the string), convert the String to the Number for that Enum:
			if typeof(Setting) ~= 'number' then ZoneSettings[Key] = self._Enum[Key]:GetValue(Setting) end
		end
	end

	--=======================================================================================================>

	-- Add the Zone to the Zoner's Table and Attributes, and return the Object to the User:
	return self:_AddZone(ZoneContainer, ZoneSettings or self._DefaultZoneSettings)

	--=======================================================================================================>
end

-- @Public
-- Method to Construct a New Zone Object (FROM REGION PARAMATERS) and Add it to the Zoner Handler, and then Return the Object:
function ZonerModule.NewZoneFromRegion(self: Zoner, RegionCFrame: CFrame, RegionSize: Vector3, ZoneSettings: ZoneSettings?): Zone
	--=======================================================================================================>
	-- Create a new Model Instance to act as a Container:
	local Container: Model = Instance.new("Model"); Container.Name = 'ZoneContainer'
	-- Create a Cube of Parts inside the Zone matching the CFrame and Size:
	Regions:CreateCube(Container, RegionCFrame, RegionSize)
	-- If the RegionCFrame has no Rotation, then Make sure if the ZoneSetting is set to PerPart, it is corrected to be BoxExact:
	if RegionCFrame.Rotation:FuzzyEq(CFrame.new()) then
		-- If a ZoneSettings Table was passed and the 
		if ZoneSettings and self._Enum.Bounds:GetValue(ZoneSettings.Bounds) == self._Enum.Bounds.PerPart then
			ZoneSettings.Bounds = self._Enum.Bounds.BoxExact
		end
	end
	--=======================================================================================================>
	-- Return a New Zone Object that has been Relocated:
	return self:NewZone(Container, ZoneSettings):Relocate()
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Method to Construct a New Zone Object and Add it to the Zoner Handler, and then Return the Object:
function ZonerModule.NewZoneCollector(self: Zoner): ZoneCollector
	--=======================================================================================================>

	local ZoneCollector: ZoneCollector = {
		--=================================================>
		-- Create a Unique Id for this Identifier:
		_Id = Utility.Identifier(false, false, true, 5);
		-- Create Dictionary to store Zone Ids:
		_Zones = {} :: {[string]: boolean};
		-- Create a Reference to the Zoner:
		_Zoner = self;
		--=================================================>
	} :: ZoneCollector

	--=======================================================================================================>

	function ZoneCollector.Add(self: ZoneCollector, Zone: Zone, Name: string?)
		--==================================================================================>
		-- Check if the passed Zone is in the Collector, if it is, warn and return:
		if self._Zones[Zone.Identifier] then warn(`Zone: "{Zone.Identifier}" already in Collector: "{self._Id}"`) return end
		--==================================================================================>
		-- Add the Zone's Id to the Collector Zones Dictionary:
		self._Zones[Zone.Identifier] = true
		--==================================================================================>
	end

	function ZoneCollector.Remove(self: ZoneCollector, Zone: Zone, DestroyZone: boolean?)
		--==================================================================================>
		-- Check if the passed Zone is in the Collector, if its not, warn and return:
		if not self._Zones[Zone.Identifier] then warn(`No Zone: "{Zone.Identifier}" found in Collector: "{self._Id}"`) return end
		--==================================================================================>
		-- Remove the Zone's Id from the Collector Zones Dictionary:
		self._Zones[Zone.Identifier] = nil
		-- Remove/Destroy the Zone from the Zoner:
		if DestroyZone then self._Zoner:_RemoveZone(Zone.Identifier) end
		--==================================================================================>
	end

	function ZoneCollector.Get(self: ZoneCollector, Zone: Zone, DestroyZone: boolean?)
		--==================================================================================>
		-- Check if the passed Zone is in the Collector, if its not, warn and return:
		if not self._Zones[Zone.Identifier] then warn(`No Zone: "{Zone.Identifier}" found in Collector: "{self._Id}"`) return end
		--==================================================================================>
		-- Remove the Zone's Id from the Collector Zones Dictionary:
		self._Zones[Zone.Identifier] = nil
		-- Remove/Destroy the Zone from the Zoner:
		if DestroyZone then self._Zoner:_RemoveZone(Zone.Identifier) end
		--==================================================================================>
	end

	-- RISK: Can cause a memory leak if user doesnt destroy the zones and there are no other references to the Zones outside the Script:
	function ZoneCollector.Clear(self: ZoneCollector, DestroyZones: boolean?)
		--==================================================================================>
		-- if DestroyZones is true then remove all the Zones from the Zoner:
		if DestroyZones == true then for ZoneId: string, Status: boolean in self._Zones do self._Zoner:_RemoveZone(ZoneId) end end
		-- Clear the Zones Dictionary:
		table.clear(self._Zones)
		--==================================================================================>
	end

	function ZoneCollector.Destroy(self: ZoneCollector)
		--==================================================================================>
		self:Clear(true)
		--==================================================================================>
	end

	--=======================================================================================================>

	-- Return the Collector and Freeze it:
	return table.freeze(ZoneCollector)

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Method called on the PostSimulation (Heartbeat) RunService Event:
function ZonerModule._OnPostSimulation(self: Zoner, Type: 'Sync'|'Desync', DeltaTime: number)
	--=======================================================================================================>
	-- Loop through all the Zones that are currently Created and Call the Method on them:
	for Id: string, Zone in pairs(self._Zones) do Zone:_OnPostSimulation(Type, DeltaTime) end
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Construct the Zoner Module:
local Zoner: Zoner = ZonerModule._Start()

-- [Notice] can only use the . operator on these functions:
-- Return a table containing the only functions and properties needed by the user:
return table.freeze({
	--==========================================================================>
	-- Pointer Function for the New Zone From Container Method:
	NewFromContainer  = function(ZoneContainer: ZoneContainer, ZoneSettings: ZoneSettings?): Zone 
		return Zoner:NewZone(ZoneContainer, ZoneSettings)
	end;	
	-- Pointer Function for the New Zone From Container Method:
	New               = function(ZoneContainer: ZoneContainer, ZoneSettings: ZoneSettings?): Zone 
		return Zoner:NewZone(ZoneContainer, ZoneSettings) 
	end;
	-- Pointer Function for the New Zone From Region Method:
	NewZoneFromRegion = function(RegionCFrame: CFrame, RegionSize: Vector3, ZoneSettings: ZoneSettings?): Zone 
		return Zoner:NewZoneFromRegion(RegionCFrame, RegionSize, ZoneSettings) 
	end;
	-- Pointer Function for the New Zone From Container Method:
	NewCollector      = function(): ZoneCollector 
		return Zoner:NewZoneCollector() 
	end;
	-- Function to Relocate the ZonerFolder:
	RelocateZonerFolder = function(Location: Instance?) 
		Zoner:_RelocateZonerFolder(Location)
	end;
	--==========================================================================>
	-- Require the Enum2 Module for Custom Enums:
	-- For referencing the Enums from other scripts:
	Enum = Zoner._Enum;
	--==========================================================================>
})

--===========================================================================================================================>