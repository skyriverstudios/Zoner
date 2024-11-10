--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Define Module table
local UtilityModule = {}

--===========================================================================================================================>
--[ SERVICES: ]


local MarketplaceService = game:GetService('MarketplaceService')
local StarterGui         = game:GetService('StarterGui')
local RunService         = game:GetService('RunService')
local Players            = game:GetService('Players')

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.TypeDefinitions)
 
-- Insert the Object Types:
type UtilityMetaData = TypeDefinitions.UtilityMetaData
type UtilityModule   = TypeDefinitions.UtilityModule
type Utility         = TypeDefinitions.Utility

-- Insert the Extra Types:
type Dictionary  = TypeDefinitions.Dictionary
type Debounces   = TypeDefinitions.Debounces
type Cycler      = TypeDefinitions.Cycler
type Table       = TypeDefinitions.Table
type Array       = TypeDefinitions.Array

--===========================================================================================================================>
--[ CONSTRUCTOR METHODS: ]


-- Function to create a new Object Instance:
function UtilityModule.New(): Utility

	--===========================================================================================>

	local UtilityData: UtilityMetaData = {
		--====================================================>
		_RandomPrefix = Random.new(3562498129478199);
		_MaxRetries   = 8;
		_FaceNormalTolerance = 1 - 0.001;
		_FaceNormalIds = {
			Enum.NormalId.Front,
			Enum.NormalId.Back,
			Enum.NormalId.Bottom,
			Enum.NormalId.Top,
			Enum.NormalId.Left,
			Enum.NormalId.Right
		};  
		--====================================================>
		_RunScope = if RunService:IsServer() then 'Server' else 'Client';
		_Studio   = RunService:IsStudio();
		--====================================================>
		-- Require the Math Sub Module:
		Math  = require(script.Classes.Math);
		-- Require the Table Sub Module:
		Table = require(script.Classes.Table);
		-- Require the Log Sub Module:
		Log   = require(script.Classes.Log);
		-- Require the Get Sub Module:
		Get   = require(script.Classes.Get);
		--====================================================>
	} :: UtilityMetaData

	--===========================================================================================>

	-- Set Metatable to the MetaTable and the current Module
	setmetatable(UtilityData, UtilityModule :: any)

	--===========================================================================================>

	-- Add values to the get module:
	UtilityData.Get._Utility   = UtilityData;
	-- Add values to the table module:
	UtilityData.Table._Utility = UtilityData;
	-- Add values to the log module:
	UtilityData.Log._Utility   = UtilityData;

	--===========================================================================================>
	-- Freeze the Modules:

	table.freeze(UtilityData.Math)
	table.freeze(UtilityData.Table)
	table.freeze(UtilityData.Log)
	table.freeze(UtilityData.Get)

	--===========================================================================================>

	-- Return the MetaTable Data
	return UtilityData

	--===========================================================================================>

end

-- Method that will Destroy the Object:
function UtilityModule.Destroy(self: Utility)

	--===========================================================================================>

	-- Clear all self data:
	for Index, Data in pairs(self) do self[Index] = nil end

	-- Set the Metatable to nil
	setmetatable(self :: any, nil)	

	--===========================================================================================>

end

--===========================================================================================================================>
--[ MISC METHODS: ]


--[[
   If it returns true, then return from whatever function its being initialized in:
   Example: 
   Start of the function:
     -- This will call the debounce function and set the bool to true if its false and return false, or return true if its already set:
    if Utility:DebounceAsync('Poop', self._Debounces, true) then return end

   End of the function:
    -- This will call the debounce function and start the wait time until it sets the bool to false:
    Utility:DebounceAsync('Poop', self._Debounces, false)
]]
-- Function which is called to initiate Debounces on seperate threads or not:
function UtilityModule.DebounceAsync(self: Utility, Name: string, Debounces: Debounces, Status: boolean): boolean
	--===========================================================================================>
	-- Check if a Debounce indexed with the Name exists:
	if not Debounces[Name] then self.Log.Warn(`No Debounce could be indexed in the Debounces by the name: "{Name}"`) return false end
	--===========================================================================================>
	-- If the Debounce has a Started Variable, then do a different kind of Debounce:
	if Status == true then
		-- If Debounce is already on return true to stop further Debounces
		if Debounces[Name].Bool == true then return true end
		-- Set Debounce to true:
		Debounces[Name].Bool = true
	else
		-- If Debounce is already false then return false:
		if Debounces[Name].Bool == false then return false end
		-- Wait the desired Time:
		task.wait(Debounces[Name].Time)
		-- Set Debounce to false:
		Debounces[Name].Bool = false
	end
	-- Return false:
	return false
	--===========================================================================================>
end

