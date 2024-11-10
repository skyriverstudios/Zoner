--===========================================================================================================================>
--!optimize 2
--!native
--!strict
--===========================================================================================================================>

-- Define Module table
local RegionsModule: RegionsModule = {}
RegionsModule.__index = RegionsModule

--===========================================================================================================================>
--[ GLOBAL VARIABLES: ]


local MAX_PART_SIZE = 2024

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- Insert the Object Types:
export type RegionsModule = typeof(RegionsModule)


type PartDetails = {
	Part: BasePart;
	Type: 'Sphere'|'Complex'|'Block';
}

-- Create Local Type:
type BoundDetails = {
	Values: {};

	ParseCheck: 
		(self: BoundDetails, Value1: number, Value2: number) -> boolean;
	Parse: 
		(self: BoundDetails, ValuesToParse: {number}) -> ();
};

-- Create Local Type:
type Bounds = {
	Max: BoundDetails; Min: BoundDetails
}

type Polygon = {
	Next: {
		Next: PolygonT2?;
		Position: Vector3;
		Previous: Polygon;
	};
	Position: Vector3;
	Previous: Polygon
}

type PolygonT2 = {
	Position: Vector3?,
	Previous: {
		Next: PolygonT2,
		Position: Vector3?,
		Previous: Polygon?
	}?
}

type PartsTable = {{CFrame: CFrame, Size: Vector3}} | {BasePart};

--===========================================================================================================================>
--[ FUNCTIONS: ]


--- @Public
--- Function to create Parts to a certain size and scale and parented to the Model Container:
function RegionsModule.CreateCube(self: RegionsModule, Container: Model, CubeCFrame: CFrame, CubeSize: Vector3)
	--=======================================================================================================>
	if CubeSize.X > MAX_PART_SIZE or CubeSize.Y > MAX_PART_SIZE or CubeSize.Z > MAX_PART_SIZE then
		local quarterSize = CubeSize * 0.25
		local halfSize = CubeSize * 0.5
		self:CreateCube(Container, CubeCFrame * CFrame.new(-quarterSize.X, -quarterSize.Y, -quarterSize.Z), halfSize)
		self:CreateCube(Container, CubeCFrame * CFrame.new(-quarterSize.X, -quarterSize.Y, quarterSize.Z), halfSize)
		self:CreateCube(Container, CubeCFrame * CFrame.new(-quarterSize.X, quarterSize.Y, -quarterSize.Z), halfSize)
		self:CreateCube(Container, CubeCFrame * CFrame.new(-quarterSize.X, quarterSize.Y, quarterSize.Z), halfSize)
		self:CreateCube(Container, CubeCFrame * CFrame.new(quarterSize.X, -quarterSize.Y, -quarterSize.Z), halfSize)
		self:CreateCube(Container, CubeCFrame * CFrame.new(quarterSize.X, -quarterSize.Y, quarterSize.Z), halfSize)
		self:CreateCube(Container, CubeCFrame * CFrame.new(quarterSize.X, quarterSize.Y, -quarterSize.Z), halfSize)
		self:CreateCube(Container, CubeCFrame * CFrame.new(quarterSize.X, quarterSize.Y, quarterSize.Z), halfSize)
	else
		local Part = Instance.new("Part")
		Part.CFrame = CubeCFrame
		Part.Size = CubeSize
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanTouch   = false
		Part.Transparency = 1
		Part.Reflectance  = 0
		Part.Material = Enum.Material.SmoothPlastic
		Part.Massless = true
		Part.Parent = Container
	end
	--=======================================================================================================>
end

