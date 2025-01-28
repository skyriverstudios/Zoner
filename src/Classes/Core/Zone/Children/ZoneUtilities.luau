--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Define Module table
local ZoneUtilitiesModule: ZoneUtilitiesModule = {}

--===========================================================================================================================>

-- Require the Trove Module for Cleanup:
local SharedTypes = require(script.Parent.Parent.Parent.Parent.Parent.Types.SharedTypes);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- Insert the Object Types:
export type ZoneUtilitiesModule = typeof(ZoneUtilitiesModule)

--===========================================================================================================================>

-- Initialization function to start/setup the Object's initial data:
function ZoneUtilitiesModule.GetZonePartsFromContainer(self: ZoneUtilitiesModule, Container: SharedTypes.ZoneContainer, ContainerType: SharedTypes.ZoneContainerType?): ({BasePart}, {Instance})
	--=======================================================================================================>
	-- Define a ZoneParts array and a Holders Array:
	local ZoneParts: {BasePart},  Holders: {Instance} = {}, {}
	--=======================================================================================================>
	-- Grab the String Type of the Container Variable:
	ContainerType = ContainerType or self:GetZoneContainerType(Container) :: SharedTypes.ZoneContainerType
	--=======================================================================================================>
	-- If the Container Type is a Table, get all the ZoneParts from inside the Table:
	-- Else if the Container Type is an Instance, get all the Decendants that are ZoneParts:
	if ContainerType == "TableOPart" then
		--============================================>
		-- Loop through Table or Array of ZoneParts:
		for Key, Part: BasePart in pairs(Container :: {BasePart} | {[any]: BasePart}) do
			-- If Part is a BasePart, insert as a ZonePart:
			if Part:IsA("BasePart") then table.insert(ZoneParts, Part) end
		end
		--============================================>		
	elseif ContainerType == "Part" then
		--============================================>
		-- Container is a ZonePart, insert it:
		table.insert(ZoneParts, Container :: BasePart)
		--============================================>
	elseif ContainerType == "Holder" then
		--============================================>
		-- Create a local typed reference:
		local Container2: (Model | BasePart | Folder) = Container :: (Model | BasePart | Folder)
		--============================================>
		-- Container is a Holder Instance, so insert it:
		table.insert(Holders, Container2)
		--============================================>
		-- Get all Descendants of Container:
		local ContainerDescendants: {Instance} = Container2:GetDescendants() :: {Instance}
		-- Loop through all the descendants of the Container Holder to add as ZoneParts or Holders:
		for Index: number, Part: Instance in ipairs(ContainerDescendants) do
			-- If its a BasePart, its a ZonePart, else a Holder:
			if Part:IsA("BasePart") then
				-- If Part is a BasePart, insert as a ZonePart:
				table.insert(ZoneParts, Part)
			elseif Part:IsA("Model") or Part:IsA("Folder") or Part:IsA("Configuration") then
				-- If Part is anything else, insert as a Holder:
				table.insert(Holders, Part)
			end
		end

		-- Clear from Memory:
		ContainerDescendants = nil :: any
		--============================================>
	end
	--=======================================================================================================>
	-- Return the two filled Arrays (possibly):
	return ZoneParts, Holders
	--=======================================================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function ZoneUtilitiesModule.GetZoneContainerType(self: ZoneUtilitiesModule, Container: SharedTypes.ZoneContainer): SharedTypes.ZoneContainerType
	--=======================================================================================================>

	-- Define the ZoneContainerType:
	local ZoneContainerType: SharedTypes.ZoneContainerType = 'Part'

	--=======================================================================================================>

	-- Grab the String Type of the Container Variable:
	local ContainerType: string = typeof(Container)

	-- If the Container Type is a Table, get all the ZoneParts from inside the Table:
	-- Else if the Container Type is an Instance, get all the Decendants that are ZoneParts:
	if ContainerType == "table" then
		-- Loop through Table or Array of ZoneParts:
		for Key, Unknown in pairs(Container :: {any}) do
			if typeof(Unknown) == 'Instance' then
				if Unknown:IsA("BasePart") then ZoneContainerType = 'TableOPart' break end
			elseif typeof(Unknown) == 'table' then
				if Unknown['CFrame'] or Unknown['Size'] then ZoneContainerType = 'TableOBox' break end
			else
				ZoneContainerType = 'TableOPart' break
			end
		end
	elseif ContainerType == "Instance" then
		-- Create a local typed reference:
		local Container: Model | BasePart | Folder = Container :: Model | BasePart | Folder
		-- Check type of Instance:
		if Container:IsA("BasePart") then
			ZoneContainerType = 'Part'
		else
			ZoneContainerType = 'Holder'
		end
	end

	--=======================================================================================================>

	-- Return the ZoneContainerType:
	return ZoneContainerType

	--=======================================================================================================>
end

--===========================================================================================================================>

--- Initialization function to start/setup the Object's initial data:
function ZoneUtilitiesModule.ArePartsAllBlocks(self: ZoneUtilitiesModule, PartsArray: {BasePart}): boolean
	--=======================================================================================================>

	-- Define the Variable boolean as true:
	local AllPartsAreBlocks: boolean = true

	-- Loop through all the ZoneParts, checking each Block's Shape Name.
	-- If any block does not have the Shape Name Block, then the boolean evaluates to false:
	for Index: number, Part: BasePart in ipairs(PartsArray) do
		--=============================================================================>
		-- If the ZonePart is a Part specifically, then check its Shape Name:
		-- If the Shape name is not a block, then set bool to false and break loop:
		-- Else Set bool to false and break loop:
		if Part:IsA('Part') then
			if Part.Shape.Name ~= "Block" then AllPartsAreBlocks = false; break end
		else
			AllPartsAreBlocks = false; break 
		end
		--=============================================================================>
	end

	-- If the Array is empty set variable to false:
	if #PartsArray < 1 then AllPartsAreBlocks = false end

	-- Return the boolean:
	return AllPartsAreBlocks

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(ZoneUtilitiesModule) :: ZoneUtilitiesModule

--===========================================================================================================================>