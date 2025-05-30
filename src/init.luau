--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>
-- [Name]:
-- Zoner

-- [Author]:
-- IISato

-- [Start]:
-- July 12, 2024

-- [Version]:
-- August 6, 2024
-- 0.1.2

-- [Description]:
-- Inspired by the ZonePlus Module by Nanoblox:
-- https://devforum.roblox.com/t/zoneplus-v320-construct-dynamic-zones-and-effectively-determine-players-and-parts-within-their-boundaries/1017701
-- Based on:  Version: 3.2.0

-- This Module acts as new version of the ZoneController Module.
-- Basically a Zone Singleton meant to be required once:
--===========================================================================================================================>

-- Set a Memory Category for this:
debug.setmemorycategory('[Zoner]')

-- Define Module table
local Zoner = {}; Zoner.__index = Zoner

--===========================================================================================================================>
--[ DEPENDENCIES: ]


local Constants  = require(`@self/Modules/Internal/Constants`);
local Plagger    = require(`@self/Modules/Internal/Plagger`);
local Utility    = require(`@self/Modules/Internal/Utility`);
local Enums      = require(`@self/Modules/Internal/Enums`);
local Zone       = require(`@self/Modules/Internal/Zone`);

--===========================================================================================================================>
--[ CONSTANTS: ]


-- The RunContext/Scope of the Module:
local RUN_CONTEXT: 'Client'|'Server' = if game:GetService('RunService'):IsServer() then 'Server' else 'Client'

-- Default Collision Group
local ZONER_COLLISION_GROUP: 'Zoner:ZonePart' = 'Zoner:ZonePart'

-- Default capacity limits for ZonerActors and ZonerGroups
local DEF_MAX_ACTOR_CAPACITY = 5;
local DEF_MAX_GROUP_CAPACITY = 10;
local DEF_MAX_THREADS        = 7;

-- Create a default Configs table constant:
local DEFAULT_ZONE_CONFIG = table.freeze({
	DetectionCoverage = Enums.DetectionCoverage.Center,
	DetectionMethod   = Enums.DetectionMethod.Automatic,
	DetectionMode     = Enums.DetectionMode.Point,
	Simulation        = Enums.Simulation.PostSimulation;
	Execution         = Enums.Execution.Parallel;
	Bounds            = Enums.Bounds.Automatic;
	Rate              = Enums.Rate.Fast;

	NoZonePartPropertyListening = false;
	NoZonePartAddedListening    = false;
	ManualStepping              = false;
});

--===========================================================================================================================>
--[ TYPES: ]


-- [ Require Types ]

-- This will inject all types into this context.
local Types = require(script.Types)

-- Import the Public Zone type file because we want documentation and this is the only way I think:
local PublicZone = require(script.Types.PublicZone)

-- [ Register Types ]

-- Zone Holder Type Id string type:
type ZonerHolderTypeId = 'G' | 'A'

type ZoneCollector = {
	--====================================================>
	_Id: string;
	_Zones: {[string]: boolean};
	_Zoner: Zoner;
	--====================================================>
	Add:
		(self: ZoneCollector, Zone: Zone) -> ();
	Remove:
		(self: ZoneCollector, Zone: Zone, DestroyZone: boolean?) -> ();
	Clear:
		(self: ZoneCollector, DestroyZones: boolean?) -> ();
	Destroy:
		(self: ZoneCollector, Zone: Zone) -> ();
	--====================================================>
}

--- Create and Export a public version of the Zone Object:
export type Zone<MetaData = {[any]: any}?> = PublicZone.Zone<MetaData>

--- Export ZoneConfig:
export type ZoneConfig = Types.ZoneConfig

--- Create and Export the Module's Object Type:
export type Zoner = typeof(setmetatable({} :: {
	--====================================================>
	_Initialized: boolean;
	--====================================================>
	_Zones: {[string]: Zone.Zone};
	_Connections: {
		Script_AC:   RBXScriptConnection;
		Script_PCS:  RBXScriptConnection;
		Script_DG:   RBXScriptConnection;
		Zone_Signal: RBXScriptConnection;
	};
	--====================================================>
	_PlayerHandler: Plagger.Plagger;
	_ZoneUpdateEvent: BindableEvent;
	--====================================================>
	_ConfigFolder: typeof(script.Config);
	--====================================================>
	_ZonerFolder: Types.ZonerFolder;
	--====================================================>
	_ZonerHolders: {[Types.ZonerHolder]: 
		{Holder: Types.ZonerHolder; Type: ZonerHolderTypeId; Binded: boolean; Capacity: NumberRange; IdsEvent: RBXScriptConnection}
	};
	--======================================>
}, {} :: typeof(Zoner)))

--===========================================================================================================================>
--[ HELPERS: ]


--[[
Updates Zoner Holder Folder and ZoneHolder Folder Total Zone Attributes

@param Zoner Zoner -- The Zoner instance managing the ZonerHolders.
]]
local function UpdateHolderStatistics(Zoner: Zoner)
	--=======================================================================================================>
	-- TotalZones Variable:
	local TotalZones: number = 0
	-- Loop through the Dictionary of ZonerHolders and Add all the ZonerGroups up:
	for Holder, HolderData in Zoner._ZonerHolders do
		-- Set a Total Zones for that HOLDER Attribute for debugging:
		Holder:SetAttribute('Zone_Total', HolderData.Capacity.Min)
		-- Add the Total Zones:
		TotalZones += HolderData.Capacity.Min
	end
	-- Set the Total Zones Entirely in the Zoner on the Holder Attribute:
	Zoner._ZonerFolder.Holders:SetAttribute('Zone_Total', TotalZones)
	--=======================================================================================================>
end

