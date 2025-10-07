--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zone]: Groups')

-- Define Module table
local Groups = {}

--===========================================================================================================================>
--[ TYPES: ]


-- This will inject all types into this context.
local Types = require(`../../../Types`)

export type ZoneGroupData = { 
	Zones: {[string]: true}; Properties: Types.ZoneGroupProperties; AttributeChanged: RBXScriptConnection? 
}

export type ZoneGroups = {
	[string]: ZoneGroupData
};

--===========================================================================================================================>

-- Create the table that stores the Zones and apply a type:
Groups.Groups     = {}  :: {[string]: ZoneGroupData}
Groups.GroupAdded = nil :: RBXScriptConnection?;

--===========================================================================================================================>

local function SetupGroup(Group: Types.GroupsFolderGroup)
	--===========================================================================>
	
	
	--===========================================================================>
end

--===========================================================================================================================>


function Groups.SetupListeners(ZonerFolder: Types.ZonerFolder)
	--=======================================================================================================>

	-- Loop through the children of the Groups to setup any that are already created:
	for Index: number, Group in ipairs(ZonerFolder.Groups:GetChildren()) do SetupGroup(Group :: Types.GroupsFolderGroup) end

	-- Connect to the GroupAdded to setup Groups as they are created:
	Groups.GroupAdded = ZonerFolder.Groups.ChildAdded:Connect(SetupGroup :: any)

	--=======================================================================================================>
end

function Groups.StopListeners(ZonerFolder: Types.ZonerFolder)
	--=======================================================================================================>

	for Key: string, Data: ZoneGroupData in Groups.Groups do
		if Data.AttributeChanged then
			Data.AttributeChanged:Disconnect()
			Data.AttributeChanged = nil 
		end
	end
	
	table.clear(Groups.Groups)

	if Groups.GroupAdded then
		Groups.GroupAdded:Disconnect()
		Groups.GroupAdded = nil :: any
	end

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(Groups)

--===========================================================================================================================>