--- @Public
--- Optimized function to get the corners of a BasePart
function RegionsModule.GetCorners(self: RegionsModule, CFrame1: CFrame, Size2: Vector3, Half: boolean?): {Vector3}
	--=======================================================================================================>
	-- Create an empty array for corner vectors
	local Corners = {}

	-- If the part is a simple box (Part) or a MeshPart with no mesh ID
	if Half == true then
		-- Only calculate the 4 necessary corners

		-- Top-Left Front
		table.insert(Corners, CFrame1 * Vector3.new(-Size2.X, Size2.Y, Size2.Z))
		-- Bottom-Right Front
		table.insert(Corners, CFrame1 * Vector3.new(Size2.X, -Size2.Y, Size2.Z))
		-- Top-Left Back
		table.insert(Corners, CFrame1 * Vector3.new(-Size2.X, Size2.Y, -Size2.Z))
		-- Bottom-Right Back
		table.insert(Corners, CFrame1 * Vector3.new(Size2.X, -Size2.Y, -Size2.Z))
	else
		-- Calculate all 8 corners for more complex parts
		table.insert(Corners, (CFrame1 * Vector3.new(Size2.X, Size2.Y, Size2.Z)))
		table.insert(Corners, (CFrame1 * Vector3.new(-Size2.X, Size2.Y, Size2.Z)))
		table.insert(Corners, (CFrame1 * Vector3.new(Size2.X, -Size2.Y, Size2.Z)))
		table.insert(Corners, (CFrame1 * Vector3.new(Size2.X, Size2.Y, -Size2.Z)))
		table.insert(Corners, (CFrame1 * Vector3.new(-Size2.X, -Size2.Y, Size2.Z)))
		table.insert(Corners, (CFrame1 * Vector3.new(Size2.X, -Size2.Y, -Size2.Z)))
		table.insert(Corners, (CFrame1 * Vector3.new(-Size2.X, Size2.Y, -Size2.Z)))
		table.insert(Corners, (CFrame1 * Vector3.new(-Size2.X, -Size2.Y, -Size2.Z)))
	end

	-- Return the corners array
	return Corners
	--=======================================================================================================>
end

--- @Public
--- Optimized function to get the corners of a BasePart
function RegionsModule.GetCornersFromPart(self: RegionsModule, Part: BasePart): {Vector3}
	--=======================================================================================================>
	-- Get the CFrame of the part
	local CFrame1 = Part.CFrame
	-- Get the size of the part, divided by half
	local Size = Part.Size * 0.5

	-- If the part is a simple box (Part) or a MeshPart with no mesh ID
	if (Part:IsA('Part') and Part.Shape == Enum.PartType.Block) or (Part:IsA('MeshPart') and Part.MeshId == "") then
		return self:GetCorners(CFrame1, Size, true)
	else
		return self:GetCorners(CFrame1, Size, false)
	end

	--=======================================================================================================>
end

--- @Public
--- Optimized function to get the corners of a BasePart
function RegionsModule.GetCornersFromPartDetails(self: RegionsModule, PartHalfSize: Vector3, PartCFrame: CFrame, PartType: 'Block'|'Sphere'|'Complex'): {Vector3}
	--=======================================================================================================>
	-- If the part is a simple box (Part) or a MeshPart with no mesh ID
	if PartType == 'Block' then
		return self:GetCorners(PartCFrame, PartHalfSize, true)
	else
		return self:GetCorners(PartCFrame, PartHalfSize, false)
	end
	--=======================================================================================================>
end

--===========================================================================================================================>

--- @Public
--- Function to return the Bounding Box Min and Max from CFrame and Size:
function RegionsModule.GetBoundingBox(self: RegionsModule, CFrame1: CFrame, Size1: Vector3): (Vector3, Vector3)
	--=======================================================================================================>
	local Min = CFrame1.Position - (Size1 * 0.5)
	local Max = CFrame1.Position + (Size1 * 0.5)
	return Min, Max
	--=======================================================================================================>
end



--- @Public
--- Function to check if a Vector3 is inside a Region3
function RegionsModule.IsPointInsideBoundBox(self: RegionsModule, Point: Vector3, BoundMin: Vector3, BoundMax: Vector3): boolean
	--=======================================================================================================>
	return Point.X >= BoundMin.X and Point.X <= BoundMax.X and
		Point.Y >= BoundMin.Y and Point.Y <= BoundMax.Y and
		Point.Z >= BoundMin.Z and Point.Z <= BoundMax.Z
	--=======================================================================================================>