--[[
Removes and cleans up a ZonerHolder instance.

@param Zoner Zoner -- The Zoner instance managing the ZonerHolders.
@param ZonerHolder Types.ZonerHolder -- The ZonerHolder to be removed.
]]
local function RemoveZonerHolder(Zoner: Zoner, ZonerHolder: Types.ZonerHolder)
	--=======================================================================================================>
	local HolderData = Zoner._ZonerHolders[ZonerHolder]
	local HolderType: ZonerHolderTypeId = HolderData.Type

	HolderData.IdsEvent:Disconnect()
	HolderData.IdsEvent = nil :: any
	HolderData.Holder   = nil :: any
	HolderData.Capacity = nil :: any
	HolderData.Type     = nil :: any
	--=======================================================================================================>

	-- If the ZonerHolder is a ZonerActor, send a Message to the Actor to Remove its Folder:
	if HolderType == 'A' then (ZonerHolder :: Types.ZonerActor):SendMessage('Remove') end
	-- Remove said Instance (ZonerInstance) from the Trove and Destroy it if its not an Actor:	
	if HolderType == 'G' then (ZonerHolder :: Types.ZonerGroup):Destroy() end

	-- Clear its Reference in the ZonerHolders Dictionary:
	Zoner._ZonerHolders[ZonerHolder] = nil :: any

	--=======================================================================================================>

	-- Count and Rename all ZonerHolders of the Type to Reorder them:
	-- Initialize a variable to count ZonerActors:
	local NumberOfHolder: number = 0
	-- Loop through the Dictionary of ZonerHolders and Add all the ZonerGroups up:
	for Holder: Instance, Data in Zoner._ZonerHolders do
		-- If Holder is not of the Same Holder Type that we are counting, continue:
		if Data.Type ~= HolderType then continue end
		-- Increment the Amount of Holders:
		NumberOfHolder += 1 
		-- Rename the Holder with the new order:
		Holder.Name =
			`Zoner{if HolderType == 'A' then 'Actor' else 'Group'}{NumberOfHolder}` :: string; 
	end
	--=======================================================================================================>
end

--[[
Gets an open ZonerHolder with available capacity.

@param Zoner Zoner -- The zoner manager to search within.
@param Type? ZonerHolderTypeId -- Optional type filter ('A' or 'G').

@return Types.ZonerHolder? -- A holder if one is found, otherwise nil.
]]
local function GetOpenZonerHolder(Zoner: Zoner, Type: ZonerHolderTypeId?): Types.ZonerHolder?
	--=======================================================================================================>
	-- Loop through the Array of ZonerActors:
	for ZonerHolder: Types.ZonerHolder, HolderData in Zoner._ZonerHolders do
		-- If the Type is not the Type Passed, continue:
		if Type then if HolderData.Type ~= Type then continue end end
		-- If Holder is not yet Binded, YIELD until it is Binded:
		if HolderData.Binded == false then 
			repeat task.wait() until HolderData.Binded :: boolean == true;
		end
		-- If the Actor's Min is less than its Max then there is an opening:
		if HolderData.Capacity.Min < HolderData.Capacity.Max then return ZonerHolder else continue end
	end
	-- Return nothing cause nothing was found:
	return nil
	--=======================================================================================================>
end

--[[
Gets a ZonerHolder that contains the given zone ID.

@param Zoner Zoner -- The zoner manager.
@param ZoneId string -- The unique zone identifier.
@param Type? ZonerHolderTypeId -- Optional filter on holder type.

@return Types.ZonerHolder? -- A holder if one matches the ID.
]]
local function GetZonerHolderFromId(Zoner: Zoner, ZoneId: string, Type: ZonerHolderTypeId?): Types.ZonerHolder?
	--=======================================================================================================>
	-- Loop through the Array of ZonerActors:
	for ZonerHolder: Types.ZonerHolder, HolderData in Zoner._ZonerHolders do
		-- If the Type is not the Type Passed, continue:
		if Type then if HolderData.Type ~= Type then continue end end
		if HolderData.Holder.Ids:GetAttribute(ZoneId) ~= nil then return ZonerHolder end
	end
	-- Return nothing cause nothing was found:
	return nil
	--=======================================================================================================>
end

--[[
Removes a zone and all associated references.

@param Zoner Zoner -- The Zoner manager instance.
@param Identifier string -- The unique ID of the zone to remove.
]]
local function RemoveZone(Zoner: Zoner, Identifier: string)
	--=======================================================================================================>
	-- Check if a Zone with that ID is stored in the Zones Table, if not, warn and return:
	if not Zoner._Zones[Identifier] then warn(`Could not Remove Zone with Id: "{Identifier}" because Zone was not found!`); return end
	--=======================================================================================================>
	-- Adjust ZonerHolder Capacity/Remove ZonerHolder if Empty:
	do
		--================================================================================>
		-- Find the ZonerHolder which Holds the Zone being Removed:
		local ZonerHolder: Types.ZonerHolder? = GetZonerHolderFromId(Zoner, Identifier)
		-- If a ZonerHolder is found and Returned and it has a Dictionary Reference:
		if ZonerHolder and Zoner._ZonerHolders[ZonerHolder] then
			-- Update the ZonerHolder's Capacity by decreasing it by 1:
			Zoner._ZonerHolders[ZonerHolder].Capacity = 
				NumberRange.new(math.max(0, Zoner._ZonerHolders[ZonerHolder].Capacity.Min - 1), Zoner._ZonerHolders[ZonerHolder].Capacity.Max)
			-- Set the Identifier Attribute on the Ids Folder to NIL to fully delete it from the Ids folder (currently it woudl be false):
			ZonerHolder.Ids:SetAttribute(Identifier, nil)
			-- If the ZonerHolder Capacity is at Min of 0, meaning Empty, then Remove the ZonerHolder:
			if Zoner._ZonerHolders[ZonerHolder].Capacity.Min == 0 then RemoveZonerHolder(Zoner, ZonerHolder) end
		end
		--================================================================================>
	end
	--=======================================================================================================>
	-- Update the Statistics:
	UpdateHolderStatistics(Zoner)
	--=======================================================================================================>
	-- Remove the Zone Object from the Trove, Destroying it in the Process:
	Zoner._Zones[Identifier]:Destroy()
	-- Clear it from the Dictionary:
	Zoner._Zones[Identifier] = nil :: any
	--=======================================================================================================>
end

