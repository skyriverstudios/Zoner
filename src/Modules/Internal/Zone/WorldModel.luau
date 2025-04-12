--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>
-- WorldModel

-- Original Author:
-- Ben Horton (ForeverHD)

-- Restructure/Rewrite:
-- 7/12/2024
-- IISato
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zone]: WorldModel')

-- Define Module table:
local WorldModelModule = {Values = {}}
WorldModelModule.__index = WorldModelModule

--===========================================================================================================================>
--[ DEFINE CONSTANTS: ]


-- ObjectValue:
local ZONER_POINTER: ObjectValue

-- Function Methods:
local WORLD_MODEL_METHODS = {
	GetPartBoundsInRadius = function(WorldModel: WorldModel, ...) return WorldModel:GetPartBoundsInRadius(...) end,
	GetPartBoundsInBox    = function(WorldModel: WorldModel, ...) return WorldModel:GetPartBoundsInBox(...) end,
	GetPartsInPart        = function(WorldModel: WorldModel, ...) return WorldModel:GetPartsInPart(...) end,
}

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- Insert Object type:
export type WorldModelModule = typeof(WorldModelModule)

--===========================================================================================================================>
--[ FUNCTIONS: ]


-- Module Method to Combine the WorldModel Arrays:
@native
local function DispatchOverlapMethod(MethodName: string, Relocated: boolean, ...): {BasePart}
	--=======================================================================================================>
	-- Get the Workspace WorldRoot Method Results:
	local Results: {BasePart} = workspace[MethodName](workspace, ...)
	--=======================================================================================================>
	-- If an Additional WorldModel exists, Call the Method on it, and Add the Results to the Original Results Array:
	if Relocated and WorldModelModule.Values['WorldModel'] then
		--===============================================================>
		-- Grab the Additional Results as an Array:
		local AdditionalResults: {BasePart} = WORLD_MODEL_METHODS[MethodName](WorldModelModule.Values['WorldModel'], ...)
		-- Loop through them all, inserting each into the Original Results Array to Combine the Arrays:
		for Index: number, Result: BasePart in ipairs(AdditionalResults) do table.insert(Results, Result) end
		--===============================================================>
	end
	-- Return the Results Array:
	return Results
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ METHODS: ]


-- Module Method to Create a WorldModel Instance or return the existing one:
function WorldModelModule.GetWorldModel(self: WorldModelModule): WorldModel
	--=======================================================================================================>
	if self.Values['WorldModel'] then return self.Values['WorldModel'] end
	--=======================================================================================================>

	-- If the ZonerPointer Constant is nil, set it:
	if not ZONER_POINTER then 
		ZONER_POINTER = 
			script.Parent.Parent.Parent.Parent:WaitForChild(`ZonerPointer:{if game["Run Service"]:IsServer() then 'Server' else 'Client'}`, false)
	end

	-- If there is already a WorldModel Found in the Service, then use that:
	-- This is Useful if we are using Actors with the Zones:
	local ExistingWorldModel = ZONER_POINTER.Value and ZONER_POINTER.Value:FindFirstChild('WorldModel')
	-- If its found, continue:
	if ExistingWorldModel then
		-- Set the Module Reference:
		self.Values.WorldModel = ExistingWorldModel :: WorldModel
		-- Return the WorldModel:
		return self.Values.WorldModel
	end
	--=======================================================================================================>

	if not ZONER_POINTER or not ZONER_POINTER.Value then
		error("ZonerPointer or its value is missing. Cannot assign WorldModel.")
	end

	-- Create a new WorldModel Instance:
	self.Values.WorldModel = Instance.new("WorldModel") 
	self.Values.WorldModel.Name = "WorldModel"
	self.Values.WorldModel.Parent = ZONER_POINTER.Value
	--=======================================================================================================>
	-- Return the WorldModel Instance:
	return self.Values.WorldModel
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Module Method to Return the Parts in Parts Instance Array:
@native
function WorldModelModule.GetPartsInPart(self: WorldModelModule, Relocated: boolean, Part: BasePart, OverlapParam: OverlapParams): {BasePart}
	return DispatchOverlapMethod("GetPartsInPart", Relocated, Part, OverlapParam)
end

-- Module Method to Return the Parts Bounds in Box Instance Array:
@native
function WorldModelModule.GetPartBoundsInBox(self: WorldModelModule, Relocated: boolean, CFrame: CFrame, Size: Vector3, OverlapParam: OverlapParams): {BasePart}
	return DispatchOverlapMethod("GetPartBoundsInBox", Relocated, CFrame, Size, OverlapParam)
end

-- Module Method to Return the Parts Bounds in Radius Instance Array:
@native
function WorldModelModule.GetPartBoundsInRadius(self: WorldModelModule, Relocated: boolean, Position: Vector3, Radius: number, OverlapParam: OverlapParams): {BasePart}
	return DispatchOverlapMethod("GetPartBoundsInRadius", Relocated, Position, Radius, OverlapParam)
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(WorldModelModule) :: WorldModelModule

--===========================================================================================================================>