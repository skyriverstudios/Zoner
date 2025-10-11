--===========================================================================================================================>
--!strict
--===========================================================================================================================>
-- Enum2

-- Original Author:
-- Ben Horton (ForeverHD)

-- Restructure:
-- 7/12/2024
-- IISato

-- Original Description:

-- Custom enum implementation that provides an effective way to compare, send
-- and store values. Instead of returning a userdata value, enum items return
-- their corresponding itemValue (an integer) when indexed. Enum items can
-- also associate a 'property', specified as the third element, which can be
-- retrieved by doing ``enum.getProperty(ITEM_NAME_OR_VALUE)``
-- This ultimately means groups of data can be easily categorised, efficiently
-- transmitted over networks and saved without throwing errors.
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Enums')

--[=[
	@class Enums

	Runtime registry of all Zoner enum tables.  
	At startup, `EnumsModule:Start()` scans `script.Enum2s` and creates a numeric
	enum object for each ModuleScript it finds (e.g. `DetectionMethod`, `Rate`, etc.).

	**Design**
	- Each enum is an **Enum2** object (documented below).
	- Indexing by name returns a **number** (`Enums.DetectionMode.Point` → `number`).
	- Reflection helpers: `:GetName(value)`, `:GetValue(name)`, `:GetProperty(nameOrValue?)`.

	**Common enums**
	- `DetectionMethod`, `DetectionMode`, `DetectionCoverage`
	- `Rate`, `Execution`, `Simulation`, `Bounds`
]=]
local Enums: Enums = {} :: Enums

-- Define Module table:
local EnumsModule: EnumsModule = {Enums = Enums, Started = false}
EnumsModule.__index = EnumsModule

-- Define the Sub Table:
local Enum2Table: Enum2Table = {}
Enum2Table.__index = Enum2Table

--[=[
	@type Enums {[string]: Enum2}
	@within Enums

	Map of enum name → Enum2 object.
]=]

--[=[
	@interface EnumItem
	@within Enums
	@field Name string --Display name of the item (e.g. "Fast")
	@field Value number --Numeric id returned when indexing by name
	@field Property any? --Optional associated property payload
]=]

--[=[
	@interface Enum2
	@within Enums

	Represents one named enum table. Indexing with an item name returns the **number** id:
	`Enums.Rate.Fast` → `number`.

	@field Name string --Enum name
	@field Enums {EnumItem} --Ordered items for iteration
	@field Values {[string]: number} --Value-string → index lookup
	@field Names {[string]: number} --Name → index lookup
	@field Properties {[string]: number} --Property-string → index lookup

	@field GetName (self: Enum2, valueOrProperty: any) -> string --Return item name or "Failure"
	@field GetValue (self: Enum2, nameOrProperty: any) -> (number | "Failure") --Return numeric id or "Failure"
	@field GetProperty (self: Enum2, nameOrValue: any) -> (any | "Failure") --Return property payload or "Failure"
]=]

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local Types = require(script.Types)


-- The Main Enums Module Type:
-- The Enums Variable Type:
export type EnumsModule = Types.EnumsModule
export type Enums       = Types.Enums

-- The MetaData for the Enum2 Object:
-- The Table Type for Enum2:
-- The Enum2 Object Type:
export type Enum2MetaData = Types.Enum2MetaData
export type Enum2Table    = Types.Enum2Table
export type Enum2         = Types.Enum2

-- An Array of Arrays of a String, Number, Number?
type EnumDetails = Types.EnumDetails

-- Enums
export type DetectionCoverages = Types.DetectionCoverages
export type DetectionMethods   = Types.DetectionMethods
export type DetectionModes     = Types.DetectionModes
export type Simulations        = Types.Simulations
export type Executions         = Types.Executions
export type Bounds             = Types.Bounds
export type Rates              = Types.Rates

--===========================================================================================================================>

