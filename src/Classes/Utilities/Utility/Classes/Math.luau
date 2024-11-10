--===========================================================================================================================>
--!native
--!strict
--===========================================================================================================================>

-- Define Module table
local Math: MathModule = {} :: MathModule

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions: {} = require(script:FindFirstAncestor('Utility').TypeDefinitions)

-- Insert the Object Types:
type MathModule = TypeDefinitions.MathModule

--===========================================================================================================================>

-- Method that will Lerp values towards a goal:
function Math.Lerp(Start: number, Goal: number, Alpha: number): number
	return Start + ((Goal - Start) * Alpha)
end

-- Method that will Step a Value to a goal at the specified Rate:
function Math.StepTowards(Value: number, Goal: number, Rate: number): number
	--===========================================================================================>
	if math.abs(Value - Goal) < Rate then 
		return Goal		
	elseif Value > Goal then 
		return (Value - Rate)
	elseif Value < Goal then 
		return (Value + Rate)
	else 
		return Goal 
	end
	--===========================================================================================>
end

-- Method that will Round a Number to the specified Decimal Places:
function Math.Round(Num: (string | number), NumDecimalPlaces: number?): number
	return tonumber(string.format(`%.{NumDecimalPlaces or 0}f`, tostring(Num))) :: number
end

-- Method that will Round a passed Number with an optional factor:
function Math.RoundFactor(Number: number, Factor: number?): number
	--===========================================================================================>
	local Mult: number = 10 ^ (Factor or 0)
	-- Return the final floored value:
	return math.floor((Number * Mult) + 0.5) / Mult
	--===========================================================================================>
end

-- Method that will Round the Number to the Nearest Factor Interval:
function Math.RoundNearestInterval(Number: number, Factor: number): number
	return Math.Round((Math.RoundFactor(Number / Factor) * Factor))
end

-- Method that will Round a Vector3:
function Math.RoundVector(Vector: Vector3): Vector3
	return Vector3.new(math.floor(Vector.X + 0.5), math.floor(Vector.Y + 0.5), math.floor(Vector.Z + 0.5) )
end

--===========================================================================================================================>

-- Return the Module table
return Math :: MathModule

--===========================================================================================================================>