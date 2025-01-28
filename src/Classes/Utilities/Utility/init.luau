--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Define Module table
local UtilityModule = {}

--===========================================================================================================================>
--[ SERVICES: ]

local HttpService = game:GetService('HttpService')

--===========================================================================================================================>
--[ DEFINE TYPES: ]

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

--===========================================================================================================================>

-- Return the Module table
return table.freeze(UtilityModule) :: UtilityModule

--===========================================================================================================================>