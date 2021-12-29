local ErrorBase = require "SelenScript.error_base"


local Errors = {}


Errors.UNIDENTIFIED = ErrorBase.generate("UNIDENTIFIED", "%s")
Errors.GRAMMAR_SYNTAX = ErrorBase.generate("GRAMMAR_SYNTAX", "GrammarSyntax: %s")
Errors.GRAMMAR_UNPARSED = ErrorBase.generate("GRAMMAR_UNPARSED", "Un-parsed Input %u@%u:\n%s")
Errors.GRAMMAR_INVALID_MATH = ErrorBase.generate("GRAMMAR_INVALID_MATH", "Invalid Math %u@%u: Attempted to processes precedence for invalid math")
Errors.SYNTAX_UNIDENTIFIED = ErrorBase.generate("SYNTAX_UNIDENTIFIED", "Syntax %u@%u: %s")
Errors.SYNTAX_MISS_NAME = ErrorBase.generate("SYNTAX_MISS_NAME", "Syntax %u@%u: Missing name")
Errors.SYNTAX_MISS_END = ErrorBase.generate("SYNTAX_MISS_END", "Syntax %u@%u: Missing closing `end`")
Errors.SYNTAX_EXPECT_THEN = ErrorBase.generate("SYNTAX_EXPECT_THEN", "Syntax %u@%u: Expected `then` when we got `%s`")
Errors.SYNTAX_EXPECT_DO = ErrorBase.generate("SYNTAX_EXPECT_DO", "Syntax %u@%u: Expected `do` when we got `%s`")
Errors.SYNTAX_EXPECT_AS = ErrorBase.generate("SYNTAX_EXPECT_THEN", "Syntax %u@%u: Expected `as` when we got `%s`")
Errors.SYNTAX_EXPECT_IN = ErrorBase.generate("SYNTAX_EXPECT_THEN", "Syntax %u@%u: Expected `in` when we got `%s`")
Errors.SYNTAX_FLOAT_EXPR = ErrorBase.generate("SYNTAX_FLOAT_EXPR", "Syntax %u@%u: Floating expression `%s`")


return Errors