--[=[
	@interface DetectionMethod
	@within Enums

	@field Automatic number --Auto-pick based on container shape & coverage/mode;
	@field Efficient number --Fastest. Uses simple CFrame and Size math checks to determine location in the Zone Volume.
	@field Simple    number --Balanced: may use `GetPartBoundsInBox/Radius` for modest cost and good fidelity. 
	@field Complex   number --Highest accuracy: per-part or mesh-aware paths like `GetPartsInPart`; most expensive. If ZoneContainer has no Instances, they will be created.
]=]
--[=[
	@prop DetectionMethod DetectionMethod
	@within Enums
	@readonly
]=]

--[=[
	@interface DetectionMode
	@within Enums

	@field Full  number --Target must be fully inside or outside the Zone bounds to trigger entrance or exit.
	@field Touch number --Any intersection with the zone boundary counts (partial overlap). (Doesn't actually use .Touched)
	@field Point number --One or more representative points must be inside (fastest). Often pairs with Efficient math tests.
]=]
--[=[
	@prop DetectionMode DetectionMode
	@within Enums
	@readonly
]=]

--[=[
	@interface DetectionCoverage
	@within Enums

	@field Center   number --Check only the target's center point (very fast). Often math-only.
	@field AllParts number --Every relevant part/point must satisfy `DetectionMode` (strict).
	@field AnyPart  number --At least one relevant part/point must satisfy `DetectionMode` (lenient).
]=]
--[=[
	@prop DetectionCoverage DetectionCoverage
	@within Enums
	@readonly
]=]

--[=[
	@interface Rate
	@within Enums

	@field Slow      number --Step period ≈ **1.0 s** between evaluations.
	@field Moderate  number --Step period ≈ **0.5 s**.
	@field Fast      number --Step period ≈ **0.1 s**.
	@field Immediate number --Step period **0 s** (continuous / every frame slice).
]=]
--[=[
	@prop Rate Rate
	@within Enums
	@readonly
]=]

--[=[
	@interface Execution
	@within Enums
	
	@field Serial   number --Single-threaded group holder. Supports manual stepping via `Zone:Step(...)` when `ManualStepping = true`.
	@field Parallel number --Actor-backed parallel evaluation. Manual stepping not exposed; runs on its own schedule. Fastest with lots of Zones.
]=]
--[=[
	@prop Execution Execution
	@within Enums
	@readonly
	@since 0.9.9
]=]

--[=[
	@interface Simulation
	@within Enums
	
	@field PostSimulation number --Run after physics; safe for effects based on final transforms.
	@field PreSimulation  number --Run before physics; good for preparing forces/constraints.
	@field PreRender      number --Run before rendering (client). On server, requests are coerced to PostSimulation.
]=]
--[=[
	@prop Simulation Simulation
	@within Enums
	@readonly
	@since 0.9.9
]=]

--[=[
	@interface Bounds
	@within Enums
	
	@field Automatic number --Auto-select bounds model from the container (boxes/spheres vs per-part).
	@field BoxExact  number --Automatically creates a Rotated Box (No Instance unless specified) that fits the sum of the ZoneContainer
	@field BoxVoxel  number --Automatically creates a Rotated Box (No Instance unless specified) that fits the sum of the ZoneContainer, then rounds to Voxel Grid
	@field PerPart   number --Evaluate each contained BasePart or {CFrame, Size} individually as the sum of the whole Zone.
]=]
--[=[
	@prop Bounds Bounds
	@within Enums
	@readonly
]=]

--===========================================================================================================================>
--[ FUNCTIONS: ]
-- Defined Functions for the Enums Module:


--[=[
	@function GetEnums
	@within Enums
	@return Enums --The live registry of all enum tables
]=]
function EnumsModule.GetEnums(self: EnumsModule): Enums
	return EnumsModule.Enums :: Enums
end

--[=[
	@function CreateEnum
	@within Enums
	@param EnumName string --Name of the enum to create (registry key)
	@param Details { {string, number, any?} } --Array of {Name, Value, Property?} tuples
	Constructs and registers a new Enum2 under `Enums[EnumName]`.
]=]
function EnumsModule.CreateEnum(self: EnumsModule, EnumName: string, Details: EnumDetails)
	--=======================================================================================================>
	-- Make sure an Assert the first Paramater is a String for the Enum Name:
	assert(typeof(EnumName) == "string",    `\n[Error] "Bad Argument" - Enums must be created using a string name!`)
	-- Assert that the Second Paramater is a Table:
	assert(typeof(Details) == "table",      `\n[Error] "Bad Argument" - Enums must be created using a table!`)
	-- Assert that the Enum hasnt already been created:
	assert(not EnumsModule.Enums[EnumName], `\n[Error] "Bad Argument" - Enum by the Name "{EnumName}" already exists!`)
	--=======================================================================================================>
	-- Construct the Enum2 and Add it to the Enums Table:
	EnumsModule.Enums[EnumName] = Enum2Table.New(EnumName, Details)
	--=======================================================================================================>
end

--[=[
	@function Start
	@within Enums
	Initializes the registry by requiring every ModuleScript under `script.Enum2s`
	and calling `CreateEnum` with its contents. Safe to call once.
]=]
function EnumsModule.Start(self: EnumsModule)
	--=======================================================================================================>
	
	-- Check if the Module has already had this function called or not:
	if self.Started == true then warn(`Called the "Start" function on the EnumsModule after it has already been started/called`); return end
	
	-- Set Started Variable to true:
	self.Started = true
	
	--=======================================================================================================>
	
	--[[
		-- Example enum
		CreateEnum("Color", {
			{"White", 1, Color3.fromRGB(255, 255, 255)},
			{"Black", 2, Color3.fromRGB(0, 0, 0)},
		})
	--]]

	-- Get the Children of the Script (Hopefully ModuleScripts)
	local ScriptChildren: {ModuleScript} = script.Enum2s:GetChildren()

	-- Loop through the Children Array to Create Enums:
	for Index: number, ChildModule: ModuleScript in ipairs(ScriptChildren) do
		--=======================================================================>
		-- If the Child is not a ModuleScript, Continue loop:
		if not ChildModule:IsA("ModuleScript") then continue end
		-- Require the Module which should be a EnumDetails Module, and Pass it, along with the ModuleName to the 
		-- CreateEnum Function:
		EnumsModule:CreateEnum(ChildModule.Name, require(ChildModule) :: EnumDetails)
		--=======================================================================>
	end
	
	-- Clear Array from Memory:
	ScriptChildren = nil :: any
	
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ CONSTRUCTOR FUNCTIONS: ]


