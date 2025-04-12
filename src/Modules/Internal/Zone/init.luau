--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Zone')

-- Define Module table
local Zone = {}

--===========================================================================================================================>
--[ SERVICES: ]


-- Get the needed Services for the following Code:
local CollectionService = game:GetService('CollectionService')

--===========================================================================================================================>

local GoodSignal = require(`./../External/GoodSignal`)
local Constants  = require(`./Constants`)
local Enums      = require(`./Enums`)
local Trove      = require(`./../External/Trove`)

local Helpers    = require(script:WaitForChild('Helpers'));
local SignalHash = require(script:WaitForChild('SignalHash'));
local WorldModel = require(script:WaitForChild('WorldModel'));

--===========================================================================================================================>
--[ DEFINE CONSTANTS: ]


-- The RunContext/Scope of the Module:
local RUN_SCOPE: 'Client'|'Server' = if game:GetService('RunService'):IsServer() then 'Server' else 'Client'

local SIGNAL_KEYS = {
	'ItemEntered', 'ItemExited',
	'PartEntered', 'PartExited',
	'PlayerEntered', 'PlayerExited',
	'LocalPlayerEntered', 'LocalPlayerExited'
}

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local Types = require(`../../Types`)

--- Create and Export the Module's Object Type:
export type Zone = typeof(setmetatable({} :: {
	--====================================================>
	_Trove: Trove.Trove;
	--====================================================>
	_EventTrove:  Trove.Trove;
	_PartTrove:   Trove.Trove;
	_HolderTrove: Trove.Trove;
	--====================================================>
	_ActiveTargets: Types.ZoneActiveTargetsTable;
	_Settings:      Types.ZoneSettingsTable;
	_States:        Types.ZoneStatesTable;
	--====================================================>
	_ZonerHolder:     Types.ZonerHolder;
	_ZonerHolderType: 'A'|'G';
	ContainerType:   Types.ZoneContainerType;
	--====================================================>
	Container:  Types.ZoneContainer;
	--====================================================>
	_Classes: {ZoneEngine: any?};
	--====================================================>
	_Tags: {
		ZonePart: string;
		Holder:   string;
	};

	Signals: {
		PlayerEntered: GoodSignal.Signal<Player>;
		PlayerExited: GoodSignal.Signal<Player>;

		PartEntered: GoodSignal.Signal<Part>;
		PartExited: GoodSignal.Signal<Part>;

		ItemEntered: GoodSignal.Signal<Instance>;
		ItemExited: GoodSignal.Signal<Instance>;

		LocalPlayerEntered: GoodSignal.Signal<Player>;
		LocalPlayerExited: GoodSignal.Signal<Player>;
	};

	_Instances: {
		RelocationContainer: Types.ZoneContainer;
		ZoneFolder:          Types.ZoneFolder;
		ZoneParts:           {BasePart};
		Holders:             {Instance};
	};

	--====================================================>
	_Holders:   {Instance};
	_ZoneParts: {BasePart};
	_ZoneFolder: Types.ZoneFolder;
	--====================================================>
	-- Meta Indexing:

	_ZonerActor: Types.ZonerActor;
	_ZonerGroup: Types.ZonerGroup;
	_ZoneBoxes: Types.ZoneBoxes;

	--====================================================>
	-- Zone Public Indexes:
	--====================================================>
	Identifier: string;
	--====================================================>
	Active:         boolean;
	Destroyed:      boolean;
	Relocated:      boolean;
	Paused:         boolean;
	--====================================================>
	Detection:      number;
	Accuracy:       number;
	Simulation:     number;
	Execution:      number;
	EnterDetection: number;
	ExitDetection:  number;
	--====================================================>
	PlayerEntered: GoodSignal.Signal<Player>;
	PlayerExited: GoodSignal.Signal<Player>;

	PartEntered: GoodSignal.Signal<Part>;
	PartExited: GoodSignal.Signal<Part>;

	ItemEntered: GoodSignal.Signal<Instance>;
	ItemExited: GoodSignal.Signal<Instance>;

	LocalPlayerEntered: GoodSignal.Signal<Player>;
	LocalPlayerExited: GoodSignal.Signal<Player>;
	--======================================>
}, {} :: {__index: typeof(Zone)}))