--[[
Callback handler for when the Attributes on the Ids folder change.
Triggers cleanup if an ID becomes invalidated.

@param Zoner Zoner -- The Zoner manager.
@param Type ZonerHolderTypeId -- Whether it is an Actor or Group.
@param Identifier string -- The attribute key that changed.
]]
local function OnIdsAttributeChanged(Zoner: Zoner, Type: ZonerHolderTypeId, Identifier: string)
	--=======================================================================================================>
	-- Loop through the ZonerHolders Dictionary to find the ZonerActor this Identifier refers to,
	-- without keeping a direct reference to the ZonerActor..
	for Holder, Data in Zoner._ZonerHolders do
		--====================================================================================>
		-- If the Holder Type is not an Actor, continue:
		if Data.Type ~= Type then continue end
		-- Access the Holder's Ids Table and GetAttribute. If the Attribute Value
		-- returned using the Identifier as Key, is nil, then that means this Ids folder does not have that attribute:
		if Data.Holder.Ids:GetAttribute(Identifier) == nil then continue end
		-- Get the Current Boolean State of the Identifier Attribute:
		local ZoneState: boolean = Data.Holder.Ids:GetAttribute(Identifier) :: boolean
		-- If the ZoneState is not True, meaning false or nil, we remove the Zone:
		if Type == 'A' then
			if ZoneState == false then RemoveZone(Zoner, Identifier) end
		else
			if ZoneState ~= true  then RemoveZone(Zoner, Identifier) end
		end
		-- Break this Loop:
		break
		--====================================================================================>
	end
	--=======================================================================================================>
end

--[[
Creates two folders for organizing zones and their identifiers.

@param Parent Instance -- The parent instance to parent the folders to.

@return Folder, Configuration -- The zones folder and ids folder.
]]
local function CreateZoneFolders(): (Folder, Configuration)
	--=======================================================================================================>
	local ZonesFolder = Instance.new('Folder')
	ZonesFolder.Name = 'Zones'
	local IdsFolder = Instance.new('Configuration')
	IdsFolder.Name = 'Ids'
	return ZonesFolder, IdsFolder
	--=======================================================================================================>
end

--[[
Creates a new ZonerHolder for Zones, either a Group or Actor.

@param Zoner Zoner -- The Zoner context.
@param Type ZonerHolderTypeId -- The holder type ('A' or 'G').

@return Types.ZonerHolder -- The new ZonerHolder instance.
]]
local function NewZonerHolder(Zoner: Zoner, Type: ZonerHolderTypeId): Types.ZonerHolder
	--=======================================================================================================>
	assert(Type == 'A' or Type == 'G', `'NewZonerHolder' 'Type' was not A or G`)
	--=======================================================================================================>
	-- If Type is 'A' then it is a ZonerActor and do things accordingly:
	-- If the Type is 'G' then it is a ZonerGroup:
	if Type == 'A' then
		--===========================================================================>
		-- Grab the Config Values:
		local ZonerMaxActorCapacity: number = Zoner._ConfigFolder:GetAttribute('ZonerMaxActorCapacity')
		local ZonerMaxThreads:       number = Zoner._ConfigFolder:GetAttribute('ZonerMaxThreads')

		-- Initialize a variable to count ZonerActors:
		local NumberOfZonerActors: number = 0
		local Capacity: NumberRange

		-- Loop through the Dictionary of ZonerHolders and Add all the ZonerActors up:
		for ZonerHolder: Types.ZonerHolder, HolderData in Zoner._ZonerHolders do
			if HolderData.Type == Type then NumberOfZonerActors += 1 end
		end

		-- If number of zone actors is greater than 7 (8) then increase all Zone Capacity to ZonerMaxThreads:
		if NumberOfZonerActors == ZonerMaxThreads then

			Zoner._ConfigFolder:SetAttribute('ZonerMaxActorCapacity', ZonerMaxActorCapacity + 1)

			ZonerMaxActorCapacity = Zoner._ConfigFolder:GetAttribute('ZonerMaxActorCapacity')

			-- Loop through the Dictionary of ZonerHolders and Update all the ZonerActor's Capacity Values:
			for ZonerHolder: Types.ZonerHolder, HolderData in Zoner._ZonerHolders do
				-- If the HolderType is not an Actor Conitnue:
				if HolderData.Type ~= Type then continue end
				-- Update the Holder's Capacity Value:
				HolderData.Capacity = NumberRange.new(HolderData.Capacity.Min, ZonerMaxActorCapacity)
			end

			-- Will be open because above we are increasing all the Zones total capacity by one:
			return GetOpenZonerHolder(Zoner, 'A') :: Types.ZonerHolder
		end

		-- Clone the ZonerActor from the Actors Folder and Set it to the Variable and Add it to the Trove:
		local ZonerActor: Types.ZonerActor = script.Holders:WaitForChild('ZonerActor'):Clone() :: Types.ZonerActor
		-- Parent the ZoneActor to nil while properties are being changed:
		-- Set the ZoneActor's Name:
		ZonerActor.Parent, ZonerActor.Name = script.Holders, `ZonerActor{NumberOfZonerActors + 1}`

		-- Create the ZonesFolder 'Folder' and IdsFolder 'Configuration'
		local ZonesFolder, IdsFolder = CreateZoneFolders()
		ZonesFolder.Parent, IdsFolder.Parent = ZonerActor, ZonerActor

		--===========================================================================>

		-- Enable the proper Script:
		do 
			-- Cache the Script:
			local UsedScript:   Script = 
				ZonerActor.Scripts:FindFirstChild(`ZoneEngine.{RUN_CONTEXT}`) :: Script
			-- Cache the Script:
			local UnusedScript: Script = 
				ZonerActor.Scripts:FindFirstChild(`ZoneEngine.{if RUN_CONTEXT == 'Client' then 'Server' else 'Client'}`) :: Script

			-- Destroy the Other RunScope Script:
			UnusedScript:Destroy()

			-- Enable the Correct RunScope Script:
			UsedScript.Enabled = true

		end

		-- Get the Starting Capacity:
		do
			-- If number of zone actors is greater than 7 (8) then increase all Zone Capacity to ZonerMaxThreads:
			if NumberOfZonerActors > (ZonerMaxThreads - 1) then
				-- Loop through the Dictionary of ZonerHolders and Update all the ZonerActor's Capacity Values:
				for ZonerHolder: Types.ZonerHolder, HolderData in Zoner._ZonerHolders do
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
		Zoner._ZonerHolders[ZonerActor] = {
			-- Set a Reference to the Holder Instance:
			Holder = ZonerActor; 
			-- Set the Holder's Capacity:
			Capacity = Capacity;
			-- Whether its binded:
			Binded = false;
			-- Set the Holder's Type:
			Type = 'A';
			-- Connect the Id's Event and Store it in the Table:
			IdsEvent = ZonerActor.Ids.AttributeChanged:Connect(function(Attribute: string)
				OnIdsAttributeChanged(Zoner, 'A', Attribute)
			end)
		}

		-- Wait for the ZonerActor to have its Binded Attribute as true, meaning the script had
		-- enough time to execute at its location before parenting it to the new Location:
		repeat task.wait() until ZonerActor:GetAttribute('Binded') == true;
		-- Parent the Holder into the ZonerFolder:
		ZonerActor.Parent = Zoner._ZonerFolder.Holders;

		--===========================================================================>

		-- Return the new ZonerActor:
		return ZonerActor

		--===========================================================================>
	else
		--===========================================================================>

		-- Initialize a variable to count ZonerActors:
		local NumberOfZonerGroups: number = 0

		-- Loop through the Dictionary of ZonerHolders and Add all the ZonerGroups up:
		for ZonerHolder: Types.ZonerHolder, HolderData in Zoner._ZonerHolders do
			if HolderData.Type == Type then NumberOfZonerGroups += 1 end
		end

		-- Clone the ZonerGroup from the Actors Folder and Set it to the Variable and Add it to the Trove:
		local ZonerGroup: Types.ZonerGroup = script.Holders:WaitForChild('ZonerGroup'):Clone() :: Types.ZonerGroup
		-- Parent the ZonerGroup to nil while properties are being changed:
		-- Set the ZonerGroup's Name:
		ZonerGroup.Parent, ZonerGroup.Name = nil, `ZonerGroup{NumberOfZonerGroups + 1}` :: any

		-- Create the ZonesFolder 'Folder' and IdsFolder 'Configuration'
		local ZonesFolder, IdsFolder = CreateZoneFolders()
		ZonesFolder.Parent, IdsFolder.Parent = ZonerGroup, ZonerGroup
		--===========================================================================>

		-- Insert the Holder with Data into the Dictionary:
		Zoner._ZonerHolders[ZonerGroup] = {
			-- Set a Reference to the Holder Instance:
			Holder = ZonerGroup; 
			-- Set the Holder's Capacity:
			Capacity = NumberRange.new(0, Zoner._ConfigFolder:GetAttribute('ZonerMaxGroupCapacity'));
			-- Auto Bind:
			Binded = true;
			-- Set the Holder's Type:
			Type = 'G';
			-- Connect the Id's Event and Store it in the Table:
			IdsEvent = ZonerGroup.Ids.AttributeChanged:Connect(function(Attribute: string)
				OnIdsAttributeChanged(Zoner, 'G', Attribute)
			end)
		}
		-- Parent the Holder into the ZonerFolder:
		ZonerGroup.Parent = Zoner._ZonerFolder.Holders

		--===========================================================================>

		-- Return the new ZonerGroup:
		return ZonerGroup

		--===========================================================================>
	end
	--=======================================================================================================>