-- Runs DebounceAsync in a seperate thread:
function UtilityModule.Debounce(self: Utility, Name: string, Debounces: Debounces, Trove: Trove, Status: boolean?): boolean
	--===========================================================================================>
	-- Check if a Debounce indexed with the Name exists:
	if not Debounces[Name] then warn(`No Debounce could be indexed in the Debounces by the name: "{Name}"`) return false end
	--===========================================================================================>

	-- Create a new Spawn thread for this code to run:
	Trove:TaskSpawn(function()

		--=======================================================================================>
		-- If the Debounce has a Started Variable, then do a different kind of Debounce:
		if Status ~= nil then 
			--==============================================================================>
			self:DebounceAsync(Name, Debounces, Status)
			--==============================================================================>
		else
			--==============================================================================>
			-- If Debounce is already on return true to stop further Debounces
			if Debounces[Name].Bool == true then return end
			--==============================================================================>
			-- Set Debounce to true:
			Debounces[Name].Bool = true
			--==============================================================================>
			-- Wait the desired Time:
			task.wait(Debounces[Name].Time)
			-- Set Debounce to false:
			Debounces[Name].Bool = false
			--==============================================================================>
		end
		--=======================================================================================>
	end)

	--===========================================================================================>\

	-- If the Debounce has a Started Variable, then do a different kind of Debounce:
	if Status ~= nil then
		--==============================================================================>
		if Status == true then
			if Debounces[Name].Bool == true then return true end
		else
			if Debounces[Name].Bool == false then return false end
		end
		--==============================================================================>
		-- Return false:
		return false
		--==============================================================================>
	else
		--==============================================================================>
		-- If Debounce is already on return true to stop further Debounces
		if Debounces[Name].Bool == true then return true end
		-- Return false:
		return false
		--==============================================================================>
	end

	--===========================================================================================>
end

-- Function which when called will Return true or false based on whether the Player Passed, has the given Gamepass from the sent GamepassID
function UtilityModule.HasPass(self: Utility, PlayerID: number, GamepassID: number): boolean
	--===========================================================================================>

	-- Define a Retries Variable:
	local Retries: number = 0

	--===========================================================================================>

	-- Define a Local, recursive Function:
	local function GetProductInfo(): boolean
		--==========================================================================>	
		-- Pcall function that will return the Value needed, if it succeeds:
		local Success: boolean, Verdict: boolean? = pcall(
			MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, PlayerID, GamepassID
		)

		-- If not a Success, then try again:
		if not Success then
			--==============================================>
			-- If the Current Try is at the Max Retry, return the Default:
			-- Else, Increment the Retries:
			if Retries == self._MaxRetries then return false else Retries += 1 end 
			--==============================================>
			-- Return Call the Function again Recursively:
			return GetProductInfo()	
			--==============================================>
		else 
			--==============================================>
			-- Return the Value if it was a Success:
			return Verdict :: boolean
			--==============================================>
		end
		--==========================================================================>
	end

	--===========================================================================================>

	-- Return the returned Value from the Called Function:
	return GetProductInfo()

	--===========================================================================================>
end

-- Method that will apply a delay to the sent Object to call its destroy method on, and return the thread:
function UtilityModule.Debris(self: Utility, Object: any, WaitTime: number): thread
	return task.delay(WaitTime, Object.Destroy, Object)
end

-- Method that will create a Beam to debug a racyast, using the Origin and EndPosition to represent the Raycast:
function UtilityModule.RaycastDebug(self: Utility, Origin: Vector3, EndPosition: Vector3, ColorType: ('Red'|'Green'|'Blue')?, ActiveTime: number?)
	--===========================================================================================>

	-- Display
	local OriginPart = Instance.new("Part")
	OriginPart.Name = "Part1RaycastDebug"
	OriginPart.Transparency = 1
	OriginPart.CanCollide = false
	OriginPart.CanQuery = false
	OriginPart.Anchored = true
	OriginPart.Parent = workspace
	OriginPart.Position = Origin
	OriginPart.Size = Vector3.new(.1,.1,.1)

	local Attachment0 = Instance.new("Attachment")
	Attachment0.Name = "Attachment0"
	Attachment0.Parent = OriginPart
	Attachment0.Visible = true

	local EndPart = Instance.new("Part")
	EndPart.Name = "Part1RaycastDebug"
	EndPart.Transparency = 1
	EndPart.CanCollide = false
	EndPart.CanQuery = false
	EndPart.Anchored = true
	EndPart.Parent = workspace
	EndPart.Position = EndPosition
	EndPart.Size = Vector3.new(.1,.1,.1)

	local Attachment1 = Instance.new("Attachment")
	Attachment1.Name = "Attachment0"
	Attachment1.Parent = EndPart
	Attachment1.Visible = true

	local Beam = Instance.new("Beam")
	Beam.Parent = OriginPart
	Beam.Attachment0 = Attachment0
	Beam.Attachment1 = Attachment1
	Beam.FaceCamera = true
	Beam.Transparency = NumberSequence.new(.5)
	Beam.LightInfluence = 0
	Beam.LightEmission = 1
	Beam.Brightness = 2
	Beam.Width0 = 0.1
	Beam.Width1 = 0.1

	local Color: Color3 = 
		if ColorType == 'Red' or ColorType == nil then Color3.fromRGB(255, 94, 94) 
		elseif ColorType == 'Blue' then Color3.fromRGB(21, 111, 255) 
		else Color3.fromRGB(52, 255, 16)

	Beam.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color);
		ColorSequenceKeypoint.new(1, Color)
	}

	--===========================================================================================>
	-- Clear Debris:
	self:Debris(OriginPart, ActiveTime or 10); self:Debris(EndPart, ActiveTime or 10)
	--===========================================================================================>
	-- Clear variables from memory:
	OriginPart, Attachment0, EndPart, Attachment1, Beam = nil :: any, nil :: any, nil :: any, nil :: any, nil :: any
	--===========================================================================================>
