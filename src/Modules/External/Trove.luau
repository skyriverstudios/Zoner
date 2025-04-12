--===========================================================================================================================>
--!native
--!strict
--===========================================================================================================================>
-- Trove
-- Stephen Leitnick
-- October 16, 2021

-- @class Trove
-- A Trove is helpful for tracking any sort of object during
-- runtime that needs to get cleaned up at some point.
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Trove')

-- Define Module table
local TroveModule = {}

--===========================================================================================================================>
--[ DEFINE CONSTANTS: ]


-- Markers for Object Types:
local FN_MARKER, THREAD_MARKER = 'function', 'thread'

--===========================================================================================================================>
--[ DEFINE GLOBALS: ]


-- Require the GoodSignal Module:
local GoodSignal = require(`./GoodSignal`)
-- Require the Log Utility Module:
local Log        = {Warn = warn; Error = error, Print = print}

--===========================================================================================================================>
--[ DEFINE TYPES: ]


type Class<ClassTable> = { New: (...any) -> ClassTable } | { new: (...any) -> ClassTable } | ((...any) -> ClassTable)

type ClassNew1<ClassTable> = { New: (...any) -> ClassTable }
type ClassNew2<ClassTable> = { new: (...any) -> ClassTable }
type ClassCall<ClassTable> = (...any) -> ClassTable

-- Create and Export the Module's Object Type:
export type Trove = typeof(setmetatable({} :: {
	--==========================>
	_Objects: {};
	_Cleaning: boolean;
	--==========================>
}, {} :: {__index: typeof(TroveModule)}
))

--===========================================================================================================================>
--[ LOCAL FUNCTIONS: ]


local function AssertPromiseLike(object)
	if
		type(object) ~= "table"
		or type(object.getStatus) ~= "function"
		or type(object.finally) ~= "function"
		or type(object.cancel) ~= "function"
	then
		Log.Error("Did not receive a Promise as an argument", 3)
	end
end

@native
local function CleanupObject(Trove: Trove, Object: any, CleanupMethod: any)
	--=======================================================================================================>
	if CleanupMethod == FN_MARKER then
		Object()
	elseif CleanupMethod == THREAD_MARKER then
		task.cancel(Object)
	else

		if Object == nil then
			Log.Warn(`Trove:`, `Object was nil when Cleaning up Object with: "{CleanupMethod}"`)
		elseif CleanupMethod == nil then
			Log.Warn(`Trove:`, `CleanupMethod was nil when Cleaning up Object:`, Object)
		elseif Object[CleanupMethod] == nil then
			Log.Warn(`Trove:`, `No Method returned with Object:`, Object, `CleanupMethod: "{CleanupMethod}"`)
		else
			Object[CleanupMethod](Object)
		end

	end
	--=======================================================================================================>
end

@native
local function FindAndRemoveFromObjects(Trove: Trove, Object: any, Cleanup: boolean): boolean
	--=======================================================================================================>
	-- Create Local reference to the Objects table:
	local Objects = Trove._Objects
	-- Loop through the table of Objects, clearing and calling the clean up method on the matching Object:
	for Index: number, Obj: any in ipairs(Objects) do
		--===================================================>
		-- if Object matches the passed Object to remove:
		if Obj[1] == Object then

			-- Get total number of Objects:
			local ObjectNum: number = #Objects

			-- Sets:
			Objects[Index], Objects[ObjectNum] = Objects[ObjectNum], nil

			-- If Cleanup is true, then cleanup the Object:
			if Cleanup then CleanupObject(Trove, Obj[1], Obj[2]) end

			-- Return true because it was found!:
			return true

		end
		--===================================================>
	end
	--=======================================================================================================>
	-- Return false because nothing was found:
	return false
	--=======================================================================================================>
end

