--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory("[Zone]: Groups")

--[=[
	@class Groups
	@private

	Manages **Zone Groups** within a Zoner system.  
	Each Group keeps a fast in-memory dictionary of Zone IDs (attributes on a `Zones` folder) so lookups like
	`IsZoneInGroup` are O(1).

	**Design (Module-as-Table, shared per-VM)**
	- Exposes a **module table** that caches group data.
	- Because it’s a table, any script that `require`s it **within the same VM** shares the same state (an in-VM singleton).
	- Multiple modules in the same VM can read group properties from this shared cache without walking the DataModel.

	**VM Registration (Actors)**
	- Register this module inside **each** Zoner Actor VM: `require` it and call `InitializeActorListeners` with that VM’s `ZonerFolder`.
	- Each VM keeps its **own synchronized copy** of group data, automatically updated by attribute-change signals on that VM’s `ZonerFolder`.
	- This keeps groups and their properties up to date **in every Actor VM**, making property access fast and straightforward.

	**Lifecycle**
	- Call `InitializeActorListeners` once (per VM) with the root `ZonerFolder` to index existing groups and attach listeners.
	- Later, call `DeinitializeActorListeners` to disconnect signals and clear all cached data.

	**Data Flow**
	- Group folders live under `ZonerFolder.Groups`.
	- Each group contains a `Zones` `Configuration` whose attributes are Zone IDs with boolean values (`true` or `nil`).
	- Attribute changes on that `Zones` configuration drive the internal `Zones` map for the group.

	**Threading**
	- Uses `RBXScriptConnection` signals; none of the public APIs yield.

	@since 0.9.9
]=]
local Groups = {}

--===========================================================================================================================>
--[ TYPES: ]

-- This will inject all types into this context.
local Types = require(`../../Types`)

--[=[
	@interface ZoneGroupData
	@within Groups
	@field Zones { [string]: true? } --Map of ZoneId -> true (present) or nil (absent) for O(1) membership checks.
	@field ZonesFolder Configuration --Reference to the group's `Zones` folder (source of truth via attributes).
	@field Properties ZoneGroupProperties --Snapshot of group properties from `GetAttributes()` on the group.
	@field AttributeChanged RBXScriptConnection --Connection tracking attribute changes on `ZonesFolder`.

	@since 0.9.9
]=]
export type ZoneGroupData = {
	Zones: { [string]: true? },
	ZonesFolder: Configuration,
	Properties: ZoneGroupProperties,
	AttributeChanged: RBXScriptConnection,
}

--[=[
	@interface ZoneGroupProperties
	@within Groups
	@field Exclusive boolean --Whether tracked items can be in more than one zone of this group simultaneously.

	@since 0.9.8
]=]
export type ZoneGroupProperties = {
	Exclusive: boolean
};

--[=[
	@type ZoneGroups {[string]: ZoneGroupData}
	@within Groups
	Map of group name -> `ZoneGroupData`.
]=]
export type ZoneGroups = {
	[string]: ZoneGroupData,
}

--===========================================================================================================================>

--[=[
	@prop ZoneGroups ZoneGroups
	@within Groups
	Holds all known groups keyed by group name. Populated by `InitializeActorListeners`. Cleared by `DeinitializeActorListeners`.
]=]
Groups.ZoneGroups       = {} :: { [string]: ZoneGroupData }
--[=[
	@prop ZoneGroupAdded RBXScriptConnection?
	@within Groups
	Connection for when a group is added under `ZonerFolder.Groups`. Established by `InitializeActorListeners`.
]=]
Groups.ZoneGroupAdded   = nil :: RBXScriptConnection?
--[=[
	@prop ZoneGroupRemoved RBXScriptConnection?
	@within Groups
	Connection for when a group is removed from `ZonerFolder.Groups`. Established by `InitializeActorListeners`.
]=]
Groups.ZoneGroupRemoved = nil :: RBXScriptConnection?
--[=[
	@prop ActorInitialized boolean
	@within Groups
	Whether this Groups singleton has been initialized by the VM that required it.
]=]
Groups.ActorInitialized = false :: boolean

--===========================================================================================================================>

--[=[
	@private
	@within Groups
	@since 0.9.9
	@param Group Types.GroupsFolderGroup The groups-folder child representing a single zone group.
	Initializes a group's cached data and begins listening to its `Zones` attribute changes.
]=]
local function SetupGroup(Group: Types.GroupsFolderGroup)
	--===========================================================================>

	-- Store a local reference to the created dictionary so that we can have it as the only captured local variable:
	local GroupData: ZoneGroupData

	-- Create the GroupData dictionary in the Groups table:
	Groups.ZoneGroups[Group.Name] = {
		-- Create a dictionary for the ZoneIds that are registered with this Group:
		Zones = Group.Zones:GetAttributes() or {},
		-- Store a reference to the ZonesFolder so that we can access it internally:
		ZonesFolder = Group.Zones,
		-- Store the dictionary of properties related to this Group:
		Properties = Group:GetAttributes() :: ZoneGroupProperties,
		-- Connect a AttributeChanged event to the ZonerFolder so that we can update our internal table whenever Zones are added or removed from the Group:
		AttributeChanged = Group.Zones.AttributeChanged:Connect(function(ZoneId: string)
			-- Update the internal Zones table. If the attribute returned on the ZonesFolder is nil, it clears the ZoneId reference, if its not, it set it to true.
			-- Remembering the ZonesFolder has attributes for ZoneIds that are either true or nil:
			GroupData.Zones[ZoneId] = GroupData.ZonesFolder:GetAttribute(ZoneId) :: true?
		end),
	}

	-- Set local reference to the GroupData Dictionary:
	GroupData = Groups.ZoneGroups[Group.Name]

	--===========================================================================>
