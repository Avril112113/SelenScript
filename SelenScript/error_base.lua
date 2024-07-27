---@class SelenScript.Error
---@field id string
---@field msg string
---@field data any
local Error = {}

---@class SelenScript.ErrorBase
---@field id string
---@field msg_format string
local ErrorBase = {
	---@param self SelenScript.ErrorBase
	---@param data table<string, any>
	---@return SelenScript.Error
	__call=function(self, data, ...)
		return {
			id=self.id,
			msg=self.msg_format:format(...),
			data=data,
		}
	end,
}

---@param id string
---@param msg_format string
---@return SelenScript.ErrorBase
function ErrorBase.generate(id, msg_format)
	return setmetatable({id=id, msg_format=msg_format}, ErrorBase)
end

return ErrorBase