--[=[
	@private
	@within Enums

	@param EnumName string --Enum name (registry key)
	@param Details { {string, number, any?} } --Item tuples
	@return Enum2 --Constructed enum object
	Internal constructor for an `Enum2`.
]=]
function Enum2Table.New(EnumName: string, Details: EnumDetails): Enum2
	--=======================================================================================================>
	-- Make sure an Assert the first Paramater is a String for the Enum Name:
	assert(typeof(EnumName) == "string",    `\n[Error] "Bad Argument" - Enums must be created using a string name!`)
	-- Assert that the Second Paramater is a Table:
	assert(typeof(Details) == "table",      `\n[Error] "Bad Argument" - Enums must be created using a table!`)
	-- Assert that the Enum hasnt already been created:
	assert(not EnumsModule.Enums[EnumName], `\n[Error] "Bad Argument" - Enum by the Name "{EnumName}" already exists!`)
	--=======================================================================================================>

	-- Define Enum2 Data
	local Enum2Data: Enum2MetaData = {
		--==========================>
		Name = EnumName;
		--==========================>
		Properties = {};
		Values     = {};
		Names      = {};
		--==========================>
		Enums = {};
		--==========================>
		_Type = 'Enum2'
		--==========================>
	} :: Enum2MetaData
	
	--=======================================================================================================>
	
	-- Loop through the Details Arrays to Create a Different "Enum" Value for Each Array:
	for Index: number, Detail: {string | number} in ipairs(Details) do
		--====================================================================================>

		-- Grab the First Index of the Detail Array, it should be a string name:
		local DetailName: string = Detail[1] :: string
		-- Grab the Second Index of the Detail Array as the Value:
		local DetailValue: number = Detail[2] :: number
		-- Grab the Third Index of the Detail Array as the Property.. Possibly:
		local DetailProperty: any? = Detail[3]

		-- Grab the Second Index of the Detail Array as the Value:
		local DetailValueString: string = tostring(DetailValue)

		--====================================================================================>

		-- Assert that the Detail should be Comprised of Arrays!:
		assert(typeof(Detail) == "table",          `\n[Error] "Bad Argument" - Details must only be comprised of tables! \nProblem Index: {Index}`)
		-- Assert that the first Index in the Array must be a String:
		assert(typeof(DetailName) == "string",     `\n[Error] "Bad Argument" - Detail must be a string! \nProblem Index: {Index}`)
		-- Assert that the DetailName used for this Value of the Enum is not already in use:
		assert(typeof(not Enum2Data.Names[DetailName]),  `\n[Error] "Bad Argument" - Detail Name "{DetailName}" already exists! \nProblem Index: {Index}`)
		-- Assert that the Enum DetailName used is not already taken via a Method:
		assert(typeof(not Enum2Table[DetailName]), `\n[Error] "Bad Argument" - Detail Name "{DetailName}" is reserved! \nProblem Index: {Index}`)
		--====================================================================================>
		-- Assert that the Enum Detail Value is not already in use either:
		assert(typeof(not Enum2Data.Values[DetailValueString]), `\n[Error] "Bad Argument" - Detail Value: "{DetailValueString}" already exists! \nProblem Index: {Index}`)
		--====================================================================================>

		-- Add the DetailName to the UsedNames Dictionary for Checking:
		Enum2Data.Names[DetailName] = Index
		-- Add the DetailValue as a String to the UsedValues Dictionary for Checking:
		Enum2Data.Values[DetailValueString] = Index

		--====================================================================================>

		-- If a Detail Property was added, check it and Add it:
		if DetailProperty then
			--================================================================>
			-- Assert that the Enum Detail Property is not already in use either:
			assert(typeof(not Enum2Data.Properties[tostring(DetailProperty)]), `\n[Error] "Bad Argument" - Detail Property: "{DetailProperty}" already exists! \nProblem Index: {Index}`)
			--================================================================>
			-- Add the DetailProperty as a String to the UsedProperties Dictionary for Checking:
			Enum2Data.Properties[tostring(DetailProperty)] = Index
			--================================================================>
		end

		--====================================================================================>

		-- Insert a Dictionary containing all the Details of Said Enum into an Enums Array for Indexing:
		table.insert(Enum2Data.Enums, {Name = DetailName, Value = DetailValue, Property = DetailProperty})

		-- Add the DetailName as a Key corresponding to its DetailValue on the Enum2 Table:
		Enum2Data[DetailName] = DetailValue

		--====================================================================================>
	end

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Enum2Table:
	setmetatable(Enum2Data, Enum2Table)

	--=======================================================================================================>

	-- Return the MetaTable Data
	return Enum2Data :: Enum2

	--=======================================================================================================>