end

-- Method that will create a Beam to debug a racyast, using the Origin and EndPosition to represent the Raycast:
function UtilityModule.BlockcastDebug(self: Utility, Size: Vector3, OriginCFrame: CFrame, EndCFrame: CFrame, ColorType: ('Red'|'Green'|'Blue')?, ActiveTime: number?)
	--===========================================================================================>

	local Color: Color3 = 
		if ColorType == 'Red' or ColorType == nil then Color3.fromRGB(255, 94, 94) 
		elseif ColorType == 'Blue' then Color3.fromRGB(21, 111, 255) 
		else Color3.fromRGB(52, 255, 16)

	-- Display
	local OriginPart = Instance.new("Part")
	OriginPart.Name = "Part1RaycastDebug"
	OriginPart.Transparency = .95
	OriginPart.CanCollide = false
	OriginPart.CanQuery = false
	OriginPart.Anchored = true
	OriginPart.Parent = workspace
	OriginPart.CFrame = OriginCFrame
	OriginPart.Size = Size
	OriginPart.Color = Color

	local Attachment0 = Instance.new("Attachment")
	Attachment0.Name = "Attachment0"
	Attachment0.Parent = OriginPart
	Attachment0.Visible = false

	local EndPart = Instance.new("Part")
	EndPart.Name = "Part1RaycastDebug"
	EndPart.Transparency = .95
	EndPart.CanCollide = false
	EndPart.CanQuery = false
	EndPart.Anchored = true
	EndPart.Parent = workspace
	EndPart.CFrame = EndCFrame
	EndPart.Size = Size
	EndPart.Color = Color3.fromRGB(255, 219, 134)

	local Attachment1 = Instance.new("Attachment")
	Attachment1.Name = "Attachment0"
	Attachment1.Parent = EndPart
	Attachment1.Visible = false

	local Beam = Instance.new("Beam")
	Beam.Parent = OriginPart
	Beam.Attachment0 = Attachment0
	Beam.Attachment1 = Attachment1
	Beam.FaceCamera = true
	Beam.Transparency = NumberSequence.new(.5)
	Beam.LightInfluence = 0
	Beam.LightEmission = 1
	Beam.Brightness = 2
	Beam.Width0 = 0.1
	Beam.Width1 = 0.1

	Beam.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color);
		ColorSequenceKeypoint.new(1, Color)
	}

	--===========================================================================================>
	-- Clear Debris:
	self:Debris(OriginPart, ActiveTime or 10); self:Debris(EndPart, ActiveTime or 10)
	--===========================================================================================>
	-- Clear variables from memory:
	OriginPart, Attachment0, EndPart, Attachment1, Beam = nil :: any, nil :: any, nil :: any, nil :: any, nil :: any
	--===========================================================================================>
end
-- Method that will create a Beam to debug a racyast, using the Origin and EndPosition to represent the Raycast:
function UtilityModule.PositionDebug(self: Utility, Position: Vector3, Name: string?, ActiveTime: number?)
	--===========================================================================================>
	local Attachment = Instance.new("Attachment")
	Attachment.Name = Name or "Attachment"
	Attachment.Parent = workspace.Terrain
	Attachment.Position = Position
	Attachment.Visible = true
	--===========================================================================================>
	-- Clear Debris:
	self:Debris(Attachment, ActiveTime or 10);
	--===========================================================================================>
	-- Clear variables from memory:
	Attachment = nil :: any
	--===========================================================================================>
end
-- Method that will create a Beam to debug a racyast, using the Origin and EndPosition to represent the Raycast:
function UtilityModule.CFrameDebug(self: Utility, CFrameSent: CFrame, Name: string?, ActiveTime: number?)
	--===========================================================================================>
	local Attachment = Instance.new("Attachment")
	Attachment.Name = Name or "Attachment"
	Attachment.Parent = workspace.Terrain
	Attachment.WorldCFrame = CFrameSent
	Attachment.Visible = true
	--===========================================================================================>
	-- Clear Debris:
	self:Debris(Attachment, ActiveTime or 10);
	--===========================================================================================>
	-- Clear variables from memory:
	Attachment = nil :: any
	--===========================================================================================>
end