--===========================================================================================================================>
--[ LOCAL FUNCTIONS: ]


local function SetEngine(Zone: Zone)
	--=======================================================================================================>
	-- If the ZonerHolder is an Actor, send the Construct Message,
	-- Else create the Engine in the Object:
	if Zone._ZonerHolderType == 'A' then
		-- Send a Message to the Actor to Construct the ZoneEngine Object on a new Thread:
		-- We send the ModuleScript Instance (Core Class) so that it can be required over there on another thread:
		Zone._ZonerActor:SendMessage('Construct', Zone.Identifier, Zone._ZoneFolder, Zone.Container)
	else
		-- Construct a ZoneEngine Object and Add it to the Classes Trove:
		Zone._Classes.ZoneEngine = Zone._Trove:Add(
			require(script.Engine).New(Zone.Identifier, Zone._ZoneFolder, Zone.Container)
		)
	end
	--=======================================================================================================>
end

local function SetInstances(Zone: Zone)
	--=======================================================================================================>

	-- Create the Zone Core Actor and Script:
	-- Clone the ZoneEngine Actor Template:
	Zone._Instances.ZoneFolder = Instance.new('Folder') :: Types.ZonerFolder
	Zone._Instances.ZoneFolder.Name = Zone.Identifier
	-- Parent the Actor to the CelestialBodies Folder:
	Zone._ZoneFolder.Parent = Zone._ZonerHolder.Zones

	--=======================================================================================================>

	local StatesFolder: Configuration = Instance.new('Configuration')
	StatesFolder.Name = 'States'
	StatesFolder.Parent = Zone._ZoneFolder

	local TriggersFolder: Configuration = Instance.new('Configuration')
	TriggersFolder.Name = 'ActiveTargets'
	TriggersFolder.Parent = Zone._ZoneFolder

	local SettingsFolder: Configuration = Instance.new('Configuration')
	SettingsFolder.Name = 'Settings'
	SettingsFolder.Parent = Zone._ZoneFolder

	--=======================================================================================================>

	-- Update Zone Folder's with default Attributes:
	-- Loop through the States Table to Update the Attributes:
	for Key: string, Status: boolean in pairs(Zone._States) do
		Zone._ZoneFolder.States:SetAttribute(Key, Status)
	end

	-- Loop through the ActiveTargets Table to Update the Attributes:
	for Key: string, Status: boolean in pairs(Zone._ActiveTargets) do
		Zone._ZoneFolder.ActiveTargets:SetAttribute(Key, Status)
	end

	-- Loop through the Settings Table to Update the Attributes:
	for Key: string, Status: boolean in pairs(Zone._Settings) do
		Zone._ZoneFolder.Settings:SetAttribute(Key, Status)
	end

	--=======================================================================================================>
end

