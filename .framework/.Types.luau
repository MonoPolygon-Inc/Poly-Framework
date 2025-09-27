--!strict
-- Poly Framework Definition

-- ─────────────────────────────────────────────────────────────────────────────
-- Poly root (what `require(Core)` returns)
export type Poly = {
	-- Kernel
	Logger:      LoggerModule,
	Maid:        Maid,
	RateLimiter: { create: (limit: number, interval: number) -> (delta: number?) -> boolean },
	Lifecycle:   Lifecycle,

	Utils: Utils,

	Components: {
		register: (tag: string, module: any) -> any,
		get: (tag: string) -> any,
		all: () -> { [string]: any },
	},

	-- Class system
	Class: ClassApi,

	-- Networking
	Net: {
		Server: (identifier: string, opts: rateLimitArg?) -> NetServer?,
		Client: (identifier: string) -> NetClient?,
		Signal: (identifier: string) -> any,
		fromServerArray: (arr: { any }) -> NetFromServer,
		fromClientArray: (arr: { any }) -> NetFromClient,
		fromSignalArray: (arr: { any }) -> NetFromSignal,
	},

	-- Boot
	BootLoader: { start: (side: "server" | "client") -> () },

	-- Misc
	RunType: "Server" | "Client",
	Version: string,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Logger
export type Logger = {
	debug: (self: Logger, ...any) -> (),
	info:  (self: Logger, ...any) -> (),
	warn:  (self: Logger, ...any) -> (),
	error: (self: Logger, ...any) -> (),
}
export type LoggerModule = {
	new: (tag: string) -> Logger,
	setLevel: (level: "DEBUG" | "INFO" | "WARN" | "ERROR") -> (),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Maid
type AnyTask = RBXScriptConnection | Instance | (() -> ()) | { Destroy: (self: any) -> () }
export type Maid = {
	_tasks: { AnyTask },
	_boundInst: Instance?,
	_boundConn: RBXScriptConnection?,
	isDead: boolean,

	new: () -> Maid,

	Give: (self: Maid, task: AnyTask) -> (),
	GiveTask: (self: Maid, task: AnyTask) -> AnyTask,
	Remove: (self: Maid, task: AnyTask) -> boolean,

	AttachToInstance: (self: Maid, inst: Instance?) -> (),
	LinkToInstance: (self: Maid, inst: Instance?) -> (),

	Extend: (self: Maid) -> Maid,

	DoCleaning: (self: Maid) -> (),
	Destroy: (self: Maid) -> (),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Lifecycle
export type Lifecycle = {
	new: () -> Lifecycle,
	register: (self: Lifecycle, service: any) -> (),
	initAll: (self: Lifecycle) -> (),
	startAll: (self: Lifecycle) -> (),
	stopAll: (self: Lifecycle) -> (),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Class system
export type ClassDef = {
	Defaults: { [string]: any }?,

	Init: (self: any, instOrArgs: any?, extra: any?) -> ()?,
	Start: (self: any) -> ()?,
	Destroy: (self: any) -> ()?,
}
export type ClassObject = {
	Maid: Maid,
	Instance: Instance?,
	[string]: any,
}
export type ClassApi = {
	adapt: (def: ClassDef) -> ClassDef,
	new: (def: ClassDef, instOrArgs: any?, extra: any?) -> ClassObject,
	newAndStart: (def: ClassDef, instOrArgs: any?, extra: any?) -> ClassObject,
	safeDestroy: (obj: ClassObject) -> (),
	Assign: (spec: string | ClassDef, instOrArg: any?, additionalData: any?) -> ClassObject,
	Get: (instance: Instance) -> { [string]: ClassObject },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Service/Controller
export type ServiceModule = {
	name: string?,
	priority: number?,
	bypassyield: boolean?,
	Init:    (self: any, poly: Poly) -> ()?,
	Start:   (self: any) -> ()?,
	Destroy: (self: any) -> ()?,
}
export type ControllerModule = ServiceModule
export type ComponentModule = {
	name: string?,
	bypassyield: boolean?,
	Init : (self: any, poly: Poly) -> ()?,
}
export type ClassModule = {
	name: string?,
	bypassyield: boolean?,
	Defaults : {any}?,
	Init:    (self: any, poly: Poly) -> ()?,
	Start:   (self: any) -> ()?,
	Destroy: (self: any) -> ()?,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Net
export type rateLimitArg = { maxEntrance: number?, interval: number? }

export type NetClient = {
	Fire:           (self: NetClient, reliable: boolean, ...any) -> (),
	Invoke:         (self: NetClient, timeout: number, ...any) -> any,
	Connect:        (self: NetClient, callback: (...any) -> ()) -> string,
	Once:           (self: NetClient, callback: (...any) -> ()) -> string,
	Disconnect:     (self: NetClient, key: string) -> (),
	DisconnectAll:  (self: NetClient) -> (),
	Destroy:        (self: NetClient) -> (),
	Wait:           (self: NetClient) -> number,
}

export type NetServer = {
	Fire:        (self: NetServer, reliable: boolean, target: Player | { Player }, ...any) -> (),
	Fires:       (self: NetServer, reliable: boolean, ...any) -> (),
	FireExcept:  (self: NetServer, reliable: boolean, except: Player, ...any) -> (),
	Invoke:      (self: NetServer, timeout: number, player: Player, ...any) -> any,
	Connect:     (self: NetServer, callback: (player: Player, ...any) -> ()) -> string,
	Once:        (self: NetServer, callback: (player: Player, ...any) -> ()) -> string,
	Disconnect:  (self: NetServer, key: string) -> (),
	DisconnectAll:(self: NetServer) -> (),
	Destroy:     (self: NetServer) -> (),
	Wait:        (self: NetServer) -> number,
}

export type NetFromServer = { [string]: NetServer }
export type NetFromClient = { [string]: NetClient }
export type NetFromSignal = { [string]: any }

-- ─────────────────────────────────────────────────────────────────────────────
-- Utils
export type AssertFn = (condition: any, msg: string?) -> ()
export type SpawnFn  = (fn: (...any) -> (), ...any) -> ()
export type KeyFn    = () -> number
export type SerdesFn = (identifier: string) -> string

export type Utils = {
	Assert: AssertFn,
	Spawn:  SpawnFn,
	Key:    KeyFn,
	Serdes: SerdesFn,
	Binder: any,
	[string]: any,
}

return nil
