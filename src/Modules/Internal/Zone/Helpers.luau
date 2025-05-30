--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zone]: Helpers')

-- Define Module table
local Helpers: Helpers = {}

--===========================================================================================================================>
--[ DEPENDENCIES: ]


local Enums   = require(`../Enums`)
local Regions = require(`./Regions`)

--===========================================================================================================================>
--[ CONSTANTS: ]

local RANDOM = Random.new()

--===========================================================================================================================>
--[ TYPES: ]


-- This will inject all types into this context.
local Types = require(`../../../Types`)

-- Export the Module Type:
export type Helpers = typeof(Helpers)

--===========================================================================================================================>

-- Initialization function to start/setup the Object's initial data:
function Helpers.GetZonePartsFromContainer(Container: Types.ZoneContainer, ContainerType: Types.ZoneContainerType?): ({BasePart}, {Instance})
	--=======================================================================================================>
	-- Assert Proper Paramaters:
	assert(Container ~= nil, `[Zoner]: 'Helpers': (GetZonePartsFromContainer) -> Paramater: 'Container' was nil`)
	--=======================================================================================================>
	-- Define a ZoneParts array and a Holders Array:
	local ZoneParts: {BasePart},  Holders: {Instance} = {}, {}
	--=======================================================================================================>
	-- Grab the String Type of the Container Variable:
	ContainerType = ContainerType or Helpers.GetZoneContainerType(Container) :: Types.ZoneContainerType
	--=======================================================================================================>
	-- If the Container Type is a Table, get all the ZoneParts from inside the Table:
	-- Else if the Container Type is an Instance, get all the Decendants that are ZoneParts:
	if ContainerType == "Parts" then
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
function Helpers.GetZoneContainerType(Container: Types.ZoneContainer): Types.ZoneContainerType
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
				if Unknown:IsA("BasePart") then ZoneContainerType = 'Parts'; break end
			elseif typeof(Unknown) == 'table' then
				if Unknown['CFrame'] or Unknown['Size'] then ZoneContainerType = 'Boxes'; break end
			else
				ZoneContainerType = 'Parts'; break
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
function Helpers.SetAutoConfig(Config: Types.ZoneConfig, ContainerType: Types.ZoneContainerType, ZoneParts: Types.ZoneParts, ZoneBoxes: Types.ZoneBoxes?)
	--=======================================================================================================>
	-- Assert Proper Paramaters:
	assert(Config ~= nil, `[Zoner]: 'Helpers': (SetAutoConfig) -> Paramater: 'Config' was nil`)
	-- Assert Proper Paramaters:
	assert(ContainerType ~= nil, `[Zoner]: 'Helpers': (SetAutoConfig) -> Paramater: 'ContainerType' was nil`)
	-- Assert Proper Paramaters:
	assert(ZoneParts ~= nil, `[Zoner]: 'Helpers': (SetAutoConfig) -> Paramater: 'ZoneParts' was nil`)
	--=======================================================================================================>

	-- If the Bounds Setting is Automatic, Determine whether to Run PerPart or BoxExact:
	if Config.Bounds == Enums.Bounds.Automatic then

		if ZoneBoxes then
			if #ZoneBoxes > 1 then
				Config.Bounds = Enums.Bounds.PerPart
			else
				Config.Bounds = Enums.Bounds.BoxExact
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
					Config.Bounds = Enums.Bounds.PerPart
				else
					Config.Bounds = Enums.Bounds.BoxExact
				end
			else
				Config.Bounds = Enums.Bounds.PerPart
			end
		end

	end

	-- If the DetectionMethod Setting is Automatic, Determine whether to Run Efficient, Simple or Complex:
	if Config.DetectionMethod == Enums.DetectionMethod.Automatic then

		if Config.Bounds == Enums.Bounds.BoxExact or Config.Bounds == Enums.Bounds.BoxVoxel or ZoneBoxes then
			Config.DetectionMethod = Enums.DetectionMethod.Efficient		
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
				Config.DetectionMethod = Enums.DetectionMethod.Efficient
			else
				Config.DetectionMethod = Enums.DetectionMethod.Complex
			end
		end

	end

	-- If our DetectionMethod is Complex, and our ContainerType is a TableOfBoxes, downgrade the DetectionMethod cause TableOfBoxes are incompatabile:
	if Config.DetectionMethod == Enums.DetectionMethod.Complex and ContainerType == 'Boxes' then
		Config.DetectionMethod = Enums.DetectionMethod.Simple
	end

	if Config.DetectionCoverage == Enums.DetectionCoverage.Automatic then
		Config.DetectionCoverage = Enums.DetectionCoverage.Center
	end
	
	if Config.DetectionMode == Enums.DetectionMode.Automatic then
		Config.DetectionMode = Enums.DetectionMode.Point
	end

	--=======================================================================================================>
end

-- Get a random item from an array using Random.new()
@native function Helpers.GetRandomArrayItem<T>(Array: {T}): T?
	--=======================================================================>
	-- If the array is empty, return nil:
	if #Array == 0 then return nil end
	-- Return the item at the random index:
	return Array[RANDOM:NextInteger(1, #Array)]
	--=======================================================================>
end
--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(Helpers) :: Helpers

--===========================================================================================================================>