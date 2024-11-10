--===========================================================================================================================>
--!native
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
local Trove      = require(script.Utility.Trove);
-- Require the Utility Module:
local Utility    = require(script.Utility.Utility.Classes.Get);
-- Require the ZoneUtility:
local Regions    = require(script.Utility.Regions);
-- Require the Constants Module:
local Constants  = require(script.Children.Constants);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types.ZonerTypes)

-- The Main Enums Module Type:
-- The Enums Variable Type:
export type ZonerMetaData = TypeDefinitions.ZonerMetaData
export type ZonerModule   = TypeDefinitions.ZonerModule
export type Zoner         = TypeDefinitions.Zoner

export type ZoneContainer = TypeDefinitions.ZoneContainer
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
	local ZonerData: ZonerMetaData = {
		--====================================================>
		_Trove = Trove.New();
		--====================================================>
		_RunScope = if RunService:IsServer() then 'Server' else 'Client';
		--====================================================>
		_Counters = {};		
		--====================================================>
		_ZoneModule    = require(script.Classes.Zone);
		--====================================================>
		_SettingsFolder = script:WaitForChild('Settings');
		--====================================================>
		_ZonersFolder = false :: any;
		_ZonerFolder  = false :: any;
		--====================================================>
		_Zones = {};
		--====================================================>
	} :: ZonerMetaData

	--=======================================================================================================>

	-- Exetend the Trove to make a Trove Specific For Zones:
	ZonerData._ZoneTrove = ZonerData._Trove:Extend()

	-- Construct the PlayerHandler:
	ZonerData._PlayerHandler = ZonerData._Trove:Construct(require(script.Classes.Plagger), false)

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

	-- If we are running on the Server:
	if self._RunScope == 'Server' then
		--============================================================================================>
	
		-- Cache the Value Instance from ZoneServerLocation Instance:
		local ServerLocation = self._SettingsFolder.ZoneServerLocation.Value

		-- If the Value Instance for a ServerLocation is not nil, then check to make sure its not in Workspace or something dumb:
		if ServerLocation ~= nil then
			--===============================================================>
			-- Boolean to check whether the Parent Location is under ServerScriptService, ReplicatedStorage, or ServerStorage:
			local IsInOkayLocation = 
				ServerLocation:IsDescendantOf(game.ServerScriptService) or
				ServerLocation:IsDescendantOf(game.ReplicatedStorage) or 
				ServerLocation:IsDescendantOf(game.ServerStorage)

			-- If its not in an Okay Location, Make it Parent Directly to ServerScriptService:
			if not IsInOkayLocation then ServerLocation = game.ServerScriptService end
			--===============================================================>
		else
			--===============================================================>
			ServerLocation = game.ServerScriptService 
			--===============================================================>
		end

		--============================================================================================>
		
		-- Check the ServerLocation if a Folder named 'Zoner:Server' already exists:
		local ExistingFolder: Folder? = ServerLocation:FindFirstChild('Zoner:Server', true)
		
		-- If one Already Exists, set the reference to it, if not, construct a new Folder:
		self._ZonerFolder = if ExistingFolder then ExistingFolder else self._Trove:Construct(Instance, 'Folder')
		-- Name said Folder (again possibly):
		self._ZonerFolder.Name = 'Zoner:Server'
		-- Set ZonerServerFolder Parent to the Variable:
		self._ZonerFolder.Parent = ServerLocation
		
		-- If this is a brand new Folder, construct the Child Instances:
		if not ExistingFolder then
			--==================================================================>
			
			local ZonesFolder: Folder = Instance.new('Folder')
			ZonesFolder.Name = 'Zones'
			ZonesFolder.Parent = self._ZonerFolder

			local IdsFolder: Configuration = Instance.new('Configuration')
			IdsFolder.Name = 'Ids'
			IdsFolder.Parent = self._ZonerFolder

			--==================================================================>
		end
		
		--============================================================================================>
	else
		--============================================================================================>
		
		-- Check if a Folder named 'Zoners' already exists:
		local ExistingZonersFolder = script:FindFirstChild('Zoners', true)
		
		-- If one Already Exists, set the reference to it, if not, construct a new Folder:
		self._ZonersFolder = if ExistingZonersFolder then ExistingZonersFolder else self._Trove:Construct(Instance, 'Folder')
		-- Name said Folder (again possibly):
		self._ZonersFolder.Name = 'Zoners' :: any
		-- Set ZonersFolder Parent to the Variable:
		self._ZonersFolder.Parent = script
	
		--============================================================================================>
		
		-- Check the ServerLocation if a Folder named 'Zoner:Client' already exists:
		local ExistingZonerFolder = self._ZonersFolder:FindFirstChild('Zoner:Client')

		-- If one Already Exists, set the reference to it, if not, construct a new Folder:
		self._ZonerFolder = if ExistingZonerFolder then ExistingZonerFolder else self._Trove:Construct(Instance, 'Folder')
		-- Name said Folder (again possibly):
		self._ZonerFolder.Name = 'Zoner:Client'
		-- Set ZonerClientFolder Parent to the Variable:
		self._ZonerFolder.Parent = self._ZonersFolder

		-- If this is a brand new Folder, construct the Child Instances:
		if not ExistingZonerFolder then
			--==================================================================>

			local ZonesFolder: Folder = Instance.new('Folder')
			ZonesFolder.Name = 'Zones'
			ZonesFolder.Parent = self._ZonerFolder

			local IdsFolder: Configuration = Instance.new('Configuration')
			IdsFolder.Name = 'Ids'
			IdsFolder.Parent = self._ZonerFolder

			--==================================================================>
		end
		
		--============================================================================================>
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
	self._Trove:Connect(self._ZonerFolder.Ids.AttributeChanged, function(Identifier: string)
		--====================================================================================>
		-- Get the Current Boolean State of the Identifier Attribute:
		local ZoneState: boolean = self._ZonerFolder.Ids:GetAttribute(Identifier) :: boolean
		-- If the ZoneState is not True, meaning false or nil, we remove the Zone:
		if ZoneState ~= true then self:_RemoveZone(Identifier) end
		--====================================================================================>
	end)

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Construct and Add a Zone Object to the Zoner's Table and return the Zone:
function ZonerModule._AddZone(self: Zoner, ...): Zone
	--=======================================================================================================>

	-- Create and get a new Unique Identifier string:
	local Identifier: string = Utility.Identifier(false, false, true, 9)

	-- Check if a Zone with that ID is stored in the Zones Table, if so, warn and return:
	if self._Zones[Identifier] then warn(`Could not Add Zone with Id: "{Identifier}" because Zone already exists!`); return nil :: any end
	
	--=======================================================================================================>
	
	-- Set the Identifier onto the Ids Folder to Store it and be able to listen for AttributeChanged:
	self._ZonerFolder.Ids:SetAttribute(Identifier, true)
	
	-- Construct the Zone Object and add it to the Zones Table with Identifier as the Key:
	self._Zones[Identifier] = self._ZoneTrove:Construct(self._ZoneModule, self._ZonerFolder, self._RunScope, Identifier, ...)
	
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
	
	-- Remove the Zone Object from the Trove, Destroying it in the Process:
	self._ZoneTrove:Remove(self._Zones[Identifier])
	
	-- Clear it from the Dictionary:
	self._Zones[Identifier] = nil :: any

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Method to Construct a New Zone Object and Add it to the Zoner Handler, and then Return the Object:
function ZonerModule.NewZone(self: Zoner, Container: ZoneContainer, Accuracy: number?, Detection: number?): Zone
	--=======================================================================================================>
	
	-- Assert Statements for Paramaters:
	do
		--=============================================================================================>
		-- Assert whether the Provided Container is of the proper Instance or Table type:
		assert((typeof(Container) == "table" or typeof(Container) == "Instance"), Constants.Logs.Zone.ContainerType)
		
		-- If the Container Type is an Instance, check type of Instance:
		if typeof(Container) == "Instance" then 
			-- Assert the Specifics of the Instance Type:
			assert(
				Container:IsA('BasePart') or Container:IsA('Model') or Container:IsA('Folder') or Container:IsA('Configuration'),
				Constants.Logs.Zone.InstanceType
			)
			-- Assert the Specifics of the Instance Type:
			assert(
				not (Container:IsA('Terrain') or Container:IsA('Workspace')),
				Constants.Logs.Zone.InstanceType
			)
		end

		-- Assert that the Accuracy Number sent is the right Enum value:
		assert((Accuracy == nil or (math.floor(Accuracy) >= 1 and math.floor(Accuracy) <= 8)), Constants.Logs.Zone.Accuracy)

		-- Assert that the Accuracy Number sent is the right Enum value:
		assert((Detection == nil or (math.floor(Detection) >= 1 and math.floor(Detection) <= 12)), Constants.Logs.Zone.Detection)
		--=============================================================================================>
	end
	
	--=======================================================================================================>
	
	-- Add the Zone to the Zoner's Table and Attributes, and return the Object to the User:
	return self:_AddZone(Container, Accuracy, Detection)
	
	--=======================================================================================================>
