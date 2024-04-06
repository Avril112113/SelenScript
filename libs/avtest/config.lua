local colors = require "avtest.terminal_colors"


local Config = {}


Config.stripColors = colors.strip

---@param useColors boolean
function Config.setColors(useColors)
	Config.PREFIX_TAG = useColors and colors.fix or ""
	Config.PREFIX_ERR = useColors and colors.error or ""
	Config.PREFIX_GROUP = useColors and colors.info or ""

	Config.PREFIX_PASS = useColors and colors.green or ""
	Config.PREFIX_FAIL = useColors and colors.error or ""

	Config.PREFIX_TEXT = useColors and colors.white or ""
	Config.RESET = useColors and colors.reset or ""
end

Config.setColors(true)


return Config
