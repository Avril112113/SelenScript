local Lanes = require "lanes"
local PoolWorkerContext = require "avlanesutils.pool_worker_context"

local unpack = table.unpack or unpack


---@class AvLanesUtils.PoolWorker.WorkState
---@field co thread  # thread == corotuine
---@field worker_id integer
---@field work_id AvLanesUtils.Pool.WorkId

---@class AvLanesUtils.PoolWorker
---@field worker_id integer
---@field linda Lanes.Linda
---@field next_work_id AvLanesUtils.Pool.WorkId
---@field pending_work table<AvLanesUtils.Pool.WorkId, AvLanesUtils.PoolWorker.WorkState>  # Work that is waiting on other work to be done.
---@field pending_results table<AvLanesUtils.Pool.WorkId, any[]>
local PoolWorker = {}

PoolWorker.__index = PoolWorker
---@param worker_id integer
---@param linda Lanes.Linda
function PoolWorker.new(worker_id, linda)
	assert(worker_id >= 0, "Invalid worker_id")
	assert(linda, "Invalid linda")
	return setmetatable({
		worker_id = worker_id,
		linda = linda,
		next_work_id = 1,
		pending_work = {},
		pending_results = {},
		_receive_keys = {"PoolWorker#result#"..worker_id, "PoolWorker#work#"..worker_id, },
	}, PoolWorker)
end

---@param blocking boolean
---@param accept_unassigned_work boolean
---@return boolean|Lanes.cancel_error
function PoolWorker:process(blocking, accept_unassigned_work)
	local results_key = "PoolWorker#result#"..self.worker_id
	local work_worker_key = "PoolWorker#work#"..self.worker_id
	local key, data
	if accept_unassigned_work then
		key, data = self.linda:receive(not blocking and 0 or nil, results_key, work_worker_key, "PoolWorker#work")
	else
		key, data = self.linda:receive(not blocking and 0 or nil, results_key, work_worker_key)
	end
	if key == Lanes.cancel_error then return Lanes.cancel_error end
	if key == nil then
		return false
	elseif key == results_key then
		local work_id, work_results = unpack(data)
		local work_state = self.pending_work[work_id]
		if work_state then
			self.pending_work[work_id] = nil
			if work_results[1] then
				self:resume_work(work_state, unpack(work_results, 2))
			else
				-- Propagate the error
				self:send_work_result(work_state, unpack(work_results, 2))
			end
		else
			self.pending_results[work_id] = work_results
		end
		return true
	elseif key == work_worker_key or "PoolWorker#work" then
		local work_worker_id, work_id, work_f, args = unpack(data)
		---@type AvLanesUtils.PoolWorker.WorkState
		local work_state = {
			co = coroutine.create(work_f),
			worker_id = work_worker_id,
			work_id = work_id,
		}
		self:resume_work(work_state, unpack(args))
		return true
	end
	error("Bad key " .. key)
end

---@param work_f fun(...):...
---@param work_args any[]
function PoolWorker:send_work(work_f, work_args)
	local work_id = self.next_work_id
	self.next_work_id = self.next_work_id + 1
	assert(self.linda:send("PoolWorker#work", {self.worker_id, work_id, work_f, work_args}) == true)
	return work_id
end

---@param worker_id integer
---@param work_f fun(...):...
---@param work_args any[]
function PoolWorker:send_work_to(worker_id, work_f, work_args)
	local work_id = self.next_work_id
	self.next_work_id = self.next_work_id + 1
	assert(self.linda:send("PoolWorker#work#"..worker_id, {self.worker_id, work_id, work_f, work_args}) == true)
	return work_id
end

---@param work AvLanesUtils.PoolWorker.WorkState
---@param result any[]
function PoolWorker:send_work_result(work, result)
	assert(self.linda:send("PoolWorker#result#"..work.worker_id, {work.work_id, result}) == true)
end

---@param work AvLanesUtils.PoolWorker.WorkState
---@param ... any
function PoolWorker:resume_work(work, ...)
	local has_set_context = false
	if PoolWorkerContext.worker_id ~= nil then
		assert(PoolWorkerContext.worker_id == self.worker_id)
		assert(PoolWorkerContext.linda == self.linda)
	else
		has_set_context = true
		PoolWorkerContext.worker_id = self.worker_id
		PoolWorkerContext.linda = self.linda
	end
	local results = {coroutine.resume(work.co, ...)}
	if has_set_context then
		PoolWorkerContext.worker_id = nil
		PoolWorkerContext.linda = nil
	end
	if coroutine.status(work.co) == "dead" then
		-- If the coroutine produced a lua error, get the traceback for it.
		if results[1] == false then
			results[2] = debug.traceback(work.co, results[2])
		end
		self:send_work_result(work, results)
	else
		assert(coroutine.status(work.co) == "suspended")
		assert(results[1] == true)
		if results[2] == "work_yield" or results[2] == "work_yield_main" or results[2] == "work_async" or results[2] == "work_async_main" then
			local work_f = results[3]
			local work_args = {unpack(results, 4)}
			local work_id
			if results[2] == "work_yield_main" or results[2] == "work_async_main" then
				work_id = self:send_work_to(0, work_f, work_args)
			else
				work_id = self:send_work(work_f, work_args)
			end
			if results[2] == "work_yield" or results[2] == "work_yield_main" then
				self.pending_work[work_id] = work
			else
				-- async work just resumes the work until it awaits for it later.
				return self:resume_work(work, work_id)
			end
		elseif results[2] == "work_await" then
			local work_results = self.pending_results[results[3]]
			if work_results then
				self.pending_results[results[3]] = nil
				if work_results[1] then
					return self:resume_work(work, unpack(work_results, 2))
				else
					-- Propagate the error
					return self:send_work_result(work, work_results)
				end
			else
				self.pending_work[results[3]] = work
			end
		else
			error(("Worker work yielded with invalid request '%s'"):format(results[2]))
		end
	end
end


return PoolWorker
