--!strict

local TableUtil = {}

local HttpService = game:GetService("HttpService")
local rng = Random.new()

local function Copy<T>(t: T, deep: boolean?): T
	if not deep then
		return (table.clone(t :: any) :: any) :: T
	end
	local function DeepCopy(tbl: { any })
		local tCopy = table.clone(tbl)
		for k, v in tCopy do
			if type(v) == "table" then
				tCopy[k] = DeepCopy(v)
			end
		end
		return tCopy
	end
	return DeepCopy(t :: any) :: T
end

local function Sync<S, T>(srcTbl: S, templateTbl: T): T
	assert(type(srcTbl) == "table", "First argument must be a table")
	assert(type(templateTbl) == "table", "Second argument must be a table")

	local tbl = table.clone(srcTbl)

	for k, v in pairs(tbl) do
		local vTemplate = templateTbl[k]

		if vTemplate == nil then
			tbl[k] = nil

		elseif type(v) ~= type(vTemplate) then
			if type(vTemplate) == "table" then
				tbl[k] = Copy(vTemplate, true)
			else
				tbl[k] = vTemplate
			end

		elseif type(v) == "table" then
			tbl[k] = Sync(v, vTemplate)
		end
	end

	for k, vTemplate in pairs(templateTbl) do
		local v = tbl[k]

		if v == nil then
			if type(vTemplate) == "table" then
				tbl[k] = Copy(vTemplate, true)
			else
				tbl[k] = vTemplate
			end
		end
	end

	return (tbl :: any) :: T
end

local function Reconcile<S, T>(src: S, template: T): S & T
	assert(type(src) == "table", "First argument must be a table")
	assert(type(template) == "table", "Second argument must be a table")

	local tbl = table.clone(src)

	for k, v in template do
		local sv = src[k]
		if sv == nil then
			if type(v) == "table" then
				tbl[k] = Copy(v, true)
			else
				tbl[k] = v
			end
		elseif type(sv) == "table" then
			if type(v) == "table" then
				tbl[k] = Reconcile(sv, v)
			else
				tbl[k] = Copy(sv, true)
			end
		end
	end

	return (tbl :: any) :: S & T
end

local function SwapRemove<T>(t: { T }, i: number)
	local n = #t
	t[i] = t[n]
	t[n] = nil
end

local function SwapRemoveFirstValue<T>(t: { T }, v: T): number?
	local index: number? = table.find(t, v)
	if index then
		SwapRemove(t, index)
	end
	return index
end