end

--[=[
	@method Destroy
	@within Enums
	@private

	@param self Enum2 --Enum object to destroy
	Removes the enum from the registry and clears its data.
]=]
function Enum2Table.Destroy(self: Enum2)
	--=======================================================================================================>

	-- Grab the EnumName:
	local EnumName: string = self.Name

	-- Clear all self data:
	for Index, Data in pairs(self) do self[Index] = nil end

	-- Set the Metatable to nil
	setmetatable(self :: any, nil)	

	-- Clear self from Enum Table:
	EnumsModule.Enums[EnumName] = nil

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ METHODS: ]
-- Defined Functions for the Enums2 Table:


--[=[
	@method GetName
	@within Enums
	
	@param self Enum2
	@param valueOrProperty any --Numeric value or property payload/name
	@return string --Item name or "Failure"
]=]
function Enum2Table.GetName(self: Enum2, ValueOrProperty: any): string
	--=======================================================================================================>
	-- Convert the ValueOrProperty into a String under the Name: "StringIndexer"
	local StringIndexer: string = tostring(ValueOrProperty)

	-- Define an EnumIndex Variable:
	local EnumIndex: number = self.Names[StringIndexer] or self.Properties[StringIndexer] or self.Values[StringIndexer]

	-- Loop through the Enums Array, Checking the Name, Property and Value if they Match the StringIndexer.
	-- If they do match, Set the EnumIndex to the Array Index and Break the loop:
	--for Index: number, Detail in ipairs(self.Enums) do
	--	if Detail.Name            == StringIndexer then EnumIndex = Index break end
	--	if Detail.Property        == StringIndexer then EnumIndex = Index break end
	--	if tostring(Detail.Value) == StringIndexer then EnumIndex = Index break end
	--end

	-- If an EnumIndex was set, use the EnumIndex to Index the EnumDetails Array and Grab the Name Variable to return,
	-- else return the string failure because we failed I guess:
	return if EnumIndex then self.Enums[EnumIndex].Name else 'Failure'
	--=======================================================================================================>