end

--- @Public
--- Check if the BasePart is fully inside the Region3
function RegionsModule.IsPartFullyInsideBoundBox(self: RegionsModule, Part: BasePart, BoundMin: Vector3, BoundMax: Vector3): boolean
	--=======================================================================================================>

	local Corners: {Vector3} = self:GetCornersFromPart(Part)

	for Index: number, Corner: Vector3 in ipairs(Corners) do
		if not self:IsPointInsideBoundBox(Corner, BoundMin, BoundMax) then return false end
	end

	--=======================================================================================================>

	-- Return True:
	return true

	--=======================================================================================================>
end

--- @Public
--- Check if the BasePart has at least  inside the Region3
function RegionsModule.IsPartTouchingBoundBox(self: RegionsModule, Part: BasePart, BoundMin: Vector3, BoundMax: Vector3): boolean
	--=======================================================================================================>
	-- Grab the Corners of the Part:
	local Corners: {Vector3} = self:GetCornersFromPart(Part)
	-- Loop through the Corners, checking each Corner Vector3 and seeing if its within the BoundBox.
	-- If just one Corner is in the BoundBox, then its touching, so return true:
	for Index: number, Corner: Vector3 in ipairs(Corners) do
		if self:IsPointInsideBoundBox(Corner, BoundMin, BoundMax) then return true end
	end
	-- Return False:
	return false
	--=======================================================================================================>
end



--- @Public
--- Function to check if a Vector3 is inside a BasePart
function RegionsModule.IsPointInsidePart(self: RegionsModule, Point: Vector3, Part: BasePart): boolean
	--=======================================================================================================>
	local CFrame1 = Part.CFrame
	local Size   = Part.Size * 0.5

	local Min = CFrame1.Position - Size
	local Max = CFrame1.Position + Size

	return Point.X >= Min.X and Point.X <= Max.X and
		Point.Y >= Min.Y and Point.Y <= Max.Y and
		Point.Z >= Min.Z and Point.Z <= Max.Z
	--=======================================================================================================>
end

--- @Public
--- Check if the BasePart1 is fully inside BasePart2
function RegionsModule.IsPartFullyInsidePart(self: RegionsModule, Part1: BasePart, Part2: BasePart): boolean
	--=======================================================================================================>

	local Corners: {Vector3} = self:GetCornersFromPart(Part1)

	for Index: number, Corner: Vector3 in ipairs(Corners) do
		if not self:IsPointInsidePart(Corner, Part2) then return false end
	end

	return true

	--=======================================================================================================>
end

--- @Public
--- Check if the BasePart is fully inside the Region3
function RegionsModule.IsBoundBoxFullyInsideBoundBox(self: RegionsModule, BoundMin1: Vector3, BoundMax1: Vector3, BoundMin2: Vector3, BoundMax2: Vector3): boolean
	--=======================================================================================================>
	-- Loop through the two Corners of the First BoundBox to check if each Corner Is inside the Second BoundBox:
	for Index: number, Corner: Vector3 in ipairs({BoundMin1, BoundMax1}) do
		if not self:IsPointInsideBoundBox(Corner, BoundMin2, BoundMax2) then return false end
	end
	-- Return True:
	return true
	--=======================================================================================================>
end


-- @Public
-- Check if the BasePart is fully inside the Region3
function RegionsModule.IsBoundBoxTouchingBoundBox(self: RegionsModule, BoundMin1: Vector3, BoundMax1: Vector3, BoundMin2: Vector3, BoundMax2: Vector3): boolean
	--=======================================================================================================>
	-- Loop through the two Corners of the First BoundBox to check if each Corner Is inside the Second BoundBox:
	for Index: number, Corner: Vector3 in ipairs({BoundMin1, BoundMax1}) do
		if not self:IsPointInsideBoundBox(Corner, BoundMin2, BoundMax2) then return true end
	end
	-- Return False:
	return false
	--=======================================================================================================>
