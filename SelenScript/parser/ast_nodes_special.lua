local ASTNodesSpecial = {}

local Utils = require("SelenScript.utils")


---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?}
---@return SelenScript.ASTNodes.Node
ASTNodesSpecial["OutputPos"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "Special_OutputPos"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?}
---@return SelenScript.ASTNodes.Node
ASTNodesSpecial["OutputLine"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "Special_OutputLine"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end

---@param args {_parent:SelenScript.ASTNodes.Node?, start:SelenScript.ASTNodes.SrcPosition?, finish:SelenScript.ASTNodes.SrcPosition?}
---@return SelenScript.ASTNodes.Node
ASTNodesSpecial["OutputColumn"] = function(args)
	args["source"] = args._parent and args._parent.source or nil
	args["type"] = "Special_OutputColumn"
	if args["start"] == nil then
		args["start"] = args._parent and args._parent.start or 1
	end
	assert(type(args["start"]) == "number")
	if args["finish"] == nil then
		args["finish"] = args._parent and args._parent.finish or 1
	end
	assert(type(args["finish"]) == "number")
	args["_parent"] = nil
	return args
end


return ASTNodesSpecial