local function SetEvents(Zone: Zone)
	--=======================================================================================================>

	-- Connect to the AncestryChanged event of the ZoneFolder:
	-- We then check if the ZoneFolder is still a decendent of the WorldModel, meaning it hasnt been destroyed.
	-- We do this to clear the Data in case the ZoneFolder is Destroyed:
	Zone._EventTrove:Connect(Zone._ZoneFolder.AncestryChanged, function()
		--====================================================================================>
		-- If the Destroying Attribute is true on the ZoneFolder, then ignore the Ancestry Changed:
		if Zone._ZoneFolder:GetAttribute('Destroying') == true then return end
		if Zone._ZoneFolder.Parent == nil or Zone._ZoneFolder:IsDescendantOf(game) == false then Zone:Destroy() end
		--====================================================================================>
	end)

	--=======================================================================================================>

	-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
	if Zone.ContainerType == 'TableOBox' then return end

	-- Connect to the ZonePart Tag Added Signal:
	-- Fires when a Part with the Zone Tag is added back to the Workspace:
	-- We will use this to reduce the Zone Based on Streaming:
	Zone._Trove:Connect(CollectionService:GetInstanceAddedSignal(Zone._Tags.ZonePart), function(ZonePart: BasePart)
		-- Call the ZonePartUpdate Function:
		Zone:_OnZonePartUpdate('Add', ZonePart)
		-- If the Zone is in Serial with a local ZoneEngine call ZonePartUpdate Function from here instead of the Engine:
		if Zone._Classes.ZoneEngine then Zone._Classes.ZoneEngine:OnZonePartUpdate('Add', ZonePart) end
	end)

	-- Connect to the ZonePart Tag Removed Signal:
	-- Fires when a Part with the Zone Tag is removed from the Workspace:
	-- We will use this to restore the Zone Based on Streaming:
	Zone._Trove:Connect(CollectionService:GetInstanceRemovedSignal(Zone._Tags.ZonePart), function(ZonePart: BasePart)
		-- Call the ZonePartUpdate Function:
		Zone:_OnZonePartUpdate('Remove', ZonePart)
		-- If the Zone is in Serial with a local ZoneEngine call ZonePartUpdate Function from here instead of the Engine:
		if Zone._Classes.ZoneEngine then Zone._Classes.ZoneEngine:OnZonePartUpdate('Remove', ZonePart) end
	end)

	-- If the Zone has Holder Instances at all Initially, then we can listen for them:
	if #Zone._Instances.Holders > 0 then
		-- Connect to the Holder Tag Added Signal:
		Zone._Trove:Connect(CollectionService:GetInstanceAddedSignal(Zone._Tags.Holder), function(Holder: Instance)
			-- Call the ZonePartUpdate Function:
			Zone:_OnHolderInstanceUpdate('Add', Holder)
			-- If the Zone is in Serial with a local ZoneEngine call HolderInstanceUpdate Function from here instead of the Engine:
			if Zone._Classes.ZoneEngine then Zone._Classes.ZoneEngine:OnHolderInstanceUpdate('Add', Holder) end
		end)
		-- Connect to the Holder Tag Removed Signal:
		Zone._Trove:Connect(CollectionService:GetInstanceRemovedSignal(Zone._Tags.Holder), function(Holder: Instance)
			-- Call the ZonePartUpdate Function:
			Zone:_OnHolderInstanceUpdate('Remove', Holder)
			-- If the Zone is in Serial with a local ZoneEngine call HolderInstanceUpdate Function from here instead of the Engine:
			if Zone._Classes.ZoneEngine then Zone._Classes.ZoneEngine:OnHolderInstanceUpdate('Remove', Holder) end
		end)
	end

	--=======================================================================================================>
end

local function Initialize(Zone: Zone)
	SetInstances(Zone); SetEvents(Zone); SetEngine(Zone)
end

--===========================================================================================================================>

-- @Private
-- Method to Update/Set the Setting of the Zone:
local function SetSetting(Zone: Zone, SettingName: any, EnumName: string, NameOrId: number | string)
	--=======================================================================================================>
	-- Grab the SettingValue Number Value:
	local SettingValue: number | 'Failure' = Enums[EnumName]:GetValue(NameOrId)
	-- If Detection is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if SettingValue == 'Failure' then warn(Constants.Logs.Zone[`Set{SettingName}`]); return end
	-- Set the new Detection in the Setting Table:
	Zone._Settings[SettingName] = SettingValue :: number
	-- Set the Attribute in a Deffered Function Synchronized in case this SetSetting function is called in Parallel by the User:
	Zone._ZoneFolder.Settings:SetAttribute(SettingName, SettingValue)
	--=======================================================================================================>
end

-- @Private
-- Method to Update/Set the State of the Zone:
local function SetState(Zone: Zone, StateName: string, State: boolean)
	--=======================================================================================================>
	-- If Detection is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if typeof(State) ~= 'boolean' then warn(Constants.Logs.Zone.SetState); return end
	-- Set the new Detection in the Setting Table:
	Zone._States[StateName] = State
	-- Set the Attribute in a Deffered Function Synchronized in case this SetState function is called in Parallel by the User:
	Zone._ZoneFolder.States:SetAttribute(StateName, State)
	--=======================================================================================================>
end