-- Method that will start from the Table passed, and recursively loop down the FilePath string which denotes which Keys to use next, and return final result:
@native
function UtilityModule.TraverseFilePath(self: Utility, Table: Dictionary, FilePath: string, NilCallback: (Key: string)->()?): any
	--=======================================================================================================>
	-- The split FilePathArray string by the forward slashes:
	local FilePathArray: {string} = string.split(FilePath, "/")

	-- The Current table that the Path is indexing to:
	local CurrentTable: any

	-- Loop through the FilePathArray to index to the ending Inheritance Table:
	for Index: number, TableKey: string in ipairs(FilePathArray) do
		--====================================================================================>
		-- Get the Current Table next in line!:
		CurrentTable = if CurrentTable == nil then Table[TableKey] else CurrentTable[TableKey]
		-- Warn the console of the error:
		if CurrentTable == nil then 
			-- Run NilCallback if it exists:
			if NilCallback then NilCallback(TableKey) else warn(`\nFilePath was incorrect for Key: {TableKey}\nStopped at Index: {TableKey}`) end 
			-- Break loop:
			break 
		end
		--====================================================================================>
	end

	-- Return final destination:
	return CurrentTable
	--=======================================================================================================>
end

-- Method that will replace all Spaces in a String with Nothing or Underscore:
function UtilityModule.StringSpaces(self: Utility, String: string, Replace: string?): string
	--=======================================================================================================>
	return string.gsub(String, ' ', if Replace then Replace else '')
	--=======================================================================================================>
end


-- Method that will start from the Table passed, and recursively loop down the FilePath string which denotes which Keys to use next, and return final result:
function UtilityModule.AlignPositionYield(self: Utility, AlignPosition: AlignPosition)
	--=======================================================================================================>

	-- If no Attachment0, return:
	if AlignPosition.Attachment0 == nil then return end
	if AlignPosition.Attachment1 == nil then return end
	if AlignPosition.Enabled == false then return end

	-- Create a TimeOut Number:
	local TimeOut: number = 0
	--=======================================================================================================>
	-- Repeat Wait Until Position is Aligned or TimeOut reaches 6, or AlignPosition is Disabled:
	repeat TimeOut += task.wait() until 
	(AlignPosition.Attachment1.WorldPosition - AlignPosition.Attachment0.WorldPosition).Magnitude < .5 or TimeOut >= 5 or AlignPosition.Enabled == false
	-- If Timedout, warn:
	if TimeOut >= 5 then self.Log.Warn('TimedOut on AlignPosition Yield') end
	--=======================================================================================================>
	-- Clear TimeOut Number:
	TimeOut = nil :: any
	--=======================================================================================================>
end


--[[**
   This function returns the face that we hit on the given part based on
   an input normal. If the normal vector is not within a certain tolerance of
   any face normal on the part, we return nil.

    @param normalVector (Vector3) The normal vector we are comparing to the normals of the faces of the given part.
    @param part (BasePart) The part in question.

    @return (Enum.NormalId) The face we hit.
**--]]
function UtilityModule.NormalToFace(self: Utility, NormalVector: Vector3, Part: BasePart): Enum.NormalId?
	--=======================================================================================================>
	for Index: number, NormalId: Enum.NormalId in ipairs( self._FaceNormalIds ) do
		-- If the two vectors are almost parallel,
		if self:GetNormalFromFace(Part, NormalId):Dot(NormalVector) > self._FaceNormalTolerance then
			return NormalId -- We found it!
		end
	end
	--=======================================================================================================>
	return nil :: any -- None found within tolerance.
	--=======================================================================================================>
end

--[[**
    This function returns a vector representing the normal for the given
    face of the given part.

    @param part (BasePart) The part for which to find the normal of the given face.
    @param normalId (Enum.NormalId) The face to find the normal of.

    @returns (Vector3) The normal for the given face.
**--]]
function UtilityModule.GetNormalFromFace(self: Utility, Part: BasePart, NormalId: Enum.NormalId): Vector3
	return Part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(NormalId))
end

--===========================================================================================================================>

-- Method that takes in an optional DeltaTime and will Increment the Counter and return a boolean:
@native
function UtilityModule.RateLimiter(self: Utility, RateData: {Counter: number; CounterMax: number}, DeltaTime: number?): boolean
	--=======================================================================================================>
	if DeltaTime then
		RateData.Counter += DeltaTime; if RateData.Counter >= RateData.CounterMax then RateData.Counter = 0; end return RateData.Counter == 0
	else
		RateData.Counter = (RateData.Counter + 1) % (RateData.CounterMax + 1); return RateData.Counter == 0
	end
	--=======================================================================================================>
end

-- Method that takes in an optional type and will Increment the Counter and return a boolean:
@native
function UtilityModule.Counter(self: Utility, CounterData: {Counter: number; CounterMax: number;}, Type: 'Max'?): boolean
	--=======================================================================================================>
	if Type == 'Max' then
		CounterData.Counter += 1; if CounterData.Counter >= CounterData.CounterMax then CounterData.Counter = 0; return true else return false end
	else
		CounterData.Counter += 1; if CounterData.Counter >= CounterData.CounterMax then CounterData.Counter = 0; end return CounterData.Counter == 0
	end
	--=======================================================================================================>
