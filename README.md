# Poly Framework

> Lightweight, obfuscated Roblox framework used across Monopolygon games.
> You interact with the **public API**; internals are bundled and hidden.

---

## 📦 Folder Layout (Studio)

```
PolyFramework (Actor in ReplicatedStorage)
├─ Src
│  ├─ Class
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

* **Src/**: your code (services/controllers/classes) the framework discovers and runs.
* **Core/**: the framework (obfuscated).

  * **Initializer/**: bootstrap scripts (you still call `Poly.BootLoader.start`).
  * **UtilityPackages/**: drop-in helpers automatically exposed as `Poly.Utils.<ModuleName>`.
  * **Config**: optional overrides (reconciled at load).
  * **Types**: type-only module for IntelliSense / strict Luau.

---

## 🚀 Quick Start

Create tiny boot scripts (no config arg needed).

```lua
-- ServerScriptService/PolyBoot.server.luau
local Root = game.ReplicatedStorage:WaitForChild("PolyFramework")
local Poly = require(Root.Core)
Poly.BootLoader.start("server")

-- StarterPlayerScripts/PolyBoot.client.luau
local Root = game.ReplicatedStorage:WaitForChild("PolyFramework")
local Poly = require(Root.Core)
Poly.BootLoader.start("client")
```

What Boot does:

1. Freezes and exposes `shared.Poly`
2. Auto-mounts `Core/UtilityPackages` → `Poly.Utils.<Name>`
3. Scans `Src/Shared` + side folder (Server/Client)
4. Sorts by `priority` → runs **`:Init(Poly)`** on all, then **`:Start()`**

---

## 📜 Required Module Header

Put this at the top of **every** module you write (services, controllers, classes):

```lua
--!strict
-- POLY HEADER
local Root = script:FindFirstAncestor("PolyFramework")
local Core = Root:WaitForChild("Core")
local Poly = require(Core)
```

---

## 🧠 Services & Controllers

Place modules in `Src/Server`, `Src/Client`, or `Src/Shared`.
Each exports a table with `name`, optional `priority`, and lifecycle:

* **Colon + PascalCase**: `:Init(Poly)`, `:Start()`, (optional) `:Destroy()`
* **Lower `priority` runs first**.

**Server example** (`Src/Server/InventoryService.luau`):

```lua
--!strict
-- POLY HEADER
local Root = script:FindFirstAncestor("PolyFramework")
local Poly = require(Root.Core)

local Service = {
  name = "InventoryService",
  priority = 100,
}

function Service:Init(poly)
  self._store = {}
  self._net = Poly.Net.Server("Inv", { maxEntrance = 200, interval = 2 })
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

**Client example** (`Src/Client/InventoryController.luau`):

```lua
--!strict
-- POLY HEADER
local Root = script:FindFirstAncestor("PolyFramework")
local Poly = require(Root.Core)

local Controller = { name = "InventoryController", priority = 100 }

function Controller:Init()
  self.Inv = Poly.Net.Client("Inv")
  self.Inv:Connect(function(kind, itemId, count)
    if kind == "Ok" then
      print("[Client] Added", itemId, "x", count)
    end
  end)
end

function Controller:Start()
  task.delay(1, function()
    self.Inv:Fire(true, "Add", "Sword")
  end)
end

return Controller
```

---

## 🧩 Classes

Classes are **tables** (no string lookup in this build).
Instances get a pre-made `._maid` and support `:Init(args?)`, `:Start()`, `:Destroy()`.

`Src/Class/HealthBar.luau`:

```lua
--!strict
local HealthBar = { Defaults = { Value = 100 } }

function HealthBar:Init(args)
  if args and args.Value then self.Value = args.Value end
end

function HealthBar:Start() end
function HealthBar:Destroy() end

return HealthBar
```

Use it:

```lua
local HBDef = require(Root.Src.Class.HealthBar)
local hb = Poly.Class.newAndStart(HBDef, { Value = 150 })
Poly.Class.safeDestroy(hb)
```

---

## 🌐 Networking (reliable fire + RPC)

**Server**

```lua
local Trade = Poly.Net.Server("Trade", { maxEntrance = 120, interval = 2 })

Trade:Connect(function(player, itemId)
  -- handle
  return true
end)

Trade:Fire(true, player, "Hello")
Trade:Fires(true, "Broadcast!")
Trade:FireExcept(true, exceptPlayer, "Hi others")
local ok = Trade:Invoke(2.0, player, "NeedAck?")
```

**Client**

```lua
local Trade = Poly.Net.Client("Trade")
Trade:Connect(function(msg) print("server:", msg) end)
Trade:Fire(true, "Hello server")
local res = Trade:Invoke(2.0, "ReqData")
```

Notes:

* First arg `true` = reliable channel.
* `Invoke` yields; returns `nil` on timeout.

---

## 🧰 UtilityPackages → `Poly.Utils.*`

Drop helper modules in **`Core/UtilityPackages/`**.
Each file is auto-required and exposed under `Poly.Utils.<ModuleName>`.

Example:

```lua
-- Core/UtilityPackages/FastMath.luau
local M = {}
function M.add(a,b) return a+b end
return M
```

Usage:

```lua
local sum = Poly.Utils.FastMath.add(10, 20) -- 30
```

> Keep names unique; last-loaded wins on conflicts.

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
m:DoCleaning()
```

---

## 🔧 Config

`Core/Config` (ModuleScript) can override defaults.
Framework reconciles your values with safe fallbacks at load.

Key fields:

* `Logger`: `IgnoreFramework`, `Level` (`"DEBUG"|"INFO"|"WARN"|"ERROR"`), `ShowInGame`
* `Net`: `DefaultRateLimit = { maxEntrance, interval }`
* `Framework`: `Debug` (`true|false|"studio"`)
* `Errors`: `HaltOnInitFailure`, `HaltOnStartFailure`

> You **don’t** pass config to Boot; it’s loaded internally.

---

## ✅ Conventions & Tips

* Use **colon + PascalCase** lifecycle: `:Init`, `:Start`, `:Destroy`
* Keep heavy work in `:Start()`; wiring/setup in `:Init()`
* Use `priority` to control init order (lower runs first)
* Always include the **POLY HEADER** snippet
* Rely on `Poly.Utils` for helper utilities (and your UtilityPackages)

---

## ❓ Troubleshooting

* **No logs in Play** → check `Logger.Level` and `ShowInGame` in `Core/Config`
* **Net not firing** → ensure identifiers match and correct side is used
* **Timeouts** → raise `Invoke` timeout or inspect callbacks
* This is an **obfuscated** build; internals are hidden by design

---

## 🔖 Types

For strict Luau / IntelliSense, see `Core/Types` (no requires, safe for any build).

---

## 📄 License

Proprietary © Monopolygon. All rights reserved.