-- @Private
-- Checks all the Event Connections to see if any are used, and then determine if the Zone is Active:
-- Checks every number interval as set in the Counters Table. It checks the connections and size of the ZonePart Array
-- to determine the ActiveTargets and the Overall Active Status of the Zone:
local function UpdateActivity(Zone: Zone)
	--=======================================================================================================>

	-- Calculate the Total Number of Event Connections for the Player Events:
	local PlayerConnections = 
		if Zone.Signals['PlayerExited']  then #Zone.Signals.PlayerExited:GetConnections()  else 0 +
		if Zone.Signals['PlayerEntered'] then #Zone.Signals.PlayerEntered:GetConnections() else 0
	-- Calculate the Total Number of Event Connections for the Item Events:
	local ItemConnections = 
		if Zone.Signals['ItemExited']  then #Zone.Signals.ItemExited:GetConnections()  else 0 +
		if Zone.Signals['ItemEntered'] then #Zone.Signals.ItemEntered:GetConnections() else 0
	-- Calculate the Total Number of Event Connections for the Item Events:
	local PartConnections = 
		if Zone.Signals['PartExited']  then #Zone.Signals.PartExited:GetConnections()  else 0 +
		if Zone.Signals['PartEntered'] then #Zone.Signals.PartEntered:GetConnections() else 0
	-- Calculate the Total Number of Event Connections for the LocalPlayer Events:
	local LocalPlayerConnections = 
		if Zone.Signals['LocalPlayerExited']  then #Zone.Signals.LocalPlayerExited:GetConnections()  else 0 +
		if Zone.Signals['LocalPlayerEntered'] then #Zone.Signals.LocalPlayerEntered:GetConnections() else 0

	--=======================================================================================================>

	if LocalPlayerConnections > 0 then Zone._ActiveTargets.LocalPlayer = true end
	if PlayerConnections > 0      then Zone._ActiveTargets.Player     = true end
	if ItemConnections > 0        then Zone._ActiveTargets.Item       = true end
	if PartConnections > 0        then Zone._ActiveTargets.Part       = true end

	--=======================================================================================================>

	-- Cache Previous Active Status:
	local ActiveStatus = Zone._States.Active

	-- Loop through the ActiveTargets Table to Update the Attributes:
	for Target, Status in Zone._ActiveTargets do
		-- Set the Zone's Active Status to true or false depending on if any Triggers are Active:
		if Status == true then Zone._States.Active = true end
		-- If the ActiveTrigger Attribute Value is not up to date, then Update it on the Attribute:
		if Zone._ZoneFolder.ActiveTargets:GetAttribute(Target :: string) ~= Status then
			Zone._ZoneFolder.ActiveTargets:SetAttribute(Target :: string, Status)
		end
	end

	-- If the ZoneParts Array is Empty, meaning no ZoneParts are in workspace, then set active to false:
	if #(Zone._ZoneBoxes or Zone._ZoneParts) < 1 then Zone._States.Active = false end

	-- If the Zone Active Status is different then it previously was, Update the Attribute:
	if Zone._States.Active ~= ActiveStatus then SetState(Zone, 'Active', Zone._States.Active) end

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- @Private
-- Constructor Function for this individual object:
function Zone.New(Container: Types.ZoneContainer, Settings: Types.ZoneSettings, Holder: Types.ZonerHolder, Id: string): Zone
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory('[Zoner] -> Zoner -> (Zone)')

	--=======================================================================================================>

	-- Define Data
	local ZoneData = {
		--====================================================>
		_Trove = Trove.New();
		--====================================================>
		-- Formerly "ZoneId". Same Purpose:
		Identifier = Id;
		--====================================================>
		-- Reference to the Original Zone Container:
		Container = Container;
		ContainerType = Helpers:GetZoneContainerType(Container);
		--====================================================>
		_ZonerHolder     = Holder;
		_ZonerHolderType = if Holder:IsA('Actor') then 'A' else 'G';
		--====================================================>
		_Classes = {};
		--====================================================>
		_Tags = {
			ZonePart = `{Id}:ZonePart:{RUN_SCOPE}`;
			Holder   = `{Id}:Holder:{RUN_SCOPE}`;
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
		};

		_ActiveTargets = {
			LocalPlayer = false;
			Player      = false;
			Item        = false;
			Part        = false;
		};

		_Settings = table.clone(Settings);
		Signals = {};
		--====================================================>
	}

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
	setmetatable(ZoneData, Zone)

	-- If the ZonerHolder is not a Group (An Actor) OR ManualStepping is false then Remove the Step Method:
	if ZoneData._ZonerHolderType ~= 'G' or ZoneData._Settings.ManualStepping == false then rawset(ZoneData :: any, 'Set', nil) end

	--=======================================================================================================>

	-- Grab the ZoneParts and Holders Array from the current Container:
	local ZoneParts: {BasePart}, Holders: {Instance} = Helpers:GetZonePartsFromContainer(ZoneData.Container, ZoneData.ContainerType)

	--=======================================================================================================>

	-- Loop through the ZoneParts to add tags:
	for Index: number, Holder: Instance in ipairs(Holders) do
		-- If the Part already has a Tag, then continue:
		-- Add the Holder tag to the Holder:
		if Holder:HasTag(ZoneData._Tags.Holder) then continue else 
			Holder:AddTag(ZoneData._Tags.Holder)
			ZoneData:_OnHolderInstanceUpdate('Add', Holder)
		end
	end

	for Index: number, Part: BasePart in ipairs(ZoneParts) do
		-- If the Part already has a Tag, then continue:
		-- Add the ZonePart tag to the ZonePart:
		if Part:HasTag(ZoneData._Tags.ZonePart) then continue else 
			Part:AddTag(ZoneData._Tags.ZonePart) 
			ZoneData:_OnZonePartUpdate('Add', Part)
		end
	end

	--=======================================================================================================>

	Helpers.SetAutoSettings(ZoneData._Settings, ZoneData._ContainerType, ZoneData._ZoneParts, ZoneData._ZoneBoxes)	

	-- Grab the ZoneParts and Holders Array from the current Container:
	ZoneData._Instances.ZoneParts, ZoneData._Instances.Holders = ZoneParts, Holders

	--=======================================================================================================>

	Initialize(ZoneData)
	-- Check the Activity Initially:
	UpdateActivity(ZoneData)

	--=======================================================================================================>

	-- Return the MetaTable Data
	return table.freeze(ZoneData) :: Zone

	--=======================================================================================================>
