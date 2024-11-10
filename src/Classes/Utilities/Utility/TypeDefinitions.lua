--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Create and Export Generic Types:
export type Dictionary  = {[string]: any}
export type Array       = {any}
export type Table       = {[any]: any}

-- Create and Export the Debounces Dictionary:
export type Debounces   = {[string]: Debounce}
-- Create and Export the Debounce table:
export type Debounce    = {Bool: boolean, Time: number}

-- Export the Spring Object which is used in a lot of Objects:
export type SpringsArray = {{Name: string; Damper: number; Speed: number; Start: number}}

-- Export the Cycler:
export type Cycler = {
	--==================================================>
	_Num: number,
	_Max: number,
	_Array: {any},
	--==================================================>
	Value: any,
	--==================================================>
	Cycle: 
		(self: Cycler) -> string,
	Forward:
		(self: Cycler) -> string,
	Backward:
		(self: Cycler) -> string,
	Destroy:
		(self: Cycler) -> (),
	--==================================================>
	Backwards: 
		(self: Cycler) -> string,
	Forwards:
		(self: Cycler) -> string,
	--==================================================>
}

--=======================================================================================================>

-- Create Module Type:
export type GetModule = {
	--==================================================>

	ArrayLooperData: 
		(DataTable: Table, LoopNum: number) -> (Array, number, number),
	RandomChildFromInstance: 
		(SentInstance: Instance ) -> any,
	InputString: 
		(InputObject: InputObject) -> string,
	Material: 
		(MaterialEnum: Enum.Material) -> string,
	HumanoidState: 
		(HumanoidStateEnum: Enum.HumanoidStateType) -> string,

	DataFromString: 
		(DataString: string) -> {string},
	ConvertedBoolean: 
		(Value: boolean | string | number) -> string | boolean,

	LightingStatus: 
		(Time: number) -> ('None' | 'Night' | 'Day'),

	MetaIndexFunction: 
		<Module>(
			Module: Dictionary, ModuleScript: ModuleScript, FrameworkData: {any}
		) -> <self, Index>(self: Module, Index: string) -> self,
	MetaModuleArray: 
		(ModuleScript: ModuleScript, FrameworkData: {any}) -> Array,
	LocalModulesArray: 
		(ChildrenFolder: (Folder | ModuleScript)) -> (Array, number),


	Identifier: 
		(Brackets: boolean, Dashes: boolean?, Shortened: boolean?, Characters: number?) -> string,

	Region3FromRegion3: 
		(Size: Vector3, CFrame1: CFrame) -> Region3,

	_Utility: Utility;

	--==================================================>
}

-- Create Module Type:
export type LogModule = {
	--==================================================>


	PrefixMessages: 
		(Messages: any) -> {any},

	SilentPrint: 
		(...any) -> (),
	SilentError: 
		(...any) -> (),
	SilentWarn: 
		(...any) -> (),

	SilentDebugPrint: 
		(...any) -> (),
	SilentDebugError: 
		(...any) -> (),
	SilentDebugWarn: 
		(...any) -> (),

	Log: 
		(...any) -> (),

	Print: 
		(...any) -> (),
	Error: 
		(...any) -> (),
	Warn: 
		(...any) -> (),

	DebugPrint: 
		(...any) -> (),
	DebugError: 
		(...any) -> (),
	DebugWarn: 
		(...any) -> (),
	--==================================================>
	_Utility: Utility;
	--==================================================>
}

-- Create Module Type:
export type MathModule = {
	--==================================================>

	Lerp: 
		(Start: number, Goal: number, Alpha: number) -> number,
	StepTowards: 
		(Value: number, Goal: number, Rate: number) -> number,
	Round: 
		(Number: (string | number), NumDecimalPlaces: number?) -> number,
	RoundFactor: 
		(Number: number, Factor: number?) -> number,
	RoundNearestInterval: 
		(Number: number, Factor: number) -> number,

	RoundVector: 
		(Vector: Vector3) -> Vector3,

	--==================================================>
}

-- Create Module Type:
export type TableModule = {
	--==================================================>

	Freeze: 
		(Table: Table) -> Table,
	DeepCopy: 
		(Table: Table) -> Table,
	CreateDictionary: 
		<SentInstance>(SentInstance: any, Recursive: boolean? ) -> (Dictionary | SentInstance),

	Move: 
		(Original: Table, MovingIntoOriginal: Table) -> (),

	Keys: 
		(Table: Dictionary) -> Array,
	Values: 
		(Table: Dictionary) -> Array,

	MergeDictionary: 
		(Dictionary1: Dictionary, Dictionary2: Dictionary) -> Dictionary,
	MergeArrays: 
		(Array1: Array, Array2: Array) -> Array,

	ShallowCopy: 
		(Table: Table) -> Table,

	TupleToTable: 
		(...any) -> Array,


	Type: 
		(Table: Table) -> ('Array' | 'Dictionary' | 'Empty'),
	Length: 
		(Table: Table) -> number,

	RandomIndexFromLength: 
		(Length: number) -> number,
	RandomIndex: 
		(Table: Table) -> number,

	ArrayToDictionary: 
		(Array: Array) -> Dictionary,

	Pack: 
		(...any) -> Table,

	IsArray: 
		(Table: Table) -> boolean,
	IsDictionary: 
		(Table: Table) -> boolean,

	ToString: 
		(Table: Table) -> string,
	From: 
		(Value: any) -> {any},

	Some: 
		(Table: Table, Callback: (Value: any) -> boolean) -> boolean,

	Filter: 
		(Array: Array, Callback: (Value: any, Index: number) -> boolean) -> Array,

	IsFlat: 
		(Table: Table) -> boolean,

	Every: 
		(Table: Table, Callback: (any) -> boolean) -> (boolean, any?),

	HasKey: 
		(Dictionary: Dictionary, Key: any) -> boolean,
	HasValue: 
		(Table: Table, Value: any) -> boolean,

	IsEmpty: 
		(Table: Table) -> boolean,

	Reconcile: 
		(Original: Dictionary, Reconcile: Dictionary) -> Dictionary,

	--==================================================>

	_Utility: Utility;

	--==================================================>
}