end

-- Method that takes in a DeltaTime and Max and will Increment the Counter and return a boolean:
@native
function UtilityModule.DeltaCounter(self: Utility, CounterData: {Counter: number; CounterMax: number;}, DeltaTime: number, Type: 'Max'?): boolean
	--=======================================================================================================>
	if Type == 'Max' then
		CounterData.Counter += DeltaTime; if CounterData.Counter >= CounterData.CounterMax then CounterData.Counter = 0; return true else return false end
	else
		CounterData.Counter += DeltaTime; if CounterData.Counter >= CounterData.CounterMax then CounterData.Counter = 0; end return CounterData.Counter == 0
	end
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Method which will return the First ToolModel found in the Instance:
function UtilityModule.FindFirstChildTool(self: Utility, SentInstance: Instance): Tool?
	--=======================================================================================================>
	-- See if the SentInstance has a Model as a descendant:
	local Tool: Tool? = SentInstance:FindFirstChildOfClass("Tool")
	-- If it does have a Model as a Descendant, check if it has the ToolAttribute, if it does, return the Model, if it doesnt, return nil:
	return if Tool then Tool else nil
	--=======================================================================================================>
end

-- Method that will return the first ToolModel Ancestor of the Instance:
function UtilityModule.FindFirstAncestorTool(self: Utility, SentInstance: Instance): Tool?
	--=======================================================================================================>

	-- Recurssive Ancestor Function:
	local function RecurssiveAncestor(SentInstanceParent: Instance): Tool?
		--===========================================================================>
		-- Check if the SentInstance's Parent is a Model:
		local IsATool: boolean = SentInstanceParent:IsA("Tool")
		--===========================================================================>
		-- If it is not a Model, get the Parent of the Parent:
		if not IsATool then 
			-- If it has a Parent, Recurssively get and check it:
			if SentInstanceParent.Parent then return RecurssiveAncestor(SentInstanceParent.Parent) else return nil end
		else
			-- If InstancePArent has the Tool Attribute, set its verdict:
			if SentInstanceParent:IsA("Tool")then
				return SentInstanceParent :: Tool
			else
				-- If it has a Parent, Recurssively get and check it:
				if SentInstanceParent.Parent then return RecurssiveAncestor(SentInstanceParent.Parent) else return nil end
			end
		end
		--===========================================================================>
	end

	-- If the Instance has a Parent, return call the Recurssive Function, else return nil:
	return if SentInstance.Parent then RecurssiveAncestor(SentInstance.Parent) else nil

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Method that will Change the Attribute with the given name to the given value on the given Instance:
function UtilityModule.ChangeAttribute(self: Utility, AttributeInstance: Instance, AttributeName: string, AttributeValue: any)
	AttributeInstance:SetAttribute(AttributeName, AttributeValue)
end

-- Will safely clone and return the cloned Instance as sent:
function UtilityModule.SafeClone(self: Utility, SentInstance: any): any
	--=======================================================================================================>
	-- Get its current Archivable Status:
	local OldArchivable = SentInstance.Archivable
	--=======================================================================================================>
	-- Set its Archivable Status to true:
	SentInstance.Archivable = true
	-- Clone it:
	local Clone = SentInstance:Clone()
	-- Return its original Status:
	SentInstance.Archivable = OldArchivable
	--=======================================================================================================>
	-- Return the Clone:
	return Clone
	--=======================================================================================================>
end

-- Method that will Recalculate the Humanoid's HipHeight:
function UtilityModule.RecalculateHipHeight(self: Utility, Character: any, Humanoid: Humanoid)
	--=======================================================================================================>
	local BottomOfHumanoidRootPart = Character.HumanoidRootPart.Position.Y - (1/2 * Character.HumanoidRootPart.Size.Y)
	local BottomOfFoot = Character.LeftFoot.Position.Y - (1/2 * Character.LeftFoot.Size.Y) -- Left or right. Chose left arbitrarily
	local NewHipHeight = BottomOfHumanoidRootPart - BottomOfFoot
	--=======================================================================================================>
	Humanoid.HipHeight = NewHipHeight
	--=======================================================================================================>
end

-- Method that will safely Call Core Methods:
function UtilityModule.CoreCall(self: Utility, Method: string, ...: any): ...any
	--=======================================================================================================>
	-- Define a Result Array:
	local Result = {}
	--=======================================================================================================>
	for Retries = 1, self._MaxRetries do
		-- Pcall the Method:
		if Method == 'SetCoreGuiEnabled' then
			Result = {pcall(StarterGui.SetCoreGuiEnabled, StarterGui, ...)}
		elseif Method == 'SetCore' then
			Result = {pcall(StarterGui.SetCore, StarterGui, ...)}
		end
		-- If Result1 is set, then break!
		if Result[1] then break end
		-- Wait:
		task.wait()
	end
	--=======================================================================================================>
	-- Return the unpacked results:
	return unpack(Result)
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ GET METHODS: ]