end

--===========================================================================================================================>



































function RegionsModule.GetHalfSize(self: RegionsModule, Size: Vector3): Vector3
	--===============================================================================>
	return Size / 2
	--===============================================================================>
end

function RegionsModule.GetRadius(self: RegionsModule, Size: Vector3): number
	--===============================================================================>
	return Size.X / 2
	--===============================================================================>
end

function RegionsModule.GetPartDetails(self: RegionsModule, Part: BasePart): PartDetails
	--===============================================================================>
	return {
		Part = Part;
		Type = self:GetPartType(Part)
	}
	--===============================================================================>
end

-- Initialization function to start/setup the Object's initial data:
function RegionsModule.GetPartType(self: RegionsModule, Part: BasePart): 'Block'|'Sphere'|'Complex'
	--=======================================================================================================>

	-- Returns whether the ZonePart is a Block:
	local function IsBlock(Part: BasePart): boolean
		-- Cache the PartShape:
		local PartShape: Enum.PartType | false = Part:IsA('Part') and Part.Shape 
		-- Return the boolean whether the PartShape is a 'Block' or the Part is a MeshPart with no Id:
		return PartShape == Enum.PartType.Block or Part:IsA('MeshPart') and Part.MeshId == "" 
	end

	-- Returns whether the ZonePart is a Sphere:
	local function IsSphere(Part: BasePart): boolean
		-- Cache the PartShape:
		local PartShape: Enum.PartType | false = Part:IsA('Part') and Part.Shape 
		-- Return the boolean whether the PartShape is a 'Ball'
		return PartShape == Enum.PartType.Ball
	end

	--=======================================================================================================>

	-- Return the ZonePartProperties Dictionary:
	return if IsBlock(Part) then 'Block' elseif IsSphere(Part) then 'Sphere' else 'Complex'

	--=======================================================================================================>
end

-- @Public
-- Get the Center Position Of the Array of Parts:
function RegionsModule.GetCenterPointOfParts(self: RegionsModule, Parts: {BasePart}): Vector3
	--=======================================================================================================> 
	-- Initialize the vector for total positions and part counter
	local TotalPosition: Vector3 = Vector3.zero
	local PartCount: number = 0
	-- Sum up positions of all parts in Parts table
	for Index: number, Part: BasePart in ipairs(Parts) do TotalPosition += Part.Position; PartCount += 1 end
	-- Return the average position; if PartCount is 0, this returns (0,0,0)
	return TotalPosition / PartCount
	--=======================================================================================================>
end

