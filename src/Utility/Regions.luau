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
function RegionsModule.IsPointInsideRegion(self: RegionsModule, Point: Vector3, Region: Region3): boolean
	--=======================================================================================================>
	local Min = Region.CFrame.Position - (Region.Size * 0.5)
	local Max = Region.CFrame.Position + (Region.Size * 0.5)

	return Point.X >= Min.X and Point.X <= Max.X and
		Point.Y >= Min.Y and Point.Y <= Max.Y and
		Point.Z >= Min.Z and Point.Z <= Max.Z
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
--- Check if the BasePart is fully inside the Region3
function RegionsModule.IsPartFullyInsideRegion(self: RegionsModule, Part: BasePart, Region: Region3): boolean
	--=======================================================================================================>
	-- Grab the Corners of the Part:
	local Corners: {Vector3} = self:GetCornersFromPart(Part)
	-- Loop through the Corners, checking each Corner Vector3 and seeing if its within the Region.
	for Index: number, Corner: Vector3 in ipairs(Corners) do
		if not self:IsPointInsideRegion(Corner, Region) then return false end
	end
	-- Return True:
	return true
	--=======================================================================================================>
end

--- @Public
--- Function to check if a Model is fully inside a Region3
function RegionsModule.IsModelFullyInsideRegion(self: RegionsModule, Model: Model, Region: Region3): boolean
	--=======================================================================================================>

	-- Get Descendants of Model:
	local ModelDescendants: {Instance} = Model:GetDescendants()

	-- Loop through the Descendants of the Model:
	for Index: number, Part: Instance in ipairs(ModelDescendants) do
		--=============================================================================>
		-- If Part is not a BasePart continue:
		if not Part:IsA("BasePart") then continue end
		--=============================================================================>
		-- Check if Part is FullyInsideRegion, if it isnt, return false:
		if not self:IsPartFullyInsideRegion(Part, Region) then ModelDescendants = nil :: any return false end
		--=============================================================================>
	end

	-- Clear from memory:
	ModelDescendants = nil :: any

	--=======================================================================================================>

	-- Return True:
	return true

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

--- @Public
--- Check if the Array of Corners denoting a Box is fully inside the Corners of Box 2:
function RegionsModule.IsBox1CornersFullyInsideBox2Corners(self: RegionsModule, Box1Corners: {Vector3}, Box2Corners: {Vector3}): boolean
	--=======================================================================================================>
	-- Loop through the two Corners of the First BoundBox to check if each Corner Is inside the Second BoundBox:
	for Index: number, Corner: Vector3 in ipairs(Box1Corners) do

	end
	-- Return True:
	return true
	--=======================================================================================================>
end

--- @Public
--- Check if the BasePart is fully inside the Region3
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

--- @Public
--- Get the Center Position Of the Array of Parts:
function RegionsModule.GetCenterPointOfParts(self: RegionsModule, Parts: {[BasePart]: boolean}): Vector3
	--=======================================================================================================>

	local TotalPosition = Vector3.new(0, 0, 0)
	local PartCount = 0

	for Part, State in pairs(Parts) do
		TotalPosition += Part.Position
		PartCount += 1
	end

	if PartCount > 0 then
		return TotalPosition / PartCount
	else
		return Vector3.new(0, 0, 0)
	end

	--=======================================================================================================>
end

--- @Public
--- Get the Center Part Of the Array of Parts:
function RegionsModule.GetCenterPartOfParts(self: RegionsModule, Parts: {[BasePart]: boolean}): BasePart
	--=======================================================================================================>

	local CenterPoint = self:GetCenterPointOfParts(Parts)
	local ClosestDistance = math.huge
	local ClosestPart = nil

	for Part, State in pairs(Parts) do
		local Distance = (Part.Position - CenterPoint).Magnitude
		if Distance < ClosestDistance then
			ClosestDistance = Distance
			ClosestPart = Part
		end
	end

	return ClosestPart

	--=======================================================================================================>
end

--===========================================================================================================================>