-- Method that will Get the ProductInfo from the passed ProductID:
function UtilityModule.GetProductInfo(self: Utility, ProductID: number): Dictionary
	--===========================================================================================>

	-- Define a Retries Variable:
	local Retries: number = 0

	--===========================================================================================>

	-- Define a Local, recursive Function:
	local function GetProductInfo(): Dictionary
		--==========================================================================>	
		-- Pcall function that will return the Value needed, if it succeeds:
		local Success: boolean, ProductInfo: Dictionary? = pcall(
			MarketplaceService.GetProductInfo, MarketplaceService, ProductID
		)
		-- If not a Success, then try again:
		if not Success then
			--==============================================>
			-- If the Current Try is at the Max Retry, return the Default:
			-- Else, Increment the Retries:
			if Retries == self._MaxRetries then return {Name = 'Product Info Name Error'} else Retries += 1 end 
			--==============================================>
			-- Return Call the Function again Recursively:
			return GetProductInfo()	
			--==============================================>
		else 
			--==============================================>
			-- Return the Value if it was a Success:
			return ProductInfo :: Dictionary
			--==============================================>
		end
		--==========================================================================>
	end

	--===========================================================================================>

	-- Return the returned Value from the Called Function:
	return GetProductInfo()

	--===========================================================================================>
end

-- Method that will Get a Player's HumanoidDescription, or create a new one if all else fails:
function UtilityModule.GetHumanoidDescription(self: Utility, UserID: number): HumanoidDescription
	--===========================================================================================>

	-- If no UserID was passed, return a blank HumanoidDescription:
	if not UserID then self.Log.Warn('No UserID passed') return Instance.new("HumanoidDescription") end

	--===========================================================================================>

	-- Define a Retries Variable:
	local Retries: number = 0

	--===========================================================================================>

	-- Define a Local, recursive Function:
	local function GetHumanoidDescription(): HumanoidDescription
		--==========================================================================>	
		-- Pcall function that will return the Value needed, if it succeeds:
		local Success: boolean, HumanoidDescription: HumanoidDescription? = pcall(
			Players.GetHumanoidDescriptionFromUserId, Players, UserID
		)
		-- If not a Success, then try again:
		if not Success then
			--==============================================>
			-- If the Current Try is at the Max Retry, return the Default:
			-- Else, Increment the Retries:
			if Retries == self._MaxRetries then
				self.Log.Warn(`{self._RunScope}:// Max Retries reached when trying to get HumanoidDescription. Returning Blank one.`) 
				-- Return a newly created Instance of Humanoid Description:
				return Instance.new("HumanoidDescription") 
			else 
				Retries += 1 
			end 
			--==============================================>
			-- Return Call the Function again Recursively:
			return GetHumanoidDescription()	
			--==============================================>
		else 
			--==============================================>
			-- Return the Value if it was a Success:
			return HumanoidDescription :: HumanoidDescription
			--==============================================>
		end
		--==========================================================================>
	end

	--===========================================================================================>

	-- Return the returned Value from the Called Function:
	return GetHumanoidDescription()

	--===========================================================================================>
end

--===========================================================================================================================>
--[ IN METHODS: ]


-- Method that will Check if the Player is in the Group with the ID Passed, and if theyre also in the Rank, if a RankID is passed:
function UtilityModule.InGroup(self: Utility, Player: Player, GroupID: number, RankID: number?, Compare: string?): boolean
	--===========================================================================================>

	-- Define a Retries Variable:
	local Retries: number = 0

	--===========================================================================================>

	-- Define a Local, recursive Function:
	local function InGroup(): boolean
		--==========================================================================>	
		-- If there was a RankID passed to the function, do RankID checking Code:
		if RankID then
			--===================================================================>
			-- Pcall function that will return the Value needed, if it succeeds:
			local Success: boolean, PlayerRoleID: number = pcall(Player.GetRankInGroup, Player, GroupID)
			-- If not a Success, then try again:
			if not Success then
				--==============================================>
				-- If the Current Try is at the Max Retry, return the Default:
				-- Else, Increment the Retries:
				if Retries == self._MaxRetries then return false else Retries += 1 end 
				--==============================================>
				-- Return Call the Function again Recursively:
				return InGroup()	
				--==============================================>
			else 
				--==============================================>
				-- Check the Rank ID and the Player's Rank ID on all the Comparisons if they apply:
				if Compare == "GreaterOrEqualTo" or Compare == ">=" then
					return if PlayerRoleID >= RankID then true else false
				elseif Compare == "LessOrEqualTo" or Compare == "<=" then
					return if PlayerRoleID <= RankID then true else false
				elseif Compare == "Less" or Compare == "<" then
					return if PlayerRoleID < RankID then true else false
				elseif Compare == "Greater" or Compare == ">" then
					return if PlayerRoleID > RankID then true else false
				else
					return if PlayerRoleID == RankID then true else false
				end
				--==============================================>
			end		
			--===================================================================>		
		else
			--===================================================================>	
			-- Pcall function that will return the Value needed, if it succeeds:
			local Success: boolean, Verdict: boolean? = pcall(Player.IsInGroup, Player, GroupID)
			-- If not a Success, then try again:
			if not Success then
				--==============================================>
				-- If the Current Try is at the Max Retry, return the Default:
				-- Else, Increment the Retries:
				if Retries == self._MaxRetries then return false else Retries += 1 end 
				--==============================================>
				-- Return Call the Function again Recursively:
				return InGroup()	
				--==============================================>
			else 
				--==============================================>
				-- Return the Value if it was a Success:
				return Verdict :: boolean
				--==============================================>
			end
			--===================================================================>
		end
		--==========================================================================>
	end

	--===========================================================================================>

	-- Return the returned Value from the Called Function:
	return InGroup()

	--===========================================================================================>