end

--[[
Adds a new Zone instance into the Zoner registry.

@param Zoner Zoner -- The zoner instance.
@param Container ZoneContainer -- What defines the zone bounds (Instance or table).
@param ZoneConfig ZoneConfig -- Configs controlling detection behavior.

@return Zone.Zone -- The created and tracked zone.
]]
local function AddZone(Zoner: Zoner, Container: Types.ZoneContainer, ZoneConfig: Types.ZoneConfig): Zone.Zone
	--=======================================================================================================>

	-- Cache the ZonerFolder:
	local ZonerFolder = Zoner._ZonerFolder
	-- Cache the Id_Counter Number:
	local Id_Counter: number = ZonerFolder:GetAttribute('Id_Counter') :: number
	-- Create and get a new Unique Identifier string:
	local Identifier: string = `{Id_Counter + 1}`

	-- Check if a Zone with that ID is stored in the Zones Table, if so, warn and return:
	if Zoner._Zones[Identifier] then warn(`Could not Add Zone with Id: "{Identifier}" because Zone already exists!`); return nil :: any end

	-- Update teh Id_Counter so that new Zones can be created:
	ZonerFolder:SetAttribute('Id_Counter', tonumber(Identifier))

	--=======================================================================================================>

	-- Get the HolderType based on Execution Config:
	local HolderType: ZonerHolderTypeId = if ZoneConfig.Execution == Enums.Execution.Serial then 'G' else 'A'

	-- Get either an Open ZonerActor, or a new ZonerActor:
	-- Boolean to whether theres a new ZonerHolder or not:
	local ZonerHolder, MakingNewZonerHolder do 
		-- Check if theres an Open ZonerHolder, set it to the variable if so:
		ZonerHolder = GetOpenZonerHolder(Zoner, HolderType) :: Types.ZonerHolder
		-- If there is no Open ZonerHolder, make a new one, and set the MakingNew variable to true:
		if not ZonerHolder then ZonerHolder, MakingNewZonerHolder = NewZonerHolder(Zoner, HolderType), true end
	end

	--=======================================================================================================>

	-- Increment the Capacity of the ZonerActor by One to Add the Zone to it:
	Zoner._ZonerHolders[ZonerHolder].Capacity = 
		NumberRange.new(Zoner._ZonerHolders[ZonerHolder].Capacity.Min + 1, Zoner._ZonerHolders[ZonerHolder].Capacity.Max)

	-- Set the Identifier onto the Ids Folder to Store it:
	ZonerHolder.Ids:SetAttribute(Identifier, true)

	-- If we have made a new ZonerHolder, then set its 'Binded' variable to true, after the initial Capacity has been Set:
	if MakingNewZonerHolder then Zoner._ZonerHolders[ZonerHolder].Binded = true; end

	--=======================================================================================================>

	-- Update the Statistics:
	UpdateHolderStatistics(Zoner)

	--=======================================================================================================>

	-- Construct the Zone Object and add it to the Zones Table with Identifier as the Key:
	Zoner._Zones[Identifier] = Zone.New(Container, ZoneConfig, ZonerHolder, Identifier)

	-- Return a REFERENCE to the Zone Object stored in the Table:
	return Zoner._Zones[Identifier] :: any

	--=======================================================================================================>