-- @Public
-- Get the Center Part Of the Array of Parts:
function RegionsModule.GetCenterPartOfParts(self: RegionsModule, Parts: {BasePart}): BasePart
	--=======================================================================================================>

	-- Calculate the center position of parts
	local CenterPoint: Vector3 = self:GetCenterPointOfParts(Parts)
	-- Define ClosestPart as BasePart
	local ClosestDistance: number, ClosestPart: BasePart = math.huge, nil

	-- Iterate through each part to find the closest one to the center point
	for Index: number, Part: BasePart in ipairs(Parts) do
		-- Grab the Distance:
		local Distance: number = (Part.Position - CenterPoint).Magnitude
		-- Compare Distance to ClosestDistance variable, overwrite if less:
		if Distance < ClosestDistance then ClosestDistance, ClosestPart = Distance, Part end
	end

	-- Return the part closest to the center point
	return ClosestPart

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Calculates an oriented bounding box for the specified parts,
-- applying a faster AABB calculation if parts are axis-aligned.
function RegionsModule.GetBoundingCFrameAndSize(self: RegionsModule, Parts: PartsTable | BasePart, VoxelAlign: boolean?): (CFrame, Vector3)
	--=======================================================================================================>

	-- Input validation: ensure Parts is not empty and contains only BasePart instances
	if typeof(Parts) ~= "table" then Parts = {Parts} end

	--=======================================================================================================>

	-- Helper function to round values to the nearest voxel grid size (default: 4) for voxel alignment
	local function RoundToVoxel(Value: number): number
		local ROUND_TO: number = 4  -- Define the alignment step to match the voxel grid
		return ROUND_TO * math.floor((Value + ROUND_TO / 2) / ROUND_TO)
	end

	-- Helper function to update min and max bounds by comparing a point to current bounds
	local function UpdateBounds(Point: Vector3, MinBound: Vector3, MaxBound: Vector3): (Vector3, Vector3)
		return MinBound:Min(Point), MaxBound:Max(Point)
	end

	-- Inline function to determine if all parts are axis-aligned (no rotation)
	local function IsAxisAligned(PartsSent: PartsTable): boolean
		-- Loop through all parts, return false if any part is rotated (not aligned with world axes)
		for Index: number, Part: BasePart | {CFrame: CFrame, Size: Vector3} in ipairs(PartsSent) do
			if not Part.CFrame.Rotation:FuzzyEq(CFrame.new()) then return false end
		end
		return true  -- All parts are aligned if none are rotated
	end

	--=======================================================================================================>

	-- Axis-Aligned Bounding Box (AABB) Optimization: Checks if all parts are axis-aligned
	local AxisAlignedParts: boolean = IsAxisAligned(Parts :: PartsTable)

	-- Define variables for the final bounding CFrame, center, and size of the calculated box
	local BoundingCFrame: CFrame, Center: Vector3, Size: Vector3

	-- Initialize min and max bounds to extreme values for later updates
	local MinBound: Vector3 = Vector3.new(math.huge, math.huge, math.huge)
	local MaxBound: Vector3 = Vector3.new(-math.huge, -math.huge, -math.huge)

	--=======================================================================================================>

	-- Axis-Aligned Bounding Box (AABB) Calculation if all parts are axis-aligned
	if AxisAlignedParts then
		--===============================================================================>
		-- Loop through all parts and update bounds based on their half-size and position
		for Index: number, Part: BasePart | {CFrame: CFrame, Size: Vector3} in ipairs(Parts :: PartsTable) do
			-- Calculate the half-size and position of each part
			local HalfSize: Vector3, Position: Vector3 = Part.Size * 0.5, Part.CFrame.Position
			-- Update the min and max bounds with each corner of the part
			MinBound, MaxBound = UpdateBounds(Position - HalfSize, MinBound, MaxBound)
			MinBound, MaxBound = UpdateBounds(Position + HalfSize, MinBound, MaxBound)
		end
		--===============================================================================>
	else
		--===============================================================================>
		-- Oriented Bounding Box Calculation if parts are not axis-aligned

		-- Variables to accumulate average look and right vectors across all parts
		local AvgLookVector: Vector3, AvgRightVector: Vector3 = Vector3.zero, Vector3.zero

		-- Calculate the sum of LookVector and RightVector for all parts to later find the average rotation
		for Index: number, Part: BasePart | {CFrame: CFrame, Size: Vector3} in ipairs(Parts :: PartsTable) do
			AvgLookVector += Part.CFrame.LookVector
			AvgRightVector += Part.CFrame.RightVector
		end

		-- Normalize vectors to unit length to create a consistent average rotation
		AvgLookVector, AvgRightVector = AvgLookVector.Unit, AvgRightVector.Unit

		-- Calculate the UpVector and rotation matrix using the average look and right vectors
		local AvgUpVector: Vector3 = AvgLookVector:Cross(AvgRightVector).Unit
		local AvgRotation: CFrame = CFrame.fromMatrix(Vector3.zero, AvgRightVector, AvgUpVector)

		-- Calculate bounds for rotated box by converting each part's CFrame to the average rotation
		for Index: number, Part: BasePart | {CFrame: CFrame, Size: Vector3} in ipairs(Parts :: PartsTable) do
			-- Transform part CFrame into local space of average rotation
			local LocalCFrame: CFrame = AvgRotation:Inverse() * Part.CFrame
			local HalfSize: Vector3 = Part.Size * 0.5

			-- Corners of the part in its local space, considering its half-size
			local Corners: {Vector3} = {
				LocalCFrame * Vector3.new(-HalfSize.X, -HalfSize.Y, -HalfSize.Z),
				LocalCFrame * Vector3.new(-HalfSize.X, -HalfSize.Y,  HalfSize.Z),
				LocalCFrame * Vector3.new(-HalfSize.X,  HalfSize.Y, -HalfSize.Z),
				LocalCFrame * Vector3.new(-HalfSize.X,  HalfSize.Y,  HalfSize.Z),
				LocalCFrame * Vector3.new( HalfSize.X, -HalfSize.Y, -HalfSize.Z),
				LocalCFrame * Vector3.new( HalfSize.X, -HalfSize.Y,  HalfSize.Z),
				LocalCFrame * Vector3.new( HalfSize.X,  HalfSize.Y, -HalfSize.Z),
				LocalCFrame * Vector3.new( HalfSize.X,  HalfSize.Y,  HalfSize.Z),
			}

			-- Update min and max bounds for each corner in the rotated box space
			for Index: number, Corner: Vector3 in ipairs(Corners) do
				MinBound, MaxBound = UpdateBounds(Corner, MinBound, MaxBound)
			end
		end

		-- Set the calculated average rotation as the initial bounding CFrame
		BoundingCFrame = AvgRotation

		--===============================================================================>
	end

	-- If voxel alignment is specified, round min and max bounds for voxel consistency
	if VoxelAlign then
		MinBound = Vector3.new(RoundToVoxel(MinBound.X), RoundToVoxel(MinBound.Y), RoundToVoxel(MinBound.Z))
		MaxBound = Vector3.new(RoundToVoxel(MaxBound.X), RoundToVoxel(MaxBound.Y), RoundToVoxel(MaxBound.Z))
	end

	--=======================================================================================================>

	-- Calculate the center and size of the bounding box from min and max bounds
	Center, Size = ((MinBound + MaxBound) / 2), (MaxBound - MinBound)

	-- Set bounding CFrame based on axis-alignment
	BoundingCFrame = if AxisAlignedParts then CFrame.new(Center) else BoundingCFrame * CFrame.new(Center)

	--=======================================================================================================>

	-- Return the calculated oriented bounding box CFrame and size
	return BoundingCFrame, Size

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Checks if a specified point (IsPointInSphere) is within a given sphere
function RegionsModule.IsPointInSphere(self: RegionsModule, PointToCheck: Vector3, SphereCFrame: CFrame, Radius: number): boolean
	--=======================================================================================================>
	-- Calculate the distance between the point and the center of the sphere
	-- Check if the distance is less than or equal to the radius
	return (PointToCheck - SphereCFrame.Position).Magnitude <= Radius
	--=======================================================================================================>
end

-- @Public
-- Checks if a specified point (PointToCheck) is within a given part, taking into account the part’s rotation.
-- This function operates in local space to correctly interpret the part’s orientation.
function RegionsModule.IsPointInBox(self: RegionsModule, PointToCheck: Vector3, BoxCFrame: CFrame, BoxHalfSize: Vector3): boolean
	--=======================================================================================================>
	-- Transform the specified point (PointToCheck) to the part’s local space
	-- This ensures that the check accounts for the rotation and position of the part
	local LocalPoint: Vector3 = BoxCFrame:PointToObjectSpace(PointToCheck)
	-- Check if the transformed point’s local coordinates (X, Y, Z) are within the bounds of the part’s half-size.
	-- math.abs() is used on each coordinate to account for both positive and negative bounds,
	-- allowing the check to work for points on either side of the part’s center.
	-- If all three coordinates are within bounds, the function returns true, indicating the point lies within the part.
	return (math.abs(LocalPoint.X) <= BoxHalfSize.X)
		and (math.abs(LocalPoint.Y) <= BoxHalfSize.Y)
		and (math.abs(LocalPoint.Z) <= BoxHalfSize.Z)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(RegionsModule) :: RegionsModule

--===========================================================================================================================>