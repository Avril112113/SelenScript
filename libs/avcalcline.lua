---@class AVCalcLine.Node
---@field pos integer
---@field line integer
---@field column integer
---@field left AVCalcLine.Node?
---@field right AVCalcLine.Node?

---@class AVCalcLine
---@field src string
---@field chunk_size integer
---@field tree AVCalcLine.Node
local AVCalcLine = {}
AVCalcLine.__index = AVCalcLine


---@param src string
function AVCalcLine.new(src)
	local self = setmetatable({}, AVCalcLine)
	self.src = src
	self.tree = {pos=1,line=1,column=1}
	return self
end

function AVCalcLine:calcline(pos)
	if pos < 0 then
		return 0, 0
	end

	local node = self.tree
	while true do
		if pos > node.pos then
			if node.right then
				node = node.right
			else
				break
			end
		elseif pos < node.pos then
			if node.left then
				node = node.left
			else
				break
			end
		else
			break
		end
	end
	---@cast node -?

	if node.pos == pos then
		return node.line, node.column
	end

	local rest, nl_count = self.src:sub(node.pos, pos):gsub("[^\n]*\n", "")
	local line = node.line + nl_count
	local column = (nl_count == 0 and node.column or 0) + #rest
	column = column ~= 0 and column or 1

	if pos > node.pos then
		node.right = {pos=pos, line=line, column=column}
	elseif pos < node.pos then
		node.left = {pos=pos, line=line, column=column}
	end

	return line, column
end


return AVCalcLine