end

-- @Public
-- Method to Construct a New Zone Object (FROM A CONTAINER (default)) and Add it to the Zoner Handler, and then Return the Object:
function ZonerModule.NewZoneFromContainer(self: Zoner, Container: ZoneContainer, Accuracy: number?, Detection: number?): Zone
	--=======================================================================================================>
	return self:NewZone(Container, Accuracy, Detection)
	--=======================================================================================================>
end

-- @Public
-- Method to Construct a New Zone Object (FROM REGION PARAMATERS) and Add it to the Zoner Handler, and then Return the Object:
function ZonerModule.NewZoneFromRegion(self: Zoner, RegionCFrame: CFrame, RegionSize: Vector3, Accuracy: number?, Detection: number?): Zone
	--=======================================================================================================>
	
	-- Create a new Model Instance to act as a Container:
	local Container: Model = Instance.new("Model")
	Container.Name = 'ZoneContainer'

	-- Create a Cube of Parts inside the Zone matching the CFrame and Size:
	Regions:CreateCube(Container, RegionCFrame, RegionSize)
	
	--=======================================================================================================>
	
	-- Return a New Zone Object that has been Relocated:
	return self:NewZone(Container, Accuracy, Detection):Relocate()
	
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

local Zoner = ZonerModule._Start()

local function NewFromContainer(Container: ZoneContainer, Accuracy: number?, Detection: number?): Zone 
	return Zoner:NewZoneFromContainer(Container, Accuracy, Detection) 
end

local function NewZoneFromRegion(RegionCFrame: CFrame, RegionSize: Vector3, Accuracy: number?, Detection: number?): Zone 
	return Zoner:NewZoneFromRegion(RegionCFrame, RegionSize, Accuracy, Detection) 
end

return table.freeze({
	-- Require the Enum2 Module for Custom Enums:
	-- For referencing the Enums from other scripts:
	Enum =  require(script.Utility.Enums).Enums;

	NewFromContainer  = NewFromContainer;
	NewZoneFromRegion = NewZoneFromRegion;
	New               = NewFromContainer;
})

-- Return the Module Constructed as an Object and Frozen:
--return table.freeze(ZonerModule._Start()) :: Zoner

--===========================================================================================================================>