local function Map<T, M>(t: { T }, f: (T, number, { T }) -> M): { M }
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be a function")
	local newT = table.create(#t)
	for k, v in t do
		newT[k] = f(v, k, t)
	end
	return newT
end

local function Filter<T>(t: { T }, predicate: (T, any, { T }) -> boolean): { T }
	assert(type(t) == "table", "First argument must be a table")
	assert(type(predicate) == "function", "Second argument must be a function")
	local newT = table.create(#t)
	if #t > 0 then
		local n = 0
		for i, v in t do
			if predicate(v, i, t) then
				n += 1
				newT[n] = v
			end
		end
	else
		for k, v in t do
			if predicate(v, k, t) then
				newT[k] = v
			end
		end
	end
	return newT
end

local function Reduce<T, R>(t: { T }, predicate: (R, T, any, { T }) -> R, init: R): R
	assert(type(t) == "table", "First argument must be a table")
	assert(type(predicate) == "function", "Second argument must be a function")
	local result = init :: R
	if #t > 0 then
		local start = 1
		if init == nil then
			result = (t[1] :: any) :: R
			start = 2
		end
		for i = start, #t do
			result = predicate(result, t[i], i, t)
		end
	else
		local start = nil
		if init == nil then
			result = (next(t) :: any) :: R
			start = result
		end
		for k, v in next, t, start :: any? do
			result = predicate(result, v, k, t)
		end
	end
	return result
end

local function Assign<T>(target: { T }, ...: { any }): { T } & { any }
	local tbl = table.clone(target)
	for _, src in { ... } do
		for k, v in src do
			tbl[k] = v
		end
	end
	return tbl
end

local function Extend<T, E>(target: { T }, extension: { E }): { T } & { E }
	local tbl = table.clone(target) :: { any }
	for _, v in extension do
		table.insert(tbl, v)
	end
	return tbl
end

local function Reverse<T>(tbl: { T }): { T }
	local n = #tbl
	local tblRev = table.create(n)
	for i = 1, n do
		tblRev[i] = tbl[n - i + 1]
	end
	return tblRev
end

local function Shuffle<T>(tbl: { T }, rngOverride: Random?): { T }
	assert(type(tbl) == "table", "First argument must be a table")
	local shuffled = table.clone(tbl)
	local random = if typeof(rngOverride) == "Random" then rngOverride else rng
	for i = #tbl, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

local function Sample<T>(tbl: { T }, size: number, rngOverride: Random?): { T }
	assert(type(tbl) == "table", "First argument must be a table")
	assert(type(size) == "number", "Second argument must be a number")

	local len = #tbl
	if len == 0 then
		return {}
	end

	local shuffled = table.clone(tbl)
	local sample = table.create(size)
	local random = if typeof(rngOverride) == "Random" then rngOverride else rng

	size = math.clamp(size, 1, len)

	for i = 1, size do
		local j = random:NextInteger(i, len)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	table.move(shuffled, 1, size, 1, sample)

	return sample
end

local function Flat<T>(tbl: { T }, depth: number?): { T }
	local maxDepth: number = if type(depth) == "number" then depth else 1
	local flatTbl = table.create(#tbl)
	local function Scan(t: { any }, d: number)
		for _, v in t do
			if type(v) == "table" and d < maxDepth then
				Scan(v, d + 1)
			else
				table.insert(flatTbl, v)
			end
		end
	end
	Scan(tbl, 0)
	return flatTbl
end

local function FlatMap<T, M>(tbl: { T }, callback: (T, number, { T }) -> M): { M }
	return Flat(Map(tbl, callback))
end

local function Keys<K, V>(tbl: { [K]: V }): { K }
	local keys = table.create(#tbl)
	for k in tbl do
		table.insert(keys, k)
	end
	return keys
end

local function Values<K, V>(tbl: { [K]: V }): { V }
	local values = table.create(#tbl)
	for _, v in tbl do
		table.insert(values, v)
	end
	return values
end

local function Find<K, V>(tbl: { [K]: V }, callback: (V, K, { [K]: V }) -> boolean): (V?, K?)
	for k, v in tbl do
		if callback(v, k, tbl) then
			return v, k
		end
	end
	return nil, nil
end

local function Every<K, V>(tbl: { [K]: V }, callback: (V, K, { [K]: V }) -> boolean): boolean
	for k, v in tbl do
		if not callback(v, k, tbl) then
			return false
		end
	end
	return true
end

local function Some<K, V>(tbl: { [K]: V }, callback: (V, K, { [K]: V }) -> boolean): boolean
	for k, v in tbl do
		if callback(v, k, tbl) then
			return true
		end
	end
	return false
end

local function Truncate<T>(tbl: { T }, len: number): { T }
	local n = #tbl
	len = math.clamp(len, 1, n)
	return if len == n then table.clone(tbl) else table.move(tbl, 1, len, 1, table.create(len))
end

local function Zip(...: { [any]: any }): ((t: { any }, k: any) -> (any, any), { any }, any)
	assert(select("#", ...) > 0, "Must supply at least 1 table")
	local function ZipIteratorArray(all: { any }, k: number): (number?, { any }?)
		k += 1
		local values = {}
		for i, t in all do
			local v = t[k]
			if v ~= nil then
				values[i] = v
			else
				return nil, nil
			end
		end
		return k, values
	end
	local function ZipIteratorMap(all: { [any]: any }, k: any): (number?, { any }?)
		local values = {}
		for i, t in all do
			local v = next(t, k)
			if v ~= nil then
				values[i] = v
			else
				return nil, nil
			end
		end
		return k, values
	end
	local all = { ... }
	if #all[1] > 0 then
		return ZipIteratorArray, all, 0
	else
		return ZipIteratorMap, all, nil
	end
end

local function Lock<T>(tbl: T): T
	local function Freeze(t: { [any]: any })
		for k, v in pairs(t) do
			if type(v) == "table" then
				t[k] = Freeze(v)
			end
		end
		return table.freeze(t)
	end
	return Freeze(tbl :: any)
end

local function IsEmpty(tbl: { any }): boolean
	return next(tbl) == nil
end

local function EncodeJSON(value: any): string
	return HttpService:JSONEncode(value)
end

local function DecodeJSON(str: string): any
	return HttpService:JSONDecode(str)
end

TableUtil.Copy = Copy
TableUtil.Sync = Sync
TableUtil.Reconcile = Reconcile
TableUtil.SwapRemove = SwapRemove
TableUtil.SwapRemoveFirstValue = SwapRemoveFirstValue
TableUtil.Map = Map
TableUtil.Filter = Filter
TableUtil.Reduce = Reduce
TableUtil.Assign = Assign
TableUtil.Extend = Extend
TableUtil.Reverse = Reverse
TableUtil.Shuffle = Shuffle
TableUtil.Sample = Sample
TableUtil.Flat = Flat
TableUtil.FlatMap = FlatMap
TableUtil.Keys = Keys
TableUtil.Values = Values
TableUtil.Find = Find
TableUtil.Every = Every
TableUtil.Some = Some
TableUtil.Truncate = Truncate
TableUtil.Zip = Zip
TableUtil.Lock = Lock
TableUtil.IsEmpty = IsEmpty
TableUtil.EncodeJSON = EncodeJSON
TableUtil.DecodeJSON = DecodeJSON

return TableUtil
