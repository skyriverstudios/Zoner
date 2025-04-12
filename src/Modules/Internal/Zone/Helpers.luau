--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zone]: Helpers')

-- Define Module table
local Helpers: Helpers = {}

--===========================================================================================================================>
--[ DEFINE GLOBALS: ]


local Enums   = require(`../Enums`)
local Regions = require(`./Regions`)

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local Types = require(`../../../Types`)

-- Export the Module Type:
export type Helpers = typeof(Helpers)

--===========================================================================================================================>

-- Initialization function to start/setup the Object's initial data:
function Helpers.GetZonePartsFromContainer(self: Helpers, Container: Types.ZoneContainer, ContainerType: Types.ZoneContainerType?): ({BasePart}, {Instance})
	--=======================================================================================================>
	-- Assert Proper Paramaters:
	assert(Container ~= nil, `[Zoner]: 'Helpers': (GetZonePartsFromContainer) -> Paramater: 'Container' was nil`)
	--=======================================================================================================>
	-- Define a ZoneParts array and a Holders Array:
	local ZoneParts: {BasePart},  Holders: {Instance} = {}, {}
	--=======================================================================================================>
	-- Grab the String Type of the Container Variable:
	ContainerType = ContainerType or self:GetZoneContainerType(Container) :: Types.ZoneContainerType
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
function Helpers.GetZoneContainerType(self: Helpers, Container: Types.ZoneContainer): Types.ZoneContainerType
	--=======================================================================================================>
	
	-- Assert Proper Paramaters:
	assert(Container ~= nil, `[Zoner]: 'Helpers': (GetZoneContainerType) -> Paramater: 'Container' was nil`)
	
	-- Define the ZoneContainerType:
	local ZoneContainerType: Types.ZoneContainerType = 'Part'

	--=======================================================================================================>

	-- Grab the String Type of the Container Variable:
	local ContainerType: string = typeof(Container)

	-- If the Container Type is a Table, get all the ZoneParts from inside the Table:
	-- Else if the Container Type is an Instance, get all the Decendants that are ZoneParts:
	if ContainerType == "table" then
		-- Loop through Table or Array of ZoneParts:
		for Key, Unknown in pairs(Container :: {any}) do
			if typeof(Unknown) == 'Instance' then
				if Unknown:IsA("BasePart") then ZoneContainerType = 'TableOPart'; break end
			elseif typeof(Unknown) == 'table' then
				if Unknown['CFrame'] or Unknown['Size'] then ZoneContainerType = 'TableOBox'; break end
			else
				ZoneContainerType = 'TableOPart'; break
			end
		end
	elseif ContainerType == "Instance" then
		-- Create a local typed reference:
		local _Container: Model | BasePart | Folder = Container :: Model | BasePart | Folder
		-- Check type of Instance:
		if _Container:IsA("BasePart") then
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
function Helpers.ArePartsAllBlocks(PartsArray: {BasePart}): boolean
	--=======================================================================================================>
	-- Assert Proper Paramaters:
	assert(PartsArray ~= nil, `[Zoner]: 'Helpers': (ArePartsAllBlocks) -> Paramater: 'PartsArray' was nil`)

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

--- Initialization function to start/setup the Object's initial data:
function Helpers.SetAutoSettings(Settings: Types.ZoneSettings, ContainerType: Types.ZoneContainerType, ZoneParts: Types.ZoneParts, ZoneBoxes: Types.ZoneBoxes?)
	--=======================================================================================================>
	-- Assert Proper Paramaters:
	assert(Settings ~= nil, `[Zoner]: 'Helpers': (SetAutoSettings) -> Paramater: 'Settings' was nil`)
	-- Assert Proper Paramaters:
	assert(ContainerType ~= nil, `[Zoner]: 'Helpers': (SetAutoSettings) -> Paramater: 'ContainerType' was nil`)
	-- Assert Proper Paramaters:
	assert(ZoneParts ~= nil, `[Zoner]: 'Helpers': (SetAutoSettings) -> Paramater: 'ZoneParts' was nil`)
	--=======================================================================================================>
	
	-- If the Bounds Setting is Automatic, Determine whether to Run PerPart or BoxExact:
	if Settings.Bounds == Enums.Bounds.Automatic then

		if ZoneBoxes then
			if #ZoneBoxes > 1 then
				Settings.Bounds = Enums.Bounds.PerPart
			else
				Settings.Bounds = Enums.Bounds.BoxExact
			end
		else
			if Helpers.ArePartsAllBlocks(ZoneParts) then 

				-- Define a Variable:
				local ZonePartsAreRotated: boolean = false;
				-- Loop through the ZoneParts to add tags:
				for Index: number, Part: BasePart in ipairs(ZoneParts) do
					if not Part.CFrame.Rotation:FuzzyEq(CFrame.new(), 0.00001) then ZonePartsAreRotated = true; break; end
				end

				if ZonePartsAreRotated or #ZoneParts > 1 then
					Settings.Bounds = Enums.Bounds.PerPart
				else
					Settings.Bounds = Enums.Bounds.BoxExact
				end
			else
				Settings.Bounds = Enums.Bounds.PerPart
			end
		end

	end

	-- If the DetectionMethod Setting is Automatic, Determine whether to Run Efficient, Simple or Complex:
	if Settings.DetectionMethod == Enums.DetectionMethod.Automatic then

		if Settings.Bounds == Enums.Bounds.BoxExact or Settings.Bounds == Enums.Bounds.BoxVoxel or ZoneBoxes then
			Settings.DetectionMethod = Enums.DetectionMethod.Efficient		
		else
			-- Define ZonePart Type Grouping Booleans:
			local AllSpheresAndBlocks: boolean = true
			local _AllComplex:          boolean = true
			local AllSpheres:          boolean = true
			local AllBlocks:           boolean = true

			-- Loop through all the ZoneParts:
			for Index: number, ZonePart in ipairs(ZoneParts) do
				-- Grab the PartProperties of the ZonePart:
				local ZonePartType = Regions:GetPartType(ZonePart)
				-- Determine the Makeup of all the ZoneParts:
				if ZonePartType == 'Block' then
					AllSpheres, _AllComplex = false, false
				elseif ZonePartType == 'Sphere' then
					AllBlocks, _AllComplex  = false, false
				elseif ZonePartType == 'Complex' then
					AllBlocks, AllSpheres, AllSpheresAndBlocks = false, false, false
				end
			end

			-- If AllBlocks, AllSpheres or a Mix of Both, then Run Efficient.
			-- If AllComplex, then Run Complex.
			-- If its a mixed back of Spheres, Complex and Blocks, then Keep it Simple:
			if AllBlocks or AllSpheres or AllSpheresAndBlocks then
				Settings.DetectionMethod = Enums.DetectionMethod.Efficient
			else
				Settings.DetectionMethod = Enums.DetectionMethod.Complex
			end
		end

	end

	-- If our DetectionMethod is Complex, and our ContainerType is a TableOfBoxes, downgrade the DetectionMethod cause TableOfBoxes are incompatabile:
	if Settings.DetectionMethod == Enums.DetectionMethod.Complex and ContainerType == 'TableOBox' then
		Settings.DetectionMethod = Enums.DetectionMethod.Simple
	end
	
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(Helpers) :: Helpers

--===========================================================================================================================>