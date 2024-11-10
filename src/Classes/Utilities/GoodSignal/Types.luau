--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Signal types
export type ConnectionModule = {
	Disconnect:
		(self: Connection) -> (),
	Destroy: 
		(self: Connection) -> (),

	__index: ConnectionModule;
	__newindex: any
}

export type ConnectionMetaData = {
	Connected: boolean,

	_signal: Signal,
	_fn: (...any) -> (...any),
	_next: any,
}

export type Connection = typeof(
	setmetatable({} :: ConnectionMetaData, {} :: ConnectionModule)
)

--=======================================================================================================>

export type SignalModule = {
	Fire: 
		(self: Signal, ...any) -> (),
	FireDeferred: 
		(self: Signal, ...any) -> (),
	Connect: 
		(self: Signal, fn: (...any) -> ()) -> Connection,
	ConnectParallel: 
		(self: Signal, fn: (...any) -> ()) -> Connection,
	Once: 
		(self: Signal, fn: (...any) -> ()) -> Connection,
	DisconnectAll: 
		(self: Signal) -> (),
	GetConnections: 
		(self: Signal) -> { Connection },
	Destroy: 
		(self: Signal) -> (),
	Wait: 
		(self: Signal) -> ...any,

	Wrap: 
		(rbxScriptSignal: RBXScriptSignal) -> Signal,
	Is: 
		(obj: any) -> boolean,
	New: 
		() -> Signal;

	__index: SignalModule
}

export type SignalMetaData = {
	_handlerListHead: any;
	_proxyHandler: any;
	_yieldedThreads: any;
}

export type Signal = typeof(
	setmetatable({} :: SignalMetaData, {} :: SignalModule)
)

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>