end

-- @Public
-- Destroyer Function which clears the entirity of the Data for the Object:
function Zone.Destroy(self: Zone)
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
		self._ZonerActor:SendMessage('Destroy', self.Identifier)
	end

	--=======================================================================================================>
	
	for Key, Signal in pairs(self.Signals) do Signal:Destroy() end; table.clear(self.Signals)
	
	-- Clean with Trove
	if self._Trove then self._Trove:Destroy() end

	-- If there is a ZoneEngine in this Object, then set it to nil:
	if self._Classes.ZoneEngine then self._Classes.ZoneEngine:Destroy(); self._Classes.ZoneEngine = nil :: any end

	-- If ZoneFolder is still in game, Destroy the ZoneFolder:
	if self._ZoneFolder:IsDescendantOf(game) then self._ZoneFolder:Destroy() end
	-- Set the Attribute on the Folder to nil. Using the Identifier string as the name, this will clear the attribute from the Folder.
	-- Thus triggering a Cleaning and removal of the Zone from the Zoner Object:
	if self._ZonerHolder:IsDescendantOf(game) and self._ZonerHolder.Ids:GetAttribute(self.Identifier) == true then
		self._ZonerHolder.Ids:SetAttribute(self.Identifier, false) 
	end
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ PUBLIC METHODS: ]

-- @Public
-- Method that will Relocate the Zone to a WorldModel not in the Workspace:
function Zone.Relocate(self: Zone): Zone
	--=======================================================================================================>
	-- If the Container Type is a Table of Part Boxes then return from here:
	if self.ContainerType == 'TableOBox' then warn(`Zone has no parts associated with it to relocate, cant relocate.`); return self end
	-- If we have already Relocated this Zone, return:
	if self._States.Relocated then warn(`Zone is already Relocated! Cant Relocate again, so stop calling this method..`); return self end
	--=======================================================================================================>
	-- Set the Relocated State to true:	
	SetState(self, 'Relocated', true)
	--=======================================================================================================>
	-- Grab the Current Container:
	local RelocationContainer: any = self.Container :: any
	-- If the Container is a table, then make the Container into a Folder and all parts to it:
	if typeof(RelocationContainer) == "table" then
		-- Create a Relocation Container Folder:
		RelocationContainer = Instance.new("Folder")
		RelocationContainer.Name = `{self.Identifier}:RelocationContainer`
		-- Loop through all the ZoneParts and Parent them to the Relocation Container:
		for Index: number, ZonePart in ipairs(self._ZoneParts) do 
			ZonePart.Parent = RelocationContainer :: any 
		end
	else
		-- Update the Name of the Container to be Id Specific:
		if RelocationContainer.Name == 'ZoneContainer' then
			RelocationContainer.Name = `{self.Identifier}:RelocationContainer`
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
function Zone.SetDetection(self: Zone, DetectionCoverage: Enums.DetectionCoverages | number, DetectionMode: Enums.DetectionModes | number)
	SetSetting(self, 'DetectionCoverage', 'DetectionCoverage', DetectionCoverage)
	SetSetting(self, 'DetectionMode', 'DetectionMode', DetectionMode)
