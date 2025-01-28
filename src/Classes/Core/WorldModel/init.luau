--===========================================================================================================================>
--!native
--!strict
--===========================================================================================================================>
-- WorldModel

-- Original Author:
-- Ben Horton (ForeverHD)

-- Restructure/Rewrite:
-- 7/12/2024
-- IISato
--===========================================================================================================================>

-- Define Module table:
local WorldModelModule: WorldModelModule = {
	Values = {}; RunScope = if game["Run Service"]:IsServer() then 'Server' else 'Client' } :: WorldModelModule

WorldModelModule.__index = WorldModelModule

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types)

-- Insert Object type:
export type WorldModelModule = TypeDefinitions.WorldModelModule

--===========================================================================================================================>
--[ FUNCTIONS: ]
-- Defined Functions for the WorldModel Module:


-- Module Method to Create a WorldModel Instance or return the existing one:
function WorldModelModule.GetWorldModel(self: WorldModelModule): WorldModel
	--=======================================================================================================>
	if self.Values.WorldModel then return self.Values.WorldModel end
	--=======================================================================================================>
	-- Check if a Folder named 'Zoners' already exists:
	local ZonerPointer: ObjectValue = script.Parent.Parent.Parent:FindFirstChild(`ZonerPointer:{self.RunScope}`, false)
	-- If there is already a WorldModel Found in the Service, then use that:
	-- This is Useful if we are using Actors with the Zones:
	if ZonerPointer.Value and ZonerPointer.Value:FindFirstChild('WorldModel') then
		-- Set the Module Reference:
		self.Values.WorldModel = ZonerPointer.Value:FindFirstChild('WorldModel') :: WorldModel
		-- Return the WorldModel:
		return self.Values.WorldModel :: any
	end
	--=======================================================================================================>
	-- Create a new WorldModel Instance:
	local WorldModel: WorldModel = Instance.new("WorldModel") 
	WorldModel.Name = "WorldModel"
	WorldModel.Parent = ZonerPointer.Value
	-- Set the Module Reference:
	self.Values.WorldModel = WorldModel
	--=======================================================================================================>
	-- Return the WorldModel Instance:
	return WorldModel
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ METHODS: ]


-- Module Method to Combine the WorldModel Arrays:
function WorldModelModule._GetCombinedResults(self: WorldModelModule, MethodName: string, Relocated: boolean, ...): {BasePart}
	--=======================================================================================================>
	-- Get the Workspace WorldRoot Method Results:
	local Results: {BasePart} = workspace[MethodName](workspace, ...)
	--=======================================================================================================>
	-- If an Additional WorldModel exists, Call the Method on it, and Add the Results to the Original Results Array:
	if Relocated and self.Values.WorldModel then
		--===============================================================>
		-- Grab the Additional Results as an Array:
		local AdditionalResults: {BasePart}

		-- This was done to avoid the "RunTime Exception Possible" Warning in the script:
		if MethodName == 'GetPartBoundsInRadius' then
			AdditionalResults = self.Values.WorldModel:GetPartBoundsInRadius(...) :: {any}
		elseif MethodName == 'GetPartBoundsInBox' then
			AdditionalResults = self.Values.WorldModel:GetPartBoundsInBox(...) :: {any}
		elseif MethodName == 'GetPartsInPart' then
			AdditionalResults = self.Values.WorldModel:GetPartsInPart(...) :: {any}
		end

		-- Loop through them all, inserting each into the Original Results Array to Combine the Arrays:
		for Index: number, Result: BasePart in ipairs(AdditionalResults :: {BasePart}) do table.insert(Results, Result)end
		--===============================================================>
	end
	-- Return the Results Array:
	return Results
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Module Method to Return the Parts in Parts Instance Array:
function WorldModelModule.GetPartsInPart(self: WorldModelModule, Relocated: boolean, Part: BasePart, OverlapParam: OverlapParams): {BasePart}
	return self:_GetCombinedResults("GetPartsInPart", Relocated, Part, OverlapParam)
end

-- Module Method to Return the Parts Bounds in Box Instance Array:
function WorldModelModule.GetPartBoundsInBox(self: WorldModelModule, Relocated: boolean, CFrame: CFrame, Size: Vector3, OverlapParam: OverlapParams): {BasePart}
	return self:_GetCombinedResults("GetPartBoundsInBox", Relocated, CFrame, Size, OverlapParam)
end

-- Module Method to Return the Parts Bounds in Radius Instance Array:
function WorldModelModule.GetPartBoundsInRadius(self: WorldModelModule, Relocated: boolean, Position: Vector3, Radius: number, OverlapParam: OverlapParams): {BasePart}
	return self:_GetCombinedResults("GetPartBoundsInRadius", Relocated, Position, Radius, OverlapParam)
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(WorldModelModule) :: WorldModelModule

--===========================================================================================================================>