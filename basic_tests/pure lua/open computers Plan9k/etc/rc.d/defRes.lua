local component = require("component")
local gpu = component.gpu

function start()
	gpu.setResolution(120, 32)
end