--- @Public
--- Initialization function to start/setup the Object's initial data:
function RegionsModule.ArePartsAllBlocks(self: RegionsModule, PartsArray: {BasePart}): boolean
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

--- @Public
--- Initialization function to start/setup the Object's initial data:
function RegionsModule.GetCalculatedPartToRegion(self: RegionsModule, Parts: ({BasePart} | BasePart), DontRound: boolean?): (Region3, Vector3, Vector3)
	--=======================================================================================================>

	-- Define a Region3, BoundMin and BoundMax Vector3:
	local Region: Region3, BoundMin: Vector3, BoundMax: Vector3

	-- Define the MinBound and MaxBound Number Arrays:
	local MinBound: {number}, MaxBound: {number} = {}, {}

	-- Define the Bounds Dictionary:
	local Bounds: Bounds = {["Min"] = {Values = {}}, ["Max"] = {Values = {}}} :: Bounds

	--=======================================================================================================>

	-- Rounding a regions coordinates to multiples of 4 ensures the region optimises the region
	-- by ensuring it aligns on the voxel grid
	local function RoundToFour(Value: number): number
		--=============================================================================>
		-- Round number constant:
		local ROUND_TO: number = 4
		-- Divide the Value:
		local Divided: number = (Value + ROUND_TO/2) / ROUND_TO
		-- Floor the Value and multiply:
		local Rounded: number = ROUND_TO * math.floor(Divided)
		-- Return rounded Number:
		return Rounded
		--=============================================================================>
	end
	
	-- Function that will Parse a Single Corner CFrame:
	local function ParseCorner(CornerCFrame: CFrame)
		--=============================================================================>
		-- Get the first 3 Values of the CFrame Components:
		local X: number, Y: number, Z: number = CornerCFrame:GetComponents()
		-- Put the three Values into an Array for Parsing:
		local AxisValues: {number} = {X, Y, Z}
		--=============================================================================>
		-- Call the Parse Function on the Min:
		Bounds.Min:Parse(AxisValues)
		-- Call the Parse Function on the Max:
		Bounds.Max:Parse(AxisValues)
		--=============================================================================>
	end
	
	-- Function that will Calculate the Corners and Parse for a Single Part:
	local function CalculatePart(Part: BasePart)
		--=============================================================================>
		-- Get half the Size of the Part:
		local SizeHalf: Vector3 = Part.Size * 0.5
		-- Create an Array of all the Corners of the Part:
		local Corners: {CFrame} = {
			Part.CFrame * CFrame.new(-SizeHalf.X, -SizeHalf.Y, -SizeHalf.Z),
			Part.CFrame * CFrame.new(-SizeHalf.X, -SizeHalf.Y,  SizeHalf.Z),
			Part.CFrame * CFrame.new(-SizeHalf.X,  SizeHalf.Y, -SizeHalf.Z),
			Part.CFrame * CFrame.new(-SizeHalf.X,  SizeHalf.Y,  SizeHalf.Z),
			Part.CFrame * CFrame.new( SizeHalf.X, -SizeHalf.Y, -SizeHalf.Z),
			Part.CFrame * CFrame.new( SizeHalf.X, -SizeHalf.Y,  SizeHalf.Z),
			Part.CFrame * CFrame.new( SizeHalf.X,  SizeHalf.Y, -SizeHalf.Z),
			Part.CFrame * CFrame.new( SizeHalf.X,  SizeHalf.Y,  SizeHalf.Z),
		}
		-- Loop through the Array of Corner CFrames:
		for Index: number, CornerCFrame: CFrame in ipairs(Corners) do ParseCorner(CornerCFrame) end
		--=============================================================================>
	end

	--=======================================================================================================>

	-- Loop through the Bounds and Add a Function to each Table:
	for BoundType: string, BoundDetail in pairs(Bounds) do
		--=============================================================================>
		function BoundDetail:ParseCheck(Value1: number, Value2: number): boolean
			--=================================================>
			if BoundType == "Min" then
				return (Value1 <= Value2)
			elseif BoundType == "Max" then
				return (Value1 >= Value2)
			else
				return true
			end
			--=================================================>
		end

		function BoundDetail:Parse(ValuesToParse: {number})
			--=================================================>
			for Index: number, Value: number in ipairs(ValuesToParse) do
				local CurrentValue: number = self.Values[Index] or Value
				if self:ParseCheck(Value, CurrentValue) then
					self.Values[Index] = Value
				end
			end
			--=================================================>
		end
		--=============================================================================>
	end
	
	-- If the Type of Parts Variable passed is an Array of Parts, Calculate a Combined Region.
	-- Else if the type of Parts Variable is a singular BasePart, Calculate a Region just for that BasePart:
	if typeof(Parts) == 'table' then
		-- Loop through the Array of Parts to calculate and parse their bounds:
		for Index: number, Part: BasePart in ipairs(Parts) do CalculatePart(Part) end
	else
		-- Calculate values for the Singular Part passed:
		CalculatePart(Parts)
	end

	-- Loop through the Bounds again to Fill the MinBound and MaxBound Arrays:
	for BoundType: string, BoundDetail in pairs(Bounds) do
		--=============================================================================>
		-- Loop through the Values Array:
		for Index: number, Value: number in ipairs(BoundDetail.Values) do
			--=====================================================================>
			-- New Bound Table Reference:
			local NewBoundTable = (BoundType == "Min" and MinBound) or MaxBound
			-- Create a new Reference Variable to the Value so it can be manipulated:
			local NewValue: number = Value
			--=====================================================================>
			-- If the DountRound Boolean is false, then Round to the fourth place:
			if DontRound == false or DontRound == nil then
				-- Create a RoundOffset:
				local RoundOffset: number = (BoundType == "Min" and -2) or 2
				-- +-2 to ensures the zones region is not rounded down/up
				NewValue = RoundToFour(Value + RoundOffset)
			end
			--=====================================================================>
			-- Insert the NewValue into the NewBoundTable:
			table.insert(NewBoundTable, NewValue)
			--=====================================================================>
		end
		--=============================================================================>
	end

	--=======================================================================================================>

	-- Unpack the MinBound Array into a Vector3 and Set to BoundMin:
	BoundMin = Vector3.new(unpack(MinBound))
	-- Unpack the MaxBound Array into a Vector3 and Set to BoundMax:
	BoundMax = Vector3.new(unpack(MaxBound))
	-- Use Both BoundMin and BoundMax Vector3's to construct a Region3:
	Region = Region3.new(BoundMin, BoundMax)

	--=======================================================================================================>

	-- Return the Region3 and BoundMin and BoundMax Vector3s:
	return Region, BoundMin, BoundMax

	--=======================================================================================================>