end

--[[
Moves the internal Zoner folder to a new location in the hierarchy.

@param Zoner Zoner -- The zoner manager.
@param Location? Instance -- The new parent (must be in a safe location).

@return "Success" | "Failure" -- Whether relocation succeeded.
]]
local function RelocateZonerFolder(Zoner: Zoner, Location: Instance?): 'Success' | 'Failure'
	--=======================================================================================================>
	-- If we are running on the Server:
	if RUN_CONTEXT == 'Server' then
		-- If Locations is nil, return the 
		if Location then 
			-- Boolean to check whether the Parent Location is under ServerScriptService, ReplicatedStorage, or ServerStorage:
			local IsInOkayLocation = 
				Location:IsDescendantOf(game.ServerScriptService) or
				Location:IsDescendantOf(game.ReplicatedStorage) or 
				Location:IsDescendantOf(game.ServerStorage)
			-- If its not in an Okay Location, Make it Parent Directly to ServerScriptService:
			if not IsInOkayLocation then 
				warn(`ZonerFolder Relocation Failed because Folder was not under a Service`); return 'Failure' 
			end
		else
			Location = script 
		end
		-- Reparent the ZonerFolder:
		Zoner._ZonerFolder.Parent = Location :: Instance
		return 'Success'
	else
		return 'Failure'
	end
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


--[[
Initializes the Zoner singleton and sets up folder structure, troves, Configs, events, and replication systems.

@return Zoner -- The constructed Zoner instance.
]]
function Zoner._Start(): Zoner
	--=======================================================================================================>

	-- Set a Memory Category for this Zoner:
	debug.setmemorycategory('[Zoner]')

	--=======================================================================================================>

	-- Define Data
	local ZonerData = {
		--====================================================>
		_ConfigFolder = script:WaitForChild('Config') :: typeof(script.Config);
		--====================================================>
		_ZonerHolders  = {} :: {[Types.ZonerHolder]: 
			{Holder: Types.ZonerHolder; Type: ZonerHolderTypeId; Binded: boolean; Capacity: NumberRange; IdsEvent: RBXScriptConnection}
		};
		_Zones = {} :: {[string]: Zone.Zone};
		_Connections   = {} :: {
			Script_AC:   RBXScriptConnection;
			Script_PCS:  RBXScriptConnection;
			Script_DG:   RBXScriptConnection;
			Zone_Signal: RBXScriptConnection;
		};
		--====================================================>
		_PlayerHandler       = Plagger.New(false);
		_ZoneUpdateEvent     = (script:WaitForChild('Events'):FindFirstChild('Zone_Update') or Instance.new('BindableEvent')) :: BindableEvent;
		--====================================================>
		_Initialized = script:GetAttribute('Initialized') :: boolean or false;
		--====================================================>
	}

	--=======================================================================================================>

	-- Check Configs and if needed, Correct, Configs:
	if not ZonerData._ConfigFolder then error('Dont delete the Config Folder on Zoner') end

	Utility.EnsureConfig(ZonerData._ConfigFolder, 'ZonerMaxActorCapacity', DEF_MAX_ACTOR_CAPACITY)
	Utility.EnsureConfig(ZonerData._ConfigFolder, 'ZonerMaxGroupCapacity', DEF_MAX_GROUP_CAPACITY)
	Utility.EnsureConfig(ZonerData._ConfigFolder, 'ZonerMaxThreads',       DEF_MAX_THREADS)

	--=======================================================================================================>

	-- if the Initialized Attribute is false, set the Script's Attribute to true:
	if ZonerData._Initialized == false then script:SetAttribute('Initialized', true) end

	--=======================================================================================================>

	-- Create a Bindable Event for this Actor Group for Zone Signals:
	-- Better than BindableEvents per Zone:
	ZonerData._ZoneUpdateEvent.Name = 'Zone_Update'
	ZonerData._ZoneUpdateEvent.Parent = script:WaitForChild('Events')

	--=======================================================================================================>

	-- Check if a Folder named 'Zoners' already exists:
	local ZonerPointer: ObjectValue = script:FindFirstChild(`ZonerPointer:{RUN_CONTEXT}`, false) or Instance.new('ObjectValue') :: ObjectValue
	-- If no ZonersPointer was found for the RunScope, create one:
	ZonerPointer.Name = `ZonerPointer:{RUN_CONTEXT}`
	ZonerPointer.Parent = script

	if not ZonerPointer.Value then
		-- If one Already Exists, set the reference to it, if not, construct a new Folder:
		ZonerData._ZonerFolder = Instance.new('Folder') :: Types.ZonerFolder
		-- Set ZonersFolder Parent to nil for no replication:
		ZonerData._ZonerFolder.Parent = nil
		-- Name said Folder (again possibly):
		ZonerData._ZonerFolder.Name = `Zoner:{RUN_CONTEXT}` :: any

		-- Set a Counter to Keep Track of the Zones Created:
		ZonerData._ZonerFolder:SetAttribute('Id_Counter', 0)

		local HoldersFolder: Folder = Instance.new('Folder')
		HoldersFolder.Name = 'Holders'
		HoldersFolder.Parent = ZonerData._ZonerFolder

		if RUN_CONTEXT == 'Server' then
			-- Boolean to check whether the Module is under ServerScriptService, or ServerStorage:
			local ScriptInServerOnlyLocation: boolean = 
				script:IsDescendantOf(game.ServerScriptService) or
				script:IsDescendantOf(game.ServerStorage)
			-- Set ZonersFolder Parent to the Script if the Script is a descendant of a Server Service, else set to Server Service:
			ZonerData._ZonerFolder.Parent = if ScriptInServerOnlyLocation then script else game.ServerScriptService
		else
			-- Set ZonersFolder Parent to the Script:
			ZonerData._ZonerFolder.Parent = script
		end
		-- Set the ObjectValue to Point to the Folder:
		ZonerPointer.Value = ZonerData._ZonerFolder
	else
		ZonerData._ZonerFolder = ZonerPointer.Value  :: Types.ZonerFolder
	end

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(ZonerData, Zoner)

	--=======================================================================================================>

	-- Connect to the AncestryChanged event of the Script:
	-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
	-- We do this to clear the Data in case the Script is Destroyed:
	ZonerData._Connections.Script_AC = script.AncestryChanged:Connect(function()
		if script.Parent == nil or script:IsDescendantOf(game) == false then if ZonerData.Destroy then ZonerData:Destroy() end end
	end)

	-- Connect to the GetPropertyChangedSignal(Parent) event of the Script:
	-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
	-- We do this to clear the Data in case the Script is Destroyed:
	ZonerData._Connections.Script_PCS = script:GetPropertyChangedSignal('Parent'):Connect(function()
		if script.Parent == nil or script:IsDescendantOf(game) == false then if ZonerData.Destroy then ZonerData:Destroy() end end
	end)

	-- Connect to the Destroying event of the Script:
	-- We do this to clear the Data in case the Script is Destroyed:
	ZonerData._Connections.Script_DG = script.Destroying:Connect(function()
		if ZonerData.Destroy then ZonerData:Destroy() end
	end)

	-- Connect to the Zoner Signal Bindable Event, and find the Zone for which the id correlates, and call its Received Method:
	ZonerData._Connections.Zone_Signal = ZonerData._ZoneUpdateEvent.Event:Connect(function(Id: string, ...) 
		if Id and ZonerData._Zones[Id] then ZonerData._Zones[Id]:_OnZoneSignalReceived(...) end
	end)

	--=======================================================================================================>

	-- Return the MetaTable Data
	return ZonerData

	--=======================================================================================================>
