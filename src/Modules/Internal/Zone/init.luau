--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Zone')

-- Define Module table
local Zone = {}

--===========================================================================================================================>
--[ GLOBALS: ]


-- Get the needed Services for the following Code:
local CollectionService = game:GetService('CollectionService')

--===========================================================================================================================>
--[ DEPENDENCIES: ]


-- [ Zoner Globals ]
local GoodSignal = require(`../External/GoodSignal`)

-- [ Internals ]
local Constants  = require(`./Constants`)
local Enums      = require(`./Enums`)

-- [ Locals ]
local Helpers    = require(`@self/Helpers`);
local Regions    = require(`@self/Regions`);
local SignalHash = require(`@self/SignalHash`);
local WorldModel = require(`@self/WorldModel`);

--===========================================================================================================================>
--[ DEFINE CONSTANTS: ]

-- Wait for the Events folder:
local EVENTS_FOLDER = script:FindFirstAncestor('Modules').Parent:WaitForChild('Events')

-- The RunContext/Scope of the Module:
local RUN_CONTEXT: 'Client'|'Server' = if game:GetService('RunService'):IsServer() then 'Server' else 'Client'

-- Cache the Zone_Id remote events:
-- CLIENT ONLY
local ZONE_ID_EVENTS = {
	ZoneId_Add    = if RUN_CONTEXT == 'Client' and workspace.StreamingEnabled then EVENTS_FOLDER:WaitForChild('ZoneId_Add', 1)    else nil;
	ZoneId_Remove = if RUN_CONTEXT == 'Client' and workspace.StreamingEnabled then EVENTS_FOLDER:WaitForChild('ZoneId_Remove', 1) else nil;
}

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
	_ActiveTargets: Types.ZoneActiveTargetsTable;
	_Config:      Types.ZoneConfigTable;
	_States:        Types.ZoneStatesTable;
	--====================================================>
	_ZonerHolder:     Types.ZonerHolder;
	_ZonerFolder:     Types.ZonerFolder;
	_ZonerHolderType: 'A'|'G';

	-- Bound groups:
	_Groups: {[string]: boolean};

	ContainerType:   Types.ZoneContainerType;
	--====================================================>
	Container:  Types.ZoneContainer;
	--====================================================>
	_Classes: {ZoneEngine: any?};
	_Connections: {[any]: RBXScriptConnection};
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
		RelocationContainer: Instance;
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
	
	MetaData: any;
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

-- @Private
-- Method to Update the Id Tags on the Server from Client:
local function UpdateIdsOnServer(Type: 'Add'|'Remove', Id, ZoneParts, ZonePartHolders)
	--=======================================================================================================>
	if Type == 'Add' then
		-- If the ZoneId_Add remote event is present, fire to the server to add the Client Ids:
		if ZONE_ID_EVENTS.ZoneId_Add then ZONE_ID_EVENTS.ZoneId_Add:FireServer(Id, ZoneParts, ZonePartHolders) end
	else
		-- If the ZoneId_Remove remote event is present, fire to the server to REMOVE the Client Ids:
		if ZONE_ID_EVENTS.ZoneId_Remove then ZONE_ID_EVENTS.ZoneId_Remove:FireServer(Id, ZoneParts, ZonePartHolders) end
	end
	--=======================================================================================================>
end

-- @Private
-- Method to Update/Set the Config of the Zone:
local function SetConfig(Zone: Zone, ConfigName: any, EnumName: string, NameOrId: number | string)
	--=======================================================================================================>
	-- Grab the ConfigValue Number Value:
	local ConfigValue: number | 'Failure' = Enums[EnumName]:GetValue(NameOrId)
	-- If Detection is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if ConfigValue == 'Failure' then warn(Constants.Logs.Zone[`Set{ConfigName}`]); return end
	-- Set the new Detection in the Config Table:
	Zone._Config[ConfigName] = ConfigValue :: number
	-- Set the Attribute in a Deffered Function Synchronized in case this SetConfig function is called in Parallel by the User:
	Zone._ZoneFolder.Config:SetAttribute(ConfigName, ConfigValue)
	--=======================================================================================================>