--=======================================================================================================>
-- Create the Object Types:


-- Create and Export Object Type:
export type Utility = typeof(
	setmetatable({} :: UtilityMetaData, {} :: UtilityModule)
)

-- Create and Export MetaData Type:
export type UtilityMetaData = {
	--==================================================>

	Table: TableModule;
	Math:  MathModule;
	Log:   LogModule;
	Get:   GetModule;

	_MaxRetries: number;
	_RandomPrefix: typeof(Random.new(123));
	_RunScope: ('Server' | 'Client');
	_Studio: boolean;
	_DebugLogging: boolean;
	_ConsoleText: {[string]: string};

	_FaceNormalTolerance: number;
	_FaceNormalIds: {Enum.NormalId};

	--==================================================>
}

-- Create Module Type:
export type UtilityModule = {
	--==================================================>

	Start: 
		(self: UtilityModule, FrameworkData: {any}) -> (),

	--==================================================>

	New: 
		() -> Utility,
	Destroy: 
		(self: Utility) -> (),

	--==================================================>

	DebounceAsync: 
		(self: Utility, Name: string, Debounces: Debounces, Status: boolean) -> boolean,

	Debounce: 
		(self: Utility, Name: string, Debounces: Debounces, Trove: any, Status: boolean?) -> boolean,

	TraverseFilePath: 
		(self: Utility, Table: Dictionary, FilePath: string, NilCallback: (Key: string)->()? ) -> Table,

	RaycastDebug: 
		(self: Utility, Origin: Vector3, EndPosition: Vector3, ColorType: ('Red'|'Green'|'Blue')?, ActiveTime: number?) -> (),
	BlockcastDebug: 
		(self: Utility, Size: Vector3, OriginCFrame: CFrame, EndCFrame: CFrame, ColorType: ('Red'|'Green'|'Blue')?, ActiveTime: number?) -> (),

	PositionDebug: 
		(self: Utility, Position: Vector3, Name: string?, ActiveTime: number?) -> (),
	CFrameDebug: 
		(self: Utility, CFrame: CFrame, Name: string?, ActiveTime: number?) -> (),

	ChangeAttribute: 
		(self: Utility, AttributeInstance: Instance, AttributeName: string, AttributeValue: any) -> (),

	SafeClone: 
		(self: Utility, SentInstance: any) -> any,

	StringSpaces: 
		(self: Utility, String: string, Replace: string?) -> string,

	RecalculateHipHeight: 
		(self: Utility, Character: any, Humanoid: Humanoid) -> (),

	AlignPositionYield: 
		(self: Utility, AlignPosition: AlignPosition) -> (),

	CoreCall: 
		(self: Utility, Method: string, ...any) -> ...any,

	RateLimiter: 
		(self: Utility, RateData: {Counter: number; CounterMax: number}, DeltaTime: number?) -> boolean,
	Counter: 
		(self: Utility, CounterData: {Counter: number; CounterMax: number}, Type: 'Max') -> boolean,
	DeltaCounter: 
		(self: Utility, CounterData: {Counter: number; CounterMax: number}, DeltaTime: number, Type: 'Max'?) -> boolean,

	Debris: 
		(self: Utility, Object: any, WaitTime: number) -> thread,

	HasPass: 
		(self: Utility, PlayerID: number, GamepassID: number) -> boolean,



	NormalToFace: 
		(self: Utility, NormalVector: Vector3, Part: BasePart) ->  Enum.NormalId?,
	GetNormalFromFace: 
		(self: Utility, Part: BasePart, NormalId: Enum.NormalId) -> Vector3,

	--==================================================>

	CreateCycler: 
		(self: Utility, Table: Table ) -> Cycler,

	--==================================================>

	FindFirstChildTool: 
		(self: Utility, SentInstance: Instance ) -> Tool,
	FindFirstAncestorTool: 
		(self: Utility, SentInstance: Instance ) -> Tool,

	--==================================================>

	IsATool: 
		(self: Utility, InstanceToCheck: Instance ) -> boolean,
	IsDescendant: 
		(self: Utility, InstanceToCheck: Instance, ParentInstance: Instance ) -> boolean,
	IsDescendantOfATool: 
		(self: Utility, InstanceToCheck: Instance ) -> boolean,
	IsTweenPlaying: 
		(self: Utility, Tween: Tween ) -> boolean,

	InGroup: 
		(self: Utility, Player: Player, GroupID: number, RankID: number?, Compare: string?) -> boolean,
	InGroupRole: 
		(self: Utility, Player: Player, GroupID: number, RoleName: string) -> boolean,

	--==================================================>

	GetProductInfo: 
		(self: Utility, ProductID: number) -> any,
	GetHumanoidDescription: 
		(self: Utility, UserID: number) -> HumanoidDescription,

	--==================================================>

	SetLocalModulesArray: 
		(self: Utility, Array: Array, ArrayLength: number, FrameworkData: {any}) -> Array,

	--==================================================>

	__index: UtilityModule

	--==================================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>