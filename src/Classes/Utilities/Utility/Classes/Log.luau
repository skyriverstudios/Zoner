--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Define Module table
local Log: LogModule = {} :: LogModule

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions: {} = require(script:FindFirstAncestor('Utility').TypeDefinitions)

-- Insert the Object Types:
type LogModule = TypeDefinitions.LogModule

--===========================================================================================================================>
--[ OTHER METHODS: ]


-- Method that will print/log all its passed paramaters, but only if running in Studio:
function Log.PrefixMessages(Messages: any): {string}
	--==========================================================================================>

	-- Loop through the packed table of Messages:
	for Index: number, Msg in ipairs(Messages) do
		-- Check if the Message sent isnt already a ConsoleText:
		if Msg == `\n//:` then continue end
		--if Msg == Log._Utility._ConsoleText.Line then continue end
		--if Msg == Log._Utility._ConsoleText.FrameworkTitle then continue end
		--if Msg == Log._Utility._ConsoleText.StudioLine then continue end
		-- if Message is a table, continue:
		if typeof(Msg) == 'table' then continue end
		-- Add the OutputPrefix before the Message, and override the Value at the Index:
		Messages[Index] = `\n//: {Msg}`
	end

	-- Set the N Value to Nil:
	Messages.n = nil :: any

	--==========================================================================================>
	
	-- Return the newly updated Messages Array:
 	return Messages
	
	--==========================================================================================>
end

--===========================================================================================================================>
--[ LOG METHODS: ]


-- Method that will print/log all its passed paramaters, but only if running in Studio:
function Log.SilentDebugPrint(...: any)
	if Log._Utility._Studio == true and Log._Utility._DebugLogging == true then print(`{Log._Utility._ConsoleText.LogPrefix}`, table.unpack(Log.PrefixMessages(table.pack(...))) ) end 
end

-- Method that will error/log all its passed paramaters, but only if running in Studio:
function Log.SilentDebugError(...: any)
	if Log._Utility._Studio == true and Log._Utility._DebugLogging == true then error(`{Log._Utility._ConsoleText.ErrorPrefix}{table.unpack(Log.PrefixMessages(table.pack(...)))}`, 1) end 
end

-- Method that will warn/log all its passed paramaters, but only if running in Studio:
function Log.SilentDebugWarn(...: any)
	if Log._Utility._Studio == true and Log._Utility._DebugLogging == true then warn(`{Log._Utility._ConsoleText.WarnPrefix}`, table.unpack(Log.PrefixMessages(table.pack(...))) ) end
end

-- Method that will print/log all its passed paramaters, but only if running in Studio:
function Log.SilentPrint(...: any)
	if Log._Utility._Studio == true then print(`{Log._Utility._ConsoleText.LogPrefix}`, table.unpack(Log.PrefixMessages(table.pack(...))) ) end 
end

-- Method that will error/log all its passed paramaters, but only if running in Studio:
function Log.SilentError(...: any)
	if Log._Utility._Studio == true then error(`{Log._Utility._ConsoleText.ErrorPrefix}{table.unpack(Log.PrefixMessages(table.pack(...)))}`, 1) end 
end

-- Method that will warn/log all its passed paramaters, but only if running in Studio:
function Log.SilentWarn(...: any)
	if Log._Utility._Studio == true then warn(`{Log._Utility._ConsoleText.WarnPrefix}`, table.unpack(Log.PrefixMessages(table.pack(...))) ) end
end

-- Method that will print/log all its passed paramaters:
function Log.DebugPrint(...: any)
	if Log._Utility._DebugLogging == true then print(`{Log._Utility._ConsoleText.DebugPrefix}`, table.unpack(Log.PrefixMessages(table.pack(...))) ) end
end

-- Method that will error/log all its passed paramaters:
function Log.DebugError(...: any)
	if Log._Utility._DebugLogging == true then error(`{Log._Utility._ConsoleText.DebugWarnPrefix}{table.unpack(Log.PrefixMessages(table.pack(...)))}`, 1) end
end

-- Method that will warn/log all its passed paramaters:
function Log.DebugWarn(...: any)
	if Log._Utility._DebugLogging == true then warn(`{Log._Utility._ConsoleText.DebugWarnPrefix}`, table.unpack(Log.PrefixMessages(table.pack(...)))) end
end

-- Method that will print/log all its passed paramaters:
function Log.Log(...: any)
	-- Unpack the Messages Table into the Output:
	print( `{Log._Utility._ConsoleText.LogPrefix}`, table.unpack(Log.PrefixMessages(table.pack(...))) )
end

-- Method that will print/log all its passed paramaters:
function Log.Print(...: any)
	print(table.unpack(Log.PrefixMessages(table.pack(...))))
end

-- Method that will error/log all its passed paramaters:
function Log.Error(...: any)
	error(`{Log._Utility._ConsoleText.ErrorPrefix}{table.unpack(Log.PrefixMessages(table.pack(...)))}`, 1)
end

-- Method that will warn/log all its passed paramaters:
function Log.Warn(...: any)
	warn(`{Log._Utility._ConsoleText.WarnPrefix}`, table.unpack(Log.PrefixMessages(table.pack(...))) )
end

--===========================================================================================================================>

-- Return the Module table
return Log :: LogModule

--===========================================================================================================================>