end

--[=[
	@private
	@within Groups
	@since 0.9.9
	@param Group Types.GroupsFolderGroup --The groups-folder child to tear down.
	Releases listeners, clears cached tables, and removes the group from `ZoneGroups`.
]=]
local function RemoveGroup(Group: Types.GroupsFolderGroup)
	--===========================================================================>

	-- Reference the GroupData Dictionary:
	local GroupData: ZoneGroupData = Groups.ZoneGroups[Group.Name]
	-- If no GroupData could be indexed, warn:
	if not GroupData then
		warn(`[Zoner]:// No group by the name of "{Group.Name}" was able to be removed`)
		return
	end

	-- Clear up the AttributeChanged signal connection:
	if GroupData.AttributeChanged then
		GroupData.AttributeChanged:Disconnect()
		GroupData.AttributeChanged = nil :: any
	end

	-- Clear the Zones table:
	table.clear(GroupData.Zones)
	-- Clear the data table:
	table.clear(GroupData)

	-- Clear the Group from the main Groups table:
	Groups.ZoneGroups[Group.Name] = nil :: any

	--===========================================================================>
end

--===========================================================================================================================>

--[=[
	@function InitializeActorListeners
	@within Groups
	@since 0.9.9

	Initialize listeners on the root Zoner folder (per VM).

	@param ZonerFolder Types.ZonerFolder --The root folder containing the `Groups` container and group children.

	Scans existing groups under `ZonerFolder.Groups` and attaches listeners so the internal cache mirrors:
	- Group property attributes on the group folder.
	- Zone membership attributes on each group's `Zones` configuration.
]=]
function Groups.InitializeActorListeners(ZonerFolder: Types.ZonerFolder)
	--=======================================================================================================>
	-- If the Groups Singleton is already Initialized then return:
	if Groups.ActorInitialized then return end; Groups.ActorInitialized = true;

	-- Connect to the GroupAdded to setup Groups as they are created:
	Groups.ZoneGroupAdded = ZonerFolder.Groups.ChildAdded:Connect(SetupGroup :: any)
	-- Connect to the GroupRemoved to remove Groups as they are deleted:
	Groups.ZoneGroupRemoved = ZonerFolder.Groups.ChildAdded:Connect(RemoveGroup :: any)

	-- Loop through the children of the Groups to setup any that are already created:
	for Index: number, Group in ipairs(ZonerFolder.Groups:GetChildren()) do
		SetupGroup(Group :: Types.GroupsFolderGroup)
	end
	--=======================================================================================================>
end

--[=[
	@function DeinitializeActorListeners
	@within Groups
	@since 0.9.9

	Stop and clean up all listeners and cached state created by `InitializeActorListeners`.

	Disconnects per-group attribute listeners, clears cached maps, and disconnects group add/remove listeners.
]=]
function Groups.DeinitializeActorListeners()
	--=======================================================================================================>
	-- If the Groups Singleton is already Initialized then return:
	if Groups.ActorInitialized == false then return end; Groups.ActorInitialized = false;

	-- Loop through all the ZoneGroups and clear out their Zones and Data:
	for Key: string, GroupData: ZoneGroupData in Groups.ZoneGroups do
		-- Clear up the AttributeChanged signal connection:
		if GroupData.AttributeChanged then
			GroupData.AttributeChanged:Disconnect()
			GroupData.AttributeChanged = nil :: any
		end
		-- Clear the Zones table:
		table.clear(GroupData.Zones)
		-- Clear the data table:
		table.clear(GroupData)
	end

	-- Clear all Groups from the Dictionary:
	table.clear(Groups.ZoneGroups)

	-- Clear out the Signal Connection:
	if Groups.ZoneGroupAdded then
		Groups.ZoneGroupAdded:Disconnect()
		Groups.ZoneGroupAdded = nil :: any
	end
	-- Clear out the Signal Connection:
	if Groups.ZoneGroupRemoved then
		Groups.ZoneGroupRemoved:Disconnect()
		Groups.ZoneGroupRemoved = nil :: any
	end
	--=======================================================================================================>
end

