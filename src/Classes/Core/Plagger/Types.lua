--=======================================================================================================>
--!strict
--=======================================================================================================>
-- Create the Object Types:


type PlayerObject = {
	Events: {
		CharacterAdded:   RBXScriptConnection;
		CharacterRemoved: RBXScriptConnection
	}; 
	Destroy:
		(self: PlayerObject)->()
};

type CharacterList = {[string]: Model}
type PlayerList    = {[string]: Player}

--=======================================================================================================>

-- Create and Export Object Type:
export type Plagger = typeof(
	setmetatable({} :: PlaggerMetaData, {} :: PlaggerModule)
)

-- Create and Export MetaData Type:
export type PlaggerMetaData = {
	--===========================================>
	_TaggedOnly: boolean?;
	_LocalOnly:  boolean?;
	_InActor:    boolean?;
	--===========================================>
	_LocalPlayerName: string?;
	--===========================================>
    _Events: {[string]: RBXScriptConnection};
    --===========================================>
	_CharacterList: CharacterList;
	_PlayerList:    PlayerList;
	--===========================================>
	-- Meta Index Variables:
	-- Some External references to internal variable:
	Characters: CharacterList;
	Players:    PlayerList;
	--===========================================>
}

-- Create and Export Module Type:
export type PlaggerModule = {
	--===========================================>

	New: 
		(TaggedOnly: boolean?, LocalOnly: boolean?, InActor: boolean?) -> Plagger,
	new: 
		(TaggedOnly: boolean?, LocalOnly: boolean?, InActor: boolean?) -> Plagger,
		
	Destroy: 
		(self: Plagger) -> (),

	_Initialize: 
		(self: Plagger) -> (),
	_SetObjects: 
		(self: Plagger) -> (),
	_SetEvents: 
		(self: Plagger) -> (),

	_AddPlayer: 
		(self: Plagger, Player: Player) -> (),
	_RemovePlayer: 
		(self: Plagger, Player: Player) -> (),

	_AddCharacter: 
		(self: Plagger, Player: Player, Character: Model?) -> (),
	_RemoveCharacter: 
		(self: Plagger, Player: Player, Character: Model) -> (),

	--===========================================>
	
	GetCharacterAddedSignal: 
		(self: Plagger) -> (RBXScriptSignal),
	GetCharacterRemovedSignal: 
		(self: Plagger) -> (RBXScriptSignal),

	GetPlayerAddedSignal: 
		(self: Plagger) -> (RBXScriptSignal),
	GetPlayerRemovedSignal: 
		(self: Plagger) -> (RBXScriptSignal),

	GetPlayers: 
		(self: Plagger) -> {[string]: Player},
	GetCharacters: 
		(self: Plagger) -> {[string]: Model},

	--===========================================>
	_RunScope: ('Server' | 'Client'),
	_CoreRunning: {
		Server: boolean;
		Client: boolean;
	};
	--===========================================>
	_Players: {[Player]: PlayerObject};
	--===========================================>
	_Tags: {
		Player          : 'PH:Player';
		ClientCharacter : 'PH:Client:Character';
		ServerCharacter : 'PH:Server:Character';
		LocalCharacter  : 'PH:Client:LocalCharacter';
	};
	--===========================================>

	__index: PlaggerModule,

	--===========================================>

}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>