@native
local function GetObjectCleanupFunction(Trove: Trove, Object: any, CleanupMethod: any): string?
	--=======================================================================================================>
	-- Get the current type of the Object:
	local Type = typeof(Object)
	--=======================================================================================================>
	-- If type is a function or a thread, return the Constants:
	if Type == "function" then return FN_MARKER elseif Type == "thread" then return THREAD_MARKER end
	-- If Object has a cleanup Method sent, return it:
	if CleanupMethod then return CleanupMethod end
	--=======================================================================================================>
	if Type == "Instance" then
		return "Destroy"
	elseif Type == "RBXScriptConnection" then
		return "Disconnect"
	elseif Type == "table" then
		-- If the type of the Destroy Method is a function then return Destroy, if the Disconnect Method is a function return Disconnect:
		if typeof(Object.Destroy) == "function" then return "Destroy" elseif typeof(Object.Disconnect) == "function" then return "Disconnect" end
	end
	--=======================================================================================================>
	-- If nothing was found, error:
	Log.Error(`Failed to get cleanup function for object: "{Type}": "{tostring(Object)}"`, 3)
	-- Return nothing
	return nil
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ METHODS: ]


--[=[
	@return Trove
	Constructs a Trove object.
]=]
function TroveModule.New(): Trove
	return setmetatable({ _Objects = {}; _Cleaning = false; }, TroveModule :: typeof(TroveModule) & {__index: typeof(TroveModule)})
end

--[=[
	Cleans up all objects in the trove. This is
	similar to calling `Remove` on each object
	within the trove. The ordering of the objects
	removed is _not_ guaranteed.
]=]
@native
function TroveModule.Clean(self: Trove)
	--=======================================================================================================>
	-- If Cleaning, then return:
	if self._Cleaning then return end
	-- Set cleaning to true:
	self._Cleaning = true
	--=======================================================================================================>
	-- Loop through all the Objects and clean them all up:
	for Index: number, Object: any in ipairs(self._Objects) do CleanupObject(self, Object[1], Object[2]) end
	-- Clear the Objects table:
	table.clear(self._Objects)
	--=======================================================================================================>
	-- Set cleaning to false:
	self._Cleaning = false
	--=======================================================================================================>
end

--[=[
	Alias for `Trove:Clean()`.
]=]
@native
function TroveModule.Destroy(self: Trove)
	self:Clean()
end

--===========================================================================================================================>

--[=[
	@return Trove
	Creates and adds another trove to itself. This is just shorthand
	for `Trove:Construct(Trove)`. This is useful for contexts where
	the trove object is present, but the class itself isn't.

	:::note
	This does _not_ clone the trove. In other words, the objects in the
	trove are not given to the new constructed trove. This is simply to
	construct a new Trove and add it as an object to track.
	:::

	```lua
	local trove = Trove.new()
	local subTrove = Trove:Extend()

	Trove:Clean() -- Cleans up the subTrove too
	```
]=]
function TroveModule.Extend(self: Trove): Trove
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Extend() while cleaning", 2) end
	-- Return a newly constructed Trove Object:
	return self:Construct(TroveModule)
	--=======================================================================================================>
end


--[=[
	Clones the given instance and adds it to the trove. Shorthand for
	`Trove:Add(instance:Clone())`.
]=]
function TroveModule.Clone<InstanceArg>(self: Trove, InstanceArg: InstanceArg & Instance): InstanceArg
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Clone() while cleaning", 2) end
	-- Return a newly Cloned Instance, added to the Trove:
	return self:Add(InstanceArg:Clone()) :: InstanceArg
	--=======================================================================================================>
end