end

--===========================================================================================================================>

--- @Public
--- Initialization function to start/setup the Object's initial data:
function RegionsModule.PointInPolygon(self: RegionsModule, Point: Vector3, Polygon: Polygon): boolean
	--=======================================================================================================>
    local current = Polygon
    local inside = false
    local A = current.Position
    local ax, az = A.X, A.Z
    local px, pz = Point.X, Point.Z
    repeat
        local B = current.Next.Position
        local bx: number, bz: number = B.X, B.Z
        if ((az >= pz) ~= (bz >= pz)) and ((px - ax) <= (bx - ax)*(pz - az)/(bz - az)) then
            inside = not inside
        end
        current = current.Next :: any
        A, ax, az = B, bx, bz
    until current == Polygon

    return inside

	--=======================================================================================================>
end

--- @Public
--- Initialization function to start/setup the Object's initial data:
function RegionsModule.CreatePolygonFromPoints(self: RegionsModule, Points: {Vector3}): Polygon
	--=======================================================================================================>

    local Polygon: Polygon = {Position = Points[1]} :: Polygon

    local First: Polygon = Polygon :: Polygon

    for i = 2, #Points do
        Polygon.Next = {Previous = Polygon, Position = Points[i]}
        Polygon = Polygon.Next :: any
    end

    Polygon.Next, First.Previous = First :: any, Polygon

    return First

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(RegionsModule) :: RegionsModule

--===========================================================================================================================>