end

--[[
Destroys the Zoner system and all its managed zones and connections.

@param self Zoner -- The instance to destroy.
]]
function Zoner.Destroy(self: Zoner)
	--=======================================================================================================>
	for Key, Zone in pairs(self._Zones) do RemoveZone(self, Key) end
	table.clear(self._Zones)
	for Holder, Data in pairs(self._ZonerHolders) do RemoveZonerHolder(self, Holder) end
	table.clear(self._ZonerHolders)
	for Key, Connection in pairs(self._Connections) do Connection:Disconnect() end
	table.clear(self._Connections)

	self._ZoneUpdateEvent:Destroy()
	self._ZonerFolder:Destroy()
	self._PlayerHandler:Destroy()
	--=======================================================================================================>
end

--===========================================================================================================================>

--[[
Creates a new Zone from a part, model, folder, config, or a list of zone boxes.

@param self Zoner -- The current Zoner context.
@param ZoneContainer ZoneContainer -- Boundaries of the zone.
@param ZoneConfig? ZoneConfig -- Optional zone tuning configs.

@return Zone -- The constructed zone object.
]]
function Zoner.NewZone(self: Zoner, ZoneContainer: Types.ZoneContainer, ZoneConfig: Types.ZoneConfig?): Zone.Zone
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

		if ZoneConfig then
			-- Assert that the DetectionCoverage Number sent is the right Enum value:
			if ZoneConfig.DetectionCoverage then 
				assert(Enums.DetectionCoverage:GetName(ZoneConfig.DetectionCoverage) ~= 'Failure', Constants.Logs.Zoner.DetectionCoverage)
			end
			-- Assert that the DetectionCoverage Number sent is the right Enum value:
			if ZoneConfig.DetectionMethod then 
				assert(Enums.DetectionMethod:GetName(ZoneConfig.DetectionMethod) ~= 'Failure', Constants.Logs.Zoner.DetectionMethod)
			end
			
			-- Assert that the EnterDetectionCoverage Number sent is the right Enum value:
			if ZoneConfig.EnterDetectionCoverage then 
				assert(Enums.DetectionCoverage:GetName(ZoneConfig.EnterDetectionCoverage) ~= 'Failure', Constants.Logs.Zoner.DetectionCoverage)
			end
			-- Assert that the ExitDetectionCoverage Number sent is the right Enum value:
			if ZoneConfig.ExitDetectionCoverage then 
				assert(Enums.DetectionCoverage:GetName(ZoneConfig.ExitDetectionCoverage) ~= 'Failure', Constants.Logs.Zoner.DetectionCoverage)
			end
			
			-- Assert that the ExitDetectionMode Number sent is the right Enum value:
			if ZoneConfig.ExitDetectionMode then 
				assert(Enums.DetectionMode:GetName(ZoneConfig.ExitDetectionMode) ~= 'Failure', Constants.Logs.Zoner.DetectionMode)
			end
			-- Assert that the EnterDetectionMode Number sent is the right Enum value:
			if ZoneConfig.EnterDetectionMode then 
				assert(Enums.DetectionMode:GetName(ZoneConfig.EnterDetectionMode) ~= 'Failure', Constants.Logs.Zoner.DetectionMode)
			end
			
			-- Assert that the DetectionCoverage Number sent is the right Enum value:
			if ZoneConfig.DetectionMode then 
				assert(Enums.DetectionMode:GetName(ZoneConfig.DetectionMode) ~= 'Failure', Constants.Logs.Zoner.DetectionMode)
			end
			-- Assert that the Simulation Number sent is the right Enum value:
			if ZoneConfig.Simulation then 
				assert(Utility.IsValidEnumValue(Enums.Simulation, ZoneConfig.Simulation), Constants.Logs.Zoner.Simulation)
			end
			-- Assert that the Execution Number sent is the right Enum value:
			if ZoneConfig.Execution then 
				assert(Utility.IsValidEnumValue(Enums.Execution, ZoneConfig.Execution), Constants.Logs.Zoner.Execution)
			end
			-- Assert that the Bounds Number sent is the right Enum value:
			if ZoneConfig.Bounds then 
				assert(Enums.Bounds:GetName(ZoneConfig.Bounds) ~= 'Failure', Constants.Logs.Zoner.Bounds)
			end
			-- Assert that the Rate Number sent is the right Enum value:
			if ZoneConfig.Rate then 
				assert(Enums.Rate:GetName(ZoneConfig.Rate) ~= 'Failure', Constants.Logs.Zoner.Rate)
			end
			-- Assert that the ManualStepping sent is a boolean:
			if ZoneConfig.ManualStepping then 
				assert(typeof(ZoneConfig.ManualStepping) == 'boolean', Constants.Logs.Zoner.ManualStepping)
			end
			-- Assert that the NoZonePartAddedListening sent is a boolean:
			if ZoneConfig.NoZonePartAddedListening then 
				assert(typeof(ZoneConfig.NoZonePartAddedListening) == 'boolean', Constants.Logs.Zoner.NoZonePartAddedListening)
			end
			-- Assert that the NoZonePartPropertyListening sent is a boolean:
			if ZoneConfig.NoZonePartPropertyListening then 
				assert(typeof(ZoneConfig.NoZonePartPropertyListening) == 'boolean', Constants.Logs.Zoner.NoZonePartPropertyListening)
			end
		end
		--=============================================================================================>
	end
	--=======================================================================================================>
	-- If no ZoneConfig were sent, we are Filling it out with default values:
	if ZoneConfig then
		-- Loop through the Default Zone Configs and use them to replace any missing Configs in the ZoneConfig Table:
		for Key: string, Config in pairs(DEFAULT_ZONE_CONFIG) do
			if ZoneConfig[Key] == nil then ZoneConfig[Key] = Config end
		end
		-- Loop through the Default Zone Configs and use them to replace any missing Configs in the ZoneConfig Table:
		for Key: string, Config in pairs(ZoneConfig) do
			-- Don't do clean for booleans:
			if typeof(Config) == 'boolean' then continue end
			-- If the Config is not the Number Version, (ie: they put in the string), convert the String to the Number for that Enum:
			if typeof(Config) ~= 'number' then ZoneConfig[Key] = Enums[Key]:GetValue(Config) end
		end
	end
	--=======================================================================================================>
	-- Add the Zone to the Zoner's Table and Attributes, and return the Object to the User:
	return AddZone(self, ZoneContainer, ZoneConfig or DEFAULT_ZONE_CONFIG)
	--=======================================================================================================>