--[=[
	@param class table | (...any) -> any
	@param ... any
	@return any
	Constructs a new object from either the
	table or function given.

	If a table is given, the table's `new`
	function will be called with the given
	arguments.

	If a function is given, the function will
	be called with the given arguments.

	The result from either of the two options
	will be added to the trove.

	This is shorthand for `Trove:Add(SomeClass.new(...))`
	and `Trove:Add(SomeFunction(...))`.

	```lua
	local Signal = require(somewhere.Signal)

	-- All of these are identical:
	local s = Trove:Construct(Signal)
	local s = Trove:Construct(Signal.new)
	local s = Trove:Construct(function() return Signal.new() end)
	local s = Trove:Add(Signal.new())

	-- Even Roblox instances can be created:
	local part = Trove:Construct(Instance, "Part")
	```
]=]
function TroveModule.Construct<ClassTable>(self: Trove, Class: Class<ClassTable>, ...): ClassTable
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Construct() while cleaning", 2) end
	--=======================================================================================================>
	-- Get the Type of the Class
	local Type: string = typeof(Class)

	--=======================================================================================================>
	-- Check Types and Construct the Object accordingly:
	if Type == "table" then
		-- Return a newly added Object:
		return self:Add( ((Class :: ClassNew1<ClassTable>)['New'] or (Class :: ClassNew2<ClassTable>)['new'])(...) ) :: ClassTable
	elseif Type == "function" then
		-- Return a newly added Object:
		return self:Add((Class :: ClassCall<ClassTable>)(...)) :: ClassTable
	else
		-- Return nothing:
		return self:Add(nil) :: any
	end
	--=======================================================================================================>
end

--[=[
	@param signal RBXScriptSignal
	@param fn (...: any) -> ()
	@return RBXScriptConnection
	Connects the function to the signal, adds the connection
	to the trove, and then returns the connection.

	This is shorthand for `Trove:Add(signal:Connect(fn))`.

	```lua
	Trove:Connect(workspace.ChildAdded, function(instance)
		print(instance.Name .. " added to workspace")
	end)
	```
]=]

function TroveModule.Connect(self: Trove, Signal: (RBXScriptSignal | GoodSignal.Signal), Callback: (...any) -> ()): RBXScriptConnection
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Connect() while cleaning", 2) end
	--=======================================================================================================>
	-- Assert the Type:
	local _Signal: RBXScriptSignal = Signal :: RBXScriptSignal
	-- Return the Signal Connection once added to the Trove:
	return self:Add(_Signal:Connect(Callback)) :: RBXScriptConnection
	--=======================================================================================================>
end

--[=[
	@param signal RBXScriptSignal
	@param fn (...: any) -> ()
	@return RBXScriptConnection
	Connects the function to the signal, adds the connection
	to the trove, and then returns the connection.

	This is shorthand for `Trove:Add(signal:Connect(fn))`.

	```lua
	Trove:Connect(workspace.ChildAdded, function(instance)
		print(instance.Name .. " added to workspace")
	end)
	```
]=]
function TroveModule.ConnectParallel(self: Trove, Signal: (RBXScriptSignal | GoodSignal.Signal), Callback: (...any) -> ()): RBXScriptConnection
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:ConnectParallel() while cleaning", 2) end
	--=======================================================================================================>
	-- Assert the Type:
	local _Signal: RBXScriptSignal = Signal :: RBXScriptSignal
	-- Return the Signal Connection once added to the Trove:
	return self:Add(_Signal:ConnectParallel(Callback)) :: RBXScriptConnection
	--=======================================================================================================>
end

--[=[
	@param name string
	@param priority number
	@param fn (dt: number) -> ()
	Calls `RunService:BindToRenderStep` and registers a function in the
	trove that will call `RunService:UnbindFromRenderStep` on cleanup.

	```lua
	Trove:BindToRenderStep("Test", Enum.RenderPriority.Last.Value, function(dt)
		-- Do something
	end)
	```
]=]
function TroveModule.BindToRenderStep(self: Trove, Name: string, Priority: number, Callback: (DeltaTime: number) -> ())
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:BindToRenderStep() while cleaning", 2) end
	--=======================================================================================================>
	-- Bind the Function to RenderStepped:
	((game:FindService('RunService') or game:GetService('RunService')) :: RunService):BindToRenderStep(Name, Priority, Callback)
	-- Add a function containing the Unbind Method to the Trove:
	self:Add(function() ((game:FindService('RunService') or game:GetService('RunService')) :: RunService):UnbindFromRenderStep(Name) end)
	--=======================================================================================================>
end