end

-- @Private
-- Method to Update/Set the State of the Zone:
local function SetState(Zone: Zone, StateName: string, State: boolean)
	--=======================================================================================================>
	-- If Detection is Failure, then warn to User that the passed Name Or Id did not return a valid Enum.
	if typeof(State) ~= 'boolean' then warn(Constants.Logs.Zone.SetState); return end
	-- Set the new Detection in the Config Table:
	Zone._States[StateName] = State
	-- Set the Attribute in a Deffered Function Synchronized in case this SetState function is called in Parallel by the User:
	Zone._ZoneFolder.States:SetAttribute(StateName, State)
	--=======================================================================================================>
end

-- @Private
-- Checks all the Event Connections to see if any are used, and then determine if the Zone is Active:
-- Checks every number interval as set in the Counters Table. It checks the connections and size of the ZonePart Array
-- to determine the ActiveTargets and the Overall Active Status of the Zone:
local function UpdateActivity(Zone: Zone): Zone
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

	-- Return for trailing:
	return Zone
	--=======================================================================================================>
end

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
		-- Construct a ZoneEngine Object and Add it to the Classes:
		Zone._Classes.ZoneEngine = require(script.Engine).New(
			-- Create a serial callback to avoid the bindable events if we're in serial, by directly calling the Signal function:
			Zone.Identifier, Zone._ZoneFolder, Zone.Container, function(...) Zone:_OnZoneSignalReceived(...) end
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

	local ConfigFolder: Configuration = Instance.new('Configuration')
	ConfigFolder.Name = 'Config'
	ConfigFolder.Parent = Zone._ZoneFolder

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

	-- Loop through the Config Table to Update the Attributes:
	for Key: string, Status: boolean in pairs(Zone._Config) do
		Zone._ZoneFolder.Config:SetAttribute(Key, Status)
	end

	--=======================================================================================================>
end

local function SetEvents(Zone: Zone)
	--=======================================================================================================>

	-- Connect to the AncestryChanged event of the ZoneFolder:
	-- We then check if the ZoneFolder is still a decendent of the WorldModel, meaning it hasnt been destroyed.
	-- We do this to clear the Data in case the ZoneFolder is Destroyed:
	Zone._Connections['AncestryChanged'] = Zone._ZoneFolder.AncestryChanged:Connect(function() 
		--====================================================================================>
		-- If the Destroying Attribute is true on the ZoneFolder, then ignore the Ancestry Changed:
		if Zone._ZoneFolder:GetAttribute('Destroying') == true then return end
		if Zone._ZoneFolder.Parent == nil or Zone._ZoneFolder:IsDescendantOf(game) == false then Zone:Destroy() end
		--====================================================================================>
	end)

	--=======================================================================================================>

	-- If the Container Type is a Table of Box Bounds, then theres no Parts in this Zone to need Events For, so return from here:
	if Zone.ContainerType == 'Boxes' then return end

	-- Connect to the ZonePart Tag Added Signal:
	-- Fires when a Part with the Zone Tag is added back to the Workspace:
	-- We will use this to reduce the Zone Based on Streaming:
	Zone._Connections['ZonePart_Add'] = CollectionService:GetInstanceAddedSignal(Zone._Tags.ZonePart):Connect(function(ZonePart: BasePart)
		-- Call the ZonePartUpdate Function:
		Zone:_OnZonePartUpdate('Add', ZonePart)
		-- If the Zone is in Serial with a local ZoneEngine call ZonePartUpdate Function from here instead of the Engine:
		if Zone._Classes.ZoneEngine then Zone._Classes.ZoneEngine:OnZonePartUpdate('Add', ZonePart) end
	end)

	-- Connect to the ZonePart Tag Removed Signal:
	-- Fires when a Part with the Zone Tag is removed from the Workspace:
	-- We will use this to restore the Zone Based on Streaming:
	Zone._Connections['ZonePart_Remove'] = CollectionService:GetInstanceRemovedSignal(Zone._Tags.ZonePart):Connect(function(ZonePart: BasePart)
		-- Call the ZonePartUpdate Function:
		Zone:_OnZonePartUpdate('Remove', ZonePart)
		-- If the Zone is in Serial with a local ZoneEngine call ZonePartUpdate Function from here instead of the Engine:
		if Zone._Classes.ZoneEngine then Zone._Classes.ZoneEngine:OnZonePartUpdate('Remove', ZonePart) end
	end)

	-- If the Zone has Holder Instances at all Initially, then we can listen for them:
	if #Zone._Instances.Holders > 0 then
		-- Connect to the Holder Tag Added Signal:
		Zone._Connections['Holder_Add'] = CollectionService:GetInstanceAddedSignal(Zone._Tags.Holder):Connect(function(Holder: Instance)
			-- Call the ZonePartUpdate Function:
			Zone:_OnHolderInstanceUpdate('Add', Holder)
			-- If the Zone is in Serial with a local ZoneEngine call HolderInstanceUpdate Function from here instead of the Engine:
			if Zone._Classes.ZoneEngine then Zone._Classes.ZoneEngine:OnHolderInstanceUpdate('Add', Holder) end
		end)
		-- Connect to the Holder Tag Removed Signal:
		Zone._Connections['Holder_Add'] = CollectionService:GetInstanceRemovedSignal(Zone._Tags.Holder):Connect(function(Holder: Instance)
			-- Call the ZonePartUpdate Function:
			Zone:_OnHolderInstanceUpdate('Remove', Holder)
			-- If the Zone is in Serial with a local ZoneEngine call HolderInstanceUpdate Function from here instead of the Engine:
			if Zone._Classes.ZoneEngine then Zone._Classes.ZoneEngine:OnHolderInstanceUpdate('Remove', Holder) end
		end)
	end

	--=======================================================================================================>
end

local function SetCore(Zone: Zone)
	--=======================================================================================================>

	-- If the ZonerHolder is not a Group (An Actor) OR ManualStepping is false then Remove the Step Method:
	if Zone._ZonerHolderType ~= 'G' or Zone._Config.ManualStepping == false then rawset(Zone :: any, 'Set', nil) end

	--=======================================================================================================>

	-- Grab the ZoneParts and Holders Array from the current Container:
	local ZoneParts: {BasePart}, Holders: {Instance} = Helpers.GetZonePartsFromContainer(Zone.Container, Zone.ContainerType)

	--=======================================================================================================>

	-- Loop through the ZoneParts to add tags:
	for Index: number, Holder: Instance in ipairs(Holders) do
		-- If the Part already has a Tag, then continue:
		-- Add the Holder tag to the Holder:
		if Holder:HasTag(Zone._Tags.Holder) then continue else 
			Holder:AddTag(Zone._Tags.Holder)
			Zone:_OnHolderInstanceUpdate('Add', Holder)
		end
	end

	for Index: number, Part: BasePart in ipairs(ZoneParts) do
		-- If the Part already has a Tag, then continue:
		-- Add the ZonePart tag to the ZonePart:
		if Part:HasTag(Zone._Tags.ZonePart) then continue else 
			Part:AddTag(Zone._Tags.ZonePart) 
			Zone:_OnZonePartUpdate('Add', Part)
		end
	end

	-- If the ZoneId_Add remote event is present, fire to the server to ADD the Client Ids:
	UpdateIdsOnServer('Add', Zone.Identifier, Zone:GetZoneParts(), Zone:GetZonePartHolders())

	--=======================================================================================================>

	-- Update simulation type on server:
	if Zone._Config.Simulation == Enums.Simulation.PreRender and RUN_CONTEXT == 'Server' then
		Zone._Config.Simulation = Enums.Simulation.PostSimulation
	end

	Helpers.SetAutoConfig(Zone._Config, Zone.ContainerType, Zone._ZoneParts, Zone._ZoneBoxes)	

	-- Grab the ZoneParts and Holders Array from the current Container:
	Zone._Instances.ZoneParts, Zone._Instances.Holders = ZoneParts, Holders

	--=======================================================================================================>
end

local function Initialize(Zone: Zone): Zone
	SetCore(Zone); SetInstances(Zone); SetEvents(Zone); SetEngine(Zone); return Zone
end

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- @Private
-- Constructor Function for this individual object:
function Zone.New(Container: Types.ZoneContainer, Config: Types.ZoneConfig, Holder: Types.ZonerHolder, ZonerFolder: Types.ZonerFolder, Id: string): Zone
	--=======================================================================================================>
	-- Set Memory Category:
	debug.setmemorycategory('[Zoner] -> Zoner -> (Zone)')
	-- Return the MetaTable Data
	return table.freeze(Initialize(setmetatable( {
		--====================================================>
		-- Formerly "ZoneId". Same Purpose:
		Identifier = Id;
		--====================================================>
		-- Reference to the Original Zone Container:
		Container     = Container;
		ContainerType = Helpers.GetZoneContainerType(Container);
		--====================================================>
		_ZonerHolder     = Holder;
		_ZonerFolder     = ZonerFolder;
		_ZonerHolderType = if Holder:IsA('Actor') then 'A' else 'G';
		--====================================================>
		_Classes = {};
		-- Table to hold connections to replace trove:
		_Connections = {};
		-- Hold all bound to groups:
		_Groups = {};
		--====================================================>
		_Tags = {
			ZonePart = `{Id}:ZonePart:{RUN_CONTEXT}`;
			Holder   = `{Id}:Holder:{RUN_CONTEXT}`;
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

		_Config = table.clone(Config);
		--====================================================>
		MetaData = {};
		Signals  = {};
		--====================================================>
	} :: any, Zone)))
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

	-- Remove Tags from Instances:
	if RUN_CONTEXT == 'Client' then
		-- If the ZoneId_Remove remote event is present, fire to the server to REMOVE the Client Ids:
		UpdateIdsOnServer('Remove', self.Identifier, self:GetZoneParts(), self:GetZonePartHolders())
	else 
		-- Remove Tags from ZoneParts:
		for Index, ZonePart in ipairs(table.clone(self:GetZoneParts())) do
			self:_OnZonePartUpdate('Remove', ZonePart)
		end; 
		-- Remove Tags from Holders:
		for Index, Holder in ipairs(table.clone(self:GetZonePartHolders())) do
			self:_OnHolderInstanceUpdate('Remove', Holder)
		end;
	end

	-- If the ZonerHolder is still in Game and is an Actor, Send the Destroy Method:
	if self._ZonerHolder:IsDescendantOf(game) and self._ZonerHolderType == 'A' then
		-- Send a Message to the ZoneEngineActor to Destroy itself:
		self._ZonerActor:SendMessage('Destroy', self.Identifier)
	end

	--=======================================================================================================>

	for Key, Signal in pairs(self.Signals) do Signal:Destroy() end; table.clear(self.Signals)

	-- Unbind from all the groups:
	for GroupName, State in pairs(self._Groups) do self:UnbindFromGroup(GroupName) end; table.clear(self._Groups)

	-- Clear connections:
	for Key, Connection in pairs(self._Connections) do self._Connections[Key]:Disconnect() end; table.clear(self._Connections)

	-- Destroy the relocation container:
	if self._Instances.RelocationContainer then self._Instances.RelocationContainer:Destroy() end

	-- If there is a ZoneEngine in this Object, then set it to nil:
	if self._Classes.ZoneEngine then self._Classes.ZoneEngine:Destroy(); self._Classes.ZoneEngine = nil :: any end

	--=======================================================================================================>

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
-- Method that will BIND the Zone to the passed Group:
function Zone.BindToGroup(self: Zone, GroupName: string)
	--=======================================================================================================>
	-- Assert the paramater:
	assert(GroupName ~= nil, `[Zone]: 'BindToGroup' | 'GroupName' paramater was nil`)
	-- Check if already bound to:
	if self._Groups[GroupName] then warn(`[Zone]: 'BindToGroup' | Zone already bound to group: "{GroupName}"`); return end
	--=======================================================================================================>
	-- Find the GroupFolder underneath the Groups Folder:
	local Group_Folder: Types.GroupsFolderGroup? = self._ZonerFolder.Groups:FindFirstChild(GroupName) :: Types.GroupsFolderGroup?
	-- If Group Folder is found, Bind the Zone to the Group:
	if Group_Folder then
		-- Set the table group hash to true:
		self._Groups[GroupName] = true
		-- Set the Attribute on the Zones Folder to the Id, to record that this Zone is bound to this group:
		Group_Folder.Zones:SetAttribute(self.Identifier, true)
	else
		warn(`[Zone]: 'BindToGroup' | No Group exists by the name: "{GroupName}"`)
	end
	--=======================================================================================================>
end

-- @Public
-- Method that will UNBIND the Zone from the passed Group:
function Zone.UnbindFromGroup(self: Zone, GroupName: string)
	--=======================================================================================================>
		-- Assert the paramater:
	assert(GroupName ~= nil, `[Zone]: 'UnbindFromGroup' | 'GroupName' paramater was nil`)
	-- Check if already unbound:
	if not self._Groups[GroupName] then warn(`[Zone]: 'UnbindFromGroup' | Zone not bound to group: "{GroupName}"`); return end
	--=======================================================================================================>
	-- Find the GroupFolder underneath the Groups Folder:
	local Group_Folder: Types.GroupsFolderGroup? = self._ZonerFolder.Groups:FindFirstChild(GroupName) :: Types.GroupsFolderGroup?
	-- If Group Folder is found, Bind the Zone to the Group:
	if Group_Folder then
		-- Set the table group hash to nil:
		self._Groups[GroupName] = nil
		-- Set the Attribute on the Zones Folder to nil, to record that this Zone is no longer bound to this group:
		Group_Folder.Zones:SetAttribute(self.Identifier, nil)
	else
		warn(`[Zone]: 'UnbindFromGroup' | No Group exists by the name: "{GroupName}"`)
	end
	--=======================================================================================================>
end

-- @Public
-- Method that will Relocate the Zone to a WorldModel not in the Workspace:
function Zone.Relocate(self: Zone): Zone
	--=======================================================================================================>
	-- If the Container Type is a Table of Part Boxes then return from here:
	if self.ContainerType == 'Boxes' then warn(`Zone has no parts associated with it to relocate, cant relocate.`); return self end
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
	-- Set the RelocationContainer Variable to to the new Folder:
	self._Instances.RelocationContainer = RelocationContainer
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
	SetConfig(self, 'DetectionCoverage', 'DetectionCoverage', DetectionCoverage)
	SetConfig(self, 'DetectionMode', 'DetectionMode', DetectionMode)
end

-- @Public
-- Method to Update/Set the Default Rate of the Zone:
function Zone.SetRate(self: Zone, Rate: Enums.Rates | number)
	SetConfig(self, 'Rate', 'Rate', Rate)
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
	if Enums.Simulation:GetValue(Simulation2) == 'PreRender' and RUN_CONTEXT == 'Server' then
		-- Warn/Log to console the Error:
		warn(Constants.Logs.Zone.SetSimulation2)
	else
		-- Set the new Simulation in the Config Table:
		self._Config.Simulation = Simulation2 :: number
		-- If the Execution of the Zone is in Parallel, we will set the Attribute for Parallel Updating:
		if self._Config.Execution == Enums.Execution.Parallel then
			-- Set the Attribute in a Deffered Function Synchronized in case this SetConfig function is called in Parallel by the User:
			task.spawn(function() task.synchronize(); self._ZoneFolder.Config:SetAttribute('Simulation', Simulation2) end)
		end
	end
	--=======================================================================================================>
end

-- @Public
-- Method to print out all the Config Names:
function Zone.LogConfig(self: Zone)
	--=======================================================================================================>

	local ConfigLog: string = `{Constants.Logs.Zone[`LogConfigPrefix`]}\n`

	for Key: string, Value: any in pairs(self._Config) do
		if typeof(Value) ~= 'number' then
			ConfigLog = ConfigLog..`{Key}: {Value}\n`
		elseif string.match(Key, 'DetectionCoverage') then
			ConfigLog = ConfigLog..`{Key}: {Enums.DetectionCoverage:GetName(Value)}\n`
		elseif string.match(Key, 'DetectionMode') then
			ConfigLog = ConfigLog..`{Key}: {Enums.DetectionMode:GetName(Value)}\n`
		else
			ConfigLog = ConfigLog..`{Key}: {Enums[Key]:GetName(Value)}\n`
		end
	end

	print(ConfigLog)

	--=======================================================================================================>
end

-- @Public
-- Method to return the array of ZoneParts:
function Zone.GetZoneParts(self: Zone): {BasePart}
	return self._ZoneParts
end

-- @Public
-- Method to return the array of ZonePartHolders:
function Zone.GetZonePartHolders(self: Zone): {Instance}
	return self._Holders
end

--===========================================================================================================================>

-- @Public
-- Method to return a random Vector3 point within the Zone's bounds.
-- Will return a point inside a box or part depending on what the Zone is made of.
@native function Zone.GetRandomPoint(self: Zone): Vector3
	--=======================================================================================================>

	-- Check if the Zone uses box-based bounds (instead of BaseParts)
	if self._ZoneBoxes then
		-- Pick a random ZoneBox from the array of zone boxes
		local ZoneBox = Helpers.GetRandomArrayItem(self._ZoneBoxes)

		if ZoneBox then
			-- If a box was found, return a random point within it using math-based method
			return Regions:GetRandomPointInBox(ZoneBox.CFrame, ZoneBox.Size)
		else
			-- Warn if no boxes exist in this zone
			warn('[Zoner]: Cant Get RandomPoint, Zone is empty')
			return Vector3.zero -- Safe fallback
		end
	else
		-- If not using box bounds, fallback to zone parts
		local ZonePart = Helpers.GetRandomArrayItem(self._ZoneParts)

		if ZonePart then
			-- Determine the shape of the part to use appropriate method
			local PartType: string = Regions:GetPartType(ZonePart)
			if PartType == 'Block' then 	
				-- If it's a block, use box math
				return Regions:GetRandomPointInBox(ZonePart.CFrame, ZonePart.Size)
			elseif PartType == 'Sphere' then
				-- If it's a sphere, use sphere math (radius = size.X / 2)
				return Regions:GetRandomPointInSphere(ZonePart.Position, ZonePart.Size.X / 2)
			else 	
				-- For complex shapes (mesh, wedge, etc), use spatial testing
				-- Choose WorldModel or Workspace depending on relocation status
				return Regions:GetRandomPointInBasePart(
					ZonePart,
					if self._States.Relocated then WorldModel:GetWorldModel() else workspace
				)
			end	
		else
			-- If no parts exist in this zone
			warn('[Zoner]: Cant Get RandomPoint, Zone is empty')
			return Vector3.zero
		end
	end

	--=======================================================================================================>
end

-- @Public
-- Method to return an array of all BaseParts currently touching this Zone.
-- Works for both Box-style and Part-style Zones.
@native function Zone.GetTouchingParts(self: Zone): {BasePart}
	--=======================================================================================================>
	-- Create a new OverlapParams object for filtering overlap checks
	local OverlapParamaters = OverlapParams.new()

	-- Check if the Zone is using box-based bounds
	if self._ZoneBoxes then
		-- Table to collect all touching parts
		local TouchingParts: {BasePart} = {}
		-- Loop through each box in the zone
		for Index: number, Box in ipairs(self._ZoneBoxes) do
			-- Get all parts overlapping this box
			local Overlapping: {BasePart} = 
				WorldModel:GetPartBoundsInBox(
					self._States.Relocated, Box.CFrame, Box.Size, OverlapParamaters
				)
			-- Insert each overlapping part into the result table
			for _: number, Part: BasePart in ipairs(Overlapping) do
				table.insert(TouchingParts, Part)
			end
		end
		-- Explicitly nil out OverlapParamaters (optional GC aid, not strictly needed)
		OverlapParamaters = nil :: any
		-- Return the collected parts
		return TouchingParts
	else
		-- Fallback if using individual parts instead of boxes
		local TouchingParts: {BasePart} = {}
		-- Loop through each part in the zone
		for Index: number, Part: BasePart in ipairs(self._ZoneParts) do
			-- Get parts touching the given part using spatial overlap
			local Overlapping: {BasePart} = 
				WorldModel:GetPartsInPart(
					self._States.Relocated, Part, OverlapParamaters
				)
			-- Insert each overlapping part into the result table
			for _: number, Instance: BasePart in ipairs(Overlapping) do
				table.insert(TouchingParts, Instance)
			end
		end
		-- Clean up OverlapParamaters object reference
		OverlapParamaters = nil :: any
		-- Return all detected touching parts
		return TouchingParts	
	end
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- only if manualstepping Config is true and the holder type is a group, if not, this method is removed:
@native function Zone.Step(self: Zone, DeltaTime: number) 
	--=======================================================================================================>
	-- Begin Profiling:
	debug.profilebegin('Manual Step: Zone')
	-- If the ZoneEngine Class Exists, Step it:
	if self._Classes.ZoneEngine then self._Classes.ZoneEngine:EvaluateParallel(DeltaTime) end
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
		if RUN_CONTEXT == 'Client' then
			-- If the ZonePart is in the Array, and is still a descendant of the Game, the only reason for the Tag being removed(probably),
			-- Is because the Server Tags are being updated on that Instance, meaning the client tags here are overwritten:
			if ZonePartIndex and ZonePart:IsDescendantOf(game) and ZonePart.Parent ~= nil then ZonePart:AddTag(self._Tags.ZonePart); return end
		else
			-- Remove the tag:
			ZonePart:RemoveTag(self._Tags.ZonePart)	
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
		if RUN_CONTEXT == 'Client' then
			-- If the ZonePart is in the Array, and is still a descendant of the Game, the only reason for the Tag being removed(probably),
			-- Is because the Server Tags are being updated on that Instance, meaning the client tags here are overwritten:
			if HolderIndex and Holder:IsDescendantOf(game) and Holder.Parent ~= nil then Holder:AddTag(self._Tags.Holder); return end
		else
			-- Remove the tag:
			Holder:RemoveTag(self._Tags.Holder)	
		end

		-- If one is found, then Remove it from the Array:
		-- Remove the Part located at the Index from the Array:
		-- Return because theres nothing to update:
		if HolderIndex then table.remove(self._Instances.Holders, HolderIndex) else return end

		-- Clear the connection if it exists:
		if self._Connections[Holder] then self._Connections[Holder]:Disconnect(); self._Connections[Holder] = nil :: any end

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

		-- If the Config to not listen for new ZonePart's added is true, then return:
		if self._Config.NoZonePartAddedListening == true then return end

		-- Clear the connection if it exists:
		if self._Connections[Holder] then self._Connections[Holder]:Disconnect(); self._Connections[Holder] = nil :: any end

		-- Connect to the Holder's ChildAdded Event:
		self._Connections[Holder] = Holder.ChildAdded:Connect(function(Child: Instance) 
			-- If not a BasePart, return:
			if not Child:IsA('BasePart') then return end
			-- Add the ZonePart tag to the Part if it doesnt have it:
			if Child:HasTag(self._Tags.ZonePart) == false then 
				-- Add the tag locally:
				Child:AddTag(self._Tags.ZonePart)		
				-- If the ZoneId_Add remote event is present, fire to the server to ADD the Client Ids:
				UpdateIdsOnServer('Add', self.Identifier, self:GetZoneParts(), self:GetZonePartHolders())
			end	
		end)

		--===============================================================================================>
	end

	--=======================================================================================================>
end

-- Callback to update this zone from the actor:
@native function Zone._OnZoneSignalReceived(self: Zone, Purpose: string, ...)
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
	if Index == 'DetectionMode'     then return self._Config.DetectionMode end
	if Index == 'DetectionCoverage' then return self._Config.DetectionCoverage end
	if Index == 'DetectionMethod'   then return self._Config.DetectionMethod end

	if Index == 'Simulation' then return self._Config.Simulation end
	if Index == 'Rate'       then return self._Config.Rate end

	if Index == 'ExitDetectionMode'      then return self._Config.ExitDetectionMode end
	if Index == 'EnterDetectionMode'     then return self._Config.EnterDetectionMode end
	if Index == 'EnterDetectionCoverage' then return self._Config.EnterDetectionCoverage end
	if Index == 'ExitDetectionCoverage'  then return self._Config.ExitDetectionCoverage end

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
	if Index == '_ZoneBoxes' or Index == 'ZoneBoxes' then return if self.ContainerType == 'Boxes' then self.Container else nil end
	--=======================================================================================================>
	if Index == '_ZoneParts' or Index == 'ZoneParts' then return self._Instances.ZoneParts end
	if Index == '_Holders'   then return self._Instances.Holders end
	--=======================================================================================================>
	if self.Signals[Index] then return self.Signals[Index] end
	-- Check if the Index is one of the Signal Names and then Check if it doesnt exist.
	-- If it doesnt exist, dynamically create the Signal and then Return it:
	if table.find(SIGNAL_KEYS, Index) and not self.Signals[Index] then
		-- Check Client only Signals
		if (Index == 'LocalPlayerEntered' or Index == 'LocalPlayerExited') and RUN_CONTEXT ~= 'Client' then return nil end
		-- Construct a new Signal:
		self.Signals[Index] = GoodSignal.New()
		-- Add callback functions:
		self.Signals[Index]:_SetOnConnectionCallback(function() UpdateActivity(self) end)
		self.Signals[Index]:_SetOnDisconnectionCallback(function() UpdateActivity(self) end)
		-- Return the newly created signal:
		return self.Signals[Index]
	end
	--=======================================================================================================>
	-- If Index is in the immediate Module tree, return that value:			
	if Zone[Index] then return Zone[Index] end
	--=======================================================================================================>
	-- Return False if all else fails!
	return nil 
	--=======================================================================================================>
end

-- Create the New Index function:
function Zone.__newindex(self: Zone, Index: string, Value: any)
	--=======================================================================================================>
	if Index == 'EnterDetection' then SetConfig(self, 'EnterDetection', 'Detection', Value); return end
	if Index == 'ExitDetection'  then SetConfig(self, 'ExitDetection',  'Detection', Value); return end
	--=======================================================================================================>
	--if Index == 'MetaData' then rawset(self :: any, 'MetaData', Value) return end
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