--[=[
	@function IsZoneInGroup
	@within Groups
	@since 0.9.9

	Check whether a ZoneId is currently recorded in a given group.

	@param ZoneId string --The Zone identifier (attribute name on the group's `Zones` folder).
	@param GroupKey string --The group name key (index into `ZoneGroups`).
	@return boolean --Whether the given `ZoneId` is part of the group right now.
]=]
function Groups.IsZoneInGroup(ZoneId: string, GroupKey: string): boolean
	return Groups.ZoneGroups[GroupKey].Zones[ZoneId] or false
end

--===========================================================================================================================>

--[=[
	@function CreateGroup
	@within Groups
	@since 0.9.9

	Create a new group folder under `ZonerFolder.Groups` for **serial** execution contexts, mirror its properties,
	and begin listening to its `Zones` attributes.

	@param GroupName string --Name of the group to create.
	@param Properties ZoneGroupProperties --Properties to set as attributes on the group.
	@param ZonerFolder Types.ZonerFolder --The owning Zoner folder for this VM.
]=]
function Groups.CreateGroup(GroupName: string, Properties: ZoneGroupProperties, ZonerFolder: Types.ZonerFolder)
	--=======================================================================================================>
	-- Create the Group Folder Instance for VM communication:
	local Group_Folder = Instance.new('Configuration')
	Group_Folder.Name = GroupName

	-- Set the properties on the GroupFolder:
	for Key: string, Value in pairs(Properties) do
		Group_Folder:SetAttribute(Key, Value)
	end

	Group_Folder.Parent = ZonerFolder.Groups 

	-- Create the Zones Folder Instance to track Zones and their Ids, registed to this group:
	local Zones_Folder = Instance.new('Configuration')
	Zones_Folder.Name = 'Zones'
	Zones_Folder.Parent = Group_Folder;

	-- Setup the Group with listening in Serial:
	SetupGroup(Group_Folder :: Types.GroupsFolderGroup)
	--=======================================================================================================>
end

--[=[
	@function AddZoneToGroup
	@within Groups
	@since 0.9.9

	Bind a zone to a group in **serial** contexts by setting the ID attribute on the group's `Zones` config
	and updating the in-memory cache.

	@param ZoneId string --Zone identifier to add.
	@param GroupName string --Target group key.
	@param ZonerFolder Types.ZonerFolder --The owning Zoner folder for this VM.
]=]
function Groups.AddZoneToGroup(ZoneId: string, GroupName: string, ZonerFolder: Types.ZonerFolder)
	--=======================================================================================================>
	-- Find the GroupFolder underneath the Groups Folder:
	local Group_Folder: Types.GroupsFolderGroup? = ZonerFolder.Groups:FindFirstChild(GroupName) :: any
	-- If Group Folder is found, Bind the Zone to the Group:
	if Group_Folder then
		-- Set the table group hash to true:
		Groups.ZoneGroups[GroupName].Zones[ZoneId] = true
		-- Set the Attribute on the Zones Folder to the Id, to record that this Zone is bound to this group:
		Group_Folder.Zones:SetAttribute(ZoneId, true)
	else
		warn(`[Groups]: 'AddZoneToGroup' | No Group exists by the name: "{GroupName}"`)
	end
	--=======================================================================================================>
end

--[=[
	@function RemoveZoneFromGroup
	@within Groups
	@since 0.9.9

	Unbind a zone from a group in **serial** contexts by clearing the ID attribute and cache entry.

	@param ZoneId string --Zone identifier to remove.
	@param GroupName string --Target group key.
	@param ZonerFolder Types.ZonerFolder --The owning Zoner folder for this VM.
]=]
function Groups.RemoveZoneFromGroup(ZoneId: string, GroupName: string, ZonerFolder: Types.ZonerFolder)
	--=======================================================================================================>
	-- Find the GroupFolder underneath the Groups Folder:
	local Group_Folder: Types.GroupsFolderGroup? = ZonerFolder.Groups:FindFirstChild(GroupName) :: any
	-- If Group Folder is found, Bind the Zone to the Group:
	if Group_Folder then
		-- Set the table group hash to nil:
		Groups.ZoneGroups[GroupName].Zones[ZoneId] = nil
		-- Set the Attribute on the Zones Folder to nil, to record that this Zone is no longer bound to this group:
		Group_Folder.Zones:SetAttribute(ZoneId, nil)
	else
		warn(`[Groups]: 'RemoveZoneFromGroup' | No Group exists by the name: "{GroupName}"`)
	end
	--=======================================================================================================>
end

--[=[
	@function RemoveZoneFromGroups
	@within Groups
	@private
	@since 0.9.9

	Remove a zone from **all** groups for this VM if present.

	@param ZoneId string --Zone identifier to purge.
	@param ZonerFolder Types.ZonerFolder --The owning Zoner folder for this VM.
]=]
function Groups.RemoveZoneFromGroups(ZoneId: string, ZonerFolder: Types.ZonerFolder)
	-- Loop through all the ZoneGroups registered, Check if Zone is in that Group, if so, Remove that Zone from that Group:
	for GroupKey, GroupData in Groups.ZoneGroups do
		if Groups.IsZoneInGroup(ZoneId, GroupKey) then Groups.RemoveZoneFromGroup(ZoneId, GroupKey, ZonerFolder) end
	end
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return Groups

--===========================================================================================================================>