end

-- Function which when called will Return true or false based on whether the Player Passed, is in the Given GroupID with the given RoleName.
function UtilityModule.InGroupRole(self: Utility, Player: Player, GroupID: number, RoleName: string): boolean
	--===========================================================================================>

	-- Define a Retries Variable:
	local Retries: number = 0

	--===========================================================================================>

	-- Define a Local, recursive Function:
	local function InGroupRole(): boolean
		--==========================================================================>	
		-- Pcall function that will return the Value needed, if it succeeds:
		local Success: boolean, PlayerRoleName: string? = pcall(Player.GetRoleInGroup, Player, GroupID)
		-- If not a Success, then try again:
		if not Success then
			--==============================================>
			-- If the Current Try is at the Max Retry, return the Default:
			-- Else, Increment the Retries:
			if Retries == self._MaxRetries then return false else Retries += 1 end 
			--==============================================>
			-- Return Call the Function again Recursively:
			return InGroupRole()	
			--==============================================>
		else 
			--==============================================>
			-- Return the Value if it was a Success:
			return PlayerRoleName == RoleName
			--==============================================>
		end
		--==========================================================================>
	end

	--===========================================================================================>

	-- Return the returned Value from the Called Function:
	return InGroupRole()

	--===========================================================================================>
end

--===========================================================================================================================>
--[ IS METHODS: ]


-- Get the Tween Index based on whether the Character is Brisk Walking or not:
function UtilityModule.IsTweenPlaying(self: Utility, Tween: Tween): boolean
	return Tween.PlaybackState == Enum.PlaybackState.Playing
end

-- Method that will check the passed Instance to check if its a Tool:
function UtilityModule.IsATool(self: Utility, InstanceToCheck: Instance): boolean
	return if InstanceToCheck:GetAttribute("Tool") then true else false
end

-- Method that will take the two Instances, and check if the first is a descendant of the Parent:
function UtilityModule.IsDescendant(self: Utility, InstanceToCheck: Instance, ParentInstance: Instance): boolean
	return InstanceToCheck:IsDescendantOf(ParentInstance)
end

-- Function which returns whether the Child is a descendant of a Tool:
function UtilityModule.IsDescendantOfATool(self: Utility, InstanceToCheck: Instance): boolean
	--=======================================================================================================>
	-- If the Instance to Check is underneath the Player's ToolStorage Folder:
	if InstanceToCheck:FindFirstAncestor("ToolStorage") then return true end
	--=======================================================================================================>
	-- Get the FirstModel Ancestor of the Instance:
	local FirstModel: Model? = InstanceToCheck:FindFirstAncestorOfClass("Model")
	--=======================================================================================================>
	-- If a FirstModel was found:
	if FirstModel then
		-- If a FirstModel was found, and the FirstModel's Name is ToolStorageModel, then return true:
		-- If theres a FirstModel and the FirstModel is the tool, return true, else return false:
		return if FirstModel.Name == 'ToolStorageModel' then true elseif self:IsATool(FirstModel) then true else false
	else
		return false
	end
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ CREATE METHODS: ]


