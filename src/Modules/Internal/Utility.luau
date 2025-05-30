--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Utility')

-- Define Module table
local UtilityModule = {}

--===========================================================================================================================>
--[ SERVICES: ]


local HttpService = game:GetService('HttpService')

--===========================================================================================================================>
--[ DEFINE TYPES: ]

local MAX_PART_SIZE = 2024

-- Create the Module Type:
type UtilityModule = typeof(UtilityModule)

--===========================================================================================================================>

--- Method that takes in an optional DeltaTime and will Increment the Counter and return a boolean:
@native
function UtilityModule.RateLimiter(RateData: {Counter: number; CounterMax: number}, DeltaTime: number?): boolean
	--=======================================================================================================>
	if DeltaTime then
		RateData.Counter += DeltaTime; if RateData.Counter >= RateData.CounterMax then RateData.Counter = 0; end; return RateData.Counter == 0
	else
		RateData.Counter = (RateData.Counter + 1) % (RateData.CounterMax + 1); return RateData.Counter == 0
	end
	--=======================================================================================================>
end

--- Method that will return an Idenitfier String from GUID:
function UtilityModule.Identifier(Brackets: boolean, Dashes: boolean?, Shortened: boolean?, Characters: number?): string
	--=======================================================================================================>
	-- Generate the Id and if Shortened, Shave off some characters:
	local Identifier: string = HttpService:GenerateGUID(Brackets)
	-- If Shortened is true, Shave off some characters:
	if Shortened == true then Identifier = string.sub(Identifier, 1, Characters or 7) end
	-- If Dashes is false, remove/replace the dash characters with nothing in the string:
	if Dashes == false then Identifier = Identifier:gsub('-', '') end
	-- Return the Id String:
	return Identifier
	--=======================================================================================================>
end

function UtilityModule.EnsureConfig(SettingsFolder: Folder, Name: string, Default: number)
	if SettingsFolder:GetAttribute(Name) == nil or SettingsFolder:GetAttribute(Name) < 1 then SettingsFolder:SetAttribute(Name, Default) end
end

function UtilityModule.IsValidEnumValue(EnumObject: any, Value): boolean
	return EnumObject:GetName(Value) ~= 'Failure'
end

--- @Public
--- Function to create Parts to a certain size and scale and parented to the Model Container:
function UtilityModule.CreateCube(Container: Model, CubeCFrame: CFrame, CubeSize: Vector3)
	--=======================================================================================================>
	if CubeSize.X > MAX_PART_SIZE or CubeSize.Y > MAX_PART_SIZE or CubeSize.Z > MAX_PART_SIZE then
		local quarterSize = CubeSize * 0.25
		local halfSize = CubeSize * 0.5
		UtilityModule.CreateCube(Container, CubeCFrame * CFrame.new(-quarterSize.X, -quarterSize.Y, -quarterSize.Z), halfSize)
		UtilityModule.CreateCube(Container, CubeCFrame * CFrame.new(-quarterSize.X, -quarterSize.Y, quarterSize.Z), halfSize)
		UtilityModule.CreateCube(Container, CubeCFrame * CFrame.new(-quarterSize.X, quarterSize.Y, -quarterSize.Z), halfSize)
		UtilityModule.CreateCube(Container, CubeCFrame * CFrame.new(-quarterSize.X, quarterSize.Y, quarterSize.Z), halfSize)
		UtilityModule.CreateCube(Container, CubeCFrame * CFrame.new(quarterSize.X, -quarterSize.Y, -quarterSize.Z), halfSize)
		UtilityModule.CreateCube(Container, CubeCFrame * CFrame.new(quarterSize.X, -quarterSize.Y, quarterSize.Z), halfSize)
		UtilityModule.CreateCube(Container, CubeCFrame * CFrame.new(quarterSize.X, quarterSize.Y, -quarterSize.Z), halfSize)
		UtilityModule.CreateCube(Container, CubeCFrame * CFrame.new(quarterSize.X, quarterSize.Y, quarterSize.Z), halfSize)
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

--===========================================================================================================================>

-- Return the Module table
return table.freeze(UtilityModule) :: UtilityModule

--===========================================================================================================================>