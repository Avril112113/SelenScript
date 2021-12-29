local ErrorBase = require "SelenScript.error_base"


local Errors = {}


Errors.INTERNAL = ErrorBase.generate("INTERNAL", "Internal Error %u@%u: %s")
Errors.CONTINUE_MISSING_LOOP = ErrorBase.generate("CONTINUE_MISSING_LOOP", "Syntax %u@%u: `continue` is missing loop to continue.")


return Errors
