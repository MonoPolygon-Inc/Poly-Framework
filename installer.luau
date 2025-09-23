local https = game:GetService("HttpService")
local repstorage = game:GetService("ReplicatedStorage")

local cache = Instance.new("ModuleScript")
cache.Source = https:GetAsync("https://raw.githubusercontent.com/MonoPolygon-Inc/Poly-Framework/refs/heads/main/.framework/core.luau")
task.delay(.05, cache.Destroy, cache)
cache = require(cache)

local origin = repstorage:FindFirstChild("PolyFramework") and repstorage.PolyFramework:FindFirstChild("Core") and require(repstorage.PolyFramework.Core)

if origin then
    warn(cache.Version)
    warn(origin.Version)
else
    warn("Install")
end
