# Poly Framework

> Lightweight, obfuscated Roblox framework used across Monopolygon games.
> You interact with the **public API**; internals are bundled and hidden.

> Current Version **0.0.1 - Stable**

---

## 📦 Folder Layout (Studio)

```
PolyFramework (Actor in ReplicatedStorage)
├─ Src
│  ├─ Class
│  ├─ Component
│  ├─ Client
│  ├─ Server
│  └─ Shared
└─ Core
   ├─ Initializer
   │  ├─ client
   │  └─ server
   ├─ UtilityPackages
   ├─ Config
   └─ Types
```

* **Src/**: your code the framework discovers and runs.

  * **Class/**: assignable classes you attach to Instances.
  * **Component/**: singleton modules auto-inited once (optional `:Init(Poly)`).
  * **Client/Server/Shared/**: services/controllers with `:Init()`/`:Start()`.
* **Core/**: framework runtime.

  * **UtilityPackages/** → exposed as `Poly.Utils.<ModuleName>`.
  * **Config** → your overrides (merged at load).

---

## 🧠 Services & Controllers

Place modules in `Src/Server`, `Src/Client`, or `Src/Shared`.
Each exports a table with optional `priority` and lifecycle:

* `:Init(Poly)` — setup/wiring
* `:Start()` — begin work
* `:Destroy()` — optional cleanup
* Lower `priority` runs first (default `100`)

> 💡 **Note:** Add `bypassyield = true` to any Service, Component, or Class table if you don't want it to yield during initialization/start.

**Server example** (`Src/Server/InventoryService.luau`):

```lua
--!strict
local Root  = script:FindFirstAncestor("PolyFramework")
local Types = require(Root.Core.Types)
local Poly : Types.Poly = require(Root.Core)
local Service : Types.ServiceModule = { priority = 100 }

function Service:Init(Poly)
	self._store = {}
	self._net = Poly.Net.Server("Inv")
end

function Service:Start()
	self._net:Connect(function(player, action, itemId)
		if action == "Add" then
			local bag = self._store[player.UserId] or {}
			bag[itemId] = (bag[itemId] or 0) + 1
			self._store[player.UserId] = bag
			self._net:Fire(true, player, "Ok", itemId, bag[itemId])
		end
	end)
end

return Service
```

---

## 🧩 Components (singletons)

Modules in `Src/Component` are required once and, if they have `:Init(Poly)`, it’s called. No `:Start()` here.

**Example** (`Src/Component/Analytics.luau`):

```lua
--!strict
local Root  = script:FindFirstAncestor("PolyFramework")
local Types = require(Root.Core.Types)
local Poly : Types.Poly = require(Root.Core)
local Analytics : Types.ComponentModule = {}

function Analytics:Init(Poly)
	local Log = Poly.Logger.new("Analytics")
	Log:info("Analytics ready on %s", Poly.RunType)
	self.StartTime = os.clock()
end

return Analytics
```

Access later via `local A = Poly.Components.get("Analytics")`.

---

## 🧱 Classes (assign to Instances)

Classes are tables with optional `Defaults`, and lifecycle: `:Init(inst?, extra?)`, `:Start()`, `:Destroy()`.
They are **auto-registered by file name** in `Src/Class`.

**Example** (`Src/Class/HealthBar.luau`):

```lua
--!strict
local Root  = script:FindFirstAncestor("PolyFramework")
local Types = require(Root.Core.Types)
local Poly : Types.Poly = require(Root.Core)
local HealthBar : Types.ClassModule = {
	Defaults = {
		Max = 100,
		Current = 100,
		Test = { a = 1 },
	},
}

function HealthBar:Init(inst, extra)
	self.Test.a += 1
	if typeof(inst) == "Instance" then
		self.Maid:AttachToInstance(inst)
		self.Maid:GiveTask(inst.AncestryChanged:Connect(function() end))
	end
	if type(extra) == "table" and extra.StartCurrent then
		self.Current = math.clamp(extra.StartCurrent, 0, self.Max)
	end
end

function HealthBar:Start() end
function HealthBar:Destroy() print("Gone woah") end

return HealthBar
```

**Assign / Get / Destroy**

```lua
local hb = Poly.Class.Assign("HealthBar", workspace.Part, { StartCurrent = 50 })

local attached = Poly.Class.Get(workspace.Part)
-- attached looks like: { HealthBar = <hbObj>, ... }

Poly.Class.safeDestroy(hb)
```

You can also assign from an ad-hoc table:

```lua
Poly.Class.Assign({
	Defaults = { Enabled = true },
	Init = function(self, inst, extra) end,
	Start = function(self) end,
	Destroy = function(self) end,
}, workspace.Part)
```

---

## 🌐 Networking

**Server**

```lua
local Trade = Poly.Net.Server("Trade", { maxEntrance = 200, interval = 2 })
Trade:Connect(function(player, msg) return "ack:"..msg end)
Trade:Fire(true, player, "Hello")
local res = Trade:Invoke(2.0, player, "Ping")
```

**Client**

```lua
local Trade = Poly.Net.Client("Trade")
Trade:Connect(function(msg) print("server:", msg) end)
Trade:Fire(true, "Hi")
local ack = Trade:Invoke(2.0, "Ping?")
```

* First arg `true` = reliable
* `Invoke` yields; returns `nil` on timeout

---

## 🧰 UtilityPackages → `Poly.Utils.*`

Drop modules into `Core/UtilityPackages/Name.luau`:

```lua
local M = {}
function M.add(a,b) return a+b end
return M
```

Use:

```lua
local sum = Poly.Utils.Name.add(2,3)
```

---

## 📝 Logger & Maid

```lua
local log = Poly.Logger.new("Inventory")
log:info("ready")
log:warn("slow op")
log:error("oops %s", "bad")

local m = Poly.Maid.new()
m:Give(workspace.Heartbeat:Connect(function() end))
m:Give(function() print("cleanup") end)
m::Destroy()
```

---

## 🔧 Config

Create `Core/Config` (ModuleScript) returning partial overrides.
They’re **reconciled**: your values win; missing fields fall back to defaults.

```lua
return {
   Logger = {
		IgnoreFramework = true :: boolean;
		Level = "DEBUG" :: ("DEBUG"|"INFO"|"WARN"|"ERROR");
		ShowInGame = false;
	},

	Net = {
		DefaultRateLimit = { maxEntrance = 200, interval = 2 };
	};

	Framework = {
		Debug = "STUDIO" :: (boolean | "STUDIO");
	};

	Errors = {
		HaltOnInitFailure = false :: boolean;
		HaltOnStartFailure = false :: boolean;
	};
}
```

---

## ✅ Conventions

* Use `:Init()` for wiring, `:Start()` for running, `:Destroy()` for cleanup
* Lower `priority` runs first
* Prefer `Poly.Class.Assign(name, instance, extra)` for per-instance behavior
* Use `Poly.Class.Get(instance)` to inspect all attached classes

---

## ❓ Troubleshooting

* No logs in Play: check `Logger.Level` and `ShowInGame` in `Core/Config`
* Net not firing: ensure identifiers match and correct side
* RPC timeouts: raise `Invoke` timeout or verify the callback runs

---

## 📄 License

Proprietary © Monopolygon. All rights reserved.