end

-- @Public
-- Method to Update/Set the Default Rate of the Zone:
function Zone.SetRate(self: Zone, Rate: Enums.Rates | number)
	SetSetting(self, 'Rate', 'Rate', Rate)
end

-- @Public
-- Method to Update/Set the Default Simulation (RunService Event) of the Zone:
function Zone.SetSimulation(self: Zone, Simulation: Enums.Simulations | number)
	--=======================================================================================================>
	-- Grab the Simulation Number Vlaue:
	local Simulation2: number | 'Failure' = Enums.Simulation:GetValue(Simulation)
	-- If Simulation is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if Simulation2 == 'Failure' then warn(Constants.Logs.Zone.SetSimulation1); return end
	--=======================================================================================================>
	-- Dont allow PreRender to be set on the Server:
	if Enums.Simulation:GetValue(Simulation2) == 'PreRender' and RUN_SCOPE == 'Server' then
		-- Warn/Log to console the Error:
		warn(Constants.Logs.Zone.SetSimulation2)
	else
		-- Set the new Simulation in the Setting Table:
		self._Settings.Simulation = Simulation2 :: number
		-- If the Execution of the Zone is in Parallel, we will set the Attribute for Parallel Updating:
		if self._Settings.Execution == Enums.Execution.Parallel then
			-- Set the Attribute in a Deffered Function Synchronized in case this SetSetting function is called in Parallel by the User:
			task.spawn(function() task.synchronize(); self._ZoneFolder.Settings:SetAttribute('Simulation', Simulation2) end)
		end
	end
	--=======================================================================================================>
end

-- @Public
-- Method to print out all the Setting Names:
function Zone.LogSettings(self: Zone)
	--=======================================================================================================>

	local SettingLog: string = `{Constants.Logs.Zone[`LogSettingsPrefix`]}\n`

	for Key: string, Setting: any in pairs(self._Settings) do
		if Key == 'ManualStepping' then
			SettingLog = SettingLog..`{Key}: {Setting}\n`
		elseif string.match(Key, 'DetectionCoverage') then
			SettingLog = SettingLog..`{Key}: {Enums.DetectionCoverage:GetName(Setting)}\n`
		elseif string.match(Key, 'DetectionMode') then
			SettingLog = SettingLog..`{Key}: {Enums.DetectionMode:GetName(Setting)}\n`
		else
			SettingLog = SettingLog..`{Key}: {Enums[Key]:GetName(Setting)}\n`
		end
	end

	print(SettingLog)

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- only if manualstepping setting is true and the holder type is a group, if not, this method is removed:
function Zone.Step(self: Zone, DeltaTime: number) 
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
-- Initialization function to start/setup the Object's initial data:
function Zone._OnZonePartUpdate(self: Zone, Purpose: 'Add'|'Remove', ZonePart: BasePart)
	--=======================================================================================================>

	-- If the Purpose is 'Remove', then remove the Part, else add it:
	if Purpose == 'Remove' then
		--===============================================================================================>
		-- Find the Index of the ZonePart in the Array:
		local ZonePartIndex: number? = table.find(self._Instances.ZoneParts, ZonePart) 

		-- Client only Extra Check:
		if RUN_SCOPE == 'Client' then
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
			if #self._Instances.ZoneParts < 1 then if self.Destroy then self:Destroy() end end
		end)
		--==============================================================================>
	end

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function Zone._OnHolderInstanceUpdate(self: Zone, Purpose: 'Add'|'Remove', Holder: Instance)
	--=======================================================================================================>