end

--[[
Creates a new zone from a region defined by a CFrame and Size vector.

@param self Zoner -- The current Zoner context.
@param RegionCFrame CFrame -- Position and rotation of the region.
@param RegionSize Vector3 -- Dimensions of the region.
@param ZoneConfig? ZoneConfig -- Optional configuration.

@return Zone -- The constructed region zone.
]]
function Zoner.NewZoneFromRegion(self: Zoner, RegionCFrame: CFrame, RegionSize: Vector3, ZoneConfig: Types.ZoneConfig?): Zone.Zone
	--=======================================================================================================>
	-- If the ZoneConfig's Paramater was passed, we will check whether to create internal parts or not:
	if ZoneConfig then
		--============================================================================================>
		-- If the RegionCFrame has no Rotation, then Make sure if the ZoneConfig is set to PerPart, it is corrected to be BoxExact:
		if RegionCFrame.Rotation:FuzzyEq(CFrame.new(), 0.00001) then
			--==================================================================================>
			-- If a ZoneConfig Table was passed and the 
			if Enums.Bounds:GetValue(ZoneConfig.Bounds) == Enums.Bounds.PerPart then
				ZoneConfig.Bounds = Enums.Bounds.BoxExact
			elseif Enums.Bounds:GetValue(ZoneConfig.Bounds) == Enums.Bounds.Automatic then
				ZoneConfig.Bounds = Enums.Bounds.BoxExact
			end
			--==================================================================================>
		end
		-- If the DetectionMethod is Automatic, set it to the most efficient DetectionMethod:
		if Enums.DetectionMethod:GetValue(ZoneConfig.DetectionMethod) == Enums.DetectionMethod.Automatic then
			ZoneConfig.DetectionMethod = Enums.DetectionMethod.Efficient
		end
		-- If the DetectionMethod is Complex, then we need to create internal parts for this Zone, else create a partless zone:
		if Enums.DetectionMethod:GetValue(ZoneConfig.DetectionMethod) == Enums.DetectionMethod.Complex then
			--==================================================================================>
			-- Create a new Model Instance to act as a Container:
			local Container: Model = Instance.new("Model"); Container.Name = 'ZoneContainer'
			-- Create a Cube of Parts inside the Zone matching the CFrame and Size:
			Utility.CreateCube(Container, RegionCFrame, RegionSize)
			-- Return a New Zone Object that has been Relocated:
			return self:NewZone(Container, ZoneConfig):Relocate()
			--==================================================================================>
		else
			-- Return a New PARTLESS Zone Object:
			return self:NewZone({{CFrame = RegionCFrame, Size = RegionSize}}, ZoneConfig)
		end
		--============================================================================================>
	else
		-- Return a New Zone Object:
		return self:NewZone({{CFrame = RegionCFrame, Size = RegionSize}}, ZoneConfig)
	end
	--=======================================================================================================>
end

--===========================================================================================================================>

--[[
Creates a new ZoneCollector used for batching multiple zones together.

@param self Zoner -- The Zoner instance.

@return ZoneCollector -- A new frozen zone collector.
]]

--function Zoner.NewZoneCollector(self: Zoner): ZoneCollector
--	--=======================================================================================================>

--	local ZoneCollector: ZoneCollector = {
--		--=================================================>
--		-- Create a Unique Id for this Identifier:
--		_Id = Utility.Identifier(false, false, true, 5);
--		-- Create Dictionary to store Zone Ids:
--		_Zones = {} :: {[string]: boolean};
--		-- Create a Reference to the Zoner:
--		_Zoner = self;
--		--=================================================>
--	} :: ZoneCollector

