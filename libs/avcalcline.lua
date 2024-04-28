---@alias AVCalcLine.Segment {pos:integer,line:integer,column:integer}

---@class AVCalcLine
---@field src string
---@field segments AVCalcLine.Segment[]
local AVCalcLine = {}
AVCalcLine.__index = AVCalcLine


---@param src string
function AVCalcLine.new(src)
	local self = setmetatable({}, AVCalcLine)
	self.src = src
	self.segments = {}
	local i, line, column = 1, 1, 1

	while true do
		table.insert(self.segments, {
			pos=i,
			line=line,
			column=column,
		})
		local rest, nl_count = src:sub(i+1,i+1000):gsub("[^\n]*\n", "")
		line = line + nl_count
		column = #rest
		column = column ~= 0 and column or 1
		if i > #src then break end
		i = i + 1000
	end
	return self
end

function AVCalcLine:calcline(pos)
	local segment = self.segments[1]
	local i = 2
	while true do
		if self.segments[i].pos > pos then
			break
		else
			segment = self.segments[i]
			i = i + 1
		end
	end
	local rest, nl_count = self.src:sub(segment.pos+1, pos):gsub("[^\n]*\n", "")
	local line = segment.line + nl_count
	local column = (nl_count == 0 and segment.column or 0) + #rest
	column = column ~= 0 and column or 1
	return line, column
end


return AVCalcLine