-- If the Purpose is 'Remove', then remove the Part, else add it:
	if Purpose == 'Remove' then
		--===============================================================================================>

		-- Find the Index of the Holder in the Array:
		local HolderIndex: number? = table.find(self._Instances.Holders, Holder) 

		-- Client only Extra Check:
		if RUN_SCOPE == 'Client' then
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
			return 
		end
		--===============================================================================================>
	end

	--=======================================================================================================>

	-- Destroy the Part Trove to destroy all Destroying Events:
	self._HolderTrove:Destroy()

	-- Loop through the Holders Instances to Connect Events to each Part to Destroy the Zone if they are all destroyed:
	for Index: number, Holder in ipairs(self._Instances.Holders) do
		--==============================================================================>

		-- Connect to the Destroying event of the Holder:
		-- We do this to clear the Data in case the Holder is Destroyed:
		self._HolderTrove:Connect(Holder.Destroying, function()
			if self.Destroy then self:Destroy() end
		end)

		-- Connect to the Holder's ChildAdded Event:
		self._HolderTrove:Connect(Holder.ChildAdded, function(Child: any)
			-- If not a BasePart, return:
			if not Child:IsA('BasePart') then return end
			-- Add the ZonePart tag to the Part if it doesnt have it:
			if Child:HasTag(self._Tags.ZonePart) == false then Child:AddTag(self._Tags.ZonePart) end
		end)

		-- Only run the follow below on the Server, since the Client can unload things:
		if RUN_SCOPE == 'Client' then continue end

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


function Zone._OnZoneSignalReceived(self: Zone, Purpose: string, ...)
	self.Signals[SignalHash.Receive[Purpose]]:Fire(...)
end

--===========================================================================================================================>
--[ INDEXER FUNCTIONS: ]


-- Create the MetaIndex function:
function Zone.__index(self: Zone, Index: string): any
	--=======================================================================================================>
	-- Specific Indexing:
	--=======================================================================================================>
	-- Things for users to index and access:
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
	if Index == '_ZoneBoxes' or Index == 'ZoneBoxes' then return if self.ContainerType == 'TableOBox' then self.Container else nil end
	--=======================================================================================================>
	if Index == '_ZoneParts' or Index == 'ZoneParts' then return self._Instances.ZoneParts end
	if Index == '_Holders'   then return self._Instances.Holders end
	--=======================================================================================================>
	if self.Signals[Index] then return self.Signals[Index] end
	-- Check if the Index is one of the Signal Names and then Check if it doesnt exist.
	-- If it doesnt exist, dynamically create the Signal and then Return it:
	if table.find(SIGNAL_KEYS, Index) and not self.Signals[Index] then
		-- Check Client only Signals
		if (Index == 'LocalPlayerEntered' or Index == 'LocalPlayerExited') and RUN_SCOPE ~= 'Client' then return nil end

		self.Signals[Index] = GoodSignal.New()
		-- Add callback functions:
		self.Signals[Index]:_SetOnConnectionCallback(function() UpdateActivity(self) end)
		self.Signals[Index]:_SetOnDisconnectionCallback(function() UpdateActivity(self) end)

		return self.Signals[Index]
	end
	--=======================================================================================================>
	-- If Index is in the immediate Module tree, return that value:			
	if Zone[Index] then return Zone[Index] end
	--=======================================================================================================>
	-- Return False if all else fails!
	return false 
	--=======================================================================================================>
end

-- Create the New Index function:
function Zone.__newindex(self: Zone, Index: string, Value: any)
	--=======================================================================================================>
	if Index == 'EnterDetection' then SetSetting(self, 'EnterDetection', 'Detection', Value); return end
	if Index == 'ExitDetection'  then SetSetting(self, 'ExitDetection',  'Detection', Value); return end
	--=======================================================================================================>
	if Index == 'Paused'  then SetState(self, 'Paused', Value);  return end 
	if Index == 'Visible' then SetState(self, 'Visible', Value); return end 
	--=======================================================================================================>
	error(`"{Index}" cannot be added to Zone`)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze({New = Zone.New})

--===========================================================================================================================>