--- State regarding this pool worker.  
--- Ensure to check for `worker_id` field existing, as this is a empty table outside of a pool worker.  
---@class AvLanesUtils.PoolWorkerContext
---@field worker_id integer
---@field linda Lanes.Linda
local PoolWorkerContext = {}


---@generic R1:any?, R2:any?, R3:any?, R4:any?, R5:any?, R6:any?
---@param f fun(...?):R1?,R2?,R3?,R4?,R5?,R6?
---@return R1,R2,R3,R4,R5,R6
---@async
function PoolWorkerContext.work(f, ...)
	assert(PoolWorkerContext.linda, "PoolWorker.work can only be called from a pool worker.")
	return coroutine.yield("work_yield", f, ...)
end
--- Queues work where the pool was created.
---@generic R1:any?, R2:any?, R3:any?, R4:any?, R5:any?, R6:any?
---@param f fun(...?):R1?,R2?,R3?,R4?,R5?,R6?
---@return R1,R2,R3,R4,R5,R6
---@async
function PoolWorkerContext.work_main(f, ...)
	assert(PoolWorkerContext.linda, "PoolWorker.work can only be called from a pool worker.")
	return coroutine.yield("work_yield_main", f, ...)
end

---@param f fun(...?):...?
---@return AvLanesUtils.Pool.WorkId
function PoolWorkerContext.work_async(f, ...)
	assert(PoolWorkerContext.linda, "PoolWorker.work_async can only be called from a pool worker.")
	return coroutine.yield("work_async", f, ...)  -- Immediately resumes
end
--- Queues work where the pool was created.
---@param f fun(...?):...?
---@return AvLanesUtils.Pool.WorkId
function PoolWorkerContext.work_main_async(f, ...)
	assert(PoolWorkerContext.linda, "PoolWorker.work_async can only be called from a pool worker.")
	return coroutine.yield("work_async_main", f, ...)  -- Immediately resumes
end

---@param work_id AvLanesUtils.Pool.WorkId
---@return ...
---@async
function PoolWorkerContext.work_await(work_id)
	assert(PoolWorkerContext.linda, "PoolWorker.work_await can only be called from a pool worker.")
	return coroutine.yield("work_await", work_id)
end


return PoolWorkerContext