end

--[=[
	@method GetValue
	@within Enums
	
	@param self Enum2
	@param nameOrProperty any --Item name or property payload/name
	@return number | "Failure" --Numeric id or "Failure"
]=]
function Enum2Table.GetValue(self: Enum2, NameOrProperty: any): any
	--=======================================================================================================>
	-- Convert the NameOrProperty into a String under the Name: "StringIndexer"
	local StringIndexer: string = tostring(NameOrProperty)

	-- Define an EnumIndex Variable:
	local EnumIndex: number = self.Values[StringIndexer] or self.Names[StringIndexer] or self.Properties[StringIndexer]

	-- Loop through the Enums Array, Checking the Name and Property if they Match the StringIndexer.
	-- If they do match, Set the EnumIndex to the Array Index and Break the loop:
	--for Index: number, Detail in ipairs(self.Enums) do
	--	if Detail.Name     == StringIndexer then EnumIndex = Index break end
	--	if Detail.Property == StringIndexer then EnumIndex = Index break end
	--end

	-- If an EnumIndex was set, use the EnumIndex to Index the EnumDetails Array and Grab the Name Variable to return,
	-- else return the string failure because we failed I guess:
	return if EnumIndex then self.Enums[EnumIndex].Value else 'Failure'
	--=======================================================================================================>
end

--[=[
	@method GetProperty
	@within Enums

	@param self Enum2
	@param nameOrValue any --Item name or numeric value
	@return any | "Failure" --Associated property payload or "Failure"
]=]
function Enum2Table.GetProperty(self: Enum2, NameOrValue: any): string?
	--=======================================================================================================>
	-- Convert the NameOrValue into a String under the Name: "StringIndexer"
	local StringIndexer: string = tostring(NameOrValue)

	-- Define an EnumIndex Variable:
	local EnumIndex: number = self.Names[StringIndexer] or self.Values[StringIndexer]

	-- Loop through the Enums Array, Checking the Name and Value if they Match the StringIndexer.
	-- If they do match, Set the EnumIndex to the Array Index and Break the loop:
	--for Index: number, Detail in ipairs(self.Enums) do
	--	if Detail.Name            == StringIndexer then EnumIndex = Index break end
	--	if tostring(Detail.Value) == StringIndexer then EnumIndex = Index break end
	--end

	-- If an EnumIndex was set, use the EnumIndex to Index the EnumDetails Array and Grab the Name Variable to return,
	-- else return the string failure because we failed I guess:
	return if EnumIndex then self.Enums[EnumIndex].Property or nil else 'Failure'
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Call the Function to Begin Creating Enums:
EnumsModule:Start()

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(EnumsModule:GetEnums())

--===========================================================================================================================>