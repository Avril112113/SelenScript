local unaryOpData = {
	-- ["OPERATOR"]={Precedence, TypeName}
	["not"]={11, "not"},
	["-"]={11, "neg"},
	["#"]={11, "len"},
	["~"]={11, "bit_not"},
}
local binaryOpData = {
	-- ["OPERATOR"]={Precedence, TypeName, RightAssoc}
	["^"]={12, "exp", true},

	-- UNARY

	["*"]={10, "mul", false},
	["/"]={10, "mul", false},
	["//"]={10, "mul", false},
	["%"]={10, "mul", false},

	["+"]={9, "add", false},
	["-"]={9, "add", false},

	[".."]={8, "concat", true},

	["<<"]={7, "bit_shift", false},
	[">>"]={7, "bit_shift", false},

	["&"]={6, "bit_and", false},

	["~"]={5, "bit_eor", false},

	["|"]={4, "bit_or", false},

	["<="]={3, "eq", false},
	[">="]={3, "eq", false},
	["<"]={3, "eq", false},
	[">"]={3, "eq", false},
	["~="]={3, "eq", false},
	["=="]={3, "eq", false},

	["and"]={2, "and", false},

	["or"]={1, "or", false},
}

local types = {}
for i, v in pairs(binaryOpData) do
	types[v[2]] = v[2]
end
for i, v in pairs(unaryOpData) do
	types[v[2]] = v[2]
end

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
	types=types,
	highestPrecedence=highestPrecedence,
}
