foo = while true do
	break "foo's value"
end
bar = do
	return "OOooo, fancy"
end
baz = for i,v in pairs(t) do
	-- will not break until v == "baz"
	-- if all elements have been checked and none was true then baz == nil
	break v if v == "baz"
	-- basically if nothing 'returned' a value then Lua's default is used `nil`
end
