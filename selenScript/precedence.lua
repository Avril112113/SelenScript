local unaryOpData = {
	-- ["OPERATOR"]={Precedence, TypeName}
	["not"]={10, "not"},
	["-"]={10, "neg"},
	["#"]={10, "len"},
	["~"]={10, "bit_not"},
}
local binaryOpData = {
	-- ["OPERATOR"]={Precedence, TypeName, RightAssoc}
	["^"]={11, "exp", true},

	-- UNARY

	["*"]={9, "mul", false},
	["/"]={9, "mul", false},
	["//"]={9, "mul", false},
	["%"]={9, "mul", false},

	["+"]={8, "add", false},
	["-"]={8, "add", false},

	[".."]={7, "concat", true},

	["<<"]={6, "bit_shift", false},
	[">>"]={6, "bit_shift", false},

	["&"]={5, "bit_and", false},

	["~"]={4, "bit_eor", false},

	["|"]={3, "bit_or", false},

	["<="]={2, "eq", false},
	[">="]={2, "eq", false},
	["<"]={2, "eq", false},
	[">"]={2, "eq", false},
	["~="]={2, "eq", false},
	["=="]={2, "eq", false},

	["and"]={1, "and", false},

	["or"]={1, "or", false},
}


local highestPrecedence = 1
for i, v in pairs(unaryOpData) do
	if v[1] > highestPrecedence then highestPrecedence = v[1] end
end
for i, v in pairs(binaryOpData) do
	if v[1] > highestPrecedence then highestPrecedence = v[1] end
end
return {
	unaryOpData=unaryOpData,
	binaryOpData=binaryOpData,
	highestPrecedence=highestPrecedence
}