--	--=======================================================================================================>

--	--[[
--	Adds a zone to the collector’s tracking list.

--	@param self ZoneCollector -- The current collector.
--	@param Zone Zone -- The zone instance.
--	@param Name? string -- Optional name reference (not stored).
--	]]
--	function ZoneCollector.Add(self: ZoneCollector, Zone: Zone, Name: string?)
--		--==================================================================================>
--		-- Check if the passed Zone is in the Collector, if it is, warn and return:
--		if self._Zones[Zone.Identifier] then warn(`Zone: "{Zone.Identifier}" already in Collector: "{self._Id}"`); return; end
--		--==================================================================================>
--		-- Add the Zone's Id to the Collector Zones Dictionary:
--		self._Zones[Zone.Identifier] = true
--		--==================================================================================>
--	end
--	--[[
--	Removes a zone from the collector, and optionally destroys it.

--	@param self ZoneCollector
--	@param Zone Zone -- Zone to remove.
--	@param DestroyZone? boolean -- If true, calls destroy on the zone.
--	]]
--	function ZoneCollector.Remove(self: ZoneCollector, Zone: Zone, DestroyZone: boolean?)
--		--==================================================================================>
--		-- Check if the passed Zone is in the Collector, if its not, warn and return:
--		if not self._Zones[Zone.Identifier] then warn(`No Zone: "{Zone.Identifier}" found in Collector: "{self._Id}"`); return; end
--		--==================================================================================>
--		-- Remove the Zone's Id from the Collector Zones Dictionary:
--		self._Zones[Zone.Identifier] = nil
--		-- Remove/Destroy the Zone from the Zoner:
--		if DestroyZone then self._Zoner:_RemoveZone(Zone.Identifier) end
--		--==================================================================================>
--	end
--	--[[
--	Fetches and optionally destroys a zone from the collector.

--	@param self ZoneCollector
--	@param Zone Zone
--	@param DestroyZone? boolean
--	]]
--	function ZoneCollector.Get(self: ZoneCollector, Zone: Zone, DestroyZone: boolean?)
--		--==================================================================================>
--		-- Check if the passed Zone is in the Collector, if its not, warn and return:
--		if not self._Zones[Zone.Identifier] then warn(`No Zone: "{Zone.Identifier}" found in Collector: "{self._Id}"`); return; end
--		--==================================================================================>
--		-- Remove the Zone's Id from the Collector Zones Dictionary:
--		self._Zones[Zone.Identifier] = nil
--		-- Remove/Destroy the Zone from the Zoner:
--		if DestroyZone then self._Zoner:_RemoveZone(Zone.Identifier) end
--		--==================================================================================>
--	end

--	--[[
--	Clears all zones stored in this collector.

--	@param self ZoneCollector
--	@param DestroyZones? boolean -- Whether to also destroy zones.
--	]]
--	function ZoneCollector.Clear(self: ZoneCollector, DestroyZones: boolean?)
--		--==================================================================================>
--		-- if DestroyZones is true then remove all the Zones from the Zoner:
--		if DestroyZones == true then for ZoneId: string, Status: boolean in self._Zones do self._Zoner:_RemoveZone(ZoneId) end end
--		-- Clear the Zones Dictionary:
--		table.clear(self._Zones)
--		--==================================================================================>
--	end

--	--[[
--	Destroys this collector and optionally all stored zones.

--	@param self ZoneCollector
--	]]
--	function ZoneCollector.Destroy(self: ZoneCollector)
--		--==================================================================================>
--		self:Clear(true)
--		--==================================================================================>
--	end

--	--=======================================================================================================>

--	-- Return the Collector and Freeze it:
--	return table.freeze(ZoneCollector)

--	--=======================================================================================================>
--end

--===========================================================================================================================>

-- Construct the Zoner Module:
local _Zoner = Zoner._Start()

-- [Notice] can only use the . operator on these functions:
--- Return a table containing the only functions and properties needed by the user:
return table.freeze({
	--==========================================================================>
	--- Pointer Function for the New Zone From Container Method:
	NewFromContainer  = function(ZoneContainer: Types.ZoneContainer, ZoneConfig: Types.ZoneConfig?): Zone 
		return _Zoner:NewZone(ZoneContainer, ZoneConfig) :: any
	end;	
	--- Pointer Function for the New Zone From Container Method:
	New               = function(ZoneContainer: Types.ZoneContainer, ZoneConfig: Types.ZoneConfig?): Zone  
		return _Zoner:NewZone(ZoneContainer, ZoneConfig)  :: any
	end;
	--- Pointer Function for the New Zone From Region Method:
	NewZoneFromRegion = function(RegionCFrame: CFrame, RegionSize: Vector3, ZoneConfig: Types.ZoneConfig?): Zone
		return _Zoner:NewZoneFromRegion(RegionCFrame, RegionSize, ZoneConfig)  :: any
	end;
	--- Pointer Function for the New Zone From Region Method:
	NewZoneFromBox = function(BoxCFrame: CFrame, BoxSize: Vector3, ZoneConfig: Types.ZoneConfig?): Zone
		return _Zoner:NewZoneFromRegion(BoxCFrame, BoxSize, ZoneConfig) :: any
	end;
	----- Pointer Function for the New Zone From Container Method:
	--NewCollector      = function(): ZoneCollector 
	--	return _Zoner:NewZoneCollector() 
	--end;

	RelocateZonerFolder = function(Location: Instance?): 'Success'|'Failure'
		return RelocateZonerFolder(_Zoner, Location)
	end;
	--==========================================================================>
	--- Require the Enum2 Module for Custom Enums:
	--- For referencing the Enums from other scripts:
	Enum = Enums;
	-- Default Zone Collision Group:
	ZONER_COLLISION_GROUP = ZONER_COLLISION_GROUP :: 'Zoner:ZonePart'
	--==========================================================================>
})

--===========================================================================================================================>