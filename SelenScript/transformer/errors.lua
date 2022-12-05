local ErrorBase = require "SelenScript.error_base"


local Errors = {}


Errors.INTERNAL = ErrorBase.generate("INTERNAL", "Internal Error %u@%u: %s")
Errors.CONTINUE_MISSING_LOOP = ErrorBase.generate("CONTINUE_MISSING_LOOP", "Syntax %u:%u: `continue` is missing loop to continue.")
Errors.BREAK_VALUES_NON_EXPR = ErrorBase.generate("BREAK_VALUES_NON_EXPR", "Syntax %u:%u: Attempted to return values from `break` within a non expression statement context.")


return Errors
