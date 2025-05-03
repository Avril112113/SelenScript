local Lanes = require "lanes"
local PoolWorker = require "avlanesutils.pool_worker"
local PoolWorkerGen = require "avlanesutils.pool_worker_gen"

local unpack = table.unpack or unpack


---@alias AvLanesUtils.Pool.WorkId integer

---@class AvLanesUtils.Pool
---@field protected _pool_worker AvLanesUtils.PoolWorker
---@field protected _workers Lanes.Thread[]
local Pool = {}
Pool.__index = Pool


---@param worker_count integer  # >0
---@param worker_init_func fun()?
---@param gen_opts Lanes.GenOpts?  # Always has "*" included
function Pool.new(worker_count, worker_init_func, gen_opts)
	assert(worker_count > 0, "count must be > 0")
	local self = setmetatable({}, Pool)
	self._pool_worker = PoolWorker.new(0, Lanes.linda())
	self._workers = {}

	local gen_worker = PoolWorkerGen("*", gen_opts)
	for i=1,worker_count do
		table.insert(self._workers, gen_worker(i, self._pool_worker.linda, worker_init_func))
	end

	return self
end

function Pool:__tostring()
	return ("AvLanesUtils.Pool: %p"):format(self)
end

function Pool:__gc()
	self:cancel()
end

function Pool:cancel()
	self._pool_worker.linda:cancel("write")
	self:poll()
	self._pool_worker.linda:cancel("both")
	for i, worker in pairs(self._workers) do
		worker:cancel("count", 1)
	end
end

---@param f fun(...):...
---@return AvLanesUtils.Pool.WorkId work_id
function Pool:work(f, ...)
	assert(self._pool_worker ~= nil, "Pool has been canceled...")
	return self._pool_worker:send_work(f, {...})
end

function Pool:poll()
	for i, worker in pairs(self._workers) do
		if worker.status == "error" then
			local _, err = worker:join()
			error(("Worker %s error:\n  %s"):format(i, err), 0)
		end
	end
	while self._pool_worker:process(false, false) == true do
	end
end

---@param work_id AvLanesUtils.Pool.WorkId
---@return boolean
function Pool:check(work_id)
	if not self._pool_worker.pending_results[work_id] then
		self:poll()
	end
	return self._pool_worker.pending_results[work_id] ~= nil
end

--- Once a result has been collected, it's in your hands and can't be collected again.
---@param work_id AvLanesUtils.Pool.WorkId
---@return ...
function Pool:collect(work_id)
	while not self._pool_worker.pending_results[work_id] do
		self:poll()
		Lanes.sleep(false)
	end
	local results = self._pool_worker.pending_results[work_id]
	self._pool_worker.pending_results[work_id] = nil
	if not results[1] then
		error(results[2], 0)
	end
	return unpack(results, 2)
end


return Pool
