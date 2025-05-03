---@param ... Lanes.GenLibsStr|Lanes.GenOpts
return function(...)
	---@param worker_id integer
	---@param linda Lanes.Linda
	---@param user_init_func fun()?
	return require "lanes".gen(..., function(worker_id, linda, user_init_func)
		local Lanes = require "lanes"

		local PoolWorkerContext = require "avlanesutils.pool_worker_context"
		PoolWorkerContext.worker_id = worker_id
		PoolWorkerContext.linda = linda

		local PoolWorker = require "avlanesutils.pool_worker".new(worker_id, linda)

		if user_init_func then user_init_func() end

		while PoolWorker:process(true, true) ~= Lanes.cancel_error do
		end
	end)
end
