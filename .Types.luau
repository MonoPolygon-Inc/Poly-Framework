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

	-- Utilities (built-ins + anything under Core/UtilityPackages auto-mounted here)
	Utils: Utils,

	-- Component registry (for auto-registered classes/tags)
	Components: {
		register: (tag: string, classModule: any) -> any,
		get: (tag: string) -> any,
		all: () -> { [string]: any },
	},

	-- Class system (table-only defs; no string lookup in this build)
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
export type Maid = {
	Give: (self: Maid, task: any) -> (),
	DoCleaning: (self: Maid) -> (),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Lifecycle (helpers; separate from BootLoader’s Init/Start)
export type Lifecycle = {
	new: () -> Lifecycle,
	register: (self: Lifecycle, service: any) -> (),
	initAll: (self: Lifecycle) -> (),
	startAll: (self: Lifecycle) -> (),
	stopAll: (self: Lifecycle) -> (),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Class system (table defs only in this build)
export type ClassDef = {
	Defaults: { [string]: any }?,

	-- colon + PascalCase lifecycle (all optional)
	Init: (self: any, instOrArgs: any?) -> ()?,
	Start: (self: any) -> ()?,
	Destroy: (self: any) -> ()?,
}
export type ClassApi = {
	adapt: (def: ClassDef) -> ClassDef,
	new: (def: ClassDef, instOrArgs: any?) -> any,
	newAndStart: (def: ClassDef, instOrArgs: any?) -> any,
	safeDestroy: (obj: any) -> (),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Service/Controller shapes (for Src/* modules Boot loads)
export type ServiceModule = {
	name: string,
	priority: number?,

	-- colon + PascalCase lifecycle (Boot calls these)
	Init:    (self: any, poly: Poly) -> ()?,
	Start:   (self: any) -> ()?,
	Destroy: (self: any) -> ()?,
}
export type ControllerModule = ServiceModule

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

export type NetEvent = {
	Reliable: RemoteEvent,
	Unreliable: RemoteEvent, -- present; may internally be a RemoteEvent fallback
	Request: RemoteEvent,
}
export type NetFromServer = { [string]: NetServer }
export type NetFromClient = { [string]: NetClient }
export type NetFromSignal = { [string]: any }

-- ─────────────────────────────────────────────────────────────────────────────
-- Utils (built-ins + dynamic UtilityPackages)
export type AssertFn = (condition: any, msg: string?) -> ()
export type SpawnFn  = (fn: (...any) -> (), ...any) -> ()
export type KeyFn    = () -> number
export type SerdesFn = (identifier: string) -> string

export type Utils = {
	Assert: AssertFn,
	Spawn:  SpawnFn,
	Key:    KeyFn,
	Serdes: SerdesFn,
	Binder: any,          -- class-based binder helper
	[string]: any,        -- extra modules added from Core/UtilityPackages (e.g. Utils.FastMath)
}

return nil