--[=[
	@param promise Promise
	@return Promise
	Gives the promise to the trove, which will cancel the promise if the trove is cleaned up or if the promise
	is removed. The exact promise is returned, thus allowing chaining.

	```lua
	Trove:AddPromise(doSomethingThatReturnsAPromise())
		:andThen(function()
			print("Done")
		end)
	-- Will cancel the above promise (assuming it didn't resolve immediately)
	Trove:Clean()

	local p = Trove:AddPromise(doSomethingThatReturnsAPromise())
	-- Will also cancel the promise
	Trove:Remove(p)
	```

	:::caution Promise v4 Only
	This is only compatible with the [roblox-lua-promise](https://eryn.io/roblox-lua-promise/) library, version 4.
	:::
]=]
function TroveModule.AddPromise(self: Trove, Promise: any): any
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:AddPromise() while cleaning", 2) end
	--=======================================================================================================>
	AssertPromiseLike(Promise)
	--=======================================================================================================>
	if Promise:getStatus() == "Started" then

		Promise:finally(function()
			-- If Cleaning then return:
			if self._Cleaning then return end
			FindAndRemoveFromObjects(self, Promise, false)
		end)

		self:Add(Promise, "cancel")

	end
	--=======================================================================================================>
	-- Return the Promise:
	return Promise
	--=======================================================================================================>
end

--[=[
	@param object any -- Object to track
	@param cleanupMethod string? -- Optional cleanup name override
	@return object: any
	Adds an object to the trove. Once the trove is cleaned or
	destroyed, the object will also be cleaned up.

	The following types are accepted (e.g. `typeof(object)`):

	| Type | Cleanup |
	| ---- | ------- |
	| `Instance` | `object:Destroy()` |
	| `RBXScriptConnection` | `object:Disconnect()` |
	| `function` | `object()` |
	| `thread` | `coroutine.close(object)` |
	| `table` | `object:Destroy()` _or_ `object:Disconnect()` |
	| `table` with `cleanupMethod` | `object:<cleanupMethod>()` |

	Returns the object added.

	```lua
	-- Add a part to the trove, then destroy the trove,
	-- which will also destroy the part:
	local part = Instance.new("Part")
	Trove:Add(part)
	Trove:Destroy()

	-- Add a function to the Trove:
	Trove:Add(function()
		print("Cleanup!")
	end)
	Trove:Destroy()

	-- Standard cleanup from table:
	local tbl = {}
	function tbl:Destroy()
		print("Cleanup")
	end
	Trove:Add(tbl)

	-- Custom cleanup from table:
	local tbl = {}
	function tbl:DoSomething()
		print("Do something on cleanup")
	end
	Trove:Add(tbl, "DoSomething")
	```
]=]
@native
function TroveModule.Add<Object>(self: Trove, Object: Object, CleanupMethod: string?): Object
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Add() while cleaning", 2) end
	-- If Object passed was nil, warn and return:
	if Object == nil then Log.Warn('Object sent to the Add Method of Trove, was nil'); return nil :: any; end
	--=======================================================================================================>
	-- Get the Cleanup Method for the passed in Object:
	local Cleanup = GetObjectCleanupFunction(self, Object, CleanupMethod)
	-- Inser the Object, along with the Cleanup Method, into a mini table inside the Trove:
	table.insert(self._Objects, { Object, Cleanup :: any })
	-- Re-return the Object once added to the Trove:
	return Object
	--=======================================================================================================>
end

@native
function TroveModule.TaskSpawn(self: Trove, Function: (...any) -> (...any), ...): thread
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Spawn() while cleaning", 2) end
	--=======================================================================================================>
	-- Initialize the Thread Variable:
	local Thread: thread
	-- Pack the Arguments into a table to be unpacked:
	local Arguments = table.pack(...)
	-- Add the Thread to the Trove and call the Function within it, and remove it from the trove when its finished:
	Thread = self:Add(task.spawn(function() Function(table.unpack(Arguments)); Arguments = nil :: any; self:Remove(Thread, true); Thread = nil :: any end))
	-- Re-return the Object once added to the Trove:
	return Thread
	--=======================================================================================================>
end

@native
function TroveModule.TaskDefer(self: Trove, Function: (...any) -> (...any), ...): thread
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Defer() while cleaning", 2) end
	--=======================================================================================================>
	-- Initialize the Thread Variable:
	local Thread: thread
	-- Pack the Arguments into a table to be unpacked:
	local Arguments = table.pack(...)
	-- Add the Thread to the Trove and call the Function within it, and remove it from the trove when its finished:
	Thread = self:Add(task.defer(function() Function(table.unpack(Arguments)); Arguments = nil :: any; self:Remove(Thread, true); Thread = nil :: any; end))
	-- Re-return the Object once added to the Trove:
	return Thread
	--=======================================================================================================>
end

@native
function TroveModule.TaskDelay(self: Trove, Time: number, Function: (...any) -> (...any), ...): thread
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Delay() while cleaning", 2) end
	--=======================================================================================================>
	-- Initialize the Thread Variable:
	local Thread: thread
	-- Pack the Arguments into a table to be unpacked:
	local Arguments = table.pack(...)
	-- Add the Thread to the Trove and call the Function within it, and remove it from the trove when its finished:
	Thread = self:Add(task.delay(Time, function() Function(table.unpack(Arguments)); Arguments = nil :: any; self:Remove(Thread, true); Thread = nil :: any end))
	-- Re-return the Object once added to the Trove:
	return Thread
	--=======================================================================================================>
end

--[=[
	@param object any -- Object to remove
	Removes the object from the Trove and cleans it up.

	```lua
	local part = Instance.new("Part")
	Trove:Add(part)
	Trove:Remove(part)
	```
]=]
@native
function TroveModule.Remove(self: Trove, Object: any, DontCleanup: boolean?): boolean
	--=======================================================================================================>
	-- Check if Cleaning, Error if cleaning:
	if self._Cleaning then Log.Error("Cannot call Trove:Remove() while cleaning", 2) end
	--=======================================================================================================>
	-- Remove the Object from Trove and return true if found:
	return FindAndRemoveFromObjects(self, Object, if DontCleanup == true then false else true)
	--=======================================================================================================>
end

--===========================================================================================================================>

--[=[
	@param instance Instance
	@return RBXScriptConnection
	Attaches the trove to a Roblox instance. Once this
	instance is removed from the game (parent or ancestor's
	parent set to `nil`), the trove will automatically
	clean up.

	:::caution
	Will throw an error if `instance` is not a descendant
	of the game hierarchy.
	:::
]=]
function TroveModule.AttachToInstance(self: Trove, Instance1: Instance)
	--=======================================================================================================>
	-- Error Checks:
	if self._Cleaning then
		Log.Error("Cannot call Trove:AttachToInstance() while cleaning", 2)
	elseif not Instance1:IsDescendantOf(game) then
		Log.Error("Instance is not a descendant of the game hierarchy", 2)
	end
	-- Return the Connection on the Instance Destroying Method, that will Destroy this Trove:
	return self:Connect(Instance1.Destroying, function() self:Destroy() end)
	--=======================================================================================================>
end

-- Find the Index in the Trove of the passed Object:
function TroveModule.FindObjectIndex(self: Trove, Object: any): number?
	--=======================================================================================================>
	-- Create Local reference to the Objects table:
	local Objects = self._Objects
	-- Loop through the table of Objects, clearing and calling the clean up method on the matching Object:
	for Index: number, Obj: any in ipairs(Objects) do
		if Obj[1] == Object then return Index end
	end
	-- Return false because nothing was found:
	return nil
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Set Module Index Function:
function TroveModule.__index(self: Trove, Index: string)
	--==========================================================================>
	-- If Index is in the immediate Module tree, return that value:
	if TroveModule[Index] then return TroveModule[Index] end
	--==========================================================================>
	-- Error if anything else is Indexed:
	Log.Error(`"{Index}" cannot be indexed on Trove`)
	--==========================================================================>
	-- Return False if all else fails!
	return nil
	--==========================================================================>
end

-- Create the New Index function:
function TroveModule.__newindex(self: Trove, Index: string, Value)
	Log.Error(`"{Index}" cannot be added to Trove`)
end

--===========================================================================================================================>

return table.freeze({New = TroveModule.New})

--===========================================================================================================================>