-- Method which will Create a new Cycler Object and return it:
function UtilityModule.CreateCycler(self: Utility, Table: Table): Cycler
	--=======================================================================================================>

	-- Create the Main Cycler Table:
	local Cycler: Cycler = {
		--======================================================>
		_Num   = 1;
		_Max   = self.Table.Length(Table);
		_Array = if self.Table.IsDictionary(Table) then self.Table.Values(Table) else table.clone(Table)
		--======================================================>
	} :: Cycler

	-- Set the Current Value:
	Cycler.Value = Cycler._Array[Cycler._Num]

	--=======================================================================================================>
	-- Main Methods:
	--=======================================================================================================>

	-- Cycles forward to the end of the Array and once it reaches it, it starts over at the starting Index of the Array:
	function Cycler.Cycle(self: Cycler): string
		--======================================================>
		-- Calculate the new Number:
		self._Num = if self._Num < self._Max then self._Num + 1 else 1
		-- Set a new Value from the Array:
		self.Value = self._Array[self._Num]
		-- Return said Value if needed:
		return self.Value
		--======================================================>
	end

	-- Cycles Forward to the end of the Array and stops increasing when it reaches ending Index:
	function Cycler.Forward(self: Cycler): string
		--======================================================>
		-- Cycles forward to the end of the Array and stops increasing when it reaches ending Index:
		self._Num = if self._Num < self._Max then self._Num + 1 else self._Num
		-- Set a new Value from the Array:
		self.Value = self._Array[self._Num]
		-- Return said Value if needed:
		return self.Value
		--======================================================>
	end

	-- Cycles Backward to the start of the Array and stops decreasing when it reaches the first Index:
	function Cycler.Backward(self: Cycler): string
		--======================================================>
		-- Calculate the new Num:
		self._Num = if self._Num == 1 then self._Num else self._Num - 1
		-- Set a new Value from the Array:
		self.Value = self._Array[self._Num]
		-- Return said Value if needed:
		return self.Value
		--======================================================>
	end

	-- Will destroy the Object by clearing all self Data:
	function Cycler.Destroy(self: Cycler)
		--======================================================>
		-- Clear all self data:
		for Index, Data in pairs(self) do self[Index] = nil end
		--======================================================>
	end

	--=======================================================================================================>
	-- Alternate names for the methods:
	--=======================================================================================================>

	-- Cycles Backward to the start of the Array and stops decreasing when it reaches the first Index:
	function Cycler.Backwards(self: Cycler): string
		--======================================================>
		-- Calculate the new Num:
		self._Num = if self._Num == 1 then self._Num else self._Num - 1
		-- Set a new Value from the Array:
		self.Value = self._Array[self._Num]
		-- Return said Value if needed:
		return self.Value
		--======================================================>
	end

	-- Cycles Forward to the end of the Array and stops increasing when it reaches ending Index:
	function Cycler.Forwards(self: Cycler): string
		--======================================================>
		-- Cycles forward to the end of the Array and stops increasing when it reaches ending Index:
		self._Num = if self._Num < self._Max then self._Num + 1 else self._Num
		-- Set a new Value from the Array:
		self.Value = self._Array[self._Num]
		-- Return said Value if needed:
		return self.Value
		--======================================================>
	end

	--=======================================================================================================>

	-- Return the Cycler Object:
	return Cycler

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ META MODULE METHODS: ]


-- Function which when called, sets all Client or Server Specific Data:
function UtilityModule.SetLocalModulesArray(self: Utility, Array: Array, ArrayLength: number, FrameworkData: FrameworkData): Array

	---=======================================================================================================>	

	local RequiredArray: {} = {}

	-- Will loop over the Array of Modules, twice. Once to require, the second go around will Start/Initialize:
	for Index = 1, (ArrayLength * 2) do

		--==============================================================>

		-- Determine what part of the Loop the Loop is on, the first go around, or the second go around:
		local LoopNum: number = if Index > ArrayLength then 2 else 1

		-- Adjust Index to Index the array twice:
		Index = if Index > ArrayLength then Index - ArrayLength else Index

		--==============================================================>

		-- ModuleScript Instance variable
		local ModuleScript: ModuleScript = Array[Index]

		--==============================================================>

		-- If First go around of the loop, require the Module and set it to the LocalModules table.
		-- On the second go around, initialize the Module with the Start Function:
		if LoopNum == 1 then

			--======================================================>

			-- Format the name of the Module, without the Module suffix:
			local ModuleName: string = string.gsub(string.gsub(ModuleScript.Name, "Framework", ""), "Module", "")

			--======================================================>

			-- Assign the Module at the same Index to now a required object/table
			RequiredArray[Index] = require(ModuleScript) :: any

			local ModuleVariable: string? = ModuleScript:GetAttribute('Variable')

			if ModuleVariable then Array[Index].ModuleVariable = ModuleVariable end

			--======================================================>

		elseif LoopNum == 2 then

			if RequiredArray[Index]["Start"] then RequiredArray[Index]:Start(FrameworkData) end		

			local Freeze: boolean = ModuleScript:GetAttribute('Freeze')
			local DataModule: boolean = ModuleScript:GetAttribute('DataModule')

			if Freeze then

				if DataModule then
					self.Table.Freeze(RequiredArray[Index])
				else
					if not table.isfrozen(RequiredArray[Index]) then table.freeze(RequiredArray[Index]) end
				end

			end

		end

		--==============================================================>

	end	

	-- Return the LocalModules Dictionary:
	return RequiredArray

	---=======================================================================================================>

end

--===========================================================================================================================>

-- Set Module Index Function:
function UtilityModule.__index(self: Utility, Index: string): any
	--==========================================================================>
	if Index == '_DebugLogging' then return false end
	--==========================================================================>
	-- If Index is in the immediate Module tree, return that value:			
	if UtilityModule[Index] then return UtilityModule[Index] end
	--==========================================================================>
	-- Return False if all else fails!
	return false 
	--==========================================================================>
end

-- Create the New Index function:
function UtilityModule.__newindex(self: Utility, Index: string, Value)
	--=======================================================================================================>
	self.Log.Error(`"{Index}" cannot be added to Utility`)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return the Module table
return table.freeze(UtilityModule.New())

--===========================================================================================================================>